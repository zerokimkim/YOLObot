import Foundation

final class TelegramNotifier {

    private struct Config: Codable {
        let telegram: TelegramConfig?
    }

    private struct TelegramConfig: Codable {
        let enabled: Bool
        let botToken: String
        let chatId: String
    }

    private var config: TelegramConfig?
    private let configPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        configPath = "\(home)/.yolobot/config.json"
        loadConfig()
    }

    // MARK: - Public

    /// Reload config from disk (called after Settings save)
    func reloadConfig() {
        loadConfig()
    }

    func sendCompletion(session: SessionInfo) {
        // Always reload before sending (pick up Settings changes)
        reloadConfig()
        guard let config = config, config.enabled else {
            print("YOLObot: Telegram not configured or disabled")
            return
        }

        let message = "✅ Claude Code task has been completed.\n\n" +
                      "📍 Path: \(session.workingDirectory)\n\n" +
                      "From YOLO zerobot 🤖"

        sendMessage(text: message)
    }

    func sendTest() {
        guard let config = config, config.enabled else {
            print("YOLObot: Telegram not configured")
            return
        }

        sendMessage(text: "🔔 YOLObot test notification — Telegram is connected!")
    }

    // MARK: - Private

    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configPath) else {
            print("YOLObot: No config at \(configPath)")
            createTemplateConfig()
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let decoded = try JSONDecoder().decode(Config.self, from: data)
            config = decoded.telegram
            if let tg = config {
                print("YOLObot: Telegram config loaded (enabled: \(tg.enabled))")
            }
        } catch {
            print("YOLObot: Failed to parse config: \(error)")
        }
    }

    private func createTemplateConfig() {
        let dir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let template = """
        {
          "telegram": {
            "enabled": false,
            "botToken": "YOUR_BOT_TOKEN_HERE",
            "chatId": "YOUR_CHAT_ID_HERE"
          }
        }
        """

        try? template.write(toFile: configPath, atomically: true, encoding: .utf8)
        print("YOLObot: Template config created at \(configPath)")
    }

    private func sendMessage(text: String) {
        guard let config = config else { return }

        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let curlCmd = """
        curl -s -X POST "https://api.telegram.org/bot\(config.botToken)/sendMessage" \
          -H "Content-Type: application/json" \
          -d '{"chat_id": "\(config.chatId)", "text": "\(escapedText)", "parse_mode": "HTML"}'
        """

        ShellExecutor.runAsync(curlCmd) { output, exitCode in
            if exitCode == 0 {
                print("YOLObot: Telegram message sent successfully")
            } else {
                print("YOLObot: Telegram send failed: \(output)")
            }
        }
    }
}
