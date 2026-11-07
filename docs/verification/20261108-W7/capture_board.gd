extends SceneTree
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func run() -> void:
 root.size = Vector2i(1280, 720)
 var english: bool = "--locale=en" in OS.get_cmdline_user_args()
 root.get_node("Localization").set_locale("en" if english else "zh_CN")
 var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
 root.add_child(hub)
 current_scene = hub
 for frame: int in 180: await process_frame
 var room = hub.get_node("Laboratory").room
 var sheet: SubViewport = room._board_viewport
 check(room._board_rows.size() == 11, "Exactly eleven chapter rows")
 var previous_bottom: float = 0.0
 for row: Dictionary in room._board_rows:
  var strip: Rect2 = row.strip.get_global_rect()
  var name_label: Label = row.name
  var count: Label = row.count
  var name_rect: Rect2 = name_label.get_global_rect()
  var count_rect: Rect2 = count.get_global_rect()
  check(strip.position.y >= previous_bottom, "Chapter rows do not overlap")
  check(strip.end.y <= sheet.size.y, "Chapter row stays inside board")
  check(strip.encloses(name_rect) and strip.encloses(count_rect), "Name and count stay inside their own row")
  check(name_rect.end.x <= count_rect.position.x, "Name and right-column count do not overlap")
  check(absf(name_rect.get_center().y - count_rect.get_center().y) < 1.0, "Name and count share one row center")
  check(name_label.get_theme_font_size("font_size") == 30 and count.get_theme_font_size("font_size") == 27, "Readable 30/27 px type")
  var font: Font = name_label.get_theme_font("font")
  check(font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x <= name_rect.size.x, "Full chapter name fits: " + name_label.text)
  previous_bottom = strip.end.y
 var optional: Label = room._board_rows[7].count
 check(optional.text == ("3 items" if english else "3 项"), "Optional exploration has its own compact count")
 await RenderingServer.frame_post_draw
 var suffix: String = "-en" if english else ""
 root.get_texture().get_image().save_png("res://docs/verification/20261108-W7/after-lab" + suffix + ".png")
 sheet.get_texture().get_image().save_png("res://docs/verification/20261108-W7/after-board" + suffix + ".png")
 print("W7_BOARD ", "en" if english else "zh_CN", " failures=", failures)
 quit(0 if failures == 0 else 1)
