# Maintainerr

Automated library maintenance. Creates rules to identify and remove old, unwatched, or low-quality content from your library to free up storage.

**Web UI:** `http://<host>:6246`

## First-Time Setup

1. **Connect Media Server** — Settings > choose Jellyfin or Plex (not both). Enter URL and API key. For Jellyfin, select an admin user for full library access.
2. **Connect Sonarr/Radarr** — Enter hostnames, ports, and API keys so Maintainerr can manage your library through them.
3. **Connect Seerr** (optional) — Allows Maintainerr to auto-clear requests when removing content.
4. **Create Rules** — Build collections using criteria like "unwatched for 90 days" or "rating below 5.0". Set a countdown (minimum 1 day) before action is taken.

## Things to Know

- **"Take action after X days" minimum is 1** — Mimics a "going away soon" warning period. Can't be zero.
- **Community rules** — Click the "Community" button when creating rules to browse pre-built rule templates.
- **Base URLs** — Enter without leading slashes (`tautulli` not `/tautulli`).
- **Permissions** — Container runs as UID 1000. Make sure the data directory is owned by that user.
- **First load** — May need a page refresh if you see a spinner.

## Links

- [Maintainerr Docs](https://docs.maintainerr.info/) — official docs
- [GitHub](https://github.com/Maintainerr/Maintainerr)
