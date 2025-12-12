# Business Stack (PBX + Web Intake) — One-Run Bootstrap

This repo is designed to be executed **once** (from USB autorun or manually) on an **already running Ubuntu Server 22.04**.

What it does:
- Installs/repairs **Asterisk 20** + **FreePBX 16**
- Installs/repairs **Apache + PHP** web intake site
- Enables and starts services
- Writes a full log to `/var/log/business-stack-install.log`
- Runs verification checks and prints PASS/FAIL

Entry point:
- `bootstrap.sh`

Safety:
- Idempotent: it uses `/var/lib/business-stack.installed` marker to avoid reruns unless you remove the marker.
USB RUN-ONCE PACKAGE

1) Label your USB drive: BUSINESS_FIX
2) Copy the contents of this folder to the USB root.
3) Plug into the running server (after the one-time udev trigger is installed).

Log on server: /var/log/usb-business-fix.log
Run-once marker: /var/lib/usb-business-fix.done
-
