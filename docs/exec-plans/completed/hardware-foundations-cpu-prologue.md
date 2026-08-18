# Hardware Foundations CPU prologue execution plan

## Goal

Extend the validated wiring/Half Adder slice into one continuous, playable CPU-construction prologue. The player must grow their own abstraction library from gates to a tiny working computer, then run a LOAD/STORE program that exposes the separation between computation and memory.

The playable sequence is:

1. compact wiring tutorial (existing, retained);
2. Half Adder (existing, generalized into progression);
3. Full Adder built from the player's sealed `HalfAdder`;
4. one-bit ALU built from the player's sealed arithmetic components, then automatically expanded to a four-bit `ALU4` wrapper;
5. SR latch built from cross-coupled NOR logic;
6. one-bit register built from the player's latch, then automatically expanded to `Register4` without repeated bit-by-bit wiring;
7. a small two-address, four-bit RAM built from the player's registers, a decoder, and a word multiplexer;
8. a four-bit accumulator computer built from the player's ALU, register, RAM, control, and data-selection components;
9. a LOAD/STORE bridge run that reuses the verified computer topology and makes CPU/RAM transfers visible before the existing Cache/locality slice.

## Scope

- Add a session-local Hardware Foundations campaign map with two branches and prerequisite unlocking.
- Preserve the existing graph-authoritative editor, free wiring, movable procedural components, exact-path parallel signal animation, desktop Mission/Test Bench windows, undo/redo, multi-selection, and structured copy/paste.
- Generalize circuit component ports to support multiple outputs, named ports, and one-bit or four-bit word widths while retaining existing one-bit APIs.
- Add verified reusable-component contracts and a session component library. Every sealed component retains the player's source topology signature and snapshot.
- Add deterministic temporal circuit evaluation for the SR latch, register, RAM, and computer instruction sequences. Gate updates are discrete; ordinary wires and junctions remain zero latency.
- Add fixed, external Test Bench cases/sequences for every level, with editable debug inputs where useful and expected-versus-actual evidence.
- Add compact procedural symbols for NOR, reusable blocks, mux/decoder/control, register, RAM, ALU, and the tiny computer without a production art pass.
- Keep Simplified Chinese as the default and update the English catalog through semantic keys.
- Add headless simulation, progression/UI, localization, and existing v0.2 regression coverage.

## Explicit non-goals

- No Cache, Profiler, locality optimization, multi-level memory, pipeline, interrupts, assembly editor, general ISA, microcode editor, multicore, GPU, or later main-campaign content.
- No realistic electrical timing, analog behavior, metastability, clock skew, wire-length cost, or transistor simulation.
- No manual construction of four identical bit slices. Word wrappers are generated only after the player proves the one-bit idea.
- No persistent save/component-library file format in this iteration; progress is session-local and the limitation must remain visible.
- No general HDL, arbitrary user-defined component schema, arbitrary bit widths, level editor, production art, commits, branches, tags, pushes, or publication.

## Affected files and subsystems

- `src/circuit/`: wider/named ports, reusable component descriptions, deterministic combinational/temporal evaluation, level Test Benches, and trace values.
- `src/hardware_foundations/`: campaign/progression controller, level definitions, generalized circuit building, Test Bench evidence, reusable-library UI, procedural symbols, and exact-path playback.
- `src/ui/prototype_hub.gd` and project-facing copy: identify the expanded prologue without removing the v0.2 locality lab.
- `tests/`: component behavior, official truth tables/sequences, graph authority, sealing prerequisites, branch unlocks, final LOAD/STORE program, editor regression, localization, and v0.2 regressions.
- `localization/`, architecture/status/testing documentation, and a focused ADR for the prologue abstraction/temporal model.

## Invariants

- Displayed topology is authoritative for every construction level; no hidden topology independently grants success.
- A component may be reused only after its unchanged source circuit passes that level's official Test Bench.
- A reusable instance keeps the player's source snapshot/signature. Its compact runtime contract is fixed at sealing and cannot silently change behavior.
- Simulation is deterministic and complete before animation starts.
- Ordinary wire/junction geometry never adds simulation delay or changes results.
- Signals animate along the exact displayed segment paths; components ready in the same causal wave animate in parallel.
- Unconnected ports default low; explicit connected high impedance remains distinct; incompatible widths and conflicting active drivers fail visibly.
- Combinational feedback remains invalid except in the explicitly temporal latch evaluation. The latch uses discrete gate updates; later stateful abstractions define their state transition at a Test Bench step boundary.
- The preserved locality DSL/SimulationCore remains independent and retains its 321/105-cycle reference behavior.
- Fixed Test Bench/Program instruments are external to player hardware and are never duplicated by copy/paste.

## Gameplay and simulation decisions

- Use a four-bit word datapath for Register/RAM/CPU levels. It is large enough to show address/data movement and small enough to remain readable.
- The ALU exposes AND, OR, ADD, and NOT-A operations. Its carry output is official evidence for ADD cases; the result selector is player-wired.
- The SR latch uses active-high `S`/`R` and two cross-coupled NOR gates. `S=R=1` is explicitly invalid; official sequences establish reset before testing hold/set/reset behavior.
- `Register1` exposes `D`, `LOAD`, and `Q`; one Test Bench step is the simplified clock edge. Passing it generates a four-bit wrapper instead of requiring four repeated constructions.
- RAM is two words × four bits, with one-bit address, four-bit data input/output, and write enable. This is intentionally tiny but exercises address selection and retained state.
- The tiny computer is an accumulator machine with four externally supplied instruction classes: `LOAD_IMM`, `ADD_IMM`, `LOAD_MEM`, and `STORE_MEM`. The Test Bench supplies the instruction stream; opcode encoding and instruction fetch are not player tasks yet.
- The final bridge replays a fixed LOAD/STORE program over the unchanged verified topology. It ends by highlighting CPU/RAM separation and offers the existing Cache Locality Lab as the next experiment; it does not introduce Cache inside the prologue.
- Campaign order is a dependency graph: Half Adder unlocks both Full Adder and Latch; Full Adder unlocks ALU; Latch unlocks Register then RAM; CPU unlocks only after ALU and RAM; LOAD/STORE unlocks after CPU.

## Implementation and verification steps

1. Add typed port specifications, width validation, reusable component records, and backwards-compatible signatures/cloning.
2. Add deterministic multi-output/value evaluation and a bounded temporal runner for feedback/state sequences, with explicit invalid/oscillation diagnostics.
3. Add level definitions, official truth tables/temporal programs, dependency unlocking, session component library, and reference auto-build helpers used only by tests/capture hooks.
4. Generalize Hardware Foundations from three hard-coded phases into tutorial + campaign levels + sealing/library progression while preserving the existing editor interactions.
5. Implement Full Adder, ALU, latch, register, RAM, tiny-computer, and LOAD/STORE bridge layouts/inventories, procedural symbols, Test Bench controls/evidence, and exact-path trace playback.
6. Add focused simulation and UI tests for every official level, invalid alternatives, unchanged-topology sealing, generated word wrappers, progression prerequisites, final program results, and deterministic traces.
7. Run all existing simulation/UI/localization suites, project/direct-scene smokes, Chinese and English captures, and representative level visual captures.
8. Review full diff/status, update durable architecture/status/testing facts, record temporary limitations, and move this plan to `completed/` only after fresh verification.

## Progress

- 2026-08-18: read the referenced planning conversation, repository rules, existing architecture/status/ADRs, current circuit/editor implementation, tests, and dirty-worktree boundary. The planned seven construction levels plus LOAD/STORE bridge were confirmed; implementation has not started.
- 2026-08-18: generalized components to named multi-input/multi-output ports and one-/two-/four-bit widths while retaining the original one-bit API. Added deterministic word values, reusable-component provenance, temporal trace events, bounded gate settling, state-step transitions, width/feedback/invalid-latch diagnostics, and official headless coverage.
- 2026-08-18: added the dependency-aware seven-level catalog and reference-only verification helpers. Full Adder, ALU, latch, register, RAM, graph-built CPU, and sealed-computer LOAD/STORE bridge all pass their official deterministic cases; the reference wiring remains outside player-facing definitions.
- 2026-08-18: integrated the campaign into the existing graph-authoritative editor. Both branches unlock from the session library, every construction challenge starts unwired, official evidence binds to the displayed signature, sealing preserves player provenance, changed upstream designs selectively invalidate dependants, and ALU/Register completion produces four-bit wrappers without repetitive slice wiring.
- 2026-08-18: added word-aware live ports and exact-curve pulses, causal-wave parallel playback, component-specific procedural feedback for gates/adder/mux/ALU/latch/register/RAM/control/computer, movable neutral Test Bench terminals, and deterministic map/CPU capture hooks. The final sealed-computer bridge is locked and hands off to the preserved locality scene.
- 2026-08-18: added two prologue test suites, expanded Chinese/English semantic catalogs and key coverage, recorded the hierarchy/temporal boundary in ADR 0008, and documented current behavior and temporary limits. A test-only unparented final-level button leak was found by verbose exit inspection and removed.
- 2026-08-18: completed fresh verification. All seven automated suites passed; Chinese/English, direct-Hardware, and hub-route smokes exited 0; both catalogs contain 477 matching entries with no missing referenced keys, duplicates, or placeholder mismatches; map/CPU captures were inspected; Markdown links and `git diff --check` passed. The only logged error is the known Windows root-certificate-store warning. The final diff/status was reviewed and no commit or push was made.

## Unresolved questions and temporary limitations

- Session-local progress is intentional for this iteration; persistence needs its own format/versioning decision later.
- The tiny external-instruction CPU is a bridge to data movement, not a claim to model a production CPU or complete ISA.
- The current automatic layouts and procedural effects are playtest-ready rather than a production art pass; dense custom player routes may still need manual junction placement.
