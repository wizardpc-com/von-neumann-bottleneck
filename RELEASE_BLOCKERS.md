# Release acceptance gates

Current source and artifact: [CURRENT_STATE](docs/CURRENT_STATE.md).
These are remaining acceptance requirements, not instructions to add features.

## Current gates — 2026-10-17

Protected PR7 merged as `94b5bff`; main contains the complete sixty-task journey.
PR8 integrates feedback operations and a Windows Release draft. The owner explicitly
chose to wait for a working domain before public release. The earlier frozen player
packages remain offline; the public download remains forty-task Alpha1.

Actual private Windows EXE feedback at fixed `beca837894481165e6e04afe93f4e879645c1d29`
passed HTTPS delivery, same-ID private reporting, retry/deduplication, deletion and
an actually started restored receiver returning410. Restore held0 events/1 tombstone.
VPS service/data isolation, daily maintenance and private routes passed; no public
entry or offsite backup is active. [Current evidence](docs/verification/20261017-feedback-release/README.md).

| Gate | Status and required evidence |
| --- | --- |
| Localhost VPS receiver and maintenance | **PASS within private scope.** Separate services and daily timer enabled; actual delivery/report/backup/delete/restored-receiver410, private permissions, shared rate limit and unchanged original services/historical hashes passed. No public intake. |
| Public feedback domain and external entry | **Open by owner choice.** The planned domain is not purchased or resolved; hosting/filing requirements are unverified. Keep localhost. Future public use requires DNS, ports80/443, TLS and an external-machine acceptance run. A configured privacy URL alone is not such acceptance. |
| Windows online Pre-release | **Draft only by owner choice.** Fixed-source347e426 Windows offline draft and all4 uploaded digests verified; representative native restore/work/opinion/save/restart PASS. Publication waits for DNS/TLS/privacy/external acceptance; never bake a planned or localhost address into a player release. |
| Current Mac native interaction | **NOT_RUN for the `f26131049877` package.** Earlier native routes retain their own build attribution. Operate this package's navigation, editing, unfinished-task feedback, save and restart on a Mac. |
| Windows native execution | **Representative acceptance PASS at current offline347e426 and earlier f261310.** Existing64-cell saved-work source/phrase/step/play/pause/viewing controls, local opinion restoration, writable save and independent restart passed; both normal exits released their owned lease and saved fields stayed intact. Earlier d34a61d navigation/generation and8a919e2 restart evidence retain their own source attribution. Automatic Windows abandoned-lock recovery remains unsupported. A fresh later-region native full-route, extended focus loss and mixed-DPI stress remain open. |
| Other Mac / installation / signing | **Open.** Candidate is unnotarized; verify download, first launch and save on another machine, then choose formal signing/distribution requirements. |
| Display and focus | **Open.** Extended small-display/Retina/mixed-DPI and repeated focus loss during drag sessions require direct evidence. Earlier capture anomalies remain attributed to their recorded builds. |
| Unfamiliar-player understanding | **Open.** Unassisted entry, task choice, Hint comprehension, full-route pacing and concrete feedback. Known-answer replay and agent observations do not establish this. |
| Listening and artistic acceptance | **Open.** Independent listening and visual/narrative review of core and creative endings remain separate from technical checks. |

All forty original tasks repeated natively are additional coverage, not a mandatory
development gate. Existing original-core, Representation/Service and C/P/G native
observations are retained in their [dated verification records](docs/README.md).
They do not combine into a fabricated fresh full-route run.

The [2026-10-12 private HTTPS record](docs/verification/20261012-pre-release/README.md)
passed actual exported Windows feedback, retry/deduplication, deletion and a
tombstone-safe restored receiver against synthetic data. Its dedicated staging
was stopped, and it does not certify the new localhost deployment or public intake.
The [2026-10-13 creative candidate record](docs/verification/20261013-creation-expression/README.md)
retains its frozen build and test attribution despite the later PR merge.

Missing remote-access configuration belongs in the private local handoff. Do not
publish credentials, infrastructure targets or raw player data. Offline refusal or
network failure must continue to leave the game usable; opinions and statistics
require separate consent under the [feedback contract](docs/architecture/community-feedback.md).
