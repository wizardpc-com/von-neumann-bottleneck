# Pre-release Windows and private feedback acceptance — 2026-10-12

The existing sixty-task candidate is ready for a controlled offline playtest.
The Windows export passed native tutorial editing/save/restart checks, and a
separate unchanged Windows export completed actual private HTTPS feedback on
the existing VPS. Public intake remains deferred. PR [#7](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/7)
is unmerged; main is unchanged.

## Source and frozen packages

The freshly fetched baseline was `cfdee8a54f0ca2787f66f91ef4d0c4d4233dbf97`;
the supplied `34aed77` reference is its ancestor. Both platforms are frozen at
`61edc8063078ee26882189efdb8bd56d70b87d8b`, with Godot
`4.7.1.stable.official.a13da4feb`. Later commits change verification tooling and
reports only; exported runtime/server bytes remain identical to this source.
The private receiver's recorded release is ancestor `377548b`; its server bytes
are identical to `61edc80`. Later CI wiring adds the two packaging/probe Python
checks without altering either exported client or receiver.

Local artifact directory: `build/playtest-PreRelease20261012-61edc8063078/`.
It includes Windows/macOS ZIPs, extracted packages, root/platform manifests,
licenses, README, changelog and known issues. Keep these artifacts immutable.

| Artifact | ZIP SHA-256 |
| --- | --- |
| Windows | `5c2d5aa5db007cb87885e73a4deedb72bade46c36bc2835376f9298270e63c41` |
| macOS | `ee0f90ac2d90a05c667407abc1ba52ed738b646fcc2cdfd985341bf154b883ae` |

The journey contains original core40, Representation5, Service3, optional
address Prediction3 and C/P/G9. The existing `CloudPlaytest` save channel is
stable: `%APPDATA%\VonNeumannBottleneckCandidates\representation\CloudPlaytest`
on Windows, and `~/Library/Application Support/VonNeumannBottleneckCandidates/representation/CloudPlaytest`
on Mac. QA used separate profiles and never copied completion flags into this
player channel. Service data uses the sibling `service/CloudPlaytest` directory;
back up both complete candidate directories before updating or reverting.
The offline package has no receiver endpoint; local opinions
and feedback export remain available, and statistics default off.

## Verification and fixes

| Check | Result and scope |
| --- | --- |
| Existing game/content/save audit | **PASS.** Windows isolated155/155 checks, including152 suites and a Chinese ordinary Game GUI route with760 checks/zero failures to Chapter1. Static review covers all regions and their earned endings. [Audit](game-audit.md). |
| Windows native exported game | **PASS, representative scope.** Actual OS pointer/keyboard input completed tutorial wiring, input change, run, delete/reconnect and its earned completion. Two independent process restarts recovered progress, byte-identical workbench and local opinion text/ID. Fullscreen/windowed captures retained privately; no new blocking layout defect observed. Later-region OS playthrough and mixed-DPI stress are not covered. |
| Local actual EXE feedback | **PASS.** Offline/online/delete, same-ID private report/triage, deduplication and tombstone-safe restore. [Windows receiver/tooling audit](feedback-local.md). |
| Actual EXE → private HTTPS → VPS → private report | **PASS.** Explicit private certificate validation, default trust rejection, offline durable outbox, independent-process retry/acknowledgment, same-ID/task/build report, deletion and a restarted receiver using a restored old snapshot. Delayed deleted uploads return410. Saved generated work and private unsent draft survive unchanged. |
| VPS isolation/cleanup | **PASS.** Separate synthetic SQLite and resource-limited receiver; loopback TLS reached through Windows OpenSSH. Management/wrong-method routes return404. Dedicated services stopped, temporary ports closed; baseline service PIDs/listeners and historical feedback database hash unchanged. |
| Freeze identity | **PASS.** All manifest file/ZIP hashes, complete60-task inventory, platform notes/licenses and official template checksum checked. Mac ZIP contains executable universal x86_64/arm64 Mach-O, matching Info.plist and PCK. [Packaging checks](freeze-tools.md). |
| Code CI | **PASS.** [Run38206327893](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/38206327893), source `51d095a`, Godot and Python jobs successful. |

Concrete repairs close SQLite handles that blocked Windows cleanup, bound
oversized-request draining by bytes and a total deadline, support Mac ZIP
construction on Windows while retaining Unix executable/symlink metadata, and
write literal UTF-8 Chinese paths in Godot export/QA configuration. Player-facing
package notes describe the complete candidate, stable save channel and separate
local/opinion/statistics behavior. No new chapter, simulation/model/save schema,
progression rule or speculative gameplay change was needed.

## Evidence and remaining acceptance

[Sanitized receipts and hashes](receipts.json) contain no credentials, receiver
target or raw identity tokens. Private evidence is retained under
`.godot/pre-release-20261012/`, `.godot/package-feedback/6df5d3f0389b/` and the
game audit's recorded isolated verification directory. Native screenshots include
the earned completion, reopened circuit, saved/reopened opinion, honest offline
refusal and windowed layout. The HTTPS probe drove actual game controls through
an external synthetic scene in an unchanged EXE/PCK; it is distinct from OS input.
Its prior failed attempts are retained as test-setup evidence. No real player data
was collected. VPS TLS material, raw reports, SQLite snapshots and access details
remain private.

The private HTTPS acceptance package is `local_acceptance_only`; it is not the
download for players and its temporary tunnel is closed. Public feedback ingress,
domain and production data require explicit owner authorization. Current Mac
native execution, another-machine installation, notarization, extended focus/DPI,
unassisted full-route understanding and independent listening/artistic acceptance
remain **NOT_RUN/Open**, as listed in [release gates](../../../RELEASE_BLOCKERS.md).
Export/automated/native observations do not establish those outcomes.
