import Foundation

final class TaskMonitor {
    private var monitorTimer: Timer?
    private var monitoredSession: SessionInfo?
    private var onComplete: ((SessionInfo) -> Void)?
    private var lastActivityTimestamp: Date?
    private var idleCount = 0

    private let idleThresholdSeconds: TimeInterval = 30
    private let checkIntervalSeconds: TimeInterval = 5

    private let agentSessionsBase: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Claude/local-agent-mode-sessions"
    }()

    func startMonitoring(session: SessionInfo, onComplete: @escaping (SessionInfo) -> Void) {
        self.monitoredSession = session
        self.onComplete = onComplete
        self.lastActivityTimestamp = session.lastActivity
        self.idleCount = 0

        monitorTimer = Timer.scheduledTimer(withTimeInterval: checkIntervalSeconds, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
        print("YOLObot: Monitoring session \(session.displayName) (PID: \(session.pid))")
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        monitoredSession = nil
        onComplete = nil
        idleCount = 0
        print("YOLObot: Monitoring stopped")
    }

    // MARK: - Status Check

    private func checkStatus() {
        guard let session = monitoredSession else { return }

        // Check 1: Is the process still alive?
        if !isProcessAlive(pid: session.pid) {
            print("YOLObot: Process \(session.pid) exited")
            triggerCompletion()
            return
        }

        // Check 2: Activity timestamp from session JSON
        if let currentActivity = getCurrentActivity(for: session) {
            if let last = lastActivityTimestamp, currentActivity == last {
                idleCount += 1
            } else {
                idleCount = 0
                lastActivityTimestamp = currentActivity
            }

            // If idle for threshold duration
            let idleDuration = TimeInterval(idleCount) * checkIntervalSeconds
            if idleDuration >= idleThresholdSeconds {
                // Double-check: verify CPU is actually idle
                if isProcessIdle(pid: session.pid) {
                    print("YOLObot: Session idle for \(Int(idleDuration))s, task likely complete")
                    triggerCompletion()
                }
            }
        }
    }

    // MARK: - Process Checks

    private func isProcessAlive(pid: Int32) -> Bool {
        let result = ShellExecutor.run("kill -0 \(pid) 2>/dev/null; echo $?")
        return result.output.trimmingCharacters(in: .whitespacesAndNewlines) == "0"
    }

    private func isProcessIdle(pid: Int32) -> Bool {
        let result = ShellExecutor.run("ps -p \(pid) -o %cpu= 2>/dev/null")
        guard let cpu = Double(result.output.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return true // process may have exited
        }
        return cpu < 1.0
    }

    // MARK: - Activity Tracking

    private func getCurrentActivity(for session: SessionInfo) -> Date? {
        let fm = FileManager.default
        guard let accountDirs = try? fm.contentsOfDirectory(atPath: agentSessionsBase) else { return nil }

        for accountDir in accountDirs where !accountDir.hasPrefix(".") && accountDir != "skills-plugin" {
            let accountPath = "\(agentSessionsBase)/\(accountDir)"
            guard let orgDirs = try? fm.contentsOfDirectory(atPath: accountPath) else { continue }

            for orgDir in orgDirs where !orgDir.hasPrefix(".") {
                let orgPath = "\(accountPath)/\(orgDir)"
                guard let files = try? fm.contentsOfDirectory(atPath: orgPath) else { continue }

                let jsonFiles = files.filter { $0.hasPrefix("local_") && $0.hasSuffix(".json") }
                for jsonFile in jsonFiles {
                    let jsonPath = "\(orgPath)/\(jsonFile)"
                    guard let data = fm.contents(atPath: jsonPath),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let cliSessionId = json["cliSessionId"] as? String,
                          cliSessionId == session.sessionId || matchesCwd(json: json, cwd: session.workingDirectory),
                          let ts = json["lastActivityAt"] as? Double else { continue }

                    return Date(timeIntervalSince1970: ts / 1000.0)
                }
            }
        }
        return nil
    }

    private func matchesCwd(json: [String: Any], cwd: String) -> Bool {
        guard let folders = json["userSelectedFolders"] as? [String] else { return false }
        return folders.contains { cwd.hasPrefix($0) || $0.hasPrefix(cwd) }
    }

    // MARK: - Completion

    private func triggerCompletion() {
        guard let session = monitoredSession else { return }
        stopMonitoring()
        onComplete?(session)
    }
}
