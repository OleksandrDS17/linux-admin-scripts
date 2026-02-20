#!/usr/bin/env bash
set -euo pipefail

# disk_usage_alert.sh
# Alerts when any filesystem usage exceeds a threshold.
# Exit codes: 0 OK, 1 WARN/CRIT found, 2 ERROR

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

# POSIX df output: Filesystem Type Size Used Avail Use% Mounted on
while read -r fs type size used avail usepct mnt; do
  [[ "$type" =~ $EXCLUDE_REGEX ]] && continue
  pct="${usepct%\%}"

  if (( pct >= CRIT_PCT )); then
    worst="CRITICAL"
    exit_code=1
    messages+=("$mnt=${pct}%")
  elif (( pct >= WARN_PCT )); then
    [[ "$worst" != "CRITICAL" ]] && worst="WARNING"
    exit_code=1
    messages+=("$mnt=${pct}%")
  fi
done < <(df -PT 2>/dev/null | awk 'NR>1{print $1,$2,$3,$4,$5,$6,$7}')

if [[ "${#messages[@]}" -eq 0 ]]; then
  echo "OK - disk usage below thresholds (warn>=$WARN_PCT% crit>=$CRIT_PCT%)"
  exit 0
fi

echo "$worst - high disk usage: ${messages[*]} (warn>=$WARN_PCT% crit>=$CRIT_PCT%)"
exit "$exit_code"
