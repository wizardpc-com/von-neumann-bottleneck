extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native display required; this verifier does not run headless")
		quit(2)
		return
	var mode: Node = root.get_node("WindowMode")
	await create_timer(1.0).timeout
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var preferred: Vector2i = mode._minimum_pixels()
	var expected_minimum := Vector2i(mini(preferred.x, int(usable.size.x * 0.9)), mini(preferred.y, int(usable.size.y * 0.9)))
	check(root.min_size == expected_minimum, "Root Window minimum must match configured native minimum")
	mode._windowed_size = Vector2i(1280, 720)
	mode._windowed_position = usable.position + Vector2i(30, 50)
	mode._has_windowed_rect = true
	var maximum := Vector2i(maxi(1280, int(usable.size.x * 0.9)), maxi(720, int(usable.size.y * 0.9)))
	var expected_size := Vector2i(clampi(1280, mini(preferred.x, usable.size.x), mini(maximum.x, usable.size.x)), clampi(720, mini(preferred.y, usable.size.y), mini(maximum.y, usable.size.y)))
	var expected_position := Vector2i(clampi(usable.position.x + 30, usable.position.x, usable.end.x - expected_size.x), clampi(usable.position.y + 50, usable.position.y, usable.end.y - expected_size.y))
	mode._leave_fullscreen()
	check(root.size == expected_size, "Windowed restore uses the expected clamped dimensions")
	check(root.position == expected_position, "Windowed move must synchronize root Window immediately")
	# The next presentation setting must not see stale fullscreen dimensions.
	check(root.size == DisplayServer.window_get_size(), "Windowed resize must synchronize root Window immediately")
	var restored_size: Vector2i = expected_size
	mode._configure_minimum_window()
	check(root.size == restored_size, "Applying minimum size must preserve the just-restored windowed size")
	await create_timer(1.0).timeout
	check(root.size == DisplayServer.window_get_size(), "Settled windowed native and root sizes agree")
	mode._enter_fullscreen()
	await create_timer(1.0).timeout
	check(mode.is_fullscreen(), "Fullscreen transition completes")
	check(root.size == DisplayServer.window_get_size(), "Settled fullscreen native and root sizes agree")
	mode._leave_fullscreen()
	await create_timer(1.0).timeout
	check(not mode.is_fullscreen(), "Windowed return completes")
	check(root.size == restored_size, "Fullscreen round trip retains the remembered windowed size")
	if failures.is_empty():
		print("PASS: native root minimum, immediate geometry synchronization and fullscreen round-trip retention")
	quit(0 if failures.is_empty() else 1)
