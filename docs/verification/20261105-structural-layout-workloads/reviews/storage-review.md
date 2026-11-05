# Round7 independent storage review

Reviewer `/root/audit_scores`, 2026-11-05. Assignment is read-only review of the
two stores and the narrow upgrade-fixture repair. Only this report was written.
No project source/test edit, Godot execution, native input, player-profile
access or Git command was performed.

**No actionable source finding was identified.** Strict v1/v2 precedence,
watched source/destination signatures, real first-copy writes, ordered leases
and exact blocked-writer recovery follow the frozen Round7 contract. The
fixture repair preserves the independent canonical-byte checks.

## Reviewed identities

| File | SHA256 |
| --- | --- |
| `experiments/layout_strategy/notebook_store.gd` | `ec23130ca452558f5dce241000205557224a95745161018f336ad88870a36699` |
| `experiments/layout_strategy/challenge_store.gd` | `f00edafcf611eaf382ce650195556ab25fc10e8263b44b10962f7a686a168685` |
| `tests/test_layout_strategy_notebook_store.gd` | `30e5a07966a34ce149241d1a96bf0b3b6e2dbd69add41db752052eca60362554` |
| `tests/test_layout_strategy_challenge_store.gd` | `9a30134ff7d5cacaa98607efa92c085e3dabc4f2d4103c32e7cc89480e9b5db2` |
| `tests/test_layout_strategy_store_upgrade.gd` | `883e7eb34c91af4ddcc5f3026fe28e3488e2462d947fd69d8874fdf48bc3f0fe` |

All five reviewed files match the synchronized QA copy at
`.godot/verification/20261105T051242Z-1f038f6c/project` byte-for-byte. That
directory now contains current integrated source; this review does not treat
its current contents as the historical frozen runtime.

## Precedence and strict input preservation

Notebook `188–233` and Targets `155–200` inspect the current destination first.
Any existing valid v2 is authoritative, including an empty map. Read failure,
directory, malformed or unsupported current payload protects the destination
without consulting v1. Only a missing current payload enables legacy lookup.

The legacy validator uses payload version1 and `Model.LEGACY_SCENARIO_IDS`;
the current validator uses version2 and all six IDs. Whole-file structural,
canonical-JSON and UTF-8 validation still precedes adoption. Notebook state
validation preserves an unfinished but structurally valid draft while refusing
an invalid retained recipe, stale task/model/condition, duplicate names or extra
score fields. Target validation retains a structurally supported stale code
exactly, leaving activation to the controller's actual inspection.

Valid v1 is copied to detached memory with only the root version lifted and
`copy_pending=true`, including an empty v1 map. Protected v1 clears the
proposed committed map and exposes `origin=legacy`, `copy_pending=false`.
Neither read path creates payloads or writer directories. Custom current paths
do not implicitly reach into a default profile; an explicit legacy override is
required. Simple normalized source/destination aliases are refused.

## Write and recovery protection

Notebook `265–286` and Targets `232–253` bind both configured paths and their
loaded content signatures. The source is watched even when it was originally
missing, until the first successful v2 replacement. Source appearance,
deletion, replacement, unreadability, destination appearance and configured-path
redirection therefore refuse stale writes. Once v2 commits, legacy lookup and
ownership are disabled so rollback and upgraded histories remain independent.

Notebook `33–92` and Targets `32–91` validate before writing, then acquire the
old-format writer before the current writer. A second digest check occurs
under the leases. The no-op shortcut requires `not copy_pending`, so an
unchanged or empty first migration passes real temporary write, flush,
readback, strict decode and replacement. A pristine non-migration empty no-op
still creates no payload, matching the existing contract.

Both stores recheck exact ownership and both signatures after preparing the
temporary file and before replacement. Failed acquisition releases any
earlier lease; open/readback/rename/conflict/ownership-loss paths release their
remaining owned leases and never adopt the proposal as committed. The reverse
release order is consistent. Replacement owner records survive because the
shared Lease releases only its own token. Successful replacement alone updates
the committed snapshot, current signature, origin and pending state.

Notebook `95–118` and Targets `94–117` recover `_blocked_writer_path` only if
it remains one of the bounded writer paths. A source or destination contention
is recorded at the acquisition or ownership check that actually failed.
Recovery checks data before and after conservative native stopped-owner
recovery, releases the temporary ownership and never writes either payload.
A separate save must reacquire both leases and recheck data. Unknown/live
owners and changed payloads remain protected.

The implementation keeps the declared cooperative-local boundary. It does
not claim arbitrary-writer compare-and-swap, power-loss durability, symlink
security or automatic history merging.

## Upgrade-fixture repair

The repair in `test_layout_strategy_store_upgrade.gd:84–87` compares both inputs
after the same JSON value round trip. It removes the irrelevant difference
between integral GDScript integers and JSON-parsed floats in semantic snapshot
comparisons. The test inputs are bounded JSON values; this helper is not part
of production storage validation.

More importantly, `240–265` retains independent byte and provenance checks:

- The captured fixture must identify the exact frozen base and contain the
  actual v1 string.
- The strict legacy normalizer must accept that parsed snapshot without
  changing its JSON value structure.
- `canonical(original) == original_text` still requires the normalized
  integer form to reproduce the actual old-store bytes exactly.
- Reading must lift only the root version, create no v2 or lease, and return
  explicit pending-copy metadata.
- An unchanged explicit write must create exact canonical v2 bytes.
- The original v1 byte buffer must remain unchanged, both leases must be
  released, and a fresh reader must select the actual current payload.

Thus the narrow repair does not replace the byte gate with a permissive
semantic comparison. Duplicate keys, padded/noncanonical JSON, float spelling
and extra fields remain protected by production decode and other tests.

The fixture remains193217 bytes, SHA256
`d32b7c69a76d2a8a941f7f433a44f2206f6a05a7248c9bb40add54b445e5c289`,
with base `e1e27db0e1fd3bdcde211b6f2f22ca059c19ebd8`. Its old Notebook and
target strings remain4519 and1753 UTF-8 bytes. Earlier controller review
inspected the frozen producer and corrected capture; this review verified the
same immutable fixture bytes.

## Coverage and runtime evidence inspected

The upgrade suite covers both stores symmetrically: maximal/sparse legacy,
unfinished serial drafts, stale target codes, strict precedence, malformed
sources, missing-source watch, late source/destination changes, actual
open/rename refusal, denied readback, clear/retry, live source/current leases,
owner replacement, exact stopped-owner recovery, abandoned owner retention,
orphan temporaries and independent partial migration. Existing suites also
retain six-target/48-named-plan persistence, stale-reader conflicts and
current-file failures. No cached metrics or Trace is persisted.

I read the following complete root-generated logs and their result manifests:

| Root execution | Observed result |
| --- | --- |
| `headless/20261105T060756Z/test_layout_strategy_notebook_store.log` |414 checks,0 failures, exit0 |
| `headless/20261105T060756Z/test_layout_strategy_challenge_store.log` |292 checks,0 failures, exit0 |
| `headless/20261105T060756Z/test_layout_strategy_store_upgrade.log` |410 checks,5 fixture comparison failures, exit1; retained historical failure |
| `headless/20261105T061037Z/test_layout_strategy_store_upgrade.log` |410 checks,0 failures, exit0 after the narrow repair |

All paths above are relative to
`.godot/verification/20261105T051242Z-1f038f6c/`. The passing upgrade log has
no skip, parser diagnostic or error line. These are inspected root executions,
not tests launched by this reviewer.

Real separate-process recovery, frozen-old-runtime rollback, native input and
other-platform acceptance remain separate root evidence. This source review
does not replace those gates. No source repair is requested; review ownership
is released.
