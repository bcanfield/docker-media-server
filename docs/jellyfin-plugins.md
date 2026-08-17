# Jellyfin Plugins

Which plugins are worth installing when the stack is tuned for **direct play on a native TV client**,
and why. Written against Jellyfin 10.11 in 2026-08; re-check versions before trusting specifics.

The constraint behind every decision: **the primary client is the native Jellyfin app on a Fire Stick
/ Android TV** (`jellyfin-androidtv`). That rules out most of what appears in "best Jellyfin plugins"
lists. Jellyfin runs outside this stack (see [cloudflared](Cloudflared) for addressing it from a
container), and Bazarr owns subtitles.

## Two current landmines

**Intro Skipper cannot be installed.** Its manifest URL `https://intro-skipper.org/manifest.json`
(and `manifest.intro-skipper.org`) returns a **308 redirect to the bare GitHub org**, so Jellyfin
cannot add the repository. Re-verified 2026-08-17. It remains the highest-value plugin here if
distribution is ever fixed, so it is described below.

**⚠ Do not install TheIntroDB as a substitute.** It looks right — targets 10.11.6+, drives the same
media-segments table, no CPU-heavy fingerprinting. In practice its `Dispose()` throws:

```
[FTL] Main: Unhandled Exception
System.ObjectDisposedException: The CancellationTokenSource has been disposed.
   at TheIntroDB.TheIntroDbUsageReportingService.Dispose()
```

That unhandled exception takes down Jellyfin's shutdown path, so **the server does not come back
after a restart** and must be started by hand. It also produced zero segments across 206 lookups,
warning every ~2 minutes. Remove its repository as well as the plugin.

**Removing any media-segment provider purges the segments table.** Re-run the *Media Segment Scan*
task afterwards or every skip button silently disappears.

Net effect: intro skipping comes from Chapter Segments Provider alone.

## The rule: server-side vs. web-UI

**Server-side** plugins run inside the server process — metadata, media segments, scrobbling,
reporting. Their effects reach every client.

**Web-UI** plugins inject JavaScript or CSS into `jellyfin-web`. The Fire Stick app is a separate
Android application that never loads that page, so these are **completely inert** on the main viewing
device: Jellyfin Enhanced, Media Bar, Home Sections, Collection Sections, Custom Tabs, HoverTrailer,
InPlayerEpisodePreview, JellyfinTweaks, KefinTweaks, the JavaScript Injector, and every skin.

If a plugin's selling point is how the interface *looks*, assume it does nothing here.

## Recommended

**Intro Skipper** — fingerprints audio across a season, finds repeated intro and credit sequences,
and writes typed entries into the **media segments** table. The Android TV client reads that type
natively and shows a real skip button. Not in the official catalog. Needs ≥10.11.11 — don't roll the
server back below that without uninstalling first. The analysis scan decodes audio across the whole
library, so schedule it off-hours. Does not work when playback is handed to an external player.

**Chapter Segments Provider** — official, v4.0.0.0. Reads **chapter titles** already in the file,
pattern-matches them (`Intro`, `Recap`, `Credits`, `Previously On`, …) and writes the same typed
segments, so the same skip button. Database rows only: no decoding, effectively instant.

It depends entirely on releases carrying *meaningful* chapter names. A 25-file sample from one
library:

| Result | Count | Examples |
| ------ | ----- | -------- |
| Usable intro/recap titles | 6 (24%) | Obi-Wan Kenobi, House of the Dragon, Superman & Lois, Blue Mountain State |
| `Credits` only | 3 (12%) | Tangled, Toy Story 2 |
| No chapters at all | 16 (64%) | Netflix WEBRips, most movie rips |

The pattern: **Disney+ and HBO sources carry rich chapter names; Netflix WEBRip and most movie
releases carry none.** Survey your own library:

```bash
docker exec bazarr ffprobe -v error -show_chapters -of json "/data/complete/tv/<show>/<file>.mkv"
```

(That path assumes `docker-compose.override.yml`; without it Bazarr sees `/tv` and `/movies`.)

**TMDb Box Sets** — official, v13.0.0.0. Builds collections from TMDb box-set data. Server-side, so
collections appear in the Fire Stick UI like any other item.

**Playback Reporting** — official, v17.0.0.0. Who watched what, when, and **critically, what
transcoded**. The only good instrument for finding files the Fire Stick can't direct-play, which is
the central question on a stack tuned for direct play.

## Optional

| Plugin | Version | Why |
| ------ | ------- | --- |
| Trakt | 30.0.0.0 | Scrobbles from any client, Fire Stick included, because scrobbling is server-side. |
| Reports | 18.0.0.0 | Library auditing — gaps, quality, missing metadata. |
| Transcode Killer | 4.0.0.0 | Kills any transcoding session, forcing direct play or failure. Blunt, but surfaces problem files fast. |
| Merge Versions | third-party | Merges duplicate 1080p/4K entries into one item with a version picker. Needs `danieladov`'s repo; verify the 10.11 build. |

## Not recommended

- **Open Subtitles** — Bazarr owns subtitles here. Two systems writing subtitle files for the same
  media.
- **JellyScrub** — superseded. Trickplay is built into 10.11: enable it on the libraries, then turn on
  *Developer options → Enable trickplay in video player* in the Android TV app.
- **Every web-UI plugin** — see the rule above.

## Subtitles: how the pieces interact

The reference Bazarr config in `${CONFIG_ROOT}/config/bazarr/config/config.yaml`:

| Setting | Value | Meaning |
| ------- | ----- | ------- |
| `use_embedded_subs` | `false` | Embedded tracks do **not** satisfy a language requirement |
| `enabled_providers` | `opensubtitlescom`, `gestdown`, `subf2m`, `yifysubtitles` | `embeddedsubtitles` is configured but not enabled |
| `subfolder` | `current` | Sidecar files land next to the video |
| `ignore_pgs_subs` / `ignore_vobsub_subs` | `true` | Inert unless `use_embedded_subs` is on |

So this is **not** "embedded first, Bazarr as fallback" — Bazarr downloads an external subtitle for
essentially everything. Both tracks appear in the picker and Jellyfin's default-track logic chooses.

**Subtitle Extract (catalog v7.0.0.0) — skip, conditionally.** It pre-extracts embedded subtitle
streams so Jellyfin doesn't run ffmpeg on demand. It writes to Jellyfin's internal cache
(`/config/data/subtitles`, keyed by item ID), **not** sidecar files, so it cannot collide with Bazarr.
It's skipped only because with `use_embedded_subs: false` a Bazarr sidecar already exists nearly
everywhere, so the stall it prevents rarely happens. It also never prunes its cache when media is
deleted.

If you enable embedded subtitles, which way you do it inverts the answer:

- **`use_embedded_subs: true`** (Bazarr accepts embedded tracks and stops fetching externals) → more
  playback uses embedded tracks, the extraction stall becomes real, so **install Subtitle Extract**.
  Keep `ignore_pgs_subs` and `ignore_vobsub_subs` true; they go live under this setting and correctly
  force a text subtitle for image-only files.
- **The `embeddedsubtitles` provider** (Bazarr extracts tracks out to sidecars) → nothing is left for
  Jellyfin to extract, so **Subtitle Extract stays redundant**.

**The constraint neither changes:** image subtitles (PGS, VOBSUB) cannot be sent as a separate stream.
Jellyfin burns them into the picture, forcing a **full video transcode** even on a file that would
otherwise direct-play. No plugin fixes this — always having a text subtitle does, which is what Bazarr
is already for.

## Fire Stick app settings

Installing segment plugins is half the job. In the Android TV app:

- **Playback → Media Segments** — set Intro and Outro to `Skip` or `Ask to skip`. Left at the default,
  the plugins produce no visible behaviour at all.
- **Developer options → Enable trickplay in video player** — experimental, off by default.

Segment skipping does not work with an external player.

## Installing

Catalog plugins install from **Dashboard → Plugins → Catalog**, or via the API. Jellyfin must restart
before a plugin loads.

```bash
J=http://JELLYFIN_HOST:8096
K=$(python3 -c "import json;print(json.load(open('.claude/settings.json'))['services']['jellyfin']['apiKey'])")

curl -s -H "X-Emby-Token: $K" "$J/Plugins" | python3 -c \
  "import json,sys;[print(p['Name'],p['Version'],p['Status']) for p in json.load(sys.stdin)]"

curl -s -X POST -H "X-Emby-Token: $K" "$J/Packages/Installed/Chapter%20Segments%20Provider"
```

Everything the catalog has a 10.11 build for:

```bash
curl -s -H "X-Emby-Token: $K" "$J/Packages" | python3 -c "
import json,sys
for p in json.load(sys.stdin):
    ok=[v for v in p.get('versions',[]) if v.get('targetAbi','').startswith('10.11')]
    print(('YES ' if ok else '--  ')+p['name']+' | '+(ok[0]['version'] if ok else 'no 10.11 build'))
"
```

## Summary

| Plugin | Source | Status |
| ------ | ------ | ------ |
| Intro Skipper | `intro-skipper.org` | **Uninstallable** — manifest 308s. Would need ≥10.11.11, scan off-hours |
| TheIntroDB | Third-party | **Do not install** — crashes Jellyfin's shutdown path |
| Chapter Segments Provider | Official | Install |
| TMDb Box Sets | Official | Install |
| Playback Reporting | Official | Install |
| Trakt / Reports / Transcode Killer | Official | Optional |
| Merge Versions | Third-party | Optional, verify 10.11 build |
| Subtitle Extract | Official | **Conditional** — only if `use_embedded_subs: true` |
| Open Subtitles | Official | Skip — Bazarr owns subtitles |
| JellyScrub | Third-party | Skip — built into 10.11 |
| Any web-UI plugin | — | Skip — inert on Fire Stick |

## References

- [Intro Skipper](https://github.com/intro-skipper/intro-skipper) ·
  [Chapter Segments Provider](https://github.com/jellyfin/jellyfin-plugin-chapter-segments)
- [Media segments](https://jellyfin.org/docs/general/server/metadata/media-segments/) ·
  [Codec support matrix](https://jellyfin.org/docs/general/clients/codec-support/)
- [Subtitle Extract](https://github.com/jellyfin/jellyfin-plugin-subtitleextract) —
  [cache cleanup issue #35](https://github.com/jellyfin/jellyfin-plugin-subtitleextract/issues/35)
- [Plugin documentation](https://jellyfin.org/docs/general/server/plugins/)
