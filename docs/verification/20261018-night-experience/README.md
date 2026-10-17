# Night experience candidate — 2026-10-18

PR10 was squash merged as `bf8f61647c03c8bba868cc833b3832e274bd4aee` after four
successful exact-head checks. The original checkout's unrelated `test_ui.gd`
deletion was preserved. Work is on isolated branch `codex/night-experience-20261018`.

## R1 observable changes

- Fresh Home Start offers a skippable Yi message tied to the actual NOT task;
  replay is available without changing progress. Five real tutorial actions still
  own first completion; NOT high→low is explicitly valid.
- Existing handbook rules have independent numeric A/B input buttons, computed
  outputs and active truth rows. Practice does not modify a player's circuit.
- Shared surfaces are calmer, with explicit focus/selection/disabled states;
  optional light comparison is a component sample, not a game-wide light mode.
- Enabled C/P/G regions have visible map shortcuts and actual catalog counts.
  Tester entry availability remains distinct from completion/model preparation.

## Fresh validation

All checks use pinned Windows Godot4.7.1 and isolated QA data. R0 import/isolation
plus four suites passed6/6; rendered old Home passed4021 checks. R1 selected
reruns passed handbook1163, three-size bilingual Home, theme contrast/state,
existing feedback/continuation/tutorial, and final route240/narrative61 checks.
Latest focused6/6: `.godot/verification/20261017T182957Z-bfe3a17f/results.json`.
Full regression, final package and final rendered comparison are pending.

Earlier failures are retained under `.godot/verification/20261017T182542Z-bb614da0/`
and `20261017T182655Z-9bd31770/`: typed-array rendering errors and English720p list
height. Final fixes do not relabel those failed runs as passing. Generic
`has_resume()` was also found unsuitable for first-NOT introduction: temporary
Prediction has no persistent resume yet still has its own destination.

Three workers independently cross-reviewed another scope. They did not run
Godot or Git. Review established source-level constraints; executed controller
tests and actual rendering are recorded separately. Current Mac native,
unfamiliar-player comprehension and final artistic approval remain unverified.
