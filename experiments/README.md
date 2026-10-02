# Experiments

Isolated technical/gameplay investigations, outside the supported runtime. Each must state
its question, setup, evidence and disposition. Production code must not acquire an
undocumented dependency on experiment files.

## Isolated second-act labs

Requires Godot **4.7.1 stable**, Python 3 and Git. No new dependencies. Run from repository root:

```sh
python3 scripts/run-experiment.py representation --godot /path/to/Godot
python3 scripts/run-experiment.py intelligent_workload --godot /path/to/Godot --locale en
```

On this Mac, replace `/path/to/Godot` with
`/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot`.

The launcher imports a fresh copy under `.godot/experiments/<id>/project`, uses a
unique `VonNeumannBottleneckChecks/experiments/<id>` user directory and writes its
session log/captures next to the copy. It never launches against your ordinary save.
`--prepare-only` prepares without opening a window. Do not launch the scenes against
an ordinary player directory: existing project autoloads still initialize there.

Representation has three sequential experiments, unlocked by recorded runs. Choose
settings, run, compare the history, and click Trace rows to inspect actual bytes and
outputs. Historical results are immutable when controls change. Progress is local
to this scene session; quitting resets it. Intelligence is a separate hidden scene,
not linked from the campaign or representation's ending. Sound remains absent.

Automated viewport acceptance (known objectives, **not** novice evidence):

```sh
python3 scripts/run-experiment.py representation --godot /path/to/Godot --replay lab
python3 scripts/run-experiment.py representation --godot /path/to/Godot --replay lab --locale en
python3 scripts/run-experiment.py representation --godot /path/to/Godot --replay proxy --locale en
```

The last command uses a bounded no-answer policy. Task fixtures use Test mode with
prerequisite components available and untouched target starters. It does not prove
ordinary Game progression. Its finite action vocabulary measures starters, reads
Hint1 and compares one-variable controls; it cannot synthesize arbitrary circuits
or understand every diagnosis. Stops are evidence of policy limits, not automatic
level failures. The policy is separate from the actuator and receives plain public
UI observations; no solution catalogs, model oracle or receipt target enters it.
See the verification report for exact paths, failures, repairs and limitations.

Design, model rules, omissions and incorporation gates:
[second-act framework](../docs/design/second-act-framework.md).

## Constructible representation and persistent state (2026-10-03)

```sh
python3 scripts/run-experiment.py representation_plan --godot /path/to/Godot
python3 scripts/run-experiment.py intelligent_state --godot /path/to/Godot --locale en
python3 scripts/run-experiment.py representation_plan --godot /path/to/Godot --replay depth
python3 scripts/run-experiment.py representation_plan --godot /path/to/Godot --replay depth --locale en
```

The depth replay operates both new scenes with viewport input and known objectives;
it is not the unknown-answer policy or native OS input. It records failed designs,
boundary edits, undo/redo, paired orders, state spills, response delay and precision
failures. The two original labs remain available. See
[plan rules](representation/PLAN_README.md), [state rules](intelligent_workload/STATE_README.md)
and [integration evidence](../docs/verification/20261002-second-act-depth/README.md).
