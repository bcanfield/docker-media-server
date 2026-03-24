# Recyclarr

Syncs TRaSH Guide quality profiles and custom formats to Sonarr/Radarr on a daily schedule. Keeps your quality settings up to date without manual tweaking.

**No web UI** — runs as a scheduled cron job inside the container.

## First-Time Setup

1. **Create Config** — Run inside the container:
   ```bash
   docker compose run --rm recyclarr config create
   ```
   This generates `recyclarr.yml` in the config volume.

2. **Pick Templates** — List available TRaSH Guide templates:
   ```bash
   docker compose run --rm recyclarr config list templates
   ```
   Common choices: `hd-bluray-web` for 1080p, `uhd-bluray-web` for 4K.

3. **Edit Config** — Update `recyclarr.yml` with your Sonarr/Radarr URLs and API keys:
   ```yaml
   sonarr:
     instance:
       base_url: http://sonarr:8989
       api_key: your-sonarr-api-key
   radarr:
     instance:
       base_url: http://radarr:7878
       api_key: your-radarr-api-key
   ```

4. **Sync** — Test manually:
   ```bash
   docker compose run --rm recyclarr sync
   ```
   After this, the container runs on `@daily` automatically.

## Things to Know

- **Sync is idempotent.** Safe to run as often as you want.
- **Templates are complete.** Resist over-customizing unless you have a specific reason.
- **Check Sonarr/Radarr** after syncing to verify new profiles and custom formats appeared.
- **`delete_old_custom_formats: true`** — Optional setting to clean up deprecated TRaSH formats.

## Links

- [Recyclarr Docs](https://recyclarr.dev/) — official docs
- [TRaSH Guides](https://trash-guides.info/) — the quality profiles Recyclarr syncs
