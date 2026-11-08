# B4 · Chapters 6–10 design-system application

Presentation-only candidate for owner review. Six source files changed; no simulation, state/catalog, task IDs, result judgement, save fields, shared style files, or localization entries changed.

## Changes and owner choices

- `experiments/service_plan/lab.gd`: move/join/undo/redo/representation actions use tool; structural edits and restore/pin/save actions use secondary; actual navigation uses nav. Local tabs use terminal surfaces. Keep the boxed navigation-like edits (left) or choose the quieter tools (right): separates editing from navigation while retaining one filled Run.
- `experiments/service_plan/state_replay_view.gd`: tool replay controls and 14 px body labels at the narrow viewport.
- `experiments/prediction/lab.gd`: explicit secondary Run to end/New run, nav for navigation; terminal tabs with narrow-column reading margins. Keep the grey results well (left) or choose terminal blue-black (right): consistent evidence hierarchy.
- `experiments/creation/workbench.gd`: nav Handbook/navigation, secondary major alternative actions, ghost local tools, existing filled Next step retained. Explanatory body requests use 14 px; short metadata and the long measured A/B summary explicitly use 13 px. Local tabs use terminal surfaces. Removed local completion-toast offset; shared safe placement handles it. Keep the compact grey/ghost presentation (left) or choose larger body text and outlined alternatives (right): easier reading with more scrolling in the recipe/examples column.
- `experiments/creation/work_focus.gd`: nav feedback/return and tool playback/view actions.
- `experiments/creation/comparison_view.gd`: tool context/difference inspection and nav side selection.

Old appearances remain reviewable in native-pixel baseline/after sheets; no player-facing setting added.

## PNG comparisons

Nine PNG files. Comparison sheets preserve all source pixels: BEFORE left, AFTER right; settled entry top, measured state bottom. G3 has entry only. English sheets use the same top/bottom sequence.

| Route | Comparison | English |
| --- | --- | --- |
| `service/move_state` | [service-before-after.png](service-before-after.png) | [service-english.png](service-english.png) |
| `prediction/regular` | [prediction-before-after.png](prediction-before-after.png) | [prediction-english.png](prediction-english.png) |
| `creation/C1_restore` | [creation-before-after.png](creation-before-after.png) | [creation-english.png](creation-english.png) |
| `creation/G3_keep` | [keep-before-after.png](keep-before-after.png) | [keep-english.png](keep-english.png) |

[Repeat-pass safe placement](creation-repeat-pass.png): learning then predictive transport, followed by a second predictive transport. The toast sits in the upper-right signal margin, below header actions and clear of buttons. Its `????` text also appears in the untouched baseline; shared cue/localization is outside B4 ownership.

### Reproduction

All engine launches use fresh `APPDATA` and `LOCALAPPDATA` below `.godot/b4-temp/<run>/`, inside this writable worktree. No real save accessed. Scratch captures, launch logs and helper scripts remain there. Initial import was repeated by the isolated verifier; fresh-worktree first import initially needed to generate the font cache.

```powershell
$GODOT = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$WT = 'E:\VNB\temp\claude-visual-20261108\wt\b4'
$env:APPDATA = "$WT\.godot\b4-temp\UNIQUE-RUN\APPDATA"
$env:LOCALAPPDATA = "$WT\.godot\b4-temp\UNIQUE-RUN\LOCALAPPDATA"
New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
& $GODOT --audio-driver Dummy --path $WT -- --test-mode --dev-enter=service/move_state@2 --dev-shot=ABS_ENTRY.png@9 --dev-click=151,669@10 --dev-shot=ABS_RUN.png@13 --dev-quit=19
```

Prediction substitutes `prediction/regular` and click `164,328@10`. Creation substitutes `creation/C1_restore`, clicks `1200,60@10`, `1200,60@12`, `350,675@15`, with measured/repeat screenshot at `@16`. G3 substitutes `creation/G3_keep` with no clicks. Add `--locale=en` for English. Each image is a real 1280×720 viewport; contact sheets are lossless concatenation without scaling.

## Verification

Final isolated verifier: **12/12 suites PASS, 0 failures**, plus import and user-directory checks PASS. Every entry in `results.json` has exit 0. Evidence: `.godot/verification/20261107T192058Z-00c47ada/`. After the final creation margin/caption repair, all six creation suites were repeated: **6/6 PASS**, import/user-directory PASS, `.godot/verification/20261107T193253Z-1cfcf254/`. PowerShell's outer log includes a Git global-ignore permission warning; suite exits and structured results are the authority.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_service_learning_ui --suite test_service_split_actions --suite test_service_state_replay_view --suite test_service_number_display --suite test_prediction_workbench_presentation --suite test_prediction_player_input --suite test_creation_workbench --suite test_creation_work_focus --suite test_creation_comparison_view --suite test_creation_keyboard_focus --suite test_creation_route_flow --suite test_creation_choice_completion
```

Final creation-only rerun (same isolated user-directory setup):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_creation_workbench --suite test_creation_choice_completion --suite test_creation_keyboard_focus --suite test_creation_route_flow --suite test_creation_work_focus --suite test_creation_comparison_view
```

| Suite | Headless passing checks | GPU passing checks |
| --- | --- | --- |
| `test_service_learning_ui` | 51 | ? |
| `test_service_split_actions` | 30 | ? |
| `test_service_state_replay_view` | 71 | ? |
| `test_service_number_display` | 24 | ? |
| `test_prediction_workbench_presentation` | 1200 | 1320 |
| `test_prediction_player_input` | PASS (no count reported) | ? |
| `test_creation_workbench` | 385 | 461 |
| `test_creation_work_focus` | 31 | ? |
| `test_creation_comparison_view` | 42 | ? |
| `test_creation_keyboard_focus` | 22 | ? |
| `test_creation_route_flow` | 18 | ? |
| `test_creation_choice_completion` | 87 | ? |
| `test_service_journey_input` | ? | 15 |

GPU: **3/3 targeted presentation/input suites PASS**, exit 0. Exact command form (with the fresh user-directory setup above):

```powershell
& $GODOT --audio-driver Dummy --path $WT --script res://tests/test_prediction_workbench_presentation.gd -- --workbench-capture --capture-size=1280x720
& $GODOT --audio-driver Dummy --path $WT --script res://tests/test_creation_workbench.gd -- --creation-capture
& $GODOT --audio-driver Dummy --path $WT --script res://tests/test_service_journey_input.gd --
```

Logs: `.godot/b4-temp/gpu-<suite>.log`, e.g. `gpu-test_creation_workbench.log`. Final creation-workbench rerun: `.godot/b4-temp/gpu-final-test_creation_workbench.log`. Every GPU run has its own `.godot/b4-temp/gpu-<suite>/{APPDATA,LOCALAPPDATA}`.

Additional GPU `test_creation_playable_loop -- --creation-capture`: **212 checks PASS, exit 0** on the final isolated candidate, without diagnostic test edits. Log: `.godot/b4-temp/gpu-playable-verified.log`; project: `.godot/verification/20261107T192058Z-00c47ada/project/`. Same command form as above, substituting that script and `--creation-capture`.

Earlier candidate geometry triggered a native signal 11 after repeated deleted-callback messages, then a 240 s harness timeout. Untouched `407dddb` passed 212 checks (`gpu-playable-baseline.log`), so it was treated as a candidate regression. Final creation tabs preserve narrow-column reading width and the long measured A/B caption stays at 13 px. The corrected route passed 212 checks twice: diagnostic `gpu-playable-margin.log` and clean `gpu-playable-verified.log`. The failing logs remain in scratch; no crash or timeout is counted as PASS.

`git diff --check` PASS. Final source review confirms only presentation changes. No presentation tests required changed expectations.


## Limits / proposals

- Existing 1600×900 stretch policy reduces logical font sizes in physical 1280×720 route screenshots. This patch raises local logical body requests without changing the shared scaling policy.
- Larger creation prose exposes fewer examples/recipe lines at once; existing scrolling retains all content. Owner should compare this density choice.
- Shared repeat-pass cue text renders as `????` in both baseline and candidate; lead should inspect shared localization/cue text separately.
- Automated input/rendering and fixed routes do not establish newcomer usability, native keyboard/IME acceptance, or packaged-build acceptance. No new gameplay proposal needing impact analysis.
