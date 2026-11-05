# Round9 Creation GPU route review

Read-only review by `audit_polish`, 2026-11-05. Root retains source/test ownership
and all Godot/Git execution. No source was edited and no engine was run by this
reviewer.

The concrete route defect is that the fixture attempts to click a hidden
`RunCostComparison` button after learning selects another evidence tab. The
original helper accepts that hidden button and only checks that its stored
rectangle center is inside the root viewport. That is insufficient to establish
an actual GUI action. This is supported by the complete source path below and
matches zero recorded comparisons; the original log does not contain visibility
or activation telemetry, so this review does not invent an observed click target.

## Observed failure and source identity

- Full log read:
  `.godot/computation-checks/20261105T101950Z/test_creation_playable_loop.log`.
  It contains the two-machine-observations assertion followed by indexing the
  empty `Array[Dictionary]`, with no earlier model/codec script error.
- The adjacent `results.json` records the actual command, return code `-15`,
  elapsed `203.283935875` seconds and missing suite PASS marker. This is a failed,
  terminated route, not acceptance.
- The command uses the frozen candidate QA project
  `.godot/verification/20261105T095516Z-05af4f51/project`. It uses
  `--windowed --resolution 1280x720` without a capture-size argument.
- Runtime `experiments/creation/workbench.gd` is unchanged from the current
  Round8 HEAD and matches that QA copy byte-for-byte:
  SHA256 `94c7129333a1f3d49a75b28c4345ae0f41028a0e1e56f125aa4a972528215527`.
  No Creation workbench runtime fix should be inferred from the kernel change.
- During review root changed the two test files. The failed QA originals read
  for this diagnosis were:
  `test_creation_playable_loop.gd` SHA256
  `f01a71a92e5de1642bb927c5df168bce8dc5b6b5617e37b170783f8d325f6142`;
  `test_creation_workbench.gd` SHA256
  `2fc4378472e399b63ccf7fc7510a2a3ebf365f6bf379585663e28b2e2f5144e0`.
  These are distinct from the newly edited working-tree fixtures.

## Concrete control path

1. `test_creation_playable_loop.gd` originally calls `change_task(2)`, presses
   `Train`, presses each `MachineConditionN`, then directly asks the helper to
   press `RunCostComparison` (original lines17–22).
2. `workbench.gd:939–963` trains the real model, presents the resulting causal
   evidence and explicitly selects `causal_panel.get_index()` in
   `causal_tabs.current_tab`. The cost ledger is a separate tab.
3. `apply_machine_condition`, lines669–673, calls
   `rebuild_editor_preserving_inputs()`. `_capture_editor_state`, lines1834–1843,
   captures `EvidenceTabs.current_tab`; rebuild, lines1848–1851, restores that
   captured selection through `_restore_editor_state`, lines1881–1883.
   Consequently the initial task2 ledger selection performed by `build()` does
   not remain selected: the causal tab is deliberately restored.
4. `RunCostComparison` is created inside `CostLedgerPage` at lines1940–1953.
   With the causal tab selected this target is hidden. Scrolling its ancestor
   `ScrollContainer` cannot select its enclosing tab.
5. The original shared `press` helper, original
   `tests/test_creation_workbench.gd:12–38`, checks only node existence and
   `disabled`; then scrolls ancestors, takes `get_global_rect().get_center()` and
   checks that this point lies in the root viewport. It neither tests
   `is_visible_in_tree()` nor observes the target's `pressed` signal. The
   headless path emits that signal directly even on a hidden tab, which can
   conceal this fixture defect in non-rendered runs.
6. `compare_transport`, lines1962–1972, runs both actual codecs and appends a
   measured snapshot before checking whether either transport succeeded. It has
   no normal failure return before the append. Thus zero rows with no earlier
   runtime error are consistent with the comparison action not executing,
   rather than an ordinary encoding/decoding rejection producing zero rows.
7. The original fixture continues after the failed count assertion and accesses
   indices0/1. The resulting script error aborts its coroutine before `quit`,
   accounting for the hung process and subsequent root cleanup.

No timing retry is needed to explain the hidden-tab precondition. No synthetic
signal emission can establish that the rendered action was usable.

## Root's in-progress fixture changes

Read-only `git diff` inspection during this review found root has already added:

- Explicit cost-ledger selection before its button click.
- Visible/enabled precondition in the shared press helper.
- A one-shot observer that requires exactly one real `pressed` activation in
  renderer mode.
- Failure exits before the fixture indexes missing comparisons.

Those changes directly address the identified route and its false-positive
helper behavior. They are a test-path repair, not a model or player-UI change.
This review has not seen their rerun result and does not certify them as passing.
The explicit tab assignment also means this fixture does not validate mouse
navigation of the tab strip; it does validate the subsequent button click if
the guarded run passes.

## Minimal follow-up if another click fails

Keep the visibility/activation failure. At that first failure record the target's
path and global rect, root visible rect and size, current `DraftTabs` and
`EvidenceTabs` selections, visible state, pressed-activation count, focus owner,
and visible/clipping ancestor rectangles. Capture the actual root image if
running the capture route. This differentiates hidden control, clipping,
overlap, rebuild/lifetime and viewport-coordinate causes without retrying or
invoking the handler directly.

For fixed-size renderer evidence, the existing testing guide documents
`-- --capture-size=1280x720` to suppress saved-geometry/Retina minimum-window
interference. Its omission is a separate isolation weakness in the failed
invocation, not proof that geometry caused these zero comparisons. Keep native
Mac input and ordinary persistence acceptance separate from deterministic
capture acceptance.

The player UI and both new kernels remain unchanged by this review.
Full-route GPU success, model outcome assertions and any later hidden controls
still require root's fresh engine run.
