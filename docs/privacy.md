# Privacy model

HackermacUI is public by design, so it follows a curated-safe policy.

## Public

- Reusable dotfiles.
- Portable scripts.
- Documentation and widget roadmap.
- Example shell integrations with no credentials.

## Private/local

- Runtime snapshots.
- Backups of live dotfiles.
- Absolute personal paths.
- Credentials, cookies, SSH keys, and environment files.
- Machine-specific app/workspace captures.

## Before publishing

Run the publication gate before pushing:

```bash
./scripts/release-check.sh
```

The gate checks for a clean worktree, public `default` repo profile, tracked private/generated files, unignored private artifacts, absolute private `/Users/...` paths, obvious secret assignments, config verification, and live drift.

Use `./scripts/release-check.sh --allow-dirty` only while developing the release gate itself.
