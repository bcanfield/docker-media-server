# Radarr

Movie management and automation. Same idea as Sonarr but for movies — monitors wishlists, grabs downloads, and organizes your library.

**Web UI:** `http://<host>:7878`

## First-Time Setup

1. **Download Client** — Settings > Download Clients > Add SABnzbd. Enter the host (`sabnzbd`), port (`8080`), and API key.
2. **Root Folder** — Settings > Media Management > Add Root Folder. Point to `/movies`.
3. **Indexers** — Synced automatically if you're using Prowlarr. Otherwise add manually under Settings > Indexers.
4. **Quality Profiles** — Use defaults or let Recyclarr handle it. Customize under Settings > Profiles.
5. **Add Movies** — Search and add films. Radarr grabs them when available.

## Things to Know

- **Same hardlink rules as Sonarr.** Keep downloads and movies on the same filesystem to avoid slow copy+delete.
- **Don't use exFAT** for media storage — it doesn't support hardlinks.
- **Naming convention** — TRaSH recommends: `{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}`. Set this under Settings > Media Management.
- **API key** — Found at Settings > General > Security. You'll need this for Seerr, Bazarr, and Homepage integrations.

## Links

- [Servarr Wiki](https://wiki.servarr.com/radarr) — official docs
- [TRaSH Guides — Radarr](https://trash-guides.info/Radarr/) — quality profiles, naming, custom formats
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-radarr)
