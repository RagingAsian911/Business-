\
#!/usr/bin/env bash
set -euo pipefail

echo "---- PBX INSTALL START ----"

# If asterisk is already installed and running, keep it; otherwise install.
if systemctl is-active --quiet asterisk; then
  echo "[OK] Asterisk service already active."
else
  echo "[INFO] Installing Asterisk 20 from source (this can take a while)."
  apt-get install -y build-essential libncurses5-dev libssl-dev libxml2-dev \
    libsqlite3-dev uuid-dev libjansson-dev libedit-dev libcurl4-openssl-dev \
    libnewt-dev libspeexdsp-dev libopus-dev libsrtp2-dev

  mkdir -p /usr/src/asterisk-src
  cd /usr/src/asterisk-src
  if [ ! -f asterisk-20-current.tar.gz ]; then
    wget -q http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
  fi
  tar xf asterisk-20-current.tar.gz
  cd asterisk-20.*

  contrib/scripts/install_prereq install || true
  ./configure
  make -j"$(nproc)"
  make install
  make samples
  make config
  ldconfig

  systemctl enable asterisk
  systemctl restart asterisk
fi

# FreePBX install (checks for /var/www/html/admin)
if [ -d /var/www/html/admin ]; then
  echo "[OK] FreePBX appears installed (/var/www/html/admin exists)."
else
  echo "[INFO] Installing FreePBX 16."
  cd /usr/src
  if [ ! -f freepbx-16.0-latest.tgz ]; then
    wget -q http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
  fi
  tar xf freepbx-16.0-latest.tgz
  cd freepbx

  # ensure mariadb running
  systemctl enable mariadb
  systemctl restart mariadb

  ./start_asterisk start || true
  ./install -n
fi

echo "---- PBX INSTALL END ----"
