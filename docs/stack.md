# Desktop stack

## Runtime ownership

| Responsibility | Owner | Notes |
|---|---|---|
| Window tiling | AeroSpace | Do not run Rift, yabai, Amethyst, Rectangle, or skhd in parallel. |
| Workspace switching | AeroSpace | `Alt+Tab` maps to `workspace-back-and-forth`. |
| Native menu-bar widgets | SwiftBar | Plugins live in `~/SwiftBarPlugins`. |
| Workspace indicator | SwiftBar plugin | `aerospace-workspaces.2s.sh` renders AeroSpace workspaces in the real macOS menu bar. |
| Window focus border | JankyBorders | `borders` can run via Homebrew service or AeroSpace startup. |
| Terminal UI | Ghostty | Glass-style terminal config. |

## Expected runtime

```txt
AeroSpace.app
SwiftBar.app
borders
```

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
