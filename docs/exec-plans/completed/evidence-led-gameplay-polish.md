# Evidence-led gameplay polish

## Goal

Make the existing Chapter 1 and Chapter 2 content reliably produce a player-led investigation: official evidence must remain comparable, conclusions must follow observation, and the final challenge must require a diagnosis before optimization.

## Scope

- Delay Chapter 2 completion reveals until the successful Trace has finished and the player explicitly reviews the finding.
- Require raw-evidence diagnosis before the Chapter 2 capstone unlocks modifications, while preserving multiple valid solutions and a non-gating cost comparison.
- Keep Chapter 1 official comparisons on the authored workload and lock the first final diagnosis to the authored machine.
- Improve Trace navigation and comparison presentation enough to make long runs inspectable without changing simulation timing.
- Correct the Chapter 2 hub identity, add a concise chapter debrief, and update localization, status/design documentation, and tests.

## Non-goals

- No new cache policy, prefetching, concurrency, multicore, or Chapter 3 content.
- No rewrite of deterministic simulation, receipts, content registries, or floating-window architecture.
- No campaign persistence, telemetry backend, release packaging, or production art pass in this batch.
- No hard cost gate or single canonical capstone solution.

## Affected subsystems

- Chapter 2 controller/catalog/state and UI integration tests.
- Chapter 1 controller/catalog and system-lab tests.
- Hub copy, chapter completion presentation, localization, and status/design/testing documentation.

## Invariants

- Simulation results remain deterministic and presentation speed never changes metrics or receipts.
- Graph/program state remains authoritative; UI summaries are derived evidence.
- Official receipts are immutable snapshots and invalidated when authoritative inputs change.
- A controlled comparison changes exactly one intended variable.
- Chapter 1 final cycle-share breakdown remains hidden until the first diagnosis.
- Chapter 2 terminology remains experience-first and is revealed only after the corresponding finding.
- Game and Test mode progression remain isolated.

## Decisions

- Evidence review is an explicit player action after playback, matching the proven Chapter 1 interaction instead of adding a new tutorial layer.
- Custom programs remain available for debugging/free experimentation but cannot satisfy authored Chapter 1 progression.
- Chapter 2 paired levels inherit an exact qualifying baseline receipt instead of asking the player to rerun an identical configuration.
- The capstone's detailed Profiler and Run History evidence share one diagnosis gate. Before diagnosis they expose total cycles, CPU WAIT, request count, Trace, and data flow only.
- The first post-diagnosis experiment remains a one-lever comparison until its current official Trace has been finished. A prior target receipt or a later baseline playback cannot satisfy that observation boundary.
- Trace compression is presentation-only. The complete authoritative event sequence remains available to Profiler and tests, and schedule metadata does not change canonical Trace signatures.

## Outcome

- Chapter 1 progression evidence now requires each level's authored program. Custom programs still run and explain their Trace but are labeled debug-only.
- The final Chapter 1 diagnosis restores and locks the authored program and default machine; any first answer reveals the breakdown, while only the correct answer reopens the sandbox.
- Chapter 2 short investigations preserve the successful Trace until playback and explicit finding review are complete, with concept names revealed afterward.
- Paired observation/implementation levels reuse strict read-only Before evidence, removing three redundant baseline runs.
- The capstone requires its exact baseline, raw-evidence diagnosis, one observed first change, and a current observed target run before completion. Hardware and software solutions remain valid at 138 cycles.
- Run History presents Baseline → Current, sole changes, total/CPU-WAIT deltas, memory evidence after its gate, and a cycle-first cost-tiebroken Personal Best.
- Trace offers Next evidence and Finish Trace, while Profiler groups memory evidence by pass and work group from the same deterministic event list.
- The hub, final debrief, Chinese/English localization, design/status/testing documentation, and automated coverage reflect the final behavior.

## Verification

- All eleven Godot simulation, UI, registry, progression, and localization suites passed in the final source state.
- Game-mode and Test-mode startup smokes exited successfully with no script, parse, invalid-call, assertion, RID, or ObjectDB error patterns.
- Focused Chapter 2 coverage proves diagnosis-time History hiding, Step → Next evidence cursor behavior, observed-first-experiment gating, re-entry resistance, current-target completion, two valid capstone solutions, and Baseline → Best debrief evidence.
- `git diff --check` passed.

## Deferred work

- Reusing a Chapter 1 CPU-comparison baseline as the following RAM-comparison baseline remains deferred because Chapter 1 receipts are intentionally bound to level ID and test-set identity. Changing that would broaden receipt semantics beyond this gameplay-polish batch.
- Cross-session campaign persistence, local playtest logging, release packaging, accessibility settings, and prologue restructuring remain separate follow-up work.
