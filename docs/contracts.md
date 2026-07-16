# HackermacUI Contracts

HackermacUI is extended through small, explicit contracts. Each contract has one owner and one stable boundary.

## Runtime Ownership API

| Concern | Owner | Extension point |
|---|---|---|
| Workspaces, focus, movement, monitor routing | AeroSpace | `configs/aerospace/aerospace.toml` or a profile template. |
| Command actions | HackermacLauncher | `configs/launcher/menu.json` or a profile menu template. |
| Menu-bar status | SwiftBar | `configs/swiftbar/plugins/`. |
| Focus border | JankyBorders | `configs/borders/bordersrc`. |
| Terminal UX | Ghostty | `configs/ghostty/config`. |
| Apply, drift, backups, templates | Repo scripts | `scripts/*.sh`. |

Do not add a second tool for a responsibility that already has an owner.

## Launcher Action Contract

`configs/launcher/menu.json` is the public command API for HackermacLauncher.

| Action type | Contract |
|---|---|
| `openApp` | Opens a macOS app by display name. |
| `openPath` | Opens a repo or local path. Use `${repo}` for repo-relative paths. |
| `openURL` | Opens URLs and macOS URL schemes. |
| `ghostty` | Opens a command in Ghostty, optionally with `cwd`. |
| `aerospace` | Runs AeroSpace CLI args. Keep this scoped to workspace/layout actions. |
| `run` | Runs a repo-owned script or allowlisted executable. Use `confirm: true` for mutating actions. |
| `appleScript` | Runs bounded AppleScript. Use sparingly and prefer `confirm: true` for system changes. |
| `sequence` | Runs multiple declarative actions in order. |

Rules:

- Prefer schema actions over arbitrary shell.
- Use `${repo}` instead of absolute personal paths.
- Use `confirm: true` for installs, template switches, apply-like behavior, and system mutations.
- Keep command-center workflows in HackermacLauncher, not SwiftBar.

## Launcher Theme Contract

`configs/launcher/theme.json` controls the Launcher panel and hotkey.

| Field | Contract |
|---|---|
| `material` | AppKit visual effect material name. |
| `cornerRadius` | Panel corner radius. |
| `accentColor` | Semantic accent name for future theme expansion. |
| `width` | Panel width in points. |
| `maxRows` | Menu row budget for future layout tuning. |
| `hotKey.key` | Trigger key. Supported values include `space` and letters `a` through `z`. |
| `hotKey.modifiers` | Trigger modifiers: `option`, `control`, `shift`, `command` and aliases. |

The default hotkey is `Option Space`.

## Template Profile Contract

Profiles live under `configs/templates/profiles/<name>/`.

Required files:

| File | Purpose |
|---|---|
| `aerospace.toml` | Full AeroSpace config rendered into `configs/aerospace/aerospace.toml`. |
| `profile.env` | Shared profile variables consumed by scripts/plugins. |

Optional files:

| File | Purpose |
|---|---|
| `launcher.menu.json` | Full launcher menu rendered into `configs/launcher/menu.json`. |

Select a live profile without mutating repo config:

```bash
./scripts/template.sh activate ignacio-dual-lg
./scripts/apply.sh
```

`activate` writes local state under `~/.hackermacui/`. `apply.sh` renders the active profile into local state and points live AeroSpace at it.

Render repo-published config only when changing the public baseline:

```bash
./scripts/template.sh render default
```

## SwiftBar Widget Contract

SwiftBar plugins are recurring executable code.

- Keep plugins finite: print and exit.
- Add timeouts around tools that can hang.
- Cache expensive rendering and icon conversion.
- Do not expose secrets, raw process args, private paths, or vault contents.
- Do not add remote/API polling by default.

## Installer Contract

Install and apply are separate.

| Step | Allowed behavior |
|---|---|
| `scripts/bootstrap.sh` | Clone/download repo and print safe next steps. |
| `scripts/onboard.sh` | Guide first-run setup with prompts; may call installers, checks, launcher build/login helpers, and `apply.sh` only after explicit confirmation. |
| `scripts/install-deps.sh` | Install Homebrew dependencies after confirmation. |
| `scripts/doctor.sh` | Verify required tools and runtime state. |
| `scripts/apply.sh` | Mutate live config only after review and explicit user action. |
| `scripts/launcher-login.sh` | Install or remove the local LaunchAgent for the built Launcher app after confirmation. |

A curl bootstrap must not run `scripts/apply.sh` automatically.

## Verification Contract

Use this before publishing or after agent-driven changes:

```bash
./scripts/verify.sh
```

It checks shell syntax, JSON syntax, semantic config contracts, and the Swift launcher build.

For publication, run:

```bash
./scripts/release-check.sh
```

The release gate adds git cleanliness, public profile, public-safety, and live drift checks.

CI may run the public subset with:

```bash
./scripts/release-check.sh --ci
```

`--ci` skips live drift and does not replace the local publication check.
