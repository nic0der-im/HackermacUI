# HackermacLauncher

HackermacLauncher is a native macOS command menu inspired by Omarchy's Walker menu. It is intentionally not a Raycast clone: it reads a declarative menu, renders a small glass panel, and executes allowlisted actions.

## Run

```bash
cd apps/HackermacLauncher
swift run HackermacLauncher
```

The launcher appears at startup and registers `Option+Space` while it is running.

This is currently a SwiftPM debug/runtime flow. Packaging as a signed `.app` and launch-at-login item is future work.

## Config

| File | Purpose |
|---|---|
| `../../configs/launcher/menu.json` | Menu tree and actions. |
| `../../configs/launcher/theme.json` | Panel material, width, and visual tuning. |

Supported action types:

- `openApp`
- `openPath`
- `openURL`
- `ghostty`
- `aerospace`
- `run`
- `appleScript`
- `sequence`

Actions are declarative by design. Add new behavior to the schema instead of executing arbitrary user input.

## Runtime Behavior

| Behavior | Detail |
|---|---|
| Hotkey | `Option+Space` toggles the panel. |
| Navigation | Arrow keys move, Enter opens/runs, Esc goes back or hides at root. |
| Open state | The panel resets to the root menu whenever it is shown. |
| Window ownership | AeroSpace keeps the launcher floating; JankyBorders blacklists it. |
| Safety | Use schema action types instead of arbitrary free-form launcher commands. |
