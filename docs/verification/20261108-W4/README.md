# W4 · Prediction workbench

1280×720, Godot 4.7.1 stable, isolated Test profiles. No model, predictor,
catalog, task judgement, simulation metrics or save changes.

## Round 2 review fixes

Handbook now uses the Hint/Journey map ghost style. The rules column is 320 px
(previously 390), keeping Task and machine reachable and giving results 70 px
more width. Timeline height is 100 px with prediction Off and 120 px with
prediction enabled (previously 142); actions sit closer to the cards.
Reveals follow the latest revealed card after layout; completed/selected runs
**return to the first card**. Long streams still use horizontal scrolling.
Owned English strings now separate labels, values and units, including
`Record #2`, `Fallback 12`, `queue 0`, and singular `Fetch 1 cycle`.

All six `after-*.png` routes below were recaptured at 1280x720 and visually
inspected; the four before images are unchanged. No model/save changes.

Final receipt: `.godot/verification/20261107T164809Z-5d9aa149/results.json`.
The same six-suite command below passed **6,953 checks, zero failures**
(presentation 1,200; other suites unchanged). Import and isolation passed.
GPU presentation against that receipt's project passed **1,320 checks, zero
failures**, engine exit 0; `.godot/w4-scratch/round2-final-gpu.log`.
The added checks cover handbook styling, rules width, idle spacing, completion
scroll reset, rapid-reveal latest-card visibility, and English formatting.
An intermediate English spacing assertion failed and was corrected before
this final receipt; earlier logs remain in `.godot/verification/`.

Reproduction uses the commands below with `$qa` set to the final receipt's
`project`, and fresh `round2-final-gpu-data` / `round2-final-gpu-local` profiles.
Capture uses `W4_PHASE=after` and fresh `round2-capture-data` /
`round2-capture-local` profiles; log `.godot/w4-scratch/round2-capture.log`,
engine exit 0. The existing certificate-store warning remains unrelated.
Native OS input and novice comprehension remain unverified.

## Changes and owner-review trade-offs

| Before | After | Review |
| --- | --- | --- |
| One unknown chip before revealing; actions in lower left | Stream-length placeholders, revealed addresses/costs, and actions share the main timeline | Default stream length is now visible; future addresses, decisions and costs remain hidden |
| Comparison sentence includes both time and bytes | Two measured cycle totals plus signed, coloured delta; full traffic/cost details remain in Result | Time comparison has priority; details require the existing scroll area |
| Draft-reset warning occupies a helper line | Same warning is the rule strip tooltip | Less persistent text; discoverability trade-off |
| Lower panels repeat their purpose in titles and history instructions | Existing tabs identify result, event detail and history | Removes duplicate text and leaves records clickable at 720p |
| Journey header has one context-dependent return and Quit | Journey map → Laboratory → Settings; standalone retains muted Quit | Both exits retain the temporary-data discard guard; OS close still handles quit |
| Long timeline scrolls to the end | Prefix follows the latest revealed request; completed runs begin at the first request | Horizontal scrolling remains necessary for guessing rules |

## PNG pairs

All four pairs use the same regular-stream session and control values.
The scene's initial card has settled before the initial captures.

| State | Before | After |
| --- | --- | --- |
| Regular, idle, Off | [before](before-regular.png) | [after](after-regular.png) |
| Reveal next ×3, Off | [before](before-prefix.png) | [after](after-prefix.png) |
| Run to end, Off | [before](before-off.png) | [after](after-off.png) |
| Change only rule to Last stride, run to end | [before](before-stride.png) | [after](after-stride.png) |

Additional final screens: [English completed stride](after-english.png),
[alternating settled, stride](after-alternating.png). Inspected rendered PNGs for
overlap, clipping and text size. Cards outside the horizontal viewport are
intentionally scrollable. The ten PNGs here are the review set.

## Round 1 verification

From the worktree root:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_prediction_workbench_presentation --suite test_prediction_navigation --suite test_prediction_player_input --suite test_prediction_slice --suite test_prediction_record_source --suite test_prediction_goal_feedback
```

Fresh isolated receipt: `.godot/verification/20261107T163409Z-9f4fc698/`.
Import and user-directory isolation PASS. Six suites PASS, **6,940 checks, zero
failures**: presentation 1,187; navigation 33; viewport input 54; slice 5,591;
record source 28; goal feedback 47. The final GPU run below adds two assertions
for rapid-reveal scrolling, one in each locale.

```powershell
$qa = "$PWD/.godot/verification/20261107T163409Z-9f4fc698/project"
# QA copy updated with the final presentation test before this run.
$env:APPDATA = "$PWD/.godot/w4-scratch/gpu-final-data"
$env:LOCALAPPDATA = "$PWD/.godot/w4-scratch/gpu-final-local"
& E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --path $qa --script res://tests/test_prediction_workbench_presentation.gd --windowed --resolution 1280x720 -- --workbench-capture --capture-size=1280x720
```

GPU presentation **PASS: 1,309 checks, zero failures**, both locales and all three
tasks. Full log: `.godot/w4-scratch/gpu-final.log`; extra GPU PNGs:
the QA copy's `.godot/workbench-captures/`.

The unchanged baseline record-source test passed 28 checks; its previously
reported failure did not reproduce. Baseline viewport-input test passed 54.
The resized history page initially prevented selecting an older record; removing
the duplicate history instruction restored its 54/54 result.

Navigation tests changed only to assert the requested map/laboratory header and
exercise quit through the existing OS-close/public-method path. Presentation
tests now expect fixed placeholders rather than a growing count of cards, check
nonoverlapping controls and a result-derived zero delta. Existing source,
immutability, prefix secrecy, goals and geometry assertions remain.

## Capture reproduction

The exact capture driver is `.godot/w4-scratch/capture.gd`. It instantiates the
real scene in candidate-journey mode, waits eight seconds at entry, then captures
idle → three `step_current()` calls → `run_current()` → rule index 1 and
`edit_policy()`/`run_current()` → English → alternating (eight-second settle).
All controls were separately exercised through viewport input by the input suite.

```powershell
$env:APPDATA = "$PWD/.godot/w4-scratch/review-data"
$env:LOCALAPPDATA = "$PWD/.godot/w4-scratch/review-local"
$env:W4_PHASE = 'review'
& E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --path $PWD --script res://.godot/w4-scratch/capture.gd --windowed --resolution 1280x720 -- --test-mode --capture-size=1280x720
```

Scratch profiles/logs are inside the worktree's ignored `.godot/w4-scratch/`
because the managed sandbox permits writes only inside this worktree. No real
player save was used. Windows root-certificate-store warnings occurred in baseline
and final runs; the verifier explicitly excludes this unrelated engine warning.

## Files and limits

- `experiments/prediction/lab.gd`: timeline, comparison, navigation, compact layout.
- `tests/test_prediction_workbench_presentation.gd`: updated presentation assertions.
- `tests/test_prediction_navigation.gd`: requested header and departure expectations.
- `localization/game.zh_CN.po`, `localization/game.en.po`: append-only W4 block for new timeline wording; inline bilingual presentation follows the existing scene convention.
- This README and ten comparison PNGs.

No proposals requiring simulation or save impact analysis. No commits or shared
style edits. Novice comprehension and subjective visual preference remain for
owner review; automated input and rendered evidence do not establish those.
