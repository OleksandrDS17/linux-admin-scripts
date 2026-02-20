#!/usr/bin/env bash
set -euo pipefail

# service_health_check.sh
# Checks systemd service status for one or multiple services.
# Exit codes: 0 all OK, 1 one or more not active, 2 error

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -eq 0 ]]; then
  cat <<EOF
Usage: $0 <service1> [service2 ...]
Example:
  $0 sshd cron docker
EOF
  exit 2
fi

command -v systemctl >/dev/null || { echo "ERROR - systemctl not found (systemd required)"; exit 2; }

bad=()
for svc in "$@"; do
  if systemctl is-active --quiet "$svc"; then
    :
  else
    bad+=("$svc")
  fi
done

if [[ "${#bad[@]}" -eq 0 ]]; then
  echo "OK - all services active: $*"
  exit 0
fi

echo "CRITICAL - inactive services: ${bad[*]}"
exit 1
