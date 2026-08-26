# Chapter 1: Waiting for Data

## Current playable scope

Chapter 1 is a five-level, prerequisite-gated performance investigation after the CPU Building Prologue. Game mode requires the LOAD/STORE handoff. Test mode unlocks every node with isolated source signatures, receipts, predictions, and completion.

| order | level | required evidence |
|---|---|---|
| 1 | Connect the First System | build the six visible CPU/Bus/RAM routes and pass both official cases |
| 2 | After the CPU Gets Faster | lock a prediction, establish the Eco baseline, change only CPU to Fast, and explain the controlled delta |
| 3 | Who Is the CPU Waiting For? | lock a prediction and compare two RAM parts while CPU/Bus/program/tests stay fixed |
| 4 | How Many Trips for One Byte? | lock a prediction and compare two Bus widths while CPU/RAM/program/tests stay fixed |
| 5 | Bottleneck Investigation | pass the fixed 4/16/64 cases, diagnose from raw evidence, then inspect the revealed breakdown |

Programs are editable through a bounded Python-shaped DSL, but software optimization is not required. Editing creates a draft; only **Confirm & Apply** replaces executable source. Every supported line is explained from the parsed instruction rather than from separate hidden logic. Custom programs may still run as debug experiments, but only the authored per-level program can create a progression receipt; this keeps the controlled CPU/RAM/Bus evidence comparable.

## Deterministic model

- All external values are 8-bit and arithmetic wraps modulo 256.
- CPU arithmetic costs are 4/2/1 cycles for Eco/Balanced/Fast.
- RAM read or write service costs are 12/8/4 cycles for Slow/Balanced/Fast.
- Every memory operation uses one Bus control cycle. An 8-bit payload takes `ceil(8 / bandwidth)` data cycles, so Bus2/4/8 produces four/two/one visible segments.
- Requests execute sequentially; there is no overlap, prefetch, queue, arbitration, or physical wire delay.
- A bottleneck is CPU, RAM, or Bus only when that category owns at least 50% of accounted cycles and is the unique maximum. Otherwise it is mixed.
- Cost 4/7/13 is recorded for each family but never gates completion.

The displayed six-route topology is authoritative. Moving CPU, Bus, or RAM changes the rendered curves but not system identity or timing. WASD pans continuously from explicit press/release state and frame time rather than operating-system key repeat; releasing a key or leaving the application stops immediately, and clicking the canvas restores movement after program editing. Middle drag and wheel zoom remain available. Empty-canvas dragging replacement-selects devices, Shift toggles a device or marquee, and GraphEdit moves the selected group together. `Ctrl+A` selects all three fixed slots. Delete or a cursor-tip-sized held-right sweep removes the selected/touched devices' incident routes while preserving the unique CPU/Bus/RAM slots for reconnection. Wiring, erasing, movement, Auto Layout, Standard Wiring, and route-color edits are reversible with `Ctrl+Z`/`Ctrl+Y` or the toolbar.

Simulation finishes before playback. Each route is drawn once in a player-selected palette hue; `1`–`9` selects a color, `Ctrl+F` colors the hovered segment, `Ctrl+E` colors its request/write/read lane, and `Ctrl+R` samples it. Reverse-flow read lanes use separate visible paths below the devices instead of crossing their surfaces. Playback adds a growing band on those exact same connection paths and one address/value badge such as `@3` or `0x2A  3/4`; it never draws a detached point or invents a bridge across a component. CPU, Bus, and RAM animate their own procedural internals, and no substitute component participates.

## Investigation and progression

The three controlled investigations require the player to lock a prediction before the first official run. The prediction remains visible beside the resulting evidence; it is not scored for correctness and cannot be rewritten after seeing the outcome. The player first establishes the authored baseline, then changes only CPU, RAM, or Bus as named by the level.

An authored official run creates a `SystemRunReceipt` that records the applied program signature, current topology signature, fixed test-set signature, selected part IDs, aggregate metrics, case Trace signatures, correctness, and trace-derived diagnosis. A custom-program official-button run still reports its cases and Trace, but is explicitly labeled debug-only and is not stored as chapter evidence. Comparison levels group receipts only when the non-compared parts, applied program, and test set match. Run History promotes a qualifying pair into a Before → After comparison that names the sole changed part, fixed controls, total-cycle delta, CPU-wait delta, and the locked prediction. Debug runs never unlock progression.

The CPU comparison is the chapter's explicit cognitive reversal. Eco → Fast reduces the authored CPU arithmetic cost from four cycles to one, but leaves the same memory traffic and CPU WAIT. Arithmetic is four times faster while total cycles improve by only about 15%; the Trace, visible `WAIT`, and comparison deltas explain the difference.

The Profiler opens through five tiers: total time; CPU compute/wait; RAM service/request count; Bus control/data/serialization; then the final investigation's raw totals and workload evidence. Before the first final diagnosis, both the authored program and default CPU/RAM/Bus selection are restored and locked, so the question is bound to the exact machine that produced its evidence. The complete CPU/RAM/Bus cycle breakdown also remains hidden. The player first judges from the 4/16/64 growth rows, total cycles, CPU WAIT, and raw Trace/data flow. Any first diagnosis reveals the full breakdown for explanation or correction; only the correct diagnosis reopens the hardware and Program sandbox for further experiments. The deterministic receipt already owns those metrics and diagnosis—the reveal is presentation-only.

Mission, Parts, Program, Test Bench, Profiler, and Run History are independent movable, resizable, closable windows. Mission does not minimize; other tools may. Each toolbar action toggles its window through the same close/show path and restores the remembered position and size. An official comparison first plays its Trace; Run History is brought forward only when playback finishes. Completing a level exposes **Review investigation finding** instead of immediately covering the evidence. The player may inspect Trace, Profiler, and History before opening the localized lesson summary; its compact centered **Continue** action returns to the five-node chapter map. The overlay and audio consume completed evidence only; neither participates in timing, receipts, diagnosis, or progression rules.

## Intentional temporary limitations

- CPU8 and RAM64x8 are compatible system-level wrappers whose provenance hashes the player's verified smaller prologue abstractions. The gate campaign itself remains at its current one-/four-bit widths.
- Chapter completion, predictions, receipts, applied drafts, window placement, and level-session layouts are session-local. There is no coordinated whole-game save yet.
- The assembly system has exactly one CPU, one Bus, one RAM, and six supported typed routes. There is no arbitrary system graph, multiple driver, bus arbitration, or multi-core model.
- Fixed system slots are not cloneable or permanently removable. Deleting a device is expressed as removing its incident routes; Chapter 1 has no prologue-style free component palette, junctions, or endpoint waypoints.
- The DSL is not Python and has no nested loops, branches, functions, or arbitrary memory addressing.
- Art, difficulty tuning, and workload constants are prototype-quality and require playtest. The completion cue is a replaceable procedural placeholder rather than authored chapter music.
- Cache, locality, line replacement, and software/hardware optimization interaction are taught in the separate formal Chapter 2 and are not introduced here.

## Manual playtest questions

- Does the first wiring task establish the request/write/read directions without feeling like busywork?
- Does locking a prediction feel quick and meaningful rather than like a quiz gate?
- Does the Eco → Fast comparison make “four times faster arithmetic, only about 15% faster overall” surprising but immediately explainable from unchanged CPU WAIT?
- Does the controlled Bus2 → Bus8 comparison make four stages becoming one legible on the exact player-colored route without the value badge looking like an extra cable?
- Does CPU `WAIT` plus RAM/Bus component feedback make the waiting relationship immediately legible?
- Do Before → After, the sole changed part, fixed controls, total delta, and CPU-wait delta make each comparison legible without reading raw receipt rows?
- Does the final 4/16/64 evidence support a diagnosis without the locked breakdown becoming frustrating?
- Does the post-submission breakdown help players explain or correct their answer rather than merely announce it?
- Does the final diagnosis feel earned from the exact system that ran?
- Does labeling custom programs as debug-only preserve experimentation without making the authored evidence boundary feel arbitrary?
- Does each completion summary reinforce the correct bottleneck concept, and does its cue/Continue handoff feel satisfying without interrupting investigation flow?
- Is the five-node chapter short enough to preserve investigative momentum, and which prediction or explanation still feels repetitive?
