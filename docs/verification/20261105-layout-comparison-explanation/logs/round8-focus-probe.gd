extends "res://tests/test_layout_strategy_ui.gd"

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()): quit(1); return
	await settle()
	var host: Control = Scene.instantiate()
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(960,640))
	host.run_current()
	host.set_baseline()
	var plan: Dictionary = host.session.draft()
	plan.query_group = 8
	plan.record_tile = 1
	host.session.edit(plan)
	host.refresh()
	host.run_current()
	host.query_group.value_changed.connect(func(value: float) -> void:
		print("FOCUS_VALUE ",JSON.stringify({"value":value,"syncing":host._syncing,"draft":host.session.draft().query_group,"text":host.query_group.get_line_edit().text})))
	var edit: LineEdit = host.query_group.get_line_edit()
	edit.focus_exited.connect(func() -> void:
		print("FOCUS_EXIT ",JSON.stringify({"syncing":host._syncing,"value":host.query_group.value,"draft":host.session.draft().query_group,"text":edit.text})))
	edit.grab_focus()
	await settle()
	edit.select_all()
	await key(KEY_7,false,false,55)
	print("BEFORE ",JSON.stringify({"value":host.query_group.value,"draft":host.session.draft().query_group,"text":edit.text,"hit":host._inspection_hit(host.explanation_button.get_global_rect().get_center())}))
	await click(host.explanation_button)
	print("AFTER ",JSON.stringify({"value":host.query_group.value,"draft":host.session.draft().query_group,"text":edit.text,"pending":host._pending_numeric==host.query_group}))
	current_scene = null
	host.queue_free()
	await settle()
	print("PASS: diagnostic only, no acceptance verdict")
	quit(0)
