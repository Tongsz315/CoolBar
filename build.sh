#!/bin/bash
set -e

echo "🔨 Building CoolBar..."

cd "$(dirname "$0")"

# Kill existing instance
pkill -f "CoolBar.app" 2>/dev/null || true

# Clear stale NSStatusItem visibility cache so the icon is not hidden by system UI.
# macOS caches per-autosaveName visibility in com.apple.controlcenter / com.apple.systemuiserver.
echo "🧹 Clearing NSStatusItem cache..."
defaults delete com.apple.controlcenter "NSStatusItem Visible com.coolbar.statusItem" 2>/dev/null || true
defaults delete com.apple.controlcenter "NSStatusItem Visible com.coolbar.statusItem.v2" 2>/dev/null || true
defaults delete com.apple.systemuiserver "NSStatusItem Visible com.coolbar.statusItem" 2>/dev/null || true
defaults delete com.apple.systemuiserver "NSStatusItem Visible com.coolbar.statusItem.v2" 2>/dev/null || true

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

# Info.plist (use Resources/Info.plist as the single source of truth)
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"

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
rm -rf /Applications/CoolBar.app
cp -R "$APP_DIR" /Applications/CoolBar.app
codesign --force --deep --sign - /Applications/CoolBar.app 2>/dev/null

echo "🚀 Launching CoolBar..."
open /Applications/CoolBar.app

echo ""
echo "======== CoolBar Ready ========"
echo "  菜单栏: 左键详情 | 右键菜单"
echo "  DMG:    $DMG_PATH"
echo "==============================="
