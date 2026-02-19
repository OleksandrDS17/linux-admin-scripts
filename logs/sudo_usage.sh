#!/usr/bin/env bash
set -euo pipefail

# Summarize sudo usage (who ran what) using journalctl or auth logs.
# Usage:
#   ./sudo_usage.sh
#   ./sudo_usage.sh --since "7 days ago"
#   ./sudo_usage.sh --top 20

SINCE="24 hours ago"
TOP=10

usage() {
  cat <<EOF
Usage: $0 [--since "<time>"] [--top N]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2;;
    --top) TOP="${2:-10}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

collect_sudo() {
  if command -v journalctl >/dev/null 2>&1; then
    journalctl --since "$SINCE" --no-pager 2>/dev/null | grep -E "sudo" || true
  else
    for f in /var/log/auth.log /var/log/secure; do
      [[ -r "$f" ]] && grep -E "sudo" "$f" || true
    done
  fi
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
collect_sudo > "$tmp"

echo "=== Sudo usage (since: $SINCE) ==="
echo

# Typical sudo log line includes: "sudo: USER : TTY=... ; PWD=... ; USER=root ; COMMAND=/..."
grep -E "sudo:|sudo\[" "$tmp" | head -n 200 || true

echo
echo "=== Top $TOP users running sudo ==="
grep -E "sudo:" "$tmp" \
  | awk '
    {
      # Find "sudo:" then username often follows
      for (i=1; i<=NF; i++) {
        if ($i ~ /sudo:/ && (i+1)<=NF) { print $(i+1); break }
      }
    }' \
  | tr -d ':' \
  | sort | uniq -c | sort -nr | head -n "$TOP" || echo "(none)"

echo
echo "=== Top $TOP commands run via sudo ==="
grep -E "COMMAND=" "$tmp" \
  | sed -E 's/.*COMMAND=//g' \
  | awk '{$1=$1}1' \
  | sort | uniq -c | sort -nr | head -n "$TOP" || echo "(none)"
