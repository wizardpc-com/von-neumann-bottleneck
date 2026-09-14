# Repository freshness check · 2026-09-14

Runtime baseline: `e24c34e`. `git fetch origin` confirmed main and origin/main
matched before this documentation-only follow-up. Unrelated project settings,
user-downloaded plans and generated UID files are preserved.

## Changes

- Refresh both README home/tree galleries from the current isolated Game scenes.
  [Image provenance and hashes](../../images/readme/README.md) distinguish these
  captures from earlier CPU, double-buffer and layout examples.
- Update the architecture map to five regions, Chapter 1’s two optional applications,
  save schema 2 and rejected-release-only diagnostics; describe current diagrams.
- Replace obsolete Mac handoff queues and candidate instructions with the current
  workflow. Retain links to historical migration evidence rather than deleting it.
- Update bilingual changelog, test entry points and the wire/guidance plan queue.
- Explicitly separate source and frozen-package identities. The existing
  `free-alpha-60de5e54c95d` omits recent runtime fixes; it is not relabelled or rebuilt.
- Replace one broken local historical ZIP link with its original filename and hash.

## Fresh verification

- Godot 4.7.1 isolated import, userdata probe, `test_localization` and
  `test_release_convergence`: all pass. [Machine-readable result](isolated-results.json).
  Complete logs remain in `.godot/verification/20260914T041306Z-16ab9036/`.
- Regenerate the task maintenance matrix through `scripts/export-task-matrix.gd`:
  40 tasks; byte-identical to the tracked matrix, so no artificial update is made.
- Capture four Chinese/English hub/tree PNGs with `capture.gd`; PNG writes succeed,
  runtime/localization files match the imported copy, all final frames are 2940×1846
  Mac display pixels. Visually review the resulting scenes.
- Validate all ten README image hashes and dimensions against their three manifests.
- Check Markdown local file links throughout tracked documentation and current
  README/changelog navigation anchors. No missing destinations remain. The checker
  excludes external URLs, code fences and example wildcard paths; this is not a
  claim that external websites or old downloadable releases were exercised.
- `git diff --check` passes. No runtime, simulation, progression or player save edits.

The first capture invocation omitted the documented capture-size argument; its
startup size differed between frames. Those frames were replaced by the final
capture invocation. The one-off manifest checker initially assumed one dimensions
schema; it was corrected to read both existing manifest formats before the final pass.

This task verifies documentation and scene rendering. It adds no native mouse,
Windows hardware, external-player or new exported-package acceptance. Those gates
remain in [RELEASE_BLOCKERS](../../../RELEASE_BLOCKERS.md).
