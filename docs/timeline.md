# Timeline

## 2026-05-19

- Chose AeroSpace as the only tiling window manager. Rift was explicitly rejected.
- Removed stale Hammerspoon LaunchAgent.
- Removed AltTab; AeroSpace owns `Alt+Tab`.
- Unified Ghostty to the pyrorhythm-inspired config.
- Created HackermacUI as the source of documentation and future timeline.
- Removed SketchyBar completely from the live machine.
- Installed SwiftBar and configured `~/SwiftBarPlugins` as plugin folder.
- Added first SwiftBar widget: AeroSpace workspace indicator/switcher in the native macOS menu bar.
- Reduced AeroSpace top gap to `8` because the native macOS menu bar owns top space.

## 2026-05-20

- Prepared HackermacUI for public, curated-safe publication.
- Removed raw runtime snapshots and machine-specific zsh captures from public git.
- Added public install, privacy, roadmap, and maintenance documentation.

## 2026-06-08

- Rejected `Cmd+Alt+Space` as a launcher chord because macOS Finder captures it for Search This Mac.
- Chose native Swift `HackermacLauncher` as the Omarchy-like command center after confirming the desired scope is an Omarchy menu, not a general-purpose launcher clone.
- Scoped HackermacLauncher around TUIs, Gamemode, Switch, Install, Config, Terminal, Theme, and Keybindings.
- Removed Raycast as a runtime dependency after using it only to validate the menu shape.
- Switched HackermacLauncher hotkey to `Option+Space` because `Cmd+Shift+Space` opens 1Password.
- Stabilized HackermacLauncher submenu navigation with explicit current-item state and root reset on open.
- Added AeroSpace and JankyBorders guardrails so HackermacLauncher stays floating and borderless.
- Tuned JankyBorders to a 3px active border with transparent inactive borders to remove dark outer halos.
- Kept SwiftBar as a compact display-only AeroSpace workspace strip with cached composite rendering and workspace-change refresh.
- Changed `Alt+Tab` from AeroSpace `workspace-back-and-forth` to `configs/aerospace/scripts/next-active-workspace.sh`.
