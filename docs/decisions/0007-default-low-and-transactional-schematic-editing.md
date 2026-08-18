# ADR 0007: default-low ports and transactional schematic editing

## Status

Accepted for Hardware Foundations 01.

## Context

The previous live-analysis milestone treated a port with no incoming segment as high impedance. The player now requires unconnected ports to behave as low, while retaining red/green/gray electrical feedback. The editor also needs familiar desktop shortcuts and Turing Complete-style multi-selection; extending only the existing one-way "undo latest wire" function would make paste, group movement, deletion, and Clear Wires inconsistent.

The public [Turing Complete controls documentation](https://turingcomplete.wiki/wiki/Controls) defines undo/redo, copy/paste, component and wire-node selection, and Shift area selection. This project adopts those outcomes without copying assets or replacing its existing wiring/eraser gestures.

## Decision

- Resolve exactly zero incoming segments as low. If one or more segments are present, retain normal tri-state resolution: all `Z` remains explicit high impedance, matching active values agree, and low/high conflict is a short circuit.
- Remove the simulator's separate "input wire required" rule so continuous feedback and official/debug execution share the same default-low semantics. Missing external Test Bench values remain errors.
- Store editor changes as reversible transactions containing added/removed components, added/removed segments, position maps, and optional selection state. Undo applies the inverse; redo reapplies the forward transaction.
- Clear the redo stack whenever a new transaction is committed after Undo. Treat branch creation, endpoint movement, continuous erase, selected deletion, Clear Wires, Auto Layout, pasted subgraphs, and one node-move gesture as atomic actions.
- Map `Ctrl+Z` to Undo, `Ctrl+Y` and `Ctrl+Shift+Z` to Redo, and `Ctrl+C`/`Ctrl+V` to an in-session structured schematic clipboard.
- Let Shift-click and Shift-drag toggle selection of components and explicit wire nodes. Keep GraphNode cards transparent and show selection with a procedural cyan circular halo.
- Copy only selected non-terminal components and connections whose two endpoints are selected. Do not duplicate fixed Test Bench terminals or boundary-crossing wires. Give pasted components deterministic monotonic IDs and select the pasted group.

## Consequences

- An untouched AND/OR input is immediately red/low; an untouched NOT input is red and its output is green. A connected explicit `Z` remains gray.
- The player can prototype repeated logic without rebuilding every gate chain, while the fixed A/B/SUM/CARRY interface stays unique.
- Undo/redo restores model and view together instead of repairing only visible connections.
- The clipboard and history are intentionally scene/session-local; no OS text format, persistence, inventory cost, cut, rotation, or cross-level paste is implied.
