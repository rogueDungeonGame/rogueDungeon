extends RefCounted
class_name TalentSelectionController

const HERO_ID_RANGED: int = 2
const TALENT_CHOICES_PER_LEVEL: int = 2
const TALENT_OPTIONS_PER_ROLL: int = 3

const WARDEN_TALENT_POOL := [
	{"id": "warden_q_damage", "title": "刀阵旋风伤害 +20%", "desc": "提高刀阵旋风的伤害。"},
	{"id": "warden_q_cd", "title": "刀阵旋风冷却 -20%", "desc": "乘法叠加降低 Q 冷却。"},
	{"id": "warden_q_echo", "title": "刀阵旋风残影", "desc": "额外在原地留下 20% 伤害的残影斩击。"},
	{"id": "warden_w_hits", "title": "淬毒环刃攻击次数 +1", "desc": "W 持续期间的强化攻击次数增加。"},
	{"id": "warden_w_cdr_on_hit", "title": "攻击减少淬毒环刃 1 秒冷却", "desc": "普通攻击命中时减少 W 冷却。"},
	{"id": "warden_e_mana", "title": "淬魂匕攻击回蓝", "desc": "攻击命中额外回复 4 点魔法。"},
	{"id": "warden_w_speed", "title": "淬毒环刃攻速加成翻倍", "desc": "W 的攻速强化进一步提高。"},
	{"id": "warden_move_speed", "title": "移动速度 +30", "desc": "永久提高移动速度。"},
	{"id": "warden_armor_shred", "title": "攻击附加破甲", "desc": "攻击会给目标附加短时易伤效果。"},
	{"id": "warden_crit", "title": "暴击率 +5%", "desc": "永久提高暴击率。"},
	{"id": "warden_transform_heal", "title": "复仇天神回血", "desc": "进入变身时回复固定值与已损失生命值。"},
	{"id": "warden_agi_growth", "title": "敏捷成长 +1", "desc": "每次升级额外获得 1 点敏捷成长。"},
	{"id": "warden_transform_duration", "title": "杀戮天神持续 +1 秒", "desc": "延长守望者变身状态。"},
	{"id": "warden_w_poison_damage", "title": "淬毒环刃被动伤害 +35%", "desc": "提高中毒持续伤害。"},
	{"id": "warden_w_poison_duration", "title": "淬毒环刃中毒时间 +3 秒", "desc": "延长中毒持续时间。"},
	{"id": "warden_q_range", "title": "刀阵旋风最远距离 +500", "desc": "提高 Q 的施法距离。"},
]

const RIFLEMAN_TALENT_POOL := [
	{"id": "rifleman_q_damage", "title": "穿透弹攻击力加成 +40%", "desc": "提高穿透弹伤害。"},
	{"id": "rifleman_q_armor_shred", "title": "穿透弹降低护甲", "desc": "Q 命中后给目标附加较长时间易伤。"},
	{"id": "rifleman_damage_growth", "title": "攻击成长 +3", "desc": "每次升级额外获得攻击成长。"},
	{"id": "rifleman_q_range", "title": "穿透弹伤害距离 +200", "desc": "提高 Q 的射程。"},
	{"id": "rifleman_attack_speed", "title": "攻击速度 +20%", "desc": "永久提高攻速。"},
	{"id": "rifleman_w_duration", "title": "脚底抹油持续时间 +1.5 秒", "desc": "延长 W 的持续时间。"},
	{"id": "rifleman_crit", "title": "暴击率 +5%", "desc": "永久提高暴击率。"},
	{"id": "rifleman_r_armor_shred", "title": "地毯式轰炸持续破甲", "desc": "R 伤害会给目标附加永久易伤。"},
	{"id": "rifleman_e_damage", "title": "精准射击攻击力加成 +20%", "desc": "提高精准射击触发的额外伤害。"},
	{"id": "rifleman_r_radius", "title": "地毯式轰炸范围 +65", "desc": "扩大 R 的轰炸半径。"},
	{"id": "rifleman_r_duration", "title": "地毯式轰炸持续时间 +0.5 秒", "desc": "增加一轮轰炸。"},
	{"id": "rifleman_r_damage", "title": "地毯式轰炸伤害 +15%", "desc": "提高 R 每轮轰炸伤害。"},
	{"id": "rifleman_r_cd", "title": "地毯式轰炸冷却 -15%", "desc": "乘法叠加降低 R 冷却。"},
	{"id": "rifleman_w_refund", "title": "精准射击额外返还脚底抹油冷却", "desc": "触发精准射击时额外减少 W 冷却。"},
	{"id": "rifleman_attack_range", "title": "攻击距离 +65", "desc": "永久提高攻击距离。"},
	{"id": "rifleman_precision_ignore_armor", "title": "精准射击穿甲强化", "desc": "提高精准射击对目标的额外伤害。"},
]

var _talent_pending_choice_count: int = 0
var _talent_last_seen_hero_level: int = 0
var _talent_session_initialized: bool = false
var _talent_popup_open: bool = false
var _talent_selected_counts: Dictionary = {}
var _talent_current_options: Array = []
var _talent_last_hero_selected: bool = false
var _talent_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func randomize_rng() -> void:
	_talent_rng.randomize()


func get_options_per_roll() -> int:
	return TALENT_OPTIONS_PER_ROLL


func is_popup_open() -> bool:
	return _talent_popup_open


func update(
	hero_ctrl: Node, is_observing_any: bool, popup_controller: Object, input_lock_changed: Callable
) -> void:
	if hero_ctrl == null:
		return
	if is_observing_any:
		return
	var hero_selected: bool = _variant_to_bool(hero_ctrl.get("hero_selection_confirmed"), false)
	if not hero_selected:
		if _talent_last_hero_selected:
			_talent_last_hero_selected = false
			_reset_talent_selection_runtime(hero_ctrl, popup_controller, input_lock_changed)
		return
	if not _talent_last_hero_selected:
		_talent_last_hero_selected = true
		_talent_session_initialized = false
		_talent_last_seen_hero_level = 0
		_talent_pending_choice_count = 0
	if not _talent_session_initialized:
		_talent_session_initialized = true
		_talent_last_seen_hero_level = maxi(_variant_to_int(hero_ctrl.get("hero_level"), 1), 1)
		_queue_talent_choices(TALENT_CHOICES_PER_LEVEL)
	else:
		var hero_level: int = maxi(_variant_to_int(hero_ctrl.get("hero_level"), 1), 1)
		if hero_level > _talent_last_seen_hero_level:
			var level_delta: int = hero_level - _talent_last_seen_hero_level
			_talent_last_seen_hero_level = hero_level
			_queue_talent_choices(level_delta * TALENT_CHOICES_PER_LEVEL)
	if not _talent_popup_open and _talent_pending_choice_count > 0:
		_show_next_talent_popup(hero_ctrl, popup_controller, input_lock_changed)


func on_option_pressed(
	option_index: int, hero_ctrl: Node, popup_controller: Object, input_lock_changed: Callable
) -> void:
	if option_index < 0 or option_index >= _talent_current_options.size():
		return
	var option_variant: Variant = _talent_current_options[option_index]
	if not (option_variant is Dictionary):
		return
	var option: Dictionary = option_variant
	var option_id: String = str(option.get("id", "")).strip_edges()
	if option_id.is_empty():
		return
	_talent_selected_counts[option_id] = int(_talent_selected_counts.get(option_id, 0)) + 1
	_apply_talent_bonuses_to_hero(hero_ctrl)
	_talent_pending_choice_count = maxi(_talent_pending_choice_count - 1, 0)
	_talent_current_options.clear()
	_talent_popup_open = false
	if _talent_pending_choice_count > 0:
		_show_next_talent_popup(hero_ctrl, popup_controller, input_lock_changed)
	else:
		_set_talent_popup_visible(false, popup_controller, input_lock_changed)


func build_bonus_bundle(hero_ctrl: Node) -> Dictionary:
	if hero_ctrl == null:
		return {}
	var hero_id: int = _variant_to_int(hero_ctrl.get("hero_id"), 0)
	if hero_id == HERO_ID_RANGED:
		return _build_rifleman_talent_bundle(_talent_selected_counts)
	return _build_warden_talent_bundle(_talent_selected_counts)


func _reset_talent_selection_runtime(
	hero_ctrl: Node, popup_controller: Object, input_lock_changed: Callable
) -> void:
	_talent_pending_choice_count = 0
	_talent_last_seen_hero_level = 0
	_talent_session_initialized = false
	_talent_popup_open = false
	_talent_selected_counts.clear()
	_talent_current_options.clear()
	_set_talent_popup_visible(false, popup_controller, input_lock_changed)
	_apply_talent_bonuses_to_hero(hero_ctrl)


func _queue_talent_choices(count: int) -> void:
	var safe_count: int = maxi(count, 0)
	if safe_count <= 0:
		return
	_talent_pending_choice_count += safe_count


func _set_talent_popup_visible(
	visible: bool, popup_controller: Object, input_lock_changed: Callable
) -> void:
	if popup_controller != null:
		popup_controller.set_visible(visible)
	if input_lock_changed.is_valid():
		input_lock_changed.call()


func _get_current_talent_pool(hero_ctrl: Node) -> Array:
	if hero_ctrl == null:
		return []
	var hero_id: int = _variant_to_int(hero_ctrl.get("hero_id"), 0)
	if hero_id == HERO_ID_RANGED:
		return RIFLEMAN_TALENT_POOL
	return WARDEN_TALENT_POOL


func _pick_random_talent_options(pool: Array, count: int) -> Array:
	var indices: Array[int] = []
	for i in range(pool.size()):
		indices.append(i)
	var picked: Array = []
	var safe_count: int = mini(maxi(count, 0), pool.size())
	for _idx in range(safe_count):
		if indices.is_empty():
			break
		var roll: int = _talent_rng.randi_range(0, indices.size() - 1)
		var picked_index: int = indices[roll]
		indices.remove_at(roll)
		picked.append(pool[picked_index])
	return picked


func _show_next_talent_popup(
	hero_ctrl: Node, popup_controller: Object, input_lock_changed: Callable
) -> void:
	if popup_controller == null:
		return
	var pool: Array = _get_current_talent_pool(hero_ctrl)
	if pool.size() < TALENT_OPTIONS_PER_ROLL:
		return
	_talent_current_options = _pick_random_talent_options(pool, TALENT_OPTIONS_PER_ROLL)
	if _talent_current_options.size() < TALENT_OPTIONS_PER_ROLL:
		return
	_talent_popup_open = true
	_set_talent_popup_visible(true, popup_controller, input_lock_changed)
	popup_controller.show_options(
		_talent_current_options, _talent_pending_choice_count, _talent_selected_counts, "天赋强化"
	)


func _build_warden_talent_bundle(counts: Dictionary) -> Dictionary:
	var bundle: Dictionary = {}
	var q_damage_count: int = int(counts.get("warden_q_damage", 0))
	if q_damage_count > 0:
		bundle["q_damage_multiplier"] = 1.0 + 0.2 * float(q_damage_count)
	var q_cd_count: int = int(counts.get("warden_q_cd", 0))
	if q_cd_count > 0:
		bundle["q_cooldown_multiplier"] = pow(0.8, float(q_cd_count))
	var q_echo_count: int = int(counts.get("warden_q_echo", 0))
	if q_echo_count > 0:
		bundle["q_origin_echo_ratio"] = 0.2 * float(q_echo_count)
	var w_hits_count: int = int(counts.get("warden_w_hits", 0))
	if w_hits_count > 0:
		bundle["warden_w_attack_count_bonus"] = w_hits_count
	var w_refund_count: int = int(counts.get("warden_w_cdr_on_hit", 0))
	if w_refund_count > 0:
		bundle["warden_w_cooldown_refund_on_attack_sec"] = float(w_refund_count)
	var e_mana_count: int = int(counts.get("warden_e_mana", 0))
	if e_mana_count > 0:
		bundle["warden_e_mana_gain_on_attack"] = 4 * e_mana_count
	var w_speed_count: int = int(counts.get("warden_w_speed", 0))
	if w_speed_count > 0:
		bundle["warden_w_attack_speed_multiplier_bonus"] = float(w_speed_count)
	var move_speed_count: int = int(counts.get("warden_move_speed", 0))
	if move_speed_count > 0:
		bundle["move_speed_bonus_flat"] = 30.0 * float(move_speed_count)
	var armor_shred_count: int = int(counts.get("warden_armor_shred", 0))
	if armor_shred_count > 0:
		bundle["warden_armor_shred_on_hit_percent"] = 4.0 * float(armor_shred_count)
		bundle["warden_armor_shred_duration_sec"] = 5.0
	var crit_count: int = int(counts.get("warden_crit", 0))
	if crit_count > 0:
		bundle["physical_crit_chance_bonus"] = 5.0 * float(crit_count)
	var transform_heal_count: int = int(counts.get("warden_transform_heal", 0))
	if transform_heal_count > 0:
		bundle["transform_enter_heal_flat"] = 100 * transform_heal_count
		bundle["transform_enter_missing_hp_heal_ratio"] = 0.05 * float(transform_heal_count)
	var agi_growth_count: int = int(counts.get("warden_agi_growth", 0))
	if agi_growth_count > 0:
		bundle["agility_growth_bonus"] = float(agi_growth_count)
	var transform_duration_count: int = int(counts.get("warden_transform_duration", 0))
	if transform_duration_count > 0:
		bundle["transform_duration_bonus_sec"] = float(transform_duration_count)
	var w_poison_damage_count: int = int(counts.get("warden_w_poison_damage", 0))
	if w_poison_damage_count > 0:
		bundle["w_poison_damage_multiplier"] = 1.0 + 0.35 * float(w_poison_damage_count)
	var w_poison_duration_count: int = int(counts.get("warden_w_poison_duration", 0))
	if w_poison_duration_count > 0:
		bundle["w_poison_duration_bonus_sec"] = 3.0 * float(w_poison_duration_count)
	var q_range_count: int = int(counts.get("warden_q_range", 0))
	if q_range_count > 0:
		bundle["q_distance_bonus_flat"] = 500.0 * float(q_range_count)
	return bundle


func _build_rifleman_talent_bundle(counts: Dictionary) -> Dictionary:
	var bundle: Dictionary = {}
	var q_damage_count: int = int(counts.get("rifleman_q_damage", 0))
	if q_damage_count > 0:
		bundle["q_damage_multiplier"] = 1.0 + 0.4 * float(q_damage_count)
	var q_armor_shred_count: int = int(counts.get("rifleman_q_armor_shred", 0))
	if q_armor_shred_count > 0:
		bundle["rifleman_q_armor_shred_percent"] = 8.0 * float(q_armor_shred_count)
		bundle["rifleman_q_armor_shred_duration_sec"] = 10.0
	var damage_growth_count: int = int(counts.get("rifleman_damage_growth", 0))
	if damage_growth_count > 0:
		bundle["damage_growth_per_level"] = 3 * damage_growth_count
	var q_range_count: int = int(counts.get("rifleman_q_range", 0))
	if q_range_count > 0:
		bundle["q_distance_bonus_flat"] = 200.0 * float(q_range_count)
	var attack_speed_count: int = int(counts.get("rifleman_attack_speed", 0))
	if attack_speed_count > 0:
		bundle["attack_speed_percent_bonus"] = 20.0 * float(attack_speed_count)
	var w_duration_count: int = int(counts.get("rifleman_w_duration", 0))
	if w_duration_count > 0:
		bundle["w_duration_bonus_sec"] = 1.5 * float(w_duration_count)
	var crit_count: int = int(counts.get("rifleman_crit", 0))
	if crit_count > 0:
		bundle["physical_crit_chance_bonus"] = 5.0 * float(crit_count)
	var r_armor_shred_count: int = int(counts.get("rifleman_r_armor_shred", 0))
	if r_armor_shred_count > 0:
		bundle["rifleman_r_permanent_armor_shred_percent"] = 1.2 * float(r_armor_shred_count)
	var e_damage_count: int = int(counts.get("rifleman_e_damage", 0))
	if e_damage_count > 0:
		bundle["rifleman_e_damage_multiplier"] = 1.0 + 0.2 * float(e_damage_count)
	var r_radius_count: int = int(counts.get("rifleman_r_radius", 0))
	if r_radius_count > 0:
		bundle["r_radius_bonus_flat"] = 65.0 * float(r_radius_count)
	var r_duration_count: int = int(counts.get("rifleman_r_duration", 0))
	if r_duration_count > 0:
		bundle["r_tick_count_bonus"] = r_duration_count
	var r_damage_count: int = int(counts.get("rifleman_r_damage", 0))
	if r_damage_count > 0:
		bundle["r_damage_multiplier"] = 1.0 + 0.15 * float(r_damage_count)
	var r_cd_count: int = int(counts.get("rifleman_r_cd", 0))
	if r_cd_count > 0:
		bundle["r_cooldown_multiplier"] = pow(0.85, float(r_cd_count))
	var w_refund_count: int = int(counts.get("rifleman_w_refund", 0))
	if w_refund_count > 0:
		bundle["rifleman_w_refund_ratio_bonus"] = 0.15 * float(w_refund_count)
	var attack_range_count: int = int(counts.get("rifleman_attack_range", 0))
	if attack_range_count > 0:
		bundle["attack_range_bonus_flat"] = 65.0 * float(attack_range_count)
	var precision_pierce_count: int = int(counts.get("rifleman_precision_ignore_armor", 0))
	if precision_pierce_count > 0:
		bundle["rifleman_precision_ignore_armor_damage_bonus"] = (
			0.24 * float(precision_pierce_count)
		)
	return bundle


func _apply_talent_bonuses_to_hero(hero_ctrl: Node) -> void:
	if hero_ctrl == null:
		return
	if hero_ctrl.has_method("apply_talent_bonuses"):
		hero_ctrl.call("apply_talent_bonuses", build_bonus_bundle(hero_ctrl))


func _variant_to_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return int(value)
		TYPE_BOOL:
			return 1 if bool(value) else 0
		TYPE_STRING:
			return int(value) if str(value).is_valid_int() else fallback
	return fallback


func _variant_to_bool(value: Variant, fallback: bool = false) -> bool:
	if value == null:
		return fallback
	match typeof(value):
		TYPE_BOOL:
			return bool(value)
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_equal_approx(float(value), 0.0)
		TYPE_STRING:
			var normalized: String = str(value).strip_edges().to_lower()
			if normalized == "true" or normalized == "1" or normalized == "yes":
				return true
			if normalized == "false" or normalized == "0" or normalized == "no":
				return false
	return fallback
