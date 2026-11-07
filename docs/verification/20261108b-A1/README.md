# A1 laboratory room art ? 2026-11-08

The outer room uses warm daylight, a pale mineral rear wall, cooler side walls,
a warm taupe floor, brown desk legs and a wood-toned desk with procedural surface relief. A passive
rear window, reveals and skirting give the enclosure scale. Existing physical
plates use brass/paper finishes, sit on dedicated bands above the works and achievement frames, and fit each
language with visible margins inside the inscription faces. Empty work frames contain no pixel
matrices; supplied saved outputs retain their existing palette and values.

Owner choice: `WARM_ROOM` in `src/lab/lab_room_3d.gd` selects the new presentation
(`true`, default) or the previous room (`false`). This includes lighting, finishes,
passive wall treatment, inscriptions and empty-frame presentation. No player setting.
The old room remains available for comparison; owner aesthetic acceptance is pending.

| Route (1280 ? 720) | Before | After |
| --- | --- | --- |
| Chinese, settled normal motion | [before](before-room.png) | [after](after-room.png) |
| English, settled normal motion | [before](before-en.png) | [after](after-en.png) |
| Settings hover, reduced motion | [before](before-settings.png) | [after](after-settings.png) |
| Archive hover, reduced motion | [before](before-archive.png) | [after](after-archive.png) |
| Open archive, close and return, reduced motion | [before](before-returned.png) | [after](after-returned.png) |

Baseline images were captured before runtime edits. The helper uses the existing
hub and production room callbacks, not a mock room. Hover captures call the semantic
hover callback; the integration suite independently verifies occlusion-tested ray
reachability. They are not native mouse acceptance. Return captures use reduced
motion; the navigation soak also exercises normal camera travel in both languages.

Reproduce with a fresh profile for each invocation (PowerShell):

```powershell
$env:APPDATA="$PWD/.godot/a1/review-zh-new"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script docs/verification/20261108b-A1/capture.gd -- --phase=after
# Repeat with another fresh profile and --locale en before --script for English.
```

Frame sample: 180 rendered wall-clock frame intervals after 8 seconds warmup,
normal motion, Compatibility / RTX 5070 Ti Laptop, 1280 ? 720:

| Locale | Before mean ms | After mean ms | FPS monitor |
| --- | ---: | ---: | ---: |
| Chinese | 16.6608 | 16.6605 | 60 / 60 |
| English | 16.6610 | 16.6607 | 60 / 60 |

These capped intervals show no observed idle regression, not isolated GPU time,
GPU headroom or a demonstrated speedup. No lights or shadow maps were added.

Verification command (fresh isolated APPDATA/LOCALAPPDATA):

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_immersive_lab --suite test_lab_journey --suite test_lab_navigation_soak --suite test_lab_saved_work_window --suite test_two_worlds
```

Verification: **5/5 suites PASS, 751 checks, 0 failures**, plus import and user-directory
isolation gates PASS. Counts: immersive room 466, journey 52, navigation soak 162,
saved work 26, two worlds 45. [Full suite logs](suite-results.txt),
[machine receipt](results.json), [matching tested source hashes](tested-source-sha256.json).
Run: `20261107T183821Z-68a4ecb2` (machine UTC clock). Full logs inspected. Round 2 recaptured all five after routes with fresh
profiles (`.godot/a1/r2-final-zh` and `r2-final-en`); original before PNGs retained.
The hover-colour assertion follows dark engraving on the light plate; seven added
checks cover English inscription bounds and an empty unused frame. Windows
certificate-store diagnostics also occur in the untouched baseline captures.

Only the room renderer, its presentation checks and this evidence folder change.
Journey-board texture/rows/font sizes, imported GLB, palette tokens, screen shader,
lab_home camera/hover/navigation logic, terminal/pages, localization, original bit
visuals, simulation, results, progression and save fields are untouched.

Limits: no human/native mouse playtest, other GPU, long performance soak or full
journey earned through play. The narrow room-board data remains small in the
observation view; its row layout and typography belong to W7 and were preserved.
No proposals needing simulation or gameplay impact analysis.

Scratch captures/logs and isolated profiles are under `.godot/a1/` and
`.godot/verification/`; this sandbox permits writes only inside this worktree.
No commit, push, merge, stash, reset or branch switch was performed.

Additional production dev-route smoke (normal motion, fresh profile):

```powershell
# Same Godot executable and --path as above, followed by:
-- --test-mode --dev-move=1225,650@8 --dev-shot=<scratch>/settings.png@9 --dev-move=175,412@10 --dev-shot=<scratch>/archive.png@11 --dev-click=175,412@12 --dev-shot=<scratch>/open.png@14 --dev-key=Escape@15 --dev-shot=<scratch>/returned.png@18 --dev-quit=20
```

Coordinates are logical 1600 ? 900 coordinates for the default scaled main scene.
Observed `dev-scaled-open.png` shows the actual archive reader and
`dev-scaled-returned.png` shows the restored room; images and full log remain in
`.godot/a1/`. The `dev-move` shots did not show hover brackets, so they are not
counted as hover acceptance. Reduced-motion comparison captures exercise the
production semantic hover callback; the suite separately verifies ray picks.
