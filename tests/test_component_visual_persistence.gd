extends "res://tests/test_global_save.gd"
## Uses the existing valid HalfAdder fixture and real GlobalSave verification path.
const Visual = preload("res://src/hardware_foundations/component_visual_layout.gd")
func _run() -> void:
	game_mode=root.get_node("GameMode");system_chapter=root.get_node("SystemChapter");locality_chapter=root.get_node("LocalityChapter")
	test_directory="res://.godot/visual_persistence_%d" % Time.get_ticks_usec()
	save_path=test_directory.path_join("save.json");workbench_path=test_directory.path_join("workbenches.json")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	game_mode.set_mode(&"game");_reset_chapters()
	var player = _build_player([&"tutorial",&"half_adder",&"full_adder",&"alu"])
	var half: ReusableComponent=player.component_library[&"HalfAdder"]
	var signature: String=player.canonical_signature()
	var compact: Dictionary={}
	var stepped: Dictionary={}
	var index: int=0
	for id: StringName in half.circuit_snapshot.components:
		compact[String(id)]={"x":(index%3)*120,"y":(index/3)*90,"w":96,"h":72}
		stepped[String(id)]={"x":(index%3)*120,"y":(index/3)*90+(160 if index==5 else 0),"w":96,"h":72}
		index+=1
	var a: Dictionary=Visual.freeze(half.source_signature,compact)
	var b: Dictionary=Visual.freeze(half.source_signature,stepped)
	_assert(a.bands!=b.bands,"Actual same-interface HalfAdder fixture has distinct shapes for two layouts")
	half.visual_snapshot=b
	_assert(player.canonical_signature()==signature,"Visual assignment changes no player or reusable signatures")
	var writer=_service();writer.game_player_content=player
	_assert(writer.save_game(true),"Visual extension saves with existing game contract")
	var reader=_service()
	_assert(reader.load_game(),"Existing verifier reloads actual circuit provenance")
	var restored: ReusableComponent=reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(restored!=null,"Presentation never invalidates verified earned component")
	if restored!=null:
		_assert(Visual.is_valid(restored.visual_snapshot,restored.source_signature),"Restart restores valid frozen footprint")
		var preview_rect:=Rect2(0,0,240,160)
		_assert(Visual.outline(restored.visual_snapshot,restored.source_signature,preview_rect)==Visual.outline(b,half.source_signature,preview_rect),"Restart retains exact rendered geometry across JSON int/float representation")
		_assert(restored.visual_snapshot.layout_digest==b.layout_digest,"Restart retains the same frozen occupancy digest")
		_assert(restored.canonical_signature()==half.canonical_signature(),"Restart logical identity unchanged")
	var derived: ReusableComponent=reader.game_player_content.component_library.get(&"ALU4")
	_assert(derived!=null and derived.visual_snapshot.is_empty(),"Derived wrapper safely uses family fallback without invented layout")
	# Existing V1 records retain their own bands rather than being regenerated.
	var legacy: Dictionary = b.duplicate(true)
	legacy.visual_algorithm = "layout-envelope-v1"
	legacy.bands = []
	for row: int in Visual.ROWS:
		var left: int = 4
		var right: int = 8
		for cell: Variant in legacy.cells:
			if int(cell)/Visual.COLUMNS == row:
				left = mini(left,int(cell)%Visual.COLUMNS)
				right = maxi(right,int(cell)%Visual.COLUMNS+1)
		legacy.bands.append([left,right])
	half.visual_snapshot = legacy
	_assert(writer.save_game(true),"Frozen V1 presentation still saves")
	reader = _service(); _assert(reader.load_game(),"V1 source remains usable after restart")
	restored = reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(restored!=null,"V1 presentation preserves the earned reusable component")
	if restored!=null:
		_assert(Visual.is_valid(restored.visual_snapshot,restored.source_signature),"Restored V1 footprint remains valid")
		_assert(restored.visual_snapshot.get("visual_algorithm")==Visual.LEGACY_ALGORITHM,"V1 presentation retains its frozen algorithm")
		var legacy_rect:=Rect2(0,0,240,160)
		_assert(Visual.outline(restored.visual_snapshot,restored.source_signature,legacy_rect)==Visual.outline(legacy,half.source_signature,legacy_rect),"V1 saved bands retain identical rendered geometry across JSON numeric types")
		_assert(restored.visual_snapshot.get("layout_digest")==legacy.layout_digest,"V1 saved footprint retains its occupancy digest")
	var wrong_source: Dictionary = b.duplicate(true)
	wrong_source.source_signature = "unrelated-source"
	half.visual_snapshot = wrong_source
	_assert(writer.save_game(true),"Mismatched visual source fixture saves independently")
	reader = _service(); _assert(reader.load_game(),"Wrong visual source never invalidates actual earned logic")
	restored = reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(restored!=null and restored.visual_snapshot.is_empty(),"Presentation from another source safely falls back")
	# Malformed presentation is ignored while actual source and unlock remain valid.
	half.visual_snapshot={"visual_schema":999,"bands":["bad"]}
	_assert(writer.save_game(true),"Presentation corruption fixture can be persisted independently")
	reader=_service();_assert(reader.load_game(),"Malformed visual does not block actual saved circuit")
	restored=reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(restored!=null and restored.visual_snapshot.is_empty(),"Malformed/unknown visual falls back, not migrated into fake history")
	half.visual_snapshot={}
	_assert(writer.save_game(true),"Legacy no-layout fixture saves")
	reader=_service();_assert(reader.load_game(),"Legacy no-layout component remains usable")
	restored=reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(restored!=null and restored.visual_snapshot.is_empty(),"Legacy source is not mistaken for a historic layout")
	for service: Node in services: service.free()
	services.clear();_reset_chapters()
	_remove_tree(ProjectSettings.globalize_path(test_directory).replace("\\","/"))
	for failure: String in failures: push_error(failure)
	print("PASS: test_component_visual_persistence" if failures.is_empty() else "FAIL: test_component_visual_persistence")
	quit(0 if failures.is_empty() else 1)
