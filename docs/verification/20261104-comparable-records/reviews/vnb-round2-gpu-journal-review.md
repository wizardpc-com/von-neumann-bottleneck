# GPU journal failure diagnosis — 2026-11-04

Reviewer: `/root/audit_polish`. Read-only investigation only; no runtime/test edits,
no Godot execution, no Git mutation. Evidence is the supplied isolated GPU run and
current source. Confirmed these source files are byte-identical to the GPU copy:
`tests/test_journey_journal.gd`, `src/playtest/playtest_moments.gd`,
`src/ui/window_mode.gd`, `src/lab/lab_terminal_pages.gd`,
`src/ui/theme_reflection.gd`.

## 1. presentation.cfg inventory failure: test isolation, not journal persistence

Evidence:

- `.godot/verification/20261104T201610Z-e2107e1b/gpu_journey_journal.txt`
  reports exactly one changed inventory entry, `presentation.cfg`, absent ->
  SHA256 `b9149c226c1e6142ced388947878597c7ca34b8f47e2eb79e39669e5f755d050`.
- Read only the explicitly named QA profile:
  `/Users/yrq/Library/Application Support/VonNeumannBottleneckChecks/20261104-round2/gpu_journey_journal-final1/presentation.cfg`.
  Its content is solely:
  ```ini
  [window]
  fullscreen=true
  size=Vector2i(1600, 900)
  position=Vector2i(0, 0)
  ```
  No locale, player progress, archive, score, lease or migration field is present.
- `window_mode.gd:303–322` runs `_save_window_geometry()` every two seconds.
  It returns early in headless mode or when user arguments contain `--capture*`,
  but otherwise creates the file when `_saved_geometry` is initially empty.
- The GPU command in `gpu-results.json` is simply `Godot --path <QA copy>
  --script res://tests/test_journey_journal.gd`; it supplies no capture argument.
- `test_journey_journal.gd:140` takes the before-inventory and subsequently changes
  viewport size/content scale in two locales and three dimensions (`141–145`).
  The comparison at `205` includes the unrelated, always-processing WindowMode
  service. Its first periodic geometry save can naturally occur inside this span.

Smallest suggested repair: isolate the geometry writer in this test, not the
journal. At the beginning of the fixture, remember `WindowMode.is_processing()`
and disable only its periodic `_process` while testing read-only inventory;
restore it after the final inventory checks. This leaves every protected file in
the inventory and does not weaken the assertion by ignoring `presentation.cfg`.
An alternative is to run this GPU suite with the existing deterministic capture
argument, which already suppresses window geometry persistence; if chosen,
record that invocation explicitly. Do not change production geometry persistence
or add a blanket settings-file exclusion merely to make this assertion green.

Note: `_exit_tree()` also saves geometry, after these assertions. The test should
make no claim that unrelated presentation preferences are never written at
application shutdown.

## 2. Ordinary feedback outside popup: actionable layout defect, not established timing noise

Evidence:

- All preceding assertions succeed: ThemeReflection owns focus, ordinary F8 opens
  PlaytestMoments, the panel belongs to that popup's viewport, and keyboard
  focus/Tab/Escape are operable. The failing assertion is its actual outer bounds
  (`test_journey_journal.gd:291–299`). This is therefore not the wrong-window
  routing or input-stack regression.
- ThemeReflection is opened at `650 × 480` (`journey_journal.gd:480`). Actual
  isolated screenshot context metadata confirms that size for three popup
  captures in this GPU run, including QA case
  `082abc527c1fe99db9dab1883d3b2070`. These are real captured viewport dimensions,
  not inferred from the desired popup size.
- `playtest_moments.gd:371–374` places a non-terminal popup panel at `(24,12)`,
  sets its desired width to `viewport.x - 48` (602 here), and assigns height zero
  so Container minimums determine the final height.
- Content has fixed minimums (`panel` width 560; scroll width 500; status height
  32), a header styled to height 44, wrapped privacy/status text outside the scroll,
  and the full-page `fit_page_margin()` applied unconditionally at line 70.
  That helper adds 32 px horizontal and 30 px vertical margins even inside this
  small native popup (`lab_terminal_pages.gd:104–110`). Panel style adds another
  12 px horizontal and 8 px vertical per side (`instrument_theme.gd:96–99`).
- `_fit_feedback_layout()` only reserves a constant 220 px for all this chrome
  (`playtest_moments.gd:321`). It does not measure actual wrapped privacy/status
  height or subtract the panel's top/bottom gap.
- Container changes can also temporarily enlarge a panel while its width settles.
  The source acknowledges this at `285–289`, but its deferred size reset applies
  **only** to `terminal_page`; ordinary popup panels receive no equivalent reset
  after minimum-size changes. Thus even a later smaller minimum can leave a
  previously enlarged non-terminal panel out of bounds.
- `full_input_key()` already waits six frames for each key edge (12 frames for
  F8), and `UiMotion.reveal()` disables animation under `--script`. Arbitrarily
  increasing the settle time is not a justified correction.

What the evidence does not establish: the log does not print the panel rectangle
or combined minimum size, so it does not identify the overflowing axis or distinguish
an excessive stable minimum from a stale enlarged size. Do not claim an exact
number of clipped pixels without the next measured run.

Smallest suggested repair:

1. Keep the existing bounds assertion. Include actual popup visible rect, panel
   global rect, panel combined minimum, scroll combined minimum and margin values
   in its diagnostic text (and optionally capture the ordinary feedback frame).
2. In PlaytestMoments only, fit non-terminal panels using the actual remaining
   viewport rectangle. Set width before budgeting height; reserve the measured
   header/privacy/status/margins, and allocate the remainder to the existing scroll.
   Reapply the fit after deferred minimum-size changes, with a re-entry guard.
   Keep the full-screen terminal branch's current layout intact. Do not enlarge
   every ThemeReflection popup or weaken the test to check focus alone.
3. If the next measurements show only stale enlargement, a bounded deferred
   non-terminal refit is enough. If the combined minimum itself exceeds available
   height, replace the fixed `-220` calculation with the measured chrome budget
   and use compact margins for the popup context. Existing scrolling should carry
   the overflow; no new page or feedback architecture is needed.

Verification recommendation: rerun this exact GPU suite in a fresh QA profile
with geometry persistence explicitly isolated, and cover ordinary feedback in
both zh_CN and en at the actual 650×480 ThemeReflection viewport. Assert panel
bounds after layout, first actionable input visibility, Tab/Escape and exact focus
restoration. Run existing `test_feedback_presentation` and terminal feedback
routing checks so the popup correction does not regress the 1280×720 terminal.
Keep original failing logs; report these as one isolation fix and one popup-layout
fix if fresh measurements confirm the proposed runtime branch.
