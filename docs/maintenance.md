# Maintenance guide

## Before changing UI behavior

1. Run `./scripts/status.sh`.
2. Run `./scripts/backup.sh`.
3. Change one tool at a time.
4. Reload only the affected tool.
5. Run `./scripts/check-drift.sh`.
6. Run `./scripts/verify.sh` when scripts, JSON, or launcher code changed.
7. Commit with a conventional commit message.

Do not run `./scripts/apply.sh` as a routine reload. It applies multiple managed config trees to live paths. Prefer targeted reloads while iterating.

## Reload commands

```bash
aerospace reload-config
open 'swiftbar://refreshallplugins'
~/.config/borders/bordersrc
```

## Current Targeted Owners

| Area | Owner | Config | Reload |
|---|---|---|---|
| Workspaces, gaps, app floating rules | AeroSpace | `configs/aerospace/aerospace.toml` | `aerospace reload-config` |
| Command center | HackermacLauncher | `configs/launcher/menu.json`, `configs/launcher/theme.json` | restart `swift run HackermacLauncher` |
| Menu-bar workspace strip | SwiftBar | `configs/swiftbar/plugins/00-hackermacui.3s.sh` | `open 'swiftbar://refreshallplugins'` |
| Focus border | JankyBorders | `configs/borders/bordersrc` | `~/.config/borders/bordersrc` |
| Terminal feel | Ghostty | `configs/ghostty/config` | restart Ghostty windows |
| Templates/profiles | Repo scripts | `configs/templates/profiles/`, `scripts/template.sh` | `scripts/template.sh activate <profile> && scripts/apply.sh` |
| Launcher login item | LaunchAgent script | `scripts/launcher-login.sh` | `scripts/launcher-login.sh install` |

## Borders Tuning

JankyBorders is intentionally tuned to avoid dark inactive halos:

| Option | Value | Reason |
|---|---|---|
| `width` | `3.0` | Keeps the active focus border visible without overpowering native app chrome. |
| `inactive_color` | `0x00000000` | Prevents inactive windows from showing a black outer frame. |
| `blacklist` | includes `HackermacLauncher` | Keeps the glass launcher panel clean. |

## Rollback principle

Use git history for public config rollback. Use `~/.hackermacui/backups/` for private machine-state rollback.
