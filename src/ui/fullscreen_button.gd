class_name FullscreenButton
extends Button


func _ready() -> void:
	name = "FullscreenButton"
	custom_minimum_size = Vector2(92.0, 38.0)
	add_theme_font_size_override("font_size", UiTypography.CAPTION_SIZE)
	tooltip_text = Localization.text(&"window.fullscreen.tooltip")
	pressed.connect(WindowMode.toggle_fullscreen)
	WindowMode.window_mode_changed.connect(_refresh)
	_refresh(WindowMode.is_fullscreen())


func _refresh(fullscreen: bool) -> void:
	text = Localization.text(
		&"window.fullscreen.exit" if fullscreen else &"window.fullscreen.enter"
	)
