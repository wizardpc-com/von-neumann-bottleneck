# Core design principles

These principles summarize the settled direction supported by the project discussion. They are not a full game design document.

## Settled direction

- The central puzzle is data movement: a player should be able to change an access pattern, observe a materially different trace, and use profiler evidence to explain the performance change.
- Hardware wiring, a deliberately small editable program, automatic Cache behavior, readable data-flow playback, and profiling belong in one feedback loop.
- The game should expose the concepts relevant to a decision while hiding machine details that do not improve that decision. The current DSL is intentionally much smaller than a general language.
- Performance feedback must be causal and legible. Metrics and animation should tell the same story because both originate from one deterministic simulation trace.
- Hardware is modeled as hardware. In particular, Cache contents are managed by the simulation rather than manually placed by the player.
- Complexity should be earned by validated play. A prototype may use explicit simplifications instead of suggesting realism it does not implement.
- Setup that creates no decision should not masquerade as gameplay. The current fixed machine topology is automatic; devices remain draggable only to support visual organization.
- Investigation should be player-directed. Profiler exposes facts and trace navigation but does not prescribe the optimized program.
- Low-level construction is justified only when topology is a real player decision. Hardware Foundations therefore evaluates the displayed graph and lets multiple equivalent circuits pass; the fixed locality machine remains automatically wired because its topology is not that level's decision.
- Abstraction should preserve ownership. Sealing a verified circuit must retain the player's implementation and named interface rather than silently replacing it with hidden built-in behavior.
- Repetition without a new idea is not a construction puzzle. After a player proves the one-bit ALU or register concept, the prologue generates a four-bit wrapper with explicit provenance instead of demanding four identical copies.
- Stateful hardware must be learned through visible state transitions. Latch, register, RAM, and CPU Test Benches execute bounded deterministic step sequences; animation presents those completed results and never supplies the state transition itself.

## Current prototype choices, not permanent product rules

- A single 4×4 row-major array-sum challenge isolates cache locality.
- Column-first and row-first traversal provide a controlled before/after comparison.
- Cache capacities of 1, 2, or 4 lines create a simple cost-versus-performance choice.
- Fixed teaching costs, a fully associative deterministic LRU Cache, and one outstanding load keep the explanation tractable.
- A desktop-first functional UI is sufficient for the current experiment.
- The Official goal is correctness plus no more than 105 cycles. Hardware cost remains evidence rather than a second pass/fail gate.
- Program, Test Bench, Profiler, and Cache open as independent embedded instruments. Players decide which evidence must coexist and may arrange or resize the windows without changing simulation.
- Cache Locality Lab component feedback is temporally staged: the active component processes the packet, wire travel separates endpoints, and the next component activates only after receipt. Hardware Foundations instead presents every component ready in the same causal wave in parallel.
- A program edit must expose its semantic effect before execution and its measured effect after execution; loop-order changes should never look like inert text edits.
- Editing and execution are separate player actions. Strategy loading or typing changes a draft; only explicit confirmation may replace the program used by the machine.
- In Hardware Foundations, Mission and Test Bench behave as desktop-style windows over the circuit board: they may coexist, move, resize, minimize, close, and restore without changing simulation.
- The CPU-construction prologue uses a four-bit accumulator, two-word RAM, and an external instruction stream. These are teaching boundaries for LOAD/STORE data movement, not a general ISA or realistic CPU claim.

These choices can change in a later, explicitly scoped design task. They should not be generalized into new systems without evidence.

## Open design questions

- What trace speed, emphasis, and profiler language best help a player form the right mental model?
- How much programming syntax remains approachable while still giving players genuine optimization agency?
- What structure would turn a successful vertical slice into a sustained game experience?
- What level of visual polish is needed before external playtesting produces useful feedback?
- Which component-specific processing animations best communicate CPU, Cache, Bus, RAM, checking, and profiling without implying false simulated latency?
- Does each construction step introduce a genuinely new design decision, or do later levels feel like mechanical wiring despite reusable components and generated word wrappers?
- Does the final accumulator/RAM program make LOAD/STORE separation clear enough to justify entering the Cache Locality Lab?

The repository currently has no settled answer to these questions. Record future decisions with evidence rather than treating possibilities from discussion as commitments.
