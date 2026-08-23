# Von Neumann Bottleneck

> Early prototype: the repository is an engineering and gameplay experiment, not a production-ready game or stable public release.

Von Neumann Bottleneck is a systems puzzle game about constructing computing abstractions and making their behavior visible. The project currently contains three connected playable slices, selected from a startup hub:

- **CPU Building Prologue:** learn direct wiring, then choose between an arithmetic/CPU line that starts with a 1-bit Half Adder and an independent storage line that starts with an SR latch. Join the resulting ALU and RAM in a four-bit accumulator computer and finish with a visible LOAD/STORE program.
- **Chapter 1 — Waiting for Data:** connect the player's generated CPU8, RAM64x8, and an 8-bit Bus, then follow five prerequisite-gated investigations from prediction through controlled experiment, Trace/Profiler explanation, and bottleneck diagnosis.
- **Chapter 2 — Reducing Data Movement:** follow seven short investigations from repeated distant reads through Cache, Locality, Working Set, Blocking/Tiling, and a diagnosis-first multi-solution capstone.

These slices are not a complete game. They test successive gameplay hypotheses while sharing deterministic simulation and trace-first presentation principles.

The playable interface defaults to Simplified Chinese. An English catalog is retained as the first alternate locale; launch with `--language en` (or pass `-- --locale=en`) to inspect it. DSL keywords, source code, addresses, port names, and stable component IDs remain language-neutral technical evidence.

Every screen exposes a shared **Game mode / Test mode** selector. Game mode is the default and follows normal progression. Test mode unlocks every current campaign level and supplies an isolated temporary component library so late levels can actually open; switching back restores Game-mode progress unchanged. Launch directly in Test mode with `-- --test-mode`. Mode and progress remain session-local, while named per-level workbench topology is saved locally in isolated Game/Test namespaces.

## Engine

- Godot 4.7.1 stable
- Strongly typed GDScript
- Built-in Godot UI and graph controls; no external addons

## Run

Open this repository in Godot 4.7.1 stable and run the project, or from PowerShell:

```powershell
& 'godot' --path .
```

The game starts in fullscreen and expands the 1600×900 design desktop to the monitor's complete aspect ratio. Use the visible **Fullscreen / Exit fullscreen** button, `F11`, or `Alt+Enter` to switch modes. Floating Mission, Test Bench, Components, Program, Profiler, and Cache windows scale with the available desktop and are kept fully on-screen after a resolution or mode change.

Suggested Hardware Foundations path:

1. Open **CPU Building Prologue** from the hub. The central graphical map shows the whole prerequisite tree: cyan nodes are currently available, green nodes are completed/replayable, and gray nodes remain locked. The map omits the Test Bench and reserves a clear left lane for the movable, focusable, minimizable, and closable **Mission** window, so neither instrument covers a level node. Completing the wiring tutorial independently opens Half Adder on the CPU/arithmetic lane and SR Latch on the storage lane; both finished lanes merge at the CPU.
2. In the tutorial, drag a gate from the movable/minimizable **Components** window directly onto the desktop, or click a palette item to arm placement. A low-opacity preview of that actual component follows the pointer at the exact snapped position; left-click repeatedly places copies and keeps the tool armed. Right-click, interacting with an existing component/port/wire, or selecting a different palette item ends or changes the current placement tool; right-click cancellation does not also erase the circuit. Left-drag a component body to move it or a compact colored port to draw a wire; its hit target remains deliberately larger than the visible disk. An unconnected port defaults to red/low (`0`); green is high (`1`), while gray is an explicit high-impedance or unresolved state. Hold the right mouse button and sweep the cursor tip directly across wires or any component to erase everything touched in one undoable stroke; nearby empty space is safe. Hold `Shift` and left-drag a connected input port when intentionally moving an existing wire end.
3. After the five tutorial interactions unlock it, build a Half Adder with the schematic `and`, `or`, and compact single-input `not` symbols. During wiring, cyan marks the chosen source, green outer rings mark exact compatible targets, red marks an invalid hovered target, and the inner red/green/gray port color continues to show the live electrical value. Rendered wires receive an exact-path hover highlight before editing. Use `1`–`9` to choose a cable hue, then hover a wire and press `Ctrl+F` for that segment, `Ctrl+E` for its connected electrical net, or `Ctrl+R` to sample its hue. Cable colors are saved with the workbench but never change simulation. A fresh unwired challenge is explicitly presented as incomplete, not faulty. Ordinary empty-canvas drag replaces the current selection; selected components recolor their complete symbol and leads instead of gaining a separate circle. `Shift`-click or `Shift`-drag toggles items, and double-click includes the explicit wire nodes connected to a component. `Ctrl+A` selects all, `Ctrl+X` cuts, `Ctrl+Z` undoes, `Ctrl+Y` or `Ctrl+Shift+Z` redoes, and `Ctrl+C`/`Ctrl+V` copies/pastes the selected player subgraph. Test Bench terminals are neither copied nor cut. WASD pans the view, the wheel zooms, and middle-drag pans directly. Ports, empty-space wire nodes, and existing segments can all start or extend a route; the same port may accept multiple distinct segments. Equal active drivers are legal, opposite `0`/`1` drivers report a short circuit, and same-tick feedback reports a circular dependency.
4. Use the movable/minimizable **Mission** and **Test Bench** windows like desktop panels. Debug individual A/B cases, then run the four Official truth-table cases.
5. Use **Workbench: default** to keep independent named solutions. A new workbench starts from the level's clean inventory; switching restores components, positions, route nodes, and wires but intentionally starts with an empty undo history. Use the top-right **Hint** button for conceptual, key-subcircuit, then complete-reference read-only boards; **Return to my workbench** restores the active player design.
6. After a fresh four-case pass, seal the unchanged topology as `HalfAdder`. This unlocks the XOR primitive and later arithmetic construction (`FullAdder` → `ALU1` → generated `ALU4`). The independent storage route remains `SRLatch` → `Register1` → generated `Register4` → `RAM2x4`.
7. Build the unlocked four-bit accumulator CPU from those verified abstractions, seal it as `TinyComputer`, then run the fixed LOAD/STORE bridge. Every construction challenge starts unwired; the final bridge deliberately reuses the already verified computer instead of asking for the same wiring again. The first completion of every level opens a localized summary of what the player established, plays a short placeholder completion cue, and offers **Continue** back to the graphical map.

The bridge now hands the player's verified source lineage to **Chapter 1 — Waiting for Data**:

1. Connect the six typed request/write/read routes among CPU, Bus, and RAM. Their visible GraphEdit topology is the topology the simulator validates.
2. Edit the bounded Python-shaped program, inspect its line-by-line explanation, then use **Confirm & Apply**. An unapplied draft cannot run. Chapter progression receipts require each level's authored program; custom programs remain available as debug-only experiments.
3. Before the CPU, RAM, and Bus investigations, lock a prediction. Run a baseline, change only the named part, and use the Before → After comparison to inspect total-cycle and CPU-wait deltas.
4. Follow exact-path request/data packets and component-native CPU `WAIT`, Bus transfer, and RAM service feedback. Eco → Fast makes arithmetic four times faster in the CPU investigation, but unchanged waiting limits total-cycle improvement to about 15%.
5. In the final investigation, the authored program and default machine remain fixed until the first diagnosis. Run the fixed 4/16/64 workloads and submit CPU/RAM/Bus/mixed from raw totals, CPU WAIT, growth, and Trace flow. Any first submission reveals the complete CPU/RAM/Bus breakdown, but only the correct diagnosis unlocks the Program and hardware sandbox; cost remains evidence rather than an optimization gate.

The Chapter 1 map has five ordered nodes. Game mode requires the prologue handoff; Test mode exposes all five with isolated provenance and progress. Mission, Parts, Program, Test Bench, Profiler, and Run History are independent movable/resizable/minimizable windows. Completed investigations leave their evidence visible until the player chooses **Review investigation finding**; that action opens the localized lesson summary, short placeholder cue, and **Continue**-to-map handoff.

Chapter 1's final diagnosis unlocks **Chapter 2 — Reducing Data Movement** in Game mode:

1. Observe a Cache-free CPU → Bus → RAM scan and commit an explanation of repeated CPU WAIT; the first level does not reveal Cache terminology.
2. Carry that 257-cycle receipt into the next level as the read-only Before, then run one line of nearby storage. The same row-first program reaches 105 cycles; only after Trace playback and explicit review does the Systems Notebook reveal Cache, Hit, and Miss.
3. Observe a one-line Cache still taking 321 cycles with column-first access, then carry that evidence into the repair level and change only the applied loop order. This separates “having Cache” from actually exploiting Locality without rerunning the same baseline.
4. Run two already-row-first passes. The one-line Cache takes 210 cycles because the four-line Working Set cannot survive between passes.
5. Carry that working-set evidence into the next level, then use the bounded Work Group control to finish both passes one line at a time. The same hardware reaches 138 cycles and reveals Blocking/Tiling without turning the level into a programming exam.
6. In the capstone, run the given 642-cycle baseline before changing anything. Program, Cache, and Work Group remain locked while the player diagnoses repeated far fetches from raw totals, CPU WAIT, request count, Trace, and data flow; both Profiler and Run History withhold hit/miss and traffic breakdowns until that diagnosis. The first experiment then permits one changed lever until its Trace has been observed. A four-line Cache reaches 138 cycles at cost 13, while a one-line Cache plus line-sized blocking reaches the same 138 cycles at cost 4.
7. Use **Next evidence** to move between consequential Trace events or **Finish Trace** after the causal pattern is clear. The comparison view keeps the authored Baseline → Current result visible and retains a cycle-first, cost-tiebroken Personal Best. After passing, keep optimizing or open a Baseline → Best chapter debrief with total, wait, cost, and final-configuration evidence.

The original v0.2 one-pass results remain covered exactly: column-first/one-line is 321 cycles with 16 misses, row-first/one-line is 105 cycles with 4 misses, and column-first/four-line is 105 cycles at the higher hardware cost. See the [Chapter 2 status](docs/status/chapter-2-reducing-data-movement.md) and [v0.2 baseline](docs/status/prototype-v0.2.md).

## Test

The repository has addon-free headless simulation and UI tests for both slices:

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-simulation.log' --script res://tests/test_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-ui.log' --script res://tests/test_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-locality-chapter-ui.log' --script res://tests/test_locality_chapter_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-circuit-simulation.log' --script res://tests/test_circuit_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-hardware-foundations-ui.log' --script res://tests/test_hardware_foundations_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-content-registry.log' --script res://tests/test_content_registry.gd
& $godotConsole --headless --path . --log-file '.godot/test-prologue-simulation.log' --script res://tests/test_prologue_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-hardware-prologue-ui.log' --script res://tests/test_hardware_prologue_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-system-lab-simulation.log' --script res://tests/test_system_lab_simulation.gd
& $godotConsole --headless --path . --log-file '.godot/test-system-lab-ui.log' --script res://tests/test_system_lab_ui.gd
& $godotConsole --headless --path . --log-file '.godot/test-localization.log' --script res://tests/test_localization.gd
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
```

See [testing details](docs/development/testing.md) for verified outcomes and environment notes.

## Repository guide

- [Architecture](ARCHITECTURE.md)
- [Content and player-design extension contract](docs/architecture/content-system.md)
- [Design principles](docs/design/core-principles.md)
- [CPU Building Prologue status and limitations](docs/status/cpu-building-prologue.md)
- [Chapter 1: Waiting for Data status and limitations](docs/status/chapter-1-waiting-for-data.md)
- [Chapter 2: Reducing Data Movement status and limitations](docs/status/chapter-2-reducing-data-movement.md)
- [Historical Hardware Foundations 01 milestone](docs/status/hardware-foundations-01.md)
- [Preserved v0.2 baseline and limitations](docs/status/prototype-v0.2.md)
- [Preserved v0.1 status](docs/status/prototype-v0.1.md)
- [Development documentation](docs/README.md)
- [Execution-plan policy](PLANS.md)

The vision is to make performance reasoning tangible through visible, explainable data flow. The shape of a complete game, its progression, and its final presentation remain open design work; this repository does not treat prototype choices as permanent product commitments.
