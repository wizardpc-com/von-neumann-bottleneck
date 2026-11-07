extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 root.mode = Window.MODE_WINDOWED
 root.size = Vector2i(1280,720)
 root.content_scale_size = Vector2i(1280,720)
 var args := OS.get_cmdline_user_args()
 root.get_node("Localization").set_locale("en" if "en" in args else "zh_CN")
 root.get_node("TaskNavigation").from_tree = true
 var scene: Control = load("res://experiments/creation/workbench.tscn").instantiate()
 root.add_child(scene)
 scene.change_task(8 if "g3" in args else 3 if "p1" in args else 0)
 var motion := InputEventMouseMotion.new()
 motion.position = Vector2(8,710)
 root.push_input(motion,true)
 await create_timer(7).timeout
 if "flow" in args:
  scene.train_model()
  await create_timer(0.3).timeout
  scene.advance_step()
 await create_timer(1).timeout
 RenderingServer.force_draw(false)
 await process_frame
 var tabs := scene.find_child("DraftTabs",true,false) as TabContainer
 var bar := tabs.get_tab_bar()
 for index: int in 3:
  if not Rect2(Vector2.ZERO,bar.size).encloses(bar.get_tab_rect(index)):
   push_error("Draft tab is clipped: "+str(index))
   quit(1)
   return
 var handbook := scene.find_child("TerminologyButton",true,false) as Button
 if handbook.get_theme_stylebox("normal").bg_color.a != 0:
  push_error("Handbook must use transparent tool style")
  quit(1)
  return
 var cue := scene.get_node_or_null("UiMetCue") as Control
 if cue != null:
  for node: Node in scene.find_children("*","Button",true,false):
   var control := node as Control
   if control.is_visible_in_tree() and cue.get_global_rect().intersects(control.get_global_rect()):
    push_error("Completion cue overlaps button: "+str(control.name))
    quit(1)
    return
 print("CAPTURE_GEOMETRY ",scene.status.get_global_rect())
 root.get_texture().get_image().save_png(args[-1])
 quit()
