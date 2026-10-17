# Offline teammate feedback

The offline tester candidate opens all sixty task entrances. It retains ordinary
simulation and earned-completion authority and uses the separate `OfflineTeammate`
profile. The existing `CloudPlaytest` and campaign saves are not migrated.
Hardware tasks have a clearly marked temporary reference component library so
missing prerequisites do not block direct testing. Player components take
precedence. References are not saved as player creations, and a circuit using
them cannot create earned completion or sealed player evidence.

## Tester workflow

F8 and the persistent bottom-right feedback button work from launch, task maps
and workbenches. Existing task feedback buttons open the same offline panel.
The game pauses while feedback is open. A clean game viewport frame is captured
before the panel appears. Notes save as they change; the ready marker is optional.
History reopens an earlier incident without changing its original scene.

Export all feedback creates one ZIP and reveals it in the file manager. Exports
are verified before success is shown and never consume originals.
Normal quit and restart retain earlier incidents and local sessions. A later
export includes both earlier plays and the new play's feedback and screenshots;
the tester need only send that final ZIP.
Save ZIP as selects another writable location, including when the default export fails.
Storage failures are visible; preserve the open note and use the rescue export
before closing. Physical storage loss cannot be prevented by an application.

## Evidence and persistence

`user://offline_playtest/cases/<random-id>/` retains original `case.json`,
`context.json`, optional `screenshot.png` and an append-only `notes.jsonl`.
Each note record is flushed and read back before success. Interrupted journal
tails remain raw evidence; a new complete record starts on a separate line.
Restart reads the last complete record. Failed initial captures remain under
`pending/` and are included under `recovery/` in an export.
If note storage fails, a successful rescue export includes the open text,
in-memory screenshot and context as a separate incident. Damaged local incidents
remain raw recovery evidence rather than blocking other usable incidents.

The allowlisted context includes current unsaved edits, designs/circuits,
program text, model parameters, run traces/results, playback position, core
memory state and candidate session data across nine workbenches. `coverage`
records unsupported fields and truncation (262,144 characters per snapshot
string, 20,000 items per snapshot collection and nesting depth 24). The screenshot
is the game viewport that has focus. A screenshot failure remains explicit.
This is diagnostic evidence rather than universal deterministic UI replay.

An export additionally retains all local playtest session JSONL files, legacy
opinion drafts, the current allowlisted game save files and game logs. Raw saved
files and current memory context are separate: a memory snapshot is not proof
that the design was previously saved. No remote outbox, deletion secret,
installation identity file, environment variables or arbitrary desktop files
are collected. No screenshot/context is added to the remote upload whitelist.

The ZIP manifest uses `format=vnb-offline-playtest`, `version=1`, a random
`bundle_id`, UTC creation time, build identity and every evidence file's relative
path, byte count and SHA-256. Export materializes the latest case metadata while
retaining its note journal. Limits are 64 MiB per file, 1 GiB expanded total and
9,999 evidence entries. Errors retain local records; failed temporary exports
are removed, with their path shown if cleanup itself fails. There is no automatic
retention deletion. Keep originals until review and backup are complete.

## Maintainer workflow

Python 3 and the standard library suffice. From the repository root:

```powershell
python scripts/offline-playtests.py import teammate-a.zip teammate-b.zip --library feedback-library
python scripts/offline-playtests.py report --library feedback-library --output feedback-library/review.html
```

Open `review.html` locally. Search and filter by task, category and build; inspect
screenshots, notes, context and original ZIPs. Repeated imports deduplicate exact
bundles. Different exports of an incident preserve history and display its newest
note revision. Original ZIPs and extracted evidence remain under `bundles/`.
The companion action analysis separates sources/build/task versions and merges
repeated session events by their session/sequence identity. Incomplete or malformed
records are not treated as measured zero-duration visits.

Only explicitly manifested regular files are accepted. Import rejects unsafe or
duplicate paths, links, corruption, unlisted entries, excessive sizes, inconsistent
case metadata and conflicting bundle identities before committing the batch.
Keep the entire library when moving reports so screenshot/context links continue
to work. These files may contain testers' designs and written text; this offline
workflow publishes nothing and performs no automatic upload.

## Build and verification

Use the pinned Godot 4.7.1 Windows engine/template, a fixed forty-character commit
and `scripts/build-free-candidate.py --offline-tester --platform Windows
--second-act-profile OfflineTeammate --creation-journey --test-batch <batch>`.
The builder requires an empty endpoint and rejects public/localhost receiver
flags. It freezes build identity and hashes and includes tester/maintainer guides.
The manifest's `public_release` selects the existing network-enabled public
playtest profile; it stays false for this offline tester. Authorized distribution
of the offline ZIP is recorded separately by the GitHub release/tag and receipt.
Neither distribution nor that field establishes a working cloud receiver.

Focused suites are `test_offline_store`, `test_offline_context`,
`test_offline_feedback`, `test_offline_tester_navigation`; Python runs
`scripts/test-offline-playtests.py` and `scripts/test-candidate-packaging.py`.
The UI suite renders both languages with `-- --offline-feedback-capture`.
The isolated package acceptance controller checks actual scene entry for every
task, screenshots, notes, restart and export/import. Native Windows input remains
a separate acceptance check, as does understanding by a new human tester.
