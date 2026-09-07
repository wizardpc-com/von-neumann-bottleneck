# Visual signal notation

2026-09-07; base 389a4ef. User requests less text inside input components and a
clear visual explanation of values and bit widths.

## Scope and invariants

- Move terminal names outside the symbol body; decimal value first, one visible
  cell per bit, explicit localized width badge and stable width colors.
- Reuse the notation in the Test Bench and an early Mission explanation. Preserve
  named signal identities and readable port widths; color is never the only cue.
- Keep existing input controls, official tests, simulation, saved circuits,
  progression, independent hints and canonical signatures unchanged.
- No pending majority-vote level or save compatibility migration in this work.

## Implementation and acceptance

1. Add a small shared presentation helper; revise procedural terminals and module
   width labels without replacing the circuit renderer.
2. Explain bit cells, decimal/binary equivalence, ranges and width matching before
   editing; retain the explanation in the Handbook and Test Bench.
3. Verify known/zero/unknown values, both languages, input editing and unchanged
   topology, with fresh Godot 4.7.1 isolation and ordinary Game replay.
4. Inspect native Tutorial and mixed-width RAM/CPU presentation, including zoom,
   Retina, input focus and wiring. Record automatic setup separately from native
   interaction. Commit the verified increment.

## Progress

- Current screenshot reproduces name/value crowding and missing explicit terminal
  width. Existing renderer only receives formatted hexadecimal text for words.
- Chosen width palette: amber 1 bit, violet 2 bits, blue 4 bits. Signal states and
  player wire colors remain separate; explicit counts and lit cells carry meaning.

## Limits and open questions

Native first-time human and Windows acceptance remain separate. Previously
reported restart-signature compatibility still awaits user approval.

### Implementation and findings

- Shared notation now drives terminal width badges, module port text, Mission
  examples, Test Bench bit rows and Handbook illustrations. Decimal 4 pairs with
  0100; 12 pairs with 1100; unknown cells never imply known zero.
- A taller terminal trial exposed ALU edge-panning and a too-short Register wire
  gesture. Kept the original 138×72 terminal / 58-pixel slot geometry, moved names
  above the body and added initial view clearance instead of moving saved parts.
- Chinese full ordinary Game replay passed 581 checks after that repair. English
  repeated the complete route with all 20 suites passing.
- Native Tutorial: two hand-drawn wires, input toggle, debug Run, Command-Z and
  Command-Shift-Z. Native RAM: 4/12/0 integer entry, bit-row synchronization,
  text focus, 150% Focus and width/range Inspector; CPU Mission and instruction
  table inspected. These are not a new manual complete CPU construction.
- Native RAM found the storage explanation hiding inputs at the default height.
  Moved inputs/debug Run before the report and increased the initial prologue
  bench height. All three inputs are now visible immediately; at window size
  the debug Run remains accessible with a short scroll.
- Native RAM wired DATA→Register4, WRITE→LOAD and Q→OUT. Debug wrote 4; after
  WRITE=0 and DATA=12, the output and stored Q stayed 4. This is a deliberately
  partial debug circuit, not a claimed official RAM solution.
- The earlier two-option single-bit control could resemble two data cells. Final
  drawing uses one 0/1 cell plus toggle arrows; existing CheckButton behavior and
  hit area are retained. Final exact-source native Tutorial recheck passed: two
  hand-drawn wires, 1→0 and 0→1 inversion, with the new single-cell toggle.

## Completion — 2026-09-08

Final Godot 4.7.1 import, actual user-directory probe, all 20 isolated suites and
English ordinary Game replay (581 checks, zero failures) pass in
`.godot/verification/20260907T155626Z-272f42d3/`. Current runtime and test sources
match that snapshot byte for byte. Native Tutorial was rechecked on that exact
source. Chinese 581-check preparation and native RAM/CPU checks are scoped to their
actual candidates in the [evidence summary](../../verification/2026-09-07-visual-signals/summary.json).
Final diff reviewed; no gameplay or persistence migration included.
