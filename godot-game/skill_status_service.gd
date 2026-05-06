extends RefCounted
class_name SkillStatusService


func update_skill_cast_masks(
		hero_ctrl: Node,
		observing_boss: bool,
		observing_enemy: bool,
		observing_remote: bool,
		skill_mana_masks: Dictionary,
		skill_cd_masks: Dictionary,
		skill_cd_mask_materials: Dictionary
	) -> void:
	var tracked_skill_keys: PackedStringArray = PackedStringArray(["Q", "W", "E", "R"])
	if hero_ctrl == null or observing_boss or observing_enemy or observing_remote:
		for key in tracked_skill_keys:
			_set_skill_cast_mask_state(String(key), false, false, 0.0, skill_mana_masks, skill_cd_masks, skill_cd_mask_materials)
		return
	var current_mana: int = _variant_to_int(hero_ctrl.get("current_mana"), 0)
	var cdr_percent: float = clampf(_variant_to_float(hero_ctrl.get("cooldown_reduction_percent_total"), 0.0), 0.0, 80.0)
	var cdr_ratio: float = cdr_percent * 0.01
	var skill_configs: Array[Dictionary] = [
		{
			"key": "Q",
			"mana_cost_prop": "flash_mana_cost",
			"cd_prop": "_flash_cooldown",
			"base_cd_prop": "flash_cooldown_time"
		},
		{
			"key": "W",
			"mana_cost_prop": "haste_mana_cost",
			"cd_prop": "_haste_cooldown",
			"base_cd_prop": "haste_cooldown_time"
		}
	]
	var has_active_e: bool = _variant_to_bool(hero_ctrl.get("skill_e_active"), false)
	if has_active_e:
		skill_configs.append({
			"key": "E",
			"mana_cost_prop": "evasive_mana_cost",
			"cd_prop": "_e_cooldown",
			"base_cd_prop": "evasive_cooldown_time"
		})
	var has_active_r: bool = _variant_to_bool(hero_ctrl.get("skill_r_active"), false)
	if has_active_r:
		skill_configs.append({
			"key": "R",
			"mana_cost_prop": "ranged_r_mana_cost",
			"cd_prop": "_r_cooldown",
			"base_cd_prop": "ranged_r_cooldown_time"
		})
	for config in skill_configs:
		var skill_key: String = str(config.get("key", ""))
		var mana_cost_prop: String = str(config.get("mana_cost_prop", ""))
		var cd_prop: String = str(config.get("cd_prop", ""))
		var base_cd_prop: String = str(config.get("base_cd_prop", ""))
		var mana_cost: int = maxi(_variant_to_int(hero_ctrl.get(mana_cost_prop), 0), 0)
		var cooldown_left: float = maxf(_variant_to_float(hero_ctrl.get(cd_prop), 0.0), 0.0)
		var base_cd: float = maxf(_variant_to_float(hero_ctrl.get(base_cd_prop), 0.0), 0.0)
		var total_cd: float = base_cd * maxf(1.0 - cdr_ratio, 0.0)
		var is_cooling: bool = cooldown_left > 0.01
		var cooldown_ratio: float = 0.0
		if is_cooling:
			if total_cd > 0.01:
				cooldown_ratio = clampf(cooldown_left / total_cd, 0.0, 1.0)
			else:
				cooldown_ratio = 1.0
		var no_mana_mask: bool = (not is_cooling) and mana_cost > 0 and current_mana < mana_cost
		_set_skill_cast_mask_state(skill_key, no_mana_mask, is_cooling, cooldown_ratio, skill_mana_masks, skill_cd_masks, skill_cd_mask_materials)
	if not has_active_e:
		_set_skill_cast_mask_state("E", false, false, 0.0, skill_mana_masks, skill_cd_masks, skill_cd_mask_materials)
	if not has_active_r:
		_set_skill_cast_mask_state("R", false, false, 0.0, skill_mana_masks, skill_cd_masks, skill_cd_mask_materials)


func update_skill_name_labels(
		hero_ctrl: Node,
		observing_boss: bool,
		observing_enemy: bool,
		observing_remote: bool,
		skill_button_by_key: Dictionary,
		q_skill_name_label: Label,
		w_skill_name_label: Label,
		e_skill_name_label: Label,
		r_skill_name_label: Label
	) -> void:
	var e_button: Control = skill_button_by_key.get("E", null) as Control
	if observing_boss or observing_enemy or observing_remote:
		if e_button != null:
			e_button.visible = true
		_set_label_text(q_skill_name_label, "-")
		_set_label_text(w_skill_name_label, "-")
		_set_label_text(e_skill_name_label, "-")
		_set_label_text(r_skill_name_label, "-")
		return

	if hero_ctrl == null:
		if e_button != null:
			e_button.visible = true
		return

	var q_name: Variant = hero_ctrl.get("skill_q_name")
	if q_name != null:
		_set_label_text(q_skill_name_label, str(q_name))
	var w_name: Variant = hero_ctrl.get("skill_w_name")
	if w_name != null:
		_set_label_text(w_skill_name_label, str(w_name))

	if e_skill_name_label != null:
		var e_active: bool = _variant_to_bool(hero_ctrl.get("skill_e_active"), false)
		var e_name: Variant = hero_ctrl.get("skill_e_name")
		var e_name_text: String = str(e_name).strip_edges() if e_name != null else ""
		if not e_active:
			if e_button != null:
				e_button.visible = not e_name_text.is_empty()
			_set_label_text(e_skill_name_label, e_name_text if not e_name_text.is_empty() else "-")
		else:
			if e_button != null:
				e_button.visible = true
			_set_label_text(e_skill_name_label, e_name_text if not e_name_text.is_empty() else "E技能")

	if r_skill_name_label != null:
		var r_active: bool = _variant_to_bool(hero_ctrl.get("skill_r_active"), false)
		if r_active:
			var r_name: Variant = hero_ctrl.get("skill_r_name")
			if r_name != null and not str(r_name).strip_edges().is_empty():
				_set_label_text(r_skill_name_label, str(r_name))
			else:
				_set_label_text(r_skill_name_label, "R技能")
		else:
			var passive_name: Variant = hero_ctrl.get("skill_passive_name")
			if passive_name != null and not str(passive_name).strip_edges().is_empty():
				_set_label_text(r_skill_name_label, str(passive_name))
			else:
				_set_label_text(r_skill_name_label, "被动")


func update_flash_cd(hero_ctrl: Node, observing_boss: bool, observing_enemy: bool, observing_remote: bool, flash_cd_label: Label) -> void:
	if flash_cd_label == null:
		return
	if observing_boss or observing_enemy or observing_remote:
		flash_cd_label.text = ""
		return
	if hero_ctrl == null:
		return
	var cd: Variant = hero_ctrl.get("_flash_cooldown")
	if cd == null:
		return
	flash_cd_label.text = "%.1f" % float(cd) if float(cd) > 0.0 else ""


func update_haste_cd(hero_ctrl: Node, observing_boss: bool, observing_enemy: bool, observing_remote: bool, haste_cd_label: Label) -> void:
	if haste_cd_label == null:
		return
	if observing_boss or observing_enemy or observing_remote:
		haste_cd_label.text = ""
		return
	if hero_ctrl == null:
		return
	var haste_cd: Variant = hero_ctrl.get("_haste_cooldown")
	var haste_active: Variant = hero_ctrl.get("_haste_active")
	var haste_left: Variant = hero_ctrl.get("_haste_time_left")
	if haste_active == true and haste_left != null and float(haste_left) > 0.0:
		haste_cd_label.text = "↑%.1f" % float(haste_left)
	elif haste_cd != null and float(haste_cd) > 0.0:
		haste_cd_label.text = "%.1f" % float(haste_cd)
	else:
		haste_cd_label.text = ""


func update_e_skill_cd(hero_ctrl: Node, observing_boss: bool, observing_enemy: bool, observing_remote: bool, e_skill_cd_label: Label) -> void:
	if e_skill_cd_label == null:
		return
	if observing_boss or observing_enemy or observing_remote:
		e_skill_cd_label.text = ""
		return
	if hero_ctrl == null:
		return
	var e_active: bool = _variant_to_bool(hero_ctrl.get("skill_e_active"), false)
	if not e_active:
		e_skill_cd_label.text = ""
		return
	var e_cd: float = maxf(_variant_to_float(hero_ctrl.get("_e_cooldown"), 0.0), 0.0)
	e_skill_cd_label.text = "%.1f" % e_cd if e_cd > 0.01 else ""


func update_r_skill_status(hero_ctrl: Node, observing_boss: bool, observing_enemy: bool, observing_remote: bool, r_skill_cd_label: Label) -> void:
	if r_skill_cd_label == null:
		return
	if observing_boss or observing_enemy or observing_remote:
		r_skill_cd_label.text = ""
		return
	if hero_ctrl == null:
		return
	var is_active_r_skill: bool = _variant_to_bool(hero_ctrl.get("skill_r_active"), false)
	if is_active_r_skill:
		var r_mode: bool = _variant_to_bool(hero_ctrl.get("_r_skill_mode"), false)
		var r_cd: float = maxf(_variant_to_float(hero_ctrl.get("_r_cooldown"), 0.0), 0.0)
		if r_mode and r_cd <= 0.01:
			r_skill_cd_label.text = "瞄准"
		elif r_cd > 0.01:
			r_skill_cd_label.text = "%.1f" % r_cd
		else:
			r_skill_cd_label.text = ""
		return
	var passive_id: int = _variant_to_int(hero_ctrl.get("skill_passive_id"), 0)
	var uses_transform_passive: bool = passive_id == 103
	if not uses_transform_passive:
		r_skill_cd_label.text = ""
		return
	var is_transformed: bool = _variant_to_bool(hero_ctrl.get("_is_transformed"), false)
	if is_transformed:
		var transform_left: float = maxf(_variant_to_float(hero_ctrl.get("_transform_time_left"), 0.0), 0.0)
		r_skill_cd_label.text = "↑%.1f" % transform_left
		return
	var current_count: int = maxi(_variant_to_int(hero_ctrl.get("_attack_count"), 0), 0)
	var required_count: int = maxi(_variant_to_int(hero_ctrl.get("passive_transform_attack_count"), 1), 1)
	r_skill_cd_label.text = "%d/%d" % [mini(current_count, required_count), required_count]


func _set_skill_cast_mask_state(
		skill_key: String,
		show_mana_mask: bool,
		show_cd_mask: bool,
		cooldown_ratio: float,
		skill_mana_masks: Dictionary,
		skill_cd_masks: Dictionary,
		skill_cd_mask_materials: Dictionary
	) -> void:
	var mana_mask: ColorRect = skill_mana_masks.get(skill_key, null) as ColorRect
	if mana_mask != null and is_instance_valid(mana_mask):
		mana_mask.visible = show_mana_mask
	var cd_mask: ColorRect = skill_cd_masks.get(skill_key, null) as ColorRect
	if cd_mask != null and is_instance_valid(cd_mask):
		cd_mask.visible = show_cd_mask
	var cd_material: ShaderMaterial = skill_cd_mask_materials.get(skill_key, null) as ShaderMaterial
	if cd_material != null:
		cd_material.set_shader_parameter("progress", clampf(cooldown_ratio, 0.0, 1.0))


func _set_label_text(label: Label, text: String) -> void:
	if label != null:
		label.text = text


func _variant_to_float(value: Variant, fallback: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_float():
			return text.to_float()
	return fallback


func _variant_to_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return roundi(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_int():
			return text.to_int()
	return fallback


func _variant_to_bool(value: Variant, fallback: bool = false) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return absf(value) > 0.0001
	if value is String:
		var text: String = (value as String).strip_edges().to_lower()
		if text == "true" or text == "1" or text == "yes" or text == "on":
			return true
		if text == "false" or text == "0" or text == "no" or text == "off":
			return false
	return fallback
