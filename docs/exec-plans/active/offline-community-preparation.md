# Offline community preparation

Approved scope, 2026-09-11. Extend the existing receiver, durable outbox and local
records; preserve all 40 tasks, progression authority and deterministic simulators.
No purchases, accounts, real endpoint, public deployment or server-side Godot replay.

## Stages and gates

1. Versioned SQLite migrations, deletion tombstones, safe backup/restore/merge,
   environment configuration and portable deployment examples. Synthetic HTTP tests.
2. Future-only basic visit summaries versus detailed telemetry; independent opinion
   and score choices, versioned consent metadata. Durable withdrawal and endpoint
   boundaries. Test semantic edits, focus timing, restart and local-only operation.
3. Read-only personal task records, versioned community aggregates and bounded
   experimental capstone boards. Server data never grants progress. Test small
   samples, versions, score consistency, deduplication and deletion.
4. Client/server loopback end-to-end checks, native UI iteration, Windows display
   configuration review, documentation and staged commits. Public endpoint stays empty.

## Decisions

- Retain legacy `/v1/events` and `/v1/data` protocol support. The client accepts an
  explicit versioned root; changing its configured string requires consent again.
- SQLite remains sufficient; no new service dependencies. Migrations are sequential
  and transactional. Merge refuses identity/event conflicts; tombstones win.
- Initial score scope is Chapter 4's mixed capstone, with authored rule versions and
  finite metrics, not an unverified generic score field. Results remain experimental.
- Optional background cohorts use fixed categories; no identity or free-text cohorts.
- Public designs remain unsupported and cannot be consented or uploaded.

## Progress

- Baseline: main 8eee3b3, only two user-owned downloaded plan files untracked.
  Existing local v2 events and receiver reviewed; no player data modified.

## Remaining acceptance boundaries

Native candidate playthrough, Windows real-machine acceptance and external novice
comprehension remain separate from development tests. Deployment requires the
owner's later domain/DNS/HTTPS/privacy/public-release decisions.

- Stage 1: schema v2 migration, complete SQLite backup/restore/merge and deletion
  tombstones implemented. `server/test_receiver.py` (2 HTTP tests) and
  `server/test_storage.py` (2 migration/conflict/restore tests) pass 2026-09-11.
  Loopback Compose, Caddy and systemd examples supplied; Docker/Linux execution
  remains a later host check, not represented as performed.

- Stage 2: basic/detailed/local choices, per-send opinion consent, separate score
  choice and disabled public designs; notice/version/time/batch/cohort metadata.
  Added semantic visit reducer, system editor undo/rejection/delete coverage and
  durable deletion retry. Basic sharing excludes visits begun before consent.
  Initial isolated full regression passed all 27 conventional suites; targeted new
  `test_visit_summary.gd` passes branch/delete/time/case-count/privacy boundaries.
  Final expanded integration and native UI checks remain below.

- Stage 3: personal task record page, telemetry-independent official result journal,
  read-only community API and one versioned experimental capstone board implemented.
  `test_personal_records.gd` passes with telemetry disabled and unchanged progression.
  Receiver/community contract tests pass, including an empty-query Python 3.9 fix.
  Real four-process client loopback passes queue → resume/deduplicate → offline
  deletion → resumed deletion. Evidence: `docs/verification/20260911-community-preparation/loopback-result.json`.
  No server replay or public endpoint used. Native presentation review follows.
