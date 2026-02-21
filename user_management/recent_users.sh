#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  recent_users.sh [--days N]
Lists users created recently (best effort).

Primary method:
  lslogins USER,UID,CREATED (if supported)

Fallback:
  shows last password change as a proxy (chage -l).

Exit codes:
  0 success
  2 error
EOF
}

DAYS=30
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

command -v date >/dev/null 2>&1 || { echo "ERROR: date not found" >&2; exit 2; }

cutoff_epoch="$(date -d "$DAYS days ago" +%s)"

if command -v lslogins >/dev/null 2>&1; then
  # Try CREATED column; if unsupported, it may fail.
  if lslogins -o USER,UID,CREATED >/dev/null 2>&1; then
    lslogins -o USER,UID,CREATED --noheadings | while read -r user uid created_rest; do
      created="$(echo "$created_rest" | xargs || true)"
      [[ -n "$created" && "$created" != "-" ]] || continue
      epoch="$(date -d "$created" +%s 2>/dev/null || echo "")"
      [[ -n "$epoch" && "$epoch" -ge "$cutoff_epoch" ]] && echo "$user (uid=$uid) created: $created"
    done
    exit 0
  fi
fi

# Fallback: use chage "Last password change" as best effort
command -v chage >/dev/null 2>&1 || { echo "ERROR: chage not found and lslogins CREATED unsupported" >&2; exit 2; }
[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

echo "NOTE: 'created' not available. Using 'last password change' as a proxy."
while IFS=: read -r user _ uid _ _ _ shell; do
  [[ "$uid" -ge 1000 || "$user" == "root" ]] || continue
  out="$(chage -l "$user" 2>/dev/null || true)"
  last="$(awk -F: '/Last password change/ {print $2}' <<<"$out" | xargs || true)"
  [[ -n "$last" && "$last" != "never" ]] || continue
  epoch="$(date -d "$last" +%s 2>/dev/null || echo "")"
  [[ -n "$epoch" && "$epoch" -ge "$cutoff_epoch" ]] && echo "$user (uid=$uid) last password change: $last"
done < /etc/passwd
