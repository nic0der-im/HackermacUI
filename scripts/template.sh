#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_ROOT="$ROOT/configs/templates/profiles"
CURRENT_FILE="$ROOT/configs/templates/current-profile"
STATE_DIR="$HOME/.hackermacui"
LIVE_PROFILE_FILE="$STATE_DIR/live-profile"

usage() {
  cat <<'EOF'
Usage: scripts/template.sh <command> [profile] [--reload]

Commands:
  list                 List available profiles.
  current              Print the selected profile.
  render <profile>     Render profile files into active repo config.
  switch <profile>     Backup, render, and select a profile.
  activate <profile>   Select a live profile under ~/.hackermacui.
  live                 Print the selected live profile.
  deactivate           Remove the live profile override.

Options:
  --reload             After switch, reload AeroSpace and refresh SwiftBar.

Profiles are repo templates. Switching mutates active repo config files; it does
not run scripts/apply.sh.
EOF
}

profile_path() {
  local profile="$1"
  printf '%s/%s' "$PROFILE_ROOT" "$profile"
}

require_profile() {
  local profile="$1" path
  path="$(profile_path "$profile")"
  if [[ ! -d "$path" ]]; then
    printf 'Unknown profile: %s\n' "$profile" >&2
    exit 1
  fi
  if [[ ! -f "$path/aerospace.toml" || ! -f "$path/profile.env" ]]; then
    printf 'Invalid profile: %s\n' "$profile" >&2
    exit 1
  fi
}

render_profile() {
  local profile="$1" path
  require_profile "$profile"
  path="$(profile_path "$profile")"
  cp "$path/aerospace.toml" "$ROOT/configs/aerospace/aerospace.toml"
  cp "$path/profile.env" "$ROOT/configs/aerospace/scripts/profile.env"
  if [[ -f "$path/launcher.menu.json" ]]; then
    cp "$path/launcher.menu.json" "$ROOT/configs/launcher/menu.json"
  fi
  printf '%s\n' "$profile" >"$CURRENT_FILE"
  printf 'Rendered profile: %s\n' "$profile"
}

activate_profile() {
  local profile="$1"
  require_profile "$profile"
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$profile" >"$LIVE_PROFILE_FILE"
  printf 'Activated live profile: %s\n' "$profile"
  printf 'Run ./scripts/apply.sh to apply it.\n'
}

reload_profile() {
  if command -v aerospace >/dev/null 2>&1; then
    aerospace reload-config || true
  fi
  /usr/bin/open 'swiftbar://refreshallplugins' >/dev/null 2>&1 || true
}

command="${1:-}"
profile="${2:-}"
reload=0

case "${3:-}" in
  --reload) reload=1 ;;
  "") ;;
  *) usage >&2; exit 1 ;;
esac

case "$command" in
  list)
    find "$PROFILE_ROOT" -mindepth 1 -maxdepth 1 -type d -print | sort | while IFS= read -r path; do
      basename "$path"
    done
    ;;
  current)
    if [[ -f "$CURRENT_FILE" ]]; then
      tr -d '\n' <"$CURRENT_FILE"
      printf '\n'
    else
      printf 'default\n'
    fi
    ;;
  live)
    if [[ -f "$LIVE_PROFILE_FILE" ]]; then
      tr -d '\n' <"$LIVE_PROFILE_FILE"
      printf '\n'
    else
      printf 'default\n'
    fi
    ;;
  render)
    [[ -n "$profile" ]] || { usage >&2; exit 1; }
    render_profile "$profile"
    ;;
  activate)
    [[ -n "$profile" ]] || { usage >&2; exit 1; }
    activate_profile "$profile"
    ;;
  deactivate)
    rm -f "$LIVE_PROFILE_FILE"
    printf 'Removed live profile override.\n'
    ;;
  switch)
    [[ -n "$profile" ]] || { usage >&2; exit 1; }
    "$ROOT/scripts/backup.sh" >/dev/null
    render_profile "$profile"
    if [[ "$reload" == "1" ]]; then
      reload_profile
      printf 'Reloaded AeroSpace and refreshed SwiftBar.\n'
    else
      printf 'Run aerospace reload-config or pass --reload to apply it live.\n'
    fi
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
