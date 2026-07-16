#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${HACKERMACUI_REPO_URL:-https://github.com/nic0der-im/HackermacUI.git}"
TARGET_DIR="${HACKERMACUI_TARGET_DIR:-$HOME/HackermacUI}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'HackermacUI bootstrap only supports macOS.\n' >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  printf 'git is required before bootstrapping HackermacUI.\n' >&2
  exit 1
fi

if [[ -d "$TARGET_DIR/.git" ]]; then
  printf 'HackermacUI repo already exists: %s\n' "$TARGET_DIR"
else
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

printf '\nHackermacUI downloaded to %s\n' "$TARGET_DIR"
printf 'Next safe path:\n'
printf '  ./scripts/onboard.sh\n'
printf '\nManual path if you do not want the onboarding wizard:\n'
printf '  ./scripts/install-deps.sh\n'
printf '  ./scripts/doctor.sh\n'
printf '  ./scripts/backup.sh\n'
printf '  ./scripts/check-drift.sh\n'
printf '  # Review configs before applying.\n'
printf '  ./scripts/apply.sh\n'
printf '\nBootstrap does not run apply.sh automatically.\n'
