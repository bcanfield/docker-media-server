#!/bin/bash
# Backs up config directory to S3-compatible storage (e.g., DigitalOcean Spaces) via restic.
# SQLite databases are safely snapshotted before backup to avoid corruption.
#
# See .env.example for required configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load env
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Required vars
: "${AWS_ACCESS_KEY_ID:?Set AWS_ACCESS_KEY_ID in .env}"
: "${AWS_SECRET_ACCESS_KEY:?Set AWS_SECRET_ACCESS_KEY in .env}"
: "${RESTIC_REPOSITORY:?Set RESTIC_REPOSITORY in .env}"
: "${RESTIC_PASSWORD:?Set RESTIC_PASSWORD in .env}"
: "${BACKUP_PATH:?Set BACKUP_PATH in .env}"

export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

echo "=== Backup started: $(date) ==="

# Safely dump SQLite DBs before backup
echo "Snapshotting SQLite databases..."
for db in $(find "$BACKUP_PATH" -name "*.db" -not -name "*.db.bak"); do
    echo "  $db"
    sqlite3 "$db" ".backup ${db}.bak"
done

# Backup everything, excluding live DB files and journals (the .bak copies are included)
echo "Running restic backup..."
restic backup "$BACKUP_PATH" \
    --exclude="*.db" \
    --exclude="*.db-journal" \
    --exclude="*.db-wal" \
    --exclude="*.db-shm"

# Prune old snapshots: keep 7 daily, 4 weekly, 3 monthly
echo "Pruning old snapshots..."
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 3 \
    --prune

# Cleanup .bak files
find "$BACKUP_PATH" -name "*.db.bak" -delete

echo "=== Backup finished: $(date) ==="
