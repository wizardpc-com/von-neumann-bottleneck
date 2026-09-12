# Desktop continuity and bilingual Mission layout — 2026-09-13

Baseline: `c573d1b`. Source presentation/navigation follow-up; no frozen package
replacement, simulated cost change, new task or new save format.

## Findings and changes

- Native CPU seven-step formal run passed using the historically earned, isolated
  `spatial-deep-20260913` profile. Returning from H1 reopened Components, expanded
  Mission and refitted the camera. Hint now captures/restores transient window
  visibility, geometry, stacking, compact state and graph camera. The ADR 0015
  history/clipboard reset remains unchanged; reference topology stays separate.
- Clicking Chapter 1 from the hub after a tree-entered CPU session redirected to
  the old tree selection. Explicit chapter cards now clear only the transient tree
  route. Last-visited navigation, progression and Continue retain their authority.
- Native RAM-wait formal tests passed 2/2: 134 cycles each, 268 total; Profiler showed
  compute 16, wait 252, RAM service 216 and 18 requests. A compute/wait proportion
  bar now presents those existing metrics. RAM service is not added to CPU wait.
  Existing diagnosis/tier gates apply, invalidated results hide the bar, and the
  tooltip distinguishes proportions from event order.
- Chapter 1 instruments now use quiet raised surfaces and a focused accent instead
  of equally bright full cyan perimeters. Text colors and readable type stay intact.
- Full English Game replay exposed a real initial Mission overflow: two-row section
  tabs plus explanatory text pushed Start building below the viewport. Page actions
  now sit between the section tabs and variable-height prose. No font reduction or
  information deletion was used. Minimum-window capture checks both languages.

## Verification and limits

Initial isolated full suite results and failures are retained, rather than rewritten
as passing. The Profiler check caught ProgressBar integer rounding; continuous
precision fixes the true ratio. A first targeted rerun reused test data and hit the
fresh-hub assertion; the final run uses a new test-only directory and passes.
Initial English complete replay: 632 checks, one failure (Mission action overflow).
Final test/native follow-up is recorded below after completion.

Earlier native operations are ordinary Game with earned saved designs, not freshly
solved circuits or Test-mode reference fixtures. Rendered replay screenshots are
separate evidence from OS mouse use. Windows mixed DPI, other-Mac installation,
external readers/new players and physical drag/focus stress remain unverified.
Frozen candidate remains `free-alpha-7a18f039dc20`; no public distribution.

### Final follow-up

- English full ordinary Game input: **633 checks, 0 failures**, including CPU/Hint
  and the first chapter entry; Chinese Tutorial: **218 checks, 0 failures**.
- All initially passing conventional suites retain their evidence. Final Hardware
  UI and prologue UI pass. The old assertion requiring page actions below the body
  was updated to the intentional above-body placement while preserving size/centering.
- Final rendered Chapter 1 suite passes in Chinese and English. It caught another
  actual long-text overflow: the finding-review action was below the Mission.
  That action now follows the title, and long Mission titles wrap.
- An English fullscreen header button was 117 px wide in a fixed 100 px allocation,
  reaching x=1601 in a 1600 px viewport. A right-anchored HBox now sizes the pair by
  their labels and expands left. Both fullscreen captions, both languages and both
  typography window sizes pass. No font reduction or clipped button label is used.
- Final shared UI, all-five-card routes, prelaunch settings and release-convergence
  checks pass. Profiler bands use no content padding, so their painted proportions
  follow the metric ratio rather than inheriting button/panel margins.
- The initial optional rendered-suite failures are retained above; they prompted
  the conclusion/header corrections. Final `last-checks` and `bar-final` logs show
  passing results. Render fixtures use generated official receipts (the captured
  final comparison totals 2352 cycles, compute 504, wait 1848); they are not the
  earlier native RAM-wait 268-cycle session.
- Final native launch was attempted but computer use explicitly reported **Mac
  locked**. The user was asked to unlock; corrected native mouse verification is
  still pending. The isolated game was stopped. No lock-screen bypass was attempted.
- A Chinese minimum-window crop concern was additionally checked with a short GUI
  geometry probe: visible virtual viewport 1600×900, stretch 0.8, rightmost hub
  button x=1454 width=120. No out-of-bounds control was reported in that probe.
  This geometry evidence does not substitute for physical mixed-DPI review.

The full cross-region spatial/native/candidate queue stays open in the active plan.
This is a reviewable desktop/typography checkpoint, not whole-game acceptance.
