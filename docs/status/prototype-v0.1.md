# Prototype v0.1 status

The annotated Git tag `prototype-v0.1` preserves the initial cache-locality vertical slice before repository bootstrap changes.

## What it implements

- One 4×4 row-major integer-array sum challenge with fixed Official Data and editable Debug Data.
- Program Controller, CPU, Cache, Bus, RAM, Test Bench, and Profiler nodes in a GraphEdit bench.
- Six exact required links, automatic wiring restoration, and run blocking when required ports are disconnected.
- A minimal DSL with registers, two fixed-range loops, `load`, `add`, a final result `store`, and two-dimensional array indexing.
- Deterministic simulation with 1-, 2-, or 4-line fully associative LRU Cache choices and fixed hardware costs.
- Precomputed trace events for requests, lookups, hits, misses, Bus/RAM activity, fills, evictions, compute, and result storage.
- Pause, resume/replay, single-step, speed selection, progress, event text, and animated device paths.
- Profiler totals for compute/wait/overall cycles, Cache hits/misses, RAM bytes, hardware cost, correctness, and like-for-like traversal comparison.

## Verified reference behavior

For the fixed Official Data with a one-line Cache, both traversals return the correct sum `88`.

| traversal | total cycles | compute | wait | hits | misses | RAM bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| column-first | 321 | 17 | 304 | 0 | 16 | 256 |
| row-first | 105 | 17 | 88 | 12 | 4 | 64 |

The headless simulation and UI tests assert these results, trace determinism, playback non-mutation, wiring, input isolation, stale-state invalidation, and the row-first comparison.

## Known limitations and shortcuts

- The prototype contains one workload, one fixed Official Data array, and fixed four-iteration loops.
- Wiring validates a prescribed topology; it is not yet a general hardware-graph simulation.
- The DSL parser and execution model exist only for this challenge and deliberately omit general language behavior.
- The Cache is fully associative, one request is outstanding at a time, and there is no prefetch or overlap.
- Cycle values are teaching constants rather than calibrated hardware measurements.
- The final store writes to Test Bench, not back to cached memory.
- Most UI is constructed in one large `main.gd`; this was expedient for a vertical slice.
- Layout targets a 1600×900 desktop view; dense side panels rely on scrolling at lower vertical space.
- Tests are custom SceneTree scripts rather than an external Godot test framework.
- Visuals are functional and use built-in controls; there is no production asset pipeline.

## Unresolved gameplay questions

Automated tests establish correctness, not whether the experience teaches effectively. Playtesting is still needed to determine whether wiring offers meaningful choice, whether trace playback is readable at useful speeds, whether profiler explanations create the intended insight, and whether the programming surface is approachable.

## Validation purpose

This prototype was built to test one loop: change memory access order, observe fewer Cache misses and a different data-flow trace, and understand the resulting cycle reduction through the Profiler. It does not validate a full game structure, long-term progression, or final presentation.
