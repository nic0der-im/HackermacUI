#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || echo "$HOME/SwiftBarPlugins")"
STATE_DIR="$HOME/.hackermacui"
LIVE_PROFILE_FILE="$STATE_DIR/live-profile"
RENDER_DIR="$STATE_DIR/rendered"

status=0

profile_name() {
  if [[ -n "${HACKERMACUI_PROFILE:-}" ]]; then
    printf '%s' "$HACKERMACUI_PROFILE"
  elif [[ -f "$LIVE_PROFILE_FILE" ]]; then
    tr -d '\n' <"$LIVE_PROFILE_FILE"
  elif [[ -f "$ROOT/configs/templates/current-profile" ]]; then
    tr -d '\n' <"$ROOT/configs/templates/current-profile"
  else
    printf 'default'
  fi
}

render_profile() {
  local profile="$1" profile_dir
  profile_dir="$ROOT/configs/templates/profiles/$profile"
  if [[ ! -f "$profile_dir/aerospace.toml" || ! -f "$profile_dir/profile.env" ]]; then
    printf 'Invalid HackermacUI profile: %s\n' "$profile" >&2
    exit 1
  fi
  mkdir -p "$RENDER_DIR"
  cp "$profile_dir/aerospace.toml" "$RENDER_DIR/aerospace.toml"
  cp "$profile_dir/profile.env" "$RENDER_DIR/profile.env"
}

check_file() {
  local label="$1" repo_file="$2" live_file="$3"
  if [[ ! -e "$repo_file" ]]; then
    echo "missing repo: $label -> $repo_file"
    status=1
    return
  fi
  if [[ ! -e "$live_file" ]]; then
    echo "missing live: $label -> $live_file"
    status=1
    return
  fi
  if cmp -s "$repo_file" "$live_file"; then
    echo "unchanged: $label"
  else
    echo "modified:  $label"
    status=1
  fi
}

dir_hash() {
  local dir="$1"
  (
    cd "$dir"
    find . -type f -print0 \
      | sort -z \
      | while IFS= read -r -d '' file; do
          shasum -a 256 "$file"
        done \
      | shasum -a 256 \
      | awk '{print $1}'
  )
}

check_dir() {
  local label="$1" repo_dir="$2" live_dir="$3"
  if [[ ! -d "$repo_dir" ]]; then
    echo "missing repo: $label -> $repo_dir"
    status=1
    return
  fi
  if [[ ! -d "$live_dir" ]]; then
    echo "missing live: $label -> $live_dir"
    status=1
    return
  fi
  local repo_hash live_hash
  repo_hash="$(dir_hash "$repo_dir")"
  live_hash="$(dir_hash "$live_dir")"
  if [[ "$repo_hash" == "$live_hash" ]]; then
    echo "unchanged: $label"
  else
    echo "modified:  $label"
    status=1
  fi
}

PROFILE="$(profile_name)"
render_profile "$PROFILE"
echo "profile: $PROFILE"

check_file "AeroSpace" "$RENDER_DIR/aerospace.toml" "$HOME/.aerospace.toml"
check_file "AeroSpace profile env" "$RENDER_DIR/profile.env" "$HOME/.config/aerospace/scripts/profile.env"
check_dir "SwiftBar plugins" "$ROOT/configs/swiftbar/plugins" "$PLUGIN_DIR"
check_file "JankyBorders" "$ROOT/configs/borders/bordersrc" "$HOME/.config/borders/bordersrc"
check_file "Ghostty" "$ROOT/configs/ghostty/config" "$HOME/.config/ghostty/config"
check_file "Fastfetch" "$ROOT/configs/fastfetch/config.json" "$HOME/.config/fastfetch/config.json"

exit "$status"
