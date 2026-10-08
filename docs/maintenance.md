# Maintenance guide

## Before changing UI behavior

1. Run `./scripts/status.sh`.
2. Run `./scripts/backup.sh`.
3. Change one tool at a time.
4. Reload only the affected tool.
5. Run `./scripts/check-drift.sh`.
6. Run `./scripts/verify.sh` when scripts, JSON, or profile templates changed.
7. Run `./scripts/release-check.sh` before publishing or pushing.
8. Commit with a conventional commit message.

GitHub Actions runs shellcheck and `./scripts/release-check.sh --ci` on push and pull requests; the release gate already runs `./scripts/verify.sh` internally. The CI release gate skips live drift; local release still requires the normal release check.

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
| First-run setup | Onboarding script | `scripts/onboard.sh` | rerun selected prompted steps |
| Workspaces, gaps, app floating rules | AeroSpace | `configs/aerospace/aerospace.toml` | `aerospace reload-config` |
| Menu-bar workspace strip | SwiftBar | `configs/swiftbar/plugins/00-hackermacui.3s.sh` | `open 'swiftbar://refreshallplugins'` |
| Focus border | JankyBorders | `configs/borders/bordersrc` | `~/.config/borders/bordersrc` |
| Terminal feel | Ghostty | `configs/ghostty/config` | restart Ghostty windows |
| Color palette | Repo theme | `configs/theme/palette.env` | `aerospace reload-config`, `~/.config/borders/bordersrc`, `open 'swiftbar://refreshallplugins'` (each consumer independently) |
| Templates/profiles | Repo scripts | `configs/templates/profiles/`, `scripts/template.sh` | `scripts/template.sh activate <profile> && scripts/apply.sh` |

## Borders Tuning

JankyBorders is intentionally tuned to avoid dark inactive halos:

| Option | Value | Reason |
|---|---|---|
| `width` | `3.0` | Keeps the active focus border visible without overpowering native app chrome. |
| `inactive_color` | `0x00000000` | Prevents inactive windows from showing a black outer frame. |

## Updating packages

`Brewfile` at the repo root is the single source of truth for dependencies. To update:

```bash
./scripts/update.sh            # brew update, upgrade, autoremove, cleanup, then doctor.sh
./scripts/update.sh --dry-run  # show outdated packages only, change nothing
./scripts/update.sh --greedy   # also upgrade casks that opt out of default upgrades
```

`update.sh` never calls `scripts/apply.sh`; it only touches Homebrew's own state.

## Rollback principle

Use git history for public config rollback. Use `~/.hackermacui/backups/` for private machine-state rollback.
