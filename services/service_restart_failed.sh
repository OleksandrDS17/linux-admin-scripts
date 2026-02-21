#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  systemd_failed_report.sh [OPTIONS]
Options:
  -n, --lines <N>     Log lines per failed unit (default 80)
  -o, --output <file> Write report to file
  -h, --help

Creates a readable report of systemd failed units and recent logs.
Exit:
  0 no failed units
  1 failed units found (report printed)
EOF
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 2; }; }

LINES=80
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--lines) LINES="${2:-}"; shift 2 ;;
    -o|--output) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

require systemctl
require journalctl
require date

tmp=""
write() {
  if [[ -n "$OUT" ]]; then
    printf "%s\n" "$1" >> "$OUT"
  else
    printf "%s\n" "$1"
  fi
}

if [[ -n "$OUT" ]]; then
  : > "$OUT"
fi

write "=== systemd FAILED report ==="
write "Generated: $(date -Is)"
write ""

mapfile -t failed < <(systemctl --failed --no-legend --plain | awk '{print $1}' | sed '/^$/d' || true)

if [[ ${#failed[@]} -eq 0 ]]; then
  write "No failed units."
  exit 0
fi

write "Failed units (${#failed[@]}):"
for u in "${failed[@]}"; do
  write " - $u"
done
write ""

for u in "${failed[@]}"; do
  write "----------------------------------------"
  write "UNIT: $u"
  write "STATUS:"
  # capture status without aborting on non-zero
  status_out="$(systemctl status "$u" --no-pager -l 2>&1 || true)"
  while IFS= read -r line; do write "$line"; done <<< "$status_out"

  write ""
  write "RECENT LOGS (last $LINES lines):"
  logs_out="$(journalctl -u "$u" --no-pager -n "$LINES" 2>&1 || true)"
  while IFS= read -r line; do write "$line"; done <<< "$logs_out"
  write ""
done

exit 1
