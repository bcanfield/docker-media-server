# Public Access with Cloudflare Tunnel

[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
publishes a service on a public hostname with no port forwarding. The `cloudflared` container dials
**out** to Cloudflare's edge and traffic is served back down that connection, so nothing opens on your
router or firewall.

This guide uses **Jellyfin** as the worked example because it runs outside this stack, which is the
case with the one non-obvious gotcha — see [Why that address](#why-that-address). Routing a service
that *is* in the stack is simpler, and covered at the end.

## Before you start

Cloudflare's [Self-Serve Subscription Agreement §2.8](https://www.cloudflare.com/terms/) restricts
serving a disproportionate amount of non-HTML content — video specifically — through the proxy.
Personal use is common and usually uneventful; sustained streaming for a large group is the pattern
that draws enforcement.

[Tailscale](Tailscale) is already in this stack and is the ToS-clean option for your own devices. Use
the tunnel when you need to hand someone a URL that works without installing anything.

You need a domain on Cloudflare nameservers and a
[Zero Trust](https://one.dash.cloudflare.com) account. Free tier is fine for both.

## Setup

1. **Create the tunnel** — [Zero Trust](https://one.dash.cloudflare.com) > **Networks > Tunnels >
   Create a tunnel**, type **Cloudflared**.

2. **Copy the token** from the install command it shows you — the long string starting `eyJhIjoi`.
   Don't run the command; the container does that job.

3. **Add both lines to `.env`:**

   ```env
   COMPOSE_PROFILES=cloudflare
   CF_TUNNEL_TOKEN=eyJhIjoi...
   ```

   `cloudflared` sits behind a Compose profile to keep it out of the default stack, so the token alone
   will not start it.

4. **Add the public hostname** — the **Published application routes** tab (**Public Hostname** in
   older dashboards):

   | Field     | Value               |
   | --------- | ------------------- |
   | Subdomain | `jellyfin`          |
   | Domain    | your domain         |
   | Type      | `HTTP`              |
   | URL       | `<HOST_LAN_IP>:8096` |

   `<HOST_LAN_IP>` is the LAN address of the machine Jellyfin runs on. Cloudflare creates the DNS
   record for you.

5. **Start it** — `docker compose up -d cloudflared`. The dashboard should show **Healthy** and the
   logs four connections:

   ```bash
   docker logs cloudflared | grep -i "registered tunnel connection"
   ```

## Configure Jellyfin to trust the tunnel

Jellyfin otherwise sees every request as coming from the tunnel, breaking IP logging and tripping
rate limits. Under **Dashboard > Networking**:

- **Known proxies** → the `sofa-squad` subnet, `172.18.0.0/16` by default. Confirm with
  `docker network inspect sofa-squad -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}'`.
- **Published server URL** → `https://jellyfin.yourdomain.com`, so generated links aren't LAN
  addresses.

Restart Jellyfin to apply.

## Why that address

For the common Windows setup — Docker Engine inside WSL, Jellyfin native on Windows — three addresses
look like they bridge the gap and two will bite you:

| Address                | What it actually is                                                        | Usable? |
| ---------------------- | -------------------------------------------------------------------------- | ------- |
| `host.docker.internal` | The WSL distro's own Docker bridge, `172.17.0.1` — Linux, not Windows       | No      |
| The WSL NAT gateway    | Reaches Windows, but the subnet is reassigned on every WSL restart          | No      |
| `<HOST_LAN_IP>`        | The Windows host's LAN address, what Jellyfin reports as `LocalAddress`     | Yes     |

Under Docker *Desktop*, `host.docker.internal` would point at Windows. Docker Engine directly in WSL
is the case where it does not — check which you have.

**Reserve `<HOST_LAN_IP>` in your router's DHCP settings.** A lease that moves turns into 502s from a
tunnel that still reports Healthy, and nothing here will tell you why.

None of this applies on Linux hosts: use the host's LAN IP, or `network_mode: host`.

## Routing other services

One tunnel serves many hostnames — adding a service is a new published route, not a second tunnel or
container. Services *in* this stack are reachable by container name, since `cloudflared` shares the
`sofa-squad` network. Only Jellyfin needs a LAN IP, and only because it isn't a container here.

Think hard before exposing the \*arrs — they have no meaningful brute-force protection. Anything
beyond Jellyfin and Seerr should sit behind a Cloudflare Access policy.

For Seerr, add a route pointing at `http://seerr:5055`, then verify the origin is actually reachable
before blaming the tunnel:

```bash
docker run --rm --network sofa-squad curlimages/curl \
  -s -o /dev/null -w '%{http_code}\n' http://seerr:5055/api/v1/status
```

Seerr also needs *Enable Proxy Support* and *Application URL* set — see [Seerr](Seerr).

## Cloudflare Access (optional)

**Access > Applications > Add an application > Self-hosted**, point it at the hostname, add a policy
(email OTP is simplest).

The catch: native Jellyfin apps — TVs, Roku, phones — cannot complete the Access login challenge and
will fail to connect. Browsers still work. Apply Access to admin surfaces and leave the Jellyfin
hostname on Jellyfin's own authentication.

## Troubleshooting

**Healthy tunnel, 502 hostname** — `cloudflared` can't reach the origin. Test from its network:

```bash
docker run --rm --network sofa-squad curlimages/curl -sv http://<HOST_LAN_IP>:8096/System/Info/Public
```

Failing that, either the LAN IP moved or a firewall is blocking the WSL subnet.

**Restart loop** — almost always an empty or truncated `CF_TUNNEL_TOKEN`; it's long and easy to clip.

**Dashboard changes don't apply** — remotely-managed tunnels pull config on connect, so
`docker restart cloudflared`.
