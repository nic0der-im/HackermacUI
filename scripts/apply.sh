#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/swiftbar-plugin-dir.sh
source "$ROOT/scripts/lib/swiftbar-plugin-dir.sh"
PLUGIN_DIR="$(swiftbar_plugin_dir)"
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

validate_profile_name() {
  local profile="$1"
  if [[ ! "$profile" =~ ^[A-Za-z0-9_-]+$ ]]; then
    printf 'Invalid HackermacUI profile name: %s\n' "$profile" >&2
    exit 1
  fi
}

same_path() {
  local a="$1" b="$2"
  [[ -d "$a" && -d "$b" ]] || return 1
  [[ "$(cd "$a" && pwd -P)" == "$(cd "$b" && pwd -P)" ]]
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
validate_profile_name "$PROFILE"
render_profile "$PROFILE"

"$ROOT/scripts/backup.sh" >/dev/null

mkdir -p "$HOME/.config/aerospace/scripts" "$HOME/.config/borders" "$HOME/.config/ghostty" "$HOME/.config/fastfetch" "$HOME/.config/hackermacui/theme"
ln -sfn "$RENDER_DIR/aerospace.toml" "$HOME/.aerospace.toml"
rsync -a --delete "$ROOT/configs/aerospace/scripts/" "$HOME/.config/aerospace/scripts/"
cp "$RENDER_DIR/profile.env" "$HOME/.config/aerospace/scripts/profile.env"
if same_path "$ROOT/configs/swiftbar/plugins" "$PLUGIN_DIR"; then
  echo "SwiftBar PluginDirectory already points at the repo; skipping plugin sync."
else
  mkdir -p "$PLUGIN_DIR"
  rsync -a --delete "$ROOT/configs/swiftbar/plugins/" "$PLUGIN_DIR/"
fi
rsync -a --delete "$ROOT/configs/borders/" "$HOME/.config/borders/"
rsync -a --delete "$ROOT/configs/ghostty/" "$HOME/.config/ghostty/"
rsync -a --delete "$ROOT/configs/fastfetch/" "$HOME/.config/fastfetch/"
# Shared theme palette consumed by bordersrc, the SwiftBar plugins, and the
# JXA strip renderer; see configs/theme/palette.env.
rsync -a --delete "$ROOT/configs/theme/" "$HOME/.config/hackermacui/theme/"

defaults write com.ameba.SwiftBar PluginDirectory -string "$PLUGIN_DIR"
defaults write com.ameba.SwiftBar HideSwiftBarIcon -bool true
defaults write com.ameba.SwiftBar Terminal -string Ghostty
defaults write com.ameba.SwiftBar Shell -string Zsh

aerospace reload-config || true
# borders runs its draw loop in the foreground; background it the same way
# AeroSpace's after-startup-command (exec-and-forget) does, so apply.sh does
# not hang waiting for it.
("$HOME/.config/borders/bordersrc" >/dev/null 2>&1 &) || true
open -a SwiftBar
open 'swiftbar://refreshallplugins' >/dev/null 2>&1 || true

echo "Applied HackermacUI configs with profile: $PROFILE"
