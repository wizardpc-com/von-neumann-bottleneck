# Bilingual copy and text after transforms — 2026-09-12

Baseline: `945df21`. User explicitly reopened English editing and requested further
Chinese review plus legibility after zoom, movement and window changes. The previous
Chinese import remains a historical receipt, including its then-English-unchanged rule.

## Editorial outcome

| Region | Chinese | English |
| --- | --- | --- |
| Prologue | 一线成机 | A Machine Takes Shape |
| Chapter 1 | 时间的去处 | Where Time Goes |
| Chapter 2 | 少走远路 | Less to Carry |
| Chapter 3 | 与等待并行 | In the Meantime |
| Chapter 4 | 各就其位 | A Place for Everything |

English uses familiar expressions (in the meantime, a place for everything, earn
their keep), not literal Chinese metaphors. Subtitles still name technical themes.
Applied 137 English catalog changes; Chinese changed one title, 早亦有时 → 过犹不及,
and its compact-map alias. Six Chapter 4 English task names and its header match
the new direction. Technical component names stay recognizable. Lower zoom uses
short functional names; complete task titles remain in the fixed details panel.

`copy-changes.json` records old/new text, key, category and baseline. `check_copy.py`
checks that no unrecorded catalog entry changed, keys are retained, and body-text
placeholders, term links and numeric tokens match. Literal JSON Unicode escapes
are rejected because Godot PO import does not interpret them as JSON does.

Semantic review:

- First-chapter mainline needs no program changes; its optional branch does.
- The first capstone comparison changes one factor; later choices can combine.
- Tutorial no longer describes 0/1 using obsolete red/green meanings.
- ALU summary says operations, covering logic as well as arithmetic.
- Alarm text names clear priority explicitly; parity retains the two-flip counterexample.
- Extra buffers cannot speed up a bandwidth-bound transfer engine: the conclusion
  remains about the engine, not an unconditional claim about whole-system speed.

Specifications, official Hint content, numeric targets, circuit/DSL identifiers,
model, progress, 40 tasks, saved designs and privacy consent are not changed.

## Typography and layout

Task-tree shapes still use world coordinates. Text is drawn separately at the final
screen font size with rounded baselines, avoiding raster text scaled down to only
a few pixels. Node labels use at least 14 logical pixels; normal node titles use at
least 16. At very wide overview (<0.34 zoom), nodes retain states and connections,
with readable regional headings; hover/select still gives a full title. This does
not promise every task title fits simultaneously at every zoom.

The fixed 1480-wide homepage overflowed at 1280. It now follows available width and
scrolls vertically when needed. Settings/Handbook controls stay outside the scroll.
Focus enters after wrapped minimum sizes settle, and a fresh hub starts at the top.
Chapter 3/4 page headers wrap; card body lines have additional spacing. English
headings use normal title case instead of long all-capital blocks.

Engineering rationale: [Godot font rendering documentation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)
explains raster scaling/oversampling. We retain the bundled font, canvas_items
stretch and importer, changing the custom map text draw path only. Readable size
and actual display review follow [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/).
No new font dependency or blanket MSDF change.

## Verification record

New `test_bilingual_typography.gd` checks both locales at 1280×720 / 1600×900,
40 task labels at 0.18, 0.33, 0.34, 0.45, 0.62, 0.85, 1 and 1.6 zoom, and fractional
pans. It checks fitted width, glyph bounds, minimum font size, integer baselines,
wrapped label heights and initial primary-entry visibility. Capture mode renders
the same layouts through Godot. The existing display-preference test now checks
horizontal fit and reaching all cards by scrolling, while retaining its preference
preservation assertions. It no longer requires a fixed 1480-wide non-scroll layout.

Initial tests/rendering found and corrected fixed-width overflow, premature focus
scrolling and two literal Unicode escape sequences in English subtitles. Failed
intermediate runs remain under ignored `.godot/verification/`; they are not counted
as successful acceptance. Final source, rendered, native and package evidence is
recorded below as completed.

### Actual Mac source interaction

Ordinary Game was launched using a dedicated QA user directory (real saves untouched).
Computer use verified English homepage starts at its primary entry, scrolling reaches
all five card actions and descriptions, entering the tree works, Overview changes
the view, and the fixed details remain readable during zoom. Switching English →
Chinese rebuilt the homepage without clipped titles; exiting fullscreen retained
wrapped cards and reachable controls. Native observation found normal-size English
labels truncating chapter prefixes before the identifying task words; the final
fix falls back to a meaningful short title whenever the full title does not fit (both locales).
An assertion now keeps Wiring identifiable at every labeled zoom.

A combined scroll/drag gesture did not establish a reliable pan result in the first
native attempt. Final corrected-map native follow-up is recorded separately below.
This is source-native review, not an exported-package mouse or external-player pass.

### Final automated evidence

- `20260912T144644Z-79761895`: final source (including short-name fallback),
  isolated import + user-dir check + all 34 test scripts + English ordinary Game: PASS.
  Game replay: 602 checks, zero failures. `english-game-results.json` and
  `english-game.txt` are the complete verifier results and replay log.
- `20260912T143653Z-1ef387c0`: Chinese ordinary Game: 602 checks, zero failures,
  with the same final catalogs and responsive hub, before the map short-name fallback.
  `chinese-game-results.json` / `chinese-game.txt` retain that exact boundary.
  The final fallback is checked for both locales by the final typography suite.
- `check_copy.py`: PASS for the exact recorded 137 English / one Chinese changes;
  no missing keys or changed protected placeholders, links or numeric tokens.
- macOS emitted `IMKCFRunLoopWakeUpReliable` during the English replay. It did not
  fail the run. This run does not certify Chinese IME composition or mixed-DPI input.

### Final corrected-map native follow-up

Computer use on the final source showed Wiring and Half adder at the normal map
zoom, not an ellipsis after Prologue. Wheel zoom changed the node size while labels
and the fixed detail panel remained readable. Selecting Half adder updated the
complete title, specification, prerequisite and locked state in that panel.
A second isolated drag attempt again produced no confirmable map translation;
native drag/pan acceptance remains open. Geometry and rendered captures include
fractional pan offsets, but cannot replace that physical interaction check.
All twelve `*-hub-*.png` / `*-map-*.png` files are final-source Godot renders.
Native observations above used computer use; those captures use the render test.

Pending: Windows real machine, another Mac/install/notarization, mixed DPI and long
focus sessions, exported-package mouse navigation, and external English/Chinese
readers. No claim of universal text clarity or beginner comprehension is made.

### Frozen local candidate

`free-alpha-7a18f039dc20`, content `7a18f039dc20f530576e55ac523caa68aa8d6107`.
Both platform ZIPs are under `build/free-alpha-7a18f039dc20/`.
`candidate-manifest.json` contains their exact hashes. Identity checker passed for
archive names, all packaged files and notes. `mac-package-result.json` records the
actual release binary probe: correct identity, Game-only mode, 40 tasks, empty remote
endpoint, upload off, excluded development files and isolated user directory.
The binary and PCK were not modified by that QA probe. This is not a release-binary
mouse or Windows-native acceptance. No public release or server deployment occurred.
