#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_dependencies.sh <service>
Outputs dependencies via systemctl list-dependencies and key unit properties.
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }
[[ $# -eq 1 ]] || { usage; exit 2; }

require systemctl

svc="$1"

echo "== Unit: $svc =="
systemctl status "$svc" --no-pager -l || true

echo
echo "== list-dependencies (reverse) =="
systemctl list-dependencies --reverse "$svc" --no-pager || true

echo
echo "== list-dependencies =="
systemctl list-dependencies "$svc" --no-pager || true

echo
echo "== Key relations =="
systemctl show "$svc" \
  -p Wants -p Requires -p After -p Before -p PartOf -p BindsTo -p Conflicts \
  --no-pager || true
