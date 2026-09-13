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

## Candidate

Candidate build and exported-binary/native checks will be appended after freezing
the preparation commit. No public upload, server, store submission or Windows
real-machine claim is included. Another Mac installation/notarization, Windows,
extended focus/mixed-DPI sessions and external beginners remain explicit release
gates rather than implied by green tests.
