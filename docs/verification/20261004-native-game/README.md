# Ordinary Game native play — 2026-10-04

Informed developer play on Ray's Linux cloud desktop with official Godot4.7.1,
using a fresh isolated ordinary-Game save. This is actual native mouse/keyboard
input, not a viewport replay, novice test or proof of enjoyment. Source runtime
is the isolated full-regression copy of0b1664b; later c2be283 changes only VPS docs.

## Observed path

- Entered the ordinary hub, prologue map and Wiring Tutorial. Inspected the opening
  guide and usable canvas with Parts, Test Bench and Mission present.
- Drew both NOT signal connections, toggled input, ran, right-click removed an
  actual wire, reconnected and earned all five tutorial steps through the UI.
- Continued to HalfAdder. Constructed NOT/AND/OR fanout wiring directly on the
  canvas; all four official cases passed. Packaged the performed design as the
  player's HalfAdder and observed the packaging animation and completion receipt.
- Continued to FullAdder, reused two earned HalfAdders plus OR, wired all eight
  connections and passed all eight official cases. Packaged FullAdder; returned
  to the map with Tutorial/HalfAdder/FullAdder completed and dependent tasks open.
- No reference load, Test-library substitution or progression setter was used.

- Closed through native Alt+F4 and relaunched. Continue Game returned to the
  task tree with the three completed tasks and dependent unlocks retained.
  Re-entering FullAdder restored all performed wiring and the earned HalfAdder
  components. Re-running all eight official inputs passed again after restart.

Native input/display did not require a code repair in this path. Actual wire
fanout and reverse-direction connection worked at75% viewport zoom. Completion
and packaging retain separate decisions; no automatic next-level skipping.

Remaining: whole prologue/storage/CPU, later regions, minimum-window/native
English, exported Windows/Mac and human
novice testing. ALSA had no output device and fell back to Dummy, so sound has
not been listened to or accepted. The main game remains offline by default.

## Storage branch continuation

Native construction then wired the two NOR gates into SRLatch, passing all five
RESET/HOLD/SET/HOLD/RESET steps and packaging the earned SRLatch. Reused that
component with NOT and two AND gates to build Register1; all five write/hold
sequence cases passed. Register1 packaging completed and unlocked Register4. Built the two-address
RAM with Decoder, two earned Register4s and a Word MUX through ten native wire
drags. All five write/read/non-overwrite sequence cases passed; RAM packaging
completed. The Continue action correctly selected the unfinished ALU branch
instead of trying to enter the still-locked CPU. Built ALU1 with the earned
FullAdder, AND/OR/NOT and Mux4 through16 native connections. All32 official
inputs passed; changing playback from2Hz to8Hz during the run did not prevent
completion. ALU packaging completed. CPU and later-region paths remain outside this recorded result.

## Branch-order continuation repair

Finishing storage before ALU exposed a native navigation defect: Continue after
ALU reopened the already-completed SRLatch. The fixed chooser keeps the normal
first-completion route, but if its destination is complete it selects an unlocked,
uncompleted core task, or returns to the map when none remains. It does not grant
completion or bypass prerequisites; optional tasks and chapter feedback retain
their existing handling.

A new regression covers arithmetic-first/storage-first order, replayed tasks,
CPU/bridge progression, all-complete and unknown cases. All60 verification stages
passed (import, isolated user directory and58 suites). Native re-run of the saved
ALU passed32 cases; Continue then packaged it and opened the unfinished CPU rather
than SRLatch. CPU execution is still pending.

## Completed-level replay UI

Completed tasks now reopen directly on the circuit with a compact, reopenable mission panel. First visits retain their full briefing. Deferred layout settlement preserves test-bench input space: an initial implementation collapsed the bench in native play despite passing headless checks, and was corrected before publication.

Native ALU replay verified the unobstructed circuit, visible A/B/CIN/OP inputs, optional experiment expansion, and manually reopened task rules. This is informed developer QA, not independent novice testing. Full isolated verifier: 60 stages passed (import, user directory and 58 suites), evidence run `20261003T180501Z-2530ffc6`. CPU and later native playthrough remain pending; audio output was not heard in this environment.

## Optional experiment discoverability

Native ALU play revealed that opening the optional experiment below five input rows left its first action outside the scroll viewport. The widget now reveals the first preset after expansion layout settles. It only scrolls its existing container; it does not select inputs, execute a circuit or award progress. Native replay confirmed the first presets become visible immediately and can be selected before separately running debug. Added a below-fold viewport regression; all 60 verifier stages passed again in the isolated run recorded for this change.

## CPU and bridge native completion

The same isolated save now has all nine core prologue tasks completed. CPU was wired through 19 native drag connections from its supplied components, using the earned ALU4/Register4/RAM2x4. All seven official program steps passed at 2 Hz; the verified topology was sealed as TinyComputer through the UI. The LOAD/STORE bridge reused that actual sealed component and passed its seven-step demonstration. Chapter feedback was skipped, without generating a subjective player rating. Closing/relaunching preserved completion and unlocked Chapter 1, whose native playthrough has begun but is not yet complete.

The bridge exposed another layout issue: its empty, irrelevant parts palette consumed the right side of an observation-only task. Default entry now leaves that panel closed for locked prologue topology; it remains recallable. Native replay showed the data-flow diagram at 100% rather than the previous 75% with no missing input/output controls. Focused tests and all 60 verification stages passed; this does not alter simulation, progression, wire topology or stored circuits.
