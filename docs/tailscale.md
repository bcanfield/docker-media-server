# Remote Access with Tailscale

[Tailscale](https://tailscale.com/) creates a private VPN (tailnet) between your devices, letting you securely access all your services from anywhere — no port forwarding or exposing anything to the public internet.

## Setup

1. **Create a Tailscale account** at [tailscale.com](https://tailscale.com/) (free for personal use, up to 100 devices).

2. **Install Tailscale on your client devices** (phone, laptop, etc.) from [tailscale.com/download](https://tailscale.com/download).

3. **Generate an auth key** at [Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys). Use a **reusable** key so the container can re-authenticate after restarts.

4. **Add the key to your `.env`:**

```env
TS_AUTHKEY=tskey-auth-your-key-here
TS_HOSTNAME=media-server
```

5. **Start (or restart) the stack:**

```bash
docker compose up -d
```

6. **Approve the node** in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines) if prompted.

## Accessing Services Remotely

Once Tailscale is running on both your server and your client device, access services using your Tailscale hostname:

| Service        | Remote URL                  |
| -------------- | --------------------------- |
| Seerr          | `http://media-server:5055`  |
| Sonarr         | `http://media-server:8989`  |
| Radarr         | `http://media-server:7878`  |
| SABnzbd        | `http://media-server:8080`  |
| Bazarr         | `http://media-server:6767`  |
| Prowlarr       | `http://media-server:9696`  |
| Homepage       | `http://media-server:3000`  |
| LazyLibrarian  | `http://media-server:5299`  |
| Audiobookshelf | `http://media-server:13378` |

Replace `media-server` with whatever you set `TS_HOSTNAME` to. You can also use the Tailscale IP shown in the admin console.

## Enabling HTTPS (Optional)

Tailscale can provision [automatic HTTPS certificates](https://tailscale.com/kb/1153/enabling-https) for your tailnet:

1. Enable HTTPS in [Admin Console > DNS](https://login.tailscale.com/admin/dns).
2. Access services at `https://media-server.your-tailnet.ts.net:<port>`.

## Enabling MagicDNS

With [MagicDNS](https://tailscale.com/kb/1081/magicdns) enabled (on by default), you can use short hostnames like `media-server` instead of full IPs across your tailnet.
