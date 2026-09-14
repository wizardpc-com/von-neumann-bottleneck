# Compact task desktop — 2026-09-14

Five regions/40 tasks and all simulation, editing, saving and Hint rules unchanged.

## Observed issue and correction

- Native ordinary Game in `compact-desktop-20260914`: entered Tutorial through the
  task tree. Mission moved horizontally by 130 screen pixels, but its initial
  almost-full-height layout left little vertical movement. The issue was constrained
  space rather than an entirely missing drag handler.
- Hardware header now shows the current task once; repeated chapter subtitle remains
  available on hover and on chapter entry. Header/toolbar padding is reduced without
  reducing body text size or removing editing/playback controls.
- Initial Mission uses 78% of available height (420–620 logical bounds), retaining
  fixed Previous/Next/Start actions and scrolling content. At 1600×1000 layout,
  the canvas begins at y=223, with 708 height; Mission is 552 high, leaving 156
  logical pixels for vertical travel. Both languages produce these bounds.
- Shared floating instruments capture ongoing drag/resize outside title/grip bounds
  in parent coordinates, cancel on release/right-click/Escape, hide and focus loss.
  Title text no longer competes for pointer input. No persistent-format change.

## Fresh checks

- `.godot/verification/20260914T021311Z-6008b066`: baseline desktop suite passes.
- `.godot/verification/20260914T021656Z-c4f95547`: hardware and typography checks,
  English ordinary Game replay pass. New desktop test initially failed at early
  autoload compilation due to a static test type; this is retained as failed evidence.
- `.godot/verification/20260914T021750Z-0460083c`: corrected desktop suite passes,
  including viewport-dispatched title drag through a 0.75-scaled parent, motion
  without button mask, release outside title, focus loss and bilingual Mission bounds.
- `.godot/verification/20260914T022601Z-562aa557`: all 39 conventional suites pass;
  Chinese ordinary Game tutorial replay passes, 219 checks / 0 failures.
- Current bilingual CPU, double-buffer and compact-Mission scenes directly rendered
  and visually inspected separately from tests. Buffer run: 28 total cycles, 12
  overlap cycles, expected output 46. CPU restored the earned QA workbench rather
  than loading a Hint/reference answer; no new completed result is claimed for it.

## Native boundary

Final source launched. CUA mouse access then failed with `noWindowsAvailable`;
keyboard fullscreen-to-window switching remained observable. A separate ad-hoc
signed QA app also hit ScreenCaptureKit -3811. Its failed call lasted several
minutes; no native pass is inferred. All such copies use isolated userdata; the
user's Godot editor and pre-existing project settings/UID changes were preserved.
Final Mac physical dragging, Windows and long-session DPI/focus remain pending.
Automated viewport input and direct screenshots do not replace native acceptance.
