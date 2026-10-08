#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEDY=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/update.sh [--greedy] [--dry-run]

Updates Homebrew dependencies for HackermacUI and runs doctor checks after.

Options:
  --greedy    Also upgrade casks that opt out of default upgrades (auto-update apps).
  --dry-run   Show outdated formulae/casks only; make no changes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --greedy) GREEDY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
  shift
done

need_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  printf 'Homebrew is required. Install it from https://brew.sh first.\n' >&2
  exit 1
}

need_brew

printf '== Updating Homebrew ==\n'
brew update

printf '\n== Outdated ==\n'
brew outdated
brew outdated --cask

if [[ "$DRY_RUN" == "1" ]]; then
  printf '\nDry run: no packages upgraded.\n'
  exit 0
fi

printf '\n== Upgrading formulae ==\n'
brew upgrade

printf '\n== Upgrading casks ==\n'
if [[ "$GREEDY" == "1" ]]; then
  brew upgrade --cask --greedy
else
  brew upgrade --cask
fi

printf '\n== Removing unused dependencies ==\n'
brew autoremove

printf '\n== Cleaning up ==\n'
brew cleanup --prune=all

printf '\n== Doctor checks ==\n'
"$ROOT/scripts/doctor.sh"
