# HackermacUI Contracts

HackermacUI is extended through small, explicit contracts. Each contract has one owner and one stable boundary.

## Runtime Ownership API

| Concern | Owner | Extension point |
|---|---|---|
| Workspaces, focus, movement, monitor routing | AeroSpace | `configs/aerospace/aerospace.toml` or a profile template. |
| Menu-bar status | SwiftBar | `configs/swiftbar/plugins/`. |
| Focus border | JankyBorders | `configs/borders/bordersrc`. |
| Terminal UX | Ghostty | `configs/ghostty/config`. |
| Color palette | Repo theme | `configs/theme/palette.env`, consumed by borders/SwiftBar/Ghostty docs. |
| Apply, drift, backups, templates | Repo scripts | `scripts/*.sh`. |

Do not add a second tool for a responsibility that already has an owner.

## Template Profile Contract

Profiles live under `configs/templates/profiles/<name>/`.

Required files:

| File | Purpose |
|---|---|
| `aerospace.toml` | Full AeroSpace config rendered into `configs/aerospace/aerospace.toml`. |
| `profile.env` | Shared profile variables consumed by scripts/plugins. |

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
| `scripts/onboard.sh` | Guide first-run setup with prompts; may call installers, checks, and `apply.sh` only after explicit confirmation. |
| `scripts/install-deps.sh` | Install Homebrew dependencies after confirmation. |
| `scripts/doctor.sh` | Verify required tools and runtime state. |
| `scripts/apply.sh` | Mutate live config only after review and explicit user action. |

A curl bootstrap must not run `scripts/apply.sh` automatically.

## Verification Contract

Use this before publishing or after agent-driven changes:

```bash
./scripts/verify.sh
```

It checks shell syntax, JSON syntax, and semantic config contracts.

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
