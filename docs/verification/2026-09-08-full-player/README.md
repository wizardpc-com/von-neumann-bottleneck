# Full Game native player pass — 2026-09-08

This is a continuing player-led pass, not release acceptance. The active ledger
is [full-game-player-iteration](../../exec-plans/active/full-game-player-iteration.md).

## Native routes and version boundaries

- Ordinary Game, Godot 4.7.1 stable, native Mac/Retina, Chinese.
- Primary pass starts from e2218ff and a new unique player directory. All work
  through CPU was performed by native clicks and drags; no reference-loader,
  developer Test mode, artificial completion flags or GUI replay prerequisites.
- Tutorial 5/5; Half Adder 4 cases; Full Adder 8 cases; ALU 32 cases; SR Latch,
  Register and RAM 5 steps each; CPU 7 steps. All earned modules were sealed via
  the visible completion action. LOAD/STORE and later chapters remain in progress.
- The recheck app uses the source from verification 20260908T042507Z-9d9acc53,
  followed by the final bench layout copied from current source. Its progress
  is a copy of only this pass's native-earned data. It is not the real player
  directory. The original native process remains running.

## Observed issues and fixes

1. Tutorial/Half Adder inputs hidden behind heading and help content: input-first
   layout, optional explanations after controls, smaller duplicate headings.
2. ALU's OP1 and debug control below the fold: inline name/width identity and
   fixed debug/formal actions; width colors and four-bit cells remain explicit.
3. A tall bench overlapped compact Mission: reserve separate vertical space;
   compact Mission is shorter, with the concrete objective always on the strip.
   Native RAM recheck shows ADDR, DATA, WRITE and both Run actions together.
4. RAM reverse drop from a four-bit input onto WRITE made a dangling junction:
   recognize visible ports before treating the release as blank canvas. Native
   recheck rejects mismatched widths, connects a compatible reverse cable, and
   supports Command undo/redo. Palette dragging places one selected Register4.
5. S=R=1 debug silently displayed NQ=Q=0: add a local conflict explanation and
   recovery guidance; deterministic simulation and accepted official inputs are
   unchanged. Native recheck shows the amber explanation.
6. Later objective strips showed only level names: added six concrete bilingual
   objectives. CPU's current interface stage precedes its longer instruction table.

The RAM decimal/hex readout inconsistency remains recorded for the next UI pass.
A new process rejects valid HalfAdder-derived saved modules and locks dependent
arithmetic/CPU progress. Storage progress survives this particular restart.
`restart-copy-hashes.json` records the native test data copied before opening the
new process. No save migration, relaxed provenance, or synthetic unlock was used.
The compatibility proposal is awaiting explicit approval.

## Evidence interpretation

- `ram-incompatible-drop-before.png`: e2218ff creates the unwanted bus endpoint.
- `ram-incompatible-drop-after.png`: native revised app reports the actual width
  mismatch and leaves the canvas unchanged.
- `ram-bench-overlap.png`: intermediate layout, not an accepted final screenshot.
- `ram-bench-after.png`: final native arrangement with inputs and actions visible.
- `latch-conflict-after.png`: native revised conflict explanation.
- `restart-map.png`: lost arithmetic progress in the independent restart copy.
- Other named screenshots record the native level/encapsulation observation;
  they are not images of a test-only or reference-loaded solution.

## Comparison reference

The [Turing Complete developer announcements](https://steamcommunity.com/app/1444480/announcements/)
were reviewed on 2026-09-08. Their component-shape consistency, readable pins,
visible memory address activity and in-game hints are useful presentation
references. The [official game description](https://store.steampowered.com/app/1444480/Turing_Complete?l=english)
emphasizes building from simple logic to a working computer. Our inference from
this native pass is that owned-module reuse already delivers that reward well;
the immediate work is removing control-discovery and feedback friction. No engine
rewrite, campaign replacement or change to this game's original 21-level route
is implied by the comparison.
