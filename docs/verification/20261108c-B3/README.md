# B3 · Chapters 4 and 5 design system · 2026-11-08

Candidate from `407dddb`, branch `claude/vux-b3-layout-repr-20261108`. Presentation only. No simulation/state/catalog, localization, shared theme, ranking order, measured number, pass judgement or save field changes.

## Files and observable changes

- `src/layout_chapter/layout_chapter.gd`: explicit nav/tool/secondary/primary assignments; Source/Scratch use quiet tool tabs with selection following the actual visible memory view, including Trace-driven switches. Direct-mode Scratch remains a no-op.
- `src/layout_chapter/layout_scoreboard_window.gd`: local terminal Tree panel, headers and selection; secondary actions and quiet Close navigation. Numeric alignment and sorting unchanged.
- `experiments/representation_region/region.gd`: local matching Tree theme for Blocks, order comparison and events; compact natural-width level tabs with current-task marker; handbook nav; local edit/replay tools, secondary plan/save actions, Run primary, standalone Quit danger. Labels requested below 14 now use 14 logical px; task tabs 13 → 14. Existing raw-data and drawn secondary annotations retain their 13 px floor.

`byte_board.gd`, `order_cost_strip.gd`, `trace_player.gd` and tests were inspected and remain unchanged. Their drawn text already meets the 14 body / 13 secondary logical floors.

## Owner choices and screenshots

Each PNG stacks **before Chinese / after Chinese / after English**, without resizing the original 1280×720 frames.

| Pair | Route / state | Owner choice |
| --- | --- | --- |
| `00-fields-entry.png` | `chapter_4/fields`, settled | Keep former filled address tabs in baseline; new tool underline distinguishes selected view with less chrome. |
| `01-fields-run.png` | Same, Run all cases | Existing run/result arrangement retained; explicit secondary rankings and nav rules entry give Run the strongest emphasis. |
| `02-rankings.png` | Same, rankings opened after run | Black/default grey table retained in baseline; new graphite table joins the terminal family. |
| `03-representation-entry.png` | `representation/mixed_scan`, settled | Equal expanded level boxes retained in baseline; natural-width tool tabs expose current task and free horizontal space. |
| `04-representation-run.png` | Same, Run current draft | Boxed edit actions retained in baseline; new quiet tools and outline plan/save actions distinguish local editing from execution. |

No information is newly hidden. The old look remains reviewable in every first frame; no user-facing option was added.

## Reproduction

Sandbox write access is limited to this worktree, so scratch, logs and isolated user data use `.godot/b3-temp/` instead of the requested sibling temp directory. Set fresh APPDATA and LOCALAPPDATA for every Godot launch. Engine: `E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

Capture helper `.godot/b3-temp/capture.py after` and `capture.py after en` uses test mode, enter at 2 s, entry at 10 s; chapter 4 Run click (1210,65) at 12 s, run at 15 s, rankings click (1100,65) at 16 s, rankings at 18 s, quit at 19 s. Chapter 5 Run click (250,459) at 12 s, run at 15 s, quit at 16 s. All paths absolute. Captures use real starter-draft measurements, not passing fixtures. Chapter 5 replay starts automatically as before; its transient highlighted event can vary with rendered timing, while measured totals remain identical.

Entry and chapter 4 baseline frames were captured before edits. The first chapter 5 run click missed; its corrected run baseline was recaptured from the exact unchanged HEAD `region.gd`, with candidate bytes restored in a `finally` block. `.godot/b3-temp/baseline-run-corrected.log` records that route. No Git restore/reset was used.

## Verification

Headless command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_layout_ui --suite test_layout_navigation --suite test_layout_scoreboard_ui --suite test_layout_challenge_window --suite test_layout_challenge_controller --suite test_representation_workbench_presentation --suite test_late_handbook_access
```

Results: `.godot/verification/20261107T190209Z-18100acd/results.json` and full per-suite logs. Import and user-directory probes PASS. **7/7 suites PASS, 0 failures.** This snapshot precedes the final memory-tab visibility synchronization and explicit Save secondary assignment; final rendered checks cover those small follow-ups.

| Suite | Headless passing checks |
| --- | --- |
| test_layout_ui | PASS (no count emitted) |
| test_layout_navigation | PASS (no count emitted) |
| test_layout_scoreboard_ui | 44 |
| test_layout_challenge_window | 106 |
| test_layout_challenge_controller | 66 |
| test_representation_workbench_presentation | 10173 |
| test_late_handbook_access | 120 |

Final rendered checks use the final source with fresh APPDATA/LOCALAPPDATA per suite, automated by `.godot/b3-temp/final.py` and `.godot/b3-temp/gpu-final.py`. The latter uses the verifier-created copied project with final source files and a fresh `VonNeumannBottleneckChecks/B3-final/<suite>` profile. Three initial launches without that required custom-profile marker were rejected before running; their logs remain under `gpu-test_layout_{scoreboard_ui,challenge_window,challenge_controller}.log`. Final results below refer to the corrected launches:

```powershell
& $Godot --audio-driver Dummy --path $Worktree --script res://tests/<suite>.gd -- <arguments>
```

**Final rendered: 5/5 PASS, 0 failures.** Full-log scan found no unexpected ERROR or FAIL. Machine-readable summaries: `checks.json`.

| Suite | Arguments after `--` | Passing checks | Final log under `.godot/b3-temp/` |
| --- | --- | --- | --- |
| test_layout_ui | none | PASS (no count) | gpu-test_layout_ui.log |
| test_layout_scoreboard_ui | --layout-score-capture | 47 | final-gpu-test_layout_scoreboard_ui.log |
| test_layout_challenge_window | --layout-challenge-capture --capture-size=1280x720 | 120 | final-gpu-test_layout_challenge_window.log |
| test_layout_challenge_controller | --layout-challenge-capture --capture-size=1280x720 | 82 | final-gpu-test_layout_challenge_controller.log |
| test_representation_workbench_presentation | --workbench-capture --capture-size=1280x720 | 2329 | gpu-test_representation_workbench_presentation.log |

Chinese/English entry, run and rankings frames were inspected at original resolution. `git diff --check` passes. No tests needed layout-contract updates. No commit, push, branch switch, stage or shared-checkout edit was performed.

## Limits and impact proposals

Native mouse play, beginner understanding and smaller windows are not acceptance claims. The existing 1600×900-to-1280×720 project stretch means logical 14/13 px is approximately native 11.2/10.4 px. A native 14/13 px floor needs coordinated global-scale/layout impact analysis, outside B3 ownership. No other impact proposal.

The known Windows root certificate diagnostic occurs in baseline and candidate. PowerShell also wraps Git's inaccessible global-ignore warning as a native-command error; use the individual `results.json` entries and complete logs for suite outcomes.
