# Desktop stack

## Runtime ownership

| Responsibility | Owner | Notes |
|---|---|---|
| Window tiling | AeroSpace | Do not run Rift, yabai, Amethyst, Rectangle, or skhd in parallel. |
| Workspace switching | AeroSpace | Six workspaces; `Alt+Tab` runs the active-workspace helper. |
| Floating window toggle and rules | AeroSpace | `Alt+Shift+Space` toggles the focused window; macOS utility apps and dialogs auto-float via `on-window-detected`. |
| Native menu-bar widgets | SwiftBar | `scripts/apply.sh` rsyncs `configs/swiftbar/plugins` into the folder set as SwiftBar's `PluginDirectory` (default `~/SwiftBarPlugins`). |
| Workspace indicator | SwiftBar plugin | `00-hackermacui.3s.sh` renders AeroSpace workspaces and compact app hints in the real macOS menu bar. |
| Optional menu-bar hiding | Ice | User-controlled cleanup layer for hiding everything except Battery, Control Center, Clock, and the HackermacUI SwiftBar plugin. |
| Window focus border | JankyBorders | Active border only; inactive border is transparent to avoid dark outer halos. |
| Terminal UI | Ghostty | Glass-style terminal config. |
| Templates/profiles | Repo scripts | `scripts/template.sh` renders selected profile files into active config. |

## Expected runtime

```txt
AeroSpace.app
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
| SwiftBar workspace strip has only maintenance dropdown links | SwiftBar | The menu bar remains a compact status surface. |
| Ice is optional, not core | User chrome | It hides unrelated menu-bar items but does not own HackermacUI widgets or command-center behavior. |
| Public default uses four workspaces | AeroSpace profile | Machine-specific monitor names stay in explicit templates such as `ignacio-dual-lg`. |
| Raycast is absent | Not used | Not part of the curated native stack. |

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
