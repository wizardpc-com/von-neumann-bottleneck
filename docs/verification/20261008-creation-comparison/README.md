# Controlled creation A/B comparison — 2026-10-08

## Scope

Read-only comparison of actual generated snapshots; minimal workbench integration.
No model/codec algorithm, chapter, media, persistent format, G2 completion call or
published build changed. The old automatic last-two-generation history remains
separate from explicit pinned A/B. A/B snapshots are temporary; only deliberately
named/kept works persist through the unchanged work schema.

## Evidence

Fresh isolated minimal Godot project, Godot **4.6.3.stable.official.7d41c59c4**:

- `test_creation_comparison.gd`: **89 checks passed**, both locales. Actual learned
  model and feedback, one/multiple changed conditions, equal output, seed-only
  variation, shifted examples, first differing cell, fixed-control locking, repeated
  pin protection, repeated B generation, cross-view navigation, protected A/B saves,
  replay, and 1280×720 mathematical bounds for main operations.
- Same suite in a **separate process**, `--comparison-reopen` with the same explicit
  `--creation-profile`: **5 checks passed**, both kept outputs regenerate exactly.
- Unchanged `test_creation_contract.gd`: **162 checks passed**.
- Unchanged `test_creation_explanation.gd`: **61 checks passed**.
- Unchanged `test_creation_state_regressions.gd`: **20 checks passed**.
- Clean harness editor import passed with no error markers after configuring all
  HOME/XDG paths explicitly.

Run each conventional suite with a fresh per-suite HOME/XDG profile. The contract
suite has fixed internal fixture paths: simply supplying `--creation-profile` does
not isolate all its fixtures. One repeated run against used QA data produced two
stale-completion assertions; rerunning with a fresh dedicated profile passed all
162. Earlier import without explicit XDG_CONFIG_HOME/XDG_CACHE_HOME emitted editor
path errors; the final isolated import was clean. These are retained as validation
limits, not hidden successful runs.

Example bounded test invocation after importing an isolated project (substitute
local paths; never use a player's profile):

```sh
env HOME="$PROFILE" XDG_DATA_HOME="$PROFILE/data" \
  XDG_CONFIG_HOME="$PROFILE/config" XDG_CACHE_HOME="$PROFILE/cache" \
  "$GODOT" --headless --path "$QA_PROJECT" \
  --script res://tests/test_creation_comparison.gd -- \
  --creation-profile=user://ab-comparison/session.json
```

Use the identical profile/path in a second process and add `--comparison-reopen`.
Do not substitute the supported release verifier's required 4.7.1 engine check;
these are explicitly additional 4.6.3 bounded checks.

## Not established

Project target remains Godot **4.7.1**. Full original project/navigation/autoload
integration, rendered appearance, native input, scrolling comfort, supported
release engine, and novice/artistic acceptance have **not** been verified here.
No screenshot or visual-acceptance claim is made. Manually inspect both languages
at 1280×720: Pin A → change one example → Learn → Generate B → inspect first
split → Keep A/B and restart; also compare equal output and multiple edits.

## Existing G2 discrepancy deliberately retained

The catalog asks for a fixed-seed authored change; the existing completion code
only requires differing outputs. It may award completion after a seed-only change.
This feature's comparison report explicitly rejects that causal interpretation,
but does not change the gate or old saved evidence. A separate reviewed change
would need to specify compatibility for existing supports and paired evidence.
