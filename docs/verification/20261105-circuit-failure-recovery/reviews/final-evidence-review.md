# Round10 final evidence review

Reviewer: `review_records_final`, 2026-11-05.
Scope: final GPU logs, current source binding, all six final raw frames, and
the receipt/current documentation. No engine/native run, Git operation,
production/test/document edit or player-data access by this reviewer.

## Conclusion

**No actionable defect or overstated acceptance found in the final reviewed
runtime, frames or durable documentation.** The earlier stale-storage-caption
issue is closed for the exercised failure/recovery workflow in both locales.
The final evidence supersedes the GPU-pending boundary in the earlier
`visual-review.md`; that earlier report remains a correctly dated source and
headless review.

The closed scope remains the bounded electrical-continuation correction and
its related playback-caption repair. It does not establish native OS input,
Windows, exports, unfamiliar-player understanding, audio/long-session behavior,
arbitrary-input correctness or new performance improvement.

## Final observed executions

Read the complete archived logs and actual invocation records, independently
recomputed each log hash, and checked equality to the originating local
receipt copies:

| Run | Observed result | Input boundary |
| --- | --- | --- |
| `20261105T113852Z` | Chinese GPU158 checks /0 failures, exit0 | Actual viewport input |
| `20261105T114010Z` | English GPU158 checks /0 failures, exit0 | Actual viewport input |
| `20261105T114738Z` | Ordinary main scene startup, exit0 | Headless `--quit-after 8` |

All three complete logs contain no script/parse error, error diagnostic or
warning. Both renderer logs explicitly report Godot
`4.7.1.stable.official.a13da4feb` and Apple M2 OpenGL. The standard startup has
no test script or capture flag and is not presented as native mouse/keyboard
or long-session acceptance.

The already reviewed final headless run `20261105T113619Z` reports host142/0
and six other affected suites passing, after the strengthened host test first
reported142/2 on the simulator-only candidate. Across the staged runs there
are13 distinct related suites with passing latest observations, separately
from import and directory-isolation checks. This is not a full-repository
test count or a single final simultaneous regression.

## Source and frame binding

The receipt manifest has1249 entries:1248 source/test/support files plus
`project.godot`. Independently rehashed the two production changes, both new
regressions and project settings against their current checkout and QA
entries. All match:

- Simulator:
  `3ed8eb32b91b9b7b00fcd9a5b8fa7c25f0095e9c561389632b448e2b51723462`.
- Hardware host:
  `abb7d470271ebadd80618c183c31cb15e537b9771e94666754065939bf273ba3`.
- Pure recovery suite:
  `5cf4ecdb8f9a8cddaf203e0b51ed6b10e3186d11367a8b0477f6343ebe757dd7`.
- Final host recovery suite:
  `88170ef898b86d36d012996463782c381a3610c0f99dadeb0ece5e28bbf46b4c`.

The final GPU invocations bind the final host test and simulator above; the
English invocation and ordinary startup additionally record the Hardware
host hash. The candidate directory is
`.godot/verification/20261105T112607Z-5880555a/project`.
Direct settings comparison shows exactly the two isolated user-directory
entries and an unchanged ordinary main scene.

Independently checked every one of the12 frame-manifest entries: six final
raw frames and six preserved initial diagnostic frames. All byte counts,
SHA256s and1280×720 dimensions match. Each final archived frame equals the
corresponding actual QA output file. No crop, resize or image edit was used
for this review.

## Actual final visual inspection

Actually opened all six final files in `receipt/frames/`, in addition to the
six original diagnostic files inspected during the previous review:

| Locale | Failed conflicting drivers | Corrected live HOLD | Recovered Debug HOLD |
| --- | --- | --- | --- |
| `zh_CN` | Red short diagnostic remains; Q3 and `已存 Q=0x3` | Source wave completed; editor/source0, LOAD0, Q3, stored3 | Green Debug completion; Q3 and stored3 |
| `en` | Red short diagnostic remains; Q3 and `Stored Q=0x3` | Source wave completed; editor/source0, LOAD0, Q3, stored3 | Green Debug completion; Q3 and stored3 |

The corrected-preview capture is still marked as changed input requiring a
new run; it does not claim that a new Debug or earned completion occurred.
The register caption remains consistent while the actual source batch is
advanced. A's source symbol is obscured by the existing floating test bench
in these captures; the visible A editor is0 and the final test separately
asserts both actual A/B symbols are0. The report does not infer hidden pixels
from a screenshot alone.

The earlier `Stored Q=0x0` failure caption was a real stale presentation
snapshot. In contrast, the earlier preview's B6 at the start of a new source
animation was an intermediate frame, not proof of failed input propagation.
The revised fixture's actual Step and unchanged-authoritative-state checks
appropriately distinguish these cases. No extra production animation bypass
or fake state update was introduced.

## Durable documentation review

Read the complete current receipt and the relevant current sections of
`docs/CURRENT_STATE.md`, `docs/development/testing.md`,
`docs/development/COMPUTATION_AUDIT_20261105.md`, the completed Round10 plan,
the active execution queue and the documentation index.

Their result counts, two-file production scope, old/new negative evidence,
three-sample complete comparison, no speedup claim and GPU/native boundaries
agree with the inspected evidence. They distinguish the later host caption
patch from the earlier computation timing measurements. The old compilation
failure, valid old-runtime assertion failures,142/2 caption regression and
initial144-check GPU frames remain explicitly retained.

The eleven accepted complete snapshots were independently reproduced earlier
in this review chain, with four raw/sealed sets and24 original serialized
snapshot hashes verified. The diagnostic comparison report and current result
explicitly preserve the original25-event prefix, actual failed observation
and overall failed verdict, while allowing only the declared carry/recovered
HOLD changes. The changed-work diagnostic is not accepted for speed ratios.
The receipt does not use that computation result as evidence that the later
Hardware presentation patch ran.

The receipt's ordinary-startup section now links the actual114738Z result.
The completed plan and queue accurately keep task-branch delivery separate
from main/release and ordinary player data.

The local coordination handoff's initial Round10 header was still awaiting
root's delivery update when inspected; root was notified. That transient
coordination text is not used as current runtime acceptance evidence here.

Machine-readable final GPU/frame/key-source verification:
`/private/tmp/vnb-round10-final-gpu-verification.json`.
No remaining source, runtime-evidence or visual acceptance finding within
this reviewed scope.
