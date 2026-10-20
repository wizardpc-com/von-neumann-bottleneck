class_name GameModeSelector
extends HBoxContainer

var show_label: bool = true
var option_button: OptionButton


func _ready() -> void:
	# Sits centred in header rows instead of stretching to the row height.
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visible = GameMode.developer_tools_enabled()
	add_theme_constant_override("separation", 6)
	if show_label:
		var label := Label.new()
		label.text = Localization.text(&"mode.selector.label")
		label.add_theme_color_override("font_color", Color("8fa3ad"))
		add_child(label)
	option_button = OptionButton.new()
	option_button.name = "ModeOption"
	option_button.tooltip_text = Localization.text(&"mode.selector.tooltip")
	option_button.add_item(Localization.text(&"mode.game"), 0)
	option_button.add_item(Localization.text(&"mode.test"), 1)
	option_button.select(maxi(0, GameMode.mode_index()))
	option_button.item_selected.connect(_on_item_selected)
	add_child(option_button)
	GameMode.mode_changed.connect(_on_mode_changed)


func _on_item_selected(index: int) -> void:
	GameMode.set_mode(GameMode.mode_at(index))


func _on_mode_changed(_mode: StringName) -> void:
	if option_button != null:
		option_button.select(maxi(0, GameMode.mode_index()))
