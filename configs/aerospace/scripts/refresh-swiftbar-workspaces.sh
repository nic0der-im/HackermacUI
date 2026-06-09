#!/usr/bin/env bash
set -euo pipefail

PLUGIN="${1:-00-hackermacui.3s.sh}"
DEBOUNCE_SECONDS="${AEROSPACE_SWIFTBAR_REFRESH_DEBOUNCE:-0}"
CACHE_DIR="${TMPDIR:-/tmp}/hackermacui-aerospace-refresh"
LOCK_DIR="$CACHE_DIR/$PLUGIN.lock"

mkdir -p "$CACHE_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi

cleanup() {
  rm -rf "$LOCK_DIR"
}
trap cleanup EXIT INT TERM

if [[ "$DEBOUNCE_SECONDS" != "0" && "$DEBOUNCE_SECONDS" != "0.0" && "$DEBOUNCE_SECONDS" != "0.00" ]]; then
  sleep "$DEBOUNCE_SECONDS"
fi
/usr/bin/open -g "swiftbar://refreshplugin?plugin=$PLUGIN" >/dev/null 2>&1 || true
