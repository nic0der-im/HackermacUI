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

## Safe Apply Path

Start with read-only checks and a backup:

```bash
./scripts/doctor.sh
./scripts/backup.sh
```

Apply only after reviewing the repo configs you want to sync:

```bash
./scripts/apply.sh
```

`apply.sh` creates a backup first, then symlinks `~/.aerospace.toml`, syncs AeroSpace helper scripts, SwiftBar plugins, JankyBorders config, Ghostty config, and Fastfetch config into live paths. The sync steps use delete semantics for managed folders, so do not run it as a blind restore.

## Bootstrap

For a fresh machine, the safe curl path is:

```bash
curl -fsSL https://raw.githubusercontent.com/nic0der-im/HackermacUI/main/scripts/bootstrap.sh | bash
```

The bootstrap clones the repo and prints the safe next steps. It does not run `apply.sh` automatically.

To install dependencies from a cloned repo:

```bash
./scripts/install-deps.sh
```

## macOS permissions

AeroSpace needs Accessibility permissions:

1. Open System Settings.
2. Go to Privacy & Security → Accessibility.
3. Enable AeroSpace.

SwiftBar should be allowed to run in the menu bar and at login if you want widgets always available.

## Launcher

HackermacLauncher is currently a SwiftPM app, not a packaged `.app` bundle:

```bash
cd apps/HackermacLauncher
swift run HackermacLauncher
```

While running, it registers `Option+Space` and reads `configs/launcher/menu.json` plus `configs/launcher/theme.json` from the repo.

Build the local app bundle with:

```bash
./scripts/build-launcher-app.sh
./scripts/restart-launcher.sh
```

Enable launch-at-login after building the app:

```bash
./scripts/launcher-login.sh install
```

Remove it with:

```bash
./scripts/launcher-login.sh uninstall
```
