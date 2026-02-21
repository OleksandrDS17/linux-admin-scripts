#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  login_shell_audit.sh
Audits user login shells and flags shells not listed in /etc/shells.

Exit codes:
  0 no suspicious shells found
  1 suspicious shells found
  2 error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }
[[ -r /etc/shells ]] || { echo "ERROR: Cannot read /etc/shells" >&2; exit 2; }

fail=0

# Build allowed shells set
allowed="$(awk 'NF && $1 !~ /^#/ {print $1}' /etc/shells | sort -u)"

while IFS=: read -r user _ uid gid gecos home shell; do
  [[ -n "$shell" ]] || continue

  # Skip system accounts (basic heuristic)
  if [[ "$uid" -lt 1000 && "$user" != "root" ]]; then
    continue
  fi

  if ! grep -qxF "$shell" <<<"$allowed"; then
    echo "[FAIL] $user has non-standard shell: $shell"
    fail=1
  fi
done < /etc/passwd

exit $fail
