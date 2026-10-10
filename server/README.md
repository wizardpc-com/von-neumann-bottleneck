# Local feedback integration (not a public deployment)

The optional client is off by default. The free candidate has no receiver URL and never uploads automatically. Local feedback/export and simulation work offline. `PlaytestData` v2 remains the source; the transport observes only future allowlisted events after consent. Freeform opinions require the player's separate **Send the opinion I just saved** action. No historical log scan, names, circuit/program source, screenshots, search text, clipboard, account or device path is sent.

A random installation ID scopes deduplication and deletion; it is not a claim of absolute anonymity. Feedback carries task, visit when known, source category, build/model/case versions, optional ratings and at most 240 characters. Metrics are observations, never leaderboard authority. Unknown ratings stay null. The endpoint is displayed in the UI. Changing receivers invalidates automatic consent and old queue destinations do not silently move to the new receiver.

## Shared VPS deployment preparation

The owner has selected a mainland China VPS. Use the [Ray VPS contract](../docs/distribution/ray-vps.md) and standalone `deploy/compose.vps.yaml` for its staging/prod port and data separation. The original Compose remains a standalone local example. No remote deployment or public endpoint activation occurred in this update.

## Local setup

Python 3.9+ standard library; no packages required:

```sh
python3 server/feedback_server.py --port 8765 --database .godot/local-feedback/feedback.sqlite
```

In an **isolated test project only**, set `application/feedback_endpoint="http://127.0.0.1:8765"`. The normal project intentionally omits this setting. In Game open F8 → Optional sharing and data settings. Opt-in automatic sharing and explicitly sending an opinion are separate. Do not add real player logs to tests or Git.

`python3 server/test_receiver.py` checks actual HTTP validation, idempotent IDs including JSON numeric roundtrips, conflicting bodies, bounded batches/text/body, authenticated reporting, deletion scope, retention and SQLite backup restore.

After importing an isolated verification copy, run:

```sh
python3 scripts/verify-feedback-local.py --godot /path/to/Godot --project .godot/verification/RUN/project
```

The helper assigns a unique userdata directory, starts with the receiver offline, runs the actual model and persists the Godot queue, exits, starts the receiver and resumes the queue in a second Godot process. It verifies SQLite contains one event despite retry plus one explicitly sent opinion while automatic sharing is off. The server binds only loopback; all data is synthetic.

## Bounds and receipts

Client: 256 pending records, 512 KiB state file, batches of 32 or about 45 seconds, 8-second HTTP timeout, 128 KiB body limit. Exponential retry is capped at 300 seconds and pauses after eight failures. Permanent rejection pauses immediately. Only an acknowledged ID is removed; no receipt means pending, not success. State writes use temporary file + rename. The queue stays out of gameplay saves. Turning sharing off cancels the active request and discards pending automatic events; explicitly requested opinions remain pending until cancelled by deletion. A request already committed remotely cannot be unsent; deletion is a separate confirmed action.

Server: 128 KiB requests, 32 records/batch, strict field/type/length whitelist, 120 requests/minute per connection IP, 100,000-event storage ceiling, 5-second socket timeout. SQLite transaction commit precedes acknowledgement. Event ID + owner + canonical body makes retry idempotent; conflicting reuse is rejected. A per-installation deletion token is stored hashed by the receiver. This token scopes deletion, not verified identity or anti-cheat.

The storage ceiling counts new IDs only: an already committed identical retry can
still receive confirmation at capacity. Exact duplicate IDs in one bounded batch
are acknowledged once; differing content with the same ID returns a conflict.

## Private analysis, retention, backup

Set `VNB_FEEDBACK_ADMIN_TOKEN` in the server process environment to enable `GET /admin/report` with `Authorization: Bearer ...`. Without it the report is unavailable. Never put this token into the game or Git. The endpoint returns counts only; raw opinions remain in the access-controlled database. `server/private_report.py` produces a local report file for the operator, suitable for an operator-scheduled daily job; it does not open a public dashboard.

Events older than 30 days are deleted at startup and hourly during traffic; clients without records are removed. For an idle server, restarting performs retention cleanup. The operator must apply the same 30-day policy to backups. Access logs deliberately omit bodies, tokens and IPs. Any future proxy logs need their own reviewed retention rules.

For a consistent live backup, use SQLite's backup API (not a raw copy of just the main file while WAL is active):

```python
import sqlite3
with sqlite3.connect('feedback.sqlite') as source, sqlite3.connect('backup.sqlite') as target:
    source.backup(target)
```

Restore with the receiver stopped, retaining a separate safety copy first. Check `PRAGMA integrity_check` and inspect counts before restart. Backups and generated reports may contain opinions; keep them private and apply deletion/retention to them too. Deletion in the game confirms only the live receiver database, so public deployment must specify the backup deletion process before launch.

## Explicitly not deployed

No domain, public port, hosting account, payment, Steam upload or identity submission. Public operation requires separately approved HTTPS termination, deployment region, proxy/access rules, operator credentials, backup access and retention, current privacy wording and load/security review. This bounded single-process loopback server is the local integration implementation, not a claim of public production readiness. Rankings, workshop identity and uploads are outside this scope.

## Portable community preparation (2026-09-11)

The receiver now migrates legacy databases to schema 2, retains deletion tombstones,
and accepts explicit experimental score submissions. Read-only community endpoints
are versioned and source-separated. No Godot runtime, real credentials, public domain
or deployed host is included. See [architecture and field inventory](../docs/architecture/community-feedback.md)
and [operator runbook](deploy/RUNBOOK.md). `storage.py` provides backup, restore,
check and conflict-refusing idempotent merge. Run `test_storage.py` and
`test_community.py` alongside the existing receiver checks.

## Summary/report convergence

Basic visit summaries are now consumed by `private_report.py` through the same local
report implementation. Reports keep version/cohort rows separate, do not double count
detail plus summary totals, and distinguish first completion from repeat visits.
Community task responses retain a `versions` array; mixed versions have no aggregate
completion percentage or median. See [maintenance](../docs/development/final-maintenance.md).

## Current journey reception and private review

`community_rules.json.content_manifests` accepts the preserved
`tasks-20260910-v1` forty-task manifest and the explicit
`tasks-20261010-journey-v1` sixty-task manifest. A visit summary must declare a
supported version and a task in that version. A versioned opinion uses the same
check. Authored `identities` in a manifest additionally require exact model/case
versions for the new domains; mismatches return fixed model/case error codes.
Historical unversioned opinions remain `legacy_unknown`, rather than
acquiring the current version. Unknown versions and mismatched historical rows
are visible in the private report's quarantine and excluded from task metrics.
Build, source commit, test batch, model and case identities stay separate.
`category` is opinion-only and optional (`confusion`, `control`, `bug`,
`audiovisual`, `discovery`, `other`); a selected category can be sent without text
or ratings. It does not authorize automatic statistics or content uploads.

Generate a private report and create a local review record using the stable
server-confirmed feedback ID:

```sh
python3 server/private_report.py --database /private/path/feedback.sqlite \
  --output /private/path/report --triage /private/path/private-triage.sqlite
python3 server/private_report.py --database /private/path/feedback.sqlite \
  --triage /private/path/private-triage.sqlite \
  --set-status SYNTHETIC_FEEDBACK_ID needs_review
python3 server/private_report.py --database /private/path/feedback.sqlite \
  --triage /private/path/private-triage.sqlite \
  --set-status SYNTHETIC_FEEDBACK_ID needs_retest \
  --fix-build FIX_BUILD --fix-commit FIX_COMMIT --review-note 'Synthetic reproduction'
```

Review states are `needs_review`, `reproduced`, `needs_information`, `fixed`,
`needs_retest`, `deferred`. No new HTTP administration endpoint or receiving
schema is introduced. The optional sidecar stores ID-linked review notes, not
copies of player opinions. Report JSON `received_feedback` and its escaped HTML
table show each stable ID, actual task/build/source/batch and current review.
Client sequence reuse cannot deduplicate distinct database IDs. Generated files
and sidecars have owner-only file permissions; operators must choose a private
directory and never serve or commit them. Keep their retention in sync with the
receiving database.

After deletion or retention, run `--purge-triage` with the current database and
sidecar; this removes review notes whose feedback no longer exists. Reports never
show sidecar notes for absent feedback. Restore old receiving snapshots only after
merging the newest deletion tombstones, then purge and regenerate the report.
That ordering also applies when restoring an older sidecar.

HTTP validation failures return only a bounded fixed `reason` code, never the
rejected note/body. Private `/admin/report` rejection counters are explicitly
process-lifetime observations, reset on receiver restart. The offline report
marks persistent rejection counts unknown; SQLite never contains rejected bodies.

Additional synthetic checks (operator runs locally; not remote-deployment proof):

```sh
python3 server/test_delivery.py
python3 server/test_private_report.py
```

The delivery check exercises real HTTP, lost-confirmation retries across receiver
restart, transactional read-only/disk-full failures and deletion-safe restored
snapshots. The report check covers stable-ID review, reused client sequences,
HTML escaping, version quarantine and sidecar purge after tombstone merge.
