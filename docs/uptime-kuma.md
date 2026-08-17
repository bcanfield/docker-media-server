# Uptime Kuma

Monitoring and alerting. Exists here for one reason: most of what breaks in a stack like this breaks
*silently*, and nothing else in the repo would tell you.

**Web UI:** `http://<host>:3001`

## First-Time Setup

Open the UI and create the admin account — there is no default login, and the instance is
unauthenticated until you do, so do it before exposing the port anywhere.

Its SQLite database lives in `${CONFIG_ROOT}/config/uptime-kuma`, so the existing
[backup](Backups) scripts already cover it.

## Monitors worth creating

| Target | Type | URL | Catches |
| ------ | ---- | --- | ------- |
| Jellyfin | HTTP(s) | `http://<jellyfin-host>:8096/System/Info/Public` | The server being down, which otherwise looks identical to nobody watching |
| Public hostname | HTTP(s) | `https://<your-tunnel-hostname>` | A tunnel reporting Healthy while the origin 502s |
| Seerr | HTTP(s) | `http://seerr:5055/api/v1/status` | The request portal users actually touch |
| Sonarr | HTTP(s) | `http://sonarr:8989/sonarr/ping` | Note the `UrlBase` — `/ping` alone returns the SPA |
| Radarr | HTTP(s) | `http://radarr:7878/radarr/ping` | |
| Prowlarr | HTTP(s) | `http://prowlarr:9696/ping` | No `UrlBase` on this one |
| SABnzbd | HTTP(s) | `http://sabnzbd:8080/sabnzbd/api?mode=version` | |

Services in this stack are reachable by container name because Uptime Kuma shares the `sofa-squad`
network. Jellyfin needs its host's LAN address — see [Cloudflare Tunnel](Cloudflared) for why
`host.docker.internal` is wrong under WSL.

**Set the retry interval higher than you think.** These services restart on their own; a 60-second
check with 1 retry will page you for every image update.

## Expiry, not just availability

The failures that cost the most notice are the ones with a date attached, and Uptime Kuma is the only
thing here that will surface them:

- **TLS certificate expiry** — automatic on any HTTPS monitor, with a configurable warning window.
- **Tailscale auth keys expire**, 90 days by default. There's no monitor type for this; put the date
  in the monitor description or a maintenance window so it appears in the UI before the node drops
  off the tailnet.

## The blind spot

**Uptime Kuma cannot monitor its own host.** Running inside this stack means it stops when the stack
stops, so it will never tell you the stack went down — only that something it watches did.

That matters more than usual if Docker runs inside WSL, where the distro powers off on its own when
no session is attached. To cover the stack itself, the check has to originate elsewhere: another
machine, or a hosted pinger aimed at a
[push monitor](https://github.com/louislam/uptime-kuma/wiki/Monitor-Types) so silence itself is the
alert.

## Notifications

Configure at least one before you rely on any of this — Settings > Notifications. Uptime Kuma
supports ntfy, Gotify, Discord, Telegram, email and ~90 others. A monitor with no notification is a
dashboard you will not be looking at when it matters.

## Links

- [GitHub](https://github.com/louislam/uptime-kuma) · [Wiki](https://github.com/louislam/uptime-kuma/wiki)
