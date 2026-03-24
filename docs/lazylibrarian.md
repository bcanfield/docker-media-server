# LazyLibrarian

Book and audiobook search and download manager. Follow authors, mark books as wanted, and LazyLibrarian automatically finds and downloads them.

**Web UI:** `http://<host>:5299`

## First-Time Setup

1. **Add Download Client** — Configure SABnzbd (or another client) under Settings with your host, port, and API key.
2. **Connect Data Sources** — LazyLibrarian pulls metadata from Goodreads and Google Books. Configure API keys if needed.
3. **Add Authors** — Search for authors to follow. Mark specific ebooks or audiobooks as "wanted".
4. **Import Existing Library** (optional) — Point it at your existing book collection to import metadata.

## Things to Know

- **Folder structure** — `/config` for app data, `/downloads` for incoming files, `/books` for your organized library.
- **Docker mods** — Two optional mods are available:
  - `linuxserver/mods:lazylibrarian-ffmpeg` — audiobook conversion (already enabled in this stack's compose file)
  - Calibredb mod — ebook format conversion
- **OPDS support** — Built-in OPDS server for ebook reader apps.
- **Magazine support** — Also handles magazine monitoring, not just books.
- **Metadata** — Saves cover art and `.opf` metadata files alongside book files (Calibre-compatible).

## Links

- [LazyLibrarian Docs](https://lazylibrarian.gitlab.io/) — official docs
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-lazylibrarian)
