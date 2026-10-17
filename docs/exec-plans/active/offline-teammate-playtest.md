# Offline teammate playtest

## Goal and scope

Provide a Windows tester candidate with all sixty task entrances available, a
global feedback entry, durable screenshots and game context, a single-file
offline export, and a maintainer importer/report. No network, VPS, accounts or
public release are required. Existing simulation, earned completion, saves,
remote feedback whitelist and frozen packages remain compatible.

## Design

- An independent `offline_playtest` store retains per-incident game viewport
  screenshots, JSON context and autosaved notes. Captures are taken before the
  panel appears. Capture/storage errors remain visible; exports never clear data.
- ZIP bundles use `format: vnb-offline-playtest`, `version: 1`, a random
  `bundle_id`, UTC creation time, build identity and a `files` array of
  `{path, size, sha256}`. Incident folders are `cases/<32-hex-id>/` containing
  `case.json`, `context.json`, and `screenshot.png` when rendering is available.
  Case metadata includes id, captured_at_utc, category, note, task and screenshot
  status. The manifest is `manifest.json` and does not hash itself.
- Export also carries the current game context and all local playtest JSONL
  sessions, existing local opinion drafts and diagnostic game logs. Credentials,
  remote outbox/identity and unrelated desktop/files are excluded.
- The Python maintainer tool validates hashes, paths and bounded ZIP sizes,
  preserves originals, deduplicates bundles and produces an escaped local HTML
  report with screenshots, notes, task/build filters and context downloads.
- An explicit offline tester build flag bypasses entrance prerequisites only.
  It uses an isolated tester save profile, has no endpoint, and retains honest
  completion and model constraints.

## Ownership and verification

Controller owns Git, Godot/native execution, offline store/UI, project autoload,
localization and final documentation/evidence. Delegated work has disjoint files:
task access/build tooling; Python importer/tests; context collector/tests.

Verify ordinary lock behavior and all sixty tester entrances, snapshot coverage,
PNG rendering, autosave/restart and export/reimport/dedup/corruption handling.
Then run full regression, freeze a fixed source and verify the actual Windows
binary's offline screenshot/export/import flow. Keep before/after observations
and exact verification limits. Existing player profiles are never QA inputs in
place. Source starts at main `5f855b6`; an authorized live fetch confirmed that
remote baseline before implementation.

## Progress

- 2026-10-17: inspected current local main and existing feedback/navigation/build
  contracts. Current short opinions lack screenshots and complete offline cases.
  Initial contract committed as `d1798d8`.
- Implemented context/import/report (`ebd5c0e`), append-only incident storage and
  global screenshot UI (`12ed8f7`), and full tester entrance/build tools
  (`fc5f7de`). Follow-ups constrain saved-file exports and preserve map feedback's
  explicit target. All changes are committed, with PR10 open as a draft.
- Windows focused suites passed6/6 including import/isolation. Chinese/English
  720p rendering passed. Actual source renderer entered all60 tasks; three real
  screenshots/notes survived an independent process restart. Both ZIPs imported
  successfully as3 cases/6 exported revisions, with original packages preserved.
  Python importer9/9, existing reporter and packaging tests pass. Independent
  audit confirmed exact hashes and no unsupported/truncated fields in the three
  representative snapshots.
- Full Windows regression and remote CI are running. Final fixed EXE capture,
  native input, artifact identity and delivery receipt remain pending.

## Limits

Captures are diagnostic evidence, not a promise of deterministic replay of every
UI frame. Unavailable renderer/snapshot fields must be explicit. Export is a
deliberate sharing action and may contain player's designs and written text.
