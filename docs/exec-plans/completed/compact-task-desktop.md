# Compact task desktop and representative README gallery — complete local scope

2026-09-14. Preserve five regions, 40 tasks, simulation, editing, saved works and
independent Hint rules. No new mechanics or public release.

Native baseline: Tutorial top chrome fills about a quarter of the window. Mission
can move horizontally but its initial height almost fills the desktop, leaving
virtually no vertical travel. Shared floating panels also lack focus-loss gesture
cancellation. Fix presentation and input capture, not level progression.

Scope: hardware header/toolbar/briefing sizing; shared FloatingInstrumentPanel;
focused desktop regression, native bilingual drag/resize, current runtime gallery
and bilingual READMEs. Preserve pre-existing project.godot ordering and untracked UIDs.

Steps: compact duplicate chapter headings; leave room around Mission; capture drag
in parent coordinates and cancel on release/Escape/focus loss; verify isolated UI
and ordinary Game interactions; capture actual earned QA runs for interesting
levels, document provenance, commit/push reviewable stages. Exported-candidate and
Windows native acceptance remain separate.

## Result

Runtime committed as `4450c78`. All 39 suites and ordinary Chinese/English Tutorial
replays pass; bilingual direct renders inspected and README provenance recorded.
Native baseline reproduced horizontal movement but constrained vertical room; final
mouse recheck blocked by CUA noWindowsAvailable/ScreenCaptureKit -3811, explicitly
retained in verification record. No new frozen package or public release.
