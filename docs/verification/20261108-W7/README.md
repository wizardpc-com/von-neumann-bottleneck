# W7 — Journey map and lab board

Owner: W7, branch `claude/vux-w7-map-20261108`. Uncommitted presentation changes only.

## Changes and owner-review trade-offs

- Before: chapter dropdown duplicates tabs on a separate header row. After: that row is folded out, Journal is in the single shared chrome row, Laboratory then Settings are last. The hidden dropdown node and its selection API remain for existing consumers/tests. Chapter tabs remain horizontally scrollable in English.
- Before: list/detail buttons only appear with a search. After: both remain visible in the side panel; selecting a result then pressing Chapter tasks returns to the same search. Without search it returns to the selected chapter list.
- Before: continuation ring pulses and redraws the entire map. After: the same target has a steady ring, with redraws on interaction. Owner review: less motion in exchange for lower idle drawing work.
- Removed the orphan tray accent line; skip tray headings when vertically clipped. Node titles and original bit/signal artwork are unchanged.
- Board names use 30 px and counts 27 px in its 680 px texture. Optional exploration uses a compact count in the same right column as chapter progress. All eleven chapters occupy one row each. Count, name and status sources are unchanged.

## PNG evidence (1280×720)

| Before | After | Route |
| --- | --- | --- |
| before-tree.png | after-tree.png | settled tree, Chinese |
| before-detail.png | after-detail.png | search `cache`, select first match |
| before-lab.png | after-lab.png | lab home, Chinese |
| — | after-return.png | selected search result → Chapter tasks, query preserved |
| scratch baseline | after-ch5.png / after-ch5-en.png | chapter 5, Chinese / English |
| — | after-lab-en.png | English lab home |

All ten PNGs were inspected. English map tabs intentionally scroll; long compact map labels use existing ellipses and full names remain in the task list. Map fixture routes use actual control signals/methods, not native typing. Round 1 lab captures used the normal dev-shot route at 9 s; the lab PNGs now show the Round 2 capture described below. English lab BEFORE was not captured; Chinese home baseline and both after locales are available. Extra baseline search/chapter PNGs and full board textures remain under `.godot/w7/`.

## Idle measurement

Rendered OpenGL compatibility, RTX 5070 Ti Laptop, 1280×720, Test mode, Chinese fresh map at Tutorial; warm up 120 frames, sample 240. Count canvas `draw` signals and sample `Performance.TIME_PROCESS`; wall time includes vsync. Reproduce the final route and measurement with `capture_probe.gd` (SceneTree script; overwrites after PNGs).

| State | draw signals / 240 frames | process median ms | process p95 ms | wall ms/frame |
| --- | ---: | ---: | ---: | ---: |
| Before | 239 | 14.967 | 41.306 | 16.528 |
| After, first sample | 0 | 5.063 | 30.701 | 16.538 |
| Final after sample (body type retained) | 0 | 7.310 | 32.683 | 16.530 |

These are short local samples, not an FPS or general hardware benchmark. The earlier 3.993 ms median / 31.927 ms p95 sample overlapped the end of headless regression work. Final sample above ran with the original body type size retained and compact typography applied only to header controls. Removing idle redraw is directly observed; vsync-limited frame intervals did not improve.

## Verification

Exact focused command from the worktree root (set fresh APPDATA and LOCALAPPDATA first):

```powershell
python -X utf8 scripts/verify-project.py --godot 'E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --suite test_task_tree --suite test_task_tree_layout --suite test_task_tree_presentation --suite test_task_tree_completed_detail --suite test_tree_journey_presentation --suite test_tree_relation_focus --suite test_lab_journey --suite test_hub_first_screen --suite test_immersive_lab
```

9/9 suites PASS, 0 failed; import and isolated user-directory probes also PASS. Exact runner receipt is `results.json`; raw logs in `.godot/verification/20261107T161951Z-31e429e5/`.

Reported assertion counts: hub first screen 7939/0, immersive lab 459/0, lab journey 52/0, completed detail 369/0, journey presentation 3314/0, relation focus 243/0. Other three suites report PASS without counts.

After removing the unused pulse callback and adding bilingual list-return assertions, reran the two affected tests against final source:

```powershell
& 'E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path $PWD --script res://tests/test_task_tree_presentation.gd
& 'E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path $PWD --script res://tests/test_tree_relation_focus.gd
```

Both PASS; relation focus 243 checks / 0 failures. After retaining the original body type size, reran test_task_tree_presentation and test_tree_journey_presentation with the same direct commands against final source: both PASS (journey presentation 3314 checks / 0 failures). The old pulse assertion now verifies processing is disabled; new assertions verify the no-search list return in both languages. `git diff --check` PASS. Engine logs include the host certificate-store warning; no product script errors.

Lab reproduction (append `--locale=en` for English):

```powershell
& 'E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --path $PWD -- --test-mode "--dev-shot=$PWD\docs\verification\20261108-W7\after-lab.png@9" --dev-quit=11
```

All Godot runs used isolated APPDATA/LOCALAPPDATA under this worktree's `.godot/w7/` (or verifier runtime), because the granted writable root excludes the requested sibling temp directory. No player saves accessed. No commits or Git mutations.

## Limits / proposals

No simulation, scoring, task IDs, gates, navigation implementation or save formats changed. No proposals requiring impact analysis. Native keyboard search and manual long-session playtest remain unverified. Owner should review the steady continuation ring, folded dropdown and wall-board type size.

## Round 2: board row correction (2026-11-08)

Names restored to 30 px and progress to 27 px. Address exploration shows a compact count (3 items in English) in its own right column. No standalone exploration line is drawn. Both locales retain eleven single rows with full chapter names. Inspected the four refreshed PNGs: after-lab.png, after-lab-en.png, after-board.png and after-board-en.png. Board textures are 449 by 680; room captures are 1280 by 720.

All nine map/lab suites listed above passed again on final runtime source, plus import and user-directory probes. Receipt: round2-results.json; full raw logs: .godot/verification/20261107T164239Z-717ab745/. Rendered capture_board.gd checks 79 geometry/type/count conditions per locale, including row containment, non-overlap, shared center, full name width and optional count; both runs report zero failures. Capture logs: round2-board-zh.log and round2-board-en.log. Only the existing host certificate-store warning was observed.

Reproduce each locale separately, with a fresh APPDATA and LOCALAPPDATA under .godot/w7/ per launch:

```powershell
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path $PWD --windowed --resolution 1280x720 --script res://docs/verification/20261108-W7/capture_board.gd -- --test-mode --capture-size=1280x720
# Append --locale=en for English.
```

README was rewritten explicitly as UTF-8. Its title, table placeholders, arrow and multiplication symbols were checked after writing; no literal question marks or replacement characters remain. All added lines in the five changed runtime/test files and both evidence helpers were checked for the same corruption: none found. No PO files changed. Native input and extended play remain unverified.

Round 2 modified src/lab/lab_room_3d.gd, this README, after-lab.png and after-lab-en.png; created capture_board.gd, after-board.png, after-board-en.png, round2-results.json and the two round2-board logs. Local ignored handoff updated. Other Round 1 runtime/test/map evidence files retained; no files deleted, no commits, no gameplay/save changes.
