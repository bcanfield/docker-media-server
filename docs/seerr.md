# Seerr

Request portal. People browse and request here; Seerr routes to Radarr/Sonarr.

**Web UI:** `http://<host>:5055`

## First-Time Setup

1. **Connect Jellyfin** — server URL and an API key from Jellyfin > Dashboard > API Keys. This is how
   Seerr knows what you already have.
2. **Connect Radarr** — host `radarr`, port `7878`, API key. Pick a default quality profile and root
   folder.
3. **Connect Sonarr** — host `sonarr`, port `8989`, same idea.
4. **User Management** — Settings > Users, for auto-approval and per-user limits.

Use container names, never `localhost`.

## Things to Know

- **Behind a reverse proxy or tunnel, set two things** — Settings > General > *Enable Proxy Support*
  (otherwise every request appears to come from the Docker bridge, making rate limiting and login
  logs useless), and *Application URL*, so notification links aren't LAN addresses. Restart after.
- **The config directory is `config/jellyseerr`**, a leftover of the rename. Any `overseerr/` or
  `jellyseerr.bak/` siblings are stale.
- **IPv6** — if hostnames won't resolve, force IPv4 under Settings > Networking > Advanced.

## Links

- [Seerr Docs](https://docs.seerr.dev/) · [Troubleshooting](https://docs.seerr.dev/troubleshooting)
- [GitHub](https://github.com/seerr-team/seerr)
