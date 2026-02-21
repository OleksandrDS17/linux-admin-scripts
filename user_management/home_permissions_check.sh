#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  home_permissions_check.sh [--base /home]
Checks home directories for risky permissions and ownership.

Checks:
  - directory exists
  - owned by the user (for /home/<user>)
  - not group-writable or world-writable

Exit codes:
  0 no issues found
  1 issues found
  2 invalid usage / error
EOF
}

BASE="/home"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

fail=0

# Only users with home under BASE
while IFS=: read -r user _ uid gid gecos home shell; do
  [[ "$home" == "$BASE/"* ]] || continue
  [[ -n "$home" ]] || continue

  if [[ ! -d "$home" ]]; then
    echo "[FAIL] $user home dir missing: $home"
    fail=1
    continue
  fi

  # owner check
  owner="$(stat -c '%U' "$home" 2>/dev/null || echo "unknown")"
  perm="$(stat -c '%a' "$home" 2>/dev/null || echo "???")"

  if [[ "$owner" != "$user" ]]; then
    echo "[FAIL] $home owned by $owner (expected $user)"
    fail=1
  fi

  # group writable bit: 020, world writable: 002
  mode="$(stat -c '%a' "$home" 2>/dev/null || echo "")"
  if [[ -n "$mode" ]]; then
    # last 3 digits, safe even if stat returns 4 digits
    m="${mode: -3}"
    g="${m:1:1}"
    o="${m:2:1}"
    # g>=2 means write bit set? (2,3,6,7)
    if [[ "$g" =~ [2367] ]]; then
      echo "[FAIL] $home is group-writable (perm $perm)"
      fail=1
    fi
    if [[ "$o" =~ [2367] ]]; then
      echo "[FAIL] $home is world-writable (perm $perm)"
      fail=1
    fi
  fi
done < /etc/passwd

exit $fail
