import Foundation
import AppKit

final class Notifier {

    func sendCompletion(session: SessionInfo) {
        let message = "\(session.displayName) task completed!"
        sendNotification(title: "YOLObot", body: message, sound: "Glass")
    }

    func sendStatus(message: String) {
        sendNotification(title: "YOLObot", body: message)
    }

    private func sendNotification(title: String, body: String, sound: String? = nil) {
        var script = "display notification \"\(escapeForAppleScript(body))\" with title \"\(escapeForAppleScript(title))\""
        if let sound = sound {
            script += " sound name \"\(sound)\""
        }

        ShellExecutor.runAsync("osascript -e '\(script)'") { _, _ in }
        print("YOLObot: \(title) - \(body)")
    }

    private func escapeForAppleScript(_ str: String) -> String {
        str.replacingOccurrences(of: "'", with: "'\\''")
           .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
