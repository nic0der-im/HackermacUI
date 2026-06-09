#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/apps/HackermacLauncher"
APP_BUNDLE="$ROOT/dist/HackermacLauncher.app"
LOG_FILE="/tmp/hackermaclauncher.log"

existing_pids="$(pgrep -f 'HackermacLauncher' || true)"
if [[ -n "$existing_pids" ]]; then
  /bin/kill -TERM $existing_pids 2>/dev/null || true
  sleep 0.4
fi

if [[ -x "$APP_BUNDLE/Contents/MacOS/HackermacLauncher" ]]; then
  /usr/bin/nohup /usr/bin/env HACKERMACUI_REPO="$ROOT" "$APP_BUNDLE/Contents/MacOS/HackermacLauncher" >"$LOG_FILE" 2>&1 </dev/null &
else
  /usr/bin/nohup /usr/bin/env swift run --package-path "$APP_DIR" HackermacLauncher >"$LOG_FILE" 2>&1 </dev/null &
fi
