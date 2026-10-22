# Palette and placed component parity

Goal: palette, placement ghost and placed node share the same complete drawing and footprint. Preserve actual port identities/widths, simulation, provenance, historical frozen layouts and player saves. No redesign of the circuit bodies or unrelated lab changes.

Confirmed defects: modules use a separate compact renderer; constant previews omit configured numeric values; declared preview footprints omit space retained by actual GraphNode layout, clipping cards and shifting placement centering.

Implementation: use full-node preview factory for all logic kinds; fit cards uniformly by width with sufficient height; initialize constant values in the shared constructor; align declared footprints with settled native layout. Verify 23 kinds against visible settled GraphEdit nodes, mixed-width constants, source-bound frozen shapes, card clipping and existing placement/persistence/UI suites. No game window or GPU acceptance under the user's prior instruction.

Root owns code, tests, Godot and Git. Worker read-only audit complete.

Complete: all logic palette previews now use the full canvas node constructor, cards fit by width at uniform scale and retain full height, constants show configured numeric values, and declared footprints equal settled native node geometry. No actual canvas port/row layout or simulation contract changes.

Final isolated verification: 20261022T152037Z-5a21f4a6, 9 suites + import/user-directory gates 11/11 passed. New parity test passes 508 assertions, including two genuinely different frozen presentations, known constants and all23logic kinds. Existing placement, persistence, geometry, hardware/prologue UI and coach suites passed. Evidence docs/verification/20261022-palette-canvas-parity/README.md. No new full suite, GPU/native input acceptance, normal-save writes, Git commit/push or export. Previous lab cross-scene failures remain independently recorded.
