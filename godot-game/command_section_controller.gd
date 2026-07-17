extends RefCounted
class_name CommandSectionController


func build(parent: Control, config: Dictionary) -> Dictionary:
	if bool(config.get("fixed_layout", false)):
		return _build_fixed(parent, config)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = float(config.get("stretch_ratio", 1.2))
	panel.add_theme_stylebox_override("panel", _get_panel_stylebox(config))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(config.get("panel_margin_left", 8)))
	margin.add_theme_constant_override("margin_right", int(config.get("panel_margin_right", 8)))
	margin.add_theme_constant_override("margin_top", int(config.get("panel_margin_top", 6)))
	margin.add_theme_constant_override("margin_bottom", int(config.get("panel_margin_bottom", 6)))
	panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", int(config.get("grid_h_separation", 8)))
	grid.add_theme_constant_override("v_separation", int(config.get("grid_v_separation", 8)))
	margin.add_child(grid)

	var skill_button_by_key: Dictionary = {}
	var skill_mana_masks: Dictionary = {}
	var skill_cd_masks: Dictionary = {}
	var skill_cd_mask_materials: Dictionary = {}
	var flash_cd_label: Label = null
	var haste_cd_label: Label = null
	var q_skill_name_label: Label = null
	var w_skill_name_label: Label = null
	var e_skill_name_label: Label = null
	var e_skill_cd_label: Label = null
	var r_skill_name_label: Label = null
	var r_skill_cd_label: Label = null
	var destroy_skill_panel: PanelContainer = null

	var skill_data: Array = config.get("skill_data", [])
	var slot_count: int = maxi(int(config.get("skill_slot_count", 12)), skill_data.size())
	for slot_index in range(slot_count):
		var data: Dictionary = {}
		if slot_index < skill_data.size() and skill_data[slot_index] is Dictionary:
			data = skill_data[slot_index]
		var skill_key: String = str(data.get("key", ""))
		var btn := _create_skill_button(
			skill_key,
			str(data.get("name", "")),
			bool(data.get("active", true)) and not skill_key.is_empty(),
			config
		)
		grid.add_child(btn)
		if skill_key.is_empty():
			continue
		skill_button_by_key[skill_key] = btn
		var mask_refs: Dictionary = _setup_skill_button_masks(skill_key, btn, config)
		if mask_refs.has("mana_mask"):
			skill_mana_masks[skill_key] = mask_refs["mana_mask"]
		if mask_refs.has("cd_mask"):
			skill_cd_masks[skill_key] = mask_refs["cd_mask"]
		if mask_refs.has("cd_material") and mask_refs["cd_material"] != null:
			skill_cd_mask_materials[skill_key] = mask_refs["cd_material"]
		match skill_key:
			"Q":
				flash_cd_label = btn.get_node("CDLabel") as Label
				q_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"W":
				haste_cd_label = btn.get_node("CDLabel") as Label
				w_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"E":
				e_skill_cd_label = btn.get_node("CDLabel") as Label
				e_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"R":
				r_skill_cd_label = btn.get_node("CDLabel") as Label
				r_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"F":
				destroy_skill_panel = btn
			_:
				pass

	return {
		"command_panel_root": panel,
		"skill_button_by_key": skill_button_by_key,
		"skill_mana_masks": skill_mana_masks,
		"skill_cd_masks": skill_cd_masks,
		"skill_cd_mask_materials": skill_cd_mask_materials,
		"flash_cd_label": flash_cd_label,
		"haste_cd_label": haste_cd_label,
		"q_skill_name_label": q_skill_name_label,
		"w_skill_name_label": w_skill_name_label,
		"e_skill_name_label": e_skill_name_label,
		"e_skill_cd_label": e_skill_cd_label,
		"r_skill_name_label": r_skill_name_label,
		"r_skill_cd_label": r_skill_cd_label,
		"destroy_skill_panel": destroy_skill_panel,
	}


func _build_fixed(parent: Control, config: Dictionary) -> Dictionary:
	var panel_rect: Rect2 = config.get("panel_rect", Rect2(1313, 0, 607, 438))
	var panel := Control.new()
	panel.position = panel_rect.position
	panel.size = panel_rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)

	var skill_button_by_key: Dictionary = {}
	var skill_mana_masks: Dictionary = {}
	var skill_cd_masks: Dictionary = {}
	var skill_cd_mask_materials: Dictionary = {}
	var flash_cd_label: Label = null
	var haste_cd_label: Label = null
	var q_skill_name_label: Label = null
	var w_skill_name_label: Label = null
	var e_skill_name_label: Label = null
	var e_skill_cd_label: Label = null
	var r_skill_name_label: Label = null
	var r_skill_cd_label: Label = null
	var destroy_skill_panel: PanelContainer = null

	var skill_data: Array = config.get("skill_data", [])
	var slot_rects: Array = config.get("skill_slot_rects", [])
	var slot_count: int = maxi(int(config.get("skill_slot_count", 12)), skill_data.size())
	for slot_index in range(slot_count):
		var data: Dictionary = {}
		if slot_index < skill_data.size() and skill_data[slot_index] is Dictionary:
			data = skill_data[slot_index]
		var skill_key: String = str(data.get("key", ""))
		var btn := _create_skill_button(
			skill_key,
			str(data.get("name", "")),
			bool(data.get("active", true)) and not skill_key.is_empty(),
			config
		)
		if slot_index < slot_rects.size() and slot_rects[slot_index] is Rect2:
			var slot_rect: Rect2 = slot_rects[slot_index]
			btn.position = slot_rect.position
			btn.size = slot_rect.size
			btn.custom_minimum_size = slot_rect.size
		panel.add_child(btn)
		if skill_key.is_empty():
			continue
		skill_button_by_key[skill_key] = btn
		var mask_refs: Dictionary = _setup_skill_button_masks(skill_key, btn, config)
		if mask_refs.has("mana_mask"):
			skill_mana_masks[skill_key] = mask_refs["mana_mask"]
		if mask_refs.has("cd_mask"):
			skill_cd_masks[skill_key] = mask_refs["cd_mask"]
		if mask_refs.has("cd_material") and mask_refs["cd_material"] != null:
			skill_cd_mask_materials[skill_key] = mask_refs["cd_material"]
		match skill_key:
			"Q":
				flash_cd_label = btn.get_node("CDLabel") as Label
				q_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"W":
				haste_cd_label = btn.get_node("CDLabel") as Label
				w_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"E":
				e_skill_cd_label = btn.get_node("CDLabel") as Label
				e_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"R":
				r_skill_cd_label = btn.get_node("CDLabel") as Label
				r_skill_name_label = btn.get_node_or_null("NameLabel") as Label
			"F":
				destroy_skill_panel = btn
			_:
				pass

	return {
		"command_panel_root": panel,
		"skill_button_by_key": skill_button_by_key,
		"skill_mana_masks": skill_mana_masks,
		"skill_cd_masks": skill_cd_masks,
		"skill_cd_mask_materials": skill_cd_mask_materials,
		"flash_cd_label": flash_cd_label,
		"haste_cd_label": haste_cd_label,
		"q_skill_name_label": q_skill_name_label,
		"w_skill_name_label": w_skill_name_label,
		"e_skill_name_label": e_skill_name_label,
		"e_skill_cd_label": e_skill_cd_label,
		"r_skill_name_label": r_skill_name_label,
		"r_skill_cd_label": r_skill_cd_label,
		"destroy_skill_panel": destroy_skill_panel,
	}


func _create_skill_button(
	key: String, skill_name: String, active: bool, config: Dictionary
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = config.get("skill_button_size", Vector2(60, 60))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _get_skill_button_stylebox(config, active))

	var key_label := Label.new()
	key_label.text = key
	key_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	key_label.position = Vector2(4, 2)
	key_label.add_theme_color_override(
		"font_color",
		(
			config.get("accent_color", Color(0.78, 0.66, 0.2, 1.0))
			if active
			else config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
		)
	)
	key_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(key_label)

	if skill_name != "":
		var name_label := Label.new()
		name_label.name = "NameLabel"
		name_label.text = skill_name
		name_label.set_anchors_preset(Control.PRESET_CENTER)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_color_override(
			"font_color",
			(
				config.get("text_color", Color(0.95, 0.92, 0.78, 1.0))
				if active
				else config.get("text_dim", Color(0.6, 0.55, 0.45, 1.0))
			)
		)
		name_label.add_theme_font_size_override("font_size", 12)
		panel.add_child(name_label)

	var cd_label := Label.new()
	cd_label.name = "CDLabel"
	cd_label.text = ""
	cd_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cd_label.position = Vector2(-24, -20)
	cd_label.add_theme_color_override(
		"font_color", config.get("cooldown_text_color", Color(1.0, 0.5, 0.3, 1.0))
	)
	cd_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(cd_label)

	return panel


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


func _get_skill_button_stylebox(config: Dictionary, active: bool) -> StyleBox:
	var texture_stylebox := config.get("skill_button_stylebox", null) as StyleBox
	if texture_stylebox != null and active:
		return texture_stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = (
		config.get("button_bg_active", Color(0.12, 0.1, 0.18, 1.0))
		if active
		else config.get("button_bg_inactive", Color(0.08, 0.07, 0.1, 1.0))
	)
	sb.border_color = (
		config.get("button_border_active", Color(0.55, 0.45, 0.15, 1.0))
		if active
		else config.get("button_border_inactive", Color(0.25, 0.2, 0.15, 1.0))
	)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	return sb


func _setup_skill_button_masks(
	skill_key: String, button: PanelContainer, config: Dictionary
) -> Dictionary:
	if button == null:
		return {}
	var mana_mask := button.get_node_or_null("ManaMask") as ColorRect
	if mana_mask == null:
		mana_mask = ColorRect.new()
		mana_mask.name = "ManaMask"
		mana_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
		mana_mask.color = config.get("skill_mana_mask_color", Color(0.18, 0.5, 1.0, 0.45))
		mana_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mana_mask.visible = false
		mana_mask.z_index = 6
		button.add_child(mana_mask)
	var cd_mask := button.get_node_or_null("CooldownMask") as ColorRect
	var cd_material: ShaderMaterial = null
	if cd_mask == null:
		cd_mask = ColorRect.new()
		cd_mask.name = "CooldownMask"
		cd_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_mask.color = Color(1.0, 1.0, 1.0, 0.45)
		cd_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_mask.visible = false
		cd_mask.z_index = 7
		var shader := Shader.new()
		shader.code = str(config.get("skill_cd_mask_shader_code", ""))
		cd_material = ShaderMaterial.new()
		cd_material.shader = shader
		cd_material.set_shader_parameter("progress", 0.0)
		cd_material.set_shader_parameter("mask_color", Color(1.0, 1.0, 1.0, 0.45))
		cd_mask.material = cd_material
		button.add_child(cd_mask)
	else:
		cd_material = cd_mask.material as ShaderMaterial
	for child in button.get_children():
		var label := child as Label
		if label != null:
			label.z_index = 12
	return {
		"skill_key": skill_key,
		"mana_mask": mana_mask,
		"cd_mask": cd_mask,
		"cd_material": cd_material,
	}
