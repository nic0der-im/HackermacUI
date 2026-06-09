# SwiftBar Setup

This setup keeps SwiftBar minimal: one native menu-bar widget for AeroSpace workspaces. The goal is a Waybar-like workspace strip without recreating a full status bar or a second command center in macOS.

## Active Plugins

| Plugin | Interval | Purpose | Performance rule |
| --- | ---: | --- | --- |
| `aerospace-workspaces.3s.sh` | 3s fallback | Shows a Waybar-like composite workspace strip with real app icons and a HackermacUI control dropdown. | Refreshes on AeroSpace workspace changes, uses bounded AeroSpace calls, cached app icons, and a state-hashed cached strip image. Dropdown actions are static until clicked. |

## Rules

- Keep `~/SwiftBarPlugins` managed from `configs/swiftbar/plugins`. The repo is the source of truth and SwiftBar reads the synced plugin folder.
- Keep only high-signal workspace UI active by default. Do not add GitHub, Docker, system, network, or service polling unless there is a concrete daily workflow.
- Keep the workspace strip display-only. Command actions belong in HackermacLauncher, not in SwiftBar dropdown menus.
- Do not add sub-5-second plugins unless they are local, trivial, and proven not to leave child processes behind.
- Do not run network/API checks from SwiftBar by default.
- Do not use streaming commands in normal refresh plugins. Use finite commands that print and exit.
- Add timeouts around tools that can hang: `aerospace`, `docker`, `gh`, cloud CLIs, and VPN/SSH helpers.
- Cache converted app icons and generated composite strip images under SwiftBar's plugin cache path. Do not repeatedly convert app bundle icons or redraw the strip during every refresh. Keep strip cache pruning enabled so state variations do not grow forever.
- Store API tokens in the tool's normal auth store, keychain, or environment. Never hardcode secrets in plugins.

## Verification

```bash
bash -n configs/swiftbar/plugins/*.sh
for plugin in "$HOME"/SwiftBarPlugins/*.sh; do time "$plugin" >/dev/null; done
ps -axo pid,ppid,etime,command | rg 'SwiftBarPlugins/.*\.sh|aerospace list-workspaces'
```

The process check should only show the check command itself or very short-lived plugin executions.
