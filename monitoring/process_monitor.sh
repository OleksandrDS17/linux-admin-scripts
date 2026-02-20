#!/usr/bin/env bash
set -euo pipefail

# process_monitor.sh
# Checks if a given process name/pattern is running.
# Exit codes: 0 found, 1 not found, 2 error

PATTERN="${1:-}"
usage() {
  cat <<EOF
Usage: $0 <pattern>
Example:
  $0 nginx
  $0 "java.*myapp"
Notes:
  Uses pgrep -f if available, else ps+grep.
EOF
}

[[ -n "$PATTERN" ]] || { usage; exit 2; }

if command -v pgrep >/dev/null; then
  if pgrep -f -- "$PATTERN" >/dev/null; then
    count="$(pgrep -f -- "$PATTERN" | wc -l | tr -d ' ')"
    echo "OK - process pattern '$PATTERN' running (count=$count)"
    exit 0
  else
    echo "CRITICAL - process pattern '$PATTERN' not running"
    exit 1
  fi
else
  # fallback
  if ps aux | grep -E -- "$PATTERN" | grep -v grep >/dev/null; then
    count="$(ps aux | grep -E -- "$PATTERN" | grep -v grep | wc -l | tr -d ' ')"
    echo "OK - process pattern '$PATTERN' running (count=$count)"
    exit 0
  else
    echo "CRITICAL - process pattern '$PATTERN' not running"
    exit 1
  fi
fi
