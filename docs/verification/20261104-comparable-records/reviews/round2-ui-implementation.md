# audit_polish implementation coordination

Owner: audit_polish. Root handoff grants task_navigation, journey_journal,
task_tree_canvas, personal_records_view; journal/new Game-projection tests.
No Godot or Git mutations. Parent/agent messages arrive encrypted; this file is
readable coordination until round2-tasks.md supplies more specific scope.

Implementing TaskNavigation.game_tasks() and game_journey_tasks(): read-only
permanent Game completion projection, no GameMode changes, preserve ordinary
current-mode tasks()/journey_tasks() behavior. PersonalRecords should default to
TaskNavigation.game_tasks() once available. Map remains current mode, suppresses
Game score captions in Test as before. Permanent journal uses game_journey_tasks().

Awaiting audit_scores record_kind values for rows exposing
best / record_kind / historical_best. Planned presentation maps all values through
localized metric labels, explicitly distinguishes remeasured saved recipe from
historical receipt, and preserves historical provenance.

Will fix personal_records_view pending community request context without
changing endpoint policy or score submission. No global task/recipe navigation
intent being added without explicit root scope; root owns locality restore UI.

## Ready for root integration / ownership released

Implemented four assigned runtime files plus new
`tests/test_game_record_projection.gd`. No edits to existing journal tests,
translations, simulator, completion or persistence formats.

- game_tasks()/game_journey_tasks() read permanent Game completion directly.
  Current-mode tasks()/journey_tasks() and original entry guards remain.
- Journal and records page consume Game projection; in Test they label archive
  scope and journal entry follows actual current-mode availability.
- Journal consumes best/record_kind/historical_best from one snapshot, labels
  current recipe remeasurement and historical source separately, localizes known
  metric labels/units, retains provenance. Reflection also uses Game state.
- Map compact score uses cycles; record_detail() and hover explain source,
  objective and Chapter4 two-case sums/peak. Game scores remain hidden in Test.
  Root may change task_tree.gd's detail from record_caption() to record_detail()
  to show the same source note without requiring hover (file outside my scope).
- Regional card page gains Review task results -> existing journal; no recipe
  restoration/navigation intent added. Drafts remain untouched.
- PersonalRecords read_only/write_failed notices appear only when needed, with
  last_error on hover, in both archive views.
- Pending community request kind remains attached to its response; requests are
  serialized, controls recover on success/failure, malformed numeric shapes are
  rejected. No production service was contacted.

Fresh checks performed by this agent: source/diff inspection, git diff --check
PASS (read-only Git; no mutations). Godot intentionally NOT run: root owns it.

Root requested focused verification: test_game_record_projection,
test_journey_journal, test_personal_records, test_tree_relation_focus,
test_release_convergence, task-navigation suites. New suite includes real saved
Chapter4 recipe remeasurement contrasted with a historical fixture scalar,
Game/Test state and disk inventory preservation, 960px zh/en header and regional
cards, storage-notice presentation, and delayed/rejected-second-response routing
without a network endpoint/socket. All mode completion states are clearly
identified fixture namespaces; this test does not claim they were earned.

Source ownership released to root for fixes/integration. No commits, staging,
branch operations or Godot runs performed by this agent.
