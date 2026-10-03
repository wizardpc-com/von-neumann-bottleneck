# Representation candidate: save and resume a complete session

## Intent and source
2026-10-03 owner supplied the game constitution v1.0 and “壹：有人应答” revised story and requested cloud playtesting and iterative development. Start from main 05c3bf0. The constitution prioritizes a complete representation experience rather than another new domain. The story is background, not mandatory exposition; its late English subtitle differs from the constitution, so retain the constitution's existing title rather than silently rename the game.

## First bounded slice
Allow a player to explicitly save and resume the five-task representation candidate's drafts and measured comparison plans in a separate opt-in candidate profile. Restore results by rerunning the exact recorded plans under the matching model/contracts. Do not serialize trusted completion flags or grant campaign progress. Keep ordinary saves, 40-task navigation, models, valid solutions and simulation unchanged. No commit, push, release or remote service in this iteration.

## Changes and safeguards
- Small candidate-only JSON storage with schema/model/contracts checks, bounded input, validated integer partitions, unknown-field refusal and atomic temporary/backup writes.
- Opt-in named profile in existing isolated launcher; replays remain isolated and cannot use it.
- Explicit save UI and restored-session message. Undo history remains session-local.
- Tests for roundtrip, corrupt/future input, stale contracts, forged results, file failures and restart; existing regression and native input checks.

## Evidence so far
Native cloud desktop: new isolated player opened task tree, entered wiring tutorial, connected A/NOT/LAMP, toggled input, ran, removed and reconnected a wire, reached completion. This is agent playtesting, not human novice evidence. Desktop audio falls back to dummy driver; no listening acceptance claimed.

## Completion gate
Fresh focused and full checks, source diff review, native save → close → reopen → inspect draft/history, and clear unverified boundaries. Keep candidate experimental until broader integration and player feedback.

## First slice verification
2026-10-03: final isolated verifier 20261003T132423Z-13d89c0f passed 57 stages (import, isolated directory, 55 suites). Candidate session suite covers 37 checks, including malformed/future data, stale writer refusal and unsaved quit cancellation. Native Linux input confirmed save/restart restoring task2 with its own draft and both task1 comparisons; quit/cancel/retry/save-and-quit worked. Four invalid launcher profile cases rejected. An early JSON type guard failure was found and fixed before final validation. One native fullscreen startup rendered at an incorrect offset until F11 switched display mode; not claimed as resolved platform behavior. Audio dummy fallback prevents listening acceptance. No gameplay model or official save semantics changed.

## Second bounded improvement
Owner emphasized that fun is central. Add a reversible path from an actual recorded plan back to editable construction, reducing repetitive rebuilding and making another experiment cheap. This enables player choices; it is not proof of fun or novice comprehension. Focused tests cover immutable historical evidence, undo, cross-task preservation and repeated copy no-op.

## Third bounded improvement
Native play showed a first attempt meets the cycle cap but exceeds storage; a generic unmet message makes the next experiment harder to reason about. Display the exact measured excess and public limit for each failed order, including when viewing older records. Do not reveal a codec/boundary solution or change acceptance. Tests compare RAW64 (68B vs60B) with a valid performed plan and English feedback.

## Complete first iteration series
Final verifier 20261003T133543Z-715a971b: 57/57 stages passed; candidate session suite 46 checks. Native input verified retrieving RAW64 from history across tasks, undo to prior RLE/RAW draft, running it again, and displaying the measured 8B storage excess (68 actual / 60 limit). No reference solutions or completion granted by reuse. Main remains unchanged; publish this bounded series on a development branch under the owner's explicit commit/push instruction. Next priorities are visual/animation feedback and richer player decisions; no whole-game fun claim.
