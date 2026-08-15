# Von Neumann Bottleneck

> Early prototype: the repository is an engineering and gameplay experiment, not a production-ready game or stable public release.

Von Neumann Bottleneck is a systems puzzle game about making data movement visible. Players wire a small hardware bench, edit a deliberately tiny program, run a deterministic simulation, and use trace playback plus profiler evidence to understand why one memory-access pattern is faster than another.

The current `prototype-v0.1` vertical slice contains one 4×4 row-major array-sum challenge. Its default column-first traversal performs poorly with a one-line Cache; swapping the loop order exposes spatial locality and reduces both cache misses and total cycles.

## Engine

- Godot 4.7.1 stable
- Strongly typed GDScript
- Built-in Godot UI and graph controls; no external addons

## Run

Open this repository in Godot 4.7.1 stable and run the project, or from PowerShell:

```powershell
& 'godot' --path .
```

Suggested prototype path:

1. Keep `1 line / 4 ints`, click **Run Official**, and watch the column-first trace.
2. Click **Load row-first**, rerun the Official Test Set, and compare the Profiler.
3. Try the larger Cache capacities, edit Debug Data, or disconnect and restore a hardware link.

With the official data and one-line Cache, both programs return `88`. Column-first records 321 total cycles and 16 misses; row-first records 105 cycles and 4 misses.

## Test

The repository has addon-free headless simulation and UI tests:

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-simulation.log' --script res://tests/test_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-ui.log' --script res://tests/test_ui.gd
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
```

See [testing details](docs/development/testing.md) for verified outcomes and environment notes.

## Repository guide

- [Architecture](ARCHITECTURE.md)
- [Design principles](docs/design/core-principles.md)
- [Prototype status and limitations](docs/status/prototype-v0.1.md)
- [Development documentation](docs/README.md)
- [Execution-plan policy](PLANS.md)

The vision is to make performance reasoning tangible through visible, explainable data flow. The shape of a complete game, its progression, and its final presentation remain open design work; this repository does not treat prototype choices as permanent product commitments.
