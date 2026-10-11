# Repository pruning — 2026-10-11

Owner: Codex root. User requests actual removal of obsolete task books and files,
followed by normal integration into main.

## Scope and invariants

Remove superseded execution briefs, duplicate historical proposals and old active
queues. Keep the game constitution, current design/model/save contracts, source,
resources, tests, delivered packages, player data and verification evidence.
Historical files remain recoverable from Git; do not create archive copies.
Consolidate still-open platform/player/deployment gates into RELEASE_BLOCKERS.
Current docs must not describe removed runtime as an available feature.

## Steps and decisions

1. Audit old plans against current state and implementation evidence.
2. Delete obsolete task instructions; retain substantive creative design sources.
3. Reduce the documentation map and acceptance list to current entry points.
4. Resolve references to deleted files through their immutable Git history,
   preserving dated verification records rather than inventing new acceptance.
5. Check local links, whitespace, runtime/resource identity and the final diff.
6. Commit, push, merge the reviewed documentation-only PR and update local main.

## Progress and limits

2026-10-11: clean main 34aed77 inspected; sole editor/Git owner is root.
Old active plans include delivered work and external acceptance, not new scope.
No runtime change, new package or remote/platform acceptance is claimed.
Verification and merge results will be recorded before completion.

2026-10-11 outcome: removed 26 obsolete files (4,731 lines), reduced CURRENT_STATE
and RELEASE_BLOCKERS to current scope, and rebuilt the documentation map. Creative
design rationale and the constitution remain; dated verification links to deleted
files resolve to immutable main 34aed773025d314d068d50e352ef8077394ca2ec in Git.
All 774 local Markdown links resolve, with zero pre-existing or introduced missing
links; diff whitespace check PASS. Changed paths are documentation-only; runtime,
resources, tests, model/save contract and constitution are unchanged. No engine
run or rebuild is needed for this pruning. Normal PR integration follows these
checks; the final merge receipt belongs in the local handoff. Remote/platform/player
acceptance remains open in RELEASE_BLOCKERS, with no new acceptance claim.
