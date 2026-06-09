# Dotfiles map

| Tool | Live path | Repo snapshot |
|---|---|---|
| AeroSpace | `~/.aerospace.toml` symlink | `configs/aerospace/aerospace.toml` |
| SwiftBar plugins | `~/SwiftBarPlugins/` | `configs/swiftbar/plugins/` |
| JankyBorders | `~/.config/borders/` | `configs/borders/` |
| Ghostty | `~/.config/ghostty/` | `configs/ghostty/` |
| Fastfetch | `~/.config/fastfetch/config.json` | `configs/fastfetch/config.json` |
| HackermacLauncher menu | Native launcher config | `configs/launcher/menu.json` |
| HackermacLauncher theme | Native launcher config | `configs/launcher/theme.json` |
| Template profiles | rendered into repo configs | `configs/templates/profiles/` |
| zsh example | manual copy | `configs/zsh/zshrc.example` |

## Runtime notes

| Area | Note |
|---|---|
| HackermacLauncher | Run from `apps/HackermacLauncher` with `swift run HackermacLauncher`, or build `dist/HackermacLauncher.app` with `scripts/build-launcher-app.sh`. |
| AeroSpace scripts | `configs/aerospace/scripts/` is synced to `~/.config/aerospace/scripts/` by `apply.sh`. |
| Templates | `scripts/template.sh` renders selected profile files into active repo config. It does not run `apply.sh`. |
| SwiftBar plugins | `apply.sh` syncs `configs/swiftbar/plugins/` to `~/SwiftBarPlugins/` and may delete unmanaged files in that folder. |
| JankyBorders | Inactive borders are transparent; launcher is blacklisted. |
| Fastfetch | Shell startup calls plain `fastfetch`; the module list lives in the fastfetch config so the default logo stays intact. |

## Public repo rule

Only share reusable configs. Raw snapshots, machine-specific overlays, credentials, logs, and local state belong in `~/.hackermacui/` or ignored folders.
