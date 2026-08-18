# ADR 0009: explicit campaign content registry and player-owned state

## Status

Accepted for the extensibility foundation after the CPU prologue.

## Context

The playable prologue grew from two levels to a branched nine-level sequence. Its behavior remained deterministic, but progression knowledge became duplicated across a hard-coded catalog, campaign-map calls, special level-ID dispatch, reward-generation branches, and downstream invalidation logic. Adding content therefore risked a partially visible or incorrectly invalidated level.

Reusable components also lived directly in the Hardware Foundations UI controller. Their source topology and provenance were preserved, but there was no domain owner for installing a replacement, generating derived wrappers, invalidating dependents, or exposing future save/automatic-design integration.

The project needs lower-cost content growth without creating a universal HDL or coupling the independent Cache Locality Lab to gate simulation.

## Decision

- Register campaign branches and levels explicitly through typed descriptors and retained content packs.
- Make deterministic order, entry kind, dependencies, semantic copy keys, reward ownership, generated-wrapper recipes, and level builders registry data.
- Keep component inventories, layouts, official Test Benches, and test-only reference topologies in the pack that owns the level.
- Retain `PrologueLevelCatalog` as a thin compatibility facade while the campaign UI queries the registry instead of maintaining its own level list.
- Validate duplicate/unknown IDs, dependency cycles, invalid builders, and ambiguous rewards before using content. Unknown levels fail closed.
- Let `PlayerContentState` own completion and the reusable library. Install verified designs and invalidate transitive dependents through registered reward ownership.
- Expose deterministic player-state identity and a versioned manifest boundary, but do not claim disk persistence or topology restoration yet.
- Require future assisted design tools to submit an ordinary graph to the same deterministic Test Bench and installation path as a manual design.
- Keep executable electrical semantics in trusted simulation code. New primitives require explicit port, evaluator, delay/state, presentation, and test changes; content data cannot define arbitrary behavior.

## Consequences

- A new level made from existing mechanics is localized to one content pack, language catalogs, and its tests. The campaign map, entry dispatch, unlock calculation, and downstream reward cleanup require no level-ID branch.
- A new branch requires a bounded pack plus one explicit manifest registration, making packaged content order reviewable.
- Replacing an upstream player design has one tested transaction for dependent completion and library provenance.
- Future save or automatic-design work has a domain boundary instead of mutating UI dictionaries, but the current manifest is not yet a stable save format.
- Arbitrary recursive player-defined components, mod loading, and new simulation mechanics remain visible follow-up work rather than implied features.
- The gate/prologue simulator and Cache Locality `SimulationCore` remain separate. They may share player-facing Test Bench patterns and semantic localization, not an unjustified universal execution model.
