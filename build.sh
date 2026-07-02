#!/bin/bash
set -e

echo "🔨 Building CoolBar..."

cd "$(dirname "$0")"

# Kill existing instance
pkill -f "CoolBar.app" 2>/dev/null || true

# Build with SPM (release)
swift build -c release 2>&1

# Create .app bundle
APP_DIR="build/CoolBar.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/arm64-apple-macosx/release/CoolBar "$APP_DIR/Contents/MacOS/CoolBar"

# PkgInfo
echo -n 'APPL????' > "$APP_DIR/Contents/PkgInfo"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleDisplayName</key>
	<string>CoolBar</string>
	<key>CFBundleExecutable</key>
	<string>CoolBar</string>
	<key>CFBundleIdentifier</key>
	<string>com.coolbar.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>CoolBar</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLISTEOF

# Ad-hoc code sign
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null

echo "✅ Build complete: $APP_DIR"

# Create DMG
DMG_PATH="build/CoolBar.dmg"
STAGING="/tmp/coolbar_dmg_$$"
rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "CoolBar" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH" 2>/dev/null
rm -rf "$STAGING"

echo "📦 DMG created: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"

# Install & Launch
echo "📋 Installing to /Applications..."
cp -R "$APP_DIR" /Applications/CoolBar.app
codesign --force --deep --sign - /Applications/CoolBar.app 2>/dev/null

echo "🚀 Launching CoolBar..."
open /Applications/CoolBar.app

echo ""
echo "======== CoolBar Ready ========"
echo "  菜单栏: 左键详情 | 右键菜单"
echo "  DMG:    $DMG_PATH"
echo "==============================="
