# Default Chinese localization boundary

## Goal

Make Simplified Chinese (`zh_CN`) the default player-facing language while separating language resources from gameplay, simulation, layout, and animation code. Keep an English catalog as the first alternate locale and as evidence that future locales can be added without changing game behavior.

## Scope

- Add one small localization service backed by Godot's `TranslationServer`.
- Add independent Simplified Chinese and English translation catalogs with stable semantic keys.
- Migrate player-facing text in the prototype hub, Hardware Foundations 01, Cache Locality Lab v0.2, and shared floating-window chrome.
- Translate player-facing validation, trace, tutorial, Test Bench, Program, Profiler, and status presentation without making simulation results locale-dependent.
- Add automated coverage for the default locale, English switching, catalog completeness, and locale-independent simulation/circuit results.
- Update only durable architecture, testing, and status documentation affected by the localization boundary.

## Explicit non-goals

- No in-game language settings screen or persisted user preference in this iteration; the service exposes switching for future UI and tests.
- No translation of DSL keywords/source code, memory addresses, component IDs, signal names (`A`, `B`, `SUM`, `CARRY`), or other technical identifiers whose spelling is part of gameplay evidence.
- No new fonts, decorative art, voice-over, right-to-left layout, or full production localization pipeline.
- No changes to circuit topology rules, cache costs, official test cases, animation scheduling, or completion conditions.
- No speculative localization framework beyond the two current catalogs and a narrow presentation API.

## Affected files and subsystems

- `project.godot`: autoload and translation-resource registration.
- `src/localization/`: locale service and presentation-only formatting helpers.
- `localization/`: independent `.po` catalogs.
- `src/ui/`: hub, locality lab, and shared floating-window text.
- `src/hardware_foundations/`: tutorial/challenge/Test Bench/sealing presentation text.
- `tests/`: default-language, alternate-language, catalog, UI, and simulation-independence checks.
- `ARCHITECTURE.md`, `docs/development/testing.md`, and current status docs where durable facts change.

## Invariants

- Simulation and circuit evaluation remain deterministic and independent from UI/rendering and locale.
- Animation timing and localized presentation never affect authoritative results or metrics.
- The visual circuit remains the authoritative topology; ordinary wires remain zero-latency.
- Stable IDs, port names, DSL syntax, source receipts, and canonical signatures remain language-neutral.
- Existing uncommitted v0.2 and Hardware Foundations work is preserved.

## Implementation plan

1. Inventory all player-facing text and classify it as UI copy, formatted presentation, or language-neutral technical evidence.
2. Register a default-`zh_CN` localization autoload and two gettext catalogs using semantic keys.
3. Replace hard-coded UI copy with catalog lookups; keep layout, interaction, simulation, and animation code unchanged.
4. Add presentation adapters for dynamic diagnostics/events so authoritative domain objects do not contain locale-dependent results.
5. Add localization tests and adjust UI assertions to test semantic behavior in both locales.
6. Run all four existing headless suites, the new localization suite, project/scene smoke checks, and visual inspection at the default locale.
7. Review the complete diff and status, record actual verification, and move this plan to `completed/` at handoff.

## Decisions and rationale

- **Godot gettext catalogs (`.po`)**: language content stays in reviewable resource files, plural/context support remains available, and future languages do not require UI code edits.
- **Semantic translation keys**: copy can change without turning an English sentence into an API between code and catalog.
- **Chinese default plus English fallback catalog**: Chinese is the shipped default; English proves that the boundary is real and provides a readable fallback during development.
- **Presentation-only formatting**: simulation events, metrics, circuit signatures, and DSL execution remain authoritative language-neutral data.
- **Technical tokens stay invariant**: code, addresses, port names, and component IDs must remain exact evidence rather than localized prose.

## Progress

- 2026-08-17: Reviewed repository guidance, architecture, testing instructions, dirty-worktree scope, and official Godot localization mechanisms. Plan created before implementation.
- 2026-08-17: Added a `Localization` autoload, registered independent `zh_CN` and `en` gettext catalogs, and made Simplified Chinese the project default.
- 2026-08-17: Migrated the hub, Hardware Foundations, Cache Locality Lab, floating-window chrome, trace feedback, DSL explanations/errors, and circuit diagnostics to semantic presentation keys.
- 2026-08-17: Kept DSL source, IDs, addresses, port/signal names, simulation events, and canonical signatures locale-neutral; added structured diagnostic adapters at the presentation boundary.
- 2026-08-17: Added localization coverage, refreshed UI assertions, completed regression/smoke/visual verification, reviewed the final diff, and closed this plan.

## Verification record

- All five headless suites completed with exit code `0` and their expected `PASS` lines: simulation, locality UI, circuit simulation, Hardware Foundations UI, and localization boundary.
- Project hub, direct Hardware Foundations, English startup, and hub-to-Hardware route smoke checks each completed with exit code `0`.
- Catalog audit found 383 referenced semantic keys and exactly 383 entries in each catalog, with no missing, duplicate, unused, or placeholder-mismatched entries.
- Locale-independence tests confirmed identical locality and circuit canonical traces under `zh_CN` and `en`.
- Rendered 1600×900 frames were inspected for the Chinese hub, Hardware Foundations, and locality workspace, plus the English hub; current labels fit and the alternate catalog is active.
- Fresh runtime logs contained no unexpected project errors. Godot continued to emit the known Windows `Failed to read the root certificate store` environment warning without affecting exit codes.
- `git diff --check` completed with no whitespace errors. Existing uncommitted v0.2 and Hardware Foundations work was preserved; no commit or push was created.

## Unresolved questions and temporary limitations

- Runtime language selection is intentionally API/launch-option only until a settings surface and persisted preference are designed.
- Changing locale after a procedural scene has already been built does not yet refresh every existing control in place; a scene reload/restart applies the chosen locale consistently.
- Broader locale concerns such as plural-rich copy, CJK-specific typography, and right-to-left layout remain future work.
