# Research: an AI "nightly checkup" service for the arr stack

*Idea validation, August 2026. Four parallel research passes: the existing arr companion-tool
landscape, AI/LLM tools already in this space, a taxonomy of how these stacks actually fail, and
feasibility (architecture, local-LLM viability, cost, distribution). All star counts and project
statuses verified against GitHub as of 2026-08-19.*

## Verdict

**Refine, don't kill — but only one narrow version of the idea survives contact with the
landscape.**

"A service that leverages AI to help with things" is too broad, and most concrete versions of it
are already dead on arrival:

- **AI chat control of the arrs** — dead. 30+ MCP servers exist for Sonarr/Radarr/Plex/Jellyfin;
  nearly all are ≤15★ one-weekend projects, and the category leaders
  ([mcp-arr](https://github.com/aplaceforallmystuff/mcp-arr), 196★) already won what little there
  was to win.
- **AI recommendations/requests** — saturated.
  [SuggestArr](https://github.com/giuseppe99barchetta/SuggestArr) (1.3k★) owns watch-history →
  auto-request; AI subtitles are solved ([subgen](https://github.com/McCloudS/subgen) 1.5k★,
  [Lingarr](https://github.com/lingarr-translate/lingarr) 847★).
- **AI that auto-fixes the stack** — trust-destroying. Arr API keys are unscoped; release names and
  log text are prompt-injectable; the community's reference disaster is an agent bricking its
  owner's machine. Every mature AIOps tool (HolmesGPT, k8sgpt) converged on read-only.
- **Generic "LLM reads your docker logs"** — commoditized. It is an afternoon of n8n, a recurring
  XDA/dev.to blog genre, and two shipped products with 1★ and 25★.

What survives is the **scheduled, read-only, arr-domain-aware diagnostic**: a nightly checkup that
collects state from every service, runs deterministic arr-specific analyzers over it, and uses an
LLM only to correlate findings across services and write the morning report. That quadrant —
*reads everything, correlates, explains, recommends, never acts* — is genuinely empty, the demand
for it is well-evidenced, and the moat is not the AI plumbing but the encoded tribal knowledge of
how these stacks fail.

## 1. The landscape has a vacant quadrant

The arr companion ecosystem is crowded on the **acting** side and empty on the **diagnosing**
side.

**Crowded — threshold-rule actors.** [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr)
(2.5k★), [Decluttarr](https://github.com/ManiMatter/decluttarr) (864★),
[Swaparr](https://github.com/ThijmenGThN/swaparr),
[qbit_manage](https://github.com/StuffAnThings/qbit_manage) (1.6k★) delete stalled/failed queue
items on timers and strikes. [Maintainerr](https://github.com/Maintainerr/Maintainerr) (2.2k★) and
[Janitorr](https://github.com/Schaka/janitorr) delete unwatched media per rules.
[Unpackerr](https://github.com/Unpackerr/unpackerr) (1.5k★) extracts archives.
Tdarr/Unmanic/FileFlows re-encode nonconforming files.

**Crowded — state convergers.** [Recyclarr](https://github.com/recyclarr/recyclarr) (2.1k★),
[Configarr](https://github.com/raydak-labs/configarr) (644★),
[Profilarr](https://github.com/Dictionarry-Hub/profilarr) (2.6k★) push declared config into the
arrs. None can *report* drift — they overwrite it, and only for the keys they manage.

**Partially covered — notifiers.** [Notifiarr](https://github.com/Notifiarr/notifiarr) is the
closest existing thing: service checks, stuck-queue watching, arr-backup SQLite validation,
dashboard digests. But it is a notification pipeline, not an analyst — per-signal thresholds,
Discord-centric SaaS, no log reading, no cross-service correlation.
[exportarr](https://github.com/onedr0p/exportarr) exposes raw Prometheus metrics; every
interesting alert is one somebody must think to write, and almost nobody does.

**Empty — diagnosis.** No shipped tool: root-causes a stalled download (dead tracker vs VPN vs
provider connection cap vs `_UNPACK_` refusal); notices a job that "succeeded" in name only;
correlates state across services; diffs live config against intent; audits grabs against the
stack's goal; or produces a prioritized assessment rather than a status list. Three 2026-vintage
micro-projects ([auditorr](https://github.com/thrill-burn/auditorr) 43★,
[Mendarr](https://github.com/Necrul/Mendarr) 0★, media-sync-auditor 0★) confirm the demand exists
and that nobody has occupied the space.

Two cautionary tales bound the design space.
[Buildarr](https://github.com/buildarr/buildarr) — the only whole-stack config-as-code attempt —
went dormant in 2023 under the schema-maintenance burden of modeling every arr exhaustively; an
LLM-narrated analyzer approach must not repeat that trap. And **Huntarr's February 2026
collapse** (author deleted repo, site, and subreddit after an unauthenticated auth-bypass leaked
every connected arr API key) set the security bar for any tool holding all the keys on the box;
Notifiarr's [starrproxy](https://github.com/Notifiarr/starrproxy) exists precisely because of that
concern.

## 2. AI tools in this space: the specific niche is untaken

Verified August 2026:

| Category | State | Evidence |
| --- | --- | --- |
| MCP / chat control | Commoditized, mostly abandoned | 30+ repos, ≤15★ typical; polished ones explicitly refuse scheduling ("purely reactive") |
| AI recommendations | Saturated | SuggestArr 1.3k★; the original Recommendarr was deleted by its author |
| AI subtitles | Mature/solved | subgen 1.5k★, Lingarr 847★ |
| "AI brain" agents | Emerging, contested, tiny | [commandarr](https://github.com/braedonsaunders/commandarr) 7★ (active, NL-scheduled automations), hookreel, Arrmate, clawarr-suite — all Feb–Aug 2026, all <15★ |
| **Scheduled arr-aware AI checkup** | **Empty** | [cortex-homelab](https://github.com/pdegidio/cortex-homelab) (1★, 4 commits, exactly this idea) and [homelab-log-analyzer](https://github.com/WhiskeyCoder/homelab-log-analyzer) (25★, dormant) |

The two direct predecessors matter most. Both built "local LLM reads arr logs nightly, sends a
digest" — and both were ignored. Neither shipped *domain knowledge*: no analyzer knows what a
quality profile is, why `_UNPACK_` residue matters, or that Recyclarr can exit 0 while syncing
nothing. They shipped the plumbing anyone can assemble in n8n and skipped the part that is hard to
copy. That is the differentiator or the death of this idea.

Community climate, which any entrant must respect:

- **Local-LLM-first is table stakes.** Every surviving AI project leads with Ollama support; the
  objection to cloud is the API key existing, not the invoice.
- **AI-slop fatigue is sharp.** Jellyfin published a formal LLM contribution policy after being
  flooded with AI PRs; maintainer burnout over AI-PR review contributed to leadership departures;
  r/selfhosted actively mocks "AI slop projects". Engineering quality must be visibly non-slop.
- **What gets praised:** narrow, reliable, toil-removing, local. What gets ignored: broad
  autonomous "AI replaces your stack" pitches.
- **The OpenClaw wave** normalized general personal agents with homelab skills — the plausible
  future where this niche is absorbed by "a general agent + an arr skill pack" rather than a
  bespoke container.

## 3. Why an LLM is actually justified: the failure taxonomy

The load-bearing question for this idea: do the failures that matter need *reasoning*, or just
thresholds? A rules-only gap would mean the right product is a Notifiarr feature request, not an
AI service. The taxonomy says otherwise — the failures people lose weeks to are the ones where
**every individual signal reads healthy and the fault only exists in a relationship** between
services.

| Failure mode | Found today by | Any tool? | Verdict |
| --- | --- | --- | --- |
| Indexer hard-down (auth/DNS) | Health banner, if notifications wired | Arr health → Notifiarr | Rule |
| Indexer quota exhausted / VIP expired — searches quietly thin | "Nothing downloaded for a week" | None (Prowlarr skips "gracefully", no warning) | **Reasoning** |
| Stalled queue items | Checking the queue | Notifiarr, Decluttarr (deletes) | Rule |
| Completed download missed (arrs scan only last 60 history items) | Never appears; manual re-search | None | **Reasoning** |
| `_UNPACK_`/`_FAILED_` residue never imported | Manual disk inspection, weeks later | None | Rule to spot, **Reasoning** to triage |
| Disk filling | Import failures / SAB pause | Netdata/Notifiarr thresholds | Rule (diagnosis: Reasoning) |
| Hardlinks silently copies, disk doubling | Disk audit months later | None | **Reasoning** |
| Profile/CF drift → DTS/TrueHD/PGS/AV1 grabs | Playback transcodes; library audit | None — an imported remux is a *success* to Sonarr | **Reasoning — strongest case** |
| Recyclarr silent no-op (exit 0, synced nothing) | Via the drift it allowed, or never | None (Healthchecks.io sees exit 0) | **Reasoning** |
| TVDB runtime-0 blocks every grab for a series | One show never downloads; log spelunking | None | **Reasoning** |
| Bazarr providers throttled | Missing subs pile up | exportarr metric exists | Rule |
| Provider silently dropped from config on update | Much later | None | **Reasoning** (config diff over time) |
| VPN dead, all torrents stalled | Days later | Gatus egress check possible | Rule (diagnosis: Reasoning) |
| Jellyfin transcoding instead of direct-play | Buffering complaints, fan noise, CPU | Jellystat records, nothing alerts, nothing explains *why* | **Reasoning — second-strongest** |
| API/auth breakage after image update | Health banner / sudden 401s | Arr health checks | Rule detect / Reasoning attribute |
| DB corruption (soft) | "Sonarr stopped updating" | Kuma keyword (hard case only) | Rule+ |
| Wrong default-audio policy (mux lies, user gets Danish) | Family complaint | None | **Reasoning** (policy audit) |

Roughly half the taxonomy — including the highest-cost rows — needs correlation and
intent-comparison no rule-based tool ships. The two strongest cases (profile drift and transcode
root-causing) both require comparing observed state against *intent that lives in prose*, which is
exactly the LLM-shaped part.

**This repo is its own evidence.** Every entry in CLAUDE.md's Operational Traps was found by
agent-assisted investigation, not by Uptime Kuma or an arr health banner: the Recyclarr
duplicate-instance no-op, the `_UNPACK_` import refusal, the six-`default=1` Danish-audio mux, the
TVDB runtime-0 rejections, the Bazarr provider drops, the TheIntroDB shutdown-path crash. And the
sharpest datapoint: **Maintainerr — the maintenance tool — sat silently dead in this stack from
May until August** before an audit noticed. The stack already has availability monitoring
(Uptime Kuma), alert routing (ntfy/Discord split), and config convergence (Recyclarr). What it
demonstrably lacks is the thing this idea proposes.

## 4. Architecture that survives contact

Prior art converges hard. k8sgpt (CNCF, the mature reference) uses **deterministic analyzers
first, LLM second** — coded checks detect, the LLM only explains and prioritizes, which is
explicitly its hallucination defense. HolmesGPT's agentic loop is the other pole, but small local
models can't drive an agent loop reliably, and a nightly batch doesn't need one.

1. **Collectors (deterministic).** Per-service API pulls: arr `/health`, `/queue`, `/history`
   grab-vs-import deltas, Prowlarr indexer stats, SABnzbd queue/warnings, Bazarr provider status,
   Jellyfin sessions + playback method, Uptime Kuma's SQLite heartbeat table — plus
   `docker logs --since 24h` through a regex noise filter (both predecessors independently proved
   this filter is mandatory; arr logs are dominated by ffprobe spam and 429s). Output: a compact
   structured findings document, 5–20k tokens, not 200k of raw logs.
2. **Analyzers (deterministic, the moat).** Encoded arr tribal knowledge: aged `_UNPACK_` dirs
   joined against the wanted list; import events logged "copy" where "hardlink" was expected;
   live CF scores diffed against recyclarr YAML; recent imports' audio/subtitle streams checked
   against the direct-play policy; per-series repeated-rejection aggregation (runtime-0);
   provider-list diff against yesterday's snapshot; grabs-trend vs wanted-trend. These detect;
   they cannot hallucinate. This layer is the entire defensible value — it is this repo's
   CLAUDE.md turned into code.
3. **LLM correlation + narration.** One bounded, JSON-schema-constrained call (or one per service
   for 7B-class models) that ranks findings, joins them across services ("Bazarr throttling and
   the Sonarr import failures share a root cause"), and writes the report. Backend-agnostic:
   Ollama-compatible first-class (Qwen 7B-class with grammar-constrained output is reliable;
   3B is below the floor), Anthropic/OpenAI endpoints as opt-in upgrade.
4. **Delivery.** Morning report to ntfy/Discord/email + a static HTML page. A quiet night is one
   line — digest fatigue killed interest in both predecessors, so "boring when healthy" is
   product-critical, not polish.
5. **Remediation posture.** v1 strictly read-only, enforced in the tool's own client layer (arr
   keys are all-or-nothing) and stated loudly. v2 at most: proposed fixes as copy-pasteable
   commands. Unattended writes: never — that is where Huntarr-grade trust destruction lives, and
   prompt-injectable release names sit inside the LLM's context.

**Cost is a non-issue.** Nightly analysis at 50–200k input tokens: local Qwen on existing
hardware $0; GPT-5-mini-class ~$0.70–1.80/month; Claude Haiku-class ~$2.25–6.75/month, halved by
batch endpoints (an overnight job has no latency requirement) and cut further by prompt-caching
the stable analyzer/rules prefix.

**Distribution reality**, if this ever productizes: Unraid Community Applications template +
[awesome-arr](https://github.com/Ravencentric/awesome-arr) PR + one strong r/selfhosted launch
post. linuxserver.io images and TRaSH-guide mentions are unattainable at launch. Single container,
PUID/PGID/TZ conventions, no telemetry, no account, works without a cloud key.

## 5. Risks and kill criteria

1. **"An afternoon of n8n" competition.** The plumbing is commodity; two predecessors have 1★ and
   25★. *Kill if* the analyzer layer can't demonstrably catch things a generic log-LLM misses.
2. **Noise fatigue.** A digest that cries wolf is uninstalled in a week. *Kill if* after tuning
   against a real stack, more than ~1 in 5 flagged findings is noise.
3. **Trust/security bar.** Holds every API key → held to the standard Huntarr failed. Read-only,
   local-first, no telemetry, visible engineering quality (the Jellyfin-policy climate applies).
4. **The general-agent wave.** commandarr and OpenClaw-style skill packs could absorb this niche —
   "checkup" becomes a skill for an agent people already run, not a container. This is the most
   plausible way the *product* dies while the *idea* wins. Hedge: the analyzer corpus is the
   portable asset; it works equally as a bespoke container's rule set or as a skill pack.
5. **Schema burnout (the Buildarr lesson).** Don't model the arrs exhaustively; collect narrow
   slices per analyzer and let the LLM absorb API variance in prose.

## 6. Recommended next step

Skip the product question for now and **prototype against this stack**, which is an ideal test
bed: eight services, real history of silent failures, and a written intent (the direct-play goal)
for analyzers to check against. The cheapest possible MVP is not even a container — it is a
scheduled agent session pointed at this repo, whose CLAUDE.md already encodes the domain
knowledge, with a prompt of the form "run the checkup, compare state against intent, write the
morning note to ntfy." The docs here already anticipate exactly this
(`docs/uptime-kuma.md`: "useful if you have an agent or script auditing the stack on a schedule").

Validation gate for the prototype: run it retroactively-style for two weeks and score it against
the known trap list — would it have caught the dead Maintainerr, the Recyclarr no-op, a planted
`_UNPACK_` folder, a planted DTS grab? If it catches most of those with near-zero noise, the idea
graduates: extract the analyzers into a proper container (or skill pack) and take it to the
community. If it can't beat the traps this repo already documented, kill it — the landscape says
nobody else has solved it either, but that's only an opportunity if the detection actually works.
