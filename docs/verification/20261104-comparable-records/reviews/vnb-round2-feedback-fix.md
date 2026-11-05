# Ordinary feedback popup refit — implementation handoff

Date: 2026-11-04. Owner `/root/audit_polish`; both assigned files now released to root.

Changed only:
- `src/playtest/playtest_moments.gd`
- `tests/test_journey_journal.gd`

## Runtime repair

The existing deferred `panel.minimum_size_changed` handler now also refits visible
non-terminal panels. Terminal pages still use exactly their viewport size. A
non-terminal feedback panel uses the existing desired width (at most 960, with
48px horizontal clearance) and its current combined minimum height. This removes
the stale pre-wrap height after labels settle, without changing the popup's
viewport, focus routing, margins, content scroll budget or terminal layout.

This is grounded in root's diagnostic run: actual popup650x480, panel at24,12 with
size602x3112, but settled minimum588x467. The correct467px height fits the remaining
468px. No larger layout rewrite or host-window enlargement was needed.

## Tests retained and strengthened

- Existing popup bounds assertion remains; its failure now prints actual popup,
  panel and minimum geometry.
- Ordinary feedback is checked in both zh_CN and en, with existing focus/Tab/Escape
  and no-offline-incident checks in each.
- Added assertions that the existing scroll area fits inside the popup and the
  opinion input is visible before scrolling.
- Optional `--journal-feedback-capture` saves raw popup frames to the QA copy's
  `.godot/feedback-popup-zh_CN.png` and `.godot/feedback-popup-en.png`, checks each
  `save_png()` result, and prints absolute artifact paths.

Use existing `--capture-size=1440x900` alongside the optional frame flag on the GPU
command. This isolates WindowMode geometry persistence through its existing
capture-mode guard; the journal's strict disk-inventory assertion is unchanged.
No WindowMode or persistence code was edited.

## Verification boundary

Fresh `git diff --check`: PASS. Full two-file diff and status inspected. No Godot
runs or Git mutations by this agent; root owns verification. Suggested focused
checks: headless `test_journey_journal`, `test_feedback_presentation`, relevant
terminal feedback/routing tests, then actual GPU `test_journey_journal` with the
capture arguments above and a fresh QA profile. Preserve the original failure
and diagnostic logs alongside the new result.
