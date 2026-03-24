# Audiobookshelf

Self-hosted audiobook and podcast server with a slick web player and mobile apps for offline listening.

**Web UI:** `http://<host>:13378`

## First-Time Setup

1. **Create a Library** — Point it at your audiobook directory (`/audiobooks` in the container). Choose "Audiobooks" as the library type.
2. **Organize Files** — Use this folder structure for best metadata parsing:
   ```
   Author Name/
     Series Name/
       Book Title/
         chapter1.mp3
         chapter2.mp3
         cover.jpg
   ```
3. **Create Users** — Add accounts through the web interface. Each user gets individual progress tracking and bookmarks.
4. **Install Mobile App** — Available for iOS and Android. Supports offline downloads.

## Things to Know

- **`/config` must be local storage** — Don't use NFS/SMB for the config volume. The SQLite database will corrupt.
- **Separate `/config` and `/metadata`** — Don't nest these volumes. The compose file already handles this correctly.
- **ID3 tags matter** — Tag your audio files (artist, album, etc.) before adding them. Audiobookshelf reads these for metadata.
- **Optional metadata files** — Drop a `desc.txt` (description) or `reader.txt` (narrator name) in a book's folder for extra info.
- **Upgrades** — Just `docker compose pull` and restart.

## Links

- [Audiobookshelf Docs](https://www.audiobookshelf.org/docs) — official docs
- [GitHub](https://github.com/advplyr/audiobookshelf)
