# Prowlarr

Indexer manager. Add usenet indexers once here and they sync to Sonarr/Radarr automatically.

**Web UI:** `http://<host>:9696`

## First-Time Setup

1. **Configure Sonarr/Radarr first** — they need root folders and download clients before Prowlarr
   can sync to them.
2. **Add Indexers** — Indexers > Add (+). Enter credentials and test each. See
   [Usenet Indexers](Usenet-Indexers).
3. **Connect Apps** — Settings > Apps > Add Application. Add Sonarr and Radarr with their URLs and
   API keys, sync level **Full Sync**.
4. **Verify** — the indexers should appear in Sonarr/Radarr under Settings > Indexers.

## Things to Know

- **Prowlarr is not an indexer.** It pushes indexers to the *arrs; don't add it as one.
- **Its API is `/api/v1/`,** not the `/api/v3/` that Sonarr and Radarr use, and it sets no `UrlBase`
  by default. Both mistakes return a 200 with the SPA's HTML, which reads like a bad API key.
- **Keep the database on local storage.** SQLite corrupts on NFS/SMB.
- **Indexers go down.** Check the Indexers page when grabs dry up.

This stack is pinned to a `-nightly` tag. Moving to stable is a **downgrade across a database
migration**, which Prowlarr does not support — it needs a restore from
`${CONFIG_ROOT}/config/prowlarr/Backups/`, not just an image swap.

## Links

- [Servarr Wiki](https://wiki.servarr.com/prowlarr)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-prowlarr)
