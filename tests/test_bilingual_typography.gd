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
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1600,900)]:
			root.size=dimensions
			root.content_scale_size=dimensions
			var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
			root.add_child(hub)
			for frame: int in range(6): await process_frame
			labels_fit(hub,Rect2(Vector2.ZERO,Vector2(dimensions)))
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
