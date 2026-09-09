# Guided workbench and illustrated learning

Date: 2026-09-09. Source starts at main `2eaacd0`; Godot
`4.7.1.stable.official.a13da4feb`, Apple M2. This is a scoped UI/guidance iteration,
not a new release acceptance or a second full-campaign novice playthrough.

## Changes

- Hardware and Chapter 3 component tools open on every level entry. Chapter 1
  opens Parts; Chapter 2 opens its storage configuration when that tool is available.
  Fixed investigation machines retain their existing configuration workflow.
- Hardware cards have a separate schematic tile, readable purpose lines and all
  distinct port widths. Mixed control/data modules show both scalar and bus badges.
  Tutorial's NOT card appears first. Ordinary click, repeat placement and drag remain.
- Idle cables are more legible and crossing cables have a darker separation border.
  Round/thin one-bit cables and square/double-rail buses retain their existing
  geometry, hit testing, custom colors and simulation meaning.
- Hardware view fitting reserves space for both side panels after the briefing and
  on return from the independent Hint canvas. This fixes a CPU output socket hidden
  under the newly open toolbox. Fitting changes the camera, not saved node positions.
- The Mission briefing uses more of the available width and height: native English
  CPU text previously pushed Start Building below the scroll boundary; it is now
  directly visible alongside the width guide at the checked window size.
- The shared Handbook has 96 terms. Each of the 29 playable lessons recommends at
  most three; search/category/direct specification links keep the full available
  reference accessible. Future diagrams retain real progression requirements.
- Controllable examples show bit weights/ranges, gate input combinations, request
  versus arrival, buffer states, buffer alternation, queue occupancy and unused-data
  eviction. Arrow buttons change only illustrative state. Chapter 3 uses this same
  Handbook rather than its previous long separate text panel.
- Tutorial separates placement, repair/undo and navigation. Half Adder explicitly
  introduces branches versus crossings. Chapter 3 program help uses short command
  cards. See the [first-use inventory](../../design/first-use-guidance.md).

## Native Game observations

Computer Use operated the native Mac app using the normal chapter hub, maps and
player controls. The isolated `overlap-20260909` profile contains progress earned
in earlier native passes; no reference insertion or progress fixture was used here.

| Path | Observed result |
| --- | --- |
| Tutorial | Open toolbox on entry; separate repair page shows Mac Command keys. Dragged NOT onto the canvas, undid/redid/undid it, right-erased one wire, reconnected, ran the circuit and switched input. All five tutorial actions completed. |
| Half Adder | New branch page explains junction dots versus crossings. Four official cases passed on the existing player circuit, with palette still open. |
| CPU | Mixed 1/2/4-bit badges visible; after Start the complete circuit fits between panels. Seven-step official program passed on the existing player circuit. |
| Chapter 1 assembly | Parts and Mission both open on entry. They remain movable/closable floating tools; the user may collapse them or pan to inspect a larger machine. |
| Chapter 2 nearby storage | English windowed entry opens Mission and Nearby Storage, with the storage behavior explained above its choices. |
| Chapter 3 distance | Toolbox opens and program stays closed initially. Mission opens two recommended topics. Stepped the eviction example and all three command cards; the existing schedule still passes at 30 cycles, output 46/46. |
| Final English CPU | Start Building is visible without scrolling. H1 enters its separate canvas; return restores the whole circuit beside the toolbox. Erased a four-bit wire and reverse-dragged a replacement; a mistaken nearby source failed official cases, then the correctly targeted RAM output passed all seven. |
| Retina / window / focus | Used Option-Return to switch to a window on the Mac Retina display. English bit-width example shows four cells, value 5 and range 0–15; buffer examples show independent use/fill states. Search with Command+A and Escape returns to the unchanged Chapter 2 workspace. |

This table records native interaction, separately from the automated route below.
The fitted CPU overview is still dense; zooming in is useful for precise port work.

## Isolated verification

The main verifier imported a fresh project, proved its custom user directory and
passed all 19 conventional suites. After the final Hint-return adjustment, the
hardware UI, prologue UI and learning suites were run again. The latter passes 830
checks including recommended knowledge availability before each lesson and diagram
steps that do not mutate player content.

The full ordinary Game viewport-input route independently earns both construction
branches, CPU and LOAD/STORE. It covers placement/cancel/focus loss, branch/erase,
undo/redo, copy/paste/multi-selection, scalar/bus mismatch and reverse previews,
independent confirmed hints, named workbenches and fullscreen/window changes.
Chinese and English routes each pass 602 checks. Language results and exact source-file
hashes are retained in `verification.json`; logs distinguish final results from
intermediate diagnostics.

Reproduction:

```sh
python3 scripts/verify-project.py --godot "$GODOT" --gui --locale zh_CN
python3 scripts/verify-project.py --godot "$GODOT" --gui --locale en
```

The final local evidence root is
`.godot/verification/20260909T152028Z-cab54078/`. Initial failed expectations for
hidden tools and 20 first-lesson topics were updated to the new requested contract.
A later CPU failure identified the Hint-return camera path. A marquee fixture
needed a larger empty-canvas margin after fitting changed nearby geometry; its
selection/move/undo assertions remain. One standard-bundle run stalled while native
fullscreen play was active and was terminated; it is not a pass. Final GUI runs
use the same 4.7.1 binary through a separate QA application identifier, serially
without competing native play. macOS IMK informational output is not a script error.
The hardware unit fixture retains its pre-existing warning about reusing one input
event in a frame (line 274); that suite passes. Final layout reruns are identified
as `final3` in the receipt and retained logs.

## Acceptance boundaries

No simulation, success target, prerequisite graph, save format, component supply
or Hint disclosure rule changed. The eight-task runtime remains removed.
Windowed/native checks do not prove new-player comprehension or enjoyment. Optional
shortcuts still use contextual tips; the inventory is not proof every novice finds
them. This iteration has no new Windows executable/native acceptance and no release.
