import Foundation
import AppKit

final class Notifier {

    private let telegramNotifier = TelegramNotifier()

    func sendCompletion(session: SessionInfo) {
        let message = "Task completed! (\(session.workingDirectory))"

        // 1) macOS notification
        sendNotification(title: "YOLO zerobot", body: message, sound: "Glass")

        // 2) Completion sound effect (louder, distinct)
        playCompletionSound()

        // 3) Telegram notification
        telegramNotifier.sendCompletion(session: session)
    }

    func sendStatus(message: String) {
        sendNotification(title: "YOLO zerobot", body: message)
    }

    // MARK: - Sound Effect

    private func playCompletionSound() {
        // Check config — sound enabled by default
        guard isSoundEnabled() else { return }

        // Try bundled sound first, fall back to system sound
        if let soundPath = Bundle.main.path(forResource: "complete", ofType: "aiff"),
           let sound = NSSound(contentsOfFile: soundPath, byReference: true) {
            sound.play()
        } else if let sound = NSSound(named: "Hero") {
            sound.play()
        } else {
            NSSound.beep()
            ShellExecutor.runAsync("afplay /System/Library/Sounds/Glass.aiff") { _, _ in }
        }
    }

    private func isSoundEnabled() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(home)/.yolobot/config.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sound = json["sound"] as? [String: Any] else {
            return true // default ON
        }
        return sound["enabled"] as? Bool ?? true
    }

    // MARK: - macOS Notification

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
