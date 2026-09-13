# Spatial interface candidate convergence — 2026-09-13

Final source runtime: `cff6feb`; subsequent preparation changes are documentation
and packaged change notes only. Godot 4.7.1 stable on the local Apple M2 Mac.

## Final source checks

Fresh isolated verifier `20260913T032109Z-be04a826` passes import, userdata isolation,
all conventional suites and the full English ordinary Game input route. See
`results.json` and `game_gui_en.txt`; detailed suite logs remain in that isolated run.
The full replay builds arithmetic/storage, CPU and LOAD/STORE, checks independent
Hint and enters Chapter 1. It is replay evidence, not a substitute for native play.
Previous current-source bilingual renders and actual Chapter 2/3 sessions are in
[readable investigations](../20260913-readable-investigations/README.md).

## Actual native closure of earlier pending source checks

- CPU: minimized the expanded Mission to its compact form, closed Parts, changed
  camera zoom, opened separate H1 and returned. Test Bench and compact Mission
  retain their positions, Parts stays hidden, and the camera matches the prior view.
- CPU formal seven-step program passes again after Hint return. Playback was changed
  from 2 Hz to 16 Hz during presentation; all seven official outputs still match.
- Chapter 1: explicitly selected the waiting-memory prediction and ran both RAM-wait
  cases. Each passes in 134 cycles. Profiler shows total 268, compute 16, wait 252,
  RAM service 216 and 18 memory requests. The strip's small cyan share matches
  16/268; RAM service is not added to CPU wait a second time.
- Resized the Profiler from roughly 552×509 to 552×324 screen points; every visible
  metric, legend and bar remains within the window. Focused surface remains distinct
  from History/Test Bench behind it.

These checks used the existing isolated, earned Game profile. No real player data,
reference-solution loader, completion setter or runtime simulation change was used.

## Frozen candidate and actual release binary

Build **free-alpha-47a59d385103**, source **47a59d3851033b0564712f36fb4eea8d64b25d3c**,
Godot **4.7.1.stable.official.a13da4feb**. The final source checks above cover the
same runtime; the freeze preparation commit changes documentation/change notes only.
Both archives are in `build/free-alpha-47a59d385103/`; see `candidate-manifest.json`
for their full SHA-256 values. Nothing has been publicly released.

Commands completed successfully:

```sh
python3 scripts/build-free-candidate.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --commit 47a59d385103
python3 scripts/check-candidate-identity.py build/free-alpha-47a59d385103
python3 scripts/verify-mac-candidate.py --app build/free-alpha-47a59d385103/macOS/Von-Neumann-Bottleneck.app
```

The last command used the actual release executable/PCK, verified Game-only mode,
40 tasks, build identity, empty endpoint, disabled upload and excluded developer
resources. See `mac-candidate-probe.json`. The QA copy only adds a userdata override;
it does not modify the executable, PCK, bundle identity or signature. Delivery
files remain untouched. Post-play hashes again match both copies and the archives.

## Native exported Game: fresh profile, earned progress, restart

Computer use operated the QA copy of that exported app, with no DEBUG window suffix.
Its isolated profile starts with no completed levels; no test fixture/completion
setter or reference loader was used. Native observations are from the live tool
screens, distinct from the renderer fixtures in earlier records.

1. Chinese hub displays the exact candidate ID. Entered the prominent task tree,
   dragged its background, zoomed and entered Tutorial with the mouse. Nodes move
   while the right-hand task description/action card remains readable and fixed.
2. Dragged a NOT from Components onto the canvas and removed it with Cmd+Z. Wired
   A → NOT → LAMP, changed A, ran the practice circuit, deleted an actual wire with
   a right click, then reconnected it. Tutorial reached 5/5 and unlocked both branches.
3. Returned to Chapters, selected English and enabled Reduce interface motion in
   Settings. F11 entered windowed mode; headings, wrapped text, scroll area and
   fixed Resume/Quit controls remained readable at the observed ~1280×768 size.
4. Quit using the actual Quit Game button; the app disappeared from running apps.
   Relaunched the same candidate. English and reduced motion remain selected.
   Continue opens the tree with completed Wiring selected and both next branches
   available. Re-entering Tutorial preserves the two wires. Its per-visit practice
   checklist resets to 0/5; this does not revoke saved completion or unlocks.
5. Rechecked English windowed Mission tabs/actions, compact instruments and hub
   chapter cards. Captions wrap or scroll rather than shrinking to fit. Verified
   reduced motion still selected in Settings, then quit normally again.

The isolated presentation file independently confirms `locale="en"` and
`reduced_motion=true`. Fullscreen preference persistence was not established;
relaunch was fullscreen. This record does not claim frame-by-frame motion analysis.

## Remaining release gates

This closes the exported Mac mouse/Continue gate on this machine. It does not close
Windows real-machine validation, another Mac install/notarization, external novice
comprehension, long-session focus loss or mixed-DPI checks. Windows is an exported
candidate with verified archive identity, not a natively played build. Those gates
remain in `RELEASE_BLOCKERS.md`; no server, store submission or public upload occurred.
