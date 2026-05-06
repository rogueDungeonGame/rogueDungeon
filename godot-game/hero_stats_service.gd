extends RefCounted
class_name HeroStatsService


static func get_primary_attr_value(primary_attribute: String, strength: int, agility: int, intelligence: int) -> int:
	match primary_attribute:
		"力量":
			return strength
		"智力":
			return intelligence
		_:
			return agility


static func build_recalculated_stats(input: Dictionary) -> Dictionary:
	var lv: int = maxi(int(input.get("hero_level", 1)), 1)
	var strength: int = int(round(
		float(input.get("strength_base", 0))
		+ (float(input.get("strength_growth", 0.0)) + float(input.get("strength_growth_bonus", 0.0))) * float(lv - 1)
	)) + int(input.get("equip_strength_bonus", 0)) + int(input.get("battle_banner_applied_strength_bonus", 0))
	var agility: int = int(round(
		float(input.get("agility_base", 0))
		+ (float(input.get("agility_growth", 0.0)) + float(input.get("agility_growth_bonus", 0.0))) * float(lv - 1)
	)) + int(input.get("equip_agility_bonus", 0)) + int(input.get("settlement_permanent_agility_bonus", 0)) + int(input.get("battle_banner_applied_agility_bonus", 0))
	var intelligence: int = int(round(
		float(input.get("intelligence_base", 0))
		+ float(input.get("intelligence_growth", 0.0)) * float(lv - 1)
	)) + int(input.get("equip_intelligence_bonus", 0)) + int(input.get("necro_bonus_int_from_flute", 0)) + int(input.get("settlement_permanent_intelligence_bonus", 0)) + int(input.get("battle_banner_applied_intelligence_bonus", 0))

	var max_hp: int = int(input.get("base_hp_flat", 0)) \
		+ int(input.get("equip_hp_bonus", 0)) \
		+ int(input.get("spark_permanent_hp_bonus_from_procs", 0)) \
		+ int(input.get("charge_permanent_hp_bonus_from_procs", 0)) \
		+ int(input.get("necro_bonus_max_hp_from_summons", 0)) \
		+ int(input.get("settlement_permanent_hp_bonus", 0)) \
		+ strength * int(input.get("str_hp_per_point", 25))
	var scaled_base_mana: int = roundi(float(input.get("base_mana_flat", 0)) * maxf(float(input.get("initial_mana_multiplier", 0.0)), 0.0))
	var max_mana: int = scaled_base_mana + int(input.get("equip_mana_bonus", 0)) + intelligence * int(input.get("int_mana_per_point", 15))

	var damage_per_hit: int = int(input.get("base_damage_flat", 0)) + int(input.get("equip_damage_bonus", 0)) + int(input.get("battle_banner_applied_damage_bonus", 0))
	damage_per_hit += get_primary_attr_value(
		str(input.get("primary_attribute", "敏捷")),
		strength,
		agility,
		intelligence
	)
	damage_per_hit += int(input.get("talent_flat_damage_bonus", 0))
	damage_per_hit += maxi(lv - 1, 0) * int(input.get("talent_damage_growth_per_level", 0))
	if bool(input.get("is_rifleman", false)):
		damage_per_hit += int(input.get("rifleman_oil_passive_damage_bonus", 0))

	var armor: float = float(input.get("base_armor_flat", 0.0)) + float(input.get("equip_armor_bonus", 0.0)) + float(agility) * float(input.get("agi_armor_per_point", 0.0))
	var raw_physical_crit_chance: float = float(input.get("settlement_raw_physical_crit_chance", 0.0))
	var dynamic_physical_crit_multiplier_bonus: float = float(input.get("settlement_dynamic_physical_crit_multiplier_bonus", 0.0))
	if bool(input.get("is_warden", false)):
		raw_physical_crit_chance += float(input.get("warden_dagger_crit_chance_bonus", 0.0))
	raw_physical_crit_chance += float(input.get("talent_physical_crit_chance_bonus", 0.0))
	var physical_crit_chance: float = clampf(raw_physical_crit_chance, 0.0, 100.0)
	var physical_crit_multiplier: float = maxf(
		float(input.get("base_physical_crit_multiplier", 2.0))
		+ (float(input.get("equip_physical_crit_multiplier_bonus", 0.0)) + dynamic_physical_crit_multiplier_bonus) * 0.01,
		1.0
	)
	var spell_crit_chance: float = clampf(float(input.get("base_spell_crit_chance", 0.0)) + float(input.get("equip_spell_crit_chance_bonus", 0.0)), 0.0, 100.0)
	var spell_crit_multiplier: float = maxf(float(input.get("base_spell_crit_multiplier", 2.0)) + float(input.get("equip_spell_crit_multiplier_bonus", 0.0)) * 0.01, 1.0)
	if bool(input.get("is_warden", false)):
		spell_crit_chance = maxf(spell_crit_chance, physical_crit_chance)
		spell_crit_multiplier = maxf(spell_crit_multiplier, physical_crit_multiplier)

	var cooldown_reduction_percent_total: float = compute_cooldown_reduction_percent(
		float(input.get("base_cooldown_reduction_percent", 0.0)),
		float(input.get("equip_cooldown_reduction_percent_bonus", 0.0)),
		float(input.get("max_cooldown_reduction_percent", 80.0))
	)
	var hp_regen_per_second: float = float(input.get("base_hp_regen_flat", 0.0)) + float(input.get("equip_hp_regen_bonus", 0.0)) + float(strength) * float(input.get("str_hp_regen_per_point", 0.05))
	var mana_regen_per_second: float = float(input.get("base_mana_regen_flat", 0.0)) + float(intelligence) * float(input.get("int_mana_regen_per_point", 0.05))
	var move_speed: float = clampf(
		float(input.get("base_move_speed", 0.0)) + float(input.get("equip_move_speed_bonus", 0.0)) + float(input.get("talent_move_speed_bonus_flat", 0.0)),
		float(input.get("wc3_min_move_speed", 100.0)),
		float(input.get("wc3_max_move_speed", 522.0))
	)
	var attack_range: float = maxf(float(input.get("base_attack_range", 0.0)) + float(input.get("equip_attack_range_bonus", 0.0)) + float(input.get("talent_attack_range_bonus_flat", 0.0)), 60.0)

	return {
		"hero_level": lv,
		"strength": strength,
		"agility": agility,
		"intelligence": intelligence,
		"max_hp": max_hp,
		"max_mana": max_mana,
		"damage_per_hit": damage_per_hit,
		"armor": armor,
		"physical_crit_chance": physical_crit_chance,
		"physical_crit_multiplier": physical_crit_multiplier,
		"spell_crit_chance": spell_crit_chance,
		"spell_crit_multiplier": spell_crit_multiplier,
		"cooldown_reduction_percent_total": cooldown_reduction_percent_total,
		"hp_regen_per_second": hp_regen_per_second,
		"mana_regen_per_second": mana_regen_per_second,
		"move_speed": move_speed,
		"attack_range": attack_range,
	}


static func get_effective_ias_percent(
		agility: int,
		equip_attack_speed_percent_bonus: float,
		spark_permanent_attack_speed_bonus_from_soul: float,
		spark_temp_attack_speed_bonus_percent: float,
		battle_banner_applied_attack_speed_percent_bonus: float,
		talent_attack_speed_percent_bonus: float,
		agi_attack_speed_per_point: float,
		ias_min: float,
		ias_max: float
	) -> float:
	var agi_ias_percent: float = float(agility) * agi_attack_speed_per_point * 100.0
	var total_ias: float = agi_ias_percent + equip_attack_speed_percent_bonus
	total_ias += spark_permanent_attack_speed_bonus_from_soul
	total_ias += spark_temp_attack_speed_bonus_percent
	total_ias += battle_banner_applied_attack_speed_percent_bonus
	total_ias += talent_attack_speed_percent_bonus
	return clampf(total_ias, ias_min, ias_max)


static func get_attack_speed_scale(
		base_attack_speed: float,
		attack_speed_percent_total: float,
		is_transformed: bool,
		transformed_attack_speed_multiplier: float,
		haste_active: bool,
		skill_w_id: int,
		haste_skill_id: int,
		haste_multiplier: float,
		talent_warden_w_attack_speed_multiplier_bonus: float
	) -> float:
	var speed_factor: float = 1.0 + attack_speed_percent_total * 0.01
	var speed: float = base_attack_speed * maxf(speed_factor, 0.05)
	if is_transformed:
		speed *= transformed_attack_speed_multiplier
	if haste_active and skill_w_id == haste_skill_id:
		speed *= haste_multiplier + talent_warden_w_attack_speed_multiplier_bonus
	return maxf(speed, 0.05)


static func get_attack_interval(attack_speed_scale: float, spark_attack_interval_reduction_sec: float) -> float:
	var interval: float = 1.0 / maxf(attack_speed_scale, 0.05)
	interval -= maxf(spark_attack_interval_reduction_sec, 0.0)
	return maxf(interval, 0.05)


static func compute_cooldown_reduction_percent(base_cooldown_reduction_percent: float, equip_cooldown_reduction_percent_bonus: float, max_cooldown_reduction_percent: float) -> float:
	var total_cdr: float = base_cooldown_reduction_percent + equip_cooldown_reduction_percent_bonus
	return clampf(total_cdr, 0.0, max_cooldown_reduction_percent)


static func compute_skill_cooldown(base_cooldown: float, cooldown_reduction_percent_total: float, max_cooldown_reduction_percent: float) -> float:
	var safe_base: float = maxf(base_cooldown, 0.0)
	if safe_base <= 0.0:
		return 0.0
	var cdr_ratio: float = clampf(cooldown_reduction_percent_total, 0.0, max_cooldown_reduction_percent) * 0.01
	return safe_base * maxf(1.0 - cdr_ratio, 0.0)


static func get_armor_damage_multiplier(armor: float, armor_k_melee_default: float, negative_armor_base_melee_default: float) -> float:
	if armor >= 0.0:
		var reduction: float = (armor_k_melee_default * armor) / (1.0 + armor_k_melee_default * armor)
		return maxf(1.0 - reduction, 0.0)
	return 2.0 - pow(negative_armor_base_melee_default, -armor)


static func get_magic_damage_multiplier(total_magic_reduction_percent: float) -> float:
	var clamped_rate: float = clampf(total_magic_reduction_percent, 0.0, 95.0)
	return maxf(1.0 - clamped_rate * 0.01, 0.0)


static func is_magic_damage_type(damage_type: String) -> bool:
	var kind: String = damage_type.strip_edges().to_lower()
	if kind.begins_with("attack_effect"):
		return true
	match kind:
		"magic", "spell", "q_ray", "flash", "poison", "skill":
			return true
		_:
			return false


static func compute_physical_damage(base_damage_amount: int, physical_crit_chance: float, physical_crit_multiplier: float) -> int:
	return int(compute_physical_damage_result(base_damage_amount, physical_crit_chance, physical_crit_multiplier).get("damage", 0))


static func compute_spell_damage(base_damage_amount: int, spell_bonus_percent: float, spell_crit_chance: float, spell_crit_multiplier: float) -> int:
	return int(compute_spell_damage_result(base_damage_amount, spell_bonus_percent, spell_crit_chance, spell_crit_multiplier).get("damage", 0))


static func compute_physical_damage_result(base_damage_amount: int, physical_crit_chance: float, physical_crit_multiplier: float) -> Dictionary:
	var dmg: int = maxi(base_damage_amount, 0)
	if dmg <= 0:
		return {
			"damage": 0,
			"is_critical": false,
		}
	var is_critical: bool = _roll_critical(physical_crit_chance)
	if is_critical:
		dmg = maxi(int(round(float(dmg) * physical_crit_multiplier)), 1)
	return {
		"damage": dmg,
		"is_critical": is_critical,
	}


static func compute_spell_damage_result(base_damage_amount: int, spell_bonus_percent: float, spell_crit_chance: float, spell_crit_multiplier: float) -> Dictionary:
	var dmg: int = maxi(base_damage_amount, 0)
	if dmg <= 0:
		return {
			"damage": 0,
			"is_critical": false,
		}
	if spell_bonus_percent > 0.0:
		dmg = maxi(int(round(float(dmg) * maxf(1.0 + spell_bonus_percent * 0.01, 0.0))), 0)
		if dmg <= 0:
			return {
				"damage": 0,
				"is_critical": false,
			}
	var is_critical: bool = _roll_critical(spell_crit_chance)
	if is_critical:
		dmg = maxi(int(round(float(dmg) * spell_crit_multiplier)), 1)
	return {
		"damage": dmg,
		"is_critical": is_critical,
	}


static func _roll_critical(chance_percent: float) -> bool:
	var clamped_chance: float = clampf(chance_percent, 0.0, 100.0)
	if clamped_chance <= 0.0:
		return false
	return randf() * 100.0 < clamped_chance
