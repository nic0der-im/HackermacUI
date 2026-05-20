# Maintenance guide

## Before changing UI behavior

1. Run `./scripts/status.sh`.
2. Run `./scripts/backup.sh`.
3. Change one tool at a time.
4. Reload only the affected tool.
5. Run `./scripts/check-drift.sh`.
6. Commit with a conventional commit message.

## Reload commands

```bash
aerospace reload-config
open 'swiftbar://refreshallplugins'
~/.config/borders/bordersrc
```

## Rollback principle

Use git history for public config rollback. Use `~/.hackermacui/backups/` for private machine-state rollback.
