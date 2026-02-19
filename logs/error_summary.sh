#!/usr/bin/env bash
set -euo pipefail

# Summarize common error keywords from system logs (journalctl or /var/log).
# Usage:
#   ./error_summary.sh                 # last 24h
#   ./error_summary.sh --since "2 hours ago"
#   ./error_summary.sh --since "2026-02-20 00:00:00"
#   ./error_summary.sh --file /var/log/syslog

SINCE="24 hours ago"
FILE=""

usage() {
  cat <<EOF
Usage: $0 [--since "<time>"] [--file <logfile>]

Examples:
  $0
  $0 --since "2 hours ago"
  $0 --file /var/log/syslog
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2;;
    --file)  FILE="${2:-}"; shift 2;;
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
    journalctl --since "$SINCE" --no-pager 2>/dev/null || true
  else
    # Fallback: try common files
    for f in /var/log/syslog /var/log/messages; do
      [[ -r "$f" ]] && cat "$f"
    done
  fi
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

collect | tee "$tmp" >/dev/null

echo "=== Error summary (since: ${SINCE}, source: ${FILE:-journalctl/logfiles}) ==="
echo

# Count by keyword (case-insensitive)
keywords=( "error" "failed" "fail" "critical" "panic" "segfault" "denied" "refused" "timeout" )
for k in "${keywords[@]}"; do
  c=$(grep -iE "\b${k}\b" "$tmp" | wc -l | tr -d ' ')
  printf "%-10s %8s\n" "$k" "$c"
done

echo
echo "=== Top 20 most frequent 'error-like' lines (normalized) ==="
grep -iE "(error|failed|critical|panic|segfault|denied|refused|timeout)" "$tmp" \
  | sed -E 's/[0-9]{2}:[0-9]{2}:[0-9]{2}//g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}//g; s/\bpid=[0-9]+\b/pid=?/g; s/\b[0-9]+\b/?/g' \
  | awk '{$1=$1}1' \
  | sort | uniq -c | sort -nr | head -20
