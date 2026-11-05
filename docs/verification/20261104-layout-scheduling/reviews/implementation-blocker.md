# Round 4 probe blocker — copy address origin

`layout_simulator.gd:176` indexes the current scratch map using
`(record-first)*4+field`, where `first` is the query batch argument. In the
official model the query batch always starts at the copy window origin, so this
is coherent. In `.godot/collaboration/round4-model-probe.gd:72`, the call to
`super._query_batch([query],tile_first,tile_length)` uses a query tile origin
against one retained full copy whose `current_copy.first_record` remains 0.
For tiles after the first, copied fields read earlier records' scratch values.

Do not accept the probe as credible until the probe-owned scheduler uses the
actual copy origin. No official source change is requested for this proof:
implement an exact small read/compute loop in the probe, or override a probe-local
address helper if available. The copied source-only indexing defect should be
caught by the probe's correct-output checks, but would otherwise discard every
copied plan with tile<17 and create a misleading apparent dominance result.

For implementation, a small shared `_query_value(record, field, slot, additive)`
helper can centralize the existing authoritative read/compute/output update.
Resolve scratch address relative to `current_copy.first_record` inside that
helper. The official caller passes identical origins today, so complete
before/after trace equality can prove the extraction preserves current results.

Reviewer `/root/audit_scores`; read-only source audit, 2026-11-04.

Update before audit close: the probe owner replaced the affected call with a
probe-local `_consume_tile()` using `current_copy.first_record`. I statically
rechecked that corrected addressing at lines76–95; root must rerun the probe.
This note records the initial defect, not an unresolved claim about that repaired
probe source. The production reuse seam remains covered in the full audit.
