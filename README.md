# Docker Media Server

Automated media management on Docker — requesting, downloading, organizing, and subtitling — with
Jellyfin running separately for playback.

## Architecture

```mermaid
graph LR
    Seerr -->|TV| Sonarr
    Seerr -->|Movies| Radarr
    Prowlarr -.->|Indexers| Sonarr & Radarr
    Sonarr & Radarr --> SABnzbd -->|Organize| Storage[("Storage")]
    Bazarr -.->|Subtitles| Storage
    Storage --> Jellyfin
```

## Services

| Service | Port | Purpose | Guide |
| --- | --- | --- | --- |
| [Seerr](https://github.com/seerr-team/seerr) | 5055 | Media request portal | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Seerr) |
| [Sonarr](https://wiki.servarr.com/sonarr) | 8989 | TV show management | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Sonarr) |
| [Radarr](https://wiki.servarr.com/radarr) | 7878 | Movie management | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Radarr) |
| [SABnzbd](https://sabnzbd.org/wiki/) | 8080 | Usenet downloader | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/SABnzbd) |
| [Bazarr](https://wiki.bazarr.media/) | 6767 | Automatic subtitles | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Bazarr) |
| [Prowlarr](https://wiki.servarr.com/prowlarr) | 9696 | Indexer management | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Prowlarr) |
| [Recyclarr](https://recyclarr.dev/) | — | TRaSH quality profile sync | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Recyclarr) |
| [Tailscale](https://tailscale.com/kb/1282/docker) | — | VPN for remote access | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Tailscale) |
| [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) | — | Public hostnames, opt-in | [Wiki](https://github.com/bcanfield/docker-media-server/wiki/Cloudflared) |

That's the whole stack, deliberately. Everything here is running in a real install, so the guides
describe what actually works rather than what should.

## Quick Start

```bash
git clone https://github.com/bcanfield/docker-media-server.git
cd docker-media-server
cp .env.example .env                                          # paths, timezone, Tailscale key
cp docker-compose.override.yml.example docker-compose.override.yml
docker compose up -d
```

The override file is not optional if you care about hardlinks: it mounts `${MEDIA_ROOT}` once as
`/data` instead of passing `/tv`, `/movies` and `/downloads` separately. Separate bind mounts look
like separate filesystems to the container, so `link()` fails and every import silently becomes a
full copy. Its header explains the layout.

Then configure each service through its web UI — see the
[wiki](https://github.com/bcanfield/docker-media-server/wiki).

## Back Up Your Config

The configs are the painful part to lose; the media is re-downloadable.

```bash
sudo ./backup/install-local-backup-timer.sh   # weekly tarball to another disk, no credentials
```

For off-site copies via restic, see the
[Backups guide](https://github.com/bcanfield/docker-media-server/wiki/Backups).

## More

- [Tailscale / Remote Access](https://github.com/bcanfield/docker-media-server/wiki/Tailscale) ·
  [Cloudflare Tunnel](https://github.com/bcanfield/docker-media-server/wiki/Cloudflared)
- [Backups](https://github.com/bcanfield/docker-media-server/wiki/Backups) ·
  [Usenet Indexers](https://github.com/bcanfield/docker-media-server/wiki/Usenet-Indexers)
- [TRaSH Guides](https://trash-guides.info/) · [Servarr Wiki](https://wiki.servarr.com/) ·
  [LinuxServer.io](https://docs.linuxserver.io/)
