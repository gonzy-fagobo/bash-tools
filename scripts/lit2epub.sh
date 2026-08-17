#!/usr/bin/env bash
set -u

VERSION="1.0.0"
APPLY=0
RECURSIVE=0
OVERWRITE=0
DELETE_SOURCE=0
VERBOSE=0
ROOT=""
LOG_FILE=""
FOUND=0
CONVERTED=0
SKIPPED=0
FAILED=0

usage() {
  cat <<'USAGE'
Usage: lit2epub.sh [options] [DIRECTORY]

Batch-convert Microsoft Reader .lit files to .epub using Calibre's ebook-convert.
Dry-run is the default. Use --apply to perform conversions.

Options:
  --apply              Perform conversions; otherwise preview only.
  --recursive          Search subdirectories recursively.
  --overwrite          Replace an existing .epub destination.
  --delete-source      Delete .lit only after a successful conversion.
  --log FILE           Append operation messages to FILE.
  --verbose            Show the ebook-convert command before execution.
  -h, --help           Show help.
  -V, --version        Show version.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() {
  local message="$1"
  printf '%s\n' "$message"
  if [[ -n "$LOG_FILE" ]]; then
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$LOG_FILE"
  fi
}

while (($#)); do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --recursive) RECURSIVE=1; shift ;;
    --overwrite) OVERWRITE=1; shift ;;
    --delete-source) DELETE_SOURCE=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    --log)
      (($# >= 2)) || fail "--log requires a file"
      LOG_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -V|--version) printf '%s\n' "$VERSION"; exit 0 ;;
    --) shift; ROOT="${1:-}"; break ;;
    -*) fail "unknown option: $1" ;;
    *) [[ -z "$ROOT" ]] || fail "only one directory may be supplied"; ROOT="$1"; shift ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  read -r -p "Directory containing .lit files: " ROOT
fi

[[ -n "$ROOT" ]] || fail "no directory supplied"
[[ -d "$ROOT" ]] || fail "directory not found: $ROOT"
[[ -r "$ROOT" ]] || fail "directory is not readable: $ROOT"
ROOT="$(realpath -- "$ROOT")"

if (( APPLY )); then
  command -v ebook-convert >/dev/null 2>&1 || fail "ebook-convert not found. Install Calibre first."
fi
if (( DELETE_SOURCE && ! APPLY )); then
  fail "--delete-source requires --apply"
fi
if [[ -n "$LOG_FILE" ]]; then
  touch "$LOG_FILE" 2>/dev/null || fail "cannot write log file: $LOG_FILE"
fi

convert_one() {
  local src="$1" dest tmp
  ((FOUND+=1))
  dest="${src%.[Ll][Ii][Tt]}.epub"

  if [[ -e "$dest" && $OVERWRITE -eq 0 ]]; then
    log "[SKIP] Destination exists: $dest"
    ((SKIPPED+=1))
    return
  fi

  if (( ! APPLY )); then
    log "[DRY-RUN] $src -> $dest"
    return
  fi

  tmp="${dest}.partial.$$"
  rm -f -- "$tmp"

  (( VERBOSE )) && log "[CMD] ebook-convert '$src' '$tmp'"
  if ebook-convert "$src" "$tmp" >/dev/null 2>&1 && [[ -s "$tmp" ]]; then
    if (( OVERWRITE )); then
      rm -f -- "$dest"
    fi
    if mv -- "$tmp" "$dest"; then
      log "[OK] $src -> $dest"
      ((CONVERTED+=1))
      if (( DELETE_SOURCE )); then
        if rm -- "$src"; then
          log "[DELETE] $src"
        else
          log "[WARN] Converted but could not delete source: $src"
        fi
      fi
    else
      rm -f -- "$tmp"
      log "[ERROR] Could not finalize destination: $dest"
      ((FAILED+=1))
    fi
  else
    rm -f -- "$tmp"
    log "[ERROR] Conversion failed: $src"
    ((FAILED+=1))
  fi
}

if (( RECURSIVE )); then
  while IFS= read -r -d '' src; do convert_one "$src"; done \
    < <(find "$ROOT" -type f -iname '*.lit' -print0)
else
  while IFS= read -r -d '' src; do convert_one "$src"; done \
    < <(find "$ROOT" -maxdepth 1 -type f -iname '*.lit' -print0)
fi

printf '\nFound: %d | Converted: %d | Skipped: %d | Failed: %d\n' "$FOUND" "$CONVERTED" "$SKIPPED" "$FAILED"
(( FAILED == 0 )) || exit 2
