# A5 shared design system · 2026-11-08

Candidate based on `196d08e`, branch `claude/vux-a5-system-20261108`.

## Observable changes and owner choices

- Handbook: original filled blue entry → shared quiet navigation outline. Its existing 118×44 minimum, anchors, position, name and callback stay the same. Compare 00–03 and 06–08.
- Buttons: filled primary remains the Run tier; secondary is an outline, tool is a ghost, nav is a quieter outline, danger uses the existing muted quit red. Explicit helpers share 34 logical px minimum height, 7 px radius, 11×5 px padding and 2 px focus rings; taller scene minimums remain. Primary padding now matches tools. Disabled text is brighter for legibility; disabled nav has a darker surface. Compare 00, 04, 07–09.
- Floating instruments: 10 → 8 px corners, shallower shadows, clearer graphite title strip and palette-based resize strokes. Existing geometry and all moving/resizing/minimizing logic remain. Compare 00–04. Old appearance is retained in the before panels of the PNGs.
- Header accent is opt-in only: `WorkbenchChrome.frame(header, chapter_color)` or `bar_style(chapter_color)` draws a 2 px bottom rule. Existing calls keep the neutral 1 px rule. No chapter opts in in this candidate.
- Typography tokens explicitly record title 26, section 18, body 16, secondary/caption 14 and dense-text logical floors 14/13. Existing tokens keep their values.

`instrument_dock.gd` and `movable_dialog_panel.gd` were inspected and need no changes for these visual refinements. No chapter files, localization entries, palette, emblems, simulation, result judgements, ranking or save fields were edited.

## Round 2 case review

No case conversion was introduced by A5; the shared styles, floating titles and heading font resource contain no uppercase transform. The unchanged baseline `localization/game.en.po` supplies `TEST MODE` (`mode.test`, line 49), `TEST BENCH` (`device.test_bench`, line 208; `state.test_bench`, line 259; `system.window.test_bench.title`, line 2346) and `MISSION` (`hardware.window.mission`, line 853; `system.window.mission.title`, line 2337; `system.window.mission.short`, line 2355; `chapter2.tool.mission`, line 3024). The live PO was compared with `HEAD` and is identical. Titles consume these translations directly; text case remains string-owned. Per review instructions, these pre-existing strings are unchanged.

## Screenshot comparisons

Each numbered PNG is a lossless vertical stack of three original 1280×720 frames: **before zh_CN / after zh_CN / after en**. No frame was rescaled. Routes are identical before and after: test mode, fresh isolated user data, enter at 2 s, shot at 10 s, quit at 11 s. No simulation result is fabricated. These are settled entry screens, not completed-solution captures.

| PNG | Route |
| --- | --- |
| `00-tutorial.png` | `hardware_foundations/tutorial` |
| `01-cpu.png` | `hardware_foundations/cpu` |
| `02-ch1.png` | `chapter_1/assembly` |
| `03-ch2.png` | `chapter_2/distant_reads` |
| `04-ch3.png` | `chapter_3/arrival` |
| `05-ch4.png` | `chapter_4/fields` |
| `06-ch5.png` | `representation/mixed_scan` |
| `07-ch6.png` | `service/move_state` |
| `08-ch7.png` | `prediction/regular` |
| `09-ch8.png` | `creation/C1_restore` |

The writable sandbox permits only this worktree, so route scratch PNGs, route logs and fresh APPDATA/LOCALAPPDATA directories are under `.godot/a5-temp/` rather than the sibling task temp directory. Reproduction helper: `.godot/a5-temp/capture.py before|after-final`. Full raw frames remain there for pixel inspection. Round 2 re-captured all ten English frames in `.godot/a5-temp/round2-en/` using `python -X utf8 .godot/a5-temp/round2-capture.py round2-en`; `round2-compare.py` replaced only the English third of each triptych and verified both Chinese thirds pixel-identical. All ten refreshed English frames were visually inspected.

Example exact route command (set APPDATA and LOCALAPPDATA to a fresh `.godot/a5-temp` subdirectory first):

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path 'E:\VNB\temp\claude-visual-20261108\wt\a5' -- --test-mode --locale=zh_CN --dev-enter=hardware_foundations/tutorial@2 --dev-shot=<absolute-png-path>@10 --dev-quit=11
```

## Remaining per-file follow-ups (not edited)

| File | Control / observation | Follow-up |
| --- | --- | --- |
| `src/hardware_foundations/hardware_foundations.gd` | Test bench Run/Seal/Official action group; 12 px `state_label` and `truth_table_note` | Review one primary per currently visible action area; use shared secondary for alternatives and body floor for explanatory text. Preserve original bit/signal visuals. |
| `src/system_lab/system_lab.gd` | Mission previous/next and evidence controls use the default boxed theme while toolbar tools are ghosts | Classify mission paging as secondary and local tools as tool; keep run primary. |
| `src/ui/main.gd` | Chapter 2 mission paging and Open test bench use boxed defaults | Apply secondary explicitly, rather than erasing all scene overrides in shared chrome. |
| `src/overlap_chapter/overlap_chapter.gd` | Mission explanation buttons are boxed; bottom `status` uses 13 logical px | Apply secondary to explanation actions and nav to its custom footer Handbook entry; shorten or reflow status before increasing its text size. |
| `src/layout_chapter/layout_chapter.gd` | Source data / temporary copy controls are default filled tabs | Consider explicit tool tier with selected marker; retain their state semantics. |
| `experiments/representation_region/region.gd` | `Blocks` Tree is black/default grey against terminal graphite; task tabs are dense | Add a scene-local matching Tree style and review task-button spacing; do not change table numbers or sorting. |
| `experiments/service_plan/lab.gd` | `button()` uses nav for edit actions as well as navigation | Assign tool to move/merge, secondary to structural edits, nav to actual navigation. |
| `experiments/prediction/lab.gd` | `button()` inherits default boxed style; Results tabs retain grey default surfaces | Assign secondary to Run to end / New round and align tab surfaces locally. |
| `experiments/creation/workbench.gd` | `label()` clamps explanatory 12 px requests to 13; many small captions remain, and generic `button()` uses tool for every nonprimary action | Separate body from caption requests; use nav for its custom Handbook entry and secondary for major nonprimary actions. Recheck English after local type changes. |

## Proposals needing impact analysis

The project stretches a 1600×900 logical canvas into 1280×720: 14/13 logical px render at approximately 11.2/10.4 native px. Achieving actual 14/13 px throughout requires a coordinated global scale or per-scene layout change. This candidate documents the scale and does not claim to solve existing small text outside the owned shared buttons. Review the full journey and compact layouts before changing the stretch policy.

## Verification

Exact isolated command (from worktree root):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_unified_style --suite test_instrument_theme --suite test_terminal_presentation_polish --suite test_floating_tool_recall --suite test_learning_handbook --suite test_system_evidence_guidance --suite test_overlap_ui --suite test_layout_ui --suite test_representation_workbench_presentation --suite test_prediction_workbench_presentation --suite test_creation_workbench
```

Rendered suites each use a fresh APPDATA/LOCALAPPDATA under `.godot/a5-temp/final-checks/`, and this command form:

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --audio-driver Dummy --path 'E:\VNB\temp\claude-visual-20261108\wt\a5' --script res://tests/<suite>.gd -- <arguments>
```

| GPU suite | Arguments |
| --- | --- |
| `test_system_evidence_guidance` | `--system-guidance-capture` |
| `test_locality_trace_presentation` | none |
| `test_representation_workbench_presentation` | `--workbench-capture --capture-size=1280x720` |
| `test_prediction_workbench_presentation` | `--workbench-capture --capture-size=1280x720` |
| `test_creation_workbench` | `--creation-capture` |

**Round 2 fresh rerun: 11/11 suites PASS, 0 FAIL; import and user-directory checks PASS. GPU: 5/5 suites PASS, 0 FAIL.**

Round 2 isolated full logs: `.godot/verification/20261107T184136Z-ac810bad/`; GPU logs and results: `.godot/a5-temp/round2-checks/`. Reproduction: `python -X utf8 .godot/a5-temp/round2-check.py` runs the exact same commands and arguments above, with a fresh APPDATA/LOCALAPPDATA per GPU launch. Check counts below are unchanged. Round 1 evidence remains in `.godot/verification/20261107T182446Z-2c78b116/` and `.godot/a5-temp/final-checks/`.

| Suite | Headless | GPU |
| --- | --- | --- |
| `test_creation_workbench` | 385 | 461 |
| `test_floating_tool_recall` | PASS | not run |
| `test_instrument_theme` | PASS | not run |
| `test_layout_ui` | PASS | not run |
| `test_learning_handbook` | 1675 | not run |
| `test_overlap_ui` | PASS | not run |
| `test_prediction_workbench_presentation` | 1200 | 1320 |
| `test_representation_workbench_presentation` | 10173 | 2329 |
| `test_system_evidence_guidance` | 84 | 86 |
| `test_terminal_presentation_polish` | 32 | not run |
| `test_unified_style` | 74 | not run |
| `test_locality_trace_presentation` | not run | 2497 |

Numbers are passing check counts where the suite reports them; PASS means the suite does not print a count. `git diff --check` passes.
GPU Locality exits 0 with all 2497 checks passing and an ObjectDB warning (6 instances leaked at exit in Round 2; 2 in Round 1). This warning was not investigated. Earlier WASAPI device errors were avoided in the final GPU run with Dummy audio.
The first candidate exposed a font-inheritance regression against the untouched baseline (baseline 385/385 headless, 449/449 GPU). The final code retains inherited scene fonts; all final suites above pass. Earlier diagnostic logs remain in `.godot/a5-temp/` for audit.

Limits: these checks and developer routes are controller/rendering evidence, not newcomer acceptance or native mouse playtesting. Only entry captures cover every chapter; the GPU suites additionally exercise measured/persisted workflow states. Existing scene text below the requested native-pixel floors remains listed above. Engine root-certificate-store diagnostics occur in both baseline and candidate; no network service is required for these checks.
