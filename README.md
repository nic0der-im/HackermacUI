# HackermacUI

HackermacUI is a public, curated macOS desktop environment. It is inspired by the clarity of Linux rice setups and Omarchy-style command flows, but it stays native to macOS: AeroSpace owns tiling, HackermacLauncher owns command execution, SwiftBar owns the menu-bar surface, JankyBorders owns focus feedback, and Ghostty owns the terminal feel.

This repository is not a raw machine backup. It contains reusable dotfiles, native tools, scripts, and documentation that describe how the desktop works. Private state, credentials, local snapshots, logs, and machine-specific overlays stay out of git.

## Visual Overview

Use these placeholders for public screenshots once the final look is stable.

| Area | Placeholder | What to show |
|---|---|---|
| Full desktop | `assets/screenshots/desktop-overview.png` | Tiled windows, menu bar, Ghostty, and focus border in one shot. |
| Launcher | `assets/screenshots/launcher-root.png` | HackermacLauncher opened with `Option+Space`. |
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
  -> HackermacLauncher opens command menus and runs declarative actions

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

The important design constraint is ownership. AeroSpace is the window manager. SwiftBar is not a second command center. HackermacLauncher is not a status bar. JankyBorders does not manage windows. Ghostty does not define global desktop behavior.

## Runtime Stack

| Layer | Project | Role in HackermacUI |
|---|---|---|
| Tiling and workspaces | AeroSpace | Manages public four-workspace default plus swappable profile templates, keyboard focus, movement, gaps, floating rules, and app launcher shortcuts. |
| Command center | HackermacLauncher | Native Swift launcher for menus, workspace actions, app opening, install helpers, config shortcuts, and Ghostty entrypoints. |
| Menu-bar widgets | SwiftBar | Hosts the native workspace strip plugin in the real macOS menu bar. |
| Workspace widget | `00-hackermacui.3s.sh` | Custom SwiftBar plugin that renders a compact workspace strip from AeroSpace state. |
| Focus border | JankyBorders / `borders` | Draws a 3px active-window gradient border while leaving inactive borders transparent. |
| Terminal | Ghostty | Provides the glass terminal, quick terminal, tab behavior, splits, and shell entrypoints. |
| Shell helpers | zsh, fzf, atuin, zoxide | Gives the terminal workflow fast history, navigation, completion, and shell ergonomics. |
| Local dev tools | OrbStack, PostgreSQL, Redis, pnpm, Node.js, Go, gh, lazygit, lazydocker | Optional development environment tools surfaced through config, launcher actions, or shell workflows. |

## Third-Party Projects

### AeroSpace

AeroSpace is the core tiling window manager. HackermacUI uses it for public workspaces `1..4`, directional focus, resize, movement, floating toggles, app launch shortcuts, and workspace-change hooks. Machine-specific layouts live in templates.

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
| Move focused window | `Alt+Ctrl+1..4`. |
| Focus movement | `Alt+Arrow`. |
| Resize | `Alt+Shift+Arrow`. |
| Floating toggle | `Alt+Shift+Space`. |
| Next active workspace | `Alt+Tab`. |
| App shortcuts | `Cmd+Enter` Ghostty, `Cmd+B` Chrome, `Cmd+F` Finder, `Cmd+O` Obsidian, `Cmd+D` LazyDocker, `Cmd+Shift+A` OpenCode CLI. |

### SwiftBar

SwiftBar is the native menu-bar layer. HackermacUI keeps it intentionally small: the default active plugin is the workspace strip, not a full replacement for macOS Control Center or a Linux-style status bar.

Repo-owned files:

| File | Purpose |
|---|---|
| `configs/swiftbar/plugins/00-hackermacui.3s.sh` | Active SwiftBar plugin and HackermacUI dropdown. |
| `configs/swiftbar/plugins/.helpers/render-hackermac-workspaces.sh` | Captures AeroSpace state, prepares app/icon records, and emits the image header. |
| `configs/swiftbar/plugins/.helpers/render-workspace-strip.jxa` | JXA renderer that creates the cached composite workspace image. |
| `configs/swiftbar/README.md` | Widget rules, performance contract, and verification notes. |

Key behavior:

| Behavior | Current state |
|---|---|
| Default plugins | `00-hackermacui.3s.sh` only. |
| Refresh model | AeroSpace workspace-change hook plus 3-second fallback interval. |
| Rendering | Cached composite PNG by default, with workspace numbers, focus styling, and app icons when available. |
| Performance | State-hash invalidation for workspaces, cached composite rendering, and no remote polling. |
| Interaction model | Mostly display-first; command actions belong in HackermacLauncher. |

### JankyBorders / borders

JankyBorders provides visual focus feedback. HackermacUI uses it only for borders, not for layout or window control.

Repo-owned file:

| File | Purpose |
|---|---|
| `configs/borders/bordersrc` | Starts `borders` with round 3px active gradient border, transparent inactive border, and app blacklist. |

Key behavior:

| Behavior | Current state |
|---|---|
| Active border | Blue-to-red gradient. |
| Inactive border | Transparent. |
| Blacklist | HackermacLauncher, System Settings, Login Window, Notification Center, Control Center. |
| Startup | Launched by AeroSpace `after-startup-command` and reloadable through launcher/theme actions. |

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
| Quick terminal | `Ctrl+Shift+Backtick` toggles the centered quick terminal. |
| Tabs and splits | `Cmd+N`, `Cmd+T`, `Cmd+D`, `Cmd+Shift+D`. |
| Shell integration | Cursor, sudo, title, path, and related Ghostty shell features. |
| Launcher integration | HackermacLauncher opens TUIs and repo shells in Ghostty. |

### Shell And Developer Tools

HackermacUI includes a zsh example and expects common terminal tools to be installed through Homebrew when desired.

Repo-owned file:

| File | Purpose |
|---|---|
| `configs/zsh/zshrc.example` | Portable shell example, not a forced live shell replacement. |

Common tools:

| Tool | Role |
|---|---|
| `fzf` | Fuzzy selection in terminal workflows. |
| `atuin` | Shell history. |
| `zoxide` | Fast directory jumping. |
| `lazygit` | Git TUI opened from launcher or terminal. |
| `lazydocker` | Docker TUI opened from launcher or AeroSpace shortcut. |
| `gh` | GitHub CLI for repo workflows. |
| `OrbStack` | Optional local container runtime. |
| `PostgreSQL`, `Redis`, `Node.js`, `pnpm`, `Go` | Optional local development stack. |

## Own Projects

### HackermacLauncher

HackermacLauncher is a native Swift command center for HackermacUI. It is inspired by Omarchy's Walker menu, but it is not a Raycast clone and it is not a general-purpose shell prompt.

It reads a declarative menu from JSON, renders a small glass SwiftUI panel, supports fuzzy filtering, and executes allowlisted action types. It currently runs as a SwiftPM app and registers `Option+Space` while running.

Repo-owned files:

| File | Purpose |
|---|---|
| `apps/HackermacLauncher/Package.swift` | SwiftPM package definition. |
| `apps/HackermacLauncher/Sources/HackermacLauncher/main.swift` | App entrypoint, panel UI, fuzzy filtering, hotkey registration, config loading, and action runner. |
| `apps/HackermacLauncher/README.md` | Launcher-specific run and config notes. |
| `configs/launcher/menu.json` | Menu tree and declarative actions. |
| `configs/launcher/theme.json` | Material, width, accent color, radius, max-row tuning, and hotkey. |

Current menu areas:

| Menu | Purpose |
|---|---|
| Agents | Opens OpenCode CLI, Codex CLI, Codex app, and Hermes over SSH. |
| TUIs | Opens LazyGit, LazyDocker, btop, and Fastfetch in Ghostty. |
| Gamemode | Moves to the gaming workspace, opens Steam, Discord, and Focus settings. |
| Switch | Switches AeroSpace workspaces and runs workspace utility actions. |
| Profiles | Swaps public/default and machine-specific templates. |
| Install | Guarded Homebrew installers for optional terminal tools. |
| Config | Opens repo-managed config files and folders. |
| Terminal | Opens Ghostty, repo shells, tmux session, and status checks. |
| Theme | Toggles macOS appearance, reloads borders, and refreshes SwiftBar. |
| Keybindings | Searchable help map for the desktop shortcuts. |

Supported action types:

| Type | Purpose |
|---|---|
| `openApp` | Opens a macOS app by name. |
| `openPath` | Opens a repo path or local path. |
| `openURL` | Opens URLs and macOS URL schemes. |
| `ghostty` | Runs a command in Ghostty, optionally from a working directory. |
| `aerospace` | Runs AeroSpace CLI actions. |
| `run` | Runs an allowlisted repo command. |
| `appleScript` | Executes bounded AppleScript actions. |
| `sequence` | Runs multiple declarative actions in order. |

Safety model:

| Rule | Why |
|---|---|
| Prefer schema actions over arbitrary input | Keeps launcher behavior auditable in `menu.json`. |
| Confirmation for install actions | Prevents accidental system changes. |
| Floating and borderless window | The command center should not participate in tiling or focus-border noise. |
| Root reset on open | Each `Option+Space` starts from a predictable command surface. |

Run it:

```bash
cd apps/HackermacLauncher
swift run HackermacLauncher
```

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
| Launcher menu | Repo-read config | `configs/launcher/menu.json` | Read by HackermacLauncher. |
| Launcher theme | Repo-read config | `configs/launcher/theme.json` | Read by HackermacLauncher. |
| Template profiles | Repo-rendered config | `configs/templates/profiles/` | Rendered by `scripts/template.sh`. |
| zsh example | Manual copy | `configs/zsh/zshrc.example` | Not applied automatically. |

`apply.sh` is intentionally powerful. It creates a backup first, then syncs managed folders into live paths. Because several sync steps use delete semantics, review the configs before applying them.

## Repository Layout

```txt
apps/
  HackermacLauncher/       Native Swift command center.

configs/
  aerospace/               Tiling, workspaces, keybindings, and helper scripts.
  borders/                 JankyBorders focus-border config.
  ghostty/                 Terminal theme and keybindings.
  launcher/                HackermacLauncher menu and theme JSON.
  swiftbar/                SwiftBar plugin and widget docs.
  templates/               Profile templates for public and machine-specific layouts.
  zsh/                     Portable zsh example.

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
  install-deps.sh          Guarded Homebrew dependency installer.
  template.sh              Render/switch profile templates.
  build-launcher-app.sh    Build local HackermacLauncher.app.
  verify.sh                Shell, JSON, and Swift verification.
  status.sh                Read current desktop-management state.
  doctor.sh                Verify required apps, CLIs, and macOS settings.
  backup.sh                Copy live configs to a timestamped local backup.
  check-drift.sh           Compare live configs with repo snapshots.
  snapshot.sh              Create private ignored local snapshots.
  apply.sh                 Apply repo configs to live paths after review.
```

## Install And Safe Apply

Install the core tools with Homebrew:

```bash
brew install --cask nikitabobko/tap/aerospace swiftbar ghostty
brew tap FelixKratz/formulae
brew install borders gh fzf atuin zoxide zsh-autosuggestions zsh-syntax-highlighting
```

Optional development tools:

```bash
brew install lazygit lazydocker node pnpm go redis postgresql@16 postgresql@18 fastfetch bat ripgrep
brew install --cask orbstack
```

Use the guarded repo workflow:

```bash
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
./scripts/doctor.sh       # verify required apps, CLIs, and macOS settings
./scripts/backup.sh       # copy live configs to ~/.hackermacui/backups/<timestamp>
./scripts/check-drift.sh  # compare live configs against repo snapshots
./scripts/template.sh     # list, activate, render, and switch profile templates
./scripts/verify.sh       # verify shell, JSON, config contracts, and Swift build
./scripts/build-launcher-app.sh # build dist/HackermacLauncher.app
./scripts/launcher-login.sh # install/remove Launcher launch-at-login
./scripts/snapshot.sh     # private local snapshot, ignored by git
./scripts/apply.sh        # apply repo configs to the live machine after review
```

## Intentionally Absent

HackermacUI avoids overlapping desktop managers by default.

| Tool | Why it is absent |
|---|---|
| Raycast | Replaced by HackermacLauncher for the command-center role. |
| SketchyBar | SwiftBar owns the native menu-bar widget surface. |
| Ice | SwiftBar stays the only menu-bar widget layer; hidden-item managers can mask status item bugs. |
| Bartender | SwiftBar stays the only menu-bar widget layer. |
| Hidden Bar | SwiftBar stays the only menu-bar widget layer. |
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
| Example shell config | Shell history and personal local state |

Local backups and snapshots belong under `~/.hackermacui/` or ignored paths.

## Current Status

| Area | State |
|---|---|
| AeroSpace desktop config | Public four-workspace default plus swappable profile templates. |
| HackermacLauncher | SwiftPM runtime flow plus local `.app` bundle build under `dist/`. |
| SwiftBar workspace strip | Implemented with cached composite image rendering. |
| JankyBorders | Active focus border with launcher/system blacklist. |
| Ghostty | Glass terminal config with developer keybindings. |
| Public docs | This README plus focused docs under `docs/`. |

## Philosophy

HackermacUI is a desktop system, not a theme dump. The value is in the boundaries: every tool has a clear job, every managed dotfile has a source path, and every public artifact should help someone understand or reuse the setup without inheriting private machine state.
