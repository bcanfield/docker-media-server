# Recyclarr

Syncs TRaSH Guide quality profiles and custom formats into Sonarr/Radarr daily.

**No web UI** — a cron loop inside the container, on `@daily`.

## First-Time Setup

```bash
docker compose run --rm recyclarr config create        # writes recyclarr.yml to the config volume
docker compose run --rm recyclarr config list templates
```

Then edit `recyclarr.yml`:

```yaml
sonarr:
  my-sonarr:                      # names must be unique across BOTH blocks
    base_url: http://sonarr:8989
    api_key: your-sonarr-api-key
radarr:
  my-radarr:
    base_url: http://radarr:7878
    api_key: your-radarr-api-key
```

Sync manually once to check it, after which the container handles it:

```bash
docker compose run --rm recyclarr sync
```

## Things to Know

- **⚠ Instance names must be globally unique across `sonarr:` and `radarr:`.** Calling both
  `instance` — as most examples do — makes v8 abort at config load with only a `DBG`-level
  `Duplicate instances:` line. No `[ERR]`, no `[WRN]`, and the cron wrapper still logs
  `job succeeded`, so nothing syncs, silently, for as long as it takes you to notice. Per-service
  runs (`sync sonarr`) scope to one block and never trigger it. Verify with
  `docker exec recyclarr recyclarr sync --preview` — it must print **both** servers.
- **Template names differ per app.** Sonarr has `web-1080p` / `web-2160p`; Radarr has
  `hd-bluray-web` / `uhd-bluray-web`. There is no `hd-bluray-web` for Sonarr.
- **Blu-ray templates conflict with a direct-play library.** Disc sources are where PGS image
  subtitles live, and those force a full video transcode. Prefer WEB-only profiles.
- **Sync is idempotent** — safe to run at any time.
- **Quality definitions are MB-per-minute.** A series whose provider metadata has `runtime: 0` makes
  the size check uncomputable, so *every* release is rejected regardless of score. Fix the runtime
  upstream; do not drop `minSize`, which recyclarr will revert on the next sync anyway.

## Links

- [Recyclarr Docs](https://recyclarr.dev/) · [TRaSH Guides](https://trash-guides.info/)
