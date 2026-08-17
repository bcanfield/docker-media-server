# Development Instructions

See [README](./README.md) for the project overview and setup, and [docs/](./docs/) for per-service
guides.

This repo is **public**. Anything describing one particular host — LAN IPs, drive letters, hardware,
library contents, provider accounts — goes in the gitignored files under
[Local, untracked files](#local-untracked-files), never in a tracked one.

## The one design goal

**Everything in this stack exists so a low-powered TV client direct-plays via Jellyfin**, and the
Jellyfin host never transcodes. Target library shape: 100% h264/MKV/SDR/1080p, EAC3/AC3/AAC audio,
text subtitles.

The reference client is a Fire TV Stick, standing in for cheap streaming hardware generally —
Chromecast/Google TV, Roku, budget Android TV boxes, built-in Samsung (no DTS since 2018) and LG (no
DTS 2020-2022) apps. An Nvidia Shield bitstreams DTS-HD/TrueHD and is the exception, but a shared
library must satisfy the *weakest* client on the account, so it loosens nothing.

Four things force a transcode, most expensive first. Judge every change against them:

1. **Image subtitles (PGS/VOBSUB)** → Jellyfin burns them in → *full video re-encode*. Decided
   **server-side, so it hits nearly every client** — not a Fire Stick limitation. Avoided
   structurally: the quality profiles allow WEB-DL/WEBRip only, and disc sources are where PGS lives.
2. **AV1** → the only genuinely per-device trigger, and it bites twice: the client has no AV1 decoder
   so the server must transcode, and if the server GPU also lacks one (e.g. VCN 2.0) that falls back
   to CPU. The Fire TV Stick **4K Max** decodes AV1; the plain 4K, 3rd-gen, Lite and 2nd-gen Cube do
   not, and it cannot be added in software. Record which stick is in use in `CLAUDE.local.md`.
3. **DTS / DTS-HD MA / DTS-X / DTS-ES / DTS-HD HRA** → audio transcode. On current Fire TV hardware
   only Kodi passes DTS-HD through; Jellyfin gets DTS core at best.
4. **TrueHD / TrueHD Atmos / FLAC / PCM** → audio transcode. Narrower support still than DTS.

`recyclarr.yml` scores all of these `-10000`, **deliberately overriding TRaSH's own rewards**
(DTS-HD MA +2500, TrueHD ATMOS +5000, FLAC/PCM +2250). Do not "restore guide defaults" on the audio
custom formats — that is the whole direct-play guarantee.

## Repository Structure

```
docker-compose.yml                  # Core: Sonarr, Radarr, Seerr, SABnzbd, Bazarr, Prowlarr, Recyclarr, Uptime Kuma, Tailscale, cloudflared
docker-compose.override.yml.example # Copy to docker-compose.override.yml — the /data mount, see below
backup/
  backup-config-local.sh            # Default: tarball to another local disk, no credentials
  install-local-backup-timer.sh     # Weekly systemd timer for the above
  backup-config.sh                  # Opt-in off-site: restic → S3-compatible, snapshots SQLite DBs
  install-restic-timer.sh           # Daily systemd timer for the above
  .env.example                      # Restic credentials (off-site only)
docs/                               # Per-service setup guides
.env.example                        # TZ, PUID/PGID, MEDIA_ROOT, CONFIG_ROOT, SABNZBD_TEMP, TS_AUTHKEY
```

There is no `extras/`. Every service in the repo is one this stack actually runs, so anything
documented here is verified against a live install rather than shipped on spec. Optional containers
hang off Compose profiles in the core file (`cloudflared` is the pattern), not a second stack.

### Local, untracked files

| Path                          | What it holds                                            |
| ----------------------------- | -------------------------------------------------------- |
| `local/`                      | Scratch space: audits, API dumps, host-specific notes    |
| `CLAUDE.local.md`             | Agent instructions for one host; loaded with `CLAUDE.md` |
| `docker-compose.override.yml` | Host-specific Compose tweaks                             |
| `.env`, `backup/.env`         | Secrets and paths                                        |
| `.claude/settings.json`       | Service API keys                                         |

## Networking, Volumes, Ports

All services share the `sofa-squad` bridge network (`172.18.0.0/16` by default), created by the core
stack. Address services by container name: `http://sonarr:8989`.

```
${CONFIG_ROOT}/config/<service>/    # Per-service config
${MEDIA_ROOT}/downloads/            # SABnzbd staging
${MEDIA_ROOT}/complete/tv/          # Sonarr root folder
${MEDIA_ROOT}/complete/movies/      # Radarr root folder
```

Those are host paths. `docker-compose.override.yml.example` mounts `${MEDIA_ROOT}` **once** as
`/data` inside sonarr/radarr/bazarr/sabnzbd (`/data/complete/tv`, `/data/downloads/completed`) rather
than separate `/tv`, `/movies` and `/downloads` mounts — separate mounts look like separate
filesystems to the container and break hardlinks. Rationale is in its header.

| Service  | Port | API Docs                                                               |
| -------- | ---- | ---------------------------------------------------------------------- |
| Seerr    | 5055 | [docs.seerr.dev](https://docs.seerr.dev/)                              |
| Sonarr   | 8989 | [wiki.servarr.com/sonarr/api](https://wiki.servarr.com/sonarr/api)     |
| Radarr   | 7878 | [wiki.servarr.com/radarr/api](https://wiki.servarr.com/radarr/api)     |
| SABnzbd  | 8080 | [sabnzbd.org/wiki/advanced/api](https://sabnzbd.org/wiki/advanced/api) |
| Bazarr   | 6767 | [wiki.bazarr.media](https://wiki.bazarr.media/)                        |
| Prowlarr | 9696 | [wiki.servarr.com/prowlarr/api](https://wiki.servarr.com/prowlarr/api) |
| Uptime Kuma | 3001 | [github.com/louislam/uptime-kuma](https://github.com/louislam/uptime-kuma/wiki) |

Env vars are documented in `.env.example`. `COMPOSE_PROFILES=cloudflare` plus `CF_TUNNEL_TOKEN`
enables the tunnel; either alone does nothing.

**Jellyfin is deliberately not in this stack** — it runs on the media host itself so it can use the
GPU directly. From a container, reach it at its host's LAN address; see
[docs/cloudflared.md](./docs/cloudflared.md) for why the obvious alternatives are wrong under WSL.
Record the actual address in `CLAUDE.local.md`.

## Agent API Access

API keys live in `.claude/settings.json` (gitignored); copy `.claude/settings.example.json`. Each
entry carries `url`, `urlBase`, and `apiVersion` where it varies, so paths can be built without
rediscovering them.

| Service  | Request                                                          | Auth                               |
| -------- | ---------------------------------------------------------------- | ---------------------------------- |
| Sonarr   | `GET {url}/sonarr/api/v3/{endpoint}`                             | `X-Api-Key` header                 |
| Radarr   | `GET {url}/radarr/api/v3/{endpoint}`                             | `X-Api-Key` header                 |
| Prowlarr | `GET {url}/api/v1/{endpoint}`                                    | `X-Api-Key` header                 |
| Bazarr   | `GET {url}/api/{endpoint}`                                       | `X-API-KEY` header (note the dash) |
| SABnzbd  | `GET {url}/sabnzbd/api?mode={mode}&output=json&apikey={apiKey}`  | query param only                   |
| Seerr    | `GET {url}/api/v1/{endpoint}`                                    | `X-Api-Key` header                 |
| Jellyfin | `GET {url}/{endpoint}`                                           | `Authorization: MediaBrowser Token="{apiKey}"` |

Three traps, each returning something that *looks* like an auth failure but isn't:

1. **`UrlBase` is not optional.** Sonarr (`/sonarr`) and Radarr (`/radarr`) set one here; Prowlarr and
   Bazarr do not. Omitting it returns the SPA's HTML index with a **200**, which reads as a broken
   key. Re-read with
   `grep -oP '(?<=<UrlBase>)[^<]*' ${CONFIG_ROOT}/config/{sonarr,radarr,prowlarr}/config.xml`.
2. **Prowlarr is `/api/v1/`,** not the `/api/v3/` Sonarr and Radarr use. v3 on Prowlarr 404s.
3. **Bazarr's header is `X-API-KEY`**, not `X-Api-Key`.

Prefer the header over `?apikey=` on the *arrs — the query parameter is rejected with 401 on these
versions. SABnzbd is the reverse: query parameter only.

Keys can be re-read from disk rather than each web UI:

```
${CONFIG_ROOT}/config/{sonarr,radarr,prowlarr}/config.xml   <ApiKey>
${CONFIG_ROOT}/config/bazarr/config/config.yaml             auth: → apikey:  (the first one; later
                                                            entries are Bazarr's copies of the
                                                            sonarr/radarr/jellyfin keys)
${CONFIG_ROOT}/config/sabnzbd/sabnzbd.ini                   api_key =
${CONFIG_ROOT}/config/jellyseerr/settings.json              main.apiKey
```

The `seerr` container mounts `config/jellyseerr`; any `overseerr/` or `jellyseerr.bak/` siblings are
stale leftovers.

**Jellyfin differs**: no `UrlBase`, and its key is created at Dashboard → API Keys and shown *once* —
there is no way to read it back. The older `X-Emby-Token: {apiKey}` header still works on 10.11 and
passes through curl more easily. Useful endpoints: `/System/Info`, `/Users`,
`/Library/VirtualFolders`, `/Items`. Library settings are written with
`POST /Library/VirtualFolders/LibraryOptions` — send the **full** `LibraryOptions` object read from
`/Library/VirtualFolders`, or unsent fields reset to defaults. Verify a key with `GET /Users`; on
10.11.11 `GET /Users/Me` returns **400** even with a valid key, so it is useless as a health check.

## Operational Traps

Each of these cost real time to find.

**Recyclarr instance names must be globally unique across `sonarr:` AND `radarr:`.** Duplicate names
make v8 abort at config load with only a `DBG`-level `Duplicate instances:` line — no `[ERR]`,
`[WRN]` or `[FTL]`, and the cron wrapper still prints `job succeeded`. Nothing syncs, silently.
Per-service runs (`sync sonarr`) scope to one block and never hit it, so it looks fine when you set it
up. Verify with `docker exec recyclarr recyclarr sync --preview` — it must print **both** servers.

**Quality profiles are referenced by collections, not just movies.** Radarr refuses to delete a
profile no movie uses because *collections* still point at it. Check `/api/v3/collection` as well as
`/api/v3/movie`. Each arr should have exactly one profile — extras have zero custom-format scores and
are an open door for a TrueHD/PGS remux.

**Hardlinks work on Windows drives mounted into WSL** (9p/drvfs), which people assume breaks `link()`.
Verify with a direct test across `downloads/completed → complete/tv`: same inode, link count 2. Files
showing `nlink=1` *after* import is expected, because the arrs remove the source. Do not "fix" it.

**Your Usenet provider's real connection cap may be below the advertised one.** Exceeding it produces
sustained `502 Too many connections` rather than a clean error. Change the value only when the plan
demonstrably changes, and watch SABnzbd's log afterwards.

**`Language: Not English` fires on "no English audio present"**, true of the original cut of any
foreign-language film. Scored `-500` (soft preference), *not* `-10000`, so English wins when it
exists but Parasite is still grabbable. Dual-audio dubs are blocked separately by `German DL` and
`MULTi` at `-10000`. `Dubs Only` is deliberately unscored — it would block English anime dubs.

**Jellyfin users need an explicit audio language.** Set `AudioLanguagePreference='eng'` and
**`PlayDefaultAudioTrack=False`** on every user. Leaving the latter true means "trust the mux", and
muxes lie: one NORDiC release flagged all six audio tracks `default=1`, resolving to the first
(Danish); a `German.DL` release had German as stream 1 with `default=1`.

**`_UNPACK_` / `_FAILED_` prefixes match `downloadClientWorkingFolders`**, so Radarr refuses to import
from those folders — "File is still being unpacked". Rename the folder, then
`GET /manualimport?folder=…` and `POST /command {name:ManualImport}`. Wanted films can sit there for
weeks looking like residue.

**Sonarr's `RenameSeries` renames files only, not the series folder.** To apply `seriesFolderFormat`
to existing series: `PUT /series/editor {seriesIds, rootFolderPath:'/data/complete/tv', moveFiles:true}`.

**Bazarr provider reality (1.6.0):** `podnapisi` was removed upstream and is silently dropped from
`enabled_providers` on restart; `subsource` needs an API key and throttles with `ConfigurationError`
without one; `subf2m` needs a `user_agent` or fails identically, forever. Enabled and healthy here:
`opensubtitlescom`, `gestdown` (TV only), `subf2m`, `yifysubtitles`. Subscene, which most guides still
recommend, shut down in 2024.

**Intro Skipper's manifest URLs 308-redirect to a bare GitHub org** and cannot be added.
**Do NOT install TheIntroDB as a substitute** — its `Dispose()` throws `ObjectDisposedException: The
CancellationTokenSource has been disposed`, taking down Jellyfin's shutdown path so the server
**does not restart on its own**. It also produced zero segments across 206 lookups. Intro/outro
skipping comes from **Chapter Segments Provider** only, wherever the release has real chapter names.
See [docs/jellyfin-plugins.md](./docs/jellyfin-plugins.md).

**Removing a media-segment provider purges the segments table.** Re-run the **Media Segment Scan**
task afterwards or every skip button silently disappears.

**The iPhone app's "Use native video player (beta)" breaks all playback.** It swaps bundled VLCKit
for iOS AVPlayer, which cannot open MKV — so Jellyfin remuxes to a *live-written* fragmented MP4 with
no known duration and empty `major_brand`/`compatible_brands`. AVFoundation rejects that with
`-11850 AVErrorServerIncorrectlyConfigured` on **every** file. Not a server misconfiguration; leave
the toggle off rather than hunting the server for it.

**"Runtime of all episodes is 0, unable to validate size until it is available"** is a *TVDB metadata
gap*, not a scoring problem. Sonarr's quality definitions are MB-per-minute (`minSize: 15` for
WEBDL/WEBRip-1080p), so `runtime: 0` makes the size check uncomputable and **every** release is
rejected — even ones scoring 2275.

- `runtime` is **provider-managed**: `PUT /series/{id}` is silently ignored, and `RefreshSeries` won't
  help if TVDB itself has no runtime. Verify with `GET /series/lookup?term=tvdb:<id>`.
- **Workaround — force the grab**, which is what the UI's download button on a rejected release does:
  ```bash
  curl -s -X POST "$SONARR/api/v3/release" -H "X-Api-Key: $KEY" \
    -H 'Content-Type: application/json' -d '{"guid":"<guid>","indexerId":<id>}'
  ```
- **Permanent fix** is adding the runtime to TheTVDB. Do *not* drop `minSize` to 0 — recyclarr
  reverts it on the next sync anyway, and it would disable size validation for every series to work
  around one.

**SABnzbd's temp-folder free space turning red does not mean the disk is low.** `glitter.main.js`
colours it whenever the remaining queue exceeds free temp space (`mbleft/1024 > diskspace1`), which is
normal during a backfill and self-clears. `download_free = 50G` + `fulldisk_autoresume = 1` are the
real protection.

## Image Pinning

Images are pinned by tag + SHA256 digest, bumped by Renovate. Update both when changing one.

`prowlarr` is deliberately on a `-nightly` tag — moving to stable is a **downgrade across a database
migration**, which Prowlarr does not support and which needs a restore from
`${CONFIG_ROOT}/config/prowlarr/Backups/`, not just an image swap.
