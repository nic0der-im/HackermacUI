# HackermacUI

A public, curated macOS desktop setup inspired by Omarchy: AeroSpace for tiling, HackermacLauncher for the command center, SwiftBar for native menu-bar widgets, JankyBorders for focus borders, and Ghostty for the terminal feel.

HackermacUI is intentionally not a raw machine backup. It keeps shareable dotfiles, scripts, and docs in git while exact local snapshots and private machine state stay outside the public repo.

> Screenshot: add your own screenshot to `assets/screenshot.png` and embed it here when ready.

## Stack

| Layer | Tool | Role |
|---|---|---|
| Tiling window manager | AeroSpace | Workspaces, focus, movement, gaps, keyboard workflow |
| Command center | HackermacLauncher | Native Swift Omarchy-inspired launcher menus and safe declarative actions on `Option+Space` |
| Native menu bar widgets | SwiftBar | Lightweight scriptable widgets in the real macOS menu bar |
| Focus borders | JankyBorders / `borders` | Active-window visual focus, with inactive borders transparent |
| Terminal | Ghostty | Transparent/glass terminal styling |
| Shell helpers | zsh, fzf, atuin, zoxide | Fast terminal workflow |
| Dev workflow | OrbStack, PostgreSQL, Redis, pnpm, node, go, gh, lazygit | Local development support |

## Quick start

```bash
git clone https://github.com/nic0der-im/HackermacUI.git
cd HackermacUI
./scripts/doctor.sh
./scripts/backup.sh
# Optional: applies repo configs to live paths after review.
./scripts/apply.sh
```

`apply.sh` mutates live config paths and uses sync/delete semantics for managed folders. Review the changed configs before running it. After applying, open AeroSpace and SwiftBar once so macOS can grant any required permissions.

## Current Desktop Behavior

| Behavior | Current state |
|---|---|
| Launcher hotkey | `Option+Space` opens HackermacLauncher while its SwiftPM debug binary is running. |
| Launcher menus | TUIs, Gamemode, Switch, Install, Config, Terminal, Theme, and Keybindings. |
| Workspaces | AeroSpace manages six workspaces; `Alt+1..6` switches and `Alt+Ctrl+1..6` moves windows. |
| Workspace strip | SwiftBar runs `aerospace-workspaces.3s.sh`, refreshed by an AeroSpace workspace-change hook plus a 3s fallback interval. |
| Borders | JankyBorders shows a 3px active border; inactive borders are transparent; HackermacLauncher is blacklisted. |
| Removed tools | Raycast, SketchyBar, AltTab, Hammerspoon, Rift, yabai, skhd, and Rectangle are intentionally not part of runtime. |

## Commands

```bash
./scripts/status.sh       # show current desktop-management state
./scripts/doctor.sh       # verify required apps, CLIs, and macOS settings
./scripts/backup.sh       # copy live configs to ~/.hackermacui/backups/<timestamp>
./scripts/check-drift.sh  # compare live configs against repo snapshots
./scripts/snapshot.sh     # private local snapshot, ignored by git
./scripts/apply.sh        # apply repo configs to the live machine after review
```

## Repository layout

```txt
apps/      Native macOS tools such as HackermacLauncher
configs/   Shareable dotfiles, launcher menus, and SwiftBar plugins
docs/      Install guide, stack notes, privacy model, roadmap
scripts/   Apply, backup, status, doctor, and drift helpers
```

## Philosophy

AeroSpace owns window/workspace behavior. HackermacLauncher owns the command center launcher. SwiftBar displays native widgets. JankyBorders shows focus. Ghostty owns terminal feel. Tools should not fight for the same responsibility.
