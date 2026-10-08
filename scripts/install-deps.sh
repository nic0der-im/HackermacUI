#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSUME_YES=0
if [[ "${1:-}" == "--yes" ]]; then
  ASSUME_YES=1
fi

confirm() {
  local prompt="$1"
  if [[ "$ASSUME_YES" == "1" ]]; then
    return 0
  fi
  printf '%s [y/N] ' "$prompt"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

need_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  printf 'Homebrew is required. Install it from https://brew.sh first.\n' >&2
  exit 1
}

need_brew

if confirm 'Install HackermacUI core Homebrew dependencies?'; then
  brew bundle --file "$ROOT/Brewfile"
fi

if confirm 'Install optional Ice menu-bar hider?'; then
  brew bundle --file "$ROOT/Brewfile.extras"
fi

printf 'Dependency install finished. Run ./scripts/doctor.sh next.\n'
