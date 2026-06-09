---
name: hackermacui-public-safety
description: "Trigger: HackermacUI publish, public repo, privacy, snapshot, credentials, private state, .env. Keep machine-specific data out of git."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

# HackermacUI Public Safety

## Activation Contract

Use when preparing HackermacUI for publication, reviewing git status, adding files, touching privacy docs, handling snapshots/backups, or deciding whether local state belongs in the repo.

## Hard Rules

- Read `docs/privacy.md`, `.gitignore`, and `docs/dotfiles.md` before adding or publishing files.
- HackermacUI stores curated reusable config, not raw machine backup.
- Do not track credentials, `.env` files, SSH/GPG/private keys, cookies, logs, shell history, raw backups, snapshots, runtime dumps, or machine-specific captures.
- Treat generated local agent indexes and absolute local paths as private unless the user explicitly approves sanitized publication.
- Do not paste raw `status.sh`, `ps`, shell config, plugin cache, or backup output into public artifacts without redaction.

## Decision Gates

| Content | Decision |
| --- | --- |
| Reusable dotfile/script/doc | Usually public-safe after review |
| Example shell integration | Public-safe only without credentials or private paths |
| Backup, snapshot, runtime state | Keep local/ignored |
| Absolute personal path | Replace, parameterize, document as private, or reject |
| Generated local agent registry | Keep private unless intentionally sanitized |

## Execution Steps

1. Inspect `git status --short` before publication-sensitive work.
2. Review new and modified files for private paths, secrets, machine captures, and generated local metadata.
3. Verify ignored/private state stays out of tracked files.
4. If a tool needs local-only customization, prefer ignored overlays or `~/.hackermacui/` state.
5. Report any public-safety blockers separately from functional issues.

## Output Contract

Return public-safety findings, files safe to track, files to keep ignored/local, redactions needed, and unresolved publication blockers.

## References

- `docs/privacy.md`
- `docs/dotfiles.md`
- `.gitignore`
- `scripts/snapshot.sh`
- `scripts/backup.sh`
