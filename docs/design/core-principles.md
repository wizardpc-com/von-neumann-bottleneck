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
- A performance investigation should make the player's reasoning observable: predict an outcome, run a controlled experiment, inspect Trace and Profiler evidence, explain the waiting, then diagnose the bottleneck.
- Evidence should be progressively disclosed. Raw totals, CPU waiting, data flow, and controlled deltas may support a diagnosis, while a near-answer such as the complete CPU/RAM/Bus cycle breakdown should wait until the player has committed one.
- A successful run should remain observable before its lesson appears. Trace playback and evidence tools stay available until the player explicitly opens the finding; a completion overlay must not cover the evidence that earned it.
- An observation/solution pair should preserve qualifying evidence across its level boundary. Repeating an identical baseline is setup, not a new decision; the next level should inherit that immutable receipt as its Before state.
- One level should carry one primary cognitive task. Observation may create a question, exploration may expose a mechanism, implementation may prove a technique, and a capstone may integrate them; a short level should not attempt all four at once.
- Prefer experience before terminology. A mechanism may first appear in concrete language such as nearby storage or active data, then enter the Systems Notebook as Cache or Working Set only after the player has observed and explained it.
- Low-level construction is justified only when topology is a real player decision. Hardware Foundations therefore evaluates the displayed graph and lets multiple equivalent circuits pass; the fixed locality machine remains automatically wired because its topology is not that level's decision.
- Abstraction should preserve ownership. Sealing a verified circuit must retain the player's implementation and named interface rather than silently replacing it with hidden built-in behavior.
- Repetition without a new idea is not a construction puzzle. After a player proves the one-bit ALU or register concept, the prologue generates a four-bit wrapper with explicit provenance instead of demanding four identical copies.
- Stateful hardware must be learned through visible state transitions. Latch, register, RAM, and CPU Test Benches execute bounded deterministic step sequences; animation presents those completed results and never supplies the state transition itself.

## Current prototype choices, not permanent product rules

- A fixed 4×4 row-major data set plus one- and two-pass workloads isolates Cache locality, working-set capacity, and blocking without adding a general workload language.
- Column-first and row-first traversal provide a controlled before/after comparison.
- Cache capacities of 1, 2, or 4 lines create a simple cost-versus-performance choice.
- Fixed teaching costs, a fully associative deterministic LRU Cache, and one outstanding load keep the explanation tractable.
- A desktop-first functional UI is sufficient for the current experiment.
- The access-order goal is correctness plus no more than 105 cycles; blocking and the capstone use 145 cycles for the two-pass workload. Hardware cost remains evidence rather than a second pass/fail gate.
- Chapter 2 uses seven short nodes: three observations, one exploration, two implementations, and one unguided capstone. Observation completion requires an evidence judgment, not only pressing Run.
- Mission, Program, Test Bench, Profiler, nearby-storage choice, Work Group, and Systems Notebook open as independent embedded instruments. Each level exposes only those needed for its primary task; players may arrange visible tools without changing simulation.
- Chapter 2 component feedback is temporally staged: the active component processes the packet, wire travel separates endpoints, and the next component activates only after receipt. Hardware Foundations instead presents every component ready in the same causal wave in parallel.
- Run History should preserve the authored baseline and present Baseline → Current, naming the changed item and total/CPU-wait deltas before listing raw run facts; later experiments may add a separate Personal Best without replacing that baseline.
- Trace navigation may jump between consequential evidence or directly to the end, but it must retain the complete authoritative event sequence and preserve the same post-playback review boundary.
- The capstone introduces no new mechanism or optimization hint. It first locks changes long enough to capture the given baseline, then requires a raw-evidence diagnosis before revealing the detailed breakdown. Its first post-diagnosis experiment changes one lever, and its current official Trace must be observed before combinations reopen; after that controlled comparison it accepts multiple hardware/software solutions and remains runnable after completion.
- Chapter 1 progression uses each level's authored workload. Custom programs remain executable for debugging, but cannot create controlled-comparison receipts; the first final diagnosis also remains bound to the authored machine configuration.
- A program edit must expose its semantic effect before execution and its measured effect after execution; loop-order changes should never look like inert text edits.
- Editing and execution are separate player actions. Strategy loading or typing changes a draft; only explicit confirmation may replace the program used by the machine.
- In Hardware Foundations, Mission and Test Bench behave as desktop-style windows over the circuit board: they may coexist, move, resize, minimize, close, and restore without changing simulation.
- The CPU-construction prologue uses a four-bit accumulator, two-word RAM, and an external instruction stream. These are teaching boundaries for LOAD/STORE data movement, not a general ISA or realistic CPU claim.
- Chapter 1 uses five short nodes. Its CPU, RAM, and Bus investigations each bind a prediction to a baseline and one-part change; the final node absorbs 4/16/64 workload scaling into the actual bottleneck diagnosis instead of preserving a decision-free scale-only level.

These choices can change in a later, explicitly scoped design task. They should not be generalized into new systems without evidence.

## Open design questions

- What trace speed, emphasis, and profiler language best help a player form the right mental model?
- How much programming syntax remains approachable while still giving players genuine optimization agency?
- What structure would turn a successful vertical slice into a sustained game experience?
- What level of visual polish is needed before external playtesting produces useful feedback?
- Which component-specific processing animations best communicate CPU, Cache, Bus, RAM, checking, and profiling without implying false simulated latency?
- Does each construction step introduce a genuinely new design decision, or do later levels feel like mechanical wiring despite reusable components and generated word wrappers?
- Do players carry Chapter 1's CPU-WAIT investigation habit into Chapter 2 without being forced to open Profiler?
- Does the 2-3 “Cache present but still slow” reversal lead players to inspect address order rather than guess at hardware speed?
- In the capstone, do players voluntarily use Trace/Profiler and discover both capacity and blocking solutions?

The repository currently has no settled answer to these questions. Record future decisions with evidence rather than treating possibilities from discussion as commitments.
