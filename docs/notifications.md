# Notifications

Alerting for the stack, via [ntfy](https://ntfy.sh/) — phone push with priority levels, natively
supported almost everywhere here, and free without an account.

## Why ntfy rather than Discord

Discord has the broadest native support: Uptime Kuma, Sonarr, Radarr, Prowlarr and Seerr all ship a
Discord connector, and Bazarr and SABnzbd reach it through their bundled Apprise. It is a perfectly
reasonable pick.

ntfy is chosen here because coverage is effectively identical — every one of those has a native ntfy
option too — while the delivery suits *alerts*. Discord notifications are the ones people mute, and
a mute is indistinguishable from working software until the media server has been down for eight
hours. ntfy pushes with a priority level and nothing else competes in the channel.

The split that matters more than the vendor: **send alerts and send activity to different places, or
send only alerts.** A channel that pings on every grab, import and subtitle download trains you to
ignore it, which costs more than having no alerting at all.

## What is configured

Only failure and health events. Grabs, imports, upgrades, renames, application updates and
"download complete" are deliberately off.

| Service | Events | Route |
| ------- | ------ | ----- |
| Sonarr | Health issue, health restored, manual interaction required | Native ntfy connector, priority High |
| Radarr | Health issue, health restored, manual interaction required | Native ntfy connector, priority High |
| Prowlarr | Health issue, health restored | Native ntfy connector, priority High |
| SABnzbd | Failed, disk full, error, quota, new login | Bundled Apprise, `ntfys://` URL |
| Uptime Kuma | Down / up on every monitor | Native ntfy notification |

**Manual interaction required** is worth keeping on: it fires when an import needs a human, which is
how a wanted film sits in an `_UNPACK_` folder for weeks looking like residue. See [Radarr](Radarr).

**SABnzbd's `complete` event is off on purpose** — it is enabled by default and fires on every
finished download. `disk_full` and `error` are on, which are the ones that mean something.

Not configured: Bazarr (subtitle events are noise) and Seerr (request notifications are a per-user
setting, not an operator alert).

## Setup

1. **Pick a topic name.** On the public ntfy.sh server a topic is the only access control: anyone who
   knows the name can both read your alerts and publish to them. Use a long random one, and keep it
   out of the repo — this is a public repository, so it belongs in `CLAUDE.local.md` alongside the
   other host-specific values.

2. **Subscribe.** Install the ntfy app (iOS/Android) or open `https://ntfy.sh/<topic>` in a browser,
   and subscribe to the topic.

3. **The *arrs** — Settings > Connect > Add > ntfy:

   | Field | Value |
   | ----- | ----- |
   | Server URL | `https://ntfy.sh` |
   | Topics | your topic |
   | Priority | High |
   | Triggers | On Health Issue, On Health Restored, On Manual Interaction Required |

   Leave "Include Health Warnings" off to start — warnings include transient indexer blips.

4. **SABnzbd** — Config > Notifications > Apprise. SABnzbd has **no native ntfy or Discord option**;
   its bundled Apprise is the route for both. URL format:

   ```
   ntfys://ntfy.sh/<topic>?priority=high
   ```

   Then untick *Completed* and tick *Failed*, *Disk full*, *Errors*, *Quota*, *New login*.

5. **Uptime Kuma** — Settings > Notifications > Setup Notification > ntfy. Server `https://ntfy.sh`,
   your topic, priority 4-5. Tick "Apply on all existing monitors" and "Default enabled" so new
   monitors inherit it.

## Verifying

Every *arr connector has a **Test** button, which is the fastest check. To test the Apprise URL
format itself without touching SABnzbd's config, Bazarr vendors Apprise and can send one:

```bash
docker exec bazarr sh -c "cd /app/bazarr/bin && python3 -c \"
import sys; sys.path.insert(0,'libs')
import apprise
a = apprise.Apprise(); a.add('ntfys://ntfy.sh/<topic>?priority=high')
print(a.notify(title='Test', body='Hello'))\""
```

## If you outgrow ntfy.sh

Self-hosting ntfy is a small Go binary and removes the public-topic problem. One caveat before you
plan on it: the **iOS app cannot receive push from a self-hosted server directly** — Apple push has
to originate from ntfy's own infrastructure, so a self-hosted instance needs `upstream-base-url`
pointed back at ntfy.sh to work on iPhones. Android is unaffected. If the phones that matter are
iPhones, self-hosting buys less than it looks like.

## Links

- [ntfy docs](https://docs.ntfy.sh/) · [Apprise ntfy syntax](https://github.com/caronc/apprise/wiki/Notify_ntfy)
