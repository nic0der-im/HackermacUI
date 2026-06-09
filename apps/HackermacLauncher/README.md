# HackermacLauncher

HackermacLauncher is a native macOS command menu inspired by Omarchy's Walker menu. It is intentionally not a Raycast clone: it reads a declarative menu, renders a small glass panel, and executes allowlisted actions.

## Run

```bash
cd apps/HackermacLauncher
swift run HackermacLauncher
```

The launcher appears at startup and registers `Option+Space` while it is running.

For the app-bundle flow, build the local `.app` bundle:

```bash
./scripts/build-launcher-app.sh
./scripts/restart-launcher.sh
```

The generated bundle lives at `dist/HackermacLauncher.app` and is intentionally ignored by git. Launch-at-login is still future work.

Enable or remove launch-at-login with:

```bash
./scripts/launcher-login.sh install
./scripts/launcher-login.sh uninstall
```

## Config

| File | Purpose |
|---|---|
| `../../configs/launcher/menu.json` | Menu tree and actions. |
| `../../configs/launcher/theme.json` | Panel material, width, visual tuning, and hotkey. |

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
| Hotkey | Configured in `configs/launcher/theme.json`; default is `Option+Space`. |
| Navigation | Arrow keys move, Enter opens/runs, Esc goes back or hides at root. |
| Open state | The panel resets to the root menu whenever it is shown. |
| Window ownership | AeroSpace keeps the launcher floating; JankyBorders blacklists it. |
| Safety | Use schema action types instead of arbitrary free-form launcher commands. |
