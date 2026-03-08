#!/bin/zsh
set -e

APP_NAME="YOLObot"
DMG_NAME="${APP_NAME}_v1.4.0.dmg"
DMG_TEMP="dmg_temp"
VOLUME_NAME="YOLO zerobot v1.4.0"

cd "$(dirname "$0")"

# Build first if .app doesn't exist
if [ ! -d "$APP_NAME.app" ]; then
    echo "📦 App bundle not found, building first..."
    ./bundle.sh
fi

echo "💿 Creating DMG installer..."

# Clean up
rm -rf "$DMG_TEMP" "$DMG_NAME"
mkdir -p "$DMG_TEMP"

# Copy app
cp -R "$APP_NAME.app" "$DMG_TEMP/"

# Create Applications symlink (for drag-to-install)
ln -s /Applications "$DMG_TEMP/Applications"

# Create README
cat > "$DMG_TEMP/README.txt" << 'README'
═══════════════════════════════════════
  YOLO zerobot v1.4.0
  Installation Guide
═══════════════════════════════════════

1. Drag YOLObot.app into the Applications folder

2. On first launch, you may see an "unidentified developer" warning:
   → Right-click (or Control+click) YOLObot.app → Select "Open"
   → Click "Open" to confirm

3. Grant Accessibility permission:
   → System Settings > Privacy & Security > Accessibility
   → Toggle ON the switch next to YOLO zerobot

4. Done! The floating widget appears in the top-right corner.

═══════════════════════════════════════
  System Requirements
═══════════════════════════════════════
• macOS 13.0 (Ventura) or later
• Apple Silicon or Intel Mac
• Claude Code CLI installed

═══════════════════════════════════════
  Usage
═══════════════════════════════════════
• YOLO ON  → Auto-approve Claude Code permissions
• YOLO OFF → Restore original settings
• Pin      → Toggle always-on-top
• Mini     → Minimize to bottom bar
• Telegram → Get notified on your phone

═══════════════════════════════════════
  Author
═══════════════════════════════════════
Made by ZEVIS
github.com/zerokimkim/YOLObot
README

# Create DMG
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_NAME" 2>&1

# Clean up temp
rm -rf "$DMG_TEMP"

# Get file size
DMG_SIZE=$(du -sh "$DMG_NAME" | cut -f1)

echo ""
echo "═══════════════════════════════════════"
echo " ✅ DMG Installer Created!"
echo "═══════════════════════════════════════"
echo ""
echo " File: $DMG_NAME"
echo " Size: $DMG_SIZE"
echo ""
echo " Distribute this DMG file."
echo " Users open the DMG and drag the app"
echo " to Applications to install."
echo ""
