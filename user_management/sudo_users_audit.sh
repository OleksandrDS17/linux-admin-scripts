#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  sudo_users_audit.sh
Lists users who likely have sudo access.

Checks:
  - members of sudo group (Debian/Ubuntu)
  - members of wheel group (RHEL/CentOS/Fedora)
  - entries in /etc/sudoers and /etc/sudoers.d

Exit codes:
  0 success
  2 error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

command -v getent >/dev/null 2>&1 || { echo "ERROR: getent not found" >&2; exit 2; }

echo "== Sudo group members =="
if getent group sudo >/dev/null 2>&1; then
  getent group sudo | awk -F: '{print "sudo:", ($4=="" ? "(none)" : $4)}'
else
  echo "sudo group not found"
fi

echo
echo "== Wheel group members =="
if getent group wheel >/dev/null 2>&1; then
  getent group wheel | awk -F: '{print "wheel:", ($4=="" ? "(none)" : $4)}'
else
  echo "wheel group not found"
fi

echo
echo "== /etc/sudoers (non-comment lines) =="
if [[ -r /etc/sudoers ]]; then
  grep -Ev '^\s*#|^\s*$' /etc/sudoers || true
else
  echo "Cannot read /etc/sudoers"
fi

echo
echo "== /etc/sudoers.d (non-comment lines) =="
if [[ -d /etc/sudoers.d ]]; then
  # show file name + lines
  for f in /etc/sudoers.d/*; do
    [[ -f "$f" ]] || continue
    echo "--- $f ---"
    if [[ -r "$f" ]]; then
      grep -Ev '^\s*#|^\s*$' "$f" || true
    else
      echo "Cannot read $f"
    fi
  done
else
  echo "/etc/sudoers.d not found"
fi
