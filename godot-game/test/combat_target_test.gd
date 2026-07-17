extends GdUnitTestSuite


func test_null_and_non_combat_nodes() -> void:
	assert_bool(CombatTarget.is_damageable(null)).is_false()
	assert_bool(CombatTarget.is_dead(null)).is_false()
	assert_bool(CombatTarget.can_receive_skill_damage(null)).is_false()
	var plain: Node3D = auto_free(Node3D.new())
	assert_bool(CombatTarget.is_damageable(plain)).is_false()
	assert_bool(CombatTarget.apply_enemy_damage(plain, 10)).is_false()
	assert_bool(CombatTarget.apply_hero_damage(plain, 10)).is_false()
	assert_bool(CombatTarget.apply_knockback(plain, Vector3.FORWARD, 10.0)).is_false()
	assert_float(CombatTarget.get_incoming_damage_bonus_percent(plain)).is_equal_approx(0.0, 0.0001)
	# 非战斗节点默认允许技能伤害（与旧 has_method 探测语义一致）
	assert_bool(CombatTarget.can_receive_skill_damage(plain)).is_true()


func test_boss_gate_dispatch() -> void:
	var gate: BossGate = auto_free(BossGate.new())
	# apply_damage 内部访问 multiplayer，节点必须挂进场景树
	add_child(gate)
	assert_bool(CombatTarget.is_damageable(gate)).is_true()
	assert_bool(CombatTarget.is_dead(gate)).is_false()
	# BossGate 显式拒绝技能伤害，分发器必须转发而不是走默认值
	assert_bool(CombatTarget.can_receive_skill_damage(gate)).is_false()
	# 大门没有击退/伤害加成，走安全默认
	assert_bool(CombatTarget.apply_knockback(gate, Vector3.FORWARD, 10.0)).is_false()
	assert_bool(CombatTarget.apply_incoming_damage_bonus(gate, 10.0, 1.0, false)).is_false()
	assert_bool(CombatTarget.apply_enemy_damage(gate, 5)).is_true()
