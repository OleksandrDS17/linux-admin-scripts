#!/usr/bin/env bash
set -euo pipefail

# system_info.sh
# Prints basic system information (host, OS, kernel, uptime, CPU, mem).

echo "Hostname: $(hostname)"
echo "Date:     $(date -Is 2>/dev/null || date)"
echo "Kernel:   $(uname -srmo 2>/dev/null || uname -a)"

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "OS:       ${PRETTY_NAME:-$NAME}"
fi

if command -v uptime >/dev/null; then
  echo "Uptime:   $(uptime -p 2>/dev/null || uptime)"
fi

cores="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc || echo 1)"
model="$(awk -F: '/model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
echo "CPU:      ${model:-unknown} (cores=$cores)"

if [[ -r /proc/meminfo ]]; then
  mt="$(awk '/^MemTotal:/ {print $2 " " $3}' /proc/meminfo)"
  ma="$(awk '/^MemAvailable:/ {print $2 " " $3}' /proc/meminfo)"
  echo "Memory:   total=$mt available=$ma"
fi

echo "Disk (df -h):"
df -hT 2>/dev/null | sed -n '1,10p' || true
