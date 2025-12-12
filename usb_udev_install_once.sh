\
#!/bin/bash
set -euo pipefail
apt-get update -y
apt-get install -y git curl python3

cat >/usr/local/sbin/usb-business-fix-runner <<'EOF'
#!/bin/bash
set -e
DEV="/dev/$1"
MNT="/mnt/business_fix_usb"
LABEL_EXPECT="BUSINESS_FIX"

mkdir -p "$MNT"
LABEL=$(blkid -o value -s LABEL "$DEV" 2>/dev/null || true)
[ "$LABEL" = "$LABEL_EXPECT" ] || exit 0

mount "$DEV" "$MNT"
if [ -f "$MNT/autorun.sh" ]; then
  chmod +x "$MNT/autorun.sh" || true
  /bin/bash "$MNT/autorun.sh"
fi
umount "$MNT"
EOF

chmod +x /usr/local/sbin/usb-business-fix-runner

cat >/etc/udev/rules.d/99-usb-business-fix.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd*[0-9]", RUN+="/usr/local/sbin/usb-business-fix-runner %k"
EOF

udevadm control --reload-rules
echo "Installed USB run-once trigger. Plug in USB labeled BUSINESS_FIX."
