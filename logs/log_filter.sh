#!/usr/bin/env bash
set -euo pipefail

# Filter a log file (or journalctl output) by include/exclude regex and optional time window.
# Usage:
#   ./log_filter.sh --include "error|failed" --since "2 hours ago"
#   ./log_filter.sh --file /var/log/syslog --include "nginx" --exclude "healthcheck"
#   ./log_filter.sh --tail 200 --include "sshd"

INCLUDE=""
EXCLUDE=""
SINCE=""
FILE=""
TAIL_LINES=0

usage() {
  cat <<EOF
Usage: $0 [--file <logfile>] [--since "<time>"] [--include "<regex>"] [--exclude "<regex>"] [--tail N]

Notes:
- If --file is not provided, journalctl is used (if available).
- --tail N limits output to last N lines (after filtering if possible).

Examples:
  $0 --include "error|failed" --since "1 hour ago"
  $0 --file /var/log/syslog --include "nginx" --exclude "healthcheck" --tail 200
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include) INCLUDE="${2:-}"; shift 2;;
    --exclude) EXCLUDE="${2:-}"; shift 2;;
    --since) SINCE="${2:-}"; shift 2;;
    --file) FILE="${2:-}"; shift 2;;
    --tail) TAIL_LINES="${2:-0}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

collect() {
  if [[ -n "$FILE" ]]; then
    [[ -r "$FILE" ]] || { echo "Cannot read $FILE" >&2; exit 1; }
    cat "$FILE"
    return
  fi

  if command -v journalctl >/dev/null 2>&1; then
    if [[ -n "$SINCE" ]]; then
      journalctl --since "$SINCE" --no-pager 2>/dev/null || true
    else
      journalctl --no-pager -n 2000 2>/dev/null || true
    fi
  else
    for f in /var/log/syslog /var/log/messages; do
      [[ -r "$f" ]] && cat "$f"
    done
  fi
}

pipe_cmd=(cat)

if [[ -n "$INCLUDE" ]]; then
  pipe_cmd+=( "|" "grep" "-Ei" "$INCLUDE" )
fi
if [[ -n "$EXCLUDE" ]]; then
  pipe_cmd+=( "|" "grep" "-Eiv" "$EXCLUDE" )
fi
if [[ "$TAIL_LINES" -gt 0 ]]; then
  pipe_cmd+=( "|" "tail" "-n" "$TAIL_LINES" )
fi

# Execute pipeline safely:
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
collect > "$tmp"

cmd="cat \"$tmp\""
[[ -n "$INCLUDE" ]] && cmd="$cmd | grep -Ei \"$INCLUDE\""
[[ -n "$EXCLUDE" ]] && cmd="$cmd | grep -Eiv \"$EXCLUDE\""
[[ "$TAIL_LINES" -gt 0 ]] && cmd="$cmd | tail -n \"$TAIL_LINES\""

# shellcheck disable=SC2090
eval "$cmd"
