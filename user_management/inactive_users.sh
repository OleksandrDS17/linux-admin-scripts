#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  inactive_users.sh [--days N]
Lists users who have not logged in for N days (default: 90).

Notes:
  Uses lastlog output. Some accounts may show "Never logged in".

Exit codes:
  0 command success (even if users are found)
  2 error
EOF
}

DAYS=90
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

command -v lastlog >/dev/null 2>&1 || { echo "ERROR: lastlog not found" >&2; exit 2; }
command -v date >/dev/null 2>&1 || { echo "ERROR: date not found" >&2; exit 2; }

cutoff_epoch="$(date -d "$DAYS days ago" +%s)"

# lastlog: Username Port From Latest
# We parse date columns and compare.
lastlog | awk -v cutoff="$cutoff_epoch" '
NR==1 {next}
{
  user=$1
  if ($0 ~ /Never logged in/) {
    print user " : Never logged in"
    next
  }
  # Typical: Mon Jan  1 12:34:56 +0000 2025 (depends)
  # We'll reconstruct the date starting at field 4.
  # lastlog output is not fully stable, so keep it simple:
  # join fields from 4..NF and let "date -d" parse it outside (in bash).
  # Instead, print raw line and let bash handle parsing via date -d.
  print $0
}' | while IFS= read -r line; do
  if [[ "$line" == *"Never logged in"* ]]; then
    echo "$line"
    continue
  fi

  user="$(awk '{print $1}' <<<"$line")"
  # remove first 3 columns (user, port, from)
  dt="$(awk '{for(i=4;i<=NF;i++) printf $i (i==NF?"" :" "); print ""}' <<<"$line")"
  epoch="$(date -d "$dt" +%s 2>/dev/null || echo "")"
  if [[ -n "$epoch" && "$epoch" -lt "$cutoff_epoch" ]]; then
    echo "$user : last login $dt"
  fi
done
