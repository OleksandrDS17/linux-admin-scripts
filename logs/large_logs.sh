#!/usr/bin/env bash
set -euo pipefail

# Find large log files under /var/log (or custom path).
# Usage:
#   ./large_logs.sh
#   ./large_logs.sh --path /var/log --top 20

PATH_TO_SCAN="/var/log"
TOP=15

usage() {
  cat <<EOF
Usage: $0 [--path <dir>] [--top N]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) PATH_TO_SCAN="${2:-}"; shift 2;;
    --top) TOP="${2:-15}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

[[ -d "$PATH_TO_SCAN" ]] || { echo "Not a directory: $PATH_TO_SCAN" >&2; exit 1; }

echo "=== Top $TOP largest files in $PATH_TO_SCAN ==="
# -xdev avoids crossing filesystem boundaries (optional)
# Use sudo if needed: sudo ./large_logs.sh
find "$PATH_TO_SCAN" -xdev -type f -printf "%s\t%p\n" 2>/dev/null \
  | sort -nr \
  | head -n "$TOP" \
  | awk '
    function human(x) {
      s="B KB MB GB TB PB"; split(s,a," ");
      for(i=1; x>=1024 && i<6; i++) x/=1024;
      return sprintf("%.2f %s", x, a[i]);
    }
    { printf "%-10s %s\n", human($1), $2 }'
