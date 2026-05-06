extends Node3D

@export var hero_controller_path: NodePath = NodePath("../HeroController")
@export var net_session_controller_path: NodePath = NodePath("../NetSessionController")
@export var scene_flow_controller_path: NodePath = NodePath("..")
@export var game_ui_path: NodePath = NodePath("../GameUI")
@export var summon_unit_scene: PackedScene = preload("res://tauren_unit.tscn")
@export var spirit_owl_visual_scene: PackedScene = preload("res://summons/spirit_owl_visual.tscn")
@export var moon_tower_visual_scene: PackedScene = preload("res://summons/moon_tower_visual.tscn")
@export var serpent_ward_visual_scene: PackedScene = preload("res://summons/serpent_ward_visual.tscn")
@export var challenge_griffin_visual_scene: PackedScene = preload("res://summons/challenge_griffin_visual.tscn")
@export var resentment_spirit_visual_scene: PackedScene = preload("res://modles/SpiritOfVengeance.before_trim.glb")

const SUMMON_KIND_SPIRIT_OWL: String = "spirit_owl"
const SUMMON_KIND_MOON_TOWER: String = "moon_tower"
const SUMMON_KIND_SERPENT_WARD: String = "serpent_ward"
const SUMMON_KIND_CHALLENGE_GRIFFIN: String = "challenge_griffin"
const SUMMON_KIND_RESENTMENT_SPIRIT: String = "resentment_spirit"

var _source_runtime: Dictionary = {}
var _summoned_units: Dictionary = {}
var _anchor_nodes: Dictionary = {}


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if not _is_authoritative():
		return
	_update_authoritative_summons()


func collect_network_states() -> Array:
	var states: Array = []
	for summon_id_variant in _summoned_units.keys():
		var summon_id: String = str(summon_id_variant)
		var unit: TaurenUnitAI = _summoned_units[summon_id] as TaurenUnitAI
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit.has_method("export_network_state"):
			continue
		var state_variant: Variant = unit.call("export_network_state")
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = (state_variant as Dictionary).duplicate(true)
		state["summon_kind"] = str(unit.get_meta("summon_kind", ""))
		states.append(state)
	return states


func apply_network_states(states: Array, is_partial: bool = false) -> void:
	var seen_ids: Dictionary = {}
	for state_variant in states:
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant as Dictionary
		var summon_id: String = str(state.get("id", "")).strip_edges()
		var summon_kind: String = str(state.get("summon_kind", "")).strip_edges()
		if summon_id.is_empty() or summon_kind.is_empty():
			continue
		seen_ids[summon_id] = true
		var unit: TaurenUnitAI = _summoned_units.get(summon_id, null) as TaurenUnitAI
		if unit == null or not is_instance_valid(unit):
			unit = _instantiate_client_summon(summon_id, summon_kind, state)
			if unit == null:
				continue
		if unit.has_method("apply_network_state"):
			unit.call("apply_network_state", state)
	if is_partial:
		return
	for summon_id_variant in _summoned_units.keys():
		var summon_id: String = str(summon_id_variant)
		if seen_ids.has(summon_id):
			continue
		var unit: TaurenUnitAI = _summoned_units[summon_id] as TaurenUnitAI
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
		_summoned_units.erase(summon_id)


func _is_authoritative() -> bool:
	var net_ctrl: Node = get_node_or_null(net_session_controller_path)
	if net_ctrl != null and net_ctrl.has_method("is_local_world_authority"):
		return bool(net_ctrl.call("is_local_world_authority"))
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()


func _update_authoritative_summons() -> void:
	var active_source_ids: Dictionary = {}
	for source_variant in _collect_authoritative_sources():
		if not (source_variant is Dictionary):
			continue
		var source: Dictionary = source_variant as Dictionary
		var source_id: String = str(source.get("source_id", "")).strip_edges()
		if source_id.is_empty():
			continue
		active_source_ids[source_id] = true
		var runtime: Dictionary = _get_or_create_source_runtime(source_id)
		if bool(source.get("is_dead", false)):
			_update_dead_source_revenge_spirit(source, runtime)
			continue
		var battle_active: bool = bool(source.get("battle_active", false))
		if not battle_active:
			if _source_runtime.has(source_id) and (bool((_source_runtime[source_id] as Dictionary).get("battle_active", false)) or bool((_source_runtime[source_id] as Dictionary).get("revenge_spawned", false))):
				_deactivate_source(source_id)
			continue
		var anchor_node: Node3D = _get_or_create_anchor_node(source_id)
		var source_pos_variant: Variant = source.get("position", Vector3.ZERO)
		if source_pos_variant is Vector3:
			anchor_node.global_position = source_pos_variant
		var was_active: bool = bool(runtime.get("battle_active", false))
		runtime["battle_active"] = true
		if not was_active:
			runtime["battle_index"] = int(runtime.get("battle_index", 0)) + 1
			_spawn_battle_prep_summons_for_source(source, runtime, anchor_node)
		_update_source_units(source, runtime, anchor_node)

	for source_id_variant in _source_runtime.keys():
		var source_id: String = str(source_id_variant)
		if active_source_ids.has(source_id):
			continue
		_deactivate_source(source_id)


func _update_dead_source_revenge_spirit(source: Dictionary, runtime: Dictionary) -> void:
	var source_id: String = str(source.get("source_id", "")).strip_edges()
	if source_id.is_empty():
		return
	_prune_runtime_units(runtime, SUMMON_KIND_RESENTMENT_SPIRIT)
	var coin_state: Dictionary = {}
	var coin_variant: Variant = source.get("coin", {})
	if coin_variant is Dictionary:
		coin_state = coin_variant as Dictionary
	var revenge_count: int = maxi(int(coin_state.get("revenge_spirit_count", 0)), 0)
	var revive_available: int = maxi(int(coin_state.get("revive_available", 0)), 0)
	if revenge_count <= 0 or revive_available > 0:
		_deactivate_source(source_id)
		return
	var anchor_node: Node3D = _get_or_create_anchor_node(source_id)
	var source_pos_variant: Variant = source.get("position", Vector3.ZERO)
	if source_pos_variant is Vector3:
		anchor_node.global_position = source_pos_variant
	var summon_id: String = "%s_%s" % [source_id, SUMMON_KIND_RESENTMENT_SPIRIT]
	runtime["battle_active"] = false
	runtime["revenge_spawned"] = true
	runtime["unit_ids"] = [summon_id]
	_spawn_or_configure_authoritative_unit(summon_id, SUMMON_KIND_RESENTMENT_SPIRIT, source, anchor_node, anchor_node.global_position, 0)


func _prune_runtime_units(runtime: Dictionary, keep_kind: String = "") -> void:
	var kept_unit_ids: Array = []
	var unit_ids_variant: Variant = runtime.get("unit_ids", [])
	if unit_ids_variant is Array:
		for summon_id_variant in unit_ids_variant:
			var summon_id: String = str(summon_id_variant)
			var unit: TaurenUnitAI = _summoned_units.get(summon_id, null) as TaurenUnitAI
			if unit == null or not is_instance_valid(unit):
				_summoned_units.erase(summon_id)
				continue
			var summon_kind: String = str(unit.get_meta("summon_kind", "")).strip_edges()
			if keep_kind != "" and summon_kind == keep_kind:
				kept_unit_ids.append(summon_id)
				continue
			unit.queue_free()
			_summoned_units.erase(summon_id)
	runtime["unit_ids"] = kept_unit_ids
	runtime["revenge_spawned"] = keep_kind != "" and not kept_unit_ids.is_empty()


func _collect_authoritative_sources() -> Array:
	var sources: Array = []
	var local_source: Dictionary = _build_local_source()
	if not local_source.is_empty():
		sources.append(local_source)
	var net_ctrl: Node = get_node_or_null(net_session_controller_path)
	if net_ctrl == null:
		return sources
	if not net_ctrl.has_method("get_synced_peer_ids"):
		return sources
	var local_peer_id: int = 0
	if net_ctrl.has_method("get_ui_self_peer_id"):
		local_peer_id = int(net_ctrl.call("get_ui_self_peer_id"))
	var peer_ids_variant: Variant = net_ctrl.call("get_synced_peer_ids")
	if not (peer_ids_variant is Array):
		return sources
	for peer_id_variant in peer_ids_variant:
		var peer_id: int = int(peer_id_variant)
		if peer_id <= 0 or peer_id == local_peer_id:
			continue
		if not net_ctrl.has_method("get_ui_peer_hero_state"):
			continue
		var hero_state_variant: Variant = net_ctrl.call("get_ui_peer_hero_state", peer_id)
		if not (hero_state_variant is Dictionary):
			continue
		var hero_state: Dictionary = hero_state_variant as Dictionary
		var necro_variant: Variant = hero_state.get("necromancy", {})
		if not (necro_variant is Dictionary):
			necro_variant = {}
		var necro_state: Dictionary = necro_variant as Dictionary
		var battle_prep_variant: Variant = hero_state.get("battle_prep", {})
		var battle_prep_state: Dictionary = {}
		if battle_prep_variant is Dictionary:
			battle_prep_state = battle_prep_variant as Dictionary
		var coin_state: Dictionary = {}
		var coin_variant: Variant = hero_state.get("coin", {})
		if coin_variant is Dictionary:
			coin_state = coin_variant as Dictionary
		if _get_total_battle_prep_count(necro_state, battle_prep_state) <= 0 and maxi(int(coin_state.get("revenge_spirit_count", 0)), 0) <= 0:
			continue
		var pos_variant: Variant = hero_state.get("pos", null)
		if not (pos_variant is Vector3):
			continue
		var source: Dictionary = {
			"source_id": "peer_%d" % peer_id,
			"peer_id": peer_id,
			"position": pos_variant,
			"visible": bool(hero_state.get("visible", true)),
			"is_dead": bool(hero_state.get("is_dead", false)),
			"damage": int(hero_state.get("damage", 0)),
			"intelligence": int(hero_state.get("intelligence", 0)),
			"attack_range": float(hero_state.get("attack_range", 0.0)),
			"attack_speed": float(hero_state.get("attack_speed", 1.0)),
			"physical_crit_chance": float(hero_state.get("physical_crit_chance", 0.0)),
			"physical_crit_multiplier": float(hero_state.get("physical_crit_multiplier", 2.0)),
			"necromancy": necro_state.duplicate(true),
			"battle_prep": battle_prep_state.duplicate(true),
			"coin": coin_state.duplicate(true),
		}
		source["battle_active"] = _is_source_in_battle_phase(source)
		sources.append(source)
	return sources


func _build_local_source() -> Dictionary:
	var hero_ctrl: Node = get_node_or_null(hero_controller_path)
	if hero_ctrl == null:
		return {}
	var hero_variant: Variant = hero_ctrl.get("_hero")
	if not (hero_variant is Node3D):
		return {}
	var hero: Node3D = hero_variant as Node3D
	if hero == null or not is_instance_valid(hero):
		return {}
	var necro_state: Dictionary = {}
	if hero_ctrl.has_method("get_necromancy_sync_state"):
		var necro_variant: Variant = hero_ctrl.call("get_necromancy_sync_state")
		if necro_variant is Dictionary:
			necro_state = (necro_variant as Dictionary).duplicate(true)
	var battle_prep_state: Dictionary = {}
	if hero_ctrl.has_method("get_battle_prep_sync_state"):
		var battle_prep_variant: Variant = hero_ctrl.call("get_battle_prep_sync_state")
		if battle_prep_variant is Dictionary:
			battle_prep_state = (battle_prep_variant as Dictionary).duplicate(true)
	var coin_state: Dictionary = {}
	if hero_ctrl.has_method("get_coin_sync_state"):
		var coin_variant: Variant = hero_ctrl.call("get_coin_sync_state")
		if coin_variant is Dictionary:
			coin_state = (coin_variant as Dictionary).duplicate(true)
	if _get_total_battle_prep_count(necro_state, battle_prep_state) <= 0 and maxi(int(coin_state.get("revenge_spirit_count", 0)), 0) <= 0:
		return {}
	var local_peer_id: int = 1
	if multiplayer.multiplayer_peer != null:
		local_peer_id = multiplayer.get_unique_id()
	var is_dead: bool = false
	if hero_ctrl.has_method("is_dead"):
		is_dead = bool(hero_ctrl.call("is_dead"))
	var source: Dictionary = {
		"source_id": "peer_%d" % local_peer_id,
		"peer_id": local_peer_id,
		"position": hero.global_position,
		"visible": hero.visible,
		"is_dead": is_dead,
		"damage": int(hero_ctrl.get("damage_per_hit")),
		"intelligence": int(hero_ctrl.get("intelligence")),
		"attack_range": float(hero_ctrl.get("attack_range")),
		"attack_speed": float(hero_ctrl.get("attack_speed")),
		"physical_crit_chance": float(hero_ctrl.get("physical_crit_chance")),
		"physical_crit_multiplier": float(hero_ctrl.get("physical_crit_multiplier")),
		"necromancy": necro_state,
		"battle_prep": battle_prep_state,
		"coin": coin_state,
	}
	source["battle_active"] = _is_source_in_battle_phase(source)
	return source


func _is_source_in_battle_phase(source: Dictionary) -> bool:
	if bool(source.get("is_dead", false)):
		return false
	if not bool(source.get("visible", true)):
		return false
	var pos_variant: Variant = source.get("position", null)
	if not (pos_variant is Vector3):
		return false
	var scene_flow: Node = get_node_or_null(scene_flow_controller_path)
	if scene_flow == null:
		return true
	if not scene_flow.has_method("get_start_area_center") or not scene_flow.has_method("get_start_area_full_recovery_radius"):
		return true
	var center_variant: Variant = scene_flow.call("get_start_area_center")
	var radius_variant: Variant = scene_flow.call("get_start_area_full_recovery_radius")
	if not (center_variant is Vector3):
		return true
	var center: Vector3 = center_variant
	var radius: float = maxf(float(radius_variant), 0.0)
	if radius <= 0.0:
		return true
	return _distance_xz(pos_variant as Vector3, center) > radius


func _get_total_battle_prep_count(necro_state: Dictionary, battle_prep_state: Dictionary) -> int:
	return maxi(int(necro_state.get("battle_prep_owl_count", 0)), 0) + maxi(int(necro_state.get("battle_prep_tower_count", 0)), 0) + maxi(int(battle_prep_state.get("snake_ward_count", 0)), 0) + maxi(int(battle_prep_state.get("challenge_griffin_count", 0)), 0)


func _get_or_create_source_runtime(source_id: String) -> Dictionary:
	if _source_runtime.has(source_id):
		return _source_runtime[source_id] as Dictionary
	var runtime: Dictionary = {
		"battle_active": false,
		"battle_index": 0,
		"unit_ids": [],
	}
	_source_runtime[source_id] = runtime
	return runtime


func _get_or_create_anchor_node(source_id: String) -> Node3D:
	if _anchor_nodes.has(source_id):
		var existing: Node3D = _anchor_nodes[source_id] as Node3D
		if existing != null and is_instance_valid(existing):
			return existing
	var anchor := Node3D.new()
	anchor.name = "%s_Anchor" % source_id
	add_child(anchor)
	_anchor_nodes[source_id] = anchor
	return anchor


func _spawn_battle_prep_summons_for_source(source: Dictionary, runtime: Dictionary, anchor_node: Node3D) -> void:
	var unit_ids: Array = []
	var necro_state: Dictionary = {}
	var necro_variant: Variant = source.get("necromancy", {})
	if necro_variant is Dictionary:
		necro_state = necro_variant as Dictionary
	var battle_prep_state: Dictionary = {}
	var battle_prep_variant: Variant = source.get("battle_prep", {})
	if battle_prep_variant is Dictionary:
		battle_prep_state = battle_prep_variant as Dictionary
	var source_id: String = str(source.get("source_id", ""))
	var anchor_pos: Vector3 = anchor_node.global_position
	var trigger_multiplier: int = maxi(int(battle_prep_state.get("trigger_multiplier", 1)), 1)
	var owl_count: int = maxi(int(necro_state.get("battle_prep_owl_count", 0)), 0) * trigger_multiplier
	for idx in range(owl_count):
		var summon_id: String = "%s_%s_%d" % [source_id, SUMMON_KIND_SPIRIT_OWL, idx]
		_spawn_or_configure_authoritative_unit(summon_id, SUMMON_KIND_SPIRIT_OWL, source, anchor_node, anchor_pos + Vector3(0.0, 120.0, 0.0), idx)
		unit_ids.append(summon_id)
	var tower_count: int = maxi(int(necro_state.get("battle_prep_tower_count", 0)), 0) * trigger_multiplier
	var battle_index: int = int(runtime.get("battle_index", 1))
	for idx in range(tower_count):
		var summon_id: String = "%s_%s_%d" % [source_id, SUMMON_KIND_MOON_TOWER, idx]
		var tower_pos: Vector3 = _build_moon_tower_spawn_position(source_id, battle_index, idx, anchor_pos)
		_spawn_or_configure_authoritative_unit(summon_id, SUMMON_KIND_MOON_TOWER, source, anchor_node, tower_pos, idx)
		unit_ids.append(summon_id)
	var snake_ward_count: int = maxi(int(battle_prep_state.get("snake_ward_count", 0)), 0)
	for idx in range(snake_ward_count):
		var summon_id: String = "%s_%s_%d" % [source_id, SUMMON_KIND_SERPENT_WARD, idx]
		var ward_pos: Vector3 = _build_ring_spawn_position(source_id, battle_index, idx, anchor_pos, 150.0, 260.0)
		_spawn_or_configure_authoritative_unit(summon_id, SUMMON_KIND_SERPENT_WARD, source, anchor_node, ward_pos, idx)
		unit_ids.append(summon_id)
	var challenge_griffin_count: int = maxi(int(battle_prep_state.get("challenge_griffin_count", 0)), 0)
	for idx in range(challenge_griffin_count):
		var summon_id: String = "%s_%s_%d" % [source_id, SUMMON_KIND_CHALLENGE_GRIFFIN, idx]
		var griffin_pos: Vector3 = _build_ring_spawn_position(source_id, battle_index + 17, idx, anchor_pos, 240.0, 360.0)
		_spawn_or_configure_authoritative_unit(summon_id, SUMMON_KIND_CHALLENGE_GRIFFIN, source, anchor_node, griffin_pos, idx)
		unit_ids.append(summon_id)
	runtime["unit_ids"] = unit_ids


func _update_source_units(source: Dictionary, runtime: Dictionary, anchor_node: Node3D) -> void:
	var source_pos_variant: Variant = source.get("position", null)
	if source_pos_variant is Vector3:
		anchor_node.global_position = source_pos_variant
	var unit_ids_variant: Variant = runtime.get("unit_ids", [])
	if not (unit_ids_variant is Array):
		return
	for summon_id_variant in unit_ids_variant:
		var summon_id: String = str(summon_id_variant)
		var unit: TaurenUnitAI = _summoned_units.get(summon_id, null) as TaurenUnitAI
		if unit == null or not is_instance_valid(unit):
			continue
		var summon_kind: String = str(unit.get_meta("summon_kind", ""))
		_apply_runtime_config_to_unit(unit, summon_kind, source, anchor_node, summon_id)
		_process_special_summon_runtime(unit, summon_kind, source)


func _deactivate_source(source_id: String) -> void:
	if not _source_runtime.has(source_id):
		return
	var runtime: Dictionary = _source_runtime[source_id] as Dictionary
	var unit_ids_variant: Variant = runtime.get("unit_ids", [])
	if unit_ids_variant is Array:
		for summon_id_variant in unit_ids_variant:
			var summon_id: String = str(summon_id_variant)
			var unit: TaurenUnitAI = _summoned_units.get(summon_id, null) as TaurenUnitAI
			if unit != null and is_instance_valid(unit):
				unit.queue_free()
			_summoned_units.erase(summon_id)
	runtime["unit_ids"] = []
	runtime["battle_active"] = false
	runtime["revenge_spawned"] = false
	if _anchor_nodes.has(source_id):
		var anchor: Node3D = _anchor_nodes[source_id] as Node3D
		if anchor != null and is_instance_valid(anchor):
			anchor.queue_free()
		_anchor_nodes.erase(source_id)


func _process_special_summon_runtime(unit: TaurenUnitAI, summon_kind: String, source: Dictionary) -> void:
	if summon_kind != SUMMON_KIND_CHALLENGE_GRIFFIN:
		return
	if unit == null or not is_instance_valid(unit):
		return
	if not unit.has_method("is_dead") or not bool(unit.call("is_dead")):
		return
	if bool(unit.get_meta("reward_granted", false)):
		return
	unit.set_meta("reward_granted", true)
	var owner_peer_id: int = int(source.get("peer_id", 0))
	var owner_gold: int = int(unit.get_meta("reward_owner_gold", 140))
	var ally_gold: int = int(unit.get_meta("reward_ally_gold", 35))
	for peer_id in _collect_reward_peer_ids(owner_peer_id):
		var reward_gold: int = owner_gold if peer_id == owner_peer_id else ally_gold
		_grant_gold_reward_to_peer(peer_id, reward_gold)
	unit.queue_free()
	_summoned_units.erase(str(unit.name))


func _collect_reward_peer_ids(owner_peer_id: int) -> Array[int]:
	var ids: Array[int] = []
	var net_ctrl: Node = get_node_or_null(net_session_controller_path)
	if net_ctrl != null:
		if net_ctrl.has_method("get_ui_self_peer_id"):
			var self_peer_id: int = int(net_ctrl.call("get_ui_self_peer_id"))
			if self_peer_id > 0 and not ids.has(self_peer_id):
				ids.append(self_peer_id)
		if net_ctrl.has_method("get_synced_peer_ids"):
			var peer_ids_variant: Variant = net_ctrl.call("get_synced_peer_ids")
			if peer_ids_variant is Array:
				for peer_id_variant in peer_ids_variant:
					var peer_id: int = int(peer_id_variant)
					if peer_id > 0 and not ids.has(peer_id):
						ids.append(peer_id)
	if owner_peer_id > 0 and not ids.has(owner_peer_id):
		ids.append(owner_peer_id)
	if ids.is_empty():
		ids.append(maxi(owner_peer_id, 1))
	return ids


func _grant_gold_reward_to_peer(peer_id: int, amount: int) -> void:
	if peer_id <= 0 or amount <= 0:
		return
	var ui: Node = get_node_or_null(game_ui_path)
	if ui == null or not ui.has_method("authority_grant_gold_reward"):
		return
	var updated_state_variant: Variant = ui.call("authority_grant_gold_reward", peer_id, amount)
	if not (updated_state_variant is Dictionary):
		return
	var updated_state: Dictionary = updated_state_variant as Dictionary
	if updated_state.is_empty():
		return
	var net_ctrl: Node = get_node_or_null(net_session_controller_path)
	if net_ctrl != null and net_ctrl.has_method("host_override_peer_equipment_state"):
		net_ctrl.call("host_override_peer_equipment_state", peer_id, updated_state)


func _instantiate_client_summon(summon_id: String, summon_kind: String, state: Dictionary) -> TaurenUnitAI:
	if summon_unit_scene == null:
		return null
	var unit := summon_unit_scene.instantiate() as TaurenUnitAI
	if unit == null:
		return null
	var pos: Vector3 = Vector3.ZERO
	var pos_variant: Variant = state.get("pos", null)
	if pos_variant is Vector3:
		pos = pos_variant
	_prepare_unit_common_flags(unit)
	unit.name = summon_id
	unit.set_meta("summon_kind", summon_kind)
	unit.target_group_name = &"hero" if summon_kind == SUMMON_KIND_CHALLENGE_GRIFFIN else &"enemy"
	unit.collision_group_name = &"enemy" if summon_kind == SUMMON_KIND_CHALLENGE_GRIFFIN else StringName("")
	unit.allow_target_chase = summon_kind == SUMMON_KIND_CHALLENGE_GRIFFIN
	unit.follow_anchor_enabled = false
	unit.max_hp = maxi(int(state.get("max_hp", 1)), 1)
	unit.damage_per_hit = maxi(int(state.get("damage", 1)), 1)
	unit.attack_range = maxf(float(state.get("attack_range", 600.0)), 60.0)
	unit.engage_range = maxf(unit.attack_range + 80.0, unit.attack_range)
	unit.attack_speed = maxf(float(state.get("attack_speed", 1.0)), 0.05)
	unit.magic_immunity_rate = clampf(float(state.get("magic_immunity_rate", 0.0)), 0.0, 100.0)
	unit.invulnerable = summon_kind == SUMMON_KIND_RESENTMENT_SPIRIT
	add_child(unit)
	unit.setup_unit(_get_visual_scene_for_kind(summon_kind), pos, _get_visual_scale_for_kind(summon_kind))
	if unit.has_method("set_network_authority"):
		unit.call("set_network_authority", false)
	_summoned_units[summon_id] = unit
	return unit


func _spawn_or_configure_authoritative_unit(summon_id: String, summon_kind: String, source: Dictionary, anchor_node: Node3D, spawn_pos: Vector3, slot_index: int) -> void:
	var unit: TaurenUnitAI = _summoned_units.get(summon_id, null) as TaurenUnitAI
	if unit == null or not is_instance_valid(unit):
		if summon_unit_scene == null:
			return
		unit = summon_unit_scene.instantiate() as TaurenUnitAI
		if unit == null:
			return
		_prepare_unit_common_flags(unit)
		unit.name = summon_id
		unit.set_meta("summon_kind", summon_kind)
		add_child(unit)
		_apply_runtime_config_to_unit(unit, summon_kind, source, anchor_node, summon_id)
		unit.setup_unit(_get_visual_scene_for_kind(summon_kind), spawn_pos, _get_visual_scale_for_kind(summon_kind))
		if unit.has_method("set_network_authority"):
			unit.call("set_network_authority", true)
		_summoned_units[summon_id] = unit
		return
	_apply_runtime_config_to_unit(unit, summon_kind, source, anchor_node, summon_id)


func _prepare_unit_common_flags(unit: TaurenUnitAI) -> void:
	unit.target_group_name = &"enemy"
	unit.collision_group_name = StringName("")
	unit.movement_collision_layer = 0
	unit.movement_collision_mask = 0
	unit.click_collision_layer = 0
	unit.click_collision_mask = 0
	unit.collision_radius = 30.0
	unit.collision_height = 90.0


func _apply_runtime_config_to_unit(unit: TaurenUnitAI, summon_kind: String, source: Dictionary, anchor_node: Node3D, summon_id: String) -> void:
	var necro_state: Dictionary = {}
	var necro_variant: Variant = source.get("necromancy", {})
	if necro_variant is Dictionary:
		necro_state = necro_variant as Dictionary
	var battle_prep_state: Dictionary = {}
	var battle_prep_variant: Variant = source.get("battle_prep", {})
	if battle_prep_variant is Dictionary:
		battle_prep_state = battle_prep_variant as Dictionary
	var summon_power_multiplier: float = 1.0 + maxf(float(necro_state.get("summon_power_percent", 0.0)), 0.0) * 0.01
	var summon_attack_multiplier: float = 1.0 + maxf(float(necro_state.get("summon_attack_bonus_percent", 0.0)), 0.0) * 0.01
	var summon_range_multiplier: float = 1.0 + maxf(float(necro_state.get("summon_range_bonus_percent", 0.0)), 0.0) * 0.01
	var hero_damage: float = maxf(float(source.get("damage", 0)), 0.0)
	var hero_intelligence: float = maxf(float(source.get("intelligence", 0)), 0.0)
	var hero_attack_range: float = maxf(float(source.get("attack_range", 0.0)), 60.0)
	var hero_attack_speed: float = maxf(float(source.get("attack_speed", 1.0)), 0.05)
	var hero_crit_chance: float = clampf(float(source.get("physical_crit_chance", 0.0)), 0.0, 100.0)
	var hero_crit_multiplier: float = maxf(float(source.get("physical_crit_multiplier", 2.0)), 1.0)
	var coin_state: Dictionary = {}
	var coin_variant: Variant = source.get("coin", {})
	if coin_variant is Dictionary:
		coin_state = coin_variant as Dictionary
	unit.set_meta("summon_kind", summon_kind)
	unit.set_meta("source_peer_id", int(source.get("peer_id", 0)))
	unit.target_group_name = &"enemy"
	unit.collision_group_name = StringName("")
	unit.magic_immunity_rate = clampf(float(necro_state.get("summon_magic_resist_percent", 0.0)), 0.0, 100.0)
	unit.allow_target_chase = false
	unit.critical_chance_percent = 0.0
	unit.critical_multiplier = 2.0
	unit.invulnerable = false
	unit.follow_anchor_enabled = summon_kind == SUMMON_KIND_SPIRIT_OWL
	if summon_kind == SUMMON_KIND_SPIRIT_OWL:
		unit.set_follow_anchor(anchor_node)
		unit.follow_anchor_offset = Vector3(0.0, 120.0, 0.0)
		unit.follow_anchor_orbit_radius = 90.0
		unit.follow_anchor_orbit_height = 20.0
		unit.follow_anchor_angular_speed_deg = 140.0 + float(_extract_slot_index_from_id(summon_id)) * 24.0
		unit.follow_anchor_speed = 960.0
		unit.attack_range = maxf(720.0 * summon_range_multiplier, 120.0)
		unit.engage_range = unit.attack_range + 120.0
		unit.attack_speed = 1.35
		unit.damage_per_hit = maxi(int(round(maxf(hero_damage * 0.9, hero_intelligence * 2.0) * summon_power_multiplier * summon_attack_multiplier)), 1)
		_set_unit_hp_scaled(unit, maxi(int(round((220.0 + hero_intelligence * 12.0) * summon_power_multiplier)), 1))
	elif summon_kind == SUMMON_KIND_MOON_TOWER:
		unit.clear_follow_anchor()
		unit.follow_anchor_enabled = false
		unit.follow_anchor_offset = Vector3.ZERO
		unit.follow_anchor_orbit_radius = 0.0
		unit.follow_anchor_orbit_height = 0.0
		unit.follow_anchor_angular_speed_deg = 0.0
		unit.follow_anchor_speed = 0.0
		unit.attack_range = maxf(980.0 * summon_range_multiplier, 180.0)
		unit.engage_range = unit.attack_range + 40.0
		unit.attack_speed = 0.85
		unit.damage_per_hit = maxi(int(round((hero_intelligence * 2.4 + hero_damage * 0.6) * summon_power_multiplier * summon_attack_multiplier)), 1)
		_set_unit_hp_scaled(unit, maxi(int(round((320.0 + hero_intelligence * 18.0) * summon_power_multiplier)), 1))
	elif summon_kind == SUMMON_KIND_SERPENT_WARD:
		unit.clear_follow_anchor()
		unit.follow_anchor_enabled = false
		unit.follow_anchor_offset = Vector3.ZERO
		unit.follow_anchor_orbit_radius = 0.0
		unit.follow_anchor_orbit_height = 0.0
		unit.follow_anchor_angular_speed_deg = 0.0
		unit.follow_anchor_speed = 0.0
		unit.target_group_name = &"enemy"
		unit.collision_group_name = StringName("")
		unit.allow_target_chase = false
		unit.magic_immunity_rate = 0.0
		unit.attack_range = maxf(760.0, 180.0)
		unit.engage_range = unit.attack_range + 40.0
		unit.attack_speed = 1.15
		unit.damage_per_hit = maxi(int(round((hero_damage * 0.7 + hero_intelligence * 1.4) * summon_power_multiplier)), 1)
		_set_unit_hp_scaled(unit, maxi(int(round(180.0 + hero_intelligence * 8.0)), 1))
	elif summon_kind == SUMMON_KIND_CHALLENGE_GRIFFIN:
		unit.clear_follow_anchor()
		unit.follow_anchor_enabled = false
		unit.follow_anchor_offset = Vector3.ZERO
		unit.follow_anchor_orbit_radius = 0.0
		unit.follow_anchor_orbit_height = 0.0
		unit.follow_anchor_angular_speed_deg = 0.0
		unit.follow_anchor_speed = 0.0
		unit.target_group_name = &"hero"
		unit.collision_group_name = &"enemy"
		unit.allow_target_chase = true
		unit.magic_immunity_rate = 0.0
		unit.attack_range = 320.0
		unit.engage_range = 880.0
		unit.attack_speed = 1.05
		unit.damage_per_hit = maxi(int(round(hero_damage * 0.6 + hero_intelligence * 0.5)), 1)
		_set_unit_hp_scaled(unit, maxi(int(round(320.0 + hero_damage * 3.5)), 1))
		unit.set_meta("reward_owner_gold", 140)
		unit.set_meta("reward_ally_gold", 35)
	elif summon_kind == SUMMON_KIND_RESENTMENT_SPIRIT:
		unit.clear_follow_anchor()
		unit.follow_anchor_enabled = false
		unit.follow_anchor_offset = Vector3.ZERO
		unit.follow_anchor_orbit_radius = 0.0
		unit.follow_anchor_orbit_height = 0.0
		unit.follow_anchor_angular_speed_deg = 0.0
		unit.follow_anchor_speed = 0.0
		unit.target_group_name = &"enemy"
		unit.collision_group_name = StringName("")
		unit.allow_target_chase = true
		unit.magic_immunity_rate = 100.0
		unit.invulnerable = true
		unit.attack_range = hero_attack_range
		unit.engage_range = hero_attack_range + 320.0
		unit.attack_speed = hero_attack_speed
		unit.critical_chance_percent = hero_crit_chance
		unit.critical_multiplier = hero_crit_multiplier
		unit.damage_per_hit = maxi(int(round(hero_damage * maxf(float(coin_state.get("revenge_spirit_attack_percent", 40.0)) * 0.01, 0.0))), 1)
		_set_unit_hp_scaled(unit, 999999)
	else:
		unit.clear_follow_anchor()
		unit.follow_anchor_enabled = false
		unit.follow_anchor_offset = Vector3.ZERO
		unit.follow_anchor_orbit_radius = 0.0
		unit.follow_anchor_orbit_height = 0.0
		unit.follow_anchor_angular_speed_deg = 0.0
		unit.follow_anchor_speed = 0.0
		unit.attack_range = maxf(700.0, 180.0)
		unit.engage_range = unit.attack_range + 40.0
		unit.attack_speed = 1.0
		unit.damage_per_hit = maxi(int(round(hero_damage)), 1)
		_set_unit_hp_scaled(unit, 200)


func _set_unit_hp_scaled(unit: TaurenUnitAI, new_max_hp: int) -> void:
	var safe_max_hp: int = maxi(new_max_hp, 1)
	var current_hp: int = maxi(int(unit.get("_current_hp")), 0)
	var prev_max_hp: int = maxi(int(unit.max_hp), 1)
	var hp_ratio: float = float(current_hp) / float(prev_max_hp)
	unit.max_hp = safe_max_hp
	var next_hp: int = clampi(int(round(float(safe_max_hp) * hp_ratio)), 0, safe_max_hp)
	if current_hp <= 0:
		next_hp = safe_max_hp
	unit.set("_current_hp", next_hp)
	if unit.has_method("_update_hp_bar"):
		unit.call("_update_hp_bar")


func _extract_slot_index_from_id(summon_id: String) -> int:
	var parts: PackedStringArray = summon_id.split("_")
	if parts.is_empty():
		return 0
	var tail: String = parts[parts.size() - 1]
	if tail.is_valid_int():
		return tail.to_int()
	return 0


func _build_moon_tower_spawn_position(source_id: String, battle_index: int, slot_index: int, center: Vector3) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s:%d:%d" % [source_id, battle_index, slot_index]))
	var angle: float = rng.randf_range(0.0, TAU)
	var radius: float = rng.randf_range(180.0, 340.0) + float(slot_index) * 40.0
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	return center + offset


func _build_ring_spawn_position(source_id: String, battle_index: int, slot_index: int, center: Vector3, min_radius: float, max_radius: float) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash("%s:ring:%d:%d" % [source_id, battle_index, slot_index]))
	var angle: float = rng.randf_range(0.0, TAU)
	var radius: float = rng.randf_range(min_radius, max_radius)
	return center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _get_visual_scene_for_kind(summon_kind: String) -> PackedScene:
	match summon_kind:
		SUMMON_KIND_SPIRIT_OWL:
			return spirit_owl_visual_scene
		SUMMON_KIND_MOON_TOWER:
			return moon_tower_visual_scene
		SUMMON_KIND_SERPENT_WARD:
			return serpent_ward_visual_scene
		SUMMON_KIND_CHALLENGE_GRIFFIN:
			return challenge_griffin_visual_scene
		SUMMON_KIND_RESENTMENT_SPIRIT:
			return resentment_spirit_visual_scene
		_:
			return spirit_owl_visual_scene


func _get_visual_scale_for_kind(summon_kind: String) -> Vector3:
	match summon_kind:
		SUMMON_KIND_SPIRIT_OWL:
			return Vector3.ONE
		SUMMON_KIND_MOON_TOWER:
			return Vector3.ONE
		SUMMON_KIND_SERPENT_WARD:
			return Vector3.ONE
		SUMMON_KIND_CHALLENGE_GRIFFIN:
			return Vector3.ONE
		_:
			return Vector3.ONE


func _distance_xz(a: Vector3, b: Vector3) -> float:
	var delta: Vector3 = a - b
	delta.y = 0.0
	return delta.length()
