# Round 5 independent integration review

Reviewer: `/root/review_records_final`

Result: **No actionable present defect found in the reviewed Goals/Session and
Notebook UI integration.** This is a source review, not runtime, native-input,
cross-platform, persistence-durability or remote-trust acceptance.

Subsequent visual review found one P3 inaccurate stale-selection label, documented
in `/private/tmp/vnb-round5-frame-review.md`. That finding supplements this
source-only result; the model, selection, save and failure-path conclusions below
remain unchanged.

Scope follows `.godot/collaboration/round5-implementation.md` and
`docs/exec-plans/active/layout-notebook-20261104.md`. The UI implementation report
was explicitly released before the final source pass. No runtime/test files were
edited; no Godot or Git operation was performed by this reviewer.

## Reviewed behavior

- `goals.gd:27-97` excludes malformed, incomplete and wrong-condition
  measurements before ranking. Caps use inclusive comparisons, unrestricted
  `-1` remains distinct from the real `0` cap, and objective ties preserve input
  order with competition ranks. Only total cycles or actual RAM read+write bytes
  determine rank; no second metric breaks a tie.
- `session.gd:73-101,120-151` executes a recipe before recording/selecting fresh
  evidence. Replay does not touch the current draft or either edit stack.
  Checkpoint restore validates the whole input before adoption and does not
  restore runs, scores, comparison baseline or Undo. Explicit restoration still
  uses the ordinary one-edit Undo path.
- `lab.gd:534-646` distinguishes current draft from selected evidence, reranks
  existing measurements without inventing runs, and labels recent-run versus
  kept-plan scope. Kept selection replays the recipe without replacing the draft;
  the emitting TreeItem survives its signal. Rebuild selection is guarded by
  `_syncing`, so goal/locale refreshes do not automatically replay rows.
- `lab.gd:648-676` keeps the measured selected recipe rather than a different
  draft. An accepted pending keep remains selectable after a failed save; the
  explicit Save action retries the Workspace proposal. Continue improving
  explicitly restores and then returns to the editor.
- `workspace.gd:18-77` and `lab.gd:678-710` distinguish a pristine missing file
  from a successfully saved workspace. The displayed persistence scope matches
  the contract: drafts/goals/named recipes are saved explicitly, while recent
  runs, comparison baseline and Undo are process-only. Storage failures retain
  visible failure/protection text rather than claiming saved state.
- `lab.gd:942-1023` distinguishes saved versus dirty exit states, makes removal
  an explicit full-workspace save, and retains the current proposal on failed
  removal. Save-and-exit calls the leave path only after `workspace.save()`
  succeeds; failure keeps the guard visible. Modal focus restoration includes
  the new Save-and-exit control, and name/numeric text editors retain their own
  text-input routing.

## Verification boundary

Read the released implementation, relevant integration paths in Workspace and
Model, and the goal/session/notebook UI behavioral tests. The tests exercise
actual model measurements, exact cap boundaries, tie/condition rejection,
selection-versus-draft isolation, explicit restore/Undo, locale preservation,
writer contention, failed Save-and-exit and fresh-scene replay.

Those assertions have been reviewed, **not executed here**. Root retains ownership
of fresh headless/GPU tests, full logs, raw viewport captures, separate-process
restart/lease acceptance and final source binding. Their results must supply
runtime acceptance; this report does not substitute historical receipts.

## Source binding

SHA-256 from the final reviewed source pass:

```text
61dc805b8cec1fd4bc19a16cd1191021f0b467cb2f6c40ad972471a75e174abb  experiments/layout_strategy/goals.gd
0329ebd9eca8b9920836f0e62a862c97751a0b2d54147f87de48450d18fa88fb  experiments/layout_strategy/session.gd
69247b2975d81722b8946ff6459c29ff82a91e8bb5e4f61f693f1c2c6c61e08e  experiments/layout_strategy/lab.gd
221c5cc236e96f1951e81d3c56017eb6a7bc3452aa5893818f7bb0ef24253606  tests/test_layout_strategy_goals.gd
60d89c5cf1ad397f1ccb7ce022c67231050fae7537b87dd064bb5800d3a4eaa8  tests/test_layout_strategy_session.gd
0f5a17249b41b5db6756e73999a987457a662ceb09df0444fbc4e155ccb28ef5  tests/test_layout_strategy_notebook_ui.gd
851dfce013abe68d1ef6511c0b227d2f2302bee4013137861408d28cac3fd878  tests/test_layout_strategy_ui.gd
```
