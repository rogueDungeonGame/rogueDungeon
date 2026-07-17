class_name CombatTarget
extends Object
## apply_damage 家族的中央分发器。
##
## 为什么不是公共基类：TaurenUnitAI 基于 CharacterBody3D，其余三类基于 Node3D，
## GDScript 单继承无法共享脚本基类；且英雄与敌方的 apply_damage 签名本就不同
## （敌方: amount/attacker/source/context，英雄: amount/ignore_armor/attacker/type）。
## 跨类型战斗调用统一走本类的静态方法，类型分发一处收口，调用点全部静态可查。


static func is_damageable(target: Node) -> bool:
	return (
		target is EnemyAI
		or target is TaurenUnitAI
		or target is BossGate
		or target is HeroController
	)


## 敌方家族伤害（EnemyAI / TaurenUnitAI / BossGate 签名一致）。命中返回 true。
static func apply_enemy_damage(
	target: Node,
	amount: int,
	attacker: Node3D = null,
	damage_source: String = "basic_attack",
	hit_context: Dictionary = {}
) -> bool:
	if target is EnemyAI:
		(target as EnemyAI).apply_damage(amount, attacker, damage_source, hit_context)
		return true
	if target is TaurenUnitAI:
		(target as TaurenUnitAI).apply_damage(amount, attacker, damage_source, hit_context)
		return true
	if target is BossGate:
		(target as BossGate).apply_damage(amount, attacker, damage_source, hit_context)
		return true
	return false


## 英雄伤害（签名与敌方不同，不做参数映射，调用方自行区分语义）。
static func apply_hero_damage(
	target: Node,
	amount: int,
	ignore_armor: bool = false,
	attacker: Node3D = null,
	damage_type: String = "physical"
) -> bool:
	if target is HeroController:
		(target as HeroController).apply_damage(amount, ignore_armor, attacker, damage_type)
		return true
	return false


static func is_dead(target: Node) -> bool:
	if target is EnemyAI:
		return (target as EnemyAI).is_dead()
	if target is TaurenUnitAI:
		return (target as TaurenUnitAI).is_dead()
	if target is BossGate:
		return (target as BossGate).is_dead()
	if target is HeroController:
		return (target as HeroController).is_dead()
	return false


## 默认允许：只有显式声明限制的目标（BossGate）才会拒绝技能伤害。
static func can_receive_skill_damage(target: Node) -> bool:
	if target == null:
		return false
	if target is BossGate:
		return (target as BossGate).can_receive_skill_damage()
	return true


static func apply_knockback(
	target: Node,
	push_direction: Vector3,
	distance: float,
	duration_sec: float = 0.2,
	source_priority: int = 0
) -> bool:
	if target is EnemyAI:
		return (target as EnemyAI).apply_knockback(
			push_direction, distance, duration_sec, source_priority
		)
	if target is TaurenUnitAI:
		return (target as TaurenUnitAI).apply_knockback(
			push_direction, distance, duration_sec, source_priority
		)
	return false


static func get_incoming_damage_bonus_percent(target: Node) -> float:
	if target is EnemyAI:
		return maxf((target as EnemyAI).get_incoming_damage_bonus_percent(), 0.0)
	if target is TaurenUnitAI:
		return maxf((target as TaurenUnitAI).get_incoming_damage_bonus_percent(), 0.0)
	return 0.0


static func apply_incoming_damage_bonus(
	target: Node, bonus_percent: float, duration_sec: float, permanent: bool
) -> bool:
	if target is EnemyAI:
		(target as EnemyAI).apply_incoming_damage_bonus(bonus_percent, duration_sec, permanent)
		return true
	if target is TaurenUnitAI:
		(target as TaurenUnitAI).apply_incoming_damage_bonus(bonus_percent, duration_sec, permanent)
		return true
	return false
