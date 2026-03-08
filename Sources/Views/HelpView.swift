import SwiftUI
import AppKit

struct HelpView: View {
    var body: some View {
        VStack(spacing: 0) {

            // ── Hero ──
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("YOLO zerobot")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Claude Code on Autopilot")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().padding(.horizontal, 24)

            // ── How to Use ──
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    sectionTitle("Quick Start")

                    VStack(alignment: .leading, spacing: 10) {
                        // Step 1: app icon instead of SF Symbol
                        HStack(spacing: 10) {
                            Image(nsImage: NSApp.applicationIconImage)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text("Launch YOLO zerobot — floating widget appears")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }
                        stepRow("2", "Click \"YOLO ON\" to activate", "power")
                        stepRow("3", "Auto-approves all permission dialogs", "checkmark.shield.fill")
                        stepRow("4", "Get notified when tasks complete", "bell.badge.fill")
                        stepRow("5", "Click \"YOLO OFF\" to restore settings", "stop.circle")
                    }

                    Divider()

                    sectionTitle("Widget Controls")

                    HStack(spacing: 20) {
                        controlChip(icon: "pin.fill", label: "Pin", desc: "Always on top")
                        controlChip(icon: "arrow.down.to.line", label: "Minimize", desc: "Bottom bar")
                        controlChip(icon: "arrow.clockwise", label: "Refresh", desc: "Re-scan")
                        controlChip(icon: "gearshape.fill", label: "Settings", desc: "Telegram")
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    sectionTitle("Keyboard Shortcuts")

                    HStack(spacing: 16) {
                        shortcutChip("⌘V", "Paste")
                        shortcutChip("⌘C", "Copy")
                        shortcutChip("⌘X", "Cut")
                        shortcutChip("⌘A", "Select All")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }

            Divider()

            // ── Contact Footer ──
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("ZERO")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("from")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Seoul")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("hipson.k@gmail.com", forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 10))
                        Text("hipson.k@gmail.com")
                            .font(.system(size: 11, design: .monospaced))
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Click to copy email")

                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("github.com/zerokimkim/YOLObot")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 400, height: 520)
    }

    // MARK: - Components

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
    }

    private func stepRow(_ num: String, _ text: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.12))
                )
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
    }

    private func controlChip(icon: String, label: String, desc: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            Text(label)
                .font(.system(size: 10, weight: .semibold))
            Text(desc)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private func shortcutChip(_ key: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                )
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}
