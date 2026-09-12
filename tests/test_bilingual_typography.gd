extends SceneTree
var failures: Array[String]=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
func capture(label: String) -> void:
	if "--typography-capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/typography")
	root.get_texture().get_image().save_png("res://.godot/typography/"+label+".png")
func labels_fit(node: Node,bounds: Rect2) -> void:
	if node is Label and node.is_visible_in_tree():
		var rect: Rect2=node.get_global_rect()
		check(rect.position.x>=bounds.position.x-1 and rect.end.x<=bounds.end.x+1,"Label overflows viewport width: "+node.text)
		check(node.size.y+1>=node.get_minimum_size().y,"Label clips its wrapped lines: "+node.text)
		var ancestor: Node=node.get_parent()
		while ancestor!=null and not ancestor is ScrollContainer: ancestor=ancestor.get_parent()
		if ancestor==null:
			check(bounds.grow(1).encloses(rect),"Unscrollable label outside viewport: "+node.text)
	for child: Node in node.get_children(): labels_fit(child,bounds)
func run() -> void:
	var loc: Node=root.get_node("Localization")
	var nav: Node=root.get_node("TaskNavigation")
	for locale: String in ["zh_CN","en"]:
		loc.set_locale(locale)
		await memory_text_fits(locale)
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1600,900)]:
			root.size=dimensions
			root.content_scale_size=dimensions
			var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
			root.add_child(hub)
			for frame: int in range(6): await process_frame
			labels_fit(hub,Rect2(Vector2.ZERO,Vector2(dimensions)))
			var fullscreen: Button=hub.fullscreen_button
			for active: bool in [true,false]:
				fullscreen._refresh(active)
				for frame: int in range(4): await process_frame
				check(hub.get_global_rect().encloses(fullscreen.get_global_rect()),"Both fullscreen captions stay inside the hub: "+locale)
			fullscreen._refresh(root.get_node("WindowMode").is_fullscreen())
			var entry: Control=hub.find_child("TaskTreeEntry",true,false)
			var scroll: ScrollContainer=hub.find_child("ChapterScroll",true,false)
			check(scroll.scroll_vertical==0 and scroll.get_global_rect().encloses(entry.get_global_rect()),"Fresh hub keeps the entire primary task-tree entry visible.")
			await capture(locale+"-hub-"+str(dimensions.x))
			hub.queue_free(); await process_frame
		nav.camera_saved=false
		var tree: Control=load("res://src/campaign/task_tree.tscn").instantiate()
		root.add_child(tree)
		for frame: int in range(5): await process_frame
		var canvas: Control=tree.canvas
		var font: Font=canvas.get_theme_default_font()
		for zoom: float in [0.18,0.33,0.34,0.45,0.62,0.85,1.0,1.6]:
			canvas.magnification=zoom
			canvas.pan=Vector2(13.4,-29.7)
			for row: Dictionary in tree.rows:
				var text: Dictionary=canvas.node_text_layout(row)
				if zoom<0.34:
					check(text.is_empty(),"Overview must not shrink task labels below readable size.")
					continue
				check(text.font_size>=14,"Task title has a screen-size floor.")
				if locale=="en" and row.id=="tutorial":
					check("Wiring" in text.title,"Wiring remains identifiable instead of truncating the chapter prefix.")
				var width: float=font.get_string_size(text.title,HORIZONTAL_ALIGNMENT_LEFT,-1,text.font_size).x
				check(width<=text.width+0.1,"Fitted title exceeds available width: "+locale+" "+row.key)
				var glyph_bounds:=Rect2(text.position-Vector2(0,font.get_ascent(text.font_size)),Vector2(width,font.get_height(text.font_size)))
				check(text.rect.grow(1).encloses(glyph_bounds),"Title leaves its node at zoom "+str(zoom)+": "+row.key)
				check(text.position==text.position.round(),"Panning keeps screen baselines pixel aligned.")
			canvas.queue_redraw()
			await process_frame
			if zoom in [0.18,0.45,0.85,1.6]: await capture(locale+"-map-"+str(zoom))
		tree.queue_free(); await process_frame
	for message: String in failures: push_error(message)
	print("PASS: bilingual hub bounds and 40 task labels across zoom/pan" if failures.is_empty() else "FAIL: bilingual typography")
	quit(0 if failures.is_empty() else 1)

func memory_text_fits(locale: String) -> void:
	var recipe = preload("res://src/layout_chapter/layout_recipe.gd")
	var catalog = preload("res://src/layout_chapter/layout_catalog.gd")
	var memory: Control = load("res://src/layout_chapter/layout_memory_view.gd").new()
	root.add_child(memory)
	var data: Array = catalog.records(12)
	var mapping: Dictionary = recipe.mapping(recipe.record_major(),12)
	var original: String = JSON.stringify(mapping)
	memory.configure(mapping,data,"这一批实际复制到的临时区 · #0–11 · 历史结果" if locale=="zh_CN" else "Actual scratch addresses for this batch · #0–11 · previous run")
	for width: float in [510.0,700.0]:
		memory.size.x=width
		memory.position=Vector2(13,19)
		for frame: int in range(3): await process_frame
		check(memory._heading.get_rect().end.x<=width,"Memory caption fits after resize.")
		check(memory._legend.position.y>=memory._heading.get_rect().end.y,"Wrapped heading and legend do not overlap.")
		check(memory._grid_top>memory._legend.get_rect().end.y,"Memory cells start below wrapped text.")
		var font: Font=memory.get_theme_default_font()
		for cell: Dictionary in mapping.cells:
			var rect: Rect2=memory.cell_rect(int(cell.address))
			var field: String=(memory.NAMES if locale=="zh_CN" else memory.EN_NAMES)[int(cell.field)]
			check(font.get_string_size(field,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x<=rect.size.x-16,"Field name fits separately from record number: "+field)
			check(font.get_string_size("#"+str(cell.record),HORIZONTAL_ALIGNMENT_LEFT,-1,16).x<=rect.size.x-16,"Double-digit record ID fits.")
			var tip: String=memory._get_tooltip(rect.get_center())
			check(field in tip and str(cell.record) in tip,"Cell tooltip follows locale and source identity.")
			if locale=="en": check("source record" in tip and "原记录" not in tip,"English tooltip contains no Chinese fallback.")
		var last: Dictionary=mapping.cells[-1]
		var click:=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true
		click.position=memory.cell_rect(int(last.address)).get_center()
		memory._gui_input(click)
		check(memory.selected_address==last.address and memory.selected_record==11,"Resized cell still selects its real address/record.")
		check(memory._get_tooltip(Vector2(74,memory._grid_top+1)).is_empty(),"Grid gutters are not data cells.")
		check(JSON.stringify(mapping)==original,"Presentation never modifies address mapping.")
		await capture(locale+"-memory-"+str(int(width)))
	var tail: Dictionary=recipe.mapping(recipe.record_major(),1,256,[0])
	tail.first_record=11
	memory.configure(tail,data,"Tail batch")
	await process_frame
	var tip: String=memory._get_tooltip(memory.cell_rect(256).get_center())
	check("#11" in tip and str(data[11][0]) in tip,"Tail batch describes the original record, not its local index.")
	check(memory._get_tooltip(memory.cell_rect(260).get_center()).is_empty(),"Alignment padding does not report a record.")
	memory.queue_free(); await process_frame
	var panel: Control=load("res://src/ui/floating_instrument_panel.gd").new()
	panel.custom_minimum_size=Vector2(280,190)
	panel.setup(&"memory","地址视图 · 这一批实际复制到的临时区" if locale=="zh_CN" else "Address view · actual scratch addresses for this batch")
	root.add_child(panel)
	panel.size=Vector2(280,190)
	for frame: int in range(3): await process_frame
	var heading: Label=panel.find_child("WindowTitle",true,false)
	var close: Button=panel.find_child("CloseButton",true,false)
	check(panel.size.x<=280,"Long window title must not force a wide instrument.")
	check(heading.get_global_rect().end.x<=close.get_global_rect().position.x,"Title leaves room for window controls.")
	check(heading.tooltip_text==heading.text,"Trimmed title retains complete tooltip.")
	panel.queue_free(); await process_frame
