# Chapter 3 native player pass — 2026-09-09

Godot 4.7.1 stable `a13da4feb`, Apple M2, ordinary Game, Chinese with an English
follow-up. Source baseline `e5d7e25` plus the fixes committed with this record.
The isolated project is `.godot/mac-playtest/overlap-player-project`; player data
is `VonNeumannBottleneckChecks/overlap-20260909`. Original prerequisites came from
the earlier native QA save. No Chapter 3 completion was fabricated or loaded from
Test mode. All construction and program edits below used computer-use mouse and
keyboard actions. Clipboard calls reported timeouts although the text arrived;
the visible editor content was checked before running.

## Actual play

| Level | Player action and visible outcome |
| --- | --- |
| Request is not arrival | Starter failed on premature consume; added independent work and ready wait; completed in 10 cycles. |
| Two buffers | Placed A/B, connected their data, ready and free ports. Serial program took 40 cycles; alternating program passed at 28, with 12 overlap. |
| Backpressure | Fixed tick starter overwrote an in-use buffer on line 6 at cycle 8. State waits passed both public workloads. H1/H2/H3 were opened through their confirmation gates; returning retained the player's unsolved program. |
| Prefetch | Serial starter took 40; bounded look-ahead passed at 28. Miss count stayed at four while waiting fell: time, not hit count alone, explains the improvement. |
| Prefetch distance | Eager starter took 56, transferred for 32, evicted seven times and queued for 12. Bounded look-ahead passed at 30 and transferred for 16. |
| Synthesis | Built a Cache route from the toolbox and edited its program. Both public workloads passed using this alternative to the two-buffer reference. |

Normal Command-Q and Continue restored all six completed nodes. Reopening the
buffer level restored the actual A/B board and program; editing and rerunning
still passed at 28. The saved solution summary is in `native-save-evidence.json`.
The previous optional applications and original chapter progress remained present.

## Bugs found and fixed during play

- Failed runs drew future transfer bars beyond the timeline window. Clamp drawing
  to the actual stopping cycle and clip the control; retain issued-operation
  durations in the event list. Reproduced and rechecked the zero-cycle error.
- Error line advanced to the next instruction after a failure. Retain the actual
  offending line; checked line 3 in arrival and line 6 in backpressure.
- Palette dragging silently failed on captured Mac input. Use the release-event
  position, matching the existing circuit host. Native recheck: drag placement,
  one-shot release, Command-Z/redo and dropping outside the canvas without a later
  accidental placement.
- Card bodies were treated as empty marquee space. Opt third-chapter cards into
  full-card hit testing; leave procedural circuit-symbol hit tests unchanged.
  Delete and body selection were rechecked. Body movement also needs the captured
  event position rather than the missing mouse-button motion mask; native movement
  and one undo restored both the original position and connected cables.
- Hide the redundant built-in cable stroke, refresh port geometry after layout,
  and use cyan double data cables versus gold thin status wires, including normal
  and reverse drag previews. Both mismatch directions left topology unchanged.
- Clear stale live-state labels when editing. Localize hint confirmation buttons,
  brighten read-only code, and position hint diagrams after Godot's layout settles.
  Final English H2 was visibly clear of the toolbar; Chinese confirmation text and
  the Chinese/English illustrated handbook were inspected.

## Verification boundary

- Fresh isolated run `20260909T120041Z-d8a2b36f`: import, directory probe and all
  19 conventional suites pass. `checks.json` retains the full results.
- Later card-motion and hint-position changes passed the focused Chapter 3 UI
  suite again; see `overlap-ui-final.txt`. The simulator's complete metrics and
  determinism assertions passed. No simulation timing or success target changed.
  Final review also guarded held drags against shortcut/eraser mutations and
  premature autosave; these extra held-gesture guards have focused regression
  coverage rather than a separate native replay claim.
- Native Command-Z/Shift-Command-Z were checked separately in graph and CodeEdit.
  Fullscreen/window switching and approximately 1200-pixel-wide native window
  readability were checked on the Mac Retina display. This is not a full DPI matrix.
- **Application-switch cancellation is not accepted yet.** Command-Tab did not
  establish a reliable focus change; the Finder control attempt timed out with
  `cgWindowNotFound`. A later empty-canvas click placed a component, so that attempt
  is not positive evidence. The placement was undone. A reliable app-switch or
  physical-user follow-up is still needed. Do not claim this boundary passed.
- Windows and first-time human beginner difficulty/fun remain unverified. No
  release acceptance is inferred from the suite totals or this experienced pass.

## Player assessment

The clearest discoveries are genuine overlap (40 → 28) and excessive prefetch
causing repeated transfers (56 → 30). Both connect a player decision to visible
causes. Backpressure teaches why a schedule must tolerate different workloads,
but an already robust two-buffer program also solves it. Similarly, the final
level is currently a reuse/alternative-design exercise rather than a new mechanic.
Those are content-balancing questions for novice feedback, not reasons to change
the approved progression or add a new subsystem during this bug-fix pass.

Mission specifications are available immediately, but longer text still needs
scrolling. Future polish should prioritize quicker comparison between the public
workloads and current state, without exposing the answer by default.
