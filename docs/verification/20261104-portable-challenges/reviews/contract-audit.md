# Round 3 — bounded offline challenge contract audit

Read-only source audit by audit_scores, 2026-11-04. No runtime/test edits, Godot,
Git mutation, network access, or player-data reads. Source findings are not new
runtime reproduction. Root owns product choice, integration, and execution.

## Recommended smallest playable contract

Ship one persistent active target per Chapter 4 task (six Game targets maximum),
plus independent session-only Test targets. A target is a recipe + objective +
full-condition identity. It never stores an authoritative cycle/traffic/space
number and never enters GlobalSave or completion. Copy/import is explicit text,
with no network, accounts, names, new rule, or achievement migration.

The existing Board is already the right measurement boundary:
`layout_scoreboard.gd:10-24` hashes task + model + ordered authored cases, then
`_measure` executes every case and verifies the actual trace identity/target.
Expose that existing identity calculation as a pure `condition_id_for(task)`
helper so encoder, loader, and board cannot drift. Do not invent a second case
hash convention or use telemetry's differently prefixed summary hash.

## Small strict code envelope

Suggested transport: `VNB4C1:` followed by one compact canonical JSON object:

    {"v":1,"task":"mixed","model":"layout-memory-1",
     "condition":"<64 lowercase hex from Board.condition_id_for>",
     "objective":"traffic","design":{...}}

Exact root keys: v/task/model/condition/objective/design. No scores, passed flags,
completion, timestamps, build paths, player identifiers, or arbitrary expressions.
`task` must be a Catalog.IDS member; objective exactly cycles/traffic/space.
The condition includes current task constraints, full ordered records/queries,
scratch limit, and timing/traffic targets because those are in Catalog.cases.
The explicit model string must match the current simulator for active import.
Model max80 characters; condition exactly64 lowercase hex. v is integer1.
Code max4096 UTF-8 bytes before parsing; model recipe bounds are far below that.
Leading/trailing text whitespace may be trimmed; no URLs, compressed data, resource
loading, executable source, or OS paths are supported.

Use exact key/type checks BEFORE normalization. Generated code can be canonical
JSON with explicit stable key ordering and integral normalized numbers. If strict
rejection of duplicate JSON keys is wanted without a new parser, require the
trimmed payload to equal canonical reserialization of the fully validated object;
a Dictionary after parse cannot reveal which duplicate keys were supplied. This
also rejects hand-edited/pretty-printed variants with a clear invalid-code result,
while unmodified copy/paste remains round-trip stable. Do not claim a signature or
anti-cheat property: the digest identifies conditions, not a trusted sender.

The transport `design` is task-specific data:
- Non-relocation: exact recipe/strategy/copy_fields/batch fields, all explicit.
- Relocation: exact `orders` object with A and B, each the same strict pure design.
  There is no unexecuted root recipe in the transport. Export resolves any old
  internal fallback into the two actual executed orders. Import reconstructs the
  internal container using Catalog.starter_design() plus those two orders.
  This intentionally preserves the actual recipe_id and both measured traces.

Pure design validation:
- recipe: exact groups/block fields; groups length1..4.
- group: exact fields/order; fields integral0..3, across groups each exactly once;
  no duplicate or missing field, no nested unknown payload. order record/field.
- block integral0..64; batch integral1..64.
- strategy exactly direct/full/batch; native-layout tasks require direct.
- copy_fields integral0..3 with no duplicates, length0..4; non-direct nonempty.
- Integers may arrive as JSON numbers represented by a float but must be finite,
  integral, and in range; never coerce strings or booleans.
- orders forbidden anywhere except the relocation envelope level; nested orders
  inside A/B and unknown root/group/recipe fields reject.
- After strict structural validation, existing Simulator.validate_design provides
  the current semantic guard. After reconstructing the design, Board.build_rows
  must yield one current eligible row; correct-but-target-unmet cannot be a target.

Encoder takes an internal recipe and objective, remeasures it, and emits only the
canonical bounded recipe. Decoder ignores no claimed numeric result because none
is accepted by schema; extra score/cycles/rank/trace fields reject. Imported code
must match the host's current task, model and condition before it becomes active.
It must not automatically navigate/unlock another task or replace current draft.
Restore remains a separate explicit undoable action through the existing host.

## Protected local storage without GlobalSave changes

Suggested new RefCounted store `layout_challenge_store.gd`, retained by the existing
LayoutChapter autoload (a new member only, not serialized in game_snapshot).
Pure codec can live separately as `layout_challenge_code.gd`. These avoid another
project autoload or third-party dependency. Explicit mode parameters bind each
operation; a stale window cannot silently apply a Game operation after Test switch.

Game file: `user://layout_challenges_v1.json`, maximum32 KiB. Suggested exact shape:

    {"schema_version":1,"targets":{
      "mixed":{"code":"VNB4C1:...","title":"My measured target"}
    }}

At most six distinct known task keys; one target per task. title plain text,
0..40 characters, no control characters; it remains local and need not enter code.
Each stored code max4096 bytes; outer task key must equal decoded envelope task.
No saved metrics, win counters, completion evidence, or current-draft mutation.
Test targets use a distinct in-memory dictionary and never read/write the Game
file for a Test pin/import/clear operation. Export is just data; a user may
explicitly paste a Test recipe into Game, where the current workload is freshly
recomputed and no completion is granted. Do not silently migrate modes.

Read behavior must distinguish structural validity from current compatibility:
- Validate the entire root and every nested entry, key/type/count/size and identity
  before replacing memory. Do not skip unknown entries and later rewrite them.
- Future schema/code version, unknown task/field, malformed code, key/task mismatch,
  oversized history or invalid recipe make the file read-only, preserving bytes.
- Structurally supported old model/case identity is stale content: preserve the
  exact code, exclude it from live comparisons, display condition-changed status.
  Never relabel it with the current model. Replacing that task's pin is an explicit
  user action; other saved entries remain intact.
- Matching current identities still require replay and all-case eligibility before
  an entry is displayed as an active target. A valid-looking scalar is irrelevant.
- Loading, listing or measuring writes nothing and awards no progress.

Writes stage a fully validated complete snapshot, use a sibling .tmp, check
open/store/flush/close outcome and atomic replacement result. Preserve original
on failure. Expose ready/read_only/write_failed and last_error, as PersonalRecords
now does. Repeat identical pin/import must permit retry after a real write failure.
To keep failure semantics simple, store changes can commit in-memory only after
successful Game write; the host may separately retain the target for this visit
and label it temporary if persistence fails. Do not display Saved on a failure.
No automatic repair/reset of a read-only file. New file rollback is isolated:
older versions ignore it, GlobalSave remains byte/schema-compatible, and removing
the new feature simply leaves a recoverable sidecar. No player-data deletion.

## Existing validation risks / normalization to avoid at the boundary

1. `layout_simulator.gd:74-97` supplies missing strategy/copy_fields/batch defaults;
   normalized_design drops all unknown top-level fields. A malformed external
   request can otherwise change silently into a legitimate different design.
2. `layout_recipe.gd:15-35` defaults missing block to0 and drops unknown recipe/group
   fields. Strict code must reject extras/missing members before invoking it.
3. `layout_scoreboard.gd:143-160` is intentionally forgiving of internal metadata:
   non-relocation orders are ignored; relocation missing A/B uses Catalog's root
   fallback. It is safe as a measurement boundary after strict import validation,
   but is not by itself a strict external protocol parser.
4. `layout_state.gd:54-67` validates `orders` only for relocation, but normalize()
   iterates orders whenever present. Thus a non-relocation saved design carrying
   malformed orders can pass valid() and reach a typed normalization failure.
   This is an existing source-traced validator mismatch, not introduced by the
   proposed code. External strict parsing must never feed it. A bounded defensive
   fix could reject orders for non-relocation; assess old internal save behavior
   and add a separate regression before expanding this round's scope.
5. `layout_state.gd:71-95` currently salvages valid old draft/named entries and
   recomputes completions. Do not reuse that partial-load policy for protected
   challenge files: the current PersonalRecords full-validation repair is the
   relevant precedent (`personal_records.gd:_valid_saved_history`).
6. `layout_chapter.gd:790-814` trusts the copied visit-local target row's metrics.
   A persisted/imported target must be decoded and freshly remeasured on load/pin;
   never hydrate its row from serialized scores. Existing fresh run comparison
   and strictly negative objective difference can then remain intact.
7. Board.rank_rows silently defaults an unknown objective to cycles. Codec/store
   must reject unknown objective before calling it; do not let typoed codes change
   the challenge meaning.

## Meaningful acceptance

- Real eligible alternatives for all six tasks; transport JSON roundtrip yields
  identical measured per-case trace/recipe signatures, metrics and condition.
- Relocation A/B preserved independently; swapped orders differ, missing order
  rejected; unused legacy root recipe cannot alter emitted identity/code.
- Compare real different-objective winners, tie, improvement and regression; all
  objectives remain constrained by original all-case correctness/time/traffic/space.
- Every root and nested field/type/bound mutation, unknown objective/version/task,
  extra claimed score, oversized text, invalid fields/orders, fractional/nonfinite
  values and stale model/cases reject without a draft, completion, or disk mutation.
- Exact duplicate code import/pin is idempotent; same-target retry after actual
  failed temp open or replace works. Disk contents survive all rejected writes.
- Future/corrupt nested store, over-limit task count and mismatched outer task key
  retain original bytes after a later valid pin; no partial salvage-and-overwrite.
- Save/reopen across scene visits and process-style fresh store instance, then
  replay target. Stale target remains historical/disabled and is never rebranded.
- Game/Test target/draft/progress isolation, including switching mode with a
  dialog open. No network/clipboard reads on entry and no saved result authority.
- UI import pins only; applying its recipe is explicit, one undo step, invalidates
  evidence, preserves current draft and leaves original Run all cases in charge.

This audit does not request a model/target change. It provides a bounded portable
recipe challenge layer over the already deterministic evaluator.
