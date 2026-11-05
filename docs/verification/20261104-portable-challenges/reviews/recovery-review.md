# Round 3 recovery follow-up review — 2026-11-04

Reviewer `/root/audit_polish`; read-only review. Both prior P2 findings and the C1 title note are resolved in the inspected source. No further actionable finding in this focused follow-up.

- `layout_chapter.gd:810–816` recognizes the active target row and inspects/pins its retained exact code and title. The Window labels this operation **Keep target / 保留目标** and explains that sorting does not change it. Selecting another row still uses the chosen objective normally.
- Controller recovery now selects the actual target TreeItem, leaves cycles sorting active against a space target, emits the visible action, and compares the complete retained code. This closes the original test gap.
- `_challenge_storage_text()` distinguishes a currently retained failed proposal from the next scene's older saved entry or absence of any saved entry. Both leave/reopen branches are covered.
- Local title sanitation now matches the store's C0/DEL/C1 bounds.
- The Window fixture's use of TextEdit insertion tests the editable control's real change notification; it does not weaken stale-preview rejection. The stale-code fixture now starts from normalized `Code.decode(...).challenge`, avoiding an accidentally noncanonical numeric representation.

## Fresh evidence independently read

Root executed these checks; this reviewer did not launch Godot.

`.godot/verification/20261104T210749Z-5839019c/headless-/20261104T211156Z/`

- `test_layout_challenge_window.log`: **106 checks, 0 failures**.
- `test_layout_challenge_controller.log`: **66 checks, 0 failures**.
- `test_layout_scoreboard_ui.log`: **44 checks, 0 failures**.
- Matching `results.json` records all three exit codes 0 and no errors. Full logs were read.
- SHA-256 of reviewed `layout_chapter.gd`, `layout_scoreboard_window.gd` and `test_layout_challenge_controller.gd` matches the executed QA copy.
- `git diff --check` passes.

The initial failed fixture observations remain in the earlier `20261104T210904Z` batch. This review does not infer GPU clipboard/focus, native OS input or exported-package acceptance from the passing headless rerun.
