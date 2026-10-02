# Construction investigations — 2026-10-02

ALU, RAM and LOAD/STORE receive optional input suggestions inside Test Bench.
Inputs do not execute automatically. Run Debug uses the actual player circuit;
only valid results enter the last-eight observation list. ALU presets preserve
A/B/CIN, RAM reads back two independent addresses, and LOAD/STORE practices an
eight-instruction change/readback using the player's sealed TinyComputer.
The official cases, prerequisites, provenance, simulator and completion rules are
unchanged. ALU's 32 official cases are grouped by operation, without revealing
unrun results. Debug history is ephemeral and clears on reset, rewiring or official
run; it is not an official receipt or saved completion authority.

Fresh isolated Godot 4.7.1 checks:

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_hardware_prologue_ui --suite test_localization --suite test_hardware_foundations_ui
```

All three pass. The preceding implementation also passed `test_prologue_simulation`;
subsequent changes only grouped UI rows and cleared history on toolbar reset.
The extended prologue UI test invokes actual suggestion button signals, verifies
that selection alone leaves memory untouched, executes each experiment, checks
RAM outputs 3/12/3/5/12 and LOAD/STORE accumulator values 6/6/2/2/6/9/9/2,
then completes the unchanged official progression. ALU presets preserve data.
No experiment grants progress or changes topology.

`capture.gd` extends this automated test in an isolated project and renders the
three panels at 1280×720. Invoke it once normally and once with `-- --english`.
The reusable components are test-earned fixtures, not native player evidence.
The panel is 520×380 within the available work area; both inputs and observations
are scrollable while debug and official actions remain fixed. Screenshots show
input questions and actual results, in both languages. A first capture fixture
used an over-tall panel; it was corrected and recaptured before acceptance.

Manual beginner comprehension, ordinary OS mouse input and the final package
remain unverified. Eight steps are suggestions, not a mandatory tutorial sequence.
