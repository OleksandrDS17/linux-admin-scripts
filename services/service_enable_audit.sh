#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_enable_audit.sh [OPTIONS] <service> [service2 ...]
Options:
  -e, --expected <enabled|disabled|static>  Expectation for all services
  -d, --diff-only                          Print only mismatches
  -h, --help

Exit codes:
  0 all match expectation (if set) or command ok
  1 mismatches found
  2 invalid usage
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

EXPECTED=""
DIFF=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--expected) EXPECTED="${2:-}"; shift 2 ;;
    -d|--diff-only) DIFF=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) break ;;
  esac
done

[[ $# -ge 1 ]] || { usage; exit 2; }
require systemctl

fail=0
for s in "$@"; do
  st="$(systemctl is-enabled "$s" 2>/dev/null || echo "unknown")"
  if [[ -n "$EXPECTED" ]]; then
    if [[ "$st" != "$EXPECTED" ]]; then
      fail=1
      [[ $DIFF -eq 1 ]] && printf "%-35s %s (expected %s)\n" "$s" "$st" "$EXPECTED" || {
        printf "%-35s %s (expected %s)\n" "$s" "$st" "$EXPECTED"
      }
    else
      [[ $DIFF -eq 1 ]] || printf "%-35s %s\n" "$s" "$st"
    fi
  else
    printf "%-35s %s\n" "$s" "$st"
  fi
done

exit $fail
