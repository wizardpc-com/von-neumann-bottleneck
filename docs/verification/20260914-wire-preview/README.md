# Wire placement feedback — 2026-09-14

## Change

Reverse input drags now generate the committed output-to-input curve and reverse
only its drawing order. Previously they used output-start curvature and could
flip on release. Ordinary preview uses the actual native nearest-port hotzone and
hover validator: a compatible socket snaps, a rejected socket shows a cross and
an empty-canvas endpoint follows the pointer. Source port electrical state is unchanged.

A brief pointer-speed response replaces the uniform draft halo. It settles at rest,
respects reduced motion and shares scalar round / bus square tips with branch and
endpoint rewiring. There is no repeated decorative pulse, input delay, topology
mutation or simulation call. Wire length still has zero modeled latency. Explicit
trace replay, its wave timing and playback-frequency controls are unchanged.

## Checks

- Godot 4.7.1 isolated run `20260914T024018Z-3710773c`: hardware UI and prologue
  simulation pass; Chinese ordinary Game recovery replay passes (634 checks, zero
  failures). Rendered feedback exposed a filled-circle width warning, fixed next.
- Final `20260914T024243Z-61ba49fa`: both targeted suites pass again; English ordinary
  Game recovery replay passes (634 checks, zero failures). Final drawing has no
  filled-circle warning. Existing synthetic-input reuse warning at test line 274
  and macOS IMK diagnostic remain separate from this change.
- Added checks cover forward/reverse curve equality, target snapping, wrong-side
  rejection, input-side bus width, movement/rest/reduced motion, cancellation and
  unchanged topology/analysis count.
- Direct renderer captures inspected: [valid socket](preview-valid.png),
  [rejected socket](preview-rejected.png), [reverse drag](preview-reverse.png).
  Moving/still frames remain in the final isolated project's `.godot` folder.
  [Capture helper](capture.gd) uses synthetic presentation setup, not earned progress.

## Native ordinary Game

Fresh profile `VonNeumannBottleneckChecks/wire-native-20260914`, QA bundle
`local.vnb.finalqa`, final isolated source. CUA mouse control worked this time:

1. Homepage → task tree → Tutorial → briefing → Start building.
2. Drag NOT input backwards to A output; connection created at the expected sockets.
3. Drag NOT output forwards to LAMP; A=0 yields LAMP=1.
4. Attempt output-to-output connection; rejection message appears and both existing
   wires remain intact.
5. Right-click the A wire, then Command-Z; wire and output restored.
6. Toggle A to 1 and run; LAMP=0, tutorial advances to 4/5.
7. Delete A wire and drag backwards to reconnect; 5/5 completion overlay appears.
8. Command-Q exits the owned QA process normally.

Native automation exposes complete drags, not held-pointer video. Fine in-flight
appearance was assessed from direct renderer frames plus state/motion tests; it is
not a claimed subjective human animation review. Multi-bit native dragging,
Windows and extended mixed-DPI/focus acceptance remain pending. The existing
frozen candidate package predates this source update and was not overwritten.
