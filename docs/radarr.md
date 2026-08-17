# Radarr

Sonarr for movies — monitors wanted films, grabs them, organizes the library.

**Web UI:** `http://<host>:7878`

## First-Time Setup

1. **Download Client** — Settings > Download Clients > Add SABnzbd. Host `sabnzbd`, port `8080`, plus its API key.
2. **Root Folder** — Settings > Media Management. `/data/complete/movies` if you use
   `docker-compose.override.yml`, otherwise `/movies`.
3. **Indexers** — sync automatically from Prowlarr.
4. **Quality Profiles** — let Recyclarr sync TRaSH profiles.

## Things to Know

- **Same hardlink rules as Sonarr** — see [Sonarr](Sonarr). Don't use exFAT; it has no hardlinks.
- **Naming** — TRaSH recommends `{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}`.
- **API key** — Settings > General > Security. Needed by Seerr and Bazarr.
- **Collections hold profile references too.** Radarr refuses to delete a quality profile that no
  movie uses if a *collection* still points at it. Check `/api/v3/collection` as well as
  `/api/v3/movie`.
- **`_UNPACK_` / `_FAILED_` folders never import** — those prefixes match
  `downloadClientWorkingFolders`, so Radarr reports "File is still being unpacked" indefinitely.
  Rename the folder, then `GET /manualimport?folder=…` and `POST /command {name:ManualImport}`.

## Links

- [Servarr Wiki](https://wiki.servarr.com/radarr)
- [TRaSH Guides — Radarr](https://trash-guides.info/Radarr/)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-radarr)
