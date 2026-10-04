# Chapter 4 direct-entry return selection

The native resumed Chapter 4 check found that first entry through the chapter card,
then Task tree, selected the tutorial instead of the task just opened. Tree-origin
entries and persisted Continue already worked.

The correction is confined to successful `layout_chapter._open`: after the existing
unlock guard, synchronize transient selection with the task actually opened. Request
recentering only if that selection changes. Matching tree selections retain their
camera. No global return/Continue logic, progression, simulation or save format changed.

## Regression

`test_layout_navigation` reproduces chapter-card entry and return, preserves matching
tree camera state, reloads Continue preferences, covers the next unfinished task, and
checks locked/unknown/unavailable routes and unchanged completed progress. Prerequisite
and completed-field fixtures are synthetic, not earned-play evidence.

Before correction, isolated run `20261004T140221Z-4958445a` failed exactly the direct-entry
selection and return-selection checks. Final focused run `20261004T140445Z-1672e0a1`
passes navigation, chapter-card routes and release convergence. Independent read-only
review found no blocking issue; its suggested next-unfinished task case was added.

## Native scope

Ray cloud Linux, Godot 4.7.1, Chinese 1364×1024. A new isolated runtime and profile were
copied from the previously earned Chapter 4 QA save; the source profile was not used
for this check. That profile has synthetic earlier prerequisites plus UI-earned Chapter
2–4 work, so this is resumed developer-informed QA, not a fresh-player playthrough.

Through native pointer input: hub Chapter 4 card opens fields; the first Task tree
return selects and centers fields. Select records, enter, return: records stays selected
with unchanged tree framing. No simulation or completion action is required. The copied
save's complete `game` object remained equal to the source after these navigation steps.
Closed only the isolated window, relaunched the same profile, and clicked the actual
hub Continue button: records was selected and centered correctly.

Windows/macOS, exported builds, novice acceptance, alternate locale, minimum window and
audio are not covered by this narrow native check. No release or merge is implied.

## Final gate

Full isolated verifier `20261004T140309Z-d1e9ca5b` passes all 61 conventional suites,
plus import and user-directory checks. The runtime fix is byte-identical in that copy;
the later added next-unfinished regression is verified in the final focused run above.
All five Python CI contracts pass (branding, playtest reporting, storage, receiver,
community), and `git diff --check` passes. No GUI full-campaign replay or export was run.
