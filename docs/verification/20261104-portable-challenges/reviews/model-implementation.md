# Round 3 model/store implementation — ready for root verification

Owned files are implemented and stable; root may copy/run. No Godot/Git mutations
or player-data reads performed by audit_scores.

- NEW src/layout_chapter/layout_challenge_code.gd
- NEW src/layout_chapter/layout_challenge_store.gd
- NEW tests/test_layout_challenge_code.gd
- NEW tests/test_layout_challenge_store.gd
- layout_scoreboard.gd: ONLY static condition_id_for extraction used by build_rows.

Public APIs exactly follow .godot/collaboration/round3-implementation.md.
`inspect` wrong_task failure retains decoded task/code/challenge/design metadata.
Current-incompatible model/condition and ineligible failures likewise retain
structurally decoded metadata; structural decode failure returns ok/reason only.

Codec generated code is VNB4C1: + canonical JSON, max4096 UTF-8 bytes. All six
fields and every nested recipe field are exact; missing defaults, unknown fields,
score claims, duplicate keys and noncanonical spelling reject. Relocation encodes
only actual A/B and reconstructs its inert root with the existing starter. Every
encode/inspect recomputes all-case eligibility. decode alone permits supported
old identity so existing targets remain recoverable.

Store lazily loads only on Game methods; Test is independent in-memory. Exact
new snapshot shape and canonical spelling are required (also rejects duplicate
stored keys); max6 targets/32768 bytes. Entire nested history is validated before
assignment, stale supported code retained verbatim, unseen external file content
changes checked before writing and again after temp flush. Game memory commits
only after successful atomic replacement. Identical pin/clear retries work.
Failure reasons include mode/task/title, codec reason, read/format/size/version,
changed/write/replace; storage status is ready/read_only/write_failed.

Tests prepared (NOT YET RUN): real eligible traces for all6 tasks/all3 objectives,
immutable inputs, exact per-case metrics/trace IDs, actual eligibility, A/B and
unused-root behavior; nested/type/default/claimed-score/size/version mutations;
stale decode vs inspect and wrong task; all6 persisted/restarted targets, exact
bytes, detached results, Game/Test isolation, nested corruption and old identity,
external change/create/delete detection, actual temp-open failure and retry,
actual rename failure via test subclass routing OS rename to an existing nonempty
directory, then identical pin/clear retry. GlobalSave snapshots remain a tested
non-mutation assertion.

No simulation/target changes. No title/score/source/path transported. No new
project autoload or GlobalSave changes. Root integrates retained Store instance.
