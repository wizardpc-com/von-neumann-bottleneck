# Original experience recovery

## Scope and authority

The 2026-09-05 user instruction supersedes the demo blueprint's replacement mainline, optional legacy workshop, and fixed-workspace decisions. Restore the existing Hardware Foundations desktop as the ordinary Game path, followed by the existing Chapter 1 and Chapter 2. Keep the eight-task implementation and both save families for comparison. This bounded change covers shared interactions and Tutorial, Half Adder, and CPU presentation; other level editing awaits human playtesting.

Simulation, provenance validation, prerequisite ordering, Game/Test separation, saves, and Git safety remain unchanged. No engine rewrite, answer injection, save deletion, commit, or push is authorized.

## Protection and baseline

- HEAD: `76ef11610c3faf2b81722877fa91877a4589074d`; direct predecessor: `d7aa2f1788c133a6f8f35233bbc6ee7e89f0b932`.
- Initial staged, unstaged, and untracked lists are empty. The redesign is already committed.
- Recovery root: `.godot/recovery/20260905T175901/backup/`. All 321 tracked working files are copied with matching SHA256 hashes; staged/unstaged patches and status are recorded. Ignored builds and prior evidence remain in place.
- Five actual Roaming Godot player files are backed up with source-before/source-after/backup hash equality: `savegame_v1.json` and `.bak`, `hardware_workbenches_v1.json`, `demo_progress_v1.json` and `.bak`. The Local candidate directory is absent. See `workspace-manifest.json`, `player-save-manifest.json`, and `player-save-scan.json` in the recovery root. Tests use isolated runtime directories.

## Execution

1. Restore the existing hub/default scene and chapter navigation; retain a secondary comparison entry.
2. Repair the original Mission and independently confirmed Hint levels. Keep editable graph controls and fixed terminal restrictions.
3. Exercise ordinary Game UI input through Tutorial and Half Adder; cover CPU controls without treating reference fixtures as ordinary progression evidence. Repair any reproduced shared interaction defects.
4. Run simulation, save, localization, UI regressions; inspect rendered windows and exported default entry. Deliver a uniquely named Windows package and document human-only gates.

## Capability recovery and evidence

| Old capability | Regression or existing defect | Recovery | Evidence |
| --- | --- | --- | --- |
| Original chapter progression | Default scene points at DemoMenu | Reconnect original hub and return paths | GUI input earns both branches, CPU and LOAD/STORE, then opens Chapter 1; exported hub visually observed |
| Branch, erase, selection, clipboard, undo | New board bypasses CircuitGraphEdit; original placement preview intercepts input, occupied-input gestures race, closing Inspector loses focus | Reuse original controls; fix event ownership, preview filtering, nearest-port hit tests, event drag coordinates and focus return | Native GUI checks for transformed placement, middle/network/end branches, precise erasure, undo/redo and multi-selection pass in both locales |
| Movable, compact, reopenable Mission | New board replaces Mission with fixed goal text; original pages contain solution recipes | Restore original desktop, explicit specifications and short goal; wrap long toolbar without shrinking fonts | Rendered Chinese/English Mission, Previous/Next, move/minimize/close/reopen and window/fullscreen pass |
| Independent H1/H2/H3 | New board reveals inline text; original next actions also lack confirmation | Original readonly board plus separate H2/H3 confirmation | Tutorial/Half Adder/CPU cancel/confirm, no-skip, readonly, return snapshot equality and remembered level pass |
| Player workbench isolation | Separate demo store does not certify old builds | Preserve both stores, original validation and namespace | Named designs through real GUI; save/provenance regressions pass; five actual files and backups match original hashes |
| Free CPU wiring | Original staged view dims/disables later modules and gates formal tests on exact reference edges | All modules editable; stages inspect input connection presence; full behavioral tests always available | Legal wrong source accepted electrically but fails behavior; corrected CPU passes all seven steps and seals |

## Implementation decisions

- Use the existing editor and floating windows; no additional editor or shell.
- Hint return follows ADR 0015: reconstructing the board clears undo/redo and clipboard. Preserve saved name, topology, layout, and wire colors; do not claim undo history survives.
- Hint reentry remembers the highest actively revealed level during this editor session, separately per Game/Test level. No timed or score penalties.
- Real UI acceptance uses native Godot input dispatch and rendered-window inspection. It is not a physical mouse or novice comprehension test.
- Briefing copy changes outside the three focus levels only remove exposed wiring recipes and clarify existing Latch/Register/module specifications. No other level layout, content topology, prerequisite or simulation behavior is rewritten.

## Progress

- 2026-09-05: Read repository guidance, architecture/status, ADR 0015, relevant editor/Mission/Hint/save code, history and diff. Verified backup before implementation. Default host bypass is confirmed in source; remaining interaction causes require event replay.
- 2026-09-05: Completed the repairs in the capability table. Twenty suites pass, including 413 rendered ordinary Game GUI checks in each locale. Hardware UI, prologue UI and localization were rerun after the final responsive/focus fixes.
- 2026-09-05: Exported `recovery-20260905T175901-76ef116`; observed its actual ordinary desktop hub and build ID. Desktop input stopped at the user-input guard; separate headless EXE startup exited 0. Produced the unique ZIP and verified unchanged actual save hashes. See [final status and package hashes](../../status/in-place-recovery.md).

## Remaining gates

Bounded implementation and automated/rendered verification are complete. Physical mouse feel, high DPI, and novice comprehension require human observation. The exported EXE's full OS-input route was not traversed; its default hub was observed, while full construction acceptance uses native Godot GUI dispatch. No full eight-task completion claim applies to this recovery. Further level changes wait for this version's human playtest.
