extends SceneTree
func _init() -> void: call_deferred("run")
func settle() -> void:
 for i: int in 6: await process_frame
func key(code: Key) -> void:
 for down: bool in [true,false]:
  var event := InputEventKey.new()
  event.keycode=code;event.physical_keycode=code;event.pressed=down
  root.push_input(event,true);await process_frame
 await settle()
func owner() -> String:
 var target: Control=root.gui_get_focus_owner()
 return str(target.name) if target != null else "NONE"
func run() -> void:
 root.get_node("TaskNavigation").pending=""
 var scene=load("res://experiments/representation_region/region.tscn").instantiate()
 root.add_child(scene);await settle()
 var rle:=scene.find_child("RLE",true,false) as Button
 rle.grab_focus();await key(KEY_ENTER)
 print("after RLE ",owner()," next valid ",rle.find_next_valid_focus().name);await key(KEY_TAB);print("next Tab ",owner())
 scene.queue_free();await settle();quit()
