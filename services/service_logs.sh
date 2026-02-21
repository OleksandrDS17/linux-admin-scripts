#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  service_logs.sh [OPTIONS] <service>
Options:
  -n, --lines <N>     Number of lines (default 200)
  -S, --since <time>  Since time (e.g. "1 hour ago", "2025-01-01 10:00:00")
  -U, --until <time>  Until time
  -f, --follow        Follow logs
  -h, --help

Examples:
  service_logs.sh nginx -n 100
  service_logs.sh ssh --since "24 hours ago"
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

LINES=200
SINCE=""
UNTIL=""
FOLLOW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--lines) LINES="${2:-}"; shift 2 ;;
    -S|--since) SINCE="${2:-}"; shift 2 ;;
    -U|--until) UNTIL="${2:-}"; shift 2 ;;
    -f|--follow) FOLLOW=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) break ;;
  esac
done

[[ $# -eq 1 ]] || { usage; exit 2; }
require journalctl

svc="$1"

args=( -u "$svc" "--no-pager" "-n" "$LINES" )
[[ -n "$SINCE" ]] && args+=( "--since" "$SINCE" )
[[ -n "$UNTIL" ]] && args+=( "--until" "$UNTIL" )
[[ $FOLLOW -eq 1 ]] && args+=( "-f" )

journalctl "${args[@]}"
