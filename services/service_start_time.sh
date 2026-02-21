#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_start_time.sh <service>
Shows ActiveEnterTimestamp and related activation timestamps.
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ $# -eq 1 ]] || { usage; exit 2; }

require systemctl

svc="$1"

systemctl show "$svc" --no-pager \
  -p Id -p Description \
  -p ActiveState -p SubState \
  -p ActiveEnterTimestamp -p ActiveExitTimestamp \
  -p InactiveEnterTimestamp -p InactiveExitTimestamp \
  -p ExecMainStartTimestamp -p ExecMainExitTimestamp \
  || true
