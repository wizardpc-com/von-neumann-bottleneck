# Round8 independent contract review

Reviewer: `/root/review_records_final`.
Scope: current explanation reducer, presenter, detached Session baseline getter,
and their new/changed tests, against
`.godot/collaboration/round8-implementation.md` and
`docs/exec-plans/active/explain-layout-comparisons-20261105.md`.

This is a source review of the snapshots below plus read-only inspection of
root's recorded focused test results. I did not run Godot, tests, native tools,
services, or Git mutations; I did not access ordinary player data. Only this
review report was written.

## Review result

No actionable finding remains in the reviewed revised snapshot.

### Resolved: [P3] Separate write count was absent from the presenter

The initial Cache reads lens omitted the reducer's existing `writes` counter.
The revised `experiments/layout_strategy/lab.gd:549-555` includes `writes`
with the explicit bilingual label `写入次数` / `write count`, separately from
read lookups/hits/misses and RAM byte rows.

The revised `tests/test_layout_strategy_explanation_ui.gd:151-152` asserts
17 versus 0 writes for both preparation and total in the real two-scan fixture.
The source correction addresses the finding; root owns its runtime verification.

The pure test revision was also reread: malformed-event injection now uses a
JSON-parsed untyped array, and rejection immutability uses `var_to_bytes`
instead of JSON serialization so NaN/Inf fixtures are representable without
serialization diagnostics. These changes preserve the intended negative cases.

### Reviewed integration repair: deferred SpinBox blur and visible focus

Root's first UI run at
`.godot/verification/20261105T070528Z-49a63b5c/headless/20261105T074051Z/`
recorded 453 checks and eight failures. I read its complete 3434-byte UI log.
The preserved focused probe at `headless/20261105T074810Z/` confirms that the
old focus-loss path applied pending `7` after `_syncing` returned to false,
changing the committed group `8` into `7`.

The revised presenter puts the committed value into the editor before releasing
focus, then defers restoring the typed pending text until after focus-loss
application. This keeps the narrow observation-only path without changing
ordinary Run semantics. The revised modal fixture explicitly focuses the
visible event table instead of the hidden History table and checks Settings,
translated Settings and F8 return to that same visible inspector. Both edits
were reread; no new actionable defect was found.

I read the complete current `headless/20261105T075427Z/`
`test_layout_strategy_explanation_ui.log`: **453 checks, 0 failures**.
The associated `results.json` records exit 0, no errors and an isolated
`VonNeumannBottleneckChecks/20261105-round8/...` profile. The six source/test
hashes below all match root's current QA project copy byte-for-byte.
The pure suite's complete `headless/20261105T074417Z/`
`test_layout_strategy_explanation.log` records **430 checks, 19 measurements,
0 failures**. These are inspected root-owned results, not executions by me.

## Reviewed behavior

- The reducer does not evaluate a plan, access files, write authoritative
  metrics/events, or use auxiliary source/scratch maps for its summaries.
  The caller supplies current-condition authority. The local consistency
  checks are not an authentication mechanism.
- Preparation/query/output durations come from ordered event durations.
  RAM reads count fills; RAM writes count writes. Cache-to-compute reads,
  eviction descriptors, allocation and release bytes are excluded from
  RAM traffic. Read hits are lookups minus fills, with writes kept separate.
- The pair fixture checks preparation +442, query -384, total +58 cycles and
  total -44 RAM bytes. Payload 68 B and allocation 80 B remain distinct.
  The split-field and grouped fixtures cover different physical tradeoffs.
- Event validation checks bounded types, current condition, complete correct
  ordered outputs, operation costs, continuous clock, read transaction
  structure, phase/job tags, output emission/spans, admissions/responses,
  allocation/release and reconciliation with stored authoritative metrics.
  JSON integral numeric forms are accepted.
- Job rows retain public job order. Q1 is job 0 completion; elapsed is actual
  completion minus admission. Sparse out-of-order completion is covered.
  Shared preparation is not assigned to a job, and elapsed intervals are not
  summed into work.
- Phase/job summaries retain original event indexes in original order.
  The UI binds baseline inspection to a detached baseline entry without
  changing Session selection or pinned baseline. Raw failure inspection remains
  available when a completed comparison is unavailable.
- Explanation caching is keyed by current condition and both run/Trace
  identities. Selection, baseline and condition changes invalidate the pair;
  goal changes refresh eligibility context without reducing a different trace.
  Locale rebuilds preserve the bound source. There is no per-frame reducer.
- The Session getter returns a deep detached snapshot and adds no persistent
  state. Its test mutates nested metrics/events/plan/outputs/maps and verifies
  the original entry, draft and Undo/Redo state remain unchanged.
- UI tests use actual key input followed by a mouse click for pending numeric
  text, then assert inspection preserves the committed draft, pending text,
  history, Undo/Redo, goal, challenge, Notebook and file snapshots. A later
  explicit Run is tested to apply the number and measure once. These are
  authored tests, not a claim that I executed or observed them passing.
- Existing modal/settings/F8/exit handling remains in place. The new input
  preservation path checks modal/exit state before acting. Bilingual
  1280x720 and 960x640 frame capture/bounds checks are authored.

## Verification boundary

The focused pure/UI logs above were inspected. Root still owns remaining
regression gates, raw rendered-frame checks and final QA/playable source
binding. The latest broader headless batch was still progressing during this
review; this report does not claim that the entire batch finished.
This review does not establish native mouse acceptance, beginner comprehension,
exported or cross-platform behavior, long-session performance, or remote score
trust. Both implementation handoffs are now present and source ownership is
released to root. Subsequent source changes require a scoped rereview.

## Reviewed SHA-256 snapshots

| File | SHA-256 |
| --- | --- |
| `experiments/layout_strategy/explanation.gd` | `3c6fa0ef67bcf56ef55cc0494cc4f771891cca436623c223ee258634d562b4be` |
| `experiments/layout_strategy/lab.gd` | `6980e106c322f7756edce3e4503dabca1a45c5def861ff533d0eaff86ae8ebd4` |
| `experiments/layout_strategy/session.gd` | `46e06cc6586a3672a24f12bc575e495227eab3ff882b145d457c739e73a51055` |
| `tests/test_layout_strategy_explanation.gd` | `69c04d36165d427ac6dcff0c82e249f013d3a810f0d8493d4de818a61ea01ebb` |
| `tests/test_layout_strategy_explanation_ui.gd` | `8db5791581fd6a60d161b8e467387f4966e65d62fc81082ec4328957d4733410` |
| `tests/test_layout_strategy_session.gd` | `6d19542c26468ae09356224a8fb773308fe435a29db9c872c2ccbc7f7f22fb13` |
