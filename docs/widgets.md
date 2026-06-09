# SwiftBar Widgets

SwiftBar is the native menu-bar layer. Keep it minimal, useful, and non-duplicative with macOS built-ins. The default UI is intentionally one AeroSpace workspace strip, inspired by Waybar-style workspace visibility without recreating a full Linux bar.

## AeroSpace workspace strip

`00-hackermacui.3s.sh` renders the cached image-based composite strip by default. It delegates state capture and image rendering to `.helpers/render-hackermac-workspaces.sh`. The compact text renderer remains available as a fallback or opt-out via `AEROSPACE_SWIFTBAR_RENDER_MODE=text`.

When image mode is enabled, icon extraction, base64 output, and the final composite strip must stay cached under SwiftBar's plugin cache path. Do not extract icons or redraw the composite PNG on every refresh without state-hash invalidation. AeroSpace triggers an immediate SwiftBar refresh on workspace changes; the plugin interval remains a fallback.

## Detected workflow apps

| Area | Detected tools | Widget idea |
|---|---|---|
| Tiling | AeroSpace | Composite workspace strip with focused styling and cached real app icons. Implemented. |
| Terminal/dev shell | Ghostty, git, gh, pnpm, node, go, lazygit | Current repo status, branch, dirty count, PR/CI shortcut. |
| IDE/AI coding | PhpStorm, Codex | Focused project shortcut, local dev server status. |
| Browser | Google Chrome, Safari | Focus-mode shortcut or active workspace browser count. |
| Local services | OrbStack, PostgreSQL, Redis | Compact service health: containers, DB, ports. |
| Knowledge | Obsidian | Quick vault/open daily note. |
| Security | 1P CLI | Lock/unlock state or quick access shortcut. |
| Communication | Discord, WhatsApp | Keep out of the bar unless there is a concrete notification workflow. |

## Current Contract

| Decision | Current state |
|---|---|
| Default plugins | `00-hackermacui.3s.sh` only. |
| Interaction model | PNG strip in the menu bar; dropdown is limited to small HackermacUI maintenance links. Command-center actions belong in HackermacLauncher. |
| Refresh path | AeroSpace workspace keys and `exec-on-workspace-change` trigger immediate SwiftBar refreshes; the 3s interval is fallback. |
| Rendering | Cached composite PNG by default. Text mode remains available via `AEROSPACE_SWIFTBAR_RENDER_MODE=text`. |
| Performance | State-hash invalidation for the workspace strip, cached composite PNGs, and cached base64 output. |

## Build order

1. AeroSpace workspace strip.
2. Only add another widget if it beats macOS built-ins and does not add background noise.
