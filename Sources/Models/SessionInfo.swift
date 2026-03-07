import Foundation

struct SessionInfo: Identifiable, Hashable {
    let id: String              // PID as string for Identifiable
    let pid: Int32
    let sessionId: String       // --resume UUID or "new"
    let workingDirectory: String
    let folderName: String      // last path component
    let title: String?          // from agent-mode JSON
    let lastActivity: Date?

    init(pid: Int32, sessionId: String, workingDirectory: String, title: String? = nil, lastActivity: Date? = nil) {
        self.id = "\(pid)"
        self.pid = pid
        self.sessionId = sessionId
        self.workingDirectory = workingDirectory
        self.folderName = URL(fileURLWithPath: workingDirectory).lastPathComponent
        self.title = title
        self.lastActivity = lastActivity
    }

    var displayName: String {
        if let t = title, !t.isEmpty {
            return t
        }
        return folderName
    }
}
