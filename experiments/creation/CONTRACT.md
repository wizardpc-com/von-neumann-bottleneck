# Continuous signal machine v1

The three modes share four symbols (integers 0–3), one frozen finite-context model,
and one sequential machine. No UI clock, ordinary wire length, or host file IO enters
the simulation. All runs begin with an empty automatic rule-row cache.

`model.gd` static API:

- `default_machine()` returns `cpu_ops_per_cycle`, `bytes_per_cycle`,
  `request_cycles`, `memory_bytes`, `cache_rows`.
- `learn(examples, order, machine, parent = "")` returns `ok`, `model`, `events`,
  `cost`, `error`. Each example is an independent array; order is 0, 1, or 2.
- `validate(model)` returns an empty string or an error code.
- `canonical_bytes(model)` / `from_bytes(bytes)` encode/recover the frozen rules.
- `identity(model)` is the SHA-256 of canonical bytes.
- `predict(model, prefix)` returns `ok`, `symbol`, `counts`, `context`, `fallback`,
  `events`, `error`. Its only information inputs are the model and revealed prefix.
- `generate(model, initial, length, seed, sampler, machine)` returns `ok`, `output`,
  `events`, `cost`, `recipe`, `model_id`, `error`. Length is total output length,
  including the seed, and must exceed the seed length so the model emits at least
  one symbol. Sampler is `weighted` or `max`; PRNG is Park-Miller v1.
- `summarize(events, machine, peak_bytes)` fills event cycles and resolves automatic
  LRU row access, returning `total_cycles`, `cpu_ops`, `transfer_bytes`, `peak_bytes`.

Events contain `phase`, `kind`, `ops`, `bytes`, `cycles`, and actual operation detail.
`rule_read` names its row; a cache hit has zero bus bytes. CPU work shares a continuous
budget within each named phase: each event receives the increment of
ceil(cumulative phase ops / CPU throughput). Bus work remains sequential:
ceil(bytes / bandwidth) + request overhead for each nonzero transfer. A model load
clears the automatic row cache. `transfer_bytes` includes RAM rule accesses and channel packets;
`packet_bytes` separately states the actual end-to-end packet size.

Models contain `version`, `order`, sorted rows, `source_digest`, full `examples`
snapshots, and `parent`. Canonical predictor bytes include version, order, rows,
and the 32-byte source digest. Full examples and parent are provenance metadata:
they are saved in recipes, not needed by the receiver and not sent twice. Every
training symbol updates all available suffix lengths independently; examples are
never joined or wrapped. Integer counts are bounded at 65535. The modeled workspace
stores one byte per unpacked symbol and reserves 11 bytes per occupied cache slot;
channel symbols are packed into two bits. No memory overflow silently removes rules.
Unknown model/row fields are rejected; parent is empty or a canonical model digest.

`codec.gd` static API:

- `encode(symbols, model, machine, codec = "predictive")`: `ok`, `packet`, `events`,
  `cost`, `metrics`, `error`. Encode includes channel transfer.
- `decode(packet, machine)`: `ok`, `output`, `model`, `events`, `cost`, `error`.
  No original, external model, asset lookup, or task identity is accepted.
- `run_transport(symbols, model, machine, codec = "predictive")`: both halves,
  combined `events`, `cost`, `metrics`, `packet`, `output`, `lossless`, `model_id`.
  It does not include learning cost; callers retain and show the previous preparation.

RAW and predictive use the same two-bit symbol language and the same packet header.
Predictive sends a real model, min(order, length) seed symbols, then one match bit
per symbol and two correction bits on a mismatch. The receiver feeds recovered
truth into history. Packet v1 has a 20-byte header, packed payload, and SHA-256
integrity trailer. Declared lengths, versions, reserved bytes, padding, model rows,
and integrity are checked before decoding. Empty input is legal. Bounds are 4096
symbols per sequence and 16 independent training examples.

Generation feeds each output into context without training. The recipe contains
the full immutable model/example snapshots, machine, seed context, sampler/PRNG
versions, random seed, and length. The application separately saves the chosen
output snapshot. There is no correctness target or aesthetic pass score in this API.
Weighted sampling subtracts one from each Park-Miller state, rejects the incomplete
upper bucket, and uses the remaining integer modulo the total count. Every random
advance and rejection is recorded; rendering has no access to this random state.


Application completion and prediction residency
----------------------------------------------

Displayed preparation belongs to the measured result. Ordinary generation carries
its complete learning record; saved snapshots/replays use the protected work's
record and transport uses its recorded preparation. Revisiting B after keeping A
or learning C must retain B's preparation and show B's model identity. Prediction
without a preparation snapshot may display the current learning record only when
its model identity matches the frozen prediction model. Viewing evidence never
changes protected works or charges preparation again.

Explicit saved-work snapshot/replay views own the visible output even when a
prediction task retains an unfinished or completed round. Viewing a work does not
discard that round; Commit/Reveal returns to its own frozen prediction evidence.

G1 observes a legal generated result. G2 denotes the player's confirmed selection;
G3 preserves that actual chosen work/recipe. One successful transactional Keep can
complete G2 and G3. Optional fixed-seed comparison explains interventions but is not
a required count or aesthetic gate; arbitrary output differences never substitute
for confirmation. Prior v1 G2 generation supports preserve earned progress after
recipe validation, without retroactively certifying controlled intervention.

Prediction workspace is canonical model bytes + 2 bytes per sequence symbol +16
bytes, plus11 bytes per cacheable row capped by configured capacity. Memorization
uses its separately documented position-copy workspace. New prediction costs use
the bounded rule table just as learn/generate/codec do. Saved prior full-capacity
prediction costs are accepted only after exact replay of all fields, sufficient
recorded memory and one consistent accounting bound for the entire round. This
narrow compatibility rule does not accept altered cycle/operation/transfer costs.

Personal-work deepening (2026-10-09)
-----------------------------------

G2 still records confirmed choice, not a causal or aesthetic certificate. Its
optional `comparison` envelope uses `controlled-design-v1`: two full immutable
`{recipe, output}` snapshots. Both recipes are re-learned/replayed on loading.
Seed, initial passage, length, machine and implementation versions must match;
exactly one passage, history order or sampler is changed. A source digest change
without changed rule rows/order is not structural evidence. Equal outputs remain
valid design observations; only actual different output establishes an observed
effect for that pair. The first difference exposes its recorded contexts/counts;
later differences inherit changed feedback and are not independent causal tests.

Legacy unextended G2 supports retain their original choice/generation provenance.
An ordinary later Keep cannot erase an existing comparison receipt. Work IDs,
training snapshots, mapping and recipes remain unchanged. Unknown comparison
versions preserve validated works read-only. Older binaries may reject the new
optional support or check-v2 identity; do not open the extended profile in an
older binary expecting write compatibility. No automatic migration is performed.

`practice-v2` and `check-v2` are separate authored streams of the public ABAC
family with rare BA→D exceptions. They reuse the same prefix-only frozen model
calls and cost events. `check-v2` has an independent persisted seen flag, set at
first reveal. Legacy check-v1 streams and supports are unchanged. These small
fixed materials demonstrate bounded uncertainty, not generalization guarantees.

C3's public orders share the exact1536-symbol source and a player-learned model;
only CPU throughput differs (1/64 operations per cycle). Deadlines240000/223000
cycles apply to the measured complete transport, including encode/decode/model
loading/channel work. Preparation was already performed and is disclosed
separately. Orders accept any actual lossless path meeting the stated deadline;
the UI does not impose a particular codec. Session-only delivery receipts do not
replace historical C3 completion evidence or silently award a new certificate.

Saved-work exhibition consumes detached saved output and host-validated replay
records. `light-trace-v1` uses16 fixed columns and ordered revealed cells;
`light-shapes-v1` remains selectable with its original interpretation. Viewing
mapping is disclosed separately from saved mapping. Cursor, playback tempo and
reduced-motion/static view are presentation state only. No extra model, PRNG,
score, cost or persistent write is performed by the renderer. The host locates
the corresponding replay event or forks the same protected work identity.
