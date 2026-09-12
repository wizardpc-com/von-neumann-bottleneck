# Bilingual voice and scalable text — COMPLETED

Goal: review Chinese copy/layout and adapt English titles, intros and transitions
with natural English idiom, matching the Chinese editorial intent rather than its
literal wording. Improve legibility after zoom/pan/resize without changing gameplay.

Scope: PO catalogs, matching title arrays, hub cards, task-tree drawn labels, shared
font use, targeted geometry tests and native/rendered review. Preserve all numerical
specifications, DSL/port identifiers, Hint levels, deterministic simulation, saves,
40 tasks and dependency gates. No new dependencies, chapter or public distribution.

Steps: inspect source and prior 82-row audit; record bilingual editorial deltas;
separate screen-space map labels from world-space shapes; verify text measurement,
minimum-size cards and fixed detail panel at zoom/pan/resize; run full isolated suites
and ordinary Game replay in English, then native bilingual review; commit, export
candidate and keep platform/novice limitations explicit.

English title direction: A Machine Takes Shape / Where Time Goes / Less to Carry /
In the Meantime / A Place for Everything. Familiar idiom and mild imagery; technical
subtitles carry precise subject matter. Chinese remains mostly as just approved;
only specific awkwardness or missing meaning is corrected.

Evidence: Godot font docs distinguish raster font scaling from rendering at the
intended size; use screen-space font sizes for task-tree labels instead of changing
the whole font importer to MSDF. Keep existing bundled font and canvas_items stretch.
https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html
https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/

Progress: baseline 945df21, user-supplied untracked plan files preserved. Current
map compact fonts can shrink below a useful screen size. English intro still contains
old no-software-optimization scope and tutorial summary still uses obsolete red/green
signal meaning; correct these to match actual Chinese/model facts.

Source work complete: 137 English catalog edits, one Chinese title correction,
screen-space map text, meaningful short-title fallback and responsive hub.
Final full isolated suites and English ordinary Game pass; Chinese replay and
final bilingual rendering pass with exact revision boundaries in the evidence.
Native homepage/locale/fullscreen/zoom/selection inspected. Native pan remains an
explicit tool/acceptance gap. Candidate free-alpha-7a18f039dc20 frozen; identity/file hashes and actual Mac
release-binary boundary passed. Artifact pointers updated. Windows/native pan,
exported mouse, external readers and mixed DPI remain explicit acceptance gaps.
