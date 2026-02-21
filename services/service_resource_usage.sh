#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_resource_usage.sh <service>
Shows resource-related fields if available (MemoryCurrent, CPUUsageNSec, TasksCurrent, IO stats).
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ $# -eq 1 ]] || { usage; exit 2; }

require systemctl

svc="$1"

echo "== $svc =="
systemctl status "$svc" --no-pager -l || true

echo
echo "== Resource fields (if supported by your systemd version/config) =="
systemctl show "$svc" --no-pager \
  -p MemoryCurrent -p MemoryPeak -p CPUUsageNSec -p TasksCurrent -p TasksMax \
  -p IOReadBytes -p IOWriteBytes -p IOReadOperations -p IOWriteOperations \
  -p ExecMainPID -p MainPID -p ControlPID \
  || true
