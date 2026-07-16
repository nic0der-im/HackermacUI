#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

confirm() {
  local prompt="$1"
  printf '%s [y/N] ' "$prompt"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

section() {
  printf '\n== %s ==\n' "$1"
}

load_homebrew_env() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done

  return 1
}

run_step() {
  local prompt="$1"
  shift
  if confirm "$prompt"; then
    "$@"
  else
    printf 'Skipped: %s\n' "$prompt"
  fi
}

install_homebrew() {
  load_homebrew_env || true
  if command -v brew >/dev/null 2>&1; then
    printf 'Homebrew found: %s\n' "$(command -v brew)"
    return 0
  fi

  printf 'Homebrew is required for HackermacUI dependencies.\n'
  if confirm 'Install Homebrew using the official installer now?'; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_homebrew_env || true
  else
    printf 'Install Homebrew from https://brew.sh, then rerun ./scripts/onboard.sh.\n'
    return 1
  fi
}

open_accessibility_settings() {
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' >/dev/null 2>&1 || open -a 'System Settings'
  printf 'Enable AeroSpace in Privacy & Security -> Accessibility.\n'
}

open_login_items_settings() {
  open 'x-apple.systempreferences:com.apple.LoginItems-Settings.extension' >/dev/null 2>&1 || open -a 'System Settings'
  printf 'Allow SwiftBar, AeroSpace, Ice, and HackermacLauncher at login if prompted.\n'
}

open_ice() {
  if [[ -d /Applications/Ice.app || -d "$HOME/Applications/Ice.app" ]]; then
    open -a Ice
    printf 'In Ice, keep Battery, Control Center, Clock, and the HackermacUI SwiftBar plugin visible. Hide the rest as desired.\n'
  else
    printf 'Ice is not installed. Run ./scripts/install-deps.sh or install jordanbaird-ice from Homebrew.\n'
  fi
}

apply_reviewed_configs() {
  printf 'This will run ./scripts/apply.sh. It backs up first, then syncs managed config folders into live paths.\n'
  printf 'Review README.md and docs/dotfiles.md before continuing if this is a new machine.\n'
  if confirm 'Apply HackermacUI configs to this machine now?'; then
    "$ROOT/scripts/apply.sh"
  else
    printf 'Skipped live config apply. Run ./scripts/apply.sh later after review.\n'
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'HackermacUI onboarding only supports macOS.\n' >&2
  exit 1
fi

cd "$ROOT"

section 'HackermacUI onboarding'
printf 'This wizard installs dependencies, opens permission panes, builds the launcher, and can apply configs after explicit confirmation.\n'
printf 'It is not a blind restore. Private machine state stays local.\n'

section 'Homebrew'
install_homebrew

section 'Dependencies'
run_step 'Install HackermacUI dependencies with guarded prompts?' "$ROOT/scripts/install-deps.sh"

section 'Checks'
run_step 'Run doctor checks now?' "$ROOT/scripts/doctor.sh"

section 'macOS permissions'
run_step 'Open Accessibility settings for AeroSpace?' open_accessibility_settings
run_step 'Open Login Items settings?' open_login_items_settings

section 'Launcher'
run_step 'Build HackermacLauncher.app?' "$ROOT/scripts/build-launcher-app.sh"
run_step 'Restart HackermacLauncher now?' "$ROOT/scripts/restart-launcher.sh"
run_step 'Install HackermacLauncher launch-at-login item?' "$ROOT/scripts/launcher-login.sh" install

section 'Optional Ice cleanup'
run_step 'Open Ice and configure visible menu-bar items?' open_ice

section 'Live config apply'
apply_reviewed_configs

section 'Next checks'
run_step 'Run drift check after onboarding?' "$ROOT/scripts/check-drift.sh"
run_step 'Run verification suite?' "$ROOT/scripts/verify.sh"

printf '\nOnboarding finished. Reopen HackermacLauncher with Option+Space after it is running.\n'
