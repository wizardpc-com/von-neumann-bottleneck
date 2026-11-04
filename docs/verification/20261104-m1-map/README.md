# M1 journey map — 2026-11-04

The map opens task details instead of a second chapter list. Chapter selection opens that chapter's first task; search retains its clickable results and detail return controls. The header Task details button releases the sidebar width and reframes the chapter. Chapter buttons use 17 px theme text (at least 13 px at the startup route's 0.8 scale), horizontal scrolling and retained-completion bars; temporary chapters have no completion bar.

Cards distinguish completed work with a check and green rail, locked work with a lock, optional work with the existing diamond, and temporary work with a clock. The actual Continue target has an amber outline, static under reduced motion. Dependency arrows retain their existing topology and direction; completed prerequisites are green, and hover separates incoming amber from outgoing cyan links. Game cards/details show existing PersonalRecords metrics when present: passed cases, cycles, or aggregate RAM read/write bytes. Earned bonus dots come from existing bonus goals. Test mode displays neither Game metrics nor earned bonus dots.

## Paired GPU frames

All PNGs are 1280×720, Godot 4.7.1 Compatibility on NVIDIA RTX 5070 Ti Laptop. Ten retained images:

| Route | Before | After |
| --- | --- | --- |
| Fresh Test startup → tree | [before-tree.png](before-tree.png) | [after-tree.png](after-tree.png) |
| Game tutorial earned through real controller actions, Chinese | [before-game-zh_CN.png](before-game-zh_CN.png) | [after-game-zh_CN.png](after-game-zh_CN.png) |
| Same Game flow, English | [before-game-en.png](before-game-en.png) | [after-game-en.png](after-game-en.png) |
| Test chapter 2 | [before-later.png](before-later.png) | [after-later.png](after-later.png) |
| Test nearby-storage hover | [before-hover.png](before-hover.png) | [after-hover.png](after-hover.png) |

Before frames precede source edits. The Game harness follows test_night_narrative.gd: connect A_IN→NOT_1→LAMP, change input, run debug, disconnect and reconnect NOT_1→LAMP, then assert actual tutorial completion. It does not assign progress, inject receipts or manufacture metrics. The tutorial has no formal best-case record, so these frames correctly show completion without a fabricated number. English is selected through Localization.set_locale("en"). Chapter/hover routes use the existing map methods, not modified task data.

Local reproducible capture harness: `.godot/m1/capture.gd`; set MAP_PHASE=after, fresh APPDATA and LOCALAPPDATA under `.godot/m1/`, then run the pinned engine with `--path E:/VNB/temp/claude-experience-20261104/wt/m1 --script res://.godot/m1/capture.gd`. The startup pair uses `-- --test-mode --dev-enter=tree@2 --dev-shot=<absolute PNG>@4 --dev-quit=5`. Harnesses and full logs stay in ignored scratch.

## Verification

From worktree root, with APPDATA and LOCALAPPDATA redirected to fresh `.godot/m1/` profiles:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_task_tree --suite test_task_tree_completed_detail --suite test_task_tree_layout --suite test_task_tree_presentation --suite test_tree_journey_presentation --suite test_tree_relation_focus --suite test_unified_journey_navigation --suite test_lab_journey --suite test_journey_journal --suite test_mode_access --suite test_global_save
```

11/11 suites PASS, 0 suite failures; logs: `.godot/verification/20261104T103843Z-8fbbd4ef/`. Reported assertion counts: completed detail 369/0, journey presentation 3314/0, relation focus 242/0, unified navigation 26/0, laboratory 52/0, journal 174, mode access 14. Other suites print PASS without an assertion count.

After localization, sidebar-focus and reduced-motion checks, repeated the same verifier with `--suite test_task_tree --suite test_task_tree_presentation --suite test_tree_relation_focus`: 3/3 PASS, relation focus 243 checks/0 failures. Logs: `.godot/verification/20261104T104240Z-88ada21a/`.

After final chapter font sizing, actual GPU run:

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path E:/VNB/temp/claude-experience-20261104/wt/m1 --script res://tests/test_tree_journey_presentation.gd
```

PASS, 3314 checks, 0 failures (`.godot/m1/final-gpu.log`). Repeated `test_task_tree_presentation.gd` headless on final sizing: PASS, including sidebar collapse/reopen and bilingual bounds (`.godot/m1/font-presentation.log`). Final captures were refreshed after that sizing change. `git diff --check` passes.

Changed journey assertions deliberately: chapter navigation now selects its first task/detail instead of preserving another chapter's selection and opening a duplicate list; compression chapter checks a readable detail viewport and reachable Enter instead of a visible list. No numeric layout constants or authority checks were weakened.

## Limits and integration notes

No simulation, task IDs, gates, formal judgement, save fields, signal/bit visuals or player files changed. No commit or push. Missing historical formal-run records remain blank; cycle targets and saved-work counters are not newly synthesized. Pure formatter fixtures verify record suppression for incomplete tasks and Test mode; real metric/bonus-rich endgame profiles were not captured. Native mouse/keyboard, motion feel, FPS and newcomer comprehension remain manual acceptance. The journal headless suite explicitly skips ThemeReflection/F8 focused-window checks. All runs emit the existing Windows root-certificate-store diagnostic; no network feature is exercised here.

Lead integration should update ARCHITECTURE.md's map paragraph (currently describes the old chapter-list default); that file is outside M1 ownership. No proposals require simulation or persistent-format impact analysis.
