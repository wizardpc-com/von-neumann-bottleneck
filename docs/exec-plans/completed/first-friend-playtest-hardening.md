# First-friend playtest hardening

## Goal

Prepare the existing Demo for a first friend playtest without adding levels or mechanics. A normal packaged launch must expose only Game mode, while `--test-mode` keeps the existing unrestricted development route. Fresh level workbenches and progressive hints must show only intentional content, final Demo feedback must lead directly to a local anonymous JSON export, and a repeatable Windows package must run without a Godot installation or repository checkout.

## Scope

- Hide the Game/Test selector and its explanatory copy from ordinary Game launches; retain the CLI Test-mode route and all existing automation flags.
- Audit the initial Hardware Foundations component inventory for Tutorial, Half Adder, Full Adder, ALU, Latch, Register, RAM, CPU, and LOAD/STORE.
- Make every stage-2 Hint an explicit coherent subcircuit with only involved components and necessary context; preserve interface-only stage 1 and full-reference stage 3.
- Refresh only the special `default` workbench when its level seed changes, migrating the existing save schema without replacing named workbenches.
- Add a narrow `--reset-local-test-state` startup action that removes Hardware workbench state and raw/active playtest sessions while preserving prior exported JSON files.
- Add an obvious export handoff after final Demo feedback, including the exported path and an open-folder action when export succeeds.
- Add a Godot Windows Desktop export preset plus a PowerShell Playtest ZIP build.
- Add focused regression coverage and update durable run/build/playtest documentation.

## Explicit non-goals

- No new level, Chapter 3, simulation rule, circuit kind, system architecture mechanism, difficulty tuning, pacing change, online upload, account, installer, signing, or automatic update.
- No in-game developer console or general save/reset manager.
- No changes to named player workbenches during seed migration.
- No collection of identity, machine information, full Program source, or Notebook text.

## Affected files and subsystems

- `src/game/game_mode.gd`, the shared selector, and chapter headers: launch authority and developer-only mode UI.
- `src/hardware_foundations/` and `src/content/prologue/`: initial inventory, hint snapshots, and default-workbench migration.
- `src/playtest/` and `src/ui/main.gd`: clean reset and final export handoff.
- `export_presets.cfg`, `scripts/build-playtest.ps1`, README/status/testing docs: Windows packaging and operator instructions.
- Existing Hardware, playtest, UI, and localization suites.

## Invariants

- Simulation, official Test Bench evidence, progression, Trace, and animation timing remain unchanged.
- Game mode is the no-argument default. Test unlocks remain explicit and isolated from Game progress.
- Palette supplies remain available for free exploration; this audit changes only initial placed inventory and Hint boards.
- Hint boards remain read-only and cannot mutate the active player workbench or grant completion.
- Seed migration may replace `default` only. Every named workbench remains byte-preserved.
- Telemetry/export failures never affect gameplay, and exports remain local anonymous JSON.

## Decisions and rationale

- Treat the presence of `--test-mode` as developer UI authority. Current mode selection is still session-wide, but a normal launch has no UI path into Test mode.
- Store a deterministic seed fingerprint beside each level's workbench entry. Existing schema-1 files migrate in place; their unversioned `default` is refreshed once while named entries and active named selection are retained.
- Use explicit authored stage-2 wires instead of percentage slicing. A coherent teaching subcircuit is a content decision, not a wire-count heuristic.
- Keep clean reset as a CLI action. It deletes only `hardware_workbenches_v1.json`, `active_session.json`, and `session_*.jsonl`; already exported JSON files remain available.
- Embed the PCK in the Windows executable and zip the executable with a short player readme. Formal release machinery remains out of scope.

## Implementation and verification steps

1. Implement launch/UI separation and focused visibility assertions.
2. Remove unused initial components, curate stage-2 subcircuits, and assert exact component/wire subsets plus full stage-3 correctness.
3. Add seed fingerprint migration and model/disk tests proving `default` refresh and named-workbench preservation.
4. Add clean-reset logic and isolated filesystem coverage.
5. Add the final export handoff, success path, and open-folder affordance with localized UI coverage.
6. Add and exercise the Windows export preset/build script as far as the installed local toolchain permits.
7. Run all documented simulation/UI/localization/playtest suites, Game/Test startup smokes, representative captures, build/export checks, and `git diff --check`.
8. Record actual results and limitations, move this plan to `completed/`, review the final diff, and commit the finished change.

## Progress

- 2026-08-27: Audited repository rules, prior mode/workbench/hint/playtest decisions, current clean Git state, content factories, controller paths, tests, and packaging gap. Confirmed unused Tutorial/ Half Adder initial parts, stage-2 context leakage/incoherent slices, missing default seed provenance, and an Options-only export handoff.
- 2026-08-27: Made Game the no-argument player-only entry and bound visible mode controls to explicit `--test-mode` developer authority. Added focused Game/Test UI assertions and inspected final 1600×900 captures of both routes.
- 2026-08-27: Reduced Tutorial and Half Adder initial inventories, audited every later initial component against its registered reference topology, and replaced percentage-based Hint slicing with exact authored stage-2 subcircuits. Inspected the clean Tutorial and Stage-2 Hint captures.
- 2026-08-27: Added schema-2 seed fingerprints, bounded schema-1 migration, named-workbench preservation, and selective `--reset-local-test-state` coverage.
- 2026-08-27: Added the final Demo export handoff, exported-path status, open-folder action, localized coverage, and a representative capture.
- 2026-08-27: Added the Windows Desktop preset, documentation resource boundary, bilingual player README, and repeatable PowerShell builder. The final ZIP contains only the embedded-PCK EXE and player README; its SHA-256 is `8720A1203BAA51ABCB96652BFDD668B7D314868E81280AA8BDADDD0FF47AC4A0`.
- 2026-08-27: Ran all 13 documented simulation/UI/playtest/localization suites in the final source state; every suite printed its expected PASS line. Source Game/Test startup smokes exited `0`. The EXE extracted from the final ZIP matched the staged byte size, and both ordinary and `--test-mode` package launches remained healthy until the bounded smoke stopped their exact processes.

## Unresolved questions and limitations

- Rebuilding requires Godot 4.7.1 plus its matching Windows export templates; the delivered EXE itself requires neither Godot nor a repository checkout. The script rejects another editor version and reports missing templates.
- The Playtest package is intentionally unsigned and has no installer or updater, so Windows may present the normal warning for an unknown publisher.
- Difficulty and pacing remain explicitly deferred to the full human playtest.
