extends RefCounted
class_name ShopPanelController

var _ui_scale: float = 1.0
var _detail_width: float = 0.0
var _detail_min_height: float = 0.0
var _detail_max_height: float = 0.0
var _detail_est_chars_per_line: float = 26.0

var _panel: Panel = null
var _offered_grid: GridContainer = null
var _shop_level_label: Label = null
var _gold_label: Label = null
var _upgrade_btn: Button = null
var _refresh_btn: Button = null
var _detail_popup: PanelContainer = null
var _detail_label: Label = null
var _detail_timer: Timer = null
var _hover_target: Control = null
var _hover_text: String = ""


func build(
	root: Control,
	ui_scale: float,
	border_color: Color,
	border_dark_color: Color,
	text_color: Color,
	detail_width: float,
	detail_min_height: float,
	detail_max_height: float,
	detail_est_chars_per_line: float,
	close_callback: Callable,
	upgrade_callback: Callable,
	refresh_callback: Callable
) -> void:
	if root == null or not is_instance_valid(root):
		return
	if _panel != null and is_instance_valid(_panel):
		return
	_ui_scale = maxf(ui_scale, 0.1)
	_detail_width = detail_width
	_detail_min_height = detail_min_height
	_detail_max_height = detail_max_height
	_detail_est_chars_per_line = maxf(detail_est_chars_per_line, 1.0)

	_panel = Panel.new()
	_panel.name = "ShopPanel"
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	var panel_size := Vector2(_px(820.0), _px(520.0))
	var panel_half_size: Vector2 = panel_size * 0.5
	_panel.custom_minimum_size = panel_size
	_panel.offset_left = -panel_half_size.x
	_panel.offset_right = panel_half_size.x
	_panel.offset_top = -panel_half_size.y
	_panel.offset_bottom = panel_half_size.y
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.09, 0.97)
	sb.border_color = border_color
	sb.set_border_width_all(_px_i(3))
	sb.corner_radius_top_left = _px_i(8)
	sb.corner_radius_top_right = _px_i(8)
	sb.corner_radius_bottom_left = _px_i(8)
	sb.corner_radius_bottom_right = _px_i(8)
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = _px(14.0)
	vbox.offset_right = -_px(14.0)
	vbox.offset_top = _px(10.0)
	vbox.offset_bottom = -_px(10.0)
	vbox.add_theme_constant_override("separation", _px_i(8))
	_panel.add_child(vbox)

	var title_hbox := HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", _px_i(12))
	vbox.add_child(title_hbox)
	var title := Label.new()
	title.text = "巫毒商店 - 肉鸽地牢"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", border_color)
	title.add_theme_font_size_override("font_size", _px_i(20))
	title_hbox.add_child(title)
	var close_btn := Button.new()
	close_btn.text = " X "
	close_btn.add_theme_font_size_override("font_size", _px_i(16))
	close_btn.pressed.connect(close_callback)
	title_hbox.add_child(close_btn)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", _px_i(16))
	vbox.add_child(info_hbox)

	_shop_level_label = Label.new()
	_shop_level_label.add_theme_color_override("font_color", border_color)
	_shop_level_label.add_theme_font_size_override("font_size", _px_i(16))
	info_hbox.add_child(_shop_level_label)

	_gold_label = Label.new()
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_gold_label.add_theme_font_size_override("font_size", _px_i(16))
	info_hbox.add_child(_gold_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(spacer)

	_upgrade_btn = Button.new()
	_upgrade_btn.add_theme_font_size_override("font_size", _px_i(13))
	_upgrade_btn.pressed.connect(upgrade_callback)
	info_hbox.add_child(_upgrade_btn)

	_refresh_btn = Button.new()
	_refresh_btn.add_theme_font_size_override("font_size", _px_i(13))
	_refresh_btn.pressed.connect(refresh_callback)
	info_hbox.add_child(_refresh_btn)

	var sep := HSeparator.new()
	var sep_sb := StyleBoxFlat.new()
	sep_sb.bg_color = border_dark_color
	sep_sb.content_margin_top = _px_i(1)
	sep_sb.content_margin_bottom = _px_i(1)
	sep.add_theme_stylebox_override("separator", sep_sb)
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_offered_grid = GridContainer.new()
	_offered_grid.columns = 5
	_offered_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offered_grid.add_theme_constant_override("h_separation", _px_i(8))
	_offered_grid.add_theme_constant_override("v_separation", _px_i(8))
	scroll.add_child(_offered_grid)

	_build_item_detail_popup(border_color, text_color)


func set_visible(visible: bool) -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.visible = visible


func is_visible() -> bool:
	return _panel != null and is_instance_valid(_panel) and _panel.visible


func get_offered_grid() -> GridContainer:
	return _offered_grid


func update_summary(shop_level_text: String, gold_text: String) -> void:
	if _shop_level_label != null:
		_shop_level_label.text = shop_level_text
	if _gold_label != null:
		_gold_label.text = gold_text


func update_action_buttons(
	upgrade_text: String, upgrade_disabled: bool, refresh_text: String, refresh_disabled: bool
) -> void:
	if _upgrade_btn != null:
		_upgrade_btn.text = upgrade_text
		_upgrade_btn.disabled = upgrade_disabled
	if _refresh_btn != null:
		_refresh_btn.text = refresh_text
		_refresh_btn.disabled = refresh_disabled


func clear_item_hover_state() -> void:
	_hover_target = null
	_hover_text = ""
	if _detail_timer != null:
		_detail_timer.stop()
	if _detail_popup != null:
		_detail_popup.visible = false


func on_item_mouse_entered(
	item_panel: Control, detail_text: String, hover_delay_sec: float
) -> void:
	_hover_target = item_panel
	_hover_text = detail_text
	if _detail_timer != null:
		_detail_timer.stop()
		_detail_timer.start(hover_delay_sec)


func on_item_mouse_exited(item_panel: Control, mouse_pos: Vector2) -> void:
	if item_panel == null:
		return
	if item_panel.get_global_rect().has_point(mouse_pos):
		return
	if _hover_target == item_panel:
		clear_item_hover_state()


func _build_item_detail_popup(border_color: Color, text_color: Color) -> void:
	_detail_popup = PanelContainer.new()
	_detail_popup.visible = false
	_detail_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_popup.custom_minimum_size = Vector2(_detail_width, _detail_min_height)
	_detail_popup.z_index = 50
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.05, 0.98)
	panel_style.border_color = border_color
	panel_style.set_border_width_all(_px_i(2))
	panel_style.corner_radius_top_left = _px_i(6)
	panel_style.corner_radius_top_right = _px_i(6)
	panel_style.corner_radius_bottom_left = _px_i(6)
	panel_style.corner_radius_bottom_right = _px_i(6)
	_detail_popup.add_theme_stylebox_override("panel", panel_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", _px_i(8))
	margin.add_theme_constant_override("margin_right", _px_i(8))
	margin.add_theme_constant_override("margin_top", _px_i(6))
	margin.add_theme_constant_override("margin_bottom", _px_i(6))
	_detail_popup.add_child(margin)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail_label.add_theme_color_override("font_color", text_color)
	_detail_label.add_theme_font_size_override("font_size", _px_i(13))
	_detail_label.custom_minimum_size = Vector2(
		_detail_width - _px(24.0), _detail_min_height - _px(18.0)
	)
	margin.add_child(_detail_label)
	_panel.add_child(_detail_popup)

	_detail_timer = Timer.new()
	_detail_timer.one_shot = true
	_detail_timer.timeout.connect(_on_detail_hover_timeout)
	_panel.add_child(_detail_timer)


func _on_detail_hover_timeout() -> void:
	if _hover_target == null:
		return
	if not is_instance_valid(_hover_target):
		clear_item_hover_state()
		return
	var text: String = _hover_text.strip_edges()
	if text == "":
		return
	var viewport := _panel.get_viewport() if _panel != null else null
	if viewport == null:
		return
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	if not _hover_target.get_global_rect().has_point(mouse_pos):
		return
	_show_item_detail(_hover_target, text)


func _show_item_detail(item_panel: Control, detail_text: String) -> void:
	if _detail_popup == null or _detail_label == null:
		return
	var compact_text: String = detail_text.strip_edges()
	_detail_label.text = compact_text
	var line_break_count: int = compact_text.count("\n")
	var estimated_lines: int = (
		line_break_count + int(ceil(float(compact_text.length()) / _detail_est_chars_per_line))
	)
	estimated_lines = clampi(estimated_lines, 4, 8)
	var target_height: float = clampf(
		_px(24.0) + float(estimated_lines) * _px(18.0), _detail_min_height, _detail_max_height
	)
	var target_size := Vector2(_detail_width, target_height)
	_detail_popup.custom_minimum_size = target_size
	_detail_popup.size = target_size
	_detail_label.custom_minimum_size = Vector2(
		_detail_width - _px(24.0), target_height - _px(18.0)
	)
	_detail_popup.visible = true
	call_deferred("_position_item_detail_popup", item_panel)


func _position_item_detail_popup(item_panel: Control) -> void:
	if _detail_popup == null or item_panel == null or not is_instance_valid(item_panel):
		return
	var popup_size: Vector2 = _detail_popup.size
	if popup_size.x <= 1.0 or popup_size.y <= 1.0:
		popup_size = _detail_popup.get_combined_minimum_size()
	var rect: Rect2 = item_panel.get_global_rect()
	var viewport := _panel.get_viewport() if _panel != null else null
	if viewport == null:
		return
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	var pos := Vector2(rect.position.x + rect.size.x + 10.0, rect.position.y)
	if pos.x + popup_size.x > viewport_rect.position.x + viewport_rect.size.x - 8.0:
		pos.x = rect.position.x - popup_size.x - 10.0
	pos.x = clampf(
		pos.x,
		viewport_rect.position.x + 8.0,
		viewport_rect.position.x + viewport_rect.size.x - popup_size.x - 8.0
	)
	pos.y = clampf(
		pos.y,
		viewport_rect.position.y + 8.0,
		viewport_rect.position.y + viewport_rect.size.y - popup_size.y - 8.0
	)
	_detail_popup.global_position = pos


func _px(value: float) -> float:
	return value * _ui_scale


func _px_i(value: int) -> int:
	return roundi(float(value) * _ui_scale)
