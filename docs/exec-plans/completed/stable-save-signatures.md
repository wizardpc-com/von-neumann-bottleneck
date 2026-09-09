# Stable save signatures and verified legacy recovery

2026-09-08, baseline 1948def. User explicitly approved backup → stable signatures
→ original official revalidation → restore only verified legacy progress.

## Scope and invariants

Fix process-dependent StringName ordering in circuit identities and seed snapshots.
Migrate only ordering/nested provenance and equivalent integral JSON representations, never circuit behavior,
ports, wires, layouts, colors, official cases, targets or campaign prerequisites.
Keep Game/Test isolation and the original 9+5+7 route. Do not change DSL receipts,
program templates, the eight-task comparison or add previously proposed levels.

Before rewriting either legacy file, retain a byte-exact, content-addressed backup
beside it. Preserve rejected original records in that application-preserved backup and notify
the player. Backup/write failures and unknown versions fail closed. Migration must
be idempotent and recover if interrupted between independently backed-up files.

## Implementation

- `LogicCircuit`: explicit textual ID ordering; same for workbench inventories.
- A bounded signature codec normalizes only component ordering and nested known
  reusable-source JSON. Unknown fields remain part of identity, never discarded.
- `CircuitWorkbenchStore`: backup and normalize Game bindings without touching
  topology/layout; adopt the current stable seed identity once without erasing an
  old default. Subsequent actual seed changes retain existing reset semantics.
- `GlobalSave`: explicit signature revision; reconstruct each primary component
  in dependency order, require structural source equality, verified nested library
  bindings, and unchanged official verifier success. Generated wrappers are still
  rebuilt by current recipes. Rebind the old Chapter 1 gate only when its old
  CPU/RAM signatures match the old manifest and all corresponding new sources
  have been verified. Downstream completion follows existing prerequisite checks.
- Hub: concise localized recovery/failure notice, with backup paths in details.

## Verification

Regression fixtures must cover legacy ordering, nested generated wrappers,
invalid circuits, changed valid-but-different topology, missing sources, conflicting
backup failure, unknown revisions, Game/Test separation, named/default layout
preservation, second load idempotence, and real seed changes after adoption.
Run fresh separate Godot processes (different StringName intern order), not only
same-process tests. Use a copy of the previous full native 21-level player data,
then ordinary Game Continue, HalfAdder/CPU workbench and later chapter maps;
close and restart again. Test outputs and native evidence are separate.
Run the isolated standard suites and ordinary Game input replay on Godot 4.7.1.
Commit the verified increment; do not push. Actual user saves stay untouched by QA.

## Progress

- Repository, save authority, workbench fingerprints, generated wrapper lineage,
  Chapter 1 composite gate and prior native evidence inspected.
- Approval is granted; old documents saying pending describe historical state.
- Windows execution and human beginner acceptance remain outside this Mac run.

## Decisions and outcome, 2026-09-09

- JSON parsing revealed a second representation issue: equivalent integer
  properties stringify as floats after a disk round trip. Canonical serialization
  now recursively normalizes exactly representable integral values below 2^53;
  simulation inputs and fractional values are untouched.
- Old seed hashes cannot reveal whether a mismatch is order-only. Preserve each
  existing legacy default during its first stable adoption; subsequent actual
  seed changes still reset only default. Named designs remain intact.
- Backup protection is content-addressed non-overwrite policy, not an OS immutable
  flag. Rejected original records are kept there; complete/partial/failed recovery
  is visible on the hub. ADR 0020 records the approved durable contract.
- Fresh isolated run 20260908T142245Z-83be88e2 passes all 21 suites and Chinese
  ordinary Game replay 593/0. Three independent legacy-writer/migration-reader/
  stable-reader processes pass with equal library digest. Earlier failed fixture
  development logs remain separate.
- Native QA continued after the overnight desktop lock: ordinary Game restored
  the prior manually earned 9+5+7 completion set, old 12-wire Half Adder passed
  four formal cases, old 19-wire CPU passed seven formal steps. After normal quit,
  another launch retained Continue, all progress and constructed workbenches;
  no repeated migration notice. Original backup hashes remain exact.
- Final runtime/test hashes match 244 files in the verified copy; native runtime
  hashes also match. No later runtime edits were made. Evidence and limits are in
  [the recovery record](../../verification/2026-09-08-save-recovery/README.md).
- Completed this approved scope. Windows, physical trackpad, first-time human
  acceptance and the CUA fullscreen lookup issue remain unverified. Future level
  additions and DSL receipt migration require their own decisions.
