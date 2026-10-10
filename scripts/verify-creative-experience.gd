extends "res://scripts/verify-personal-works.gd"
## Same-model C/P/G fixture, now uses the player's existing-passage editor.
## Text entry is a disclosed controller fixture; buttons use viewport input.
func click(action: Button, viewport: Window = null) -> void:
	# Switching a tab changes its scroll range after container layout settles.
	# Reveal again against that actual range before inheriting viewport input.
	if action != null:
		expose(action)
		await settle()
		expose(action)
		await settle()
	await super.click(action,viewport)

func author_examples(scene, indices: Array, order: int) -> void:
	if indices != [0,4]:
		await super.author_examples(scene,indices,order)
		return
	var before_model: Dictionary = scene.session.data.model.duplicate(true)
	var before_a: Dictionary = scene.pinned_creation.duplicate(true)
	var before_examples: Array = scene.session.data.draft.examples.duplicate(true)
	var intention := scene.find_child("CreationIntent",true,false) as LineEdit
	intention.text = "Fewer B, more C in this passage" if locale=="en" else "让这一段少一些B，多一些C"
	intention.text_changed.emit(intention.text)
	var intended_text: String = intention.text
	await press(scene,"EditExample1")
	var editor := scene.find_child("SampleEditText",true,false) as LineEdit
	check(editor != null and editor.text==Catalog.symbols(before_examples[1]),"Existing second passage opens in place")
	editor.text=Catalog.symbols(Catalog.sample(4)); editor.text_changed.emit(editor.text)
	await capture("04-edit-existing-passage")
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft.examples==[before_examples[0],Catalog.sample(4)],"Apply replaces only the chosen passage, retaining order and neighbours")
	check(scene.session.data.model==before_model and scene.pinned_creation==before_a,"Editing cannot silently relearn or mutate pinned A")
	report.author_setup.append({"action":"existing passage editor; controller text + viewport Apply", "index":1,"before":before_examples[1],"after":Catalog.sample(4),"intention":intended_text,"intention_evaluated":false})
	await press(scene,"Train")
	check(scene.session.data.model!=before_model,"Explicit Learn recounts the actual edited passage")
	await capture("04-learned-rule-change")

func capture(name: String, viewport: Window = null) -> void:
	if name == "05-generation-B":
		var scene := root.get_child(root.get_child_count()-1)
		var decision := scene.find_child("CreationFirstDifference",true,false) as Button
		if decision != null:
			expose(decision)
			await settle()
			expose(decision)
			await settle()
	if viewport != null and viewport != root and viewport.get("mapping_choice") != null:
		viewport.get("mapping_choice").select(2)
		viewport.call("sync_presentation")
	await super.capture(name,viewport)
	if name == "08-performance-complete" and viewport != null:
		var prior_size: Vector2i = viewport.size
		viewport.size=Vector2i(640,420)
		await settle()
		await super.capture("08-compact-phrases",viewport)
		check(viewport.get("canvas").viewing_mapping=="light-phrases-v1" and viewport.get("work").output==viewport.get("canvas").output,"Compact phrase view retains every protected symbol")
		var point: Vector2 = viewport.get("canvas").phrase_point(viewport.get("cursor")-1)
		var scroll: ScrollContainer = viewport.get("snapshot_scroll")
		check(point.y >= scroll.scroll_vertical and point.y <= scroll.scroll_vertical+scroll.size.y,"Compact resized view locates the actual current saved symbol")
		viewport.size=prior_size
		await settle()
