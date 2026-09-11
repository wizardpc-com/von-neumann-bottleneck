# Release convergence evidence — 2026-09-11

Baseline main 773168f. Exact outcomes and frozen identity are appended after checks.
Initial import caught two unmigrated dynamic localization calls; corrected before
running suites. Failed import 20260911T105259Z-cfca30de is retained, not acceptance.

## Automated evidence

Source regression `20260911T110108Z-e6ed64b4`: all conventional suites pass,
including writer/legacy/Chapter 4 provenance, personal records, native UI model,
locale, metadata extension and navigation authority. [Results](regression-results.json).
Earlier full runs exposed duplicate per-button locale listeners in three host suites;
replacing them with one listener and weak button references fixed all three. Their
failed outputs remain in `.godot/verification/` and are not counted as acceptance.
Ordinary Game input replays in `20260911T105354Z-24266423` (Chinese) and
`20260911T105753Z-842f77cb` (English) each report 602 checks, zero failures.
These are automated input paths; final native checks are separate below.

## Native Game observations

Godot 4.7.1, Mac M2, native computer use, dedicated prior `community-native-20260911`
QA profile; actual player profile untouched. Its original schema-1 files were copied
into ignored local evidence before launch. Chinese startup restored Tutorial completion.
Continue opened the task tree with an available fallback. Selected the other branch,
SR Latch, entered its original Mission, and quit normally. English restart + Continue
located SR Latch, without completing it or changing unlocks. [Restart state](native-restart-summary.json)
shows schema 2 / minimum writer 2 and separate recent-task preference; automatic
backup exists. Dedicated automated fixtures prove byte-preserved legacy backup and
rejection of future writer, root fields, chapter data and fields within a chapter.

English record page showed 1/40, two stored workbenches and no community controls.
F11 changed to windowed mode; header, region filter and scrollable rows remained
readable. Repeated mouse attempts briefly lost the computer-use window surface after
external window changes; F11 restored operation. A final corner-shrink attempt was
interrupted by external input, so it is not a completed small-size drag acceptance.
Minimum 1280x720 setting is implemented and checked; Windows/mixed-DPI/long focus
stress and external beginners remain in RELEASE_BLOCKERS, not claimed passed.

## Completion-board refinement

Latest owner direction removes individual task rows from the personal board. Total,
main/side/bonus counts and five regional cards use the existing chapter artwork and
colors. Full regression after this change: `20260911T111205Z-1665736f`, all suites
pass ([results](board-regression-results.json)). Native Chinese inspection then
caught a total-count label wrapping vertically and squeezing the cards; disabling
wrap on that numeric label fixed it. A focused 1280/960-width test passes in both
locale settings ([log](board-final-test.log)). Final native English Game → task tree
→ personal board shows a single-line 1/40 and all five cards. F11 windowed and Escape
return to the unchanged tree both work. The above earlier per-task-row observation
is historical; the shipping page is now the completion board.

## Frozen candidate

Exact content commit, generated build identity and package checks are appended after
export. No public upload, DNS, server configuration, account or store action occurs.
