# Round10 Hardware host recovery fixture

Owner `audit_polish`, 2026-11-05. Implementation is released to root:
`tests/test_hardware_failure_recovery.gd`.

SHA256 at release:
`a43b24446d72728b172b0c8c3328e0e2a86705af64ba33f5230a422f38ba1dbc`.
Root owns UID import, all Godot execution, integration and further edits.

The new fixture exercises the real HardwareFoundations Test-mode host and its
visible A/B word inputs, LOAD toggle, Debug button, Pause and Step controls.
It reproduces the shared-driver/register sequence through actual host callbacks:

1. A=B=3, LOAD=1: preview does not commit; Debug commits and observes3.
2. A=5, B=6, LOAD=1: live preview and Debug retain a real short-circuit failure.
   The failed result retains the conflicting input values and full error/events;
   runtime storage and continuation map must retain their previous valid values.
3. LOAD=0, A=B=0: corrected live preview becomes electrically valid and observes3
   without a reset or new commit. Debug then successfully HOLDs3 and replaces
   the failed status with the actual successful output.

For each explicit valid/failed/recovered Debug observation, the fixture pauses
ordinary playback if needed and uses the real Step control. It checks exactly
one existing batch advances, while runtime, carry and the complete authoritative
result/event snapshot remain unchanged. Playback's visual period is set to2s
in fixture setup only, so the explicit Pause/Step observation does not race
autoplay; model execution remains synchronous.

The original failed result is retained by reference and frozen as
`canonical_signature()` plus `error_specs` (the one result field not included in
that method). Later input correction, Debug and Step must leave that evidence
unchanged. The current host's Debug method keeps the live result instead of
publishing its one-step report to `prologue_report`; the fixture reads that
actual boundary and its real playback batches.

The diagnostic board is five real supported components and four real
connections: two4-bit external inputs into one register4 DATA port, a LOAD input
and a4-bit Q observer. It is installed only into the instance's detached
register descriptor and temporary Test inventory using existing host builders.
The registered lesson and its official steps are never mutated. No reference
solution, fabricated result, forced passing flag or simulator stub is used.
The fixture is an authored controller regression, not a claim that the player
built or earned this circuit.

Isolation is checked before host construction: the actual user directory must
match the verifier's `VonNeumannBottleneckChecks/` namespace. The real `--script`
host must expose an empty workbench storage path and the Test namespace.
Game content signatures and exact Game/workbench main/tmp/bak file hashes are
compared before/after. Test progress and library signatures, official evidence,
sealing availability and completion overlay must remain unchanged/unearned.
No profile file is created by this fixture; optional PNGs remain in the copied
QA project's `.godot` directory.

Headless input changes use actual SpinBox/CheckButton signals and Debug/Step
button callbacks. Renderer runs use actual viewport mouse and keyboard events
for word fields, toggles and actions. Each action must be visible, unclipped,
on screen and enabled; its normal pressed listener remains attached through
the full click and settling interval and must count exactly one activation.
There is no hidden-control signal fallback, retry or direct handler call in the
GPU path. Native OS input is not claimed.

Expected old-runtime failure: failed Debug publishes its conflicting map,
therefore the last-valid carry assertion fails; subsequently corrected preview
and Debug still report the old short. The fixture preserves those failures
rather than resetting state. Root must demonstrate this on the frozen base and
then obtain a fresh candidate pass; neither result has been run by this agent.

Suggested root runs:

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_hardware_failure_recovery
```

For GPU, use the already imported isolated copy with its own QA user-directory
binding, `--windowed --resolution 1280x720 --script
res://tests/test_hardware_failure_recovery.gd -- --capture-size=1280x720
--hardware-recovery-capture`. Optional raw captures:

- `.godot/hardware-recovery-captures/failed-conflicting-drivers.png`
- `.godot/hardware-recovery-captures/corrected-live-hold.png`
- `.godot/hardware-recovery-captures/recovered-debug-hold.png`

Both directory creation and `save_png()` are checked. Fixed-size capture
acceptance must remain separate from native input and ordinary window
persistence acceptance.

Static verification: inspected current host Debug/live-preview/Step/build/store
paths, prior recovery analysis and independent contract review; inspected the
full authored test and current Git status. `git diff --check` is clean.
`git diff --no-index --check /dev/null tests/test_hardware_failure_recovery.gd`
emitted no whitespace diagnostics (exit1 denotes the new-file difference).
No Godot/parser/GPU/native run or Git mutation was performed by this agent.
