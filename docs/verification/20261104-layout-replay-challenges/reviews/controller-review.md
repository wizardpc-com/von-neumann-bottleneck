# Round 6 independent controller and process review

Reviewer `/root/audit_scores`. Read-only source review requested in the latest
`.godot/collaboration/round6-implementation.md`. No production/test edits, engine
execution, Git mutation or player-profile writes by this reviewer.

## Final closure after root correction and real process run

**Review complete: the saved-assurance P2 is closed by corrected source and a
fresh passing controller suite. No outstanding controller/process finding
remains in this review scope.** `target()` now
requires `storage_status != "read_only"` before reporting saved. The new
controller tests use both a genuinely removed target after an external update
and a genuinely deleted isolated file, then check the old code remains copyable
without the saved claim. This is the intended narrow correction; no pending
proposal or stale-code behavior was removed.

Current corrected controller SHA256:
`8ca5735cee7f095bca628cb4ec0a8b2d171e9f9ad5943ded7bd409f01197132b`.
Current controller test SHA256:
`52321e072608a1e27b87b2e088bf6d2920978de10344913faf8efc3627bf73ae`.
Read the full new
`headless/20261105T041349Z/test_layout_strategy_challenges.log` and its
`results.json`: **65 checks,0 failures,exit0**, including the six additional
external-conflict/deletion checks. The current source and test bytes both match
the corresponding files in the current isolated QA project. No additional source
fix or targeted rerun is requested by this review.

The corrected Store suite has now actually passed **288 checks,0 failures,
exit0** at `headless/20261105T040604Z/test_layout_strategy_challenge_store.log`.
The original failed run remains at the earlier batch. Root's readable task note
also records an actual installed-engine diagnostic confirming new dot-assigned
dictionary keys are `StringName` (typeof21), while explicit String keys pass.
Strict production schema validation was preserved.

I read every complete process log and `process/results.json` under
`docs/verification/20261104-layout-replay-challenges/`. All seven recorded phases
pass: seed7, reopen7, contend8, recover7, second reopen7, separate-profile4 checks,
plus deliberately killed owned writer PID27900 exit-9. The six normal processes
exit0; the killed holder is explicitly not a normal/graceful completion.

The actual fixture profile is
`VonNeumannBottleneckChecks/layout_strategy/challenges-process-20261105T040712Z`.
Read-only inspection of its final target and expected-replay files confirms
serial cap601, unchanged batch cap350, exact matching saved/expected canonical
codes, matching SHA256 challenge IDs and distinct full-condition Trace IDs:

- Batch `5d6fe398bda194c801c658074004d588e46b2a954b0f1c9094eb2ed145917424`.
- Serial `9a3a101d933f1ae22601a92efe4586edfa8e7fa249a6bf8dccf05fd68ea51572`.

Both source starters remeasure Q1307/total2456, with different condition-bound
Traces; no synthetic persisted score is used. The process probe and runner hashes
are unchanged from the source review below. This is now actual bounded process
evidence, not merely a source prediction. It preceded the saved-label predicate
correction; that narrow change is now covered by the65-check controller rerun.
No need to repeat the whole process matrix solely for this presentation predicate
unless another relevant implementation change occurs.

## Finding

**[P2, closed; original finding preserved] A detected external conflict leaves unaffected cached targets labelled
saved even when the actual file no longer contains them.**

At initial review, `experiments/layout_strategy/challenges.gd:44` derived `saved` solely
from `_has_saved and not pending`. `_has_saved` is populated at setup/successful
write; `_observe` records the Store's later `read_only/changed` result without
invalidating that assurance. This can occur within the exact existing controller
test sequence:

1. `old` loads the first saved `scan_batch` target.
2. The main controller replaces and then clears `scan_batch`, finally saving
   only a serial target.
3. `old.accept(serial.code,"scan_serial")` detects the external change and
   correctly protects the file as `read_only`.
4. `old.target("scan_batch")` still returns `saved:true`: its cached code equals
   its old committed map and `_has_saved` remains true, although that code is
   absent from the real saved file.

The accepted frozen contract explicitly requires an actual saved target, and the
UI distinguishes saved from temporary/protected state. Preserve cached/proposed
codes for use/copy, but withdraw the saved assurance after detected protection/
conflict. A minimal correction can invalidate `_has_saved` when `_observe` sees
`read_only`, or gate `saved` on that state. This should not erase proposals or
turn supported stale codes loaded successfully from an unchanged file into
temporary data.

Add the exact assertion to the existing stale-controller test, whose file has
already genuinely changed. Also cover detected external deletion if convenient.
The original finding was source-backed; the reviewer did not execute an engine
repro. Root's correction and actual targeted verification are recorded above.

## Verified source behavior

- Preview decodes workload first and re-inspects actual inputs without changing
  proposals, Notebook state, selected evidence or edits. Accept rechecks the
  current code/task and writes only the canonical target proposal.
- Failed replacement keeps the exact proposed code. Failed clear retains
  `_targets` without that task, reports a pending removal, stops active comparison
  and leaves committed file bytes intact. `retry()` writes the exact whole
  proposal; personal goal/draft/selection are absent from this path.
- The comparison boundary re-executes the actual selected plan, checks current
  task/full condition, requires `run.passed` and equality with the stored full
  Trace hash, then builds a new complete entry. Altered cached metrics are
  ignored; Code.compare receives genuine current evidence. Changing the
  Notebook filter cannot change the target's immutable rule.
- Cached targets are bound to canonical code plus current full condition and
  returned as detached inspection dictionaries. Supported old model/condition
  codes remain retained and copyable, with no active comparison.
- Store validates the complete canonical nested file and each code through
  structural decode, including task-key/envelope correspondence. It retains
  supported stale identities byte-for-byte and stores no score or Trace.
- Store checks the main-file digest before lease acquisition, after acquisition
  and after actual temporary flush/readback; confirms lease ownership before
  atomic replacement. In-memory commit follows successful replacement only.
  Dedicated `.writer/challenges.json` does not share Notebook's transaction.
- Recovery affects writer ownership only; a subsequent explicit changed write
  remains necessary. Unknown/live owners, altered main files and malformed files
  stay protected. This is cooperative writer protection, not arbitrary-writer
  compare-and-swap or power-loss durability.

No other actionable production issue was found in the reviewed controller/store
paths at this snapshot.

## Process acceptance design

`tests/recovery/layout_challenge_process_probe.gd` and
`.godot/collaboration/run-round6-process.py` are adequate to establish the
intended bounded acceptance if their actual phases pass:

- A fresh profile is configured before autoload startup. Seed writes real
  notebook input and two actually measured target codes.
- A second process compares exact normalized notebook inputs, canonical codes,
  actual metrics and complete Trace hashes, then obtains the real grouped
 339/1368 improvement without modifying target storage.
- An owned process acquires the actual challenge writer lease and publishes its
  PID. The runner checks that marker against its own live subprocess.
- A separate contender attempts a genuinely different target, observes busy and
  retained pending state, refuses live-owner recovery, and verifies unchanged
  target bytes. It independently changes/saves Notebook goal data and asserts
  those bytes changed while the challenge lease remains held.
- The runner deliberately SIGKILLs only that owned confirmed PID and records
  exit-9. This is not a graceful-exit test.
- Recovery changes serial Q1 cap600→601, writes a different real canonical code,
  asserts target bytes changed and Notebook bytes did not, and records new
  expected code/identity/actual replay.
- A later process again reconstructs the exact stored cap/code/metric/Trace
  result. A separate profile starts with neither file. The copied project
  settings are restored in `finally`.

This closes the previous no-op recovery-fixture class: neither the challenge
post-recovery write nor the independent Notebook save can pass as an unchanged
save. Current process output directory did not yet exist when reviewed; these
are source conclusions, **not a process acceptance claim**.

Operational evidence note: the runner writes fixed `process/seed.log`,
`reopen.log`, `results.json`, etc. A second invocation would overwrite the first
invocation's evidence. Before any rerun, preserve the old directory or use a
timestamped output directory; keep initial failed logs rather than only the
latest success. This does not block a first successful invocation.

## Fresh core evidence read and Store fixture feedback

Read complete actual logs and the batch result at:

`.godot/verification/20261105T033350Z-75462610/headless/20261105T040136Z/`

- Codec: **397 checks,0 failures**, engine exits0.
- Controller: **59 checks,0 failures**, engine exits0.
- Store's initial run failed supported-stale fixture assertions and then hit
  missing `targets.scan_batch`; runner exits-2. That run does not establish
  storage acceptance.

Two fixture faults were independently identified and sent to root:

1. Inserting previously absent target keys via `.targets.scan_batch = ...`
   /`.scan_serial = ...` is inconsistent with the Store's strict String-key
   schema (new dot keys may be StringName). Decoder assertions already passed;
   normalization then failed before writing. Use bracketed explicit String keys
   for additions, while retaining strict Store validation.
2. The Notebook-lease check formerly asserted
   `not notebook_lease.owns(...)`, then the next check required `owns(...)`.
   Its message also claimed actual ownership. This was contradictory.

A later read during this review observed root's source corrections to bracketed
new keys and the positive Notebook ownership check. Fresh rerun remains required;
the initial failure log should remain archived.

## Source binding at review

| File | SHA256 |
| --- | --- |
| `experiments/layout_strategy/challenges.gd` | `39e4c2856b87be0d37e1560d70967be2774027fe621ec888d12c423d45d440da` |
| `experiments/layout_strategy/challenge_store.gd` | `15ec81202cefe7b7ff5cc74ac79a392a487a4c49e8fb8c151a0a7705c8b81931` |
| `tests/test_layout_strategy_challenges.gd` | `fbe6a959236c61e96aa44c915c308a38ee946dab99e8afd366dfb59453894e04` |
| `tests/recovery/layout_challenge_process_probe.gd` | `5134bc365b0528ef75d8e3f7d0d3bb133ffbc58bfc0ab45c73657e13a8171dcb` |
| `.godot/collaboration/run-round6-process.py` | `80fbc5a1af91efc67adfc8732a13c8f0aa00f9c274e347f4ff6359822088cbae` |

Source may change under root ownership after this snapshot. Native input,
rendered UI, exports, cross-platform operation and online trust were not reviewed
or established here.
