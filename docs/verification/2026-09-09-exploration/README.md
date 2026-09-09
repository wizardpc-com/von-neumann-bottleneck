# Exploration checkpoint — 2026-09-09

Godot 4.7.1 stable, native Mac M2, ordinary Game entry, isolated QA user directory
`VonNeumannBottleneckChecks/exploration-20260909`. Existing player-earned QA progress
was copied from the earlier Bus play session; new branch completions were earned here.

- Hub has only the original campaign entries; the retired eight-task entry is gone.
- Optional map branches are legible in the 1204×768 window; original prerequisites remain.
- Selector: dragged AND and two XOR gates from the searchable palette, freely wired
  the alternate three-gate implementation, passed all eight official combinations.
- Delay: dragged two earned Register4 tools, wired data and ACCEPT separately,
  exercised Command-Z / Shift-Command-Z, passed all twelve stateful official steps.
- Normal quit/restart retained both optional completions, the original 9+5+7 progress,
  and the two-register player circuit. Runtime registers correctly restart at zero.
- Player findings fixed: short goal strips now state required behavior; task specifications
  link the handbook; ACCEPT no longer displays HOLD; optional completion no longer locks
  editing or claims a new packaged chip. The final two fixes have focused checks;
  completion editing will be revisited during the final expansion player pass.

Isolated run `20260909T101234Z-2b151d05`: all 16 non-localization suites and
Chinese ordinary Game input 593/0 passed. Localization initially caught missing
handbook links; after correction it passed in the same isolated project. Focused
exploration test passed again after the native findings. These checks are development
evidence, not Windows or first-time-human acceptance.

Screenshots: [completion](delay-complete.png), [restored board](delay-restored.png).
