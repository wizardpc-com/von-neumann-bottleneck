# Chapter 1: Waiting for Data

## Goal

Add the first post-prologue chapter as a six-level, 45–60 minute performance-learning sequence. The player combines player-provenance CPU and RAM abstractions through an 8-bit Bus, observes deterministic CPU/RAM/Bus timing, and diagnoses the bottleneck in the exact machine and program they ran.

## Scope

- Add a separate system-performance domain for 8-bit CPU, RAM, Bus, program, topology, trace, and diagnosis behavior.
- Add six ordered levels: assembly, CPU comparison, RAM wait, Bus width, workload scaling, and final diagnosis.
- Keep programs editable behind the existing Draft → Apply → Execute evidence boundary, without requiring software optimization.
- Add a system-lab scene with exact-path request/data playback, progressive Profiler evidence, replaceable parts, Test Bench, Run History, and responsive floating windows.
- Preserve the current circuit campaign and Cache Locality Lab. Expose the new chapter from the hub and from the prologue completion action without rewriting either simulator into a universal model.

## Non-goals

- Cache, cache lines, locality, working sets, data layout, blocking, or replacement policy.
- Queues, contention, DMA, arbitration, bursts, prefetch, overlap, or multiple outstanding requests.
- Real DRAM timing, electrical frequency, physical wire delay, production art/audio, scoring tiers, or leaderboards.
- A general Python interpreter, HDL, arbitrary-width circuit system, or destructive migration of existing workbench files.

## Affected subsystems

- `src/system_lab/`: new deterministic system-performance model, bounded DSL, six-level catalog, and UI.
- `src/ui/prototype_hub.gd`: chapter entry and test-mode routing while preserving existing entries.
- `src/content/` and prologue content: generated CPU8/RAM64x8 provenance metadata and completion handoff; avoid changing existing circuit execution semantics.
- `tests/`: focused domain/UI coverage plus all current regressions.
- localization and durable architecture/status/testing documentation.

## Invariants

- Simulation is deterministic and complete before playback.
- UI and animation never determine results, timing, diagnosis, or progression.
- Ordinary visible wires have zero simulated latency; CPU, RAM, and Bus specs own every cycle.
- The displayed system topology and selected part specs are authoritative.
- Request and data animation use the exact displayed connection curves.
- Cache Locality Lab reference behavior and current circuit behavior remain unchanged.
- Existing uncommitted work is preserved; no commit or push is part of this task.

## Decisions

- Keep the gate/circuit domain at its current widths. Generate opaque system-level CPU8/RAM64x8 provenance from verified player source signatures instead of converting every prologue circuit to 8-bit.
- Use one CPU, one Bus, and one RAM with typed request/write/read routes. All parts expose one compatible 8-bit system interface.
- CPU compute costs are 4/2/1 cycles; RAM service costs are 12/8/4 cycles; Bus bandwidths are 2/4/8 bits per cycle. Costs are 4/7/13 for each family.
- Each memory request has one Bus control cycle. An 8-bit payload costs `ceil(8 / bandwidth)` Bus cycles. Only one request executes at a time.
- Bottleneck diagnosis uses accounted cycle shares: a category is dominant at 50% or more; otherwise the result is mixed.
- Preserve the existing locality scene as an explicit lab entry. The new chapter does not reuse its Cache-specific `SimulationCore`.
- Implement six levels in one system-lab scene/catalog rather than six scene copies. Level content owns workload, available parts, Profiler tier, official cases, and completion requirements.

## Implementation steps

1. Add typed system part/topology/program/event/trace/core classes and deterministic tests.
2. Add six level definitions, player chapter state, comparable-run receipts, and provenance-derived default parts.
3. Add the system-lab scene/UI, program application, component replacement, wiring, animation, Profiler tiers, diagnosis, and Test-mode unlocks.
4. Route the hub and prologue handoff to the chapter while retaining direct locality access.
5. Add Chinese/English copy, architecture/status/testing documentation, and an ADR for the system-performance boundary.
6. Run focused tests during implementation, then all repository suites, startup smokes, visual captures, diff checks, and final status review.

## Verification

- All ten headless suites passed in the final source state with exit code `0`: locality simulation/UI, circuit simulation/editor UI, prologue simulation/content/progression UI, system-lab simulation/UI, and localization.
- Default Game mode, Test mode, English locale, direct system scene, and hub-to-system startup smokes all exited `0` in the final source state.
- Domain coverage verifies exact CPU/RAM/Bus formulas, 8-bit wrapping, bounded DSL behavior, deterministic trace/signatures, all four diagnosis outcomes, invalid topology, source provenance, receipt invalidation, and geometry-independent timing.
- UI coverage verifies all six level gates and their normal completion path, Test-mode isolation, explicit Apply, comparable-run controls, progressive Profiler evidence, floating-window coexistence, exact transformed GraphEdit curves, and CPU/Bus/RAM feedback.
- Fresh system map, workspace, and Bus2-read captures were visually inspected at 1600×900. The active packet follows one displayed wire while CPU `WAIT`, Bus `TRANSFER`, and the addressed RAM row agree with the same trace event.
- Final diff/status and documentation checks were performed without committing or pushing.

## Progress

- 2026-08-19: inspected repository rules, dirty worktree, campaign registry, prologue handoff, v0.2 SimulationCore/Trace/DSL, current tests, and the accepted six-level product plan. Confirmed that the current locality simulator is Cache-specific and that the campaign entry contract has no system-lab kind.
- 2026-08-19: implemented the independent deterministic system-performance domain, typed authoritative topology, bounded program parser, traces, receipts, diagnosis, part catalog, and source-provenance boundary.
- 2026-08-19: implemented the six ordered levels, controlled CPU/RAM/Bus comparisons, workload scaling, final diagnosis, normal/Test progression, and prologue invalidation behavior.
- 2026-08-19: implemented the responsive system desktop, graphical map, movable CPU/Bus/RAM, exact-path playback, device-specific feedback, explicit program Apply, Test Bench, progressive Profiler, run history, and capture hooks.
- 2026-08-19: integrated the chapter with the hub and verified LOAD/STORE handoff while preserving the direct Cache Locality Lab; added Chinese/English copy, architecture/status/testing documents, ADR 0016, and automated coverage.
- 2026-08-19: completed the full regression, affected-suite reruns, five startup routes, visual QA, and final repository review. No commit or push was created.

## Intentional temporary limitations

- Chapter completion, generated CPU/RAM provenance, system layouts, and program drafts are session-local; disk persistence is deferred.
- The chapter models exactly one CPU, one Bus, one RAM, six typed routes, and one sequential outstanding request. Cache, overlap, queues, arbitration, and physical wire delay remain outside this chapter by design.
- Part costs are displayed as diagnostic evidence but are not a completion budget or optimization objective yet.
- Device visuals are clean procedural placeholders. Final art, audio, and workload/copy pacing still require manual playtest tuning.
