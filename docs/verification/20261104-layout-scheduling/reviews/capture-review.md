# Round4 capture harness review — final outcome

Reviewer: audit_polish. READ ONLY, except this report. No Godot execution, Git
mutation, product/test/helper edit or image modification was performed.

**Final reviewed outcome: PASS within the scripted GPU/viewport scope. No
remaining actionable capture or English-layout defect was found.**

This report supersedes its earlier recommendation. Engine startup flags alone
were NOT sufficient: gpu/20261105T014422Z still had242 checks and the same two
Chinese1280 raw-image dimension failures. The earlier claim that those flags
would prevent the observed failure must not be treated as accepted causality.

## Actual verified repair and receipts

Root retained `--windowed --resolution 1280x720`, then changed only the capture
fixture's synchronization:

- `exercise()` now instantiates/adds the real scene, settles it, and only then
  requests1280x720. This includes the scene's own ready/deferred layout work.
- `resize_viewport()` reasserts Windowed during each bounded observation and
  checks the ACTUAL rendered Image after frame_post_draw, rather than texture
  metadata alone. It requires four consecutive matching observations, resetting
  the count after any mismatch. It also performs the final actual-image check.
- `capture()` continues asserting each raw Image's expected dimensions and the
  save_png result. No assertion was loosened and no output image was rescaled.

I read both final results.json files and their complete original logs under
`.godot/verification/20261105T005513Z-6cc70bb5/`:

- headless/20261105T014628Z: exit0, errors[],214 checks/0 failures.
- gpu/20261105T014640Z: exit0, errors[],242 checks/0 failures; Godot
  4.7.1.stable.official.a13da4feb, Apple M2 OpenGL. The log records all12 captures.

I also read the retained flags-only failure result at gpu/20261105T014422Z.
The archived final log/result pairs and that failure pair are byte-for-byte
identical to the QA originals.

The exact native callback sequence was not instrumented. The earlier review
of Godot's a13da4feb macOS native fullscreen/resize implementation supports a
possible delayed-native-geometry explanation, but the new evidence proves only
that flags alone did not solve it and that post-scene, repeated actual-image
synchronization did. It does not isolate whether scene timing, repeated window
mode assertion, actual-image polling, or their combination was decisive.

## Six English final frames visually inspected

All were opened directly from the durable captures directory, at raw dimensions:

- layout-strategy-en-compare-1280.png —1280x720.
- layout-strategy-en-evidence-1280.png —1280x720.
- layout-strategy-en-compare-960.png —960x640.
- layout-strategy-en-evidence-960.png —960x640.
- layout-strategy-en-public-960.png —960x640.
- layout-strategy-en-quit-960.png —960x640.

At both sizes, Run/Undo/Redo/language/Settings/Exit are visible and the complete
left plan controls remain inside the viewport. Comparison rows, four metrics,
selected recipe, restore/reference actions and signed tradeoff are readable.
Evidence table and detail pane have distinct visible scrolling regions;
partial JSON at the lower scroll boundary is scrollable content, not a missing
control. Public workload correctly distinguishes first-submitted Q1 and lists
request readiness/costs in its scrollable reading area. The quit guard retains
both complete actions, a readable loss warning and an unmistakable initial Keep
exploring focus outline. No overlap, viewport overflow or inaccessible primary
action is apparent in these six frames. Chinese visual review belongs to root.

## Fresh source, frame and copied-receipt binding

I independently recomputed SHA256 for all1171 entries in source-sha256.json
against BOTH current source and its declared QA project. Every recorded digest
matches the actual file.1170 source/QA pairs are identical. The sole intentional
exception is project.godot: QA adds two custom-user-directory lines for the
isolated playable-preview profile and selects the experimental main scene.
There are no unexplained project-setting differences.

Relevant current source/QA identical hashes:

- lab.gd: a5a87f4e5183c0f767eade4077c641b52bb8573a35abe935c4ca853d110a4ae3
- lab.tscn: 6d94418964144051ac4895da143abb2aa9ebf6d814fb87e5f8242d78b36d6364
- model.gd: 8c980ac8a9e09fd4a491d3cf392a267cd64108550af77cf54bd95a0f2b36b23f
- session.gd: 6601c2eecfeffcae2c94d3d3d7f427dfc179917cfd3eb71a24b349e0548c0087
- test_layout_strategy_ui.gd: bce9bc35bf1426de331a05f0211330773968ebf99d768d3d8b8aea3b5807a030

For every frame-sha256.json entry, I recomputed PNG IHDR dimensions, byte count
and SHA256, and verified its referenced log exists:12 final captures plus12
explicit historical diagnostics, no mismatch. Each final capture also matches
its declared original PNG in the isolated20261105T014640Z profile byte-for-byte.
All12 final images have the expected1280x720 or960x640 raw dimensions.

The final two result/log pairs and the flags-only failure result/log pair in
`docs/verification/20261104-layout-scheduling/logs/` match their QA counterparts.
The old oversized images/failure logs must remain historical diagnostics, never
relabeled as the final1280 acceptance.

## Limits and release

This accepts the described raw-window sizes and scripted scene interaction
checks, not native mouse comfort, general fullscreen-transition correctness,
newcomer comprehension, exported packages, another platform, or a full repository
regression. Native observations retain their separate stated limitations.
No new production change is recommended for this bounded capture failure.
Report ownership is released to root for archival/integration; all runtime,
test, fixture and document ownership otherwise remains with root.
