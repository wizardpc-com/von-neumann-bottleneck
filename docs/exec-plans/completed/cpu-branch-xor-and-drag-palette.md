# CPU branch, XOR, and drag palette

## Goal

Correct the prologue progression so Half Adder belongs to the CPU/arithmetic line rather than gating storage, add a real XOR primitive for later arithmetic construction, and make every editable level expose an explicit, draggable component supply in a movable/minimizable desktop window.

## Scope

- Move the Half Adder descriptor into the arithmetic branch and make the storage branch begin from the completed wiring tutorial.
- Add deterministic one-bit XOR behavior, ports, delay accounting, trace feedback, and a procedural schematic symbol.
- Add explicit per-level component palettes for the currently implemented prologue levels.
- Add a component palette window whose items can be clicked for repeated placement or dragged directly onto the graph.
- Preserve the existing graph-authoritative circuit, editor history, copy/paste, and Test Bench behavior.
- Update focused tests and durable documentation.

## Non-goals

- Do not add new campaign levels, a general component authoring system, persistence, arbitrary word widths, rotation, or a production art pass.
- Do not copy Turing Complete assets, wording, source code, or puzzle solutions.
- Do not change simulation latency based on drag distance or wire geometry.

## Affected subsystems

- `src/content/prologue/`: branch ownership, prerequisites, and declared component supply.
- `src/circuit/`: XOR electrical behavior and deterministic simulation.
- `src/hardware_foundations/`: procedural XOR symbol, palette window, drag/drop placement, and history integration.
- `localization/`: Chinese-default and English alternate UI copy.
- `tests/`: content graph, XOR semantics, palette inventory, and direct drag placement.
- Architecture/status/decision documentation where durable facts change.

## Invariants

- The displayed graph remains the authoritative player topology.
- UI drag/drop changes the graph only through the same atomic placement transaction as click placement.
- Simulation remains deterministic; every basic gate, including XOR, costs one tick.
- Ordinary wires and junctions remain zero latency.
- Storage progression does not depend on Half Adder completion or replacement.
- Locked demonstration topology does not accept palette placement.

## Implementation steps

1. Correct content branch ownership and prerequisite edges; update registry tests.
2. Implement and test XOR across logic specification, analyzers/simulators, metrics, and procedural presentation.
3. Add explicit per-level palette definitions without creating a second hidden topology.
4. Add a movable/minimizable palette window, procedural palette items, and graph drop handling that reuses atomic placement.
5. Update localization and durable architecture/status documentation.
6. Run all relevant headless suites, startup smokes, diff checks, and inspect final status.

## Decisions and rationale

- The wiring tutorial is the shared root. Half Adder starts the arithmetic/CPU branch; SR Latch starts the independent storage branch.
- XOR is a primitive unlocked by being offered only in later arithmetic palettes. Half Adder itself must still be built from earlier gates.
- Each level declares its palette explicitly. Reference components and reference wires remain deterministic test/capture evidence, while the palette controls player supply.
- The old menu remains as a compact alternative, but the floating palette is the primary discoverable interaction and supports direct drag/drop.

## Progress

- 2026-08-19: committed the preceding visual/animation baseline as `94958a9`.
- 2026-08-19: inspected repository plans, progression/content packs, existing placement code, tests, and public Turing Complete component/control references; created this plan before implementation.
- 2026-08-19: moved Half Adder into the arithmetic branch, made Tutorial the independent prerequisite for SR Latch, and updated transitive invalidation coverage.
- 2026-08-19: added the deterministic one-bit XOR primitive, one-tick base-circuit accounting, tri-state-aware prologue evaluation, and a distinct procedural XOR symbol.
- 2026-08-19: added explicit palettes for every editable prologue level plus a movable/minimizable Components window. Palette drag/drop and click-to-repeat placement share the same snapped authoritative history transaction.
- 2026-08-19: adjusted challenge zoom defaults so the initial palette does not hide important terminals, updated both locales and durable architecture/status records, and added ADR 0014.

## Verification

- All eight headless suites exited `0`: simulation, locality UI, circuit simulation, Hardware Foundations UI, prologue simulation, content registry, prologue UI, and localization.
- Default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality startup smokes exited `0`.
- Focused coverage proves XOR truth tables/determinism, branch ownership/unlocks/invalidation, exact per-level palette contents, direct palette drop, click placement, snapping, and undo.
- Fresh 1600×900 tutorial and CPU captures were inspected. The palette tiles use procedural silhouettes, the windows remain movable/minimizable, and the automatically zoomed layouts keep important terminals visible.
- Current final-log scanning found no script/parse error, failed assertion, locked-object error, invalid content, RID leak, or ObjectDB leak. `git diff --check` passed.
- Godot still prints the known non-fatal Windows root-certificate-store warning. The editor import scan also cannot persist global editor settings outside the workspace, but it registered the new script class and generated its UID successfully.

## Limitations and follow-up

- The component palette is level-local and session-only; there is no persistent custom-category library or cross-level clipboard persistence.
- Palette items use compact procedural summaries. There is no production icon/art pass or rotated component support.
- Reference inventories remain available to deterministic tests/capture hooks; normal player success still comes only from the visible graph.
