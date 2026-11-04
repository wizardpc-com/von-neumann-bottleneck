# R1 regression evidence

Five identical before/after routes, ten PNGs total. Before frames were captured before R1 production/test edits. Godot 4.7.1, 1280×720, separate fresh APPDATA/LOCALAPPDATA for every launch.

| Route | Before | After |
| --- | --- | --- |
| chapter_2/capstone, zh_CN | [before](before-locality.png) | [after](after-locality.png) |
| creation/G3_keep, zh_CN | [before](before-creation.png) | [after](after-creation.png) |
| tree, zh_CN | [before](before-tree.png) | [after](after-tree.png) |
| creation/G3_keep, en | [before](before-creation-en.png) | [after](after-creation-en.png) |

Capture command (each route/locale; absolute PNG paths):

```powershell
$env:APPDATA="$PWD/.godot/r1/<phase>-<route>"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" -- --test-mode --dev-enter=<route>@2 --locale=<locale> --dev-shot=<absolute-PNG>@5 --dev-quit=7
```

These entry frames verify that the accepted presentation remains intact; the repaired run, focus, measured-evidence and chapter-browsing behavior is established by the focused suites, not by static entry frames. English launch is supported and inspected; the initial contextual tooltip appears in both English captures.

Ten target suites pass (latest applicable evidence across two focused runs). The first run also retained intermediate route/floating-panel failures and a test-script compile error; the second run fixes and reruns all affected suites. See [per-suite causes and final full verification](../20261104-experience-polish/final-regression.md).

Evidence directories:

- `.godot/verification/20261104T173203Z-c7274635` — six unchanged final suites plus first checks.
- `.godot/verification/20261104T173536Z-dacf1dbd` — candidate focus, creation route, full journey narrative and UI all pass.
- `.godot/r1/` — capture scripts/logs and verifier launch logs.

No physical-input, exported-build, audio or beginner-comprehension acceptance is claimed.

## Chapter-browse comparison

[Before](before-browse.png) / [after](after-browse.png): `--dev-enter=tree@2 --dev-click=1204,134@4 --dev-move=640,700@5 --dev-shot=<PNG>@7 --dev-quit=9`.

The before browse frame replays the archived unmodified integration project at `.godot/verification/20261104T165056Z-7de994b4/project` in a fresh isolated profile. It is an additional baseline replay captured after implementation; the first four baseline frames above were captured before edits. The after frame replays current production. Browsing opens a chapter list and preserves the actual selected task.

Final applicable verification: **247 PASS / 2 known baseline FAIL**, using one full run (244/5) plus the three final test-only rechecks (3/0). Full evidence `.godot/verification/20261104T173811Z-7dab96b9`; final rechecks `.godot/verification/20261104T181304Z-3e524fc7`. See the linked regression report for exact commands and limits.
