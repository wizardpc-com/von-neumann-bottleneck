# R1 regression repair

Scope: the accepted uncommitted experience-polish integration on `claude/ux-integration-20261104`. No simulation, judgement, task identity, save format or Git history changes.

| Suite | Cause → decision → fix |
| --- | --- |
| test_candidate_disabled_focus | Header Language is hidden and Quit moved to execution controls; Hint moved ahead of task controls in tree order. (b) Traverse from visible Settings to Quit/review, checking disabled stops throughout. (a) Explicitly link Service task buttons to the next enabled task or Hint, preserving unlock and Undo/Redo tests. |
| test_chapter_return_input | Run enlarged Test Bench over the playback strip. (a) Preserve existing instrument visibility/geometry on run; finish-playback stays accessible. |
| test_settings_language_input | Same chapter-2 run reframing regression. (a) Same production fix. |
| test_terminal_language_input | Same chapter-2 run reframing regression. (a) Same production fix. |
| test_creation_keyboard_focus | Language deliberately moved between Unit and draft history. (b) Check Unit → Language → Previous, retaining unavailable Undo/Redo checks. |
| test_creation_route_access | Chapter browsing selected the first task and hid the list. (a) Restore browsing without selection and show list. (b) Scroll each chapter shortcut into view before checking bounds, matching the accepted larger scrollable strip. All selection, viewport, list-height and progress checks remain. |
| test_creation_save_input | More tools hid evidence tab selectors even with measured output. (a) Show tabs whenever real latest evidence exists and refresh their visibility with results. |
| test_full_journey_narrative | Overlap framing repeatedly stretched and repositioned panels, including making the mission too tall to retain a valid moved position. (a) Frame the graph without assigning panel geometry; preserve open tools on run. |
| test_locality_chapter_ui | Every capstone completion automatically opened the completion overlay. (a) Restore editable capstone completion; explicit mission finish still opens its measured summary. |
| test_ui | Resume now uses the terminal page's localized Back · Esc label. (b) Check the exact localized Back · Esc label while retaining overlay, export, Quit and fullscreen assertions. Restore the protected open-instrument assertion to match production repair. |

Additional neighbouring check: `test_locality_trace_presentation` assumed a direct controller run would automatically open Test Bench. (b) Explicitly open it before running, then retain its existing visibility assertion. This matches the real player run path and the restored protection of player-selected windows. `test_task_tree` also encoded M1 automatic first-task selection: restore its original assertion that chapter browsing shows the list without changing selection. `test_tree_journey_presentation` encoded the same automatic selection: restore its original bilingual list-height and clickable-entry checks. All three neighbouring checks are rerun after the full pass. No production changes after the full-run snapshot.

## Verification

Targeted verification: **10/10 suites PASS, 0 FAIL**, combining unchanged final evidence from the first run and all affected suites rerun in the second. Both runs also pass import and isolated user-directory checks.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_candidate_disabled_focus --suite test_chapter_return_input --suite test_settings_language_input --suite test_terminal_language_input --suite test_creation_keyboard_focus --suite test_creation_route_access --suite test_creation_save_input --suite test_full_journey_narrative --suite test_locality_chapter_ui --suite test_ui
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_candidate_disabled_focus --suite test_creation_route_access --suite test_full_journey_narrative --suite test_ui
```

- First evidence: `.godot/verification/20261104T173203Z-c7274635`; initial intermediate route/floating-window failures and test compilation error retained.
- Final affected-suite evidence: `.godot/verification/20261104T173536Z-dacf1dbd`; 4 PASS, 0 FAIL.

| Final suite | Result | Assertion count where reported |
| --- | --- | --- |
| test_candidate_disabled_focus | PASS | 110 checks, 0 failures |
| test_chapter_return_input | PASS | 51 checks, 0 failures |
| test_settings_language_input | PASS | 120 checks, 0 failures |
| test_terminal_language_input | PASS | 65 checks, 0 failures |
| test_creation_keyboard_focus | PASS | 23 checks, 0 failures |
| test_creation_route_access | PASS | 240 checks, 0 failures |
| test_creation_save_input | PASS | 40 checks, 0 failures |
| test_full_journey_narrative | PASS | 1138 checks, 0 failures |
| test_locality_chapter_ui | PASS | Suite does not print a numeric assertion total |
| test_ui | PASS | Suite does not print a numeric assertion total |

Full verifier (completed):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
```

Evidence: `.godot/verification/20261104T173811Z-7dab96b9`; launch log `.godot/r1/full.log`.


Before/after route images: [R1 evidence](../20261104-r1-regressions/README.md).

## Limits

Headless assertions and scripted GPU captures do not establish physical keyboard input or human play acceptance. No proposals requiring simulation or persistence changes.

## Final full-set result

**247 PASS / 2 FAIL** in the final applicable result set (249 verifier entries, including import and isolated-directory checks).

The single full run produced **244 PASS / 5 FAIL**. Three failures were incompatible presentation-test expectations, corrected in tests only after that snapshot; no production code changed afterward. The three affected suites were rerun and all passed. This is full-run evidence plus scoped final rechecks, not a second full run.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_locality_trace_presentation --suite test_task_tree --suite test_tree_journey_presentation
```

Final scoped evidence: `.godot/verification/20261104T181304Z-3e524fc7` — 3 suites PASS / 0 FAIL, plus import and isolation PASS. `test_locality_trace_presentation`: 140 checks / 0 failures; `test_tree_journey_presentation`: 3314 checks / 0 failures; `test_task_tree` prints no numeric assertion count. `results.json` records exit 0 for every check; the PowerShell wrapper reports a nonzero status despite these successful process results, alongside Git's environment permission warning on stderr.

The only remaining failures are the two baseline failures specified in R1:

- `test_prediction_record_source`: 1 failure / 28 checks, cross-task record/rule caption.
- `test_service_undo_context`: 16 failures / 96 checks, group selection restoration in temporary/persistent zh/en sessions.

All full-run logs were scanned for errors and warnings. Other warnings are root-certificate-store access (excluded by the verifier), opposite-anchor size warnings in desktop/feedback checks, and Git's unreadable global-ignore warning. No additional script errors or failed suites remain in the applicable evidence set.

`git diff --check` passes. Final diff and status inspected. No commits, pushes, merges, branch changes, or real-save access. Native keyboard, exported builds and human experience acceptance remain unverified.

Final hash comparison of `src/`, `experiments/` and `localization/` against the full-run project found no changed production scripts, scenes, resources or PO files. An unrelated concurrent `docs/CURRENT_STATE.md` edit was observed and left untouched.
