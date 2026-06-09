---
name: hackermacui-maintenance
description: "Trigger: HackermacUI apply, backup, doctor, status, check drift, rollback, maintenance. Safely operate repo scripts and config flow."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# HackermacUI Maintenance

## Activation Contract

Use when work involves HackermacUI maintenance scripts, live config application, backups, drift checks, rollback, install verification, or repo-managed local state.

## Hard Rules

- Read `README.md`, `docs/maintenance.md`, `docs/dotfiles.md`, and the relevant `scripts/*.sh` before changing workflow behavior.
- Do not run `./scripts/apply.sh` unless the user explicitly approves it in the current task.
- Treat `apply.sh` as live-machine mutation: it backs up, symlinks/rsyncs configs, writes SwiftBar defaults, reloads tools, and uses `rsync --delete`.
- Keep backups and snapshots under `~/.hackermacui/` or ignored local state; never promote them into tracked config.
- Update scripts and docs together when managed live paths, required tools, or apply behavior changes.

## Decision Gates

| Situation | Action |
| --- | --- |
| User asks to apply config | Confirm diff/backup awareness before running `apply.sh` |
| Script touches live files | Check `docs/dotfiles.md` and `scripts/backup.sh` coverage |
| New managed path appears | Update `apply.sh`, `backup.sh`, `check-drift.sh`, docs, and privacy notes if needed |
| Output may contain runtime details | Redact paths, process args, tokens, and private project names before public use |

## Execution Steps

1. Inspect `git status --short` and relevant docs/scripts.
2. Identify whether the change affects AeroSpace, SwiftBar, borders, Ghostty, zsh example, or support scripts.
3. Prefer targeted edits and targeted reload commands over full apply.
4. Verify shell syntax for changed shell scripts.
5. Recommend `./scripts/check-drift.sh` after live changes, but do not treat drift as a public-safety scan.

## Output Contract

Return changed files, live-machine actions performed or intentionally skipped, verification commands run, and any remaining apply/backup/drift risks.

## References

- `README.md`
- `docs/maintenance.md`
- `docs/dotfiles.md`
- `scripts/apply.sh`
- `scripts/backup.sh`
- `scripts/check-drift.sh`
- `scripts/doctor.sh`
- `scripts/status.sh`
