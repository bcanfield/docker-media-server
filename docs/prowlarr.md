# Prowlarr

Centralized indexer manager. Add your usenet indexers once in Prowlarr and they sync automatically to Sonarr/Radarr — no need to configure indexers in each app separately.

**Web UI:** `http://<host>:9696`

## First-Time Setup

1. **Add Indexers** — Indexers > Add (+). Choose your usenet indexers (NZBgeek, NZBPlanet, etc.) and enter credentials/API keys. Test each one.
2. **Connect Apps** — Settings > Apps > Add Application. Add Sonarr and Radarr with their URLs and API keys. Use "Full Sync" so indexers stay in sync automatically.
3. **Verify** — Check Sonarr/Radarr under Settings > Indexers. Your Prowlarr indexers should appear there.

## Things to Know

- **Don't add Prowlarr as an indexer in Sonarr/Radarr.** Prowlarr pushes indexers to them — it's not an indexer itself.
- **Configure Sonarr/Radarr first.** They need root folders and download clients set up before Prowlarr can sync to them.
- **Database on local storage only.** SQLite databases corrupt on network drives (NFS/SMB).
- **FlareSolverr** — If an indexer is behind Cloudflare protection, deploy FlareSolverr alongside Prowlarr to bypass it.
- **Test periodically.** Indexers go down. Check the Indexers page for failures.

## Links

- [Servarr Wiki](https://wiki.servarr.com/prowlarr) — official docs
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-prowlarr)
