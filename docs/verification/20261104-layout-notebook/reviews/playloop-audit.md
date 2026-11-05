# Round5 player-loop audit

Owner: `/root/audit_polish`. Read-only audit of HEAD `3182a469fc3c222854f6976d8f251b6489f7030c`, branch `codex/gameplay-systems-20261104`. No production/UI/translation changes, Git mutations or Godot execution by this agent. Recommendations below are not frozen product decisions.

## Recommendation

Prioritize a **retained plan notebook with an explicit response/space envelope**. The loop should be: run a plan → keep the measured recipe with a name → choose the limits that matter → compare eligible recipes on total cycles or RAM → restore one recipe and improve it → close → reopen the same isolated notebook and continue.

This fits the root continuation candidate. It addresses the strongest current loss of player value while using the existing model. Four workloads already demonstrate genuine competing response/total/traffic/space results; another workload generator or another challenge-code protocol would leave the basic retention gap unresolved. A notebook is useful even if a particular chosen envelope has only one eligible metric class. It must not imply that every envelope has an improving answer, that a sampled winner is globally optimal, or that a ranking grants campaign completion.

Keep both Q1 and copy-space limits visible together, with total/RAM as a separate comparison objective. Do not add a weighted score. Treat these limits as player goals applied to genuine completed measurements, not simulator parameters, admission rules, or fabricated penalties. Confirm the exact useful envelopes with the root's production-model probe before selecting any built-in examples.

## Main blockers and source evidence

| Priority | Observed behavior | Consequence and bounded response |
| --- | --- | --- |
| P1 | `session.gd:2,10-16,60-85,154-158` keeps all work in memory. `lab.gd:674-701` only offers keep exploring or discard/exit. | A discovered strategy has no reliable return route after closing. Retain recipes and resumable drafts in a separate experimental notebook; the exit flow must tell the truth about what reached disk. |
| P1 | `scripts/run-experiment.py:22-23` rejects `layout_strategy --profile`; lines 32-35,51 create a new timestamped Checks profile. `lab.gd:55-64` only accepts Checks paths. | A save button alone is insufficient: the next ordinary launcher invocation cannot find the saved work. A reusable, explicitly isolated experiment profile must be selected before any autoload starts. |
| P2 | `session.gd:77-84` appends every run and prunes beyond24, protecting only the selected row and baseline. `lab.gd:426` identifies entries by run number. | More than two useful competing strategies can disappear while exploring; numeric IDs are difficult to recognize next time. Keep named recipes outside transient history eviction. Repeated measurements may remain genuine history, but must not consume or overwrite saved notebook entries. |
| P2 | `session.gd:124-140` truthfully compares four signed axes; `lab.gd:452-463` says tradeoff but has no goal contract or eligibility boundary. | A player can observe a tradeoff without being able to say which plan suits the current purpose. Q1/copy caps plus total/RAM comparison provide that purpose, while retaining the other metrics visibly. |
| P2 | `lab.gd:415-447` separates selected evidence from live draft correctly. Existing formal named save, however, explicitly saves the current draft (`layout_scoreboard_window.gd:91-98`, `layout_chapter.gd:784-805`). | Reuse the separation, not ambiguous save scope. A notebook action next to a selected run should be called **Keep selected plan**, and preserve that immutable measured recipe even when the editor differs. Draft resumption is a separate status. |
| P3 | `lab.gd:627-638` returns for every focused LineEdit/TextEdit before the Run shortcut, including numeric editors. `test_layout_strategy_ui.gd:192-202` covers text Undo but not the edit→Run shortcut. | Source inspection suggests an extra focus step after typing a number. If this round touches controls, verify and optionally support committing the numeric edit then Cmd/Ctrl+Enter once. Preserve text Undo and modal ownership. This is a static friction observation, not a reproduced native defect. |

There is no reason here to alter the contested Chapter4 panel geometry, CPU disclosure, map navigation, or other Opus choices. Those remain in the durable audit queue.

## Minimal UI and player flow

Retain the current two-pane layout, permanent Run/Undo/Redo/language/Settings/Exit controls and existing Evidence/Public pages. Add the notebook within the Compare area rather than a separate navigation hierarchy.

1. The existing workload selector remains the condition boundary. Under it, a compact goal row shows `Q1 ≤ … cycles`, `Copy ≤ … B` and a comparison choice `Total cycles / RAM bytes`. Initial limits can use a clearly explained nonrestrictive state; do not silently select a challenge that excludes every starter. A separate “Use selected run's limits” action is optional, if the probe shows it useful.
2. Use a small source switch `本次运行 / Recent runs` and `已保留 / Kept plans` above one consistent four-metric table. The notebook view gives recipes meaningful names; avoid keeping both dense tables on screen at960×640.
3. After a correct real run, `保留所选方案 / Keep selected plan` opens a short name entry. It saves the selected run, not whichever draft is visible. A sensible unique suggested name allows one confirmation. Rename/remove can be compact secondary actions. A full notebook must be disclosed and require an explicit replacement/removal; never silently evict kept recipes.
4. Table selection only changes evidence/details. `载入改进 / Continue improving` applies the selected recipe as one Undo transaction, returns focus to an editing/run control and marks an edited draft as unmeasured. Editing the draft never changes a kept recipe.
5. Show `满足限制 / Within limits`, `Q1超限 / Q1 over limit`, `复制超限 / Copy over limit`, or `未完成 / Incomplete`. Failed/partial runs cannot win with low partial numbers. Preserve all four metrics; use “best among kept plans” or rank labels scoped to these measured entries. Equal selected-objective values share a rank.
6. Keep the comparison target or baseline independent of the table's sorting and filtering. A newly chosen envelope may make the baseline ineligible; label that explicitly without deleting the recipe or silently replacing the target.
7. Reopening the same notebook restores the last condition and its exact draft, including dormant copy choices. Kept entries are remeasured from recipes before being eligible; use `本机复测 / Remeasured locally` for fresh reconstructed evidence. Do not silently describe reconstructed Trace as a historical runtime trace. Transient runs and cross-process Undo may remain session-only if the UI states that distinction.

Suggested concise bilingual labels:

| 中文 | English | Scope |
| --- | --- | --- |
| 保留所选方案 | Keep selected plan | Selected measured recipe |
| 已保留 | Kept plans | Persistent recipes, current condition |
| 本次运行 | Recent runs | Bounded transient observations |
| 载入改进 | Continue improving | Explicit one-step-Undo restore |
| 首答上限 | Q1 limit | First submitted request's completion |
| 复制空间上限 | Copy limit | Copy scratch only |
| 按总周期比较 | Compare total cycles | Objective, not the Q1 cap |
| 按RAM流量比较 | Compare RAM bytes | Objective, not a combined score |
| 已保存 | Saved | Only after successful write |
| 尚未写入 · 重试 | Not saved · Retry | Live state differs from persisted bytes |

Names should not become external identifiers or trusted metric sources. Notebook removal must not unexpectedly erase the current draft, transient measurement, or independently retained comparison target.

## Entry, exit and persistence expectations

- Provide one documented repeatable launch route, such as a safe named layout-strategy profile, and a convenient local launcher for that exact profile. Prepare a fresh project copy as today, but bind a stable **experiment-only** data directory before import/startup. Do not reuse ordinary campaign paths, candidate sibling domains, `GlobalSave`, formal challenge sidecars or the `VNB4C1` codec.
- Keep the one-off QA route available and honestly labelled session-only. Do not claim “Saved” in a profile that the next launch cannot reach. Whether profile selection is opt-in or a stable experimental default is a root decision; the acceptance must verify two separate processes using the documented player-facing route.
- Store validated condition/model identity, recipe, bounded title and needed selection/goal preferences. Metrics and Trace must come from the actual current model, not editable persisted totals. The integrity audit owns exact schema, limits and protected-write mechanics.
- If drafts auto-save, save only normalized draft state; do not imply it is correct or measured. A failed or incompatible recipe may remain recoverable but must not join eligible rankings. Preserve exact dormant choices where valid.
- On write failure or unknown/corrupt format, preserve old bytes and live edits. Show the retry route and keep the departure guard. “Previously saved version” and “current in-memory proposal” must remain distinguishable after reopening, matching the repaired formal challenge semantics.
- When all persistent state is saved, ordinary Exit can leave directly if only explicitly session-only history would disappear; if a warning remains, it must describe only that remaining loss. Never continue to say all drafts are discarded after implementing their persistence.
- Persistence must remain local to this independent model. Game/Test switches, notebook opening, ranking and target selection grant no task completion, personal official record or telemetry `official_result`.

## Reuse from formal challenge flow

The current formal host is useful interaction evidence, not a subsystem to couple directly:

- `layout_chapter.gd:775-782` restores through existing Undo and explicit edit invalidation.
- `layout_chapter.gd:808-822` preserves the exact active target objective when the table's sort changes.
- `layout_chapter.gd:918-950` checks and rechecks imported recipes while preserving the draft.
- `layout_chapter.gd:968-978` distinguishes temporary unsaved proposals from previous saved targets.
- `layout_scoreboard_window.gd:302-334` starts import empty, invalidates a checked preview after text changes, and preserves text Undo.
- `tests/test_layout_challenge_controller.gd:119-171,223-262` tests preserved draft/Undo, real ties/improvements and failed-write exact retry.

The notebook round does not need another share/import protocol. Keeping its data contract narrow is sufficient groundwork for eventual replayable challenges.

## Acceptance for the selected increment

Root should execute these in isolated profiles; this audit did not run them.

1. **Actual two-strategy loop:** In `scan_batch`, run starter `(Q1,total,RAM,copy)=(307,2456,2176,0)` and source group8/tile1 `(531,552,272,0)`. Keep both with names. They stay visibly different and remeasure identically. A Q1 cap307 excludes the grouped plan; cap531 allows it. Total comparison then prefers552 over2456. These are published current-model examples, not new fixed game scores.
2. **Real space/response constraint:** In `scan_serial`, keep starter and full temperature copy `(557,1362,980,80)`. With Q1 cap557 and copy cap80 both are eligible and the copy has less total/RAM. Copy cap0 or Q1 cap307 excludes that recipe. Equality at the cap is accepted. Show actual disqualifying reason rather than substituting a fake score.
3. **Retained discovery survives:** After more than24 additional runs, keep both original named recipes, their distinct condition identity and goal. Close normally; start a second process with the documented notebook route. Verify exact draft/condition/goal/name resumption, freshly evaluated metrics, and the same expected Trace signatures for equal recipes.
4. **Scope and truthfulness:** A `scan_batch` recipe cannot appear as a comparable `scan_serial` score; changing conditions restores the corresponding notebook. Failed allocation and malformed imported/persisted data never become winners. No aggregate global “best,” official awards or changed campaign bytes.
5. **Inspection and restoration:** Select an older kept plan while the editor has an unrelated valid draft. Keep/rename/compare must preserve draft and Undo. Restore then one Undo returns the exact draft. Objective/envelope changes must not rewrite recipe or create a fake run. Test stale-measurement labels and all metric ties.
6. **Failure/retry:** Obstruct a real temporary write in a QA fixture. Old persisted bytes remain; live notebook/draft remain recoverable; UI says unsaved. Retry exact proposed state, restart, and confirm the intended version. Unknown format is protected, not overwritten. Exit/OS close offers a correct recover-or-discard choice when writes remain unsaved.
7. **Bilingual interaction:**960×640 and1280×720 Chinese/English with actual raw-image dimension assertions. Name editor Unicode/Undo, Tab loop, long names, disabled controls, F8/F10/exit nesting, language rebuild and precise focus return all preserve state. Test the documented Run shortcut after numeric text input if changed; never let name-text Undo undo the underlying plan.
8. **Evidence boundary:** Run focused model/session/notebook/UI/profile-isolation suites and the existing official legacy parity gate if shared paths change. Record actual two-process commands and profile path; native ordinary launch/close and nested Settings remain separate from scripted GPU acceptance. Do not infer long-term fun or native coverage from automated counts.

Root's continuation note reports fresh model/session baseline passing at `.godot/verification/20261105T021829Z-18f99d78/project`; this agent has not inspected those full logs and does not claim their runtime result independently.

## Remaining decisions

- Exact notebook profile root/default behavior, bounded capacity, draft auto-save schedule and protected file schema: root plus integrity audit.
- Whether the comparison envelope is per workload or part of a separate named goal, and which initial/example envelopes have meaningful competing plans: root plus strategy probe. Minimal recommendation is one remembered envelope per complete condition.
- Whether automatic local Pareto marking helps beyond explicit constrained ranking: optional; do not delay the retention loop or label finite samples globally optimal.
- Wider workloads, external codes and campaign promotion are follow-up work. Current production source remains unchanged by this audit.

Report ready for root review. No implementation ownership claimed.
