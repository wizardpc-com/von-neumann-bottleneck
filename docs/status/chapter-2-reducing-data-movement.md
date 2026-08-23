# Chapter 2: Keep Data Close

Chapter 2 promotes the Cache Locality Lab v0.2 mechanisms into a seven-level investigation chapter. Its theme is not “install a Cache”; it is reducing expensive data movement so the CPU spends fewer cycles waiting.

## Implemented progression

| level | primary cognitive task | fixed evidence or decision | concept revealed after completion |
| --- | --- | --- | --- |
| 2-1 Why Go All the Way Back? | observation | follow repeated CPU → Bus → RAM value requests and explain CPU WAIT | none |
| 2-2 Leave It Nearby | exploration | compare direct RAM with one nearby line; observe first far fetch and later near returns | Cache, Hit, Miss |
| 2-3 Why Didn't It Help? | observation | explain why a present one-line Cache still misses on all column-first loads | none |
| 2-4 Change the Order | implementation | Apply row-first access and reach 105 cycles without replacing Cache | Locality |
| 2-5 The Order Is Already Right | observation | explain why two row-first passes reload all four lines | Working Set |
| 2-6 Do Less at Once | implementation | group both passes one line at a time and reach 145 cycles without upgrading hardware | Blocking / Tiling |
| 2-7 Now Investigate | capstone | diagnose a fresh two-pass baseline, then reach 145 cycles with any valid learned approach | no new concept |

Observation levels require an official run plus an explicit evidence judgment; running alone cannot complete them. Implementation levels complete only from correct trace-derived performance evidence. The capstone deliberately gives no diagnosis or optimization hint. Its Program, Cache, and Work Group decisions stay locked until the given baseline produces an official receipt, then remain active after completion so the player can continue reducing cycles or hardware cost.

Game mode gates the chapter behind Chapter 1's final bottleneck diagnosis and follows the seven registered prerequisites. Test mode exposes every valid level through separate progress and receipts. Chapter and notebook progress remain session-local.

## Deterministic reference evidence

All reference runs use the same 4×4 integer data and return `88`.

| workload | access order | Cache lines | work group | total | CPU WAIT | hits | misses | RAM bytes | cost |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| one pass, direct RAM | row-first | 0 | whole | 257 | 240 | 0 | 0 | 64 | 0 |
| one pass | column-first | 1 | whole | 321 | 304 | 0 | 16 | 256 | 4 |
| one pass | row-first | 1 | whole | 105 | 88 | 12 | 4 | 64 | 4 |
| two passes | row-first | 1 | whole | 210 | 176 | 24 | 8 | 128 | 4 |
| two passes | row-first | 1 | one line | 138 | 104 | 28 | 4 | 64 | 4 |
| two passes | column-first | 4 | whole | 138 | 104 | 28 | 4 | 64 | 13 |

The capstone therefore has multiple real solutions. A four-line Cache retains the complete working set at cost 13. A one-line Cache plus line-sized blocking reaches the same 138 cycles at cost 4. Two-line/two-line-group combinations are also valid; cost is visible evidence rather than a completion gate.

## Simulation and evidence boundary

- `SimulationCore.run()` is unchanged and retains the v0.2 one-pass reference traces and metrics.
- `SimulationCore.run_workload()` is additive. It supports a direct-memory observation route plus one or two program passes and fixed 0/1/2/4-line work groups.
- The parsed `DSLProgram` remains authoritative. The scheduler derives every iteration address from the two nested loops and executes the actual inner IR body; it does not substitute a hidden row/column result.
- Direct reads emit CPU → Bus requests, Bus → RAM access, and RAM → Bus → CPU value returns. Cached reads retain the established request/lookup/hit/miss/fill/evict events and timing.
- Cache state is deterministic fully associative LRU with one outstanding request, as in v0.2. Blocking changes the authored order in which both workload passes consume program-derived iterations; it does not expose replacement-policy tuning.
- Trace metrics drive Profiler evidence, CPU WAIT, Run History, receipts, correctness, and completion before playback starts. Window state, GraphEdit geometry, playback speed, and language never feed simulation.

## Player-facing investigation tools

Each level exposes only the Mission, Program, Test Bench, nearby-storage choice, Work Group, Profiler, and Notebook windows needed for its primary task. Level 2-1 has no visible Cache node or Cache terminology. Level 2-2 initially labels the mechanism as nearby storage; completing the comparison reveals Cache/Hit/Miss in the Systems Notebook and updates the visible machine terminology.

Run History now leads with the latest Before → After pair. It names the only changed item when controlled, then shows total-cycle delta and percentage, CPU-WAIT delta, far-fetch/near-return counts, and RAM traffic. The prior raw-list presentation is no longer the main comparison surface.

The Systems Notebook contains the Chapter 1 concepts CPU WAIT, Controlled Comparison, and Bottleneck plus Chapter 2's Cache, Hit, Miss, Locality, Working Set, and Blocking/Tiling. Locked concepts display `???`; each entry appears only after its prerequisite experience and records a concise observation, explanation, causal diagram, and related concepts.

## Automated coverage

- `tests/test_simulation.gd` preserves all v0.2 invariants and adds exact direct-memory, two-pass, blocking, multi-solution, route, address-schedule, and determinism checks.
- `tests/test_locality_chapter_ui.gd` completes the normal seven-level path, verifies hub and prerequisite gates, tool exposure, observation judgments, delayed terminology, reference metrics, Before → After evidence, the capstone baseline lock, notebook unlocks, and two capstone solutions.
- `tests/test_ui.gd` retains deep v0.2 Apply/Trace/Profiler/floating-window/exact-curve coverage inside the two-pass capstone.
- Content-registry and localization suites verify the seven authored descriptors, dependencies, complete Chinese/English catalogs, and locale-independent simulation.

## Intentional limitations and playtest questions

- The model remains fixed at one 4×4 array, four integers per line, fully associative LRU, sequential requests, and no overlap or prefetch.
- Program editing remains the bounded Python-shaped DSL; Work Group is a small authored control rather than a programming exercise.
- Progress, receipts, Run History, Notebook entries, and tool use are not persisted or exported as analytics.
- Procedural device cards and floating windows are playtest UI, not production art or audio.

External playtesting should determine whether players inspect Trace before choosing observation judgments, understand the 2-3 “Cache present but still slow” reversal, distinguish poor access order from an oversized working set, discover more than one capstone solution, and voluntarily reopen Trace/Profiler in the unguided capstone. Those results should drive pacing and copy changes before adding new cache mechanisms.
