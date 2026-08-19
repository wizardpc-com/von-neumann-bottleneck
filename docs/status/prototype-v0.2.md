# Prototype v0.2 status

Prototype v0.2 turns the tagged v0.1 technical slice into a focused gameplay-validation loop. The `prototype-v0.1` Git tag remains the historical baseline; v0.2 deliberately changes its DSL and interaction model.

## What it implements

- One editable Python-shaped program whose parsed nested IR is the only source executed by `SimulationCore`.
- A fixed, automatically laid-out machine topology with draggable components and an Auto Layout reset; this level no longer asks the player to perform prescribed wiring.
- Trace events that connect simulated cycles to source lines, exact hardware routes, single-focus component feedback, and cache-line evidence.
- Continuous packets that process inside one component, travel over actual GraphEdit connection curves, and process at the receiver; reverse RAM → Bus → Cache traffic explicitly dwells in all three components.
- Program, Test Bench, Profiler, and Cache floating instruments that are closed by default but may coexist, move, resize, minimize, and close independently.
- A Python-shaped reference, directly loadable column-first/row-first strategy drafts, parsed line-by-line explanation, explicit Apply Program confirmation, and a last-run receipt proving which applied source produced the measured cycles and misses.
- An openable Profiler with cycle/wait breakdown, individual miss evidence, exact source and array coordinates, returned line contents, trace navigation, and up to eight session runs.
- Replaceable 1-, 2-, and 4-line Cache choices with costs 4, 7, and 13.
- An Official target of correct result in at most 105 cycles. Hardware cost is recorded evidence, not a hard gate.
- Pause/resume, step, replay, 0.5×/1×/2×/4× speed, source highlight, component state badges, and animated control/data paths.

## Verified reference tradeoff

All runs below use the fixed Official Data and return the correct sum `88`.

| program | Cache lines | total cycles | hits | misses | RAM bytes | hardware cost | target |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| column-first | 1 | 321 | 0 | 16 | 256 | 4 | over |
| column-first | 2 | 321 | 0 | 16 | 256 | 7 | over |
| column-first | 4 | 105 | 12 | 4 | 64 | 13 | met |
| row-first | 1 | 105 | 12 | 4 | 64 | 4 | met |

This is the prototype's first explicit software-versus-hardware comparison: both the optimized one-line solution and the unoptimized four-line solution meet the same performance target, while Run History preserves their different hardware costs.

## Verified interaction contract

- Parser tests prove the exact address order comes from executable loop nesting, and reject old syntax, invalid ranges, and tabs.
- Canonical trace tests prove source, routes, details, events, and metrics remain deterministic.
- UI tests compare wire polylines with `GraphEdit.get_connection_line()` before and after moving Cache, then verify internal processing ranges and the multi-edge line-return path.
- Single-focus feedback, source highlight, instrument coexistence/movement/resizing, program preview/receipt, cache invalidation, Profiler drill-down, trace inspection, history, and both valid Official solutions are covered headlessly.
- Draft/applied/executed source separation is covered headlessly: unapplied strategies block Test Bench, Apply unlocks it, and the trace retains the exact applied source.
- Manual frame inspection confirms that Program, CPU, and Cache activate in sequence without pre-lighting later components; request and line-return packets dwell inside components, and Program plus Profiler remain contained side-by-side.

## Known limitations

- The prototype still contains one fixed-size workload, one Official dataset, and a very small language.
- Costs are deterministic teaching constants, not calibrated timing measurements.
- The topology is fixed and does not simulate arbitrary hardware graphs.
- Cache is fully associative, permits one outstanding request, and has no overlap or prefetch.
- Most UI composition remains concentrated in `main.gd`; built-in controls provide functional presentation rather than production art.
- Processing now stays on the actual displayed device body and state label; the former generic PROCESS orbit and radial indicator were removed. Richer component-specific animation remains presentation-only future work and may not invent hidden internals.
- Run History and traces are in-memory only; there is no save, progression, localization, telemetry, or CI pipeline.

## Remaining validation question

Automated and visual checks establish causal consistency, not teaching effectiveness. Playtesting must now determine whether players discover both solutions, use Profiler evidence before guessing, understand why the same 105-cycle outcome can have different hardware cost, and find the trace readable at useful speeds. That evidence should decide the next prototype rather than more cosmetic expansion of this slice.
