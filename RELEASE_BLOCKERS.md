# Release acceptance gates

Current source and artifact: [CURRENT_STATE](docs/CURRENT_STATE.md).
These are remaining acceptance requirements, not instructions to add features.

## Current candidate — 2026-10-12

The sixty-task candidate includes the original core, Representation, Service,
optional address Prediction and C/P/G. Main contains the integrated runtime;
The latest unmerged review branch freezes Mac and Windows packages at
`61edc8063078`; main remains `cfdee8a`. Windows isolated155/155 checks and
code CI38206327893 passed. Actual Windows EXE → private HTTPS → VPS SQLite →
private report, retry/deduplication, delete and actual tombstone-safe restored
receiver checks passed. Windows native tutorial editing, earned completion and
two save/draft restarts passed. [Exact receipts and limits](docs/verification/20261012-pre-release/README.md).

| Gate | Status and required evidence |
| --- | --- |
| Real VPS staging feedback | **PASS within private synthetic scope.** Actual Windows package over verified HTTPS/Windows SSH, same-ID/task/build remote report, retry/deduplication, deletion and a restored receiver returning410 for deleted identity. Dedicated staging stopped; other services and historical database unchanged. Public player intake remains separate. |
| External feedback entry and public release | **Deferred.** No public deployment in the current authorization. A future owner decision must specify the entry, privacy/retention/backup configuration and release scope. |
| Current Mac native interaction | **NOT_RUN for the `61edc8063078` package.** Earlier native routes retain their own build attribution. Operate this package's navigation, editing, unfinished-task feedback, save and restart on a Mac. |
| Windows native execution | **PASS within representative scope.** Frozen EXE start, tutorial editing/completion, local feedback typing/save, two independent restarts and fullscreen/windowed observation. Later-region native full-route, extended focus loss and mixed-DPI stress remain open. |
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
