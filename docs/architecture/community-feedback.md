# Offline-first community preparation

The 40-task game, deterministic simulators, receipt validation and local unlock
rules are unchanged. `PersonalRecords` observes locally verified official results
through a separate signal, even when action telemetry is disabled. Its bounded
journal is presentation-only; it cannot grant progression. Existing saved Chapter 4
best designs are evaluated locally for the internal journal. Older unrecorded metrics
remain absent. Named circuits and layout designs plus Chapter 3 drafts are counted from
local files; reading task records does not migrate those files.

Task record summaries consume `region_title_key`, `record_metrics` and `bonus_goals`
from TaskNavigation metadata. They do not use a fixed region or bonus count. Circuit
records retain verified case counts; systems retain cycles/cost, and layout retains cycles,
reads/writes and peak scratch. The visible personal board now shows completion totals
and region cards only, following the owner's latest UI direction. Task details and
individual feedback remain on the task tree. No receiver means no community widgets or HTTPRequest.

## Data and authorization

`RemoteFeedback` persists its existing outbox path with schema 2. Upgrading schema 1
keeps deletion identity but requires a fresh notice choice; stale queues are not
uploaded. A changed endpoint string disables automatic and score consent and drops
old pending destinations on reload. Normal builds have no configured endpoint.
The origin-root form is backward compatible; `/v1` roots never get `/v1` appended twice.

| Choice | What can leave the device | Trigger |
|---|---|---|
| Local only | Nothing automatically | Default |
| Basic statistics | Ended-visit summary, completion, a selected moment category without its note | Visits begun after consent |
| Detailed playtest | Basic summary plus whitelisted edits, runs/cases, timing, hints and map actions | Future events after explicit choice |
| Opinion | That saved rating and up to 240 characters | Separate Send for this opinion |
| Experimental score | Two verified local capstone case metric sets, rule/model/case/build versions | Separate score consent AND Submit |
| Public design | Nothing | Unsupported; no upload method |

Notice `2026-09-11`, consent `sharing-2`, UTC consent time, configurable nonpersonal
`application/feedback_source_batch` (default `free-alpha`) and optional fixed
experience cohort accompany new records. Source (`external_player`, `agent_native`,
`automated`, `developer`, `unknown`) and Game/Test remain separate. No account,
identity, names of saved designs, full circuit/program, input text, pointer path,
clipboard, screenshot or filesystem path enters the transport. Existing
content digests are bounded diagnostic identifiers, not uploaded designs.

Switching statistics tiers drops pending automatic records; withdrawing score consent
drops pending scores. Opinions already explicitly queued remain independent until
Delete All. Delete All turns both choices off, clears queues, persists the deletion
request through offline restart, and waits asynchronously for confirmation. Confirmed
delete retires that random identity; a later explicit consent creates a new one.
Exit finalizes a visit while the outbox still exists and cancels HTTP without waiting.

## Visit meaning

`visit_summary.gd` reduces semantic transactions. Foreground/background/feedback time
come from existing monotonic checkpoints. Interrupted visits retain measured segments
and `duration_unknown=true`; offline hours are not assigned to play time. Completion
comes from the local progress snapshot on entry and any completion during this visit,
never a server unlock. Turning local recording off closes the measured visit;
turning it back on starts a new segment instead of counting unrecorded time. Empty/missing old
visits are not backfilled. Branch replacement edges do not inflate connection counts;
component incident wires are separate from explicit wire erasures. Undo/redo are
separate, official runs are distinct from cases and debug requests. Cases carry finite
metrics; unavailable metrics remain absent, not zero. Rejections count attempted
release on an incompatible port once, not hover checks or cancelled empty-space drags.

## Community protocol v1

Existing POST `/v1/events` accepts bounded `event`, `feedback`, `score` records;
DELETE `/v1/data` removes all three. The existing envelope, owner deletion token,
ack-after-commit and event-ID/content conflict detection remain intact.

GET `/v1/community/tasks` returns only current manifest task versions, defaulting to
`source=external_player&mode=game`; test/developer samples require explicit filters.
Starts count received ended-visit summaries, not every player who ever opened a task.
Each installation/visit contributes once. With fewer than five installations, counts
remain visible but percentages, medians, Hint and strategy distributions are hidden.
These are consenting installations and repeat visits, not people or population rates.

GET `/v1/leaderboards?level_id=chapter_4%2Fmixed&ruleset_version=layout-mixed-1&model_version=layout-memory-1&case_set_version=<manifest hash>`
returns up to 50 installation-best rows. Rule versions cannot mix. Two official cases
must pass; phases sum to each case, cases to total; read lines are 16 B multiples,
writes/space 4 B multiples; target and scratch bounds apply. Conservative logical-read
floors are 280 and 126 cycles (no copying/output assumed in these lower bounds).
Plausible totals below 1000 are held for review, not labelled cheating or verified.
A 12-score/minute/identity limit supplements bounded IP/body/batch/storage limits.
Bounded raw score receipts remain for the retention period to permit deduplication and
review; only the best eligible row appears publicly. Board-scoped aliases exclude
installation IDs and notes. No prizes, ranking-based unlocks, server Godot or replay.

`server/community_rules.json` is exported from the current development catalogs by
`scripts/export-community-rules.gd`; update and review it whenever these rules change.
The deployed receiver reads the JSON only. A future trusted verifier belongs behind
this result-validation boundary and would require a separate product decision.

See [operator runbook](../../server/deploy/RUNBOOK.md) for schema migration,
backup/restore, tombstones, DNS cutover, retention and later deployment prerequisites.
