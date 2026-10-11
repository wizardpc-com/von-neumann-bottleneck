# Claude and Codex collaboration

This checkout is shared by the user, Claude, and Codex. `AGENTS.md` is the common
policy; `CLAUDE.md` imports it. Product status belongs in
[CURRENT_STATE](../CURRENT_STATE.md), architecture in
[ARCHITECTURE](../../ARCHITECTURE.md), and test procedures in
[testing](testing.md). This guide describes coordination in the workspace.

The root `CLAUDE.md` contains only `@AGENTS.md`, using the documented
[file import syntax](https://code.claude.com/docs/en/memory#import-additional-files).
Keep the shared rules in one file.

## Starting a task

1. Read the common policy and relevant source-of-truth documents.
2. Inspect `git status --short --branch --untracked-files=all`, `git diff`, and the
   local handoff at `.godot/collaboration/handoff.md` if present.
3. Record the task owner, intended outcome, and files to edit in that handoff.
   Coordinate overlapping files before editing. If another assistant is active
   and ownership is unclear, read/review first and resolve ownership with the user.
4. Follow `PLANS.md` when the change needs a versioned execution plan.

Each assistant can implement or review. Choose roles per task; a second assistant
can review the same files without editing them. Parallel implementation requires
disjoint file ownership, including shared resources, tests, translations, and docs.
The handoff is a human-readable record, not an enforced lock. Do not assume a task
is abandoned because its entry is old.

## Shared checkout discipline

Keep one owner for Git mutations and one owner for Godot execution at a time.
Branch switches affect both assistants. Never switch, pull, merge, stash, stage,
commit, or restore files while the other assistant is editing without coordination.
Read-only Git inspection is safe during concurrent work.

Preserve unfamiliar changes and inspect the live file again before applying an
edit based on an earlier read. If overlapping work is required, finish and hand
off the file first. Distinct worktrees are an option for genuinely independent
tasks, following project and user instructions; they are not required for routine
edits in this folder.

Do not automatically start or message another assistant. The user coordinates
Claude/Codex tasks unless they explicitly authorize delegation. This setup does
not establish a live messaging connection to Claude.

## Tools and verification

Use the pinned **Godot 4.7.1 stable** standard engine and Python 3. If the engine
is kept locally under `.godot/tools/godot-4.7.1/`, its macOS executable is:

```sh
.godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot --version
python3 scripts/verify-project.py --godot .godot/tools/godot-4.7.1/Godot.app/Contents/MacOS/Godot
```

Run these from the repository root. The verifier imports a fresh QA copy and uses
separate player-data directories. Use repeatable `--suite` arguments for focused
checks. Run Godot verification and native play sequentially. Follow `testing.md`
for GUI, restart, and network checks; automated success does not establish native
input, beginner understanding, or package acceptance.

The Python CI gates are:

```sh
python3 scripts/check-branding.py
python3 scripts/test-report-playtests.py
python3 server/test_storage.py
python3 server/test_receiver.py
python3 server/test_community.py
python3 server/test_delivery.py
python3 server/test_private_report.py
```

The receiver/community tests require permission to bind temporary loopback ports.
Godot QA writes isolated data outside the checkout on macOS; a sandbox may require
execution permission. Tools, imported caches, and local handoffs stay under the
already ignored `.godot/` directory. Never commit them or delete player saves.

## Handing off work

Update `.godot/collaboration/handoff.md` with:

* owner, task, and state: active, ready for review, blocked, or complete;
* owned/changed files and a concise behavior summary;
* exact check commands, outcomes, and paths to evidence;
* outstanding decisions, failures, and unverified acceptance;
* the next action and whether file ownership has been released.

Inspect the final diff and Git status. Another assistant's review should identify
actionable issues with file/line evidence and respect existing file ownership.
The user remains the final integrator under the existing Git policy. Commits,
pushes, and publication require the authorization defined in `AGENTS.md`.

`main` can contain local commits ahead of `origin/main`. Check both before an
update; `git pull --ff-only` cannot integrate remote changes if histories diverge.
Do not reset local work to make the status appear synchronized.
