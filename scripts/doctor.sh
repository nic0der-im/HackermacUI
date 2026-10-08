#!/usr/bin/env bash
set -euo pipefail

failures=0
warnings=0

pass() { printf '✓ %s\n' "$1"; }
warn() { printf '! %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '✗ %s\n' "$1"; failures=$((failures + 1)); }

need_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd found ($(command -v "$cmd"))"
  else
    fail "$cmd missing"
  fi
}

need_app() {
  local app="$1"
  if [[ -d "/Applications/$app.app" || -d "$HOME/Applications/$app.app" ]]; then
    pass "$app.app installed"
  else
    fail "$app.app missing"
  fi
}

echo "== Required commands =="
need_cmd brew
need_cmd aerospace
need_cmd borders

echo
echo "== Fonts =="
if command -v fc-list >/dev/null 2>&1; then
  # Capture first: `fc-list | grep -q` can SIGPIPE under pipefail and false-negative.
  if grep -qi 'jetbrainsmono nerd font' <<<"$(fc-list)"; then
    pass "JetBrainsMono Nerd Font found"
  else
    warn "JetBrainsMono Nerd Font not found (used by configs/ghostty/config)"
  fi
else
  if compgen -G "$HOME/Library/Fonts/*[Jj]et[Bb]rains*[Nn]erd*" >/dev/null 2>&1 \
    || compgen -G "/Library/Fonts/*[Jj]et[Bb]rains*[Nn]erd*" >/dev/null 2>&1; then
    pass "JetBrainsMono Nerd Font found"
  else
    warn "JetBrainsMono Nerd Font not found (used by configs/ghostty/config)"
  fi
fi

echo
echo "== Required apps =="
need_app AeroSpace
need_app SwiftBar
need_app Ghostty

if brew list sketchybar >/dev/null 2>&1; then
  warn "SketchyBar is installed, but HackermacUI expects SwiftBar"
else
  pass "SketchyBar removed"
fi

echo
echo "== Services/processes =="
pgrep -x AeroSpace >/dev/null && pass "AeroSpace running" || warn "AeroSpace not running"
pgrep -x SwiftBar >/dev/null && pass "SwiftBar running" || warn "SwiftBar not running"
pgrep -x borders >/dev/null && pass "borders running" || warn "borders not running"

spaces_value="$(defaults read com.apple.spaces spans-displays 2>/dev/null || echo default)"
if [[ "$spaces_value" == "1" ]]; then
  warn "Displays may not have separate Spaces enabled; check Desktop & Dock settings"
else
  pass "Displays have separate Spaces enabled or default"
fi

echo
if (( failures > 0 )); then
  echo "Doctor failed: $failures required check(s) failed, $warnings warning(s)."
  exit 1
fi

echo "Doctor passed with $warnings warning(s)."
