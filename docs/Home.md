# Docker Media Server Wiki

Setup guides for each service in the stack. See the [README](https://github.com/bcanfield/docker-media-server) for architecture, installation, and configuration.

## Core Services

- [Seerr](Seerr) — media request portal
- [Sonarr](Sonarr) — TV show management
- [Radarr](Radarr) — movie management
- [SABnzbd](SABnzbd) — usenet downloader
- [Bazarr](Bazarr) — automatic subtitles
- [Prowlarr](Prowlarr) — indexer management
- [Recyclarr](Recyclarr) — quality profile sync

## Guides

- [Tailscale / Remote Access](Tailscale) — VPN setup for accessing services from anywhere
- [Cloudflare Tunnel](Cloudflared) — public access without port forwarding
- [Jellyfin Plugins](Jellyfin-Plugins) — what's worth installing, and what breaks the server
- [Backups](Backups) — local tarballs, plus off-site config backups with restic
- [Usenet Indexers](Usenet-Indexers) — recommended indexers for Prowlarr
