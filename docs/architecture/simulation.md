# Simulation architecture

## Hardware Foundations circuit pipeline

1. After any topology or Test Bench input change, the current component catalog and displayed `GraphEdit` connection list are exported into a fresh `LogicCircuit`. Named ports and their one-, two-, or four-bit widths are part of its canonical signature.
2. The tutorial and Half Adder retain `CircuitAnalyzer`/`CircuitSimulator`: every zero-wire input is low, a connected explicit `Z` remains high impedance, active driver conflicts are shorts, and same-tick combinational cycles are errors.
3. Campaign levels use `PrologueSimulator`, which applies the same graph-authority, width, driver, cycle, and zero-wire rules to `DigitalValue` words. It evaluates Full Adder, ALU, mux/decoder/control, latch, register, RAM, and computer contracts without consulting the UI.
4. Basic AND, OR, NOT, and NOR gates add one simulation tick. Ordinary wires and routing junctions add zero ticks; all segments reached through any number of junctions retain one causal wire wave. Physical curve length, anchors, zoom, and component positions never change a result or delay.
5. `evaluate()` settles one combinational/state boundary. `run_sequence()` executes fixed Test Bench steps in order, carrying only explicit runtime state and prior outputs between steps. Input edits use `evaluate()` as preview; only a debug/official `run_sequence()` commits a boundary. Raw feedback is allowed only for the SR-latch challenge; stable `S=R=1`, unresolved oscillation, short circuits, and width mismatches fail deterministically.
6. `Register1`/`Register4` sample `D` when `LOAD=1` at a Test Bench step boundary. `RAM2x4` retains two four-bit words and writes the addressed word when `WE=1`. `TinyComputer` retains accumulator/RAM state and accepts an external opcode, argument, and address for `LOAD_IMM`, `ADD_IMM`, `LOAD_MEM`, and `STORE_MEM`.
7. Each evaluation completes all outputs, state, errors, and typed `PrologueEvent` values before playback. A state commit emits an explicit `state_transition` event even for HOLD/READ with unchanged output; all storage cells at the same boundary share one presentation wave. Presentation-only `visual_step` groups independent ready components and zero-delay net segments into parallel causal waves and is absent from canonical simulation evidence.
8. The UI colors ports from event-driven analysis, not `_process()`. During playback every wire event resolves the exact current `GraphEdit.get_connection_line()` path; moving a component or junction changes only that rendered path.
9. Every level owns a fixed external Test Bench of truth-table cases or temporal steps. Actual values always come from the displayed graph. A complete pass records that exact topology signature; any later topology edit invalidates the evidence.
10. Sealing creates a `ReusableComponent` with named interface, source-level identity, cloned player circuit/signature, and provenance. `PlayerContentState` installs the level's declared reward and any registered generated wrappers; ALU1 and Register1 completion therefore create four-bit wrappers referencing their source signatures because repeating four identical slices is not a new puzzle.
11. Resealing an upstream component with a changed signature follows the validated campaign registry and invalidates only transitive dependent progression and declared library rewards. The independent arithmetic or storage branch remains intact.
12. The final LOAD/STORE level reuses the already sealed `TinyComputer` behind a locked, externally wired Test Bench. It demonstrates data transfer and hands off to the preserved locality slice; it is not another hidden construction success path.

Unused supplied components are legal and every input with zero incoming segments resolves low. Multiple distinct wires may share a port: connected high-impedance drivers remain `Z` and are ignored when resolving active values, equal active values agree, and simultaneous low/high values are a short circuit. Missing external Test Bench stimuli, shorts, illegal cycles/state, incompatible widths, invalid ports, and unsupported components fail deterministically.

## Cache Locality Lab pipeline

1. `DSLParser.parse()` converts editor draft text into a nested, source-line-aware `DSLProgram`, collecting validation errors and supplying address/line explanations without executing it.
2. Apply Program copies a valid draft into `applied_program_source`. Test Bench is disabled while the draft differs and reparses only this applied source before calling `SimulationCore.run()`.
3. `SimulationCore.run()` recursively executes that applied IR against an integer array and selected Cache capacity. There is no independent traversal selector in the core.
4. The core computes result, cycle counters, Cache/RAM metrics, and an ordered list of `SimulationEvent` objects.
5. Each event records its originating source line, device route, and relevant evidence such as array coordinates, address, line base, and returned cache-line values. The completed `SimulationTrace` retains the exact applied source.
6. `src/ui/main.gd` renders metrics immediately and plays those events over time. Playback timing is presentation-only; source highlight, staged component/wire path, component state, and Profiler detail all read the same event.

The current DSL accepts integer initialization, exactly two four-space-indented `for name in range(4):` loops, `name = load(A[i][j])`, `name += name`, `name += load(A[i][j])`, and a final `store(OUT[0], name)`. Tabs, other loop bounds, invalid indentation, and old v0.1 syntax are rejected. It is a purpose-built Python-shaped parser, not a Python interpreter or compiler platform.

## Intended invariants and current status

| invariant | current implementation |
| --- | --- |
| Simulation is deterministic. | Cache replacement, loop ranges, costs, and event order are deterministic; `canonical_signature()` is compared in the simulation test. |
| Ordinary wire latency is zero. | Graph connections gate whether a run is allowed but never add cycles. |
| Transfer cost belongs to components. | Cache lookup, Bus request/line transfer, and RAM access own explicit costs; CPU add and result-store costs are separate compute work. |
| UI/rendering cannot affect simulation. | `SimulationCore` has no UI dependency. UI receives a completed trace and does not call back into the core during playback. |
| Simulation emits trace data and UI plays it back. | Metrics and all events are computed before `current_trace` is assigned to playback. |
| Live circuit feedback shares execution semantics. | `CircuitAnalyzer` is the one electrical-state model used by continuous port colors and `CircuitSimulator`; UI only presents its result. |
| Cache is hardware-managed. | Loads perform lookup, deterministic LRU fill/eviction, and automatic line return; there is no player cache-insertion action. |
| Animation and investigation remain causal. | Route devices, source line, and detail evidence are stored on the same event that contributes the simulated cycles. |

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

Hardware Foundations uses editable graph-authoritative wiring. Each editable level derives a component menu from the unique non-terminal electrical specifications in its declared inventory. Selecting one item arms repeated snapped placement on empty canvas space; every placed instance receives a deterministic ID, enters the same catalog/circuit used by live analysis and official tests, and is one reversible history transaction. Fixed external Test Bench terminals and explicit wire nodes are not menu templates, and locked demonstration levels expose no placement action.

Both output fan-out and multiple distinct segments on one input are allowed; exact duplicate segments and invalid endpoints remain rejected. Electrically, a port with zero segments is low; on a connected port, `Z` contributes no active driven value, matching low or high drivers are legal, and simultaneous low/high drivers produce a blocking short-circuit diagnostic rather than an implicit OR. Ordinary left-drag moves component bodies or draws new connections from available ports, but cannot silently detach a connected sink. During any route gesture the source gets a cyan guide, every exact compatible target gets a green outer ring, and an incompatible hovered target gets a red ring; these guides are separate from the inner red/green/gray live-value color and disappear without changing electrical state. Rendered wires use their exact displayed Bezier path for hover hit testing and feedback. `Shift` + left-drag explicitly moves an existing input end to another port, empty-space endpoint, or existing segment. A player may end a cable from either direction in empty space, drag an existing rendered segment to a port or empty space, and continue from the resulting movable wire nodes. Each branch transaction replaces the original segment with explicit zero-delay trunk/branch segments; crossings do not connect without the visible junction. Holding right mouse creates a continuous eraser stroke: the editor densely samples the complete pointer path but uses only a cursor-tip-sized contact patch, immediately removes every directly touched wire and component including Test Bench terminals, and groups the whole stroke into one undo action.

Ordinary left-drag on empty canvas replacement-selects every component/wire node in the marquee, and an unmodified empty click clears the selection. `Shift`-click and `Shift`-drag toggle items without disturbing the rest; GraphEdit moves a selected group together. Hit priority is deterministic: port, component body, rendered wire, then empty canvas, so selection never steals a wiring gesture. Double-clicking a component selects that body plus the explicit routing nodes connected to its pins, without absorbing the other endpoint components. `Ctrl+A` selects the canvas; `Ctrl+X` cuts selected player hardware while preserving unique Test Bench terminals. `Ctrl+Z`/`Ctrl+Y` (plus `Ctrl+Shift+Z`) replay complete reversible transactions for placement, routes, endpoint edits, cut/deletion, Clear Wires, Auto Layout, paste, and node movement. `Ctrl+C`/`Ctrl+V` uses an in-session structured clipboard containing selected player gates/wire nodes and only segments whose two endpoints are selected. External Test Bench terminals and boundary-crossing wires are excluded. Every placement/paste receives deterministic monotonic IDs and is one undoable action; any new edit after Undo clears the redo branch. WASD changes only `GraphEdit.scroll_offset`; middle drag and the mouse wheel retain their normal pan/zoom behavior.

Circuit trace playback is parallel by causal wave, not serial by event-array position. Inputs or gates ready at the same simulation layer process together; every segment of the same zero-delay junction network travels in the same wire wave; downstream gates remain later. Compact procedural schematic symbols present lowercase English `and`, `or`, and `not` names plus distinct source, observer, and junction geometry without imported art or a visible GraphNode card; the single-input `not` uses a shorter footprint than two-input gates, while the transparent node remains only as the movement and port-hit carrier. Unselected component bodies, labels, and leads keep a fixed neutral color. Selection recolors the complete procedural symbol and leads cyan without drawing a separate circle or changing the port colors. Every input and output port is continuously colored red for low, green for high, or gray for explicit high impedance/unresolved state; a zero-wire input is red. Visible wire segments use the source state. An internal conflict also renders unresolved gray but always carries an explicit short-circuit diagnostic. Component processing uses a separate fixed-color radial effect. These visual effects add no ticks.

Mission and Test Bench are desktop-style embedded windows over a full-width circuit canvas. They coexist, move, resize, minimize, close, focus, and restore through a taskbar. Their geometry has no simulation meaning.

The separate Cache Locality Lab GraphEdit bench contains six programmatically created connections among Program Controller, CPU, Cache, Bus, RAM, Test Bench, and Profiler. Players cannot add or remove wiring in that level. Devices are automatically laid out, may be dragged for readability, and return to canonical positions through Auto Layout. This fixed topology is presentation structure, not a graph-driven simulation network.

For playback, each event becomes a presentation route with explicit component-processing sections and wire sections. Program-issued load/add/store events prepend Program → CPU; every inter-component section is resolved through `GraphEdit.get_connection_line()` at draw time. Reverse traffic uses the same curve in reverse, and a returned cache line progresses through RAM processing → RAM/Bus wire → Bus processing → Bus/Cache wire → Cache processing. Only the component currently containing the packet is strongly highlighted; CPU waiting may remain as muted context. Internal events such as Cache lookup or miss use only an internal processing loop and do not invent wire traffic. These processing loops and display durations add no simulated cycles.

The Program instrument contains a compact Python-shaped reference and two supplied strategies. A strategy button loads an editable draft without applying it. The parsed draft supplies traversal, address preview, and one explanation for each non-blank source line. Apply Program is the only transition to active source; it invalidates stale evidence and unlocks Test Bench. The last-run receipt exposes traversal, cycles, misses, and confirms that the trace source equals the applied source. These previews are UI evidence, not a second execution path.

The current internal PROCESS orbit is deliberately generic prototype presentation. Formal production may dispatch a visual profile per component—CPU decode/ALU, Cache tag lookup/fill, Bus relay, RAM row/burst, Test Bench comparison, and Profiler sampling—while preserving the same processing intervals, exclusive focus, event authority, and zero presentation cost.

Program, Test Bench, Profiler, and Cache are independent embedded floating instruments. They are closed by default, may coexist, move, resize, minimize, and close independently, and remain open during runs or Profiler trace inspection. Their positions do not affect simulation or GraphEdit device routes.

The Official goal—correct result and at most 105 cycles—is evaluated by the Test Bench after simulation. Hardware cost and Run History are UI evidence; they do not change `SimulationCore` behavior.

## Prototype-scale shortcuts

- Hardware Foundations supports the fixed one-/two-/four-bit components needed by this prologue, including a deliberately bounded SR-latch feedback path and step-boundary register/RAM/computer state. It has no general clock, edge waveform, tri-state switch, analog/metastability model, arbitrary width, HDL, or user-authored component schema.
- Reusable components and campaign progress are session-local. Source snapshots/provenance support this fixed hierarchy, but there is no persistence format, arbitrary recursive composition, or cross-session library.
- The four-bit accumulator consumes Test Bench instructions directly; instruction memory/fetch, a program counter, decoding exercises, pipeline, interrupts, and production ISA are not implemented.
- The parser permits only two nested `range(4)` loops for the fixed 4×4 workload.
- The result store targets Test Bench rather than array memory.
- `main.gd` is a large programmatic UI coordinator rather than a mature set of smaller view components.
- The Profiler retains at most eight runs in session memory and does not persist them.
- The event trace is retained in memory and is not a stable external serialization format.

These are documented facts, not invitations for an unrelated refactor.
