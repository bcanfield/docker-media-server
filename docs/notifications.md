# Notifications

Two channels: [ntfy](https://ntfy.sh/) for anything that means something is wrong, Discord for
everything else.

## Why two

Either one alone covers the whole stack. Discord has the broadest *native* support — Uptime Kuma,
Sonarr, Radarr, Prowlarr and Seerr all ship a connector, and Bazarr and SABnzbd reach it through
their bundled Apprise — and every one of those has a native ntfy option too.

Splitting them is the point. A channel that pings on every grab, import and subtitle download trains
you to ignore it, and an ignored channel is indistinguishable from working software until the media
server has been down for eight hours. Routing the ~5 events that need a human to ntfy, at High
priority, keeps that signal out of the stream you scroll past.

ntfy takes the alert side because it pushes with a priority level to a channel containing nothing
else. Discord takes the activity side because that content genuinely is chat.

## Two channels, split by urgency

**ntfy carries alerts. Discord carries activity.** The trigger sets never overlap, so nothing is sent
twice and neither channel becomes the one you mute.

| Service | → ntfy (alerts) | → Discord (activity) |
| ------- | --------------- | -------------------- |
| Sonarr | health issue/restored, manual interaction required | grab, import, upgrade |
| Radarr | health issue/restored, manual interaction required | grab, import, upgrade, movie added |
| Prowlarr | health issue/restored | — |
| SABnzbd | failed, disk full, error, quota, new login | download complete |
| Bazarr | — | subtitle downloaded |
| Seerr | — | request pending/approved/available/failed, issue created |
| Uptime Kuma | down / up on every monitor | — |

The *arrs take two connectors side by side — one ntfy, one Discord — which is the whole mechanism.
Prowlarr gets no Discord connector because it has no activity stream; its events are health and
application updates.

**Manual interaction required** is worth keeping on the alert channel: it fires when an import needs
a human, which is how a wanted film sits in an `_UNPACK_` folder for weeks looking like residue. See
[Radarr](Radarr).

**SABnzbd routes per event.** Its default `apprise_urls` points at ntfy while
`apprise_target_complete` overrides just completions to Discord — so the split needs no second
integration. Note `complete` ships *enabled*, and left on the default URL it would fire on every
finished download.

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
   its bundled Apprise is the route for both, and it supports a per-event override:

   ```
   Default URL         ntfys://ntfy.sh/<topic>?priority=high
   Completed override  discord://<webhook-id>/<webhook-token>
   ```

   Tick *Failed*, *Disk full*, *Errors*, *Quota*, *New login* — those use the default URL — and leave
   *Completed* ticked with the Discord override in its own box.

5. **Discord** — Server Settings > Integrations > Webhooks > New Webhook, copy the URL. The *arrs and
   Seerr take it as-is; Bazarr and SABnzbd need it as an Apprise URL, which is the same two path
   segments rearranged:

   ```
   https://discord.com/api/webhooks/<id>/<token>   →   discord://<id>/<token>
   ```

   The webhook URL is a credential — anyone with it can post to that channel. Keep it in
   `CLAUDE.local.md`, not the repo.

6. **Uptime Kuma** — Settings > Notifications > Setup Notification > ntfy. Server `https://ntfy.sh`,
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
