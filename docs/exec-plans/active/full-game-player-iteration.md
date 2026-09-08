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
| LOAD/STORE | Pending | |
| Chapter 1: first system | Pending | |
| Chapter 1: faster CPU | Pending | |
| Chapter 1: RAM wait | Pending | |
| Chapter 1: bus width | Pending | |
| Chapter 1: bottleneck investigation | Pending | |
| Chapter 2: repeated distant reads | Pending | |
| Chapter 2: cache placement | Pending | |
| Chapter 2: replacement | Pending | |
| Chapter 2: access order | Pending | |
| Chapter 2: second pass | Pending | |
| Chapter 2: work grouping | Pending | |
| Chapter 2: capstone | Pending | |

## Issues and decisions

Observed bench clipping in Tutorial/Half Adder/ALU is being repaired by putting inputs before optional explanations and retaining explicit width badges. Native first-pass completions above are e2218ff; the source fix is not yet the running game. Historical restart-signature instability
is documented in `docs/status/mac-native-polish.md`; reproduce with isolated data
and preserve the approval boundary. Earlier records remain historical evidence.

## Completion

In progress. This plan closes only after the original full-game attempt and the
authorized fixes/rechecks are actually complete, or its precise blocking boundary
has been explained. No release acceptance is implied by test counts.

2026-09-08 restart recheck: copied only this native pass data into a separate user directory; Continue rejected HalfAdder and its dependent arithmetic/CPU completions, while storage completion survived. Original native process remains open. Compatibility approval requested; no migration performed. Recheck copy confirms Tutorial input and result are visible without scrolling after the bench fix.

First fix batch: Tutorial/RAM controls, fixed debug and formal actions, separate compact Mission space, concrete goals, CPU stage first, SR conflict feedback and rejected reverse-port drops. Native rechecks include palette Register4 placement, wrong/correct reverse bus, undo/redo, Tutorial input, RAM final layout and SR conflict text. Final run 20260908T045330Z-d24b1378 passes all 20 suites and Chinese Game replay; runtime/test hashes match. An earlier concurrent GUI run timed out at CPU H3; a subsequent independent complete run passes. Cause of the timeout is not proven. Native whole-game pass continues in the original e2218ff process.
