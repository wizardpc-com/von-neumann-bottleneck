# Round 2 final read-only review

Date: 2026-11-04. Reviewer: `/root/review_records_final`.
Checkout: `/Users/yrq/Documents/冯诺伊曼瓶颈`, branch `codex/gameplay-systems-20261104`.

Reviewed the live working diff and current source for personal record condition minima and persistence, Game-only task/archive projections, journal reflection and navigation, retained Locality best replay, and restore-best / return-to-draft integration. No runtime or test file edits, Git mutations, Godot runs, or player data access were performed by this reviewer.

## Finding

### P2 — Preserve partially corrupt journal files before the next observed result overwrites them

Location: `src/playtest/personal_records.gd:50-64`, especially the silent `continue` at line 54; analogous behavior in `_bounded_records` at lines 71-75.

The loader protects invalid JSON, unsupported root versions/fields and non-Dictionary root containers, but silently drops malformed inner entries and leaves `disk_write_allowed` true. For example, this complete, syntactically valid file has a corrupt per-task condition container:

```json
{"schema_version":1,"best":{"chapter_1/assembly":{"cycles":17}},"conditions":{"chapter_1/assembly":[]}}
```

`_load_records` drops the conditions entry at line 54. The next eligible official run reaches `_save_records` (lines 146-149), replaces the original with the sanitized projection, and permanently loses the original damaged history without surfacing a read-only state. A non-Dictionary value in `best`/`legacy`, a non-Dictionary condition entry, or a signature/identity mismatch follows the same silent-repair route. This violates the explicit contract in `docs/exec-plans/active/comparable-records-20261104.md:51-52`: unknown/future or corrupt files are write-protected and are not automatically repaired over the original.

Suggested correction: validate complete per-task container/entry structure before authorizing disk writes. On malformed content, retain safe data for display if desired but call `_protect_records` and preserve original bytes. Treat oversized loaded task/condition containers explicitly as unsupported or preserve them without writing, rather than silently truncating and replacing. Keep the intentional bounded eviction policy for newly generated valid conditions distinct from validation of existing disk data.

Suggested focused regression: create schema-1 files with malformed nested `best`, `legacy`, task condition buckets, record entries and mismatched identities; load each, observe a real valid result, assert `storage_status == "read_only"` and byte-identical original file. Current `test_personal_record_conditions.gd` covers malformed JSON, future root versions and unknown root fields, but does not cover these nested cases.

## No further actionable finding in reviewed scope

- Same-condition slower/tied observations now select that condition's retained minimum while independent conditions stay separate.
- Scalar historical observations remain distinct from currently replayed Chapter 2 / Chapter 4 designs, and Game archive completion reads explicit Game dictionaries without a mode switch.
- Journal entry continues to use current-mode original task availability, while reflection uses explicit Game completion/solution dictionaries. Reading the archive does not call progression mutators.
- Restore-best / return-to-draft preserves raw and applied source separately, restores configuration together, invalidates the current trace/results and clears pending review, and does not itself award completion. Backup is scoped to level/mode and transient.
- No new simulation-rule or save-format migration concern was found in these paths.

## Verification boundary

This is source/diff review, not a fresh runtime acceptance. Root retains sole Godot ownership and must run the focused persistence regression plus the already planned isolated suites after any repair. Earlier pass reports and current tests were read only; this reviewer does not claim them as fresh execution evidence.
