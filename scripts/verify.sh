#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '== Shell syntax ==\n'
bash -n "$ROOT"/scripts/*.sh
bash -n "$ROOT"/configs/aerospace/scripts/*
bash -n "$ROOT"/configs/swiftbar/plugins/*.sh "$ROOT"/configs/swiftbar/plugins/.helpers/*.sh

printf '\n== JSON ==\n'
while IFS= read -r json_file; do
  python3 -m json.tool "$json_file" >/dev/null
done < <(find "$ROOT/configs" -name '*.json' -type f | sort)

printf '\n== Swift build ==\n'
swift build --package-path "$ROOT/apps/HackermacLauncher"

printf '\nVerification passed.\n'
