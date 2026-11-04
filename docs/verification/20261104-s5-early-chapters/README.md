# S5: machine and measured results

Chapter 1 opens its existing profiler beside the machine after official runs.
The first-diagnosis compute/wait reveal gate is preserved. A second complete
correct run compares actual receipt cycle totals; failed/debug runs hide it.
Chapter 3 compacts the parts tool on entry, frames the machine beside mission
or timeline, and replays the existing real event states from cycle zero.
Incomplete trials retain the last complete correct comparison.
Chapter 4 opens tools beside the memory map, then results beside the measured
source map. Only actual fill events outline a full transferred RAM row.
Existing same-condition comparisons, hint layers and rule text remain intact.
No simulation, judgement, task ID, reward or save field changed.

## Before/after pairs (10 PNGs)

| Route/state | Before | After |
| --- | --- | --- |
| bottleneck run +1 s | [before](before-bottleneck-run1.png) | [after](after-bottleneck-run1.png) |
| buffers entry | [before](before-buffers-entry.png) | [after](after-buffers-entry.png) |
| buffers run +1 s | [before](before-buffers-run1.png) | [after](after-buffers-run1.png) |
| fields entry | [before](before-fields-entry.png) | [after](after-fields-entry.png) |
| fields run +1 s | [before](before-fields-run1.png) | [after](after-fields-run1.png) |

Godot 4.7.1 stable, Compatibility, 1280x720 Chinese, Test mode, fresh isolated
APPDATA/LOCALAPPDATA. All paired machines use their ordinary starters.
Additional requested routes (including buffers +3 s and mixed entry), logs and
three visually inspected English run frames are in `.godot/s5/`.
English `--locale=en` is supported.

Capture command (replace route, filenames and method for each chapter):
```powershell
$env:APPDATA="$PWD/.godot/s5/<fresh-profile>"
$env:LOCALAPPDATA=$env:APPDATA
$godot='E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
& $godot --path "$PWD" -- --test-mode --dev-enter=chapter_3/buffers@2 --dev-shot=<entry.png>@3 --dev-call=workspace_owners:_run_official@4 --dev-shot=<run1.png>@5 --dev-shot=<run3.png>@7 --dev-quit=8
```
Other routes: chapter_1/bottleneck with _run_official; chapter_4/fields and
chapter_4/mixed with _run_all. English frames add --locale=en.

## Verification

Commands below run from this worktree. Prefix for every suite invocation:
`python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`

Initial invocation (17 suites PASS, 0 FAIL; import and user_directory also PASS):
```
--suite test_system_lab_ui --suite test_system_lab_simulation --suite test_system_device_visual_state --suite test_system_evidence_guidance --suite test_overlap_ui --suite test_overlap_simulation --suite test_overlap_player_input --suite test_layout_ui --suite test_layout_simulation --suite test_layout_navigation --suite test_layout_recipe_sources --suite test_layout_preview_selection --suite test_layout_trace_storage --suite test_chapter_workspaces --suite test_chapter_settings_input --suite test_recovery_departure_paths --suite test_global_save
```
Evidence: `.godot/verification/20261104T104802Z-a71bfc89/`.
Expanded invocation:
```
--suite test_system_lab_ui --suite test_system_cost_evidence --suite test_system_trace_source_binding --suite test_system_baseline_continuity --suite test_system_applications --suite test_overlap_ui --suite test_layout_ui --suite test_layout_trace_storage --suite test_target_evidence_guidance
```
8 PASS, 1 FAIL: system UI required visible initial prediction controls. The
final Chapter 1 retains its expanded, non-minimizable mission. Failure evidence:
`.godot/verification/20261104T105317Z-2c73f50c/`.
Final affected-suite rerun:
```
--suite test_system_lab_ui --suite test_overlap_ui --suite test_layout_trace_storage
```
Final affected suites: **3 PASS, 0 FAIL**, plus import/user_directory PASS.
Evidence: `.godot/verification/20261104T105723Z-27fc05c2/`.
All 22 distinct suites have passing evidence; the earlier failure was fixed.
Full test text logs were inspected.

Process recovery command:
`python -X utf8 .godot/s5/test_process_recovery.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`
18/18 PASS (quit, map, lab, close notification, early/late kill for all three
chapters). This baseline lacks the requested process harness: the integration
worktree's Python and probe were copied to scratch, with only ROOT and probe
path adjusted to target this worktree. Logs: `.godot/d1b/process-20261104-185448/`.

## Limits

No impact-analysis proposals. Chapter 1 deliberately preserves the diagnosis
reveal gate. Chapter 4 highlights the selected event without timed playback.
No separate overlap prediction/difficulty suites exist in this baseline;
overlap UI/simulation and target-evidence cover its current contracts.
Native input, newcomer comprehension, other resolutions and full CI remain
unverified. Baseline and changed runs emit the Windows root-certificate warning.


## Round 2 ? result headlines and clear primary actions

Chapter 1 leads with the shared read-only cycle budget bar, using the measured
2352 total / 1848 waiting cycles. The original first-diagnosis text and gated
CPU/RAM/Bus component breakdown remain unchanged. Chapters 1, 3 and 4 register
their toolbars with the existing opening-card avoidance mechanism.
Chapter 3 colours the measured result summary green when correct and within its
target, amber otherwise. Chapter 4 leads each order with its actual verdict and
RAM traffic, followed by cycles/peak scratch and existing actions. Details retain
phase costs, read/write traffic, contract gaps, initial/best measurements, exact
outputs and the same-condition comparison (including peak-scratch delta).
RAM and cycles also show previous ? current values, green for less, amber for
more. Incomplete runs still cannot replace a complete correct comparison.
The source table tints every recorded fill row and sums its real byte counts;
repeated fills count repeatedly. The selected-event outline remains separate.
No simulation, judging, progression, task identity or save format changes.

### Round 2 comparisons (10 additional PNGs; 20 total)

| State | Before Round 2 | After Round 2 |
| --- | --- | --- |
| bottleneck run +1 s | [before](round2-before-bottleneck-run1.png) | [after](round2-after-bottleneck-run1.png) |
| buffers run +1 s | [before](round2-before-buffers-run1.png) | [after](round2-after-buffers-run1.png) |
| fields entry | [before](round2-before-fields-entry.png) | [after](round2-after-fields-entry.png) |
| fields run +1 s | [before](round2-before-fields-run1.png) | [after](round2-after-fields-run1.png) |
| fields run +1 s, English | [before](round2-before-fields-en-run1.png) | [after](round2-after-fields-en-run1.png) |

The same Round 1 capture command/routes were used, with `.godot/s5b/` output and
fresh isolated profiles. Entry, +1 s and +3 s were also captured for bottleneck,
buffers, fields and mixed; fields English entry/run was visually inspected.
Other frames/logs remain in `.godot/s5b/`. All selected frames are 1280?720.
The opening card is below the toolbar in Chinese and English at entry and run.

### Round 2 verification

Exact command from the worktree root:
```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_system_lab_ui --suite test_system_lab_simulation --suite test_system_device_visual_state --suite test_system_evidence_guidance --suite test_overlap_ui --suite test_overlap_simulation --suite test_overlap_player_input --suite test_layout_ui --suite test_layout_simulation --suite test_layout_navigation --suite test_layout_recipe_sources --suite test_layout_preview_selection --suite test_layout_trace_storage --suite test_chapter_workspaces --suite test_chapter_settings_input --suite test_recovery_departure_paths --suite test_global_save --suite test_system_cost_evidence --suite test_system_trace_source_binding --suite test_system_baseline_continuity --suite test_system_applications --suite test_target_evidence_guidance
```
Initial run: 21 PASS / 1 FAIL, import/user_directory PASS, at
`.godot/verification/20261104T110728Z-52e20031/`. Layout UI still looked for RAM
in the old metrics node; it now checks the headline. The new source-row byte
assertion subsequently caught reset-on-event-selection and this was corrected.
That intermediate rerun is retained at
`.godot/verification/20261104T110950Z-b78d3b75/` (1 PASS / 1 FAIL).

Final affected checks:
```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_layout_ui --suite test_layout_trace_storage --suite test_target_evidence_guidance
```
3 PASS / 0 FAIL, import/user_directory PASS, at
`.godot/verification/20261104T111344Z-da50f9c9/`; source storage 54 checks and
bilingual target guidance 108 checks. All 22 distinct requested suites have
passing evidence. Full test logs were inspected.

After retaining the detailed read/write and peak-delta text, final receipt check:
```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_layout_ui --suite test_layout_trace_storage
```
2 PASS / 0 FAIL, import/user_directory PASS. Final receipt:
`.godot/verification/20261104T111531Z-e3f78d10/`.

Process recovery (same scratch harness as Round 1):
```powershell
python -X utf8 .godot/s5/test_process_recovery.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
```
18/18 PASS; evidence `.godot/d1b/process-20261104-191121/`, summary
`.godot/s5b/recovery.log`. Quit/map/lab/close/early kill/late kill for all three
chapters use isolated profiles. `git diff --check` passes.

### Round 2 limits

No proposals needing impact analysis. Source row shading summarizes the selected
order's complete recorded fills, including preparation and repeated queries;
it is not timed playback or a claim of cache residency. Scratch views retain
the existing allocation-aware selected-event presentation. Native manual input,
newcomer comprehension, other resolutions, exported builds and full CI remain
unverified. The unchanged Windows root-certificate warning occurs in baseline
and final logs. Shared `cycle_budget_bar.gd` was reused without editing it.
