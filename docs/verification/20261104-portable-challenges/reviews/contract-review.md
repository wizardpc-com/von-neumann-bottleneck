# Round 3 independent codec/store review — 2026-11-04

Reviewer: `/root/review_records_final`. Scope: challenge codec/store, their focused tests, the Board condition helper, and host calls at the external-data/storage boundary. Read-only review against `.godot/collaboration/round3-implementation.md` and the portable-challenges execution plan. No production/test edits, Godot execution, player-file access, or Git mutation by this reviewer.

## Finding

**No additional actionable defect found in the inspected codec/store implementation.** This is a source-review result, not a runtime acceptance claim. The two host recovery issues and C1-title mismatch already documented in `/private/tmp/vnb-round3-controller-review.md` remain applicable; they are not duplicated here as new findings.

## Evidence reviewed

- `layout_challenge_code.gd` bounds the input in UTF-8 bytes before parsing, checks exact keys and primitive/container types at each recipe level, validates finite integral ranges, and compares the payload against rebuilt canonical JSON. Duplicate keys, ignored nested data, alternate numerical spelling, and claimed scores cannot silently become a canonical live challenge.
- Supported old model/condition values remain decodable. `inspect()` retains task metadata for wrong-task feedback but rejects incompatible identities before measuring. Every accepted live target or export is derived from fresh `Board.build_rows()` results; `decode()` does not supply a score.
- Relocation transports only explicit A/B recipes and reconstructs an inert starter root. The current Board identity follows the ordered recipes actually executed. Encoding does not give unused root fields score authority.
- The extracted `condition_id_for()` uses the same task, current model, and full ordered official cases previously used by `build_rows()`. The helper introduces no change to case execution or eligibility.
- Store load validates the entire nested snapshot before adopting it. Unknown/future/malformed structure becomes read-only. It preserves supported stale code text rather than relabeling it as current.
- Game and Test use separate dictionaries. Test methods return before Game load/write. Read and operation results are detached copies. The retained store is absent from GlobalSave and progression snapshots.
- Game commits check original-file identity before preparing the temporary file and again before rename. Neither write/flush/rename failure commits proposed Game memory. The original saved target is retained; failed proposals are deliberately managed separately by the host for that visit. Subsequent identical pin/clear calls retry when the obstruction is removed.
- File bounds, invalid UTF-8 round trips, directory paths, failed/short reads, changed storage paths, and externally changed/created/deleted files have explicit protective branches. A previously detected protected file remains read-only for the lifetime of that store; this matches the preservation contract.
- Focused tests cover all six tasks and all three objectives using actual Board metrics/trace identities, mutation rejection, A/B binding, stale decode versus replay, Game/Test isolation, detached state, nested-history protection, external changes, real temp-open obstruction, and real OS rename failure with identical retry.

## Verification boundary

The root remains the sole engine runner. I did not run or infer a passing result from these tests. The existing-file READ-open failure and invalid-UTF-8 branches were assessed statically; the current store test does not include direct fixtures for those two branches. Native interaction, clipboard/focus, GPU layout, packaging, and any remote identity or anti-cheat property are outside this report.

Reviewed file SHA-256 values:

- `src/layout_chapter/layout_challenge_code.gd`: `7c7ae53491580cbe93dbe51ab383d4108b517eab5b6a936170266388aa3ec7d6`
- `src/layout_chapter/layout_challenge_store.gd`: `2c272d2f820135a39bba13d7080460015d0ba99cd6315404f2b1c9d56843db0f`
- `src/layout_chapter/layout_scoreboard.gd`: `b6862a3c3def534134ff5ca7bd8beb7031a110db111a21c1747ddccdb6f55aac`
- `tests/test_layout_challenge_code.gd`: `3b13de69f4d37742e4d3caf0670a472cbf739cbaa66867ed1d070c3ffed75335`
- `tests/test_layout_challenge_store.gd`: `6a18b57c95e81281822cc4233dff404594f81f7b9a173923b9f4f79dfcd0ddcd`
