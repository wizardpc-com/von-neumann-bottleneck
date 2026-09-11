# Task tree clarity and input follow-up

Baseline d49924c; scoped visual/input repairs, no text rewrite, new task, unlock,
simulation or save change. Existing user downloads and player data are preserved.

Native source baseline: the detail text sat directly against the clipped map edge,
with no containing surface or padding; title/type/body/status had nearly the same
weight, and the Enter action looked like the secondary records/feedback actions.

Changes: a shared instrument card, 18-point gap from map, padded title/type, scrolling task body, status and fixed actions. Region accent follows selection, available
Enter is primary and locked Enter stays disabled. Hover border/cursor identifies
clickable nodes without animation. Drag cancels on focus/window-mode change and
when motion arrives without a held mouse button, avoiding a stuck camera after
release outside the canvas. All navigation and domain gates remain authoritative.

References (design interpretation, not copied artwork):
- https://turingcomplete.game/ describes progression from logic gates through
  components to architecture; retain the real prerequisite graph and inspectable tasks.
- https://www.zachtronics.com/opus-magnum/ describes open-ended machine solutions;
  preserve the free workbench and existing completion rules while improving navigation.

Verification: isolated conventional suites and ordinary Game replay, bilingual
40-task card bounds at the real 1280×720 viewport, retained ordinary pan, hover and
cancellation. Native after-change and candidate receipts follow below. Windows,
external beginners and long mixed-DPI sessions remain separate acceptance gates.

## Final source evidence

All conventional suites and the 602-check Chinese ordinary Game input replay pass
in `20260911T173750Z-2b1104f4`. Final targeted map and bilingual presentation tests
also pass after the subsequent native finding described below. Each of 40 tasks
is checked in both languages at 1280×720; extension/DAG and unlock tests remain intact.

Native source Game, Mac M2: entered tree by mouse; inspected Tutorial and locked
Half Adder, hover/selected outlines and disabled Enter. F11 switched to windowed,
then mouse selected Tutorial and entered its ordinary Mission/Parts/Test Bench.
No new progress fixture or reference solution was loaded.

English Continue then exposed a real centering defect: container layout resized the
map after its initial locate, leaving the selected task at the lower edge. The
canvas now preserves its world center across size changes. Added assertions check
actual centered-node coordinates after bilingual initial layout and resize. Final
English native Continue centered Tutorial; F11 kept it centered. Final status sits
under the prerequisite list to preserve the existing wording about tasks above.
Normal exits and logs are clean. These are source-native observations; the older
exported-package CUA mouse limitation, Windows, external beginners and long sessions
are not marked passed. No narrative copy or simulation changes.
