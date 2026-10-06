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

Initial native session: CUA observes the new default hub and enters Service using keyboard. Pointer
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

[Earlier approved HTTPS push attempt](push-authentication.json) actually exited128, missing
GitHub HTTPS username with prompts disabled. No remote write; this supersedes the
prior approval refusal for475df50. This is historical; the SSH follow-up below succeeds.

Follow-up native session63263 on the same immutable package/profile now confirms
mouse slot edit1→4, two Run results and actual Save. Both remain task1: clicking
locked task2 did not transition. Measured1324cycles/2320B total/528B state/458B
peak, first responses[89,158,227,296], exact score/state; peak exceeds350 by108B.
The [actual saved recipe](mac-native-saved-recipe.json) contains two runs, no
supports, four-slot RAW64 draft. SaveSHA256
`30e934d2e66958b2a2b44c79fa8e11eee83318e7bbeb66ac1802074879883a42`.
Cmd-Q exits0; writer lease released. [Log](mac-native-followup.txt) retains OS
IMK/TSM diagnostics; no Godot error. CUA screenshots are in the conversation,
not stored PNG artifacts. [Full bounded receipt](mac-native-followup.json).

Independent restart session13682 reaches the hub, but CUA pointer entry returns
`-10005 noWindowsAvailable` even after Raise, keyboard and new binding attempts.
No Service restore was observed. The [startup log](mac-native-resume-attempt.txt)
is empty; Cmd-Q did not stop own PID75776. After verifying its exact QA command,
root sent SIGTERM only to that process (exit143). No remaining game process or
candidate lease, and saved recipe bytes unchanged. This attempted restart is
**not** clean-startup/restore evidence. Priorc78 successful native restart remains
separate. Window transition improves first-session pointer input but does not
close general pointer/drag or full5+3 acceptance.

The user explicitly authorized SSH push after establishing authentication.
[Actual SSH push](push-ssh.json) exits0; read-only `git ls-remote` confirms remote
`codex/mac-second-act-20261005` at`9cfbb05b7e3764ef54664fe275d42b32295f452d`.
Strict host verification stayed enabled. No remotes modified, main merge, force
push, candidate upload or unrelated collaborator files committed.

Finite A–D source requirements are implemented across the existing linked stages:
Representation5, Service3, optional commissions, introductions, navigation,
protected sessions and separate/joint reviews. Independent beginner/otherMac,
full native pointer/menu route and formal/public integration remain open. Next
step is acceptance of this frozen candidate and fixes from actual feedback;
no additional chapter count or new simulator is implied by those gates.

Subsequent sole CUA .app launch PID83217 confirms independent native Service
restore: entry shows the saved draft and two records recomputed under the same
model; metrics match the actual recipe above. Normal mouse edits concentrate
A0..A5 first. B1 is selected, but destination editing then fails with CUA
`-10005 windowNotFoundAtPosition`; window transitions and Tab/Shift-Tab do not
restore operation. No new Run/Save or successful plan is claimed. Cmd-Q leaves
the process alive; after exact binary identity verification, SIGTERM ends only
that QA instance. No game process remains. **The dead Service writer marker
remains protected**, and the actual saved bytes are unchanged; it was not
manually removed. Explicit native dead-writer recovery remains pending.
[Bounded restored-record receipt](mac-native-restored-records.json).
This supersedes the earlier attempted restore limitation without changing its
historical failure evidence; it does not establish full native5+3 or novice play.

SSH remote commit91524d7 passed the actual
[GitHub Actions run37428444712](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/37428444712).
[Final job status](ci-91524d7-status.json). Official Godot4.7.1 release SHA512 is
checked by the workflow. Downloaded [full83 Godot logs](ci-91524d7-godot-logs.txt)
were inspected:81 conventional suites PASS, import and isolated-directory probe,
no missing/unexpected suite or error. [Per-log hashes and scope](ci-91524d7-evidence.json).
The GUI-only `test_recovery_game_input` is intentionally outside this headless
workflow. Five [Python checks](ci-91524d7-python-checks.txt) also succeed. Only documentation/evidence differs
between runtime9e1f601 and CI91524d7, so this is a fresh full frozen-source Linux
regression for the candidate runtime; native Mac acceptance remains separate.
No redundant local whole-project rerun or artifact rebuild was performed.
Raw CI logs retain whitespace and four non-failing anchor/size warnings from
existing UI fixtures; they are not silently rewritten as warning-free results.
