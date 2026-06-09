#!/usr/bin/env bash
set -euo pipefail

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"
PROFILE_ENV="${HACKERMACUI_PROFILE_ENV:-$HOME/.config/aerospace/scripts/profile.env}"

if [[ -f "$PROFILE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$PROFILE_ENV"
fi

WORKSPACES="${HACKERMACUI_WORKSPACES:-1 2 3 4}"

if [[ ! -x "$AEROSPACE" ]]; then
  AEROSPACE="$(command -v aerospace || true)"
fi

if [[ -z "$AEROSPACE" ]]; then
  exit 0
fi

focused="$($AEROSPACE list-workspaces --focused 2>/dev/null | head -n 1 || true)"
if [[ -z "$focused" ]]; then
  exit 0
fi

active_workspaces="$($AEROSPACE list-windows --all --format '%{workspace}' 2>/dev/null \
  | awk -v workspaces="$WORKSPACES" '
      BEGIN {
        split(workspaces, allowed, " ")
        for (i in allowed) valid[allowed[i]] = 1
      }
      valid[$0] && !seen[$0]++ { print }
    ' \
  | sort -n || true)"

count="$(printf '%s\n' "$active_workspaces" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$count" -le 1 ]]; then
  exit 0
fi

next=""
if printf '%s\n' $WORKSPACES | grep -qx "$focused"; then
  while IFS= read -r workspace; do
    [[ -z "$workspace" ]] && continue
    if [[ "$workspace" -gt "$focused" ]]; then
      next="$workspace"
      break
    fi
  done <<< "$active_workspaces"
fi

if [[ -z "$next" ]]; then
  next="$(printf '%s\n' "$active_workspaces" | sed '/^$/d' | head -n 1)"
fi

if [[ -n "$next" && "$next" != "$focused" ]]; then
  "$AEROSPACE" workspace "$next" >/dev/null 2>&1 || true
fi
