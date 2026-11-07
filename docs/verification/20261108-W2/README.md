# W2 · Chapter 5 representation workbench

Scope: presentation only. `model.gd`, `catalog.gd`, `session_store.gd`, simulation traces, task IDs, acceptance, ranking and saves are unchanged. No commits or integration performed.

## Changes and owner-review pairs

| Before | After | Owner review |
| --- | --- | --- |
| Journey has a conditional map/home button and a bottom Quit | Header has Journey map → Laboratory → Settings; standalone Quit remains last in header, with shared muted-red styling | Navigation uses existing unsaved-session guard |
| Selected-order badge can say Met while another order fails; deciding constraint is in folded details | Main line uses the recording's overall accepted verdict and first exceeded constraint, actual/limit and signed delta; successful runs show first-order cycle delta | **Default information hierarchy**: the main verdict belongs to the whole recording; the selector and cost rows identify the inspected order |
| Unrun view contains empty cost, order, playback and history boxes | Catalog target card per order/asset with pending marks; recorded values fill its bars after a run. My designs and protected-plan restore remain reachable even with no recordings | **Default visibility**: empty evidence hidden, detailed evidence still foldable |
| Small replay text, separate partition and codec rows, two primary actions | 14 px replay body / 13 px secondary text, one wrapping tool group, single primary Run, outline Save; table uses a bounded row-based height; numeric columns align right | **Layout**: compact table; first row is selected on entry and Split works immediately |
| Bottom failure plus repeated reading directions | Failure reason remains at bottom; reading directions are available by hovering that feedback | **Reduced default prose** |

## PNGs

All route PNGs are raw 1280×720 dev captures. `before-mixed.png` → `after-mixed.png`; `before-run.png` → `after-run.png`; `before-cross.png` → `after-cross.png`. `english-run.png` and `english-cross.png` cover the same screens in English. The unchanged initial RAW plan is already a failing draft: storage 68 / 60 B, delta +8; cycles 136 / 136.

`native-zh-run.png` comes from the isolated QA `round2_route_probe.gd -- --native`: it instantiates the actual region scene, sets both root size and content_scale_size to 1280×720, waits eight seconds for the opening cue, clicks the actual Run control, steps the actual recorded event and captures the viewport. `.godot/w2/round2-route-native-v2.log` confirms both logical root and scene are 1280×720 and save_png returned 0. `native-en-earned.png` is the presentation test's revalidated successful cross-assets fixture, showing independent costs and recorded-event byte lighting. No image editing was used.

## Verification

Engine: Godot 4.7.1 stable. Every engine process uses isolated APPDATA/LOCALAPPDATA below `.godot/w2` or the verifier's runtime folder. Scratch files stay in this worktree because the assigned external temp path is outside its writable sandbox.

Exact first command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_representation_region --suite test_representation_session --suite test_representation_visual --suite test_representation_workbench_presentation --suite test_representation_edit_context --suite test_representation_closure_navigation --suite test_representation_player_input --suite test_representation_design_shelf --suite test_representation_restored_notice
```

Initial receipt: `.godot/verification/20261107T162005Z-da5e9e26/`. Two presentation suites initially failed: old selected-order main-line assertions and a table-center input click. The assertions now check the actual deciding constraint; the input clicks the actual first TreeItem rectangle. No model expectations were relaxed.

Final affected-suite command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_representation_visual --suite test_representation_player_input --suite test_representation_workbench_presentation
```

Receipt: `.godot/verification/20261107T162343Z-6f2ed669/`. Both verifier imports and user-directory isolation checks passed.

| Suite | Checks | Failures |
| --- | ---: | ---: |
| representation_region | 3329 | 0 |
| representation_session | 47 | 0 |
| representation_visual | 264 | 0 |
| representation_workbench_presentation | 9383 | 0 |
| representation_edit_context | 39 | 0 |
| representation_closure_navigation | 55 | 0 |
| representation_player_input | 71 | 0 |
| representation_design_shelf | 38 | 0 |
| representation_restored_notice | 64 | 0 |
| Total | 13290 | 0 |

After the final feedback-only adjustment, copied the final region/presentation test and append-only catalogs into that same isolated QA project. Ran the complete presentation matrix again (`.godot/w2/final-matrix.log`) and renderer capture (`.godot/w2/renderer.log`):

```powershell
& $GODOT --headless --path "$QA_PROJECT" --script res://tests/test_representation_workbench_presentation.gd
& $GODOT --path "$QA_PROJECT" --windowed --resolution 1280x720 --script res://tests/test_representation_workbench_presentation.gd -- --workbench-capture --capture-size=1280x720
```

Renderer: 2131 checks, 0 failures. Full matrix: 9383 checks, 0 failures. Raw renderer frames remain in `$QA_PROJECT/.godot/workbench-captures/`. Windows root-certificate-store diagnostics occur on baseline and final launches and are excluded by the repository verifier; no network behavior is involved.

Round 2 route capture uses `.godot/w2/round2_route_probe.gd` copied into the final QA project. With fresh APPDATA/LOCALAPPDATA for every launch:

```powershell
& $GODOT --path $QA_PROJECT --windowed --resolution 1280x720 --script res://round2_route_probe.gd -- --locale=en --cross
```

Omit `--cross` for mixed scan; use `--locale=zh_CN` for Chinese and `--native` for logical 1280. The probe enters through TaskNavigation, waits for the opening cue, captures initial state, clicks Run at its actual control rectangle, steps one recorded event, and captures measured state. `.godot/w2/round2-capture.py` repeats these launches with isolated profiles. Ordinary routes retain WindowMode's logical 1600×900 canvas in the physical 1280×720 window; native probe and presentation matrix enforce logical 1280×720.

## Round 2 (Claude review)

Targets now come directly from `Catalog.goals`, labeled with catalog order/asset names. Pending marks contain no measured values; the selected recording supplies measured values even while its draft differs. Cache/link facts occupy one short line on the left. English reading controls have explicit room at 1280×720. The cross-asset draft summary fits one line; default selection was already present and is now explicitly tested.

The draft table no longer expands into spare editor height. The target card and cost overview stay above the right reading scroll; history, protected plans, designs and event playback share that scroll so adding targets cannot squeeze history out of reach. All empty measured instruments remain hidden before a run.

Final nine-suite receipt: `.godot/verification/20261107T164842Z-dc52e48b/`. Round 2 logs are `.godot/w2/round2-final-nine.log`, `round2-final-render.log`, and `round2-route-*.log`. Initial Round 2 checks exposed the replaced mission/evidence assertions and a history viewport squeeze; final assertions follow target-card content and retain exact model expectations. The English preparation feedback overflow was corrected before final verification.

All `after-*`, `english-*`, and `native-*` PNGs are refreshed for Round 2. `before-*` retain the original baseline. Final nine suites: **14,080 checks / 0 failures** (presentation matrix 10,173). Renderer: **2,329 checks / 0 failures**. Each of the 11 verifier JSON entries (import, isolation and nine suites) has `exit: 0`, `passed: true`; the PowerShell envelope flagged Git’s read-only ignore-file warning. Renderer and routes run through the Python launcher with explicit subprocess exit codes.

## Limits / proposals

- Real player saves, sibling worktrees, shared checkout, standalone OS-close behavior and package distribution were not exercised. Existing model/session/guard tests passed; no beginner playtest is claimed.
- Cross-assets' second board remains in the existing independent asset-reading scroll; deep reading and detailed records still scroll.
- Shared WindowMode scales the default logical design canvas into the dev helper's 1280×720 window. The 14/13 logical font floor is verified at native logical 1280; default scaled routes render smaller. A project-wide physical-pixel typography/scaling policy needs lead review in the shared window/theme files, outside W2 ownership.
- The renderer's other raw captures can include the initial guidance cue before it fades; selected delivery frames avoid that obstruction.

Round 2 touched `experiments/representation_region/region.gd`, `tests/test_representation_player_input.gd`, `tests/test_representation_workbench_presentation.gd` and this evidence folder. Existing Round 1 changes in `byte_board.gd`, `trace_player.gd`, `tests/test_representation_visual.gd` and the two append-only PO blocks remain in the review diff. No model, catalog, save or progression code changed.
