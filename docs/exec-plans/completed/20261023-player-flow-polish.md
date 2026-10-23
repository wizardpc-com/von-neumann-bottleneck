# Player flow and pending work protection

## Goal and scope

Preserve the current game while correcting reproducible input and departure surprises. Settings must own input over a workbench; leaving must respect that workbench's existing unsaved-work protection. Unsubmitted invalid creation text must require an explicit discard before departure.

No simulation, task eligibility, reward, save-format, art redesign, export or release changes. `E:/VNB/video` remains outside the work scope. Preserve the existing uncommitted Claude polish and chapter-five cinematic integration.

## Files and invariants

- Settings departure: `src/ui/prototype_hub.gd`, `tests/test_workbench_escape.gd`.
- Hardware input: `src/hardware_foundations/hardware_foundations.gd`, a dedicated input regression.
- Creation pending text: `experiments/creation/workbench.gd`, `tests/test_creation_sample_editing.gd`.
- Related system/overlap/layout input handlers: inspect the same modal boundary and change only confirmed leaks, with viewport-input tests.
- Root owns integration, documentation and all Godot execution. Workers have disjoint file ownership recorded in the local collaboration handoff.

Existing draft persistence, normal undo/redo, tooltip handling, help/completion guards, and Game/Test separation must remain unchanged. Settings dismissal must restore ordinary controls. Invalid text is never serialized as valid draft data.

## Implementation and verification

1. Preserve the initial dirty diff and run the existing full regression in an isolated project and user directories.
2. Add focused checks for each concrete finding; execute them against the preserved old runtime to establish failure.
3. Apply small local fixes using existing leave and modal interfaces.
4. Run the new tests and affected navigation, save/recovery, creation and input suites against final sources. Inspect actual results and review the diff independently of worker conclusions.
5. Save evidence, source hashes and remaining acceptance limits; update current-state documentation.

## Progress and decisions

- 2026-10-23: initial diff preserved under `E:/VNB/temp/flow-audit-20261023/baseline.patch`; full isolated baseline started at `20261023T101406Z-17a315ad`.
- Static audits found settings quit bypassing candidate leave guards, hardware edit keys leaking through Settings, and invalid Initial text bypassing creation leave protection. Root also found analogous input handlers in other early chapters and is checking their actual behavior before inclusion.
- Prefer existing close notification ownership over introducing a new quit API. Protect pending creation text separately from valid saved draft state.
- 2026-10-23: old-runtime checks reproduced pending Initial loss, Settings Quit bypasses in all four candidate workbenches, hardware shortcuts, and System/Overlap/Layout input leaks. Initial harness errors (eager loading of an autoload-dependent subclass and untyped fixture arrays) were corrected before treating these as runtime evidence.
- Final focused run `20261023T102738Z-73e2219c` verifies the six changed runtime files. Creation pending text passed 258 checks, workbench leave protection 105, and hardware Settings input passed. A temporary card-position fixture affected a redo expectation; the corrected same fixture fails against the old runtime and passes 26 checks against the new runtime in `20261023-flow-final-fixture`.
- Source comparison confirms only the six intended runtime files differ from the preserved baseline; 547 other runtime/assets/localization files and project settings are unchanged. The full baseline and a serial recheck of unexplained process exits are still pending.

## Limits and open work

Automated viewport events and isolated suites do not establish physical keyboard/mouse behavior, audio synchronization, newcomer comprehension or a newly exported package. No claim that every possible bug has been eliminated. Handbook changes await the user's source files.

## Completion

- 2026-10-23: full baseline completed 226 suites + 2 stages; two unexplained exits were retained. Across the baseline and focused run, four suites exited without diagnostic assertions; all four passed serial rechecks after parallel verification ended. Cause remains unlocated.
- Final six-file behavior accepted with 38 relevant headless suites and 3 GPU suites. Latest creation checks: 270 headless, 338 GPU; Settings departure 105; cross-chapter input 26. The GPU-only hidden-tab fixture error was corrected, and the new dialog text was shortened and wrapped before the final headless and GPU replays. Both actual language frames were inspected.
- Evidence, source hashes, scoped patch, original failures and replay helpers are in `docs/verification/20261023-player-flow/`. File ownership is released. No commit, push or export; `video/` remains untouched.
