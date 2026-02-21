#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  user_health_report.sh [--output FILE]
Runs multiple user_management checks and prints a combined report.

Exit codes:
  0 report generated (no critical findings)
  1 report generated (findings exist)
  2 error
EOF
}

OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

write() {
  if [[ -n "$OUT" ]]; then
    printf "%s\n" "$1" >> "$OUT"
  else
    printf "%s\n" "$1"
  fi
}

run_section() {
  local title="$1"; shift
  write "============================================================"
  write "$title"
  write "============================================================"
  if "$@"; then
    write ""
    return 0
  else
    rc=$?
    write ""
    return "$rc"
  fi
}

if [[ -n "$OUT" ]]; then : > "$OUT"; fi

write "User Health Report"
write "Generated: $(date -Is)"
write ""

base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

findings=0

run_section "1) Duplicate UID check"      bash "$base_dir/duplicate_uid_check.sh" || findings=1
run_section "2) UID 0 extra accounts"     bash "$base_dir/uid_zero_check.sh" || findings=1
run_section "3) Home permissions check"   bash "$base_dir/home_permissions_check.sh" || findings=1
run_section "4) Login shell audit"        bash "$base_dir/login_shell_audit.sh" || findings=1
run_section "5) User expiry check (14d)"  bash "$base_dir/user_expiry_check.sh" || findings=1

# Empty password check: treat permission issue as findings=1 but keep report
write "============================================================"
write "6) Empty password audit (requires root)"
write "============================================================"
if bash "$base_dir/empty_password_check.sh"; then
  write ""
else
  rc=$?
  if [[ "$rc" -eq 2 ]]; then
    write "WARNING: cannot read /etc/shadow (run as root to enable this check)."
    write ""
  else
    findings=1
    write ""
  fi
fi

write "============================================================"
write "7) Basic user audit summary"
write "============================================================"
bash "$base_dir/user_audit.sh" || true
write ""

exit $findings
