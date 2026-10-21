# Immersive laboratory integration candidate — 2026-10-21

Baseline: `472890a9a014683517614e8737bf288caaa95241`.
This is a new-branch integration candidate, not a graphical acceptance receipt.

## Runtime ownership

- `LabHome` retains its existing terminal, arrival/departure, archive, localization and progression-reading controller.
- `LabRoom3D` owns only imported geometry, fixed-position camera, lighting, physical picking and read-only displays. Mouse look is bounded to ±12° horizontally and ±6° vertically. This is not free walking or a complete 360° environment.
- Start/Continue and Journey use the existing `TaskNavigation` routes; saved works use the existing protected Journey Journal; achievements use the existing achievements/save page; the reader uses the existing handbook; settings use the existing settings overlay; the letter opens the existing voluntary local feedback panel. No new external submission is introduced.
- The globe preserves the authored Africa-facing pose and axial tilt, with a runtime replacement of the imported offset timeline: exactly 24 seconds, linear rotation, fixed center. Reduced motion pauses it and fixes the viewing direction.
- Picks use the nearest actual triangle hit among semantic geometry and opaque architecture. A wall is a blocker, not a transparent route to a board behind it.
- `--flat-lab` keeps the earlier drawn laboratory presentation; `--classic-hub` retains the existing diagnostic classic entry. Neither creates another save or grants progress.

## Controls

Move the pointer to gently turn the fixed camera. Click a visible object to open its existing feature. Use the top-row shortcuts with Tab/Enter when a small object is inconvenient to target. Terminal focuses the screen; Look around releases the menu to explore the room again. Esc closes the current existing overlay first; at home it opens the existing quit confirmation. Reduced motion fixes the camera and pauses the globe. No click on a wall can activate a hidden object behind it.

## Asset and render boundary

The imported GLB contains 208 mesh objects, approximately 190,400 triangles, 19 materials and the Natural Earth globe texture. Its geometry came from the separately reviewed Blender v10 source, not from a screenshot. Natural Earth attribution is included beside the asset. Godot lighting is an engine-native approximation: Blender baked probes, procedural micro-bump and compositor settings do not transfer through GLB. No claim is made that the Godot image matches the Blender image before actual renderer review.

The terminal is a 2D control aligned to the projected front glass bounds, not a perspective-correct live texture. It is only shown once the camera is front-aligned; look-around hides the awake menu. Camera focus/return and the entry passage remain reversible presentation effects.

## Verified environment and limit

Official Linux Godot `4.7.1.stable.official.a13da4feb`, downloaded from the vendor archive and SHA512-verified. The approved existing virtual display could not start in this execution environment. The engine's own help reports headless supports only `dummy`, not a graphics backend. Consequently there are no new Godot screenshots or measured GPU/frame-time claims in this receipt. Headless tests establish runtime logic/geometry/layout only.

`scripts/capture-immersive-lab.gd` is a real-display capture helper and refuses headless mode rather than produce empty evidence. Run it only in an isolated QA project, after import, on a supported graphical Godot backend. Capture arrival, both look directions, focused terminal and each panel; review 1280×720 Chinese/English and 1600×900, clipping, surface contrast, shadows, hover readability and transition feel. Measure target-device frame time before release.

## Automated evidence

Initial published candidate isolated run `20261021T141651Z-f3f61b6b`, Godot 4.7.1, Linux headless: import + custom-user-directory isolation + all 10 selected suites passed. Source saves were never used. This is not the full repository suite and not rendered acceptance.

| Suite | Result |
| --- | --- |
| test_immersive_lab | 166 assertions passed |
| test_hub_first_screen | 6,955 assertions passed |
| test_lab_journey | 48 assertions passed |
| test_lab_terminal_routing | 37 assertions passed |
| test_two_worlds | 45 assertions passed |
| test_terminal_presentation_polish | 32 assertions passed |
| test_journey_journal | 173 assertions passed |
| test_journey_work_review | 125 assertions passed |
| test_learning_handbook | passed |
| test_prelaunch_settings | passed |

The new suite checks Chinese/English at 1280×720 and 1600×900, safe screen bounds and recovered keyboard focus after recentering, truthful station/work displays including fixtures and empty state, all existing feature panels and return guards, globe loop/center and reduced motion. A production triangle ray grid found all nine semantic objects at the neutral camera; the two previously proven wall-through-click pixels return no action. The grid log records actual coordinates.

Four iterations exposed/corrected a null physics-world lookup, menu wake visibility, classic homepage reappearing after achievements, and layout test logical-size mismatch. Independent review led to actual per-station/works data, pre-departure recentering and withholding flat UI until front alignment. The old eight-frame wake assertion was updated to wait 0.6 seconds for that deliberate camera transition; no occlusion or bounds assertion was relaxed. Explicit focus recovery after this transition is separately tested.

The final source includes larger physically bounded panel type after font-metric/projection calculation (approximately 11 pixels at 1600×900). That numeric check is not a substitute for human legibility review. No Godot screenshot or frame-rate result was produced. Native mouse feel, graphics/materials/shadows, target performance, exported game startup and the complete repository regression remain unverified.

Published candidate should be reviewed on a graphical machine before merging to main. Raw selected-suite logs and the machine-readable result are included beside this receipt.

## Initial-input correction (2026-10-21, 15:00 UTC)

Additional existing input suites exposed a real arrival regression: the default OS pointer coordinate (0,0) was treated as an intentional look gesture before any mouse motion. This moved the camera off-center, delaying Enter wake and caret visibility. The earlier 0.6-second test wait masked this issue rather than fixing it.

The room now stays neutral until an actual mouse-motion event and recenters when the pointer is outside its bounds. The original eight-frame laboratory wake assertion has been restored without a relaxed timeout. A new neutral-arrival assertion covers ordinary motion settings.

Isolated run `20261021T145813Z-33714b07` passed import, user-directory isolation and all eight selected suites: first_lesson_input, ui_convergence, immersive_lab (167 assertions), lab_journey, lab_terminal_routing, terminal_task_titles, terminal_language_input and settings_language_input. Exact tested source bytes were compared before committing. The two before-fix failing logs and all after-fix results are retained in `input-followup/`.

Remote CI run 39620977961 was last observed at 14:57 UTC with Python checks successful and Godot checks in progress. Further CI reads were denied by the execution permission review and were stopped. No terminal CI result is claimed. These local results are not a substitute for full remote CI or graphical acceptance.

## Interaction detail correction (2026-10-21, 15:10 UTC)

Reproduced failures, then corrected:
- After keyboard navigation inside Archive, closing lost the launching shortcut's focus (three repeated cycles failed). Preserve and restore the valid opener, with a visible room shortcut fallback; ignore duplicate Archive opens.
- Reduced-motion navigation with no destination still used a 0.5-second animated return. Restore the room directly in this fallback, without that tween. Normal motion keeps its transition.
- Return-focus repair must not steal focus from a feedback modal opened through the existing global shortcut while navigation is pending. The final guard and test cover this case.

The rotated-camera ESC confirmation hypothesis did not reproduce as a defect. Its existing implementation was not changed; the regression check now covers confirmation focus and a second ESC returning to the primary action. Repeated route activation emits once, pending navigation blocks other room actions, and modal opening clears the underlying hover hint.

Broad isolated run `20261021T150722Z-72293996` passed all eight selected suites (first_lesson_input, immersive_lab, lab_journey, lab_terminal_routing, prelaunch_settings, settings_language_input, terminal_language_input, ui_convergence). After the final modal-focus guard, isolated run `20261021T150929Z-d6829a76` re-ran and passed immersive_lab (188 assertions), lab_journey and lab_terminal_routing, plus import and isolated-user-directory checks. Final source bytes match that tested project. Before-fix, broad and final logs are in `detail-followup/`.

Tests include control-level calls and headless viewport dispatch from existing input suites, not native OS mouse/keyboard or rendered usability validation. The prior CI-read and graphical acceptance limitations still apply; no new CI result was obtained.
