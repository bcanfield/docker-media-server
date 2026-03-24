# Development Instructions

See [README](./README.md) for project overview, architecture diagram, and user-facing setup instructions.
See [docs/](./docs/) for per-service setup guides.

## Repository Structure

```
docker-compose.yml          # Core services: Sonarr, Radarr, Seerr, SABnzbd, Bazarr, Prowlarr, Recyclarr, Tailscale
extras/
  docker-compose.yml        # Optional services: Homepage, Maintainerr, LazyLibrarian, Audiobookshelf
  .env.example              # Extra env vars (HOMEPAGE_ALLOWED_HOSTS)
  backup/
    backup-config.sh        # Restic backup script (S3-compatible, snapshots SQLite DBs)
    .env.example            # Backup credentials template
  homepage/                 # Starter Homepage dashboard config (YAML files)
docs/                       # Per-service setup guides
.env.example                # Main env vars: TZ, PUID/PGID, MEDIA_ROOT, CONFIG_ROOT, SABNZBD_TEMP, TS_AUTHKEY
```

## Docker Networking

All services share the `sofa-squad` bridge network. Core stack creates it; extras join it as `external: true`. Use container names as hostnames between services (e.g., `http://sonarr:8989`).

## Environment Variables

| Variable                 | Purpose                                         |
| ------------------------ | ----------------------------------------------- |
| `TZ`                     | Timezone for all containers                     |
| `PUID` / `PGID`          | Unix user/group IDs for file permissions        |
| `MEDIA_ROOT`             | Root path for downloads and organized media     |
| `CONFIG_ROOT`            | Root path for all app config volumes            |
| `SABNZBD_TEMP`           | Root path for SABnzbd intermediate downloads    |
| `TS_AUTHKEY`             | Tailscale auth key for VPN container            |
| `TS_HOSTNAME`            | Hostname in tailnet (default: `media-server`)   |
| `HOMEPAGE_ALLOWED_HOSTS` | Required for Homepage dashboard access (extras) |

## Volume Layout

```
${CONFIG_ROOT}/config/<service>/    # Per-service config (sonarr, radarr, bazarr, etc.)
${MEDIA_ROOT}/downloads/            # SABnzbd download staging
${MEDIA_ROOT}/complete/tv/          # Organized TV library (Sonarr root folder)
${MEDIA_ROOT}/complete/movies/      # Organized movie library (Radarr root folder)
${MEDIA_ROOT}/complete/audiobooks/  # Audiobook library (LazyLibrarian + Audiobookshelf)
```

## Service Ports Quick Reference

| Service        | Port  | API Docs                                                               |
| -------------- | ----- | ---------------------------------------------------------------------- |
| Seerr          | 5055  | [docs.seerr.dev](https://docs.seerr.dev/)                              |
| Sonarr         | 8989  | [wiki.servarr.com/sonarr/api](https://wiki.servarr.com/sonarr/api)     |
| Radarr         | 7878  | [wiki.servarr.com/radarr/api](https://wiki.servarr.com/radarr/api)     |
| SABnzbd        | 8080  | [sabnzbd.org/wiki/advanced/api](https://sabnzbd.org/wiki/advanced/api) |
| Bazarr         | 6767  | [wiki.bazarr.media](https://wiki.bazarr.media/)                        |
| Prowlarr       | 9696  | [wiki.servarr.com/prowlarr/api](https://wiki.servarr.com/prowlarr/api) |
| Homepage       | 3000  | —                                                                      |
| Maintainerr    | 6246  | [docs.maintainerr.info](https://docs.maintainerr.info/)                |
| LazyLibrarian  | 5299  | [lazylibrarian.gitlab.io](https://lazylibrarian.gitlab.io/)            |
| Audiobookshelf | 13378 | [api.audiobookshelf.org](https://api.audiobookshelf.org/)              |

## Agent API Access

Service API keys are stored in `.claude/settings.json` (gitignored). Copy from `.claude/settings.example.json` and fill in your values.

```bash
cp .claude/settings.example.json .claude/settings.json
```

To query a service API (e.g. Radarr):
```
GET {url}/api/v3/{endpoint}?apikey={apiKey}
```

Sonarr and Radarr both use `/api/v3/`. SABnzbd uses `/sabnzbd/api?mode={mode}&apikey={apiKey}&output=json`.

## Image Pinning

Most images are pinned by tag + SHA256 digest in the compose files. When updating an image, update both the tag and the digest.
