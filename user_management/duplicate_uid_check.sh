#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  duplicate_uid_check.sh
Checks /etc/passwd for duplicate UIDs.

Exit codes:
  0 no duplicates found
  1 duplicates found
  2 error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

awk -F: '
{
  uid=$3; user=$1;
  users[uid] = (uid in users) ? users[uid] "," user : user;
  count[uid]++
}
END {
  found=0
  for (u in count) {
    if (count[u] > 1) {
      found=1
      printf "Duplicate UID %s: %s\n", u, users[u]
    }
  }
  exit(found ? 1 : 0)
}' /etc/passwd
