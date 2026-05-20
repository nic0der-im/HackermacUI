#!/usr/bin/env bash
# <xbar.title>AeroSpace Workspaces</xbar.title>
# <xbar.version>v1.0.0</xbar.version>
# <xbar.author>Ignacio Medina</xbar.author>
# <xbar.desc>Shows AeroSpace workspaces in the native macOS menu bar and lets you switch from the dropdown.</xbar.desc>
# <xbar.dependencies>aerospace,bash</xbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

set -euo pipefail

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"
SCRIPT_PATH="${SWIFTBAR_PLUGIN_PATH:-$0}"
GREEN="#82FB9C"
MUTED="#8A8F98"
FG="#E6EDF3"

if [[ $# -ge 2 && "${1:-}" == "workspace" ]]; then
  "$AEROSPACE" workspace "$2" >/dev/null 2>&1 || true
  exit 0
fi

if ! command -v "$AEROSPACE" >/dev/null 2>&1 && [[ ! -x "$AEROSPACE" ]]; then
  echo "WS ? | color=#ff5f57"
  echo "---"
  echo "AeroSpace binary not found | color=#ff5f57"
  exit 0
fi

focused="$($AEROSPACE list-workspaces --focused 2>/dev/null | head -n 1 || true)"
workspaces="$($AEROSPACE list-workspaces --all 2>/dev/null || true)"
window_workspaces="$($AEROSPACE list-windows --all --format '%{workspace}' 2>/dev/null || true)"

if [[ -z "$workspaces" ]]; then
  echo "WS — | color=$MUTED"
  echo "---"
  echo "No AeroSpace workspaces found | color=$MUTED"
  exit 0
fi

title="WS"
while IFS= read -r ws; do
  [[ -z "$ws" ]] && continue
  if [[ "$ws" == "$focused" ]]; then
    title="$title [$ws]"
  elif printf '%s\n' "$window_workspaces" | grep -qx "$ws"; then
    title="$title ${ws}•"
  else
    title="$title $ws"
  fi
done <<< "$workspaces"

echo "$title | color=$GREEN font=Menlo size=12 dropdown=false"
echo "---"
echo "AeroSpace Workspaces | color=$GREEN"
echo "Focused: ${focused:-none} | color=$FG"
echo "---"
while IFS= read -r ws; do
  [[ -z "$ws" ]] && continue
  mark="○"
  color="$FG"
  [[ "$ws" == "$focused" ]] && mark="●" && color="$GREEN"
  apps="$($AEROSPACE list-windows --workspace "$ws" --format '%{app-name}' 2>/dev/null | sort -fu | paste -sd ', ' - || true)"
  [[ -z "$apps" ]] && apps="empty"
  echo "$mark Workspace $ws — $apps | color=$color bash=$SCRIPT_PATH param1=workspace param2=$ws terminal=false refresh=true"
done <<< "$workspaces"
echo "---"
echo "Reload AeroSpace config | bash=/opt/homebrew/bin/aerospace param1=reload-config terminal=false refresh=true"
echo "Open HackermacUI | bash=/usr/bin/open param1=$HOME/HackermacUI terminal=false"
