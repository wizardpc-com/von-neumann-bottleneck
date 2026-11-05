# Final independent score review

Read-only review of current integration, 2026-11-04. Prior compile, persistence-failure visibility, and challenge-success coverage were repaired; do not treat historical failures as current. Fresh focused receipt .godot/verification/20261104T190535Z-d73a6de8 records all eight entries passing.

## One remaining actionable issue (P2)

src/layout_chapter/layout_chapter.gd:767-780, _save_score_design:

After a real disk failure the named recipe correctly remains in memory and name_edit remains populated. The status invites Retry saving. Reopening the rankings and pressing Save current design with that same name enters the existing-name guard (line 768) and returns before GlobalSave.save_game(), so the advertised retry cannot work through the same player operation. tests/test_layout_scoreboard_ui.gd:persistent_save_checks bypasses this by calling save.save_game() directly, rather than exercising the board's retry action.

Suggested bounded repair: permit an idempotent retry if the existing normalized named recipe equals the current normalized design; keep rejecting any differing design to protect saved copies. Alternatively track an explicit pending failed-save name. Verify by removing the temporary-write obstruction, reopening the board and invoking name_edit + board._request_save(), then inspect disk. Keep the duplicate-name/different-design rejection check.

## Otherwise no actionable issue found

- Pure validation, normalized JSON numeric identity, executed A/B recipe identities and exact current task/model condition binding are coherent.
- Eligibility requires every original case and target, excludes invalid/incomplete/over-space and correct-but-too-slow results. Objective rankings retain real cycle/traffic/peak semantics.
- Board and pin operations do not award progress. Restore uses existing Undo and marks the recipe stale; named schemes and Game/Test data stay separate.
- Challenge targets are deep-copied, session-local, and condition-checked. Latest tests exercise actual cycles and space wins, failure, tie, saved-data reload and real write obstruction.
- Chapter 2 comparison key now separates actual workspace mode, task and pass count; official data/model are fixed within the same scene session. Debug/failed runs remain excluded and existing capstone disclosure lock is applied. Increased-hit color semantics remain in the already documented pending-review queue, not introduced as ranking authority.
- Read current source and focused results only; root owns all edits, GPU/native tests and complete acceptance.
