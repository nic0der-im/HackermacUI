#!/usr/bin/env bash
set -euo pipefail

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
  brew install --cask nikitabobko/tap/aerospace swiftbar ghostty
  brew tap FelixKratz/formulae
  brew install borders gh fzf atuin zoxide zsh-autosuggestions zsh-syntax-highlighting fastfetch bat ripgrep
fi

if confirm 'Install optional local development tools?'; then
  brew install lazygit lazydocker node pnpm go redis postgresql@16 postgresql@18
  brew install --cask orbstack
fi

printf 'Dependency install finished. Run ./scripts/doctor.sh next.\n'
