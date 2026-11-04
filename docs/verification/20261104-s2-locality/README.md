# S2 locality presentation, 2026-11-04

Base: main `0ba32e2`. Presentation changes only; simulation, receipts, formal judgement, progression and save schema are unchanged.

- Starting a valid run closes tool windows and frames the machine; toolbar buttons reopen tools during playback.
- Cache rows replay actual `cache_fill`/`cache_evict` events and their recorded `line_values`. RAM coordinates mark the current event address in green and RAM-access/return blocks in amber. The bus displays the model's transfer byte count during return events. Seeking reconstructs the displayed event prefix; no cache policy is duplicated.
- Default replay is 8 Hz; key evidence receives twice the display time. All events remain in order; pause, step, evidence jump and editable frequency remain available. The 144-event column-first trace has 24 seconds of nominal presentation time, versus 72 seconds previously (wall time also depends on frame rate).
- The playback area keeps current measured totals visible. A second correct, nonempty formal run of the same task compares cycles, CPU wait, hits, misses and RAM bytes with the previous qualifying run in this scene session. Debug/incorrect runs do not qualify. Correct but over-budget runs remain explicitly over budget. This comparison has no persistence or award authority.

## Chosen before / after frames

All ten PNGs are 1280x720, Chinese, Test mode with isolated profiles.

| Route | Before | After |
| --- | --- | --- |
| access_order entry | before-entry.png | after-entry.png |
| formal run +1.5 s | before-run-1.5.png | after-run-1.5.png |
| formal run +4 s | before-run-4.png | after-run-4.png |
| formal run +8 s | before-run-8.png | after-run-8.png |
| column-first then row-first real formal runs | before-comparison.png | after-comparison.png |

The timed route opens Run at (1096,78), then formal test at (1080,170). Enter at startup +2 s; baseline Run opens +3 s and executes +4 s. Final captures use +5 / +6 s to allow settled entry layout, with the same offsets from Run. Entry is taken +4 s. Rendering is live, so event boundaries may differ by a frame.

The comparison harness instantiates the actual main scene, calls `_start_level`, `_run_simulation("Official Test Set")`, then selects `ProgramTemplates.ROW_FIRST` through `_load_strategy`, calls `_apply_program`, and runs the same formal set. It waits 1.5 s after run one and captures 4 s after run two. It does not inject results or mark completion. The initial comparison was captured before editing; the retained 720p baseline was regenerated with HEAD's exact main.gd as a script override to match the final fixed window size. The source of this override remains in scratch for review.

Additional inspected GPU frames (scratch, omitted here to keep ten images): distant_reads entry and actual direct-memory run, blocking entry, and an English comparison with `--locale=en`. The direct-memory run is scripted through the real handler because its Run toolbar coordinate differs from access_order. English device state text wraps within nodes.

## Verification

Command from worktree root (isolated project and user directories are created by the verifier):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_locality_trace_presentation --suite test_locality_chapter_ui --suite test_locality_restored_baseline --suite test_ui --suite test_simulation --suite test_global_save --suite test_trace_ambience
```

Result: **7 suites PASS, 0 FAIL**. Full logs: `.godot/verification/20261104T100211Z-bdeb606e/`. New presentation suite: **134 checks, 0 failures**; restored baseline: 15 checks. Simulation suite includes deterministic signatures; presentation additionally asserts that rendering every event preserves its trace signature, checks residency against real event prefixes, seeks back to an empty cache, excludes incorrect/debug comparisons, and separates tasks/direct-memory runs.

After final neutral-highlight clearing and English state wrapping, reran `test_locality_trace_presentation`, `test_ui`, `test_locality_chapter_ui`; **3 suites PASS, 0 FAIL**; logs: .godot/verification/20261104T100541Z-9181e192/ (presentation: 134 checks, 0 failures).

Initial verification found a placeholder mismatch in the new test and a missing verifier PASS marker; corrected before the final runs. All logs include the pre-existing Windows root-certificate-store warning, which the supplied verifier filters. No script errors remain.

## Limits / review

- No human newcomer, physical mouse/keyboard, exported-package or full 60-task acceptance. The chapter suite's optional renderer/pointer/Space subtest was not run; these PNG routes provide separate GPU evidence.
- This task does not change the floating-panel implementation. Reopening several tools during replay can still reduce graph scale; starting a new run exposes the full machine again.
- Comparison resets when the scene is destroyed. Persistent comparison would need a separate save-impact review; none is proposed or implemented here.
- Replay speed and whether the hierarchy explains locality clearly still need player review. No new tutorial copy or mission rules were added.
- Scratch is under `.godot/s2-locality/` inside this worktree because the execution sandbox only permits this checkout as a writable project root. It includes capture harness, source baseline, extra images and raw logs. No real player saves or protected directories were accessed.

## Repeat the comparison capture

```powershell
$env:APPDATA="$PWD/.godot/s2-recapture-profile"
$env:LOCALAPPDATA=$env:APPDATA
& E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --path E:/VNB/temp/claude-experience-20261104/wt/s2 --script docs/verification/20261104-s2-locality/capture-comparison.gd -- E:/VNB/temp/claude-experience-20261104/wt/s2/.godot/s2-recapture.png --locale=en
```

Use a fresh profile path each time; omit `--locale=en` for Chinese. `--distant` runs distant_reads without the program-change step. `--baseline` uses the original main script retained at `.godot/s2-locality/base-main.gd` (HEAD 0ba32e2). The other screenshots use the developer route arguments described above. Capture helper methods execute actual UI handlers; they are not physical input evidence.


## Round 2 - S2b, 2026-11-04

This section supersedes Round 1's tool-folding and small-zoom limitations. Round 1 changes and evidence are retained.

### Final behavior

- An executed run keeps Test Bench open on the right, including outcome, measured time/limit, compute/wait bar and the existing evidence actions. Other tools fold; the player can reopen them. The comparison is the first item in the result body, uses arrows and signed deltas, and colors improvements green and regressions amber (hits increase; all other compared costs decrease). Eligibility is unchanged: only correct, nonempty official runs of the same task in this scene session qualify.
- Header status clips with an ellipsis instead of contributing its entire text width. Settings stays on screen in Chinese and English.
- RAM cell count/coordinates use official data size and ARRAY_WIDTH; fetched blocks use CACHE_LINE_INTS. Cache display capacity comes from the model's supported capacities. Resident rows show matrix coordinates, recorded fill values and brackets around the currently accessed word. Recorded hits flash the resident row green; recorded misses flash the cache rows amber, including an empty slot. No replacement policy or data values are synthesized.
- Machine framing has a 0.85 zoom floor. When several tools leave too little space, the canvas remains pannable/scrollable instead of shrinking further. This intentionally cannot show every node simultaneously in a very narrow free band.
- No simulation, formal judgement, task, receipt, save or progression implementation changed. No new localization keys were needed in Round 2.

### Retained frames

All PNGs are 1280x720. Ten Round 1 PNGs plus these ten = 20 total.

| Route | Round 1 state before S2b edits | After S2b |
| --- | --- | --- |
| access_order, column then row official runs | r2-before-comparison.png | r2-after-comparison.png |
| same comparison, English | r2-before-en.png | r2-after-en.png |
| distant_reads official run | r2-before-distant.png | r2-after-distant.png |
| capstone baseline official run | r2-before-capstone.png | r2-after-capstone.png |

Additional final flow frames: `r2-distant-judgment.png`, `r2-capstone-judgment.png`.

The four Round 2 baseline PNGs were captured before editing runtime/test files, using the Round 1 capture helper extended only to select capstone. Final captures use identical run inputs and timing. The final helper also sets SceneTree.current_scene, allowing the fullscreen helper to install the real Settings button; the older helper omitted this and therefore baseline frames do not establish Settings behavior. Final captures assert that Settings is fully inside the viewport in both languages. Live event boundaries vary slightly with rendering.

`capture-comparison.gd` now supports `--capstone` and `--flow` (with `--distant` or `--capstone`). The existing repeat command above still applies; use a new profile path and output path each time. `--baseline` still means HEAD 0ba32e2, not the uncommitted Round 1 state.

Flow verification uses viewport mouse motion, press and release events at actual control centers:

- distant_reads: Finish Trace -> Test Bench evidence -> Mission -> supported judgement (`repeated_ram`). This observation has no budget-based result-trace button; its existing evidence action is preserved.
- capstone: Finish Trace -> inspect the waiting fetch -> close Profiler -> Mission -> supported diagnosis (`repeated_far_fetch`). The chosen frame shows the supported diagnosis and unlocked experiment guidance, without completing the task.

Both routes asserted visible controls and the resulting selected judgement. Logs: `.godot/s2b/flow-distant.log`, `.godot/s2b/flow-capstone.log`. This establishes automated viewport input, not physical mouse acceptance. Entry, official runs and the comparison program selection still use actual handlers as described in Round 1.

### Verification

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_locality_trace_presentation --suite test_locality_chapter_ui --suite test_locality_restored_baseline --suite test_ui --suite test_simulation --suite test_global_save --suite test_trace_ambience --suite test_completion_evidence --suite test_performance_player_input
```

Final runtime: **9 suites PASS, 0 FAIL**. Logs: `.godot/verification/20261104T102236Z-5c76190e/`. Includes all Round 1 suites, Chapter 2 progression/evidence/judgement and multiple capstone solutions, completion evidence (8 checks, 0 failures), and performance viewport input (82 checks, 0 failures). Restored baseline: 15 checks. Presentation: 138 checks at this point.

After adding two hit/word assertions, reran the exact command with only `--suite test_locality_trace_presentation`: **1 suite PASS, 0 FAIL; 140 checks, 0 failures**. Logs: `.godot/verification/20261104T102423Z-3b079d60/`. No runtime edits followed the nine-suite run. Logs contain the existing Windows certificate-store warning and no script errors or FAIL markers. `git diff --check` passed. The PowerShell execution envelope reported exit 1 while emitting the Git ignore permission warning; the verifier results.json receipts independently record exit 0, passed=true and empty errors for every import, isolation probe and suite in both final runs.

### Limits and impact proposals

No proposals needing simulation/save/judgement impact analysis. No full 60-task run, exported-package run, physical input or newcomer comprehension acceptance. Large/English result bodies still scroll inside the existing Test Bench. Opening several instruments can occlude parts of the machine, but no longer drives zoom below 0.85. Scratch and isolated profiles are in `.godot/s2b/`; no real player save was used. Import-generated unrelated UID files were removed using an exact eight-file hash inventory at `.godot/s2b/import-artifacts.json`.
