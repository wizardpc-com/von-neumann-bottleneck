# Round11 released regression and corpus source follow-up

Reviewed at 2026-11-05T12:25:55.310388+00:00 by `/root/review_records_final`.
Read-only follow-up to `/private/tmp/vnb-round11-contract-review.md`.

**No actionable finding in the released test and Region-specific adapter changes.** This is a static source review only; execution and evidence acceptance remain root-owned.

Reviewed the complete new rejection test and its release report; the new Region corpus input, public execution dispatch, semantic validator and strengthened rejection validator; relevant unchanged snapshot, Base and Region contracts from the initial review.

- The rejection test reaches the real public API after verifying actual Base success. Its21-key checks,14 integer-zero metric checks, four empty arrays, complete typed fresh-Trace comparison, retained typed input provenance, repeats, nested two-way detachment, later-result isolation and five task completion gates match the agreed rejected contract.
- The source inventory yields63 preparation-negative cases (51 parameter cases plus12 codec/load cases),11 compound Base failures and12 legal boundary cases. These are authored counts, not executed check totals.
- The late scratch fixture uses RAW `[0,8)` plus RAW `[8,64)` with scratch_limit8 and all preparation parameters invalid. It explicitly requires stored_bytes12, empty blocks and complete typed equality with actual Base failure after only Region identity assignment. This is equivalent to the earlier proposed16-byte/20-byte boundary and correctly catches lost partial Base evidence.
- The compatibility adapter executes actual Region.run for all8 authored orders across four plans per task and retains original Trace objects; it executes Region.meets for all20 plan/task combinations. The32 full traces and20 booleans are not replaced by projected metrics or cached results.
- Both task-specific alternative plans remain the existing acceptance fixtures. Whole RAW/RLE decisions are checked against the captured goals, not guessed. The independent expected source values, scalar totals, byte ranges and decoding, client identities, storage, traffic, preparation/service ordering and cycle accounting make the new semantic validation meaningful.
- The rejection diagnostic retains the existing same short-order clients0 input and whole RAW plan. Its strengthened expectations intentionally fail on the old residual service evidence. Other diagnostic outcomes should stay exact; the combined changed diagnostic must not be claimed as full parity or equal-work speedup.
- The adapter retains its existing integer reconstruction for JSON inputs, while the pure test directly supplies malformed floats so that strict preparation-type rejection is not hidden by this benchmark behavior.

Exact inspected SHA256:

- `tests/test_representation_region_rejections.gd`: `371c9dea028ebeae2437ecfae0f889c4cbd521741f31e83ee5f211f1e6b0dbcd`
- `scripts/benchmarks/computation/workload_cases.gd`: `3ee67c17a7e3d5c985929fed99b0b61b2296de6dab75450a436153a9b0ae6df8`
- `experiments/representation_region/model.gd`: `c7e37462fd24f23f01425cc2094e5818d1374070e08f51b46a6f6177b9423528`

No Godot/native process, Git command or production/test/document edit was performed by this reviewer. Root still needs to inspect parse/runtime results, old negative control, complete old/new typed snapshots, full logs and related regressions. No source ownership is retained.
