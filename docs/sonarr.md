# Sonarr

TV show management and automation. Monitors for new episodes, sends downloads to SABnzbd, and organizes files into your library.

**Web UI:** `http://<host>:8989`

## First-Time Setup

1. **Download Client** — Settings > Download Clients > Add SABnzbd. Enter the host (`sabnzbd`), port (`8080`), and API key.
2. **Root Folder** — Settings > Media Management > Add Root Folder. Point to `/tv` (your organized library, not the downloads folder).
3. **Indexers** — If using Prowlarr, indexers sync automatically. Otherwise add them manually under Settings > Indexers.
4. **Quality Profiles** — Use the defaults or let Recyclarr sync TRaSH Guide profiles. Customize under Settings > Profiles.
5. **Add Shows** — Search and add TV series. Sonarr monitors for new episodes and backfills missing ones.

## Things to Know

- **Root folder != downloads folder.** Root is where organized media lives. Downloads are temporary.
- **Naming matters.** Use Sonarr's recommended naming format (Settings > Media Management) so Jellyfin picks up files correctly.
- **Hardlinks save disk space.** If `/downloads` and `/tv` are on the same filesystem, Sonarr hardlinks instead of copying. This is already set up correctly in the compose file.
- **Remote path mapping** is only needed if Sonarr and your download client see files at different paths (not the case in this Docker stack).

## Links

- [Servarr Wiki](https://wiki.servarr.com/sonarr) — official docs
- [Quick Start Guide](https://wiki.servarr.com/sonarr/quick-start-guide)
- [TRaSH Guides — Sonarr](https://trash-guides.info/Sonarr/) — quality profiles, naming, custom formats
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-sonarr)
