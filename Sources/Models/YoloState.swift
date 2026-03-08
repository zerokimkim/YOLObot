import Foundation
import SwiftUI
import AppKit

@MainActor
final class YoloState: ObservableObject {
    @Published var isOn = false
    @Published var sessions: [SessionInfo] = []
    @Published var monitoredSessionId: String?
    @Published var statusMessage = "YOLO OFF"
    @Published var isPinned = true
    @Published var isSessionsCollapsed = false
    @Published var isMinimized = false

    /// Direct panel reference
    weak var panel: NSPanel?

    private let sessionDetector = SessionDetector()
    private let permissionManager = PermissionManager()
    private let uiAutomator = UIAutomator()
    private let taskMonitor = TaskMonitor()
    private let notifier = Notifier()
    private var refreshTimer: Timer?

    func pinWidget() {
        guard let panel = panel else {
            print("[YOLObot] pinWidget: panel is NIL!")
            return
        }
        isPinned = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.orderFront(nil)
        print("[YOLObot] PIN level=\(panel.level.rawValue)")
    }

    func unpinWidget() {
        guard let panel = panel else {
            print("[YOLObot] unpinWidget: panel is NIL!")
            return
        }
        isPinned = false
        panel.level = .normal
        panel.isFloatingPanel = false
        panel.collectionBehavior = [.managed, .fullScreenAuxiliary]
        panel.orderBack(nil)
        print("[YOLObot] UNPIN level=\(panel.level.rawValue)")
    }

    // MARK: - Minimize / Restore

    private var savedFrame: NSRect?

    func minimizeWidget() {
        guard let panel = panel else { return }
        savedFrame = panel.frame
        isMinimized = true

        // Animate to mini bar at bottom-right
        if let screen = NSScreen.main {
            let miniWidth: CGFloat = 220
            let miniHeight: CGFloat = 40
            let x = screen.visibleFrame.maxX - miniWidth - 16
            let y = screen.visibleFrame.minY + 16
            let miniFrame = NSRect(x: x, y: y, width: miniWidth, height: miniHeight)

            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(miniFrame, display: true)
            })
        }
        print("[YOLObot] Minimized to bottom bar")
    }

    func restoreWidget() {
        guard let panel = panel else { return }
        isMinimized = false

        let targetFrame = savedFrame ?? {
            if let screen = NSScreen.main {
                let x = screen.visibleFrame.maxX - 280
                let y = screen.visibleFrame.maxY - 420
                return NSRect(x: x, y: y, width: 260, height: 400)
            }
            return NSRect(x: 100, y: 100, width: 260, height: 400)
        }()

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        })
        print("[YOLObot] Restored to full view")
    }

    func toggle() {
        if !isOn {
            showDisclaimerThenActivate()
        } else {
            isOn = false
            deactivateYolo()
        }
    }

    private func showDisclaimerThenActivate() {
        let alert = NSAlert()
        alert.messageText = "⚠️ YOLO Mode Disclaimer"
        alert.informativeText = """
        YOLObot is designed for convenience by automating Claude Code's \
        permission approval process.

        By enabling YOLO mode, you acknowledge that:

        • All confirmation dialogs will be automatically approved
        • File edits, command execution, and network access may proceed without review
        • You assume full responsibility for any consequences

        The authors of YOLObot accept no liability for any damages, data loss, \
        or unintended actions resulting from the use of this tool.

        Proceed at your own risk.
        """
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: "I Understand, Enable YOLO")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            isOn = true
            activateYolo()
        }
    }

    func startSessionRefresh() {
        refreshSessions()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshSessions()
            }
        }
    }

    func stopSessionRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func refreshSessions() {
        sessions = sessionDetector.detectActiveSessions()
    }

    private func activateYolo() {
        DebugLog.clear()
        DebugLog.log("activateYolo: sessions.count=\(sessions.count)")
        statusMessage = "Injecting permissions..."

        // Engine A: Modify settings.json
        let injected = permissionManager.injectYoloPermissions()
        if injected {
            statusMessage = "YOLO ON — Permissions injected"
        } else {
            statusMessage = "YOLO ON — Injection failed, UI auto only"
        }

        // Engine B: Start UI automation
        uiAutomator.startMonitoring()

        // Monitor: Start session monitoring
        startSessionMonitoring()
    }

    private func startSessionMonitoring() {
        DebugLog.log("startSessionMonitoring: sessions.count=\(sessions.count)")
        if let session = sessions.first {
            DebugLog.log("Monitoring: \(session.displayName) PID=\(session.pid) sid=\(session.sessionId)")
            monitoredSessionId = session.sessionId
            taskMonitor.startMonitoring(session: session) { [weak self] completedSession in
                Task { @MainActor in
                    self?.notifier.sendCompletion(session: completedSession)
                    self?.statusMessage = "Done! — YOLO ON"
                }
            }
        }
    }

    private func deactivateYolo() {
        // Engine A: Restore settings.json
        permissionManager.restoreOriginalPermissions()

        // Engine B: Stop UI automation
        uiAutomator.stopMonitoring()

        // Monitor: Stop session monitoring
        taskMonitor.stopMonitoring()

        monitoredSessionId = nil
        statusMessage = "YOLO OFF"
    }
}
