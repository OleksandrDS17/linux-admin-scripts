#!/usr/bin/env bash
set -euo pipefail

# memory_check.sh
# Checks memory usage (uses /proc/meminfo; works without free).
# Exit codes: 0 OK, 1 WARN/CRIT, 2 ERROR

WARN_PCT="${WARN_PCT:-80}"
CRIT_PCT="${CRIT_PCT:-90}"

usage() {
  cat <<EOF
Usage: $0
Env:
  WARN_PCT  warn threshold percent (default: $WARN_PCT)
  CRIT_PCT  critical threshold percent (default: $CRIT_PCT)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi
[[ -r /proc/meminfo ]] || { echo "ERROR - /proc/meminfo not readable"; exit 2; }

mem_total_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
mem_avail_kb="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)"

[[ -n "$mem_total_kb" && -n "$mem_avail_kb" ]] || { echo "ERROR - cannot parse meminfo"; exit 2; }

mem_used_kb=$(( mem_total_kb - mem_avail_kb ))
mem_used_pct="$(awk -v u="$mem_used_kb" -v t="$mem_total_kb" 'BEGIN{printf "%.0f", (t>0?(u*100)/t:0)}')"

status="OK"
exit_code=0
if (( mem_used_pct >= CRIT_PCT )); then status="CRITICAL"; exit_code=1
elif (( mem_used_pct >= WARN_PCT )); then status="WARNING"; exit_code=1
fi

echo "$status - mem_used=${mem_used_pct}% (used=${mem_used_kb}KB total=${mem_total_kb}KB avail=${mem_avail_kb}KB) (warn>=$WARN_PCT% crit>=$CRIT_PCT%)"
exit "$exit_code"
