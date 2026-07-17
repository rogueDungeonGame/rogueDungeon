extends RefCounted
class_name TalentPopupController

var _overlay: ColorRect = null
var _panel: PanelContainer = null
var _header_label: Label = null
var _subtitle_label: Label = null
var _options_row: HBoxContainer = null
var _buttons: Array[Button] = []
var _option_pressed_callback: Callable = Callable()
var _border_color: Color = Color(0.9, 0.8, 0.4, 1.0)


func build(
	root: Control,
	option_count: int,
	border_color: Color,
	subtitle_color: Color,
	option_pressed_callback: Callable
) -> void:
	if root == null or not is_instance_valid(root):
		return
	if _overlay != null and is_instance_valid(_overlay):
		return
	_option_pressed_callback = option_pressed_callback
	_border_color = border_color

	_overlay = ColorRect.new()
	_overlay.name = "TalentOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.name = "TalentPanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -520
	_panel.offset_right = 520
	_panel.offset_top = -210
	_panel.offset_bottom = 210
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	panel_style.border_color = Color(border_color.r, border_color.g, border_color.b, 0.0)
	panel_style.set_border_width_all(0)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_right = -8
	vbox.offset_top = 8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 18)
	_panel.add_child(vbox)

	_header_label = Label.new()
	_header_label.text = "Talent Choice"
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 28)
	_header_label.add_theme_color_override("font_color", border_color)
	vbox.add_child(_header_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = ""
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", subtitle_color)
	vbox.add_child(_subtitle_label)

	_options_row = HBoxContainer.new()
	_options_row.name = "TalentOptionsRow"
	_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_row.add_theme_constant_override("separation", 18)
	vbox.add_child(_options_row)

	for i in range(maxi(option_count, 0)):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 220)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98, 1.0))
		button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
		_apply_option_button_theme(button, _border_color, i)
		button.pressed.connect(_on_option_pressed.bind(i))
		_options_row.add_child(button)
		_buttons.append(button)


func show_options(
	options: Array,
	pending_choice_count: int,
	selected_counts: Dictionary,
	title: String = "Talent Choice"
) -> void:
	if _overlay == null or not is_instance_valid(_overlay):
		return
	_overlay.visible = true
	if _header_label != null:
		_header_label.text = title
	if _subtitle_label != null:
		_subtitle_label.text = "Choices left: %d" % pending_choice_count
	for i in range(_buttons.size()):
		var button: Button = _buttons[i]
		if button == null:
			continue
		if i >= options.size():
			button.visible = false
			continue
		button.visible = true
		var option_variant: Variant = options[i]
		var option: Dictionary = (
			option_variant as Dictionary if option_variant is Dictionary else {}
		)
		var option_id: String = str(option.get("id", ""))
		var option_title: String = str(option.get("title", option_id))
		var option_desc: String = str(option.get("desc", ""))
		var picked_count: int = int(selected_counts.get(option_id, 0))
		var suffix: String = ""
		if picked_count > 0:
			suffix = "  x%d" % picked_count
		button.text = "%s%s\n%s" % [option_title, suffix, option_desc]
		_apply_option_button_theme(button, _border_color, i, picked_count)


func set_visible(visible: bool) -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.visible = visible


func is_visible() -> bool:
	return _overlay != null and is_instance_valid(_overlay) and _overlay.visible


func _on_option_pressed(option_index: int) -> void:
	if _option_pressed_callback == null or not _option_pressed_callback.is_valid():
		return
	_option_pressed_callback.call(option_index)


func _apply_option_button_theme(
	button: Button, border_color: Color, option_index: int, picked_count: int = 0
) -> void:
	if button == null:
		return
	var accent: Color = _get_option_accent_color(option_index, border_color)
	var bonus_border: int = 1 if picked_count > 0 else 0
	button.add_theme_stylebox_override(
		"normal", _build_option_style(accent, 0.84, 0.92, 2 + bonus_border)
	)
	button.add_theme_stylebox_override(
		"hover", _build_option_style(accent.lightened(0.08), 0.92, 1.0, 3 + bonus_border)
	)
	button.add_theme_stylebox_override(
		"pressed", _build_option_style(accent.lightened(0.14), 0.98, 1.0, 4 + bonus_border)
	)
	button.add_theme_stylebox_override(
		"focus", _build_option_style(accent.lightened(0.18), 0.95, 1.0, 4 + bonus_border)
	)


func _get_option_accent_color(option_index: int, border_color: Color) -> Color:
	match posmod(option_index, 3):
		0:
			return border_color.lightened(0.08)
		1:
			return border_color.lerp(Color(0.34, 0.88, 1.0, 1.0), 0.45)
		2:
			return border_color.lerp(Color(1.0, 0.78, 0.36, 1.0), 0.45)
		_:
			return border_color


func _build_option_style(
	accent: Color, fill_alpha: float, border_alpha: float, border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(
		0.035 + accent.r * 0.10, 0.04 + accent.g * 0.08, 0.055 + accent.b * 0.12, fill_alpha
	)
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	style.set_border_width_all(maxi(border_width, 2))
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style
