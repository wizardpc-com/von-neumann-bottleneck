# Bus transfer illustration and desktop input — Mac, 2026-09-09

Baseline: 98cde8b. Godot 4.7.1.stable.official.a13da4feb, Apple M2,
OpenGL 4.1 Metal 90.5. This continues the existing 9+5+7 Game route.

## What changed and why

The old Bus drawing always showed four decorative lines. Eight visible bit cells
now group by selected bandwidth: Bus2 has four groups, Bus8 one. Idle captions
explain capacity without pretending to show live data. Actual read/write events
supply the decimal value, binary cells, bandwidth and group count; their existing
playback progress highlights the current illustrative group. Requests remain
separate. This does not define a physical bit-order protocol or change timing.

Native play also exposed four defects repaired in this increment:

- Paused/stepped overlays detached after zoom or device movement. They now redraw
  the same displayed event/progress on geometry changes.
- Write payload highlighted the request route because device-pair lookup selected
  its first matching edge. Geometry and player color now use the typed data route.
- Changing hardware retained old green results and a stale playback caption;
  running again retained an obsolete header warning. Current evidence now clears
  on change and refreshes on rerun. History comparison receipts remain available.
- Parts rendered above Test Bench while the latter intercepted clicks. All three
  desktop hosts now synchronize sibling input order with visual focus order.

The [Turing Complete developer description](https://store.steampowered.com/app/1444480/Turing_Complete?l=english)
informs the emphasis on discovering behavior through construction and observation.
This is our design inference, not adoption of its tri-state bus model.
[Godot documents](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-property-z-index)
that drawing z-index does not determine Control input order.

## Native player evidence

Ordinary Game was launched from the hub using a separate copy of our earlier
manually completed QA save, under `VonNeumannBottleneckChecks/bus-diagram-20260909`.
No actual user saves were read or changed, no Test mode/reference loader/progress
setter was used for this player pass. The read-only QA observer saves viewport
images and reports Game counts 9/5/7. The old displayed build label is historical;
use the source hash manifest for the tested runtime identity.

Computer use selected Chapter 1, entered the original bus-width investigation,
made the four-to-one prediction and ran the baseline. Bus2 passed at 144 cycles;
paused single steps displayed write value 3 as `00 00 00 11`, group 4/4, on the
amber write route. Retina windowed zoom, device drag, Command-Z and
Command-Shift-Z kept the highlighted route attached to the displayed ports.
With Test Bench still visible behind Parts, the Bus dropdown opened and accepted
Bus8 directly. Closing Parts left Test Bench open. The eight cells became one
group, old result rows cleared, and a fresh official run passed at 96 cycles.
History retained 144→96 total cycles and 64→16 data-transfer cycles.

- [Overlapping Parts dropdown receiving input](overlapping-parts.png).
- [Bus2 write, paused zoom/move/redo](bus2-write-final.png).
- [Bus8 write value 3 in one group](bus8-write-final.png).
- [Original controlled comparison](bus-comparison.png).
- [Bus8 read value 5](bus8-read-final.png), [final hardware-change status](bus8-idle-final.png).
- [English Bus2 read layout](bus2-read-en-fixture.png) is a visibly labeled Test
  fixture inspected with computer use, separate from the ordinary Game playthrough.
- `bus2-write.png` is an early reproduction frame before the typed write-route fix.
  `bus8-idle.png` predates the final one-line stale playback-caption correction.
  They are diagnostic evidence, not final acceptance screenshots.

## Verification and limits

Automated and final native recheck details are recorded below. Earlier runs remain
under `.godot/verification`; one initial restricted import could not write Godot's
editor settings, and the first overlap test used screen coordinates for a scaled
viewport. Its corrected `push_input(..., true)` dispatches viewport coordinates
and checks which actual close button receives input, rather than asserting tree
order. Those failed attempts are not represented as passing runs.

The broader full-campaign native pass belongs to the previous iteration. This
increment's new native player evidence is the Chapter 1 bus comparison and desktop
interaction. No level content/order, hints, simulation, receipts or save formats
changed. Windows, physical trackpad behavior and first-time human beginner
acceptance remain unverified; automated replay is not release acceptance.

### Final verification record

Final run `.godot/verification/20260909T030131Z-3ee57359`: import and user-directory
probe pass, all **21 suites pass**, English ordinary Game input replay **593/0**.
[Results](automated-results.json), [focused UI suite](test_system_lab_ui.txt),
[English replay](game_gui_en.txt). Chinese input replay was also **593/0** on the
same changes before the final one-line playback-caption correction;
[its log](game_gui_zh_CN-before-caption.txt) is labeled accordingly. Both replay logs
include a native macOS IMK messaging diagnostic, without a failed assertion.

[105 runtime source hashes](verified-source-hashes.json) match checkout, final
isolated verification and native QA project. Final ordinary Game restart repeated
the Bus2 baseline, overlapping Parts selection, Bus8 idle status clearing, Bus8
96-cycle rerun, amber write value 3 and green read value 5. The final idle screenshot
shows the rerun notice in the bottom caption as well as the test/header areas.
Normal Command-Q exited 0. [Window-fix native log](native-window-recheck.txt) and
[final native log](native-final.txt) contain no engine/script errors and report
ordinary Game with retained 9/5/7 counts. No further runtime edits followed.
