#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  user_expiry_check.sh [--days N]
Lists users whose account expiry date is within N days (default: 14).

Notes:
  Uses chage output. Some accounts have "never" expiry.

Exit codes:
  0 no expiring accounts found
  1 expiring accounts found
  2 error
EOF
}

DAYS=14
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

command -v chage >/dev/null 2>&1 || { echo "ERROR: chage not found" >&2; exit 2; }
command -v date >/dev/null 2>&1 || { echo "ERROR: date not found" >&2; exit 2; }
[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

now="$(date +%s)"
limit="$(date -d "$DAYS days" +%s)"

found=0
while IFS=: read -r user _ uid _ _ _ _; do
  [[ "$uid" -ge 1000 || "$user" == "root" ]] || continue

  out="$(chage -l "$user" 2>/dev/null || true)"
  exp="$(awk -F: '/Account expires/ {print $2}' <<<"$out" | xargs || true)"
  [[ -n "$exp" && "$exp" != "never" ]] || continue

  exp_epoch="$(date -d "$exp" +%s 2>/dev/null || echo "")"
  [[ -n "$exp_epoch" ]] || continue

  if [[ "$exp_epoch" -ge "$now" && "$exp_epoch" -le "$limit" ]]; then
    echo "$user expires on: $exp"
    found=1
  fi
done < /etc/passwd

exit $found
