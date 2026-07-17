extends GdUnitTestSuite


func test_normalize_difficulty_key() -> void:
	# 表驱动：[raw, expected]
	var cases := [
		["simple", "simple"],
		[" HARD ", "hard"],
		["Inferno", "inferno"],
		["不存在的难度", "simple"],
		["", "simple"],
	]
	for c: Array in cases:
		assert_str(RogueFloorBalance.normalize_difficulty_key(c[0])).is_equal(c[1])


func test_build_floor_profile_floor1_simple() -> void:
	var p := RogueFloorBalance.build_floor_profile(1, "simple")
	assert_float(p["damage_growth"]).is_equal_approx(1.30, 0.0001)
	assert_float(p["boss_hp_growth"]).is_equal_approx(1.40, 0.0001)
	# boss_damage = 1.30^1 * 0.75 * 3.0
	assert_float(p["boss_damage_multiplier"]).is_equal_approx(2.925, 0.0001)
	# boss_hp = 1.40^1 * 2.0
	assert_float(p["boss_hp_multiplier"]).is_equal_approx(2.8, 0.0001)
	assert_float(p["boss_armor_bonus"]).is_equal_approx(1.5, 0.0001)


func test_build_floor_profile_floor_thresholds() -> void:
	# 第 10 层起 boss 血量成长 +0.03，第 12 层起技能伤害成长 -0.01
	var p9 := RogueFloorBalance.build_floor_profile(9, "hard")
	var p10 := RogueFloorBalance.build_floor_profile(10, "hard")
	var p12 := RogueFloorBalance.build_floor_profile(12, "hard")
	assert_float(p9["boss_hp_growth"]).is_equal_approx(1.40, 0.0001)
	assert_float(p10["boss_hp_growth"]).is_equal_approx(1.43, 0.0001)
	assert_float(p9["skill_damage_growth"]).is_equal_approx(1.30, 0.0001)
	assert_float(p12["skill_damage_growth"]).is_equal_approx(1.29, 0.0001)


func test_build_floor_profile_difficulty_offsets() -> void:
	# inferno：全成长 +0.10，boss 血量成长偏移 -0.10（相互抵消回 1.40）
	var p := RogueFloorBalance.build_floor_profile(1, "inferno")
	assert_float(p["damage_growth"]).is_equal_approx(1.40, 0.0001)
	assert_float(p["boss_hp_growth"]).is_equal_approx(1.40, 0.0001)
	assert_float(p["enemy_damage_multiplier"]).is_equal_approx(1.20, 0.0001)


func test_build_floor_profile_clamps_floor_index() -> void:
	var p := RogueFloorBalance.build_floor_profile(-3, "simple")
	assert_int(p["floor_index"]).is_equal(1)


func test_round_clear_gold() -> void:
	# 200 + 150 * max(floor, 1)
	assert_int(RogueFloorBalance.get_round_clear_base_gold(1)).is_equal(350)
	assert_int(RogueFloorBalance.get_round_clear_base_gold(5)).is_equal(950)
	assert_int(RogueFloorBalance.get_round_clear_base_gold(0)).is_equal(350)
