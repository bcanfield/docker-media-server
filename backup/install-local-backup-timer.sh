#!/bin/bash
# Installs a weekly systemd timer that runs backup-config-local.sh.
#
# Run with sudo:
#     sudo ./backup/install-local-backup-timer.sh
#
# The units are generated rather than shipped as static files so the absolute
# path to the script is always correct for wherever this repo is checked out.
#
# Runs as root so root-owned state (Tailscale's tailscaled.state) is captured.
#
# Persistent=true matters if the host is a desktop rather than an always-on
# server. If the machine is powered off at the scheduled time, the backup runs
# shortly after the next boot instead of being skipped until the following week.

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run this with sudo." >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-config-local.sh"

[ -f "$BACKUP_SCRIPT" ] || { echo "Not found: $BACKUP_SCRIPT" >&2; exit 1; }
chmod +x "$BACKUP_SCRIPT"

UNIT=media-config-backup

cat > "/etc/systemd/system/$UNIT.service" <<EOF
[Unit]
Description=Backup media stack config to local disk
Documentation=file://$SCRIPT_DIR/backup-config-local.sh
# The stack does not need to be up for the backup to be valid -- sqlite3
# .backup works on files at rest too -- but ordering after docker keeps the
# log readable when both run near boot.
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
ExecStart=$BACKUP_SCRIPT
# The destination may be a slow spinning disk or a network mount; give it room.
TimeoutStartSec=2h
Nice=10
IOSchedulingClass=idle
EOF

cat > "/etc/systemd/system/$UNIT.timer" <<EOF
[Unit]
Description=Weekly backup of media stack config to local disk

[Timer]
OnCalendar=Sun 03:00
# Run after the next boot if the machine was off when this was due.
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now "$UNIT.timer"

echo
echo "Installed and enabled. Schedule:"
systemctl list-timers "$UNIT.timer" --no-pager
echo
echo "Run one now to verify:   sudo systemctl start $UNIT.service"
echo "Watch it:                journalctl -u $UNIT.service -f"
