# Round 4 playable UX audit — 2026-11-04

Owner `/root/audit_polish`. Read-only audit under `.godot/collaboration/round4-tasks.md`; no production/test changes, Godot execution, Git mutation or player-data access. Recommendations below await the root's model/workload decision.

## Recommended scope

Build one standalone **调度与复制实验 / Scheduling and copying lab**, launched into an explicitly isolated profile. Its useful loop is:

**Choose a public workload → edit the order window and physical copy plan → run → compare with your previous run under the same conditions → inspect response/transfer evidence → restore either recipe and continue.**

Keep the experiment outside Game/Test campaign navigation and the existing portable challenge board for this increment. The prior model and all its valid cold-field results remain accessible unchanged. An experimental scene offers a reversible place to measure whether the proposed mechanics create actual choices before exposing them as ordinary fourth-chapter rules.

## Why current UI cannot simply acquire another strategy option

The present workbench calls the strategy area “Preparation before queries” and couples `batch` to copying (`layout_chapter.gd:189–213`). Players cannot express source-only query tiling, and the existing copy checkboxes require at least one field. Adding a “tile” option there would inherit misleading “preparation” language and complicate the established draft/score contracts.

The official model performs `_query_batch()` for all queries/repetitions in each copy batch. Round 3's fresh sample found cold-copy plans dominating the earlier examples; the sample does not establish a global optimum. This experiment should make the scheduling boundary visible, not relabel the old valid result as an exploit or an invalid achievement.

The old model emits logical outputs after all queries. If the new model emits each answer when its job finishes, response timing has a different semantic contract. Do not put the new first-response measure in the old leaderboard or synthesize an old response timestamp that its trace never recorded.

## Smallest useful controls

1. **Workload:** initially only the scenarios that the model audit can justify, likely “requests ready together” and “next request after previous response.” Display public ordered jobs, requested fields, record indices/count, repeats and readiness rule. A compact visible sentence should explain the admission boundary; details can occupy a Public requests tab.
2. **Query window:** the number of already available logical jobs that may be worked on together. Keep public request order fixed for the first experiment. This avoids an apparent first-response improvement obtained solely by renaming/reordering which job counts as “first.”
3. **Records per query tile:** expose only when more than one job can be interleaved and tile size changes the model's actual address/event order. Under a one-job window or serial admission, a tile-size setting may be a semantic no-op; disable/hide it with a short rule note instead of presenting false freedom.
4. **Copy plan:** source only / copy once / bounded copy tiles, as finally defined by the model audit. Source-only hides copy-field/layout/copy-size controls. Copying exposes only settings actually used: copied fields, destination layout and copy lifetime/extent. Preserve values when the player switches away so trying “source only” does not destroy a prior copy plan.

Query tiling and copy tiling must have different labels and observable effects. The exact control domain should follow the implemented model, not force another interpretation of the old `batch` field. If copying is scoped to a query window, show that explicitly; do not let a player assume one retained copy while the model repeats preparation for every group.

For destination layout, reuse the existing field/group concepts and small memory presenter where practical. A small explicitly named preset set is acceptable for the first bounded experiment if it is the actual playable domain, but do not claim it explores every layout supported by the old simulator. Avoid duplicating the whole fourth-chapter workbench solely to retain its drag mechanics.

Before keeping a control, demonstrate at least one legal scenario/plan where changing it alters the actual schedule, trace or modeled metric. Equal results for some cases are valid. A setting that never changes anything in the delivered scenarios should not ship as a central gameplay choice.

## Metrics and evidence

- Keep separate columns for **Q1 response**, **total cycles**, **RAM bytes** and **copy scratch peak**. No weighted score or universal “best” badge.
- Define Q1 response as the completion cycle of the first public logical request, including its real output cost. If the model instead uses earliest completed job, label it as such and keep job identity visible. Do not use the two definitions interchangeably.
- Show each job's actual completion cycle in a small response list/timeline. Selecting a job jumps to the recorded response/output event. A sum over all records cannot be presented as answered when only one tile has been consumed.
- Label scratch according to what the model measures. Existing peak counts the copy allocation, not every accumulator/output slot or total machine memory. A new scheduling model that does not charge those structures must not present this number as universal total memory use.
- Preparation reads/writes, source query reads, responses and tile boundaries should be selectable evidence filters. A small ordered event table plus a readable detail panel is sufficient; animation is optional and cannot determine timing.
- Distinguish correct complete, incomplete/error and resource-limit results. Failed partial work may remain in history for diagnosis but must not appear faster than a successful run in objective comparisons.
- Cross-model old/new inspection should label separate model identities. Show unavailable old response timing as “not recorded,” not zero. Automatic deltas and ranks belong only to identical model/workload/readiness conditions.
- Avoid preloaded optimized leaderboard examples. Start from a transparent source-only, one-job plan and let the player's runs populate history. Developer reference plans remain tests/probes.

## Layout and interaction

At 1280×720 use one root screen:

- A compact header with workload selector, Run, Undo/Redo, language, Settings and Exit experiment. Run remains visible when either pane scrolls.
- Left plan pane around 300–330px; Plan / Public requests tabs keep lengthy jobs and field controls from pushing Run below the viewport.
- Right pane with Comparison / Evidence tabs. Comparison lists the player's immutable runs and an explicit Restore selected plan action. Evidence shows the selected run, not the live controls.
- A short draft-state label and a separate selected-run identity prevent “edited values beside old numbers” ambiguity. Avoid repeating the authority/isolation explanation on every panel.

A practical minimum is approximately 960×640 if verified; do not advertise it before real measurement. At smaller supported widths, wrap top actions or stack panes rather than shrink the font below the existing readable body scale. The ordinary F8 panel also needs testing in whichever Window actually owns focus.

History should preserve separate drafts and Undo/Redo for each workload. Switching workloads should not reset an unfinished plan. Selecting a historical run only changes inspection. Restore copies its plan into the matching workload in one Undo transaction and marks current measurements stale. Named retained attempts can be a small bounded collection; names are local annotations, never metric identity.

Keep all model configuration separate from transient GUI state: selected field, selected job/event, scroll/tab choice and focused editor. Language rebuild must preserve draft, history, selection and Undo/Redo. `WindowMode.reload_localized_scene()` falls back to reloading the scene unless the host implements `reload_localized_scene()`; a new temporary lab must explicitly provide that in-place path.

Keyboard handling should return early when Settings, F8 feedback or a modal owns input. Text editors keep text Undo; workbench shortcuts operate only outside them. Esc closes the uppermost panel first, then asks to leave only if unsaved session work would actually be discarded. Do not make Esc unexpectedly route to the ordinary campaign hub.

## Entry, persistence and accidental authority

**Standalone is preferable now.**

`experiments/README.md` and `scripts/run-experiment.py` already establish copied projects, pinned Godot, locale selection and isolated custom user directories. Extend that route for the new domain rather than add a chapter/test-mode link. All project autoloads still initialize when directly launching a scene; a scene-level guard alone occurs too late to guarantee no normal player profile was read. The launcher must set isolation before importing/starting Godot, and the scene should additionally reject an unbound directory.

The launcher's current text claiming root F5 defaults to core40 is stale relative to the present 60-task default. If root edits the launcher, correct that specific message as part of making the new instructions accurate.

For the smallest first playable version:

- Session-local history, per-workload drafts and Undo are sufficient during one visit, provided Exit and OS close protect unsaved work and say exactly what will be lost.
- Prefer one resumable isolated preview project/profile for review, so reopening its dedicated launcher continues the same experimental sidecar. A new generic launch may still create a fresh profile.
- If adding named cross-process attempts, use a separate bounded experiment session file with its own version and protected write behavior. Store recipes and annotations, then remeasure on reopening; never persist a naked score as authority.
- Avoid extending candidate cross-domain `Context.FILES` or binding to the existing representation/service candidate profiles. The new domain should not find or rewrite a sibling campaign/candidate file by inferred path.
- Do not call `LayoutChapter.record_pass`, save experimental plans into its named/draft dictionaries, or emit `PlaytestData.record_official_run(&"chapter_4",...)`. That signal feeds personal records even if telemetry transport is off.
- Existing F8 can supply a screenshot/opinion in the isolated profile. `offline_context.gd` has an explicit host allowlist, so the new scene will initially report unavailable domain state; do not falsely claim a captured recipe. If a recipe snapshot is needed, add a narrowly scoped pure snapshot adapter under root ownership, without chapter completion identity.
- Existing portable challenge codes bind `layout-memory-1` and official cases. The experimental lab must neither import them as current experimental scores nor export its result as `VNB4C1`. A separately identified experiment sharing format can wait until this model proves useful.

## Decisive acceptance matrix

1. **Observable choice:** for each enabled control, exhibit at least one actual legal plan pair with the same outputs and changed event order/cost. Report any always-no-op controls and hide them before delivery.
2. **Tradeoff reality:** measure the intended source-tiling response-versus-total example and its copy alternative with the real model. If one choice dominates every delivered workload, report that honestly rather than add a fabricated delay or declare “depth” from the number of controls.
3. **Response semantics:** verify actual first-request/output event completion, every job's output and complete final ordering; rejected cross-request work in the serial scenario must remain explicit.
4. **Draft/history:** edit, run, switch workload, inspect older run, restore, Undo/Redo, change language and return. Exact draft/selection/history stays recoverable; old measurements remain immutable.
5. **Persistence, if included:** one process saves and another replays; unknown versions/corruption/write failure preserve original bytes and the active draft. No official save/score/progression file mutation attributable to experimental controls.
6. **Modal/input:** Tab/Shift-Tab/Enter, Cmd/Ctrl Undo, focused text edits, Settings language reload, F8→Esc→exact focus return, dirty Exit Cancel and OS-close notification.
7. **GPU:** Chinese and English at1280×720 and the claimed minimum, longest workload names, maximum job list and history, first-answer/total tradeoff visible, response-event selection and copy/source evidence. Capture real frames with checked image writes.
8. **Compatibility:** canonical old official runs/challenge replays unchanged before/after enabling the experimental implementation. Merely opening the experiment grants no task, reward or old leaderboard entry.

The model audit must settle job expansion, copy lifetime and the public workloads before implementation. The UX can then expose those rules directly without prematurely accepting new simulation semantics.
