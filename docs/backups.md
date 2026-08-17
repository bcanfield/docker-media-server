# Backups

The media library is re-downloadable. The service configs are not — API keys, quality profiles,
indexer setup, and the SQLite database behind every arr. `backup/` has two scripts for them; run at
least the first.

Both snapshot SQLite with `sqlite3 .backup` before archiving, so containers keep running — a plain
copy of a live SQLite file can be torn mid-write and restore corrupt. Both run as root so root-owned
state (notably Tailscale's `0600` `tailscaled.state`) is captured; as a normal user they still work
but silently omit those files.

## Local backup (start here)

Tarballs `CONFIG_ROOT` onto another physical disk. No credentials, no account.

```bash
sudo ./backup/install-local-backup-timer.sh   # weekly systemd timer
```

Paths come from `.env` unless overridden: `BACKUP_SRC` (default `CONFIG_ROOT`), `BACKUP_DEST`
(default `MEDIA_ROOT/backups`, already a different disk in a typical setup), `BACKUP_KEEP`
(default 8).

The script refuses to run if source and destination share a backing device, so a wrong default fails
loudly rather than writing a backup onto the disk it exists to protect against.

This is **not** off-site — it defends against losing the disk holding `CONFIG_ROOT`, including a WSL
virtual disk, not against losing the machine.

## Off-site backup (optional)

Encrypted, deduplicated [restic](https://restic.net/) to S3-compatible storage. After the first
upload each run sends only what changed, typically a few MB.

```bash
apt install -y restic sqlite3

cd backup
cp .env.example .env      # S3 credentials, restic password, BACKUP_PATH
set -a && source .env && set +a
restic init               # once
./backup-config.sh        # test run
```

```bash
sudo ./backup/install-restic-timer.sh   # daily systemd timer
```

Retention is 7 daily, 4 weekly, 3 monthly, pruned only after a snapshot is confirmed to have landed.

> **Store `RESTIC_PASSWORD` somewhere other than this machine.** There is no reset — without it the
> repository is unrecoverable, and a backup you can't decrypt isn't a backup. Keeping it only in
> `backup/.env` on the host you're protecting defeats the point.

## Restore

```bash
cd backup
set -a && source .env && set +a
restic snapshots
restic restore latest --target /tmp/restore
```

Local tarballs are plain `tar xzf`. Stop the stack before restoring over a live `CONFIG_ROOT`.

Live database files and journals are excluded from both — only the `.bak` snapshots are archived, and
those are deleted after each run.
