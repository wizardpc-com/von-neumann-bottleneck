# L1 laboratory home - 2026-11-04

The room now has a bound handbook, a rotary control panel and an envelope tray.
Six physical bilingual nameplates brighten on hover. Four frames show the newest
four saved outputs (first 32 cells each, preserving the existing palette); unused
frames stay dim. Eleven equipment modules and chapter seals share the exact
completed-station state used by the journey board. Wall finishes and a localized,
slowly breathing warm desk light add depth. Reduced motion freezes the new light.
The imported GLB, globe loop, original bit visuals, routing, simulation and save
formats are unchanged. Existing bilingual object nouns are reused from lab_home.

## Before / after

Round 1 originally captured 18 PNGs; four room/work PNGs are retained here.
The other round-1 captures remain in `.godot/l1b/retained-originals/`. All images are 1280 x 720. `before-*.png` uses the unchanged HEAD room script;
`after-*.png` uses the source recorded in round1-tested-source-sha256.json.

| Route | Before | After |
| --- | --- | --- |
| Fresh room at 4 seconds | [room](before-room.png) | [room](after-room.png) |
| Real saved work, real 2/57 completions | [work](before-work.png) | [work](after-work.png) |

The capture helper inherits `prepare_saved_work()` from the existing saved-work
window test. It trains, restores a predictive packet, completes eligible prediction,
generates and explicitly saves an actual 16-cell work. No progress or output is
fabricated; the resulting 2/57 comes from the existing production creation flows.
Before/after fresh captures use ordinary Game state. English uses fresh Test mode;
its existing access/progress behavior is retained.

Hover shots send mouse motion, then feed the production ray-pick result to the
production hover handler, with automatic cursor polling temporarily disabled.
The injected `--dev-move`/viewport motion alone did not update OS mouse position
in this harness. All six recorded pick results match their target ids. These
captures verify rendering and ray selection, not physical mouse ownership.
Reduced motion holds the camera steady for comparison. Normal motion is restored
before performance sampling, with physics/cursor polling enabled.

The round-1 command below is historical. The current helper writes to `.godot/l1c/`;
use the Round 3 command for the current room. Reproduce captures in a fresh APPDATA and LOCALAPPDATA beneath
`.godot/l1/` (use a new directory each run):

```powershell
$env:APPDATA="$PWD/.godot/l1/review-profile"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script docs/verification/20261104-l1-lab-home/capture.gd -- --phase=after
```

## Verification

Exact final command, from the worktree root, with APPDATA and LOCALAPPDATA both
set to the fresh `.godot/l1/verify-final` directory:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_immersive_lab --suite test_lab_journey --suite test_lab_navigation_soak --suite test_lab_saved_work_window --suite test_room_page_skin_lifecycle --suite test_room_skin_dynamic_descendants --suite test_lab_terminal_routing --suite test_lab_terminal_pages --suite test_global_save
```

Final run `.godot/verification/20261104T103341Z-dd1028a6`: **9/9 suites PASS**,
plus import and isolated-user-directory gates PASS. See [exact results](suite-results.txt).

| Suite | Checks | Failures |
| --- | ---: | ---: |
| test_immersive_lab | 443 | 0 |
| test_lab_journey | 52 | 0 |
| test_lab_navigation_soak | 162 | 0 |
| test_lab_saved_work_window | 26 | 0 |
| test_room_page_skin_lifecycle | 96 | 0 |
| test_room_skin_dynamic_descendants | 27 | 0 |
| test_lab_terminal_routing | 39 | 0 |
| test_lab_terminal_pages | 52 | 0 |
| test_global_save | suite-level PASS (no count emitted) | 0 |

Four new assertions verify completed-only chapter illumination, English nameplate,
real palette values and an empty second frame. No pinned geometry/pixel assertions
were loosened. The first iteration's four aspect-ratio failures exposed an enlarged
Journey region from the equipment rail; the final rail is a passive display and
the original journey-board focus bounds are preserved. Final source bytes match
the verifier's isolated project copy.

GPU: Godot 4.7.1 / Compatibility / RTX 5070 Ti Laptop, 1280 x 720. After a one-second
warmup, 180 normal-motion frames averaged 16.6603 ms; Performance.TIME_FPS = 60.
Baseline normal-motion sample averaged 16.6607 ms. These are capped wall-clock
frame intervals, not isolated GPU timings. Raw captures, earlier failures and
logs remain in ignored `.godot/l1/`; final render log is `after-proof.log`.

## Limits / proposals

No proposals requiring simulation/progression/save impact analysis.
Chapter illumination uses the tested completed-station presentation fixture;
the captured real 2/57 run does not complete a whole chapter. The gallery has four
visible slots and 32-cell previews; the existing Works page retains the collection
and full output. Native mouse/keyboard, newcomer understanding, long-duration GPU
soak and other machines remain unverified. The terminal-pages suite explicitly
skips nested native Window focus in headless mode. Existing room render suspension
is preserved and covered by immersive regressions, not remeasured as GPU draw calls.
All engine runs emit the environment's root certificate-store warning; it also
appears in baseline and passing suites. No networking was needed.


## Round 2 - quiet night laboratory

The room uses cooler, darker architectural finishes and a dim ceiling diffuser.
A physical desk lamp casts a warm shadowed pool across the desk. Rounded book
covers, page edges and a curved spine replace the slab silhouette; the instrument
panel has a rounded face, cylindrical metal knobs and a power indicator. The
letter tray has rounded lips and a folded envelope. The chapter display is an
11-slot standing equipment rack with a cable to the terminal. Its indicators and
the larger rimmed chapter medals use the board's completed-station state.
The four work previews use a wider two-column arrangement and square output cells.
Six physical plates use the existing bundled font, with higher raster resolution,
no outline and contrasting backing. No localization entries were added.

Normal motion adds staggered earned-indicator shimmer and 12 faint lamp motes.
Reduced motion freezes the motes immediately, stops emission and holds the lamp
and earned indicators steady. Simulation, saved outputs and progression keep their
existing authority. Imported GLB bytes, signal visuals and routing controllers are
unchanged.

### Render iterations

1. Added rounded objects, standing rack, medals, lamp and dark rear wall. Measured
   16.6598 ms / 60 FPS. The image exposed wall shadow stripes and gallery overflow.
2. Restored the broad lights' shallow-angle shadow bias and corrected gallery
   transforms; wall stripes disappeared. Added slow earned-light shimmer and dust.
   Measured 16.6616 ms / 60 FPS.
3. Darkened side fields and workstation, dimmed the ceiling's emissive strip and
   aligned both frame rows. Measured 16.6616 ms / 60 FPS. The desk pool now has a
   visible boundary while the terminal is the visual focus.
4. Final refinement: desk shadow bias, clear bilingual front plates, readable
   semantic names and matching triangle colliders on every rounded submesh,
   immediate reduced-motion particle freeze, and full-size desktop plate lettering. Final measurements and suite receipt are recorded below.

### Round 2 comparisons

At the Round 2 handoff there were 23 PNGs: four round-1 comparisons and 19 round-2 images. Round 3 archives the round-2 baseline and reduced-motion intermediates under `.godot/l1c/retained-round2/` to keep the durable evidence at 24 PNGs.
Round-2 baseline is the exact round-1 working tree, captured before editing.

| Route | Before | After |
| --- | --- | --- |
| Fresh room | archived locally | [room](r2-after-room.png) |
| Handbook hover | archived locally | [handbook](r2-after-handbook.png) |
| Settings hover | archived locally | [settings](r2-after-settings.png) |
| Feedback hover | archived locally | [feedback](r2-after-feedback.png) |
| Works hover | archived locally | [works](r2-after-works.png) |
| Achievements hover | archived locally | [achievements](r2-after-achievements.png) |
| Archive hover | archived locally | [archive](r2-after-archive.png) |
| Real saved output / 2 of 57 completions | archived locally | [work](r2-after-work.png) |
| English | archived locally | [English](r2-after-en-room.png) |

The round-2 reduced-motion frame is archived locally. Comparison routes hold reduced motion
on for matching camera poses; the performance sample restores ordinary motion,
globe rotation, dust, physics and cursor polling. The final hover helper checks
the production ray and searches inside the target bounds if its center is empty;
it never emits activation or grants progress. This verifies rendering and semantic
surface reach, not physical mouse input.

```powershell
$env:APPDATA="$PWD/.godot/l1b/review-fresh-profile"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script docs/verification/20261104-l1-lab-home/capture.gd -- --phase=review
# Repeat with another fresh profile and --locale=en.
# The current helper writes PNGs and intermediate captures to .godot/l1c/.
```

Compatibility is the project's configured renderer on both desktop and mobile.
SSAO is unavailable in that renderer; glow configuration and Filmic tonemapping
are retained, without changing the renderer or claiming unsupported effects.
The visual result relies on actual spotlights, material contrast and geometry.
No geometry assertions were loosened. Native input, other GPUs, long GPU soak,
full chapter earning and human aesthetic acceptance remain unverified.
No proposals requiring impact analysis.


### Final Round 2 verification

Fresh APPDATA and LOCALAPPDATA: `.godot/l1b/verify-accepted-profile`.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_immersive_lab --suite test_lab_journey --suite test_lab_navigation_soak --suite test_lab_saved_work_window --suite test_room_page_skin_lifecycle --suite test_room_skin_dynamic_descendants --suite test_lab_terminal_routing --suite test_lab_terminal_pages --suite test_global_save
```

Final isolated run: `20261104T105931Z-53eb5f10`: **9/9 suites PASS**,
899 counted checks, zero failures, plus GlobalSave suite PASS and import/isolation
gates PASS. [Exact results](suite-results-round2.txt), [machine receipt](round2-results.json).

| Suite | Checks | Failures |
| --- | ---: | ---: |
| test_global_save | suite PASS | 0 |
| test_immersive_lab | 445 | 0 |
| test_lab_journey | 52 | 0 |
| test_lab_navigation_soak | 162 | 0 |
| test_lab_saved_work_window | 26 | 0 |
| test_lab_terminal_pages | 52 | 0 |
| test_lab_terminal_routing | 39 | 0 |
| test_room_page_skin_lifecycle | 96 | 0 |
| test_room_skin_dynamic_descendants | 27 | 0 |

Two new assertions check immediate reduced-motion particle freeze and normal-motion
resume. The four round-1 real-state/language assertions remain. No pinned geometry
assertions changed. The final source and test hashes match the isolated test copy
and are recorded in `tested-source-sha256.json`.

After a one-second warmup, 180 normal-motion frames averaged **16.6607 ms**,
Performance.TIME_FPS **60**; English averaged 16.6613 ms. These are capped wall-clock
frame intervals on Compatibility / RTX 5070 Ti Laptop at 1280 x 720, not isolated
GPU timings. Raw logs: `.godot/l1b/accepted.log`, `accepted-en.log`,
`verify-accepted.log`. All six final hover ray results match their target ids.
The existing certificate-store warning and Git ignore-file access warning remain;
they were also present in earlier passing runs.


## Round 3 - composition and finishing

The lamp sits beside the handbook, leaving the globe fully visible; the rack is
further left and back. Eleven dark glass indicators have thin metal bezels and
front-panel highlights, with a thin cable running toward the terminal base.
Earned teal illumination still uses the same completed-station state as the board.
The desk and legs use a rough neutral grey finish. The four existing work frames
are 65% taller, with matte surfaces and proportion-corrected coloured cells from
actual saved outputs. Physical nameplates have thinner metal borders and dark
faces; font size and bilingual labels are unchanged.

Plated objects retain corner brackets and plate brightening without a duplicate
hover pill. The terminal, globe and journey board retain their existing pills.
The existing keyboard routes and page focus behavior remain covered by the room,
navigation and terminal suites; no new keyboard object-selection mode is added.

### Render iterations

1. Separated lamp/globe/rack, neutralized the desk, enlarged the work inset and
   thinned plates. [Iteration 1](r3-iteration1-room.png) exposed a bright panel
   reflection and stretched output glyphs. Mean normal-motion frame interval:
   16.6623 ms / 60 FPS.
2. Made the work panel matte and adjusted glyph proportions. The first proportion
   pass made cells too wide; the final pass centers compact cells within each
   frame. Final Chinese and English captures and timings are recorded below.

### Round 3 comparisons

The baseline is the exact round-2 uncommitted source, freshly captured before
runtime edits. All comparison routes use the same helper, viewport, reduced-motion
camera pose and real-saved-work preparation described above.

| Route | Before | After |
| --- | --- | --- |
| Fresh room | [before](r3-before-room.png) | [after](r3-after-room.png) |
| Settings hover | [before](r3-before-settings.png) | [after](r3-after-settings.png) |
| Archive hover | [before](r3-before-archive.png) | [after](r3-after-archive.png) |
| Real saved output / 2 of 57 completions | [before](r3-before-work.png) | [after](r3-after-work.png) |
| English | [before](r3-before-en-room.png) | [after](r3-after-en-room.png) |

Reproduce in a new profile for each invocation:

```powershell
$env:APPDATA="$PWD/.godot/l1c/review-new-profile"
$env:LOCALAPPDATA=$env:APPDATA
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$PWD" --script docs/verification/20261104-l1-lab-home/capture.gd -- --phase=review
# Repeat with a different fresh profile and --locale=en before the -- separator.
```

No simulation, result metrics, station-state source, task IDs, save fields or
localization entries changed. No proposals needing impact analysis.
Physical mouse/keyboard operation, other GPUs, a full chapter earned through play,
long GPU soak and human aesthetic acceptance remain unverified. Automated hover
captures exercise real ray picks and presentation, not native cursor ownership.

### Final Round 3 verification

Fresh APPDATA and LOCALAPPDATA: `.godot/l1c/verify-final-profile`.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_immersive_lab --suite test_lab_journey --suite test_lab_navigation_soak --suite test_lab_saved_work_window --suite test_room_page_skin_lifecycle --suite test_room_skin_dynamic_descendants --suite test_lab_terminal_routing --suite test_lab_terminal_pages --suite test_global_save
```

Final isolated run `20261104T111732Z-b494fb9a`: **9/9 suites PASS**, 913 counted
checks, zero failures, plus GlobalSave suite PASS and import/isolation gates PASS.
[Exact results](suite-results-round3.txt), [machine receipt](round3-results.json),
[source hashes matching the test copy](round3-tested-source-sha256.json).

| Suite | Checks | Failures |
| --- | ---: | ---: |
| test_global_save | suite PASS | 0 |
| test_immersive_lab | 459 | 0 |
| test_lab_journey | 52 | 0 |
| test_lab_navigation_soak | 162 | 0 |
| test_lab_saved_work_window | 26 | 0 |
| test_lab_terminal_pages | 52 | 0 |
| test_lab_terminal_routing | 39 | 0 |
| test_room_page_skin_lifecycle | 96 | 0 |
| test_room_skin_dynamic_descendants | 27 | 0 |

Fourteen new checks cover duplicate-pill removal, retained brackets and plate
brightening, and hints on unplated objects. Existing geometry, reachability,
24-second globe-loop, real-state and reduced-motion assertions remain intact.
All full suite logs were inspected. The terminal-pages headless suite retains its
native nested-Window focus skip. Certificate-store warnings also appear in the
fresh baseline; no new suite failures occurred.

Final normal-motion wall-clock frame sample after one second warmup, 180 frames:
Chinese **16.6612 ms / 60 FPS**, English **16.6617 ms / 60 FPS**; fresh round-2
baseline **16.6622 ms / 60 FPS**. These are capped intervals on Compatibility /
RTX 5070 Ti Laptop at 1280 x 720, not isolated GPU times or evidence of a speedup.
[Raw measurements](round3-frame-times.json). Scratch logs remain in `.godot/l1c/`.

24 PNGs are retained across all rounds, including five final Round 3 pairs and
one first-iteration frame. Source diff and `git diff --check` were inspected.
No commits, pushes, merges, stashes, resets or branch switches were performed.
