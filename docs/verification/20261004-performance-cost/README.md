# See what the measured speedup costs

Baseline `079d4f5ae29a0b7a15b4faf1357d70504f526962`, existing
`ray/representation-playloop-20261003` branch. Presentation-only addition; no
simulation, receipt, completion, unlock, task-count or save-schema changes.

## Native finding

Developer-informed Linux cloud play used Godot `4.7.1.stable.official.a13da4feb`
at 1364×1024. The UI-earned storage/CPU profile was copied into an independent
QA directory; the original remained byte-identical. All arithmetic, storage,
CPU and LOAD/STORE prerequisites came from the prior native construction pass.
No completion setter, reference solution or injected circuit was used here.

The initial transition already explains the separate eight-bit teaching model,
its three devices, the applied program and six request/write/read connections.
Native input connected all six routes. Assembly passed both official cases at
22 cycles each, and its finding opened the CPU comparison. That comparison
introduced prediction, baseline and a one-part change clearly.

The missing connection was the resource tradeoff: Run History showed Eco → Fast,
316 → 268 total cycles, 252 → 252 CPU WAIT and 64 → 16 compute cycles, but no
hardware cost. Cost was visible only in the separately changing Parts panel.
The measured finding therefore did not put the 15% time reduction beside its
21 → 30 hardware cost.

## Change

Run History now shows the recorded baseline machine cost and the recorded
before/after cost delta. It reads the same immutable receipt as the existing time
comparison, not current part selections or draft code. Costs are per machine,
not summed across cases. The CPU mission adds a short bilingual cue to compare
time saved with hardware cost; cost is not a new requirement for that mission.
The existing timing chart, authored comparison, locks and success actions remain.

## Verification

- New `test_system_cost_evidence`: 114 bilingual checks pass, covering CPU, RAM,
  Bus, baseline lock/prediction, no-run state, per-machine cost, unrun selections,
  debug runs, unapplied drafts, unchanged receipts and duplicate reruns.
- The final suite against the baseline runtime fails at the 12 missing cost
  readouts, exit 1. The original suite draft incorrectly expected an identical
  rerun to append a reverse comparison; it was corrected to verify existing
  deduplication rather than changing runtime behavior.
- Full isolated run `20261004T221659Z-c645f5ba`: all 69 conventional suites plus
  import and user-directory isolation pass (71 stages). Final runtime,
  localization and focused test bytes match that run's imported copy.
- All five Python CI commands and isolated normal / Test / reset startup smokes
  pass. Independent read-only review found no blocker. `git diff --check` passes.

## Native recheck

Restart preserved the earned Assembly/CPU completion and following RAM unlock.
The reopened session required fresh runs before showing cost evidence; no missing
receipt was filled from the current settings. Running Eco again displayed cost 21.
Selecting Fast changed Parts to cost 30 while History kept its recorded 21.
After Fast's official run and explicit Finish Trace, History showed cost
21 → 30, Δ +9 beside the unchanged 316 → 268 and CPU WAIT comparison.
Chinese and English Mission page 3 and History were inspected for readable,
unclipped text. Language reload preserved the in-session measured comparison.
Both owned QA sessions were closed through Quit Game.

## Limits

This is informed Linux source QA, not novice comprehension, Windows/macOS,
exported-package, HiDPI or audio acceptance. Screenshots were inspected in native
computer-use history. Native logs retain the environment's unsupported V-Sync
and ALSA-to-Dummy warnings. No merge, release or deployment.
