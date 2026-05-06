extends RefCounted
class_name HudStatusPanelsController


func build_hero_section(parent: HBoxContainer, config: Dictionary, callbacks: Dictionary = {}) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.5
	var sb := StyleBoxFlat.new()
	sb.bg_color = config.get("panel_bg", Color(0.06, 0.05, 0.1, 1.0))
	sb.border_color = config.get("panel_border", Color(0.45, 0.35, 0.1, 1.0))
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var margin_left := MarginContainer.new()
	margin_left.add_theme_constant_override("margin_left", 8)
	margin_left.add_theme_constant_override("margin_top", 8)
	margin_left.add_theme_constant_override("margin_bottom", 8)
	hbox.add_child(margin_left)

	var portrait_rect := ColorRect.new()
	portrait_rect.custom_minimum_size = Vector2(100, 0)
	portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_rect.color = config.get("portrait_bg", Color(0.05, 0.04, 0.08, 1.0))
	margin_left.add_child(portrait_rect)

	var portrait_border := ReferenceRect.new()
	portrait_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_border.border_color = config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
	portrait_border.border_width = 2.0
	portrait_border.editor_only = false
	portrait_rect.add_child(portrait_border)

	var portrait_label := Label.new()
	portrait_label.text = "HERO"
	portrait_label.set_anchors_preset(Control.PRESET_CENTER)
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	portrait_label.add_theme_font_size_override("font_size", 14)
	portrait_rect.add_child(portrait_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 6)
	info_vbox.add_child(spacer_top)

	var name_label := Label.new()
	name_label.text = "英雄信息"
	name_label.add_theme_color_override("font_color", config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0)))
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)

	var hp_container := _create_bar_row("HP", config.get("hp_bar_color", Color(0.1, 0.85, 0.1, 1.0)), config)
	info_vbox.add_child(hp_container)
	var hero_hp_bar := hp_container.get_node("Bar") as ProgressBar
	var hero_hp_label := hp_container.get_node("ValueLabel") as Label

	var mp_container := _create_bar_row("MP", config.get("mp_bar_color", Color(0.15, 0.35, 0.95, 1.0)), config)
	info_vbox.add_child(mp_container)
	var hero_mp_bar := mp_container.get_node("Bar") as ProgressBar
	hero_mp_bar.value = 100
	var hero_mp_label := mp_container.get_node("ValueLabel") as Label
	hero_mp_label.text = "100 / 100"

	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 20)
	info_vbox.add_child(stats_hbox)
	var atk_label := _create_stat_label(stats_hbox, "攻击: 20", config)
	var def_label := _create_stat_label(stats_hbox, "护甲: 5", config)
	var spd_label := _create_stat_label(stats_hbox, "移速: 200", config)

	var combat_hbox := HBoxContainer.new()
	combat_hbox.add_theme_constant_override("separation", 20)
	info_vbox.add_child(combat_hbox)
	var atk_speed_label := _create_stat_label(combat_hbox, "攻速: 2.00", config)
	var atk_interval_label := _create_stat_label(combat_hbox, "攻间隔: 0.50", config)
	var atk_range_label := _create_stat_label(combat_hbox, "攻距: 250", config)
	var cdr_label := _create_stat_label(combat_hbox, "冷却减免: 0.0%", config)

	var crit_hbox := HBoxContainer.new()
	crit_hbox.add_theme_constant_override("separation", 20)
	info_vbox.add_child(crit_hbox)
	var phys_crit_rate_label := _create_stat_label(crit_hbox, "物暴率: 0.0%", config)
	var phys_crit_mul_label := _create_stat_label(crit_hbox, "物暴倍: 2.00x", config)
	var spell_crit_rate_label := _create_stat_label(crit_hbox, "法暴率: 0.0%", config)
	var spell_crit_mul_label := _create_stat_label(crit_hbox, "法暴倍: 2.00x", config)

	var regen_hbox := HBoxContainer.new()
	regen_hbox.add_theme_constant_override("separation", 20)
	info_vbox.add_child(regen_hbox)
	var hp_regen_label := _create_stat_label(regen_hbox, "回血: 0.00/s", config)
	var mp_regen_label := _create_stat_label(regen_hbox, "回蓝: 0.00/s", config)

	var attr_hbox := HBoxContainer.new()
	attr_hbox.add_theme_constant_override("separation", 20)
	info_vbox.add_child(attr_hbox)
	var str_label := _create_stat_label(attr_hbox, "力量: 24", config)
	var agi_label := _create_stat_label(attr_hbox, "敏捷: 12", config)
	var int_label := _create_stat_label(attr_hbox, "智力: 14", config)

	var inv_margin := MarginContainer.new()
	inv_margin.add_theme_constant_override("margin_top", 8)
	inv_margin.add_theme_constant_override("margin_right", 8)
	inv_margin.add_theme_constant_override("margin_bottom", 8)
	hbox.add_child(inv_margin)

	var inv_vbox := VBoxContainer.new()
	inv_vbox.add_theme_constant_override("separation", 2)
	inv_margin.add_child(inv_vbox)

	var inv_title := Label.new()
	inv_title.text = "物品栏"
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_title.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	inv_title.add_theme_font_size_override("font_size", 11)
	inv_vbox.add_child(inv_title)

	var inv_grid := GridContainer.new()
	inv_grid.columns = 2
	inv_grid.add_theme_constant_override("h_separation", 3)
	inv_grid.add_theme_constant_override("v_separation", 3)
	inv_vbox.add_child(inv_grid)

	var inventory_slots: Array = []
	var inventory_icons: Array = []
	for i in range(6):
		var slot := _create_inventory_slot(i + 1, config)
		inv_grid.add_child(slot)
		inventory_slots.append(slot)
		var on_gui_input: Callable = callbacks.get("on_inv_slot_input", Callable())
		if on_gui_input != null and on_gui_input.is_valid():
			slot.gui_input.connect(on_gui_input.bind(i))
		var on_mouse_entered: Callable = callbacks.get("on_inv_slot_mouse_entered", Callable())
		if on_mouse_entered != null and on_mouse_entered.is_valid():
			slot.mouse_entered.connect(on_mouse_entered.bind(i))
		var on_mouse_exited: Callable = callbacks.get("on_inv_slot_mouse_exited", Callable())
		if on_mouse_exited != null and on_mouse_exited.is_valid():
			slot.mouse_exited.connect(on_mouse_exited.bind(i))
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var tex_rect := TextureRect.new()
		tex_rect.name = "ItemIcon"
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.visible = false
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tex_rect)
		inventory_icons.append(tex_rect)

	return {
		"portrait_rect": portrait_rect,
		"hero_name_label": name_label,
		"hero_hp_bar": hero_hp_bar,
		"hero_hp_label": hero_hp_label,
		"hero_mp_bar": hero_mp_bar,
		"hero_mp_label": hero_mp_label,
		"atk_label": atk_label,
		"def_label": def_label,
		"spd_label": spd_label,
		"atk_speed_label": atk_speed_label,
		"atk_interval_label": atk_interval_label,
		"atk_range_label": atk_range_label,
		"cdr_label": cdr_label,
		"phys_crit_rate_label": phys_crit_rate_label,
		"phys_crit_mul_label": phys_crit_mul_label,
		"spell_crit_rate_label": spell_crit_rate_label,
		"spell_crit_mul_label": spell_crit_mul_label,
		"hp_regen_label": hp_regen_label,
		"mp_regen_label": mp_regen_label,
		"str_label": str_label,
		"agi_label": agi_label,
		"int_label": int_label,
		"inventory_panel_root": inv_margin,
		"inventory_slots": inventory_slots,
		"inventory_icons": inventory_icons,
	}


func build_boss_section(parent: HBoxContainer, config: Dictionary) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = config.get("boss_panel_bg", Color(0.1, 0.04, 0.04, 1.0))
	sb.border_color = config.get("boss_panel_border", Color(0.7, 0.2, 0.15, 1.0))
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var margin_top := MarginContainer.new()
	margin_top.add_theme_constant_override("margin_left", 8)
	margin_top.add_theme_constant_override("margin_top", 6)
	margin_top.add_theme_constant_override("margin_right", 8)
	vbox.add_child(margin_top)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin_top.add_child(inner_vbox)

	var boss_title := Label.new()
	boss_title.text = "★ BOSS - %s" % str(config.get("boss_display_name", "BOSS"))
	boss_title.add_theme_color_override("font_color", config.get("boss_title_color", Color(1.0, 0.4, 0.3, 1.0)))
	boss_title.add_theme_font_size_override("font_size", 14)
	inner_vbox.add_child(boss_title)

	var boss_portrait_rect := ColorRect.new()
	boss_portrait_rect.custom_minimum_size = Vector2(0, 50)
	boss_portrait_rect.color = config.get("boss_portrait_bg", Color(0.08, 0.03, 0.03, 1.0))
	inner_vbox.add_child(boss_portrait_rect)

	var boss_portrait_label := Label.new()
	boss_portrait_label.text = "BOSS"
	boss_portrait_label.set_anchors_preset(Control.PRESET_CENTER)
	boss_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_portrait_label.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	boss_portrait_label.add_theme_font_size_override("font_size", 11)
	boss_portrait_rect.add_child(boss_portrait_label)

	var hp_row := _create_bar_row("HP", config.get("boss_hp_bar_color", Color(0.9, 0.2, 0.15, 1.0)), config)
	inner_vbox.add_child(hp_row)
	var boss_hp_bar := hp_row.get_node("Bar") as ProgressBar
	var boss_hp_label := hp_row.get_node("ValueLabel") as Label

	return {
		"boss_portrait_rect": boss_portrait_rect,
		"boss_hp_bar": boss_hp_bar,
		"boss_hp_label": boss_hp_label,
	}


func _create_bar_row(label_text: String, bar_color: Color, config: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(28, 0)
	lbl.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(160, 18)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.1, 0.15, 1.0)
	bar_bg.border_color = Color(0.3, 0.25, 0.2, 1.0)
	bar_bg.set_border_width_all(1)
	bar_bg.corner_radius_top_left = 2
	bar_bg.corner_radius_top_right = 2
	bar_bg.corner_radius_bottom_left = 2
	bar_bg.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = bar_color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", bar_fill)
	row.add_child(bar)

	var val_label := Label.new()
	val_label.name = "ValueLabel"
	val_label.text = "--- / ---"
	val_label.custom_minimum_size = Vector2(100, 0)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.add_theme_color_override("font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0)))
	val_label.add_theme_font_size_override("font_size", 12)
	row.add_child(val_label)

	return row


func _create_stat_label(parent: HBoxContainer, text: String, config: Dictionary) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.add_theme_color_override("font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0)))
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	return lbl


func _create_inventory_slot(index: int, config: Dictionary) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(38, 38)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 1.0)
	sb.border_color = config.get("panel_border", Color(0.45, 0.35, 0.1, 1.0))
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	slot.add_theme_stylebox_override("panel", sb)

	var num_label := Label.new()
	num_label.text = str(index)
	num_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	num_label.position = Vector2(-12, -18)
	num_label.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2, 0.6))
	num_label.add_theme_font_size_override("font_size", 10)
	slot.add_child(num_label)
	return slot
