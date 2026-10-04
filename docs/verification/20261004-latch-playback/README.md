# Latch playback follows the player's output interface

Baseline `480a0975f601cc3ff8735f6fab33e13778cb7566`, existing
`ray/representation-playloop-20261003` branch. Presentation-only correction;
simulation, circuit validity, official cases, reusable-component provenance,
five-region / 40-task progression and save schemas are unchanged.

## Native finding

Developer-informed Linux cloud play used Godot `4.7.1.stable.official.a13da4feb`
at 1364×1024. An isolated copy preserved the existing QA profile whose Tutorial,
Half Adder and Full Adder were earned through real mouse/keyboard input. This pass
constructed the ALU's 16 wires, passed all 32 official cases, explicitly sealed
ALU1 and followed Continue into SR Latch. The six-wire latch was constructed from
its visible parts without loading Hint or injecting a solution/completion.

After SET produced Q=1/NQ=0, running HOLD (S=R=0) showed Q=0/NQ=1 in the Test
Bench's retained-state readout during replay, then corrected itself at completion.
Pausing at 0.5 Hz reproduced the disagreement beside the correct actual result
and terminal values. The seed's historical `NOR_Q` ID actually drives NQ, while
`NOR_NQ` drives Q; the playback monitor had treated those IDs as output names.
Renamed gates also failed the authored-ID filter used for boundary updates.

## Correction

Latch prior observations are resolved from the actual Q/NQ observers' incoming
source ports. The existing digital-value resolver handles multiple drivers;
missing evidence remains unavailable, and Z/SHORT are preserved without inventing
complementary outputs. At the existing state boundary both observations are
published together from the authoritative case result. The immutable prior snapshot
is restored for replay/step only when the playback contains a real state boundary;
live-preview animation cannot resurrect a previous run's snapshot. Alarm and the
other storage-task paths retain their existing behavior.

## Automated verification

`test_latch_playback_readout` covers SET/HOLD/RESET/HOLD using the real simulator,
partial/completed boundary waves, final result, replay and step replay in both
locales. Synthetic topology fixtures include authored and renamed gates, a routed
output and a reusable latch's nonzero output port. Edge checks cover matching and
conflicting drivers, non-complementary values, missing data, Z, preview replay and
explicit reset. Result canonical signatures remain unchanged by presentation.
These controller fixtures are not native player-progression evidence.

The final 636-check regression fails on baseline runtime with 366 expected
readout assertions (exit 1), and passes on the corrected runtime (exit 0).
Full isolated run `20261004T205353Z-d4eacc1f` passes all 67 conventional suites,
plus import and user-directory isolation (69 stages). The only later test edit
renamed the single-in/single-out junction fixture from “branched” to “routed”;
the identical 636 checks were rerun successfully after that label correction.
Runtime SHA-256 matches the full-suite project and native QA project. All five
Python CI commands passed. Independent read-only review found no blocker and
`git diff --check` passes.

## Native recheck and limits

The copied profile reopened its saved six-wire circuit with the corrected runtime.
Chinese SET→HOLD at 0.5 Hz and pause preserved Q=1/NQ=0 through the complete stepped
sequence. RESET began with the real prior Q=1/NQ=0 and finished at Q=0/NQ=1;
restarting with Step restored its original prior state. English language reload
preserved the circuit, and the same paused HOLD retained the correct visible
values with readable text. All five native official latch cases passed, then the
player explicitly sealed SRLatch. Continue opened One-bit Register with that earned
component available. The owned QA window was closed normally and its absence
verified. No test fixture was injected into native play.

Screenshots were inspected in computer-use history, not persisted image artifacts.
The original source QA profile remains byte-identical; only the copied profile
was advanced. The initial direct shell GUI launch lacked access to the X11 display;
launching the same local script through the cloud desktop terminal succeeded.
Native logs retain the environment's unsupported V-Sync and ALSA→Dummy warnings,
with no game-script errors. This is developer-informed Linux source QA, not novice,
Windows/macOS, export, HiDPI or audio acceptance. No merge, release or deployment.
Remote publication and exact-SHA CI are verified separately in the handoff.
