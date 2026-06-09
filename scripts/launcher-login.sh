#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BIN="$ROOT/dist/HackermacLauncher.app/Contents/MacOS/HackermacLauncher"
LABEL="dev.hackermacui.launcher"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

usage() {
  cat <<'EOF'
Usage: scripts/launcher-login.sh <install|uninstall|status>

Installs or removes the local HackermacLauncher LaunchAgent. Build the app first
with scripts/build-launcher-app.sh.
EOF
}

require_app() {
  if [[ ! -x "$APP_BIN" ]]; then
    printf 'Missing app binary: %s\n' "$APP_BIN" >&2
    printf 'Run ./scripts/build-launcher-app.sh first.\n' >&2
    exit 1
  fi
}

install_agent() {
  require_app
  mkdir -p "$(dirname "$PLIST")"
  cat >"$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_BIN</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HACKERMACUI_REPO</key>
    <string>$ROOT</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>/tmp/hackermaclauncher.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/hackermaclauncher.log</string>
</dict>
</plist>
PLIST

  launchctl bootout "$DOMAIN" "$PLIST" >/dev/null 2>&1 || true
  launchctl bootstrap "$DOMAIN" "$PLIST"
  launchctl enable "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  printf 'Installed launch-at-login: %s\n' "$PLIST"
}

uninstall_agent() {
  launchctl bootout "$DOMAIN" "$PLIST" >/dev/null 2>&1 || true
  rm -f "$PLIST"
  printf 'Removed launch-at-login: %s\n' "$PLIST"
}

status_agent() {
  if [[ -f "$PLIST" ]]; then
    printf 'LaunchAgent exists: %s\n' "$PLIST"
  else
    printf 'LaunchAgent not installed.\n'
  fi
  launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 && printf 'LaunchAgent loaded.\n' || printf 'LaunchAgent not loaded.\n'
}

case "${1:-}" in
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  status) status_agent ;;
  *) usage >&2; exit 1 ;;
esac
