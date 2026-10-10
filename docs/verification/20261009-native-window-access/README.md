# Native-window access diagnostic — 2026-10-09

Previous goal turn made progress: split-input repair, fresh target-engine checks,
matching Mac package, native T1/T2 save evidence, full CI and pushed handoff.
This continuation checks the same live process rather than restarting it.

At source `ef61f832a2c6`, runtime `426009f1c052`, authorized `ps -p 80322
-o pid=,stat=,command=` returned the exact exported executable in state S.
CUA inventory likewise reports the game running. Two exact-path `getApp` attempts
returned `Accessibility error: AXError.cannotComplete`. No native input, new
measurement, save or window observation occurred. The unsaved T3 RLE draft is
left in the existing process; no parallel Godot, kill or injected save was used.

A single read-only one-second `sample` completed successfully at 04:19:07 EDT.
The [raw call graph](sample-callgraph.txt) shows all 58 main-thread samples inside
AppKit event-loop callbacks ending in `nanosleep`; worker threads waited on
conditions. Most engine frames are unsymbolicated. No GDScript loop was visible
in this sampled interval, but this is not proof of responsiveness or absence of
bugs. The existing `src/ui/window_mode.gd` explicitly reduces `Engine.max_fps`
to15 on focus exit. The sample is compatible with an idle/limited engine; it
cannot attribute the CUA failure or earlier unchanged GUI to a definite cause.

The full raw sample, including loaded-library inventory, remains under ignored
`.godot/diagnostics/native-80322-20261009/sample-full.txt`; its hash and the exact
excerpt boundary are in [receipt.json](receipt.json). Only the call graph is
committed. No runtime change or regression/export repetition was justified.

Fresh `git ls-remote --heads origin` matched every local remote-tracking SHA;
there is no newly observed branch content to integrate. The same four unrelated
collaborator paths remain untouched. Goal stays active and unproven: this is the
second consecutive turn with this window-access barrier, after the prior turn
still made repair/verification progress. Resume the same app when native control
is available; do not start another engine while PID80322 remains live. Earn and
save Representation3–5/review/reopen and Service, then continue original40 and
independent human/platform acceptance. Automated proof cannot replace them.
