#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '== Shell syntax ==\n'
# Discover scripts by shebang instead of a hardcoded list so new shell files
# in these trees are covered automatically. `bash -n a b c` only checks `a`
# (b and c become its positional params), so each file is checked on its own.
while IFS= read -r -d '' file; do
  head -n1 "$file" | grep -qE '^#!.*(bash|/bin/sh|/bin/dash)$' || continue
  bash -n "$file"
done < <(
  find \
    "$ROOT/scripts" \
    "$ROOT/configs/aerospace/scripts" \
    "$ROOT/configs/swiftbar/plugins" \
    "$ROOT/configs/borders" \
    -type f \( -name '*.sh' -o -perm -111 \) -print0 \
    | sort -z
)

printf '\n== JSON ==\n'
while IFS= read -r json_file; do
  python3 -m json.tool "$json_file" >/dev/null
done < <(find "$ROOT/configs" -name '*.json' -type f | sort)

printf '\n== Config contracts ==\n'
"$ROOT/scripts/validate-configs.py"

printf '\nVerification passed.\n'
