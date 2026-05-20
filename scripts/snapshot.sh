#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$HOME/.hackermacui"
SNAPSHOT_DIR="$STATE_DIR/snapshots/$(date +%Y%m%d-%H%M%S)"
PLUGIN_DIR="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || echo "$HOME/SwiftBarPlugins")"
mkdir -p "$SNAPSHOT_DIR"

[[ -f "$HOME/.aerospace.toml" ]] && cp "$HOME/.aerospace.toml" "$SNAPSHOT_DIR/aerospace.toml"
[[ -d "$PLUGIN_DIR" ]] && rsync -a "$PLUGIN_DIR/" "$SNAPSHOT_DIR/SwiftBarPlugins/"
[[ -d "$HOME/.config/borders" ]] && rsync -a "$HOME/.config/borders/" "$SNAPSHOT_DIR/borders/"
[[ -d "$HOME/.config/ghostty" ]] && rsync -a "$HOME/.config/ghostty/" "$SNAPSHOT_DIR/ghostty/"

"$ROOT/scripts/status.sh" > "$SNAPSHOT_DIR/status.txt"

echo "Private snapshot written: $SNAPSHOT_DIR"
