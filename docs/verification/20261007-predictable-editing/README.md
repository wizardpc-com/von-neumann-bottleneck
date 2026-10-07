# Predictable editing — 2026-10-07

Runtime `2f47e75180c294821f75b367b4e2fe3cdd46355c`; candidate `free-alpha-2f47e75180c2`, isolated profile `Editing-2f47e75`. Internal team candidate, not public release or final artistic acceptance.

## Actual changes

- Service Save→Undo/Redo replaces stale saved-success feedback with an accurate unsaved-draft notice. Recorded measurements remain unchanged.
- Service undo/redo restores the selected request group alongside its plan, including move/join/split/history restoration. This is in-memory editing state; the persistent recipe format is unchanged.
- Representation clicking the active task preserves unfinished design names, the open design shelf and replay state. Initial saved/pending task entry still builds correctly.
- Copying an identical named Representation plan no longer promises a new Undo step. Cross-task context switching remains intact.

Two 6.1 Sol high workers owned separate labs/tests; a 6.1 Sol medium reviewer found no blocking issue. Root alone integrated, ran Godot/GUI, exported and handled Git. Simulation, prerequisite, completion and persistence semantics were not changed.

## Verification layers

Frozen runtime: nine affected suites plus import/isolation PASS; 2,576 source identities matched. Raw receipt, source manifest and full logs are in `frozen/`. Suites: service_undo_context (96), service_split_actions (30), service_session (63), service_design_shelf (48), representation_edit_context (39), representation_restored_notice (64), representation_design_shelf (38), representation_session (47), release_convergence (PASS). Counts are assertions, not play-throughs.

Export/import/licenses and candidate identity PASS. Fourteen actual packaged-binary checks PASS; `package/` holds manifest and raw logs. ZIP SHA256: `198fd53c0775a71c72deb6f0f56538f5cf6dbf18ca767eab35594097a9801097`.

Native CUA play on the delivered Mac app, fresh Chinese profile: Home→task tree; search 服务; select 少搬状态→enter Service. Initial A0 first/selected→Down→A0 second/selected→Save displayed saved-success→Undo restored A0 first/selected and displayed 已撤销草稿修改；旧实测不变。尚未保存；退出前请保存。→Redo restored A0 second/selected and the corresponding unsaved-redo message→Save→Cmd-Q. Process inspection confirmed no game/engine remained. Archive inspection confirms schema2, task0, B0/A0 first two groups, one slot, no measured runs/supports. This was editing QA, not an earned completion.

One CUA windowNotFoundAtPosition error occurred on the task-entry click; observing the current state and retrying succeeded. AX mostly exposed window/menu only, so verification used returned screenshots. Post-quit CUA returned procNotFound; process inspection confirmed exit. Screenshots were observed inline, not archived as image files. Native engine log contains no diagnostics.

Both own QA profile directories were reversibly archived with eight matching file hashes (`profile-archive.json`), leaving the delivered profile fresh. No real player save was edited.

## Playable route and remaining acceptance

Launch `build/free-alpha-2f47e75180c2/macOS/Von-Neumann-Bottleneck.app`. Recommended journey remains construction/core bottlenecks→core closure→Representation→persistent state/Service→earned extended review. Dotted recommendations are not new prerequisites; optional tasks remain optional. This turn repaired editing friction along that existing route rather than adding content domains.

Not newly verified natively: Representation repeated-task/name preservation, identical-plan copy, Service join/split/history restore or saved restart, English/temporary sessions, the full earned journey/ending. Those applicable editing cases have automated evidence only. Audio listening, novice comprehension, device coverage and final style/distribution acceptance remain open; earlier evidence retains its original source scope.

## Claude and team handoff

Copy/presentation interfaces: `experiments/service_plan/lab.gd` (restore_edit_state feedback and workbench UI) and `experiments/representation_region/region.gd` (change_task and restore_design feedback); preserve the accompanying tests. Existing theme/audio replacement boundaries remain as documented in the completion brief and prior handoffs. Do not move outcome authority into prose or change SessionStore/model contracts while polishing style.

Team decisions still needed: whether first-time players understand the relation between draft and measured history; preferred narrative restraint at earned closure; audio comfort after real listening. A Thought Within the World and the open ancestor background remain the governing direction.
