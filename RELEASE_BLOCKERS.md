# Release acceptance gates

Current source and artifact: [CURRENT_STATE](docs/CURRENT_STATE.md).
These are remaining acceptance requirements, not instructions to add features.

## Current candidate — 2026-10-11

The sixty-task candidate includes the original core, Representation, Service,
optional address Prediction and C/P/G. Main contains the integrated runtime;
Mac and Windows packages are frozen at `efda8b84ae6e`. Final integration CI passed
152 suites, import/user isolation and seven Python checks. Actual exported Mac
binary → local HTTP → SQLite → private report/triage, save/reopen, retry/deduplication,
delete and restored tombstone checks passed within the recorded local scope.
[Exact receipts and limits](docs/verification/20261010-cloud-playtest/README.md).

| Gate | Status and required evidence |
| --- | --- |
| Real VPS staging feedback | **NOT_RUN.** Use only authorized existing staging through an SSH tunnel. Confirm an actual test package's synthetic receipt ID, task and build in remote SQLite and the private report, including retry/deduplication and delete/restore. Localhost success does not establish this. |
| External feedback entry and public release | **Deferred.** No public deployment in the current authorization. A future owner decision must specify the entry, privacy/retention/backup configuration and release scope. |
| Current Mac native interaction | **NOT_RUN for the frozen round package.** The screen was locked; earlier native routes retain their own build attribution. Operate this package's navigation, editing, unfinished-task feedback, save and restart. |
| Windows native execution | **NOT_RUN for the current candidate.** Actual EXE start, task entry, editing, feedback, save/restart, focus and DPI are required. Export success is insufficient. |
| Other Mac / installation / signing | **Open.** Candidate is unnotarized; verify download, first launch and save on another machine, then choose formal signing/distribution requirements. |
| Display and focus | **Open.** Extended small-display/Retina/mixed-DPI and repeated focus loss during drag sessions require direct evidence. Earlier capture anomalies remain attributed to their recorded builds. |
| Unfamiliar-player understanding | **Open.** Unassisted entry, task choice, Hint comprehension, full-route pacing and concrete feedback. Known-answer replay and agent observations do not establish this. |
| Listening and artistic acceptance | **Open.** Independent listening and visual/narrative review of core and creative endings remain separate from technical checks. |

All forty original tasks repeated natively are additional coverage, not a mandatory
development gate. Existing original-core, Representation/Service and C/P/G native
observations are retained in their [dated verification records](docs/README.md).
They do not combine into a fabricated fresh full-route run.

Missing remote-access configuration belongs in the private local handoff. Do not
publish credentials, infrastructure targets or raw player data. Offline refusal or
network failure must continue to leave the game usable; opinions and statistics
require separate consent under the [feedback contract](docs/architecture/community-feedback.md).
