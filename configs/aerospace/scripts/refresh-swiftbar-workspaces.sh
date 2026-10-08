#!/usr/bin/env bash
set -euo pipefail

PLUGIN="${1:-00-hackermacui.3s.sh}"
DEBOUNCE_SECONDS="${AEROSPACE_SWIFTBAR_REFRESH_DEBOUNCE:-0.08}"
CACHE_DIR="${TMPDIR:-/tmp}/hackermacui-aerospace-refresh"
LOCK_DIR="$CACHE_DIR/$PLUGIN.lock"
OWNER_FILE="$LOCK_DIR/pid"

mkdir -p "$CACHE_DIR"

take_lock() {
  mkdir "$LOCK_DIR" 2>/dev/null
}

# One debounce window owns the refresh; events arriving during it coalesce into
# that single pending render instead of spawning overlapping SwiftBar refreshes.
if ! take_lock; then
  holder=""
  if [[ -f "$OWNER_FILE" ]]; then
    holder="$(<"$OWNER_FILE")"
  fi
  if [[ -n "$holder" ]] && kill -0 "$holder" 2>/dev/null; then
    exit 0
  fi
  if [[ -z "$holder" ]]; then
    # The owner may have just taken the lock and not written its pid yet;
    # give it a moment before treating an empty owner file as stale.
    lock_mtime="$(stat -f '%m' "$LOCK_DIR" 2>/dev/null || printf '0')"
    if (( $(date +%s) - lock_mtime < 1 )); then
      exit 0
    fi
  fi
  # Stale lock: the previous owner died before its trap could clean up.
  rm -rf "$LOCK_DIR"
  take_lock || exit 0
fi

cleanup() {
  rm -rf "$LOCK_DIR"
}
# Cleanup must run and the script must actually stop on INT/TERM: a bare trap
# without exit only runs the handler and lets execution continue.
trap 'cleanup; exit' EXIT INT TERM

printf '%s' "$$" >"$OWNER_FILE"

case "$DEBOUNCE_SECONDS" in
  ""|0|0.0|0.00|0.000) ;;
  *) sleep "$DEBOUNCE_SECONDS" ;;
esac

/usr/bin/open -g "swiftbar://refreshplugin?plugin=$PLUGIN" >/dev/null 2>&1 || true
