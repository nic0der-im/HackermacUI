# SwiftBar Widgets

SwiftBar is the native menu-bar layer. Keep it minimal, useful, and non-duplicative with macOS built-ins. The default UI is intentionally one AeroSpace workspace strip, inspired by Waybar-style workspace visibility without recreating a full Linux bar.

## AeroSpace workspace strip

`aerospace-workspaces.3s.sh` renders the top-bar workspace strip as a cached composite PNG. The strip includes workspace numbers, focused-state styling, quiet empty workspaces, and real app icons per window when macOS app bundles expose `.icns` assets. This keeps SwiftBar + ICE as the native menu-bar layer while avoiding the one-image-per-item limitation for inline app icons.

Icon extraction and the final composite strip must stay cached under SwiftBar's plugin cache path. Do not extract icons or redraw the composite PNG on every refresh without state-hash invalidation. AeroSpace triggers a debounced SwiftBar refresh on workspace changes; the plugin interval remains a fallback.

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
| Default plugin | `aerospace-workspaces.3s.sh` only. |
| Interaction model | Display-only strip; command actions belong in HackermacLauncher. |
| Refresh path | AeroSpace `exec-on-workspace-change` triggers a debounced refresh; the 3s interval is fallback. |
| Rendering | Cached composite PNG with workspace numbers, focus styling, and app icons when available. |
| Performance | State-hash invalidation; no repeated icon extraction or redraw when state is unchanged. |

## Build order

1. AeroSpace workspace strip.
2. Only add another widget if it beats macOS built-ins and does not add background noise.
