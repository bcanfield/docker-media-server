# Seerr

User-facing request portal. People browse and request movies/TV shows here, and Seerr routes requests to Radarr/Sonarr automatically.

**Web UI:** `http://<host>:5055`

## First-Time Setup

1. **Connect Jellyfin** — Enter your Jellyfin server URL and API key (found under Jellyfin > Dashboard > API Keys). This lets Seerr show what's already in your library.
2. **Connect Radarr** — Enter hostname (`radarr`), port (`7878`), and API key. Select default quality profile and root folder.
3. **Connect Sonarr** — Same as above with hostname (`sonarr`), port (`8989`), and API key.
4. **User Management** — Settings > Users. Set default permissions (auto-approve requests, quality limits, etc.).

## Things to Know

- **Container networking** — Use container names (`radarr`, `sonarr`) not `localhost` when connecting services.
- **Library sync** — Seerr syncs with Jellyfin to show available vs. missing content. This runs automatically.
- **Notifications** — Configure Discord, email, or webhook alerts under Settings > Notifications.
- **IPv6 issues** — If hostnames won't resolve, force IPv4 under Settings > Networking > Advanced.

## Links

- [Seerr Docs](https://docs.seerr.dev/)
- [GitHub](https://github.com/seerr-team/seerr)
- [Troubleshooting](https://docs.seerr.dev/troubleshooting)
