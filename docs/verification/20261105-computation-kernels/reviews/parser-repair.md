# Round9 final receipt-parser repair

Owner `/root/audit_scores`, 2026-11-05. F1 from
`/private/tmp/vnb-round9-final-harness-review.md` is repaired.
Only `scripts/benchmarks/computation/compare.py` and `test_compare.py` were
edited. Both files are released to root.

## Change

`compare.read()` now uses a strict `object_pairs_hook`. A repeated JSON object
key raises `ValueError` at any nesting depth, before receipt/schema comparison.
The same loader handles ordinary JSON and decompressed gzip JSON.

The existing CLI error path catches this exception, reports `passed:false`
with a concise duplicate-field error and an empty case list, and exits1.
No speed ratio or time-reduction field is published. Both input files can
contain the same malformed duplicate fields and still fail closed.

No runner, snapshot, adapter, runtime, timing sample or original benchmark
receipt changed. The new validation concerns offline receipt ingestion;
engine retiming is unnecessary. Root will rerun the three valid sealed
comparisons using this final parser.

## Fresh verification

```text
python3 -B scripts/benchmarks/computation/test_compare.py
.....................
Ran 21 tests in 0.728s
OK
```

The new test method exercises six cases: plain JSON and gzip, each containing
duplicate top-level `failures`, nested process `returncode`, or nested process
`diagnostics`. In every case it verifies both the loader exception and the
actual comparator CLI's exit1, JSON failure verdict, empty cases, absence of
timing ratios and absence of a traceback. The previous20 tests still pass.

Inspected the complete test result, both edited regions and shared status.
`git diff --check` produced no issues. These benchmark files are still in an
untracked directory, so ordinary `git diff` cannot display their changes;
explicit owned-file whitespace/conflict-marker checks also passed.
Unrelated changes were preserved. No Godot, Git mutation or production file
edit occurred.

## Released byte identities

| File under `scripts/benchmarks/computation/` | SHA-256 |
|---|---|
| `compare.py` | `0a615f9e1ba14c2c89b5f6f85fa7f46be4d0f3323b47d9a52846e9defed4293e` |
| `test_compare.py` | `aa84998bbae8357096f52a15cb58b26bc09313a0b2447b035454cbd83f7a774d` |

All other final-review evidence boundaries remain as documented. This repair
does not itself make a new candidate-performance, full-regression or
cross-platform acceptance claim.
