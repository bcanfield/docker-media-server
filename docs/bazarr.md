# Bazarr

Automatic subtitles. Connects to Sonarr/Radarr, scans the library, fetches what's missing.

**Web UI:** `http://<host>:6767`

## First-Time Setup

1. **Connect Sonarr & Radarr** — Settings > Sonarr / Radarr. Use container names (`sonarr:8989`,
   `radarr:7878`) and their API keys.
2. **Set Languages** — Settings > Languages. Create a profile and set a cutoff language so Bazarr
   stops searching once it has one.
3. **Enable Providers** — see below; the defaults suggested in most guides are dead.
4. **Path Mapping** — not needed here, the mounts match.

Bazarr's API key header is `X-API-KEY` — note the dashes, unlike the *arrs' `X-Api-Key`.

## Provider reality (1.6.0)

Most guides still recommend Subscene, which **shut down in May 2024**. Of what remains:

| Provider           | Status                                                              |
| ------------------ | ------------------------------------------------------------------- |
| `opensubtitlescom` | Works. Needs a free account.                                        |
| `gestdown`         | Works, TV only.                                                     |
| `subf2m`           | Works **only** with a `user_agent` set — otherwise it fails forever. |
| `yifysubtitles`    | Works, movies only.                                                 |
| `podnapisi`        | Removed upstream; silently dropped from `enabled_providers` on restart. |
| `subsource`        | Needs an API key; throttles with `ConfigurationError` without one.   |

## Things to Know

- **Text subtitles only, deliberately.** Image subtitles (PGS/VOBSUB) force Jellyfin to burn them in,
  which triggers a full video transcode. Keeping a text subtitle available on everything is what
  avoids that.
- **Forced subtitles** — the ones for foreign-language dialogue. Configured separately.
- **First scan** starts automatically once Sonarr/Radarr are connected.

## Links

- [Bazarr Wiki](https://wiki.bazarr.media/) · [Setup Guide](https://wiki.bazarr.media/Getting-Started/Setup-Guide/)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-bazarr)
