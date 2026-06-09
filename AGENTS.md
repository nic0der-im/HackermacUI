# HackermacUI Agent Context

HackermacUI is a public, curated macOS desktop setup. It is not a raw machine backup.

## Project Invariants

- Keep reusable configs, portable scripts, and documentation in git.
- Keep private state out of git: raw snapshots, backups, credentials, logs, local overlays, machine captures, shell history, and personal runtime dumps.
- Preserve runtime ownership: AeroSpace owns tiling/workspaces, SwiftBar owns native menu-bar widgets, JankyBorders owns focus borders, and Ghostty owns terminal feel.
- Do not reintroduce competing desktop managers such as SketchyBar, AltTab, Hammerspoon, Rift, yabai, skhd, or Rectangle unless the user explicitly asks for an architecture change.
- Treat SwiftBar plugins, AeroSpace helper scripts, and repo shell scripts as executable code, not passive configuration.
- Do not run `./scripts/apply.sh` automatically. It mutates live machine config and uses destructive sync semantics; run it only after explicit user approval.

## Expected Workflow

Before changing live-affecting config, inspect the relevant docs and scripts, prefer one tool at a time, and preserve the documented flow: status, backup, targeted change, reload only the affected tool, then drift check.

Project skills under `.opencode/skills/` provide more specific guidance for maintenance, desktop-stack ownership, SwiftBar widgets, and public-safety review.
