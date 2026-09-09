# Chapter 3 development verification — 2026-09-09

This earlier checkpoint is superseded for native-play status by the
[subsequent six-level player pass](../2026-09-09-overlap-native/README.md).

**Not release acceptance. Chapter 3 ordinary Game computer-use play is blocked by
macOS lock screen.** The computer-use tool twice reported that the Mac was locked
and automatic unlock failed. User unlock was requested. No chapter-three node is
claimed as manually played or completed in this checkpoint.

## Completed evidence

Godot 4.7.1 stable (a13da4feb), Apple M2 / OpenGL 4.1 Metal 90.5, isolated copies.

- `20260909T105942Z-5d39b71d`: all 19 suites, import and isolated directory checks
  passed; Chinese ordinary original-Game input regression 593 checks / 0 failures.
- `20260909T110333Z-3ea08921`: all 19 suites, import and isolated directory checks
  passed; English ordinary original-Game input regression 593 / 0. This run includes
  the chapter bridge, completion feedback, and one-shot palette drag / editor-focus fixes.
- Actual scene tests cover all six nodes, reference schedules, alternative Cache
  synthesis, deletion/undo after completion, separate hint boards, immutable trace
  seeking, bounded windows, and current global-save JSON round-trip.
- Corrupted root solutions invalidate dependent unlocks while preserving drafts.
  New Game preserves drafts unless workbench clearing was explicitly selected.
- Determinism checks compare whole trace signatures. Measured serial/double-buffer
  fixture: 40 / 28; variable tasks 28 / 29; bounded prefetch 28; distance 30 versus
  the over-eager starter 56; synthesis 28 / 33 for both buffer and Cache routes.
- **Test-mode render checks** at 1600×900 exercised Chinese/English hub, map, mission,
  program, timeline, H3 and completion. Fixed oversized floating panels, duplicate
  status glyphs, blank palette previews, unclear port side alignment, and title wrapping.
  These scripted captures do not replace mouse play. The dev build label changed
  after the structural checks; source version is `exploration-overlap-20260909-dev`.

The two optional electrical applications were actually built through computer use
before the lock, passed their official cases, and survived a normal quit/restart;
see [that separate player record](../2026-09-09-exploration/README.md).

## Still required after unlocking the Mac

1. Restart a fresh isolated copy from ordinary Game with the earned original QA
   prerequisites; no Test toggles or fabricated completions.
2. Play arrival, buffers, backpressure, prefetch, distance and synthesis. Build the
   empty interiors through the palette and wires; edit the program through its UI.
3. Inspect both failure and success explanations, H1/H2/H3 spoiler confirmations,
   all public tasks, useful alternative designs and progressive handbook diagrams.
4. Test Retina/windowed readability, drag-outside cancel, focus loss, text versus
   graph Command-Z, deletion, reverse connections and state/data width mismatches.
5. Normal quit/restart: recovered drafts must be editable, all earned chapter-three
   completions revalidated and the original 9+5+7 route retained. Iterate on findings.

Windows, actual beginner difficulty, sustained fun and balance remain unverified.

[Chinese map (Test)](map-test-zh.png) · [Actual bad-prefetch trace (Test)](prefetch-test-zh.png)
· [Independent H3 (Test)](hint-test-en.png) · [Completion (Test)](completion-test-zh.png)
