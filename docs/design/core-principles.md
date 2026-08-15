# Core design principles

These principles summarize the settled direction supported by the project discussion. They are not a full game design document.

## Settled direction

- The central puzzle is data movement: a player should be able to change an access pattern, observe a materially different trace, and use profiler evidence to explain the performance change.
- Hardware wiring, a deliberately small editable program, automatic Cache behavior, readable data-flow playback, and profiling belong in one feedback loop.
- The game should expose the concepts relevant to a decision while hiding machine details that do not improve that decision. The current DSL is intentionally much smaller than a general language.
- Performance feedback must be causal and legible. Metrics and animation should tell the same story because both originate from one deterministic simulation trace.
- Hardware is modeled as hardware. In particular, Cache contents are managed by the simulation rather than manually placed by the player.
- Complexity should be earned by validated play. A prototype may use explicit simplifications instead of suggesting realism it does not implement.

## Current prototype choices, not permanent product rules

- A single 4×4 row-major array-sum challenge isolates cache locality.
- Column-first and row-first traversal provide a controlled before/after comparison.
- Cache capacities of 1, 2, or 4 lines create a simple cost-versus-performance choice.
- Fixed teaching costs, a fully associative deterministic LRU Cache, and one outstanding load keep the explanation tractable.
- A desktop-first functional UI is sufficient for the current experiment.

These choices can change in a later, explicitly scoped design task. They should not be generalized into new systems without evidence.

## Open design questions

- Does manual wiring create meaningful reasoning after the first run, or is it only setup friction?
- What trace speed, emphasis, and profiler language best help a player form the right mental model?
- How much programming syntax remains approachable while still giving players genuine optimization agency?
- What structure would turn a successful vertical slice into a sustained game experience?
- What level of visual polish is needed before external playtesting produces useful feedback?

The repository currently has no settled answer to these questions. Record future decisions with evidence rather than treating possibilities from discussion as commitments.
