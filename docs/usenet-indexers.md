# Recommended Usenet Indexers

Managed through Prowlarr. Indexers differ in sources and retention depth, so 2-3 covers far more than
one. Prices drift — treat the figures as a rough guide.

| Indexer                                 | Registration | Cost                        | Strength                                                       |
| --------------------------------------- | ------------ | --------------------------- | -------------------------------------------------------------- |
| [NZBgeek](https://nzbgeek.info/)        | Open         | ~$12/year                   | Reliable all-rounder, strong on current content                |
| [NZBPlanet](https://nzbplanet.net/)     | Open (paid)  | ~8 EUR/year                 | Largest index, good for older and obscure titles               |
| [NZBFinder](https://nzbfinder.ws/)      | Open         | Free tier / ~15-35 EUR/year | Always open, fast indexing, usable free tier                   |
| [DrunkenSlug](https://drunkenslug.com/) | Invite-only  | ~10-20 EUR/year             | Top-tier quality; watch r/usenet for open registration windows |
| [DOGnzb](https://dognzb.cr/)            | Invite-only  | ~$37/year                   | 4,800+ days retention, IMDb/Trakt watchlist sync               |

Indexers are only half the equation — you also need a **Usenet provider** (the servers articles are
actually pulled from), configured in SABnzbd rather than Prowlarr. Running a single provider means
any article it has dropped is unrecoverable, whatever your indexers say; a cheap block account from a
different backbone is the usual insurance.
