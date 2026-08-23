# Chapter 2: Reduce Data Movement

## Goal

Turn the existing Cache Locality Lab v0.2 into a complete seven-level Chapter 2 vertical slice for first external playtesting. The chapter teaches players to reduce expensive data movement through Cache, locality, working-set reasoning, and blocking, while keeping each level focused on one primary cognitive task.

## Scope

- Add seven ordered levels: repeated distant reads, nearby storage exploration, ineffective Cache observation, access-order repair, working-set overflow observation, blocking implementation, and an unguided capstone.
- Reuse the current DSL, explicit Draft → Apply → Execute boundary, deterministic Cache simulation, authoritative Trace, staged playback, Profiler, Cache controls, and Run History.
- Add bounded workload scheduling for no-Cache observation, repeated passes, and line-sized blocking without changing the existing one-pass `SimulationCore.run()` contract.
- Add a Chapter 2 map, Game/Test progress separation, level-specific tool exposure, evidence judgments, completion receipts, and a lightweight Systems Notebook whose terminology unlocks after the relevant experience.
- Present the current v0.2 lab as Chapter 2 from the prototype hub and gate it behind Chapter 1 completion in Game mode.
- Update the generic content registry with a locality-chapter entry kind and register the seven authored levels through a Chapter 2 content manifest.
- Update Chinese and English localization, status/design/architecture/testing documentation, and automated tests.

## Non-goals

- Prefetching, multilevel caches, set associativity controls, replacement-policy lessons, multicore behavior, queues, overlap, or multiple outstanding requests.
- Arbitrary programs, array dimensions, cache-line sizes, data types, or a general workload scripting system.
- A universal simulator shared with the circuit or Chapter 1 domains.
- Production art, audio, persistent save files, scoring tiers, leaderboards, or a required minimum hardware cost.
- Refactoring Chapter 1, the hardware prologue, or unrelated dirty-worktree changes.

## Affected subsystems

- `src/simulation/`: additive workload configuration and deterministic scheduled execution while preserving legacy one-pass results.
- `src/locality_chapter/` and `src/content/locality/`: Chapter 2 catalog, progress/receipt state, notebook concepts, and content registration.
- `src/ui/main.gd`: chapter map and level shell around the existing workbench, mission/judgment/blocking/notebook instruments, level-specific controls, comparison history, completion flow, and capstone behavior.
- `src/ui/prototype_hub.gd` and `project.godot`: chapter entry, Game-mode gate, and autoload state.
- `tests/`, localization catalogs, and durable project documentation.

## Invariants

- Simulation finishes deterministically before playback; animation and window layout never influence timing, results, evidence, or completion.
- Parsed program IR remains authoritative for traversal and address order. Blocking only schedules repetitions of that derived order; it never substitutes a hidden program result.
- Existing `SimulationCore.run()` reference metrics, events, signatures, cache costs, and DSL validation remain unchanged.
- Trace events remain the source for Profiler totals, CPU wait, hit/miss evidence, data-flow playback, and receipts.
- Draft source never executes until explicit Apply, and the executed source is recorded.
- Cache behavior remains hardware-managed and deterministic. No chapter level teaches or exposes replacement-policy tuning.
- Game and Test progress remain isolated. Existing Chapter 1 and hardware-prologue state is preserved.
- Existing uncommitted Chapter 1 work is not reverted or overwritten.

## Decisions

- Keep all seven levels in the existing locality scene/controller rather than duplicating scenes. A Chapter 2 catalog owns scenario, fixed or available controls, evidence requirement, and completion rule.
- Keep `SimulationCore.run()` as the legacy one-pass API. Add a small scenario API for direct-memory observation and repeated/scheduled access, using program-derived load order and the same timing/event primitives.
- Use two passes over the existing 4×4 data set for the working-set and capstone workloads. An unblocked one-line Cache cannot retain the full four-line working set between passes; blocking reorders the two passes one cache line at a time.
- Treat 2-1's Cache-free path as an authored observation scenario, with CPU → Bus → RAM routes and no Cache terminology in player-facing copy.
- Reveal concepts on completion: Cache/Hit/Miss after 2-2, Locality after 2-4, Working Set after 2-5, and Blocking/Tiling after 2-6. Locked notebook entries display `???`.
- Require an explicit evidence judgment in observation levels so that running alone does not complete them. Implementation levels complete from trace-derived correctness and performance evidence.
- Set the capstone target broadly enough for multiple solutions: a large Cache, line-sized blocking with a small Cache, and intermediate Cache/block combinations can all pass; cost remains visible but is not a hard gate. Keep configuration changes locked until the given baseline creates the first official receipt.
- Let a completed capstone remain runnable and replayable. The player can return to the map or continue optimizing without introducing a separate post-pass mode.
- Reuse the campaign registry for authored identity, order, dependencies, and localization ownership, but keep locality-specific scenario metadata in the Chapter 2 catalog.

## Implementation steps

1. Add and test the additive workload/schedule simulation API, including no-Cache routes, two-pass working-set behavior, blocking, exact metrics, and determinism.
2. Add the locality content manifest, seven-level catalog, Game/Test chapter state, trace-derived receipts, and notebook unlock rules.
3. Wrap the existing v0.2 workbench in the Chapter 2 map/mission flow and add level-specific tool visibility, observation judgments, blocking controls, improved comparisons, and completion behavior.
4. Gate and route the hub entry, add all Chinese/English copy, and update content/localization coverage.
5. Add focused chapter progression/UI tests, preserve legacy UI/simulation coverage, and update architecture/status/design/testing documentation.
6. Run all headless suites, startup smokes, visual captures, final diff/status review, and move this plan to `completed/` with actual verification evidence.

## Progress

- 2026-08-24: audited repository rules, the dirty Chapter 1 worktree, Cache Locality Lab v0.2 docs/ADRs, DSL/IR, deterministic simulation, Trace/playback, Program Apply, Profiler, Cache controls, Run History, hub, content registry, chapter map/state patterns, localization, and tests. Confirmed that the proposed chapter fits as an additive shell and bounded simulation extension rather than a cross-domain rewrite.
- 2026-08-24: selected the two-pass 4×4 workload for working-set evidence and the program-derived blocked schedule for 2-6/capstone; retained the legacy one-pass API as a regression boundary.
- 2026-08-24: implemented the additive direct/two-pass/blocked workload runner, seven-level manifest/catalog/state/receipts, map and level-specific tools, evidence judgments, delayed Systems Notebook reveals, Before → After comparison, hub gate, and multi-solution capstone. The capstone requires its given baseline receipt before exposing configuration changes.
- 2026-08-24: completed both localization catalogs and removed pre-reveal Cache/Hit/Miss terminology from the direct and nearby-storage experiences, including Trace, device feedback, graph actions, and Profiler details.
- 2026-08-24: all eleven automated suites passed in the final runtime source state. Default, Test-mode, English, and direct Chapter 2 route smokes passed; Chinese map/capstone and English capstone 1600×900 frames passed visual inspection; current logs contain no script, parse, assertion, invalid-call, RID, or ObjectDB leak errors; `git diff --check` passed.

## Unresolved questions and limits

- The 145-cycle implementation/capstone target is fixed for the first external playtest; later calibration should use observed player behavior rather than add new mechanisms preemptively.
- Chapter and notebook progress remain session-local, matching the current prototype's other chapter state.
- The existing 4×4, four-integer line, fully associative LRU model remains intentionally fixed for this vertical slice.
- External playtesting instrumentation is limited to in-session receipts and run/tool history; analytics export is follow-up work.
