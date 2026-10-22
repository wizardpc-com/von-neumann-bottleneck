# Late cloud desktop smoke check

Observed 2026-10-22 01:15–01:18 UTC, after the cloud desktop became available.
This adds limited graphical/manual-input evidence; it does not replace Windows
native testing, full-game acceptance or measured performance.

- Matching Linux Godot 4.7.1 opened the previously verified Windows candidate's
  embedded PCK, using OpenGL compatibility rendering and separate QA user dirs.
- Actual window was 1364×1024. Laboratory room, floating globe, terminal and
  tabletop objects rendered. Enter opened the full-screen terminal.
- Native clicks opened the journey map. Overview contained all eleven chapter
  regions. Task details and their primary entry action were visible.
- Entered the first wiring lesson. Replaying the demonstration visibly showed
  the illustrative cursor, dashed route and stop control at the actual ports.
- Real mouse drags connected A→NOT→LAMP and advanced the five-step coach.
  Input toggle and F6 advanced to removal; right-clicking a wire removed it;
  reconnecting completed the lesson in the isolated QA profile.
- The completion overlay's first return click finished its typewriter text;
  a second click returned to the terminal. It showed 1/60 and Continue HalfAdder.

No gameplay logic, production code or release package changed during this check.
No user save was used, and no completion was fabricated in the user's profile.
Later levels, Windows input/rendering, sustained FPS, accessibility and new-player
comprehension remain outside this small smoke check. Do not call it full graphical
acceptance or a complete end-to-end playthrough.

## Extended ordinary-profile play, 09:40–09:46 Beijing

The owner extended work to about 11:00 Beijing. On the same isolated ordinary
QA profile, native mouse input connected the complete HalfAdder circuit from its
unwired initial parts. F6 produced SUM=0/CARRY=0; all four official cases passed.
The explicit seal action persisted HalfAdder and exposed the next challenge.
The FullAdder board visibly reused the player's layout-derived HalfAdder outline
both on canvas and in the palette. Native mouse input connected two HalfAdders
and an OR gate; all eight official input cases passed, and the explicit seal
saved FullAdder. The map and terminal showed 3/60 after returning. Normal Quit
completed and the native window disappeared. No seeded completion was injected.

Two reproducible usability defects were identified in this packed candidate:

1. Closing Components or Test Bench, then selecting Show gesture, did nothing.
2. FullAdder F6 ran the actual circuit but left the coach at Try it. The shortcut
   called the lower-level prologue runner rather than the common button route.

These observations motivate subsequent source fixes and separate retesting.
The previously exported executable still has these defects until rebuilt.

## Source repair retest, 09:52–09:54 Beijing

A new isolated imported source copy included the targeted fixes and reused only
a copy of the two QA save/workbench JSON files from the earned 3/60 playthrough.
The terminal restored 3/60 and the player's reusable components after restart.
On the available, uncompleted SR Latch board, real drags connected the two NOR
feedback paths and both outputs. Pressing F6 now visibly advanced the coach to
step 3/3 (Official test), with actual NQ=1/Q=0 for S=0/R=1. Closing Components or
Test Bench then selecting Show gesture displayed the correct named bottom-button
recovery instruction and did not forcibly reopen the panel or modify the circuit.
The revised build instruction correctly acknowledges the existing canvas parts.

Runtime log identifies Mesa llvmpipe software rendering. Audio output fell back
to the dummy driver, so sound quality is not tested. These facts must accompany
any later performance report; no hardware-accelerated or audible-play claim.

The same native session subsequently passed the SR Latch and Register1 official
state sequences (reset/set/hold and write/hold). Both circuits were built through
real mouse drags using the earned SRLatch module for Register1. Sealing is an
explicit action, not the visual animation itself granting completion. This adds
arithmetic and storage-branch coverage, not all fourteen prologue lessons.
