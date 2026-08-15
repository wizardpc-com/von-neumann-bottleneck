# Codex workflow

## 1. Scope

- Read root `AGENTS.md`, `README.md`, `ARCHITECTURE.md`, the relevant detailed docs, tests, and current Git state.
- Restate the requested outcome, boundaries, and explicit non-goals.
- Treat unresolved design questions as unresolved. Do not expand a task because a future feature seems adjacent.

## 2. Plan

- Use a short inline plan for small, localized work.
- Follow `PLANS.md` and create a versioned active plan for architecture changes, cross-subsystem features, large refactors, risky Godot resource moves, or roughly 500+ non-mechanical lines.
- Name affected files, invariants, verification, and likely failure modes before implementation.

## 3. Implement

- Make the smallest coherent change that achieves the scoped behavior.
- Preserve the simulation/UI boundary and other project invariants.
- Avoid drive-by formatting, speculative abstractions, dependency additions, and resource moves without a demonstrated need.
- Update the specific source-of-truth documentation when facts change.

## 4. Verify

- Run the exact relevant commands from `docs/development/testing.md`.
- Compare observed results with the acceptance criteria; do not infer success from code inspection alone.
- Review `git diff`, `git diff --check`, ignored/untracked files, and final `git status`.
- Distinguish baseline environment warnings from failures introduced by the change.

## 5. Review and handoff

- Check for scope growth, duplicated logic, broken invariants, stale docs, and missing tests.
- Report files/subsystems changed, exact verification outcomes, assumptions, known limitations, and anything not verified.
- Commit only when the task authorizes it. Never push, add a remote, merge, or publish without explicit authorization.
