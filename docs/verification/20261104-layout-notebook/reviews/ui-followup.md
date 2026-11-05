# Round5 UI follow-up — read-only

Received a new opaque task message; the latest readable implementation contract
still gives all source ownership to root. No source edit or Godot run occurred.

Inspected the complete latest UI logs and results under:

`.godot/verification/20261105T021829Z-18f99d78/headless/20261105T024724Z/`

- Existing `test_layout_strategy_ui`:216 checks,0failures, process exit0.
- New notebook UI:155 checks,2failures, process exit1. Both failures are the
  same assertion, “Keeping includes the separately edited draft,” one per locale.
  The remaining scene/goal/restore/save-failure/reopen assertions completed.
- Import, Workspace, legacy, formal challenge code/store, GlobalSave and
  localization entries in this batch are marked passed; their full individual
  logs were not reviewed in this follow-up.

The original UI assertion compared raw JSON-decoded nested plan values against
the typed normalized in-memory plan. Root has already changed source line104 to
`Model.normalize_plan(persisted.states.scan_batch.draft) == grouped`.
This uses the production full-plan normalization and preserves the actual draft
equality assertion. It does not replace it with a weaker single-field check or
change any simulation/storage behavior.

The source correction is appropriate. It still requires the new suite to rerun;
the failed024724Z log must remain labelled as a failed initial observation.
No fresh result for that changed assertion is claimed here. All implementation
ownership remains released to root.

If a further review/edit was intended by the newest encrypted message, please
place its scope in round5-implementation.md or another readable coordination file.
