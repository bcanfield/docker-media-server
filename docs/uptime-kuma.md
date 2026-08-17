# Uptime Kuma

Monitoring and alerting. Exists here for one reason: most of what breaks in a stack like this breaks
*silently*, and nothing else in the repo would tell you.

**Web UI:** `http://<host>:3001`

## First-Time Setup

Open the UI and create the admin account — there is no default login, and the instance is
unauthenticated until you do, so do it before exposing the port anywhere.

Its SQLite database lives in `${CONFIG_ROOT}/config/uptime-kuma`, so the existing
[backup](Backups) scripts already cover it.

## Monitors

Every URL below was verified from inside the container. Use **HTTP(s) - Keyword** rather than plain
HTTP where a keyword is given: a plain status check passes on any 200, including the SPA's HTML index
that these apps return for unknown paths. The keyword proves the *application* answered.

| Monitor | URL | Keyword | Interval |
| ------- | --- | ------- | -------- |
| Jellyfin | `http://<jellyfin-host>:8096/System/Info/Public` | `ServerName` | 60s |
| Public hostname | `https://<your-tunnel-hostname>` | — | 60s |
| Seerr | `http://seerr:5055/api/v1/status` | `version` | 60s |
| Sonarr | `http://sonarr:8989/sonarr/ping` | `OK` | 300s |
| Radarr | `http://radarr:7878/radarr/ping` | `OK` | 300s |
| Prowlarr | `http://prowlarr:9696/ping` | `OK` | 300s |
| Bazarr | `http://bazarr:6767/` | `Bazarr` | 300s |
| SABnzbd | `http://sabnzbd:8080/sabnzbd/api?mode=version` | `version` | 300s |

Note the `UrlBase` asymmetry, which is the easiest way to build a monitor that watches nothing:
Sonarr and Radarr need `/sonarr` and `/radarr` prefixes, Prowlarr and Bazarr do not.
`http://sonarr:8989/ping` returns the SPA with a **200** and would pass forever.

Services in this stack are reachable by container name because Uptime Kuma shares the `sofa-squad`
network. Jellyfin needs its host's LAN address — see [Cloudflare Tunnel](Cloudflared) for why
`host.docker.internal` is wrong under WSL.

**Set retries to 2-3.** These containers restart on image updates; a single failed check with no
retry will page you for every Renovate merge. The 60s tier is for what users notice; 300s is enough
for the back end.

The public hostname monitor answers a question no internal check can: it exercises the whole path,
edge to origin to application. A tunnel reports Healthy while its origin 502s, so watching the
tunnel's own status is not the same thing. Expect a redirect to a login page — Kuma follows
redirects by default, so it lands on a 200.

### Services with no HTTP surface

Recyclarr, Tailscale and cloudflared have no endpoint to poll. Kuma can watch containers directly via
a **Docker Host**, but that needs `/var/run/docker.sock` mounted into the container, which is
effectively root on the host and not something to hand a service published on port 3001. It's
deliberately not in the compose file. If you want it, add the socket read-only and understand the
trade.

Recyclarr in particular cannot be usefully monitored this way regardless — its failure mode is
running successfully while syncing nothing. See the duplicate-instance trap in
[Recyclarr](Recyclarr).

## Notifications

Configure one before relying on any of this — a monitor with no notification is a dashboard you will
not be looking at when it matters, and ~1-minute detection is the main thing Kuma offers over
checking by hand. Settings > Notifications, and tick *Apply on all existing monitors* plus *Default
enabled* so new monitors inherit it. See [Notifications](Notifications) for the channel this stack
uses and why.

## Expiry, not just availability

The failures that cost most are the ones with a date attached:

- **TLS certificate expiry** — automatic on any HTTPS monitor, with a configurable warning window.
- **Tailscale auth keys expire**, 90 days by default. There's no monitor type for it; put the date in
  a monitor description or a maintenance window so it surfaces before the node drops off the tailnet.

## Reading the history programmatically

Useful if you have an agent or script auditing the stack on a schedule: it samples, Kuma observes. An
outage that starts and ends between two runs is invisible to the sampler and a gap in Kuma's
heartbeat table.

**SQLite directly** — no auth, the richest source. Open read-only so you never contend with the
running container's WAL:

```sql
-- sqlite3 'file:${CONFIG_ROOT}/config/uptime-kuma/kuma.db?mode=ro'
SELECT m.name, MIN(h.time) AS started, MAX(h.time) AS ended,
       COUNT(*) AS failed_checks, MAX(h.msg) AS reason
FROM heartbeat h JOIN monitor m ON m.id = h.monitor_id
WHERE h.status = 0 AND h.time > datetime('now','-1 day')
GROUP BY m.id;
```

Also useful: `stat_hourly` / `stat_daily` for response-time trends (degradation before outage),
`monitor_tls_info` and `domain_expiry` for expiry dates, `notification_sent_history` for what already
alerted.

**HTTP** — `/metrics` is Prometheus format and needs an API key from Settings > API Keys; it carries
current state only, no history. `/api/status-page/heartbeat/<slug>` returns real heartbeat JSON for a
published status page. Note that **`/api/monitors` is not an endpoint** — it returns the SPA with a
200. Uptime Kuma 2.5 has no REST write API; monitor creation only goes through Socket.IO.

Heartbeat retention is configurable under Settings > Monitor History. Anything querying `heartbeat`
can only see as far back as that window.

## The blind spot

**Uptime Kuma cannot monitor its own host.** Running inside this stack means it stops when the stack
stops, so it will never tell you the stack went down — only that something it watches did.

That matters more if Docker runs inside WSL, where the distro powers off on its own when no session is
attached. Covering the stack itself needs a check originating elsewhere — another machine, or a
hosted pinger aimed at a
[push monitor](https://github.com/louislam/uptime-kuma/wiki/Monitor-Types), so silence is the alert.

## Links

- [GitHub](https://github.com/louislam/uptime-kuma) · [Wiki](https://github.com/louislam/uptime-kuma/wiki)
