# Native C→P→G journey and restart — 2026-10-08 resume

This is an operator observation record from the actual exported Mac application,
using CUA native mouse/keyboard input. No support insertion, scripted controller
fixture or direct modification of the save was used to earn these nine tasks.
Screenshots were inspected in the conversation; the CUA API returned pixels but
provided no documented file-saving operation, so there are **no committed native
PNG captures** in this folder. The three JSON files are copies of this run's own
isolated saved profile, not replacement fixtures.

## Frozen artifact

- Runtime commit: `ade587d50e02561767417649c2da2b58ce150c89`.
- Actual app: `build/free-alpha-ade587d50e02/macOS/Von-Neumann-Bottleneck.app`.
- Isolated profile: `Redo-ade587d`; custom user directory
  `VonNeumannBottleneckCandidates/representation/Redo-ade587d`.
- Engine: `4.7.1.stable.official.a13da4feb`, Apple M2 OpenGL compatibility renderer,
  original assets and Noto font. Initial native log showed this engine/device.
- Archive: 78,565,380 bytes, SHA256
  `8e4b05f18b1635b1be697fff1229691a7623753ddb73bffec2d5c9885e7eb01a`.
- Export/identity/strict codesign/16 actual binary checks are the separately retained
  [keyboard checkpoint](../keyboard-redo/README.md), not newly repeated here.

Fresh native inventory no longer reported the previous Mac-locked blocker. Root
alone operated Git, Godot and GUI. Runtime and archive did not change in this run.

## Observed player route

| Task | Actual native observation |
| --- | --- |
| C1 | Learned the two public ABAC/ABAD examples at order1, sent 1536 source cells; lossless restoration and completion. Predictive cost 38303 ops,4543 total transfer B,20092 cycles. Selected cell32's D exception: context A, predicted B, actual D, counts B12/C6/D6; one marker bit and two correction bits. |
| C2 | Same model/machine: RAW 13134 cycles,436 packet B; predictive 20092 cycles,430 packet B. UI showed six fewer packet bytes but 6958 extra cycles, separate from total rule traffic. Earned completion. |
| C3 | Same material/model/bus1/request64/cache21/RAM8192, only CPU changes. CPU1: RAW235928 vs predictive258602 cycles. CPU64: RAW225601 vs predictive220899. Packet sizes remain436/430. Both native comparisons earned completion. |
| P1 | Connected sealed future. Commit displayed the chosen prediction while truth stayed sealed; Reveal then enabled. Next mismatch selected cell4, predicted B→actual C with synchronized context/counts. Finished 7/10 hits and earned completion; frozen model unchanged. |
| P2 | Learned order2 using original ordered examples; practice 9/10 hits,392 ops,269 B,1620 cycles; preparation separately12731 cycles,479 ops,755 B,peak326. Earned completion only with the proper comparable source/order. |
| P3 | Unseen check prefix A,C; no learning during checking. Native Commit/Reveal and remaining-step run yielded14/14 hits,494 ops,273 B,1881 cycles and completion. |
| G1 | Disconnected truth and fed output into context. AB initial, weighted counts, seed17,length64, order2 frozen model. Generated64 cells with no target:2168 ops,334 B,5232 cycles,peak342; generate1069/output4163 cycles. Earned completion. |
| G2 | Opened naming flow, entered `回灌光纹·原生试玩`, explicitly confirmed save. Work appeared in list and closure; G2 completed without requiring different outputs. |
| G3 | Navigated to G3; completion already earned by the actual legal confirmed work. Opened full saved-work modal showing all64 cells, then saved G3 draft. |

Order1 model identity:
`9ef3356e1f82ada6ea8d4385261140235ef5f0069125467c77adf5bd8ade4441`.
Order2 saved-work identity:
`f2a7f52567cda7f6aa3647be16dd3aee696066444da8145ccc3e988b17cd2610`.

## Actual mistakes and tool limitations

P2 dropdown keyboard operation initially selected order0; this was operator input,
not a task completion. Another focus mistake temporarily removed ABAC; restoring
checkboxes reversed example order. The resulting9/10 practice correctly did not
complete the comparable-model task. Removing/re-adding ABAD restored the original
ordered examples, learning order2 and rerunning practice earned P2. P3 initially
opened a seen training passage; the UI correctly warned it was not an unseen check.
The operator then used the actual Check action, without silently counting the seen
passage as P3 proof.

Early coordinate inputs earned C tasks/P1 and controlled P2 choices. Later native
pointer calls repeatedly failed inside the CUA server with `windowNotFoundAtPosition`
or `noWindowsAvailable` although the app was running and screenshots/keyboard worked.
Rebinding, raise/fullscreen changes and session reset did not restore coordinate
input. Native Tab/ShiftTab/Return/paste completed the remaining route. This is a
recorded automation limitation, not sufficient evidence of a game input defect.
Godot controls were absent from AX; focus was observed in screenshots before actions.
Disabled buttons remain Tab-focusable, and workbench rebuilds reset focus, increasing
operator steps. This did not prevent completing the route.

System Cmd+Q and native menu Quit attempts did not establish termination. The actual
in-game home settings `退出游戏` button did: immediately following AX access returned
`procNotFound: no eligible process with specified descriptor`. No force kill was used.
Fullscreen home captures showed a narrow noisy strip above game content in the native
capture; windowed workbench captures were legible. Its capture/display origin is
unresolved, not a verified renderer repair. This run makes no listening claim.

## Real quit/restart/replay/fork

1. Native Save draft on G3; copied [before-restart.json](before-restart.json).
2. Workbench Exit returned home; home Continue pointed to G3. Native Escape opened
   home settings; Tab from Resume selected Quit, Return closed the process.
3. Relaunched the exact frozen app path with CUA. Home Continue still pointed to G3.
   Copied [after-restart.json](after-restart.json): byte-for-byte equal to before.
4. Native Continue entered G3 showing protected64-cell snapshot, correct model/name,
   and **no claimed current-run costs**. Native recipe replay reported matching
   snapshot and2168 ops/334 B/5232 cycles, keeping saved data intact.
5. Native Fork cleared presented output/costs, marked unsaved draft, retained saved
   work, enabled Undo. Native Save draft persisted the fork. Copied
   [after-fork.json](after-fork.json): identical works and supports to before, with
   `parent_work` referencing the protected work's actual id. No second work was made.
6. Read-only Python assertions on those copies passed: restart exact bytes,64 output
   cells, nine task supports, unchanged work/support dictionaries and correct fork
   parent/task8. [receipt.json](receipt.json) contains exact hashes and output.

Saved work id:
`478739dc14e3f53132c51f6881e17b00da40f1640f9f92b3549bdf0b5446f40c`.
The copied JSON contains only generated candidate game data. Production profile was
not read or modified. App presentation language returned Chinese after restart;
locale per scene and global preferences were not revised.

## Acceptance boundary

PASS for this known-answer operator's actual exported C1–G3/save/restart/replay/fork
route. Prior controller/renderer/core/wider-route checks remain separate evidence;
no full-suite rerun or identical package rebuild was needed for documentation only.
No new implementation defect was established by this route.

Independent beginner explanation, listening/artistic judgment, other devices,
Windows/clean-install/distribution and a native earned original40/Representation/
Service journey remain open. This does not establish that the entire game is
bug-free or that the broad whole-game goal is complete. No main merge/public release.
