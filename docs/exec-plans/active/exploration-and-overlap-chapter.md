# Exploration branches and Chapter 3

## Authorization and scope

The user explicitly adopted the latest planning discussion in ChatGPT conversation
`6a9ba8c0-65ec-83ea-9326-18cc6474f590` and requested implementation, removal of the
eight-task version, native play and iteration. Baseline main is d9f56bf. The latest
discussion supersedes its earlier data-layout-first staging.

Deliver two optional circuit applications (`selector`, after Half Adder; `delay`,
after Register), a searchable categorized component palette, a non-destructive
new blank scheme action, and Chapter 3 “别让计算原地等” with six nodes:
request/completion → {double buffering → backpressure, prefetch → prefetch limits}
→ bounded-budget synthesis. New branches never gate the existing 21 levels.
Data-layout applications remain the next independent expansion, after this chapter.

Remove eight-task runtime, its autoload, entry points, exclusive translations,
exclusive tests and packaging hooks. Preserve historical docs as marked history
and leave existing user files untouched; deleted code remains in Git history.
Do not migrate eight-task completions into original campaign progress.

## Invariants and design boundaries

- Godot 4.7.1; deterministic simulation independent of rendering.
- Keep existing circuit and Chapter 1/2 semantics, progression and save provenance.
- New exploration boards begin with fixed public I/O and no solution parts.
  Official behavior accepts equivalent circuits, with independent H1/H2/H3 boards.
- Do not change old seeds or existing default schemes. Blank creation makes a new
  named scheme with the same fixed I/O and no solution parts.
- Preserve natural placement/drag/cancel, branches, delete, undo/redo, focus and
  the current floating workbench style. Categorization reuses placement code.
- Chapter 3 owns a bounded new asynchronous resource model, not a rewrite of the
  previous simulators. Explicit buffers are separate from hardware-managed Cache.
  Wires only connect; screen distance has zero latency.
- One transfer resource and one compute resource may overlap. Requests finish at
  explicit times. Buffers have empty/filling/ready/in-use states. Invalid early
  reads, overwrites, duplicates and missing batches produce explanatory failures.
- Cache prefetch shares the transfer resource with demand reads, has finite queue
  capacity and deterministic replacement. No “optimal prefetch” special case.
- Wall time, compute busy, transfer busy, overlap and wait are separate metrics.
  A 4-batch 6-transfer/4-compute fixture must distinguish 40 serial from 28 overlap.
- Topology and applied instructions determine outcomes. No double-buffer toggle,
  automatically solved Game board, reference-circuit completion or animation score.
- New persistence must revalidate saved solutions and never manufacture old rewards.

## Affected areas

`src/demo`, `project.godot`, hub, content manifest/packs, circuit level startup,
component palette, scheme management, prologue map and verification; new bounded
`src/overlap_chapter` simulation/state/content plus a host using existing GraphEdit,
floating instruments, typography, hint conventions and handbook; GlobalSave and
chapter navigation integration; Chinese/English content and regression tests.

## Stages and acceptance

1. Remove the eight-task fork. Verify no live resource/autoload references remain;
   ordinary hub and retained regressions pass. Commit this reversible boundary.
2. Add exploration content, palette discovery and new blank schemes. Validate
   reference and alternative/error circuits, old seeds/progression preservation,
   old save restart, independent hints. Native build both new circuits from tools.
3. Implement bounded scheduling and content for 3-1/3-2; verify true overlap, failure
   diagnostics and deterministic traces. Build the real topology/program workflow.
4. Add variable-speed coordination, queued cache prefetch/eviction and capstone.
   Measure authored targets from simulation and demonstrate multiple valid designs
   and bandwidth-bound counterexamples. Integrate progress, public specs, hints
   and progressive diagrams without adding mandatory optional-branch gates.
5. Fresh isolated full checks, Chinese/English render/input checks, normal Game
   play of each new node, Retina/focus/shortcuts, independent restart. Record actual
   player findings and fix them. Commit significant verified increments.

No publication or release acceptance is inferred from test totals. Windows and
first-time human beginner acceptance require separate evidence.

## Progress

- 2026-09-09: read latest two design turns in full and current repository boundaries.
  Clean main at d9f56bf. Approved content/architecture expansion is scoped above.
  Resource scheduling, UI decisions and measured targets will be documented as
  implemented; unresolved details are not claims of completed features.

- Removal checkpoint: isolated run `20260909T100024Z-0682bada` passes import,
  directory isolation, all 16 retained suites and Chinese Game input 593/0.
  Tests for the removed fork were deleted with that fork, not counted as passing.
  Native hub inspection will accompany the new-content player pass.

- Exploration checkpoint: two optional branches and toolbox discovery implemented.
  Native ordinary Game alternate selector and two-register delay passed; normal
  restart retained both completions and the player board. See
  `docs/verification/2026-09-09-exploration/README.md`. Chapter 3 remains in progress.

- Chapter 3 development checkpoint: deterministic model, six nodes, editable workbench,
  buffer/state wiring, queued prefetch, trace/state replay, gated independent hints,
  progressive diagrams, local feedback instrumentation and revalidated persistence
  implemented. Core committed as `18e2233`. Both full isolated runs pass 19 suites;
  ordinary original-Game input is 593/0 in Chinese and English.
- Native Chapter 3 acceptance is blocked by the locked Mac. Computer use reports it
  cannot unlock the machine; user unlock requested. Test render checks found and
  fixed oversized windows and port/readability issues but are not counted as play.
  The active plan remains open. Detailed next player steps and evidence:
  `docs/verification/2026-09-09-overlap-development/README.md`.

- Subsequent native pass: all six Chapter 3 nodes completed in ordinary Game,
  including manual buffer wiring and an alternative Cache synthesis. Fixed native
  palette/card input, error-line/failed-timeline and cable/hint display bugs.
  Normal quit/Continue restored all six solutions and editable drafts. Fresh 19
  suites pass; final focused UI regression also passes. See
  `docs/verification/2026-09-09-overlap-native/README.md` for exact evidence.
- Keep this plan open for reliable application-switch cancellation verification;
  computer-use switching timed out and that check was not accepted. Windows and
  actual novice difficulty/fun remain separate acceptance work.
