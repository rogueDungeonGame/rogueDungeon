extends RefCounted
class_name RogueFloorBalance

const DIFFICULTY_SIMPLE: String = "simple"
const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "hard"
const DIFFICULTY_CRUEL: String = "cruel"
const DIFFICULTY_INFERNO: String = "inferno"

const DEFAULT_TOTAL_FLOORS: int = 21
const BASE_DAMAGE_GROWTH: float = 1.30
const BASE_BOSS_HP_GROWTH: float = 1.40
const BASE_SKILL_DAMAGE_GROWTH: float = 1.30
const BASE_MOB_HP_GROWTH: float = 1.35
const BOSS_BASE_ATTACK_MULTIPLIER: float = 3.0
const BOSS_BASE_HP_MULTIPLIER: float = 2.0
const BOSS_BASE_SKILL_DAMAGE_MULTIPLIER: float = 2.0
const MOB_BASE_ATTACK_MULTIPLIER: float = 2.0
const MOB_BASE_HP_MULTIPLIER: float = 2.0
const FLOOR_10_BOSS_HP_BONUS: float = 0.03
const FLOOR_12_SKILL_DAMAGE_PENALTY: float = 0.01
const BOSS_ARMOR_BONUS_PER_FLOOR: float = 1.5
const ROUND_CLEAR_BASE_GOLD: int = 200
const ROUND_CLEAR_GOLD_PER_FLOOR: int = 150
const ROUND_CLEAR_SURVIVOR_BONUS: int = 35

const DIFFICULTY_DATA := {
	DIFFICULTY_SIMPLE: {
		"display_name": "Simple",
		"enemy_damage_multiplier": 0.75,
		"growth_bonus_all": 0.0,
		"boss_hp_growth_offset": 0.0,
	},
	DIFFICULTY_NORMAL: {
		"display_name": "Normal",
		"enemy_damage_multiplier": 0.85,
		"growth_bonus_all": 0.0,
		"boss_hp_growth_offset": 0.0,
	},
	DIFFICULTY_HARD: {
		"display_name": "Hard",
		"enemy_damage_multiplier": 1.0,
		"growth_bonus_all": 0.0,
		"boss_hp_growth_offset": 0.0,
	},
	DIFFICULTY_CRUEL: {
		"display_name": "Cruel",
		"enemy_damage_multiplier": 1.0,
		"growth_bonus_all": 0.05,
		"boss_hp_growth_offset": -0.05,
	},
	DIFFICULTY_INFERNO: {
		"display_name": "Inferno",
		"enemy_damage_multiplier": 1.20,
		"growth_bonus_all": 0.10,
		"boss_hp_growth_offset": -0.10,
	},
}


static func normalize_difficulty_key(raw_value: String) -> String:
	var key: String = raw_value.strip_edges().to_lower()
	if DIFFICULTY_DATA.has(key):
		return key
	return DIFFICULTY_SIMPLE


static func get_difficulty_display_name(raw_value: String) -> String:
	var key: String = normalize_difficulty_key(raw_value)
	return str((DIFFICULTY_DATA[key] as Dictionary).get("display_name", "Simple"))


static func build_floor_profile(floor_index: int, raw_difficulty: String = DIFFICULTY_SIMPLE) -> Dictionary:
	var floor_no: int = maxi(floor_index, 1)
	var difficulty_key: String = normalize_difficulty_key(raw_difficulty)
	var difficulty: Dictionary = DIFFICULTY_DATA[difficulty_key] as Dictionary
	var growth_bonus_all: float = float(difficulty.get("growth_bonus_all", 0.0))
	var boss_hp_growth_offset: float = float(difficulty.get("boss_hp_growth_offset", 0.0))

	var damage_growth: float = BASE_DAMAGE_GROWTH + growth_bonus_all
	var boss_hp_growth: float = BASE_BOSS_HP_GROWTH + growth_bonus_all + boss_hp_growth_offset
	var skill_damage_growth: float = BASE_SKILL_DAMAGE_GROWTH + growth_bonus_all
	var mob_hp_growth: float = BASE_MOB_HP_GROWTH + growth_bonus_all

	if floor_no >= 10:
		boss_hp_growth += FLOOR_10_BOSS_HP_BONUS
	if floor_no >= 12:
		skill_damage_growth -= FLOOR_12_SKILL_DAMAGE_PENALTY

	var enemy_damage_multiplier: float = float(difficulty.get("enemy_damage_multiplier", 1.0))
	var boss_damage_multiplier: float = pow(damage_growth, floor_no) * enemy_damage_multiplier * BOSS_BASE_ATTACK_MULTIPLIER
	var boss_skill_damage_multiplier: float = pow(skill_damage_growth, floor_no) * enemy_damage_multiplier * BOSS_BASE_SKILL_DAMAGE_MULTIPLIER
	var boss_hp_multiplier: float = pow(boss_hp_growth, floor_no) * BOSS_BASE_HP_MULTIPLIER
	var mob_damage_multiplier: float = pow(damage_growth, floor_no) * enemy_damage_multiplier * MOB_BASE_ATTACK_MULTIPLIER
	var mob_hp_multiplier: float = pow(mob_hp_growth, floor_no) * MOB_BASE_HP_MULTIPLIER

	return {
		"floor_index": floor_no,
		"difficulty_key": difficulty_key,
		"difficulty_name": str(difficulty.get("display_name", "Simple")),
		"enemy_damage_multiplier": enemy_damage_multiplier,
		"damage_growth": damage_growth,
		"boss_hp_growth": boss_hp_growth,
		"skill_damage_growth": skill_damage_growth,
		"mob_hp_growth": mob_hp_growth,
		"boss_damage_multiplier": boss_damage_multiplier,
		"boss_hp_multiplier": boss_hp_multiplier,
		"boss_skill_damage_multiplier": boss_skill_damage_multiplier,
		"mob_damage_multiplier": mob_damage_multiplier,
		"mob_hp_multiplier": mob_hp_multiplier,
		"boss_armor_bonus": BOSS_ARMOR_BONUS_PER_FLOOR * float(floor_no),
	}


static func get_round_clear_base_gold(floor_index: int) -> int:
	return ROUND_CLEAR_BASE_GOLD + ROUND_CLEAR_GOLD_PER_FLOOR * maxi(floor_index, 1)


static func get_round_clear_survivor_bonus() -> int:
	return ROUND_CLEAR_SURVIVOR_BONUS
