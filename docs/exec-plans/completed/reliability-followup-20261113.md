# Player-loop reliability follow-up — 2026-11-13

## Goal and scope

Continue the existing game reliability audit from main `3a8e605`, with emphasis
on player input, named designs and safe departure. User authorizes subagents and
verified milestone commits/pushes to main. Do not choose final art, add gameplay,
change simulation semantics, migrate saves, publish exports or deploy services.

## Ownership

Root owns integration, Git mutations, sequential Godot runs and evidence/status docs.
Core agent owns Hardware naming-modal input and its new regression.
Scheduling agent owns formal Layout named-save protection, experimental scheduling
quit input handling and their new regressions. Presentation agent owns corrections
to final-maintenance.md and the existing visual decision inventory.
No overlapping file edits; local coordination lives in .godot/collaboration/handoff.md.

## Candidate defects and implementation

1. Reproduce editor shortcuts beneath the Hardware new/copy naming overlay with
   actual viewport focus. Make the overlay own input; preserve its existing close,
   submit and text editing behavior and resume editor actions after close.
2. Reproduce same-name different-recipe replacement from the formal Layout tools.
   Preserve named copies consistently with the existing scoreboard policy; allow
   exact retries and expose rejected saves without changing the saved schema.
3. Reproduce pristine scheduling departure after unsubmitted numeric text. Commit
   through the existing numeric path before deciding whether an exit guard is needed.
4. Verify Escape while holding a component drag stays in the level and ends the
   gesture, per existing nearest-layer navigation rules. Preserve the established
   focus-loss convention of one undoable move rather than inventing rollback.
5. Correct current maintenance scope and old-home-only Logo instructions; retain
   rejected visual changes as historical boundaries, without selecting art.

## Invariants and verification

Ordinary player profiles remain untouched. Use Godot 4.7.1 stable and isolated QA
copies. Root runs new tests against unchanged runtime first, retains expected failures,
then runs candidate regressions and neighboring input/save/challenge/navigation suites.
Inspect complete logs, rendered input where relevant, source bindings and final diff.
A second agent reviews final code. Document exact evidence and native/export limits.
Commit/push each coherent verified block and confirm remote main identity.

## Progress and decisions

- 2026-11-13: clean starting tree; remote main independently confirmed at `3a8e605`.
  Read-only audits found the three candidates above; all three reproduced against the old runtime. Extended Hardware negative control
  reports 22 expected failures; Layout named save 8; pending exit 4. No script errors.
- Engine located at `/Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot`;
  repository-local historical engine path is absent on this checkout.

- 2026-11-13: four defects reproduced and repaired.22 distinct focused headless
  suites and4 GPU regressions pass; final native Mac naming-modal/Undo/Redo check
  passes and owned process exits0. Independent cross-review found no blocker.
  Evidence: [receipt](../../verification/20261113-input-preservation/README.md).
  Source-bound logs retained; implementation complete, delivery pending.

## Open acceptance

Native mouse/keyboard/focus, exported Mac/Windows, long-session/audio and newcomer
understanding remain separate from automated controller/viewport checks. Final
visual/Logo selection belongs to the user and team. No online ranking authority
or release acceptance is implied by this pass.
