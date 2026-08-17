# SABnzbd

Usenet downloader. Takes NZBs from Sonarr/Radarr, downloads, repairs, unpacks.

**Web UI:** `http://<host>:8080`

## First-Time Setup

1. **Add Usenet Server** — Config > Servers. Provider hostname, port `563` for SSL, username,
   password. Test the connection.
2. **Set Up Categories** — Config > Categories. Create `tv` and `movies`; Sonarr/Radarr use these to
   route downloads. Without them the *arrs lose track of downloads.
3. **Get API Key** — Config > General. Needed when adding SABnzbd as a download client.

## Things to Know

- **SSD temp path** — `SABNZBD_TEMP` is mounted at `/incomplete` with the override file, or
  `/downloads/intermediate` without it. Point it at an SSD; in-progress downloads deliberately stay
  off the media mount so unpacking is fast and the import that follows is a free hardlink.
- **API auth is the query parameter only** — `?apikey=`. Unlike the *arrs, SABnzbd rejects the header
  form.
- **Host whitelist** — if the *arrs can't connect, add the container name under
  Config > Special > `host_whitelist`.
- **Connection counts above your plan's cap** produce sustained `502 Too many connections` rather
  than a clean error. Raise them one step at a time and watch the log.
- **Red "free space" on the temp folder is not a low disk.** The UI colours it whenever the remaining
  queue exceeds free temp space, which is normal during a backfill and self-clears.
  `download_free` + `fulldisk_autoresume` are the real protection.

## Links

- [SABnzbd Wiki](https://sabnzbd.org/wiki/) · [Quick Setup](https://sabnzbd.org/wiki/introduction/quick-setup)
- [TRaSH Guides — SABnzbd](https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/)
- [LinuxServer.io Docker](https://docs.linuxserver.io/images/docker-sabnzbd)
