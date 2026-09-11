# Documentation map

Start with [CURRENT_STATE](CURRENT_STATE.md), the single current entry. The documents below are subsystem references or dated implementation history.

- [Offline community preparation](architecture/community-feedback.md): personal records, consent, visit summaries, community and experimental scores.
- [Native and loopback evidence](verification/20260911-community-preparation/README.md), [owner deployment checklist](distribution/community-deployment-checklist.md), [operator migration runbook](../server/deploy/RUNBOOK.md).

- [Task tree and optional missions](exec-plans/active/task-tree-and-side-missions.md): historical 34-node expansion, now included in the 40-task game.
- [Local playtest evidence](status/playtest-instrumentation.md): visits, case outcomes, voluntary moments and multi-export reports.

- [Guided workbench and diagrams](verification/2026-09-09-guided-workbench/README.md): open tools, cable separation, focused Handbook, and this iteration's native/check evidence.
- [First-use guidance](design/first-use-guidance.md): the dated teaching inventory and pacing boundaries.

- [Mac native polish](status/mac-native-polish.md): current Mac UI changes, ordinary Game play evidence and approved restart recovery and its native verification.
- [Stable save recovery](verification/2026-09-08-save-recovery/README.md): byte-exact backups, provenance revalidation and repeat native startup.
- [Mac development handoff](development/mac-handoff.md): current baseline, Mac setup, isolated checks, Windows verification and next native-playtest tasks.
- [Completed migration delivery](exec-plans/completed/mac-development-handoff.md): published source, Windows prerelease and verification boundaries.

- [Visual and learning polish](status/visual-learning-polish.md): current signal controls, aligned schematics, instrument style, progressive Handbook, package and acceptance evidence.
- [Visual and learning plan](exec-plans/active/visual-learning-polish.md): implemented scope and pending native desktop / human acceptance.
- [Construction experience](status/construction-experience.md): earlier schematic, editing and learning improvements, package, evidence and human playtest gates.
- [Experience plan](exec-plans/completed/construction-experience.md): protected baseline, reference observations and capability preservation.
- [Recovery status](status/in-place-recovery.md): restored default route and earlier repair evidence.
- [Recovery plan](exec-plans/completed/in-place-recovery.md): scope, protected baseline and capability recovery table.
- [Demo blueprint](design/DEMO_REDESIGN_BLUEPRINT.md), [historical status](status/demo-redesign.md) and [ADR 0019](decisions/0019-eight-task-mainline-and-standard-modules.md): historical eight-task design, removed from runtime on 2026-09-09; replacement-mainline, optional-workshop and fixed-desktop decisions are superseded.

- `design/core-principles.md`: settled design direction, prototype choices, and open design questions.
- `architecture/simulation.md`: current simulation pipeline, cost ownership, invariants, and model limits.
- `architecture/localization.md`: default locale, catalog boundary, language-neutral technical evidence, and the process for adding a locale.
- `architecture/content-system.md`: explicit campaign registry, content-pack extension contract, player-owned state, global-save/workbench provenance reconciliation, and the boundary between authored content and executable mechanics.
- `status/cpu-building-prologue.md`: current tutorial-to-CPU campaign, reusable-component progression, temporal model, final LOAD/STORE bridge, limitations, and playtest questions.
- `status/chapter-1-waiting-for-data.md`: implemented five-level CPU/RAM/Bus investigation chapter, prediction and controlled-comparison flow, gated diagnosis evidence, exact cost model, limitations, and playtest questions.
- `status/chapter-2-reducing-data-movement.md`: implemented seven-level Cache/locality/working-set/blocking investigation, delayed Systems Notebook concepts, deterministic reference evidence, multiple capstone solutions, limitations, and playtest questions.
- `status/playtest-instrumentation.md`: anonymous offline session events, concise feedback flow, crash recovery, export format, automation flags, and the clean-playtest procedure.
- `status/hardware-foundations-01.md`: historical wiring/Half Adder milestone retained as design evidence.
- `status/prototype-v0.2.md`: preserved one-pass Cache Locality Lab baseline and reference tradeoffs retained as the Chapter 2 regression boundary.
- `status/prototype-v0.1.md`: what the tagged prototype actually implements and what it was meant to validate.
- `development/testing.md`: commands that have been run successfully in this repository.
- `development/git-workflow.md`: branch, review, commit, and release conventions.
- `development/codex-workflow.md`: scoping, planning, implementation, verification, and handoff for agent-assisted work.
- `decisions/`: durable architectural or product decisions that need rationale and consequences.
- `decisions/0016-system-performance-domain-boundary.md`: why Chapter 1 uses a bounded 8-bit system domain and provenance wrapper instead of widening the gate simulator or reusing the Cache-specific locality core.
- `decisions/0017-local-offline-playtest-observability.md`: why playtest evidence uses a separate append-only anonymous observer, optional feedback, and a single-file local export.
- `decisions/0018-provenance-checked-global-save.md`: why Continue uses a small Game-only recovery index and revalidates reusable components from independent workbenches.
- `decisions/0001-v0.2-core-loop-boundaries.md`: accepted v0.2 decisions for DSL authority, fixed topology, event-driven feedback, Profiler behavior, and goal evaluation.
- `decisions/0002-staged-animation-and-floating-instruments.md`: correction from simultaneous highlighting and exclusive drawers to staged component processing and coexisting instruments.
- `decisions/0003-explicit-program-application.md`: draft/apply/execute state boundary, supplied strategies, IR-derived explanations, and production animation extension.
- `decisions/0004-graph-authoritative-circuit-encapsulation.md`: visual-topology authority, separate circuit simulator, Test Bench boundary, and sealed HalfAdder snapshot.
- `decisions/0005-semantic-key-localization-boundary.md`: Simplified Chinese default, semantic translation keys, structured presentation diagnostics, and locale-independent simulation.
- `decisions/0006-tristate-live-circuit-analysis.md`: shared tri-state analysis, multi-driver resolution, structural cycle detection, and event-driven port presentation.
- `decisions/0007-default-low-and-transactional-schematic-editing.md`: zero-wire low defaults, reversible editor transactions, Shift selection, and structured subgraph clipboard semantics.
- `decisions/0008-hierarchical-temporal-cpu-prologue.md`: player-owned component dependencies, bounded sequential semantics, generated word wrappers, and the external-instruction CPU boundary.
- `decisions/0009-explicit-content-registry-and-player-state.md`: deterministic content packs/validation, registry-driven progression/rewards, player-state ownership, and the non-HDL behavior boundary.
- `decisions/0010-level-authoritative-component-placement.md`: level-derived component supply, authoritative repeated placement, editor shortcuts, and the truthful-rotation boundary.
- `decisions/0011-explicit-global-game-test-mode.md`: shared Game/Test mode, isolated test content, all-level development access, and normal-progression protection.
- `decisions/0012-component-aligned-trace-feedback.md`: wire-only overlays, real-symbol processing feedback, and removal of invented radial/orbit component models.
- `decisions/0013-functional-schematic-shapes-and-single-wire-rendering.md`: function-specific schematic surfaces, value-aware pin animation, RAM cursor feedback, and one full-path wire renderer.
- `decisions/0014-independent-branch-roots-and-explicit-component-palettes.md`: Half Adder/storage branch correction, XOR semantics, explicit per-level supplies, and draggable component windows.
- `decisions/0015-versioned-workbench-snapshots-and-read-only-hints.md`: per-mode/per-level named topology snapshots, empty-history restore, and three-stage read-only hint boards.
- `exec-plans/active/`: living plans for large or cross-cutting work.
- `exec-plans/completed/`: completed plans retained as implementation history.

Keep root documents navigational. Update the most specific source-of-truth document instead of repeating the same details across files.

- [Chapter 3 overlap model and persistence](architecture/overlap-chapter.md)
- [Chapter 3 native player pass and fixes](verification/2026-09-09-overlap-native/README.md)

## Current five-region candidate

- [Execution and remaining gates](exec-plans/active/five-chapter-free-alpha.md)
- [Layout model](architecture/layout-chapter.md)
- [Adding tasks without map coordinate changes](development/adding-tasks.md)
- [Native evidence](verification/20260910-five-chapter/README.md)
- [Candidate distribution](distribution/free-alpha.md)
- [Optional local feedback server](../server/README.md)
