> **HISTORICAL / SUPERSEDED as an active queue.** Implementation history only.
> Current scope and remaining acceptance: [CURRENT_STATE](../../CURRENT_STATE.md) and [release blockers](../../../RELEASE_BLOCKERS.md).
> Older task counts and candidate identities below describe their dated iteration.

# Full original Game player pass and iteration

2026-09-08; start e2218ff. The user asks for a player-led attempt of the entire
game, recording and repairing observed problems through continued iteration.

## Scope and boundaries

Play the original 9 + 5 + 7 route through ordinary Game on Mac with Godot 4.7.1.
Use native computer-use actions for this pass; automated replay and unit fixtures
remain separate verification and cannot stand in for these native completions.
Read the visible Mission/Handbook/Hint as a player would. This is an informed AI
player pass, not a claim of first-time human beginner research.

Fix reversible UI, editing, clarity and feedback defects after reproducing them.
Keep deterministic simulation, official tests, original progression, free building,
independent H1/H2/H3 and save authority. Material gameplay, architecture or data
changes need a concrete proposal and user approval. Earlier optional-level and
save-compatibility proposals are not silently authorized by this plan.

Actual player data and existing editor/game windows remain untouched. Use unique
test player directories and keep every run identifiable. Do not push; commit each
substantial verified increment as the user requested.

## Loop

1. Verify the current source in isolation and start a fresh ordinary Game.
2. Play each original level, including editing mistakes and recovery, specification
   lookup, execution, completion, next-step clarity and meaningful experiments.
3. Record the native action/result, screenshot, source version and issue severity.
   Fix a coherent batch; run appropriate fresh checks and native rechecks.
4. Continue through all chapters. Record restart/Continue separately; do not bypass
   provenance or grant progress if the known restart issue occurs.
5. Final report distinguishes repaired defects, native completion coverage,
   automated checks, unresolved design decisions and unperformed human/Windows QA.

## Native coverage ledger

| Level | Current pass | Evidence / finding |
|---|---|---|
| Tutorial | Native complete | 5/5; A=0/1; right erase, Command undo/redo, reconnect. First input clipped by bench header/help at default window. |
| Half Adder | Native complete + sealed | 12 hand-dragged wires; all 4 official cases passed. Same input discoverability defect. |
| Full Adder | Native complete + sealed | 8 hand-dragged wires using owned HalfAdders; debug 111 gives SUM=COUT=1; 8 official cases passed. |
| ALU | Native complete + sealed | 16 hand-dragged wires; debug AND/OR/ADD/NOT at A1 B0; all 32 formal cases passed at player-selected 20 Hz. OP1/debug below fold. |
| SR Latch | Native complete + sealed | 6 manual wires; reset → set → hold; S=R=1 exposes NQ=Q=0 without contextual explanation; recover reset/hold; all 5 formal steps pass. |
| Register | Native complete + sealed | 8 manual wires; write D1 then LOAD0/D0 retains Q1; all 5 formal steps pass. |
| RAM | Native complete + sealed | 10 manual wires; write M0=3/M1=12 then read both; all 5 formal steps pass. Reverse 4-bit input to WRITE incorrectly created junction; undo recovered. |
| CPU | Native complete + sealed | 19 manual wires; stage auto-advancement; Shift+Home 75%; LOAD_IMM debug; all 7 program steps passed. Compact Mission hides current stage below opcode table. |
| LOAD/STORE | Native complete | 7 official program steps; ACC=7, M0=3 remain distinct. Entered Chapter 1 via owned CPU/RAM handoff. |
| Chapter 1: first system | Native complete | 6 hand-dragged routes after correcting two read-back segments; 2 official cases, 22 cycles each. Port direction and generic missing-route feedback caused avoidable confusion. |
| Chapter 1: faster CPU | Native complete | Predicted small improvement; Eco → Fast 316 → 268, WAIT unchanged at 252. Completion incorrectly calls the correct prediction a surprise. |
| Chapter 1: RAM wait | Native complete | Slow → Fast RAM 268 → 124, WAIT 252 → 108; inspected profiler. Floating evidence windows overlap. |
| Chapter 1: bus width | Native complete | Bus2 → Bus8 144 → 96, transfer 64 → 16; same correct output. A persistent bit-group diagram would explain serialization better. |
| Chapter 1: bottleneck investigation | Native complete | 4/16/64 cases: 112/448/1792; raw WAIT 88/352/1408. Chose RAM; revealed split CPU 504/RAM 1344/Bus 504 confirms 57% RAM. |
| Chapter 2: repeated distant reads | Native complete | 257 cycles, WAIT 240; paused and stepped RAM addresses. Wrong arithmetic explanation rejected, but refers to unavailable Profiler. Correct explanation reviewed. |
| Chapter 2: cache placement | Native complete | Inherited own baseline; installed 1-line storage; 105 cycles, 12 nearby returns/4 fills. Stepped direct nearby return of -2. Ambiguous 88 / 88 and far-fetch 0 → 4 labels. |
| Chapter 2: replacement | Native complete; visual evidence through eviction | 321 cycles, 16 misses, 256 B; stepped miss line 1, RAM fetch, eviction of line 0. Correct explanation reviewed. Screen became stale during this level; process and AX actions remained active. |
| Chapter 2: access order | Native complete + supplemental visual replay | Used visible strategy buttons, reviewed row/col draft, applied, official 105 cycles vs inherited 321. Later replay also verified editing, Command undo/redo, Apply and the 105-cycle result on screen. |
| Chapter 2: second pass | Native complete + supplemental visual replay | 210 cycles, WAIT 176, 8 misses, 128 B; correct four-lines-versus-one capacity explanation reviewed. |
| Chapter 2: work grouping | Native complete + supplemental visual replay | Selected 1-line group using Game button; 138 cycles, WAIT 104, 4 misses, 64 B, cost 4. Only one new legal choice limits discovery. |
| Chapter 2: capstone | Native complete + supplemental visual replay | Scrolled native test bench to reveal Run; baseline 642, diagnosis; 2-line 642/cost 7; 4-line 138/cost 13; 1-line + row + blocking 138/cost 4. Final summary records best. Completed chapter/feedback flow using native buttons. |

## Issues and decisions

Observed bench clipping in Tutorial/Half Adder/ALU was repaired in b155421 by putting inputs before optional explanations and retaining explicit width badges. Native first-pass completions above remain e2218ff; fixes have their own recheck evidence. Historical restart-signature instability
is documented in `docs/status/mac-native-polish.md`; reproduce with isolated data
and preserve the approval boundary. Earlier records remain historical evidence.

## Completion

The full original player pass and two authorized repair/recheck batches are complete.
The plan remains active for future player iterations. The separately approved save
compatibility repair is complete; see the 2026-09-09 update below. Neither test counts nor this informed AI pass are
release acceptance.

2026-09-08 restart recheck: copied only this native pass data into a separate user directory; Continue rejected HalfAdder and its dependent arithmetic/CPU completions, while storage completion survived. Original native process remains open. Compatibility approval requested; no migration performed. Recheck copy confirms Tutorial input and result are visible without scrolling after the bench fix.

First fix batch: Tutorial/RAM controls, fixed debug and formal actions, separate compact Mission space, concrete goals, CPU stage first, SR conflict feedback and rejected reverse-port drops. Native rechecks include palette Register4 placement, wrong/correct reverse bus, undo/redo, Tutorial input, RAM final layout and SR conflict text. Final run 20260908T045330Z-d24b1378 passes all 20 suites and Chinese Game replay; runtime/test hashes match. An earlier concurrent GUI run timed out at CPU H3; a subsequent independent complete run passes. Cause of the timeout is not proven. Native whole-game pass continues in the original e2218ff process.

Second fix batch: taller map cards retain status under long titles; Chapter 1 ports show entry/exit arrows and explicit read-back names; failed runs name missing routes in the bench; Chapter 2 Run stays above scrolling debug inputs; results identify actual/expected values; nearby-fill language no longer calls bypass cache-miss zero a remote-read count; neutral prediction/navigation/ending copy. No simulation, authored objective, target, prerequisite or persistent format changes. The raw row-first template, including its developer-facing comment, stays byte-identical because saved receipts hash the whole text. Its cleanup remains behind the save-compatibility decision.

All 21 original levels were completed through the same fresh Game process. During
2-3, CG stopped supplying current screenshots while native AX actions continued.
Switching the known QA window between fullscreen and windowed restored current
images; the cause is unproven. Supplemental visual replays of 2-4, 2-5, 2-6 and
2-7 now show the expected 105, 210, 138 and 138 cycles. These are screenshots of
the original e2218ff process, not acceptance of the second fix batch. Editing and
Command undo/redo were checked in 2-4; 2-7's original hidden Run was revealed by
native scrolling. No further screen-restoration action is needed from the user.

Supplemental replay also found completed observations reopening as 1/2 (capstone
2/3) and correct target-free observations using warning color. Both are now
presentation-only fixes; completion receipts, judgments and targets are unchanged.
A second restart of a copy of the fully completed native player data again locked
later chapters. No migration or artificial Game unlock was applied. Latest-source
native presentation rechecks use the separate, visibly labeled Test mode; they
are not counted as ordinary Game completion evidence.

Final second-batch evidence: 20260908T063439Z-770259c1, all 20 suites plus Chinese
Game replay 593/0, source hashes verified. Native Test-mode rechecks confirm map
containment, six manual routes and 2/2 official cases, pinned Run and complete
actual/expected/time fields, amber over-target output, green target-free output,
and completed observation reopen at 2/2. Final result font/layout was adjusted
once more after native observation found the time line clipped; then checks and
native observation were repeated. Fullscreen transitions restored stale CUA
frames, but do not prove the underlying window issue resolved. Windows and human
beginner acceptance remain unperformed. No actual player data was accessed.

2026-09-09 approved save repair completed: explicit textual circuit/seed ordering,
integral JSON identity normalization, content-addressed originals, unchanged
source/official verification and one-time preservation of legacy defaults.
The previous native full-player data recovers all 21 levels in ordinary Game;
Half Adder and CPU formal reruns pass, normal exit and another startup retain
identical Game progress and constructed workbenches. All 21 isolated suites,
593 Chinese Game input checks and three separate-process migration checks pass.
[Evidence](../../verification/2026-09-08-save-recovery/README.md).
This approval does not add optional levels or change raw DSL receipt signatures.
Further beginner difficulty/motivation and Windows acceptance remain open.

## Next UI increment, 2026-09-09: readable bus transfer groups

Native reopened `bus_width` on 98cde8b: the device draws four decorative lanes
regardless of selected 2/4/8-bit-per-cycle bandwidth. Mission states the numbers,
but the machine does not visually connect one 8-bit word to transfer groups.
Replace that decorative surface with eight bit cells grouped by current bandwidth,
a persistent width/cycle caption and trace-derived data/progress during playback.
Show only the current configuration, preserving prediction and baseline gating.
Group order is a presentation illustration, not a new simulated bit-order protocol.
Keep port geometry, free device movement, event durations, metrics, receipts and
saves unchanged. Check real Trace/part switching and then ordinary Game native
Bus2/Bus8 comparison, selection/movement, zoom and focus. This is a reversible
presentation change within the approved continuing-polish scope.

Reference reviewed: [Turing Complete's developer description](https://store.steampowered.com/app/1444480/Turing_Complete?l=english)
emphasizes discovery through puzzles and freedom to construct. Our inference is to
make a selected machine's behavior observable without changing the puzzle or
supplying a completed circuit. Its shared tri-state bus is not imported into this
chapter's separate deterministic bandwidth model.

Native zoom during paused Bus2 playback reproduced detached overlay strokes.
`SystemGraphEdit` already detects displayed geometry changes; notify its host to
redraw the stored displayed event/progress when paused, including after single
step (whose playback index already points to the next event). Clear that view
reference on stop/finish/new Trace. Add regression checks for automatic paused
zoom/pan/move updates and unchanged authoritative evidence.

The same paused write-data frame exposed a second pre-existing error: the overlay
selected the first route between each device pair, so write payload used request
ports and their color. Select the existing typed route by event kind for both
geometry and color. Regression checks use authoritative read/write/request events
and assert both segment origins against actual corresponding port transforms.

Native Bus2 → Bus8 switching also left the old green 144-cycle card visible,
while a later passing run retained the header's rerun warning. Clear current
result cards when hardware changes (History retains valid comparison receipts)
and refresh the header from the newly produced debug/official status. Verify both
boundaries without changing receipt or completion authority.

Native overlapping Parts/Test Bench windows reproduced an input-order defect:
Parts rendered in front, but the later Test Bench sibling intercepted its clicks.
All three hosts now move the focused panel to the last sibling as well as raising
its draw order. A viewport-dispatched click regression closes the foreground Parts
window while leaving the overlapping Test Bench open. This follows Godot's
[documented separation of z-index and input handling](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-property-z-index).

The final native switch check also exposed a stale bottom playback caption after
changing a part. The same rerun notice now replaces that old event caption; the
regression covers result cards, test status and playback status together.

Final increment verification: 20260909T030131Z-3ee57359, all 21 suites plus English
ordinary Game input replay 593/0; 105 runtime files match the native copy. Chinese
replay was 593/0 before the final playback-caption-only correction. Final native
Game repeats Bus2/Bus8, overlapping Parts selection, status clearing and typed
read/write observations; exit 0. Evidence and candidate/final distinctions are in
[the iteration record](../../verification/2026-09-09-bus-diagram/README.md).
