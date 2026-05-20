#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$HOME/SwiftBarPlugins"

"$ROOT/scripts/backup.sh" >/dev/null

cp "$ROOT/configs/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
mkdir -p "$PLUGIN_DIR" "$HOME/.config/borders" "$HOME/.config/ghostty"
rsync -a --delete "$ROOT/configs/swiftbar/plugins/" "$PLUGIN_DIR/"
rsync -a --delete "$ROOT/configs/borders/" "$HOME/.config/borders/"
rsync -a --delete "$ROOT/configs/ghostty/" "$HOME/.config/ghostty/"

defaults write com.ameba.SwiftBar PluginDirectory -string "$PLUGIN_DIR"
defaults write com.ameba.SwiftBar HideSwiftBarIcon -bool true
defaults write com.ameba.SwiftBar Terminal -string Ghostty
defaults write com.ameba.SwiftBar Shell -string Zsh

aerospace reload-config || true
"$HOME/.config/borders/bordersrc" || true
open -a SwiftBar
open 'swiftbar://refreshallplugins' >/dev/null 2>&1 || true

echo "Applied HackermacUI configs."
