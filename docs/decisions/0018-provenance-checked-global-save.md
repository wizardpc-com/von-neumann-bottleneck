# 0018 — Provenance-checked global Save / Continue

## Status

Accepted for the first friends playtest on 2026-08-27.

## Context

Players may spend 30–60 minutes across Hardware Foundations and two connected chapters. Session-only progression forces a complete restart after a normal exit, but reusable components cannot be recovered safely from completion flags alone. Their validity depends on the player's visible source topology, embedded reusable bindings, and the deterministic official Test Bench. Hardware workbenches already persist that topology independently.

## Decision

One autoloaded `GlobalSave` service owns a version-1 Game-only recovery index at `user://savegame_v1.json`. It stores the `PlayerContentState` manifest, Chapter 1 completion and CPU/RAM handoff signatures, and Chapter 2 completion. Notebook concepts are derived from restored completion requirements. Receipts, Trace position, editor history, selections, clipboard, debug inputs, window geometry, runtime memory, telemetry, and Test progression are excluded.

The manifest is not reusable-component authority. On load, primary reusable components are restored in registered dependency order only when a Game workbench reconstructs to the saved source signature, all nested reusable bindings match already revalidated sources, and the current official verifier passes. Generated wrappers are recreated from the current catalog recipe and verified source signature. Missing or mismatched evidence invalidates only that level and its registered dependents; Chapter 1 and Chapter 2 gates are accepted only after their upstream provenance remains valid.

Writes use a validated temporary JSON document, replacement of the primary, and one previous valid backup. Corrupt primary data may recover from that backup. Unknown future schemas disable automatic writes. Continue opens the deepest valid chapter map rather than a transient screen. New Game requires confirmation, preserves telemetry and exports, and keeps workbenches unless the player explicitly clears only the Game namespace.

## Alternatives considered

- Persisting completion flags alone would fabricate HalfAdder/ALU/Register/RAM/TinyComputer rewards without source evidence.
- Copying every circuit into the global save would create two competing topology authorities and synchronization failures with named workbenches.
- Persisting all receipts and UI state would enlarge and couple the schema without improving ordinary continuation.
- Treating telemetry as recovery input would violate its non-authoritative observer boundary.
- Saving Test progression would make developer shortcuts indistinguishable from player achievement.

## Consequences

- A normal player can resume meaningful Game progress across launches without weakening deterministic evidence.
- Deleting or changing one required source workbench may require replay of that design and its dependents, while an independent valid branch survives.
- Continue resumes at a chapter map; incomplete local evidence and transient UI state restart cleanly.
- Save schema upgrades require an explicit future migration or refusal path rather than implicit coercion.
- Workbench and global-save files remain independently useful but must be reconciled on every load.
