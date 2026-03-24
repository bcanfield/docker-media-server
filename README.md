# Docker Media Server

Automated media management stack running on Docker. Handles requesting, downloading, organizing, and subtitling media — with Jellyfin running on a separate server for playback.

## Key Files

- `docker-compose.yml` — core service definitions
- `extras/docker-compose.yml` — optional services (dashboard, library maintenance, audiobooks)
- `.env` / `.env.example` — Docker Compose environment variables (paths, PUID/PGID, timezone)

## Architecture

```mermaid
graph LR
    Seerr -->|TV| Sonarr
    Seerr -->|Movies| Radarr
    Sonarr & Radarr --> SABnzbd -->|Organize| Storage[("Storage")]
    Bazarr -.->|Subtitles| Storage
    Storage --> Jellyfin
```

## Core Services

| Service                                           | Port | Purpose                                                       | Setup Guide                            |
| ------------------------------------------------- | ---- | ------------------------------------------------------------- | -------------------------------------- |
| [Seerr](https://github.com/seerr-team/seerr)      | 5055 | User-facing request portal for movies and TV                  | [docs/seerr.md](docs/seerr.md)         |
| [Sonarr](https://wiki.servarr.com/sonarr)         | 8989 | TV show management and automation                             | [docs/sonarr.md](docs/sonarr.md)       |
| [Radarr](https://wiki.servarr.com/radarr)         | 7878 | Movie management and automation                               | [docs/radarr.md](docs/radarr.md)       |
| [SABnzbd](https://sabnzbd.org/wiki/)              | 8080 | Usenet download client                                        | [docs/sabnzbd.md](docs/sabnzbd.md)     |
| [Bazarr](https://wiki.bazarr.media/)              | 6767 | Automatic subtitle downloading                                | [docs/bazarr.md](docs/bazarr.md)       |
| [Prowlarr](https://wiki.servarr.com/prowlarr)     | 9696 | Centralized indexer management, syncs to Sonarr/Radarr        | [docs/prowlarr.md](docs/prowlarr.md)   |
| [Recyclarr](https://recyclarr.dev/)               | —    | Syncs TRaSH quality profiles to Sonarr/Radarr on a daily cron | [docs/recyclarr.md](docs/recyclarr.md) |
| [Tailscale](https://tailscale.com/kb/1282/docker) | —    | Private VPN for secure remote access without port forwarding  | —                                      |

## Extras (Optional)

| Service                                               | Port  | Purpose                                        | Setup Guide                                      |
| ----------------------------------------------------- | ----- | ---------------------------------------------- | ------------------------------------------------ |
| [Homepage](https://gethomepage.dev/)                  | 3000  | YAML-configured dashboard with service widgets | [docs/homepage.md](docs/homepage.md)             |
| [Maintainerr](https://docs.maintainerr.info/)         | 6246  | Automated library maintenance based on rules   | [docs/maintainerr.md](docs/maintainerr.md)       |
| [LazyLibrarian](https://lazylibrarian.gitlab.io/)     | 5299  | Book/audiobook search and download management  | [docs/lazylibrarian.md](docs/lazylibrarian.md)   |
| [Audiobookshelf](https://www.audiobookshelf.org/docs) | 13378 | Self-hosted audiobook server with mobile apps  | [docs/audiobookshelf.md](docs/audiobookshelf.md) |

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
MEDIA_ROOT=/mnt/media         # Where downloads and organized media live
CONFIG_ROOT=/opt/config-root  # Where app configs are stored
SABNZBD_TEMP=/opt/sabnzbd-temp  # SSD-backed path for SABnzbd temp downloads
```

3. Start the core stack:

```bash
docker compose up -d
```

4. Configure each service through its web UI (see the [setup guides](docs/) for each service):
   - Point Sonarr/Radarr to SABnzbd as the download client
   - Point Seerr to Sonarr/Radarr
   - Point Bazarr to Sonarr/Radarr for subtitle fetching
   - Add indexers in Prowlarr and sync to Sonarr/Radarr

### Extras (Optional)

To run the optional services alongside the core stack:

```bash
cd extras
cp .env.example .env  # edit with your values
cp -r homepage/ ${CONFIG_ROOT}/config/homepage/  # starter dashboard config
docker compose --env-file ../.env --env-file .env up -d
```

The extras compose uses the same `sofa-squad` network as the core stack, so all services can communicate.

## Remote Access with Tailscale

[Tailscale](https://tailscale.com/) creates a private VPN (tailnet) between your devices, letting you securely access all your services from anywhere — no port forwarding or exposing anything to the public internet.

### Setup

1. **Create a Tailscale account** at [tailscale.com](https://tailscale.com/) (free for personal use, up to 100 devices).

2. **Install Tailscale on your client devices** (phone, laptop, etc.) from [tailscale.com/download](https://tailscale.com/download).

3. **Generate an auth key** at [Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys). Use a **reusable** key so the container can re-authenticate after restarts.

4. **Add the key to your `.env`:**

```env
TS_AUTHKEY=tskey-auth-your-key-here
TS_HOSTNAME=media-server
```

5. **Start (or restart) the stack:**

```bash
docker compose up -d
```

6. **Approve the node** in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines) if prompted.

### Accessing Services Remotely

Once Tailscale is running on both your server and your client device, access services using your Tailscale hostname:

| Service        | Remote URL                  |
| -------------- | --------------------------- |
| Seerr          | `http://media-server:5055`  |
| Sonarr         | `http://media-server:8989`  |
| Radarr         | `http://media-server:7878`  |
| SABnzbd        | `http://media-server:8080`  |
| Bazarr         | `http://media-server:6767`  |
| Prowlarr       | `http://media-server:9696`  |
| Homepage       | `http://media-server:3000`  |
| LazyLibrarian  | `http://media-server:5299`  |
| Audiobookshelf | `http://media-server:13378` |

Replace `media-server` with whatever you set `TS_HOSTNAME` to. You can also use the Tailscale IP shown in the admin console.

### Enabling HTTPS (Optional)

Tailscale can provision [automatic HTTPS certificates](https://tailscale.com/kb/1153/enabling-https) for your tailnet:

1. Enable HTTPS in [Admin Console > DNS](https://login.tailscale.com/admin/dns).
2. Access services at `https://media-server.your-tailnet.ts.net:<port>`.

### Enabling MagicDNS

With [MagicDNS](https://tailscale.com/kb/1081/magicdns) enabled (on by default), you can use short hostnames like `media-server` instead of full IPs across your tailnet.

## Backups

`extras/backup/` backs up service configs to S3-compatible storage (e.g., DigitalOcean Spaces) using [restic](https://restic.net/). Safely snapshots SQLite databases before backup.

```bash
# Install dependencies
apt install -y restic sqlite3

# Configure
cd extras/backup
cp .env.example .env   # fill in your S3 credentials, restic password, and backup path

# Initialize restic repo (once)
set -a && source .env && set +a
restic init

# Test a backup
./backup-config.sh

# Schedule daily at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * $(pwd)/backup-config.sh >> /var/log/restic-backup.log 2>&1") | crontab -
```

Restore:
```bash
cd extras/backup
set -a && source .env && set +a
restic snapshots                             # list snapshots
restic restore latest --target /tmp/restore  # restore latest
```

## Recommended Usenet Indexers

Managed via Prowlarr. Running multiple indexers improves coverage — each has different sources and retention depths. 2-3 indexers is the sweet spot.

| Indexer                                 | Registration | Cost                        | Strength                                                       |
| --------------------------------------- | ------------ | --------------------------- | -------------------------------------------------------------- |
| [NZBgeek](https://nzbgeek.info/)        | Open         | ~$12/year                   | Reliable all-rounder, great for current content                |
| [NZBPlanet](https://nzbplanet.net/)     | Open (paid)  | 8 EUR/year                  | Largest index (~3M NZBs), strong for older/obscure content     |
| [NZBFinder](https://nzbfinder.ws/)      | Open         | Free tier / ~15-35 EUR/year | Always-open registration, fast indexing, good free tier        |
| [DrunkenSlug](https://drunkenslug.com/) | Invite-only  | ~10-20 EUR/year             | Top-tier quality, watch r/usenet for open registration windows |
| [DOGnzb](https://dognzb.cr/)            | Invite-only  | $37/year                    | 4,800+ days retention, IMDb/Trakt watchlist sync               |

**Currently using:** NZBgeek, NZBPlanet, NZBFinder

## Resources

- [LinuxServer.io](https://docs.linuxserver.io/) — maintains most of the Docker images used here
- [TRaSH Guides](https://trash-guides.info/) — quality profile recommendations (synced via Recyclarr)
- [Servarr Wiki](https://wiki.servarr.com/) — docs for Sonarr, Radarr, and related apps
