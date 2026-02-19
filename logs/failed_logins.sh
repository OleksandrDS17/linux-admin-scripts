#!/usr/bin/env bash
set -euo pipefail

# Show failed login attempts from auth logs (journalctl or /var/log/auth.log/secure).
# Usage:
#   ./failed_logins.sh
#   ./failed_logins.sh --since "7 days ago"
#   ./failed_logins.sh --top 20

SINCE="24 hours ago"
TOP=10

usage() {
  cat <<EOF
Usage: $0 [--since "<time>"] [--top N]

Examples:
  $0 --since "7 days ago" --top 20
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

collect_auth() {
  if command -v journalctl >/dev/null 2>&1; then
    # auth facility varies; SYSLOG_IDENTIFIER=sshd is a good start
    journalctl --since "$SINCE" --no-pager 2>/dev/null \
      | grep -E "sshd|pam_unix|sudo|login" || true
  else
    for f in /var/log/auth.log /var/log/secure; do
      [[ -r "$f" ]] && cat "$f"
    done
  fi
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
collect_auth | tee "$tmp" >/dev/null

echo "=== Failed login attempts (since: $SINCE) ==="
echo

# Common patterns:
# - sshd: Failed password for ...
# - sshd: Invalid user ...
# - pam_unix(...): authentication failure
grep -iE "Failed password|Invalid user|authentication failure|Failed publickey" "$tmp" || true

echo
echo "=== Top $TOP source IPs (failed ssh logins) ==="
grep -iE "sshd.*(Failed password|Invalid user|Failed publickey)" "$tmp" \
  | awk '
    {
      for (i=1; i<=NF; i++) {
        if ($i == "from" && (i+1)<=NF) { print $(i+1) }
      }
    }' \
  | sed 's/[[:space:]]//g' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|^[0-9a-fA-F:]+$' \
  | sort | uniq -c | sort -nr | head -n "$TOP" \
  || echo "(no IPs found)"

echo
echo "=== Top $TOP usernames (failed ssh logins) ==="
grep -iE "sshd.*(Failed password|Invalid user|Failed publickey)" "$tmp" \
  | awk '
    {
      # try to capture username after "for" (or after "user")
      for (i=1; i<=NF; i++) {
        if ($i == "for" && (i+1)<=NF) { print $(i+1); break }
        if ($i == "user" && (i+1)<=NF) { print $(i+1); break }
      }
    }' \
  | tr -d ':' \
  | sort | uniq -c | sort -nr | head -n "$TOP" \
  || echo "(no usernames found)"
