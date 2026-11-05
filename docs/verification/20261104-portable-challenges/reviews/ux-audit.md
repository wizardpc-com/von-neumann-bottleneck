# Round 3 playable challenge UX audit — 2026-11-04

Owner: `/root/audit_polish`. Read-only audit of runtime/tests; root owns all Godot/Git and integration. No runtime edits and no new runtime verification in this audit. `git diff --check` passed.

## Current behavior and useful boundaries

- `src/layout_chapter/layout_scoreboard_window.gd:23–88` already provides a discoverable exclusive window at 1040×560, minimum 760×420, with a real measured table, objective selector, named save and load/pin actions. Keep this entry rather than create a competing challenge destination.
- `layout_scoreboard_window.gd:144–148` pins a deep-copied measured row and closes the window. `layout_chapter.gd:790–794` retains it only in a scene field, so navigating away loses the target.
- The current pin only updates the generic status label. `_changed()` replaces that label; therefore an active target is no longer discoverable during iterative edits even before leaving the scene.
- `layout_chapter.gd:759–765` already restores a recipe through `_remember()` and `_changed()`, giving exact Undo and invalidating stale results. Import must not bypass or duplicate this route.
- `layout_chapter.gd:796–818` compares only after `_run_all()`, requires all official case targets, checks condition identity, uses the chosen real metric, and treats equality as a tie. Preserve that result contract.
- Current candidates are at most 26 (current, passing best, 24 named); a single active target adds only one. Opening/saving remeasures, whereas sorting reorders the existing snapshot.
- `_unhandled_key_input()` deliberately returns while the ranking Window is visible; ranking Escape closes only that Window. Existing tests cover this, same-name save protection and release of the ranking modal before the GlobalSave recovery dialog.
- Test named schemes/drafts survive visits through their autoload but are not persisted by GlobalSave. A new challenge store must not accidentally turn Test recipes into Game records or completion.

## Proposed minimum playable loop

1. Open **My design rankings / 我的方案榜**, select an eligible measured design, choose cycles / RAM / scratch, and press **Set target / 设为目标**. Store the bounded recipe plus condition and objective, not authoritative numbers from the UI. Pinning leaves the current draft, undo/redo and named designs unchanged.
2. Retain one active target per task and current mode. The workbench ranking button gains a concise active-target cue, and its tooltip states title, objective and locally measured number. This remains visible when the generic status changes and avoids another full-width status strip.
3. Opening the board shows the active target as a distinctly labeled row, remeasured under its bound conditions. An existing objective selector changes list sorting only; it does not silently change the pinned target's objective.
4. **Share code / 分享挑战码** opens a compact code view within the existing exclusive Window. It contains selectable text and **Copy / 复制**. The share preview identifies the selected recipe, task and chosen objective; it never uploads anything. The user can manually select the text if clipboard integration is unavailable.
5. **Import code / 导入挑战码** opens the same code view with an empty multiline text input and **Check / 检查**. Explicit paste/check only; do not automatically read the clipboard or parse on each character. Validate size/format/task/conditions, then remeasure every official case before showing a target preview.
6. A successful import preview shows task, title, objective and all three remeasured totals. **Set target / 设为目标** (or **Replace target / 替换目标** when one exists) persists it and returns to editing. Invalid or incompatible text stays in the editor with a precise localized error; it changes nothing else. **Back / 返回** discards only the preview and returns focus to the initiating board action.
7. To inspect the imported recipe, select its target row and use the existing **Continue improving / 载入改进** action. This is the sole import-related action that changes the draft and is one Undo transaction. Merely reading, copying, checking, pinning or clearing a target never calls `_changed()` or records a completed task.
8. Edit and **Run all cases / 运行全部订单**. After a fully qualified official run, display beaten / tied / continue improving with the same objective and signed delta as today. A failed case cannot beat the target even if a partial metric is smaller. Keep the target until explicitly replaced/cleared; success is not a command to overwrite it.

## Compact presentation and error behavior

- Prefer one page-switched content area within the same Window, not an additional Window or an ever-growing inline form. The table page retains current save/rank controls. The code page contains a modest scrolling TextEdit, preview/error, Check/Copy, Set target and Back. Only one page is visible, so the code box does not consume table height at 720p.
- Short parallel captions or `HFlowContainer` actions avoid fitting four long English buttons on the current 760px minimum. Keep one primary action per page and the always-visible Return action. Do not rely on tooltips to reveal the import entry.
- The current target is identifiable in the board and host; avoid adding repeated paragraphs about storage/authority. Show storage information only for Test or an actual error.
- In Game, successful persistent pin says it is kept. A failed write must say **Target active for this visit; saving failed. Retry / 目标本次有效；保存失败，重试** and retain the recipe/code in memory. “Kept” must not be shown for memory-only state.
- Test wording follows the store's chosen lifetime. Recommended default is retained across visits for this process only, matching current Test drafts; if root intentionally chooses independent Test persistence, label the mode and test restart isolation explicitly.
- When an entire store is protected because of corruption or future schema, never silently replace it. Show read-only storage state and allow bounded transient comparison/code copy if the store contract supports that. Keep the protected file intact.
- Imported code for a different task should report the actual task name and instruct the player to open that task first. Do not auto-navigate, mutate drafts, bypass locks or switch mode. This is a small first transport with no deferred navigation state.
- If stored conditions/model no longer match, retain the raw bounded envelope for recovery but do not list it as a current comparable target. Show inactive/incompatible state and permit copying its original code. Do not silently rebind it to changed workloads.
- Newer schema, malformed recipe, unsupported objective, stale conditions, wrong task, nonqualifying design and oversize code are distinct actionable messages. Do not surface parser dumps to the player.
- Clearing/replacing the active target is an explicit local action; no progression or named design is deleted. A replacement label makes the one-target policy visible. Avoid inventing a large challenge history in this increment.

## Suggested ownership and API boundary

Root should freeze final names/shapes in the plan before implementation.

**Model/storage agent**

- New `src/layout_chapter/layout_challenge_code.gd`, pure `RefCounted`, plus codec tests.
- New `src/layout_chapter/layout_challenge_store.gd` with bounded detached state, pure-ish path injection for tests, and store tests.
- Codec API proposal:
  - `encode(task, design, objective, title) -> {ok, code, challenge, row, reason}`.
  - `inspect(code, expected_task) -> {ok, challenge, row, reason, task}`.
  - `challenge` is the strict versioned data envelope; `row` is produced only by current model evaluation and must not be read from the code.
  - `row` retains the existing scoreboard shape so the host can keep its proven comparison.
- Store API proposal:
  - `active(task, mode) -> detached envelope/status`, `pin(envelope, mode) -> status`, `clear(task, mode) -> status`, `retry() -> status`.
  - Expose `ready / write_failed / read_only`, `last_error` and dirty memory state.
  - A reused same-target pin must retry an earlier write failure; deduplication cannot suppress recovery.
  - Avoid GlobalSave and project autoload changes unless root finds a real need. A shared RefCounted store/host-owned singleton reference can keep separate Test lifetime without new completion authority.

**UI agent (`audit_polish` if assigned)**

- Own `src/layout_chapter/layout_scoreboard_window.gd`.
- Own new `tests/test_layout_challenge_window.gd` or a narrow extension to `tests/test_layout_scoreboard_ui.gd`; use exactly one owner for each test file.
- Window remains a presenter emitting `import_requested(code)`, `share_requested(row, objective)`, `challenge_requested(row, objective)` and `clear_challenge_requested`. The host supplies a result/status via explicit methods. No file access or progression calls in the Window.
- Render state should include current target/objective, optional preview, localized storage status and bounded code. Existing `restore_requested` stays unchanged.

**Root**

- Own `src/layout_chapter/layout_chapter.gd`, integration controller test, docs, translations and all runtime execution.
- Load target on scene/task entry; revalidate/rebind only when the strict contract matches.
- Preserve existing `personal_challenge` row/objective shape if possible; add persistence in the host rather than a second challenge-comparison algorithm.
- Store the mode explicitly at opening/action boundary or assert unchanged mode. Never infer Game from the existence of saved data.
- The target UI must refresh after pin/clear/import/write retry and language rebuild; a changed table sort alone does not change it.

## Meaningful verification

### Model/storage (other agent/root)

- Encode/decode real eligible layouts, JSON numeric round trip, duplicate-key/unknown-field policy, exact-size bounds, invalid group/field/batch data, wrong task/model/cases/objective, and both A/B relocation recipes.
- Poison external score fields; prove no imported number affects target. Verify canonical case/recipe/Trace identities and all metric totals equal direct fresh simulation.
- An incompatible future file remains byte-for-byte unchanged after pin/clear/retry attempts. Real temporary-write/rename failure preserves previous disk state, surfaces dirty state and recovers on retry.
- Restart Game target recovery, scene-reopen Test retention and whichever explicit Test restart lifetime root chooses. No GlobalSave or PersonalRecords byte change from pin/import.

### Controller (root)

- Create an unsaved draft with nonempty undo and redo; snapshot design, stacks, selections, Game/Test state and stored bytes. Export, failed import, successful check, cancellation and pin preserve every snapshot except the separate target store.
- Explicit target-row restore changes one draft transaction; Undo/Redo returns exact pre-import/current designs and stale results cannot become completion.
- Pin a slow passing mixed layout, leave/reopen, run a genuinely faster layout and observe beaten; equal candidate yields tied; wrong/space-limited/target-unmet candidate never beats it.
- Change list objective after pin; comparison still uses pinned objective. Switching tasks/modes never reuses a target from another namespace.
- Failed persistence keeps code/target visible and retryable, then a newly constructed store reads the successful recovery. Original completion remains unchanged until an ordinary official run.

### Window/GPU

- Chinese and English at actual 1280×720 host and 760×420 minimum board: table, code page, maximum legal title/code, error and storage failure. Confirm all action bounds, no clipped buttons and usable code scroll.
- Viewport Tab/Shift-Tab/Enter/Escape, including TextEdit native Undo, workbench Undo isolation, focus return from code page and board, F10/F8 nesting and repeated open/close.
- Copy a generated fixture code then paste through the real editor path on GPU; save/restore the test's previous clipboard. No clipboard claim on headless runs.
- Optional raw captures with `--capture-size=1280x720` and checked `save_png()`. Keep scripted GPU verification distinct from unlocked-Mac native input and exported-package acceptance.

No simulation/target changes are required for this loop. Strategy richness should be decided from the sibling agent's measured enumeration, not inferred from the UI or one known reference solution.
