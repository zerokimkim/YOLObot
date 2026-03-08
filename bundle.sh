#!/bin/zsh
set -e

APP_NAME="YOLObot"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS="$BUNDLE_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

cd "$(dirname "$0")"

echo "🔨 Building $APP_NAME (release)..."
swift build -c release 2>&1

echo "📦 Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp .build/release/$APP_NAME "$MACOS/$APP_NAME"

# Copy icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES/AppIcon.icns"
    echo "✅ Icon applied"
else
    echo "⚠️  AppIcon.icns not found, skipping icon"
fi

# Copy Claude icon for button animation
if [ -f "claude_icon.png" ]; then
    cp claude_icon.png "$RESOURCES/claude_icon.png"
    echo "✅ Claude icon bundled"
fi

# Copy completion sound effect
if [ -f "complete.aiff" ]; then
    cp complete.aiff "$RESOURCES/complete.aiff"
    echo "✅ Completion sound bundled"
fi

# Info.plist with icon reference
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>YOLObot</string>
    <key>CFBundleIdentifier</key>
    <string>com.zevis.yolobot</string>
    <key>CFBundleName</key>
    <string>YOLO zerobot</string>
    <key>CFBundleDisplayName</key>
    <string>YOLO zerobot</string>
    <key>CFBundleVersion</key>
    <string>1.4.1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.4.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>YOLObot needs Apple Events to send notifications.</string>
</dict>
</plist>
PLIST

# Code sign with entitlements
if [ -f "YOLObot.entitlements" ]; then
    codesign --force --sign - --entitlements YOLObot.entitlements "$BUNDLE_DIR" 2>/dev/null || true
    echo "✅ Signed with entitlements"
else
    codesign --force --sign - "$BUNDLE_DIR" 2>/dev/null || true
    echo "⚠️  Signed without entitlements"
fi

echo ""
echo "==================================="
echo " ✅ $APP_NAME.app 생성 완료!"
echo "==================================="
echo ""
echo "실행: open $BUNDLE_DIR"
