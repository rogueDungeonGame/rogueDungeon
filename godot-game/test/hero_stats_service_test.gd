extends GdUnitTestSuite


func test_get_primary_attr_value() -> void:
	# 表驱动：[primary, expected]（str=10, agi=20, int=30）
	var cases := [
		["力量", 10],
		["智力", 30],
		["敏捷", 20],
		["未知", 20],
	]
	for c: Array in cases:
		assert_int(HeroStatsService.get_primary_attr_value(c[0], 10, 20, 30)).is_equal(c[1])


func test_build_recalculated_stats_basic_growth() -> void:
	var stats := (
		HeroStatsService
		. build_recalculated_stats(
			{
				"hero_level": 5,
				"strength_base": 20,
				"strength_growth": 2.0,
				"equip_strength_bonus": 3,
				"agility_base": 15,
				"agility_growth": 1.5,
				"intelligence_base": 18,
				"intelligence_growth": 1.8,
				"primary_attribute": "敏捷",
				"base_hp_flat": 100,
				"base_mana_flat": 100,
				"initial_mana_multiplier": 1.0,
				"base_damage_flat": 10,
				"base_armor_flat": 2.0,
			}
		)
	)
	# str = round(20 + 2.0*4) + 3 = 31; agi = round(15 + 1.5*4) = 21
	# int = round(18 + 1.8*4) = round(25.2) = 25
	assert_int(stats["strength"]).is_equal(31)
	assert_int(stats["agility"]).is_equal(21)
	assert_int(stats["intelligence"]).is_equal(25)
	# max_hp = 100 + 31*25（str_hp_per_point 默认 25）
	assert_int(stats["max_hp"]).is_equal(875)
	# max_mana = 100*1.0 + 25*15（int_mana_per_point 默认 15）
	assert_int(stats["max_mana"]).is_equal(475)
	# damage = 10 + 主属性(敏捷 21)
	assert_int(stats["damage_per_hit"]).is_equal(31)
	assert_float(stats["armor"]).is_equal_approx(2.0, 0.0001)


func test_build_recalculated_stats_level_floor() -> void:
	var stats := HeroStatsService.build_recalculated_stats({"hero_level": -2})
	assert_int(stats["hero_level"]).is_equal(1)


func test_effective_ias_percent_clamped() -> void:
	# 30 敏捷 * 0.02/点 * 100 = 60%，+装备 40% = 100%，上限 80%
	var ias := HeroStatsService.get_effective_ias_percent(
		30, 40.0, 0.0, 0.0, 0.0, 0.0, 0.02, -80.0, 80.0
	)
	assert_float(ias).is_equal_approx(80.0, 0.0001)


func test_attack_interval() -> void:
	# 1/2.0 - 0.1 = 0.4
	assert_float(HeroStatsService.get_attack_interval(2.0, 0.1)).is_equal_approx(0.4, 0.0001)
	# 下限 0.05
	assert_float(HeroStatsService.get_attack_interval(100.0, 10.0)).is_equal_approx(0.05, 0.0001)


func test_compute_skill_cooldown() -> void:
	# 表驱动：[base, cdr, cdr上限, expected]
	var cases := [
		[10.0, 30.0, 80.0, 7.0],
		[10.0, 100.0, 80.0, 2.0],
		[0.0, 50.0, 80.0, 0.0],
		[-5.0, 50.0, 80.0, 0.0],
	]
	for c: Array in cases:
		assert_float(HeroStatsService.compute_skill_cooldown(c[0], c[1], c[2])).is_equal_approx(
			c[3], 0.0001
		)


func test_armor_damage_multiplier() -> void:
	# armor=0 → 无减伤
	assert_float(HeroStatsService.get_armor_damage_multiplier(0.0, 0.06, 0.94)).is_equal_approx(
		1.0, 0.0001
	)
	# armor=10, k=0.06 → 1 - 0.6/1.6 = 0.625
	assert_float(HeroStatsService.get_armor_damage_multiplier(10.0, 0.06, 0.94)).is_equal_approx(
		0.625, 0.0001
	)
	# 负甲：2 - 0.94^5
	assert_float(HeroStatsService.get_armor_damage_multiplier(-5.0, 0.06, 0.94)).is_equal_approx(
		2.0 - pow(0.94, 5.0), 0.0001
	)


func test_magic_damage_multiplier() -> void:
	assert_float(HeroStatsService.get_magic_damage_multiplier(0.0)).is_equal_approx(1.0, 0.0001)
	assert_float(HeroStatsService.get_magic_damage_multiplier(50.0)).is_equal_approx(0.5, 0.0001)
	# 上限 95%
	assert_float(HeroStatsService.get_magic_damage_multiplier(200.0)).is_equal_approx(0.05, 0.0001)


func test_is_magic_damage_type() -> void:
	# 表驱动：[type, expected]
	var cases := [
		["magic", true],
		[" SPELL ", true],
		["attack_effect_lightning", true],
		["poison", true],
		["physical", false],
		["", false],
	]
	for c: Array in cases:
		assert_bool(HeroStatsService.is_magic_damage_type(c[0])).is_equal(c[1])


func test_compute_physical_damage_result_no_crit() -> void:
	# 暴击率 0 → 确定性无暴击
	var result := HeroStatsService.compute_physical_damage_result(100, 0.0, 2.0)
	assert_int(result["damage"]).is_equal(100)
	assert_bool(result["is_critical"]).is_false()
	# 非正伤害直接归零
	assert_int(HeroStatsService.compute_physical_damage_result(-5, 0.0, 2.0)["damage"]).is_equal(0)


func test_compute_spell_damage_result_bonus_no_crit() -> void:
	# 100 * (1 + 50%) = 150，暴击率 0
	var result := HeroStatsService.compute_spell_damage_result(100, 50.0, 0.0, 2.0)
	assert_int(result["damage"]).is_equal(150)
	assert_bool(result["is_critical"]).is_false()
