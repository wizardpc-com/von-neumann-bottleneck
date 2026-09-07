# Construction experience optimization

## Goal and authority

The user's 2026-09-05 request extends the recovered original game: improve circuit presentation, natural editing, beginner instruction and motivation, while retaining existing features and the arithmetic/storage → CPU → LOAD/STORE → Chapter 1 → Chapter 2 progression. The eight-task comparison remains secondary. This is an incremental change to the existing editor, not another campaign or shell.

## Scope and invariants

- Shared Hardware Foundations symbols, wires, navigation and editing feedback.
- Mission presentation and staged specifications; beginner copy across the original route; explicit next-capability previews after success.
- Existing movable windows, named schemes, selection/move/place/delete/branch/multi-select/clipboard/history, Game/Test isolation, three separately requested hints, handbook and tests remain available.
- No simulation, correctness threshold, provenance, save schema, prerequisite, Git index, commit or push changes. Hint return retains ADR 0015's history/clipboard reset.
- No new levels, new editor, copied commercial assets, automatic answer wiring or automatic completion.

## Protection and baseline

HEAD: `76ef11610c3faf2b81722877fa91877a4589074d`. The 32 recovery paths were already staged on arrival; the working tree had no unstaged edits. Preserve this index unchanged.

Backup: `.godot/experience/20260905T230741/backup/`; 331 tracked/untracked non-ignored files copied and SHA-256 verified, binary staged/unstaged patches, HEAD/status and index hash recorded. Actual Roaming player JSON/save/workbench files and existing exported feedback were copied and hash checked; the Local candidate was absent. Original files remain untouched. All runtime checks use repository-local APPDATA/LOCALAPPDATA.

## Reference observations and design choices

- [Turing Complete official page](https://turingcomplete.game/) and [developer's Steam description](https://store.steampowered.com/app/1444480/Turing_Complete/) describe learning through constructing reusable components and solving open-ended circuits. Adopt clear component identities and visible electrical interfaces; keep alternate valid circuits legal. Official screenshots are inspected as visual references; no assets are imported.
- [Human Resource Machine official description](https://tomorrowcorporation.com/humanresourcemachine) uses concrete jobs and gradually introduces commands. Our application: give each existing level one clear new idea, a small behavior example and a reason to continue; keep complex specifications accessible.
- [TIS-100 official description](https://www.zachtronics.com/tis-100/) separates machine documentation from open-ended programming and optimization. Our application: specifications are always readable; solution reasoning stays in voluntary hints.
- These are design inferences, not evidence that our difficulty or novice comprehension has already improved. Novice playtesting is a separate acceptance gate.

## Implementation and verification

1. **Presentation:** reduce cable dominance, distinguish bus/scalar widths, improve symbol/module labels and direction cues; inspect Tutorial, Half Adder and CPU at normal and zoomed views. Keep exact draw/hit/flow path agreement.
2. **Operations:** add focused, discoverable inspection/navigation affordances using the existing GraphEdit. Preserve every current gesture; add regression coverage for new behavior and transformed coordinates.
3. **Learning and tasks:** structure Mission pages, allow immediate building with specs still reachable, add specific examples and next-capability previews without changing tests or prerequisites. Localize Chinese/English together.
4. **Acceptance and delivery:** run relevant suites at each stage, then all 20 suites; ordinary Game GUI replay in Chinese/English, rendered layout review and uniquely identified Windows EXE. Verify exported default entry, saves and index; record OS mouse/High DPI/novice limitations honestly.

## Capability preservation and evidence table

| Existing capability / friction | Incremental improvement | Acceptance evidence |
| --- | --- | --- |
| Freely constructed circuits; thick cables obscure small components | Readable visual hierarchy, scalar/bus distinction, clearer labels | Rendered Tutorial/Half Adder/CPU; geometry and module-clearance suites pass |
| Wire branch/delete, transformed placement and selection | Contextual connection inspection and camera navigation; nearest-port priority and precise single-wire erasing | 454 ordinary Game GUI checks per language, including original CPU seed coordinates |
| Movable Mission, pages, compact objective | Structured specs, direct build entry, always-reachable full task | First-entry Start visibility, direct sections, Previous/Next, small-window and localization checks pass |
| Separate voluntary H1/H2/H3 | Preserve hidden defaults, confirmation and snapshot restoration | Tutorial/Half Adder/CPU hint round trips pass; ADR 0015 history reset remains explicit |
| Original progression and meaningful tests | New concept/examples/next-purpose copy, unchanged gates and thresholds | Both branches → CPU → LOAD/STORE → ordinary Chapter 1 entry through GUI; all simulation/save/chapter suites pass |

## Progress

- 2026-09-05: repository guidance, staged recovery state and relevant editor/Mission sources inspected; protection completed. Implementation begins with shared circuit presentation.
- 2026-09-06: presentation, view navigation, task/specification copy and completion handoff implemented. Native event replay exposed close-port selection, transparent node padding and multi-wire eraser contact; final shared fixes preserve original seed coordinates and save fingerprints. A runtime typed-array error in Focus and an initial Mission-height issue were also corrected. Failed captures/logs are retained under the evidence root.
- 2026-09-06: final implementation passes all 19 conventional suites and 454 GUI checks per language. Final build-label/Tutorial replay passes 121 checks. `experience-20260906T013002-76ef116` exported with matching templates; archive/resource hashes and Game/Test headless startup verified. The original 32-path binary staged patch and actual player-file hashes match the protected baseline. The index file's metadata hash changed during final inspection, while its staged contents remained byte-identical. No commits or pushes.
- Delivered as a bounded playable revision; [status and package](../../status/construction-experience.md) distinguish automated, rendered and partial native-desktop evidence. The desktop locked after an earlier exported candidate reached the original map; final-package desktop replay, physical mouse feel and novice acceptance remain human gates, not completed claims.

## Remaining questions and human gates

No destructive or major progression decision is needed for this scope. High DPI, physical mouse comfort, learning without H3 and desire to continue require human playtesting; automated passes cannot establish them.
