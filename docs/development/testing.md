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

This suite also starts from the registry-derived central dependency map, verifies its branch/merge geometry and locked/unlocked/replayable states, rejects a Half Adder prerequisite bypass, completes the five tutorial interactions, verifies the visible unlock transition, and checks that a fresh unwired Half Adder is neutral rather than a simulator error. It covers the shorter `not`, whole-symbol selection with unchanged live port colors, the level-derived component menu, snapped authoritative placement, placement cancellation, exact valid/invalid port guides, exact-path wire hover, ordinary replacement marquee selection, Shift toggle selection, placement/cut undo and redo, `Ctrl+A/X`, WASD navigation, and double-click component-plus-route-node selection. It switches to Test mode, proves that all nine valid registered levels are enterable, directly opens LOAD/STORE using the isolated helper library, then returns to the byte-identical Game-mode player-content signature. Map/tutorial transitions emit the real `Button.pressed` signals and verify that outgoing controls are released after the signal completes, covering Godot's locked-emitter lifetime rule.

## CPU prologue simulation tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-prologue-simulation.log' --script res://tests/test_prologue_simulation.gd
```

Expected success output:

```text
PASS: deterministic reusable-component, latch, register, RAM, and tiny-computer prologue tests passed
```

This suite covers the complete tutorial-to-Half-Adder prerequisite contract, port-width errors, zero-latency multi-junction networks, deterministic Full Adder/ALU/latch/register/RAM/CPU behavior, explicit write/hold state-boundary events, parallel RAM-cell commits, every official case or sequence, invalid alternatives, sealed-component behavior, generated-wrapper provenance, and dependency contracts.

## Campaign content registry tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-content-registry.log' --script res://tests/test_content_registry.gd
```

Expected success output:

```text
PASS: deterministic campaign registry, synthetic content extension, and validation tests passed
```

This suite validates the built-in campaign manifest and proves that a synthetic branch, prerequisite chain, localized level metadata, builder, and reusable reward can be registered without changing campaign UI code. It also rejects duplicate IDs, unknown branches/dependencies, dependency cycles, and ambiguous reward ownership.

## CPU prologue progression/UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-hardware-prologue-ui.log' --script res://tests/test_hardware_prologue_ui.gd
```

Expected success output:

```text
PASS: two-branch prologue progression, player-owned sealing, word wrappers, CPU construction, and LOAD/STORE UI tests passed
```

This suite starts each player challenge unwired, applies a valid visible topology through the same connection request path, runs its official Test Bench, seals it, and traverses both branches through the final bridge. It also checks topology-bound evidence, selective downstream invalidation, event-driven live analysis, storage preview/commit/reset UI, before/after state rows, parallel RAM-cell feedback aligned to displayed nodes after zoom/scroll, parallel CPU component waves, and four-bit pulses on exact rendered curves.

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
& $godotConsole --path . --log-file '.godot/component-placement.log' --write-movie '.godot/component-placement.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-component-placement
& $godotConsole --path . --log-file '.godot/wiring-guides.log' --write-movie '.godot/wiring-guides.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-wiring-guides
& $godotConsole --path . --log-file '.godot/selection-highlight.log' --write-movie '.godot/selection-highlight.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-selection-highlight
& $godotConsole --path . --log-file '.godot/test-mode-map.log' --write-movie '.godot/test-mode-map.png' --fixed-fps 30 --quit-after 5 -- --test-mode --capture-hardware
& $godotConsole --path . --log-file '.godot/prologue-map.log' --write-movie '.godot/prologue-map.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-prologue-map
& $godotConsole --path . --log-file '.godot/prologue-storage.log' --write-movie '.godot/prologue-storage.png' --fixed-fps 30 --quit-after 4 -- --capture-hardware --capture-prologue-storage
& $godotConsole --path . --log-file '.godot/prologue-cpu.log' --write-movie '.godot/prologue-cpu.png' --fixed-fps 30 --quit-after 4 -- --capture-hardware --capture-prologue-cpu
```

Inspect consecutive PNG frames for single-component activation in the locality lab, parallel equal-wave activation in Hardware Foundations, internal PROCESS dwell, a short moving tail rather than pre-lit future components, exact wire travel, RAM/Bus/Cache staging, contained side-by-side instruments, and a row-first draft that visibly requires Apply. The Hardware schematic hook produces an `A=1 → NOT=0 → LAMP=0` settled frame for checking neutral component drawings, lowercase English gate names, green/high and red/low driven output ports, red/low zero-wire ports, and heavy exact-path wires. The component-placement hook arms the first allowed gate without committing it and shows the snapped cyan corner/crosshair guide on empty canvas space; confirm that this guide has no enclosing component card and that the toolbar still fits at 1600×900. The wiring-guides hook freezes a drag from A: verify the cyan source, green rings only around exact compatible inputs, the larger hovered-target halo, and unchanged inner live-value colors. The selection hook selects the compact `not`: its complete triangle, inversion bubble, leads, and label must be cyan with no circular selection backdrop, while the input/output ports remain red/green. The normal map hook exposes real clickable nodes on a visible arithmetic/storage fork and CPU merge; the Test-mode map must show all nine nodes enterable plus the explicit warning and temporary library. Confirm that bottom explanations fit and Mission/Test Bench windows remain independent. The storage hook solves RAM, rewinds its playback monitor to the pre-write `M0=0x0`/`M1=0x0` state, and freezes the first parallel Register4 write/hold boundary aligned with the displayed nodes; completing playback restores the official final `M0=0x5`/`M1=0xC` state. The other prologue hook exposes a solved CPU trace with four-bit value badges plus distinct control/ALU/register/RAM feedback. `--capture-row` applies and starts an Official row-first playback when comparing both valid software/hardware solutions.

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
