# Round7 storage implementation handoff

Date: 2026-11-05. Owner: `/root/review_records_final`.
Implementation follows `.godot/collaboration/round7-implementation.md` and
`docs/exec-plans/active/structural-layout-workloads-20261105.md`.

All five owned source/test files are ready for root integration and ownership
is released with this report. No Godot run, native input, Git mutation, network
operation, ordinary player-profile access, UID generation, or edit to another
owner's files was performed by this child.

## Changes

- Both stores default to their independent `layout_strategy_*_v2.json` sidecar.
  Existing v1 payloads are read-only sources; no code path writes, renames,
  deletes, or backfills a v1 payload.
- Added `DEFAULT_PATH`, `LEGACY_PATH`, `legacy_path`, `origin`, and
  `copy_pending`. Read/write/recovery results retain the existing fields and
  append the two status fields. Default lookup requires the exact current
  default path; custom current paths do not implicitly read profile v1 data.
- `normalize_snapshot` strictly validates version2 and six current IDs.
  `normalize_legacy_snapshot` independently validates version1 and the literal
  original four IDs in `Model.LEGACY_SCENARIO_IDS`. Complete nested validation,
  canonical JSON, UTF-8, stale Notebook protection, supported stale code
  retention, 128KiB/32KiB bounds, and eight retained plans remain enforced.
- Existing v2, including an empty map, wins without looking at legacy.
  Protected v2 never falls back. Missing v2 plus valid v1 returns a detached
  version2 proposal, preserving every other input and marking an explicit
  pending copy. Protected v1 adopts no partial state. Reading creates neither
  a payload nor lease directory.
- Source and destination byte signatures are watched until an actual first
  v2 commit, including an initially absent source. First-copy saving acquires
  the exact old store lease, then current store lease, and rechecks data and
  ownership before replacement. Every acquired lease is released on success
  and failure. A lost/replaced owner is preserved rather than removed.
- Unchanged first copy, including an empty legacy target map, must pass
  temporary write/readback/replacement and create a real v2 file. Successful
  commit clears pending/source watch; subsequent histories stay independent.
- Recovery remembers the exact bounded old/current writer that blocked saving.
  It uses the existing conservative stopped-owner check, changes no payload,
  and cannot bypass changed source or destination bytes.
- Existing store suites now exercise current version2, six target entries and
  48 Unicode-named kept plans; unsupported-version fixtures use99. Existing
  envelope version1 assertions remain unchanged.

## New migration suite

`tests/test_layout_strategy_store_upgrade.gd` covers both stores with isolated
fixture paths and an explicit QA-profile guard:

- Exact default/custom/explicit path selection and simple path alias refusal.
- Original four-ID v1/current v2 separation, maximal and sparse source maps,
  dormant choices and unfinished serial drafts without silent correction.
- The actual old-runtime `notebook_v1` and `targets_v1` strings from
  `tests/fixtures/layout_strategy/legacy-scheduling-v1.json`, anchored to
  base `e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8`. It checks version-only lifting,
  actual unchanged-copy creation, exact old bytes, and fresh-reader reopening.
- Valid, empty, corrupt, unsupported, unreadable and directory precedence;
  malformed nested/source structures, unknown new IDs in v1, duplicate keys,
  noncanonical spelling, invalid UTF-8, file bounds and stale cases.
- No write/lease on read, detached proposals, required unchanged/empty first
  copy, fresh missing-source defaults and subsequent independent histories.
- Source replacement/deletion/appearance/redirection/read denial, destination
  appearance, and changes injected during temporary preparation.
- Actual failed open/rename and denied readback, clear-to-empty failure,
  preserved source/proposal, exact changed retry, and lease release.
- Real held old/current Lease objects, refusal to steal live owners, release
  of an earlier lease when the next acquisition blocks, and exact retry.
- Both old/current owner replacement during temporary preparation; save
  refuses, remembers the exact path, preserves replacement ownership and
  releases the other still-owned lease.
- Conservative unknown/stopped-owner recovery, genuinely changed write after
  recovery, and changed-source recovery refusal. Unsupported native checks
  explicitly exercise refusal and print a skip instead of claiming recovery.
- Unadopted orphan temporaries and independent Notebook/target migration.
- Unchanged official progress and all default old/new sidecar bytes.

## Verification actually performed

- Read current implementation, relevant model/lease/controller contract and
  owned tests. Inspected the scoped tracked diff and current Git status.
- `git diff --check -- experiments/layout_strategy/notebook_store.gd
  experiments/layout_strategy/challenge_store.gd
  tests/test_layout_strategy_notebook_store.gd
  tests/test_layout_strategy_challenge_store.gd`: exit0, no output.
- Python UTF-8/trailing-whitespace/final-newline scan of all five authored
  files: exit0, no issues.
- Read-only inspection confirmed the frozen old fixture contains the exact
  base identity, four old IDs, and canonical old-store strings of4519/1753
  UTF-8 bytes. The test will validate these through the Godot stores.

No engine import, compile, suite execution or process acceptance has been
performed by this child. These results are source/static checks only.

Root should run:

1. `test_layout_strategy_notebook_store`
2. `test_layout_strategy_challenge_store`
3. `test_layout_strategy_store_upgrade`

Root owns real cross-process/rollback, controller/UI and final byte-binding
acceptance. The implementation retains cooperative-local protection only;
it makes no arbitrary-writer CAS, power-loss durability or remote-trust claim.

## Released file identities

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `experiments/layout_strategy/notebook_store.gd` | 431 | `ec23130ca452558f5dce241000205557224a95745161018f336ad88870a36699` |
| `experiments/layout_strategy/challenge_store.gd` | 376 | `f00edafcf611eaf382ce650195556ab25fc10e8263b44b10962f7a686a168685` |
| `tests/test_layout_strategy_notebook_store.gd` | 480 | `30e5a07966a34ce149241d1a96bf0b3b6e2dbd69add41db752052eca60362554` |
| `tests/test_layout_strategy_challenge_store.gd` | 485 | `9a30134ff7d5cacaa98607efa92c085e3dabc4f2d4103c32e7cc89480e9b5db2` |
| `tests/test_layout_strategy_store_upgrade.gd` | 587 | `4cc7affc1191b72017e4efd532cf9ae198e84585f72711f4f7262af70758fbd5` |
