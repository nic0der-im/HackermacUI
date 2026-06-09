#!/usr/bin/env bash
set -euo pipefail

REPO="${HACKERMACUI_REPO:-$HOME/HackermacUI}"
printf -v QUOTED_REPO '%q' "$REPO"
COMMAND="cd $QUOTED_REPO && { command -v opencode >/dev/null || { print -u2 'opencode not found'; exec zsh; }; opencode; }"

exec /usr/bin/open -na Ghostty --args -e /bin/zsh -lc "$COMMAND"
