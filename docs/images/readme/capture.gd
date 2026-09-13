extends SceneTree
func _init() -> void: call_deferred("run")
func snap(label: String) -> void:
 for frame: int in range(12): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.godot/"+label+".png")
func run() -> void:
 root.mode=Window.MODE_WINDOWED
 root.size=Vector2i(1600,1000)
 root.content_scale_size=Vector2i(1600,1000)
 for locale: String in ["zh_CN","en"]:
  root.get_node("Localization").set_locale(locale)
  var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate()
  root.add_child(hub)
  await snap(locale+"-readme-hub")
  hub.queue_free(); await process_frame
  root.get_node("TaskNavigation").camera_saved=false
  var tree: Control=load("res://src/campaign/task_tree.tscn").instantiate()
  root.add_child(tree)
  for frame: int in range(30): await process_frame
  tree.canvas.magnification=0.62
  tree.canvas.pan=Vector2(20,20)
  tree.canvas.queue_redraw()
  for frame: int in range(30): await process_frame
  var area: Rect2=tree.canvas.region_rects[0]
  tree.canvas.magnification=minf(0.68,(tree.canvas.size.x-48.0)/area.size.x)
  tree.canvas.pan=Vector2(24,26)-area.position*tree.canvas.magnification
  tree.canvas.queue_redraw()
  await snap(locale+"-readme-tree")
  tree.queue_free(); await process_frame
 print("PASS: four current-runtime README captures; isolated fresh profile")
 quit()
