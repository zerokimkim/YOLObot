import Foundation

final class TaskMonitor {
    private var monitorTimer: Timer?
    private var monitoredSession: SessionInfo?
    private var onComplete: ((SessionInfo) -> Void)?
    private var lastActivityTimestamp: Date?
    private var idleCount = 0
    private var cpuIdleCount = 0

    private let idleThresholdSeconds: TimeInterval = 8
    private let checkIntervalSeconds: TimeInterval = 2

    private let agentSessionsBase: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Claude/local-agent-mode-sessions"
    }()

    func startMonitoring(session: SessionInfo, onComplete: @escaping (SessionInfo) -> Void) {
        self.monitoredSession = session
        self.onComplete = onComplete
        self.lastActivityTimestamp = session.lastActivity
        self.idleCount = 0
        self.cpuIdleCount = 0

        DebugLog.log("TaskMonitor.startMonitoring PID=\(session.pid) cwd=\(session.workingDirectory)")
        monitorTimer = Timer.scheduledTimer(withTimeInterval: checkIntervalSeconds, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        monitoredSession = nil
        onComplete = nil
        idleCount = 0
        cpuIdleCount = 0
        print("YOLObot: Monitoring stopped")
    }

    // MARK: - Status Check

    private func checkStatus() {
        guard let session = monitoredSession else {
            DebugLog.log("checkStatus: no monitoredSession!")
            return
        }

        // Check 1: Is the process still alive?
        let alive = isProcessAlive(pid: session.pid)
        if !alive {
            DebugLog.log("checkStatus: PID \(session.pid) exited → triggerCompletion")
            triggerCompletion()
            return
        }

        // Check CPU
        let cpuResult = ShellExecutor.run("ps -p \(session.pid) -o %cpu= 2>/dev/null")
        let cpuStr = cpuResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let cpu = Double(cpuStr) ?? -1

        // Check 2: Activity timestamp from session JSON (primary)
        if let currentActivity = getCurrentActivity(for: session) {
            if let last = lastActivityTimestamp, currentActivity == last {
                idleCount += 1
            } else {
                idleCount = 0
                lastActivityTimestamp = currentActivity
            }

            let idleDuration = TimeInterval(idleCount) * checkIntervalSeconds
            let idle = cpu < 5.0
            DebugLog.log("check: JSON found, cpu=\(cpuStr) idle=\(idle) idleCount=\(idleCount) dur=\(Int(idleDuration))s")

            if idleDuration >= idleThresholdSeconds && idle {
                DebugLog.log("TRIGGER: JSON+CPU idle \(Int(idleDuration))s")
                triggerCompletion()
            }
        } else {
            // Fallback: CPU-only monitoring
            let idle = cpu < 5.0
            if idle {
                cpuIdleCount += 1
            } else {
                cpuIdleCount = 0
            }

            let cpuIdleDuration = TimeInterval(cpuIdleCount) * checkIntervalSeconds
            DebugLog.log("check: NO JSON, cpu=\(cpuStr) idle=\(idle) cpuIdleCount=\(cpuIdleCount) dur=\(Int(cpuIdleDuration))s")

            if cpuIdleDuration >= idleThresholdSeconds {
                DebugLog.log("TRIGGER: CPU-only idle \(Int(cpuIdleDuration))s")
                triggerCompletion()
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
        return cpu < 5.0
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
        let callback = onComplete  // Save before stopMonitoring nils it
        DebugLog.log("triggerCompletion: \(session.displayName) PID=\(session.pid)")
        stopMonitoring()
        callback?(session)
    }
}
