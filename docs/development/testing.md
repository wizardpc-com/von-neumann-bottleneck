# Testing

## Verified environment

- Windows PowerShell
- Godot `4.7.1.stable.official.a13da4feb`
- Console-capable Godot executable, shown below as `godot_console` on `PATH` (use the platform's equivalent `godot` executable where appropriate)

The invocations below match successful repository-root runs; the machine-specific executable path has been normalized to `godot_console` for publication.

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

## Playtest data and feedback tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-playtest-data.log' --script res://tests/test_playtest_data.gd
& $godotConsole --headless --path . --log-file '.godot/test-playtest-feedback-ui.log' --script res://tests/test_playtest_feedback_ui.gd
```

Expected success output:

```text
PASS: durable playtest session, recovery, feedback, summary, export, and clean-reset tests passed
PASS: non-blocking localized level, chapter, Demo feedback, and final export handoff UI tests passed
```

The data suite uses an isolated repository-local temporary directory. It verifies unique IDs, append-and-flush behavior, clean shutdown, active-session recovery, a malformed trailing JSONL record, Game/Test attribution, attempt/edit/Hint/tool counters, Chapter 2 capstone summaries, optional-text bounds, export schema, excluded-content privacy metadata, and selective local reset that preserves prior exports. The UI suite verifies all three localized completion surfaces, ratings, optional text, explicit Skip, final Demo export/path/open-folder handoff, and questionnaire-disabled navigation.

Normal player runs store the JSONL authority under `user://playtest_data` and export one JSON document from the final Demo handoff or chapter-selection Options panel. Script, headless, and capture runs suppress questionnaires automatically; the independent flags are `--disable-playtest-feedback`, `--disable-playtest-telemetry`, `--enable-playtest-feedback`, and `--enable-playtest-telemetry`. `--reset-local-test-state` is the explicit destructive QA boundary for Game progression, anonymous session streams, and Hardware workbenches; it preserves prior exports.

## Global Save / Continue tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-global-save.log' --script res://tests/test_global_save.gd
```

Expected success output:

```text
PASS: minimal global Save/Continue, provenance reconciliation, chapter gates, New Game, and mode isolation tests passed
```

The suite verifies mid-prologue resume, HalfAdder sealing, independent arithmetic/storage branches, generated-wrapper source binding, CPU/LOAD STORE and Chapter 1→2 gates, derived Notebook concepts, selective dependency invalidation, source-signature/workbench mismatch fallback, corrupt-primary backup recovery, corrupt and unknown schemas, confirmed New Game boundaries, optional Game-only workbench deletion, Test-progress exclusion, and telemetry-export independence. No receipt, editor-history, selection, clipboard, Trace position, or debug-input field enters the save snapshot.

## Chapter 2 progression/UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-locality-chapter-ui.log' --script res://tests/test_locality_chapter_ui.gd
```

Expected success output:

```text
PASS: complete seven-level Chapter 2 progression, concept reveals, comparisons, and multiple capstone solutions passed
```

This suite traverses all seven Chapter 2 levels through the normal map and workbench boundaries. It verifies the Chapter 1 gate, observation-before-judgment flow, qualifying observation receipts carried into paired solution levels, pass/work-group schedule metadata rendered as selectable Profiler evidence, key-evidence/end Trace navigation without event mutation, successful-Trace playback plus explicit finding review before concept reveal, direct-RAM and nearby-storage comparison, ineffective-Cache reversal, access-order repair, working-set evidence, and blocking without a hardware upgrade. The capstone keeps Program, Cache, Work Group, and detailed Profiler/History evidence locked through its baseline and raw-evidence diagnosis, enforces one changed lever until the first post-diagnosis official Trace is observed, rejects old target receipts after re-entry or baseline playback, then accepts both the larger-Cache and low-cost blocking solutions, leaves cost visible, retains a cycle-first/cost-tiebroken Personal Best, presents a Baseline → Best debrief, and remains runnable after completion. The final Notebook assertions cover the delayed reveals for Cache, Hit, Miss, Locality, Working Set, and Blocking/Tiling.

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

This suite also starts from the registry-derived central dependency map, verifies its branch/merge geometry and locked/unlocked/replayable states, and proves that editor/layout/Trace controls plus Test Bench and Components reopen actions are absent on the map. Real pointer input drags, scrolls, closes, and reopens Mission above the full-rect map; its reserved lane intersects no level node. Its title action toggles a readable lower-left compact state with Test Bench width, never the generic long title strip, and restores the exact prior geometry. The Mission taskbar button toggles close/open while preserving the current compact or expanded geometry. The map header keeps the explicit chapter-selection action, while entering a playable level restores the circuit toolbar. The suite rejects a Half Adder prerequisite bypass, completes the five tutorial interactions, and proves that the tutorial independently unlocks Half Adder and SR Latch. It checks that a fresh unwired Half Adder is neutral rather than a simulator error and that XOR is absent until later arithmetic levels. It covers complete safe-width `and`/`or`/`not` and terminal names, the shorter `not`, distinct XOR/input/output silhouettes, progressive value-colored component strokes with neutral bodies, whole-symbol selection with unchanged live port colors, compact visual ports with unchanged hit behavior, one player-colored full-path settled-wire renderer, color undo/redo and branch inheritance, causal input-change waves, the explicit level palette, direct palette drag/drop, a low-opacity truthful component ghost at the exact snap position, repeated authoritative placement, and cancellation by right click, existing-content interaction, palette replacement, and Escape. Placement arming, repetition, and cancellation must keep the circuit desktop plus every floating window's visibility, minimized state, position, and size byte-stable. Default page dimensions must leave a large central work area while keeping each page readable. The suite also covers exact valid/invalid port guides, exact-path wire hover, ordinary replacement marquee selection, Shift toggle selection, placement/cut undo and redo, `Ctrl+A/X`, press/release-driven WASD with text-focus recovery and focus-loss cleanup, and double-click component-plus-route-node selection. Tutorial completion verifies the localized learning summary, one presentation cue request, and Continue returning to the map. It switches to Test mode, proves that all nine valid registered levels are enterable, directly opens LOAD/STORE using the isolated helper library, then returns to the byte-identical Game-mode player-content signature. Map/tutorial transitions emit the real `Button.pressed` signals and verify that outgoing controls are released after the signal completes, covering Godot's locked-emitter lifetime rule. It also asserts that Hardware Test Bench and Components hide their title-bar minimize controls and reject minimized state.

Transform coverage also verifies that settled cables and Trace endpoints remain attached after non-unit zoom, pan, and component movement, and that placing a component preserves the preview symbol's exact geometry without a vertical jump.

The suite also covers body selection/drag/undo with hidden GraphNode title bars, zoom-stable right-button erasing, branching from occupied inputs and existing nets, precise incompatibility reasons, component Inspector content and bit widths, Mission re-expansion with Previous/Next, Hint pan/zoom/inspection under mutation lock, frequency-only playback controls, CPU stage derivation across save/reload, the complete CPU onboarding contract, and immediate post-Official success actions.

The same suite verifies versioned workbench snapshots in memory and on disk: automatic `default`, content-seed refresh of only that default, version-1 migration, preservation of active named workbenches, Unicode naming, per-level/per-mode isolation, independent topology/positions, autosave/reload, and the explicit absence of an operation-history field. UI coverage switches between two tutorial workbenches, enters all three read-only hint stages, verifies that Stage 2 contains only the curated subcircuit components, returns to the byte-identical player snapshot, and proves that the level-3 Half Adder topology genuinely passes the official truth table without granting player completion.

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

This suite starts each player challenge unwired, verifies the exact explicit suitable-component palette for every editable level, applies a valid visible topology through the same connection request path, runs its official Test Bench, seals it, and traverses both branches through the final bridge. It proves that XOR appears in the post-Half-Adder arithmetic levels and that the locked bridge rejects placement. It also checks topology-bound evidence, selective downstream invalidation, event-driven live analysis, storage preview/commit/reset UI, before/after state rows, parallel RAM-cell feedback aligned to displayed nodes after zoom/scroll, complete advanced-module names, and geometric non-overlap between every central name, function icon, and adjacent port label. Function-specific surfaces, a known-address cursor on the truthful two-row RAM grid, Q-only latch state output, parallel CPU component waves, and four-bit pulses on exact rendered curves remain covered.

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

This suite verifies all five catalog entries, authored-program signature contracts, the bounded parser, exact typed topology, 8-bit wrapping, exact CPU/RAM/Bus cycle formulas, Bus2/4/8 serialization, repeat signatures, every bottleneck category, immutable aggregate receipts, fixed-test binding, controlled comparisons that reject custom programs or changes to non-compared hardware, the memory-heavy Eco → Fast reversal, and final 4/16/64 aggregation.

## Chapter 1 progression/UI tests

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/test-system-lab-ui.log' --script res://tests/test_system_lab_ui.gd
```

Expected success output:

```text
PASS: five-level system chapter map, prediction, controlled comparison, evidence reveal, exact-path animation, and diagnosis tests passed
```

This suite runs the full five-level Test-mode route through normal Apply, prediction, Test Bench, part-selection, controlled-comparison, and diagnosis boundaries. It verifies hub/prologue gates, isolated provenance/progression, map nodes, six visible routes, draft blocking, delta-based WASD without fixed key-repeat jumps or post-release drift, canvas-focus recovery after program editing, replacement/Shift/Ctrl+A selection, whole-device selection feedback, selected-group movement, fixed-slot deletion semantics, cursor-tip wire erasing, and atomic undo/redo. It also covers component movement without timing change, exact cable and active-Trace routes after non-unit zoom, pan, and component movement, CPU WAIT feedback, coexisting/minimizable windows, locked predictions, authored-workload-only progression with explicit custom-program debug results, the baseline-direction gate, Before → After history with one changed part and total/wait deltas, Trace-before-History ordering, final authored machine/program locking, 4/16/64 workload rows, receipt-bound breakdown locking, and a correct-first post-submission reveal that remains visible. Each completion must expose its localized lesson summary only through the explicit finding-review action; the final Continue action returns to the chapter map.

## Project startup smoke check

```powershell
$godotConsole = 'godot_console'
& $godotConsole --headless --path . --log-file '.godot/project-smoke.log' --quit-after 5
& $godotConsole --headless --path . --log-file '.godot/project-test-mode-smoke.log' --quit-after 5 -- --test-mode
```

Success is exit code `0` with no project parse/runtime error before the automatic quit.

The ordinary smoke must remain in Game mode with all mode/Test UI hidden and must expose the Game-only Continue/New Game entry. The second smoke proves that `--test-mode` is accepted as the developer entry and hides those player save actions. A clean QA launch may combine `--test-mode --reset-local-test-state`; do not use the reset flag when local named workbenches or Game progress must be retained.

## Windows playtest build

Install the Godot 4.7.1 Windows export templates, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-playtest.ps1 -GodotExecutable 'C:\path\to\Godot_v4.7.1-stable_win64.exe'
```

Success creates `build/playtest/Von-Neumann-Bottleneck.exe`, copies the friend-facing README beside it, creates `build/Von-Neumann-Bottleneck-Windows-Playtest.zip`, and prints the ZIP SHA-256. The script rejects another Godot version and fails with an export-template instruction instead of producing a partial package.

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
& $godotConsole --path . --log-file '.godot/new-game-confirmation.log' --write-movie '.godot/new-game-confirmation.png' --fixed-fps 30 --quit-after 3 -- --capture-new-game
& $godotConsole --path . --log-file '.godot/chapter2-map.log' --write-movie '.godot/chapter2-map.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-chapter2-map
& $godotConsole --path . --log-file '.godot/terminology-handbook.log' --write-movie '.godot/terminology-handbook.png' --fixed-fps 30 --quit-after 3 -- --capture-terminology
& $godotConsole --path . --log-file '.godot/chapter-options.log' --write-movie '.godot/chapter-options.png' --fixed-fps 30 --quit-after 3 -- --capture-options
& $godotConsole --path . --log-file '.godot/playtest-export.log' --write-movie '.godot/playtest-export.png' --fixed-fps 30 --quit-after 3 -- --capture-playtest-export
& $godotConsole --path . --log-file '.godot/chapter2-capstone.log' --write-movie '.godot/chapter2-capstone.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-chapter2-capstone
& $godotConsole --path . --log-file '.godot/v02-capture.log' --write-movie '.godot/v02-demo.png' --fixed-fps 30 --quit-after 45 -- --test-mode --capture-demo
& $godotConsole --path . --log-file '.godot/v02-profiler.log' --write-movie '.godot/v02-profiler.png' --fixed-fps 30 --quit-after 2 -- --test-mode --capture-profiler
& $godotConsole --path . --log-file '.godot/v02-workspace.log' --write-movie '.godot/v02-workspace.png' --fixed-fps 30 --quit-after 2 -- --test-mode --capture-workspace
& $godotConsole --path . --log-file '.godot/program-draft.log' --write-movie '.godot/program-draft.png' --fixed-fps 30 --quit-after 2 -- --test-mode --capture-program-draft
& $godotConsole --path . --log-file '.godot/hardware-schematic.log' --write-movie '.godot/hardware-schematic.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-schematic-signal
& $godotConsole --path . --log-file '.godot/official-sequence.log' --write-movie '.godot/official-sequence.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-hardware --capture-official-sequence
& $godotConsole --path . --log-file '.godot/component-processing.log' --write-movie '.godot/component-processing.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-component-processing
& $godotConsole --path . --log-file '.godot/component-placement.log' --write-movie '.godot/component-placement.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-component-placement
& $godotConsole --path . --log-file '.godot/transformed-placement.log' --write-movie '.godot/transformed-placement.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-transformed-placement
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
& $godotConsole --path . --log-file '.godot/mission-briefing.log' --write-movie '.godot/mission-briefing.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-mission-briefing
& $godotConsole --path . --log-file '.godot/mission-compact.log' --write-movie '.godot/mission-compact.png' --fixed-fps 30 --quit-after 3 -- --capture-hardware --capture-mission-compact
& $godotConsole --path . --log-file '.godot/half-adder-briefing.log' --write-movie '.godot/half-adder-briefing.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-hardware --capture-half-adder-briefing
& $godotConsole --path . --log-file '.godot/prologue-tutorial.log' --write-movie '.godot/prologue-tutorial.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-tutorial
& $godotConsole --path . --log-file '.godot/prologue-half-adder.log' --write-movie '.godot/prologue-half-adder.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-half-adder
& $godotConsole --path . --log-file '.godot/prologue-full-adder.log' --write-movie '.godot/prologue-full-adder.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-full-adder
& $godotConsole --path . --log-file '.godot/prologue-alu.log' --write-movie '.godot/prologue-alu.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-alu
& $godotConsole --path . --log-file '.godot/prologue-latch.log' --write-movie '.godot/prologue-latch.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-latch
& $godotConsole --path . --log-file '.godot/prologue-register.log' --write-movie '.godot/prologue-register.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-register
& $godotConsole --path . --log-file '.godot/prologue-ram-default.log' --write-movie '.godot/prologue-ram-default.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-ram-default
& $godotConsole --path . --log-file '.godot/prologue-cpu-default.log' --write-movie '.godot/prologue-cpu-default.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-prologue-cpu-default
& $godotConsole --path . --log-file '.godot/component-inspector.log' --write-movie '.godot/component-inspector.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-component-inspector
& $godotConsole --path . --log-file '.godot/cpu-success.log' --write-movie '.godot/cpu-success.png' --fixed-fps 30 --quit-after 5 -- --capture-hardware --capture-cpu-success
& $godotConsole --path . --log-file '.godot/system-map.log' --write-movie '.godot/system-map.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-system-map
& $godotConsole --path . --log-file '.godot/system-workspace.log' --write-movie '.godot/system-workspace.png' --fixed-fps 30 --quit-after 3 -- --test-mode --capture-system
& $godotConsole --path . --log-file '.godot/system-run.log' --write-movie '.godot/system-run.png' --fixed-fps 30 --quit-after 7 -- --test-mode --capture-system-run
```

Inspect the New Game frame for a clear destructive confirmation, an unchecked optional Game-workbench checkbox, and copy that explicitly preserves telemetry exports and Test state. Inspect the Chapter 2 map for seven readable short investigations and clear state hierarchy. The playtest-export frame must show the final handoff with a prominent Export action and no account/upload request. The capstone frame must show the given configuration, a baseline-first evidence prompt, and locked decision controls without exposing a prescribed solution. Inspect consecutive PNG frames for single-component activation in the locality lab, parallel equal-wave activation in Hardware Foundations, a growing state stroke rather than a point or pre-lit future components, exact wire travel, RAM/Bus/Cache staging, contained side-by-side instruments, and a row-first draft that visibly requires Apply. Device processing must stay inside the actual card with no orbit or radial indicator. The Hardware schematic hook produces an `A=1 → NOT=0 → LAMP=0` settled frame for checking neutral component drawings, directional level-input geometry, lowercase English gate names, compact red/green/gray ports, player-hued bright/dim cables, and one heavy exact-path cable rather than two stacked full paths. The component-processing hook freezes NOT midway: the high input stroke must enter the real triangle, the body route uses cyan, the low output stroke is queued at the inversion bubble, and no dot, second NOT model, full cable, or halo may appear. The component-placement hook arms the first allowed gate without committing it and shows a low-opacity copy of that exact symbol at the snapped pointer position; confirm that there is no substitute card/bounding box and that the toolbar still fits at 1600×900. The completion hook shows the localized lesson modal and Continue action; the longer opt-in audio capture lets the actual procedural cue finish and should exit without an audio/RID/Object leak. The wiring-guides hook freezes a drag from A: verify the cyan source, green rings only around exact compatible inputs, the larger hovered-target halo, unchanged inner live-value colors, and a visible player-hued draft cable despite the hidden native stroke. The selection hook selects the compact `not`: its complete triangle, inversion bubble, leads, and label must be cyan with no circular selection backdrop, while the input/output ports remain red/green. The normal map hook exposes real clickable nodes on a visible arithmetic/storage fork and CPU merge; the Test-mode map must show all nine nodes enterable plus the explicit warning and temporary library. Confirm that bottom explanations fit, the Test Bench is absent, and Mission remains fully operable in its dedicated left lane without covering a node. The storage hook solves RAM, rewinds its playback monitor to the pre-write `M0=0x0`/`M1=0x0` state, and freezes the first parallel Register4 write/hold boundary on the real Register4 modules; completing playback restores the official final `M0=0x5`/`M1=0xC` state. The CPU hook must show distinct control fan-out, register latch, notched ALU, mux wedge, and two-word RAM grid surfaces; a RAM processing event highlights its known addressed row. The system-run hook must show one badge on a player-colored connection segment without drawing a capsule or a straight bridge through Bus. `--capture-row` applies and starts an Official row-first playback when comparing both valid software/hardware solutions.

The workbench-hint hook freezes tutorial hint stage 2. Confirm that the top-right control clearly shows hint progression and Return, the Mission window explains the read-only scope, only the first `A → NOT` wire is revealed, Test Bench/Components windows stay hidden, and the toolbar does not overflow at 1600×900. The official-sequence hook freezes Half Adder case 1: only its row may say Running, later rows must remain Not Run without expected outputs, and the editable playback-frequency control must fit the toolbar. The two Mission-briefing hooks show tutorial page 1 and Half Adder page 2 respectively; inspect the centered large task window, upper-left Test Bench, red-low/green-high directional `0`/`1` switches, and the complete readable four-row truth-table definition. An ordinary component-placement capture should also show the compact `Workbench: default` selector and Hint button without covering the circuit.

The system-map hook shows the complete five-node zig-zag investigation and its prerequisite state. The system-workspace hook opens Program and Profiler together to check draggable-window containment, applied-source state, line explanations, the Bus prediction, and progressive metric labels. The system-run hook freezes a Bus2 read packet: verify one settled green cable, an `0xNN 3/4` packet exactly on that cable, CPU `WAIT`, Bus `TRANSFER`, and the addressed RAM row, with no detached component model or second full wire. Manually inspect the final investigation both before and after a first diagnosis: the former must show raw 4/16/64 evidence without CPU/RAM/Bus shares, while the latter must reveal the complete breakdown.

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

The smooth-navigation and Chapter 1 editor-continuity iteration on 2026-08-22 ran six relevant suites in the final runtime source state with exit code `0`: circuit simulation, Hardware Foundations UI, prologue progression/UI, Chapter 1 simulation/UI, and localization. Default, Test-mode, direct Hardware Foundations, and direct Chapter 1 startup smokes also exited `0`. Hardware UI verifies that WASD no longer performs fixed key-repeat jumps, stops on release, ignores visible text entry, and resumes immediately when the canvas retakes focus. Chapter 1 UI verifies the same focus boundary plus real marquee/Shift/Ctrl+A selection, whole-device feedback, pass-through body dragging, grouped movement, fixed-slot route deletion, cursor-tip and continuous right-button erasing, session-local layout without operation history, and Ctrl+Z/Ctrl+Y/Ctrl+Shift+Z replay. A fresh 1600×900 Chapter 1 workspace capture confirmed that Undo/Redo and the existing essential tools fit without toolbar overflow. Final logs contained no script, parse, assertion, locked-object, invalid-call, RID, or ObjectDB leak errors; `git diff --check` passed. The known Windows root-certificate warning remained non-fatal.

The Chapter 2 vertical-slice iteration on 2026-08-24 ran all eleven suites in the final runtime source state with exit code `0`: locality simulation, legacy locality UI, Chapter 2 progression/UI, circuit simulation, Hardware Foundations UI, content registry, prologue simulation/UI, Chapter 1 simulation/UI, and localization. Default, Test-mode, English-locale, and direct Chapter 2 route smokes also exited `0`. Fresh 1600×900 Chinese map/capstone and English capstone frames were inspected for seven-node readability, baseline-first investigation copy, movable-window containment, and localization fit. Automated coverage confirms exact v0.2 metrics, direct-memory routes, two-pass working-set behavior, blocking, delayed Cache terminology, the capstone baseline lock, two valid capstone solutions, and all prior simulation invariants. Final logs contained no script, parse, assertion, invalid-call, RID, or ObjectDB leak errors; `git diff --check` passed.

The layered-mission, progressive-hint, and three-level Esc-navigation iteration on 2026-08-25 ran all eleven suites in the final runtime source state with exit code `0`, followed by a project startup smoke. Hardware UI now covers the three-page tutorial and Half Adder briefings, immediate four-row truth-table explanation, upper-left Test Bench, asymmetric low/high signal placeholders, one-wire tutorial hint stage 2, and CARRY-only Half Adder stage 2. Hardware, Chapter 1, and Chapter 2 UI suites each exercise `Esc` from a level to its map and again to chapter selection. Fresh 1600×900 tutorial-page-1 and Half-Adder-page-2 captures were inspected for centered readable Mission layout, unobscured upper-left Test Bench, and unclipped Chinese truth-table copy. `git diff --check` passed. The restricted Windows runs still printed the known non-product certificate warning and occasional `user://C:` directory warning; every command exited `0`.

The Mission-window consistency follow-up on 2026-08-25 ran the Hardware Foundations, hardware prologue, legacy Cache, Chapter 1, Chapter 2, and localization UI suites with exit code `0`, then passed both default and Test-mode startup smokes. Coverage verifies the shared type scale, compact centered Continue action, non-minimizable Mission windows, equal-height tool launchers, second-press close behavior, and exact position/size restoration after either launcher or title-bar close. A fresh 1600×900 Mission capture was inspected for centered hierarchy, a bottom-aligned Continue action, a close-only title bar, and matching bottom-right controls. The restricted runs again printed only the known certificate and occasional `user://C:` warnings.

The Esc-priority and chapter-options follow-up on 2026-08-25 ran the Hardware Foundations, legacy Cache, Chapter 1, Chapter 2, and localization UI suites with exit code `0`. Navigation now runs after GUI input, so an active Chapter 1 selection gesture consumes Esc without leaving its level; all three chapter suites also verify that the map-to-chapter press does not leak into the new Options overlay. Hub coverage verifies open/close toggling, handbook priority, localized Resume/fullscreen/Quit actions, and a hidden initial state. A fresh 1600×900 Chinese Options frame was inspected for modal contrast, consistent type/button sizing, visible focus, and a distinct quit action.

The Hardware Mission compact-navigation follow-up on 2026-08-26 ran the Hardware Foundations, hardware prologue, legacy Cache, Chapter 1, Chapter 2, and localization UI suites with exit code `0`, then passed default and Test-mode startup smokes. Coverage verifies the custom title action beside Close, readable compact content rather than generic minimization, exact Test Bench width, lower-left anchoring, exact expanded-geometry restoration, compact-state preservation across taskbar close/open, Previous page navigation, centered Continue, and last-page Continue entering the same compact state. Fresh 1600×900 Chinese frames were inspected for the large Half Adder page-2 navigation row and the ordinary compact tutorial Mission alongside the upper-left Test Bench.

The Esc/Handbook hierarchy correction on 2026-08-26 reran the Hardware Foundations, Chapter 1, Chapter 2, legacy UI, and localization suites with exit code `0`. All three map-to-chapter routes now consume Esc before scene removal, and their logs no longer contain the null-viewport `set_input_as_handled` failure. Handbook coverage verifies all 89 unique terms under four top-level topics and fourteen second-level directories, a maximum visible depth of three including term leaves, searchable directory paths, and the concise equal-sized lower-right Handbook button. Fresh 1600×900 Chinese handbook and Hardware-map frames were inspected for hierarchy readability and taskbar alignment.

The Hardware non-minimizable-tools follow-up on 2026-08-26 reran the Hardware Foundations UI suite and startup smoke with exit code `0`. Coverage verifies that Test Bench and Components omit title-bar minimization while retaining movement, resizing, Close, taskbar toggle, and geometry restoration. Mission keeps its dedicated readable compact action.

The Clock Period and sequential-official-test follow-up on 2026-08-26 reran Hardware Foundations, the construction prologue, Chapter 1, Chapter 2, and localization UI coverage with exit code `0`. All three playback toolbars expose the same editable `0.05–2.00` second Clock Period instead of multiplier presets. Hardware tests verify that only the active official case is revealed, future rows omit expected outputs, and sealing/completion evidence remains unavailable until every case finishes. The handbook contains the new Clock Period term.

The illustrated-Handbook follow-up on 2026-08-26 reran Hardware Foundations, Chapter 1, Chapter 2, shared UI, and localization coverage with exit code `0`. Twelve harder terms now expose a concrete worked example and one of eleven scalable in-game diagrams; simple entries omit the illustration region rather than showing empty space. Coverage opens every illustrated entry, verifies the accumulator's `3 + 2 → ACC=5` write-back flow, and checks that all diagram labels and examples exist in both registered catalogs. A fresh 1600×900 Chinese accumulator frame was inspected for readable arrows, unclipped definition text, and one continuous detail scrollbar.

The beginner mission-narrative revision on 2026-08-26 reran localization, Hardware Foundations UI, Chapter 1 UI, Chapter 2 progression/UI, and the legacy locality UI suite with exit code `0`, followed by a clean project startup smoke. Coverage verifies one-to-four authored pages per level, Previous/Continue navigation in all three chapters, a four-page Half Adder explanation that defines the truth table before using it, one shared term-link color, valid Handbook targets in both locales, and click-through selection of the exact Handbook entry. A fresh 1600×900 Chinese Half Adder page-2 frame was inspected for centered readable copy, an unclipped four-row table, visible cyan term link, compact navigation, and an unobscured upper-left Test Bench. `git diff --check` passed.

The minimal global Save/Continue iteration on 2026-08-27 ran all fourteen `tests/test_*.gd` suites with exit code `0`, including the new provenance reconciliation suite and Game/Test hub assertions. Isolated Game, `--test-mode`, and `--test-mode --reset-local-test-state` startup smokes exited `0`; the reset reported both raw playtest-state and global-save cleanup boundaries. Fresh 1600×900 Chinese hub and New Game confirmation frames were inspected for disabled fresh Continue, visible New Game, readable destructive copy, and the unchecked optional Game-workbench deletion. The Godot 4.7.1 Windows export produced a self-contained EXE and ZIP; packaged Game/Test headless starts both exited `0`. The final ZIP SHA-256 was `5B1745FE2B17A7736D1E0BB72324818AFB26B1EF80D57C0C6985CE287D787B1F`. The known Windows root-certificate warning remained non-fatal.

The Prologue Playability Rework Round 2 on 2026-08-28 reran all fourteen `tests/test_*.gd` suites in the final source state with exit code `0`. Coverage now binds the pre-CPU seeds/reference/hints to the player's saved accepted topology and coordinates; exercises precise procedural-surface component erasing, near misses, zoom/pan placement conversion, compatible net branching, read-only Hint/Official navigation, role-specific Inspector terminology, and Seal/Continue/Return success behavior; and replays the complete two-branch prologue through CPU and LOAD/STORE. Normal Windows Godot captures were inspected for the map, Tutorial, every construction level, signal states, Mission, Inspector, Hint, CPU opcode/stage guidance, fullscreen, zoom/pan placement, and the three-action success modal at 1600×900. The host reported `AppliedDPI=144` (150%). Restricted Godot runs can crash while resolving `user://`; final tests and captures therefore used one non-sandbox process at a time with project-local logs. The player's three backed-up save/workbench files were restored afterward and verified byte-for-byte by SHA-256.

## What to run after changes

- Simulation/DSL/cost/trace changes: simulation test, legacy Cache Locality UI test, Chapter 2 progression/UI test, and smoke check.
- Circuit model, Test Bench, or encapsulation changes: circuit simulation test, Hardware Foundations UI test, and smoke check.
- CPU-prologue component/level/state changes: content-registry test, both prologue tests, circuit simulation test, Hardware Foundations UI test, localization test, and smoke check.
- Hardware Foundations wiring/window/animation changes: Hardware Foundations UI test and smoke check; also run the circuit simulation test if trace or topology assumptions changed.
- Chapter 2 catalog/progression/notebook changes: content-registry test, Chapter 2 progression/UI test, localization test, and smoke check.
- UI/wiring/profiler/playback changes: the affected UI suites and smoke check; also run the simulation test if Trace assumptions changed.
- Player-facing copy or localization-boundary changes: localization test, affected progression/UI suites, and smoke check; visually inspect the Chinese default and at least one alternate-locale launch.
- Playtest event/storage/export changes: both playtest suites, all affected host UI suites, normal/Test/reset startup smokes, final export-handoff capture, Windows package build, export inspection, and `git diff --check`.
- Godot resource moves: all affected suites plus explicit `res://` and UID reference inspection.
- Documentation-only changes: inspect links, paths, whitespace, and the Git diff; runtime tests are optional unless commands or architecture claims changed.

## CI status

There is intentionally no GitHub Actions workflow yet. Local commands are reliable, but exact Godot 4.7.1 provisioning on the selected GitHub runner has not been validated in this repository. Add CI only after the runner installation method is reproducible and the same commands have passed there once; do not configure a required status check before that job exists.
