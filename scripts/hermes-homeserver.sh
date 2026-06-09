#!/usr/bin/env bash
set -euo pipefail

HOST="${HERMES_SSH_HOST:-homeserver}"
REMOTE_COMMAND="${HERMES_REMOTE_COMMAND:-hermes}"

exec /usr/bin/ssh -t "$HOST" "$REMOTE_COMMAND"
