#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  critical_services_check.sh [OPTIONS]
Options:
  -f, --file <path>     File with service names (one per line, # comments allowed)
  -s, --services "a b"  Space separated list of services
  -r, --restart         Restart services that are not active
  -h, --help            Show help

Exit codes:
  0 all active
  1 at least one not active (and restart disabled or restart failed)
  2 invalid usage
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

FILE=""
SERV_STR=""
RESTART=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file) FILE="${2:-}"; shift 2 ;;
    -s|--services) SERV_STR="${2:-}"; shift 2 ;;
    -r|--restart) RESTART=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

require systemctl

services=()
if [[ -n "$FILE" ]]; then
  [[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 2; }
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs || true)"
    [[ -n "$line" ]] && services+=("$line")
  done < "$FILE"
elif [[ -n "$SERV_STR" ]]; then
  # shellcheck disable=SC2206
  services=($SERV_STR)
else
  echo "Provide --file or --services" >&2
  usage
  exit 2
fi

[[ ${#services[@]} -gt 0 ]] || { echo "No services to check." >&2; exit 2; }

fail=0
for s in "${services[@]}"; do
  state="$(systemctl is-active "$s" 2>/dev/null || true)"
  if [[ "$state" != "active" ]]; then
    echo "[FAIL] $s is $state"
    if [[ $RESTART -eq 1 ]]; then
      echo "  -> restarting $s ..."
      if systemctl restart "$s"; then
        new_state="$(systemctl is-active "$s" 2>/dev/null || true)"
        if [[ "$new_state" == "active" ]]; then
          echo "  -> OK after restart"
        else
          echo "  -> still $new_state"
          fail=1
        fi
      else
        echo "  -> restart failed"
        fail=1
      fi
    else
      fail=1
    fi
  else
    echo "[OK]   $s active"
  fi
done

exit $fail
