# A7 - UI scale decision study - 2026-11-08

**Decision material only. Do not integrate this branch. Keep A now; recommend a separately approved C layout pass before adopting C.**

Baseline `196d08e`; Godot `4.7.1.stable.official.a13da4feb`, Windows, OpenGL Compatibility, RTX 5070 Ti Laptop GPU. Only `src/ui/window_mode.gd` has a source diff: private `SCALE_STUDY_OPTION`, finally set to `A`. Change that constant to B/C to compare. `project.godot` remains unchanged. Workbenches, simulation, judgement, results, task IDs, save formats and localization are untouched. This experimental policy is not a shipping implementation or a user setting.

## Options

| Option | Policy | Physical size of logical 14 / 16 px at 720p | At 1080p | Assessment |
| --- | --- | --- | --- | --- |
| A current | 1600x900, canvas_items, expand, factor=1 | 11.2 / 12.8 px | 16.8 / 19.2 px | Compact; small text at 720p. Keep as current default and reference. |
| B font floor study | Keep 1600x900. Standard Control fonts multiplied by max(1,1/window_ratio), rounded up; 1.25 at 720p, 1 at 1080p | 14.4 / 16 px | Same font sizes as A | Better standard text, more wrapping/scrolling; explicit draw_string sizes remain small. Layout recursion conflict also found. Do not adopt this implementation. |
| C smaller base | Window.content_scale_size=1280x720; existing stretch mode/aspect/factor retained | 14 / 16 px | 21 / 24 px | Most consistent direction, with lower density and necessary layout work. |

C overrides the logical size in the autoload to isolate the comparison. Adoption should also align project.godot viewport/initial-window settings and WindowMode.DESIGN_SIZE, rather than ship only this override.

With canvas_items, this is not enlargement of one low-resolution UI bitmap. A's main problem is small effective type and fine fractional-pixel strokes. B standard text looks stronger at 720p while custom drawing stays small. C body/button text is clearer and largest at 1080p. These are visual observations, not instrumented font-raster measurements. All options retain some existing custom-drawn text below 13 physical px; C is not a universal readability guarantee.

## Evidence: 10 PNGs containing all 120 unscaled views

Six native atlases each contain ten routes at BOTH resolutions. Images are pasted at native pixels, without interpolation. Left = 1280x720; right = 1920x1080. Gray below a left image is padding, not missing game content. Each atlas is 3200x11120: download/zoom to 100%; chat previews shrink it.

| Option | Chinese | English |
| --- | --- | --- |
| A before | [A Chinese](A-zh_CN-native-atlas.png) | [A English](A-en-native-atlas.png) |
| B after | [B Chinese](B-zh_CN-native-atlas.png) | [B English](B-en-native-atlas.png) |
| C after | [C Chinese](C-zh_CN-native-atlas.png) | [C English](C-en-native-atlas.png) |

Four direct comparisons, all A / B / C left-to-right at native 1280x720:

- [Chapter 2](compare-03-zh_CN.png): mission text, wrapping and machine clearance.
- [Chapter 4](compare-05-zh_CN.png): left-column density versus unchanged custom address lettering in B.
- [Service English](compare-07-en.png): B pushes lower editor controls into scrolling; C preserves more editor content.
- [Creation English](compare-09-en.png): B title ellipsis; C playback explanation wraps and fewer examples fit.

Atlas row i screenshot origins: left `(0, i*1112+32)`; right `(1280, i*1112+32)`.

| Row | Route | Observed differences / risks, mainly at 720p |
| --- | --- | --- |
| 00 | lab home | Chinese is the room; English is the terminal start page after returning home in the same process. This sequence is identical for A/B/C. Room UI has independent 3D/subviewport scaling; root policy does not guarantee its text changes. B English footer links wrap to two lines. |
| 01 | journey map | B English chapter tabs ellipsize earlier. C shows fewer branches, and the upper node is cut by the viewport edge: review initial framing. Canvas is pannable; this does not prove inaccessible tasks. |
| 02 | hardware_foundations/half_adder | C graph fit falls to about 62% Chinese / 55% English. B English toolbar wraps. C displays fewer component rows. Original 0/1 appearance retained; automatic graph fit offsets some text-size gain. |
| 03 | chapter_2/distant_reads | B mission wraps more and exposes less explanation. C mission window occupies a larger fraction of the screen. Actual replay tests additionally detect machine/label clearance failures. |
| 04 | chapter_3/buffers | C fixed-width mission consumes more canvas and partly obscures the transfer device; mission scrolling increases. English header goal ellipsizes. B English mission also needs more scrolling. |
| 05 | chapter_4/fields | B denser instructions and controls, but explicit address/field drawing remains fixed. C wider sidebar, narrower address area, fewer records visible. Run remains visible. |
| 06 | representation/mixed_scan | B enlarges controls but explicit 13/14px byte-grid text remains about 10.4/11.2 physical px. C improves byte-grid lettering while increasing table/button footprint. Large pending-run empty area remains. |
| 07 | service/move_state | B English lower editor goes into scrolling and bottom status ellipsizes. C editor widens while results narrow. Long status ellipsis also exists in A; not all truncation is new. |
| 08 | prediction/regular | B rule explanation wraps more. C timeline/controls occupy more space and lower-left explanations narrow. Initial Run remains visible; no conclusion about long histories from this entry view. |
| 09 | creation/C1_restore | B English chapter title becomes Compre...; C shows fewer examples and wraps English playback explanation onto two lines. Initial primary action remains visible; later stages not covered. |

These are entry-state observations, not acceptance of every hidden window or run state. All 1080p originals are included. A/B use similar font sizes there; after the 720p-to-1080p resize, B can retain enlarged window geometry. C still has less logical space and does not recover A's density at 1080p.

## Verification

| Option | test_unified_style, headless | test_locality_trace_presentation, headless | Same presentation suite, real GPU |
| --- | --- | --- | --- |
| A | 74 checks / 0 failures | 2497 / 0 | 2497 / 0 |
| B | 74 / 0, direct isolated-project run | 2497 / 3, direct isolated-project run | 2497 / 3 |
| C | 74 / 0 | 2497 / 36 | 2497 / 36 |

B: all 3 failures concern result-bench height versus existing content height. C: 4 machine-node/free-band failures and 32 wire-caption/node intersections. They are real layout risks under the changed policy, not fixed assertions. No tests were edited. The untouched A run passed, so these are not labelled pre-existing.

Standard verifier: A both suites PASS; C one PASS / one FAIL. B import PASS, but its user_directory startup probe hit a resized/fit_page_margin recursion at lab_terminal_pages.gd:105-107 (stack overflow), so the standard runner did not reach the suites. Both headless suites were then run directly in that isolated B copy, producing the full counts above. This does not mean B passed the standard runner.

B initial capture had a few deferred arguments referring to freed Controls. The final private code accepts Variant and checks validity before touching the node; the B direct suites and GPU run use that guard. It does not alter live-control font sizes/pixels, so the original B captures are retained. The recursion in the separate startup probe remains an adoption risk. All GPU logs also contain a system root-certificate-store read warning, including A; no network functionality was tested.

Raw logs, scripts, profiles and 120 individual PNGs: `.godot/a7-study/`. Standard isolated copies:

- A: `.godot/verification/20261107T180247Z-ad3e5bf6/`
- B: `.godot/verification/20261107T180724Z-5323d71c/`
- C: `.godot/verification/20261107T181129Z-8ec72f02/`

Scratch is inside this worktree because current write permissions cover only this worktree, rather than the requested external tmp directory. Every Godot launch used isolated APPDATA and LOCALAPPDATA; no real player save was read.

Exact commands from the root, selecting the private option before each run:

```powershell
$GODOT = 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$env:APPDATA = "$PWD/.godot/a7-study/<fresh-run>-profile"
$env:LOCALAPPDATA = "$PWD/.godot/a7-study/<fresh-run>-local"
python -X utf8 scripts/verify-project.py --godot $GODOT --suite test_unified_style --suite test_locality_trace_presentation
& $GODOT --path "$PWD" --script res://tests/test_locality_trace_presentation.gd -- --capture-size=1280x720
```

B direct headless follow-up, each with a fresh isolated profile:

```powershell
& $GODOT --headless --path "$PWD/.godot/verification/20261107T180724Z-5323d71c/project" --script res://tests/test_unified_style.gd
& $GODOT --headless --path "$PWD/.godot/verification/20261107T180724Z-5323d71c/project" --script res://tests/test_locality_trace_presentation.gd
```

## Adoption effort and test risks - estimates, not completed work

- A: zero migration; accept small 720p text. It cannot meet a physical 14px body floor.
- B: at least ten entry screens plus independent lab subviewports and custom map/circuit/byte/address drawing; roughly 15-25 UI files to inspect/adapt. Resolve theme/resize recursion, font-source synchronization and resize geometry retention. The current experiment is insufficient.
- C: about two global configuration files, then ten entry-screen reviews. Prioritize six layout families: map, prologue, chapters 2/3, Service and Creation; roughly 10-20 UI files. Verify the other 50 tasks, popups and run states. This is not a time commitment.
- At least 8 relevant presentation suites need review: completion, feedback, locality_trace, prediction_workbench, representation_workbench, task_tree, terminal_presentation_polish, tree_journey. Of these, 5 have explicit renderer/capture paths and 3 reset content_scale_size themselves, potentially masking the global policy. Estimate 5-8 suites need changed/expanded real-root coverage; only locality failures were actually established here. No advance authorization to weaken tests is implied.

Owner choices: A preserves compactness/current behavior; B makes body text larger with uneven density and substantial implementation risk; C is more consistent and larger at 1080p, at the cost of layout adaptation and less simultaneous content. Recommend C for a separate approved adaptation pass; keep A until then.

Proposals needing impact analysis: before adopting C, decide how circuit auto-fit interacts with minimum graph text, fixed side-window proportions and default map framing. Preserve comparisons for changes to default information visibility or operation flow. No simulation/result/progression change is proposed.

## Reproduce captures

The dev helper forces 1280x720, so a temporary SceneTree runner calls existing TaskNavigation instead. One fresh process per option; Chinese ten routes then English ten routes. Per route: wait 8 seconds; set each physical window size; wait 0.7 seconds and frame_post_draw; save root texture. All 120 screenshot dimensions were individually asserted; each atlas tile was also verified pixel-for-pixel equal to its original PNG. Final default-A unified-style smoke: 74 checks / 0 failures. Capture logs report A/B logical 1600x900 and C 1280x720.

```powershell
$env:A7_OPTION = 'A' # Also select the matching private source constant
& $GODOT --path "$PWD" --script res://.godot/a7-study/capture.gd -- --capture-size=1280x720
```

Runner source, retained here so it can be rebuilt after clearing ignored scratch:

```gdscript
extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 await create_timer(1.0).timeout
 root.get_node("GameMode").set_mode(&"test")
 var option: String = OS.get_environment("A7_OPTION")
 var folder: String = "res://.godot/a7-study/" + option
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 var routes: Array[String] = ["home", "tree", "hardware_foundations/half_adder", "chapter_2/distant_reads", "chapter_3/buffers", "chapter_4/fields", "representation/mixed_scan", "service/move_state", "prediction/regular", "creation/C1_restore"]
 for locale: String in ["zh_CN", "en"]:
  root.get_node("Localization").set_preferred_locale(locale)
  for index: int in routes.size():
   var route: String = routes[index]
   root.size = Vector2i(1280,720)
   if route == "home": change_scene_to_file("res://src/ui/prototype_hub.tscn")
   elif route == "tree": root.get_node("TaskNavigation").open_tree()
   else: root.get_node("TaskNavigation").enter(route)
   await create_timer(8.0).timeout
   for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
    root.size = dimensions
    await create_timer(0.7).timeout
    await RenderingServer.frame_post_draw
    var picture: Image = root.get_texture().get_image()
    var name: String = "%02d-%s-%dx%d.png" % [index,locale,dimensions.x,dimensions.y]
    picture.save_png(folder.path_join(name))
    print("CAPTURE ", option, " ", route, " ", name, " pixels=", picture.get_size(), " logical=",root.get_visible_rect().size," factor=",root.content_scale_factor)
 quit()
```

Not verified: all 60 tasks, native player interactions, long results/text, HiDPI, multiple monitors, non-16:9 ratios, native fullscreen switching, exported builds or all GPU suites. No commit, push or integration.
