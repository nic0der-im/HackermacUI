# Templates And Profiles

Templates let HackermacUI swap desktop layouts without changing tool ownership.

## Quick Path

```bash
./scripts/template.sh list
./scripts/template.sh current
./scripts/template.sh switch default
./scripts/template.sh switch ignacio-dual-lg --reload
```

The Launcher exposes the same flow under `Profiles`.

## Profiles

| Profile | Purpose |
|---|---|
| `default` | Public single-monitor profile with 4 workspaces. |
| `ignacio-dual-lg` | Ignacio's dual-monitor profile with 6 workspaces and LG/built-in routing. |

## Rendered Files

| Template file | Rendered target |
|---|---|
| `configs/templates/profiles/<name>/aerospace.toml` | `configs/aerospace/aerospace.toml` |
| `configs/templates/profiles/<name>/profile.env` | `configs/aerospace/scripts/profile.env` |
| `configs/templates/profiles/<name>/launcher.menu.json` | `configs/launcher/menu.json` |

Switching profiles mutates repo config files. If live config is symlinked to the repo, an AeroSpace reload makes the selected profile live.

## Safety

- `switch` runs `scripts/backup.sh` before rendering.
- `switch` does not run `scripts/apply.sh`.
- `--reload` only runs targeted `aerospace reload-config` and SwiftBar refresh.
- Keep private or machine-specific templates explicit; do not hide them inside the public default.
