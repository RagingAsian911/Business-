\
#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/business-stack-install.log"
MARK="/var/lib/business-stack.installed"

mkdir -p /var/log /var/lib
exec > >(tee -a "$LOG") 2>&1

echo "==== BUSINESS STACK BOOTSTRAP START $(date) ===="

if [ -f "$MARK" ]; then
  echo "[SKIP] Already installed. Marker exists: $MARK"
  echo "Remove marker to re-run: sudo rm -f $MARK"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] Base packages"
apt-get update -y
apt-get install -y curl wget git unzip ca-certificates lsb-release gnupg \
  apache2 mariadb-server mariadb-client ufw \
  php php-cli php-common php-mysql php-curl php-mbstring php-xml php-zip php-gd \
  sox net-tools

echo "[2/6] Firewall (safe defaults)"
ufw allow OpenSSH || true
ufw allow 80 || true
ufw allow 443 || true
ufw allow 5060 || true
ufw allow 5061 || true
ufw allow 10000:20000/udp || true
ufw --force enable || true

echo "[3/6] Install/Repair PBX"
bash ./scripts/pbx_install.sh

echo "[4/6] Install/Repair Web Intake"
bash ./scripts/web_intake_install.sh

echo "[5/6] Verification"
bash ./scripts/verify.sh

touch "$MARK"
echo "[DONE] Marker created: $MARK"
echo "==== BUSINESS STACK BOOTSTRAP END $(date) ===="
