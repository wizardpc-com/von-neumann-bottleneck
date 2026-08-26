# Documentation map

Repository-local documentation is the source of truth for future human and Codex work.

- `design/core-principles.md`: settled design direction, prototype choices, and open design questions.
- `architecture/simulation.md`: current simulation pipeline, cost ownership, invariants, and model limits.
- `architecture/localization.md`: default locale, catalog boundary, language-neutral technical evidence, and the process for adding a locale.
- `architecture/content-system.md`: explicit campaign registry, content-pack extension contract, player-owned state, and the boundary between authored content and executable mechanics.
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
