#!/usr/bin/env bash
set -euo pipefail

# cpu_load_check.sh
# Checks 1/5/15 load average vs CPU core count.
# Exit codes: 0 OK, 1 WARN/CRIT (threshold exceeded), 2 ERROR

WARN_PER_CORE="${WARN_PER_CORE:-1.00}"
CRIT_PER_CORE="${CRIT_PER_CORE:-2.00}"

usage() {
  cat <<EOF
Usage: $0
Env:
  WARN_PER_CORE  load-per-core warn threshold (default: $WARN_PER_CORE)
  CRIT_PER_CORE  load-per-core critical threshold (default: $CRIT_PER_CORE)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

cores="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc || echo 1)"
read -r l1 l5 l15 _ < /proc/loadavg

per_core_l1="$(awk -v l="$l1" -v c="$cores" 'BEGIN{printf "%.2f", (c>0?l/c:l)}')"

status="OK"
exit_code=0

awk -v v="$per_core_l1" -v t="$CRIT_PER_CORE" 'BEGIN{exit !(v>=t)}' && { status="CRITICAL"; exit_code=1; }
awk -v v="$per_core_l1" -v t="$WARN_PER_CORE" 'BEGIN{exit !(v>=t)}' && [[ "$status" != "CRITICAL" ]] && { status="WARNING"; exit_code=1; }

echo "$status - load1=$l1 load5=$l5 load15=$l15 cores=$cores load1_per_core=$per_core_l1 (warn>=$WARN_PER_CORE crit>=$CRIT_PER_CORE)"
exit "$exit_code"
