\
#!/usr/bin/env bash
set -euo pipefail

echo "---- VERIFY START ----"

fail=0
check() {
  local name="$1"
  shift
  if "$@"; then
    echo "[PASS] $name"
  else
    echo "[FAIL] $name"
    fail=1
  fi
}

check "apache2 active" systemctl is-active --quiet apache2
check "mariadb active" systemctl is-active --quiet mariadb
check "asterisk active" systemctl is-active --quiet asterisk

# FreePBX check (fwconsole exists after install)
if command -v fwconsole >/dev/null 2>&1; then
  echo "[PASS] fwconsole present"
else
  echo "[WARN] fwconsole not found (FreePBX may not be installed correctly)"
  fail=1
fi

# Port checks
ss -tulpn | grep -q ":80" && echo "[PASS] port 80 listening" || (echo "[FAIL] port 80 not listening"; fail=1)
ss -tulpn | grep -q ":5060" && echo "[PASS] port 5060 listening" || echo "[WARN] port 5060 not listening (SIP may be off or bound differently)"

# HTTP check
if curl -fsS http://127.0.0.1/ >/dev/null 2>&1; then
  echo "[PASS] HTTP responds on localhost"
else
  echo "[FAIL] HTTP not responding on localhost"
  fail=1
fi

echo "---- VERIFY END ----"
if [ "$fail" -ne 0 ]; then
  echo "OVERALL: FAIL"
  exit 1
fi
echo "OVERALL: PASS"
