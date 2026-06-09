#!/usr/bin/env bash
# <xbar.title>AeroSpace Workspaces</xbar.title>
# <xbar.version>v3.0.0</xbar.version>
# <xbar.author>Ignacio Medina</xbar.author>
# <xbar.desc>AeroSpace workspace strip rendered as a cached Waybar-like image.</xbar.desc>
# <xbar.dependencies>aerospace,bash,awk,sort,paste,sips,base64,osascript</xbar.dependencies>
# <swiftbar.refreshOnOpen>false</swiftbar.refreshOnOpen>
# <swiftbar.runInBash>false</swiftbar.runInBash>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

set -uo pipefail

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"
SCRIPT_PATH="${SWIFTBAR_PLUGIN_PATH:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WORKSPACES="${AEROSPACE_SWIFTBAR_WORKSPACES:-1 2 3 4 5 6}"
TIMEOUT_TICKS="${AEROSPACE_SWIFTBAR_TIMEOUT_TICKS:-15}"
MAX_ICONS_PER_WORKSPACE="${AEROSPACE_SWIFTBAR_MAX_ICONS:-5}"
REAL_ICONS="${AEROSPACE_SWIFTBAR_REAL_ICONS:-1}"
EMPTY_LABEL="${AEROSPACE_SWIFTBAR_EMPTY_LABEL:-}"
STRIP_CACHE_LIMIT="${AEROSPACE_SWIFTBAR_STRIP_CACHE_LIMIT:-24}"
CACHE_ROOT="${SWIFTBAR_PLUGIN_CACHE_PATH:-${TMPDIR:-/tmp}/swiftbar-aerospace-workspaces}"
CACHE_FILE="$CACHE_ROOT/menu.txt"
ICON_CACHE_ROOT="$CACHE_ROOT/icons"
STRIP_CACHE_ROOT="$CACHE_ROOT/strips"
STRIP_STATE_FILE="$CACHE_ROOT/strip-state.tsv"
RENDERER="$SCRIPT_DIR/.helpers/render-workspace-strip.jxa"

GREEN="#82FB9C"
MUTED="#8A8F98"
FG="#E6EDF3"
WARN="#F6C177"
ERROR="#FF5F57"

PLISTBUDDY="/usr/libexec/PlistBuddy"
SIPS="/usr/bin/sips"
BASE64="/usr/bin/base64"
OSASCRIPT="/usr/bin/osascript"
LS="/bin/ls"
RM="/bin/rm"

if [[ ! -x "$AEROSPACE" ]]; then
  echo "WS ? | color=$ERROR"
  echo "---"
  echo "AeroSpace binary not found | color=$ERROR"
  exit 0
fi

mkdir -p "$CACHE_ROOT" "$ICON_CACHE_ROOT" "$STRIP_CACHE_ROOT" 2>/dev/null || true

run_with_timeout() {
  local max_ticks="$1"
  shift
  local tmp pid status ticks

  tmp="$(mktemp "${TMPDIR:-/tmp}/swiftbar-aerospace.XXXXXX")" || return 1
  "$@" >"$tmp" 2>/dev/null &
  pid="$!"
  ticks=0

  while kill -0 "$pid" 2>/dev/null; do
    if (( ticks >= max_ticks )); then
      kill "$pid" 2>/dev/null || true
      sleep 0.1
      kill -9 "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      rm -f "$tmp"
      return 124
    fi

    sleep 0.1
    ticks=$((ticks + 1))
  done

  wait "$pid"
  status="$?"
  cat "$tmp"
  rm -f "$tmp"
  return "$status"
}

aerospace_capture() {
  run_with_timeout "$TIMEOUT_TICKS" "$AEROSPACE" "$@"
}

app_icon() {
  case "$1" in
    "Ghostty"|"Terminal"|"iTerm2"|"Alacritty"|"WezTerm") printf '⌘' ;;
    "Google Chrome"|"Chrome"|"Safari"|"Firefox"|"Brave Browser"|"Arc") printf '◎' ;;
    "PhpStorm"|"WebStorm"|"IntelliJ IDEA"|"Visual Studio Code"|"Code"|"Cursor") printf '⌥' ;;
    "Finder") printf '◆' ;;
    "Obsidian") printf '◇' ;;
    "Discord"|"WhatsApp"|"Telegram"|"Slack") printf '✉' ;;
    "Spotify"|"Music") printf '♪' ;;
    "Steam"|"Steam Helper") printf '▶' ;;
    "Docker"|"Docker Desktop"|"OrbStack") printf '◧' ;;
    *) printf '•' ;;
  esac
}

workspace_app_records() {
  local ws="$1"
  printf '%s\n' "$window_lines" \
    | awk -F '|' -v ws="$ws" '$1 == ws && $2 != "" { print $2 "|" $3 }'
}

workspace_apps() {
  local ws="$1"
  workspace_app_records "$ws" | awk -F '|' '{ print $1 }'
}

cache_key() {
  printf '%s' "$1" | cksum | awk '{ print $1 }'
}

bundle_icon_source() {
  local bundle_path="$1"
  local plist icon source fallback

  [[ -n "$bundle_path" && -d "$bundle_path" ]] || return 1
  plist="$bundle_path/Contents/Info.plist"
  [[ -f "$plist" && -x "$PLISTBUDDY" ]] || return 1

  icon="$($PLISTBUDDY -c 'Print CFBundleIconFile' "$plist" 2>/dev/null || true)"
  if [[ -n "$icon" ]]; then
    [[ "$icon" == *.* ]] || icon="$icon.icns"
    source="$bundle_path/Contents/Resources/$icon"
    [[ -f "$source" ]] && printf '%s' "$source" && return 0
  fi

  fallback="$(printf '%s\n' "$bundle_path"/Contents/Resources/*.icns 2>/dev/null | awk 'NR == 1 { print }')"
  [[ -f "$fallback" ]] || return 1
  printf '%s' "$fallback"
}

icon_png() {
  local app_name="$1"
  local bundle_path="$2"
  local source key png

  [[ "$REAL_ICONS" == "1" ]] || return 1
  [[ -x "$SIPS" ]] || return 1

  source="$(bundle_icon_source "$bundle_path")" || return 1
  key="$(cache_key "$bundle_path|$source")"
  png="$ICON_CACHE_ROOT/$key.png"

  if [[ ! -s "$png" || "$source" -nt "$png" ]]; then
    "$SIPS" -s format png --resampleWidth 36 "$source" --out "$png" >/dev/null 2>&1 || return 1
  fi

  printf '%s' "$png"
}

file_mtime() {
  [[ -e "$1" ]] && stat -f '%m' "$1" 2>/dev/null || printf '0'
}

icon_base64() {
  local png

  [[ -x "$BASE64" ]] || return 1
  png="$(icon_png "$1" "$2")" || return 1
  "$BASE64" <"$png" | tr -d '\n'
}

workspace_primary_image() {
  local ws="$1"
  local record app bundle image

  while IFS= read -r record; do
    [[ -z "$record" ]] && continue
    app="${record%%|*}"
    bundle="${record#*|}"
    image="$(icon_base64 "$app" "$bundle")" || true
    [[ -n "$image" ]] && printf '%s' "$image" && return 0
  done < <(workspace_app_records "$ws")

  return 1
}

workspace_icons() {
  local ws="$1"
  local app count out icon

  count=0
  out=""
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    icon="$(app_icon "$app")"
    out="$out$icon"
    count=$((count + 1))
    (( count >= MAX_ICONS_PER_WORKSPACE )) && break
  done < <(workspace_apps "$ws")

  printf '%s' "$out"
}

write_strip_state() {
  local ws record app bundle icon limit count icon_mtime

  : >"$STRIP_STATE_FILE" || return 1
  for ws in $WORKSPACES; do
    count=0
    if ! workspace_app_records "$ws" | grep -q .; then
      printf '%s\t%s\t\t\t0\n' "$ws" "$([[ "$ws" == "$focused" ]] && printf '1' || printf '0')" >>"$STRIP_STATE_FILE"
      continue
    fi

    while IFS= read -r record; do
      [[ -z "$record" ]] && continue
      app="${record%%|*}"
      bundle="${record#*|}"
      icon="$(icon_png "$app" "$bundle")" || icon=""
      icon_mtime="$(file_mtime "$icon")"
      printf '%s\t%s\t%s\t%s\t%s\n' "$ws" "$([[ "$ws" == "$focused" ]] && printf '1' || printf '0')" "$app" "$icon" "$icon_mtime" >>"$STRIP_STATE_FILE"
      count=$((count + 1))
      (( count >= MAX_ICONS_PER_WORKSPACE )) && break
    done < <(workspace_app_records "$ws")
  done
}

strip_image_base64() {
  local key png renderer_mtime

  [[ -x "$OSASCRIPT" && -x "$BASE64" && -f "$RENDERER" ]] || return 1
  write_strip_state || return 1
  renderer_mtime="$(file_mtime "$RENDERER")"
  key="$(cksum <"$STRIP_STATE_FILE" | awk -v renderer_mtime="$renderer_mtime" '{ print $1 "-" $2 "-" renderer_mtime }')"
  png="$STRIP_CACHE_ROOT/$key.png"

  if [[ ! -s "$png" ]]; then
    "$OSASCRIPT" -l JavaScript "$RENDERER" "$STRIP_STATE_FILE" "$png" "$EMPTY_LABEL" >/dev/null 2>&1 || return 1
    prune_strip_cache
  fi

  [[ -s "$png" ]] || return 1
  "$BASE64" <"$png" | tr -d '\n'
}

prune_strip_cache() {
  local files excess file

  [[ "$STRIP_CACHE_LIMIT" =~ ^[0-9]+$ ]] || return 0
  (( STRIP_CACHE_LIMIT > 0 )) || return 0

  files="$($LS -t "$STRIP_CACHE_ROOT"/*.png 2>/dev/null || true)"
  [[ -n "$files" ]] || return 0
  excess="$(printf '%s\n' "$files" | awk -v limit="$STRIP_CACHE_LIMIT" 'NR > limit { print }')"
  [[ -n "$excess" ]] || return 0

  while IFS= read -r file; do
    [[ -n "$file" ]] && "$RM" -f "$file"
  done <<<"$excess"
}

workspace_title_segment() {
  local ws="$1"
  local icons segment

  icons="$(workspace_icons "$ws")"
  [[ -z "$icons" ]] && icons="·"
  segment="$ws$icons"

  if [[ "$ws" == "$focused" ]]; then
    printf '[%s]' "$segment"
  else
    printf '%s' "$segment"
  fi
}

render_title() {
  local ws out

  out=""
  for ws in $WORKSPACES; do
    out="$out $(workspace_title_segment "$ws")"
  done

  printf '%s' "${out# }"
}

render_current() {
  local strip_image

  focused="$(aerospace_capture list-workspaces --focused | awk 'NR == 1 { print }')" || return 1
  window_lines="$(aerospace_capture list-windows --all --format '%{workspace}|%{app-name}|%{app-bundle-path}')" || return 1

  strip_image="$(strip_image_base64)" || true
  if [[ -n "$strip_image" ]]; then
    echo "  | image=$strip_image trim=false"
  else
    echo "$(render_title) | color=$GREEN font=Menlo size=12"
  fi
}

render_stale() {
  if [[ -s "$CACHE_FILE" ]]; then
    awk 'NR == 1 { sub(/ \|/, " stale |") } { print }' "$CACHE_FILE"
    echo "---"
    echo "AeroSpace did not respond within ${TIMEOUT_TICKS}00ms | color=$WARN"
    echo "Using cached workspace strip | color=$MUTED"
  else
    echo "WS stale | color=$WARN"
    echo "---"
    echo "AeroSpace did not respond within ${TIMEOUT_TICKS}00ms | color=$WARN"
    echo "No cached workspace strip yet | color=$MUTED"
  fi
}

if output="$(render_current)"; then
  printf '%s\n' "$output"
  [[ -d "$CACHE_ROOT" ]] && printf '%s\n' "$output" >"$CACHE_FILE"
else
  render_stale
fi
