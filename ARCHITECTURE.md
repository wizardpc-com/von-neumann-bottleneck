# Architecture

This file is the high-level map. Detailed simulation behavior lives in [`docs/architecture/simulation.md`](docs/architecture/simulation.md); current slice facts live in [`docs/status/cpu-building-prologue.md`](docs/status/cpu-building-prologue.md), [`docs/status/chapter-1-waiting-for-data.md`](docs/status/chapter-1-waiting-for-data.md), [`docs/status/chapter-2-reducing-data-movement.md`](docs/status/chapter-2-reducing-data-movement.md), and [`docs/status/playtest-instrumentation.md`](docs/status/playtest-instrumentation.md).

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

Wiring tutorial --+-> HalfAdder -> FullAdder -> ALU1 -> ALU4 --+
                  |                                        +-> TinyComputer -> LOAD/STORE bridge
                  +-> SRLatch -> Register1 -> Register4 -> RAM2x4 --+
```

## Chapter 2 data-movement flow

```text
Chapter 1 bottleneck completion + registered seven-level prerequisites
  -> observation / exploration / implementation / capstone configuration
  + CodeEdit draft where the level exposes Program
  -> DSLParser preview / line explanations
  -> explicit Apply Program
  -> applied source -> DSLParser / nested DSLProgram IR
  + selected direct/Cache path + pass count + bounded work grouping
  -> SimulationCore.run() or additive run_workload()
  -> complete SimulationTrace + metrics + source/route evidence
  -> immutable LocalityRunReceipt + Before → After comparison
  -> qualifying observation receipt carried read-only into its paired solution level
  -> read-only playback, component feedback, and progressive Profiler investigation
  -> evidence judgment or trace-derived performance finding
  -> completed Trace + explicit finding review
  -> delayed Systems Notebook concept reveal
```

## Chapter 1 system-performance flow

```text
prologue CPU/RAM source signatures + selected compatible parts
  + displayed six-route CPU/Bus/RAM GraphEdit topology
  + explicitly applied bounded program + fixed official cases
  -> deterministic SystemSimulationCore
  -> complete SystemTrace events/metrics/output
  -> immutable SystemRunReceipt bound to source, topology, parts, and test set
  -> prediction-led controlled comparison or trace-derived final diagnosis
  -> read-only exact-curve playback + component feedback + progressive Profiler
  -> complete diagnostic breakdown only after the player's first submitted diagnosis
```

Chapter 1 progression receipts additionally require the authored per-level program signature. Custom programs can execute as debug evidence but cannot enter controlled comparisons. Before the first final diagnosis, the authored program and default machine parts remain fixed alongside the hidden breakdown.

## Subsystems

- `src/game/game_mode.gd` owns the explicit session-wide Game/Test mode. Game is the default and hides mode/QA controls; only the `--test-mode` CLI authority exposes the shared selector and Test tooling. Test unlocks valid registered levels through a separate temporary content state and never changes simulation or Game-mode progression.
- `src/playtest/playtest_data.gd` owns one anonymous session identity, an immediately flushed versioned JSONL event stream, interrupted-session recovery, derived level summaries, a versioned single-file JSON export, and the explicit `--reset-local-test-state` developer cleanup. It observes existing controller boundaries only: callers ignore write/export failures, and the service never supplies simulation inputs, completion evidence, progression state, scores, Trace data, or playback state. Every event carries Game/Test mode; full Program source, Notebook text, machine identity, and unrelated personal data are excluded. Reset removes local session streams and Hardware workbench state while preserving previous exports.
- `src/playtest/playtest_feedback_overlay.gd` owns concise skippable chapter and Demo forms plus the final Demo export handoff, exported path, and open-folder action. `src/ui/level_completion_overlay.gd` optionally embeds the three per-level ratings and bounded note after authoritative completion. Normal player launches enable these surfaces; script, headless, and capture launches suppress them unless a focused test explicitly opts in.
- `src/content/` owns explicit campaign branch/level descriptors, deterministic registry validation/order/dependencies, bounded prologue content packs, reward recipes, and session `PlayerContentState`. It describes arrangements of supported mechanics but does not execute electrical behavior. See [`docs/architecture/content-system.md`](docs/architecture/content-system.md).
- `src/circuit/` owns named typed ports, one-/two-/four-bit digital values, logic graphs/cloning/signatures, deterministic default-low tri-state analysis, combinational and bounded temporal prologue simulation, short/cycle/width/state diagnostics, reusable-component provenance, and causal events. It has no UI or locality-simulation dependency.
- `src/hardware_foundations/` owns the registry-driven graphical dependency map from tutorial through CPU, isolated Game/Test player-content views, Half Adder and later construction interactions, explicit level-owned component supplies, a draggable movable/resizable/closable component palette, scaled palette thumbnails and low-opacity placement previews generated from the same procedural node view used on the canvas, repeated snapped commits, seed-fingerprinted per-level named topology snapshots, separate read-only progressive hint graphs, authoritative GraphEdit export, fixed external Test Benches, compact function-specific procedural symbols and whole-surface selection feedback, compact visual ports with generous independent hit zones, exact-port wiring guides, one-renderer player-colored cables, port/segment/waypoint wiring and context deletion, transactional undo/redo, replacement/toggle marquee selection, selected-subgraph copy/paste, automatic layouts, live port feedback, floating Mission/Test Bench windows, parallel exact-path causal flow with wider-value badges, case-by-case official-test presentation, and encapsulation presentation. Stage 1 hints show only the interface, Stage 2 shows an authored subcircuit and necessary context, and Stage 3 shows the complete reference. Future-case outputs and the aggregate verdict remain hidden until their playback boundary completes. Test Bench and Components omit minimization but retain geometry-preserving close/taskbar toggles. Its campaign map hides the Test Bench and gives Mission a dedicated non-overlapping lane; these presentation choices do not change progression or simulation. Workbench persistence reconstructs ordinary displayed topology and optional cable-color metadata but does not participate in simulation semantics, official evidence, or animation timing.
- `src/simulation/dsl_*.gd` parses a Python-shaped, indentation-based subset into nested, source-line-aware instructions. The program also derives address preview and line explanations from that IR. Test Bench creates the executable IR only from explicitly applied source.
- `src/simulation/simulation_core.gd` recursively executes that IR and owns the deterministic cost model, Cache state, events, result, and metrics. Its legacy `run()` path preserves the one-pass v0.2 trace exactly. The additive `run_workload()` path executes direct RAM observation or one/two program passes with bounded program-derived work groups; it has no UI dependency and no hidden row/column result branch.
- `src/simulation/simulation_event.gd` and `simulation_trace.gd` are the simulation/presentation boundary. Events retain source line, device route, and investigation details; the trace retains exact source and supports canonical deterministic comparisons.
- `src/system_lab/` owns Chapter 1's separate 8-bit CPU/RAM/Bus specifications, six typed routes, bounded program parser, sequential cost model, deterministic Trace/receipt/diagnosis, five-level prediction-and-investigation catalog, isolated Game/Test chapter state, graphical chapter map, system desktop, player-colored route rendering, component-native feedback, exact-segment flow-band/value-badge overlay, an editable presentation Clock Period, controlled Before → After evidence, gated diagnostic breakdown, and completion handoff to its own map. It deliberately has no Cache or circuit-gate evaluator.
- `src/locality_chapter/` owns Chapter 2's seven-level runtime catalog, isolated Game/Test completion and receipt state, concept-unlock rules, trace-bound run receipts, and exact validation of the observation receipts that may become paired-level baselines. It reuses the generic registered identity/order/dependency contract without executing content dictionaries.
- `src/content/locality/` registers the Chapter 2 branch and seven sequential descriptors. Locality-specific workload and UI metadata remains in the typed Chapter 2 catalog rather than stretching the campaign registry into a simulator.
- `src/ui/prototype_hub.tscn` is the project entry scene and selects Hardware Foundations, Chapter 1, or Chapter 2. Chapter 2 is gated behind Chapter 1 in Game mode and open in Test mode. Its modal Options overlay owns chapter-selection `Esc`, Resume, fullscreen switching, and explicit application exit.
- `src/ui/main.gd` wraps the established locality GraphEdit workbench in a seven-node map and per-level tool configuration. It owns Mission judgments, Program Apply, direct/Cache topology presentation, Work Group controls, staged/key-evidence/end playback navigation, an editable presentation Clock Period, progressive Profiler, inherited Before → After plus Personal Best history, post-playback finding review, diagnosis-gated capstone evidence, Systems Notebook, and Baseline → Best completion presentation; none of those determine simulation.
- `src/ui/floating_instrument_panel.gd` provides embedded movable, resizable, independently closable windows and allows a host-owned compact action to replace generic title-strip minimization. Hardware Mission uses that action for its readable lower-left compact state; Hardware Test Bench/Components and Chapter 1/2 Mission disable minimization, while other chapter tools may retain it. Launcher buttons use close-equivalent toggling, so hiding and reopening preserves the panel's current geometry.
- `src/ui/ui_typography.gd` owns the shared title, subtitle, body, caption, window-title, and compact-control dimensions used across chapter headers, Mission content, completion summaries, and the terminology handbook. `src/ui/terminology_handbook.gd` presents its cross-chapter catalog, including the presentation-only Clock Period, as a bounded topic → directory → term tree while retaining category filtering and search.
- `src/ui/level_completion_overlay.gd` presents an already-authoritative level completion with localized lesson copy, a replaceable in-memory audio cue, optional compact playtest ratings, and a Continue signal. Feedback remains skippable and never determines results, unlocks, timing, or saved state; each host performs its own return-to-map action.
- `src/ui/trace_overlay.gd` renders only a compact moving packet along a continuous presentation path. Inter-component portions use the workbench's actual GraphEdit connections; in-component portions stay inside the actual device body, whose real card/state supplies processing feedback. It does not call the simulation.
- `src/ui/window_mode.gd`, `fullscreen_button.gd`, and `floating_instrument_panel.gd` own the presentation-only desktop boundary: resizable fullscreen startup, shared `F11`/`Alt+Enter` switching, deterministic windowed captures, and keeping movable instrument panels sized and clamped to the current visible workspace. Window size never enters simulation, topology, timing, or save signatures.
- Chapter roots perform level/map back-navigation from unhandled key input. Focused controls and graph gestures therefore receive `Esc` first; only an unconsumed press advances from level to map or map to chapter selection.
- `src/localization/localization.gd` owns startup locale selection and presentation lookup through Godot's `TranslationServer`; `localization/*.po` owns language copy. UI uses semantic keys, while simulation traces, DSL syntax, circuit topology, metrics, and canonical signatures remain locale-independent.
- `tests/test_simulation.gd` verifies parser/IR execution, address preview, line explanations, direct and cached routes, one-/two-pass evidence, blocking schedules, multiple solutions, determinism, and all legacy/current reference metrics. `tests/test_ui.gd` retains deep fixed-topology, continuous component-path, floating-instrument, Apply/run, exact-source, Profiler, goal, and invalidation coverage inside the capstone. `tests/test_locality_chapter_ui.gd` verifies the complete seven-level Game path, delayed concepts, judgments, comparisons, gates, and multiple capstone solutions.
- `tests/test_circuit_simulation.gd` verifies default-low and explicit-high-Z gate behavior including XOR, multi-driver resolution, short/cycle diagnostics, connectivity, determinism, delays, valid/invalid Half Adders, official cases, and sealed behavior. `tests/test_hardware_foundations_ui.gd` verifies the unobstructed graphical campaign topology/state, independent branch roots, editor shortcuts/history, truthful repeated palette placement and every cancellation boundary, movable/custom-compact/closable Mission behavior, briefing Previous/final-Continue flow, geometry-preserving taskbar toggles, Test Bench map exclusion, replacement and Shift-toggle selection, subgraph copy/paste, exact compatible-port guides, event-driven live port colors, wiring interaction, exact displayed paths, authoritative graph export, official gating, Half Adder sealing, and completion return-to-map flow.
- `tests/test_content_registry.gd` verifies the built-in manifest, deterministic ordering, synthetic branch/level registration, invalid content rejection, reward installation, selective invalidation, and the player-content manifest boundary. `tests/test_prologue_simulation.gd` verifies named/word ports, zero-latency junction networks, official Full Adder/ALU/latch/register/RAM/CPU cases, invalid topologies, explicit write/hold state events, parallel RAM-cell boundaries, deterministic state transitions, generated wrappers, dependency contracts, and sealed behavior. `tests/test_hardware_prologue_ui.gd` verifies both progression branches, player-owned provenance, storage preview/commit/reset presentation, before/after rows, state-effect alignment after GraphEdit zoom/scroll, unlock/invalidation rules, exact word-path parallel animation, CPU construction, and the final LOAD/STORE bridge.
- `tests/test_localization.gd` verifies the Simplified Chinese default, English alternate catalog, semantic-key coverage, localized structured diagnostics, and identical simulation/circuit signatures across locales.
- `tests/test_system_lab_simulation.gd` verifies the five-level catalog, bounded DSL, displayed-topology authority, exact CPU/RAM/Bus formulas, 8-bit wrap, deterministic signatures, controlled-comparison receipts, the CPU-speed reversal, final workload aggregation, and CPU/RAM/Bus/mixed diagnoses. `tests/test_system_lab_ui.gd` completes all five levels through the normal UI boundary and verifies map gates, prediction locking, Apply, controlled Before → After evidence, replaceable parts, floating tools, exact transformed connection curves, component feedback, diagnosis-time breakdown reveal, Game/Test isolation, localized completion summaries, and Continue-to-map behavior.
- `tests/test_playtest_data.gd` verifies unique sessions, append durability, malformed-tail recovery, Test-mode attribution, counters, bounded text, summary derivation, clean shutdown, export schema/privacy, and selective local reset. `tests/test_playtest_feedback_ui.gd` verifies localized level/chapter/Demo submission, skip paths, final export/path/open-folder handoff, and questionnaire-disabled non-blocking behavior.

## Repository boundaries

- `docs/` is the durable project knowledge base.
- `experiments/` is for isolated investigations and must not become an implicit runtime dependency.
- There is no asset pipeline yet; the current interface is generated from built-in Godot controls.
- There is no CI workflow yet. The locally verified commands and the CI prerequisite are recorded in `docs/development/testing.md`.

Keep this map compact. Put subsystem mechanics in detailed docs and record consequential changes in `docs/decisions/` when a durable decision is actually made.
