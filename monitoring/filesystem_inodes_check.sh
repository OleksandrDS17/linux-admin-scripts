#!/usr/bin/env bash
set -euo pipefail

# filesystem_inodes_check.sh
# Checks inode usage using df -i.
# Exit codes: 0 OK, 1 WARN/CRIT, 2 ERROR

WARN_PCT="${WARN_PCT:-80}"
CRIT_PCT="${CRIT_PCT:-90}"
EXCLUDE_REGEX="${EXCLUDE_REGEX:-^(tmpfs|devtmpfs|overlay|squashfs)$}"

usage() {
  cat <<EOF
Usage: $0
Env:
  WARN_PCT        warn threshold percent (default: $WARN_PCT)
  CRIT_PCT        critical threshold percent (default: $CRIT_PCT)
  EXCLUDE_REGEX   filesystem type regex to exclude (default: $EXCLUDE_REGEX)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

if ! command -v df >/dev/null; then
  echo "ERROR - df not found"
  exit 2
fi

exit_code=0
worst="OK"
messages=()

# Need type + inode percent: combine df -PT and df -Pi
# Build map mount->type
declare -A mnt_type
while read -r _ type _ _ _ _ mnt; do
  mnt_type["$mnt"]="$type"
done < <(df -PT 2>/dev/null | awk 'NR>1{print $1,$2,$3,$4,$5,$6,$7}')

while read -r _ inodes iused ifree iusepct mnt; do
  type="${mnt_type[$mnt]:-unknown}"
  [[ "$type" =~ $EXCLUDE_REGEX ]] && continue
  pct="${iusepct%\%}"

  if (( pct >= CRIT_PCT )); then
    worst="CRITICAL"; exit_code=1; messages+=("$mnt=${pct}%")
  elif (( pct >= WARN_PCT )); then
    [[ "$worst" != "CRITICAL" ]] && worst="WARNING"
    exit_code=1; messages+=("$mnt=${pct}%")
  fi
done < <(df -Pi 2>/dev/null | awk 'NR>1{print $1,$2,$3,$4,$5,$6}')

if [[ "${#messages[@]}" -eq 0 ]]; then
  echo "OK - inode usage below thresholds (warn>=$WARN_PCT% crit>=$CRIT_PCT%)"
  exit 0
fi

echo "$worst - high inode usage: ${messages[*]} (warn>=$WARN_PCT% crit>=$CRIT_PCT%)"
exit "$exit_code"
