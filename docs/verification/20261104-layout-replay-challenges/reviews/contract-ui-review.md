# Round 6 codec/UI independent contract review

Reviewer: `/root/review_records_final`

Scope: frozen follow-up assignment in
`.godot/collaboration/round6-implementation.md`; released codec and codec suite,
current `lab.gd` / `challenge_window.gd`, and the UI suite and supporting
controller/Model/Goals/Settings paths as needed.

**Follow-up: both initial findings are closed in current source. No remaining
actionable finding in this reviewed scope.**

## Repair verification

Reviewed the current repairs and the corresponding new behavioral assertions.

- P2: the read-only branch now precedes pending state, explains unsupported or
  externally changed storage and retains the temporary/removal explanation.
  The host passes explicit retryability to the Window; permanent protection
  hides target Retry and its exit-guard equivalent. The exit guard retains the
  protection explanation. Saving Notebook falls back to the visible cancel
  action when target retry is unavailable.
- P3: the exit focus whitelist now includes `exit_target_retry`, preserving
  the existing visibility/focusability fallback. The suite focuses actual
  retry during a live-contention pending proposal, reloads the locale, and
  checks the same focus and unchanged exploration/target.
- Added protected-file scenario seeds an actual unsupported-version sidecar,
  accepts a real current starter as temporary, checks visible protected and
  temporary status, hidden futile actions, exact retained code, unchanged
  original bytes after retry and the protected exit explanation.

The latest completed root run was independently inspected after it became
available during this review:

`.godot/verification/20261105T033350Z-75462610/headless/20261105T042615Z/`

Both `results.json` and the full challenge UI log report fresh import exit0
and **250 checks, 0 failures**, exit0 with no recorded errors. All three
current UI source/test files match that QA project's bytes:

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `experiments/layout_strategy/lab.gd` | 1338 | `dba382169f996fdfe22a4710a37e4b5be6997d1f150c4b6cf8f6c576b2df2b5f` |
| `experiments/layout_strategy/challenge_window.gd` | 424 | `2e44ba58a49c79fc1e4cbbb096094d476c649bd317e0c2a776e792f687939df3` |
| `tests/test_layout_strategy_challenge_ui.gd` | 489 | `76ccc231614efce6a820dcd2f36fd4a22e0b6962c1bc713c32f29ca74cd04736` |

Read-only `git diff --check` produced no diagnostics.

## Numeric and popup fixture boundary

The source still commits only the four known editable SpinBox editors via the
installed `apply()` before a single guarded run. The root SpinBox diagnostic
confirms method availability, expression evaluation and visible clamping.
The focus-settle diagnostic shows actual viewport printable input yielding
visible2 while draft remains1, then Command Enter commits2 and produces one run.
The current suite retains that printable-input path for its first numeric edits,
and waits after focus before preparing expression/cap fixture text.

The popup helper now reveals and focuses an actual enabled button, waits for
focus, asserts Window/visibility/focus, then dispatches Window Enter down/up.
Normal positive action routes do not emit `pressed` or call action handlers.
This is a legitimate scripted keyboard route, with the original model/state/
byte/preview assertions retained. Root-viewport mouse Run remains covered.

The recorded synthetic popup mouse limitation is preserved: mouse events
reached Button GUI input but its reported mouse position remained outside and
no press occurred. Switching the fixture to keyboard activation establishes
neither popup mouse correctness nor native OS typing. GPU and native acceptance
remain separate; no such run was performed by this reviewer.

## Initial findings, now resolved

### P2 — Pending target hides a permanently protected storage state

`experiments/layout_strategy/lab.gd:774-781`

`_challenge_storage_text` returns the pending-target or pending-removal message
before checking `challenges.storage_status == "read_only"`. Consequently,
loading a malformed/future sidecar and then accepting a valid target shows
“This target is temporary; saving has not succeeded. Retry in Challenges.”
The same masking occurs after an external-change conflict. The actual
read-only reason disappears from every visible storage message, and repeated
retry can never repair that Store instance: `Store.write` immediately refuses
when protected, while `recover_writer` also refuses.

This is particularly confusing because the protected file is intentionally
preserved and the active temporary target is otherwise usable. Keep both facts
visible: temporary/pending removal **and** protected file/reason, without
suggesting retry alone can clear the protected state. Preserve the existing
exact proposal and bytes. Add a UI case seeded with an invalid/future file or
external conflict, accept a valid code, and verify the protected explanation
remains visible alongside pending state after retry.

### P3 — Exit retry button omitted from locale focus restoration

`experiments/layout_strategy/lab.gd:1117-1119`

The new `ExitRetryTarget` button is a visible keyboard action when a target
proposal is pending, but `_restore_focus` still whitelists only
`exit_cancel`, `exit_save` and `exit_confirm`. With retry focused in the exit
guard, an in-place locale reload records `ExitRetryTarget`, finds the same live
button, then explicitly replaces it with `exit_cancel`. This loses the user's
exact action focus despite the pending retry remaining available.

Include `exit_target_retry` in the guard's valid focus targets, retaining the
existing visibility/focusability fallback. A locale-reload assertion with a
pending target and retry focused should return focus to the same retry action
without changing the proposal or running/saving anything.

## Checked without additional findings

- Codec has exact bounded transport, quote-aware preparse depth guard, strict
  nested Model/Goals schemas, canonical duplicate/alternate-spelling rejection,
  and explicit supported-stale retention.
- Creation/inspection remeasure current inputs. Controller comparison
  reconstructs the actual attempt and binds the full Trace, while the target
  fixes objective and inclusive caps independently of personal Notebook goals.
- Window preview is bound to exact editor text; edits invalidate preview.
  Confirmation re-inspects through the controller. Foreign workload handling
  leaves task, draft, history, goals and selection unchanged.
- Sharing uses the selected actual recipe; reply explicitly uses the retained
  immutable target goal. Target inspection and one-Undo restoration are explicit.
- Failed acceptance/clear preserve exact pending proposals. Notebook save and
  target save remain separate, and the exit guard does not silently discard a
  pending target when saving only Notebook.
- Code text Undo remains local; numeric commit/run is narrowly routed to the
  four editable SpinBoxes, with modal/exit/repeat guards. Settings suspension
  retains the existing challenge editor/preview and follows locale replacement.
- Stale code remains copyable without live comparison/restore authority.

## Verification boundary

This is a **source and root-log review**, not a native/GPU acceptance. No Godot execution,
Git mutation, source/test edit or ordinary player-data access was performed.
Root owns runtime repair and verification; UI implementation ownership was not
claimed. The earlier codec/controller report remains supporting source evidence:
`/private/tmp/vnb-round6-codec-controller-review.md`.
