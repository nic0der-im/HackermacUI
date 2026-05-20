# SwiftBar widget roadmap

SwiftBar is the native menu-bar layer. Keep widgets small, useful, and non-duplicative with macOS built-ins.

## Detected workflow apps

| Area | Detected tools | Widget idea |
|---|---|---|
| Tiling | AeroSpace | Workspace indicator and switcher. Implemented. |
| Terminal/dev shell | Ghostty, git, gh, pnpm, node, go, lazygit | Current repo status, branch, dirty count, PR/CI shortcut. |
| IDE/AI coding | PhpStorm, Codex | Focused project shortcut, local dev server status. |
| Browser | Google Chrome, Safari | Focus-mode shortcut or active workspace browser count. |
| Local services | OrbStack, PostgreSQL, Redis | Compact service health: containers, DB, ports. |
| Knowledge | Obsidian | Quick vault/open daily note. |
| Security | 1P CLI | Lock/unlock state or quick access shortcut. |
| Communication | Discord, WhatsApp | Keep out of the bar unless there is a concrete notification workflow. |

## Build order

1. AeroSpace workspaces.
2. Dev services health: OrbStack/PostgreSQL/Redis.
3. Project status: current git repo + GitHub PR shortcut.
4. Obsidian daily note shortcut.
5. Calendar next event, only if it adds more signal than the native Calendar menu.
