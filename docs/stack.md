# Desktop stack

## Runtime ownership

| Responsibility | Owner | Notes |
|---|---|---|
| Window tiling | AeroSpace | Do not run Rift, yabai, Amethyst, Rectangle, or skhd in parallel. |
| Workspace switching | AeroSpace | Six workspaces; `Alt+Tab` runs the active-workspace helper. |
| Command center launcher | HackermacLauncher | Native Swift Omarchy-inspired command center. Excluded from borders and kept floating. |
| Floating window toggle and rules | AeroSpace | `Alt+Shift+Space` toggles the focused window; macOS utility apps and dialogs auto-float via `on-window-detected`. |
| Native menu-bar widgets | SwiftBar | `~/SwiftBarPlugins` is symlinked to `configs/swiftbar/plugins`. |
| Workspace indicator | SwiftBar plugin | `aerospace-workspaces.3s.sh` renders AeroSpace workspaces and compact app hints in the real macOS menu bar. |
| Window focus border | JankyBorders | Active border only; inactive border is transparent to avoid dark outer halos. |
| Terminal UI | Ghostty | Glass-style terminal config. |

## Expected runtime

```txt
AeroSpace.app
HackermacLauncher
SwiftBar.app
borders
```

## Current Rules

| Rule | Owner | Why |
|---|---|---|
| `Option+Space` opens HackermacLauncher | HackermacLauncher | Avoids `Cmd+Shift+Space` conflict with 1Password and Finder's `Cmd+Alt+Space` search chord. |
| HackermacLauncher stays floating and borderless | AeroSpace + JankyBorders | Command center panels should not be tiled or visually framed as app windows. |
| SwiftBar workspace strip has no dropdown actions | SwiftBar | The menu bar remains a compact status surface, not a second command center. |
| Raycast is absent | HackermacLauncher | Native launcher replaced Raycast after the menu shape was validated. |

## Intentionally absent

```txt
SketchyBar
AltTab
Hammerspoon
Rift
yabai
skhd
Rectangle
```
