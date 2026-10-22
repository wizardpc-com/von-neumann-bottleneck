extends SceneTree
## Reverting a room page must detach its resize listener before freeing the rule.
const PageSkin = preload("res://src/lab/room_page_skin.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var page := Control.new()
	page.size = Vector2(640, 360)
	root.add_child(page)
	var initial_listeners: int = page.resized.get_connections().size()
	for cycle: int in 12:
		PageSkin.apply(page, "settings")
		var rule := page.get_node(PageSkin.RULE_NAME) as ColorRect
		var lifetime: WeakRef = weakref(rule)
		check(page.resized.get_connections().size() == initial_listeners + 1, "One resize listener while a skin is active")
		PageSkin.apply(page, "settings")
		check(page.resized.get_connections().size() == initial_listeners + 1, "Repeated apply does not duplicate the listener")
		page.size.x += 10
		await process_frame
		check(rule.size == Vector2(page.size.x, 2.0), "The active rule follows page width")
		PageSkin.revert(page)
		check(page.resized.get_connections().size() == initial_listeners, "Revert disconnects before freeing the rule")
		check(page.get_node_or_null(PageSkin.RULE_NAME) == null, "Revert removes the active rule")
		await process_frame
		check(lifetime.get_ref() == null, "The removed rule is actually freed")
		page.size.x += 10
		await process_frame
		check(page.resized.get_connections().size() == initial_listeners, "Resizing after free retains no stale callback")
	page.queue_free()
	await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ") + "room page skin lifecycle %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
