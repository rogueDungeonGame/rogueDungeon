extends RefCounted
class_name HudPresenter

const HERO_ID_MELEE: int = 1
const HERO_ID_RANGED: int = 2
const HERO_NAME_MELEE: String = "守望者"
const HERO_NAME_RANGED: String = "火枪手"
const BOSS_DISPLAY_NAME: String = "牛肉人酋长"
const ENEMY_DISPLAY_NAME: String = "牛头人"

var _refs: Dictionary = {}
var _colors: Dictionary = {}


func configure(refs: Dictionary, colors: Dictionary) -> void:
	_refs = refs.duplicate()
	_colors = colors.duplicate()


func update(
		hero_ctrl: Node,
		enemy_ai: Node,
		ui_state: Object,
		skill_status_service: Object
	) -> void:
	var observing_boss: bool = _is_observing_boss(ui_state)
	var observing_enemy: bool = _is_observing_enemy(ui_state)
	var observing_remote: bool = _is_observing_remote(ui_state)
	_update_hero_info(hero_ctrl, enemy_ai, ui_state, observing_boss, observing_enemy, observing_remote)
	_update_boss_info(enemy_ai)
	if skill_status_service != null:
		skill_status_service.update_skill_name_labels(
			hero_ctrl,
			observing_boss,
			observing_enemy,
			observing_remote,
			_refs.get("skill_button_by_key", {}),
			_get_label("q_skill_name_label"),
			_get_label("w_skill_name_label"),
			_get_label("e_skill_name_label"),
			_get_label("r_skill_name_label")
		)
		skill_status_service.update_flash_cd(hero_ctrl, observing_boss, observing_enemy, observing_remote, _get_label("flash_cd_label"))
		skill_status_service.update_haste_cd(hero_ctrl, observing_boss, observing_enemy, observing_remote, _get_label("haste_cd_label"))
		skill_status_service.update_e_skill_cd(hero_ctrl, observing_boss, observing_enemy, observing_remote, _get_label("e_skill_cd_label"))
		skill_status_service.update_skill_cast_masks(
			hero_ctrl,
			observing_boss,
			observing_enemy,
			observing_remote,
			_refs.get("skill_mana_masks", {}),
			_refs.get("skill_cd_masks", {}),
			_refs.get("skill_cd_mask_materials", {})
		)
		skill_status_service.update_r_skill_status(hero_ctrl, observing_boss, observing_enemy, observing_remote, _get_label("r_skill_cd_label"))


func _update_hero_info(
		hero_ctrl: Node,
		enemy_ai: Node,
		ui_state: Object,
		observing_boss: bool,
		observing_enemy: bool,
		observing_remote: bool
	) -> void:
	if observing_boss:
		_update_observed_boss_info(enemy_ai)
		return
	if observing_enemy:
		_update_observed_enemy_info(ui_state)
		return
	if observing_remote:
		_update_remote_hero_info(ui_state)
		return
	var hero_hp_bar: ProgressBar = _get_progress_bar("hero_hp_bar")
	if hero_ctrl == null or hero_hp_bar == null:
		return
	var local_hero_id: int = _variant_to_int(hero_ctrl.get("hero_id"), 0)
	var local_profile: String = str(hero_ctrl.get("hero_profile"))
	var hero_name_label: Label = _get_label("hero_name_label")
	if hero_name_label != null:
		hero_name_label.text = "你自己 · %s" % _resolve_hero_display_name(local_hero_id, local_profile)
	_update_hero_portrait(local_hero_id, local_profile)

	var current_hp: Variant = hero_ctrl.get("_current_hp")
	var max_hp: Variant = hero_ctrl.get("max_hp")
	if current_hp == null or max_hp == null:
		return

	var hp_max_value: int = maxi(_variant_to_int(max_hp, 1), 1)
	var ratio: float = float(current_hp) / float(hp_max_value) * 100.0
	hero_hp_bar.value = ratio
	var hero_hp_label: Label = _get_label("hero_hp_label")
	if hero_hp_label != null:
		hero_hp_label.text = "%d / %d" % [current_hp, max_hp]

	var fill_sb := hero_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_sb != null:
		fill_sb.bg_color = _hp_low_color().lerp(_hp_full_color(), float(current_hp) / float(hp_max_value))

	var current_mp: Variant = hero_ctrl.get("current_mana")
	var max_mp: Variant = hero_ctrl.get("max_mana")
	var hero_mp_bar: ProgressBar = _get_progress_bar("hero_mp_bar")
	var hero_mp_label: Label = _get_label("hero_mp_label")
	if current_mp != null and max_mp != null and hero_mp_bar != null and hero_mp_label != null:
		var mp_max_value: int = maxi(_variant_to_int(max_mp, 1), 1)
		var mp_ratio: float = float(current_mp) / float(mp_max_value) * 100.0
		hero_mp_bar.value = mp_ratio
		hero_mp_label.text = "%d / %d" % [current_mp, max_mp]

	var dmg: Variant = hero_ctrl.get("damage_per_hit")
	var atk_label: Label = _get_label("atk_label")
	if dmg != null and atk_label != null:
		atk_label.text = "攻击: %d" % dmg
	var str_val: Variant = hero_ctrl.get("strength")
	var agi_val: Variant = hero_ctrl.get("agility")
	var int_val: Variant = hero_ctrl.get("intelligence")

	var hero_lv: Variant = hero_ctrl.get("hero_level")
	var str_base: Variant = hero_ctrl.get("strength_base")
	var agi_base: Variant = hero_ctrl.get("agility_base")
	var int_base: Variant = hero_ctrl.get("intelligence_base")
	var str_growth: Variant = hero_ctrl.get("strength_growth")
	var agi_growth: Variant = hero_ctrl.get("agility_growth")
	var int_growth: Variant = hero_ctrl.get("intelligence_growth")
	var has_growth_data: bool = false
	var natural_str: int = 0
	var natural_agi: int = 0
	var natural_int: int = 0
	if hero_lv != null and str_base != null and agi_base != null and int_base != null and str_growth != null and agi_growth != null and int_growth != null:
		var lv_i: int = maxi(_variant_to_int(hero_lv, 1), 1)
		natural_str = roundi(float(str_base) + float(str_growth) * float(lv_i - 1))
		natural_agi = roundi(float(agi_base) + float(agi_growth) * float(lv_i - 1))
		natural_int = roundi(float(int_base) + float(int_growth) * float(lv_i - 1))
		has_growth_data = true

	var attack_range: Variant = hero_ctrl.get("attack_range")
	var attack_speed: Variant = hero_ctrl.get("attack_speed")
	var attack_interval: Variant = hero_ctrl.get("attack_interval")
	var cooldown_reduction_percent_total: Variant = hero_ctrl.get("cooldown_reduction_percent_total")
	var passive_skill_name: Variant = hero_ctrl.get("skill_passive_name")
	var physical_crit_chance: Variant = hero_ctrl.get("physical_crit_chance")
	var physical_crit_multiplier: Variant = hero_ctrl.get("physical_crit_multiplier")
	var spell_crit_chance: Variant = hero_ctrl.get("spell_crit_chance")
	var spell_crit_multiplier: Variant = hero_ctrl.get("spell_crit_multiplier")
	var primary_attr_name_var: Variant = hero_ctrl.get("primary_attribute")
	var primary_attr_name: String = "敏捷"
	if primary_attr_name_var != null:
		primary_attr_name = str(primary_attr_name_var)
	var primary_attr_value: int = 0
	match primary_attr_name:
		"力量":
			if str_val != null:
				primary_attr_value = _variant_to_int(str_val, 0)
		"智力":
			if int_val != null:
				primary_attr_value = _variant_to_int(int_val, 0)
		_:
			if agi_val != null:
				primary_attr_value = _variant_to_int(agi_val, 0)

	if atk_label != null:
		var range_text: String = "-"
		var speed_text: String = "-"
		var interval_text: String = "-"
		var ias_text: String = "-"
		var cdr_text: String = "-"
		var dmg_text: String = "-"
		var base_damage_text: String = "-"
		var equip_damage_text: String = "0"
		var base_damage_flat: Variant = hero_ctrl.get("base_damage_flat")
		var equip_damage_bonus: Variant = hero_ctrl.get("_equip_damage_bonus")
		var attack_speed_percent_total: Variant = hero_ctrl.get("attack_speed_percent_total")
		if attack_range != null:
			range_text = str(roundi(float(attack_range)))
		if attack_speed != null:
			speed_text = "%.2f" % float(attack_speed)
		if attack_interval != null:
			interval_text = "%.2f" % float(attack_interval)
		if attack_speed_percent_total != null:
			ias_text = "%.1f%%" % float(attack_speed_percent_total)
		if cooldown_reduction_percent_total != null:
			cdr_text = "%.1f%%" % float(cooldown_reduction_percent_total)
		if dmg != null:
			dmg_text = str(_variant_to_int(dmg, 0))
		if base_damage_flat != null:
			base_damage_text = str(_variant_to_int(base_damage_flat, 0))
		if equip_damage_bonus != null:
			equip_damage_text = str(_variant_to_int(equip_damage_bonus, 0))
		var pcrit_text: String = "-"
		var pcrit_mul_text: String = "-"
		var passive_text: String = "-"
		if physical_crit_chance != null:
			pcrit_text = "%.1f%%" % float(physical_crit_chance)
		if physical_crit_multiplier != null:
			pcrit_mul_text = "%.2fx" % float(physical_crit_multiplier)
		if passive_skill_name != null:
			passive_text = str(passive_skill_name)
		var atk_tip: String = "主属性: %s (%d)\n基础攻击: %s\n装备攻击加成: +%s\n最终攻击: %s\n攻速加成(IAS): %s\n攻击速度: %s 次/秒\n攻击间隔: %s 秒\n攻击范围: %s\n冷却减免(CDR): %s\n物理暴击率: %s\n物理暴击倍率: %s\n被动技能: %s" % [primary_attr_name, primary_attr_value, base_damage_text, equip_damage_text, dmg_text, ias_text, speed_text, interval_text, range_text, cdr_text, pcrit_text, pcrit_mul_text, passive_text]
		_set_tooltip_if_changed(atk_label, atk_tip)
	if _get_label("atk_speed_label") != null and attack_speed != null:
		_get_label("atk_speed_label").text = "攻速: %.2f" % float(attack_speed)
	if _get_label("atk_interval_label") != null and attack_interval != null:
		_get_label("atk_interval_label").text = "攻间隔: %.2f" % float(attack_interval)
	if _get_label("atk_range_label") != null and attack_range != null:
		_get_label("atk_range_label").text = "攻距: %d" % roundi(float(attack_range))
	var cdr_label: Label = _get_label("cdr_label")
	if cdr_label != null and cooldown_reduction_percent_total != null:
		cdr_label.text = "冷却减免: %.1f%%" % float(cooldown_reduction_percent_total)
		_set_tooltip_if_changed(cdr_label, "缩短技能冷却时间（当前作用于 Q/W/R 主动技能）。上限 80%。")
	var phys_crit_rate_label: Label = _get_label("phys_crit_rate_label")
	if phys_crit_rate_label != null and physical_crit_chance != null:
		phys_crit_rate_label.text = "物暴率: %.1f%%" % float(physical_crit_chance)
		_set_tooltip_if_changed(phys_crit_rate_label, "普通攻击触发暴击的概率。")
	var phys_crit_mul_label: Label = _get_label("phys_crit_mul_label")
	if phys_crit_mul_label != null and physical_crit_multiplier != null:
		phys_crit_mul_label.text = "物暴倍: %.2fx" % float(physical_crit_multiplier)
		_set_tooltip_if_changed(phys_crit_mul_label, "普通攻击暴击时造成的伤害倍率。")
	var spell_crit_rate_label: Label = _get_label("spell_crit_rate_label")
	if spell_crit_rate_label != null and spell_crit_chance != null:
		spell_crit_rate_label.text = "法暴率: %.1f%%" % float(spell_crit_chance)
		_set_tooltip_if_changed(spell_crit_rate_label, "法术伤害触发暴击的概率（如Q、毒伤）。")
	var spell_crit_mul_label: Label = _get_label("spell_crit_mul_label")
	if spell_crit_mul_label != null and spell_crit_multiplier != null:
		spell_crit_mul_label.text = "法暴倍: %.2fx" % float(spell_crit_multiplier)
		_set_tooltip_if_changed(spell_crit_mul_label, "法术暴击时造成的伤害倍率。")
	var armor: Variant = hero_ctrl.get("armor")
	if armor != null and _get_label("def_label") != null:
		_get_label("def_label").text = "护甲: %.1f" % float(armor)
	var spd: Variant = hero_ctrl.get("move_speed")
	var spd_label: Label = _get_label("spd_label")
	if spd != null and spd_label != null:
		spd_label.text = "移速: %d" % roundi(float(spd))
	if spd_label != null:
		_set_tooltip_if_changed(spd_label, "冰封王座移速限制: 100 - 522")
	var hp_regen: Variant = hero_ctrl.get("hp_regen_per_second")
	if hp_regen != null and _get_label("hp_regen_label") != null:
		_get_label("hp_regen_label").text = "回血: %.2f/s" % float(hp_regen)
	var mp_regen: Variant = hero_ctrl.get("mana_regen_per_second")
	if mp_regen != null and _get_label("mp_regen_label") != null:
		_get_label("mp_regen_label").text = "回蓝: %.2f/s" % float(mp_regen)
	_update_attribute_labels(str_val, agi_val, int_val, has_growth_data, natural_str, natural_agi, natural_int)


func _update_attribute_labels(
		str_val: Variant,
		agi_val: Variant,
		int_val: Variant,
		has_growth_data: bool,
		natural_str: int,
		natural_agi: int,
		natural_int: int
	) -> void:
	var str_label: Label = _get_label("str_label")
	if str_val != null and str_label != null:
		str_label.text = "力量: %d" % _variant_to_int(str_val, 0)
		var str_now: int = _variant_to_int(str_val, 0)
		var str_hp_bonus: int = str_now * 25
		var str_regen_bonus: float = float(str_now) * 0.05
		var str_natural_text: String = "-"
		var str_equip_text: String = "-"
		if has_growth_data:
			str_natural_text = str(natural_str)
			str_equip_text = str(str_now - natural_str)
		var str_tip: String = "每点力量提供:\n+25 生命上限\n+0.05 生命回复/秒\n\n当前力量: %d\n自然成长: %s\n装备加成: %s\n力量提供生命: +%d\n力量提供回血: +%.2f/s" % [str_now, str_natural_text, str_equip_text, str_hp_bonus, str_regen_bonus]
		_set_tooltip_if_changed(str_label, str_tip)
	var agi_label: Label = _get_label("agi_label")
	if agi_val != null and agi_label != null:
		agi_label.text = "敏捷: %d" % _variant_to_int(agi_val, 0)
		var agi_now: int = _variant_to_int(agi_val, 0)
		var agi_ias_bonus: float = float(agi_now)
		var agi_armor_bonus: float = float(agi_now) * 0.14
		var agi_natural_text: String = "-"
		var agi_equip_text: String = "-"
		if has_growth_data:
			agi_natural_text = str(natural_agi)
			agi_equip_text = str(agi_now - natural_agi)
		var agi_tip: String = "每点敏捷提供:\n+1%% 攻速(IAS)\n+0.14 护甲\n\n当前敏捷: %d\n自然成长: %s\n装备加成: %s\n敏捷提供攻速: +%.1f%%\n敏捷提供护甲: +%.2f" % [agi_now, agi_natural_text, agi_equip_text, agi_ias_bonus, agi_armor_bonus]
		_set_tooltip_if_changed(agi_label, agi_tip)
	var int_label: Label = _get_label("int_label")
	if int_val != null and int_label != null:
		int_label.text = "智力: %d" % _variant_to_int(int_val, 0)
		var int_now: int = _variant_to_int(int_val, 0)
		var int_mp_bonus: int = int_now * 15
		var int_regen_bonus: float = float(int_now) * 0.05
		var int_natural_text: String = "-"
		var int_equip_text: String = "-"
		if has_growth_data:
			int_natural_text = str(natural_int)
			int_equip_text = str(int_now - natural_int)
		var int_tip: String = "每点智力提供:\n+15 法力上限\n+0.05 法力回复/秒\n\n当前智力: %d\n自然成长: %s\n装备加成: %s\n智力提供法力: +%d\n智力提供回蓝: +%.2f/s" % [int_now, int_natural_text, int_equip_text, int_mp_bonus, int_regen_bonus]
		_set_tooltip_if_changed(int_label, int_tip)


func _update_remote_hero_info(ui_state: Object) -> void:
	var hero_state: Dictionary = _get_observed_hero_state(ui_state)
	if hero_state.is_empty():
		return
	var hero_hp_bar: ProgressBar = _get_progress_bar("hero_hp_bar")
	if hero_hp_bar == null:
		return

	var current_hp: int = int(hero_state.get("hp", 0))
	var max_hp: int = maxi(int(hero_state.get("max_hp", 1)), 1)
	var hp_ratio: float = clampf(float(current_hp) / float(max_hp) * 100.0, 0.0, 100.0)
	hero_hp_bar.value = hp_ratio
	var hero_hp_label: Label = _get_label("hero_hp_label")
	if hero_hp_label != null:
		hero_hp_label.text = "%d / %d" % [current_hp, max_hp]

	var fill_sb := hero_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_sb != null:
		fill_sb.bg_color = _hp_low_color().lerp(_hp_full_color(), float(current_hp) / float(max_hp))

	var current_mp: int = int(hero_state.get("mana", 0))
	var max_mp: int = maxi(int(hero_state.get("max_mana", 1)), 1)
	var hero_mp_bar: ProgressBar = _get_progress_bar("hero_mp_bar")
	if hero_mp_bar != null:
		hero_mp_bar.value = clampf(float(current_mp) / float(max_mp) * 100.0, 0.0, 100.0)
	var hero_mp_label: Label = _get_label("hero_mp_label")
	if hero_mp_label != null:
		hero_mp_label.text = "%d / %d" % [current_mp, max_mp]

	var remote_hero_id: int = int(hero_state.get("hero_id", 0))
	var profile_text: String = str(hero_state.get("hero_profile", ""))
	var hero_name_label: Label = _get_label("hero_name_label")
	if hero_name_label != null:
		hero_name_label.text = "玩家P%d · %s" % [_get_observed_peer_id(ui_state), _resolve_hero_display_name(remote_hero_id, profile_text)]
	_update_hero_portrait(remote_hero_id, profile_text)

	_update_remote_stat_labels(hero_state)


func _update_remote_stat_labels(hero_state: Dictionary) -> void:
	_set_stat_int_label_from_state("atk_label", hero_state, "damage", "攻击")
	_set_stat_float_label_from_state("def_label", hero_state, "armor", "护甲", "%.1f")
	_set_stat_rounded_label_from_state("spd_label", hero_state, "move_speed", "移速")
	_set_stat_float_label_from_state("atk_speed_label", hero_state, "attack_speed", "攻速", "%.2f")
	_set_stat_float_label_from_state("atk_interval_label", hero_state, "attack_interval", "攻间隔", "%.2f")
	_set_stat_rounded_label_from_state("atk_range_label", hero_state, "attack_range", "攻距")
	_set_stat_float_label_from_state("cdr_label", hero_state, "cooldown_reduction_percent_total", "冷却减免", "%.1f%%")
	_set_stat_float_label_from_state("phys_crit_rate_label", hero_state, "physical_crit_chance", "物暴率", "%.1f%%")
	_set_stat_float_label_from_state("phys_crit_mul_label", hero_state, "physical_crit_multiplier", "物暴倍", "%.2fx")
	_set_stat_float_label_from_state("spell_crit_rate_label", hero_state, "spell_crit_chance", "法暴率", "%.1f%%")
	_set_stat_float_label_from_state("spell_crit_mul_label", hero_state, "spell_crit_multiplier", "法暴倍", "%.2fx")
	_set_stat_float_label_from_state("hp_regen_label", hero_state, "hp_regen_per_second", "回血", "%.2f/s")
	_set_stat_float_label_from_state("mp_regen_label", hero_state, "mana_regen_per_second", "回蓝", "%.2f/s")
	_set_stat_int_label_from_state("str_label", hero_state, "strength", "力量")
	_set_stat_int_label_from_state("agi_label", hero_state, "agility", "敏捷")
	_set_stat_int_label_from_state("int_label", hero_state, "intelligence", "智力")


func _update_observed_boss_info(enemy_ai: Node) -> void:
	var hero_hp_bar: ProgressBar = _get_progress_bar("hero_hp_bar")
	if enemy_ai == null or hero_hp_bar == null:
		return
	var hero_name_label: Label = _get_label("hero_name_label")
	if hero_name_label != null:
		hero_name_label.text = "BOSS · %s" % BOSS_DISPLAY_NAME
	_update_hero_portrait(0, "")

	var current_hp_variant: Variant = enemy_ai.get("_current_hp")
	var max_hp_variant: Variant = enemy_ai.get("max_hp")
	var boss_current_hp: int = 0
	var boss_max_hp: int = 1
	if current_hp_variant != null:
		boss_current_hp = maxi(int(current_hp_variant), 0)
	if max_hp_variant != null:
		boss_max_hp = maxi(int(max_hp_variant), 1)
	hero_hp_bar.value = clampf(float(boss_current_hp) / float(boss_max_hp) * 100.0, 0.0, 100.0)
	var hero_hp_label: Label = _get_label("hero_hp_label")
	if hero_hp_label != null:
		hero_hp_label.text = "%d / %d" % [boss_current_hp, boss_max_hp]
	_clear_hero_mp()

	var boss_damage_variant: Variant = enemy_ai.get("damage_per_hit")
	var atk_label: Label = _get_label("atk_label")
	if atk_label != null:
		if boss_damage_variant != null:
			atk_label.text = "攻击: %d" % int(boss_damage_variant)
		else:
			atk_label.text = "攻击: -"
		_set_tooltip_if_changed(atk_label, "")
	var def_label: Label = _get_label("def_label")
	if def_label != null:
		def_label.text = "护甲: -"
		_set_tooltip_if_changed(def_label, "")

	var boss_speed_variant: Variant = enemy_ai.get("move_speed")
	var spd_label: Label = _get_label("spd_label")
	if spd_label != null:
		if boss_speed_variant != null:
			spd_label.text = "移速: %d" % int(round(float(boss_speed_variant)))
		else:
			spd_label.text = "移速: -"
		_set_tooltip_if_changed(spd_label, "")

	var boss_attack_speed_variant: Variant = enemy_ai.get("attack_speed")
	var boss_attack_range_variant: Variant = enemy_ai.get("attack_range")
	var atk_speed_label: Label = _get_label("atk_speed_label")
	if atk_speed_label != null:
		if boss_attack_speed_variant != null:
			atk_speed_label.text = "攻速: %.2f" % float(boss_attack_speed_variant)
		else:
			atk_speed_label.text = "攻速: -"
	var atk_interval_label: Label = _get_label("atk_interval_label")
	if atk_interval_label != null:
		if boss_attack_speed_variant != null and float(boss_attack_speed_variant) > 0.0001:
			atk_interval_label.text = "攻间隔: %.2f" % (1.0 / float(boss_attack_speed_variant))
		else:
			atk_interval_label.text = "攻间隔: -"
	var atk_range_label: Label = _get_label("atk_range_label")
	if atk_range_label != null:
		if boss_attack_range_variant != null:
			atk_range_label.text = "攻距: %d" % int(round(float(boss_attack_range_variant)))
		else:
			atk_range_label.text = "攻距: -"
	_clear_non_combat_stat_labels()


func _update_observed_enemy_info(ui_state: Object) -> void:
	var hero_hp_bar: ProgressBar = _get_progress_bar("hero_hp_bar")
	if hero_hp_bar == null:
		return
	var enemy_state: Dictionary = _get_observed_enemy_state(ui_state)
	if enemy_state.is_empty():
		return
	var hero_name_label: Label = _get_label("hero_name_label")
	if hero_name_label != null:
		var enemy_name: String = str(enemy_state.get("name", ENEMY_DISPLAY_NAME)).strip_edges()
		if enemy_name.is_empty():
			enemy_name = ENEMY_DISPLAY_NAME
		hero_name_label.text = enemy_name
	_update_hero_portrait(0, "")

	var enemy_current_hp: int = maxi(int(enemy_state.get("hp", 0)), 0)
	var enemy_max_hp: int = maxi(int(enemy_state.get("max_hp", 1)), 1)
	hero_hp_bar.value = clampf(float(enemy_current_hp) / float(enemy_max_hp) * 100.0, 0.0, 100.0)
	var hero_hp_label: Label = _get_label("hero_hp_label")
	if hero_hp_label != null:
		hero_hp_label.text = "%d / %d" % [enemy_current_hp, enemy_max_hp]
	_clear_hero_mp()

	var atk_label: Label = _get_label("atk_label")
	if atk_label != null:
		if enemy_state.has("damage"):
			atk_label.text = "攻击: %d" % int(enemy_state.get("damage", 0))
		else:
			atk_label.text = "攻击: -"
		_set_tooltip_if_changed(atk_label, "")
	var def_label: Label = _get_label("def_label")
	if def_label != null:
		def_label.text = "护甲: -"
		_set_tooltip_if_changed(def_label, "")
	var spd_label: Label = _get_label("spd_label")
	if spd_label != null:
		if enemy_state.has("move_speed"):
			spd_label.text = "移速: %d" % int(round(float(enemy_state.get("move_speed", 0.0))))
		else:
			spd_label.text = "移速: -"
		_set_tooltip_if_changed(spd_label, "")

	_set_stat_float_label_from_state("atk_speed_label", enemy_state, "attack_speed", "攻速", "%.2f")
	var atk_interval_label: Label = _get_label("atk_interval_label")
	if atk_interval_label != null:
		var enemy_attack_speed: float = float(enemy_state.get("attack_speed", 0.0))
		if enemy_attack_speed > 0.0001:
			atk_interval_label.text = "攻间隔: %.2f" % (1.0 / enemy_attack_speed)
		else:
			atk_interval_label.text = "攻间隔: -"
	_set_stat_rounded_label_from_state("atk_range_label", enemy_state, "attack_range", "攻距")
	_clear_non_combat_stat_labels()


func _update_boss_info(enemy_ai: Node) -> void:
	var boss_hp_bar: ProgressBar = _get_progress_bar("boss_hp_bar")
	if enemy_ai == null or boss_hp_bar == null:
		return

	var current_hp: Variant = enemy_ai.get("_current_hp")
	var max_hp: Variant = enemy_ai.get("max_hp")
	if current_hp == null or max_hp == null:
		return

	var ratio: float = float(current_hp) / float(max_hp) * 100.0
	boss_hp_bar.value = ratio
	var boss_hp_label: Label = _get_label("boss_hp_label")
	if boss_hp_label != null:
		boss_hp_label.text = "%d / %d" % [current_hp, max_hp]


func _clear_hero_mp() -> void:
	var hero_mp_bar: ProgressBar = _get_progress_bar("hero_mp_bar")
	if hero_mp_bar != null:
		hero_mp_bar.value = 0.0
	var hero_mp_label: Label = _get_label("hero_mp_label")
	if hero_mp_label != null:
		hero_mp_label.text = "-- / --"


func _clear_non_combat_stat_labels() -> void:
	for key in ["cdr_label", "phys_crit_rate_label", "phys_crit_mul_label", "spell_crit_rate_label", "spell_crit_mul_label", "str_label", "agi_label", "int_label"]:
		var label: Label = _get_label(key)
		if label == null:
			continue
		match key:
			"cdr_label":
				label.text = "冷却减免: -"
			"phys_crit_rate_label":
				label.text = "物暴率: -"
			"phys_crit_mul_label":
				label.text = "物暴倍: -"
			"spell_crit_rate_label":
				label.text = "法暴率: -"
			"spell_crit_mul_label":
				label.text = "法暴倍: -"
			"str_label":
				label.text = "力量: -"
			"agi_label":
				label.text = "敏捷: -"
			"int_label":
				label.text = "智力: -"
		_set_tooltip_if_changed(label, "")
	var hp_regen_label: Label = _get_label("hp_regen_label")
	if hp_regen_label != null:
		hp_regen_label.text = "回血: -"
	var mp_regen_label: Label = _get_label("mp_regen_label")
	if mp_regen_label != null:
		mp_regen_label.text = "回蓝: -"


func _set_stat_int_label_from_state(label_key: String, state: Dictionary, state_key: String, title: String) -> void:
	var label: Label = _get_label(label_key)
	if label == null:
		return
	if state.has(state_key):
		label.text = "%s: %d" % [title, int(state.get(state_key, 0))]
	else:
		label.text = "%s: -" % title


func _set_stat_rounded_label_from_state(label_key: String, state: Dictionary, state_key: String, title: String) -> void:
	var label: Label = _get_label(label_key)
	if label == null:
		return
	if state.has(state_key):
		label.text = "%s: %d" % [title, int(round(float(state.get(state_key, 0.0))))]
	else:
		label.text = "%s: -" % title


func _set_stat_float_label_from_state(label_key: String, state: Dictionary, state_key: String, title: String, format_text: String) -> void:
	var label: Label = _get_label(label_key)
	if label == null:
		return
	if state.has(state_key):
		label.text = "%s: %s" % [title, format_text % float(state.get(state_key, 0.0))]
	else:
		label.text = "%s: -" % title


func _resolve_hero_display_name(hero_id: int, profile_text: String = "") -> String:
	match hero_id:
		HERO_ID_MELEE:
			return "1号%s" % HERO_NAME_MELEE
		HERO_ID_RANGED:
			return "2号%s" % HERO_NAME_RANGED
	var normalized: String = profile_text.strip_edges().to_lower()
	if normalized == "远程" or normalized == "ranged" or normalized.find("火枪手") >= 0:
		return "2号%s" % HERO_NAME_RANGED
	if normalized == "近战" or normalized == "melee" or normalized.find("守望者") >= 0 or normalized.find("暗夜刺客") >= 0:
		return "1号%s" % HERO_NAME_MELEE
	if profile_text.strip_edges().is_empty():
		return "未知英雄"
	return profile_text


func _update_hero_portrait(hero_id: int, profile_text: String = "") -> void:
	var portrait := _get_texture_rect("hero_portrait_texture_rect")
	if portrait == null:
		return
	var texture: Texture2D = null
	match hero_id:
		HERO_ID_MELEE:
			texture = _refs.get("hero_portrait_melee_texture", null) as Texture2D
		HERO_ID_RANGED:
			texture = _refs.get("hero_portrait_ranged_texture", null) as Texture2D
		_:
			var normalized: String = profile_text.strip_edges().to_lower()
			if normalized == "远程" or normalized == "ranged" or normalized.find("火枪手") >= 0:
				texture = _refs.get("hero_portrait_ranged_texture", null) as Texture2D
			elif normalized == "近战" or normalized == "melee" or normalized.find("守望者") >= 0 or normalized.find("暗夜刺客") >= 0:
				texture = _refs.get("hero_portrait_melee_texture", null) as Texture2D
	portrait.texture = texture
	portrait.visible = texture != null


func _set_tooltip_if_changed(ctrl: Control, text: String) -> void:
	if ctrl == null:
		return
	if ctrl.tooltip_text == text:
		return
	ctrl.tooltip_text = text


func _get_label(key: String) -> Label:
	return _refs.get(key, null) as Label


func _get_progress_bar(key: String) -> ProgressBar:
	return _refs.get(key, null) as ProgressBar


func _get_texture_rect(key: String) -> TextureRect:
	return _refs.get(key, null) as TextureRect


func _hp_full_color() -> Color:
	return _colors.get("hp_full", Color(0.1, 0.85, 0.1, 1.0))


func _hp_low_color() -> Color:
	return _colors.get("hp_low", Color(0.9, 0.15, 0.1, 1.0))


func _is_observing_boss(ui_state: Object) -> bool:
	if ui_state == null:
		return false
	return ui_state.is_observing_boss()


func _is_observing_enemy(ui_state: Object) -> bool:
	if ui_state == null:
		return false
	return ui_state.is_observing_enemy()


func _is_observing_remote(ui_state: Object) -> bool:
	if ui_state == null:
		return false
	return ui_state.is_observing_remote()


func _get_observed_hero_state(ui_state: Object) -> Dictionary:
	if ui_state == null:
		return {}
	return ui_state.get_observed_hero_state()


func _get_observed_enemy_state(ui_state: Object) -> Dictionary:
	if ui_state == null:
		return {}
	return ui_state.observed_enemy_state


func _get_observed_peer_id(ui_state: Object) -> int:
	if ui_state == null:
		return 0
	return int(ui_state.observed_peer_id)


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
