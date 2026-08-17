#!/bin/bash
# Backs up the config directory to a local tarball on another physical disk.
#
# This is the no-credentials sibling of backup-config.sh (which pushes to
# S3-compatible storage via restic). Use this one when you want protection
# immediately without setting up a bucket. It is NOT off-site: it defends
# against the disk holding CONFIG_ROOT being corrupted or lost (including a WSL
# virtual disk), not against the whole machine being lost. Run both if you care
# about the latter.
#
# SQLite databases are snapshotted with `sqlite3 .backup` before archiving, so
# the containers can keep running -- a plain copy of a live SQLite file can be
# torn mid-write and restore as a corrupt database.
#
# Run as root so root-owned state (notably Tailscale's tailscaled.state, which
# is 0600 root) is captured. Running as an unprivileged user still produces a
# usable archive, but silently omits those files.
#
# Config via environment, or via the stack's .env, with defaults:
#   BACKUP_SRC   directory to back up       (default: CONFIG_ROOT from ../.env)
#   BACKUP_DEST  where tarballs are written (default: MEDIA_ROOT/backups from
#                ../.env, since MEDIA_ROOT is already on a different disk
#                from the container config in a typical setup)
#   BACKUP_KEEP  how many to retain         (default: 8)
#
# The script refuses to run if source and destination turn out to share a
# backing device, so a wrong default fails loudly rather than writing a useless
# backup onto the disk it is meant to protect against.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Pull paths from the stack's .env unless they are set explicitly.
if [ -f "$REPO_ROOT/.env" ]; then
    env_value() { grep -E "^$1=" "$REPO_ROOT/.env" | tail -1 | cut -d= -f2-; }
    CONFIG_ROOT="$(env_value CONFIG_ROOT)"
    MEDIA_ROOT="$(env_value MEDIA_ROOT)"
fi

BACKUP_SRC="${BACKUP_SRC:-${CONFIG_ROOT:-}}"
BACKUP_DEST="${BACKUP_DEST:-${MEDIA_ROOT:+$MEDIA_ROOT/backups}}"
BACKUP_KEEP="${BACKUP_KEEP:-8}"

: "${BACKUP_SRC:?Could not determine what to back up. Set BACKUP_SRC, or CONFIG_ROOT in .env}"
: "${BACKUP_DEST:?Could not determine where to write backups. Set BACKUP_DEST, or MEDIA_ROOT in .env}"
[ -d "$BACKUP_SRC" ] || { echo "Source does not exist: $BACKUP_SRC" >&2; exit 1; }

mkdir -p "$BACKUP_DEST"

# If the destination lives on a mount that is not currently mounted (a NAS
# share, or a Windows drive over drvfs under WSL), the path still resolves as an
# ordinary empty directory on the root filesystem -- which would silently write
# the backup onto the very disk we are protecting against. Comparing backing
# devices catches both that and a plain misconfig.
SRC_DEV="$(findmnt -no SOURCE -T "$BACKUP_SRC")"
DEST_DEV="$(findmnt -no SOURCE -T "$BACKUP_DEST")"
DEST_FSTYPE="$(findmnt -no FSTYPE -T "$BACKUP_DEST")"
if [ "$SRC_DEV" = "$DEST_DEV" ]; then
    echo "Refusing to back up onto the same filesystem as the source ($SRC_DEV)." >&2
    echo "The point is to survive that disk failing. Check that BACKUP_DEST is mounted." >&2
    exit 1
fi
# A different device is not sufficient: tmpfs and ramfs are RAM, so a backup
# written there is both gone on reboot and eating memory the stack needs.
case "$DEST_FSTYPE" in
    tmpfs|ramfs|devtmpfs)
        echo "Refusing to write a backup to $DEST_FSTYPE ($BACKUP_DEST) -- that is RAM." >&2
        echo "It would vanish on reboot and consume memory the containers need." >&2
        exit 1
        ;;
esac

STAMP="$(date +%Y%m%d-%H%M%S)"
PREFIX="$(basename "$BACKUP_SRC")"
ARCHIVE="$BACKUP_DEST/$PREFIX-$STAMP.tar.gz"

echo "=== Backup started: $(date) ==="
echo "Source:      $BACKUP_SRC  ($SRC_DEV)"
echo "Destination: $ARCHIVE  ($DEST_DEV)"
[ "$(id -u)" -eq 0 ] || echo "NOTE: not running as root; root-owned files (e.g. tailscaled.state) will be skipped."

# --- Snapshot SQLite databases -------------------------------------------
# A failure here is a warning, not fatal: a single locked logs.db should not
# cost you the whole backup. Failures are counted and reported at the end.
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
done < <(find "$BACKUP_SRC" -name '*.db' -not -name '*.db.bak' 2>/dev/null)

# --- Archive --------------------------------------------------------------
# Live .db files are excluded; the consistent .bak snapshots stand in for them.
#
# Also excluded: regenerable bulk, plus directories left behind by services
# people commonly retire from this kind of stack. MediaCover is artwork the arrs
# re-fetch on demand (often >1 GB) and recyclarr/resources is a git clone of the
# TRaSH guides (~80 MB); together with logs these dominate the archive size and
# none of it is unrecoverable. Prune the retired-service lines below to match
# what you actually run -- an exclude that matches nothing is harmless.
echo "Creating archive..."
tar_rc=0
tar czf "$ARCHIVE" \
    -C "$(dirname "$BACKUP_SRC")" \
    --exclude='*.db' \
    --exclude='*.db-journal' \
    --exclude='*.db-wal' \
    --exclude='*.db-shm' \
    --exclude='*/MediaCover' \
    --exclude='*/logs' \
    --exclude='*/log' \
    --exclude='*/recyclarr/resources' \
    --exclude='*/config/organizr' \
    --exclude='*/config/jellystat' \
    --exclude='*/config/overseerr' \
    --exclude='*/config/swag' \
    --exclude='*/config/authelia' \
    --exclude='*/config/duckdns' \
    --exclude='*/config/jellyseerr.bak' \
    "$PREFIX" || tar_rc=$?

find "$BACKUP_SRC" -name '*.db.bak' -delete 2>/dev/null || true

# tar's exit code alone is a poor gate. Exit 1 ("some files changed while being
# read") is routine with a live stack. Exit 2 is raised for a single unreadable
# file too, yet the rest of the archive is perfectly good -- deleting it there
# would throw away a usable backup. So the real gate is verification below;
# tar's code is reported, not obeyed.
case "$tar_rc" in
    0) ;;
    1) echo "Note: some files changed while being read (normal for a live stack)." ;;
    *) echo "WARNING: tar exited $tar_rc -- some files were not archived (see errors above)." >&2 ;;
esac

# --- Verify ---------------------------------------------------------------
echo "Verifying archive..."
if ! gzip -t "$ARCHIVE" 2>/dev/null; then
    echo "Archive failed integrity check. Removing it and keeping the previous backups." >&2
    rm -f "$ARCHIVE"
    exit 1
fi
entries="$(tar tzf "$ARCHIVE" | wc -l)"
if [ "$entries" -lt 100 ]; then
    echo "Archive has only $entries entries, which is implausibly small. Removing it." >&2
    rm -f "$ARCHIVE"
    exit 1
fi
echo "  integrity OK, $entries entries, $(du -h "$ARCHIVE" | cut -f1)"

# --- Retention ------------------------------------------------------------
# Pruned only after a verified-good new archive exists, so a failing backup can
# never delete the last good one.
echo "Pruning old backups (keeping $BACKUP_KEEP)..."
ls -1t "$BACKUP_DEST/$PREFIX"-*.tar.gz 2>/dev/null \
    | tail -n +$((BACKUP_KEEP + 1)) \
    | while IFS= read -r old; do
        echo "  removing $(basename "$old")"
        rm -f "$old"
    done

if [ "$db_failed" -gt 0 ]; then
    echo "WARNING: $db_failed database(s) could not be snapshotted." >&2
fi

echo "=== Backup finished: $(date) ==="
