extends RefCounted
class_name ShopItemCardFactory


func create_card(
		data: Dictionary,
		index: int,
		can_buy: bool,
		buy_disabled: bool,
		ui_scale: float,
		build_name: String,
		build_color: Color,
		item_level: int,
		cost: int,
		icon_texture: Texture2D,
		tooltip_text: String,
		on_buy_pressed: Callable,
		on_hover_entered: Callable,
		on_hover_exited: Callable
	) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_px(148.0, ui_scale), _px(134.0 if can_buy else 118.0, ui_scale))
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.1, 0.08, 0.16, 1.0)
	ssb.border_color = build_color
	ssb.set_border_width_all(_px_i(2, ui_scale))
	ssb.corner_radius_top_left = _px_i(4, ui_scale)
	ssb.corner_radius_top_right = _px_i(4, ui_scale)
	ssb.corner_radius_bottom_left = _px_i(4, ui_scale)
	ssb.corner_radius_bottom_right = _px_i(4, ui_scale)
	panel.add_theme_stylebox_override("panel", ssb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", _px_i(2, ui_scale))
	panel.add_child(vbox)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var build_label := Label.new()
	build_label.text = "[%s]" % build_name
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_label.add_theme_color_override("font_color", build_color)
	build_label.add_theme_font_size_override("font_size", _px_i(9, ui_scale))
	build_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(build_label)

	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_center)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(_px(42.0, ui_scale), _px(42.0, ui_scale))
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_texture != null:
		icon.texture = icon_texture
	icon_center.add_child(icon)

	var name_label := Label.new()
	name_label.text = str(data.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", build_color)
	name_label.add_theme_font_size_override("font_size", _px_i(12, ui_scale))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "等级: Lv%d" % item_level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0, 1.0))
	level_label.add_theme_font_size_override("font_size", _px_i(10, ui_scale))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(level_label)
	panel.tooltip_text = ""

	var price_label := Label.new()
	price_label.text = "价格: %d金" % cost
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	price_label.add_theme_font_size_override("font_size", _px_i(11, ui_scale))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(price_label)

	if can_buy:
		var buy_btn := Button.new()
		buy_btn.text = "购买"
		buy_btn.add_theme_font_size_override("font_size", _px_i(11, ui_scale))
		buy_btn.disabled = buy_disabled
		buy_btn.tooltip_text = ""
		buy_btn.pressed.connect(on_buy_pressed.bind(index))
		buy_btn.mouse_entered.connect(on_hover_entered.bind(panel, tooltip_text))
		buy_btn.mouse_exited.connect(on_hover_exited.bind(panel))
		vbox.add_child(buy_btn)

	panel.mouse_entered.connect(on_hover_entered.bind(panel, tooltip_text))
	panel.mouse_exited.connect(on_hover_exited.bind(panel))
	return panel


func _px(value: float, ui_scale: float) -> float:
	return value * maxf(ui_scale, 0.1)


func _px_i(value: int, ui_scale: float) -> int:
	return roundi(float(value) * maxf(ui_scale, 0.1))
