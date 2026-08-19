# ADR 0013: functional schematic shapes and single-wire rendering

- Status: Accepted
- Date: 2026-08-19

## Context

The first component-aligned animation pass stopped drawing substitute models, but higher-level components were still generic text rows and their processing feedback did not identify which values entered or which output changed. Level input, output, and constant hardware also reused overly similar round forms. Separately, GraphEdit drew every settled cable while a custom signal layer drew the same complete curve again; at bends and zoom levels one connection could look like two stacked wires.

Public Turing Complete 2 notes describe the presentation outcomes used as references here: consistent updated component shapes, IEEE-style wide gates, larger and distinct component I/O pins, hover-visible pin names, and an address cursor on RAM. The component catalog confirms the relevant functional categories. These are reference principles only; no source, exact assets, proprietary geometry, or animation timing is copied.

References:

- <https://steamcommunity.com/app/1444480/announcements/> (`Turing Complete 2 patch notes`)
- <https://turingcomplete.wiki/wiki/Components>
- <https://turingcomplete.wiki/w/index.php?title=Save_breaker_changes>

## Decision

- Basic AND, OR, NOR, and NOT remain procedural standard-style silhouettes with lowercase English function names. Level input and output use larger opposing directional tags; constants use a diamond; lamps and explicit junctions remain distinct.
- Encapsulated arithmetic, routing, control, and storage components use their actual functional module surface rather than a generic text card. Current profiles include adder sigma, mux wedge, notched ALU, decoder/control fan-out, register/latch mark, truthful two-word-by-four-bit RAM grid, and split CPU/memory mark.
- Full port names and widths remain available in the component tooltip. Compact edge labels keep dense CPU circuits readable.
- Component events carry presentation-only input/output value descriptors into the displayed surface. Input tokens enter from their real rows, the fixed cyan process route remains inside the public module body, and only the event's real output port emits a red/green/gray token. Multi-bit tokens may show the word text.
- A RAM event with a known address highlights the matching one of its two displayed word rows. An SR-latch Q state event does not falsely duplicate Q onto NQ.
- Red, green, and gray remain signal-state colors for ports, wires, and moving tokens. Component bodies stay neutral except for fixed cyan processing or selection feedback.
- GraphEdit is the only renderer of a settled full connection path. The duplicate complete signal-wire layer is removed. Playback may add one short centered tail and data marker, never another complete cable; hover/drag guides remain transient centered feedback.

## Alternatives considered

- Keep generic module rectangles and add richer floating animations: rejected because the animation would again communicate geometry not present in the player's circuit.
- Reveal the sealed component's internal source circuit during every event: rejected because it would overwhelm the CPU view and break the abstraction boundary.
- Keep both settled wire layers but align them more carefully: rejected because duplicate authorities can drift again under transforms and are unnecessary when GraphEdit already owns the visible path and live endpoint colors.

## Consequences

- Component kind, active pins, and value direction are readable without a second animation model.
- Dense high-level circuits use small public-interface diagrams rather than decorative internals; inspection of the source circuit remains a separate future feature.
- One visible connection is now one cable at rest. Signal trace storage is still retained for diagnostics/tests even though it no longer owns a second full-path drawing layer.
- Simulation results, event ordering, electrical resolution, causal waves, and tick costs are unchanged.
