extends SceneTree
var draws: int = 0
func _init() -> void: call_deferred("run")
func shot(path: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run() -> void:
 root.size=Vector2i(1280,720)
 root.get_node("Localization").set_locale("zh_CN")
 var nav=root.get_node("TaskNavigation");nav.camera_saved=false;nav.selected="hardware_foundations/tutorial"
 var scene=load("res://src/campaign/task_tree.tscn").instantiate();root.add_child(scene)
 for i in 120: await process_frame
 await shot("res://docs/verification/20261108-W7/after-tree.png")
 scene.canvas.draw.connect(func(): draws+=1)
 var times: Array[float]=[]
 var start=Time.get_ticks_usec()
 for i in 240:
  await process_frame
  times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
 times.sort()
 print("W7_IDLE frames=240 draws=%d process_median_ms=%.3f process_p95_ms=%.3f wall_frame_ms=%.3f" % [draws,times[120],times[228],(Time.get_ticks_usec()-start)/240000.0])
 scene.search.text="cache";scene._on_search_changed("cache")
 for i in 5: await process_frame
 await shot("res://.godot/w7/after-search.png")
 var matches=scene.canvas.matching_keys()
 if not matches.is_empty(): scene._select_and_locate(matches[0])
 for i in 5: await process_frame
 await shot("res://docs/verification/20261108-W7/after-detail.png")
 scene.list_button.pressed.emit()
 for i in 5: await process_frame
 await shot("res://docs/verification/20261108-W7/after-return.png")
 scene._choose_region(5)
 for i in 5: await process_frame
 await shot("res://docs/verification/20261108-W7/after-ch5.png")
 root.get_node("Localization").set_locale("en")
 scene.queue_free();await process_frame
 scene=load("res://src/campaign/task_tree.tscn").instantiate();root.add_child(scene)
 for i in 15: await process_frame
 scene._choose_region(5)
 for i in 15: await process_frame
 await shot("res://docs/verification/20261108-W7/after-ch5-en.png")
 quit()
