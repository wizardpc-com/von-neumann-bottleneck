# Round10 final artifact and scope review

**PASS for the current source/evidence scope, with one delivery inclusion note
below.** No source, test, engine, Git-index, branch, or player-data mutation was
performed by this reviewer.

Reproducible read-only check:

`python3 /private/tmp/vnb-round10-final-static-review.py`

Machine-readable result:
`/private/tmp/vnb-round10-final-static-review.json`

The checker exits 0 with `passed: true`, 5701 structural/hash/link assertions and
no open verification failures. This assertion count is not a gameplay-scenario
count. The receipt contained 100 files when this audit completed.

## Final source and approved scope

- All **1249 manifest entries** match current source and final QA bytes:
  1248 runtime/test/support files plus `project.godot`.
- The manifest exactly covers the current tracked/untracked source inventory
  under `src`, `experiments`, `scripts`, `tests`, and `localization`, plus project
  settings; it does not merely check a potentially incomplete declared subset.
- Every non-settings entry is identical in source and QA. The QA settings differ
  by exactly the two isolated user-directory entries, retain the ordinary main
  scene, and select the declared `round10/playable-preview-20261105` profile.
- All **556 frozen runtime files** were independently checked against both the
  frozen reference directory and the actual Git blob bytes at
  `b765dd249cd165358dc5329480c529c76f9218bc`, using read-only `git cat-file`.
- Both the byte comparison and the actual Git production diff show exactly the
  two agreed changes: `src/circuit/prologue_simulator.gd` and
  `src/hardware_foundations/hardware_foundations.gd`.
- Current branch is `codex/gameplay-systems-20261104`; local `main` remains
  `b65a0bd3064888f41c5caeb8d7d0717d2b901658`.

The final source manifest SHA256 at review is recorded in the JSON result.
This review does not authorize or claim a commit, push, release, or main merge.

## Evidence retained exactly

Verified **64 original archived files** byte-for-byte against the original
`.godot` invocation/benchmark directories and standard verifier outputs.
This includes the newly archived ordinary startup record at
`checks/20261105T114738Z`, whose actual process exited 0 without diagnostics.

All original and followed-up diagnostic report/helper/result files match the
respective `/private/tmp` originals. The measurement-phase report remains
separate from the later host-source follow-up; its old one-file scope is not
presented as final two-file scope.

The negative attempts are present with exact original logs, hashes, recorded
exits and diagnostic lists:

| Evidence | Actual retained outcome |
| --- | --- |
| `112423Z` pure recovery on frozen runtime | exit 1; 301 checks / 31 failures |
| `112423Z` first host fixture load | exit -15, `script_error`; compile error retained |
| `112522Z` corrected host fixture on frozen runtime | exit 1; 124 checks / 7 failures |
| `113442Z` stronger caption regression before host fix | exit 1; 142 checks / 2 failures |

The failed fixture load remains distinguished from product failure. The old pure
and valid old-host tests completed without script/parser exceptions.
Early Chinese/English GPU observations remain **144/0**, while the final two
GPU observations remain **158/0**. Their differing test-script hashes and
results are preserved, rather than relabeled as one final run.

The 13-suite standard verifier archive contains import and isolation checks as
well. All archived results pass and complete logs contain no script errors,
engine errors or warnings. The pure recovery result is **308/0**. Final headless
host and six related suites, final GPU and ordinary startup retain their actual
PASS/exit/diagnostic outcomes.

Final invocation simulator and test hashes match current source. The actual
headless and Chinese GPU records predate the `hardware_host_sha256` field;
the checker records that absence rather than inventing a historical value.
Final English GPU `114010Z` and ordinary startup `114738Z` do contain that field,
and both equal the current host SHA256
`abb7d470271ebadd80618c183c31cb15e537b9771e94666754065939bf273ba3`.
The current full source/QA manifest independently binds the final host.

## Images and local references

All **12 PNGs** are present: six final frames and six initial diagnostic frames.
Their actual PNG signatures, 1280×720 IHDR dimensions, byte counts and SHA256s
match the frame manifest. Every final frame also equals its raw QA capture.
This is artifact verification; pixel-level visual judgment belongs to the
separate visual/evidence reviewer.

All **30 local Markdown links** in the receipt's Markdown files resolve,
including the completed plan, current audit, raw invocation records, reviews,
manifests, frame image and diagnostics directory. External links were not
claimed as checked.

## Delivery inclusion note

**26 raw `.log` files still match the repository-wide `*.log` ignore rule.**
Their actual bytes are verified and present in the receipt, but an ordinary
unforced `git add` would omit them. Root must include these exact files in the
delivery scope with explicit force-add or a receipt-local ignore exception.
Their full paths are recorded in the JSON result. No ignore rule or index was
modified by this review.

This is a concrete packaging requirement before delivery, not a failure of the
runtime or stored evidence. The final commit/scope manifest and remote delivery
remain root-owned and were not yet verified here.

## Boundaries

No new engine test or native input was executed by this reviewer. This audit
does not broaden the receipt to Windows, exports, newcomers, audio, long-session
testing or performance acceptance. The original benchmark comparison remains a
correctness comparison; the failed reference diagnostic cannot support a
speedup claim. Source hashes and current evidence establish the bounded state
reviewed here, not arbitrary-input correctness.
