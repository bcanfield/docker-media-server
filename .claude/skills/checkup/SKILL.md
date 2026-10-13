---
name: checkup
description: >
  Audit a self-hosted media stack (Sonarr/Radarr/Prowlarr/Bazarr/SABnzbd/Jellyfin and friends) for
  silent failures — things every dashboard reports as healthy while they quietly break. Use this
  whenever the user asks for a checkup, health check, audit, "how is the stack doing", a
  nightly/morning report, why something isn't downloading or importing, or whether anything broke —
  even if they don't say "checkup". Read-only: it diagnoses and proposes, never fixes. It keeps a
  journal in local/checkup/ and gets smarter every run.
---

# Stack Checkup

The failures that cost weeks in a stack like this are the ones where every individual signal reads
healthy: a sync job exits 0 having synced nothing, an indexer's quota runs out and searches
"gracefully" return less, a profile drifts and a transcode-hostile remux imports as a *success*.
Availability monitors can't see these because the fault only exists in a **relationship** — between
services, between state and intent, between today and last week. Your job is to check the
relationships.

Three rules govern every run:

1. **Read-only.** Never change service state, config, or files during a checkup. API keys here are
   all-or-nothing, so restraint is yours to enforce. Findings come with a proposed fix the user can
   apply; they don't come pre-applied.
2. **Verify before you flag.** A report that cries wolf gets ignored, and an ignored report is
   worse than none. Three confirmed findings beat ten maybes. When healthy, say so in a line or two
   and stop — a quiet report on a quiet night is the product working, not you underdelivering.
3. **Learn something.** Every run ends by updating the journal (below). A checkup that leaves the
   journal untouched on a surprising run wasted the surprise.

## State

All checkup state is host-specific, so it lives in gitignored `local/checkup/`:

```
local/checkup/env.md        # what this stack is: services, addresses, quirks (written by setup)
local/checkup/notes.md      # the journal: what past runs learned (read first, write last)
local/checkup/baseline/     # snapshots to diff against: profiles, providers, images
local/checkup/last-report.md
```

## First run: setup

If `local/checkup/env.md` doesn't exist, do a one-time scan before anything else:

1. Read the repo's `CLAUDE.md` and `CLAUDE.local.md` — they carry the stack's design intent and
   known traps. The intent (e.g. a direct-play policy) is what several checks compare against.
2. Discover what's actually running: the compose file(s) declare the services; `docker ps` shows
   reality. Note gaps between the two.
3. Verify API access to each service using the auth table in `CLAUDE.md` and keys from
   `.claude/settings.json` (or read keys from config files on disk, also per `CLAUDE.md`). Record
   working base URLs — URL-base prefixes vary per service and a wrong one returns the web UI's
   HTML with a 200, which looks exactly like a broken key.
4. Write `local/checkup/env.md`: one line per service (name, URL, auth quirk), the stack's stated
   intent in a sentence or two, the notification channel to use for reports if one exists, and
   anything host-specific a future run shouldn't have to rediscover.
5. Write the first baselines to `local/checkup/baseline/`: quality profiles + custom-format scores
   per arr (JSON), enabled subtitle providers, enabled indexers, image tags/digests in use.

Setup is also the recovery path: if a check fails because the environment changed (service added,
port moved), update `env.md` rather than working around it silently.

## Every run: the checkup

Start by reading `env.md` and `notes.md` — the journal's suppressions and lessons apply from the
first check, not after you've re-flagged a known false positive. Then work through the checks. For
each service, prefer its API over its logs; use logs to explain findings, not to find them (arr
logs are mostly noise — ffprobe spam, transient 429s).

**Self-reporting liars** — jobs that succeed in name only:
- Config-sync tools (Recyclarr etc.): don't trust exit codes; verify the sync actually covered
  every instance (e.g. a preview run naming each server) or diff live scores against the YAML.
- Anything on a schedule (backups, timers, cleanup containers): confirm it ran *recently* and its
  output exists, not that it's merely configured. A maintenance tool that's been dead for months
  is a documented failure mode of this genre.

**State vs intent** — the stack's goal is written down; hold reality against it:
- Sample the last ~20 imports per arr and inspect what actually landed (codec, audio streams,
  subtitle types). Anything that violates the stated policy (e.g. transcode triggers in a
  direct-play library) is a top-priority finding — trace *how* it got past the profiles.
- Diff live quality profiles/CF scores against baseline. Unexplained drift or a new profile with
  no scores is an open door, not a cosmetic issue.

**Flow** — content should be moving:
- Queues: items stuck, stalled, or waiting on "manual interaction"; compare grab history against
  import history for silent drop-off.
- Download staging area: aged `_UNPACK_`/`_FAILED_`/orphaned folders, joined against the wanted
  list — is that residue, or a wanted item that will sit there forever?
- Wanted vs grabbed trend: monitored items aging without grabs usually means quota-exhausted
  indexers or a metadata gap upstream, neither of which raises any health warning. Check
  per-series/movie rejection reasons before blaming indexers.

**Drift** — diff today against baseline: enabled indexers, subtitle providers (updates silently
drop dead ones), image tags, notification connections. Update the baseline afterwards *only* for
changes the user made deliberately; drift you can't attribute stays a finding.

**The basics, cheaply**: native health-check endpoints on every service; disk space and growth
rate; container restarts in the last day; monitoring history if a monitor (e.g. Uptime Kuma)
keeps one — read its DB for outages between runs rather than sampling now.

Skip checks that don't apply to this stack (no torrents → no VPN/seeding checks); `env.md` says
which. Add checks the journal has proven matter here.

## Report

Write `local/checkup/last-report.md` and deliver it (to the channel in `env.md`, else just present
it). Lead with the verdict:

```
# Checkup — <date>
**<All clear | N findings>** — one-sentence verdict.

## Findings            (omit when clear)
1. <what> — <evidence: numbers, names, dates> — <proposed fix, copy-pasteable when possible>

## Watching            (not actionable yet; trends worth a line)
```

Severity order: intent violations and silent-failure confirmations first, flow problems second,
drift and trends last. Every finding names its evidence — a finding the user can't verify in one
click teaches them to skim.

## The journal

`local/checkup/notes.md` is why run 30 is better than run 1. After every run, append only what was
*surprising* — one line each, newest last:

```
- 2026-08-19 NOISE: sab temp-space "low" during backfill — UI quirk, self-clears; don't flag
- 2026-08-19 REAL: recyclarr synced 0 instances since May; cause: duplicate instance names; check: preview must list both servers
- 2026-08-20 FIXED: _UNPACK_ residue was wanted film; rename+manual-import worked; watch folder weekly
```

Three tags are enough: `NOISE` (flagged it, wasn't real — includes the suppression rule), `REAL`
(missed or nearly missed — includes the check that would have caught it), `FIXED` (a proposed fix
was applied — record whether it worked). A healthy run with no surprises appends nothing.

Keep it concise or it stops being read: when it grows past ~40 lines, consolidate — merge
duplicates, drop entries the checks above now cover, keep the rule and drop the story.

**Promote what generalizes.** When a journal entry is about arr-stack behavior rather than this
host (an upstream bug, a provider dying, a new silent-failure mode), propose moving it into this
skill's check list or the repo's `CLAUDE.md` traps section as a committed change — that's how a
lesson learned on one clone reaches everyone. Host-specific lessons stay in the journal.

## Scheduling

To make this the nightly checkup it's designed to be, run it headless on a timer, e.g.
`claude -p "/checkup"` from cron/systemd on the host. The report-delivery channel in `env.md`
(ntfy, Discord webhook, email) is what makes an unattended run useful; without one, the checkup
only informs the next person who asks.
