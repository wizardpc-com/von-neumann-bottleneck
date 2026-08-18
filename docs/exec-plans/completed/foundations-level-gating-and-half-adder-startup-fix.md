# Hardware Foundations level gating and Half Adder startup fix

## Goal

Fix the player-visible failure that appears when the Half Adder challenge first opens, and make the existing Hardware Foundations sequence use one visible, prerequisite-gated level map from the wiring tutorial through the CPU/storage branches.

The intended progression is:

```text
Signal and wiring tutorial -> Half Adder
                             -> Full Adder -> ALU -----+
                             -> SR Latch -> Register -> RAM -> CPU -> LOAD/STORE
```

Every construction level must still evaluate the circuit drawn by the player. Passing an earlier level is the only way to unlock its dependants.

## Scope

- Reproduce and distinguish an invalid initial Half Adder presentation from a real wiring/runtime diagnostic.
- Keep an untouched, unwired Half Adder in a neutral "ready to build" state until the player runs or creates an electrically invalid topology.
- Add the wiring tutorial and Half Adder to the visible campaign map and prerequisite catalog.
- Route every map launch through the same unlock check, including the special tutorial and Half Adder scenes.
- Mark the tutorial complete only after its existing five interaction checks pass.
- Preserve replay of completed levels and the session-local component library.
- Add headless regression coverage for initial state, visible locks, bypass rejection, unlock transitions, and the existing complete progression.
- Update only the durable status/testing documentation affected by this behavior.

## Non-goals

- No new Full Adder, ALU, storage, CPU, or programming levels.
- No save-file or cross-session progression format.
- No replacement of the current AND/OR/NOT inventory with a NAND-only campaign.
- No change to circuit truth tables, deterministic simulation, wire latency, free-form valid topology, or encapsulation provenance.
- No art pass or broad map redesign beyond readable prerequisite state.

## Affected subsystems and files

- `src/hardware_foundations/hardware_foundations.gd`: phase routing, initial diagnostics, map presentation, completion transitions.
- `src/hardware_foundations/prologue_level_catalog.gd`: complete ordered level/dependency graph.
- `localization/game.zh_CN.po`, `localization/game.en.po`: map and neutral-build copy.
- `tests/test_hardware_foundations_ui.gd`: tutorial/Half Adder startup and unlock regression.
- `tests/test_hardware_prologue_ui.gd`: full map dependency and downstream progression regression.
- `docs/status/cpu-building-prologue.md`, `docs/development/testing.md`: durable implemented facts and verification evidence.

## Invariants

- Simulation is deterministic and independent from UI/animation.
- The displayed GraphEdit topology remains authoritative.
- Ordinary wires and routing nodes add zero simulation latency.
- A locked level cannot be entered by its visible button or its internal start router.
- A completed level remains replayable, but replay must not erase unrelated completed progress or owned components.
- Existing dirty-worktree changes are preserved; no commits or pushes are created.

## Implementation steps

1. Capture the initial Half Adder state in a focused headless regression and identify the exact false-error path.
2. Separate neutral incomplete topology presentation from genuine short/cycle/invalid-wire diagnostics.
3. Extend the catalog order/dependencies with `tutorial` and `half_adder` and add a Foundations branch to the map.
4. Add one guarded campaign start router for tutorial, Half Adder, and catalog-defined levels.
5. Record tutorial completion at the existing five-check boundary and refresh the map/unlock state without granting later completion.
6. Add regression assertions for locked Half Adder, tutorial unlock, Half Adder unlock, direct bypass rejection, and downstream prerequisites.
7. Run fresh circuit, Foundations UI, prologue simulation/UI, localization, and startup smoke checks; inspect the final diff and status.

## Decisions and rationale

- 2026-08-18: Use the existing AND/OR/NOT tutorial and Half Adder inventory. The product request is about Turing Complete-like progressive abstraction and prerequisite gating; replacing the already implemented gate vocabulary would be a separate campaign redesign.
- 2026-08-18: Keep completed levels replayable. A dependency map should gate first access, not prevent experimentation after completion.
- 2026-08-18: Keep progress session-local. This repair must not invent a persistent schema while the repository explicitly documents that limitation.

## Progress

- 2026-08-18: Read repository guidance, architecture, testing documentation, current implementation, and current UI/progression tests.
- 2026-08-18: Confirmed the current map excludes tutorial and Half Adder even though later dependencies refer to `half_adder`; current tests manually seed that prerequisite.
- 2026-08-18: Baseline `test_hardware_foundations_ui.gd` passes, confirming the reported startup failure is not covered by the existing suite.
- 2026-08-18: Added tutorial and Half Adder to the ordered catalog, made the dependency map the normal entry view, and routed every visible launch through the same prerequisite guard.
- 2026-08-18: Added a neutral unwired Half Adder state while preserving live short/cycle errors and authoritative official-test failure.
- 2026-08-18: Preserved completed-level replay and added downstream invalidation when a replayed Half Adder is resealed with a changed source signature.
- 2026-08-18: Captured and visually inspected the initial 1600×900 map; it shows tutorial available and Half Adder/later levels locked.
- 2026-08-18: Completed fresh circuit, Foundations UI, prologue simulation/UI, localization, v0.2 simulation/UI, and startup smoke verification with exit code 0.
- 2026-08-18 follow-up: Real `Button.pressed` emission exposed synchronous destruction of the emitting map/tutorial button. `_clear_container()` now detaches and queues old controls for end-of-frame deletion; the regression emits the real signals and verifies the old buttons become invalid safely.

## Unresolved questions and temporary limitations

- The baseline did not reproduce a script crash in Half Adder. The concrete player-visible defect was an ambiguous unwired/live-diagnostic transition plus the absence of tutorial/Half Adder from the gated map; both now have explicit regression coverage.
- The map remains a clean procedural UI rather than a final node-and-path art treatment.
- Progress remains session-local and resets when the game closes.

## Verification

All commands used Godot `4.7.1.stable.official.a13da4feb` and exited `0`:

- `tests/test_circuit_simulation.gd`: PASS.
- `tests/test_hardware_foundations_ui.gd`: PASS, including initial map locks, bypass rejection, tutorial unlock, and neutral unwired Half Adder.
- `tests/test_prologue_simulation.gd`: PASS, including ordered root prerequisites.
- `tests/test_hardware_prologue_ui.gd`: PASS through both branches, CPU, and LOAD/STORE.
- `tests/test_localization.gd`: PASS for Simplified Chinese and English catalogs.
- `tests/test_simulation.gd` and `tests/test_ui.gd`: PASS for the preserved v0.2 prototype.
- project startup smoke with `--quit-after 5`: exit `0` and no project parse/runtime failure.
- visual capture `.godot/initial-foundations-map00000001.png`: inspected at 1600×900.
- locked-emitter follow-up: Foundations UI, prologue UI, localization, and startup smoke all exited `0`; fresh logs contained no locked-object, script-error, RID-leak, or ObjectDB-leak lines.

Every Godot invocation printed the pre-existing Windows warning `Failed to read the root certificate store`; it did not affect exit status or any test result.
