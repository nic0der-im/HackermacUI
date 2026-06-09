---
name: hackermacui-swiftbar-widgets
description: "Trigger: HackermacUI SwiftBar widget, SwiftBar plugin, xbar, menu-bar widget, aerospace-workspaces. Build small native widgets."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# HackermacUI SwiftBar Widgets

## Activation Contract

Use when creating, reviewing, optimizing, renaming, or debugging SwiftBar/xbar plugins in HackermacUI.

## Hard Rules

- Treat every plugin as recurring executable code.
- Read `docs/widgets.md`, `docs/privacy.md`, and the affected plugin before editing.
- Keep widgets small, high-signal, native, and non-duplicative with macOS built-ins.
- Avoid secrets, tokens, private project names, credentials, raw process args, and sensitive paths in widget output or menu actions.
- Prefer explicit timeouts, caching, cheap commands, and graceful stale/error output for commands that can hang.
- Ensure plugin files remain executable-compatible after `apply.sh` syncs them to `~/SwiftBarPlugins/`.

## Decision Gates

| Widget Idea | Default Decision |
| --- | --- |
| AeroSpace workspace/status | Accept if cheap and resilient |
| Dev service health | Accept if low-frequency and local-only |
| Git/GitHub project status | Accept if scoped and privacy-safe |
| Obsidian quick action | Accept if it does not expose vault contents |
| Communication/noisy notification widget | Reject unless there is a concrete workflow |

## Execution Steps

1. Inspect current plugin headers, refresh interval, commands, and menu actions.
2. Verify shell safety: quoting, timeouts, fallbacks, temporary files, and command paths.
3. Keep UI output compact enough for the macOS menu bar.
4. Update `docs/widgets.md` when widget behavior or roadmap status changes.
5. Run shell syntax checks for changed plugin scripts.

## Output Contract

Return plugin files changed, refresh/caching behavior, safety checks, docs updated or intentionally skipped, and verification results.

## References

- `docs/widgets.md`
- `docs/privacy.md`
- `configs/swiftbar/plugins/`
- `scripts/apply.sh`
