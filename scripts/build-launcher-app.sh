#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/apps/HackermacLauncher"
DIST_DIR="$ROOT/dist"
APP_BUNDLE="$DIST_DIR/HackermacLauncher.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
VERSION="${HACKERMACUI_LAUNCHER_VERSION:-0.1.0}"

mkdir -p "$MACOS_DIR"

swift build -c release --package-path "$APP_DIR"
BIN_DIR="$(swift build -c release --package-path "$APP_DIR" --show-bin-path)"
cp "$BIN_DIR/HackermacLauncher" "$MACOS_DIR/HackermacLauncher"
chmod 755 "$MACOS_DIR/HackermacLauncher"

cat >"$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>HackermacLauncher</string>
  <key>CFBundleExecutable</key>
  <string>HackermacLauncher</string>
  <key>CFBundleIdentifier</key>
  <string>dev.hackermacui.launcher</string>
  <key>CFBundleName</key>
  <string>HackermacLauncher</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

printf 'Built %s\n' "$APP_BUNDLE"
