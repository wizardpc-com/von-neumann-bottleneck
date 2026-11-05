# Round 2 nested personal-record persistence repair

Date: 2026-11-04. Owner: `/root/review_records_final`.
Status: implementation complete; both assigned files released to root for integration and runtime verification.

## Scope and outcome

- `src/playtest/personal_records.gd`: validates the complete saved `best`, optional `legacy`, and optional `conditions` before loading/canonicalizing entries. Malformed inner containers/entries, unsupported fields, sanitizer-lossy values, invalid/conflicting cycle metrics, mismatched task identity, missing/mismatched condition identity, and loaded bounds violations make the entire file read-only. No silent nested repair can authorize overwriting the original.
- Persisted summaries remain the established flat sanitizer format. Valid old schema-1 scalar summaries do not need fabricated model/workload metadata and remain readable. Integer JSON numbers are normalized only after lossless validation.
- Validation counts at most 100 distinct task keys across all three containers, and at most eight conditions per task. `_observe` now applies the same combined task bound, so loading a valid boundary history with legacy-only task keys cannot later write its own unsupported 101-task file.
- Existing eight-condition eviction remains for new valid observations. No simulation/progression behavior, path, schema number, or public record UI API was changed.
- `tests/test_personal_record_conditions.gd`: added 25 malformed/unsupported on-disk fixture variants, each followed by a real measured observation and exact original-byte comparison. Also checks exactly 100 task keys/eight conditions, refusal of a 101st distinct task, writable existing-task observation at the bound, reload, and normal ninth-condition eviction/reload.

## Source verification and limits

- Re-read both affected files, their existing contracts and focused tests before editing.
- Reviewed the resulting source diff and full new helper/fixtures.
- `git diff --check -- src/playtest/personal_records.gd tests/test_personal_record_conditions.gd`: no diagnostics, exit 0.
- Since the test file is untracked, also ran `git diff --no-index --check -- /dev/null tests/test_personal_record_conditions.gd`: no whitespace diagnostics; exit 1 is the expected new-file difference.
- No Godot execution, Git mutation, actual player-data access, or edits outside the two assigned files and this report. Root remains sole engine owner and must run `test_personal_record_conditions` and related regression suites. Runtime pass is not claimed here.
- The earlier P2 review in `/private/tmp/vnb-round2-final-review.md` is historical evidence of the repaired path, not a new runtime verdict.

## Released source identities

- `src/playtest/personal_records.gd`: `35242d3a1a3bd17930ea5b9d8499bb4fc33bf78017e417b982f2ee9a0f2a159c`
- `tests/test_personal_record_conditions.gd`: `5ddb80be0258c72d5d2d7e35a793cb2f104469b257308fd5ad0860fcbc13a1db`
