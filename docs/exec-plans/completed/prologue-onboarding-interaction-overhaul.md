# Prologue Onboarding and Interaction Overhaul

Status: completed 2026-08-28. Automated verification is complete; fresh-player comprehension remains a manual playtest gate.

## Goal

Turn the Hardware Foundations prologue into a self-contained path from first signals to a small accumulator computer. A player without prior digital-logic knowledge must be able to identify the task, inspect every required tool and port, obtain progressively stronger reasoning help, and complete the build without guessing hidden contracts.

## Scope

- Correct component selection, movement, placement coordinates, erasing, branching/fan-out, connection compatibility feedback, and observation during read-only playback/hints.
- Add a cross-level component information system with concise hover help, detailed inspection, localized terminology, explicit port widths/behavior, provenance, and Handbook access.
- Rewrite the prologue overview, Mission briefings, hints, first-use onboarding, and completion flow.
- Rework the Tutorial, Half Adder, Full Adder, ALU, SR Latch, Register, RAM, CPU, and LOAD/STORE bridge layouts and teaching content.
- Convert the CPU build into staged in-level integration while retaining the final seven-step official program and the player's authoritative topology.
- Add focused interaction, Mission, component-information, hint, CPU, save, and regression coverage plus visual QA captures.

## Non-goals

- No Chapter 3, pipeline, prefetch, multicore, instruction memory, program counter, general ISA, or new large architecture system.
- No arbitrary-width HDL or player-configurable bit-width framework in this iteration; required widths become explicit in the existing bounded model.
- No copied Turing Complete UI, copy, or art and no production-art pipeline.
- No simulation rewrite, answer injection, hidden topology promotion, or weakening of official evidence.

## Invariants

- Simulation remains deterministic, UI-independent, and the sole source of results, metrics, completion, and `SimulationTrace`/prologue event evidence.
- Playback frequency, animation, camera motion, inspection, and window motion are presentation-only.
- Displayed player topology and provenance remain authoritative; Hint workbenches remain read-only and never enter player snapshots or receipts.
- Save/Continue, telemetry, named workbenches, branch independence, and reusable-component invalidation remain intact.
- Ordinary wires and explicit junctions remain zero-latency; crossings do not connect without a junction.
- The palette may retain meaningful alternatives; only misleading default pre-placement is removed.

## Affected subsystems and likely files

- Hardware editor and controller: `src/hardware_foundations/circuit_graph_edit.gd`, `circuit_module_row.gd`, `component_palette_item.gd`, `hardware_foundations.gd`, and the Hardware scene.
- Prologue content: `src/content/prologue/*_content_pack.gd` and `src/hardware_foundations/prologue_level_catalog.gd`.
- Shared UI: Mission narrative, completion overlay, terminology Handbook, and a bounded component-inspector view if extraction is warranted.
- Localization: Simplified Chinese and English PO catalogs.
- Persistence/telemetry only where a lightweight learned-capability or CPU-stage field is required; no new authority role.
- Tests: circuit/prologue simulation, Hardware UI/progression, content registry, localization, global save, playtest, Chapter 1/2 regressions, and startup smoke.
- Durable documentation: prologue status, architecture/testing notes, and this plan.

## Requirement checklist

### P0 interaction and CPU blockers

- [x] CPU shows the exact opcode-to-operation table and explains every required module, control signal, port, bit width, constant, and data path.
- [x] CPU uses bounded in-level stages for immediate source, ALU-to-ACC, memory load, memory store, then the complete seven-step program.
- [x] CPU default layout separates data, control, and constants; hints provide direction, a real key subcircuit, then the full reference.
- [x] Seeded, newly placed, and loaded components select and move reliably at ordinary and transformed canvas coordinates without stealing port wiring.
- [x] Placement preview and committed anchor agree after pan, zoom, window/fullscreen changes, and palette-window movement.
- [x] Right-button erase uses a visible, zoom-stable cursor contact area and does not delete distant hardware.
- [x] Players can branch from wire segments, waypoints, endpoints, and existing nets while duplicates remain rejected and crossings remain disconnected.
- [x] Compatibility uses direction, width, and electrical constraints; every rejected connection displays a concrete reason.

### Onboarding, information, and presentation

- [x] Prologue overview names the arithmetic and storage routes and their CPU/LOAD-STORE convergence.
- [x] Tutorial desktop is simpler; it teaches signal meaning, Handbook links, basic wiring, branching, inspection, and Test Bench once.
- [x] Signal state uses color plus `0`/`1` and directional shape, without relying on red/green alone.
- [x] Playback control is expressed as frequency/Hz, supports faster playback, and remains presentation-only.
- [x] Components palette tiles have consistent preview/name/detail alignment, padding, height, and width information.
- [x] Every required component has a concise tooltip and detailed localized Inspector with function, ports, widths, behavior, provenance, and Handbook action.
- [x] Important port labels expose bit widths; incompatibility and wider-signal presentation are visually clear.
- [x] Formal component names do not contain `Your`; ownership is expressed as provenance.
- [x] Controller, Register, RAM, ALU, MUX, Decoder, Carry, Load, Store, Latch, Working Set, and related first-use terminology are consistent across Mission, component UI, Handbook, and Test Bench.
- [x] Mission copy is concise, task-led, lightly contextual, and free of repetitive textbook/AI phrasing.
- [x] Completed briefings can always be expanded and navigated with Previous/Next; page counts follow teaching need.
- [x] Shared first-use capabilities work whichever branch is entered first and are not repeated after being learned.
- [x] Hint 1 supplies a reasoning direction, Hint 2 a key relationship plus curated partial topology, and Hint 3 the complete topology.
- [x] Hint workbenches permit WASD/middle-drag pan, wheel zoom, and component inspection while forbidding mutations and official evidence.
- [x] Trace/Official playback permits pan, zoom, inspection, and observation-window movement while locking authoritative mutations.
- [x] Every authoritative official pass enters an immediate success state with lesson/reward plus Seal/Continue and Return to Map as applicable.

### Level-specific teaching and layout

- [x] Half Adder teaches gates, truth table, truth-table-to-Boolean-to-circuit reasoning, and explicitly names/unlocks XOR on success.
- [x] Full Adder starts from the player's Half Adder ownership, has a clean left-to-right layout, and omits repeated Test Bench teaching.
- [x] ALU states the available operations/components, MUX role, OP mapping, result routing, carry semantics, and actual construction layer.
- [x] SR Latch teaches the need for state, feedback, NOR, SET/RESET/HOLD, Q/NQ, and uses a legible feedback layout.
- [x] Register gives the D/LOAD behavior table and bounded `S = ?`, `R = ?` derivation instead of an unscoped leap.
- [x] RAM explains Decoder/MUX/Register, DATA/ADDR/WRITE/OUT widths and flow, and uses a branch-friendly wide-signal layout.
- [x] LOAD/STORE bridge avoids repeated construction, makes semantics clear, and motivates Chapter 1's performance question.
- [x] All default layouts follow input-left, processing/storage-center, output-right, clear feedback, and adequate routing-space rules.

### P2 treatment in this iteration

- [x] Add bounded contextual flavor where it improves task identity without creating a new narrative system.
- [x] Apply coherent visual polish to the touched prologue surfaces.
- [x] Record configurable bit width as deferred; implement explicit width visibility now.
- [x] Improve clarity using the project's own procedural visual language rather than copied assets.

## Implementation and verification sequence

1. Reproduce and isolate current interaction failures with focused headless/UI probes; inspect coordinate conversions and input priority before editing.
2. Repair editor gestures and add focused regression coverage.
3. Build the component knowledge metadata/view and connect it to canvas, palette, ports, and Handbook.
4. Rework Mission/Hint/shared-onboarding/completion infrastructure and localization.
5. Update each level's content, layouts, hints, and success lessons; implement CPU stage gates without changing final simulation authority.
6. Run focused tests after each workstream, then the full documented suite, startup smokes, save/telemetry checks, and `git diff --check`.
7. Capture and inspect Tutorial, Half Adder, Full Adder, ALU, Latch, Register, RAM, CPU, Inspector, Hint 2/3, success, clock, signal-state, and transformed/fullscreen frames.
8. Record actual outcomes and limitations, move this plan to `completed/`, and leave human playtest questions explicit.

## Decisions and rationale

- CPU stages are presentation/progression checks over the same visible topology and deterministic simulator, not alternate hidden circuits. This reduces simultaneous cognitive load while preserving the final construction problem.
- Component knowledge will be driven by one bounded metadata source so palette, canvas Inspector, ports, Handbook links, and tests cannot drift independently.
- First-use onboarding state is instructional preference only. It must never serve as completion or reusable-component authority.
- Success presentation begins only after authoritative official evidence completes. It may offer Seal/Continue directly but cannot manufacture the evidence.

## Progress

- 2026-08-27: Read the complete attached 2,259-line playtest/telemetry/requirements record, repository guidance, prior prologue status, and relevant historical interaction decisions. Confirmed a clean `main` worktree before implementation.
- 2026-08-28: Repaired editor selection/movement, placement coordinates, precise erasing, occupied-input branching/fan-out, compatibility diagnostics, and read-only observation navigation. Added focused UI regressions.
- 2026-08-28: Added the component Inspector, concise hover help, formal localized naming, explicit bit widths, behavior/provenance, Handbook access, aligned palette tiles, signal value/direction shapes, and presentation-only `0.5–120 Hz` playback.
- 2026-08-28: Rewrote map/Mission/Hint/onboarding content and default layouts across Tutorial, Half Adder, Full Adder, ALU, Latch, Register, RAM, CPU, and LOAD/STORE. CPU now has a five-page contract and four topology-derived integration stages before the unchanged seven-step official program.
- 2026-08-28: Added immediate authoritative-success actions and captured/inspected Tutorial, Half Adder, Full Adder, ALU, Latch, Register, RAM, CPU briefing, Inspector, Hint, and CPU success at 1600×900 with Godot 4.7.1.
- 2026-08-28: Passed all 14 repository test suites on Godot 4.7.1, including simulation, both prologue suites, all UI suites, localization, global save, telemetry/playtest data, and feedback. Ordinary and Test-mode startup smokes both exited cleanly.

## Unresolved questions and limitations

- Shared onboarding is expressed once at the common Tutorial/map boundary, so no new learned-capability persistence field or completion authority was required.
- Automated checks establish reachability, information presence, unchanged deterministic authority, and visual non-overlap. Zero-prior-knowledge comprehension, comfort, and the CPU Mission + Inspector + Hint 1/2 kill gate still require the requested fresh human playtest.
