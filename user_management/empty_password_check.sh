#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  empty_password_check.sh
Checks /etc/shadow for accounts with empty password field.

Note:
  Requires root to read /etc/shadow.

Exit codes:
  0 no empty passwords found
  1 empty password accounts found
  2 cannot read /etc/shadow / error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

if [[ ! -r /etc/shadow ]]; then
  echo "ERROR: Cannot read /etc/shadow (run as root)." >&2
  exit 2
fi

# Empty password field means no password set (login without password can be possible depending on config)
awk -F: '$2=="" {print "Empty password field:", $1; found=1} END{exit(found?1:0)}' /etc/shadow
