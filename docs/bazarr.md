# Bazarr

Automatic subtitle downloading. Connects to Sonarr/Radarr, scans your library, and fetches subtitles from multiple providers.

**Web UI:** `http://<host>:6767`

## First-Time Setup

1. **Connect Sonarr & Radarr** — Settings > Sonarr / Radarr. Use container names as hostnames (`sonarr:8989`, `radarr:7878`) and their API keys. Test each connection.
2. **Set Languages** — Settings > Languages. Pick your subtitle languages and create a language profile. Set a "cutoff" language so Bazarr stops searching once it finds that language.
3. **Enable Providers** — Settings > Providers. Turn on subtitle sources (OpenSubtitles, Subscene, etc.). More providers = better coverage.
4. **Path Mapping** — Only needed if Bazarr sees files at different paths than Sonarr/Radarr. In this Docker stack, the volume mounts match, so skip this.

## Things to Know

- **First scan** — After connecting Sonarr/Radarr, Bazarr automatically scans your existing library for missing subtitles.
- **Forced subtitles** — These are the ones that show up when characters speak a foreign language. Configure separately from regular subtitles.
- **Supported formats** — `.srt`, `.ass`, `.ssa`, `.sub`, `.vtt`, and more.
- **Don't skip steps** — The setup wizard walks you through everything in order. Complete it fully or subtitles won't download.

## Links

- [Bazarr Wiki](https://wiki.bazarr.media/) — official docs
- [Setup Guide](https://wiki.bazarr.media/Getting-Started/Setup-Guide/)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-bazarr)
