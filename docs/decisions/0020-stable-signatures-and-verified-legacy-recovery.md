# ADR 0020: Stable signatures and verified legacy recovery

Status: accepted, explicitly approved by the user on 2026-09-08. Implemented and
Mac rechecked on 2026-09-08–09. Extends [ADR 0018](0018-provenance-checked-global-save.md).

## Context

Native ordinary Game completion of all 21 original levels exposed loss of
arithmetic-derived completion and later chapter access after restart. Sorting
`Array[StringName]` did not provide the required textual identity order across
processes. Seed fingerprints could also change and replace an edited default.
JSON round trips additionally distinguish integral floats from integers in text.
Completion flags alone cannot safely recover player-owned reusable components.

## Decision

Circuit component IDs and inventory snapshots use explicit textual ordering.
Canonical property serialization normalizes exactly representable integral floats
below 2^53 to integers, recursively; runtime values and fractional numbers remain
unchanged. No simulator, official case, prerequisite or DSL receipt rule changes.

Keep global schema 1 and workbench schema 2, with an explicit `signature_version: 2`.
Before legacy conversion, retain byte-exact SHA-256-addressed `.pre-stable-*.bak`
files for both global candidates and the workbench manifest. Application writes
never overwrite or rotate these backups. A conflicting backup or migration write
failure stops automatic saving. Unknown revisions are not overwritten.
Workbench replacement uses a validated temporary file, flush/close and rename.

Normalize only recognized circuit/component order and nested reusable provenance,
retaining all identity fields and wire order. This bounded codec is not proof of
validity. Restore primary designs in dependency order only when an independent
Game workbench matches that normalized identity, all nested bindings match the
verified library, and the unchanged official verifier passes. Rebuild generated
wrappers from current recipes. Rebind Chapter 1 only if the old CPU/RAM gate also
matches the old manifest and all corresponding current definitions are verified.
Existing downstream dependency checks remain authoritative.

An old opaque seed hash cannot distinguish this ordering defect from a real seed
change. At each legacy level's first visit, adopt the stable seed hash once while
preserving an existing default, names, layout and wires. Record
`seed_signature_version: 2` per entry. Later actual seed changes retain existing
default-reset semantics; named boards remain. Test bindings are not normalized
into Game data. A missing default can still be initialized normally.

Write only recovered verified progress; original rejected records remain in the
content-addressed backups. The hub reports complete, partial or failed recovery,
with rejected IDs and backup paths in details. Repeated stable loads do not repeat
the migration notice. Interruption after workbench conversion is recoverable by
revalidating the still-legacy global manifest against the upgraded workbenches.

## Alternatives and consequences

Trusting completion flags would bypass player provenance; resetting all defaults
would destroy valid construction. Neither is acceptable. Suppressing equality
checks would silently accept changed designs. The chosen migration retains exact
identity and official verification while handling known representation changes.
Recovery can be partial for stale, missing or invalid circuits. Backups require
additional local disk space and are not automatically pruned. They are protected
by application policy, not filesystem immutable flags. Windows rename/export
behavior and first-time human acceptance remain unverified in this Mac increment.

[Verification](../verification/2026-09-08-save-recovery/README.md) separates regression
fixtures, three-process checks and real ordinary Game continuation of prior native
player data. Actual user saves were not used for QA.
