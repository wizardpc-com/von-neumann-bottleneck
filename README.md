# Von Neumann Bottleneck

> Early prototype: the repository is an engineering and gameplay experiment, not a production-ready game or stable public release.

Von Neumann Bottleneck is a systems puzzle game about constructing computing abstractions and making their behavior visible. The project currently contains two playable research slices, selected from a startup hub:

- **CPU Building Prologue:** learn direct wiring, construct and seal a 1-bit Half Adder, then grow that player-owned component library through Full Adder/ALU and latch/register/RAM branches. Join both branches in a four-bit accumulator computer and finish with a visible LOAD/STORE program.
- **Cache Locality Lab v0.2:** edit and explicitly apply a tiny program, investigate its deterministic machine trace, and compare software locality with additional Cache capacity.

Neither slice is a complete game. They test different gameplay hypotheses while sharing deterministic simulation and trace-first presentation principles.

The playable interface defaults to Simplified Chinese. An English catalog is retained as the first alternate locale; launch with `--language en` (or pass `-- --locale=en`) to inspect it. DSL keywords, source code, addresses, port names, and stable component IDs remain language-neutral technical evidence.

Every screen exposes a shared **Game mode / Test mode** selector. Game mode is the default and follows normal progression. Test mode unlocks every current campaign level and supplies an isolated temporary component library so late levels can actually open; switching back restores Game-mode progress unchanged. Launch directly in Test mode with `-- --test-mode`. Mode and progress remain session-local.

## Engine

- Godot 4.7.1 stable
- Strongly typed GDScript
- Built-in Godot UI and graph controls; no external addons

## Run

Open this repository in Godot 4.7.1 stable and run the project, or from PowerShell:

```powershell
& 'godot' --path .
```

Suggested Hardware Foundations path:

1. Open **CPU Building Prologue** from the hub. The central graphical map shows the whole prerequisite tree: cyan nodes are currently available, green nodes are completed/replayable, and gray nodes remain locked. The arithmetic and storage branches visibly merge at the CPU, while level identity and unlock state still come from the campaign registry rather than a duplicated UI list.
2. In the tutorial, choose a gate from **Components**, then left-click empty canvas space to place as many level-allowed instances as needed; `Esc` cancels placement. Left-drag a component body to move it or a large colored port to draw a wire. An unconnected port defaults to red/low (`0`); green is high (`1`), while gray is an explicit high-impedance or unresolved state. Hold the right mouse button and sweep the cursor tip directly across wires or any component to erase everything touched in one undoable stroke; nearby empty space is safe. Hold `Shift` and left-drag a connected input port when intentionally moving an existing wire end.
3. After the five tutorial interactions unlock it, build a Half Adder with the schematic `and`, `or`, and compact single-input `not` symbols. During wiring, cyan marks the chosen source, green outer rings mark exact compatible targets, red marks an invalid hovered target, and the inner red/green/gray port color continues to show the live electrical value. Rendered wires receive an exact-path hover highlight before editing. A fresh unwired challenge is explicitly presented as incomplete, not faulty. Ordinary empty-canvas drag replaces the current selection; selected components recolor their complete symbol and leads instead of gaining a separate circle. `Shift`-click or `Shift`-drag toggles items, and double-click includes the explicit wire nodes connected to a component. `Ctrl+A` selects all, `Ctrl+X` cuts, `Ctrl+Z` undoes, `Ctrl+Y` or `Ctrl+Shift+Z` redoes, and `Ctrl+C`/`Ctrl+V` copies/pastes the selected player subgraph. Test Bench terminals are neither copied nor cut. WASD pans the view, the wheel zooms, and middle-drag pans directly. Ports, empty-space wire nodes, and existing segments can all start or extend a route; the same port may accept multiple distinct segments. Equal active drivers are legal, opposite `0`/`1` drivers report a short circuit, and same-tick feedback reports a circular dependency.
4. Use the movable/minimizable **Mission** and **Test Bench** windows like desktop panels. Debug individual A/B cases, then run the four Official truth-table cases.
5. After a fresh four-case pass, seal the unchanged topology as `HalfAdder`. Continue on the same map through the arithmetic branch (`FullAdder` → `ALU1` → generated `ALU4`) and storage branch (`SRLatch` → `Register1` → generated `Register4` → `RAM2x4`).
6. Build the unlocked four-bit accumulator CPU from those verified abstractions, seal it as `TinyComputer`, then run the fixed LOAD/STORE bridge. Every construction challenge starts unwired; the final bridge deliberately reuses the already verified computer instead of asking for the same wiring again.

The preserved v0.2 path remains available from the same hub:

1. Open **Program**, use the Python-shaped reference or load either supplied strategy, and inspect the line-by-line explanation plus address preview. Editing changes only a draft; press **Apply Program** to confirm the exact source Test Bench may execute.
2. Watch each request progress through Program issue, one component's internal PROCESS animation, wire transfer, and the next component's receive stage.
3. Open **Profiler** beside Program, move or resize either instrument, select a memory event, and use **Inspect in Trace** without losing the editor or investigation layout.
4. Run the applied source and use its last-executed receipt to confirm cycles and misses. Reach the Official goal—correct result in at most `105` cycles—by changing loop order, replacing the Cache with 2 or 4 lines, or comparing both approaches in Run History.

With the official data and one-line Cache, both traversal orders return `88`. Column-first records 321 total cycles and 16 misses; row-first records 105 cycles and 4 misses. A four-line Cache also lets the unoptimized column-first program reach 105 cycles, but records hardware cost 13 instead of 4.

## Test

The repository has addon-free headless simulation and UI tests for both slices:

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-simulation.log' --script res://tests/test_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-ui.log' --script res://tests/test_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-circuit-simulation.log' --script res://tests/test_circuit_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-hardware-foundations-ui.log' --script res://tests/test_hardware_foundations_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-content-registry.log' --script res://tests/test_content_registry.gd
& $godotConsole --headless --path . --log-file '.godot/test-prologue-simulation.log' --script res://tests/test_prologue_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-hardware-prologue-ui.log' --script res://tests/test_hardware_prologue_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-localization.log' --script res://tests/test_localization.gd
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
```

See [testing details](docs/development/testing.md) for verified outcomes and environment notes.

## Repository guide

- [Architecture](ARCHITECTURE.md)
- [Content and player-design extension contract](docs/architecture/content-system.md)
- [Design principles](docs/design/core-principles.md)
- [CPU Building Prologue status and limitations](docs/status/cpu-building-prologue.md)
- [Historical Hardware Foundations 01 milestone](docs/status/hardware-foundations-01.md)
- [Current v0.2 status and limitations](docs/status/prototype-v0.2.md)
- [Preserved v0.1 status](docs/status/prototype-v0.1.md)
- [Development documentation](docs/README.md)
- [Execution-plan policy](PLANS.md)

The vision is to make performance reasoning tangible through visible, explainable data flow. The shape of a complete game, its progression, and its final presentation remain open design work; this repository does not treat prototype choices as permanent product commitments.
