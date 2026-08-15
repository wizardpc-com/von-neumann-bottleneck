# Git workflow

## Branches

- `main` should remain runnable and should contain reviewable, verified changes.
- Use short-lived branches. Suggested prefixes: `feat/`, `fix/`, `refactor/`, `docs/`, `experiment/`, and `chore/`.
- Keep each branch focused on one stated outcome. Separate unrelated cleanup.

## Commits and review

- Commit intentionally; messages should describe the outcome rather than the editing process.
- Significant AI-generated code changes should normally be reviewed through a pull request.
- A PR should state scope, behavior change, affected subsystems, exact test results, limitations, and documentation/decision updates.
- Prefer a clean squash into `main` after review when a branch contains iterative agent-fix commits.

## Releases and history

- Preserve meaningful versions with Git tags and, when a build is suitable for others, GitHub releases.
- Do not create copied `v0.1/`, `v0.2/`, or similar source directories.
- The `prototype-v0.1` tag marks the historical cache-locality vertical slice.
- Do not rewrite shared history or move published tags.

## Safety

- Inspect `git status --short --branch --untracked-files=all` before and after work.
- Do not force-push, run `git reset --hard`, run `git clean -fd`, or discard unrelated changes.
- Do not add or change remotes, push, merge, or publish unless the user explicitly requests it.
- Never invent Git author identity. If it is missing, report the exact configuration and remaining commit/tag commands.
