# Content and player-design architecture

The campaign content system separates authored progression from executable electrical behavior. Its purpose is to make new branches, levels, Test Benches, copy, and rewards routine to add without turning untrusted content dictionaries into a programming language.

## Runtime flow

```text
explicit prologue content manifest
  -> retained content packs
  -> CampaignBranchDefinition + CampaignLevelDefinition
  -> deterministic CampaignContentRegistry validation/order/dependencies
  -> PrologueLevelCatalog compatibility facade
  -> generic campaign map, entry routing, unlocks, rewards, and invalidation

level builder + current player component library
  -> component inventory + automatic layout + official Test Bench + reference topology
  -> displayed graph authored by the player
  -> deterministic simulator and official evidence
  -> ReusableComponent
  -> PlayerContentState installs reward/generated wrappers and unlocks dependents
```

`src/content/prologue/prologue_content_manifest.gd` is the explicit root of the current prologue. It registers four ordered packs: foundations, arithmetic, storage, and integration. Explicit registration is intentional. It makes packaged builds deterministic and auditable and avoids relying on filesystem reflection or import order.

Each pack owns the things that normally change together:

- branch and level IDs, ordering, and semantic title/description keys;
- prerequisites and entry type;
- component inventory and initial readable layout;
- fixed official Test Bench cases or temporal steps;
- reference wires used only by tests/capture hooks;
- seal reward names and generated-wrapper recipes;
- small level-specific presentation/handoff metadata.

The generic campaign UI queries branches and levels from `PrologueLevelCatalog`. It does not keep a second list of level IDs. Entry routing is metadata (`tutorial`, `half_adder`, or ordinary `circuit`), and resealing invalidation follows the registered transitive dependency graph. Reward ownership is also registered, so removing dependent completion and library entries does not require a UI `match` statement.

## Validation contract

`CampaignContentRegistry.validation_errors()` fails closed on:

- duplicate branch or level IDs;
- empty/unknown branches and prerequisites;
- self-dependencies, repeated prerequisites, and dependency cycles;
- missing circuit builders or semantic copy keys;
- duplicate or ambiguous reward ownership;
- incomplete generated-wrapper recipes.

Branch and level order is explicit and deterministic, with stable ID ordering only as a tie breaker. Unknown level IDs never unlock. A registry retains its content providers because a Godot `Callable` bound to a released `RefCounted` would otherwise become invalid.

`tests/test_content_registry.gd` checks the built-in manifest and creates a synthetic branch/level/reward chain that is not known to the campaign UI. This proves the extension boundary rather than only retesting current IDs. `tests/test_localization.gd` recursively scans `src/content/`, so semantic keys introduced by future content packs must exist in both registered language catalogs.

## Player-owned content state

`PlayerContentState` owns the session component library and completion set. The Hardware Foundations controller retains its legacy dictionary aliases for UI/test compatibility, but installation and invalidation go through this domain object.

Installing a verified reusable design:

1. requires the owning level to declare the reward;
2. compares the replacement source signature with the previous design;
3. invalidates only registered transitive dependents and their declared rewards when the source changed;
4. installs the primary player topology/provenance;
5. creates any declared generated wrappers from the primary signature; and
6. marks the owning level complete.

The state exposes a deterministic canonical signature and a versioned `manifest_snapshot()`. The snapshot is a save-ready boundary for completion and provenance, not a disk save implementation: it deliberately does not claim that arbitrary topology can already be reconstructed across versions.

This boundary also gives future assisted/automatic design tools a safe integration point. Such a tool should produce a normal `LogicCircuit`, submit it to the same level Test Bench and deterministic simulator, and call `PlayerContentState.install_reusable()` only after the same official evidence succeeds. It must not write completion flags or inject a hidden truth-table result directly.

## Adding content built from existing mechanics

For a level in an existing branch:

1. add its descriptor and builder to the appropriate `src/content/prologue/*_content_pack.gd`;
2. declare stable IDs, ordering, dependencies, semantic localization keys, rewards, and any generated-wrapper recipe;
3. build its inventory/layout/reference graph and complete official Test Bench in that same pack;
4. add Chinese and English catalog entries;
5. add reference success/failure coverage and, when interaction differs, UI coverage;
6. run the content-registry, prologue simulation/UI, localization, and relevant circuit suites.

For a new branch, add one bounded pack and register it in `prologue_content_manifest.gd`. No campaign-map or invalidation change should be needed.

Content IDs and localization keys are durable identity. Player-facing words belong in PO catalogs; simulation values, topology, signatures, test vectors, and reward IDs do not.

## Adding a new mechanic or electrical primitive

A new arrangement of supported components is content. A new executable behavior is code.

Adding a genuinely new component kind still requires an explicit, reviewed vertical slice:

- fixed named port schema and widths in the circuit domain;
- deterministic evaluation/state semantics and diagnostics;
- gate delay/state-boundary rules independent of geometry;
- procedural symbol/feedback behavior where needed;
- canonical-signature and simulation tests;
- content inventory and Test Bench usage only after those mechanics exist.

This is deliberate. A universal dictionary evaluator or data-authored script would be an accidental HDL, weaken validation, and incorrectly force gates, CPU state, and Cache locality into one simulation model. The content registry reduces authoring duplication; it does not erase domain boundaries.

## Current limitations

- Current reusable definitions preserve a player circuit snapshot/signature, but opaque placement still selects one of the trusted built-in behavior kinds. Arbitrary recursively nested player-defined components are not implemented.
- The player-content manifest is session-only and cannot yet restore circuit topology. There is no save/load migration, mod loader, workshop, or untrusted content execution.
- The Hardware Foundations scene controller is still large. Campaign knowledge has moved out, but view extraction should be driven by measured change pressure rather than a broad rewrite.
- New storage timing, bus contention, Cache behavior, or locality objectives require their own deterministic domain design. They should reuse the Test Bench/player-evidence pattern where natural, not a speculative universal simulator.
