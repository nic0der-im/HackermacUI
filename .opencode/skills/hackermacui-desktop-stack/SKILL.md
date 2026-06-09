---
name: hackermacui-desktop-stack
description: "Trigger: HackermacUI AeroSpace, SwiftBar, JankyBorders, borders, Ghostty, workspace, tiling, menu bar. Preserve desktop stack ownership."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# HackermacUI Desktop Stack

## Activation Contract

Use when changing HackermacUI desktop behavior, app launchers, workspace rules, focus borders, terminal UX, menu-bar ownership, or tool interactions.

## Hard Rules

- Read `docs/stack.md` and the affected config before editing.
- Preserve ownership: AeroSpace owns tiling/workspaces/app launchers, SwiftBar owns native menu-bar widgets, JankyBorders owns focus borders, and Ghostty owns terminal feel.
- Do not add overlapping managers such as SketchyBar, AltTab, Hammerspoon, Rift, yabai, skhd, Rectangle, or duplicate launch/focus layers without an explicit architecture decision.
- Keep machine-specific assumptions visible and avoid new hardcoded personal paths in public config.
- When changing workspace counts or routing, check AeroSpace config, helper scripts, SwiftBar workspace widgets, and docs together.

## Decision Gates

| Change | Owner |
| --- | --- |
| Window rules, workspaces, launch shortcuts | AeroSpace |
| Native status/menu widget | SwiftBar |
| Active-window visual border | JankyBorders |
| Terminal theme, keybinds, tab/window behavior | Ghostty |
| Shell helper example | zsh example, not managed live shell |

## Execution Steps

1. Classify the requested behavior by owner before editing.
2. Inspect the owner config and adjacent docs.
3. Reject or escalate requests that make tools fight for the same responsibility.
4. Keep docs current when behavior or ownership changes.
5. Use targeted reload commands: `aerospace reload-config`, `open 'swiftbar://refreshallplugins'`, or `~/.config/borders/bordersrc`.

## Output Contract

Return the selected owner, files changed, competing tools considered, verification performed, and any user approval needed for live apply.

## References

- `docs/stack.md`
- `docs/widgets.md`
- `docs/timeline.md`
- `configs/aerospace/aerospace.toml`
- `configs/borders/bordersrc`
- `configs/ghostty/config`
- `configs/swiftbar/plugins/`
