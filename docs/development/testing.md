# Testing

## Verified environment

- Windows PowerShell
- Godot `4.7.1.stable.official.a13da4feb`
- Console executable: `godot_console`

The commands below were run successfully from the repository root after the directory migration.

## Simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-simulation.log' --script res://tests/test_simulation.gd
```

Expected success output:

```text
PASS: Python-shaped DSL, deterministic simulation, route, and cache-goal tests passed
```

## UI integration tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-ui.log' --script res://tests/test_ui.gd
```

Expected success output:

```text
PASS: staged animation, floating instruments, explicit Program apply/explanation/strategies, Profiler, and Cache tradeoff tests passed
```

This suite also verifies the resizable-fullscreen project boundary, aspect-ratio expansion, the shared visible fullscreen action on the hub and Cache Locality Lab, and complete on-screen fitting of oversized/misplaced floating instruments. Hardware Foundations UI coverage checks the same fullscreen action and fitting contract for Mission, Test Bench, and Components pages.

## Circuit simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-circuit-simulation.log' --script res://tests/test_circuit_simulation.gd
```

Expected success output:

```text
PASS: deterministic default-low tri-state circuit, multi-driver wiring, Half Adder, and encapsulation tests passed
```

## Hardware Foundations UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-hardware-foundations-ui.log' --script res://tests/test_hardware_foundations_ui.gd
```

Expected success output:

```text
PASS: global test mode, compact NOT, whole-symbol selection, graphical map, wiring, and Hardware UI tests passed
```

This suite also starts from the registry-derived central dependency map, verifies its branch/merge geometry and locked/unlocked/replayable states, and proves that editor/layout/Trace controls plus Test Bench and Components reopen actions are absent on the map. Real pointer input drags, scrolls, minimizes, closes, and reopens the Mission panel above the full-rect map; its reserved lane intersects no level node. The map header keeps the explicit chapter-selection action, while entering a playable level restores the circuit toolbar. The suite rejects a Half Adder prerequisite bypass, completes the five tutorial interactions, and proves that the tutorial independently unlocks Half Adder and SR Latch. It checks that a fresh unwired Half Adder is neutral rather than a simulator error and that XOR is absent until later arithmetic levels. It covers the shorter `not`, distinct XOR/input/output silhouettes, progressive value-colored component strokes with neutral bodies, whole-symbol selection with unchanged live port colors, compact visual ports with unchanged hit behavior, one player-colored full-path settled-wire renderer, color undo/redo and branch inheritance, causal input-change waves, the explicit level palette, direct palette drag/drop, a low-opacity truthful component ghost at the exact snap position, repeated authoritative placement, and cancellation by right click, existing-content interaction, palette replacement, and Escape. It also covers exact valid/invalid port guides, exact-path wire hover, ordinary replacement marquee selection, Shift toggle selection, placement/cut undo and redo, `Ctrl+A/X`, WASD navigation, and double-click component-plus-route-node selection. Tutorial completion verifies the localized learning summary, one presentation cue request, and Continue returning to the map. It switches to Test mode, proves that all nine valid registered levels are enterable, directly opens LOAD/STORE using the isolated helper library, then returns to the byte-identical Game-mode player-content signature. Map/tutorial transitions emit the real `Button.pressed` signals and verify that outgoing controls are released after the signal completes, covering Godot's locked-emitter lifetime rule.

Transform coverage also verifies that settled cables and Trace endpoints remain attached after non-unit zoom, pan, and component movement, and that placing a component preserves the preview symbol's exact geometry without a vertical jump.

The same suite verifies versioned workbench snapshots in memory and on disk: automatic `default`, Unicode naming, per-level/per-mode isolation, independent topology/positions, autosave/reload, and the explicit absence of an operation-history field. UI coverage switches between two tutorial workbenches, enters all three read-only hint stages, returns to the byte-identical player snapshot, and proves that the level-3 Half Adder topology genuinely passes the official truth table without granting player completion.

## CPU prologue simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-prologue-simulation.log' --script res://tests/test_prologue_simulation.gd
```

Expected success output:

```text
PASS: deterministic reusable-component, latch, register, RAM, and tiny-computer prologue tests passed
```

This suite covers the complete tutorial branch-root contract, port-width errors, zero-latency multi-junction networks, deterministic XOR/Full Adder/ALU/latch/register/RAM/CPU behavior, explicit write/hold state-boundary events, parallel RAM-cell commits, every official case or sequence, invalid alternatives, sealed-component behavior, generated-wrapper provenance, and dependency contracts.

## Campaign content registry tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-content-registry.log' --script res://tests/test_content_registry.gd
```

Expected success output:

```text
PASS: deterministic campaign registry, synthetic content extension, and validation tests passed
```

This suite validates the built-in campaign manifest, including Half Adder's CPU/arithmetic ownership, Tutorial-to-Latch independence, and selective downstream invalidation. It proves that a synthetic branch, prerequisite chain, localized level metadata, builder, and reusable reward can be registered without changing campaign UI code. It also rejects duplicate IDs, unknown branches/dependencies, dependency cycles, and ambiguous reward ownership.

## CPU prologue progression/UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-hardware-prologue-ui.log' --script res://tests/test_hardware_prologue_ui.gd
```

Expected success output:

```text
PASS: two-branch prologue progression, player-owned sealing, word wrappers, CPU construction, and LOAD/STORE UI tests passed
```

This suite starts each player challenge unwired, verifies the exact explicit suitable-component palette for every editable level, applies a valid visible topology through the same connection request path, runs its official Test Bench, seals it, and traverses both branches through the final bridge. It proves that XOR appears in the post-Half-Adder arithmetic levels and that the locked bridge rejects placement. It also checks topology-bound evidence, selective downstream invalidation, event-driven live analysis, storage preview/commit/reset UI, before/after state rows, parallel RAM-cell feedback aligned to displayed nodes after zoom/scroll, function-specific register/RAM/ALU/control surfaces, a known-address cursor on the truthful two-row RAM grid, Q-only latch state output, parallel CPU component waves, and four-bit pulses on exact rendered curves.

Before solving each later level, this suite checks that stage 2 loads the explicitly curated key subcircuit, every hint component is non-draggable, stage 3 has the same canonical signature as the registered complete reference circuit, and leaving hints restores the byte-identical player workbench with an empty history. The same contract is checked for the locked LOAD/STORE bridge. Every sealing or final-bridge completion also verifies the matching localized summary overlay.

## Chapter 1 system simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-system-lab-simulation.log' --script res://tests/test_system_lab_simulation.gd
```

Expected success output:

```text
PASS: deterministic 8-bit system chapter simulation, topology, DSL, and bottleneck tests passed
```

This suite verifies all six catalog entries, the bounded parser, exact typed topology, 8-bit wrapping, exact CPU/RAM/Bus cycle formulas, Bus2/4/8 serialization, repeat signatures, every bottleneck category, immutable aggregate receipts, fixed-test binding, and controlled comparisons that reject changes to non-compared hardware.

## Chapter 1 progression/UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-system-lab-ui.log' --script res://tests/test_system_lab_ui.gd
```

Expected success output:

```text
PASS: six-level system chapter map, applied program, typed wiring, floating tools, evidence progression, exact-path animation, and diagnosis tests passed
```

This suite runs the full six-level Test-mode route through normal Apply/Test Bench/part-selection/diagnosis boundaries. It verifies hub/prologue gates, isolated provenance/progression, map nodes, six visible routes, draft blocking, component movement without timing change, exact cable and active-Trace routes after non-unit zoom, pan, and component movement, CPU WAIT feedback, coexisting/minimizable windows, progressive receipts, workload scale, and final diagnosis. Each first completion must present the matching localized lesson summary; the final Continue action returns to the chapter map.

## Project startup smoke check

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
& $godotConsole --headless --path . --log-file '.godot/project-test-mode-smoke.log' --quit-after 5 -- --test-mode
```

Success is exit code `0` with no project parse/runtime error before the automatic quit.

## Localization boundary tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-localization.log' --script res://tests/test_localization.gd
```

Expected success output:

```text
PASS: Chinese default, English catalog, key coverage, and locale-independent simulation tests passed
```

This suite checks every semantic localization key referenced by the current playable UI in both registered catalogs. It also proves that changing locale does not change the canonical locality or circuit trace.

## Visual playback check

The project exposes deterministic capture hooks for local visual QA:

```powershell
$godotConsole = 'godot_console'
& $godotConsole --path . --log-file '.godot/v02-capture.log' --write-movie '.godot/v02-demo.png' --fixed-fps 30 --quit-after 45 -- --capture-demo
& $godotConsole --path . --log-file '.godot/v02-profiler.log' --write-movie '.godot/v02-profiler.png' --fixed-fps 30 --quit-after 2 -- --capture-profiler
& $godotConsole --path . --log-file '.godot/v02-workspace.log' --write-movie '.godot/v02-workspace.png' --fixed-fps 30 --quit-after 2 -- --capture-workspace
& $godotConsole --path . --log-file '.godot/program-draft.log' --write-movie '.godot/program-draft.png' --fixed-fps 30 --quit-after 2 -- --capture-program-draft
& $godotConsole --path . --log-file '.godot/hardware-schematic.log' --write-movie '.godot/hardware-schematic.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-schematic-signal
& $godotConsole --path . --log-file '.godot/component-processing.log' --write-movie '.godot/component-processing.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-component-processing
& $godotConsole --path . --log-file '.godot/component-placement.log' --write-movie '.godot/component-placement.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-component-placement
& $godotConsole --path . --log-file '.godot/level-completion.log' --write-movie '.godot/level-completion.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-level-completion
& $godotConsole --path . --log-file '.godot/level-completion-audio.log' --write-movie '.godot/level-completion-audio.png' --fixed-fps 30 --quit-after 40 -- --capture-hardware --capture-level-completion --capture-completion-audio
& $godotConsole --path . --log-file '.godot/wiring-guides.log' --write-movie '.godot/wiring-guides.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-wiring-guides
& $godotConsole --path . --log-file '.godot/selection-highlight.log' --write-movie '.godot/selection-highlight.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-selection-highlight
& $godotConsole --path . --log-file '.godot/test-mode-map.log' --write-movie '.godot/test-mode-map.png' --fixed-fps 30 --quit-after 5 -- --test-mode --capture-hardware
& $godotConsole --path . --log-file '.godot/prologue-map.log' --write-movie '.godot/prologue-map.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-prologue-map
& $godotConsole --path . --log-file '.godot/prologue-storage.log' --write-movie '.godot/prologue-storage.png' --fixed-fps 30 --quit-after 4 -- --capture-hardware --capture-prologue-storage
& $godotConsole --path . --log-file '.godot/prologue-cpu.log' --write-movie '.godot/prologue-cpu.png' --fixed-fps 30 --quit-after 4 -- --capture-hardware --capture-prologue-cpu
& $godotConsole --path . --log-file '.godot/workbench-hint.log' --write-movie '.godot/workbench-hint.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-workbench-hint
& $godotConsole --path . --log-file '.godot/workbench-create.log' --write-movie '.godot/workbench-create.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-workbench-create
& $godotConsole --path . --log-file '.godot/system-map.log' --write-movie '.godot/system-map.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-system-map
& $godotConsole --path . --log-file '.godot/system-workspace.log' --write-movie '.godot/system-workspace.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-system
& $godotConsole --path . --log-file '.godot/system-run.log' --write-movie '.godot/system-run.png' --fixed-fps 30 --quit-after 7 -- --test-mode --capture-system-run
```

Inspect consecutive PNG frames for single-component activation in the locality lab, parallel equal-wave activation in Hardware Foundations, a growing state stroke rather than a point or pre-lit future components, exact wire travel, RAM/Bus/Cache staging, contained side-by-side instruments, and a row-first draft that visibly requires Apply. Device processing must stay inside the actual card with no orbit or radial indicator. The Hardware schematic hook produces an `A=1 → NOT=0 → LAMP=0` settled frame for checking neutral component drawings, directional level-input geometry, lowercase English gate names, compact red/green/gray ports, player-hued bright/dim cables, and one heavy exact-path cable rather than two stacked full paths. The component-processing hook freezes NOT midway: the high input stroke must enter the real triangle, the body route uses cyan, the low output stroke is queued at the inversion bubble, and no dot, second NOT model, full cable, or halo may appear. The component-placement hook arms the first allowed gate without committing it and shows a low-opacity copy of that exact symbol at the snapped pointer position; confirm that there is no substitute card/bounding box and that the toolbar still fits at 1600×900. The completion hook shows the localized lesson modal and Continue action; the longer opt-in audio capture lets the actual procedural cue finish and should exit without an audio/RID/Object leak. The wiring-guides hook freezes a drag from A: verify the cyan source, green rings only around exact compatible inputs, the larger hovered-target halo, unchanged inner live-value colors, and a visible player-hued draft cable despite the hidden native stroke. The selection hook selects the compact `not`: its complete triangle, inversion bubble, leads, and label must be cyan with no circular selection backdrop, while the input/output ports remain red/green. The normal map hook exposes real clickable nodes on a visible arithmetic/storage fork and CPU merge; the Test-mode map must show all nine nodes enterable plus the explicit warning and temporary library. Confirm that bottom explanations fit, the Test Bench is absent, and Mission remains fully operable in its dedicated left lane without covering a node. The storage hook solves RAM, rewinds its playback monitor to the pre-write `M0=0x0`/`M1=0x0` state, and freezes the first parallel Register4 write/hold boundary on the real Register4 modules; completing playback restores the official final `M0=0x5`/`M1=0xC` state. The CPU hook must show distinct control fan-out, register latch, notched ALU, mux wedge, and two-word RAM grid surfaces; a RAM processing event highlights its known addressed row. The system-run hook must show one badge on a player-colored connection segment without drawing a capsule or a straight bridge through Bus. `--capture-row` applies and starts an Official row-first playback when comparing both valid software/hardware solutions.

The workbench-hint hook freezes tutorial hint stage 2. Confirm that the top-right control clearly shows hint progression and Return, the Mission window explains the read-only scope, only the key `A → NOT → LAMP` graph is visible, Test Bench/Components windows stay hidden, and the toolbar does not overflow at 1600×900. An ordinary component-placement capture should also show the compact `Workbench: default` selector and Hint button without covering the circuit.

The system-map hook shows the complete six-node zig-zag route and its prerequisite state. The system-workspace hook opens Program and Profiler together to check draggable-window containment, applied-source state, line explanations, and progressive metric labels. The system-run hook freezes a Bus2 read packet: verify one settled green cable, an `0xNN 3/4` packet exactly on that cable, CPU `WAIT`, Bus `TRANSFER`, and the addressed RAM row, with no detached component model or second full wire.

## Verified evidence

On 2026-08-17, all five simulation/UI/localization commands above completed freshly with exit code `0` and printed their expected success lines. The project-hub startup smoke, a direct Hardware Foundations scene smoke, an English-locale startup, and the hub-to-Hardware route smoke also completed with exit code `0`. Catalog inspection found 383 referenced semantic keys and exactly 383 entries in each of the `zh_CN` and `en` catalogs, with no missing, duplicate, unused, or placeholder-mismatched entries. Rendered 1600×900 frames were inspected for the Chinese hub, Hardware Foundations, and locality workspace plus the English hub, as well as compact gate/terminal spacing, a visible movable branch node, restored topology after atomic undo, simultaneous AND/OR processing in one parallel wave, exact-path signals, coexisting floating windows, and the sealed component. Each Godot launch printed `Failed to read the root certificate store` on this Windows environment; it is a pre-existing environment warning and did not change process exit codes or test results.

Later on 2026-08-17, the schematic/free-wiring iteration again ran all five suites with exit code `0`; Hardware UI printed the updated schematic/signal/free-wiring success line. All four startup/direct-scene/English/route smokes also exited `0`. Catalog inspection then found 385 referenced keys and exactly 385 entries in both catalogs, with zero missing, duplicate, unused, or placeholder-mismatched entries. A settled 1600×900 `A=1 → NOT=0 → LAMP=0` frame was inspected for distinct AND/OR/NOT geometry, heavier exact-curve connections, green high, red low, protected Test Bench terminals, and readable Chinese interaction guidance. The same root-certificate environment warning remained the only logged error.

The subsequent signal-color correction reran all five suites and the project startup smoke with exit code `0`. Hardware UI now asserts that input/observer symbols and receiving ports stay neutral, only driven output ports expose red/green state, and full rendered connections retain their source value. A fresh 1600×900 frame confirmed the same separation visually. The Windows root-certificate warning remained non-fatal.

On 2026-08-18, the continuous-erase correction reran all five suites and the project startup smoke with exit code `0`. Hardware UI now covers a single right click, a fast one-motion crossing of a thin wire, a multi-component held-right sweep including external Test Bench terminals, removal of every incident wire, and one Undo restoring the exact pre-stroke component count and canonical topology. A fresh 1600×900 Chinese frame confirmed that the revised tutorial instruction fits without disturbing the frameless schematic. The same Windows root-certificate warning remained non-fatal.

Later on 2026-08-18, the cursor-tip precision correction reran the Hardware Foundations UI suite and project startup smoke with exit code `0`. Hardware UI now additionally proves that touching empty space 10 pixels from a connection center line does not delete it, direct cursor-tip contact does, Undo restores it, and dense path sampling still catches a fast crossing. The same Windows root-certificate warning remained non-fatal.

The tri-state live-analysis iteration then ran all five simulation/UI/localization suites and the project startup smoke freshly with exit code `0`. Circuit simulation covered deterministic low/high/high-impedance propagation, matching and conflicting multi-driver inputs, structural combinational cycles, the official Half Adder table, and sealed behavior. Hardware UI covered red/green/gray input and output ports before Run, lowercase English gate labels, short/cycle diagnostics, same-frame refresh coalescing, and no idle-frame recomputation. A rendered 1600×900 `A=1 → NOT=0 → LAMP=0` frame was inspected: component bodies remained neutral, the source/NOT/lamp ports and exact-path wires carried the expected green/red state, and every unconnected AND/OR port was gray. The pre-existing Windows root-certificate warning remained non-fatal.

Later on 2026-08-18, the default-low/editor-history iteration reran all five simulation/UI/localization suites and the project startup smoke freshly with exit code `0`. Circuit coverage distinguishes a truly unconnected low port from a connected explicit high-impedance source. Hardware UI covers Shift click/rectangle selection, group movement, selected-subgraph copy/paste with fixed Test Bench exclusion, atomic `Ctrl+Z`/`Ctrl+Y` history, the `Ctrl+Shift+Z` redo alias, redo-branch invalidation, and undoable Clear Wires. A rendered 1600×900 Chinese Hardware frame confirmed red/low untouched AND/OR ports, the settled green/red `A=1 → NOT=0 → LAMP=0` route, exact heavy wire paths, and a complete toolbar after adding Redo. The same Windows root-certificate warning remained non-fatal.

The CPU Building Prologue iteration on 2026-08-18 ran all seven simulation/UI/localization suites freshly with exit code `0`: the two preserved locality suites, base circuit suite, Hardware Foundations editor suite, new prologue simulation suite, new two-branch progression/UI suite, and localization suite all printed their expected PASS lines. Default-Chinese project startup, English startup, direct Hardware scene startup, and hub-to-Hardware routing also exited `0`. Static catalog inspection found 476 referenced semantic keys and 477 entries in each catalog, with zero missing keys, duplicates, catalog key-set differences, or Chinese/English placeholder mismatches. Fresh 1600×900 map and CPU frames were inspected for the dependency branches, session component provenance, coexisting desktop panels, word badges, distinct high-level component silhouettes, parallel feedback, and exact red/green connection curves. The CPU layout was then adjusted to place accumulator/ALU and RAM/source-selection flow more legibly; both prologue suites passed again. The Windows root-certificate warning remained the only logged error and no RID/Object leak remained in verbose prologue UI exit output.

The Storage Foundations completion later on 2026-08-18 again ran all seven suites with exit code `0`, including new assertions for visible latch HOLD feedback, explicit register boundaries, parallel RAM-cell write/hold waves, preview/commit/reset UI, chronological state monitoring, and effect alignment after GraphEdit zoom/scroll. Default-Chinese, English, direct-Hardware, and hub-route smokes all exited `0`. Static catalog inspection found 511 referenced semantic keys and 512 entries in each catalog, with zero missing keys, duplicates, catalog key-set differences, or placeholder mismatches; the sole intentionally unreferenced legacy entry remains `circuit.error.wire_endpoint_missing`. A fresh 1600×900 RAM capture was inspected at the first write boundary: both Register4 effects are aligned to their displayed nodes, one writes `0x3` while the other holds `0`, and the committed-state monitor remains at the pre-write `M0=0x0`/`M1=0x0` until the effect completes. The same Windows root-certificate warning remained non-fatal.

The prerequisite-map correction on 2026-08-18 ran all seven suites and the project startup smoke freshly with exit code `0`. Hardware Foundations UI now begins on the map, rejects entering Half Adder before the five tutorial interactions are complete, verifies the visible unlock transition, and treats a fresh unwired Half Adder as a neutral incomplete design. Prologue coverage still traverses both construction branches through CPU and LOAD/STORE. A fresh 1600×900 initial-map frame was inspected with only the wiring tutorial available and all dependent levels visibly locked. The same Windows root-certificate warning remained non-fatal.

The locked-emitter follow-up on 2026-08-18 reproduced `Attempted to free a locked object (calling or emitting)` through real level-map button signals. Container rebuilds now detach outgoing controls and use end-of-frame deletion instead of immediate `free()`. Hardware Foundations UI, prologue progression/UI, localization, and project startup then all exited `0`; log inspection found no locked-object, script-error, RID-leak, or ObjectDB-leak lines. The same Windows root-certificate warning remained non-fatal.

The extensible-content foundation later on 2026-08-18 ran all eight suites, including the new campaign content-registry contract, with exit code `0`. Default-Chinese, English, direct-Hardware, and hub-to-Hardware startup smokes also exited `0`; the registry/prologue/localization and route checks were rerun after final review. The synthetic registry test proves a new branch, level, prerequisite, builder, and reward can join without campaign-UI edits, while invalid IDs/dependencies/cycles/reward ownership fail closed. Both PO catalogs contain 516 unique matching entries with no duplicates or key-set difference. Log inspection found no parse/compile error, locked object, invalid content, RID leak, or ObjectDB leak. The known Windows root-certificate warning remained non-fatal.

The Turing-style component-placement and controls iteration later on 2026-08-18 ran all eight suites and all four default-Chinese/English/direct-Hardware/hub-route startup smokes freshly with exit code `0`. Hardware UI coverage proves that menu placement changes the authoritative circuit, remains armed for repeated use, snaps to the visible grid, and is atomic under undo/redo; it also covers select-all, cut with Test Bench protection, WASD navigation, and connected-route-node double-click selection. Both PO catalogs contain 529 unique matching entries with no duplicates, and the localization suite reports matching key coverage and locale-independent simulation. Final log scanning found no script/parse error, locked-object error, failed assertion, invalid content, RID leak, or ObjectDB leak. A 1600×900 placement capture was inspected for the complete toolbar, frameless gate symbols, and the cyan snapped guide. The known Windows root-certificate warning remained non-fatal.

The graphical-map and editor-affordance iteration later on 2026-08-18 again ran all eight suites and all four default-Chinese/English/direct-Hardware/hub-route startup smokes freshly with exit code `0`. Hardware UI coverage proves registry-derived map topology/state, exact valid/invalid target discovery, exact-path wire hover, replacement marquee selection, Shift toggle selection, and unchanged live port colors during guide rendering; prologue UI independently confirms that both post-Half-Adder branches unlock while CPU stays locked. Both PO catalogs contain 539 unique matching entries with zero duplicates or key-set difference. Fourteen current test/capture logs contained no unexpected error pattern, all local Markdown links resolved, and `git diff --check` passed. Fresh 1600×900 map and wiring-guide frames were inspected; the known Windows root-certificate warning remained non-fatal.

The global Game/Test-mode and selection-clarity iteration later on 2026-08-18 ran all eight suites and six default-Chinese/English/direct-Hardware/hub-route/Test-hub/Test-route startup smokes freshly with exit code `0`. Hardware UI proves actual selector-driven mode changes, all nine valid levels enterable, unknown IDs still rejected, final LOAD/STORE instantiation through isolated helper definitions, zero fabricated completion, and exact Game-state restoration after switching back. It also verifies the shorter `not`, complete-symbol selection color, and unchanged live port colors. Both PO catalogs contain 546 unique matching entries with zero duplicates or key-set difference. Thirty-six current final test/capture logs contained no unexpected error pattern; all local Markdown links and `git diff --check` passed. Fresh 1600×900 Game-mode selection, Test-mode hub/map, and locality-header frames were inspected. The known Windows root-certificate warning remained non-fatal.

The component-aligned animation correction on 2026-08-19 ran all eight suites plus default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality startup smokes freshly with exit code `0`. Hardware UI now proves that component waves animate the actual NOT/AND/OR symbols while the shared overlay remains wire-only; prologue UI proves parallel RAM state boundaries highlight the real Register4 row surfaces after GraphEdit transforms; locality UI proves each processing point stays inside the displayed device rect, internal Cache events use a short lane, and no generic radial indicator exists. Fresh 1600×900 NOT, RAM, CPU, and 20-frame locality captures were inspected: no substitute component model, halo, or circular orbit remained. Final logs contained only the known non-fatal Windows root-certificate warning; local Markdown links and `git diff --check` passed.

The functional-shape, pin-animation, and single-wire follow-up on 2026-08-19 ran all eight suites together in the final source state with exit code `0`. Default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality smokes all exited `0`. New coverage verifies directional input/output silhouettes, value-colored NOT input/output tokens, function-specific register/RAM/ALU/control surfaces, a known-address RAM cursor, Q-only latch state output, and the absence of a duplicate full-path signal layer. Fresh settled/tutorial-processing, storage, and CPU frames were inspected: cables are single centered curves, terminals remain neutral, and high-level diagrams stay on their real nodes. Final log scanning found only the known non-fatal Windows root-certificate warning; local Markdown links and `git diff --check` passed.

The independent-branch, XOR, and draggable-palette iteration on 2026-08-19 ran all eight suites freshly with exit code `0`, followed by default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality startup smokes with exit code `0`. Circuit/prologue coverage verifies deterministic XOR truth tables and gate accounting; registry/UI coverage verifies that Tutorial independently unlocks Half Adder and SR Latch, Half Adder belongs to the CPU/arithmetic branch, replacing it cannot invalidate storage, every editable level exposes its exact explicit suitable-component set, and post-Half-Adder arithmetic palettes include XOR. Hardware UI verifies direct palette drop and click-to-repeat placement share authoritative snapped history. Fresh 1600×900 tutorial and CPU frames were inspected: the movable/minimizable Components window shows procedural tiles, leaves the automatic circuit layout readable, and its CPU scroll area exposes the bounded level supply. Final logs contained no script/parse error, failed assertion, locked-object error, invalid content, RID leak, or ObjectDB leak; `git diff --check` passed. The known Windows root-certificate warning remained non-fatal.

The named-workbench and progressive-hint iteration on 2026-08-19 again ran all eight suites freshly with exit code `0`, followed by the default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality smokes with exit code `0`. Model/UI coverage verifies automatic `default`, Unicode naming, clean independent workbenches, per-level/per-mode isolation, component/position/wire disk round-trips, empty history after switching, and preservation of an unknown future schema without overwrite. Every current prologue level now verifies an authored stage-2 subgraph, a read-only stage-3 reference graph, and byte-identical restoration of the player's workbench; the complete Half Adder hint passes the real official truth table without granting completion. Fresh 1600×900 frames were inspected for the ordinary selector, the uncluttered hint board, and the compact centered name modal. Fresh command output contained no script/parse failure or locked-object error; the known non-fatal Windows root-certificate warning was the only reported engine error. `git diff --check` passed.

The fullscreen/responsive-desktop iteration on 2026-08-19 ran all eight suites freshly with exit code `0`, followed by the default hub, Test-mode hub, direct Hardware Foundations, and direct Cache Locality startup smokes with exit code `0`. Coverage verifies default resizable fullscreen, `expand` aspect handling, visible fullscreen controls on all three entry screens, deterministic windowed capture behavior, and complete clamping of floating pages after oversize/off-screen placement. Fresh 1600×900 and 1920×1200 frames were inspected for the hub, Hardware Foundations, and Cache Locality Lab; the taller layout gives pages additional usable height without clipping, overflow, or forced mutual exclusion. Final log scanning found only the known non-fatal Windows root-certificate warning; `git diff --check` passed.

The Chapter 1 / Waiting for Data iteration on 2026-08-19 ran all ten suites in the final source state with exit code `0`: locality simulation/UI, circuit simulation/editor UI, prologue simulation/content/progression UI, system-lab simulation/UI, and localization. Default Game mode, Test mode, English locale, the direct system scene, and the hub-to-system route then all completed fresh startup smokes with exit code `0`. Fresh 1600×900 system-map, system-workspace, and active Bus2-read frames were inspected for the six-node prerequisite path, coexisting draggable tools, exact displayed-curve packet travel, CPU `WAIT`, Bus `TRANSFER`, and addressed RAM-row feedback. Final clean-environment runs contained no script, parse, assertion, locked-object, RID, or ObjectDB errors; restricted runs can still print non-product Windows certificate/user-directory environment warnings. The chapter intentionally remains session-local and its sequential one-request timing model does not include Cache, overlap, queues, or physical wire delay.

The placement/map/completion-flow iteration later on 2026-08-19 again ran all ten suites in the final source state with exit code `0`. Default Game mode, Test mode, English locale, direct Hardware Foundations, and direct Chapter 1 startup smokes also exited `0`. Hardware UI coverage verifies the truthful low-opacity snapped component preview, repeated placement, cancellation boundaries, the map's absent Test Bench, non-overlapping operable Mission panel, tutorial completion summary, cue request, and Continue-to-map action. Prologue and system UI coverage verifies the level-specific summary for every remaining Hardware and Chapter 1 completion path. Fresh 1600×900 placement, map, and completion frames were inspected, and a 40-frame opt-in audio capture completed without RID/ObjectDB leaks. Final logs contained no script, parse, assertion, locked-object, RID, or ObjectDB errors; the known non-fatal Windows root-certificate warning remained the only engine error.

The compact-port, causal-data-flow, and player-wire-color iteration later on 2026-08-19 ran all ten suites freshly with exit code `0`, then passed default, Test-mode, direct Hardware Foundations, and direct Chapter 1 startup smokes. Hardware UI coverage verifies a 12-pixel disk inside the unchanged 24-pixel port canvas, one heavy full-path cable, presentation-only color undo/redo and branch inheritance, plus automatic source-wire → gate → destination-wire causal updates after an input change. System UI verifies saved segment colors, whole request/write/read-lane coloring, custom path hit testing, and reverse read routes below rather than through device surfaces. Fresh 1600×900 frames were inspected for the Hardware growing component/cable stroke and the Chapter 1 exact-route `0x03 3/4` badge; neither contains a detached transfer point, duplicate cable, or overlay bridge across a device. `git diff --check` passed after the runtime work. The known Windows root-certificate warning remained non-fatal.

## What to run after changes

- Simulation/DSL/cost/trace changes: simulation test, UI test, and smoke check.
- Circuit model, Test Bench, or encapsulation changes: circuit simulation test, Hardware Foundations UI test, and smoke check.
- CPU-prologue component/level/state changes: content-registry test, both prologue tests, circuit simulation test, Hardware Foundations UI test, localization test, and smoke check.
- Hardware Foundations wiring/window/animation changes: Hardware Foundations UI test and smoke check; also run the circuit simulation test if trace or topology assumptions changed.
- UI/wiring/profiler/playback changes: UI test and smoke check; also run the simulation test if trace assumptions changed.
- Player-facing copy or localization-boundary changes: localization test, both UI tests, and smoke check; visually inspect the Chinese default and at least one alternate-locale launch.
- Godot resource moves: all three commands plus explicit `res://` and UID reference inspection.
- Documentation-only changes: inspect links, paths, whitespace, and the Git diff; runtime tests are optional unless commands or architecture claims changed.

## CI status

There is intentionally no GitHub Actions workflow yet. Local commands are reliable, but exact Godot 4.7.1 provisioning on the selected GitHub runner has not been validated in this repository. Add CI only after the runner installation method is reproducible and the same commands have passed there once; do not configure a required status check before that job exists.
