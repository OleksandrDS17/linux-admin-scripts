#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  multi_service_status.sh <service> [service2 ...]
Shows: ActiveState, SubState, UnitFileState (enabled/disabled)
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ $# -ge 1 ]] || { usage; exit 2; }

require systemctl

printf "%-35s %-10s %-12s %-12s\n" "SERVICE" "ACTIVE" "SUBSTATE" "ENABLED"
printf "%-35s %-10s %-12s %-12s\n" "-------" "------" "--------" "-------"

fail=0
for s in "$@"; do
  active="$(systemctl is-active "$s" 2>/dev/null || true)"
  sub="$(systemctl show -p SubState --value "$s" 2>/dev/null || true)"
  enabled="$(systemctl is-enabled "$s" 2>/dev/null || true)"
  [[ "$active" == "active" ]] || fail=1
  printf "%-35s %-10s %-12s %-12s\n" "$s" "$active" "${sub:-n/a}" "${enabled:-n/a}"
done

exit $fail
