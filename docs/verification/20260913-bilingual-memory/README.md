# Bilingual text and movable-window follow-up — 2026-09-13

Baseline: `08c245a`. This is a presentation/copy follow-up, not a new candidate or
whole-game acceptance. The existing adapted English chapter-title system remains;
this pass targets concrete ambiguity and overflow in the layout chapter and shared
window chrome. Five regions, 40 tasks, mappings, costs, Hint rules and saves remain.

## Changes and editorial decisions

- Memory cells used to concatenate field and record (`Battery10`). They now show
  the field, original record number (`#10`) and value on separate lines. Field
  colors retain their meanings, with textual identity as well as color.
- Wrapped captions and legends follow actual font height after a resize. Row width
  follows the window while retaining four 4 B cells per 16 B row. Narrower windows
  scroll the grid instead of shrinking its lettering; record numbers use 16 px.
- Memory tooltips now follow the selected language and identify source record,
  value and byte address. Padding/gutters produce no fabricated record. Tail batches
  use the source record offset, not the batch-local array index.
- Shorter Layout tools / 布局工具 titles avoid redundant explanation in the header.
  Shared long instrument titles ellipsize and expose their full tooltip while
  leaving close/minimize controls accessible. The header still receives drag input.
- English task instructions replace “public workloads”, “starts cold” and “choosing
  neighbors” with direct test-case, empty-cache and field-arrangement language.
  Chinese also clarifies that query results match computation from the original
  data; it does not require a sum to equal a source record. Its two rules occupy
  separate lines to avoid a stranded final character at the inspected width.
- New measurement text keeps numbers and units together with nonbreaking spaces.
  Seven small semantic keys replace the affected inline wording. Existing catalogs,
  technical terms, placeholders and model values are preserved. Chapter 3 heading
  punctuation and English chapter-entry button capitalization now match adjacent cards.

## Actual native observations

Godot 4.7.1 on this Mac, ordinary Game entry. QA profile `spatial-deep-20260913`
was copied from the historically earned `five-chapter-20260910` profile, without
setting completion flags. All 18 source QA files remain byte-identical
([hash check](save-isolation.json)); actual player data was not used.

Chinese and English hub → Chapter 4 → task explanation → arrange → run all cases
were operated through computer use. The saved non-reference field grouping still
passes case A at 49 cycles / 32 B read and case B at 73 cycles / 48 B read, before
and after this change. English native review checked scrolling to the retained
source records and collected temperatures, selecting a cell and switching from
fullscreen to windowed mode. It found the small record index and wrapped `16 B`,
which prompted the final 16 px / nonbreaking-space adjustment. Final Chinese native
review confirmed the shortened tools title, separate field/index/value and the same
49/73-cycle result. The last Chinese two-sentence line break and chapter punctuation
were checked in the final rendered captures after native play.

This is an existing-design text/UI review, not a new native solve of all six tasks.
The screenshots in this directory are Godot render fixtures, not computer-use
screenshots. The mission fixture explicitly uses Test mode for deterministic capture;
it is not counted as earned Game progress.

## Fresh verification and failed intermediates

- `20260912T164101Z-b13f666a`: English ordinary Game Tutorial 212 checks / 0 failures.
  The new typography test initially preloaded autoload-dependent scripts too early;
  changed it to load after the SceneTree starts. All other conventional suites passed.
- `20260912T164651Z-ed7381ce`: 33 other conventional scripts passed, plus Chinese
  ordinary Game Tutorial 212 checks / 0 failures. The longer caption fixture then
  caught a real overlap while wrapped font height settled. This original failure
  remains in [full results](full-run-results.json) and [failure log](long-caption-failure.txt).
- Fixed caption/legend minimum-size notifications. Final typography render test and
  six-host layout UI suite both passed: [follow-up](layout-followup-results.json).
  Final translation import, localization assertions, typography and bilingual task
  renders also passed: [final copy checks](final-copy-results.json).
- Typography checks cover both languages at 1280×720 / 1600×900, 40 map labels over
  eight zoom levels with fractional pan, 510/700-wide memory views, long captions,
  double-digit IDs, tail batches, padding hit tests and 280-wide instrument headers.
  Source address maps stay byte-equivalent during presentation checks.
- Existing layout simulation and locale-independent simulation checks passed. Mac
  emitted the known non-fatal IMKCFRunLoopWakeUpReliable message during Game replay.
  `git diff --check` is clean.

Windows mixed DPI, exported-package mouse input, long focus sessions and external
Chinese/English readers remain pending. Physical map pan is still not closed by
this text pass; well-formed replay events and rendered pan geometry are distinct
from the earlier computer-use motion limitation. Frozen artifacts remain
`free-alpha-7a18f039dc20`; no archive was replaced or publicly released.
