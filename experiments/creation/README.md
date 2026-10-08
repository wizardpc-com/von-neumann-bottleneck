# Compression → content prediction → creation

An offline candidate in one continuous light-pattern workbench. Four symbols use
both shape and color; static viewing is complete without audio. This is a bounded
context-count model, not a claim about general intelligence or Yi's origin.

## Play

From the repository root with Godot 4.7.1 stable:

```sh
python scripts/run-experiment.py creation --godot <Godot-4.7.1> --profile Creation-20261008 --journey
```

Open the journey map and locate **Compression · candidate**. The three new regions
contain nine units. Recommended links connect Representation to compression,
content prediction and creation without changing the old forty tasks, Service
ending, or optional address prediction. Omit `--journey` to open the workbench
directly. Reusing the profile resumes its draft and works; a different profile
starts independently. `--prepare-only` produces an imported runnable project copy.

Choose visible examples and memory, learn explicitly, then send RAW or a predictive
packet. Inspect a restored cell and its correction. Compare both representations;
change the machine to examine cost conditions. Explicitly connect the same rules
to sealed input, commit a prediction, then reveal its truth. Practice, a training
passage, fixed-position memorization, and a frozen check have different labels.
Seen check answers remain seen. Connect output feedback to generate, adjust the
recipe, and name a work you choose to keep.

**Play snapshot**, **regenerate recipe**, and **fork** are distinct actions. A work
contains actual symbols and a complete model/example/machine/PRNG recipe. Saving
does not rank beauty. Identical and repetitive works are legal. The work shelf is
bounded to twelve entries and refuses overflow instead of deleting older work.

## Controlled creation comparison

Generate an actual work, then **Pin A** (also on G2's action row). Pinning keeps a
full in-memory snapshot and locks seed, initial passage and length. In Examples /
history, change one passage, learn explicitly, and generate B. A is unchanged by
later learning, generation, playback, language changes or navigation. End the
comparison before pinning a new A; this temporary pair does not survive leaving
the workbench/restarting and is not included in Save draft.

Creation recipe and Measurements show actual changed conditions, including which
passages were added/removed/replaced and the first differing cell (one-based).
Minimum passage-edit count avoids counting shifted survivors as additional edits.
Changes to several examples/parameters are labelled multi-condition; derived model
identity is not counted again as a second control. Equal output is a valid observed
result, not a failed artwork. Seed-only variation is never described as evidence of
an intended effect. Underlines on the current output mean differences from A, not
errors against a target. First difference pauses and moves playback to that cell.

**Keep A… / Keep B…** restores that actual run's full recipe and asks for a name
when needed, then uses the existing protected-work save path. Keeping one does not
delete the other or any saved work. **Keep editing** retains A. Saved chosen works
still support ordinary snapshot playback, recipe replay and forking. This feature
does not change the model, session schema or candidate progression gates.

Known boundary: the old G2 completion call only tests that two consecutive outputs
differ, although its catalog goal asks for a fixed-seed change. This patch deliberately
leaves that existing completion behavior and saved supports unchanged. Its completion
mark is not a causal-evidence certificate. Revising the gate and persistent paired
proof needs a separate compatibility/design review. The new report is observational
and must not be silently reused as a new completion gate.

See [bounded verification](../../docs/verification/20261008-creation-comparison/README.md).

## Model and ownership boundaries

See [the format and event contract](CONTRACT.md). Training reads each example
independently. Prediction sees only its frozen rules and revealed prefix. Generation
feeds emitted symbols into history and never trains on its own output. The receiver
gets packet bytes only. RAW and predictive both use two-bit symbols; model, header,
padding and integrity bytes are included.

All three stages use the same machine configuration and model identity. CPU rate,
channel rate, request overhead, finite memory and automatic rule-row cache affect
actual execution costs. This is an explicit higher-level teaching machine; earlier
gate-level circuits do not execute this algorithm, and cross-domain cycle totals
are not ranked together. Training preparation records its original machine.

`session.gd` owns drafts, frozen checking, successful support recipes and immutable
works. It reuses candidate transactional files, byte archives and writer leases.
Its separate `creation-candidate/session.json` does not migrate old saves. Unknown
fields or versions block rewriting. A recognized work snapshot with an incompatible
recipe remains viewable read-only; regeneration is refused. Interrupted file
transactions require explicit recovery, never silent fallback over a future main.

The nine candidate units combine distinct goals: corrections, representation cost,
machine conditions; committed prediction, necessary memory, frozen checking;
feedback, intentional changes, and keeping work. Comparison-unit support requires
actual comparable runs; ordinary restoration and creation do not require staged
failure or arbitrary repeated clicks. This is candidate content, not human learning
or final artistic acceptance.

## Development and review

The [execution plan](../../docs/exec-plans/completed/compression-prediction-creation.md)
owns current progress and remaining work. Tests cover pure bytes/causality, saved
work in independent processes, and the actual workbench separately. Viewport QA
knows the intended route and does not establish novice discovery.

Team/Claude review should begin with three concrete moments: a smaller packet that
costs more time, a revealed prediction failure, and two intentionally different
saved works. `signal_view.gd` maps symbols to visible shapes; `catalog.gd` owns
candidate text and original examples. Visual polish may change these mappings or
wording with a new mapping identity when needed, but must not change packet truth,
prediction boundaries, cost values, model provenance or protected snapshots.

## Causal inspection follow-up (cloud candidate)

Selecting a signal cell opens **Cause details**: the white selection remains at that
position, the actually matched prior context is outlined in teal on the authoritative
history lane, and four count/weight bars show the recorded successor candidates.
The compact line beside the signal traces context → prediction → revealed value or
correction. Pending predictions remain explicitly unrevealed. Generation is labeled
as output feedback without a target answer. RAW/seed writes and positional
memorization are not attributed to learned context counts.

Raw audit records are folded by default and remain available through an explicit
checkbox. Selecting a learned rule opens its frozen counts. After learning, the
panel lists count changes versus the previous frozen model, including removed
rules; this is a comparison of two full recounts, not incremental self-training.
No new state is persisted, and no predictor is called by the presentation helpers.

`tests/test_creation_causal_panel.gd` covers the controller, count bars, minimum-size
bounds, audit foldout, rule differences, focus through reveal and language changes,
and the pending-truth boundary. At 1280×720 the current evidence pane is compact;
the candidate bar row is first and full explanatory text scrolls. This remains a
native visual/play-test item rather than a claim of comfortable layout. Godot 4.6.3
cloud checks are not a substitute for the pinned 4.7.1 project verification.

## Cost ledger, evidence reading and saved-work focus

Use **Locked codec comparison** to measure RAW and predictive transport under one
source/model/machine snapshot. **Cost ledger** keeps the latest six measured pairs
for this session; editing settings marks previous conditions as historical without
recalculating them. Separate bars show actual sequential phase cycles and packet
bytes. Learning cost and its original machine are disclosed separately.

**Expand evidence** temporarily gives the detail tabs more room. **Back to signal**
retains the selected cell and page. Selecting a cell in A uses A's recorded rules;
B and packet receiver/source lanes use their own recorded evidence.

In Works / recipes, select a saved work and choose **Focus on work** for its complete
scrollable output plus supported recipe/source information. Close or Escape returns
to the workbench without changing a result or file. Unknown recipe, model, sampling
or PRNG versions remain snapshot-only, without guessing how their fields work.

Older false RAW-C1 profiles preserve validated works read-only and explain the need
for fresh predictive-restoration evidence. No automatic progress migration occurs.
See [v2 scope and verification limits](../../docs/verification/20261008-creation-evidence-v2/README.md).

## Mac playable-loop follow-up

C3 offers two public machine conditions, both with bus 1 B/cycle, request overhead
64 cycles, automatic cache 21 rows and RAM 8192 B. Only CPU throughput changes from
1 to 64. Applying a condition neither trains nor runs. With the default learned
examples and regular 1536-cell source, measured RAW/predictive cycles are
235928/258602 under A and 225601/220899 under B; packets stay 436/430 B. Other
rules/sources may behave differently. C3 retains source/model for its cost evidence.

After one manual commit/reveal, Prediction offers Run remainder and Until mismatch.
Both use the same per-cell commit→reveal path, freeze the model and retain causal
focus. A pending manual guess must be revealed first. Events now show the actual
prediction trace; pending events contain no future truth. Invalid initial text
clears executable generation and blocks Generate/Keep until corrected.

[4.7.1 original-asset route, actual chosen works and review checklist](../../docs/verification/20261008-creation-playable-loop/README.md).
