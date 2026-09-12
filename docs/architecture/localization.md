# Localization

## Runtime boundary

`Localization` is an autoload backed by Godot's `TranslationServer`. It selects `zh_CN` by default, exposes the currently supported locales, and formats semantic message keys with language-neutral arguments.

Player-facing copy lives in independent gettext catalogs:

- `localization/game.zh_CN.po`
- `localization/game.en.po`

The prototype hub, Hardware Foundations, Cache Locality Lab, floating-window chrome, trace captions, DSL explanations, and player-facing diagnostics use those catalogs. Layout, animation, simulation, and circuit code do not choose wording.

Mission narratives use `[[term_id|visible text]]` inside localized strings. `LinkedMissionText` renders every marked term with the shared cyan Handbook accent and emits the stable `term_id` when clicked; the active chapter then opens `TerminologyHandbook` directly at that entry. `MissionNarrativeCatalog` owns the page order for all three chapters. A mission may use one to four pages, but pages are added only when a concept, action, or verification step genuinely needs separate explanation. Localization tests reject missing page copy, more than four pages, malformed markers, and links whose IDs do not exist in the Handbook.

## Language-neutral evidence

The following remain stable across locales:

- DSL keywords and exact applied source;
- loop variables, memory addresses, component IDs, port and signal names;
- circuit topology and canonical signatures;
- simulation events, results, metrics, costs, and canonical traces;
- official test inputs and expected values.

DSL and circuit validation expose semantic diagnostic keys plus arguments for presentation. Existing English fallback strings remain developer/debug evidence and are not used as the UI localization API. Simulation-event captions are derived in the UI from event kind and structured fields, so changing locale cannot mutate an authoritative trace.

## Adding a locale

1. Add a complete `localization/game.<locale>.po` catalog using the existing semantic keys.
2. Register the resource in `project.godot` and add its standardized locale code to `Localization.SUPPORTED_LOCALES`.
3. Do not translate DSL syntax, stable IDs, addresses, or signal names unless a separate gameplay decision deliberately changes those contracts.
4. Keep mission link IDs unchanged while translating their visible text, and introduce a term in plain context before relying on it.
5. Run `tests/test_localization.gd`, the affected UI suites, and a visual startup check for the new locale.

The settings window persists Chinese/English through `DisplayPreferences` and refreshes procedural UI when the locale changes. Language choice remains separate from simulation and progress state. Chapter 4 currently keeps its localized title arrays in `LayoutCatalog`; compact task-tree labels likewise retain Chinese/English pairs. Keep those title surfaces synchronized when editing the PO catalogs.

The bounded September 12 Chinese editorial import and protected-token checks are recorded in [the copy audit](../verification/20260912-chinese-copy/README.md). That receipt predates the [bilingual follow-up](../verification/20260912-bilingual-type/README.md), which now adapts English as well. `overlap.hub.eyebrow` separates the technical subtitle from the branch label in both languages.

Task-tree shapes transform with the camera; text draws at a measured final screen size with rounded baselines. Overview omits illegibly tiny node text, while hover and the fixed detail card preserve full titles. Homepage text follows available width and vertical scrolling; it does not force a fixed 1480-pixel content width.

For development, `--language en` selects the English catalog when Godot exposes that engine override at startup. The explicit project-level form `-- --locale=en` is also supported.
