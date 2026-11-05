# Round 3 challenge Window implementation — 2026-11-04

Owner `/root/audit_polish`; implementation ready for root integration/runtime verification. File ownership RELEASED to root. No Godot run, Git mutation, host/state/model edit or player-data access by this agent.

## Changed files

- `src/layout_chapter/layout_scoreboard_window.gd`: retained existing public fields/signals and ordinary measured ranking, save, pin/hide, restore/hide and dismissal semantics. Added the contracted five signals, both-page controls and `set_target_state`, `show_code`, `show_import_result`.
- `tests/test_layout_challenge_window.gd`: new standalone presenter/viewport suite with fake host callbacks. Real Catalog rows provide measured fixture metrics, while the 4096-byte code is deliberately unparsed presentation text. Actual strict codec/controller behavior belongs to sibling/root suites.

## Behavior

- One exclusive Window with table/code pages. Compact actions and a persistent target row use the current 760×420 minimum; long target titles ellipsize with the complete tooltip.
- Target display is a detached deep copy; table sorting cannot mutate its pinned objective. Separate storage message remains visible alongside ordinary save feedback. Active and stale targets expose code/clear actions.
- Share emits a detached selected row/objective. The host supplies text and summary; opening share performs no clipboard operation. Explicit Copy uses clipboard support when present; text stays selectable for manual copy.
- Import begins empty without reading clipboard. Check emits the exact text; only the root-supplied accepted result enables Set/Replace target. Supplied metrics/objective are presented next to the root's localized message.
- Any changed text invalidates the preview. A result must still match the requested editor text, and confirmation checks that same binding again. Observed-text tracking avoids a deferred TextEdit change signal invalidating a check already performed on that exact text.
- Code Back/Escape returns to Share, Import or Target code as appropriate; table Escape emits ordinary dismissal. Tab/Shift-Tab loops omit hidden/disabled actions; editor Tab moves focus and ordinary built-in text Undo remains untouched. Clearing a focused target action restores focus to Import.
- `refresh()` returns to the table, matching host reopen/save behavior. Import confirmation emits without hiding; root alone decides result/temporary target and hides after pin.

## Static checks and runtime request

`git diff --check` passes. Both changed files and current host integration were read after edits; method/signal shapes match `.godot/collaboration/round3-implementation.md`.

Root should run `test_layout_challenge_window` with existing `test_layout_scoreboard_ui`, codec/store and actual controller suites. This agent has not claimed parser/headless/GPU success.

The new suite covers Chinese/English, 1280×720 host, actual 760×420 Window, maximum code/title, active/stale state, storage failure display, detached targets, unchanged Game/Test state, objective stability, keyboard Check/pin, TextEdit Undo, stale preview/edit/late-result refusal, Return/Escape focus and underlying-shortcut isolation. GPU additionally checks explicit real clipboard Copy/paste and restores the pre-test clipboard.

Optional rendered invocation in root's isolated copied project:

```sh
<Godot-4.7.1> --path <isolated-project> \
  --script res://tests/test_layout_challenge_window.gd \
  -- --capture-size=1280x720 --layout-challenge-capture
```

It writes six checked PNGs under the isolated `user://`: table, import preview and retained-code page in both locales. These are scripted presenter frames, not native OS or exported-package acceptance. Root's controller test covers actual host/data/completion behavior; existing settings/feedback tests cover F10/F8 nesting.
