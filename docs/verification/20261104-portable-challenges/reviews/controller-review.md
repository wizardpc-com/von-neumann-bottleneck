# Round 3 independent controller review — 2026-11-04

Reviewer: `/root/audit_polish`. Scope: root-authored `layout_chapter.gd`, the retained store in `layout_state.gd`, and `test_layout_challenge_controller.gd`; Window/store inspected as dependencies. Read-only review, no source changes or Godot run.

Two actionable recovery-flow issues remain. They do not challenge the deterministic model or completion authority.

## P2 — The advertised retry can silently change an imported target's objective

Evidence:

- `layout_chapter.gd:965–966` instructs the player to “Set this target again in rankings to retry.”
- `_open_scoreboard()` at `752–773` does not synchronize the sorting objective with the active target; a newly created Window defaults to cycles, and importing a space/traffic code deliberately does not change that sort.
- `_set_personal_challenge()` at `808–816` re-encodes the target recipe using the Window's passed `objective`, even for `row.id == "challenge"`; only the old title is preserved.
- The controller test at `199–214` bypasses the real Window action by manually supplying `"space"` to the host on retry.

Reproduction from the code:

1. Start a board with its ordinary cycles sort.
2. Import a valid space challenge, with a real temporary-write obstruction.
3. The correct space target is now active for this visit, and the player is instructed to retry from the rankings.
4. Remove the obstruction, reopen the board, select the current target row and press Set target.
5. The same design is persisted with a **cycles** objective, because that is still the table's sort selection.

This is not an identical-target retry. It is especially easy after importing a target because the import's objective and the board's sort are intentionally independent.

Recommended repair: provide an explicit persistence retry that submits the retained `challenge_entry.code`/title unchanged, or otherwise make the exact-retry operation distinct from choosing a new objective for a row. Avoid making mere sorting change the active objective. Update the controller fixture to exercise the actual visible retry/pin button without injecting the desired objective manually, and verify that the whole encoded target is byte-for-byte unchanged.

## P2 — Reopening after a failed write mislabels the older persisted target as visit-only

Evidence:

- Store `_commit()` only updates `_game_targets` after a successful replace; failed pinning keeps the older disk-backed entry and sets `storage_status = "write_failed"`.
- `read_target()` therefore returns that older persisted entry together with the failure status.
- `layout_chapter.gd:854–858` correctly loads the returned older entry on the next scene visit and calls `_challenge_storage_text(stored, false)`.
- `_challenge_storage_text()` at `965–966` ignores `temporary == false` for `write_failed`, unconditionally saying the active target is valid only for this visit.

Reproduction: persist A, fail replacement with B, leave the task and reopen without rebuilding the store. A is correctly restored from the retained store, but the board claims A is temporary. If the failed first pin had no previous entry, a reopened task has **no target**, yet the same text says a target is active for this visit.

Recommended repair: distinguish “current requested target is temporary” from “an earlier storage operation failed.” On ordinary load after failure, state that the last saved target is being used (or no target was saved); reserve visit-only language for the currently retained failed proposal. Extend the controller test to leave/reopen before retry with both an existing A and an initially empty store, checking recipe/objective and the presentation.

## Small robustness note

`_pin_challenge()` sanitizes only C0 and U+007F (`935–937`), whereas store `_valid_title()` also rejects U+0080–U+009F. Existing named schemes accept arbitrary characters within their length bound. A named title containing one of those C1 characters can therefore create a repeated title-validation failure that the host calls a write failure. Align the host fallback with the store's character range when touching recovery text; this is lower priority than the two ordinary recovery paths above.

## Contracts that appear sound in the inspected implementation

- The store is independent of GlobalSave and is retained by LayoutChapter only; the Game snapshot and original pass logic are unchanged.
- New host actions guard the mode captured when entering the scene. No asynchronous gap occurs between guard and mutation.
- Share/import/preview/pin do not modify the design, Undo/Redo, named schemes or progress; explicit restore uses the established one-transaction `_remember()`/`_changed()` path.
- Target rows are remeasured on entry/open/fresh comparison. Imported numbers never determine a target. Fresh failed/unqualified results cannot beat it; ties remain ties.
- Supported stale code is retained and copyable but excluded from current rankings and comparisons. Wrong-task import produces a localized task name without automatic navigation.
- The host preserves failed proposal B in scene memory while the protected store keeps prior A. This is a deliberate and recoverable policy; only its retry/status presentation needs the corrections above.

Runtime checks are still pending at review time. Source inspection cannot certify parsing, actual viewport focus, clipboard behavior or native input.
