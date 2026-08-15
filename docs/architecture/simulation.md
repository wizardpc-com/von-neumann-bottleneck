# Simulation architecture

## Current pipeline

1. `DSLParser.parse()` converts editor text into a `DSLProgram`, collecting validation errors instead of executing invalid input.
2. `SimulationCore.run()` executes fixed four-by-four loop ranges against an integer array and selected Cache capacity.
3. The core computes result, cycle counters, Cache/RAM metrics, and an ordered list of `SimulationEvent` objects.
4. The completed `SimulationTrace` crosses the simulation/UI boundary.
5. `src/ui/main.gd` renders metrics immediately and plays events over time. Playback timing is presentation-only.

The current DSL accepts register initialization, exactly two nested `for name in 0..4` loops, `load`, `add`, a final `store result, register`, and `A[row][col]` indexing. It is a purpose-built parser, not a compiler platform.

## Intended invariants and current status

| invariant | current implementation |
| --- | --- |
| Simulation is deterministic. | Cache replacement, loop ranges, costs, and event order are deterministic; `canonical_signature()` is compared in the simulation test. |
| Ordinary wire latency is zero. | Graph connections gate whether a run is allowed but never add cycles. |
| Transfer cost belongs to components. | Cache lookup, Bus request/line transfer, and RAM access own explicit costs; CPU add and result-store costs are separate compute work. |
| UI/rendering cannot affect simulation. | `SimulationCore` has no UI dependency. UI receives a completed trace and does not call back into the core during playback. |
| Simulation emits trace data and UI plays it back. | Metrics and all events are computed before `current_trace` is assigned to playback. |
| Cache is hardware-managed. | Loads perform lookup, deterministic LRU fill/eviction, and automatic line return; there is no player cache-insertion action. |

No violation of these listed invariants is currently verified. Future changes must preserve them or document an intentional architectural decision before changing behavior.

## Cost and Cache model

- Cache line: 4 integers / 16 bytes.
- Capacity: 1, 2, or 4 fully associative lines.
- Replacement: deterministic least-recently-used.
- Cache lookup: 1 cycle.
- Bus request: 2 cycles.
- RAM access: 12 cycles.
- Bus line return: 4 cycles.
- CPU add: 1 cycle.
- Final result store to Test Bench: 1 cycle.
- One memory request is completed before the next; there is no overlap or prefetch.

Wait cycles include Cache lookup and miss-path transfer costs. Compute cycles include adds and the final result store. `total_cycles` is their sum in the current sequential model.

## Wiring and presentation

The GraphEdit bench requires six exact connections among Program Controller, CPU, Cache, Bus, RAM, Test Bench, and Profiler. Wiring is currently a fixed-topology validation rule, not a graph-driven simulation network. A missing required connection blocks execution; extra connections do not alter cost or routing.

For playback, most events use a direct visual route between devices. A returned cache line is explicitly drawn RAM → Bus → Cache. Event display durations are chosen for readability and are unrelated to simulated cycle counts.

## Prototype-scale shortcuts

- The core iterates fixed 4×4 ranges and executes a flattened loop body represented by the DSL program.
- The result store targets Test Bench rather than array memory.
- `main.gd` is a large programmatic UI coordinator rather than a mature set of smaller view components.
- The profiler compares a row-first run only with a previously captured column-first baseline for the same test name and Cache capacity.
- The event trace is retained in memory and is not a stable external serialization format.

These are documented facts, not invitations for an unrelated refactor.
