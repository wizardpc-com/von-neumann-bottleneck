# Architecture

This file is the high-level map. Detailed simulation behavior lives in [`docs/architecture/simulation.md`](docs/architecture/simulation.md); current slice facts live in [`docs/status/cpu-building-prologue.md`](docs/status/cpu-building-prologue.md) and [`docs/status/prototype-v0.2.md`](docs/status/prototype-v0.2.md).

## Hardware Foundations flow

```text
displayed GraphEdit components + connections
  -> exported LogicCircuit
  -> deterministic one-bit CircuitAnalyzer or multi-bit PrologueSimulator
  -> complete output/state evidence + causal events + diagnostics
  -> read-only parallel exact-wire/component playback

fresh official pass + unchanged topology signature
  -> cloned source snapshot + named interface/provenance
  -> PlayerContentState reusable component in the session library
  -> registered dependency unlocks and generated four-bit wrappers where repetition adds no decision

Wiring tutorial -> HalfAdder -> FullAdder -> ALU1 -> ALU4 --+
                           |                              +-> TinyComputer -> LOAD/STORE bridge
                           +-> SRLatch -> Register1 -> Register4 -> RAM2x4 --+
```

## Cache Locality Lab flow

```text
CodeEdit draft
  -> DSLParser preview / line explanations
  -> explicit Apply Program
  -> applied source -> DSLParser / nested DSLProgram IR
  -> SimulationCore
  -> complete SimulationTrace + metrics + source/route evidence
  -> read-only playback, component feedback, and Profiler investigation
```

## Subsystems

- `src/game/game_mode.gd` owns the explicit session-wide Game/Test mode. Game is the default; Test unlocks valid registered levels through a separate temporary content state and never changes simulation or Game-mode progression.
- `src/content/` owns explicit campaign branch/level descriptors, deterministic registry validation/order/dependencies, bounded prologue content packs, reward recipes, and session `PlayerContentState`. It describes arrangements of supported mechanics but does not execute electrical behavior. See [`docs/architecture/content-system.md`](docs/architecture/content-system.md).
- `src/circuit/` owns named typed ports, one-/two-/four-bit digital values, logic graphs/cloning/signatures, deterministic default-low tri-state analysis, combinational and bounded temporal prologue simulation, short/cycle/width/state diagnostics, reusable-component provenance, and causal events. It has no UI or locality-simulation dependency.
- `src/hardware_foundations/` owns the registry-driven graphical dependency map from tutorial through CPU, isolated Game/Test player-content views, Half Adder and later construction interactions, authoritative GraphEdit export, fixed external Test Benches, compact procedural symbols and whole-symbol selection feedback, exact-port wiring guides, port/segment/waypoint wiring and context deletion, transactional undo/redo, replacement/toggle marquee selection, selected-subgraph copy/paste, automatic layouts, live port feedback, floating Mission/Test Bench windows, parallel exact-path playback, and encapsulation presentation.
- `src/simulation/dsl_*.gd` parses a Python-shaped, indentation-based subset into nested, source-line-aware instructions. The program also derives address preview and line explanations from that IR. Test Bench creates the executable IR only from explicitly applied source.
- `src/simulation/simulation_core.gd` recursively executes that IR and owns the deterministic cost model, Cache state, events, result, and metrics. It has no UI dependency and no hidden row/column traversal branch.
- `src/simulation/simulation_event.gd` and `simulation_trace.gd` are the simulation/presentation boundary. Events retain source line, device route, and investigation details; the trace retains exact source and supports canonical deterministic comparisons.
- `src/ui/prototype_hub.tscn` is the project entry scene and selects Hardware Foundations or the preserved locality lab. `src/ui/main.tscn` remains the v0.2 locality scene.
- `src/ui/main.gd` assembles the fixed locality GraphEdit workbench, draggable auto-laid-out devices, independent floating instruments, staged playback, component feedback, Run History, and the Official target.
- `src/ui/floating_instrument_panel.gd` provides embedded movable, resizable, minimizable, independently closable windows used by both playable slices.
- `src/ui/trace_overlay.gd` renders a short moving tail and the active component's internal PROCESS indicator along a continuous presentation path. Inter-component portions are resolved from the workbench's actual GraphEdit connections; it does not call the simulation.
- `src/localization/localization.gd` owns startup locale selection and presentation lookup through Godot's `TranslationServer`; `localization/*.po` owns language copy. UI uses semantic keys, while simulation traces, DSL syntax, circuit topology, metrics, and canonical signatures remain locale-independent.
- `tests/test_simulation.gd` verifies parser/IR execution, address preview, line explanations, routes, evidence, cache tradeoffs, determinism, and reference metrics. `tests/test_ui.gd` verifies fixed topology, continuous component paths, floating instruments, strategy loading, Apply/run separation, exact source receipts, Profiler inspection, goals, and state invalidation.
- `tests/test_circuit_simulation.gd` verifies default-low and explicit-high-Z gate behavior, multi-driver resolution, short/cycle diagnostics, connectivity, determinism, delays, valid/invalid Half Adders, official cases, and sealed behavior. `tests/test_hardware_foundations_ui.gd` verifies the graphical campaign topology/state, editor shortcuts/history, replacement and Shift-toggle selection, subgraph copy/paste, exact compatible-port guides, event-driven live port colors, wiring interaction, exact displayed paths, authoritative graph export, official gating, and Half Adder sealing.
- `tests/test_content_registry.gd` verifies the built-in manifest, deterministic ordering, synthetic branch/level registration, invalid content rejection, reward installation, selective invalidation, and the player-content manifest boundary. `tests/test_prologue_simulation.gd` verifies named/word ports, zero-latency junction networks, official Full Adder/ALU/latch/register/RAM/CPU cases, invalid topologies, explicit write/hold state events, parallel RAM-cell boundaries, deterministic state transitions, generated wrappers, dependency contracts, and sealed behavior. `tests/test_hardware_prologue_ui.gd` verifies both progression branches, player-owned provenance, storage preview/commit/reset presentation, before/after rows, state-effect alignment after GraphEdit zoom/scroll, unlock/invalidation rules, exact word-path parallel animation, CPU construction, and the final LOAD/STORE bridge.
- `tests/test_localization.gd` verifies the Simplified Chinese default, English alternate catalog, semantic-key coverage, localized structured diagnostics, and identical simulation/circuit signatures across locales.

## Repository boundaries

- `docs/` is the durable project knowledge base.
- `experiments/` is for isolated investigations and must not become an implicit runtime dependency.
- There is no asset pipeline yet; the current interface is generated from built-in Godot controls.
- There is no CI workflow yet. The locally verified commands and the CI prerequisite are recorded in `docs/development/testing.md`.

Keep this map compact. Put subsystem mechanics in detailed docs and record consequential changes in `docs/decisions/` when a durable decision is actually made.
