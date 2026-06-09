#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)"

echo "== Services =="
brew services list | egrep 'borders|atuin|redis|postgresql' || true

echo
echo "== Installed menu bar stack =="
brew list --cask swiftbar >/dev/null 2>&1 && echo "SwiftBar: installed" || echo "SwiftBar: missing"
brew list sketchybar >/dev/null 2>&1 && echo "SketchyBar: still installed" || echo "SketchyBar: removed"

echo
echo "== Desktop processes =="
ps -axo pid,%cpu,%mem,rss,command \
  | egrep 'SwiftBar|AeroSpace|borders|sketchybar|sketchybarrc|AltTab|Hammerspoon|Rift|yabai|skhd|Rectangle' \
  | egrep -v 'egrep|status.sh|zsh -c' \
  | sort -k2 -nr || true

echo
echo "== AeroSpace gaps =="
sed -n '/^\[gaps\]/,/^$/p' "$HOME/.aerospace.toml" || true

echo
echo "== SwiftBar =="
echo "PluginDirectory: ${PLUGIN_DIR:-not configured}"
if [[ -n "$PLUGIN_DIR" && -d "$PLUGIN_DIR" ]]; then
  find -H "$PLUGIN_DIR" -maxdepth 1 -type f -perm -111 -print | sed "s#^$PLUGIN_DIR/##" | sort
else
  echo "No plugin directory found"
fi
