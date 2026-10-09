# Current runtime Linux CI — 2026-10-09

[Run 37884348935](https://github.com/wizardpc-com/von-neumann-bottleneck/actions/runs/37884348935)
completed successfully at commit `d5dd5d4be778a48d4762cae6da7d9bc27d6823e6`
on development branch `codex/mac-second-act-20261005`. Runtime is unchanged from
`f90597bf999a9fa09b08ac89fa0b4512f5835de6`. This was the existing push-triggered
run; root inspected it without dispatching or rerunning any job.

Ubuntu 24.04.5 x86_64 used the checksum-verified official Godot
`4.7.1.stable.official.a13da4feb` and repository resources. Fresh isolated import,
user-directory probe and all 143 headless suites passed. The current disabled-focus
suite passed all 22 checks. All 145 raw artifact logs were inspected for PASS,
errors and skips: no script errors, failures or skip lines; four previously recorded
desktop anchor warnings remain. Branding, playtest-report checks and the Python
storage/receiver/community jobs also passed. Community's five tests include two
receiver tests already run separately; do not treat them as ten distinct tests.

`run.json` records exact commit/job identity, `full.log` retains the complete CI
log, and `artifact/` retains all original per-suite text files before their seven-day
remote expiration. `summary.json` states counts and boundaries. `SHA256.json`
covers payload bytes. The workflow reports artifact ID `11596345599` and compressed
ZIP hash; that reported ZIP hash is not a local recomputed archive hash.

CI action Node deprecation advisories are retained in the full log. Neither they
nor the known Godot anchor warnings failed either job. No workflow/dependency change
was made during this audit.
The raw four warning lines retain their original trailing spaces, reported by
`git diff --check`; authored documents have no whitespace errors.

The connector returned an empty run list; explicit `gh run list --commit <sha>`
located the actual live run. Root then used `gh run view 37884348935 --repo
wizardpc-com/von-neumann-bottleneck --json status,conclusion,headSha,jobs,url`,
`--log`, and `gh run download ... --name isolated-godot-results` to inspect/save it.
Remote branch inventory showed no new branch content requiring integration.

This extends current-runtime regression evidence to Linux. It does not establish
native Mac input, earned Representation2–5/Service/original40 routes, human novice
understanding, listening/artistic/device/Windows or distribution acceptance.
The exact frozen Mac attempt still reported a locked Mac and accepted no native
input. Sol's read-only continuation/modal/rebuild audit found no new concrete
defect; that is not native acceptance. No repeated local tests, export or speculative
source change was performed. The broader objective remains active.
