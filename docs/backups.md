# Backups

`extras/backup/` backs up service configs to S3-compatible storage (e.g., DigitalOcean Spaces) using [restic](https://restic.net/). Safely snapshots SQLite databases before backup.

## Setup

```bash
# Install dependencies
apt install -y restic sqlite3

# Configure
cd extras/backup
cp .env.example .env   # fill in your S3 credentials, restic password, and backup path

# Initialize restic repo (once)
set -a && source .env && set +a
restic init

# Test a backup
./backup-config.sh

# Schedule daily at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * $(pwd)/backup-config.sh >> /var/log/restic-backup.log 2>&1") | crontab -
```

## Restore

```bash
cd extras/backup
set -a && source .env && set +a
restic snapshots                             # list snapshots
restic restore latest --target /tmp/restore  # restore latest
```

## What It Does

- Snapshots all SQLite `.db` files to `.db.bak` before backing up (prevents corruption)
- Excludes live database files and journals (only the safe `.bak` copies are backed up)
- Prunes old snapshots: keeps 7 daily, 4 weekly, 3 monthly
- Cleans up `.bak` files after backup completes
