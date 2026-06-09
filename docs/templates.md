# Templates And Profiles

Templates let HackermacUI swap desktop layouts without changing tool ownership.

## Quick Path

```bash
./scripts/template.sh list
./scripts/template.sh current
./scripts/template.sh live
./scripts/template.sh activate ignacio-dual-lg
./scripts/apply.sh
```

The Launcher exposes the live-profile flow under `Profiles`.

## Profiles

| Profile | Purpose |
|---|---|
| `default` | Public single-monitor profile with 4 workspaces. |
| `ignacio-dual-lg` | Ignacio's dual-monitor profile with 6 workspaces and LG/built-in routing. |

## Repo Rendered Files

| Template file | Rendered target |
|---|---|
| `configs/templates/profiles/<name>/aerospace.toml` | `configs/aerospace/aerospace.toml` |
| `configs/templates/profiles/<name>/profile.env` | `configs/aerospace/scripts/profile.env` |
| `configs/templates/profiles/<name>/launcher.menu.json` | `configs/launcher/menu.json` |

`render` and `switch` mutate repo config files. Use them when changing what the repository publishes.

## Live Profile Files

`activate` selects the profile for the current machine without mutating repo config.

| Local file | Purpose |
|---|---|
| `~/.hackermacui/live-profile` | Selected local live profile. |
| `~/.hackermacui/rendered/aerospace.toml` | Rendered live AeroSpace config used by `apply.sh`. |
| `~/.hackermacui/rendered/profile.env` | Rendered live profile metadata used by helper scripts. |

`apply.sh` links `~/.aerospace.toml` to the local rendered config. This keeps the repo public default clean while the live machine can run a private or machine-specific profile.

## Safety

- `switch` runs `scripts/backup.sh` before rendering.
- `switch` does not run `scripts/apply.sh`.
- `activate` does not mutate repo files.
- `--reload` only runs targeted `aerospace reload-config` and SwiftBar refresh.
- Keep private or machine-specific templates explicit; do not hide them inside the public default.
