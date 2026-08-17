# Remote Access with Tailscale

[Tailscale](https://tailscale.com/) builds a private network between your devices, so you can reach
every service from anywhere with no port forwarding and nothing exposed publicly.

## Setup

1. Create an account at [tailscale.com](https://tailscale.com/) (free for personal use).
2. Install Tailscale on your client devices.
3. Generate a **reusable** auth key at
   [Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys) — reusable so
   the container re-authenticates after restarts.
4. Add it to `.env`:

   ```env
   TS_AUTHKEY=tskey-auth-your-key-here
   TS_HOSTNAME=media-server
   ```

5. `docker compose up -d`, then approve the node in the
   [admin console](https://login.tailscale.com/admin/machines) if prompted.

**Auth keys expire** — 90 days by default. Note the date, or the container drops off the tailnet on a
restart long after you've forgotten it was configured.

## Accessing Services

| Service  | Remote URL                 |
| -------- | -------------------------- |
| Seerr    | `http://media-server:5055` |
| Sonarr   | `http://media-server:8989` |
| Radarr   | `http://media-server:7878` |
| SABnzbd  | `http://media-server:8080` |
| Bazarr   | `http://media-server:6767` |
| Prowlarr | `http://media-server:9696` |
| Uptime Kuma | `http://media-server:3001` |

Substitute your own `TS_HOSTNAME`. Short names work because
[MagicDNS](https://tailscale.com/kb/1081/magicdns) is on by default.

## Options Already Set

The container runs with `--advertise-exit-node`, so you can route all traffic from a remote device
through this host — enable it per-device in the admin console. It uses `network_mode: host`, which is
why it sees the other services directly.

To reach your whole LAN rather than just this host, add `--advertise-routes` in
`docker-compose.override.yml` (there's a commented example) and approve the route in the admin
console.

## HTTPS (Optional)

Enable HTTPS in [Admin Console > DNS](https://login.tailscale.com/admin/dns), then reach services at
`https://media-server.your-tailnet.ts.net:<port>`.
