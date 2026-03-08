# YOLObot

**Claude Code on Autopilot** — A macOS floating widget that auto-approves Claude Code permission dialogs so you can run unattended.

## Features

- **Dual Engine Architecture**
  - **Engine A (Settings Injection):** Modifies `~/.claude/settings.json` to pre-approve tool permissions
  - **Engine B (UI Automation):** Uses macOS Accessibility API to auto-click "Allow" buttons in real-time

- **Session Monitoring:** Detects active Claude Code sessions and monitors task completion
- **Completion Notifications:**
  - macOS system notification
  - Custom completion sound effect
  - Telegram Bot alerts (get notified on your phone)
- **Floating Widget:** Always-on-top draggable panel with pin/unpin/minimize
- **Settings UI:** Built-in settings window for Telegram configuration (⌘,)

## Requirements

- macOS 13.0+
- Swift 5.9+
- **Accessibility Permission** — Required for UI automation (prompted on first launch)

## Quick Start

### Build & Run (Local)

```bash
cd YOLObot
bash bundle.sh
open YOLObot.app
```

### Install via DMG

```bash
bash create_dmg.sh
# Opens YOLObot_v1.4.0.dmg — drag to Applications
```

## Usage

1. **Launch YOLObot** — The floating widget appears in the top-right corner
2. **Grant Accessibility Permission** — Follow the first-launch prompt (one-time only)
3. **Click "YOLO ON"** — Both engines activate:
   - Settings are injected for tool auto-approval
   - UI automation begins scanning for permission dialogs
4. **Click "YOLO OFF"** — Everything reverts:
   - Original settings.json is restored
   - UI automation stops

## Widget Controls

| Control | Description |
|---------|-------------|
| **YOLO ON / OFF** | Main toggle — activates/deactivates both engines |
| **Pin** | Toggle always-on-top floating behavior |
| **Minimize** | Shrink widget to a slim bottom bar |
| **Refresh** | Re-scan for active Claude Code sessions |
| **Collapse** | Hide/show the sessions list |
| **Settings (⌘,)** | Configure Telegram notifications |
| **Quit** | Exit YOLObot (restores original settings) |

## Telegram Notifications

Get notified on your phone when Claude Code tasks complete.

### Setup

1. Create a Telegram bot via [@BotFather](https://t.me/BotFather)
2. Get your Chat ID from [@userinfobot](https://t.me/userinfobot)
3. Open YOLObot Settings (⌘,) and enter your Bot Token + Chat ID
4. Click "Test" to verify

Each user sets up their own bot — no shared API keys or costs.

## How It Works

```
┌─────────────────────────────────────┐
│           YOLObot Widget            │
├─────────────────────────────────────┤
│                                     │
│  Engine A: PermissionManager        │
│  ├─ Backs up settings.json          │
│  ├─ Injects allow-all permissions   │
│  └─ Restores on YOLO OFF            │
│                                     │
│  Engine B: UIAutomator              │
│  ├─ Polls every 0.5s                │
│  ├─ Scans Claude windows via AX API │
│  └─ Auto-clicks Allow/Yes/Approve   │
│                                     │
│  Monitor: TaskMonitor               │
│  ├─ Tracks session activity + CPU   │
│  └─ Sends notification on complete  │
│                                     │
│  Notifier                           │
│  ├─ macOS notification              │
│  ├─ Completion sound effect         │
│  └─ Telegram Bot message            │
│                                     │
└─────────────────────────────────────┘
```

## Project Structure

```
YOLObot/
├── Sources/
│   ├── YOLObotApp.swift          # App entry, AppDelegate, FloatingPanel
│   ├── Views/
│   │   ├── WidgetView.swift      # SwiftUI floating widget UI
│   │   ├── SettingsView.swift    # Telegram settings window
│   │   └── HelpView.swift        # Help & info window
│   ├── Models/
│   │   ├── YoloState.swift       # Central state management
│   │   └── SessionInfo.swift     # Session data model
│   ├── Services/
│   │   ├── PermissionManager.swift  # Engine A — settings.json injection
│   │   ├── UIAutomator.swift        # Engine B — AX API auto-clicking
│   │   ├── SessionDetector.swift    # Claude Code process detection
│   │   ├── TaskMonitor.swift        # Task completion monitoring
│   │   ├── Notifier.swift           # macOS notifications + sound
│   │   └── TelegramNotifier.swift   # Telegram Bot notifications
│   └── Helpers/
│       ├── ShellExecutor.swift   # Shell command wrapper
│       ├── FileWatcher.swift     # File monitoring
│       └── DebugLog.swift        # Debug file logging
├── Package.swift
├── bundle.sh                     # Build + .app bundle script
├── create_dmg.sh                 # DMG installer creation
├── YOLObot.entitlements
├── AppIcon.icns
├── claude_icon.png
└── complete.aiff                 # Task completion sound effect
```

## Changelog

### v1.4.0
- Completion sound effect on task finish
- Telegram Bot notification support
- Settings UI for Telegram configuration (⌘,)
- Help window with usage guide
- Minimize-to-bottom-bar mode
- Improved task completion detection (CPU + session activity)
- Debug logging for troubleshooting

### v1.0.0
- Initial release
- Dual engine architecture (Settings Injection + UI Automation)
- Floating widget with pin/unpin
- Session detection and monitoring

## License

MIT

## Author

**ZEVIS** — [github.com/zerokimkim](https://github.com/zerokimkim)
