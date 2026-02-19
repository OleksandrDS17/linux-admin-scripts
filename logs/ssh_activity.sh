#!/usr/bin/env bash
set -euo pipefail

# Show SSH activity summary (accepted logins, disconnects) from logs.
# Usage:
#   ./ssh_activity.sh
#   ./ssh_activity.sh --since "7 days ago"
#   ./ssh_activity.sh --top 20

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

collect_sshd() {
  if command -v journalctl >/dev/null 2>&1; then
    journalctl --since "$SINCE" --no-pager 2>/dev/null | grep -E "sshd" || true
  else
    for f in /var/log/auth.log /var/log/secure; do
      [[ -r "$f" ]] && grep -E "sshd" "$f" || true
    done
  fi
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
collect_sshd > "$tmp"

echo "=== SSH activity (since: $SINCE) ==="
echo

echo "Accepted logins:"
grep -E "sshd.*Accepted (password|publickey|keyboard-interactive)" "$tmp" || echo "(none)"
echo

echo "=== Top $TOP source IPs (accepted) ==="
grep -E "sshd.*Accepted (password|publickey|keyboard-interactive)" "$tmp" \
  | awk '{for(i=1;i<=NF;i++) if($i=="from" && (i+1)<=NF) print $(i+1)}' \
  | sort | uniq -c | sort -nr | head -n "$TOP" || echo "(none)"
echo

echo "=== Top $TOP users (accepted) ==="
grep -E "sshd.*Accepted (password|publickey|keyboard-interactive)" "$tmp" \
  | awk '{for(i=1;i<=NF;i++) if($i=="for" && (i+1)<=NF) {print $(i+1); break}}' \
  | sort | uniq -c | sort -nr | head -n "$TOP" || echo "(none)"
echo

echo "Disconnects (summary):"
grep -E "sshd.*(Disconnected from|Received disconnect|Connection closed)" "$tmp" \
  | head -n 50 || echo "(none)"
