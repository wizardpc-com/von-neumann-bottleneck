# Round 6 independent evidence review

Reviewer: `/root/review_records_final`; read-only source/log/file inspection.

**Current result: no actionable discrepancy found in the completed runtime,
source-binding, native saved-input or final static evidence. The intended
169-file staged scope and all49 raw logs have now been independently checked.
The generated static receipt still needs its planned final restage; subsequent
report archival, commit and push are not certified by this snapshot.**

## Documentation and delivery scope

Read the complete main Round6 receipt, completed execution plan, leading
`CURRENT_STATE` entry, native receipt, strategy receipt and archived frame review.
They distinguish staged targeted checks from a whole-repository regression,
scripted viewport/GPU evidence from native operation, and local cooperative
recovery from arbitrary-writer CAS/power-loss durability.

The completed plan explicitly separates implementation/runtime acceptance from
the later authorized milestone commit/push. At this inspection, read-only Git
reports task branch `codex/gameplay-systems-20261104`, HEAD
`e07b4bbba845a1046835884ecf06916930fa8b8a`, and main
`b65a0bd3064888f41c5caeb8d7d0717d2b901658`. No premature sixth-round push or release
claim was found in the reviewed receipt/plan. This review does not certify any
subsequent Git delivery.

## Runtime receipts

Independently read the complete latest log for each of the **16 distinct
headless suites** and their result manifests. All cited latest observations
have exit0/passed true and match the documented counts:
codec397, store288, controller65, challengeUI250, model2669/171 measurements,
legacy3810/141 designs/282 cases, goals75, session72, workspace51,
NotebookStore414, formalCodec288, formalStore166, GlobalSave/localization,
originalUI216 and NotebookUI159.

Read the complete final GPU logs and results:

- `20261105T043615Z`: challengeUI282/0, exit0, Apple M2/OpenGL.
- `20261105T042825Z`: originalUI244/0 and NotebookUI177/0, exit0.

The earlier failure/capture batches are retained rather than substituted for
the successful observations. The text records the fixture failures and the
separate successful native route without treating scripted popup mouse failure
as either native acceptance or a simulation failure.

Ordinary playable startup receipt reports exit0, no diagnostic errors and
launcher syntax exit0. Its raw startup log is clean. The launcher is executable,
contains no fixture/test driver and points at the declared prepared project.
The complete preview-import file was scanned for errors, warnings, failure or
exception diagnostics; none were found.

## Source, settings and image binding

Recomputed every hash in `source-sha256.json` from the actual repository, final
QA and playable files. All recorded hashes match. The manifest contains1206
entries: **1205 identical source/test/support files**, plus the separately
documented `project.godot` settings entry.

Independent text diffs confirm only two isolated user-directory entries in QA;
the playable copy additionally selects the experiment main scene. No other
settings difference exists. The playable profile currently contains neither
an injected Notebook nor challenge target file.

For all46 frame-manifest entries, recomputed archived hashes, file sizes and PNG
header dimensions and compared archived bytes with their recorded original
isolated-profile files. All match: **28 final frames and18 earlier frames**.
The final versus historical batches and actual popup dimensions are documented
correctly. Root/another reviewer performed the visual examinations; this review
does not claim to have re-opened those46 images visually.

## Separate-process persistence evidence

Read all seven process logs/results, the process probe and archived runner.
Six ordinary phases exit0; the held writer PID27900 is identity-checked and
deliberately killed, exit-9. The result does not disguise that crash as normal
shutdown.

The probe/runner establish actual changed operations, not only no-op success:

- Live target ownership refuses competing target replacement and preserves
  original bytes.
- A genuinely changed Notebook goal saves under that same contention, with
  changed Notebook bytes.
- Recovery explicitly reclaims the stopped owner, changes serial Q1 cap600→601,
  checks different target bytes and leaves Notebook bytes unchanged.
- A subsequent independent process reconstructs exact codes, challenge IDs,
  metrics and complete Trace hashes.
- A different fresh profile inherits neither target nor Notebook state.

The runner's finally block restores the QA settings and its concluding checks
assert byte-for-byte restoration and all expected phase results.

## Native evidence boundary and saved inputs

Read the ordinary native invocation/runner, final engine log, native receipt,
archived project settings and both saved JSON files. The invocation selects
the ordinary lab scene without a test script, an isolated named profile,
process43541 and normal exit0. The engine log has no Godot error; the macOS
keyboard informational line is documented.

Recomputed both archived file hashes and compared them with the actual same
isolated native-profile files:

- Target file453 bytes, SHA256
  `f553aca3eee3890daa98f21c90f1ecdbef0af3829d6423cac611432dcb04e784`.
  It contains the accepted original direct-source group1/tile17 target,
  objective cycles and Q1/copy caps350/0.
- Notebook file3129 bytes, SHA256
  `625fe99da0b5f7ba734089965cf956c0e19381921d777263e58d49e93c96776a`.
  It retains group2/tile1 as the scan-batch draft, unlimited personal goal,
  no retained preset solutions and the current full condition.

These files support the claimed separation of target and improved draft.
Native screenshot/action observations belong to root's CUA history; this
reviewer did not operate or independently observe that CUA session and does
not infer the precise sequence of clicks from saved files alone. The receipt
states the limited Chinese path and explicitly excludes native English,
clipboard, keypad, settings/feedback, resize and native same-profile reopen.
Its screenshots are not relabeled as fixed-size GPU captures.

## Final static and staged-scope review

Read the complete `.godot/collaboration/check-round6-final.py`, generated
169-name intended-file list and actual `static-checks.json` receipt dated
`2026-11-05T05:02:46.461666+00:00`. The helper includes tracked, cached and
nonignored untracked changes, every actual receipt file including ignored raw
logs, and its exact generated output path. Its bootstrap exception is limited
to that same output; it does not hide arbitrary missing documentation links.
The helper was inspected but not executed by this reviewer.

The passed receipt records45 authored files,21 Markdown files,169 intended
files,49 raw logs,1205 source bindings,28 final frames and18 historical frames.
Independently recomputed authored-file whitespace and local Markdown link
checks against the actual intended list: no issues, with all linked local
paths now present.

Independently enumerated all49 actual receipt `.log` files and confirmed every
one is in the unique169-name intended list. Read-only Git inspection then
confirmed exactly169 staged paths, with no missing or extra paths. Compared
each staged blob with its worktree bytes:168 match, including all49 raw logs;
only the subsequently regenerated `static-checks.json` differs. Root has
explicitly scheduled that generated receipt and this final report for archival
and restaging before commit. The raw-log inclusion concern is closed at this
staged snapshot despite the repository-wide ignore rule.

Unstaged `git diff --check` exits0. Staged `git diff --cached --check` exits2
with exactly the two documented raw-log final blank-line warnings:
`logs/startup-smoke.log:2` and `process/hold.log:2`. No authored whitespace
warning exists. Preserving those unedited engine logs is consistent with the
receipt's stated byte-for-byte evidence policy.

This completes the evidence/static review and the independently observed
staged-scope/raw-log check. It does not certify the final report's later staged
bytes, the generated receipt's planned restage, a Round6 commit, a remote push,
a main update or a release. These remain root's separate delivery checks.

No source/test/docs were edited by this reviewer; only this assigned report.
No engine run, native input, Git mutation, network operation or ordinary player
profile was used. Exported builds, other platforms, newcomers, long-session/
audio behavior, formal promotion and online trust remain outside this evidence.
