# Execution plans

Execution plans make large Codex-assisted changes reviewable without forcing process onto small edits.

## When a versioned plan is required

Create a Markdown plan under `docs/exec-plans/active/` before implementation when work:

- changes architecture or a project invariant;
- spans multiple runtime subsystems;
- performs a large refactor or risky Godot resource migration;
- adds a feature whose behavior needs staged acceptance; or
- is expected to exceed roughly 500 non-mechanical changed lines.

Small, localized, reversible tasks may use an inline plan in the task conversation.

## Required plan content

Each versioned plan must record:

- goal, scope, and explicit non-goals;
- affected files and subsystems;
- invariants that must remain true;
- implementation and verification steps;
- decisions and their rationale;
- progress with dated or commit-linked updates; and
- unresolved questions, limitations, and follow-up work.

Plans are living documents, not speculative specifications. Update them when evidence changes the approach. Do not silently convert an unresolved question into a decision.

## Lifecycle

1. Create a clearly named file in `docs/exec-plans/active/`.
2. Keep its progress and verification evidence current while implementing.
3. Review the final diff and capture the actual outcome.
4. Move the completed plan to `docs/exec-plans/completed/` in the same change that closes the work.

Do not duplicate release snapshots in version folders. Git commits and tags preserve history.
