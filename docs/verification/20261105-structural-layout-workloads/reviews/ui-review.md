# Round7 independent UI contract review

Reviewer: `/root/review_records_final`, 2026-11-05.
Read-only review against
`docs/exec-plans/active/structural-layout-workloads-20261105.md`.
No production/test edits, Godot execution, native input or Git operation.

## Actionable finding

### P2 — Use canonical bytes for the valid empty legacy-target fixture

Location: `tests/test_layout_strategy_structures_ui.gd:436`.

`empty_legacy_targets()` writes `{"version":1,"targets":{}}` and then expects
the old target file to load as a valid pending copy. The whole-file decoder in
`experiments/layout_strategy/challenge_store.gd:223-228` requires exact canonical
JSON; `_canonical` uses `JSON.stringify(value,"",true)`, whose sorted spelling
for this map is `{"targets":{},"version":1}`. The current fixture therefore
enters `read_only`/`format`, with `copy_pending=false`, before the intended UI
path is reached.

Consequently the pending-copy assertions at439-444 fail, the retry action is
hidden, and446-449 cannot establish that an empty legacy target map really
creates a v2 copy. The final check uses short-circuit `and`; this finding does
not claim a null-access crash.

Create `original` with
`JSON.stringify({"version":1,"targets":{}},"",true)` (or the exact sorted literal)
and retain the final byte-preservation assertion. This repairs the intended
valid-data fixture without weakening canonical/protected-file behavior.

Root was notified immediately. The report records the source observed before
any root repair.

## Other paths reviewed

No additional actionable production defect was confirmed in the reviewed code:

- Notebook protected status precedes pending-copy wording in `lab.gd:727-773`.
  Challenge protection also precedes legacy-copy wording at798-828; the UI
  exposes retry only when the controller is not read-only.
- Empty valid target maps use collection `is_dirty()`/`copy_pending`, not a
  fabricated per-target pending flag, to show Save target copy. The source
  path is consistent; the malformed fixture above prevents its current test.
- Exit handles Notebook and target copies independently at1265-1365.
  Notebook save does not leave while targets remain dirty; target save
  refreshes the guard and does not itself quit.
- A single contextual starter uses the current task in
  `challenge_window.gd:116-120,192-210`. Host guards at915-958 prevent a foreign
  or stale task action, and workload changes dismiss the old popup.
- Retained invalid group values remain visible and repairable at
  `lab.gd:460-479`; rendering does not clamp the draft. Run validation remains
  authoritative, repair is an ordinary edit, and Undo restores the old value.
- `change_task()` clears the pending editor reference before refreshing the
  new task. Numeric Run applies the enabled focused/pending SpinBox once.
  The new test checks numeric submission after a workload switch, actual
  metrics, per-task retained state and no bleed from the submitted run.
- Shared workload names, expanded public request order, target measurement,
  preview/accept isolation, goal ranking reversal and physical-layout metrics
  are covered by the authored structural suite without changing model rules.

## Verification boundary

This is source review only. I read both production UI files, the complete new
structural UI suite, relevant inherited UI helpers, and controller/store
contracts. I did not run or claim a passing UI suite, rendered layout, native
focus transition, or cross-platform result.

In particular, the new numeric case submits its pending value before switching
away; the source-level pending-reference reset is visible, but native focus
behavior while switching away from still-unsubmitted text is not runtime
evidence from this review.

Review complete; all source ownership remains with root.
