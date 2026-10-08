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

## 2026-09-26

- Removed HackermacLauncher (SwiftUI command panel, `Option+Space`) from the repo and the live machine.
- Added `Brewfile`, `Brewfile.dev`, and `Brewfile.extras` as the single source of truth for Homebrew packages; `scripts/install-deps.sh` installs through `brew bundle`.
- Added `scripts/update.sh` for the Homebrew update, upgrade, and cleanup flow.
- Fixed `scripts/verify.sh` so every shell script gets a syntax check, not only the first file of each list.
- Added `configs/theme/palette.env`, a single GitHub Dark-family color source for `bordersrc` and the Ghostty focus colors (deployed to `~/.config/hackermacui/theme/`, with repo-relative and built-in fallbacks); `scripts/apply.sh`, `check-drift.sh`, `backup.sh`, and `snapshot.sh` all learned about it.
- Unified the focus color: the JankyBorders active border and Ghostty's cursor/selection use the same green; aligned Ghostty's ANSI palette (1/2/4, 9/10/12) to GitHub Dark, and added a `validate-configs.py` check that Ghostty's cursor/selection colors match the palette.
- Tried moving AeroSpace launchers off `Cmd+*` onto `Alt+*` and focus/move onto vim-style keys, then reverted: launchers are back on `Cmd+Enter`/`Cmd+B`/`Cmd+Shift+F`/`Cmd+O`/`Cmd+D`, focus/move/resize back on `Alt+Arrow`/`Alt+Ctrl+Arrow`/`Alt+Shift+Arrow`. The `ignacio-dual-lg` profile adds `Alt+I/J/K/L` focus, `Alt+Shift+J/L` move, and `Alt+Ctrl+J/L` width resize.
- Service mode's `Esc` now only returns to main mode; reload moved to `Shift+R`.
- Standardized on JetBrainsMono Nerd Font Mono everywhere in Ghostty (font and window-title font), dropped the `font-iosevka` cask, and raised Ghostty's cursor opacity from `0.33` to `0.8`.
- Kept the SwiftBar workspace strip on its previous design; the strip redesign was reverted.
