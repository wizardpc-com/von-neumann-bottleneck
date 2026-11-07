# W5 creation workbench

Presentation only. Model, codec, session, catalog, judgement, save schema and result values are unchanged. The original signal symbols are preserved.

## Before / after (owner review)

- `before-c1.png` / `after-c1.png`: duplicate full-width selector and language row removed from view; pager arrows replace Previous/Next. Handbook, Undo/Redo and More tools share the next-action line. Language stays in Settings; the legacy nodes/methods remain callable.
- `before-c1-run.png` / `after-c1-run.png`: real Learn then predictive packet restoration; the same source, frozen rules and restored cells remain visible, with readable captions.
- `before-g3.png` / `after-g3.png`: the empty evidence page is hidden until tools, evidence or results are requested; a compact centered four-stage path shows the real selected count, frozen-rule state, generated length and saved-work count.
- `after-p1.png`: prediction stage. English: `after-c1-en.png`, `after-p1-en.png`, `after-g3-en.png`.
- Header order: title, nine-unit pager, Save draft, Journey map, Laboratory, Settings. Quit is only shown for standalone entry. Laboratory uses the same pending-input/unsaved-draft departure protection.
- The current next action alone is filled; secondary actions use InstrumentTheme tools. Captions/drawn labels have a 13 px floor; body labels retain 14 px or larger.

These default visibility, tool placement, compact stage path and standalone Quit changes are owner-review trade-offs. No proposals require simulation impact analysis.

## Round 2 review

- Completion cue is positioned by the workbench in the result area; shared cue code is unchanged.
- Packet checks say match/mismatch; seen-answer fields say seen/unseen. No raw player-visible boolean strings remain in the workbench.
- Handbook uses the same transparent tool style as Undo/Redo. Opening and edit events report state; the next-action line owns normal progression instructions. The repeated left footnote is removed.
- English draft tabs are Examples / Machine / Recipe and remain visible together at 1280x720.
- All seven after frames are refreshed. Round 2 source changes: `experiments/creation/workbench.gd`, `experiments/creation/signal_view.gd`; evidence changes: this README, refreshed after PNGs, receipt, capture helper and `round2-results.json`. Other Round 1 source/test edits are retained. Model/session/codec/save/task/judgement files remain untouched.

## Reproduction

Initial baseline routes were captured before editing with dev-enter at 2 s, dev-shot at 9 s and dev-quit at 10 s. That helper retains the project's 1600x900 content size when shrinking its window. The retained comparisons were therefore recaptured with `capture.gd` in both the untouched initial verifier copy and final project, explicitly setting both window and content size to 1280x720. It waits eight seconds, moves synthetic viewport hover outside content, and uses real Host operations for the run comparison. Every process has fresh APPDATA and LOCALAPPDATA beneath this worktree's ignored `.godot` scratch directory; no player profile is used.

```powershell
$env:APPDATA="$PWD\.godot\review-c1"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script res://docs/verification/20261108-W5/capture.gd -- --test-mode "$PWD\.godot\review-c1.png"
```

Insert `p1`, `g3`, `flow`, or `en` before the output path as needed. Use a new profile directory per invocation. Baseline copy: `.godot/verification/20261107T161725Z-930322d9/project`.

## Verification

Round 2: all nine headless suites passed (1502 checks); final GPU workbench passed (461 checks). All seven refreshed after frames pass tab-containment and transparent-Handbook checks; C1 after-run also passes completion-cue/button non-overlap checks. The final cue offset was adjusted after the nine-suite run; final-source GPU and captures cover it. Logs: `.godot/verification/20261107T164532Z-d0392a31/`; structured results: `round2-results.json`. Headless workbench was also replayed on the final offset.

The Settings/CPG GPU results below are Round 1 evidence, not rerun in Round 2. Native input/play acceptance remains unverified.


```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_cpg_connection_fragment --suite test_creation_navigation --suite test_creation_comparison_view --suite test_creation_playable_loop --suite test_creation_sample_editing --suite test_creation_work_focus --suite test_creation_edit_controls --suite test_creation_draft_undo
```

Nine headless suites passed, 1502 checks, zero failures. Import and isolated user-directory checks passed. Logs: `.godot/verification/20261107T162356Z-9525f34e/`. The final header-only adjustments (longer English prediction title and retained offline-feedback button moved to the secondary row) are covered by the final GPU reruns below.

Presentation-test changes: workbench bounds require Laboratory in place of the hidden language shortcut; the playback-note assertion is 13 px; editing/sample tests invoke the retained language rebuild method because its toolbar shortcut is hidden. Real Settings language coverage is separate.

Serial GPU workbench replay passed 461 checks; real Settings localization passed 511 checks with zero failures. The GPU CPG suite fails on feedback viewport/focus and the following Escape chain, while its layout/ancestor-boundary checks pass. The untouched baseline reproduces the exact same ordered 12 failures (four focus/Escape assertions repeated three times); no additional final-source GPU failures occur. Baseline workbench and CPG test bytes match HEAD exactly. Logs: `.godot/last-test_cpg_connection_fragment.log`, `.godot/baseline-cpg-gpu.log`, `.godot/last-test_creation_workbench.log`, `.godot/last-test_late_settings_localization.log`. GPU commands use the same isolated imported project, fresh per-suite profiles and `--script res://tests/<suite>.gd -- <capture-flag>`. Exact flags: `test_creation_workbench --creation-capture`; `test_cpg_connection_fragment --cpg-connection-capture`; `test_late_settings_localization` (no flag).

## Limits

Synthetic viewport events and controller captures do not establish native mouse/keyboard or unaided play acceptance. Human review should check the new tool placement and stage path. Broad simulation, exported-package and listening acceptance were not rerun. The CPG GPU feedback-focus failure remains a known baseline limitation, independently reproduced serially; headless CPG checks and rendered geometry pass. Godot logs include a system certificate-store diagnostic.
