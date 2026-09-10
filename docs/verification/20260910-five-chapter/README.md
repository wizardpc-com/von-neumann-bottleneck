# Five-region free alpha — actual evidence

## M0 baseline

`24d5c22`, main == origin/main after fetch. Original downloaded plan/prompt were the only untracked input files; they remain unchanged. Original player directory not used for testing.

Isolated verification `20260910T145537Z-6be7309f`: 24 suites pass; ordinary Chinese Game input replay **602 checks / 0 failures**. Previous replay coordinate failures are closed for this baseline. This is automation, not novice acceptance.

## M1 native checkpoint (2026-09-10, Apple M2, Godot 4.7.1)

Official engine, normal Game hub → task tree → chapter 4, separate `VonNeumannBottleneckChecks/five-chapter-20260910` copied from the previously earned exploration QA save. No progress flags or reference designs injected into native play. `source=agent_native` in local v2 events. The renamed temporary engine bundle displayed a window but CUA coordinate input reported noWindowsAvailable; the official bundle worked after raising its AX window. No change to the user's Godot installation.

- 4-1: baseline two cases correctly outputs values but fails 128/192 B versus target 64/96 B. Manually moved temperature to a **separate final group**, retaining the other three fields. This differs from Hint 3's field-major recipe. Observed 32/48 B, 49/73 cycles, both pass.
- Command-Z returns to record-major; Command-Shift-Z restores the edited grouping. Saved named scheme **Temp at end**.
- Return to tree exposes both 4-2 and 4-4 choices without automatic next-level navigation.
- 4-2: copied the player's 4-1 grouping. Correct output but **96/128 B**, 120/164 cycles, neither meets its flow goal. Dragged temperature before battery into the record group, using order `[ID, temperature, battery, alarm]`. Observed **32/48 B, 56/84 cycles**, both pass. This is also a non-reference field order.
- Normal quit/restart through the Game hub restored the 4-1 completion, named scheme and unfinished 4-2 draft.

### Issues found by native operation and fixed

1. Saving a name rebuilt/freed its emitting button. Keep nodes alive until the deferred deletion boundary.
2. Native Mac drag motion can omit button masks. Reuse the existing palette's held-input fallback; resolve release after normal Godot drop with a shared once-only transaction flag.
3. JSON numbers restored as floats; field-array lookup/removal using integers silently failed. Normalize new-chapter recipe/group/copy/batch integers on restore. **Native restart → actual drag → changed addresses → successful run** verified after this fix. Add JSON roundtrip editing regression.

## Model calibration

`model-calibration.txt`: actual deterministic engine results over authored workload/recipe variants, not hardware benchmarks. Independent eight-record arithmetic: 8 record-major misses × 16 B = 128 B; contiguous temperatures occupy 2 lines = 32 B. Cycles = 8 lookups + 8 arithmetic + fills ×16 + 1 output = 145 / 49.

Measured tradeoffs: native hot/cold mixed grouping 623 cycles vs record-major 1007; runtime one-shot direct 307 versus temperature copy 557; repeated direct 2456 versus full copy 1362. Batch 4 with 17 records allocates 16 B peak, copies exactly 68 B in five batches (4+4+4+4+1), finishes in 802 cycles. Full copy needing 80 B fails before allocation against 48 B. Mixed task accepts full hot-field copy (2404/1515 cycles) and batched hot-field copy (1364/1131), both with exact oracle outputs.

## Remaining, not claimed

Native 4-3–4-6 and broader old-level input checks; complete M3/M4/M5, remote local integration, candidate exports and platform checks. Windows runtime and real new-player comprehension/fun are unverified. The task tree currently has the fifth region but semantic zoom/polish is still pending. New chapter trace text and first-use pacing need further native polish.
