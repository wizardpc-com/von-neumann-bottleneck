# A4 — Journey map chapter identity — 2026-11-08

Presentation only. The uncommitted diff belongs to `claude/vux-a4-mapart-20261108`, based on `196d08e`.

## Round 2 review

Tray nodes consistently omit the chapter prefix and retain the task wording at every text-visible zoom, with trailing ellipsis on overflow. Detail cards, lists and tooltips retain full titles. The session clock now has a bilingual hover explanation: optional temporary exploration, not retained after leaving.

Re-ran the same eight suites with the command below: **8 PASS / 0 FAIL**, import and isolation checks PASS ([results](round2-suite-results.json), [run log](round2-suite-results.txt)). Added bilingual title checks at zoom 0.4/0.85/1.6. Original captures and comparison sheets were refreshed; added [chapter 7 Chinese](after-chapter7.png) and [English](after-english7.png). The [capture log](round2-capture.txt) ([exit-0 receipt](round2-capture-receipt.json)) records both session tooltip strings and **0 / 240 idle redraws** again. Capture script: [capture.gd.txt](capture.gd.txt); final launch used `.godot/a4-temp/round2-sealed-capture-profile`, `A4_PHASE=round2`. Scripted routes and tooltip checks do not establish native mouse acceptance.

## Changes and owner choices

- Eleven pastel chapter accents and eleven schematic emblems replace eight repeating map colours. Tab, tray heading, task detail and real progress bar share their chapter accent. The existing large chapter-card artwork remains the default outside the map.
- Available tasks keep a quiet outline; completed tasks use a filled check and accent edge; locked tasks remain dim with a lock; optional tasks gain a dashed perimeter. Continue keeps its steady ring. Owner choice: the old card styling remains visible in the before PNGs; the new styling reduces reliance on status text.
- A restrained screen-space signal grid and flat trays replace the blank canvas and broad tray shadows. Solid prerequisites and dashed suggestions retain their actual relationships; non-focused edges are less heavily dimmed. Incoming selected edges keep the existing amber emphasis.
- Node titles are at least 18 logical px and visible status captions at least 17 (14.4 / 13.6 output px at 1280×720). At overview scale, task text remains intentionally omitted. Badges reserve title width.
- Chinese tabs fit the strip. English labels retain full text inside their buttons and use the existing scrolling strip; later tabs require horizontal scrolling. No player setting was added.

## PNG comparisons

All game captures are native 1280×720. Pair sheets preserve original pixels, before on the left and after on the right.

| Route | Before | After |
| --- | --- | --- |
| Settled tree / tutorial | [before-tree.png](before-tree.png) | [after-tree.png](after-tree.png) |
| Chapter 4, chapter task list | [before-chapter4.png](before-chapter4.png) | [after-chapter4.png](after-chapter4.png) |
| Chapter 8, chapter task list | [before-chapter8.png](before-chapter8.png) | [after-chapter8.png](after-chapter8.png) |
| Search `cache`, first result selected | [search-pair.png](search-pair.png) | same sheet |
| Overview after clearing search | [overview-pair.png](overview-pair.png) | same sheet |
| English: tutorial, chapter 4, chapter 8 | [english-pairs.png](english-pairs.png) | same sheet |

[emblems.png](emblems.png) shows all eleven symbols/accents, plus explicitly synthetic state-style fixtures. These four fixture booleans demonstrate rendering only; they are not earned player achievements or simulated results.

## Verification

Engine: `4.7.1.stable.official.a13da4feb`, Windows, OpenGL compatibility renderer. Every Godot process uses isolated APPDATA and LOCALAPPDATA under this worktree's ignored `.godot` directory. The requested sibling temp directory is outside this session's writable root, so `.godot/a4-temp` is used instead.

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_task_tree --suite test_task_tree_layout --suite test_task_tree_presentation --suite test_task_tree_completed_detail --suite test_tree_journey_presentation --suite test_tree_relation_focus --suite test_direct_task_navigation --suite test_unified_journey_navigation
```

8 suites PASS / 0 FAIL, plus import and user-directory checks PASS. Details: [suite-results.json](suite-results.json), [suite-results.txt](suite-results.txt). Reported counts include completed-detail 369, journey presentation 3314, relations 243, direct navigation 28 and unified navigation 26; other suites print a PASS summary without assertion counts.

After adding badge width reservation and a bilingual full-tab-text fit assertion:

```powershell
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_task_tree_presentation --suite test_tree_relation_focus
```

2 suites PASS / 0 FAIL, import and user-directory checks PASS: [label-results.json](label-results.json), [label-results.txt](label-results.txt). No prior layout assertions were removed or weakened.

Rendered idle measurement: **before 0 / 240 frames; after 0 / 240 frames**, counting the canvas `draw` signal after settling. No processing loop or animation was added.

To replay the after captures, copy [capture.gd.txt](capture.gd.txt) into `.godot/a4-temp/capture.gd`, create the output directory, and run from the worktree root:

```powershell
$env:APPDATA="$pwd\.godot\a4-temp\review-runtime"
$env:LOCALAPPDATA=$env:APPDATA
$env:A4_PHASE='round2'
& 'E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --path "$pwd" --script "$pwd\.godot\a4-temp\capture.gd" -- --capture-size=1280x720 --test-mode
```

The replay instantiates the actual tree scene and invokes the same chapter/search/overview callbacks; it does not prove native mouse interaction. `--resolution` alone is overridden by window restoration, so the deterministic capture-size argument is required. Baselines use the same route script with HEAD versions of the three presentation files; the sheet is after-only.

## Limits and proposals

- Screenshots are Test mode with fresh isolated data. Completed and locked styles are explicitly synthetic on the emblem sheet; gate correctness and completed-path geometry are covered by the relevant suites.
- Not run: full verifier, complete 60-task playthrough, colour-vision user testing, or live saved-player acceptance. Windows emits a root-certificate-store warning even on successful baseline runs; suite results remain PASS.
- Global text scaling and existing small header/list secondary text remain a shared style decision. No shared style files were edited.
- No proposals requiring gameplay/simulation impact analysis. Layout, navigation, save, unlocking, task ordering, metrics and 0/1 artwork are unchanged.
