# Representation split input — 2026-10-09

Actual frozen f905 Mac app (`Continuity-f90597b`) earned task1 and task2 through
native CUA Home/map entry and keyboard edits/run/save. Observed task1 metrics:
135 cycles/60B storage/60B traffic; task2:34/52/16. Two native saved supports and
runs are retained in the own-profile copy. This is known-answer operator evidence,
not novice acceptance. Cmd+Q followed by procNotFound ended this native process.

The same native route exposed a concrete error: right RLE block[16,64), old
SplitAt16 makes Split unavailable. Pasting24 and Tab then Enter skipped Split and
activated Raw. Only after focus left did24 update the button. Enter in the input
before Tab avoided it, allowing task2 completion. Pointer-routing failures and
one mistaken focus-count sequence are tool/operator issues, not runtime defects.

SplitAt now uses Godot's existing update_on_text_changed property. Integer edits
refresh action availability before Tab traversal; model splitting, codecs, traces,
metrics, save schemas and gates are unchanged. Service has no matching disabled
Split boundary chain, so it is unchanged. The focused suite retains its original
22 checks plus six checks: right-block fixture, invalid16, intermediate2, valid24,
Tab-to-Split, Enter retaining RLE. Inputs are actual viewport keys, fixture setup is
explicit, and rendered viewport verification is distinct from native OS input.

Official4.7.1.a13da4feb fresh isolated verification: import/isolation PASS,
focus28/edit-context39/Representation3329 PASS. Full logs retained. One Apple M2
OpenGL renderer run in its own fresh QA directory also passed28, exit0; a native
IMK mach-port message remains in the raw log, no Godot script error. First import
in the restricted sandbox failed because editor settings could not be saved;
its original full log is retained. The authorized retry passed. No repetitive full
baseline or Linux rerun; earlier f905 Linux143-suite evidence remains attributed.

Commands:
- `python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --suite test_candidate_disabled_focus --suite test_representation_edit_context --suite test_representation_region`
- Renderer command, unique data directory and source hashes: split-renderer.json.

Current work: commit/export the corrected runtime, then verify its native text/Tab
path and continue Representation3–5/review/save/reopen and Service. Original40,
independent novice/artistic/listening/device/Windows/distribution acceptance remain
open. Four unrelated collaborator files preserved; no production migration,
main merge or public release. Goal active after Mac unlock; old locked-state
records describe historical attempts, not the present barrier.
