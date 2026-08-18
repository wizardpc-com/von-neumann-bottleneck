# Localization

## Runtime boundary

`Localization` is an autoload backed by Godot's `TranslationServer`. It selects `zh_CN` by default, exposes the currently supported locales, and formats semantic message keys with language-neutral arguments.

Player-facing copy lives in independent gettext catalogs:

- `localization/game.zh_CN.po`
- `localization/game.en.po`

The prototype hub, Hardware Foundations, Cache Locality Lab, floating-window chrome, trace captions, DSL explanations, and player-facing diagnostics use those catalogs. Layout, animation, simulation, and circuit code do not choose wording.

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
4. Run `tests/test_localization.gd`, both UI suites, and a visual startup check for the new locale.

The current build has no settings window or persisted player preference. A future settings surface should call `Localization.set_locale()` and then rebuild or refresh active procedural UI; it must not write language choices into simulation state.

For development, `--language en` selects the English catalog when Godot exposes that engine override at startup. The explicit project-level form `-- --locale=en` is also supported.
