# Storage Foundations completion execution plan

## Goal

Complete the planned storage branch as a readable playable sequence rather than only a functionally passing skeleton:

1. cross-coupled NOR feedback stores one bit in `SRLatch`;
2. `D` plus `LOAD` turns the player's latch into `Register1`, then a generated `Register4`;
3. address decode plus two player-owned word registers and a read mux form `RAM2x4`.

The key validation question is whether the player can see and control the distinction between changing an input, committing a new stored state, and holding an old state.

## Scope

- Preserve the existing three storage levels, official sequences, dependency map, reusable-component provenance, graph-authoritative wiring, and CPU integration.
- Add simulator-authored state-boundary events for stateful components, including explicit write/set/reset/hold/read captions even when the stored output does not change.
- Add a storage state monitor and Reset State action to the external Test Bench. Input edits preview the circuit; Run Current Case commits one deterministic step.
- Show simulator-derived before/after state in official sequence rows, including both RAM cells.
- Keep stored values visible on reusable latch/register/RAM component bodies outside the transient animation.
- Add a deterministic storage capture hook and focused simulation/UI/localization coverage.

## Explicit non-goals

- No additional flip-flop, counter, stack, ROM, SRAM/DRAM, memory hierarchy, Cache, latency, bandwidth, or locality levels.
- No larger RAM, arbitrary address width, arbitrary word width, clock waveform editor, analog timing, metastability, persistence, HDL, or production art pass.
- No changes to the arithmetic branch, CPU instruction contract, v0.2 locality metrics, or Cache behavior except regression-safe presentation support shared by existing stateful components.

## Affected files and subsystems

- `src/circuit/prologue_simulator.gd` and `prologue_event.gd`: deterministic state-boundary trace evidence.
- `src/hardware_foundations/hardware_foundations.gd`: state monitor, Reset State, transition rows, persistent component readouts, capture hook, and localized playback captions.
- `src/hardware_foundations/circuit_trace_overlay.gd`: reuse existing latch/register/RAM procedural effects for explicit state events.
- `tests/test_prologue_simulation.gd` and `tests/test_hardware_prologue_ui.gd`: state-event, reset, monitor, transition, and parallel-write coverage.
- `localization/`, status/architecture/testing documentation, and this plan.

## Invariants

- The displayed graph remains the authoritative topology and all official actual values come from it.
- State commits occur only in deterministic simulation at Test Bench step boundaries; UI controls and animation never mutate authoritative state directly.
- Editing inputs performs a preview only. Running one debug case commits one step. Reset State clears only the current level's debug state.
- Basic gates retain one tick; ordinary wires and routing junctions retain zero ticks independent of geometry.
- Independent stateful components at one boundary animate in one parallel causal wave.
- Sealing still requires a fresh official pass for the unchanged topology signature, and sealed definitions retain player provenance.
- Chinese remains the default; simulation keys, values, topology, and signatures remain locale independent.
- Existing CPU and locality behavior remains unchanged.

## Implementation and verification steps

1. Extend the temporal report with explicit deterministic state-boundary events and test write/hold plus parallel RAM-register commits.
2. Add Test Bench state monitor/reset controls and official before/after transition presentation for latch, register, and RAM.
3. Add persistent stored-value readouts and make playback captions consume event message keys.
4. Add a storage capture hook and inspect a solved RAM sequence frame for address/write/state readability.
5. Update Chinese/English catalogs and only documentation whose durable facts change.
6. Run both prologue suites during implementation, then all seven repository suites, Chinese/English/direct/route smokes, catalog integrity, diff/link/status checks.
7. Move this plan to `completed/` only after fresh verification and final review.

## Progress

- 2026-08-18: reread the referenced planning conversation and confirmed the intended storage scope is exactly latch → register → addressed RAM. Current baseline simulation and progression/UI suites pass, but storage debug state has no reset control, official rows do not expose state transitions, and unchanged HOLD boundaries may have no component feedback.
- 2026-08-18: added simulator-authored `state_transition` waves. Both cross-coupled NOR gates now acknowledge SET/RESET/HOLD together; reusable latch/register/RAM state commits even when the value is unchanged; both RAM word registers share one boundary wave.
- 2026-08-18: added the storage Test Bench monitor and reset action, separated live port preview from committed state, added official action/before/after rows, and kept compact stored values visible on stateful components between effects. Playback now advances those readouts only when the corresponding boundary animation completes.
- 2026-08-18: added semantic Chinese/English copy, a deterministic RAM capture hook, and UI coverage that checks state-effect placement in displayed GraphEdit coordinates after zoom/scroll.
- 2026-08-18: completed fresh verification. All seven automated suites and four startup/direct/locale/route smokes exited `0`; both catalogs contain 512 matching entries with 511 referenced keys and no missing, duplicate, key-set, or placeholder mismatch; the RAM capture was inspected; whitespace/link/status checks passed. The known Windows root-certificate warning was the only logged error. No commit or push was made.

## Unresolved questions and temporary limitations

- The teaching model continues to use Test Bench step boundaries rather than a free-running clock. A later playtest should decide whether a clock visualization is needed; this iteration will not invent clock timing semantics.
- `RAM2x4` remains intentionally tiny. Its purpose is to teach address selection and retained words, not capacity or memory performance.
