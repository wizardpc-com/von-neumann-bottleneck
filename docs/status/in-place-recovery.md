# Original experience recovery — 2026-09-05

The default Game is again the original Hardware Foundations construction desktop, followed by Chapter 1 and Chapter 2. The eight-task implementation remains available from the secondary comparison button. It neither replaces construction nor certifies its achievements. The replacement-mainline, optional-workshop and fixed-workspace decisions in the old blueprint and ADR 0019 are withdrawn by the user's current instruction; those documents remain historical evidence.

Build identifier: `recovery-20260905T175901-76ef116`. This is a bounded playable recovery, with human usability acceptance still open. No eight-task redesign continuation is planned.

## Playable entry

- Windows package: `build/Von-Neumann-Bottleneck-Recovery-20260905T175901.zip`; executable: `build/recovery-20260905T175901/Von-Neumann-Bottleneck.exe`.
- Source: run `project.godot` with Godot 4.7.1. The configured entry is `src/ui/prototype_hub.tscn`.
- Choose Hardware Foundations. Tutorial unlocks the arithmetic and storage branches independently. Their player-built ALU and RAM unlock CPU; sealed CPU leads to LOAD/STORE and Chapter 1. The original Chapter 1 → Chapter 2 prerequisite remains intact.
- Existing Continue and named workbenches keep their original provenance reconciliation. No comparison completion flag is imported as verified construction.

## Actual causes, repairs and evidence

| Capability / regression | Observed cause | Final behavior and evidence |
| --- | --- | --- |
| Default free construction disappeared | The redesigned entry loaded a different board using plain GraphEdit instead of the original controller and CircuitGraphEdit signals | Original hub and return path restored. Native GUI replay starts from the configured scene in Game and earns both construction branches, CPU and LOAD/STORE before entering Chapter 1. |
| Body movement | Original drag code sampled viewport pointer state separately from the event; replay reproduced a stale coordinate and a huge jump | Use the transformed event position. GUI checks verify snapped displacement, undo and redo. Physical mouse feel is not inferred from replay. |
| Click placement | The preview's GraphNode intercepted the click after the ghost appeared | Preview ignores mouse input. Palette clicks place the selected part at its displayed, snapped coordinates, including after zoom/pan. |
| Branching from a connected input | Native backwards dragging and the custom branch handler both started; replay produced extra junctions and a phantom endpoint | One gesture owns the press/motion/release. A connected-input branch adds exactly one junction; wire-middle, waypoint and wired-end continuation also pass GUI checks. |
| Dense ports after zoom | Hit testing selected the first nearby port rather than the nearest | Nearest visible port wins. CPU 2-bit/1-bit rejection and legal 4-bit routes are exercised at its displayed zoom. |
| Connection feedback | Drag-end text overwrote the rejection; native incompatible drops were treated as empty space | Preserve the electrical/width reason and avoid a stray endpoint over an incompatible input. |
| Chosen wire color | New connections read an implicit default before storing the chosen palette index | Assign the active color on connection; GUI checks verify effective colors through branching, camera changes and Hint return. |
| Escape during placement | Gesture cancellation left the key unhandled, allowing the same key to navigate away | Active-gesture Escape is consumed; another navigation action remains available afterward. |
| Delete after inspection | Rendered English replay observed a selected node with no keyboard focus after closing Inspector | Closing a desktop tool returns focus to GraphEdit. Selection, Delete, copy/paste, undo/redo, and text-field-to-graph input are exercised. |
| English controls outside the window | A single non-wrapping toolbar imposed a minimum width larger than the viewport | Toolbar wraps without shrinking fonts; frequency label and value stay together. Header text wraps when needed. Window/fullscreen GUI checks cover both locales. |
| Mission hard to find / solution text exposed | The new host used a fixed task summary; several original briefing pages also contained wiring recipes | Restore movable/minimizable Mission, enlarge initial Test Bench, add a persistent short goal/reopen action. Tutorial/Half Adder/CPU lead with requirements. Small copy corrections separate Latch/Register behavior examples and other prologue module specifications from their existing H2 reasoning. Previous/Next remain available. |
| Hint lost its independent progressive flow | New host used inline hints; original Hint Next also lacked spoiler confirmation | Original independent read-only board returns. H1 requires opening Hint; H2 and H3 each require a separate request and confirmation, with an explicit complete-answer warning at H3. Cancel remains the initial focused action. |
| CPU legal wiring restricted | Original stages dimmed/disabled later modules and required exact reference wires before full tests | All modules and compatible connections are editable immediately. Stages check connected interfaces only; full behavioral tests remain authoritative. GUI replay accepts a fully connected wrong source, fails the seven-step test, then passes after the player input repairs that source. |
| Success had no obvious next action | Original post-seal completion exposed Continue but lacked its map return action | Explicit success offers the existing seal/continue action and a visible return to map. It never auto-advances. |

No simulation engine, test case, prerequisite, component source validation, save schema, or reference topology was changed. Ordinary wires retain zero delay. Animation frequency only controls presentation; cache management and applied-program authority remain unchanged. The fixed LOAD/STORE demonstration is still fixed. For test terminals, the original distinction remains: clipboard/Delete protect them, precise right erasure may remove them and Undo restores them.

## Verification

Evidence root: `.godot/recovery/20260905T175901/`.

- All 19 existing simulation, content, original UI, save, localization, telemetry and comparison suites pass. Only obsolete default-entry, hub wording and CPU answer-gate assertions were updated to their replacement contracts; their behavioral coverage remains.
- `tests/test_recovery_game_input.gd` adds ordinary Game GUI-dispatch acceptance. It sends mouse/key events to rendered controls and reads state for assertions. It does not call solution loaders, mutate progress, supply a Test library, call controller actions directly, or fast-forward playback internally. Tests use isolated data / the existing in-memory automated workbench boundary.
- The route creates named Tutorial and Half Adder designs, exercises body dragging, palette placement, wire-middle/network/end branches, precise erasure, undo/redo, marquee/multi-selection, clipboard, zoom/pan, movable/reopened Mission, window/fullscreen and keyboard focus. Each of Tutorial, Half Adder and CPU separately traverses H1 → cancel/confirm H2 → cancel/confirm H3 → return → remembered-level reentry.
- Hint return compares the name, canonical topology, every component position and effective wire color. Read-only editing is rejected. Full tests and sealing remain unavailable there. A half-adder expression different from H3, `(A OR B) AND NOT(A AND B)`, passes all four cases; CARRY is built separately.
- The GUI route then wires and seals Full Adder, ALU, SR Latch, Register and RAM through normal controls, completes CPU and LOAD/STORE, and opens Chapter 1 with earned sources. The original Chapter 1/2 suites separately cover their full progression. This is not a fresh physical-mouse playthrough of both later chapters.
- Chinese and English captures cover the hub, Mission, hint boards/confirmation, circuits, success, fullscreen and the Chapter 1 entry. Selected captures are in `docs/images/recovery-*.png`. Detailed check counts and final package results are recorded below.

Final verification: 20 suites pass (19 existing suites plus the new GUI suite). The rendered GUI suite passes **413/413 checks in Chinese and 413/413 in English** at a 1600×900 logical window and during fullscreen toggles. Logs: `logs/recovery-input-zh_CN.log`, `logs/recovery-input-en.log`; complete assertions: `ui-observations-zh_CN.json`, `ui-observations-en.json`. The affected Hardware UI, prologue UI and localization suites were rerun after the toolbar/focus repair and pass.

The release EXE was launched without Test/capture/helper flags, using isolated APPDATA/LOCALAPPDATA. Its actual desktop window was observed showing the original three chapter cards, locked Chapter 1/2, secondary comparison entry, and `recovery-20260905T175901-76ef116`. See [the exported window](../images/recovery-export.png). A subsequent desktop click encountered the Computer Use user-input guard, so desktop input stopped; the full route evidence above comes from Godot GUI dispatch, not an OS-level full playthrough of the EXE. A separate ordinary headless EXE startup with automatic exit returned 0 (`logs/package-headless.log`). Export-template external-script probing is unsupported and is not counted as evidence.

Package: **43,026,762 bytes**, SHA256 `19A4628912E9EE41C074971A283D101D66658A75747C96B975D9B504878E4CED`. Embedded-PCK EXE: **115,142,280 bytes**, SHA256 `50268CD3674EB4C50295C672D4AAD175F47BCBF84F19C53FB838E9E663162515`. The ZIP contains only the EXE and bilingual playtest readme; old packages remain in place.

The known Godot Windows root-certificate-store warning is present in logs. The matching 4.7.1 export emits its informational ICU compatibility notice. These are recorded separately from script, parse and assertion failures.

## Protection and compatibility

Initial HEAD was `76ef11610c3faf2b81722877fa91877a4589074d`; its direct predecessor is the supplied `d7aa2f1788c133a6f8f35233bbc6ee7e89f0b932`. The initial staged/unstaged/untracked lists were empty. This is selective in-place repair, not a repository rollback.

Before editing, all 321 tracked files were copied with SHA256 verification to `.godot/recovery/20260905T175901/backup/`; Git status, history and both empty patches were recorded. Five actual player files were also copied with source-before/source-after/backup hash equality: both `savegame_v1.json` files, the named-workbench manifest, and both `demo_progress_v1.json` files. The Roaming Godot directory contains them; the Local candidate is absent. Existing ignored builds and older evidence remain in place. No actual player file was used to seed GUI acceptance or removed. Final SHA256 verification confirms all five originals and backups are unchanged (`player-save-final-verification.json`). See `workspace-manifest.json`, `player-save-manifest.json`, and `player-save-scan.json` under `backup/`.

The supplied recovery attachment is retained at `docs/design/IN_PLACE_RECOVERY_AND_OPTIMIZATION.md` (original SHA256 `8ECAA49152556CBDB0F0B74842ECC6CC72EBFF961AA656E9AE888FEDA899D0C4`). The explicit current user request governs where it differs from historical design documents.

## Remaining human gates and limits

- Physical mouse drag comfort, branch discoverability and precise erasure feel: not observed with a human operator.
- High DPI: not tested. Window/fullscreen rendering and automated inputs are separate evidence.
- Novice comprehension, readability at the user's actual display, enjoyment and pace: pending. First try Tutorial/Half Adder with Mission + Inspector + H1/H2, without H3, then assess CPU module relationships and feedback.
- Hint return intentionally clears undo/redo and clipboard under ADR 0015. Names/topology/layout/colors are preserved. Viewed hint level is remembered within the editor session per Game/Test level, not across application restarts.
- Larger per-level revisions and further Chapter 1/2 content tuning wait for this version's human playtest. The eight-task redesign is stopped; the comparison implementation is preserved.

No commit, push, hard reset, clean, or whole-tree restoration is part of this delivery.
