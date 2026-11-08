# B2 · Chapters 2 and 3 design system

Candidate from 407dddb; branch claude/vux-b2-mid-20261108. Uncommitted.

## Changes / owner choices

- Chapter 2: Run primary; debug/evidence/mission paging/open-bench secondary; local edits/playback tool; navigation nav. Chapter 3: Begin and explanations secondary; custom footer Handbook nav. Old boxed/filled appearances remain in before frames.
- Chapter 2: mode selector stays available, before Journey map → Laboratory → Settings. Status moves from header to playback area, replacing the redundant Trace Playback heading in its existing row. Trade-off: status is read near replay instead of navigation; chapter map no longer shows the workbench status sentence. Compare 00–02.
- Chapter 2 Profiler: terminal Tree surface, cyan selection, matching column headers, right-aligned numeric metrics. Values, order and evidence unchanged.
- Chapter 3: status wraps to two lines at 14 logical px; component explanations/result details rise 13 → 14. Existing fixed result band stays. Compare 03–04.

## Evidence

Each PNG stacks before zh_CN / after zh_CN / after en vertically; each original frame 1280×720 without rescaling. Fresh isolated user data, Test access, no granted completion. Run frames use unchanged starters: actual Chapter 2 result 257 cycles; actual Chapter 3 unmet target 40/28 cycles.

| PNG | Route | Action |
| --- | --- | --- |
| 00-distant.png | chapter_2/distant_reads | settled |
| 01-distant-run.png | same | one Run click |
| 02-capstone.png | chapter_2/capstone | settled |
| 03-buffers.png | chapter_3/buffers | settled |
| 04-buffers-run.png | same | Run all tasks |

Reproduction: python -X utf8 .godot/b2-temp/capture.py before or after. Raw frames/logs: .godot/b2-temp/before/zh_CN and after/zh_CN, after/en. Sandbox only permits this worktree, so scratch and fresh APPDATA/LOCALAPPDATA are under .godot/b2-temp rather than sibling temp.

Engine: E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe
Capture arguments: --audio-driver Dummy --path <worktree> -- --test-mode --locale=zh_CN --dev-enter=<route>@2 --dev-shot=<absolute-png>@10 --dev-quit=11
Run routes add --dev-click=1162,78@8 (Chapter 2 zh_CN), 1140,78@8 (Chapter 2 en), or 1213,688@8 (Chapter 3). Set APPDATA and LOCALAPPDATA to fresh app/local folders per launch, as the helper does.

## Verification

Exact headless command (8 suites; fresh isolated project and user directories):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_ui --suite test_locality_chapter_ui --suite test_locality_trace_presentation --suite test_overlap_ui --suite test_terminal_presentation_polish --suite test_chapter_settings_input --suite test_floating_tool_recall --suite test_instrument_theme
```

Final complete run: 8/8 suites PASS, 0 FAIL; import and user-directory checks PASS. Locality Trace 2497 checks, settings input 26, terminal polish 32; remaining suites report PASS without a count. Final isolated logs: .godot/verification/20261107T191347Z-647100da/.

GPU commands use fresh APPDATA/LOCALAPPDATA per launch, Dummy audio, and the same engine:

```powershell
& <engine> --audio-driver Dummy --path <worktree> --script res://tests/test_locality_trace_presentation.gd
& <engine> --audio-driver Dummy --path <worktree> --script res://tests/test_overlap_ui.gd
& <engine> --audio-driver Dummy --path <worktree> --script res://tests/test_locality_chapter_ui.gd -- --locality-outcome-capture
```

GPU Trace: 2497 PASS / 0 FAIL. GPU Overlap: PASS. The additional GPU outcome matrix is **PARTIAL: 509/518 assertions PASS, 9 FAIL**, with 12 result/trace PNGs (both languages at 1280?720, 1440?900, 1920?1080). The untouched HEAD baseline, run in the isolated QA copy with only the two owned source files replaced by their HEAD bytes, has 10 failing assertions. Final candidate failures: six stale 20px expectations (the HEAD source uses 18); one result/action containment; one pointer hover; one pointer inspection. Baseline failures are the same categories: six / two / one / one respectively. The existing test was left intact. This is not an all-green GPU claim.

Logs: .godot/b2-temp/checks.log, gpu-test_locality_trace_presentation.log, gpu-test_overlap_ui.log, gpu-final-outcome.log, baseline-outcome.log. Baseline reproduction helper: .godot/b2-temp/baseline.py (restores candidate QA bytes in finally). Final GPU outcome receipt and raw frames: .godot/b2-temp/gpu-final-*/app/Godot/app_userdata/Von Neumann Bottleneck/locality-outcome-captures/. Earlier diagnostic output remains scratch only.

All launches report a root-certificate-store environment diagnostic. GPU Trace additionally reports eight ObjectDB instances leaked on exit (six in the prior run); not investigated. No external network is needed. No claim that native input/export acceptance passed.

## Limits / proposals needing impact analysis

Shared styles, catalogs/state/simulation/saves, formal judgement, ranking, task IDs, localization and bit visuals untouched. No new settings or strings.
Existing logical 1600×900 canvas scales to 1280×720: 14 logical px is approximately 11.2 native px. Global scale needs coordinated review; this candidate meets logical floors only.
Native input/IME, newcomer understanding, sound and exported builds unverified.
