#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/library/Coelho, Paulo/Subdir" "$TMP/library/Camus, Albert"
touch "$TMP/library/Coelho, Paulo/book.epub" "$TMP/library/readme.txt"

printf '== Syntax checks ==\n'
for s in "$ROOT"/scripts/*.sh; do
  bash -n "$s"
  printf 'OK  %s\n' "$(basename "$s")"
done

printf '\n== Tree inventory ==\n'
bash "$ROOT/scripts/tree_inventory.sh" --max-depth 2 "$TMP/library" >/dev/null
printf 'OK  tree_inventory.sh\n'

printf '\n== Author normalization dry-run ==\n'
out="$(bash "$ROOT/scripts/normalize_authors.sh" --recursive "$TMP/library")"
grep -q 'Paulo Coelho' <<<"$out"
grep -q 'Albert Camus' <<<"$out"
[[ -d "$TMP/library/Coelho, Paulo" ]]
printf 'OK  dry-run makes no changes\n'

printf '\n== Author normalization apply ==\n'
bash "$ROOT/scripts/normalize_authors.sh" --apply "$TMP/library" >/dev/null
[[ -d "$TMP/library/Paulo Coelho" ]]
[[ -d "$TMP/library/Albert Camus" ]]
printf 'OK  apply renames expected directories\n'

printf '\n== LIT converter dry-run ==\n'
touch "$TMP/library/example.lit"
out="$(bash "$ROOT/scripts/lit2epub.sh" "$TMP/library")"
grep -q '\[DRY-RUN\]' <<<"$out"
[[ ! -e "$TMP/library/example.epub" ]]
printf 'OK  conversion preview makes no changes\n'

printf '\nAll smoke tests passed.\n'
