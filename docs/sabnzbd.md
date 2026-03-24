# SABnzbd

Usenet download client. Receives NZB files from Sonarr/Radarr, downloads from your usenet provider, and unpacks the results.

**Web UI:** `http://<host>:8080`

## First-Time Setup

1. **Add Usenet Server** — Config > Servers. Enter your provider's hostname, port (563 for SSL), username, and password. Test the connection.
2. **Set Up Categories** — Config > Categories. Create a `tv` category and a `movies` category. Sonarr/Radarr will use these to route downloads to the right folders.
3. **Get API Key** — Config > General > Security. You'll need this when adding SABnzbd as a download client in Sonarr/Radarr.

## Things to Know

- **SSD temp path** — The compose file maps `SABNZBD_TEMP` to `/downloads/intermediate` for faster unpacking. Make sure this points to an SSD.
- **Categories matter** — Without categories, Sonarr/Radarr can lose track of downloads. Always set the matching category when adding SABnzbd as a download client.
- **Host whitelist** — If Sonarr/Radarr can't connect, add the container name to Config > Special > `host_whitelist`.
- **Performance** — If the server struggles during unpacking, try disabling Direct Unpack or enabling "Pause Downloading During Post-Processing".

## Links

- [SABnzbd Wiki](https://sabnzbd.org/wiki/) — official docs
- [Quick Setup](https://sabnzbd.org/wiki/introduction/quick-setup)
- [TRaSH Guides — SABnzbd](https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/) — categories & path setup
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-sabnzbd)
