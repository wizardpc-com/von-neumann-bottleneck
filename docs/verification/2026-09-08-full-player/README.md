# Full Game native player pass — 2026-09-08

This is a continuing player-led pass, not release acceptance. The active ledger
is [full-game-player-iteration](../../exec-plans/active/full-game-player-iteration.md).

## Native routes and version boundaries

- Ordinary Game, Godot 4.7.1 stable, native Mac/Retina, Chinese.
- Primary pass starts from e2218ff and a new unique player directory. All 21 levels were played by native clicks and drags; no reference-loader,
  developer Test mode, artificial completion flags or GUI replay prerequisites.
- Tutorial 5/5; Half Adder 4 cases; Full Adder 8 cases; ALU 32 cases; SR Latch,
  Register and RAM 5 steps each; CPU 7 steps. All earned modules were sealed via
  the visible completion action. LOAD/STORE and both later chapters were subsequently completed in this same native process; see the coverage boundary below.
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

## Continued campaign pass and limits

LOAD/STORE and Chapter 1 all completed with native screen evidence. Chapter 2
completed through ordinary Game, including 2-line cache failure and two successful
capstone solutions (4-line cache/cost 13; row-first + 1-line blocking/cost 4), both
138 cycles from the original 642-cycle baseline. All prerequisites came from this
pass. Full metrics and mistakes are in the active ledger.

During 2-3, the native screen connection stopped returning current frames and
reported `cgWindowNotFound` / `noWindowsAvailable`. The Godot process remained
alive without new runtime errors. Native AX buttons and scrollbar values continued
to work. A fullscreen/windowed transition restored current native frames; the
underlying cause is unproven. Supplemental visual replay then covered 2-4 through
2-7. The original completion actions during the screen outage remain AX evidence;
the supplemental screenshots separately establish the later visual observations.

- `ch1-cpu-native.png`: 316 → 268 comparison.
- `ch2-map-overflow-before.png`: status outside the original short cards.
- `ch2-all-complete-native.png`: all seven Chapter 2 nodes complete.
- `ch2-access-order-native.png`: manually edited/applied row-first result, 105 cycles;
  editor Command undo/redo was checked before Apply.
- `ch2-working-set-native.png`: 210 cycles and the misleading amber correct result.
- `ch2-blocking-native.png`: native grouping choice, 138 cycles, cost 4.
- `ch2-capstone-native.png`: native row-first/blocking replay, 138 cycles, cost 4.
- `native-player-session.json`: local export from this fresh player session after
  all 21 native completions. It contains no real player's prior progress.

The second fix batch makes map cards taller, names Chapter 1 missing routes and
entry/exit direction, pins Chapter 2 Run above scrolling debug inputs, labels
actual/expected values, corrects nearby-fill terminology, neutralizes prediction
feedback and fixes completed-progress counts and observation success colors.
It preserves the entire raw program template because its text participates in
saved receipt signatures. No authored targets, cases, simulation, prerequisite,
judgment rule or saved format changed.

The save compatibility approval request remains unanswered; no migration made.
A second isolated copy of the native-complete data also loses chapter access on
restart (`second-recheck-save-copy-hashes.json`). Latest-source Test-mode UI
rechecks are separate from the ordinary Game full-player evidence above.


## Final second-batch verification

Final source: `20260908T063439Z-770259c1`, all 20 suites pass; ordinary Chinese
Game GUI replay 593 checks / 0 failures. `second-fix-verification.json` records
checks and byte-matching runtime/test hashes. The final native recheck runtime
also matches these source/translation files. An earlier unprivileged import
could not create the isolated user directory and was rerun with the required
filesystem access; it is not recorded as a product failure or passing check.

Separate native Test-mode presentation rechecks on this Mac:

- `ch2-map-after-test-recheck.png`: long titles and status contained in cards.
- `ch1-missing-routes-after-test-recheck.png`: all six missing typed routes named.
- `ch1-routes-passed-test-recheck.png`: six hand-dragged routes, two official cases
  pass, each 22 cycles. Arrow/label controls do not obstruct port dragging.
- `ch2-capstone-bench-after-test-recheck.png`: no preliminary scroll; Run visible,
  actual 88 / expected 88 and time 642 fully visible; over-target result amber.
- `ch2-observation-color-after-test-recheck.png`: correct target-free 210-cycle
  observation uses green. Neither speed target nor completion rule changed.
- `ch2-reopen-progress-after-test-recheck.png`: run → judgment → review → map →
  reopen, now correctly displays completed 2/2 without selecting again.

Option+Return was exercised for fullscreen/window restoration. Primary Game's
2-4 editor Command undo/redo and first-batch palette/reverse-wire undo/redo are
separate native checks; these do not establish every focus or Retina setup.
The CUA accessibility tree sometimes remained window-only; screenshot-coordinate
clicks/drags provided the final visible rechecks. No Windows run or human beginner
study was performed in this iteration. Restart provenance remains a release
blocker awaiting the user's data-compatibility decision.
