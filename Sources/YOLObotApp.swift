import SwiftUI
import AppKit
import ApplicationServices

@main
struct YOLObotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel!
    private let yoloState = YoloState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkFirstLaunch()
        setupFloatingWidget()
    }

    /// Prompt Accessibility permission only once
    private func checkFirstLaunch() {
        let hasShownPrompt = UserDefaults.standard.bool(forKey: "hasShownAccessibilityPrompt")
        guard !hasShownPrompt, !AXIsProcessTrusted() else { return }

        UserDefaults.standard.set(true, forKey: "hasShownAccessibilityPrompt")

        let alert = NSAlert()
        alert.messageText = "YOLObot needs Accessibility permission"
        alert.informativeText = """
        YOLObot requires macOS Accessibility permission to \
        automatically handle Claude Code permission dialogs.

        Follow these steps:
        1. Click 'Open System Settings' below
        2. Toggle ON the switch next to YOLObot
        3. The app will start working automatically
        """
        alert.alertStyle = .informational
        alert.icon = NSImage(named: NSImage.applicationIconName)
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    private func setupFloatingWidget() {
        panel = FloatingPanel()
        yoloState.panel = panel

        let widgetView = WidgetView(state: yoloState)
        let hostingView = NSHostingView(rootView: widgetView)
        panel.contentView = hostingView

        // Position: top-right corner
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 280
            let y = screen.visibleFrame.maxY - 420
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
    }
}

// MARK: - Floating Panel (Always-on-top, draggable)

class FloatingPanel: NSPanel {
    static weak var shared: FloatingPanel?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 400),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow

        FloatingPanel.shared = self
    }

    // Allow the panel to become key (for button clicks)
    override var canBecomeKey: Bool { true }

    func pin() {
        print("[YOLObot] PIN → floating level")
        level = .floating
        isFloatingPanel = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        orderFront(nil)
    }

    func unpin() {
        print("[YOLObot] UNPIN → normal level")
        level = .normal
        isFloatingPanel = false
        collectionBehavior = [.fullScreenAuxiliary]
        orderBack(nil)
    }
}
