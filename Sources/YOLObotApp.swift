import SwiftUI
import AppKit
import ApplicationServices
import ObjectiveC

@main
struct YOLObotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .frame(width: 420, height: 500)
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel!
    private let yoloState = YoloState()
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        swizzleSystemHelp()
        checkFirstLaunch()
        setupFloatingWidget()
        setupCustomMenu()
        setupEditingShortcuts()

        // Listen for Settings open request from widget
        NotificationCenter.default.addObserver(
            self, selector: #selector(showSettings),
            name: .init("ShowSettings"), object: nil
        )

        // Listen for Help open request (from swizzled NSApplication.showHelp)
        NotificationCenter.default.addObserver(
            self, selector: #selector(showHelpWindow),
            name: .init("ShowHelp"), object: nil
        )
    }

    // MARK: - Swizzle NSApplication.showHelp (prevents "Help isn't available" dialog)

    private func swizzleSystemHelp() {
        let originalSel = #selector(NSApplication.showHelp(_:))
        let swizzledSel = #selector(NSApplication.yolobot_showHelp(_:))

        guard let originalMethod = class_getInstanceMethod(NSApplication.self, originalSel),
              let swizzledMethod = class_getInstanceMethod(NSApplication.self, swizzledSel) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    // MARK: - Global Editing Shortcuts (intercepts ⌘V BEFORE menu system)

    private func setupEditingShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
                  let chars = event.charactersIgnoringModifiers,
                  ["v", "c", "x", "a"].contains(chars) else {
                return event
            }

            // Try direct NSTextView first
            if let window = NSApp.keyWindow,
               let textView = window.firstResponder as? NSTextView {
                switch chars {
                case "v": textView.paste(nil)
                case "c": textView.copy(nil)
                case "x": textView.cut(nil)
                case "a": textView.selectAll(nil)
                default: break
                }
                return nil
            }

            // Fallback: notify SwiftUI to handle paste directly
            if chars == "v" {
                NotificationCenter.default.post(name: .init("YOLObotPaste"), object: nil)
                return nil
            }
            if chars == "a" {
                NotificationCenter.default.post(name: .init("YOLObotSelectAll"), object: nil)
                return nil
            }

            return nil // consume all ⌘+key to prevent system beep
        }
    }

    // MARK: - Accessibility Prompt (first launch only)

    private func checkFirstLaunch() {
        let hasShownPrompt = UserDefaults.standard.bool(forKey: "hasShownAccessibilityPrompt")
        guard !hasShownPrompt, !AXIsProcessTrusted() else { return }

        UserDefaults.standard.set(true, forKey: "hasShownAccessibilityPrompt")

        let alert = NSAlert()
        alert.messageText = "YOLO zerobot needs Accessibility permission"
        alert.informativeText = """
        YOLO zerobot requires macOS Accessibility permission to \
        automatically handle Claude Code permission dialogs.

        Follow these steps:
        1. Click 'Open System Settings' below
        2. Toggle ON the switch next to YOLO zerobot
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

    // MARK: - Floating Widget

    private func setupFloatingWidget() {
        panel = FloatingPanel()
        yoloState.panel = panel

        let widgetView = WidgetView(state: yoloState)
        let hostingView = NSHostingView(rootView: widgetView)
        panel.contentView = hostingView

        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 280
            let y = screen.visibleFrame.maxY - 420
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
    }

    // MARK: - Custom Menu Bar

    private func setupCustomMenu() {
        let mainMenu = NSMenu()

        // ── YOLObot Menu ──
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About YOLO zerobot",
                        action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Settings...",
                        action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide YOLO zerobot",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit YOLO zerobot",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // ── Edit Menu (for ⌘C/⌘V/⌘X in text fields) ──
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "")

        mainMenu.addItem(editMenuItem)

        // ── Help Menu ──
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "How to Use YOLO zerobot",
                         action: #selector(showHelpWindow), keyEquivalent: "")
        helpMenu.addItem(withTitle: "Telegram Setup Guide",
                         action: #selector(showTelegramGuide), keyEquivalent: "")
        helpMenu.addItem(.separator())
        helpMenu.addItem(withTitle: "Accessibility Settings",
                         action: #selector(openAccessibility), keyEquivalent: "")
        helpMenu.addItem(withTitle: "Open Config Folder",
                         action: #selector(openConfigFolder), keyEquivalent: "")
        helpMenu.addItem(.separator())
        helpMenu.addItem(withTitle: "GitHub Repository",
                         action: #selector(openGitHub), keyEquivalent: "")

        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
        // Register our Help menu so macOS routes showHelp: to us
        NSApp.helpMenu = helpMenu
    }

    // MARK: - Menu Actions

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "YOLO zerobot v1.3.8"
        alert.informativeText = """
        Claude Code on Autopilot

        Auto-approve permission dialogs and monitor sessions \
        so you can let Claude Code run unattended.

        • Dual Engine: Settings injection + UI automation
        • Session detection & task completion alerts
        • Telegram notifications
        • Floating widget with minimize support

        Made by ZEVIS
        github.com/zerokimkim/YOLObot
        """
        alert.alertStyle = .informational
        alert.icon = NSImage(named: NSImage.applicationIconName)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func showSettings() {
        // Use SwiftUI's built-in Settings scene — v1.3.8
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    // Override macOS system showHelp: so our window opens instead of "Help isn't available"
    @objc func showHelp(_ sender: Any?) {
        showHelpWindow()
    }

    @objc private func showHelpWindow() {
        if let window = helpWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let helpView = HelpView()
        let hostingView = NSHostingView(rootView: helpView)

        let window = EditableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "YOLO zerobot Help"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        helpWindow = window

        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func showTelegramGuide() {
        let alert = NSAlert()
        alert.messageText = "Telegram Setup Guide"
        alert.informativeText = """
        Get notified on your phone when tasks complete!

        Step 1: Create a Telegram Bot
        • Open Telegram → search @BotFather
        • Send /newbot → follow the prompts
        • Copy the Bot Token

        Step 2: Get Your Chat ID
        • Send any message to your new bot
        • Visit in browser:
          api.telegram.org/bot<TOKEN>/getUpdates
        • Find "chat":{"id": YOUR_CHAT_ID}

        Step 3: Configure in YOLO zerobot
        • Go to Settings (⌘,)
        • Paste Bot Token and Chat ID
        • Toggle "Enable" ON
        • Click "Send Test" to verify

        That's it! You'll now receive Telegram alerts.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Close")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showSettings()
        }
    }

    @objc private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func openConfigFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let configDir = "\(home)/.yolobot"
        // Create dir if needed
        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(URL(fileURLWithPath: configDir))
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/zerokimkim/YOLObot")!)
    }
}

// MARK: - Editable Window (fixes ⌘V paste in SwiftUI TextField)

class EditableWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "x":
                if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
            case "c":
                if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
            case "v":
                if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
            case "a":
                if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) { return true }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
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

    override var canBecomeKey: Bool { true }

    func pin() {
        level = .floating
        isFloatingPanel = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        orderFront(nil)
    }

    func unpin() {
        level = .normal
        isFloatingPanel = false
        collectionBehavior = [.fullScreenAuxiliary]
        orderBack(nil)
    }
}

// MARK: - NSApplication Help Override (swizzled at launch)

extension NSApplication {
    @objc func yolobot_showHelp(_ sender: Any?) {
        // Instead of "Help isn't available" dialog, open our custom Help window
        NotificationCenter.default.post(name: .init("ShowHelp"), object: nil)
    }
}
