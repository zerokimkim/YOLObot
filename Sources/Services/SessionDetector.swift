import Foundation

final class SessionDetector {

    private let agentSessionsBase: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Claude/local-agent-mode-sessions"
    }()

    func detectActiveSessions() -> [SessionInfo] {
        let pids = findClaudeCodePIDs()
        var sessions: [SessionInfo] = []

        for pid in pids {
            guard let cwd = getWorkingDirectory(pid: pid) else { continue }
            let sessionId = getSessionId(pid: pid) ?? "unknown"
            let (title, lastActivity) = getSessionMetadata(cwd: cwd)

            let session = SessionInfo(
                pid: pid,
                sessionId: sessionId,
                workingDirectory: cwd,
                title: title,
                lastActivity: lastActivity
            )
            sessions.append(session)
        }

        return sessions.sorted { ($0.lastActivity ?? .distantPast) > ($1.lastActivity ?? .distantPast) }
    }

    // MARK: - PID Detection

    private func findClaudeCodePIDs() -> [Int32] {
        let result = ShellExecutor.run(
            "ps aux | grep 'claude-code.*claude' | grep -v grep | grep -v disclaimer | awk '{print $2}'"
        )
        return result.output
            .split(separator: "\n")
            .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
    }

    // MARK: - Working Directory

    private func getWorkingDirectory(pid: Int32) -> String? {
        let result = ShellExecutor.run("lsof -p \(pid) 2>/dev/null | grep cwd | awk '{print $NF}'")
        let cwd = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return cwd.isEmpty ? nil : cwd
    }

    // MARK: - Session ID from command line

    private func getSessionId(pid: Int32) -> String? {
        let result = ShellExecutor.run("ps -p \(pid) -o args= 2>/dev/null")
        let args = result.output

        // Find --resume <uuid>
        if let range = args.range(of: "--resume ") {
            let afterResume = args[range.upperBound...]
            let uuid = afterResume.prefix(while: { !$0.isWhitespace })
            if !uuid.isEmpty {
                return String(uuid)
            }
        }

        return nil
    }

    // MARK: - Session Metadata from agent-mode JSONs

    private func getSessionMetadata(cwd: String) -> (title: String?, lastActivity: Date?) {
        let fm = FileManager.default
        guard let accountDirs = try? fm.contentsOfDirectory(atPath: agentSessionsBase) else {
            return (nil, nil)
        }

        for accountDir in accountDirs where !accountDir.hasPrefix(".") && accountDir != "skills-plugin" {
            let accountPath = "\(agentSessionsBase)/\(accountDir)"
            guard let orgDirs = try? fm.contentsOfDirectory(atPath: accountPath) else { continue }

            for orgDir in orgDirs where !orgDir.hasPrefix(".") {
                let orgPath = "\(accountPath)/\(orgDir)"
                guard let files = try? fm.contentsOfDirectory(atPath: orgPath) else { continue }

                let jsonFiles = files.filter { $0.hasPrefix("local_") && $0.hasSuffix(".json") }
                for jsonFile in jsonFiles {
                    let jsonPath = "\(orgPath)/\(jsonFile)"
                    if let (title, lastActivity) = parseSessionJSON(path: jsonPath, matchingCwd: cwd) {
                        return (title, lastActivity)
                    }
                }
            }
        }

        return (nil, nil)
    }

    private func parseSessionJSON(path: String, matchingCwd: String) -> (String?, Date?)? {
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Match by userSelectedFolders containing the cwd
        if let folders = json["userSelectedFolders"] as? [String] {
            let matched = folders.contains { folder in
                matchingCwd.hasPrefix(folder) || folder.hasPrefix(matchingCwd)
            }
            if !matched { return nil }
        } else {
            return nil
        }

        let title = json["title"] as? String
        var lastActivity: Date?
        if let ts = json["lastActivityAt"] as? Double {
            lastActivity = Date(timeIntervalSince1970: ts / 1000.0)
        }

        return (title, lastActivity)
    }
}
