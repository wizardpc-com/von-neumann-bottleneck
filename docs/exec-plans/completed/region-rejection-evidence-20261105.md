# Consistent rejected Region evidence — Round11

## Goal and scope

Base `cf27a8236db7faca56d6361cf9a44d35224b748e` on
`codex/gameplay-systems-20261104`. The previous milestone is committed, pushed
and independently verified. Current source confirms that a Region call with
invalid preparation parameters publishes zero total cycles and no events,
but retains completed service costs, outputs, encoded blocks and cache data.
Make this rejected result internally consistent while preserving all valid
computation, historical achievements and the existing error precedence.

Root owns `experiments/representation_region/model.gd`, documentation,
integration, Git and all sequential Godot/native execution. Separate agents own
the new pure regression and the workload benchmark adapter; a third reviews
the contract independently. Exact coordination lives in
`.godot/collaboration/round11-region.md`.

## Contract and impact

After an otherwise valid Base execution, invalid `online`, `clients` or
`encoder` returns a fresh failed `SimulationTrace`. Keep the existing
`representation-region-v1` identity, `preparation_machine` error and metric key
set, with detached submitted `spec` and `plan`. All fourteen execution/storage
metrics are zero, output/expected/block/access arrays are empty, and top-level
result/expected/events retain fresh Trace defaults.

The accepted parameter types and bounds stay unchanged: boolean `online`,
integer clients1–8 and integer encoder≥1, including the existing requirements
for offline orders. Base-invalid inputs retain their complete current failure
and priority. Do not move preparation validation ahead of Base in this change.
That would conflate a correctness repair with a separate execution optimization
and change compound-error precedence.

Valid results must remain identical in every typed field, including complete
events, cache snapshots, encoded bytes, preparation/service costs, provenance
and `meets()` decisions. No version, catalog, cost, saved schema, condition
identity, old achievement or ranking change is authorized by this repair.
Rejected inputs already fail; the correction cannot grant completion.
GDScript remains the reference. No native code or dependency is added.

## Implementation and verification

1. Freeze the committed Round10 runtime independently before production edits,
   bind its source to Git bytes and prepare an isolated reference profile.
2. Add a pure negative regression covering malformed types, missing fields,
   boundaries, both online modes, RAW/RLE/mixed plans, detached inputs and
   retained evidence. Verify that it detects residual work on the old runtime.
   Check complete Base-error delegation and unchanged completion rejection.
3. Add a measured compatibility corpus covering all eight authored orders
   with whole RAW, whole RLE and the two task-specific existing alternatives:
   32 complete traces plus all plan/task `meets()` decisions. Keep full typed
   comparison separate from the deliberately changed rejection diagnostic.
4. Construct the clean Region rejection with an explicit metric schema and
   detached inputs. Do not mutate a populated success Trace into a partial
   failure, alter shared Base behavior or fabricate another invalid input.
5. Run isolated Godot4.7.1 checks for Region, session restore, protected supports,
   journey review and current workbench presentation. Compare old/new complete
   successful corpus, repeat determinism and input/history immutability.
   Preserve all initial failures and full process records.
6. Independently inspect exact diagnostic differences, source and evidence.
   Update architecture, testing, current state and the computation audit.
   Bind an ordinary isolated preview to source, verify startup and close
   the plan before the authorized task-branch commit/push.

This is a correctness change, not a speedup claim. Same-host elapsed timings
remain available as observations; the changed rejected output cannot support
an equal-work speed ratio. Native OS input, Windows, exports, newcomers and
long-session acceptance remain separate from model or headless verification.

## Rollback and follow-up

Rollback restores the single Region rejection branch and related diagnostic
expectations from the base. No player file needs rewriting or deletion.
Preserve old raw evidence and the prior metric contradiction for audit.

After this contract is stable, measure repeated cold-client computation and
Trace copying before choosing the next GDScript optimization. A C++/Rust pilot
still requires independent value, a separate branch, full parity and actual
Windows/macOS evidence.

## Progress

- 2026-11-05: inspected the clean current checkout, Region/Base/Trace code,
  prior audit and actual archived rejection evidence. Recorded scope and
  ownership before production changes. Round11 implementation is beginning.
- 2026-11-05: froze556 runtime/support files from committed Git before editing.
  Old pure regression854/252 demonstrates residual evidence; no script/parse
  diagnostic. The same candidate regression854/0 and five other related suites
  pass through the standard isolated verifier.
- 2026-11-05: the two valid benchmark cases pass strict full typed comparison:
  32 authored-order traces,20 goal decisions and4 existing online traces.
  Three fixed-count samples preserve all original ranges; unchanged valid
  medians are about2.1% and3.1% slower, so no speedup is claimed. The separate
  old rejected diagnostic has15 semantic failures and the candidate has none.
  The strict comparator intentionally rejects the historical failed diagnostic.
- 2026-11-05: independent artifact review confirms all13 rejection siblings
  exact and only the declared Region metric/array/scalar differences. Original
  JSON, isolated outputs, snapshot hashes and sealed logs are independently
  checked; the reviewer's initial configuration-blank-line failure is retained.
  Final1251-entry source binding passes, ordinary startup exits0 without
  diagnostics and the isolated preview launcher passes shell syntax checking.
  Final independent evidence review completes3235structural checks with no
  actionable issue. Source and runtime verification are complete; root closes
  the exact artifact scope and authorized task-branch commit/push. See the
  [complete receipt](../../verification/20261105-region-rejection-evidence/README.md).
