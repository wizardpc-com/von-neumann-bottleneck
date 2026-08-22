# Chapter 1: Waiting for Data

## Current playable scope

Chapter 1 is a six-level, prerequisite-gated performance investigation after the CPU Building Prologue. Game mode requires the LOAD/STORE handoff. Test mode unlocks every node with isolated source signatures, receipts, and completion.

| order | level | required evidence |
|---|---|---|
| 1 | Connect the First System | build the six visible CPU/Bus/RAM routes and pass both official cases |
| 2 | After the CPU Gets Faster | pass with two distinct CPUs under one program, RAM, Bus, and test set |
| 3 | Who Is the CPU Waiting For? | pass with two distinct RAM parts while CPU/Bus/program stay fixed |
| 4 | How Many Trips for One Byte? | pass with two distinct Bus widths while CPU/RAM/program stay fixed |
| 5 | Workload Magnifier | pass the fixed 4/16/64 cases in one official run |
| 6 | Bottleneck Investigation | pass all cases, then submit the bottleneck derived from that aggregate Trace |

Programs are editable through a bounded Python-shaped DSL, but software optimization is not required. Editing creates a draft; only **Confirm & Apply** replaces executable source. Every supported line is explained from the parsed instruction rather than from separate hidden logic.

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

## Evidence and progression

An official run creates a `SystemRunReceipt` that records the applied program signature, current topology signature, fixed test-set signature, selected part IDs, aggregate metrics, case Trace signatures, correctness, and trace-derived diagnosis. Comparison levels group receipts only when the non-compared parts and program match. Debug runs never unlock progression.

The Profiler opens progressively across the chapter: total time; CPU compute/wait; RAM service/request count; Bus control/data/serialization; bytes/cost/history; and final cycle shares. Mission, Parts, Program, Test Bench, Profiler, and Run History are independent movable, resizable, minimizable windows.

The first authoritative completion of each level opens a localized summary of the investigation's lesson and plays a short low-volume procedural cue. **Continue** returns to the six-node chapter map. The overlay and audio consume completed evidence only; neither participates in timing, receipts, diagnosis, or progression rules.

## Intentional temporary limitations

- CPU8 and RAM64x8 are compatible system-level wrappers whose provenance hashes the player's verified smaller prologue abstractions. The gate campaign itself remains at its current one-/four-bit widths.
- Chapter completion, receipts, applied drafts, window placement, and level-session layouts are session-local. There is no coordinated whole-game save yet.
- The assembly system has exactly one CPU, one Bus, one RAM, and six supported typed routes. There is no arbitrary system graph, multiple driver, bus arbitration, or multi-core model.
- Fixed system slots are not cloneable or permanently removable. Deleting a device is expressed as removing its incident routes; Chapter 1 has no prologue-style free component palette, junctions, or endpoint waypoints.
- The DSL is not Python and has no nested loops, branches, functions, or arbitrary memory addressing.
- Art, difficulty tuning, and workload constants are prototype-quality and require playtest. The completion cue is a replaceable procedural placeholder rather than authored chapter music.
- Cache, locality, line replacement, and software/hardware optimization interaction remain in the separate preserved v0.2 lab and are not taught in this chapter.

## Manual playtest questions

- Does the first wiring task establish the request/write/read directions without feeling like busywork?
- Are the four/two/one Bus stages and the single value badge readable on the exact player-colored route without looking like an extra cable?
- Does CPU `WAIT` plus RAM/Bus component feedback make the waiting relationship immediately legible?
- Do two-part comparisons feel controlled, and does Run History make their evidence easy to compare?
- Does the progressive Profiler reveal enough at each level without answering the later diagnosis early?
- Does the final diagnosis feel earned from the exact system that ran?
- Does each completion summary reinforce the correct bottleneck concept, and does its cue/Continue handoff feel satisfying without interrupting investigation flow?
- Is the 45–60 minute six-level pacing credible, and which workload or explanation needs shortening?
