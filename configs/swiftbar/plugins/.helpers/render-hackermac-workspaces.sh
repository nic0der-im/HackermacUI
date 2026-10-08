#!/bin/bash
# <xbar.title>AeroSpace Workspaces</xbar.title>
# <xbar.version>v3.1.0</xbar.version>
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

if [[ -z "${AEROSPACE:-}" ]]; then
  if [[ -x "/opt/homebrew/bin/aerospace" ]]; then
    AEROSPACE="/opt/homebrew/bin/aerospace"
  else
    AEROSPACE="/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  fi
fi
SCRIPT_PATH="${SWIFTBAR_PLUGIN_PATH:-$0}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
[[ -z "$SCRIPT_DIR" || "$SCRIPT_DIR" == "$SCRIPT_PATH" ]] && SCRIPT_DIR="."
SCRIPT_DIR="$(cd "$SCRIPT_DIR" 2>/dev/null && pwd)"
PROFILE_ENV="${HACKERMACUI_PROFILE_ENV:-$HOME/.config/aerospace/scripts/profile.env}"

if [[ -f "$PROFILE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$PROFILE_ENV"
else
  REPO_PROFILE_ENV="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)/configs/aerospace/scripts/profile.env"
  if [[ -f "$REPO_PROFILE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$REPO_PROFILE_ENV"
  fi
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
# Bump when the strip layout changes so cached strips are not reused across versions.
STRIP_FORMAT_VERSION="3.1"

GREEN="#82FB9C"
MUTED="#8A8F98"
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
  TIMEOUT_SECONDS="$((TIMEOUT_TICKS / 10)).$((TIMEOUT_TICKS % 10))0"
else
  TIMEOUT_SECONDS="1.50"
fi

if [[ ! -x "$AEROSPACE" ]]; then
  echo "WS ? | color=$ERROR"
  echo "---"
  echo "AeroSpace binary not found | color=$ERROR"
  exit 0
fi

# Runtime state shared by the functions below.
focused=""
filtered_window_lines=""
state_blob=""
renderer_mtime="0"
bundle_paths=()
icon_memo=""

render_cached_or_busy() {
  if [[ -s "$CACHE_FILE" ]]; then
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '%s\n' "$line"
    done <"$CACHE_FILE"
  else
    echo "WS … | color=$WARN font=Menlo size=12"
  fi
}

acquire_render_lock() {

  if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rm -rf "$LOCK_DIR"' EXIT INT TERM
    return 0
  fi

  for _ in 1 2 3 4 5; do
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

file_mtime() {
  [[ -e "$1" ]] && stat -f '%m' "$1" 2>/dev/null || printf '0'
}

cache_key() {
  local sum

  sum="$(printf '%s' "$1" | cksum)"
  printf '%s' "${sum%% *}"
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

# Records are "app|bundle" for one window each, filtered to a single workspace.
workspace_app_records() {
  local ws="$1" line rest

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "${line%%|*}" == "$ws" ]] || continue
    rest="${line#*|}"
    printf '%s|%s\n' "${rest%%|*}" "${rest#*|}"
  done <<<"$filtered_window_lines"
}

workspace_apps() {
  local line

  while IFS= read -r line; do
    printf '%s\n' "${line%%|*}"
  done < <(workspace_app_records "$1")
}

bundle_icon_source() {
  local bundle_path="$1"
  local plist plist_mtime cached_source cached_plist_mtime icon source fallback line

  [[ -n "$bundle_path" && -d "$bundle_path" ]] || return 1
  plist="$bundle_path/Contents/Info.plist"
  [[ -f "$plist" && -x "$PLISTBUDDY" ]] || return 1
  plist_mtime="$(file_mtime "$plist")"

  cached_source=""
  cached_plist_mtime=""
  if [[ -s "$ICON_SOURCE_CACHE_FILE" ]]; then
    while IFS= read -r line; do
      [[ "${line%%$'\t'*}" == "$bundle_path" ]] || continue
      line="${line#*$'\t'}"
      cached_source="${line%%$'\t'*}"
      cached_plist_mtime="${line#*$'\t'}"
      break
    done <"$ICON_SOURCE_CACHE_FILE"
    if [[ -n "$cached_source" && -f "$cached_source" && "$cached_plist_mtime" == "$plist_mtime" ]]; then
      printf '%s' "$cached_source"
      return 0
    fi
  fi

  icon="$($PLISTBUDDY -c 'Print CFBundleIconFile' "$plist" 2>/dev/null || true)"
  if [[ -n "$icon" ]]; then
    [[ "$icon" == *.* ]] || icon="$icon.icns"
    source="$bundle_path/Contents/Resources/$icon"
    if [[ -f "$source" ]]; then
      write_icon_source_cache "$bundle_path" "$source" "$plist_mtime"
      printf '%s' "$source"
      return 0
    fi
  fi

  fallback=""
  for line in "$bundle_path"/Contents/Resources/*.icns; do
    [[ -e "$line" ]] && { fallback="$line"; break; }
  done
  [[ -n "$fallback" ]] || return 1
  write_icon_source_cache "$bundle_path" "$fallback" "$plist_mtime"
  printf '%s' "$fallback"
}

write_icon_source_cache() {
  local bundle_path="$1" source="$2" plist_mtime="$3" tmp_cache line

  tmp_cache="$ICON_SOURCE_CACHE_FILE.$$"
  : >"$tmp_cache" || return 1
  while IFS= read -r line; do
    [[ "${line%%$'\t'*}" == "$bundle_path" ]] && continue
    printf '%s\n' "$line" >>"$tmp_cache"
  done <"$ICON_SOURCE_CACHE_FILE" 2>/dev/null
  printf '%s\t%s\t%s\n' "$bundle_path" "$source" "$plist_mtime" >>"$tmp_cache"
  "$MV" "$tmp_cache" "$ICON_SOURCE_CACHE_FILE" 2>/dev/null || true
}

# Icon PNGs are memoized per run: the same app repeats for every window it owns.
icon_png() {
  local app_name="$1" bundle_path="$2"
  local source key png memo_key

  [[ "$REAL_ICONS" == "1" ]] || return 1
  [[ -x "$SIPS" ]] || return 1

  memo_key="$app_name"$'\t'"$bundle_path"
  case "$icon_memo" in
    *$'\n'"$memo_key"$'\t'*)
      png="${icon_memo#*$'\n'"$memo_key"$'\t'}"
      png="${png%%$'\n'*}"
      [[ "$png" == "-" ]] && return 1
      printf '%s' "$png"
      return 0
      ;;
  esac

  if ! source="$(bundle_icon_source "$bundle_path")"; then
    icon_memo="$icon_memo"$'\n'"$memo_key"$'\t-'
    return 1
  fi
  key="$(cache_key "$bundle_path|$source")"
  png="$ICON_CACHE_ROOT/$key.png"

  if [[ ! -s "$png" || "$source" -nt "$png" ]]; then
    if ! "$SIPS" -s format png --resampleWidth 36 "$source" --out "$png" >/dev/null 2>&1; then
      icon_memo="$icon_memo"$'\n'"$memo_key"$'\t-'
      return 1
    fi
  fi

  icon_memo="$icon_memo"$'\n'"$memo_key"$'\t'"$png"
  printf '%s' "$png"
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

# One AeroSpace round trip: workspace|is-focused|app|bundle|title per window.
refresh_workspace_state() {
  local raw meta tag value

  raw="$(aerospace_capture list-windows --all --format '%{workspace}|%{workspace-is-focused}|%{app-name}|%{app-bundle-path}|%{window-title}')" || return 1

  filtered_window_lines="$(printf '%s\n' "$raw" | awk -F '|' '$3 != "" && $5 != "Dictation" { print $1 "|" $3 "|" $4 }')"
  meta="$(printf '%s\n' "$raw" | awk -F '|' '
    $3 != "" && $5 != "Dictation" {
      if ($2 == "true") focus = $1
      if (!seen[$4]++) print "P\t" $4
    }
    END { print "F\t" focus }')"

  focused=""
  bundle_paths=()
  while IFS=$'\t' read -r tag value; do
    case "$tag" in
      P) [[ -n "$value" ]] && bundle_paths+=("$value") ;;
      F) focused="$value" ;;
    esac
  done <<<"$meta"

  if [[ -z "$focused" ]]; then
    focused="$(aerospace_capture list-workspaces --focused 2>/dev/null | awk 'NR == 1 { print }')" || focused=""
  fi

  build_state_blob
}

# Everything the rendered strip depends on: workspace/app layout, the focused
# workspace, icon sources (app bundle mtimes), renderer and format version.
build_state_blob() {
  local bundle plist

  state_blob="$STRIP_FORMAT_VERSION
$focused
$filtered_window_lines
$renderer_mtime
$EMPTY_LABEL
$WORKSPACES|$MAX_ICONS_PER_WORKSPACE|$REAL_ICONS|$COMPACT_MODE"
  for bundle in "${bundle_paths[@]:-}"; do
    [[ -n "$bundle" ]] || continue
    plist="$bundle/Contents/Info.plist"
    [[ -f "$plist" ]] || plist="$bundle"
    state_blob="$state_blob
$bundle=$(file_mtime "$plist")"
  done
}

# Fast path: the strip image is still valid for the current state.
cached_strip_b64() {
  local b64

  [[ -s "$STRIP_B64_FILE" && -s "$STRIP_KEY_FILE" ]] || return 1
  [[ "$state_blob" == "$(<"$STRIP_KEY_FILE")" ]] || return 1
  b64="$(<"$STRIP_B64_FILE")"
  [[ -n "$b64" ]] || return 1
  printf '%s' "${b64//$'\n'/}"
}

# Slow path: only reached when the state changed. Callers hold the render lock.
strip_image_base64() {
  local key png tmp_b64 b64

  [[ -x "$OSASCRIPT" && -x "$BASE64" && -f "$RENDERER" ]] || return 1
  write_strip_state || return 1
  key="$(cksum <"$STRIP_STATE_FILE" | awk -v renderer_mtime="$renderer_mtime" '{ print $1 "-" $2 "-" renderer_mtime }')"
  png="$STRIP_CACHE_ROOT/$key.png"

  if [[ ! -s "$png" ]]; then
    "$OSASCRIPT" -l JavaScript "$RENDERER" "$STRIP_STATE_FILE" "$png" "$EMPTY_LABEL" >/dev/null 2>&1 || return 1
    prune_strip_cache
  fi

  [[ -s "$png" ]] || return 1
  tmp_b64="$STRIP_B64_FILE.$$"
  "$BASE64" <"$png" >"$tmp_b64" || return 1
  "$MV" "$tmp_b64" "$STRIP_B64_FILE" || return 1
  printf '%s' "$state_blob" >"$STRIP_KEY_FILE.$$" && "$MV" "$STRIP_KEY_FILE.$$" "$STRIP_KEY_FILE" || true

  b64="$(<"$STRIP_B64_FILE")"
  printf '%s' "${b64//$'\n'/}"
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

  refresh_workspace_state || return 1

  if [[ "$RENDER_MODE" == "image" ]]; then
    strip_image="$(cached_strip_b64)" || strip_image=""
    if [[ -z "$strip_image" ]]; then
      acquire_render_lock || return 2
      strip_image="$(strip_image_base64)" || strip_image=""
    fi
    if [[ -n "$strip_image" ]]; then
      printf '  | image=%s trim=false\n' "$strip_image"
      return 0
    fi
  fi

  if [[ "$COMPACT_MODE" == "1" ]]; then
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

renderer_mtime="$(file_mtime "$RENDERER")"
if [[ ! -d "$CACHE_ROOT" || ! -d "$ICON_CACHE_ROOT" || ! -d "$STRIP_CACHE_ROOT" ]]; then
  mkdir -p "$CACHE_ROOT" "$ICON_CACHE_ROOT" "$STRIP_CACHE_ROOT" 2>/dev/null || true
fi

output="$(render_current)"
render_status=$?
if [[ "$render_status" -eq 0 ]]; then
  printf '%s\n' "$output"
  if [[ -d "$CACHE_ROOT" ]]; then
    cached_menu=""
    [[ -s "$CACHE_FILE" ]] && cached_menu="$(<"$CACHE_FILE")"
    if [[ "$output" != "$cached_menu" ]]; then
      printf '%s\n' "$output" >"$CACHE_FILE.$$" && "$MV" "$CACHE_FILE.$$" "$CACHE_FILE"
    fi
  fi
elif [[ "$render_status" -eq 2 ]]; then
  render_cached_or_busy
else
  render_stale
fi
