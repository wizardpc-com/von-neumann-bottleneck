# A2 terminal presentation

The terminal has an 11-segment chapter strip in journey order (prologue through chapter 10). Each segment uses `LabState.station_progress(LabState.tasks())`, the laboratory board's real progress source, which excludes temporary session tasks. The next task's chapter is outlined; hover reveals its chapter name and earned count. Existing `chapter_emblem.gd` artwork is instantiated without editing that file. Total completion stays at the right.

At 1280 x 720 the taller terminal places the footer near the bottom with consistent margins in both languages. The English Begin card uses its own PO entry, "Connect the first line". The accepted segmented mode control, one selected-mode explanation, footer grouping and original Tab order remain.

## PNG pairs (1280 x 720)

| State | Original | Round 1 | Final |
| --- | --- | --- | --- |
| Chinese Test | [before](before-awake-zh.png) | [round 1](round1-awake-zh-test.png) | [after](after-awake-zh-test.png) |
| English Game | [before](before-awake-en-game.png) | [round 1](round1-awake-en-game.png) | [after](after-awake-en-game.png) |
| Chinese Game | | [round 1](round1-awake-zh-game.png) | [after](after-awake-zh-game.png) |
| English Test | | [round 1](round1-awake-en-test.png) | [after](after-awake-en-test.png) |

[Standby baseline](before-standby-zh.png) is retained. The four final PNGs were recaptured with the pinned console engine in the final isolated QA project. Every GPU/capture launch has fresh APPDATA and LOCALAPPDATA beneath `.godot/a2/r2-*`. Exact commands and exits: [GPU/capture receipt](round2-gpu-captures.json). Captures use `--test-mode --locale=<locale> --dev-key=Enter@3 --dev-shot=<absolute-png>@13 --dev-quit=14`; Game adds `--dev-click=850,265@11`.

## Verification

Final isolated verifier: **8 suites PASS / 0 FAIL, 9,443 checks**; import and isolated user-directory checks PASS. [Receipt](results.json); full logs and frozen QA project: `.godot/verification/20261107T184233Z-683f7324/`.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_lab_terminal_modes --suite test_terminal_presentation_polish --suite test_lab_terminal_routing --suite test_lab_terminal_pages --suite test_hub_first_screen --suite test_lab_journey --suite test_terminal_task_titles --suite test_lab_terminal_confirmation
```

| Suite | Checks | Failures |
| --- | ---: | ---: |
| test_hub_first_screen | 7939 | 0 |
| test_lab_journey | 52 | 0 |
| test_lab_terminal_confirmation | 34 | 0 |
| test_lab_terminal_modes | 331 | 0 |
| test_lab_terminal_pages | 52 | 0 |
| test_lab_terminal_routing | 39 | 0 |
| test_terminal_presentation_polish | 32 | 0 |
| test_terminal_task_titles | 964 | 0 |

The modes suite checks real chapter counts against the board source in both languages at three sizes, all chapter/footer bounds, prologue and next-task chapter highlighting, card capitalization, and unchanged Game progress. The 7/57 total fixture only checks supplied-count presentation; chapter fills always read live authoritative data.

GPU follow-up: modes **331 checks / 0 failures**; pages **58 checks / PASS**, including nested native focus. Logs: `.godot/a2/r2-gpu-test_lab_terminal_{modes,pages}.log`. All four final PNGs visually inspected. `git diff --check` PASS. The baseline Windows root-certificate-store warning remains expected.

## Scope and limits

Modified: `src/lab/lab_terminal.gd`, `tests/test_lab_terminal_modes.gd`, A2 blocks in `localization/game.en.po` and `localization/game.zh_CN.po`, and this evidence folder. Updated local coordination entry: `.godot/collaboration/handoff.md`. No commits or pushes.

`chapter_emblem.gd`, `lab_state.gd`, `lab_home.gd`, physical standby (A1), `terminal_passage.gd`, Yi words, simulation, progression and save formats are unchanged. Captures use fresh empty progress; no earned mid-campaign capture or manual full campaign/export acceptance is claimed. Original before PNGs, Round 1 after PNGs and [Round 1 receipt](round1-results.json) are retained.
