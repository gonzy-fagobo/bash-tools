#!/usr/bin/env bash
set -u

VERSION="1.0.0"
MAX_DEPTH=-1
DIRS_ONLY=0
OUTPUT=""
ROOT=""
DIR_COUNT=0
FILE_COUNT=0

usage() {
  cat <<'USAGE'
Usage: tree_inventory.sh [options] [DIRECTORY]

Generate a readable recursive tree without requiring the `tree` command.

Options:
  --dirs-only          Show directories only.
  --max-depth N        Limit recursion depth (root children = depth 1).
  --output FILE        Write the report to FILE instead of stdout.
  -h, --help           Show help.
  -V, --version        Show version.

If DIRECTORY is omitted, the script asks for it interactively.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --dirs-only) DIRS_ONLY=1; shift ;;
    --max-depth)
      (($# >= 2)) || fail "--max-depth requires a value"
      [[ "$2" =~ ^[0-9]+$ ]] || fail "--max-depth must be a non-negative integer"
      MAX_DEPTH="$2"; shift 2 ;;
    --output)
      (($# >= 2)) || fail "--output requires a file"
      OUTPUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -V|--version) printf '%s\n' "$VERSION"; exit 0 ;;
    --) shift; ROOT="${1:-}"; break ;;
    -*) fail "unknown option: $1" ;;
    *) [[ -z "$ROOT" ]] || fail "only one directory may be supplied"; ROOT="$1"; shift ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  read -r -p "Directory to inventory: " ROOT
fi

[[ -n "$ROOT" ]] || fail "no directory supplied"
[[ -d "$ROOT" ]] || fail "directory not found: $ROOT"
[[ -r "$ROOT" ]] || fail "directory is not readable: $ROOT"

ROOT="$(realpath -- "$ROOT")"

emit() {
  if [[ -n "$OUTPUT" ]]; then
    printf '%s\n' "$1" >> "$OUTPUT"
  else
    printf '%s\n' "$1"
  fi
}

walk() {
  local dir="$1" prefix="$2" depth="$3"
  local -a entries=()
  local entry name connector child_prefix
  local i total

  if (( MAX_DEPTH >= 0 && depth >= MAX_DEPTH )); then
    return
  fi

  if (( DIRS_ONLY )); then
    mapfile -d '' -t entries < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
  else
    mapfile -d '' -t entries < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
  fi

  total=${#entries[@]}
  for ((i=0; i<total; i++)); do
    entry="${entries[i]}"
    name="$(basename -- "$entry")"
    if (( i == total - 1 )); then
      connector='└── '
      child_prefix="${prefix}    "
    else
      connector='├── '
      child_prefix="${prefix}│   "
    fi

    if [[ -d "$entry" ]]; then
      ((DIR_COUNT+=1))
      emit "${prefix}${connector}${name}/"
      walk "$entry" "$child_prefix" $((depth + 1))
    else
      ((FILE_COUNT+=1))
      emit "${prefix}${connector}${name}"
    fi
  done
}

if [[ -n "$OUTPUT" ]]; then
  : > "$OUTPUT" || fail "cannot write output file: $OUTPUT"
fi

emit "$(basename -- "$ROOT")/"
walk "$ROOT" "" 0
emit ""
emit "Directories: $DIR_COUNT"
if (( ! DIRS_ONLY )); then
  emit "Files: $FILE_COUNT"
fi
