# Homepage

YAML-configured dashboard with service widgets. Shows the status of all your media services at a glance.

**Web UI:** `http://<host>:3000`

## First-Time Setup

The starter config is in `extras/homepage/`. Copy it to your config root during setup:

```bash
cp -r extras/homepage/ ${CONFIG_ROOT}/config/homepage/
```

Then edit the YAML files to match your setup:

- **`services.yaml`** — Your service list with icons, URLs, and widgets. Replace `your-*-api-key` placeholders with real API keys.
- **`settings.yaml`** — Theme, layout, and branding.
- **`widgets.yaml`** — System resource monitors (CPU, memory, disk).
- **`bookmarks.yaml`** — Quick links to external resources.
- **`docker.yaml`** — Docker socket config for container stats.

## Things to Know

- **`HOMEPAGE_ALLOWED_HOSTS`** — Set this env var to the hostname/IP you use to access the dashboard (including port). Required or the page won't load.
- **Widget URLs shouldn't end with `/`** — Homepage handles routing automatically.
- **Container names as hostnames** — Use `sonarr`, `radarr`, etc. in widget URLs since everything is on the same Docker network.
- **No built-in auth** — Put it behind a reverse proxy if exposed to untrusted networks.
- **Changes need a refresh** — Click the refresh icon after editing YAML files.

## Links

- [Homepage Docs](https://gethomepage.dev/) — official docs
- [Services Config](https://gethomepage.dev/configs/services/)
- [Widget List](https://gethomepage.dev/widgets/)
