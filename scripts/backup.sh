#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.hackermacui"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    rsync -a "$src" "$dest"
  fi
}

copy_if_exists "$HOME/.aerospace.toml" "$BACKUP_DIR/aerospace.toml"
copy_if_exists "$HOME/SwiftBarPlugins/" "$BACKUP_DIR/SwiftBarPlugins/"
copy_if_exists "$HOME/.config/borders/" "$BACKUP_DIR/borders/"
copy_if_exists "$HOME/.config/ghostty/" "$BACKUP_DIR/ghostty/"
copy_if_exists "$HOME/.zshrc" "$BACKUP_DIR/zshrc"

cat > "$STATE_DIR/state.json" <<JSON
{
  "last_backup": "$BACKUP_DIR",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

echo "Backup written: $BACKUP_DIR"
