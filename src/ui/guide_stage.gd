extends RefCounted
## Who may speak in a level. Guidance (the opening line, step guide, help and
## highlight) only shows while nothing blocking is open above the workbench:
## Settings, a completion card, a confirmation or a reading layer. Blocking
## surfaces join BLOCKER_GROUP; guidance asks `blocked()` before it appears and
## steps aside (it does not queue up to replay) when one opens.
## Presentation only: no progression, input routing or simulation authority.

const BLOCKER_GROUP := &"guide_blockers"


static func blocked(tree: SceneTree) -> bool:
	if tree == null: return false
	var window_mode: Node = tree.root.get_node_or_null("WindowMode")
	if window_mode != null and is_instance_valid(window_mode.get("settings_layer")): return true
	for node: Node in tree.get_nodes_in_group(BLOCKER_GROUP):
		if node is CanvasItem and (node as CanvasItem).is_visible_in_tree(): return true
		if node is CanvasLayer and (node as CanvasLayer).visible: return true
	return false


static func mark_blocker(node: Node) -> void:
	if node != null and not node.is_in_group(BLOCKER_GROUP): node.add_to_group(BLOCKER_GROUP)
