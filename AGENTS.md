# AGENTS.md

## Repository guidance

Before non-trivial work, inspect the relevant code, tests, and repository documentation.

Start with:

* `README.md` — project status, run instructions, and vision.
* `ARCHITECTURE.md` — high-level subsystem map.
* `PLANS.md` — planning rules for large or risky work.
* `docs/README.md` — index of detailed design, architecture, development, and status documentation.

Repository-local documentation is the durable source of truth.

Do not invent product decisions when documentation is incomplete or ambiguous.

## Core invariants

Unless explicitly changed by the user:

* Use Godot 4.7.1 stable and prefer strongly typed GDScript.
* Simulation must be deterministic and independent from UI/rendering.
* Simulation produces authoritative results, metrics, and `SimulationTrace`; UI only presents them.
* Animation timing must never affect simulation results.
* Ordinary wires describe connectivity and have zero simulation latency.
* Latency, bandwidth, transfer time, and queuing belong to modeled components such as Cache, Bus, and RAM.
* Cache is hardware-managed; players do not manually place cache contents.
* Prefer explicit simplified models over fake physical precision.
* Prefer simple existing Godot mechanisms over unnecessary dependencies or speculative abstractions.

Do not silently perform a large rewrite when existing code violates an invariant. Surface the mismatch and scope the correction explicitly.

## Working discipline

Before editing:

1. inspect `git status`;
2. preserve unrelated user changes;
3. inspect the relevant implementation, tests, and documentation;
4. understand existing behavior before replacing it.

Make the smallest coherent change that solves the requested problem.

Avoid:

* unrelated cleanup or refactors;
* unnecessary file moves or renames;
* speculative architecture for future features;
* gameplay/design changes outside the task;
* moving Godot resources without checking `res://`, UID, scene, and resource references.

For small reversible implementation details, make a reasonable choice and continue.

Stop and surface the issue when a decision would materially change gameplay, simulation semantics, architecture, persistent formats, dependencies, or task scope.

Follow `PLANS.md` for large, risky, architectural, or cross-subsystem work.

## Verification

Never claim work is complete or working without fresh verification.

Use the verified commands documented in:

`docs/development/testing.md`

Before handoff:

1. run the relevant tests/checks;
2. inspect their full result;
3. inspect `git diff`;
4. inspect `git status`;
5. report anything not verified or any pre-existing failures separately.

Simulation changes must verify determinism and relevant metrics, not only final output.

When durable architecture, simulation behavior, testing procedures, or project status changes, update the corresponding repository documentation.

## Git safety

Development is primarily performed locally. The user is the final integrator and normally reviews changes before committing and pushing.

Unless explicitly requested:

* do not create commits;
* do not push or merge;
* do not modify remotes;
* do not force-push or rewrite history;
* do not discard unrelated user changes;
* do not run destructive commands such as `git reset --hard` or `git clean -fd`.

Do not create branches or worktrees mechanically for trivial tasks.

Historical versions belong in Git commits, tags, and releases, not copied version directories.

## Handoff

At completion, report concisely:

* what changed;
* verification performed and results;
* known limitations or unverified items;
* anything the user should manually inspect or play-test.
