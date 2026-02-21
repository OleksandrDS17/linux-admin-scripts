#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  uid_zero_check.sh
Finds accounts with UID 0 besides root.

Exit codes:
  0 only root has UID 0
  1 extra UID 0 accounts found
  2 error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

found=0
while IFS=: read -r user _ uid _ _ _ _; do
  if [[ "$uid" == "0" && "$user" != "root" ]]; then
    echo "UID 0 account found: $user"
    found=1
  fi
done < /etc/passwd

exit $found
