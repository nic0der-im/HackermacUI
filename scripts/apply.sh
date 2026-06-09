#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$HOME/SwiftBarPlugins"
STATE_DIR="$HOME/.hackermacui"
LIVE_PROFILE_FILE="$STATE_DIR/live-profile"
RENDER_DIR="$STATE_DIR/rendered"

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

PROFILE="$(profile_name)"
render_profile "$PROFILE"

"$ROOT/scripts/backup.sh" >/dev/null

mkdir -p "$PLUGIN_DIR" "$HOME/.config/aerospace/scripts" "$HOME/.config/borders" "$HOME/.config/ghostty" "$HOME/.config/fastfetch"
ln -sfn "$RENDER_DIR/aerospace.toml" "$HOME/.aerospace.toml"
rsync -a --delete "$ROOT/configs/aerospace/scripts/" "$HOME/.config/aerospace/scripts/"
cp "$RENDER_DIR/profile.env" "$HOME/.config/aerospace/scripts/profile.env"
rsync -a --delete "$ROOT/configs/swiftbar/plugins/" "$PLUGIN_DIR/"
rsync -a --delete "$ROOT/configs/borders/" "$HOME/.config/borders/"
rsync -a --delete "$ROOT/configs/ghostty/" "$HOME/.config/ghostty/"
rsync -a --delete "$ROOT/configs/fastfetch/" "$HOME/.config/fastfetch/"

defaults write com.ameba.SwiftBar PluginDirectory -string "$PLUGIN_DIR"
defaults write com.ameba.SwiftBar HideSwiftBarIcon -bool true
defaults write com.ameba.SwiftBar Terminal -string Ghostty
defaults write com.ameba.SwiftBar Shell -string Zsh

aerospace reload-config || true
"$HOME/.config/borders/bordersrc" || true
open -a SwiftBar
open 'swiftbar://refreshallplugins' >/dev/null 2>&1 || true

echo "Applied HackermacUI configs with profile: $PROFILE"
