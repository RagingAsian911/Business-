\
#!/bin/bash
set -euo pipefail

LOG="/var/log/usb-business-fix.log"
MARK="/var/lib/usb-business-fix.done"

echo "==== USB RUN START $(date) ====" | tee -a "$LOG"

if [ -f "$MARK" ]; then
  echo "Already ran once. Marker exists: $MARK" | tee -a "$LOG"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

mkdir -p /root/business-fix
cd /root/business-fix

# Clone/pull the one repo that actually builds the PBX + web stack
URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
fi

if [ ! -d repo/.git ]; then
  git clone -b "$BRANCH" "$URL" repo 2>&1 | tee -a "$LOG"
else
  (cd repo && git pull 2>&1 | tee -a "$LOG") || true
fi

cd repo
chmod +x "$BOOTSTRAP_PATH"
bash "./$BOOTSTRAP_PATH" 2>&1 | tee -a "$LOG"

mkdir -p /var/lib
touch "$MARK"
echo "Created marker: $MARK" | tee -a "$LOG"
echo "==== USB RUN END $(date) ====" | tee -a "$LOG"
