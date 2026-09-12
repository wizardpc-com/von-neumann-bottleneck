# Spatial UI / live iteration — 2026-09-13

Baseline c0a05fa; ongoing goal covers entry, all five regions and related level
experience. This is the first stage, not a whole-game or release acceptance.

## Implemented presentation

Static, input-transparent ambient backdrop and drafting plane; raised chapter
surfaces and layered versions of the existing chapter emblems; stronger title/action
hierarchy with quieter borders. Task tree region trays follow the real dependency
layout; readable screen-space labels and existing selection remain unchanged.
All surfaces retain the existing font, five chapter colors and procedural renderer.
No continuously animated decoration, imported raster asset or new dependency.

First rendered review found emblems' leads escaping narrow cards. The artwork now
scales to available width independently of text. Initial layout checks passed,
but this visual issue was found by inspection, demonstrating their coverage limit.

## Native feedback and level issue

Computer use entered ordinary Game with a fresh dedicated QA directory, opened
the tree, entered Tutorial, started construction, opened H1 and expanded Mission.
This exposed an actual bug: H1 inherited compact Mission, and expanding it replaced
the hint text with ordinary task briefing and a Start Building button.
Fix: explicit Hint entry expands its explanation; folding/unfolding never invokes
the player briefing. Hint canvas remains read-only, H2/H3 still independently
confirmed and returning restores the same player design. Replay assertions added.

The task-tree drag diagnostic (`native-input-diagnostic.txt`, QA-only instrumentation)
records button down, then a motion event with button_mask=0 and relative=(0,0), then
release elsewhere. The existing safety handler cancels that gesture. Do not weaken
focus-loss protection to accommodate this tool event sequence. This does not prove
physical mouse dragging broken or native panning accepted. Two clicks on Tutorial
ports did not build a wire (the editor uses dragging); native completion is not
claimed. Ordinary Game input replay covers wiring separately.

## Verification and remaining goal

Visual-stage isolated run 20260912T161725Z-be91c39c: all conventional suites pass,
ordinary Tutorial Game replay 208 checks/0 failures. This predates the Hint fix.
Final Hint regression/native result and final captures follow below.

Still required by the active plan: construction/CPU and Chapters 1–4 player sessions,
related demonstrated content/layout fixes, bilingual and minimum-size follow-up,
final package checks. Windows, mixed DPI, external readers and native drag remain
distinct pending evidence. Previous frozen candidate remains historical to this
source iteration until a new candidate is deliberately built.

### Final Hint fix verification

Run 20260912T162339Z-84d33daf: all conventional suites passed; Chinese ordinary
Tutorial Game replay passed 212 checks with zero failures, including new Hint
fold/unfold assertions. Final bilingual typography rendering passed at both sizes
and eight zoom scales. Included images are final Godot test renders.

Native final follow-up: Continue located Tutorial; entered the existing QA design,
started building, opened H1. The explanation and next/return actions were directly
visible. Fold then unfold restored that same explanation without Mission briefing.
Requesting H2 opened the separate spoiler confirmation; cancel stayed in H1.
Returning restored the original unconnected player circuit, without completing it.
No native wire-drag completion is claimed.

English follow-up on the final isolated source: ordinary Tutorial replay 212/0;
full assertion list in `en-ui-observations.json`. `en-tutorial-hint-1.png` visibly
shows the expanded English explanation and actions. Final bilingual hub/map
captures retain the corrected narrow-card artwork. The nonfatal macOS IMK message
is present in replay output; no script/test failure was reported.
