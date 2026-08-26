# Chapter 2: Reducing Data Movement

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

Observation levels require an official run plus an explicit evidence judgment; running alone cannot complete them. Implementation levels complete only from correct trace-derived performance evidence. A qualifying receipt from 2-1, 2-3, or 2-5 becomes the read-only Before evidence in its paired 2-2, 2-4, or 2-6 level, so the player does not repeat an identical baseline run before making the new decision.

Non-capstone completion enters a pending-finding state. The successful Trace remains visible and must finish playback before **Open finding** appears; only that explicit review commits completion and reveals the lesson or new terminology. The capstone likewise requires its given baseline first, but keeps Program, Cache, Work Group, and the detailed Profiler and Run History breakdowns locked until the player diagnoses the repeated far fetches from raw totals, CPU WAIT, request count, Trace, and data flow. The first post-diagnosis experiment may change only one lever until its official Trace is observed; only then can the chapter complete and all learned controls be combined for further optimization.

Game mode gates the chapter behind Chapter 1's final bottleneck diagnosis and follows the seven registered prerequisites. Test mode is an explicit QA sandbox: it exposes every valid level through separate progress and receipts and skips the capstone's diagnosis/decision locks and hidden-breakdown presentation. Game completion persists in the global save, and Notebook unlocks are derived from that sanitized completion; Test progression remains session-local.

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
- Trace metrics drive Profiler evidence, CPU WAIT, Run History, receipts, correctness, and completion before playback starts. Window state, GraphEdit geometry, the user-selected presentation Clock Period, and language never feed simulation.
- Cross-level Before evidence is accepted only when its source level, official data, program signature, access order, Cache configuration, pass count, and work grouping match the authored pair. The receipt stays immutable; the destination level merely presents it.
- **Next evidence** pauses on the next near return, far fetch, eviction, RAM access, or result boundary, while **Finish Trace** consumes the remaining presentation immediately. Both move only the playback cursor; neither edits the authoritative event list, metrics, or receipt.

## Player-facing investigation tools

Each level exposes only the Mission, Program, Test Bench, nearby-storage choice, Work Group, Profiler, and Notebook windows needed for its primary task. Level 2-1 has no visible Cache node or Cache terminology. Level 2-2 initially labels the mechanism as nearby storage; completing the comparison reveals Cache/Hit/Miss in the Systems Notebook and updates the visible machine terminology.

Run History now keeps the first authored or inherited receipt as Baseline and compares it with the current run. It names the only changed item when controlled, then shows total-cycle delta and percentage, CPU-WAIT delta, far-fetch/near-return counts, and RAM traffic. After a third official run it also retains a Personal Best chosen by lowest cycles, then lowest cost. The prior raw-list presentation is no longer the main comparison surface.

Before the capstone diagnosis, Profiler and Run History expose only the correctness result, total cycles, CPU WAIT, request count, and raw Trace navigation; both withhold the near-answer hit/miss, traffic, cost, and wait-category breakdowns. After passing, **Finish chapter** opens a Baseline → Best debrief showing total-cycle and CPU-WAIT improvements, hardware cost, and the best passing configuration; it does not impose a cost gate or choose one canonical solution.

Profiler also groups memory evidence by pass and, when blocking is active, by work group plus pass. Each cycle-labeled child remains selectable for exact Trace inspection, making whole-workload versus grouped scheduling visible without inventing a second execution model.

The Systems Notebook contains the Chapter 1 concepts CPU WAIT, Controlled Comparison, and Bottleneck plus Chapter 2's Cache, Hit, Miss, Locality, Working Set, and Blocking/Tiling. Locked concepts display `???`; each entry appears only after its prerequisite experience and records a concise observation, explanation, causal diagram, and related concepts.

## Automated coverage

- `tests/test_simulation.gd` preserves all v0.2 invariants and adds exact direct-memory, two-pass, blocking, multi-solution, route, address-schedule, and determinism checks.
- `tests/test_locality_chapter_ui.gd` completes the normal seven-level path and verifies hub/prerequisite gates, inherited pair baselines, pass/work-group schedule evidence, key-evidence/end Trace navigation, successful-Trace review before concept reveal, raw-evidence capstone diagnosis before controls/breakdown unlock, reference metrics, Before → After plus Personal Best evidence, Notebook unlocks, the Baseline → Best debrief, and two capstone solutions.
- `tests/test_ui.gd` retains deep v0.2 Apply/Trace/Profiler/floating-window/exact-curve coverage inside the two-pass capstone.
- Content-registry and localization suites verify the seven authored descriptors, dependencies, complete Chinese/English catalogs, and locale-independent simulation.

## Intentional limitations and playtest questions

- The model remains fixed at one 4×4 array, four integers per line, fully associative LRU, sequential requests, and no overlap or prefetch.
- Program editing remains the bounded Python-shaped DSL; Work Group is a small authored control rather than a programming exercise.
- Game completion persists as the minimum prerequisite set, and Notebook unlocks are derived again after load. Receipts, Run History, transient Notebook presentation, and Test progress remain session-local. The separate playtest observer records only bounded semantic actions and counters, never these authoritative objects or full player-authored contents; see [`playtest-instrumentation.md`](playtest-instrumentation.md).
- Procedural device cards and floating windows are playtest UI, not production art or audio.

External playtesting should determine whether players use the carried-forward evidence instead of treating paired levels as unrelated tasks, inspect Trace before opening a finding, understand the 2-3 “Cache present but still slow” reversal, distinguish poor access order from an oversized working set, diagnose the capstone before guessing a replacement part, and discover more than one solution. Those results should drive pacing and copy changes before adding new cache mechanisms.
