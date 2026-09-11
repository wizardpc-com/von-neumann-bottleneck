# Task-tree-first startup, 2026-09-11

Small presentation change on top of main 25134c4. The task tree is now the large
cyan primary action at the top, with a real prologue dependency preview. The five
existing chapter emblems, colors, descriptions, entry buttons and unlock checks
remain below. Continue/New Game move into the secondary right side. Build identity
moves to the footer. No progress, simulation or persistent format change.

Godot 4.7.1 isolated checks: test_display_preferences (both languages, all five
cards within bounds, primary keyboard focus and position above cards), test_ui
(existing menu and instruments) and test_localization pass. Diff whitespace clean.

Native computer use, ordinary Game in the existing dedicated community QA profile:
Chinese startup, Return directly opens the tree, Escape returns, F11 switches to
windowed mode; all five cards and footer remain visible. Final English startup
inspected. Native review caught low contrast on the focused cyan button; focused
and pressed text now use dark ink, confirmed in the final English frame. Preview
uses existing task dependencies and completion states without saving camera state.

These are source-run native observations, not a new packaged release or Windows
real-machine validation. Previous candidate ZIPs still contain content 6942a61.
