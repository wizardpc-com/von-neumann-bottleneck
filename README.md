# Von Neumann Bottleneck — Cache Locality Slice

A disposable Godot 4.7.1 vertical slice for testing one idea: can hardware wiring, a tiny editable program, an automatic Cache, readable data-flow playback, and a Profiler make cache locality feel like a game?

The single level sums a fixed 4×4 row-major integer array. The default program traverses columns first. Swapping only the two loop headers makes it traverse rows first, converting repeated misses into spatial-locality hits.

## Run

Open this folder in Godot 4.7.1 stable and run the project, or use the executable already supplied for this workspace:

```powershell
& 'godot' --path .
```

Suggested first play:

1. Keep `1 line / 4 ints`, click **Run Official**, and watch the default column-first trace.
2. Click **Load row-first**, run the same Official Test Set, and read the direct before/after comparison in Profiler.
3. Try the 2-line and 4-line Cache choices. Larger capacity costs more hardware credits.
4. Disconnect a hardware link and try to run; use **Auto Wire** to restore the required topology.
5. Edit Debug Data and use **Run Debug**. Official data remains fixed.

Reference Official Test Set results with the one-line Cache:

| traversal | total | compute | wait | hits | misses | RAM bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| column-first | 321 | 17 | 304 | 0 | 16 | 256 |
| row-first | 105 | 17 | 88 | 12 | 4 | 64 |

Both produce the same correct result, `88`; only access order changes.

## Tests

The tests are plain headless GDScript and require no addon:

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --script res://tests/test_simulation.gd
& $godotConsole --headless --path . --script res://tests/test_ui.gd
& $godotConsole --headless --path . --quit-after 5
```

In a restricted Codex sandbox, Godot may be unable to create its normal AppData log directory. In that environment only, pass an absolute writable log path inside this workspace, for example:

```powershell
& $godotConsole --headless --path . --log-file '.godot/test.log' --script res://tests/test_simulation.gd
```

## Architecture

- `src/simulation/` is UI-independent. `DSLParser` validates only the syntax needed by this experiment. `SimulationCore` executes the program deterministically and produces a complete `SimulationTrace`.
- Wires describe connectivity and always cost zero cycles. Cache lookup, Bus request/transfer, RAM access, and CPU add/store operations own their costs.
- `src/ui/main.gd` builds the GraphEdit hardware bench, program/test controls, Profiler, and playback controls. Playback reads trace events; it never calls back into the simulation or changes metrics.
- Trace playback supports Pause, Step, 0.5×–4× speed, overall progress, event-specific pacing, and an explicit RAM → Bus → Cache path for returned cache lines.
- Program, relevant Test Bench data, Cache-capacity, and wiring changes invalidate stale trace/Profiler state. A column-first baseline is retained only for a like-for-like test and Cache comparison.
- `tests/test_simulation.gd` checks correctness, traversal classification, deterministic trace equality, playback non-mutation, capacity/cost behavior, and the official row-first advantage.
- `tests/test_ui.gd` constructs the real scene headlessly and exercises default layout visibility, exact-port wiring, editable-vs-official test isolation, stale-state invalidation, Profiler comparison, RAM return routing, and Step playback.

## Prototype model and deliberate simplifications

- Array: 4×4 row-major signed integers.
- Cache line: 4 contiguous integers / 16 bytes.
- Capacity: 1, 2, or 4 fully-associative lines with deterministic LRU replacement.
- One outstanding memory request at a time; no prefetching or overlap.
- Loads use the Cache. The final `store result, register` writes to the Test Bench, not back into cached array memory.
- Fixed teaching costs: Cache lookup 1 cycle, Bus request 2, RAM access 12, line return 4, add 1, final result store 1.
- DSL scope: register declarations, `load`, `add`, final `store`, exactly two `for name in 0..4` loops, and `A[row][col]`. It is intentionally not a general language.
- Visuals are functional prototype UI, not a final art pipeline.
- The UI targets a 1600×900 desktop layout; the dense Program and Profiler panels scroll when vertical space is tighter.

Not implemented: gate-level CPUs, multi-level caches, multicore/GPU, compression, blocking/tiling, energy, leaderboards, progression, save/version management, random levels, or a general compiler.
