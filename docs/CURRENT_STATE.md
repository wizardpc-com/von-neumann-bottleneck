# Current state — free Alpha

**Single current entry.** Five regions, 40 tasks: original construction prologue,
waiting/data transport, cache/locality, overlap/prefetch and data layout. No new
chapter, simulation rule, progression threshold or server feature in this iteration.
Original free wiring, branch/delete/undo, floating instruments, named workbenches,
provenance revalidation and separate three-stage Hint remain authoritative.

## Current behavior

Bilingual editorial and typography pass: Chinese chapter titles remain 一线成机 /
时间的去处 / 少走远路 / 与等待并行 / 各就其位. English uses A Machine Takes Shape /
Where Time Goes / Less to Carry / In the Meantime / A Place for Everything.
Task-tree labels render at screen size with a readable floor and compact overview;
the five-card hub wraps and scrolls at narrower sizes. See [bilingual evidence](verification/20260912-bilingual-type/README.md).
The [earlier Chinese-only audit](verification/20260912-chinese-copy/README.md) remains
historical. Legacy prologue applications with the same depth occupy distinct display
columns without changing prerequisites.

Task-tree polish adds a padded detail card, separated title/body/status, fixed
primary Enter action, node hover and canceled stale map drags. Continue and window
resizing preserve the centered task after container layout. Final bilingual bounds
and native observations: [tree evidence](verification/20260912-tree-polish/README.md).

Latest follow-up: structured settings provide persistent Chinese/English and audio,
scrolling content with fixed close controls, safe presentation defaults and local
diagnostics. Configured receivers get a first local/basic sharing choice, with no
retroactive upload; public endpoint remains empty. See
[prelaunch settings evidence](verification/20260911-prelaunch-settings/README.md) and
[final follow-up](verification/20260911-settings-followup/README.md). Repeated exports
preserve reports; export actions join keyboard navigation; confirmation buttons follow
the selected language. Native reset/title/Tab checks are complete.

- Startup prioritizes the task tree; five chapter artworks and descriptions remain.
  Continue selects the recent Game task on the map. `task_navigation.cfg` is a
  navigation preference only; deleted/unknown task IDs fall back to an available task.
- Global save schema 2 (retaining filename `savegame_v1.json`) reads schema 1, validates existing provenance and retains
  automatic backup. `minimum_writer_version=2`, unknown root/chapter fields and
  future schema block writing. Already-issued schema-1 games reject schema 2.
  Do not manually replace the main save with its older backup during downgrade.
- The personal task board shows total completion and regional cards, with shared
  chapter emblems and accents; individual tasks remain on the prerequisite tree.
  Regions, route/bonus counts and internal result metrics derive from task metadata. Without a configured receiver they contain no community request controls.
  Remote sharing remains off, endpoint empty, no account or public service.
- New personal-record/sharing/settings text uses the existing bilingual catalogs.
- Windowed minimum targets 1280×720 logical points (Mac applies Retina scale),
  clamped to the usable desktop on smaller displays. Canvas scaling preserves the
  design workspace; F11 / Alt+Enter returns to fullscreen. Physical small-display
  and Windows mixed-DPI acceptance remain separate.

## Build identity and current evidence

The working checkout is `free-alpha-development`, not a frozen candidate. Packaging
archives one commit and generates `free-alpha-<12-char commit>`, writes the ID and
full source commit into the exported project settings, manifests, README, change
notes and ZIP names. A frozen identity cannot be overwritten. The game shows that
same ID; the release-binary probe checks it against its adjacent manifest.

Current frozen artifact: **free-alpha-aa755796594a**, content commit **aa75579**.
Later evidence-only commits do not rename or overwrite those archives.
[Current verification and package hashes](verification/20260912-chinese-copy/README.md).
Earlier candidates, including `free-alpha-427512c5a504` and `free-alpha-80105a7f5ea6`, and their reports are historical.
The latest package remains offline by default and has not been publicly released.

## What remains

[RELEASE_BLOCKERS](../RELEASE_BLOCKERS.md) is the release gate list. Windows native,
another Mac install/notarization, external beginners and extended focus/DPI sessions
must be described as pending until actually performed. Do not add more chapters or
remote features to resolve those evidence gaps. Hosting, DNS, privacy publication,
Steam setup and public release still require the owner's separate decisions.

Architecture: [root map](../ARCHITECTURE.md), [community/privacy](architecture/community-feedback.md).
Operations: [testing](development/testing.md), [distribution](distribution/free-alpha.md),
[server migration](../server/deploy/RUNBOOK.md), [owner deployment checklist](distribution/community-deployment-checklist.md).
