# Dotfiles map

| Tool | Live path | Repo snapshot |
|---|---|---|
| AeroSpace | `~/.aerospace.toml` symlink | `configs/aerospace/aerospace.toml` |
| SwiftBar plugins | `~/SwiftBarPlugins/` | `configs/swiftbar/plugins/` |
| JankyBorders | `~/.config/borders/` | `configs/borders/` |
| Ghostty | `~/.config/ghostty/` | `configs/ghostty/` |
| HackermacLauncher menu | Native launcher config | `configs/launcher/menu.json` |
| HackermacLauncher theme | Native launcher config | `configs/launcher/theme.json` |
| zsh example | manual copy | `configs/zsh/zshrc.example` |

## Runtime notes

| Area | Note |
|---|---|
| HackermacLauncher | Run from `apps/HackermacLauncher` with `swift run HackermacLauncher`; packaging as `.app` is still future work. |
| AeroSpace scripts | `configs/aerospace/scripts/` is synced to `~/.config/aerospace/scripts/` by `apply.sh`. |
| SwiftBar plugins | `apply.sh` syncs `configs/swiftbar/plugins/` to `~/SwiftBarPlugins/` and may delete unmanaged files in that folder. |
| JankyBorders | Inactive borders are transparent; launcher is blacklisted. |

## Public repo rule

Only share reusable configs. Raw snapshots, machine-specific overlays, credentials, logs, and local state belong in `~/.hackermacui/` or ignored folders.
