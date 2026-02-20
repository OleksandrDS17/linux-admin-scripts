#!/usr/bin/env bash
set -euo pipefail

# system_health_summary.sh
# Runs multiple checks and prints a consolidated summary.
# Exit codes: 0 OK, 1 some checks non-OK, 2 error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional env thresholds (forwarded)
export WARN_PER_CORE="${WARN_PER_CORE:-1.00}"
export CRIT_PER_CORE="${CRIT_PER_CORE:-2.00}"
export WARN_PCT="${WARN_PCT:-80}"
export CRIT_PCT="${CRIT_PCT:-90}"

overall=0

run_check() {
  local name="$1"; shift
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if (( rc == 0 )); then
    echo "[OK]   $name: $out"
  else
    overall=1
    echo "[FAIL] $name: $out"
  fi
}

echo "==== System Health Summary ($(date -Is 2>/dev/null || date)) ===="

run_check "CPU Load"     "$SCRIPT_DIR/cpu_load_check.sh"
run_check "Memory"       "$SCRIPT_DIR/memory_check.sh"
run_check "Disk Usage"   "$SCRIPT_DIR/disk_usage_alert.sh"
run_check "Inodes"       "$SCRIPT_DIR/filesystem_inodes_check.sh"

echo
echo "---- Top CPU ----"
"$SCRIPT_DIR/top_cpu_processes.sh" || true
echo
echo "---- Top Memory ----"
"$SCRIPT_DIR/top_memory_processes.sh" || true

echo
echo "---- Network ----"
"$SCRIPT_DIR/network_connections.sh" || true

echo
echo "---- System Info ----"
"$SCRIPT_DIR/system_info.sh" || true

exit "$overall"
