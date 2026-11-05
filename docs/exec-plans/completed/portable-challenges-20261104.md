# Portable measured layout challenges — 2026-11-04

Owner: Codex root; branch `codex/gameplay-systems-20261104`, baseline `b65a0bd`.
The first two completed increments remain intact and uncommitted.

## Goal and scope

Finish a playable offline challenge loop over Chapter 4's actual calculations:
pin a measured target, keep it across visits, explicitly copy/import its bounded
recipe, inspect the locally remeasured result, and improve it through ordinary
editing and Run all cases. Measure the existing strategy distribution before
deciding whether any simulation extension is warranted.

One target per task is sufficient for this increment. Game targets use a new
protected sidecar; Test targets survive scene visits only within the process.
The board remains the only challenge entry, with two pages inside its existing
exclusive Window. Import/preview/pin never changes a draft or earns completion;
the existing explicit restore action is one undoable edit.

Non-goals: online services, accounts, remote scores, anti-cheat claims, changes to
the original simulation/targets/progression, campaign additions, main commits,
pushes, releases or exported packages. Disputed Opus design decisions stay in
the existing audit rather than being silently reverted.

## Decisions and compatibility

- Use `VNB4C1:` plus bounded canonical JSON. Exact fields are version, task,
  model, condition, objective and data recipe. No external score, executable
  source, path, completion flag, player identifier or arbitrary metadata.
- Validate exact keys/types/finite integral bounds at every nesting level before
  calling permissive internal normalization. Require canonical payload equality,
  rejecting ambiguous duplicate keys and hand-edited unknown structure.
- Bind task/model/all ordered official cases and their existing constraints
  through the same condition helper used by `LayoutScoreboard`. All imported
  live targets must remeasure as eligible for every original case.
- Relocation transport contains exactly A/B recipes; reconstruct the internal
  root container without treating unused root fields as executed work.
- Store at most six targets in `user://layout_challenges_v1.json`, at most
  32 KiB, with codes bounded to 4096 UTF-8 bytes. Preserve unknown/corrupt files
  read-only. Supported old conditions remain stored but inactive. Stage atomic
  writes, keep original bytes on failure and permit identical-target retry.
- GlobalSave's schema, task solutions, named designs and original rewards are
  unchanged. Old software ignores the new sidecar. Rollback leaves the sidecar
  recoverable; do not delete player files. A failed save can keep a clearly
  temporary target for the current visit without claiming persistence.
- Game/Test mode is captured at the action boundary. A stale dialog cannot
  operate in a newly selected namespace. No clipboard read occurs on entry.

## Ownership and affected files

- `audit_scores`: new challenge codec/store and their focused tests; only the
  condition helper extraction in `layout_scoreboard.gd`.
- `audit_polish`: `layout_scoreboard_window.gd` and new Window test. No persistence
  or simulator authority in the presenter.
- `review_records_final`: read-only strategy audit and bounded probe under the
  ignored collaboration folder, then independent review when assigned.
- Root: `layout_chapter.gd`, the new retained store member in `layout_state.gd`,
  controller tests, integration, docs and all sequential Godot/Git operations.

Exact shared APIs and review boundaries live in the local collaboration record;
the durable behavior contract lives here and in layout architecture documentation.
The existing non-relocation `orders` validator mismatch is recorded for a
separately scoped follow-up; strict external parsing must not expose that path.

## Implementation and acceptance

1. Audit current model/persistence/Window contracts; freeze pure interfaces.
2. Implement strict codec, protected sidecar and compact two-page Window in
   parallel. Integrate mode-bound loading, pinning, preview, explicit restore,
   clear and retry with the ordinary run comparison.
3. Run bounded real strategies through the current simulator. Record exact
   candidate scope, Pareto tradeoffs and repeated Trace/recipe identities.
   No model change follows merely from adding challenge UI.
4. Verify strict malformed/version/identity/size rejection, A/B preservation,
   full-case recomputation, restart retention, Game/Test isolation, original
   file protection and actual open/rename failure recovery.
5. Verify controller draft/undo/progression preservation, real beaten/tied/failed
   runs after reopen, pinned-objective stability, stale mode rejection and
   clipboard/focus/modal behavior in bilingual GPU layouts.
6. Independently review implementation, inspect diff/status, archive logs and
   raw frames, update current status/testing/contracts and provide an isolated
   playable preview. Native input and exported-platform claims require separate
   evidence; Mac lock-screen failure from round2 is not a successful test.

## Progress and limitations

- 2026-11-04: checkout and previous receipts verified. Three read-only audits
  started. Contract/UX audits support this bounded extension without a model
  change. Root owns sequential verification; independent runtime work begins
  after this plan and the shared API assignment.
- Strategy distribution remains unmeasured at plan creation. Optional resource
  ceilings and server replay remain follow-ups, not accepted design decisions.
- 2026-11-04 measurement update: all2555 candidates completed in42.610s with
  1991 accounting checks and13 repeat/JSON identity samples. Each task's declared
  sample has one frontier metric triple; cold-field batch1 dominates earlier
  mixed examples. Record this as a high-priority modeling question, retain all
  valid results, and defer major-rule changes to an explicitly versioned
  experiment. Resource ceilings alone would not address this dominance.
- 2026-11-04 integration: initial codec288/store166 and10 existing suites passed.
  New Window/controller fixture failures were corrected, then Window106,
  controller66 and existing scoreboard UI44 passed. Independent review found
  and root repaired exact-target retry/objective and persisted-fallback wording;
  final GPU and modality acceptance is in progress.
- 2026-11-04 completion: 14 related headless suites have passing latest staged
  observations. GPU Window120/controller82/original score UI47/settings26 passed;
  real process seed/reopen preserved the Game code and dropped Test targets.
  Ordinary isolated startup exited0. Raw logs, reviews,13 final frames plus1
  diagnostic and1153-file source binding are in
  `docs/verification/20261104-portable-challenges/`. Mac native input remains
  blocked by the locked session; no exported/cross-platform/newcomer claim.
  `.godot/portable-challenges-preview-20261104.command` is the isolated preview.
  No commit/push/release. Ownership released to root for handoff; this bounded
  plan is complete. The broader development goal and measured model question
  remain active follow-up work.
- Local recomputation explains results but does not establish remote identity,
  unmodified clients, server trust or cross-platform package acceptance.
