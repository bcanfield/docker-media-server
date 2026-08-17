#!/bin/bash
# Installs a daily systemd timer that runs backup-config.sh (restic -> S3).
#
# Run with sudo, AFTER filling in backup/.env and running `restic init`:
#     sudo ./backup/install-restic-timer.sh
#
# Daily rather than weekly: restic backups are incremental and deduplicated, so
# after the first upload each run sends only what changed -- typically a few MB.
# Weekly would cost the same bandwidth but lose up to 7 days of history for no
# saving. Change OnCalendar below if you disagree.
#
# This runs as root so root-owned state (Tailscale's tailscaled.state, 0600
# root) is captured. As a normal user restic would log "permission denied" and
# exit 3, which under the script's `set -e` aborts before the prune step.

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run this with sudo." >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup-config.sh"
ENV_FILE="$SCRIPT_DIR/.env"

[ -f "$BACKUP_SCRIPT" ] || { echo "Not found: $BACKUP_SCRIPT" >&2; exit 1; }
[ -f "$ENV_FILE" ]      || { echo "Not found: $ENV_FILE -- create it first." >&2; exit 1; }

# Refuse to schedule a job that is guaranteed to fail every night.
if grep -q 'REPLACE_ME' "$ENV_FILE"; then
    echo "ERROR: $ENV_FILE still contains REPLACE_ME placeholders." >&2
    echo "Fill in your S3 credentials and repository URL first." >&2
    exit 1
fi

# Confirm the repository is reachable and initialised before scheduling.
echo "Checking the restic repository is reachable..."
if ! ( set -a; . "$ENV_FILE"; set +a; restic snapshots >/dev/null 2>&1 ); then
    echo "ERROR: cannot open the restic repository." >&2
    echo "Run 'restic init' first (see the setup steps), and check credentials." >&2
    exit 1
fi
echo "  repository OK"

chmod +x "$BACKUP_SCRIPT"
chmod 600 "$ENV_FILE"

UNIT=media-config-backup-offsite

cat > "/etc/systemd/system/$UNIT.service" <<EOF
[Unit]
Description=Off-site backup of media stack config (restic -> S3)
Documentation=file://$BACKUP_SCRIPT
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$BACKUP_SCRIPT
# systemd starts units with an almost-empty environment. Without HOME, restic
# cannot locate a cache directory, logs "unable to open cache", and re-downloads
# the repository index on every run -- which was most of the wall-clock time of
# a nightly job that only uploads a few MB.
Environment=HOME=/root
# Uploads over a home connection can be slow on the first (full) run.
TimeoutStartSec=6h
Nice=10
IOSchedulingClass=idle
EOF

cat > "/etc/systemd/system/$UNIT.timer" <<EOF
[Unit]
Description=Daily off-site backup of media stack config

[Timer]
OnCalendar=*-*-* 02:00:00
# Run after the next boot if the machine was off when this was due.
Persistent=true
RandomizedDelaySec=30m

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
