import SwiftUI
import AppKit

struct WidgetView: View {
    @ObservedObject var state: YoloState
    @State private var colorPhase = false
    @State private var rotation: Double = 0
    @State private var showAbout = false

    // Brand colors from YOLObot icon
    private let brandTerracotta = Color(red: 0.61, green: 0.29, blue: 0.17)
    private let brandCoral = Color(red: 0.83, green: 0.51, blue: 0.41)

    var body: some View {
        VStack(spacing: 0) {

            // ── Drag Handle ──
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // ── Header ──
            HStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Text("YOLObot")
                    .font(.system(size: 16, weight: .bold))

                Spacer()

                // About
                Button(action: { showAbout.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help("About YOLObot")
                .popover(isPresented: $showAbout) {
                    AboutPopover()
                }

                // Pin / Unpin (always-on-top toggle)
                Button(action: togglePin) {
                    Image(systemName: state.isPinned ? "pin.fill" : "pin.slash")
                        .font(.system(size: 12))
                        .foregroundColor(state.isPinned ? .orange : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(state.isPinned ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help(state.isPinned ? "Unpin from top" : "Pin to top")

                Text(state.isOn ? "ON" : "OFF")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(state.isOn ? .green : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(state.isOn ? Color.green.opacity(0.25) : Color.gray.opacity(0.2))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // ── Big Toggle Button ──
            Button(action: { state.toggle() }) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(state.isOn
                              ? (colorPhase ? brandTerracotta : brandCoral)
                              : Color.green.opacity(0.85))

                    // Spinning claude icon overlay (only when ON)
                    if state.isOn, let iconPath = Bundle.main.path(forResource: "claude_icon", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: iconPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .opacity(0.15)
                            .rotationEffect(.degrees(rotation))
                    }

                    // Button label
                    HStack(spacing: 8) {
                        Image(systemName: state.isOn ? "stop.fill" : "play.fill")
                            .font(.system(size: 18))
                        Text(state.isOn ? "YOLO OFF" : "YOLO ON")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    colorPhase = true
                }
            }
            .onChange(of: state.isOn) { isOn in
                if isOn {
                    rotation = 0
                    withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.5)) {
                        rotation = 0
                    }
                }
            }

            // ── Tagline ──
            Text("Claude Code on Autopilot")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 6)

            // ── Status ──
            HStack(spacing: 6) {
                Circle()
                    .fill(state.isOn ? Color.green : Color.gray)
                    .frame(width: 7, height: 7)
                Text(state.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 14)

            // ── Sessions (collapsible) ──
            if !state.isSessionsCollapsed {
                if state.sessions.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("No active sessions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Active Sessions")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 2)

                        ForEach(state.sessions) { session in
                            SessionRow(
                                session: session,
                                isMonitored: session.sessionId == state.monitoredSessionId
                            )
                        }
                    }
                }
            }

            Divider()
                .padding(.horizontal, 14)

            // ── Bottom Buttons ──
            HStack {
                Button(action: { state.startSessionRefresh() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.primary.opacity(0.7))
                }
                .buttonStyle(.plain)

                Spacer()

                // Collapse / Expand sessions
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.isSessionsCollapsed.toggle()
                    }
                }) {
                    Image(systemName: state.isSessionsCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(state.isSessionsCollapsed ? "Expand sessions" : "Collapse sessions")

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // ── Version Footer ──
            Text("v1.0.0 · ZEVIS")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.bottom, 8)
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            state.startSessionRefresh()
        }
    }

    // MARK: - Pin Toggle

    private func togglePin() {
        if state.isPinned {
            state.unpinWidget()
        } else {
            state.pinWidget()
        }
    }
}

// MARK: - About Popover

struct AboutPopover: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("YOLObot")
                .font(.system(size: 16, weight: .bold))

            Text("v1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 4) {
                Text("Claude Code on Autopilot")
                    .font(.system(size: 11, weight: .medium))
                Text("Auto-approve permissions & monitor sessions")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            VStack(spacing: 2) {
                Text("Made by ZEVIS")
                    .font(.system(size: 10, weight: .medium))
                Text("github.com/zeroillri")
                    .font(.system(size: 10))
                    .foregroundColor(.blue.opacity(0.8))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Label("Dual Engine: Settings injection + UI automation", systemImage: "gearshape.2")
                Label("Session detection & task completion alerts", systemImage: "bell")
                Label("Floating widget with always-on-top", systemImage: "macwindow.on.rectangle")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 240)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: SessionInfo
    let isMonitored: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMonitored ? "eye.fill" : "folder")
                .font(.system(size: 10))
                .foregroundColor(isMonitored ? .blue : .secondary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.displayName)
                    .font(.system(size: 12, weight: isMonitored ? .semibold : .regular))
                    .lineLimit(1)

                Text(session.workingDirectory)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text("PID \(session.pid)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isMonitored ? Color.blue.opacity(0.08) : Color.clear)
        )
        .padding(.horizontal, 4)
    }
}
