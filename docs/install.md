# Install HackermacUI

HackermacUI assumes macOS with Homebrew. It is designed for a curated public setup, not a blind restore of another person's machine.

## Prerequisites

Install the core tools:

```bash
brew install --cask nikitabobko/tap/aerospace swiftbar ghostty
brew tap FelixKratz/formulae
brew install borders gh fzf atuin zoxide zsh-autosuggestions zsh-syntax-highlighting
```

Optional dev tools used by this setup:

```bash
brew install lazygit lazydocker node pnpm go redis postgresql@16 postgresql@18 fastfetch bat ripgrep
brew install --cask orbstack
```

## Apply

```bash
./scripts/doctor.sh
./scripts/backup.sh
./scripts/apply.sh
```

## macOS permissions

AeroSpace needs Accessibility permissions:

1. Open System Settings.
2. Go to Privacy & Security → Accessibility.
3. Enable AeroSpace.

SwiftBar should be allowed to run in the menu bar and at login if you want widgets always available.
