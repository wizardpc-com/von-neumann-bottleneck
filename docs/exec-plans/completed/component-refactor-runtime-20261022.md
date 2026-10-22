# Component rendering and frozen player layouts

## Goal and scope
Complete the shared rendering of 23 circuit types and CPU/RAM/Bus, using the
supplied asset package as a visual and algorithm reference. Verify the real
palette, graph, wires and zoom before revising them; deliver comparable GPU
captures from baseline `30a92f8` and the final source.

## Invariants
Keep component IDs, port names/order/indices/widths, simulation, verification,
progression and canonical save signatures unchanged. Freeze visuals only through
successful existing sealing, separately from signed logic. Preserve old visual
snapshots and use family fallback for missing/invalid/derived data. Asset fixtures
are references and QA inputs, never installed as normal player accomplishments.
Normal player saves are not used for testing.

## Files and ownership
- Root: hardware graph/seal capture, module/symbol/palette renderers, shared
  visual vocabulary, graphical verification harness integration and documentation.
- `frozen_layout` (6.1 sol): layout generator and its two dedicated tests.
- `system_visuals` (6.1 sol): system surface and dedicated visual-state tests.
- `capture_harness` (6.1 sol): new real-game capture script only.
- Root exclusively owns Git mutations and Godot execution.

## Steps and verification
1. Inventory source and package, preserve baseline identity and isolate QA saves.
2. Capture baseline representative game views and full production-type catalog.
3. Repair shared shell continuity, readable palette presentation and true frozen
   layout input; retain real port geometry and event-driven presentation.
4. Run focused geometry, persistence, actual seal, input, localization and system
   tests; inspect graphical captures at native scale and two zoom levels.
5. Run relevant broader regression, inspect diff/source hashes and report actual
   results, remaining native/human acceptance boundaries and reproducible commands.

## Decisions and progress
- 2026-10-22: clean source baseline `30a92f8`; Claude handoff releases Godot/Git.
  Attachment SHA-256 `e09a82e14b6fe237894d5a63345dd7e159274f70a4b1d23cb50dcaa26d9317cb`.
  Extracted outside `res://`; its instructions remain reference material.
- Existing V1 frozen presentation, save sidecar and real seal gates are reused.
  New layouts may use a versioned aspect-preserving algorithm; V1 geometry stays
  stable. No Python generator or offline SVG ports become runtime authorities.

## Open acceptance
Visual style is subject to the owner's review. Automated GPU viewport input and
screenshots do not establish physical mouse/keyboard play, beginner comprehension,
all-task completion or exported package acceptance.

## Verified outcome · 2026-10-22
- Shared renderers cover all 26 kinds. Dense palette modules reuse the existing
  miniature; the canvas and sealed result retain real native ports and labels.
- V2 freezes internal stable footprints at the existing successful seal gate;
  legacy V1 bands are accepted unchanged. No signed model/schema modification.
- Final focused verification: 9 suites plus 2 isolation gates, 11/11 passed.
- Before/after GPU: 223 checks and 20 native-resolution frames per source, zero
  failures; actual earned seals reloaded and system trace/metrics matched exactly.
- Full snapshot: 219 stages, 216 passed. Immersive-lab and terminal-routing suites
  also fail on unchanged baseline (routing fails at different points); terminal
  language failed in the full run but passes baseline and final isolated reruns.
- Evidence: `docs/verification/20261022-component-refactor/README.md`, with raw logs,
  source hashes and explicit QA provenance. No commit/push/package publication.
- Implementation and delivery complete; native input, newcomer acceptance and the
  separate lab-test failures remain outside this verified component scope.
