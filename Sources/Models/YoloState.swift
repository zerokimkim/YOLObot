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
        if let session = sessions.first {
            monitoredSessionId = session.sessionId
            taskMonitor.startMonitoring(session: session) { [weak self] completedSession in
                Task { @MainActor in
                    self?.notifier.sendCompletion(session: completedSession)
                    self?.statusMessage = "Done: \(completedSession.displayName)"
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
