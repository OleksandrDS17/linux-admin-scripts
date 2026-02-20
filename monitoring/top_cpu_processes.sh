#!/usr/bin/env bash
set -euo pipefail

# top_memory_processes.sh
# Shows top processes by memory usage.

TOP_N="${TOP_N:-10}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0  (Env: TOP_N=$TOP_N)"
  exit 0
fi

echo "Top $TOP_N processes by %MEM:"
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n $((TOP_N + 1))
