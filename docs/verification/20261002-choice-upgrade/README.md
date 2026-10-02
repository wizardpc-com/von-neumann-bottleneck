# Chapter 2 grouping-choice upgrade — 2026-10-02

The catalog-only 0/1/2/4 choice expansion changed the whole-chapter workspace
fingerprint despite retaining all existing programs, outputs, costs and goals.
The state accepts only the exact old fingerprint while its current fingerprint is
the exact grouping-choice revision. Any later model change disables this alias.
Workspaces retain drafts/configuration and the original version on the next save.
Observations always rerun through the simulator; saved numbers are not evidence.
No new completion or save schema is introduced.

Fresh Godot 4.7.1 isolated verification:

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot --suite test_chapter_workspaces --suite test_locality_chapter_ui --suite test_simulation --suite test_final_convergence
```

All four suites pass, with full logs in this directory. The workspace test also
checks a different future fingerprint rejects the alias and tampered saved metrics
are discarded. On that isolated project, run `tests/fixture_locality_choice_upgrade.gd`
three times using the same isolated user directory: `-- --writer`, then twice with
no arguments. All three processes pass. The first writes a synthetic old-version
snapshot with invalid draft text, a valid applied program, selected group size and
false metric 1. Readers preserve the draft/choice and recompute 210 cycles, keep
completion empty and retain the original workspace version after writing.

These are automated fixtures, not an actual player's save or a native playthrough.
The alias must be re-audited if any fingerprint source changes. Exported-package
parity remains part of the later release gate.
