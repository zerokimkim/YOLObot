import Foundation
import AppKit
import ApplicationServices

final class UIAutomator {
    private var timer: Timer?
    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Check accessibility permission (prompt is handled once at first launch)
        if !checkAccessibilityPermission() {
            print("YOLObot: Accessibility permission not granted. Enable in System Settings > Privacy & Security > Accessibility")
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForPermissionDialogs()
        }
        print("YOLObot: UI Automator started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("YOLObot: UI Automator stopped")
    }

    // MARK: - Accessibility Permission

    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    private func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Permission Dialog Detection

    private func checkForPermissionDialogs() {
        guard let claudePID = findClaudePID() else { return }

        let appElement = AXUIElementCreateApplication(claudePID)

        // Get all windows
        var windowsValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        guard result == .success, let windows = windowsValue as? [AXUIElement] else { return }

        for window in windows {
            scanForAllowButton(in: window)
        }
    }

    private func findClaudePID() -> pid_t? {
        let apps = NSWorkspace.shared.runningApplications
        for app in apps {
            if app.bundleIdentifier == "com.anthropic.claudedesktop" ||
               app.localizedName == "Claude" {
                return app.processIdentifier
            }
        }
        return nil
    }

    // MARK: - Button Scanning

    private func scanForAllowButton(in element: AXUIElement) {
        // Get role
        var roleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String

        // Get title/label
        var titleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        let title = titleValue as? String ?? ""

        // Get description
        var descValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)
        let desc = descValue as? String ?? ""

        // Check if this is an "Allow" button
        let allowPatterns = ["Allow", "Yes", "Approve", "Accept", "허용", "확인",
                             "Allow once", "Allow for this session", "Always allow"]
        if role == kAXButtonRole as String {
            let combined = "\(title) \(desc)".lowercased()
            for pattern in allowPatterns {
                if combined.contains(pattern.lowercased()) {
                    clickButton(element)
                    print("YOLObot: Auto-clicked '\(title.isEmpty ? desc : title)' button")
                    return
                }
            }
        }

        // Recursively scan children
        var childrenValue: CFTypeRef?
        let childResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        guard childResult == .success, let children = childrenValue as? [AXUIElement] else { return }

        for child in children {
            scanForAllowButton(in: child)
        }
    }

    private func clickButton(_ button: AXUIElement) {
        AXUIElementPerformAction(button, kAXPressAction as CFString)
    }
}
