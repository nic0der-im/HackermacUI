# SwiftBar Setup

This setup keeps SwiftBar minimal: one native menu-bar widget for AeroSpace workspaces. The goal is a Waybar-like workspace strip without recreating a full status bar or a second command center in macOS.

## Active Plugins

| Plugin | Interval | Purpose | Performance rule |
| --- | ---: | --- | --- |
| `00-hackermacui.3s.sh` | 3s fallback | Shows a cached image-based AeroSpace workspace strip and HackermacUI dropdown. | Refreshes on AeroSpace workspace changes, delegates rendering to `.helpers/render-hackermac-workspaces.sh`, and falls back to text if image rendering fails. |

## Rules

- Keep `~/SwiftBarPlugins` managed from `configs/swiftbar/plugins`. The repo is the source of truth and SwiftBar reads the synced plugin folder.
- Keep only high-signal workspace UI active by default. Do not add GitHub, Docker, system, network, or service polling unless there is a concrete daily workflow.
- Keep the workspace strip visually focused. The dropdown may expose small HackermacUI maintenance links, but command-center actions belong in HackermacLauncher.
- Do not add sub-5-second plugins unless they are local, trivial, and proven not to leave child processes behind.
- Do not run network/API checks from SwiftBar by default. Local interface inspection is acceptable when the workflow explicitly calls for it.
- Do not use streaming commands in normal refresh plugins. Use finite commands that print and exit.
- Add timeouts around tools that can hang: `aerospace`, `docker`, `gh`, cloud CLIs, and VPN/SSH helpers.
- Cache converted app icons and generated composite strip images under SwiftBar's plugin cache path. Do not repeatedly convert app bundle icons or redraw the strip during every refresh. Keep strip cache pruning enabled so state variations do not grow forever.
- Store API tokens in the tool's normal auth store, keychain, or environment. Never hardcode secrets in plugins.

## Verification

```bash
bash -n configs/swiftbar/plugins/*.sh configs/swiftbar/plugins/.helpers/*.sh
for plugin in "$HOME"/SwiftBarPlugins/*.sh; do time "$plugin" >/dev/null; done
ps -axo pid,ppid,etime,command | rg 'SwiftBarPlugins/.*\.sh|aerospace list-workspaces'
```

The process check should only show the check command itself or very short-lived plugin executions.
