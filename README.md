# HackermacUI

A public, curated macOS desktop setup inspired by Omarchy: AeroSpace for tiling, SwiftBar for native menu-bar widgets, JankyBorders for focus borders, and Ghostty for the terminal feel.

HackermacUI is intentionally not a raw machine backup. It keeps shareable dotfiles, scripts, and docs in git while exact local snapshots and private machine state stay outside the public repo.

> Screenshot: add your own screenshot to `assets/screenshot.png` and embed it here when ready.

## Stack

| Layer | Tool | Role |
|---|---|---|
| Tiling window manager | AeroSpace | Workspaces, focus, movement, gaps, keyboard workflow |
| Native menu bar widgets | SwiftBar | Lightweight scriptable widgets in the real macOS menu bar |
| Focus borders | JankyBorders / `borders` | Active-window visual focus |
| Terminal | Ghostty | Transparent/glass terminal styling |
| Shell helpers | zsh, fzf, atuin, zoxide | Fast terminal workflow |
| Dev workflow | OrbStack, PostgreSQL, Redis, pnpm, node, go, gh, lazygit | Local development support |

## Quick start

```bash
git clone https://github.com/nic0der-im/HackermacUI.git
cd HackermacUI
./scripts/doctor.sh
./scripts/backup.sh
./scripts/apply.sh
```

After applying, open AeroSpace and SwiftBar once so macOS can grant any required permissions.

## Commands

```bash
./scripts/status.sh       # show current desktop-management state
./scripts/doctor.sh       # verify required apps, CLIs, and macOS settings
./scripts/backup.sh       # copy live configs to ~/.hackermacui/backups/<timestamp>
./scripts/check-drift.sh  # compare live configs against repo snapshots
./scripts/snapshot.sh     # private local snapshot, ignored by git
./scripts/apply.sh        # apply repo configs to the live machine
```

## Repository layout

```txt
configs/   Shareable dotfiles and SwiftBar plugins
docs/      Install guide, stack notes, privacy model, roadmap
scripts/   Apply, backup, status, doctor, and drift helpers
```

## Philosophy

AeroSpace owns window/workspace behavior. SwiftBar displays native widgets. JankyBorders shows focus. Ghostty owns terminal feel. Tools should not fight for the same responsibility.
