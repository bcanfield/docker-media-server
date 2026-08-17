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

# restic keeps a cache of repository index metadata. Without HOME set it cannot
# locate a cache directory, logs "unable to open cache", and re-downloads the
# index on every run -- which is most of the wall-clock time of a nightly job
# that only uploads a few MB. systemd units start with an almost-empty
# environment, so this cannot be assumed.
export HOME="${HOME:-/root}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

echo "=== Backup started: $(date) ==="

# --- Snapshot SQLite databases -------------------------------------------
# A failure here is a warning, not fatal. Previously `set -e` meant one locked
# logs.db aborted the entire run before restic was ever reached, losing that
# night's off-site copy to a transient lock. Failures are counted and reported
# at the end instead. (Ported from backup-config-local.sh.)
echo "Snapshotting SQLite databases..."
db_failed=0
while IFS= read -r db; do
    if sqlite3 "$db" ".backup ${db}.bak" 2>/dev/null; then
        echo "  ok    $db"
    else
        echo "  FAIL  $db (excluded from this backup)" >&2
        db_failed=$((db_failed + 1))
        rm -f "${db}.bak"
    fi
done < <(find "$BACKUP_PATH" -name '*.db' -not -name '*.db.bak' 2>/dev/null)

# --- Backup ---------------------------------------------------------------
# Excludes, in two groups:
#
#   1. Live DB files and journals. The consistent .bak snapshots taken above
#      stand in for them; a raw copy of a live SQLite file can be torn
#      mid-write and restores as a corrupt database.
#
#   2. Regenerable bulk, plus directories left behind by services people
#      commonly retire from this kind of stack. MediaCover is artwork
#      Radarr/Sonarr re-fetch on demand (often >1 GB) and recyclarr/resources
#      is a git clone of the TRaSH guides (~80 MB); together with logs these
#      dominate the size of every run. Nothing here is unrecoverable: the arrs
#      rebuild artwork and recyclarr re-clones on the next sync. Prune the
#      retired-service lines to match what you run -- an exclude that matches
#      nothing is harmless.
echo "Running restic backup..."
restic_rc=0
restic backup "$BACKUP_PATH" \
    --exclude="*.db" \
    --exclude="*.db-journal" \
    --exclude="*.db-wal" \
    --exclude="*.db-shm" \
    --exclude="**/MediaCover" \
    --exclude="**/logs" \
    --exclude="**/log" \
    --exclude="**/recyclarr/resources" \
    --exclude="**/config/organizr" \
    --exclude="**/config/jellystat" \
    --exclude="**/config/overseerr" \
    --exclude="**/config/swag" \
    --exclude="**/config/authelia" \
    --exclude="**/config/duckdns" \
    --exclude="**/config/jellyseerr.bak" \
    || restic_rc=$?

# Cleanup .bak files regardless of outcome, so a failed run does not leave
# stale snapshots lying around to be picked up by the next one.
find "$BACKUP_PATH" -name "*.db.bak" -delete 2>/dev/null || true

# restic exits 3 when some files could not be read but the snapshot was still
# created -- routine against a live stack, and the snapshot is usable. Anything
# else non-zero means no usable snapshot, so stop before pruning.
case "$restic_rc" in
    0) ;;
    3) echo "Note: some files were unreadable during backup (normal for a live stack)." ;;
    *) echo "restic backup failed (exit $restic_rc). Keeping existing snapshots; not pruning." >&2
       exit "$restic_rc" ;;
esac

# --- Verify ---------------------------------------------------------------
# Confirm a snapshot actually landed before letting `forget --prune` run.
# Pruning on the strength of a command that "did not fail" is how a broken
# backup quietly deletes the last good one.
echo "Verifying snapshot..."
if ! restic snapshots --latest 1 --json | grep -q '"short_id"'; then
    echo "No snapshot found after backup. Refusing to prune." >&2
    exit 1
fi
restic snapshots --latest 1

# --- Retention ------------------------------------------------------------
# Only reached after a verified-good snapshot exists.
echo "Pruning old snapshots..."
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 3 \
    --prune

if [ "$db_failed" -gt 0 ]; then
    echo "WARNING: $db_failed database(s) could not be snapshotted." >&2
fi

echo "=== Backup finished: $(date) ==="
