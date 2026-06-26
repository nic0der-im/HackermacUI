#!/bin/bash
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
# <swiftbar.hideSwiftBar>false</swiftbar.hideSwiftBar>

set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin${PATH:+:$PATH}"

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"
SCRIPT_PATH="${SWIFTBAR_PLUGIN_PATH:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROFILE_ENV="${HACKERMACUI_PROFILE_ENV:-$HOME/.config/aerospace/scripts/profile.env}"
REPO_PROFILE_ENV="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)/configs/aerospace/scripts/profile.env"

if [[ -f "$PROFILE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$PROFILE_ENV"
elif [[ -f "$REPO_PROFILE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$REPO_PROFILE_ENV"
fi

WORKSPACES="${AEROSPACE_SWIFTBAR_WORKSPACES:-${HACKERMACUI_WORKSPACES:-1 2 3 4}}"
TIMEOUT_TICKS="${AEROSPACE_SWIFTBAR_TIMEOUT_TICKS:-15}"
MAX_ICONS_PER_WORKSPACE="${AEROSPACE_SWIFTBAR_MAX_ICONS:-5}"
REAL_ICONS="${AEROSPACE_SWIFTBAR_REAL_ICONS:-1}"
EMPTY_LABEL="${AEROSPACE_SWIFTBAR_EMPTY_LABEL:-}"
STRIP_CACHE_LIMIT="${AEROSPACE_SWIFTBAR_STRIP_CACHE_LIMIT:-24}"
RENDER_MODE="${AEROSPACE_SWIFTBAR_RENDER_MODE:-image}"
COMPACT_MODE="${AEROSPACE_SWIFTBAR_COMPACT:-1}"
CACHE_ROOT="${SWIFTBAR_PLUGIN_CACHE_PATH:-${TMPDIR:-/tmp}/swiftbar-hackermac-workspaces}"
CACHE_FILE="$CACHE_ROOT/menu.txt"
LOCK_DIR="$CACHE_ROOT/render.lock"
ICON_CACHE_ROOT="$CACHE_ROOT/icons"
ICON_SOURCE_CACHE_FILE="$CACHE_ROOT/icon-sources.tsv"
STRIP_CACHE_ROOT="$CACHE_ROOT/strips"
STRIP_STATE_FILE="$CACHE_ROOT/strip-state.tsv"
STRIP_B64_FILE="$CACHE_ROOT/strip.b64"
STRIP_KEY_FILE="$CACHE_ROOT/strip.key"
RENDERER="$SCRIPT_DIR/render-workspace-strip.jxa"

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
PERL="/usr/bin/perl"
MV="/bin/mv"
SLEEP="/bin/sleep"

if [[ "$TIMEOUT_TICKS" =~ ^[0-9]+$ ]]; then
  TIMEOUT_SECONDS="$(awk -v ticks="$TIMEOUT_TICKS" 'BEGIN { printf "%.2f", ticks / 10 }')"
else
  TIMEOUT_SECONDS="1.50"
fi

if [[ ! -x "$AEROSPACE" ]]; then
  echo "WS ? | color=$ERROR"
  echo "---"
  echo "AeroSpace binary not found | color=$ERROR"
  exit 0
fi

mkdir -p "$CACHE_ROOT" "$ICON_CACHE_ROOT" "$STRIP_CACHE_ROOT" 2>/dev/null || true

render_cached_or_busy() {
  if [[ -s "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
  else
    echo "WS … | color=$WARN font=Menlo size=12"
  fi
}

acquire_render_lock() {
  local attempt

  if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
    return 0
  fi

  for attempt in 1 2 3 4 5; do
    "$SLEEP" 0.05
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
      return 0
    fi
  done

  return 1
}

aerospace_capture() {
  "$PERL" -MTime::HiRes=alarm -e '
    $SIG{ALRM} = sub { exit 124 };
    my $timeout = shift @ARGV;
    alarm($timeout);
    exec @ARGV;
    exit 127;
  ' "$TIMEOUT_SECONDS" "$AEROSPACE" "$@" 2>/dev/null
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
  printf '%s\n' "$filtered_window_lines" \
    | awk -F '|' -v ws="$ws" '$1 == ws { print $2 "|" $3 }'
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
  local plist plist_mtime cached_source cached_plist_mtime icon source fallback tmp_cache

  [[ -n "$bundle_path" && -d "$bundle_path" ]] || return 1
  plist="$bundle_path/Contents/Info.plist"
  [[ -f "$plist" && -x "$PLISTBUDDY" ]] || return 1
  plist_mtime="$(file_mtime "$plist")"

  if [[ -s "$ICON_SOURCE_CACHE_FILE" ]]; then
    IFS=$'\t' read -r cached_source cached_plist_mtime < <(
      awk -F '\t' -v bundle_path="$bundle_path" '$1 == bundle_path { print $2 "\t" $3; exit }' "$ICON_SOURCE_CACHE_FILE"
    )
    if [[ -n "${cached_source:-}" && -f "$cached_source" && "${cached_plist_mtime:-}" == "$plist_mtime" ]]; then
      printf '%s' "$cached_source"
      return 0
    fi
  fi

  icon="$($PLISTBUDDY -c 'Print CFBundleIconFile' "$plist" 2>/dev/null || true)"
  if [[ -n "$icon" ]]; then
    [[ "$icon" == *.* ]] || icon="$icon.icns"
    source="$bundle_path/Contents/Resources/$icon"
    if [[ -f "$source" ]]; then
      tmp_cache="$ICON_SOURCE_CACHE_FILE.$$"
      awk -F '\t' -v bundle_path="$bundle_path" '$1 != bundle_path { print }' "$ICON_SOURCE_CACHE_FILE" 2>/dev/null >"$tmp_cache" || true
      printf '%s\t%s\t%s\n' "$bundle_path" "$source" "$plist_mtime" >>"$tmp_cache"
      "$MV" "$tmp_cache" "$ICON_SOURCE_CACHE_FILE" 2>/dev/null || true
      printf '%s' "$source"
      return 0
    fi
  fi

  fallback="$(printf '%s\n' "$bundle_path"/Contents/Resources/*.icns 2>/dev/null | awk 'NR == 1 { print }')"
  [[ -f "$fallback" ]] || return 1
  tmp_cache="$ICON_SOURCE_CACHE_FILE.$$"
  awk -F '\t' -v bundle_path="$bundle_path" '$1 != bundle_path { print }' "$ICON_SOURCE_CACHE_FILE" 2>/dev/null >"$tmp_cache" || true
  printf '%s\t%s\t%s\n' "$bundle_path" "$fallback" "$plist_mtime" >>"$tmp_cache"
  "$MV" "$tmp_cache" "$ICON_SOURCE_CACHE_FILE" 2>/dev/null || true
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
  local ws record app bundle icon count icon_mtime records focused_flag tmp_state

  tmp_state="$STRIP_STATE_FILE.$$"
  : >"$tmp_state" || return 1
  for ws in $WORKSPACES; do
    count=0
    focused_flag="0"
    [[ "$ws" == "$focused" ]] && focused_flag="1"
    records="$(workspace_app_records "$ws")"
    if [[ -z "$records" ]]; then
      printf '%s\t%s\t\t\t0\n' "$ws" "$focused_flag" >>"$tmp_state"
      continue
    fi

    while IFS= read -r record; do
      [[ -z "$record" ]] && continue
      app="${record%%|*}"
      bundle="${record#*|}"
      icon="$(icon_png "$app" "$bundle")" || icon=""
      icon_mtime="$(file_mtime "$icon")"
      printf '%s\t%s\t%s\t%s\t%s\n' "$ws" "$focused_flag" "$app" "$icon" "$icon_mtime" >>"$tmp_state"
      count=$((count + 1))
      (( count >= MAX_ICONS_PER_WORKSPACE )) && break
    done <<<"$records"
  done

  "$MV" "$tmp_state" "$STRIP_STATE_FILE" || return 1
  return 0
}

strip_image_base64() {
  local key png renderer_mtime cached_key tmp_b64 tmp_key

  [[ -x "$OSASCRIPT" && -x "$BASE64" && -f "$RENDERER" ]] || return 1
  write_strip_state || return 1
  renderer_mtime="$(file_mtime "$RENDERER")"
  key="$(cksum <"$STRIP_STATE_FILE" | awk -v renderer_mtime="$renderer_mtime" '{ print $1 "-" $2 "-" renderer_mtime }')"
  png="$STRIP_CACHE_ROOT/$key.png"

  cached_key=""
  [[ -s "$STRIP_KEY_FILE" ]] && cached_key="$(tr -d '\n' <"$STRIP_KEY_FILE")"
  if [[ "$cached_key" == "$key" && -s "$STRIP_B64_FILE" ]]; then
    tr -d '\n' <"$STRIP_B64_FILE"
    return 0
  fi

  if [[ ! -s "$png" ]]; then
    "$OSASCRIPT" -l JavaScript "$RENDERER" "$STRIP_STATE_FILE" "$png" "$EMPTY_LABEL" >/dev/null 2>&1 || return 1
    prune_strip_cache
  fi

  [[ -s "$png" ]] || return 1
  tmp_b64="$STRIP_B64_FILE.$$"
  tmp_key="$STRIP_KEY_FILE.$$"
  "$BASE64" <"$png" | tr -d '\n' >"$tmp_b64" || return 1
  "$MV" "$tmp_b64" "$STRIP_B64_FILE" || return 1
  printf '%s' "$key" >"$tmp_key" && "$MV" "$tmp_key" "$STRIP_KEY_FILE" || true
  tr -d '\n' <"$STRIP_B64_FILE"
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
  window_lines="$(aerospace_capture list-windows --all --format '%{workspace}|%{app-name}|%{app-bundle-path}|%{window-title}')" || return 1
  filtered_window_lines="$(printf '%s\n' "$window_lines" | awk -F '|' '$2 != "" && $4 != "Dictation" { print $1 "|" $2 "|" $3 }')"

  if [[ "$RENDER_MODE" == "image" ]]; then
    strip_image="$(strip_image_base64)" || true
  fi

  if [[ "$RENDER_MODE" == "image" && -n "$strip_image" ]]; then
    echo "  | image=$strip_image trim=false"
  elif [[ "$COMPACT_MODE" == "1" ]]; then
    echo "WS $focused | color=$GREEN font=Menlo size=12"
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

if ! acquire_render_lock; then
  render_cached_or_busy
  exit 0
fi

if output="$(render_current)"; then
  printf '%s\n' "$output"
  if [[ -d "$CACHE_ROOT" ]]; then
    printf '%s\n' "$output" >"$CACHE_FILE.$$" && "$MV" "$CACHE_FILE.$$" "$CACHE_FILE"
  fi
else
  render_stale
fi
