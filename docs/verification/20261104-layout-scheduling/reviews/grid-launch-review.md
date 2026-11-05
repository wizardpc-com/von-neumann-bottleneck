# Round 4 production grid and launcher review — 2026-11-04

Reviewer `/root/audit_scores`; READ-ONLY assignment in
`.godot/collaboration/round4-tasks.md`. No source/test edit, Godot execution, Git
mutation or player-data access. This review did not repeat the model-test review.

**Conclusion: no blocking defect found in the current accepted grid evidence or
the current layout_strategy launcher entry.** The finite sample supports real
response/total/traffic/scratch tradeoffs. Launcher isolation is configured before
any engine process uses the copied project. Actual fresh launcher/GPU acceptance
remains root's separate execution responsibility.

## Evidence and source binding

Read the complete grid script, current launcher and its diff, then the accepted
receipt:

`docs/verification/20261104-layout-scheduling/strategy/20261105T005822Z/`

- Invocation: pinned Godot4.7.1 under the existing copied project
  `.godot/verification/20261105T005513Z-6cc70bb5/project`.
- Explicit profile:
  `VonNeumannBottleneckChecks/20261104-round4/production-grid/20261105T005822Z`.
- Receipt reports exit0, no diagnostics, restored settings; complete raw log
  states595 candidates,90 replay executions,12770.009ms.
- Parsed result has595 rows, all correct, no recorded failures.
- All eight invocation SHA256 bindings match the current measured model/memory/
  Trace sources plus archived grid. The archived grid equals the live ignored
  grid byte-for-byte.

Review identities:

```text
2954adf29f88ccafa0589bf90d8d5a9a3853df8a25aa50f4169771d2b11a8595  scripts/run-experiment.py
d52a60c6703e4f7a9cf63acac3ff63f82feec35373f810f0e0271295ffdb76e8  round4-production-grid.gd
f30a9d061aa335141d42619408b09e8fcc8a5a92f8d4bb22b821b452054e9f9b  strategy/20261105T005822Z/results.json
```

## Finite domain and interpretation

Seven physical plans are explicitly sampled: source only, plus each of `[0]`,
`[0,3]`, `[1,2]` copied once in record-major or field-major layout. Five query
tile lengths are1,2,4,8,17. Known batches use declared groups; serial uses1.
No old completion thresholds, hidden bonus or fabricated delay enters the grid.

| Workload | Delivered in UI | Plan combinations | Nondominated metric classes |
| --- | --- | ---: | ---: |
| scan_batch | yes | 140 | 4 |
| scan_serial | yes | 35 | 2 |
| mixed_batch | yes | 175 | 5 |
| mixed_serial | yes | 35 | 2 |
| scan16_batch | no; additional probe | 175 | 6 |
| scan16_serial | no; additional probe | 35 | 2 |

The total is595 combinations, of which385 belong to the four delivered
workloads. The extra210 are explicitly marked `shipped:false`. They test a
bounded16-job extension using the same pure model, not two additional playable
workloads.

“595 combinations” must not become “595 distinct strategies”: record/field
layouts for a single copied field are equivalent, and several tile/group
choices tie. The frontier groups equal metric vectors. Four dimensions are
compared independently with at least one strict improvement; there is no
weighted best score. It is a finite-sample frontier, not a global-optimum proof.

Concrete delivered choices are source-only ready scan307 first/2456 total/
2176 RAM B/0 copy B versus fused531/552/272/0, and serial direct307/2456/2176/0
versus retained temperature copy557/1362/980/80. Mixed serial also has a real
direct341/2784/2208/0 versus retained hot-pair825/2404/1624/144 tradeoff.

## Independent checks performed on the archived JSON

Using Python only, without calling Godot or the new model:

1. Recomputed nondominated metric sets from every correct candidate, independently
   of the report's stored frontier. All six matched exactly.
2. Recomputed each plan SHA256 from canonical model plus effective plan, removing
   dormant copy recipe/fields only for source-only. All595 matched.
3. Recomputed every full condition SHA256 from the archived task, experimental
   model and explicit existing memory constants/policies. All595 matched.
   There are exactly six distinct condition IDs;16-job probe rows do not mix
   with8-job delivered rows despite sharing their base scenario ID.
4. Checked all response arrays: first metric equals public job0, maximum response
   equals makespan, batch admissions are all0 and serial admissions exactly
   follow preceding responses. All595 matched.
5. Independently checked integer cost residual
   `cycles - RAM_bytes = 2Q + O + 6M`, deriving query values Q, logical output
   count O and copied words M solely from the archived task/plan. All595 matched.
   The sampled single-group copy layouts also have exact line-aligned
   `ceil(4M/16)*16` peak scratch; all595 matched.

The grid itself checks actual output vectors, fill-based total/traffic
identities, actual output/write event counts, response/admission events,
readiness and selected full-Trace repeat/JSON signatures. It calls the shipped
`Model.evaluate()` instead of the earlier proof subclass. No telemetry or
cached scalar supplies a score.

A failed future grid must never be accepted merely by reading its `frontier`:
the script computes frontiers from collected rows, and correctness is enforced
by overall failures/exit status. In this accepted receipt every row is correct,
the failure list is empty, the file fully parses and counts match. This is an
evidence-consumption boundary, not a current receipt defect.

## Launcher isolation and entry safety

The new entry only adds `layout_strategy` to the allowed experiment list, rejects
the older replay routes for it, points the copied project's main scene at the
standalone lab, and adds accurate session-only launch text. The normal fallback
scene mapping also resolves to `res://experiments/layout_strategy/lab.tscn`.

The existing safety path remains intact:

- `--profile` and `--journey` reject layout_strategy before engine invocation.
  The new explicit replay rejection also runs before engine invocation.
- Engine version is checked before project preparation.
- Tracked/untracked nonignored source is copied into a newly generated
  `.godot/experiments/<id>/project`; source project.godot is never rewritten.
- Symlink files are rejected. Existing source override.cfg or custom-user-dir
  settings are rejected before the engine uses the copy.
- The copied settings receive
  `config/use_custom_user_dir=true` and
  `VonNeumannBottleneckChecks/experiments/<id>` before editor import, and retain
  those settings for launch/F5. Thus all existing autoloads use the isolated
  directory from initialization.
- The new lab's scene-level QA-directory guard remains a second guard, not the
  primary data-isolation mechanism. A direct source-scene launch could already
  initialize autoloads; published instructions must keep using the launcher.
- No candidate profile, candidate-save, journey flag, scene registration or
  campaign navigation is granted by this new path.

Current source preconditions were checked: exactly one application section and
one main_scene line; no custom-user-dir settings; no root override.cfg; actual
lab.tscn exists. Therefore the targeted replacement enters the intended
standalone lab for this checkout.

I executed four negative CLI cases with `--godot /__must_not_execute__`:
layout_strategy plus `--profile review-only`, `--journey`, `--replay lab`, and
`--replay candidate-proxy`. Each exited2 with an argparse error, before any
attempt to invoke the nonexistent engine or prepare a project. No Godot ran.

Remaining acceptance: root should retain the actual prepared-project settings
and ordinary launch/GPU evidence. Static isolation reasoning and these rejected
argument checks do not by themselves establish a visible playable window.
