# Docker Media Server

Automated media management stack running on Docker. Handles requesting, downloading, organizing, and subtitling media — with Jellyfin running on a separate server for playback.

## Key Files

- `docker-compose.yml` — all service definitions
- `.env` / `.env.example` — Docker Compose environment variables (paths, PUID/PGID, timezone)

## Architecture

```mermaid
graph TD
    subgraph Media Server ["Media Server (Docker Compose)"]
        Seerr["Seerr<br>Media Requests"]
        Sonarr["Sonarr<br>TV Management"]
        Radarr["Radarr<br>Movie Management"]
        SABnzbd["SABnzbd<br>Usenet Downloader"]
        Bazarr["Bazarr<br>Subtitles"]
        Recyclarr["Recyclarr<br>Quality Profiles"]
        Tautulli["Tautulli<br>Monitoring"]
        Homepage["Homepage<br>Dashboard"]
        Maintainerr["Maintainerr<br>Library Maintenance"]
    end

    subgraph Playback ["Separate Server / VM"]
        Jellyfin["Jellyfin<br>Media Player"]
    end

    User -->|Request Media| Seerr
    Seerr -->|TV| Sonarr
    Seerr -->|Movies| Radarr
    Sonarr -->|Download| SABnzbd
    Radarr -->|Download| SABnzbd
    SABnzbd -->|Completed Files| Sonarr
    SABnzbd -->|Completed Files| Radarr
    Bazarr -->|Fetch Subtitles| Sonarr
    Bazarr -->|Fetch Subtitles| Radarr
    Recyclarr -->|Sync Profiles| Sonarr
    Recyclarr -->|Sync Profiles| Radarr
    Tautulli -->|Monitor| Jellyfin
    Homepage -->|Status Widgets| Sonarr
    Homepage -->|Status Widgets| Radarr
    Homepage -->|Status Widgets| SABnzbd
    Homepage -->|Status Widgets| Tautulli
    Maintainerr -->|Manage Library| Jellyfin
    Maintainerr -->|Manage Library| Sonarr
    Maintainerr -->|Manage Library| Radarr
    Jellyfin -->|Reads| MediaStorage[("Shared Media<br>Storage")]
    Sonarr -->|Writes| MediaStorage
    Radarr -->|Writes| MediaStorage
```

## Services

| Service                                                        | Port | Purpose                                                       |
| -------------------------------------------------------------- | ---- | ------------------------------------------------------------- |
| [Seerr](https://github.com/seerr-team/seerr)                   | 5055 | User-facing request portal for movies and TV                  |
| [Sonarr](https://docs.linuxserver.io/images/docker-sonarr)     | 8989 | TV show management and automation                             |
| [Radarr](https://docs.linuxserver.io/images/docker-radarr)     | 7878 | Movie management and automation                               |
| [SABnzbd](https://docs.linuxserver.io/images/docker-sabnzbd/)  | 8080 | Usenet download client                                        |
| [Bazarr](https://docs.linuxserver.io/images/docker-bazarr)     | 6767 | Automatic subtitle downloading                                |
| [Tautulli](https://docs.linuxserver.io/images/docker-tautulli) | 8181 | Playback monitoring and statistics                            |
| [Recyclarr](https://recyclarr.dev/guide/installation/docker/)  | —    | Syncs TRaSH quality profiles to Sonarr/Radarr on a daily cron |
| [Homepage](https://gethomepage.dev/)                            | 3000 | YAML-configured dashboard with service widgets                |
| [Maintainerr](https://docs.maintainerr.info/)                  | 6246 | Automated library maintenance based on rules                  |

## Why Run Jellyfin on a Separate Server?

Jellyfin handles real-time transcoding which is CPU/GPU intensive. Running it on a dedicated VM or machine means:

- **Transcoding doesn't starve downloads** — SABnzbd and the *arr apps keep running at full speed during heavy playback.
- **Independent scaling** — give the playback server a GPU or more RAM without over-provisioning the automation stack.
- **Isolation** — a Jellyfin crash or update doesn't take down your download pipeline (and vice versa).

Both servers just need access to the same shared media storage (NFS, SMB, etc.).

## Setup

1. Clone the repo and copy the example env file:

```bash
git clone https://github.com/bcanfield/docker-media-server.git
cd docker-media-server
cp .env.example .env
```

2. Edit `.env` with your values:

```env
TZ=America/New_York      # Your timezone
PUID=1000                 # id $USER
PGID=1000
MEDIA_ROOT=/media         # Where downloads and organized media live
CONFIG_ROOT=/mediaconfig  # Where app configs are stored
HOMEPAGE_ALLOWED_HOSTS=localhost:3000  # Hostname used to access the dashboard
```

3. Copy the Homepage starter config (edit API keys to match your services):

```bash
cp -r homepage/ ${CONFIG_ROOT}/config/homepage/
```

4. Start the stack:

```bash
docker compose up -d
```

5. Configure each service through its web UI, wiring them together:
   - Point Sonarr/Radarr to SABnzbd as the download client
   - Point Seerr to Sonarr/Radarr
   - Point Bazarr to Sonarr/Radarr for subtitle fetching
   - Point Tautulli to your Jellyfin instance
   - Point Maintainerr to Jellyfin, Sonarr, and Radarr
   - Configure Homepage by editing YAML files in `${CONFIG_ROOT}/config/homepage/` (services.yaml, widgets.yaml, etc.)

## Resources

- [LinuxServer.io](https://docs.linuxserver.io/) — maintains most of the Docker images used here
- [TRaSH Guides](https://trash-guides.info/) — quality profile recommendations (synced via Recyclarr)
- [Servarr Wiki](https://wiki.servarr.com/) — docs for Sonarr, Radarr, and related apps
