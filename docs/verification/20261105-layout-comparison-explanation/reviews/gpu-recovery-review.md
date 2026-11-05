# Round8 GPU recovery review

Read-only follow-up by `/root/review_records_final`, following
`.godot/collaboration/round8-review-followup.md`.
This reviewer did not run engine/native/service tools, mutate Git, or edit
source/tests. Only this report was written; the existing contract report is retained.

## Result

No actionable defect was confirmed in the current scrolling addition or
diagnostic/guard revision. The original structures GPU run did fail and must
remain recorded as a failed attempt. The latest root-owned GPU rerun completes
both relevant suites without diagnostics:

- `gpu/20261105T081357Z/test_layout_strategy_structures_ui.log`:
  **348 checks, 0 failures**.
- `gpu/20261105T081357Z/test_layout_strategy_explanation_ui.log`:
  **481 checks, 0 failures**.

Both complete logs and `results.json` were read. The manifest records exit 0,
empty error arrays and separate isolated
`VonNeumannBottleneckChecks/20261105-round8/...` profiles; the logs identify
Apple M2 OpenGL. These are reviewed root-owned results, not executions by this
reviewer.

## Scroll addition

`experiments/layout_strategy/lab.gd:569-570` now calls `scroll_to_item` only after
the rebuilt explanation table has a non-null selected item. The item belongs to
that just-rebuilt table; the existing scope selection and first-row fallback
precede it. The operation changes the table's visible scroll position and does
not select a different Session run, alter a baseline, replay a plan or write a
file.

This addresses retaining an irrelevant old scroll offset after the table changes
lens/rows. It has no direct path into `open_challenges`. The empty legacy target
fixture opens a new host on Compare and never enables explanation mode.
Actual final frame readability remains with the assigned visual reviewers;
this report does not substitute source inspection for pixel acceptance.

## Original nil failure and narrowed cause

The complete original log
`gpu/20261105T075637Z/test_layout_strategy_structures_ui.log` contains:

```
Invalid access to property or key 'retry_button' on a base object of type 'Nil'
at: empty_legacy_targets (...:443)
```

The failure occurred after both languages' earlier structural captures, at the
English empty-map fixture. Its trailing `PASS ... 342 checks, 0 failures` is
not acceptance: the failed function never reached its remaining assertions.
Root's batch manifest correctly classified the run as failed (`code: -2`,
nonempty `errors`) despite that printed line.

The current relevant source narrows the failure:

1. `tests/test_layout_strategy_structures_ui.gd:438-444` creates a fresh host,
   injects a real viewport click, then reads `host.challenge_window`.
2. `tests/test_layout_strategy_ui.gd:32-42` computes the button's current global
   center, pushes mouse-down/mouse-up on successive frames, and settles.
3. `experiments/layout_strategy/lab.gd:1160-1186` creates and assigns the
   `ChallengeWindow` synchronously after its modal/exit guard. There is no
   awaited creation step or empty-target early return.

Therefore a null member at this point means the open action was not reached or
returned through its modal/exit guard before creation. It does not indicate a
failed target-save operation or an asynchronous target-load result.

The first failing run lacked before/after input-state diagnostics, so its exact
cause is **not established**. A transient viewport click/focus dispatch or
modal/exit state at dispatch remains possible; none is proven. No speculative
runtime retry, persistence change or reducer change is justified by this single
unreproduced observation.

## Guard and rerun evidence

`tests/test_layout_strategy_structures_ui.gd:441-449` now logs both states and
asserts that the click opened a valid visible window before dereferencing it.
If the member is null, it safely closes the host after recording a failed
check. It does not retry, directly invoke the action, skip the assertion or
convert an unsuccessful click into success. If a window exists but is hidden,
the visibility check remains a failure; later popup helpers independently
require visible enabled focused controls.

The final diagnostics show, for both languages:

- Before the click: viewport 960x640, Compare tab, visible enabled Challenge
  button, `blocked=false`, `exit=false`, and no existing challenge window.
- Chinese bounds `(621,515)` size `(69,39)` and English bounds `(648,515)`
  size `(118,39)` are entirely within the viewport.
- After the click: a real `ReplayChallenges` window exists, is the exclusive
  modal, and the underlying Challenges button held focus before the popup's
  deferred focus restoration.

The remaining empty-map copy assertions then ran. The final count is 348,
covering both added open assertions and the previously interrupted remainder.
The latest evidence establishes a successful guarded rerun; it does not
retrospectively identify the first dispatch failure.

## Snapshot binding

All three current files below match the root QA project
`.godot/verification/20261105T070528Z-49a63b5c/project` byte-for-byte:

| File | SHA-256 |
| --- | --- |
| `experiments/layout_strategy/lab.gd` | `c88d8ef8e87dedc9fef185bebf120cc2c8e34dee70b069057d27a2cb13b5b7b4` |
| `tests/test_layout_strategy_structures_ui.gd` | `a72de1f22b9fc31bae971afad0a4fe0ab70ca2e62fa7bee3e4db2c767fa827da` |
| `tests/test_layout_strategy_explanation_ui.gd` | `8db5791581fd6a60d161b8e467387f4966e65d62fc81082ec4328957d4733410` |

Logs are relative to `.godot/verification/20261105T070528Z-49a63b5c/`:

| Log | SHA-256 |
| --- | --- |
| `gpu/20261105T075637Z/test_layout_strategy_structures_ui.log` | `a041d400907601b12b7bc66bb973c776fa5730bba5a6c0be07c8e011acdc8e5d` |
| `gpu/20261105T081357Z/test_layout_strategy_structures_ui.log` | `78ed5972efc61aba069343ef82385ccb37741494b61887d0048ef6fb8e5c59d2` |
| `gpu/20261105T081357Z/test_layout_strategy_explanation_ui.log` | `96414e5e3f68dc3258c0b9383dff3d126fc9f8339e574a0d83f3d2ef4bf65409` |

Native input, exported/cross-platform operation and newcomer acceptance remain
outside this review.
