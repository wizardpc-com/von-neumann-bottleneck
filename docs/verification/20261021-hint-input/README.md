# Hint input correction — 2026-10-21

Base: `276a5950e972a6ab7c6b232c3487ac98cfe71c2f`, branch
`codex/navigation-closeout-20261020`. Godot `4.7.1.stable.official.a13da4feb`, Windows.

## Behavior

- F1 shares the Hint button action, including while Component Search has focus
  and while reading the hint canvas. Tiers 2 and 3 retain separate confirmation;
  key repeat and the final disabled tier cannot advance hints.
- Floating instruments use bounded stacking beneath help/dialog overlays. The
  help card stays above instruments in both drawing and pointer order, including
  after reopening. Previously, repeated instrument focus could conceal it or
  intercept clicks, despite the card's visible flag being true.
- Settings, naming, Handbook, completion and sealing retain ownership of their
  interaction. Opening hints does not edit the player's circuit.

## Verification

The same final `test_hint_input.gd` against the base runtime reproduces 14 failed
assertions out of 36 (`baseline.txt`). Input uses synthetic viewport pointer/key
events, with an explicit instrument-over-help layout fixture. The hardware UI
regression checks that dragging a panel brings it above its peers, rather than
requiring its numeric z-index to grow forever.

Final isolated headless regression: see `results.json`. Rendered bilingual input
checks and inspected 1280×720 overlap screenshots: see `rendered.txt` and the
two `*-help-over-instrument.png` files. Source hashes and exact evidence paths
are recorded in `source_identity.json`.

## F11 report: not reproduced

The user reported a transient window pinned at the screen's upper-left after
exiting fullscreen, corrected by resizing and subsequently unreproducible even
after removing AppData. No root cause is confirmed and `window_mode.gd` is
unchanged.

An isolated fresh-data Windows run tested the initial fullscreen exit and six
F11 round trips in the real rendered window. All settled window rectangles fit
the usable screen; the first exit immediately reported 1600×900 at (3680,594)
on the tested 3840×2160 secondary screen, with matching native/engine geometry.
See `window-restore.json`, `window-restore.txt` and the preserved QA probe. This
does not rule out a timing/display/driver-specific issue on another machine.

No player saves were altered. Physical keyboard/mouse, classmate computers and
an updated exported ZIP were not tested or delivered in this source correction.
