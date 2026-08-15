# Architecture

This file is the high-level map. Detailed simulation behavior lives in [`docs/architecture/simulation.md`](docs/architecture/simulation.md); verified prototype facts live in [`docs/status/prototype-v0.1.md`](docs/status/prototype-v0.1.md).

## Runtime flow

```text
CodeEdit source
  -> DSLParser / DSLProgram
  -> SimulationCore
  -> complete SimulationTrace + metrics
  -> UI profiler and read-only trace playback
```

## Subsystems

- `src/simulation/dsl_*.gd` parses and represents only the language needed by the current experiment: registers, fixed two-level loops, `load`, `add`, a final `store`, and 2D array indexing.
- `src/simulation/simulation_core.gd` owns deterministic execution, the fixed teaching cost model, Cache state, events, results, and metrics. It has no UI dependency.
- `src/simulation/simulation_event.gd` and `simulation_trace.gd` are the boundary between simulation and presentation. A canonical signature supports deterministic comparisons.
- `src/ui/main.tscn` is the project scene. `src/ui/main.gd` currently assembles the program editor, Test Bench, GraphEdit hardware layout, playback controls, and Profiler in code.
- `src/ui/trace_overlay.gd` renders packet paths from already-computed trace events. It does not call the simulation.
- `tests/test_simulation.gd` verifies model behavior and reference metrics. `tests/test_ui.gd` instantiates the real scene headlessly and verifies wiring, UI state, playback non-mutation, and layout assumptions.

## Repository boundaries

- `docs/` is the durable project knowledge base.
- `experiments/` is for isolated investigations and must not become an implicit runtime dependency.
- There is no asset pipeline yet; the current interface is generated from built-in Godot controls.
- There is no CI workflow yet. The locally verified commands and the CI prerequisite are recorded in `docs/development/testing.md`.

Keep this map compact. Put subsystem mechanics in detailed docs and record consequential changes in `docs/decisions/` when a durable decision is actually made.
