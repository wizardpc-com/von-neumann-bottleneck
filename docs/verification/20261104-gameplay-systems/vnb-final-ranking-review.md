# Final ranking optimization and save-retry review

Reviewer: audit_scores. Read-only review of the current working tree on 2026-11-04. No source edits, Godot execution or Git mutations.

No actionable issue found in the bounded optimization or retry repair.

- `layout_scoreboard.gd:27-53` deep-copies the existing measured rows before sorting. It does not change the caller's measurements, recipes, case/trace identities or ranking snapshot. Every eligible row receives a newly calculated rank; noneligible rows originate with rank 0 and stay unranked.
- `cycles`, `traffic`, and `space` correctly map to cycles, traffic, and peak. Eligibility sorts first; equal chosen values share competition ranks; candidate id, then recipe id/title, provide deterministic order. Sorting does not invent a weighted metric or reclassify a failed recipe.
- `layout_scoreboard_window.gd` uses rank_rows only for objective selection. `refresh()` still calls build_rows; `_open_scoreboard()` and successful save still call refresh with fresh deep-copied candidates. The exclusive window plus controller key guard prevent ordinary editing beneath the snapshot. Restore/challenge close the window; subsequent opening remeasures. The current scene exposes only one task and mode at a time, so no present path reuses rows across task/mode changes.
- A pinned challenge is deep-copied. `_show_challenge_result()` still computes fresh actual results and compares condition_id before using the objective metric. The re-sort snapshot never becomes progress authority.
- `_save_score_design()` now allows a repeated name only when its normalized saved recipe equals the current normalized recipe. It does not replace a differing design. Game retry calls GlobalSave.save_game again; failed disk writes keep the name and in-memory copy, hide the exclusive ranking window, and expose existing recovery UI. Success clears the name and refreshes current candidates.
- `test_layout_scoreboard.gd` compares resort-only results against full recomputation for space/traffic and checks the original measurement snapshot is unchanged. Existing tie/repeat/JSON/alias tests still cover core invariants.
- `test_layout_scoreboard_ui.gd:178-194` now removes a real QA-only write obstruction and retries using the actual name field + board._request_save() path, then inspects saved bytes. The differing-design duplicate-name rejection remains covered earlier in the suite.

Verification boundary: this is source/test review, not an independent runtime rerun. Root owns final focused/GPU tests and performance evidence. The optimization intentionally applies only while a single exclusive measurement window is open; opening or saving remains a full remeasurement.
