#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_uptime.sh <service>
Prints service uptime based on ActiveEnterTimestamp (if active).
Exit:
  0 if active and uptime printed
  1 if not active / no timestamp
  2 invalid usage
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ $# -eq 1 ]] || { usage; exit 2; }

require systemctl
require date

svc="$1"

state="$(systemctl is-active "$svc" 2>/dev/null || true)"
if [[ "$state" != "active" ]]; then
  echo "$svc is $state (no uptime)"
  exit 1
fi

ts="$(systemctl show -p ActiveEnterTimestamp --value "$svc" 2>/dev/null || true)"
if [[ -z "$ts" || "$ts" == "n/a" ]]; then
  echo "No ActiveEnterTimestamp for $svc"
  exit 1
fi

start_epoch="$(date -d "$ts" +%s 2>/dev/null || true)"
now_epoch="$(date +%s)"
if [[ -z "$start_epoch" ]]; then
  echo "Failed to parse timestamp: $ts"
  exit 1
fi

diff=$((now_epoch - start_epoch))
days=$((diff / 86400)); diff=$((diff % 86400))
hours=$((diff / 3600)); diff=$((diff % 3600))
mins=$((diff / 60)); secs=$((diff % 60))

printf "%s uptime: %dd %02dh %02dm %02ds (since %s)\n" "$svc" "$days" "$hours" "$mins" "$secs" "$ts"
