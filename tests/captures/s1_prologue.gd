extends "res://tests/test_half_adder_reseal_progression.gd"
var phase := "review"
func shot(label: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://.godot/s1b/" + phase + "-" + label + ".png")
func official() -> void:
 main.official_button.pressed.emit()
 while main.official_sequence_active:
  if main.playback_running: main._finish_playback()
  await process_frame
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
 root.size = Vector2i(1280,720)
 root.get_node("GameMode").set_mode(&"game")
 navigation = root.get_node("TaskNavigation")
 navigation.pending = ""
 navigation.from_tree = false
 save = root.get_node("GlobalSave")
 save.configure_for_test("user://capture-save.json", "user://capture-boards.json")
 save.load_game()
 await open_workbench()
 assert(await earn_tutorial())
 assert(await open_level(&"half_adder"))
 await shot("entry")
 for wire: Dictionary in main._half_adder_reference_wires():
  main._on_connection_request(wire.from_node, wire.get("from_port",0), wire.to_node, wire.get("to_port",0))
 await settle(12)
 main._focus_circuit(true)
 main.input_a_button.button_pressed = true
 main.input_b_button.button_pressed = true
 main.bench_debug_button.pressed.emit()
 main.playback_running = false
 for i: int in range(main.playback_batches.size()):
  main.playback_index = i
  main._show_playback_batch(main.playback_batches[i],0.5)
  await shot("wave%d" % i)
  main._show_playback_batch(main.playback_batches[i],1.0)
 main._finish_playback()
 var sum_wire: Dictionary
 for w: Dictionary in main.graph.get_connection_list():
  if w.to_node == &"SUM_OUT": sum_wire = w

 if not sum_wire.is_empty():
  main._on_disconnection_request(sum_wire.from_node,sum_wire.from_port,sum_wire.to_node,sum_wire.to_port)
  main._on_connection_request(&"A_IN",0,sum_wire.to_node,sum_wire.to_port)
 await official()
 await settle(12)
 await shot("failure")
 if not sum_wire.is_empty():
  main._on_disconnection_request(&"A_IN",0,sum_wire.to_node,sum_wire.to_port)
  main._on_connection_request(sum_wire.from_node,sum_wire.from_port,sum_wire.to_node,sum_wire.to_port)
 await official()
 assert(main.official_passed)
 main.level_completion_overlay.primary_action_button.pressed.emit()
 await create_timer(0.2).timeout
 await shot("seal-early")
 await create_timer(0.5).timeout
 await shot("seal-late")
 while main.sealing: await process_frame
 assert(main.component_library.has(&"HalfAdder"))
 await shot("sealed")
 assert(await open_level(&"full_adder"))
 await shot("arrival")
 await close_workbench()
 print("PASS: real tutorial, half-adder debug/failure/seal and earned full-adder arrival captures")
 quit()
