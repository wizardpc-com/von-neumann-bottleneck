extends RefCounted
## Optional local artwork. Application/save identity is deliberately outside this file.
const CONFIG := "res://assets/branding/brand.cfg"
static func settings() -> Dictionary:
	var config := ConfigFile.new()
	var result: Dictionary = {}
	if config.load(CONFIG)!=OK: return result
	for key: String in ["revision","app_icon","logo_zh","logo_en","symbol","native_icon_windows","native_icon_macos"]:
		result[key]=str(config.get_value("brand",key,""))
	return result

static func texture(path: String) -> Texture2D:
	if path.is_empty() or not path.begins_with("res://assets/branding/") or not ResourceLoader.exists(path): return null
	var resource: Resource=load(path)
	return resource as Texture2D

static func title_slot(locale: String, title: Label, values: Dictionary = {}) -> Control:
	if values.is_empty(): values=settings()
	var logo: Texture2D=texture(str(values.get("logo_zh" if locale.begins_with("zh") else "logo_en","")))
	var symbol: Texture2D=texture(str(values.get("symbol","")))
	if logo==null and symbol==null: return title
	var box := CenterContainer.new()
	box.name="BrandLogoSlot"; box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",12);box.add_child(row)
	if symbol!=null:
		var mark := TextureRect.new();mark.texture=symbol
		mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.custom_minimum_size=Vector2(40,40);mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(mark)
	if logo!=null and logo.get_width()>0 and logo.get_height()>0:
		var view := TextureRect.new()
		view.texture=logo; view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.custom_minimum_size=Vector2(360,64)
		view.mouse_filter=Control.MOUSE_FILTER_IGNORE; view.focus_mode=Control.FOCUS_NONE
		row.add_child(view);title.free()
	else: row.add_child(title)
	return box
