#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  user_audit.sh
Basic user audit summary.

Outputs:
  - total users
  - human users (uid >= 1000) + root
  - locked accounts (best effort via passwd -S)
  - users with /bin/bash like shells (interactive)

Exit codes:
  0 success
  2 error
EOF
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || { usage; exit 0; }

[[ -r /etc/passwd ]] || { echo "ERROR: Cannot read /etc/passwd" >&2; exit 2; }

total="$(wc -l < /etc/passwd | tr -d ' ')"
human="$(awk -F: '($3>=1000)||($1=="root"){c++} END{print c+0}' /etc/passwd)"
interactive="$(awk -F: '($3>=1000)||($1=="root"){ if($7 !~ /(nologin|false)$/) c++ } END{print c+0}' /etc/passwd)"

echo "Total users:            $total"
echo "Human users (+root):    $human"
echo "Interactive users:      $interactive"

echo
echo "== Locked accounts (best effort) =="
if command -v passwd >/dev/null 2>&1; then
  # passwd -S user => status in 2nd column (L = locked)
  awk -F: '{print $1}' /etc/passwd | while read -r u; do
    st="$(passwd -S "$u" 2>/dev/null | awk '{print $2}' || true)"
    [[ "$st" == "L" ]] && echo "$u locked"
  done
else
  echo "passwd command not found; cannot check locked accounts"
fi

echo
echo "== Interactive shells (uid>=1000 + root) =="
awk -F: '($3>=1000)||($1=="root"){ if($7 !~ /(nologin|false)$/) print $1 " -> " $7 }' /etc/passwd
