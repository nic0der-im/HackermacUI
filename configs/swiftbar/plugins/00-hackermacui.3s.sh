#!/bin/bash
# <xbar.title>HackermacUI Workspaces</xbar.title>
# <xbar.version>v1.0.0</xbar.version>
# <xbar.author>Ignacio Medina</xbar.author>
# <xbar.desc>HackermacUI workspace strip rendered as a cached image, with local actions in the dropdown.</xbar.desc>
# <xbar.dependencies>aerospace,bash,awk,sort,paste,sips,base64,osascript</xbar.dependencies>
# <swiftbar.refreshOnOpen>false</swiftbar.refreshOnOpen>
# <swiftbar.runInBash>false</swiftbar.runInBash>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin${PATH:+:$PATH}"

SCRIPT_PATH="${SWIFTBAR_PLUGIN_PATH:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RENDER_HELPER="$SCRIPT_DIR/.helpers/render-hackermac-workspaces.sh"

GREEN="#82FB9C"
MUTED="#8A8F98"
ERROR="#FF5F57"

render_header() {
  local output title

  if [[ ! -x "$RENDER_HELPER" ]]; then
    echo "HM | color=$ERROR"
    return 0
  fi

  output="$(SWIFTBAR_PLUGIN_PATH="$RENDER_HELPER" AEROSPACE_SWIFTBAR_RENDER_MODE=image AEROSPACE_SWIFTBAR_COMPACT=1 "$RENDER_HELPER" 2>/dev/null)" || output=""
  title="$(printf '%s\n' "$output" | awk 'NR == 1 { print; exit }')"

  if [[ -n "$title" ]]; then
    printf '%s\n' "$title"
  else
    echo "HM | color=$ERROR"
  fi
}

render_dropdown() {
  echo "---"
  echo "HackermacUI Workspaces | color=$GREEN"
  echo "Refresh strip | refresh=true"
  echo "Open HackermacUI repo | bash=/usr/bin/open terminal=false param1=$REPO_ROOT"
  echo "Open SwiftBar plugins | bash=/usr/bin/open terminal=false param1=$SCRIPT_DIR"
  echo "Open AeroSpace config | bash=/usr/bin/open terminal=false param1=$REPO_ROOT/configs/aerospace/aerospace.toml"
  echo "SwiftBar owns this widget | color=$MUTED"
}

render_header
render_dropdown
