#!/usr/bin/env bash
set -euo pipefail

# top_cpu_processes.sh
# Shows top processes by CPU usage.

TOP_N="${TOP_N:-10}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0  (Env: TOP_N=$TOP_N)"
  exit 0
fi

echo "Top $TOP_N processes by %CPU:"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n $((TOP_N + 1))
