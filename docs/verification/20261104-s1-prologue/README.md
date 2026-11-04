# S1 prologue: wiring and sealing

CPU opens on its circuit with Test Bench and Components folded to restorable title strips. Mission specifications remain accessible through the goal bar and taskbar. Focus reserves the folded strips vertically and the expanded tools horizontally; restoring/folding a CPU tool reframes the circuit while the player has kept the automatic view. Other workbenches retain their existing panel implementation and defaults.

Wire-drag emphasis selects the same nearest port as release hit testing. Other compatible targets use smaller rings, reducing overlap on dense parts. Signal values, wire latency, simulation, official judgement and original bit visuals are unchanged.

The sealing silhouette gains short external leads. An actually sealed HalfAdder receives one brief palette emphasis when entering Full Adder in the same session; this adds no persisted field or reward. Reduced motion skips the palette emphasis.

## Rendered comparisons

All retained PNGs are native 1280x720 Chinese Test-mode frames, captured before editing and after implementation with the identical sequence below:

| Route | Before | After |
| --- | --- | --- |
| Half adder | [before](before-half_adder.png) | [after](after-half_adder.png) |
| CPU | [before](before-cpu.png) | [after](after-cpu.png) |
| Full adder, palette visible | [before](before-full_adder.png) | [after](after-full_adder.png) |
| Chapter 2 access order | [before](before-access_order.png) | [after](after-access_order.png) |
| Chapter 3 arrival | [before](before-arrival.png) | [after](after-arrival.png) |

Capture arguments after `--path <worktree> --`: `--test-mode --dev-enter=hardware_foundations/tutorial@2 --dev-shot=<phase>-tutorial-entry.png@3 --dev-shot=<phase>-tutorial.png@5 --dev-enter=hardware_foundations/half_adder@6 --dev-shot=<phase>-half_adder.png@8 --dev-enter=hardware_foundations/cpu@9 --dev-shot=<phase>-cpu.png@11 --dev-enter=hardware_foundations/full_adder@12 --dev-shot=<phase>-full_adder.png@14 --dev-enter=chapter_2/access_order@15 --dev-shot=<phase>-access_order.png@17 --dev-enter=chapter_3/arrival@18 --dev-shot=<phase>-arrival.png@20 --dev-quit=21`.

Tutorial entry and two seconds later, plus English CPU / restored Mission / Full Adder captures, were inspected and kept in `.godot/s1/` to limit retained comparisons to ten PNGs. English used the engine flag `--locale en` before `--`. Half-adder and arrival before/after PNG files are byte-identical. Small typewriter/header-settling differences appear in other unchanged routes. No shared floating-panel source was modified.

## Verification

Godot: `4.7.1.stable.official.a13da4feb`, Windows. All launches used isolated APPDATA and LOCALAPPDATA inside the writable worktree's ignored `.godot/`; no player profile was used. The assigned external scratch directory is outside this session's writable root.

Initial focused command:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry --suite test_hardware_foundations_ui --suite test_hardware_prologue_ui --suite test_first_lesson_input --suite test_half_adder_reseal_progression --suite test_tutorial_resume_guidance --suite test_workbench_escape --suite test_floating_tool_recall --suite test_system_lab_ui --suite test_overlap_ui --suite test_layout_ui --suite test_wire_drag_geometry
```

Evidence: `.godot/verification/20261104T095607Z-ab4110e4/`. Eleven existing suites passed; the new workspace suite initially failed to compile because of a global-type dependency in the test harness. After that correction it exposed missing full-Mission reopening on CPU; the implementation was corrected.

Reruns:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry --suite test_half_adder_reseal_progression
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry --suite test_hardware_foundations_ui
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry
```

The real ordinary-Game sealing/resealing suite passed 172 checks, 0 failures (including the earned arrival cue), in `.godot/verification/20261104T095826Z-d6c2c26d/`. Hardware UI and CPU workspace reopening passed in `.godot/verification/20261104T100025Z-cd235e38/`. The final workspace rerun passed 63 checks, 0 failures, including every CPU component against the restored bench (`.godot/verification/20261104T100249Z-cd2f29a2/`). Final aggregate: 12 distinct relevant suites passed, 0 outstanding suite failures. Import and isolated user-directory checks passed. The engine reports the environment's root-certificate-store diagnostic; the verifier recognizes this existing diagnostic. Git diff whitespace check passed.

## Limits and review

No proposals requiring simulation, progression or persistent-format changes. Trace ordering, mismatch emphasis and instructional copy retain their existing implementations. No native physical-input acceptance, full 60-task playthrough or human comprehension review was performed. A held-wire baseline PNG and a rendered real-earned seal-to-palette sequence were not captured; sealing/provenance/arrival were verified through real controller execution in the focused suite. Please inspect the new seal leads and short arrival emphasis during manual play. The palette cue is session-local and is intentionally absent after restarting or direct Test-mode entry.


## Round 2 ? computation, case review and earned sealing

The existing trace-wave player now adds value-colored wire/port pulses and a brief outline on the real evaluated component. Parallel events retain their original visual-step grouping. Existing bits, circuit values and judgement remain authoritative. Reduced motion finishes playback and sealing immediately; existing pause/step and seal-skip controls remain available.

Failed official runs select the first failing result row. Output markers show its actual and expected values. Completed half-adder input buttons and result labels, plus prologue result labels, reopen recorded cases without granting progress or installing rewards. Editing invalidates the comparisons. CPU tool folding reframes only while the view still matches automatic framing; native GraphEdit layout is allowed to settle before recording that view. The half-adder bench is slightly narrower/shorter with all entry controls and the truth-table link visible in Chinese and English.

Sealing briefly condenses an actual rendered circuit snapshot into HalfAdder. The 1.55-second sequence and existing skip remain; the earned Full Adder palette arrival cue from round 1 is preserved.

| Route | Baseline | Final |
| --- | --- | --- |
| Half adder entry | [before](r2-before-entry.png) | [after](r2-after-entry.png) |
| Debug wave 4/8, midpoint | [before](r2-before-wave3.png) | [after](r2-after-wave3.png) |
| Failed official run | [before](r2-before-failure.png) | [after](r2-after-failure.png) |
| Earned seal, early | [before](r2-before-seal-early.png) | [after](r2-after-seal-early.png) |
| Earned seal, later / next task | ? | [later](r2-after-seal-late.png), [arrival](r2-after-arrival.png) |

Twenty PNGs total, including round 1. Additional wave, seal and English frames remain in `.godot/s1b/`. Inspected GPU frames are 1280x720, NVIDIA/OpenGL compatibility renderer. The first failed case here is A=0, B=1: SUM actually 0, expected 1. The intentional erroneous wire is A directly to SUM; it is repaired before earning the seal.

Reproducible GPU fixture: `tests/captures/s1_prologue.gd`. It inherits the real ordinary-Game tutorial/level helpers from the reseal suite, connects construction inputs through production editor controllers, executes real debug/official runs, repairs the deliberate fault, presses the actual seal action and waits for its production timer before entering unlocked Full Adder. No completion state is injected. Wave midpoints are held through the existing presentation method for repeatable comparison; they are not physical input or wall-clock acceptance.

```powershell
$env:APPDATA="$PWD/.godot/s1b/review-profile"; $env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script res://tests/captures/s1_prologue.gd -- --phase=review
```

Use a fresh profile for each run. For English, add `--locale en` before `--script`. Baseline used the identical fixture before round-2 implementation. English entry, failure, wire and earned-seal/arrival frames were inspected at `.godot/s1b/english-*.png`.

Focused verification commands (from the worktree root):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry --suite test_hardware_foundations_ui --suite test_hardware_prologue_ui --suite test_first_lesson_input --suite test_half_adder_reseal_progression --suite test_tutorial_resume_guidance --suite test_workbench_escape --suite test_floating_tool_recall --suite test_system_lab_ui --suite test_overlap_ui --suite test_layout_ui --suite test_wire_drag_geometry
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_hardware_workspace_entry --suite test_hardware_foundations_ui --suite test_hardware_prologue_ui --suite test_half_adder_reseal_progression
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_circuit_simulation
```

Initial round-2 run: 11/12 suites passed; workspace failed 2/64 checks because native GraphEdit scroll clamping differed from the automatic view snapshot. Evidence: `.godot/verification/20261104T101534Z-c8c2aa41/`. After correction, affected four-suite reruns passed 4/4, 0 failures (`20261104T102021Z-96294205`, final `20261104T102236Z-36b331a6`). Workspace: 69 checks, 0 failures; real Game reseal: 172 checks, 0 failures. Hardware UI includes trace ordering, exact paths, pause/pan/zoom and reduced-motion checks. Unaffected neighbour evidence from the 12-suite run remains applicable. Import and isolated-user-directory gates passed. The Windows root-certificate diagnostic remains filtered by the verifier; JSON results record exit 0 for passing engine runs.

No proposals needing simulation/progression/save impact analysis. No simulation sources, task IDs, formal criteria or saved fields changed. Limits: no physical mouse/keyboard acceptance, full 60-task playthrough, newcomer comprehension study or performance benchmark. Sequential case review presents the stored result without restoring simulator runtime. The captured seal path is HalfAdder; other module seals retain the existing generic effect.

Circuit regression: 1/1 suite passed, 0 failures; `.godot/verification/20261104T102438Z-15eaebe5/`. Final aggregate: 13 distinct relevant suites passed, 0 outstanding failures. Final diff whitespace check passed. GPU fixture logs finish with PASS; no script errors.

Final GPU lifecycle check: `.godot/s1b/check_skip.gd` / `skip-check.log`, 3 checks, 0 failures. Immediate skip during the pending snapshot readback cannot reopen the effect; reduced motion bypasses readback. The ordinary earned GPU fixture also passed again (`skip-review.log`) after this guard. Retained frames are visually unchanged by the guard.
