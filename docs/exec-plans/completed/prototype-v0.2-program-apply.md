# Prototype v0.2 explicit program application plan

## Goal

Make programming state unambiguous: editor changes remain a draft, line-by-line explanations and address preview describe that draft, and only an explicit Apply action replaces the program used by Test Bench. Provide directly loadable column-first and row-first strategy drafts plus a concise Python-shaped syntax reference.

## Scope and non-goals

In scope:

- separate draft source, applied source, and last-executed source states;
- block Test Bench while a valid draft is unapplied;
- explicit Apply Program action and visible application receipt;
- parsed-IR-driven line explanations and address previews;
- column-first and row-first strategy buttons that load drafts without silently applying them;
- tests and durable documentation.

Out of scope:

- general Python compatibility, arbitrary loop bounds, undo history, file import/export, progression, balancing the supplied strategies, or production per-component animation assets.

## Invariants

- `SimulationCore` executes a parsed program originating from the applied source only.
- Editing or loading a strategy never changes the applied source implicitly.
- Invalid or unapplied drafts cannot be run from Test Bench.
- Applying a draft invalidates stale trace evidence; playback remains read-only.
- Reference metrics remain 321 cycles for column-first/one-line and 105 cycles for row-first/one-line.

## Implementation and verification

1. Add IR-derived source-line explanations to `DSLProgram`.
2. Add Python-shaped reference, strategy buttons, Apply Program, application state, and explanation output to Program instrument.
3. Change Test Bench to parse and execute `applied_program_source`, with draft mismatch blocking run buttons and direct calls.
4. Extend simulation/UI tests for explanation coverage, strategy loading, blocking, applying, exact source execution, and unchanged metrics.
5. Update ADR/status/testing docs, run all checks, capture Program visually, and audit the final diff.

## Decisions

- Strategy buttons load editable drafts and never bypass confirmation.
- The starter column-first source is applied at startup so the original first-run path remains available.
- Line explanations describe semantics but do not execute code or produce a second IR.
- Per-component animation families are deferred to formal production; the current staged animation exposes the extension point without inventing unvalidated art behavior.

## Progress

- 2026-08-15: plan created; implementation started from direct feedback.
- 2026-08-15: draft/applied/last-executed source states implemented; unapplied valid drafts block Test Bench and direct run calls.
- 2026-08-15: Python-shaped reference, column-first/row-first strategy library, prominent Apply Program confirmation, IR-derived address preview, and six-line starter explanation implemented.
- 2026-08-15: simulation and UI tests cover explanation semantics, silent-apply prevention, blocked run, explicit row-first application, exact trace source, and unchanged 321/105 metrics.
- 2026-08-15: Program draft capture verified that row-first selection visibly reports DRAFT NOT APPLIED and exposes an enabled Apply button before the code editor.
- 2026-08-15: simulation, UI, and startup smoke checks passed with exit code `0`; documentation and ADR 0003 updated.

## Outcome

Programming now has an explicit, auditable state transition. Both supplied strategies are immediately usable but never silently active; a player can inspect Python-shaped syntax, code, address order, and line meanings before confirming Apply. Test Bench then executes only that applied source, and the receipt plus `SimulationTrace.program_source` prove which code produced the measured result. Component-specific animation families are recorded as a production follow-up while the generic v0.2 PROCESS orbit remains unchanged.

## Unresolved items

- None for this prototype correction.
