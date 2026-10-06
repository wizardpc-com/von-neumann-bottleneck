# Confirmed candidate reload and recorded Prediction source

Runtime commit `9e1f6019c102e5e9ec358664c711d30b18bfa4e1`, branch
`codex/mac-second-act-20261005`; starting HEAD `475df50`. Root integrated the
existing Sol agents' disjoint review/test contributions and performed all Git,
Godot and GUI work serially. This closes this bounded source fix, not all external
acceptance or formal campaign integration.

Confirmed reload now initializes task/draft/selections before reading. A smaller
Representation snapshot cannot retain an invalid block index; an empty profile
cannot retain an old draft while marking it clean. Service also clears the
replaced event and pinned comparison. Normal writer retry still retains exploration.
Optional Prediction shows the selected record's task/rule and its relation to
current task/draft. Its detached source field never exposes future observations.
Models, candidate schema2, production saves, core40/endings and optional status
are unchanged. No new contract, model or domain was added.

Fresh baselines: [snapshot/empty-profile failures](baseline-restore.txt) reproduce
index3 out of bounds and6 failed assertions; [Prediction source baseline](baseline-prediction-source.txt)
fails10 assertions. A suspected Representation detail-sync bug was **not reproduced**:
[new baseline replay coverage](baseline-replay-details.txt) passes261 checks, so
that runtime was left unchanged. One [new layout fixture failure](initial-layout-fixture-failure.txt)
was corrected by setting its explicit1280px test size/anchors; production layout
was unchanged.

Frozen affected regression `20261006T063309Z-6e12e9ac`: import/isolation and all six
suites PASS. Restore42, writer retry UI48, Prediction source28, Representation
visual261, Service session63 and navigation24. [Full results](frozen-results.json).
[Identity receipt](source-identity.json) verifies1856 committed files against the
QA copy; unrelated collaborator AGENTS/docs index excluded and only two QA user
path settings normalized. This is affected verification after the earlier whole
integration freeze, not a newly run whole-project regression.

New local package `build/free-alpha-9e1f6019c102/macOS/Von-Neumann-Bottleneck.app`,
profile `MacSecondAct-9e1f601`. [Manifest](mac-manifest.json). Matching official4.7.1
private template; universal ad-hoc signature, not notarized/publicly released.
ZIP `Von-Neumann-Bottleneck-macOS-free-alpha-9e1f6019c102.zip`,78328939B,
SHA256 `75cf25ca1b6c6e84224c65876be09c88c221ae1244ec896c948b142bc127595a`.
Identity command passes source/archive/file hashes/notes; [actual release binary/PCK probe](mac-release-probe.json)
and [14 checks](mac-release-probe.txt) pass in QA `68c0fd723dad`.

Native CUA observes the new default hub and enters Service using keyboard. Pointer
click returns `-10005 noWindowsAvailable`. Input attempts after a frontmost change
are re-observed, but slot editing/save are not established in this session. No new
native saved record was created; no claimed novice or full5+3 result. A separate
actual binary default startup session65566 exits0 on CmdQ; its [log](mac-native.txt)
contains no engine error. The prior CUA-launched service process is gone and its
independent profile has no save/lease after exit. Source/PCK checks and prior
c78d594 native edit/save/restart evidence remain separate from this limited native
observation. Newly fixed snapshot/empty reload is verified by real isolated UI/
Store/Lease tests, not a new native recovery walkthrough.

A direct exported Prediction scene override was attempted and rejected by the
**official release template** (`disable_path_overrides`); [raw log](mac-scene-override-failure.txt)
preserved, exit1. The default app then launched normally through CUA; do not
attribute that hub to a successful Prediction override. Prediction's new caption
has bilingual minimum-layout/prefix-hiding tests; no native Prediction claim.

[Approved push attempt](push-authentication.json) actually exited128, missing
GitHub HTTPS username with prompts disabled. No remote write; this supersedes the
prior approval refusal for475df50. Credentials must be restored through the user's
normal login flow before the authorized developer-branch push can succeed.

Finite A–D source requirements are implemented across the existing linked stages:
Representation5, Service3, optional commissions, introductions, navigation,
protected sessions and separate/joint reviews. Independent beginner/otherMac,
full native pointer/menu route and formal/public integration remain open. Next
step is acceptance of this frozen candidate and fixes from actual feedback;
no additional chapter count or new simulator is implied by those gates.
