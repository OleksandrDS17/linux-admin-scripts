#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  check_services.sh [OPTIONS] <service> [service2 ...]
Options:
  -q, --quiet      Only exit code, no output
  -j, --json       Output JSON
  -h, --help       Show help

Exit codes:
  0 all services active
  1 at least one service not active
  2 invalid usage / missing systemctl
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

QUIET=0
JSON=0
SERVICES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quiet) QUIET=1; shift ;;
    -j|--json) JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; SERVICES+=("$@"); break ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) SERVICES+=("$1"); shift ;;
  esac
done

require systemctl

if [[ ${#SERVICES[@]} -eq 0 ]]; then
  echo "No services provided." >&2
  usage
  exit 2
fi

fail=0

if [[ $JSON -eq 1 ]]; then
  printf '{ "services": ['
  first=1
  for s in "${SERVICES[@]}"; do
    state="$(systemctl is-active "$s" 2>/dev/null || true)"
    sub="$(systemctl show -p SubState --value "$s" 2>/dev/null || true)"
    desc="$(systemctl show -p Description --value "$s" 2>/dev/null || true)"
    [[ "$state" == "active" ]] || fail=1
    [[ $first -eq 1 ]] || printf ','
    first=0
    printf '%s' "{\"name\":\"$s\",\"is_active\":\"$state\",\"sub_state\":\"$sub\",\"description\":\"${desc//\"/\\\"}\"}"
  done
  printf '] }\n'
else
  for s in "${SERVICES[@]}"; do
    state="$(systemctl is-active "$s" 2>/dev/null || true)"
    [[ "$state" == "active" ]] || fail=1
    if [[ $QUIET -eq 0 ]]; then
      printf "%-35s %s\n" "$s" "$state"
    fi
  done
fi

exit $fail
