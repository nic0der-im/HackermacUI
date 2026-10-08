#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/swiftbar-plugin-dir.sh
source "$ROOT/scripts/lib/swiftbar-plugin-dir.sh"
STATE_DIR="$HOME/.hackermacui"
SNAPSHOT_DIR="$STATE_DIR/snapshots/$(date +%Y%m%d-%H%M%S)"
PLUGIN_DIR="$(swiftbar_plugin_dir)"
mkdir -p "$SNAPSHOT_DIR"

[[ -f "$HOME/.aerospace.toml" ]] && cp "$HOME/.aerospace.toml" "$SNAPSHOT_DIR/aerospace.toml"
[[ -d "$PLUGIN_DIR" ]] && rsync -a "$PLUGIN_DIR/" "$SNAPSHOT_DIR/SwiftBarPlugins/"
[[ -d "$HOME/.config/borders" ]] && rsync -a "$HOME/.config/borders/" "$SNAPSHOT_DIR/borders/"
[[ -d "$HOME/.config/ghostty" ]] && rsync -a "$HOME/.config/ghostty/" "$SNAPSHOT_DIR/ghostty/"
[[ -d "$HOME/.config/hackermacui/theme" ]] && rsync -a "$HOME/.config/hackermacui/theme/" "$SNAPSHOT_DIR/theme/"

"$ROOT/scripts/status.sh" > "$SNAPSHOT_DIR/status.txt"

echo "Private snapshot written: $SNAPSHOT_DIR"
