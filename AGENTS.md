# Repository guidance

## Start here

- `README.md`: project status, run instructions, and vision.
- `ARCHITECTURE.md`: high-level subsystem map.
- `PLANS.md`: when and how to write an execution plan.
- `docs/README.md`: detailed design, architecture, development, and status docs.

Repository-local documentation is the source of truth. Preserve unresolved questions instead of inventing product decisions.

## Repository map

- `project.godot`: Godot 4.7.1 project entry point.
- `src/simulation/`: typed, deterministic DSL and simulation code.
- `src/ui/`: Godot scene, hardware bench, profiler, and trace playback.
- `tests/`: addon-free headless simulation and UI checks.
- `experiments/`: isolated investigations; production code does not depend on them.
- `docs/`: durable design, architecture, workflow, plans, decisions, and status.

Do not move `.gd`, `.tscn`, or other Godot resources merely to make the tree look cleaner. Inspect `res://` and UID references before any resource move.

## Project invariants

- Use Godot 4.7.1 stable and prefer strongly typed GDScript.
- Keep simulation deterministic and independent from UI/rendering.
- Produce a complete `SimulationTrace`; UI may play it back but must not change results or metrics.
- Ordinary wires describe connectivity and have zero simulation latency.
- Transfer costs belong to components such as Cache, Bus, and RAM.
- Cache is hardware-managed; players do not insert cache contents manually.
- Prefer Godot built-ins, simple code, and explicit prototype limitations over speculative abstractions.

## Mandatory workflow gates

1. Inspect `git status` and read the relevant docs and tests before editing.
2. Keep work inside the requested scope; avoid drive-by cleanup, unrelated renames, and gameplay redesign.
3. Follow `PLANS.md` when a change crosses its planning threshold.
4. Update architecture, status, testing, or decision docs when their source-of-truth facts change.
5. Run fresh, relevant verification and review the final diff before claiming completion.

## Verification

- Simulation changes: run `tests/test_simulation.gd` and confirm determinism and the row-first advantage.
- UI, wiring, profiler, or playback changes: also run `tests/test_ui.gd` and the project smoke command.
- Documentation-only changes: run whitespace/link/path checks appropriate to the files changed.
- Use only commands recorded as verified in `docs/development/testing.md`; report exact outcomes and separate pre-existing warnings from introduced failures.

## Git safety

- Keep `main` runnable; use short-lived, focused branches for feature work.
- Never push, merge, force-push, rewrite history, add a remote, or discard unrelated user changes unless explicitly requested.
- Do not run destructive commands such as `git reset --hard` or `git clean -fd`.
- Do not invent Git author identity. Preserve releases with commits and tags, not copied version directories.
