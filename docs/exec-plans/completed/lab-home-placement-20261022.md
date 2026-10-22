# Laboratory home and placement polish

Goal: keep the existing room and terminal, put quit confirmation on the physical terminal screen, improve clear homepage readability and component placement responsiveness.

Scope: lab_home, lab_room_3d, lab_terminal, Hub quit routing, page skin lifecycle, component graph placement. Preserve existing component refactor changes, navigation ownership, actual progress, ports, snapping rules, simulation and player save contracts. No fixture installation or Git publication.

Steps: inspect existing room evidence and input routes; reuse the existing confirmation controls on the screen texture; verify cancellation, focus and screen picking; remove stale page callbacks and unnecessary placement redraw/construction; run isolated headless relevant suites and review diff.

2026-10-22: user requested no game window. No new graphical run or screenshot acceptance; visual comparison is deferred. Root owns engine/Git, bounded workers own page lifecycle and placement changes.

Completed: existing confirmation controls now render on physical glass, with perspective-correct mouse mapping, default No focus, real dispatched Escape and return-to-origin behavior. Warmed the existing sky lighting; no model or object rearrangement. Detached stale skin resize callbacks and guarded freed windows. Placement updates the child ghost directly, preserves unsnapped fractional coordinates, and avoids a disposable ghost at drag release.

Final verification: isolated 20261022T140013Z-10b76db7, 9 suites + import/user directory gates, 11/11 pass. Source receipts match 23 source/test files; 11 protected model/simulation/save contract files unchanged. Two additional cross-scene navigation regressions from the earlier expanded run remain failed, with raw logs retained. No new full suite, GUI window, GPU render, native input, FPS or visual acceptance. Evidence: docs/verification/20261022-lab-placement-polish/README.md. No Git commit/push/export. Visual and native placement-feel acceptance intentionally deferred under the user's latest instruction.
