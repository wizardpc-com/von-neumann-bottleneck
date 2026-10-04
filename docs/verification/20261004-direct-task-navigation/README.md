# Direct task entry follows the active task

Baseline `cbe20010624679fe8f3a5fb896d8c3819a2dc355`, existing
`ray/representation-playloop-20261003` branch. This is a bounded navigation
correction. Simulation, task definitions, locks, progression and save schemas are
unchanged; the earned tutorial replay correction remains intact.

## Reproduction and correction

Native Linux cloud QA, official Godot `4.7.1.stable.official.a13da4feb`, English,
1364×1024. The existing isolated native profile had earned Tutorial completion
through ordinary input in the earlier tutorial replay check. No completion flag
or solution was injected for this native check.

Task tree → completed Wiring Tutorial → Mission's “Begin Half Adder Challenge”
opened Half Adder correctly. Its Level Map button then returned to the task tree
with Wiring Tutorial still selected. The recent-visit preference already pointed
to Half Adder, so hub Continue could locate it, masking the transient-selection bug.

`TaskNavigation.remember_visit` now synchronizes transient selection after matching
an existing unlocked Game task, before its repeated-visit persistence shortcut.
Only a changed selection requests map recentering. Matching tree entry and repeated
matching visits retain the camera. Locked/unknown entries and Test-mode visits
remain unable to replace Game navigation. This uses the existing validated visit
hook shared by direct task starts; it introduces no new routing or persistence path.

## Regression evidence

The corrected 26-check regression fails on the baseline source, including both
actual map-return selections, direct branch navigation, repeated last-visit repair,
and the shared visit hook for later chapters. The initial test draft also had a
camera expectation carried across a map scene that legitimately changed framing;
that assertion was corrected before the final red/green comparison.

The new suite opens Tutorial through the tree, presses the actual next button,
returns to the real map, re-enters the selected node, directly opens Latch and
rejects locked Full Adder. It also checks repeated visits, preserved camera state,
unknown/locked visit rejection, Test-mode isolation, persisted Continue reload,
and unchanged complete progression snapshots. Prerequisites are explicitly
synthetic test fixtures, separate from native earned-play evidence. Later chapter
coverage exercises the shared visit hook, not four new native playthroughs.

Focused run `20261004T200254Z-b1c95684` passes import, isolated user directory and
five suites: direct-task navigation, tutorial replay, layout navigation,
chapter-card routes and release convergence. Baseline source and corrected test
are retained in local isolated run `20261004T200218Z-8cf9374b`.

## Final verification

Full isolated run `20261004T200352Z-946500f0` passes all 65 conventional Godot
suites plus import and user-directory isolation (67 stages, exit 0). Production
navigation and the new regression are byte-identical to that imported copy.
All five Python CI commands pass: branding, report-playtests, storage, receiver
and community. `git diff --check` passes. Independent read-only review found no
material correctness or regression issue.

After updating only the isolated QA runtime script, the same native earned profile
was restarted. Tutorial still displayed earned 5/5 without a new completion cue.
Its direct Half Adder action opened the expected task; Level Map selected and
centered Half Adder. After manually panning the tree, entering Half Adder again
and returning retained that exact visible framing and selection. A normal close,
restart and actual hub Continue click again selected and centered Half Adder.
The complete saved `game` object was identical before and after these native checks,
with only Tutorial completed. Owned QA windows were normally closed.

Screenshots were inspected in computer-use history, not retained as image files.
Native logs show only the existing unsupported V-Sync and ALSA → Dummy warnings,
with no game-script error. This is developer-informed Linux source QA, not novice
acceptance, a full-campaign native replay, Windows/macOS, export, HiDPI or audio
acceptance. No merge, release or deployment. Remote publication and exact-SHA CI
are verified separately in the handoff.
