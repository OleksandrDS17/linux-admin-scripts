#!/usr/bin/env bash
set -euo pipefail

# Watch logs in real-time (tail -f or journalctl -f) with optional include/exclude regex.
# Usage:
#   ./log_watch.sh --include "error|failed"
#   ./log_watch.sh --file /var/log/syslog --include "nginx"
#   ./log_watch.sh --exclude "healthcheck"

INCLUDE=""
EXCLUDE=""
FILE=""

usage() {
  cat <<EOF
Usage: $0 [--file <logfile>] [--include "<regex>"] [--exclude "<regex>"]

Examples:
  $0 --include "error|failed"
  $0 --file /var/log/auth.log --include "sshd"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include) INCLUDE="${2:-}"; shift 2;;
    --exclude) EXCLUDE="${2:-}"; shift 2;;
    --file) FILE="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

stream() {
  if [[ -n "$FILE" ]]; then
    [[ -r "$FILE" ]] || { echo "Cannot read $FILE" >&2; exit 1; }
    tail -n 50 -F "$FILE"
    return
  fi

  if command -v journalctl >/dev/null 2>&1; then
    journalctl -f --no-pager
  else
    echo "journalctl not available and no --file provided." >&2
    exit 1
  fi
}

# Build filter chain
if [[ -n "$INCLUDE" && -n "$EXCLUDE" ]]; then
  stream | grep -Ei "$INCLUDE" | grep -Eiv "$EXCLUDE"
elif [[ -n "$INCLUDE" ]]; then
  stream | grep -Ei "$INCLUDE"
elif [[ -n "$EXCLUDE" ]]; then
  stream | grep -Eiv "$EXCLUDE"
else
  stream
fi
