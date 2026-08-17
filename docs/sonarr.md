# Sonarr

TV management. Monitors for episodes, sends NZBs to SABnzbd, organizes the results.

**Web UI:** `http://<host>:8989`

## First-Time Setup

1. **Download Client** — Settings > Download Clients > Add SABnzbd. Host `sabnzbd`, port `8080`, plus its API key.
2. **Root Folder** — Settings > Media Management. `/data/complete/tv` if you use
   `docker-compose.override.yml`, otherwise `/tv`.
3. **Indexers** — sync automatically from Prowlarr; otherwise add them under Settings > Indexers.
4. **Quality Profiles** — let Recyclarr sync TRaSH profiles rather than hand-tuning.

## Things to Know

- **Hardlinks need one mount, not two.** The base compose maps `/tv` and `/downloads` separately,
  which Docker presents as two filesystems — `link()` fails and every import becomes a full copy.
  `docker-compose.override.yml.example` mounts `${MEDIA_ROOT}` once as `/data` to fix this. Copy it
  before importing anything, since switching later means re-pointing root folders and remote path
  mappings.
- **Root folder is not the downloads folder.** Root is where organized media lives.
- **`RenameSeries` renames files only, not the series folder.** To apply `seriesFolderFormat` to
  existing series: `PUT /series/editor {seriesIds, rootFolderPath, moveFiles:true}`.
- **Remote path mapping** is unnecessary here — Sonarr and SABnzbd see identical paths.

## Links

- [Servarr Wiki](https://wiki.servarr.com/sonarr) · [Quick Start](https://wiki.servarr.com/sonarr/quick-start-guide)
- [TRaSH Guides — Sonarr](https://trash-guides.info/Sonarr/)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-sonarr)
