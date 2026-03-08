import SwiftUI
import AppKit

// MARK: - Settings View

struct SettingsView: View {
    @State private var soundEnabled = true
    @State private var telegramEnabled = false
    @State private var botToken = ""
    @State private var chatId = ""
    @State private var testStatus = ""
    @State private var isTesting = false
    @FocusState private var focusedField: Field?

    private enum Field { case botToken, chatId }

    private let configPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.yolobot/config.json"
    }()

    // Store full body for later restore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Sound Section ──
            GroupBox {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.orange)
                    Text("Completion Sound")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Toggle("", isOn: $soundEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(4)
            }

            // ── Telegram Section ──
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {

                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                        Text("Telegram Notifications")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: $telegramEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    Text("Get notified on your phone when Claude Code tasks complete.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bot Token")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("123456:ABC-DEF1234ghIkl-zyx57W2v...", text: $botToken)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                            .focused($focusedField, equals: .botToken)

                        Text("Chat ID")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        TextField("987654321", text: $chatId)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                            .focused($focusedField, equals: .chatId)
                    }
                    .opacity(telegramEnabled ? 1.0 : 0.4)
                    .disabled(!telegramEnabled)

                    Divider()

                    // ── Setup Guide ──
                    DisclosureGroup("How to get Bot Token & Chat ID") {
                        VStack(alignment: .leading, spacing: 6) {
                            stepText("1", "Open Telegram → search @BotFather")
                            stepText("2", "Send /newbot → follow prompts → copy Token")
                            stepText("3", "Send any message to your new bot")
                            stepText("4", "Visit: api.telegram.org/bot<TOKEN>/getUpdates")
                            stepText("5", "Find \"chat\":{\"id\": YOUR_CHAT_ID}")
                        }
                        .padding(.top, 6)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
                .padding(4)
            }

            // ── Action Buttons ──
            HStack {
                Button(action: sendTestNotification) {
                    HStack(spacing: 4) {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "bell.badge")
                        }
                        Text("Send Test")
                    }
                    .font(.system(size: 12))
                }
                .disabled(!telegramEnabled || botToken.isEmpty || chatId.isEmpty || isTesting)

                if !testStatus.isEmpty {
                    Text(testStatus)
                        .font(.system(size: 11))
                        .foregroundColor(testStatus.contains("✅") ? .green : .red)
                }

                Spacer()

                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }

                Button("Save") {
                    saveConfig()
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { loadConfig() }
        // ── Paste handler (SwiftUI level — bypasses AppKit responder chain) ──
        .onReceive(NotificationCenter.default.publisher(for: .init("YOLObotPaste"))) { _ in
            guard let string = NSPasteboard.general.string(forType: .string) else { return }
            switch focusedField {
            case .botToken: botToken = string
            case .chatId: chatId = string
            case nil: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("YOLObotSelectAll"))) { _ in
            // Select all is handled natively when NSTextView works
        }
    }

    // MARK: - Helper Views

    private func stepText(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(num)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.blue.opacity(0.7)))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Config I/O

    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configPath) else { return }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let telegram = json["telegram"] as? [String: Any] else { return }

        // Sound
        if let sound = json["sound"] as? [String: Any] {
            soundEnabled = sound["enabled"] as? Bool ?? true
        }

        telegramEnabled = telegram["enabled"] as? Bool ?? false
        botToken = telegram["botToken"] as? String ?? ""
        chatId = telegram["chatId"] as? String ?? ""

        if botToken == "YOUR_BOT_TOKEN_HERE" { botToken = "" }
        if chatId == "YOUR_CHAT_ID_HERE" { chatId = "" }
    }

    private func saveConfig() {
        let dir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let config: [String: Any] = [
            "sound": [
                "enabled": soundEnabled
            ],
            "telegram": [
                "enabled": telegramEnabled,
                "botToken": botToken,
                "chatId": chatId
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }

    private func sendTestNotification() {
        guard !botToken.isEmpty, !chatId.isEmpty else { return }
        isTesting = true
        testStatus = ""
        saveConfig()

        let message = "YOLO zerobot test - Telegram connected!"
        let curlCmd = """
        curl -s -o /dev/null -w "%{http_code}" -X POST \
          "https://api.telegram.org/bot\(botToken)/sendMessage" \
          -H "Content-Type: application/json" \
          -d '{"chat_id": "\(chatId)", "text": "\(message)"}'
        """

        ShellExecutor.runAsync(curlCmd) { output, exitCode in
            isTesting = false
            if exitCode == 0 && output == "200" {
                testStatus = "✅ Sent!"
            } else {
                testStatus = "❌ Failed (code: \(output))"
            }
        }
    }
}
