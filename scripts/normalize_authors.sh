#!/usr/bin/env bash
set -u

VERSION="1.0.0"
APPLY=0
RECURSIVE=0
ROOT=""
PLANNED=0
RENAMED=0
SKIPPED=0
ERRORS=0

usage() {
  cat <<'USAGE'
Usage: normalize_authors.sh [options] [DIRECTORY]

Normalize author directories from "Surname, Given name" to "Given name Surname".
Dry-run is the default: no directory is renamed unless --apply is supplied.

Options:
  --apply              Apply changes. Without this flag, only preview them.
  --recursive          Process subdirectories recursively.
  -h, --help           Show help.
  -V, --version        Show version.

Example:
  Coelho, Paulo/  ->  Paulo Coelho/
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

while (($#)); do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --recursive) RECURSIVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -V|--version) printf '%s\n' "$VERSION"; exit 0 ;;
    --) shift; ROOT="${1:-}"; break ;;
    -*) fail "unknown option: $1" ;;
    *) [[ -z "$ROOT" ]] || fail "only one directory may be supplied"; ROOT="$1"; shift ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  read -r -p "Directory to process: " ROOT
fi

[[ -n "$ROOT" ]] || fail "no directory supplied"
[[ -d "$ROOT" ]] || fail "directory not found: $ROOT"
[[ -r "$ROOT" ]] || fail "directory is not readable: $ROOT"
[[ -w "$ROOT" || $APPLY -eq 0 ]] || fail "directory is not writable: $ROOT"
ROOT="$(realpath -- "$ROOT")"

printf 'Mode: %s\n' "$([[ $APPLY -eq 1 ]] && printf 'APPLY' || printf 'DRY-RUN')"
printf 'Recursive: %s\n\n' "$([[ $RECURSIVE -eq 1 ]] && printf 'yes' || printf 'no')"

process_dir() {
  local path="$1" base parent surname given target
  base="$(basename -- "$path")"
  [[ "$base" == *,* ]] || return 0

  surname="$(trim "${base%%,*}")"
  given="$(trim "${base#*,}")"

  if [[ -z "$surname" || -z "$given" || "$given" == *,* ]]; then
    printf '[SKIP] Ambiguous name: %s\n' "$path"
    ((SKIPPED+=1))
    return 0
  fi

  parent="$(dirname -- "$path")"
  target="$parent/$given $surname"

  if [[ "$path" == "$target" ]]; then
    ((SKIPPED+=1))
    return 0
  fi

  ((PLANNED+=1))
  if [[ -e "$target" ]]; then
    printf '[COLLISION] %s -> %s\n' "$path" "$target" >&2
    ((ERRORS+=1))
    return 0
  fi

  if (( APPLY )); then
    if mv -- "$path" "$target"; then
      printf '[RENAMED] %s -> %s\n' "$path" "$target"
      ((RENAMED+=1))
    else
      printf '[ERROR] Could not rename: %s\n' "$path" >&2
      ((ERRORS+=1))
    fi
  else
    printf '[DRY-RUN] %s -> %s\n' "$path" "$target"
  fi
}

if (( RECURSIVE )); then
  while IFS= read -r -d '' path; do
    process_dir "$path"
  done < <(find "$ROOT" -mindepth 1 -depth -type d -print0)
else
  while IFS= read -r -d '' path; do
    process_dir "$path"
  done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -type d -print0)
fi

printf '\nPlanned: %d | Renamed: %d | Skipped: %d | Errors: %d\n' "$PLANNED" "$RENAMED" "$SKIPPED" "$ERRORS"
(( ERRORS == 0 )) || exit 2
