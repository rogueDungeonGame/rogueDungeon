extends RefCounted
class_name EquipmentEffectsService

var _default_build_name: String = "无派系"
var _build_alias_map: Dictionary = {}
var _spark_force_item_names: Dictionary = {}
var _charge_build_name: String = "充能"
var _coin_build_name: String = "硬币"
var _charge_stack_agility: int = 2
var _charge_staff_summon_bonus_per_stack: float = 5.0
var _coin_button_attack_speed_per_layer: int = 25
var _coin_smile_damage_tenths_per_coin_owned: int = 15
var _coin_gold_refresh_limit_per_item: int = 10
var _coin_lucky_gold_per_trigger: int = 85
var _coin_gold_gold_per_layer: int = 20


func _init(config: Dictionary = {}) -> void:
	_default_build_name = str(config.get("default_build_name", _default_build_name)).strip_edges()
	if _default_build_name == "":
		_default_build_name = "无派系"
	if config.get("build_alias_map", null) is Dictionary:
		_build_alias_map = (config.get("build_alias_map", {}) as Dictionary).duplicate(true)
	if config.get("spark_force_item_names", null) is Dictionary:
		_spark_force_item_names = (config.get("spark_force_item_names", {}) as Dictionary).duplicate(true)
	_charge_build_name = str(config.get("charge_build_name", _charge_build_name)).strip_edges()
	_coin_build_name = str(config.get("coin_build_name", _coin_build_name)).strip_edges()
	_charge_stack_agility = int(config.get("charge_stack_agility", _charge_stack_agility))
	_charge_staff_summon_bonus_per_stack = float(config.get("charge_staff_summon_bonus_per_stack", _charge_staff_summon_bonus_per_stack))
	_coin_button_attack_speed_per_layer = int(config.get("coin_button_attack_speed_per_layer", _coin_button_attack_speed_per_layer))
	_coin_smile_damage_tenths_per_coin_owned = int(config.get("coin_smile_damage_tenths_per_coin_owned", _coin_smile_damage_tenths_per_coin_owned))
	_coin_gold_refresh_limit_per_item = int(config.get("coin_gold_refresh_limit_per_item", _coin_gold_refresh_limit_per_item))
	_coin_lucky_gold_per_trigger = int(config.get("coin_lucky_gold_per_trigger", _coin_lucky_gold_per_trigger))
	_coin_gold_gold_per_layer = int(config.get("coin_gold_gold_per_layer", _coin_gold_gold_per_layer))


func calculate_inventory_bonuses(item_db: Array, inv: Array, meta_array: Array, coin_state: Dictionary, destroy_bonus: Dictionary) -> Dictionary:
	var total: Dictionary = {
		"strength": 0,
		"agility": 0,
		"intelligence": 0,
		"hp": 0,
		"mana": 0,
		"damage": 0,
		"armor": 0.0,
		"attack_speed_percent": 0.0,
		"move_speed": 0.0,
		"attack_range": 0.0,
		"hp_regen": 0.0,
		"cooldown_reduction_percent": 0.0,
		"physical_crit_chance": 0.0,
		"physical_crit_multiplier": 0.0,
		"spell_crit_chance": 0.0,
		"spell_crit_multiplier": 0.0,
		"spell_damage_percent": 0.0,
		"magic_damage_reduction_percent": 0.0,
		"spark_effects": {},
		"charge_effects": {},
		"necromancy_effects": {},
		"battle_banner_effects": {},
		"battle_prep_effects": {},
		"settlement_effects": {},
		"coin_effects": {},
	}
	for i in range(inv.size()):
		var item_idx: int = int(inv[i])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_bonus: Dictionary = _parse_item_bonus(_get_item_data(item_db, item_idx))
		total["strength"] = int(total["strength"]) + int(item_bonus.get("strength", 0))
		total["agility"] = int(total["agility"]) + int(item_bonus.get("agility", 0))
		total["intelligence"] = int(total["intelligence"]) + int(item_bonus.get("intelligence", 0))
		total["hp"] = int(total["hp"]) + int(item_bonus.get("hp", 0))
		total["mana"] = int(total["mana"]) + int(item_bonus.get("mana", 0))
		total["damage"] = int(total["damage"]) + int(item_bonus.get("damage", 0))
		total["armor"] = float(total["armor"]) + float(item_bonus.get("armor", 0.0))
		total["attack_speed_percent"] = float(total["attack_speed_percent"]) + float(item_bonus.get("attack_speed_percent", 0.0))
		total["move_speed"] = float(total["move_speed"]) + float(item_bonus.get("move_speed", 0.0))
		total["attack_range"] = float(total["attack_range"]) + float(item_bonus.get("attack_range", 0.0))
		total["hp_regen"] = float(total["hp_regen"]) + float(item_bonus.get("hp_regen", 0.0))
		total["cooldown_reduction_percent"] = float(total["cooldown_reduction_percent"]) + float(item_bonus.get("cooldown_reduction_percent", 0.0))
		total["physical_crit_chance"] = float(total["physical_crit_chance"]) + float(item_bonus.get("physical_crit_chance", 0.0))
		total["physical_crit_multiplier"] = float(total["physical_crit_multiplier"]) + float(item_bonus.get("physical_crit_multiplier", 0.0))
		total["spell_crit_chance"] = float(total["spell_crit_chance"]) + float(item_bonus.get("spell_crit_chance", 0.0))
		total["spell_crit_multiplier"] = float(total["spell_crit_multiplier"]) + float(item_bonus.get("spell_crit_multiplier", 0.0))
		total["spell_damage_percent"] = float(total["spell_damage_percent"]) + float(item_bonus.get("spell_damage_percent", 0.0))
		total["magic_damage_reduction_percent"] = float(total["magic_damage_reduction_percent"]) + float(item_bonus.get("magic_damage_reduction_percent", 0.0))

	var spark_effects: Dictionary = _calculate_spark_effects(item_db, inv)
	total["spark_effects"] = spark_effects
	var bonus_per_spark_item: float = float(spark_effects.get("bonus_attack_speed_percent_per_spark_item", 0.0))
	var spark_item_count: int = int(spark_effects.get("spark_item_count", 0))
	if bonus_per_spark_item > 0.0 and spark_item_count > 0:
		total["attack_speed_percent"] = float(total["attack_speed_percent"]) + bonus_per_spark_item * float(spark_item_count)

	var charge_effects: Dictionary = _calculate_charge_effects(item_db, inv, meta_array)
	total["charge_effects"] = charge_effects
	total["agility"] = int(total["agility"]) + int(charge_effects.get("agility", 0))
	total["intelligence"] = int(total["intelligence"]) + int(charge_effects.get("intelligence", 0))
	total["hp"] = int(total["hp"]) + int(charge_effects.get("hp", 0))
	total["spell_damage_percent"] = float(total["spell_damage_percent"]) + float(charge_effects.get("spell_damage_percent", 0.0))
	total["attack_range"] = float(total["attack_range"]) + float(charge_effects.get("attack_range", 0.0))
	total["physical_crit_multiplier"] = float(total["physical_crit_multiplier"]) + float(charge_effects.get("physical_crit_multiplier", 0.0))

	total["necromancy_effects"] = _calculate_necromancy_effects(item_db, inv, meta_array)
	total["battle_banner_effects"] = _calculate_battle_banner_effects(item_db, inv)
	total["battle_prep_effects"] = _calculate_battle_prep_effects(item_db, inv)
	total["settlement_effects"] = _calculate_settlement_effects(item_db, inv)

	var coin_effects: Dictionary = _calculate_coin_effects(item_db, inv, meta_array, coin_state)
	total["coin_effects"] = coin_effects
	total["strength"] = int(total["strength"]) + int(coin_effects.get("strength", 0))
	total["agility"] = int(total["agility"]) + int(coin_effects.get("agility", 0))
	total["intelligence"] = int(total["intelligence"]) + int(coin_effects.get("intelligence", 0))
	total["damage"] = int(total["damage"]) + int(coin_effects.get("damage", 0))
	total["attack_speed_percent"] = float(total["attack_speed_percent"]) + float(coin_effects.get("attack_speed_percent", 0.0))

	total["strength"] = int(total["strength"]) + int(destroy_bonus.get("strength", 0))
	total["agility"] = int(total["agility"]) + int(destroy_bonus.get("agility", 0))
	total["intelligence"] = int(total["intelligence"]) + int(destroy_bonus.get("intelligence", 0))
	total["hp"] = int(total["hp"]) + int(destroy_bonus.get("hp", 0))
	total["spell_damage_percent"] = float(total["spell_damage_percent"]) + float(destroy_bonus.get("spell_damage_percent", 0.0))
	return total


func _calculate_spark_effects(item_db: Array, inv: Array) -> Dictionary:
	var effects: Dictionary = {
		"spark_item_count": 0,
		"bonus_attack_speed_percent_per_spark_item": 0.0,
		"attack_interval_reduction_sec": 0.0,
		"attack_effect_multiplier": 1.0,
		"attack_effect_agility_ratio": 0.0,
		"attack_effect_attack_speed_ratio": 0.0,
		"attack_effect_current_mana_ratio": 0.0,
		"attack_effect_max_hp_ratio": 0.0,
		"attack_effect_flat_damage": 0.0,
		"attack_effect_flat_heal": 0.0,
		"attack_effect_low_hp_double_threshold": 0.0,
		"attack_effect_total_item_level_scale": 0.0,
		"inventory_level_sum": 0,
		"attack_effect_aoe_radius": 260.0,
		"on_hit_attack_speed_bonus_percent": 0.0,
		"on_hit_attack_speed_bonus_duration_sec": 0.0,
		"on_hit_spell_damage_bonus_percent": 0.0,
		"on_hit_spell_damage_bonus_duration_sec": 0.0,
		"on_hit_permanent_hp_gain": 0,
		"soul_consume_attack_speed_permanent_bonus_per_use": 0.0,
	}
	var item_count_by_name: Dictionary = {}
	var spark_item_count: int = 0
	var inventory_level_sum: int = 0
	for item_idx_variant in inv:
		var item_idx: int = int(item_idx_variant)
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_data: Dictionary = _get_item_data(item_db, item_idx)
		var item_name: String = _normalize_item_name_for_effects(item_data)
		item_count_by_name[item_name] = int(item_count_by_name.get(item_name, 0)) + 1
		inventory_level_sum += _get_item_level(item_data)
		if _is_spark_item_for_effects(item_data):
			spark_item_count += 1
	effects["spark_item_count"] = spark_item_count
	effects["inventory_level_sum"] = inventory_level_sum
	effects["bonus_attack_speed_percent_per_spark_item"] = 5.0 * float(_count_named_items(item_count_by_name, ["加速手套"]))
	effects["attack_interval_reduction_sec"] = 0.15 * float(_count_named_items(item_count_by_name, ["疾风短剑"])) + 0.3 * float(_count_named_items(item_count_by_name, ["幻影对剑"]))
	var spark_ring_count: int = _count_named_items(item_count_by_name, ["火花环刃"])
	if spark_ring_count > 0:
		effects["attack_effect_multiplier"] = pow(2.0, float(spark_ring_count))
	effects["attack_effect_attack_speed_ratio"] = float(_count_named_items(item_count_by_name, ["破败火花剑", "破败之刃"]))
	effects["attack_effect_agility_ratio"] = float(_count_named_items(item_count_by_name, ["火花奇术手"]))
	effects["attack_effect_current_mana_ratio"] = 0.02 * float(_count_named_items(item_count_by_name, ["霓虹棍剑"])) + 0.04 * float(_count_named_items(item_count_by_name, ["蓝港棍剑"]))
	effects["attack_effect_max_hp_ratio"] = 0.02 * float(_count_named_items(item_count_by_name, ["毁灭之怒", "泰坦之怒"])) + 0.04 * float(_count_named_items(item_count_by_name, ["陨灭泰坦之锤", "陨灭泰坦锤"]))
	var ember_blade_count: int = _count_named_items(item_count_by_name, ["火花末刃"])
	effects["attack_effect_flat_damage"] = 20.0 * float(ember_blade_count)
	effects["attack_effect_flat_heal"] = 10.0 * float(ember_blade_count)
	if ember_blade_count > 0:
		effects["attack_effect_low_hp_double_threshold"] = 0.35
	effects["attack_effect_total_item_level_scale"] = 10.0 * float(_count_named_items(item_count_by_name, ["闪耀之爪"]))
	var flying_arrow_count: int = _count_named_items(item_count_by_name, ["火花飞矢"])
	if flying_arrow_count > 0:
		effects["on_hit_attack_speed_bonus_percent"] = 20.0 * float(flying_arrow_count)
		effects["on_hit_attack_speed_bonus_duration_sec"] = 4.0
	var eye_count: int = _count_named_items(item_count_by_name, ["遗留者眼球"])
	if eye_count > 0:
		effects["on_hit_spell_damage_bonus_percent"] = 10.0 * float(eye_count)
		effects["on_hit_spell_damage_bonus_duration_sec"] = 4.0
	effects["on_hit_permanent_hp_gain"] = _count_named_items(item_count_by_name, ["符文石"])
	var spark_urn_count: int = _count_named_items(item_count_by_name, ["火花灵瓮", "火花灵翁"])
	if spark_urn_count > 0:
		effects["soul_consume_attack_speed_permanent_bonus_per_use"] = 25.0 * float(spark_urn_count)
	return effects


func _calculate_necromancy_effects(item_db: Array, inv: Array, meta_array: Array) -> Dictionary:
	var effects: Dictionary = {
		"spirit_book_count": 0,
		"spirit_flute_count": 0,
		"spellcaster_necro_robe_count": 0,
		"moon_tower_count": 0,
		"spirit_staff_count": 0,
		"battle_prep_owl_count": 0,
		"battle_prep_tower_count": 0,
		"summon_magic_resist_percent": 0.0,
		"book_max_hp_per_summon": 0,
		"flute_stack_gain_per_summon": 0,
		"flute_stacks_per_int": 7,
		"flute_int_per_threshold": 1,
		"summon_power_percent_per_spell_cast": 0.0,
		"charge_gain_per_basic_attack": 0,
		"max_charge_stacks": 0,
		"summon_attack_and_range_percent_per_charge": 0.0,
		"summon_attack_bonus_percent_flat": 0.0,
		"summon_range_bonus_percent_flat": 0.0,
	}
	var item_count_by_name: Dictionary = {}
	for item_idx_variant in inv:
		var item_idx: int = int(item_idx_variant)
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_name: String = _normalize_item_name_for_effects(_get_item_data(item_db, item_idx))
		item_count_by_name[item_name] = int(item_count_by_name.get(item_name, 0)) + 1

	var spirit_book_count: int = _count_named_items(item_count_by_name, ["通灵书"])
	var spirit_flute_count: int = _count_named_items(item_count_by_name, ["通灵笛"])
	var robe_count: int = _count_named_items(item_count_by_name, ["咒文师的通灵长袍"])
	var moon_tower_count: int = _count_named_items(item_count_by_name, ["月牙塔"])
	var spirit_staff_count: int = _count_named_items(item_count_by_name, ["通灵杖"])
	effects["spirit_book_count"] = spirit_book_count
	effects["spirit_flute_count"] = spirit_flute_count
	effects["spellcaster_necro_robe_count"] = robe_count
	effects["moon_tower_count"] = moon_tower_count
	effects["spirit_staff_count"] = spirit_staff_count
	effects["battle_prep_owl_count"] = spirit_flute_count
	effects["battle_prep_tower_count"] = moon_tower_count
	effects["summon_magic_resist_percent"] = 20.0 * float(spirit_book_count)
	effects["book_max_hp_per_summon"] = 4 * spirit_book_count
	effects["flute_stack_gain_per_summon"] = spirit_flute_count
	effects["summon_power_percent_per_spell_cast"] = 5.0 * float(robe_count)

	var spirit_staff_charge_count: int = 0
	for slot_idx in _find_item_slots_by_name(item_db, inv, "通灵杖"):
		var spirit_staff_idx: int = int(inv[slot_idx])
		var spirit_staff_meta: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, spirit_staff_idx)
		spirit_staff_charge_count += maxi(int(spirit_staff_meta.get("charges", 0)), 0)
	var total_staff_bonus: float = float(spirit_staff_charge_count) * _charge_staff_summon_bonus_per_stack
	effects["summon_attack_bonus_percent_flat"] = total_staff_bonus
	effects["summon_range_bonus_percent_flat"] = total_staff_bonus
	return effects


func _calculate_charge_effects(item_db: Array, inv: Array, meta_array: Array) -> Dictionary:
	var effects: Dictionary = {
		"agility": 0,
		"intelligence": 0,
		"hp": 0,
		"spell_damage_percent": 0.0,
		"attack_range": 0.0,
		"physical_crit_multiplier": 0.0,
		"attack_effect_agility_ratio": 0.0,
		"on_hit_permanent_hp_gain": 0,
	}
	var charge_attribute_agility_total: int = 0
	var perfect_core_count: int = 0
	var perfect_firestone_count: int = 0
	var charge_scepter_count: int = 0
	for slot_idx in range(inv.size()):
		var item_idx: int = int(inv[slot_idx])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_data: Dictionary = _get_item_data(item_db, item_idx)
		var item_name: String = _normalize_item_name_for_effects(item_data)
		match item_name:
			"完美核心":
				perfect_core_count += 1
			"完美火花石":
				perfect_firestone_count += 1
			"充能神杖":
				charge_scepter_count += 1
			_:
				pass
		if not _is_charge_item_for_effects(item_data):
			continue
		var entry: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, item_idx)
		var charge_count: int = maxi(int(entry.get("charges", 0)), 0)
		var charge_agility: int = maxi(int(entry.get("permanent_agility", 0)), 0)
		if item_name != "通灵杖":
			charge_agility += charge_count * _charge_stack_agility
		var particle_bonus_per_two: int = maxi(int(entry.get("particle_bonus_per_two_charges", 0)), 0)
		if particle_bonus_per_two > 0 and charge_count > 0:
			charge_agility += (charge_count / 2) * particle_bonus_per_two
		effects["agility"] = int(effects.get("agility", 0)) + charge_agility
		charge_attribute_agility_total += charge_agility
		effects["hp"] = int(effects.get("hp", 0)) + maxi(int(entry.get("permanent_hp", 0)), 0)
		effects["spell_damage_percent"] = float(effects.get("spell_damage_percent", 0.0)) + float(maxi(int(entry.get("permanent_spell_damage_percent", 0)), 0))
		effects["attack_range"] = float(effects.get("attack_range", 0.0)) + float(maxi(int(entry.get("permanent_attack_range", 0)), 0))
		effects["physical_crit_multiplier"] = float(effects.get("physical_crit_multiplier", 0.0)) + float(maxi(int(entry.get("permanent_physical_crit_multiplier", 0)), 0))
		if item_name == "未来引擎":
			var future_engine_bonus: Dictionary = _parse_item_bonus(item_data)
			effects["agility"] = int(effects.get("agility", 0)) + int(future_engine_bonus.get("agility", 0)) + charge_agility
	effects["intelligence"] = charge_attribute_agility_total * charge_scepter_count
	effects["attack_effect_agility_ratio"] = float(perfect_core_count + perfect_firestone_count)
	effects["on_hit_permanent_hp_gain"] = perfect_firestone_count
	return effects


func _calculate_battle_banner_effects(item_db: Array, inv: Array) -> Dictionary:
	var effects: Dictionary = {
		"total_banner_count": 0,
		"elf_banner_count": 0,
		"kingdom_banner_count": 0,
		"wasteland_banner_count": 0,
		"heroic_banner_count": 0,
		"council_banner_count": 0,
		"silvermoon_banner_count": 0,
		"inspiration_double_count": 0,
		"pulse_interval_sec": 16.0,
		"elf_attack_speed_percent_per_pulse": 5.0,
		"kingdom_damage_per_pulse": 5,
		"wasteland_spell_damage_percent_per_pulse": 2.0,
		"heroic_all_attributes_per_pulse": 1,
		"council_intelligence_per_pulse": 3,
		"silvermoon_battle_prep_multiplier": 1.25,
	}
	var item_count_by_name: Dictionary = {}
	var total_banner_count: int = 0
	for item_idx_variant in inv:
		var item_idx: int = int(item_idx_variant)
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_data: Dictionary = _get_item_data(item_db, item_idx)
		var item_name: String = _normalize_item_name_for_effects(item_data)
		item_count_by_name[item_name] = int(item_count_by_name.get(item_name, 0)) + 1
		if _normalize_build_name(str(item_data.get("build", _default_build_name))) == "战旗":
			total_banner_count += 1
	effects["total_banner_count"] = total_banner_count
	effects["elf_banner_count"] = _count_named_items(item_count_by_name, ["精灵战旗"])
	effects["kingdom_banner_count"] = _count_named_items(item_count_by_name, ["王国战旗"])
	effects["wasteland_banner_count"] = _count_named_items(item_count_by_name, ["荒芜战旗"])
	effects["heroic_banner_count"] = _count_named_items(item_count_by_name, ["英勇战旗"])
	effects["council_banner_count"] = _count_named_items(item_count_by_name, ["议会之旗"])
	effects["silvermoon_banner_count"] = _count_named_items(item_count_by_name, ["银月战旗"])
	effects["inspiration_double_count"] = _count_named_items(item_count_by_name, ["英灵旗布"])
	return effects


func _calculate_battle_prep_effects(item_db: Array, inv: Array) -> Dictionary:
	var effects: Dictionary = {
		"trigger_multiplier": 1,
		"snake_ward_count": 0,
		"challenge_griffin_count": 0,
		"revive_charge_if_empty": 0,
		"titan_helmet_count": 0,
	}
	var item_count_by_name: Dictionary = {}
	for item_idx_variant in inv:
		var item_idx: int = int(item_idx_variant)
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_name: String = _normalize_item_name_for_effects(_get_item_data(item_db, item_idx))
		item_count_by_name[item_name] = int(item_count_by_name.get(item_name, 0)) + 1
	var trigger_multiplier: int = 1 + _count_named_items(item_count_by_name, ["耐文合金"])
	effects["trigger_multiplier"] = maxi(trigger_multiplier, 1)
	effects["snake_ward_count"] = _count_named_items(item_count_by_name, ["储备蛇棒"]) * 3 * maxi(trigger_multiplier, 1)
	effects["challenge_griffin_count"] = _count_named_items(item_count_by_name, ["挑战头巾"]) * maxi(trigger_multiplier, 1)
	effects["revive_charge_if_empty"] = _count_named_items(item_count_by_name, ["吊命娃娃"]) * maxi(trigger_multiplier, 1)
	effects["titan_helmet_count"] = _count_named_items(item_count_by_name, ["泰坦巨盔"])
	return effects


func _calculate_settlement_effects(item_db: Array, inv: Array) -> Dictionary:
	var effects: Dictionary = {
		"settlement_item_count": 0,
		"extra_trigger_count": 0,
		"hawkeye_ring_count": 0,
		"gold_medal_count": 0,
		"lion_ring_count": 0,
		"judgement_sword_count": 0,
		"holy_sword_count": 0,
		"crit_overflow_item_count": 0,
		"double_crit_item_count": 0,
	}
	var item_count_by_name: Dictionary = {}
	var settlement_item_count: int = 0
	for item_idx_variant in inv:
		var item_idx: int = int(item_idx_variant)
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_data: Dictionary = _get_item_data(item_db, item_idx)
		var item_name: String = _normalize_item_name_for_effects(item_data)
		item_count_by_name[item_name] = int(item_count_by_name.get(item_name, 0)) + 1
		if _normalize_build_name(str(item_data.get("build", _default_build_name))) == "结算":
			settlement_item_count += 1
	effects["settlement_item_count"] = settlement_item_count
	effects["extra_trigger_count"] = _count_named_items(item_count_by_name, ["金色账簿", "账本"])
	effects["hawkeye_ring_count"] = _count_named_items(item_count_by_name, ["雄鹰戒指", "雄鹰戒子"])
	effects["gold_medal_count"] = _count_named_items(item_count_by_name, ["金色勋章"])
	effects["lion_ring_count"] = _count_named_items(item_count_by_name, ["雄狮之戒"])
	effects["judgement_sword_count"] = _count_named_items(item_count_by_name, ["审判金剑"])
	effects["holy_sword_count"] = _count_named_items(item_count_by_name, ["裁决者圣剑"])
	effects["crit_overflow_item_count"] = _count_named_items(item_count_by_name, ["开辟者"])
	effects["double_crit_item_count"] = _count_named_items(item_count_by_name, ["恶鬼剑"])
	return effects


func _calculate_coin_effects(item_db: Array, inv: Array, meta_array: Array, coin_state: Dictionary) -> Dictionary:
	var effects: Dictionary = {
		"strength": 0,
		"agility": 0,
		"intelligence": 0,
		"damage": 0,
		"attack_speed_percent": 0.0,
		"revive_charge_total": maxi(int(coin_state.get("revive_event_charges", 0)), 0),
		"auto_destroy_coin_enabled": _bool_from_variant(coin_state.get("auto_destroy_coin_enabled", false), false),
		"total_coin_count": 0,
		"total_coin_layers": 0,
		"gold_coin_count": 0,
		"gold_coin_refresh_limit": 0,
		"revenge_spirit_count": 0,
		"revenge_spirit_attack_percent": 0.0,
		"dream_active_count": 0,
	}
	var total_coin_layers: int = _get_total_coin_layers(item_db, inv, meta_array)
	var total_coin_count: int = _count_coin_items_in_inventory(item_db, inv)
	var smile_damage_tenths_total: int = 0
	var coin_item_count_by_name: Dictionary = {}
	for slot_idx in _get_coin_item_slots(item_db, inv):
		var item_idx: int = int(inv[slot_idx])
		var item_name: String = _get_item_name_by_index(item_db, item_idx)
		var entry: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, item_idx)
		coin_item_count_by_name[item_name] = int(coin_item_count_by_name.get(item_name, 0)) + 1
		effects["strength"] = int(effects.get("strength", 0)) + int(entry.get("permanent_strength", 0))
		effects["agility"] = int(effects.get("agility", 0)) + int(entry.get("permanent_agility", 0))
		effects["intelligence"] = int(effects.get("intelligence", 0)) + int(entry.get("permanent_intelligence", 0))
		effects["damage"] = int(effects.get("damage", 0)) + int(entry.get("permanent_damage", 0))
		effects["attack_speed_percent"] = float(effects.get("attack_speed_percent", 0.0)) + float(int(entry.get("permanent_attack_speed_percent", 0)))
		smile_damage_tenths_total += int(entry.get("permanent_damage_tenths", 0))
		if item_name == "经验币":
			effects["attack_speed_percent"] = float(effects.get("attack_speed_percent", 0.0)) + float(maxi(int(entry.get("coin_layers", 0)), 0))
		if item_name == "铜硬币":
			effects["damage"] = int(effects.get("damage", 0)) + total_coin_layers
	effects["damage"] = int(effects.get("damage", 0)) + int(smile_damage_tenths_total / 10)
	effects["damage"] = int(effects.get("damage", 0)) + maxi(int(coin_state.get("retained_copper_damage", 0)), 0)
	effects["total_coin_count"] = total_coin_count
	effects["total_coin_layers"] = total_coin_layers
	effects["gold_coin_count"] = _count_named_items(coin_item_count_by_name, ["金硬币"])
	effects["gold_coin_refresh_limit"] = int(effects["gold_coin_count"]) * _coin_gold_refresh_limit_per_item
	effects["revenge_spirit_count"] = _count_named_items(coin_item_count_by_name, ["怨恨硬币"])
	effects["revenge_spirit_attack_percent"] = (40.0 + float(total_coin_layers)) * float(int(effects["revenge_spirit_count"]))
	effects["dream_active_count"] = int(effects["gold_coin_count"])
	return effects


func _parse_item_bonus(item_data: Dictionary) -> Dictionary:
	var stat_text: String = str(item_data.get("stat", ""))
	var result: Dictionary = {
		"strength": 0,
		"agility": 0,
		"intelligence": 0,
		"hp": 0,
		"mana": 0,
		"damage": 0,
		"armor": 0.0,
		"attack_speed_percent": 0.0,
		"move_speed": 0.0,
		"attack_range": 0.0,
		"hp_regen": 0.0,
		"cooldown_reduction_percent": 0.0,
		"physical_crit_chance": 0.0,
		"physical_crit_multiplier": 0.0,
		"spell_crit_chance": 0.0,
		"spell_crit_multiplier": 0.0,
		"spell_damage_percent": 0.0,
		"magic_damage_reduction_percent": 0.0,
	}
	var all_attr: int = _sum_regex_int(stat_text, "\\+(\\d+)全属性")
	all_attr += _sum_regex_int(stat_text, "\\+(\\d+)三围(?:属性)?")
	result["strength"] = int(result["strength"]) + all_attr
	result["agility"] = int(result["agility"]) + all_attr
	result["intelligence"] = int(result["intelligence"]) + all_attr
	result["strength"] = int(result["strength"]) + _sum_regex_int(stat_text, "\\+(\\d+)力量")
	result["agility"] = int(result["agility"]) + _sum_regex_int(stat_text, "\\+(\\d+)敏捷")
	result["agility"] = int(result["agility"]) + _sum_regex_int(stat_text, "\\+(\\d+)敏(?!捷)")
	result["intelligence"] = int(result["intelligence"]) + _sum_regex_int(stat_text, "\\+(\\d+)智力")
	result["intelligence"] = int(result["intelligence"]) + _sum_regex_int(stat_text, "\\+(\\d+)智(?!力)")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "\\+(\\d+)生命")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "\\+(\\d+)[Hh][Pp]")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "\\+(\\d+)生命最大值")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "生命最大值\\+(\\d+)")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "\\+(\\d+)最大生命值")
	result["hp"] = int(result["hp"]) + _sum_regex_int(stat_text, "最大生命值\\+(\\d+)")
	result["mana"] = int(result["mana"]) + _sum_regex_int(stat_text, "\\+(\\d+)(?:法力|魔法|蓝量|MP)")
	result["mana"] = int(result["mana"]) + _sum_regex_int(stat_text, "\\+(\\d+)最大(?:法力|魔法|蓝量|MP)")
	result["mana"] = int(result["mana"]) + _sum_regex_int(stat_text, "最大(?:法力|魔法|蓝量|MP)\\+(\\d+)")
	result["damage"] = int(result["damage"]) + _sum_regex_int(stat_text, "\\+(\\d+)攻击(?:力)?")
	result["armor"] = float(result["armor"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)护甲"))
	result["attack_speed_percent"] = float(result["attack_speed_percent"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%攻速"))
	result["attack_speed_percent"] = float(result["attack_speed_percent"]) + float(_sum_regex_int(stat_text, "攻速\\+(\\d+)%"))
	result["attack_speed_percent"] = float(result["attack_speed_percent"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%攻击速度"))
	result["attack_speed_percent"] = float(result["attack_speed_percent"]) + float(_sum_regex_int(stat_text, "攻击速度\\+(\\d+)%"))
	result["move_speed"] = float(result["move_speed"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)移速"))
	result["move_speed"] = float(result["move_speed"]) + float(_sum_regex_int(stat_text, "移速\\+(\\d+)"))
	result["attack_range"] = float(result["attack_range"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)攻击范围"))
	result["attack_range"] = float(result["attack_range"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)攻击距离"))
	result["hp_regen"] = float(result["hp_regen"]) + _sum_regex_float(stat_text, "\\+(\\d+(?:\\.\\d+)?)生命恢复")
	result["hp_regen"] = float(result["hp_regen"]) + _sum_regex_float(stat_text, "生命恢复\\+(\\d+(?:\\.\\d+)?)")
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%冷却减免"))
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%冷却缩减"))
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "冷却减免\\+(\\d+)%"))
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "冷却缩减\\+(\\d+)%"))
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%[Cc][Dd][Rr]"))
	result["cooldown_reduction_percent"] = float(result["cooldown_reduction_percent"]) + float(_sum_regex_int(stat_text, "[Cc][Dd][Rr]\\+(\\d+)%"))
	result["physical_crit_chance"] = float(result["physical_crit_chance"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%暴击率"))
	result["physical_crit_chance"] = float(result["physical_crit_chance"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%暴击(?!率|伤害|倍率)"))
	result["physical_crit_multiplier"] = float(result["physical_crit_multiplier"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%(?:暴击伤害|暴击倍率)"))
	result["spell_crit_chance"] = float(result["spell_crit_chance"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%法术暴击率"))
	result["spell_crit_chance"] = float(result["spell_crit_chance"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%法暴率?"))
	result["spell_crit_multiplier"] = float(result["spell_crit_multiplier"]) + float(_sum_regex_int(stat_text, "\\+(\\d+)%(?:法术暴击伤害|法术暴击倍率|法暴伤害|法暴倍率)"))
	result["spell_damage_percent"] = float(result["spell_damage_percent"]) + _sum_regex_float(stat_text, "\\+(\\d+(?:\\.\\d+)?)%法伤")
	result["spell_damage_percent"] = float(result["spell_damage_percent"]) + _sum_regex_float(stat_text, "\\+(\\d+(?:\\.\\d+)?)%法术伤害")
	result["magic_damage_reduction_percent"] = float(result["magic_damage_reduction_percent"]) + _sum_regex_float(stat_text, "-(\\d+(?:\\.\\d+)?)%受到的魔法伤害")
	result["magic_damage_reduction_percent"] = float(result["magic_damage_reduction_percent"]) + _sum_regex_float(stat_text, "减少(\\d+(?:\\.\\d+)?)%受到的魔法伤害")
	return result


func _get_item_data(item_db: Array, item_idx: int) -> Dictionary:
	if item_idx < 0 or item_idx >= item_db.size():
		return {}
	if item_db[item_idx] is Dictionary:
		return item_db[item_idx] as Dictionary
	return {}


func _get_item_name_by_index(item_db: Array, item_idx: int) -> String:
	if item_idx < 0 or item_idx >= item_db.size():
		return ""
	return str(_get_item_data(item_db, item_idx).get("name", "")).strip_edges()


func _normalize_item_name_for_effects(item_data: Dictionary) -> String:
	return str(item_data.get("name", "")).strip_edges()


func _count_named_items(count_by_name: Dictionary, names: Array) -> int:
	var total: int = 0
	for name_variant in names:
		total += int(count_by_name.get(str(name_variant), 0))
	return total


func _is_spark_item_for_effects(item_data: Dictionary) -> bool:
	var item_name: String = _normalize_item_name_for_effects(item_data)
	if _spark_force_item_names.has(item_name):
		return true
	return _normalize_build_name(str(item_data.get("build", _default_build_name))) == "火花"


func _is_charge_item_for_effects(item_data: Dictionary) -> bool:
	return _normalize_build_name(str(item_data.get("build", _default_build_name))) == _charge_build_name


func _is_coin_item_for_effects(item_data: Dictionary) -> bool:
	var item_name: String = _normalize_item_name_for_effects(item_data)
	if item_name == "":
		return false
	if item_name == "硬币箱":
		return false
	if item_name == "夹层硬币" or item_name == "经验币":
		return true
	return _normalize_build_name(str(item_data.get("build", _default_build_name))) == _coin_build_name


func _get_coin_item_slots(item_db: Array, inventory: Array) -> Array[int]:
	var out: Array[int] = []
	for slot_idx in range(inventory.size()):
		var item_idx: int = int(inventory[slot_idx])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		if not _is_coin_item_for_effects(_get_item_data(item_db, item_idx)):
			continue
		out.append(slot_idx)
	return out


func _count_coin_items_in_inventory(item_db: Array, inventory: Array) -> int:
	return _get_coin_item_slots(item_db, inventory).size()


func _get_total_coin_layers(item_db: Array, inventory: Array, meta_array: Array) -> int:
	var total_layers: int = 0
	for slot_idx in _get_coin_item_slots(item_db, inventory):
		var item_idx: int = int(inventory[slot_idx])
		var entry: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, item_idx)
		total_layers += maxi(int(entry.get("coin_layers", 0)), 0)
	return total_layers


func _find_item_slots_by_name(item_db: Array, inventory: Array, item_name: String) -> Array[int]:
	var slots: Array[int] = []
	for i in range(inventory.size()):
		if _get_item_name_by_index(item_db, int(inventory[i])) == item_name:
			slots.append(i)
	return slots


func _get_inventory_meta_entry(meta_array: Array, slot_idx: int, _item_idx: int = -1) -> Dictionary:
	if slot_idx >= 0 and slot_idx < meta_array.size() and meta_array[slot_idx] is Dictionary:
		return (meta_array[slot_idx] as Dictionary).duplicate(true)
	return {}


func _get_effective_inventory_item_level(item_db: Array, item_idx: int, slot_idx: int, meta_array: Array, inventory: Array = []) -> int:
	if item_idx < 0 or item_idx >= item_db.size():
		return 0
	var item_name: String = _get_item_name_by_index(item_db, item_idx)
	if not inventory.is_empty() and _find_item_slots_by_name(item_db, inventory, "金硬币").size() > 0 and item_name != "金硬币":
		return 0
	var base_level: int = _get_item_level(_get_item_data(item_db, item_idx))
	var entry: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, item_idx)
	if item_name == "血羽之心":
		return maxi(int(entry.get("dynamic_level", base_level)), base_level)
	if item_name == "邪灵宝珠":
		return maxi(int(entry.get("dynamic_level", 0)), 0)
	return base_level


func _get_item_level(item_data: Dictionary) -> int:
	var stat: String = str(item_data.get("stat", ""))
	if stat.begins_with("Lv"):
		var space_idx: int = stat.find(" ")
		if space_idx > 2:
			return int(stat.substr(2, space_idx - 2))
	return 1


func _normalize_build_name(raw_build_name: String) -> String:
	var build_name: String = raw_build_name.strip_edges()
	if build_name == "":
		return _default_build_name
	var alias_variant: Variant = _build_alias_map.get(build_name, null)
	if alias_variant != null:
		var mapped_build: String = str(alias_variant).strip_edges()
		if mapped_build != "":
			return mapped_build
	return build_name


func _sum_regex_int(text: String, pattern: String) -> int:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return 0
	var total: int = 0
	for match_variant in regex.search_all(text):
		var match := match_variant as RegExMatch
		if match == null:
			continue
		var value_text: String = match.get_string(1)
		if value_text != "":
			total += int(value_text)
	return total


func _sum_regex_float(text: String, pattern: String) -> float:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return 0.0
	var total: float = 0.0
	for match_variant in regex.search_all(text):
		var match := match_variant as RegExMatch
		if match == null:
			continue
		var value_text: String = match.get_string(1)
		if value_text == "":
			continue
		total += float(value_text)
	return total


func _bool_from_variant(value: Variant, fallback: bool = false) -> bool:
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
