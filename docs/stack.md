# Desktop stack

## Runtime ownership

| Responsibility | Owner | Notes |
|---|---|---|
| Window tiling | AeroSpace | Do not run Rift, yabai, Amethyst, Rectangle, or skhd in parallel. |
| Workspace switching | AeroSpace | Six workspaces; `Alt+Tab` runs the active-workspace helper. |
| Command center launcher | HackermacLauncher | Native Swift Omarchy-inspired command center. Excluded from borders and kept floating. |
| Floating window toggle and rules | AeroSpace | `Alt+Shift+Space` toggles the focused window; macOS utility apps and dialogs auto-float via `on-window-detected`. |
| Native menu-bar widgets | SwiftBar | `~/SwiftBarPlugins` is symlinked to `configs/swiftbar/plugins`. |
| Workspace indicator | SwiftBar plugin | `00-hackermacui.3s.sh` renders AeroSpace workspaces and compact app hints in the real macOS menu bar. |
| Optional menu-bar hiding | Ice | User-controlled cleanup layer for hiding everything except Battery, Control Center, Clock, and the HackermacUI SwiftBar plugin. |
| Window focus border | JankyBorders | Active border only; inactive border is transparent to avoid dark outer halos. |
| Terminal UI | Ghostty | Glass-style terminal config. |
| Templates/profiles | Repo scripts | `scripts/template.sh` renders selected profile files into active config. |

## Expected runtime

```txt
AeroSpace.app
HackermacLauncher
SwiftBar.app
borders
```

Optional user chrome:

```txt
Ice.app
```

## Current Rules

| Rule | Owner | Why |
|---|---|---|
| `Option+Space` opens HackermacLauncher | HackermacLauncher | Avoids `Cmd+Shift+Space` conflict with 1Password and Finder's `Cmd+Alt+Space` search chord. |
| `Cmd+Shift+A` opens OpenCode CLI | AeroSpace + Ghostty | Direct fast path for agent work; the full Agents menu stays in HackermacLauncher. |
| HackermacLauncher stays floating and borderless | AeroSpace + JankyBorders | Command center panels should not be tiled or visually framed as app windows. |
| SwiftBar workspace strip has only maintenance dropdown links | SwiftBar | The menu bar remains a compact status surface; command-center workflows stay in HackermacLauncher. |
| Ice is optional, not core | User chrome | It hides unrelated menu-bar items but does not own HackermacUI widgets or command-center behavior. |
| Public default uses four workspaces | AeroSpace profile | Machine-specific monitor names stay in explicit templates such as `ignacio-dual-lg`. |
| Raycast is absent | HackermacLauncher | Native launcher replaced Raycast after the menu shape was validated. |

## Intentionally absent

```txt
SketchyBar
Bartender
Hidden Bar
AltTab
Hammerspoon
Rift
yabai
skhd
Rectangle
```
