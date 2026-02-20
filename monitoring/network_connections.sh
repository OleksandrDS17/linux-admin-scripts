#!/usr/bin/env bash
set -euo pipefail

# network_connections.sh
# Summarizes TCP connection states and top remote IPs.
# Exit codes: always 0 (informational)

TOP_N="${TOP_N:-10}"

usage() {
  cat <<EOF
Usage: $0
Env:
  TOP_N  number of top remote IPs to show (default: $TOP_N)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

if command -v ss >/dev/null; then
  echo "TCP state summary:"
  ss -tan | awk 'NR>1{print $1}' | sort | uniq -c | sort -nr

  echo
  echo "Top remote IPs (established):"
  ss -tan state established | awk 'NR>1{print $5}' | sed 's/\[//g;s/\]//g' | awk -F: '{print $1}' \
    | sort | uniq -c | sort -nr | head -n "$TOP_N"
else
  echo "ss not found; trying netstat..."
  if command -v netstat >/dev/null; then
    echo "TCP state summary:"
    netstat -tan | awk 'NR>2{print $6}' | sort | uniq -c | sort -nr

    echo
    echo "Top remote IPs (established):"
    netstat -tan | awk 'NR>2 && $6=="ESTABLISHED"{print $5}' | awk -F: '{print $1}' \
      | sort | uniq -c | sort -nr | head -n "$TOP_N"
  else
    echo "Neither ss nor netstat found."
  fi
fi
