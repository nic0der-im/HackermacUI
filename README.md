# HackermacUI

HackermacUI is a public, curated macOS desktop environment. It is inspired by the clarity of Linux rice setups and Omarchy-style command flows, but it stays native to macOS: AeroSpace owns tiling, SwiftBar owns the menu-bar surface, JankyBorders owns focus feedback, and Ghostty owns the terminal feel.

This repository is not a raw machine backup. It contains reusable dotfiles, native tools, scripts, and documentation that describe how the desktop works. Private state, credentials, local snapshots, logs, and machine-specific overlays stay out of git.

## Visual Overview

Use these placeholders for public screenshots once the final look is stable.

| Area | Placeholder | What to show |
|---|---|---|
| Full desktop | `assets/screenshots/desktop-overview.png` | Tiled windows, menu bar, Ghostty, and focus border in one shot. |
| Workspace strip | `assets/screenshots/swiftbar-workspaces.png` | SwiftBar workspace strip with active workspace and app icons. |
| Terminal | `assets/screenshots/ghostty-terminal.png` | Ghostty glass theme and developer shell. |
| Config flow | `assets/screenshots/config-flow.png` | Repo config, status, backup, and drift-check workflow. |

```md
![HackermacUI desktop overview](assets/screenshots/desktop-overview.png)
```

## What It Is

HackermacUI is a reproducible desktop layer for macOS power users who want a fast keyboard-first workflow without turning the system into a fragile pile of overlapping window managers and menu bars.

The project should transmit three ideas:

| Idea | Meaning |
|---|---|
| Native first | Use macOS-native surfaces where they make sense: menu bar, SwiftUI panels, app hotkeys, and Homebrew-managed tools. |
| One owner per responsibility | Each runtime concern has one owner so tools do not fight each other. |
| Public and reusable | Share configs and implementation patterns, not personal machine state. |

## Core Model

```txt
Keyboard shortcuts
  -> AeroSpace manages workspaces, focus, movement, floating rules, and app launch shortcuts

AeroSpace workspace events
  -> refresh-swiftbar-workspaces.sh
  -> SwiftBar plugin redraws cached workspace strip

Focused window changes
  -> JankyBorders renders active focus border

Terminal actions
  -> Ghostty opens developer shells, TUIs, and quick terminal workflows

Repo configs
  -> scripts/backup.sh protects live state
  -> scripts/apply.sh syncs managed dotfiles after review
  -> scripts/check-drift.sh compares live config against repo source
  -> scripts/template.sh swaps selected profile templates
```

The important design constraint is ownership. AeroSpace is the window manager. SwiftBar is the menu-bar status surface, not a second window manager. JankyBorders does not manage windows. Ghostty does not define global desktop behavior.

## Runtime Stack

| Layer | Project | Role in HackermacUI |
|---|---|---|
| Tiling and workspaces | AeroSpace | Manages public four-workspace default plus swappable profile templates, keyboard focus, movement, gaps, floating rules, and app shortcuts. |
| Menu-bar widgets | SwiftBar | Hosts the native workspace strip plugin in the real macOS menu bar. |
| Workspace widget | `00-hackermacui.3s.sh` | Custom SwiftBar plugin that renders a compact workspace strip from AeroSpace state. |
| Focus border | JankyBorders / `borders` | Draws a 3px active-window gradient border while leaving inactive borders transparent. |
| Terminal | Ghostty | Provides the glass terminal, quick terminal, tab behavior, splits, and shell entrypoints. |
| Shell tooling | Fastfetch | Optional system-info panel; config only, the shell startup hook is left to the user. |
| Menu-bar cleanup | Ice | Optional user chrome for hiding unrelated menu-bar items; SwiftBar still owns the HackermacUI workspace widget. |

## Third-Party Projects

### AeroSpace

AeroSpace is the core tiling window manager. HackermacUI uses it for public workspaces `1..4`, directional focus, resize, movement, floating toggles, app launch shortcuts, and workspace-change hooks. Machine-specific layouts live in templates.

App launch shortcuts live on `Alt+*`, not `Cmd+*`: `Cmd+Enter`, `Cmd+B`, `Cmd+O`, and `Cmd+Shift+F` collided with macOS/app defaults (bold, open, bookmark, search). Focus and window movement use vim-style `H/J/K/L` instead of arrow keys, freeing `Alt+Ctrl+Arrow` entirely and keeping `Alt+Shift+Arrow` for resize.

Repo-owned files:

| File | Purpose |
|---|---|
| `configs/aerospace/aerospace.toml` | Main tiling, workspace, keybinding, app-routing, and hook config. |
| `configs/aerospace/scripts/next-active-workspace.sh` | Switches to the next workspace that currently has windows. |
| `configs/aerospace/scripts/refresh-swiftbar-workspaces.sh` | Debounced bridge from AeroSpace workspace events to SwiftBar refreshes. |
| `configs/aerospace/scripts/finder-new-window` | Opens Finder as a new window from an AeroSpace shortcut. |
| `configs/aerospace/scripts/profile.env` | Active profile metadata consumed by helper scripts and widgets. |

Key behavior:

| Behavior | Current state |
|---|---|
| Workspace count | Four persistent workspaces in the public default profile. |
| Main switching | `Alt+1..4`. |
| Send window to workspace | `Alt+Ctrl+1..4`. |
| Focus movement | `Alt+Arrow`. |
| Reorder window | `Alt+Ctrl+Arrow`. |
| Resize | `Alt+Shift+Arrow`. |
| Floating toggle | `Alt+Shift+Space`. |
| Next active workspace | `Alt+Tab`. |
| App shortcuts | `Cmd+Enter` Ghostty, `Cmd+B` Chrome, `Cmd+Shift+F` Finder, `Cmd+O` Obsidian. |
| Service mode | `Alt+Shift+;` enters it; `Esc` returns to main; `Shift+R` reloads config, other bindings unchanged. |

### SwiftBar

SwiftBar is the native menu-bar layer. HackermacUI keeps it intentionally small: the default active plugin is the workspace strip, not a full replacement for macOS Control Center or a Linux-style status bar.

Repo-owned files:

| File | Purpose |
|---|---|
| `configs/swiftbar/plugins/00-hackermacui.3s.sh` | Active SwiftBar plugin, HackermacUI dropdown, workspace switcher, and keybindings cheat sheet. |
| `configs/swiftbar/plugins/.helpers/render-hackermac-workspaces.sh` | Captures AeroSpace state, prepares app/icon records, and emits the image header. |
| `configs/swiftbar/plugins/.helpers/render-workspace-strip.jxa` | JXA renderer that creates the cached composite workspace image. |
| `configs/swiftbar/README.md` | Widget rules, performance contract, and verification notes. |

Key behavior:

| Behavior | Current state |
|---|---|
| Default plugins | `00-hackermacui.3s.sh` only. |
| Refresh model | AeroSpace workspace-change hook plus 3-second fallback interval. |
| Rendering | Cached composite PNG by default, retina-crisp (~22pt logical height), with workspace numbers, focus styling, monitor grouping, and app icons when available. |
| Stability | Always renders every persistent workspace (live from `aerospace list-workspaces --all`), including a focused-but-empty one. |
| Performance | State-hash invalidation for workspaces, cached composite rendering, and no remote polling. |
| Interaction model | Workspace switcher and a keybindings cheat sheet (parsed from the active `aerospace.toml`, cached by its mtime) in the dropdown; the menu bar itself is still a status surface, not a command center. |

### JankyBorders / borders

JankyBorders provides visual focus feedback. HackermacUI uses it only for borders, not for layout or window control.

Repo-owned file:

| File | Purpose |
|---|---|
| `configs/borders/bordersrc` | Starts `borders` with a round 3px solid focus-green active border, transparent inactive border, and app blacklist; sources the shared theme palette. |

Key behavior:

| Behavior | Current state |
|---|---|
| Active border | Solid focus green (`configs/theme/palette.env` `HACKERMACUI_COLOR_FOCUS`), the same color as Ghostty's selection/cursor. The SwiftBar strip keeps its own design. |
| Inactive border | Transparent. |
| Blacklist | System Settings, Login Window, Notification Center, Control Center. |
| Startup | Launched by AeroSpace `after-startup-command` and reloadable with `~/.config/borders/bordersrc`. |

### Ghostty

Ghostty owns the terminal experience. HackermacUI configures it as a glassy developer terminal with native tabs, splits, quick terminal, and macOS-friendly keybindings.

Repo-owned file:

| File | Purpose |
|---|---|
| `configs/ghostty/config` | Theme, opacity, blur, keybindings, tabs, splits, shell integration, and quick-terminal behavior. |

Key behavior:

| Behavior | Current state |
|---|---|
| Visual style | Dark glass background with low opacity and macOS blur. |
| Font | JetBrainsMono Nerd Font Mono, for both the terminal and the window title. |
| Cursor and selection | Focus green (`HACKERMACUI_COLOR_FOCUS`), matching the border and the SwiftBar strip; cursor opacity `0.8`. |
| ANSI palette | Red/green/blue (1/2/4) and their bright variants (9/10/12) aligned to GitHub Dark's terminal colors. |
| Quick terminal | `Ctrl+Shift+Backtick` toggles the centered quick terminal. |
| Tabs and splits | `Cmd+N`, `Cmd+T`, `Cmd+D`, `Cmd+Shift+D`. |
| Shell integration | Cursor, sudo, title, path, and related Ghostty shell features. |

### Fastfetch

Fastfetch provides an optional terminal system-info panel. HackermacUI ships only its config; calling it from your shell startup is up to you (see `docs/dotfiles.md`).

Repo-owned file:

| File | Purpose |
|---|---|
| `configs/fastfetch/config.json` | Fastfetch module list, so the default logo stays intact. |

## Own Projects

### AeroSpace Workspace SwiftBar Plugin

The SwiftBar plugin is the custom menu-bar widget for HackermacUI. It translates AeroSpace window state into a compact visual workspace strip.

The plugin is intentionally more than a passive shell snippet. It has a performance contract: it bounds external calls, caches converted app icons, caches the final strip image, prunes old strip cache entries, and redraws only when the workspace state changes.

Repo-owned files:

| File | Purpose |
|---|---|
| `configs/swiftbar/plugins/00-hackermacui.3s.sh` | Visible SwiftBar plugin; prints the PNG header and HackermacUI dropdown actions. |
| `configs/swiftbar/plugins/.helpers/render-hackermac-workspaces.sh` | Captures AeroSpace state, prepares app/icon records, emits the image header. |
| `configs/swiftbar/plugins/.helpers/render-workspace-strip.jxa` | Draws the composite PNG used by SwiftBar. |
| `configs/aerospace/scripts/refresh-swiftbar-workspaces.sh` | Debounced refresh hook called from AeroSpace. |

Core behavior:

| Step | What happens |
|---|---|
| 1 | AeroSpace reports workspaces, focused workspace, and visible app windows. |
| 2 | Plugin maps apps to real bundle icons when available, with fallback glyphs. |
| 3 | Renderer creates one composite image for the whole strip. |
| 4 | SwiftBar displays that image in the native menu bar. |
| 5 | AeroSpace events trigger refreshes; the plugin interval remains a fallback. |

## Dotfiles Map

| Area | Live path | Repo source | Managed by `apply.sh` |
|---|---|---|---|
| AeroSpace config | `~/.aerospace.toml` | `configs/aerospace/aerospace.toml` | Symlink. |
| AeroSpace scripts | `~/.config/aerospace/scripts/` | `configs/aerospace/scripts/` | `rsync --delete`. |
| SwiftBar plugins | `~/SwiftBarPlugins/` | `configs/swiftbar/plugins/` | `rsync --delete`. |
| JankyBorders | `~/.config/borders/` | `configs/borders/` | `rsync --delete`. |
| Ghostty | `~/.config/ghostty/` | `configs/ghostty/` | `rsync --delete`. |
| Theme palette | `~/.config/hackermacui/theme/` | `configs/theme/` | `rsync --delete`. |
| Template profiles | Repo-rendered config | `configs/templates/profiles/` | Rendered by `scripts/template.sh`. |
| Fastfetch | `~/.config/fastfetch/config.json` | `configs/fastfetch/config.json` | `rsync --delete`. |

`apply.sh` is intentionally powerful. It creates a backup first, then syncs managed folders into live paths. Because several sync steps use delete semantics, review the configs before applying them.

## Repository Layout

```txt
configs/
  aerospace/               Tiling, workspaces, keybindings, and helper scripts.
  borders/                 JankyBorders focus-border config.
  ghostty/                 Terminal theme and keybindings.
  swiftbar/                SwiftBar plugin and widget docs.
  templates/               Profile templates for public and machine-specific layouts.
  theme/                   Shared color palette consumed by borders and Ghostty.
  fastfetch/               Fastfetch module list.

docs/
  contracts.md             APIs and extension contracts.
  templates.md             Profile/template switching model.
  install.md               Install and safe apply path.
  stack.md                 Runtime ownership and absent competing tools.
  widgets.md               SwiftBar widget contract.
  dotfiles.md              Live path to repo source map.
  maintenance.md           Maintenance workflow.
  privacy.md               Public repo privacy model.
  roadmap.md               Future work.
  timeline.md              Project evolution notes.

scripts/
  bootstrap.sh             Safe curl/bootstrap entrypoint.
  onboard.sh               Guided first-run setup with explicit confirmations.
  install-deps.sh          Guarded Homebrew dependency installer.
  update.sh                Update Homebrew packages, then run doctor checks.
  template.sh              Render/switch profile templates.
  verify.sh                Shell, JSON, and config verification.
  status.sh                Read current desktop-management state.
  doctor.sh                Verify required apps, CLIs, and macOS settings.
  backup.sh                Copy live configs to a timestamped local backup.
  check-drift.sh           Compare live configs with repo snapshots.
  snapshot.sh              Create private ignored local snapshots.
  apply.sh                 Apply repo configs to live paths after review.
```

## Install And Safe Apply

`Brewfile` at the repo root is the single source of truth for dependencies. Install
the core stack with Homebrew, plus optional groups as needed:

```bash
brew bundle --file Brewfile          # core stack (see docs/install.md for the full list)
brew bundle --file Brewfile.extras   # optional Ice menu-bar hider
```

Use the guarded repo workflow:

```bash
./scripts/onboard.sh      # guided setup path

# Or run the manual path yourself:
./scripts/doctor.sh
./scripts/backup.sh
./scripts/check-drift.sh
./scripts/verify.sh
# Review configs before this step.
./scripts/apply.sh
```

After applying, open AeroSpace and SwiftBar once so macOS can grant any required permissions. AeroSpace needs Accessibility permission in System Settings.

## Maintenance Commands

```bash
./scripts/status.sh       # show current desktop-management state
./scripts/onboard.sh      # guided setup with explicit confirmations
./scripts/doctor.sh       # verify required apps, CLIs, and macOS settings
./scripts/update.sh       # update Homebrew packages, then run doctor checks
./scripts/backup.sh       # copy live configs to ~/.hackermacui/backups/<timestamp>
./scripts/check-drift.sh  # compare live configs against repo snapshots
./scripts/template.sh     # list, activate, render, and switch profile templates
./scripts/verify.sh       # verify shell, JSON, and config contracts
./scripts/release-check.sh # run publication/public-safety gate
./scripts/snapshot.sh     # private local snapshot, ignored by git
./scripts/apply.sh        # apply repo configs to the live machine after review
```

## Optional Menu-Bar Cleanup

Ice is optional in HackermacUI. SwiftBar remains the only HackermacUI-owned menu-bar widget layer, but Ice can be used as user chrome to hide third-party or low-signal macOS menu-bar items.

Recommended visible items when using Ice:

| Visible item | Why |
|---|---|
| Battery | Native power status should stay visible. |
| Control Center | Keeps Wi-Fi, Bluetooth, sound, display, and Focus reachable. |
| Clock | Native time remains a system anchor. |
| HackermacUI SwiftBar plugin | Shows the AeroSpace workspace strip. |

Everything else can be hidden behind Ice based on the user's machine. Ice preferences are intentionally local because menu-bar item names and ordering vary by installed apps.

## Intentionally Absent

HackermacUI avoids overlapping desktop managers by default.

| Tool | Why it is absent |
|---|---|
| Raycast | Not part of the curated native stack. |
| SketchyBar | SwiftBar owns the native menu-bar widget surface. |
| Bartender | Ice is the preferred optional hider when menu-bar cleanup is needed. |
| Hidden Bar | Ice is the preferred optional hider when menu-bar cleanup is needed. |
| AltTab | AeroSpace owns focus and workspace navigation. |
| Hammerspoon | Avoided as a second automation/window layer. |
| Rift | Avoided as a competing desktop/window layer. |
| yabai | AeroSpace owns tiling. |
| skhd | AeroSpace owns global desktop keybindings. |
| Rectangle | AeroSpace owns window movement and layout. |

Adding any of these should be treated as an architecture change, not a casual dependency.

## Public Repo Safety

Keep this repository shareable.

| Keep in git | Keep out of git |
|---|---|
| Reusable configs | Credentials and tokens |
| Portable scripts | Raw machine snapshots |
| Native app source | Logs and runtime dumps |
| Documentation | Private overlays |
| Example configs | Personal local state |

Local backups and snapshots belong under `~/.hackermacui/` or ignored paths.

## Current Status

| Area | State |
|---|---|
| AeroSpace desktop config | Public four-workspace default plus swappable profile templates. |
| SwiftBar workspace strip | Implemented with cached composite image rendering. |
| JankyBorders | Active focus border with system blacklist. |
| Ghostty | Glass terminal config with developer keybindings. |
| Public docs | This README plus focused docs under `docs/`. |

## Philosophy

HackermacUI is a desktop system, not a theme dump. The value is in the boundaries: every tool has a clear job, every managed dotfile has a source path, and every public artifact should help someone understand or reuse the setup without inheriting private machine state.
