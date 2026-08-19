# ADR 0002: staged animation and floating instruments

- Status: Accepted; generic orbit superseded by ADR 0012
- Date: 2026-08-15

## Context

Direct inspection of the first v0.2 presentation found three causal-clarity failures. One event strongly highlighted several components simultaneously; a packet moved from an input port to an output port without visible component work; and mutually exclusive right-side drawers prevented Program and Profiler evidence from remaining visible together. Program edits executed correctly in tests but did not expose enough immediate or post-run proof to the player.

## Decision

- Each event is presented as a continuous sequence of component-processing and wire-transfer sections. Instruction events prepend Program → CPU; simulation routes remain unchanged.
- The active component draws a local two-turn processing orbit and is the only strongly highlighted component. During a wire section neither endpoint is strongly highlighted. Muted CPU waiting text may preserve context.
- Only a short packet tail is drawn. Future component-processing paths remain invisible until the packet reaches them.
- Inter-component sections continue to use actual GraphEdit curves, while entry → processing center → exit creates continuous travel inside a component. These presentation sections add no simulation cycles.
- Program, Test Bench, Profiler, and Cache become embedded floating instruments that may coexist, move, resize, and close independently. They remain open during runs and Inspect in Trace.
- Program shows a live traversal/address preview derived from parsed IR, marks edits stale, and records traversal, cycles, misses, and exact source after the next run.

## Alternatives considered

- Keep simultaneous endpoint highlighting and add more labels: rejected because it still obscures event order.
- Split every presentation phase into additional `SimulationEvent` objects: rejected because component animation timing is not simulated work and would pollute the authoritative trace.
- Use native OS windows: rejected because embedded instruments must remain in screenshots, headless scene tests, and the workbench coordinate system.
- Keep exclusive drawers and add tabs: rejected because Program and Profiler cannot be compared simultaneously.
- Add an Apply/Compile copy of the program: rejected because Test Bench already executes the current source; an extra copy would create stale-state risk.

## Consequences

- Packet position, processing indicator, and strong component highlight share one normalized presentation route.
- Component-internal travel is visually explanatory but must never be interpreted as additional simulated latency.
- Multiple instruments can cover parts of the machine; players can reposition, resize, or close them, and layout persistence remains out of scope.
- Program changes are visible both semantically before a run and quantitatively after it.
