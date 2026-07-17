extends RefCounted
class_name HudStatusPanelsController


func build_hero_section(
	parent: Control, config: Dictionary, callbacks: Dictionary = {}
) -> Dictionary:
	if bool(config.get("fixed_layout", false)):
		return _build_hero_section_fixed(parent, config, callbacks)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = float(config.get("stretch_ratio", 1.55))
	panel.add_theme_stylebox_override("panel", _get_panel_stylebox(config))
	parent.add_child(panel)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override(
		"margin_left", int(config.get("outer_margin_left", 10))
	)
	outer_margin.add_theme_constant_override("margin_top", int(config.get("outer_margin_top", 8)))
	outer_margin.add_theme_constant_override(
		"margin_right", int(config.get("outer_margin_right", 10))
	)
	outer_margin.add_theme_constant_override(
		"margin_bottom", int(config.get("outer_margin_bottom", 8))
	)
	panel.add_child(outer_margin)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", int(config.get("section_separation", 12)))
	outer_margin.add_child(hbox)

	var portrait_column := VBoxContainer.new()
	var portrait_size := float(config.get("portrait_size", 138.0))
	var portrait_column_width := float(config.get("portrait_column_width", portrait_size))
	portrait_column.custom_minimum_size = Vector2(portrait_column_width, 0)
	portrait_column.add_theme_constant_override("separation", 4)
	hbox.add_child(portrait_column)

	var portrait_center := CenterContainer.new()
	portrait_center.custom_minimum_size = Vector2(portrait_column_width, portrait_size)
	portrait_column.add_child(portrait_center)

	var portrait_square := AspectRatioContainer.new()
	portrait_square.ratio = 1.0
	portrait_square.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	portrait_square.custom_minimum_size = Vector2(portrait_size, portrait_size)
	portrait_center.add_child(portrait_square)

	var portrait_rect := ColorRect.new()
	portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_rect.color = config.get("portrait_bg", Color(0.05, 0.04, 0.08, 1.0))
	portrait_square.add_child(portrait_rect)

	var portrait_texture_rect := TextureRect.new()
	portrait_texture_rect.name = "PortraitTexture"
	portrait_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var portrait_inset := int(config.get("portrait_inset", 6))
	portrait_texture_rect.offset_left = portrait_inset
	portrait_texture_rect.offset_top = portrait_inset
	portrait_texture_rect.offset_right = -portrait_inset
	portrait_texture_rect.offset_bottom = -portrait_inset
	portrait_texture_rect.texture = config.get("portrait_texture", null) as Texture2D
	portrait_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_texture_rect.visible = portrait_texture_rect.texture != null
	portrait_rect.add_child(portrait_texture_rect)

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
	portrait_label.add_theme_color_override(
		"font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
	)
	portrait_label.add_theme_font_size_override("font_size", 14)
	portrait_label.visible = portrait_texture_rect.texture == null
	portrait_rect.add_child(portrait_label)

	var hp_refs := _create_portrait_bar_row(
		"HP", config.get("hp_bar_color", Color(0.1, 0.85, 0.1, 1.0)), config, portrait_size - 16.0
	)
	portrait_column.add_child(hp_refs.get("root"))
	var hero_hp_bar := hp_refs.get("bar") as ProgressBar
	var hero_hp_label := hp_refs.get("value_label") as Label

	var mp_refs := _create_portrait_bar_row(
		"MP", config.get("mp_bar_color", Color(0.15, 0.35, 0.95, 1.0)), config, portrait_size - 16.0
	)
	portrait_column.add_child(mp_refs.get("root"))
	var hero_mp_bar := mp_refs.get("bar") as ProgressBar
	hero_mp_bar.value = 100
	var hero_mp_label := mp_refs.get("value_label") as Label
	hero_mp_label.text = "100 / 100"

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = "英雄信息"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override(
		"font_color", config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
	)
	name_label.add_theme_font_size_override("font_size", 17)
	info_vbox.add_child(name_label)

	var stats_title := Label.new()
	stats_title.text = "属性"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_color_override(
		"font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
	)
	stats_title.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(stats_title)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 3)
	info_vbox.add_child(stats_grid)
	var str_label := _create_stat_label(stats_grid, "力量: 24", config)
	var agi_label := _create_stat_label(stats_grid, "敏捷: 12", config)
	var int_label := _create_stat_label(stats_grid, "智力: 14", config)
	var atk_label := _create_stat_label(stats_grid, "攻击: 20", config)
	var def_label := _create_stat_label(stats_grid, "护甲: 5", config)
	var spd_label := _create_stat_label(stats_grid, "移速: 200", config)
	var atk_speed_label := _create_stat_label(stats_grid, "攻速: 2.00", config)
	var atk_range_label := _create_stat_label(stats_grid, "攻距: 250", config)
	var cdr_label := _create_stat_label(stats_grid, "冷却减免: 0.0%", config)
	var hp_regen_label := _create_stat_label(stats_grid, "回血: 0.00/s", config)
	var mp_regen_label := _create_stat_label(stats_grid, "回蓝: 0.00/s", config)
	var phys_crit_rate_label := _create_stat_label(stats_grid, "物暴率: 0.0%", config)
	var phys_crit_mul_label := _create_stat_label(stats_grid, "物暴倍: 2.00x", config)
	var spell_crit_rate_label := _create_stat_label(stats_grid, "法暴率: 0.0%", config)
	var spell_crit_mul_label := _create_stat_label(stats_grid, "法暴倍: 2.00x", config)
	var atk_interval_label := _create_stat_label(stats_grid, "攻间隔: 0.50", config)

	var inv_panel := PanelContainer.new()
	inv_panel.custom_minimum_size = Vector2(float(config.get("inventory_panel_width", 152.0)), 0)
	inv_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_panel.add_theme_stylebox_override("panel", _get_inventory_panel_stylebox(config))
	hbox.add_child(inv_panel)

	var inv_margin := MarginContainer.new()
	inv_margin.add_theme_constant_override(
		"margin_left", int(config.get("inventory_grid_margin_left", 8))
	)
	inv_margin.add_theme_constant_override(
		"margin_top", int(config.get("inventory_grid_margin_top", 6))
	)
	inv_margin.add_theme_constant_override(
		"margin_right", int(config.get("inventory_grid_margin_right", 8))
	)
	inv_margin.add_theme_constant_override(
		"margin_bottom", int(config.get("inventory_grid_margin_bottom", 6))
	)
	inv_panel.add_child(inv_margin)

	var inv_vbox := VBoxContainer.new()
	inv_vbox.add_theme_constant_override("separation", 6)
	inv_margin.add_child(inv_vbox)

	var inv_title := Label.new()
	inv_title.text = "物品栏"
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_title.add_theme_color_override(
		"font_color", config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
	)
	inv_title.add_theme_font_size_override("font_size", 13)
	inv_vbox.add_child(inv_title)

	var inv_grid := GridContainer.new()
	inv_grid.columns = 2
	inv_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inv_grid.add_theme_constant_override(
		"h_separation", int(config.get("inventory_grid_h_separation", 6))
	)
	inv_grid.add_theme_constant_override(
		"v_separation", int(config.get("inventory_grid_v_separation", 6))
	)
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
		var icon_inset := int(config.get("inventory_icon_inset", 0))
		tex_rect.offset_left = icon_inset
		tex_rect.offset_top = icon_inset
		tex_rect.offset_right = -icon_inset
		tex_rect.offset_bottom = -icon_inset
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.visible = false
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tex_rect)
		inventory_icons.append(tex_rect)

	return {
		"portrait_rect": portrait_rect,
		"hero_portrait_texture_rect": portrait_texture_rect,
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
		"inventory_panel_root": inv_panel,
		"inventory_slots": inventory_slots,
		"inventory_icons": inventory_icons,
	}


func _build_hero_section_fixed(
	parent: Control, config: Dictionary, callbacks: Dictionary = {}
) -> Dictionary:
	var hero_rect: Rect2 = config.get("hero_rect", Rect2(504, 36, 443, 354))
	var hero_panel := Control.new()
	hero_panel.position = hero_rect.position
	hero_panel.size = hero_rect.size
	hero_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hero_panel)

	var portrait_size := float(config.get("portrait_size", 150.0))
	var portrait_rect := ColorRect.new()
	portrait_rect.position = Vector2(30, 45)
	portrait_rect.size = Vector2(portrait_size, portrait_size)
	portrait_rect.color = config.get("portrait_bg", Color(0.05, 0.04, 0.08, 1.0))
	hero_panel.add_child(portrait_rect)

	var portrait_texture_rect := TextureRect.new()
	portrait_texture_rect.name = "PortraitTexture"
	portrait_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var portrait_inset := int(config.get("portrait_inset", 6))
	portrait_texture_rect.offset_left = portrait_inset
	portrait_texture_rect.offset_top = portrait_inset
	portrait_texture_rect.offset_right = -portrait_inset
	portrait_texture_rect.offset_bottom = -portrait_inset
	portrait_texture_rect.texture = config.get("portrait_texture", null) as Texture2D
	portrait_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_texture_rect.visible = portrait_texture_rect.texture != null
	portrait_rect.add_child(portrait_texture_rect)

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
	portrait_label.add_theme_color_override(
		"font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
	)
	portrait_label.add_theme_font_size_override("font_size", 14)
	portrait_label.visible = portrait_texture_rect.texture == null
	portrait_rect.add_child(portrait_label)

	var hp_refs := _create_fixed_bar(
		"HP",
		Vector2(30, 216),
		Vector2(188, 24),
		config.get("hp_bar_color", Color(0.1, 0.85, 0.1, 1.0)),
		config
	)
	hero_panel.add_child(hp_refs.get("root"))
	var hero_hp_bar := hp_refs.get("bar") as ProgressBar
	var hero_hp_label := hp_refs.get("value_label") as Label

	var mp_refs := _create_fixed_bar(
		"MP",
		Vector2(30, 250),
		Vector2(188, 24),
		config.get("mp_bar_color", Color(0.15, 0.35, 0.95, 1.0)),
		config
	)
	hero_panel.add_child(mp_refs.get("root"))
	var hero_mp_bar := mp_refs.get("bar") as ProgressBar
	hero_mp_bar.value = 100
	var hero_mp_label := mp_refs.get("value_label") as Label
	hero_mp_label.text = "100 / 100"

	var name_label := Label.new()
	name_label.text = "英雄信息"
	name_label.position = Vector2(286, 33)
	name_label.size = Vector2(500, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override(
		"font_color", config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
	)
	name_label.add_theme_font_size_override("font_size", 18)
	hero_panel.add_child(name_label)

	var stats_title := Label.new()
	stats_title.text = "属性"
	stats_title.position = Vector2(286, 64)
	stats_title.size = Vector2(500, 22)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_color_override(
		"font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
	)
	stats_title.add_theme_font_size_override("font_size", 13)
	hero_panel.add_child(stats_title)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.position = Vector2(286, 98)
	stats_grid.size = Vector2(500, 254)
	stats_grid.add_theme_constant_override("h_separation", 92)
	stats_grid.add_theme_constant_override("v_separation", 8)
	hero_panel.add_child(stats_grid)
	var str_label := _create_stat_label(stats_grid, "力量: 24", config)
	var agi_label := _create_stat_label(stats_grid, "敏捷: 12", config)
	var int_label := _create_stat_label(stats_grid, "智力: 14", config)
	var atk_label := _create_stat_label(stats_grid, "攻击: 20", config)
	var def_label := _create_stat_label(stats_grid, "护甲: 5", config)
	var spd_label := _create_stat_label(stats_grid, "移速: 200", config)
	var atk_speed_label := _create_stat_label(stats_grid, "攻速: 2.00", config)
	var atk_range_label := _create_stat_label(stats_grid, "攻距: 250", config)
	var cdr_label := _create_stat_label(stats_grid, "冷却减免: 0.0%", config)
	var hp_regen_label := _create_stat_label(stats_grid, "回血: 0.00/s", config)
	var mp_regen_label := _create_stat_label(stats_grid, "回蓝: 0.00/s", config)
	var phys_crit_rate_label := _create_stat_label(stats_grid, "物暴率: 0.0%", config)
	var phys_crit_mul_label := _create_stat_label(stats_grid, "物暴倍: 2.00x", config)
	var spell_crit_rate_label := _create_stat_label(stats_grid, "法暴率: 0.0%", config)
	var spell_crit_mul_label := _create_stat_label(stats_grid, "法暴倍: 2.00x", config)
	var atk_interval_label := _create_stat_label(stats_grid, "攻间隔: 0.50", config)

	var inv_rect: Rect2 = config.get("inventory_rect", Rect2(980, 0, 333, 438))
	var inv_panel := Control.new()
	inv_panel.position = inv_rect.position
	inv_panel.size = inv_rect.size
	parent.add_child(inv_panel)

	var inv_title := Label.new()
	inv_title.text = "物品栏"
	inv_title.position = Vector2(58, 18)
	inv_title.size = Vector2(170, 28)
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_title.add_theme_color_override(
		"font_color", config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
	)
	inv_title.add_theme_font_size_override("font_size", 18)
	inv_panel.add_child(inv_title)

	var inventory_slots: Array = []
	var inventory_icons: Array = []
	var slot_rects: Array = config.get("inventory_slot_rects", [])
	for i in range(6):
		var slot := _create_inventory_slot(i + 1, config)
		if i < slot_rects.size() and slot_rects[i] is Rect2:
			var slot_rect: Rect2 = slot_rects[i]
			slot.position = slot_rect.position
			slot.size = slot_rect.size
			slot.custom_minimum_size = slot_rect.size
		inv_panel.add_child(slot)
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
		var icon_inset := int(config.get("inventory_icon_inset", 0))
		tex_rect.offset_left = icon_inset
		tex_rect.offset_top = icon_inset
		tex_rect.offset_right = -icon_inset
		tex_rect.offset_bottom = -icon_inset
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.visible = false
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tex_rect)
		inventory_icons.append(tex_rect)

	return {
		"portrait_rect": portrait_rect,
		"hero_portrait_texture_rect": portrait_texture_rect,
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
		"inventory_panel_root": inv_panel,
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
	boss_title.add_theme_color_override(
		"font_color", config.get("boss_title_color", Color(1.0, 0.4, 0.3, 1.0))
	)
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
	boss_portrait_label.add_theme_color_override(
		"font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
	)
	boss_portrait_label.add_theme_font_size_override("font_size", 11)
	boss_portrait_rect.add_child(boss_portrait_label)

	var hp_row := _create_bar_row(
		"HP", config.get("boss_hp_bar_color", Color(0.9, 0.2, 0.15, 1.0)), config
	)
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
	bar.custom_minimum_size = Vector2(160, 24)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false

	var bar_bg := _create_bar_background_stylebox()
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = bar_color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", bar_fill)
	_add_bar_frame_texture(bar, label_text, config)
	row.add_child(bar)

	var val_label := Label.new()
	val_label.name = "ValueLabel"
	val_label.text = "--- / ---"
	val_label.custom_minimum_size = Vector2(100, 0)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.add_theme_color_override(
		"font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0))
	)
	val_label.add_theme_font_size_override("font_size", 12)
	row.add_child(val_label)

	return row


func _create_portrait_bar_row(
	label_text: String, bar_color: Color, config: Dictionary, bar_width: float
) -> Dictionary:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(bar_width, 20)
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(20, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(maxf(bar_width - 24.0, 80.0), 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _create_bar_background_stylebox())
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = bar_color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", bar_fill)
	_add_bar_frame_texture(bar, label_text, config)
	row.add_child(bar)

	var val_label := Label.new()
	val_label.name = "ValueLabel"
	val_label.text = "--- / ---"
	val_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_label.add_theme_color_override(
		"font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0))
	)
	val_label.add_theme_font_size_override("font_size", 10)
	val_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(val_label)

	return {
		"root": row,
		"bar": bar,
		"value_label": val_label,
	}


func _create_fixed_bar(
	label_text: String, position: Vector2, size: Vector2, bar_color: Color, config: Dictionary
) -> Dictionary:
	var root := Control.new()
	root.position = position
	root.size = Vector2(size.x + 22.0, size.y)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(0, 0)
	lbl.size = Vector2(20, size.y)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0)))
	lbl.add_theme_font_size_override("font_size", 10)
	root.add_child(lbl)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.position = Vector2(22, 0)
	bar.size = size
	bar.custom_minimum_size = size
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _create_bar_background_stylebox())
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = bar_color
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", bar_fill)
	_add_bar_frame_texture(bar, label_text, config)
	root.add_child(bar)

	var val_label := Label.new()
	val_label.name = "ValueLabel"
	val_label.text = "--- / ---"
	val_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_label.add_theme_color_override(
		"font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0))
	)
	val_label.add_theme_font_size_override("font_size", 10)
	val_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(val_label)

	return {
		"root": root,
		"bar": bar,
		"value_label": val_label,
	}


func _create_stat_label(parent: Control, text: String, config: Dictionary) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.add_theme_color_override(
		"font_color", config.get("text_color", Color(0.95, 0.92, 0.78, 1.0))
	)
	lbl.add_theme_font_size_override("font_size", int(config.get("stat_font_size", 11)))
	parent.add_child(lbl)
	return lbl


func _create_inventory_slot(index: int, config: Dictionary) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = config.get("inventory_slot_size", Vector2(38, 38))
	slot.add_theme_stylebox_override("panel", _get_inventory_slot_stylebox(config))

	var num_label := Label.new()
	num_label.text = str(index)
	num_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	num_label.position = Vector2(-16, -20)
	num_label.add_theme_color_override("font_color", Color(0.95, 0.74, 0.2, 0.58))
	num_label.add_theme_font_size_override("font_size", 10)
	num_label.z_index = 10
	slot.add_child(num_label)
	return slot


func _get_panel_stylebox(config: Dictionary) -> StyleBox:
	var texture_stylebox := config.get("panel_stylebox", null) as StyleBox
	if texture_stylebox != null:
		return texture_stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = config.get("panel_bg", Color(0.06, 0.05, 0.1, 1.0))
	sb.border_color = config.get("panel_border", Color(0.45, 0.35, 0.1, 1.0))
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func _get_inventory_slot_stylebox(config: Dictionary) -> StyleBox:
	var texture_stylebox := config.get("inventory_slot_stylebox", null) as StyleBox
	if texture_stylebox != null:
		return texture_stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 1.0)
	sb.border_color = config.get("panel_border", Color(0.45, 0.35, 0.1, 1.0))
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	return sb


func _get_inventory_panel_stylebox(config: Dictionary) -> StyleBox:
	var texture_stylebox := config.get("inventory_panel_stylebox", null) as StyleBox
	if texture_stylebox != null:
		return texture_stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.035, 0.07, 0.72)
	sb.border_color = config.get("panel_border", Color(0.45, 0.35, 0.1, 1.0))
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	return sb


func _create_bar_background_stylebox() -> StyleBox:
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.1, 0.15, 1.0)
	bar_bg.border_color = Color(0.3, 0.25, 0.2, 1.0)
	bar_bg.set_border_width_all(1)
	bar_bg.corner_radius_top_left = 2
	bar_bg.corner_radius_top_right = 2
	bar_bg.corner_radius_bottom_left = 2
	bar_bg.corner_radius_bottom_right = 2
	return bar_bg


func _add_bar_frame_texture(bar: ProgressBar, label_text: String, config: Dictionary) -> void:
	var texture: Texture2D = null
	if label_text == "HP":
		texture = config.get("health_bar_frame_texture", null) as Texture2D
	elif label_text == "MP":
		texture = config.get("mana_bar_frame_texture", null) as Texture2D
	if texture != null:
		var frame := NinePatchRect.new()
		frame.name = "FrameTexture"
		frame.texture = texture
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.patch_margin_left = 8
		frame.patch_margin_top = 8
		frame.patch_margin_right = 8
		frame.patch_margin_bottom = 8
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.z_index = 5
		bar.add_child(frame)
