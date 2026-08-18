# Extensible content and player-design system execution plan

## Goal

Reduce the marginal cost and regression risk of adding campaign branches, levels, localized text, rewards, and player-owned designs. The immediate architectural milestone is to make campaign content declarative and registry-driven while preserving every current playable level.

The longer-lived product boundary is:

- content describes progression, inventory, benches, presentation keys, and rewards;
- deterministic simulation code defines executable electrical behavior;
- the UI queries registered content instead of maintaining a second hard-coded campaign map;
- player-built components retain authoritative topology and explicit provenance;
- localization remains presentation-only and can grow independently from simulation state.

## Scope

1. Introduce typed campaign branch and level descriptors plus a deterministic content registry.
2. Split the current prologue catalog into bounded content packs while retaining its public compatibility API.
3. Make the campaign map, entry dispatch, dependency invalidation, and reward lookup consume the registry.
4. Add validation that rejects duplicate IDs, unknown prerequisites, cycles, ambiguous rewards, invalid entry definitions, and missing semantic localization keys.
5. Add focused automated coverage proving that a synthetic branch and level can be registered without editing the campaign UI.
6. Document the extension contract and the remaining boundary for truly arbitrary player-authored components.
7. Assess and, if feasible without inventing a universal HDL, introduce a save-ready player-content state boundary for completed levels and reusable designs.

## Explicit non-goals

- No new Full Adder, ALU, storage, CPU, Cache, or locality gameplay in this milestone.
- No universal simulator shared by logic gates, CPU microarchitecture, cache locality, and later systems.
- No data-driven executable scripts, arbitrary HDL, mod loader, online workshop, or untrusted code execution.
- No speculative knowledge tree, production level editor, cloud save, or compatibility promise for an unreleased save format.
- No claim that a new electrical primitive is content-only: new simulation semantics still require explicit deterministic code and tests.
- No broad rewrite of the valuable v0.2 locality prototype or current Hardware Foundations editor.

## Affected files and subsystems

- `src/content/`: campaign descriptors, registry, reusable level-building helpers, and prologue content packs.
- `src/hardware_foundations/prologue_level_catalog.gd`: compatibility facade over registered content.
- `src/hardware_foundations/hardware_foundations.gd`: registry-driven map, entry routing, rewards, and invalidation.
- `tests/test_content_registry.gd`, prologue tests, UI tests, and localization tests: extension-contract and regression coverage.
- `docs/architecture/`, `docs/decisions/`, `docs/development/testing.md`, and this plan.
- Potentially a narrow player-content state object if it can replace UI-owned dictionaries without destabilizing the current editor.

## Invariants

- Simulation is deterministic; animation and UI never determine results.
- The displayed circuit graph remains authoritative for player-built topology.
- Ordinary wires and routing junctions remain zero-latency regardless of geometry.
- Campaign ordering and dependency traversal are deterministic and independent of dictionary iteration order.
- Content uses semantic localization keys; locale changes never alter IDs, topology, test vectors, rewards, signatures, or completion state.
- A level cannot silently unlock through a missing or cyclic prerequisite.
- Replacing a player design invalidates only registered transitive dependents and their declared rewards.
- Existing public catalog calls and all current playable levels continue to work during migration.
- Gate simulation and later locality/cache simulation remain separate domains unless concrete shared behavior justifies a smaller common abstraction.

## Implementation and verification steps

1. Capture the current coupling map and write the content/behavior boundary as an ADR.
2. Add branch/level descriptors and a deterministic registry with structural validation.
3. Migrate foundations, arithmetic, storage, and integration metadata into registered packs; keep the current catalog API as a facade.
4. Route the campaign UI, entry types, reward ownership, and downstream invalidation through the registry.
5. Add a synthetic extension test, catalog validation, automatic localization-source discovery, and regression assertions for every existing level.
6. Evaluate the reusable-component execution boundary. Implement only a bounded topology-backed mechanism that preserves deterministic semantics; otherwise document the exact follow-up rather than hiding a built-in-behavior dependency.
7. Run the new focused suite, both prologue suites, circuit and Hardware Foundations suites, localization, existing locality suites, and project smoke. Inspect logs, final diff, links, and `git status`.
8. Move this plan to `completed/` only when the implemented milestone and fresh evidence match the claims above.

## Decisions and rationale

- Use an explicit registry rather than filesystem reflection. Godot exports and headless tests need deterministic order, validation, and visible registration; implicit directory scanning would make packaged behavior harder to audit.
- Keep executable component behavior in trusted code. Treating arbitrary content dictionaries as simulation programs would create an accidental HDL and blur determinism/security boundaries.
- Preserve the catalog facade during migration. Existing tests and UI can move incrementally while one canonical registry eliminates duplicated progression knowledge.
- Describe special entry flows (`tutorial`, `half_adder`, ordinary circuit challenge) as metadata rather than matching level IDs in UI code.
- Declare rewards on levels. This lets dependency invalidation remove owned components without another hard-coded level-to-library switch.
- Keep player topology and provenance in reusable definitions. Whether arbitrary nested designs can execute recursively is a separate simulator decision and must be proven with cycle/width/state tests before becoming a promise.

## Progress

- 2026-08-18: reread the referenced design conversation and audited the current implementation, tests, architecture decisions, and durable status documents. Localization already has a sound semantic-key boundary, and deterministic simulation is separated from animation. The principal extension gaps are a monolithic 4,000-line Hardware Foundations controller, hard-coded campaign metadata/branches/rewards in multiple files, hard-coded component schemas and evaluator switches, and reusable designs whose later execution still depends on a built-in `behavior_kind`.
- 2026-08-18: selected a bounded registry-and-content-pack migration as the first implementation stage. This lowers level/text/progression cost without forcing gate circuits and cache/locality mechanics into a speculative universal model.
- 2026-08-18: added typed branch/level descriptors, deterministic registry validation, four retained prologue content packs, and a thin compatibility catalog. The campaign map, entry dispatch, completion-without-sealing, reward lookup/generated wrappers, and transitive invalidation now consume registered content rather than hard-coded level-ID lists.
- 2026-08-18: introduced `PlayerContentState` as the session owner of completion and reusable designs. Installation checks declared reward ownership, generates registered wrappers, invalidates only transitive dependents after a source change, and exposes deterministic identity plus a versioned save-ready manifest boundary.
- 2026-08-18: added a focused extension-contract suite with a synthetic branch/level and invalid registries, and made localization coverage recursively discover content-pack scripts. Focused content, prologue simulation/UI, Hardware Foundations UI, and localization checks pass during implementation; full fresh verification remains pending.
- 2026-08-18: documented the extension recipe and explicit behavior boundary in `architecture/content-system.md` and ADR 0009. Arbitrary recursive player-defined execution remains out of scope; future assisted design must submit a normal graph to the same deterministic official evidence path.
- 2026-08-18: completed fresh verification. All eight automated suites and four default-Chinese/English/direct-Hardware/hub-route smokes exited `0`. Post-review reruns of the content registry, prologue simulation/UI, localization, default startup, and hub route also exited `0`. Both PO catalogs contain 516 unique matching keys with no duplicates or key-set delta; local Markdown links and whitespace checks passed. Log scanning found no parse/compile error, locked-object error, RID/Object leak, failed assertion, or invalid content. The known Windows root-certificate warning was the only logged error. No commit or push was made.

## Unresolved questions and temporary limitations

- Arbitrary player-created components are not yet guaranteed to execute from their stored source topology when nested. The current reusable type keeps topology/provenance but selects behavior through a built-in kind. This plan will either add a narrow deterministic composite evaluator or leave a precise follow-up contract after testing the recursion, state, cycle, and width implications.
- Full save/load compatibility is not yet promised. The new versioned manifest records completion and design provenance but intentionally does not serialize/restorably reconstruct topology; a disk format should wait until the player-design execution model is stable.
- Adding a genuinely new electrical primitive will still require simulator and presentation code. The intended low-cost path applies to new arrangements, tests, inventory, progression, copy, and rewards built from supported mechanics.
- The current single Hardware Foundations controller remains a maintainability risk even after campaign metadata moves out. Further extraction should follow measured change pressure rather than a one-shot rewrite.
