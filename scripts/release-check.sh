#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOW_DIRTY=0

usage() {
  cat <<'EOF'
Usage: scripts/release-check.sh [--allow-dirty]

Runs the publication gate for HackermacUI. By default it requires a clean git
worktree. Use --allow-dirty only while developing the gate itself.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
  shift
done

failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }
info() { printf 'INFO %s\n' "$1"; }

run_gate() {
  local label="$1"
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_clean_git() {
  local status
  status="$(git -C "$ROOT" status --short)"
  if [[ -z "$status" ]]; then
    return 0
  fi
  if [[ "$ALLOW_DIRTY" == "1" ]]; then
    info "dirty worktree allowed for development"
    printf '%s\n' "$status"
    return 0
  fi
  printf '%s\n' "$status"
  return 1
}

check_public_profile() {
  [[ "$($ROOT/scripts/template.sh current)" == "default" ]]
}

check_private_paths_not_tracked() {
  local tracked
  tracked="$(git -C "$ROOT" ls-files \
    '.idea/*' \
    'dist/*' \
    'build/*' \
    '.build/*' \
    'apps/HackermacLauncher/.build/*' \
    'snapshots/*' \
    'backups/*' \
    'private/*' \
    '.hackermacui/*' \
    '.env' \
    '.env.*' \
    '*.pem' \
    '*.key' \
    '*.p12' \
    '*.mobileprovision' || true)"
  [[ -z "$tracked" ]] || { printf '%s\n' "$tracked"; return 1; }
}

check_no_unignored_private_artifacts() {
  local untracked
  untracked="$(git -C "$ROOT" ls-files --others --exclude-standard \
    '.idea/*' \
    'dist/*' \
    'build/*' \
    '.build/*' \
    'apps/HackermacLauncher/.build/*' \
    'snapshots/*' \
    'backups/*' \
    'private/*' \
    '.hackermacui/*' \
    '.env' \
    '.env.*' \
    '*.pem' \
    '*.key' \
    '*.p12' \
    '*.mobileprovision' || true)"
  [[ -z "$untracked" ]] || { printf '%s\n' "$untracked"; return 1; }
}

check_absolute_private_paths() {
  local matches
  matches="$(git -C "$ROOT" grep -nE '/Users/ignacio/' -- . \
    ':(exclude)scripts/release-check.sh' || true)"
  [[ -z "$matches" ]] || { printf '%s\n' "$matches"; return 1; }
}

check_secret_markers() {
  local matches
  matches="$(git -C "$ROOT" grep -nEi '(api[_-]?key|secret|token|password|private[_-]?key)\s*[:=]\s*[^[:space:]"'\''<>]+' -- . \
    ':(exclude)docs/privacy.md' \
    ':(exclude)scripts/release-check.sh' || true)"
  [[ -z "$matches" ]] || { printf '%s\n' "$matches"; return 1; }
}

cd "$ROOT"

printf '== HackermacUI Release Check ==\n'
run_gate 'clean git worktree' check_clean_git
run_gate 'public repo profile is default' check_public_profile
run_gate 'no private/generated files tracked' check_private_paths_not_tracked
run_gate 'no unignored private artifacts pending' check_no_unignored_private_artifacts
run_gate 'no absolute private /Users paths in tracked files' check_absolute_private_paths
run_gate 'no obvious secret assignments in tracked files' check_secret_markers
run_gate 'suite verification passes' "$ROOT/scripts/verify.sh"
run_gate 'live drift check passes' "$ROOT/scripts/check-drift.sh"

if (( failures > 0 )); then
  printf '\nRelease check failed: %d gate(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nRelease check passed.\n'
