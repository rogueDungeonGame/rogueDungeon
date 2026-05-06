extends Node3D

@export var unit_count: int = 20
@export var tauren_scene_path: String = "res://modles/Tauren.glb"
@export var fallback_tauren_scene: PackedScene = preload("res://modles/HeroTaurenChieftain.glb")
@export var unit_scale: Vector3 = Vector3(1.6, 1.6, 1.6)
@export var spawn_radius: float = 900.0
@export var spawn_radius_jitter: float = 700.0
@export var spawn_height: float = 0.0
@export var min_spawn_distance: float = 260.0
@export var spawn_try_count: int = 40
@export var phase_wave_spawn_radius: float = 520.0
@export var phase_wave_spawn_radius_jitter: float = 260.0
@export var phase_wave_min_spawn_distance: float = 180.0
@export var randomize_seed_on_ready: bool = true

const TAUREN_UNIT_SCENE: PackedScene = preload("res://tauren_unit.tscn")

var _loaded_model_scene: PackedScene = null
var _spawn_serial: int = 0
var _network_authority_enabled: bool = true
var _floor_profile: Dictionary = {}
var _base_unit_stats: Dictionary = {}
var _spawn_rect_enabled: bool = false
var _spawn_rect_origin_xz: Vector2 = Vector2.ZERO
var _spawn_rect_size_xz: Vector2 = Vector2.ZERO
var _spawn_rect_seed: int = 0
var _spawn_rect_margin: float = 0.0


func _ready() -> void:
	if randomize_seed_on_ready:
		randomize()

	_loaded_model_scene = _load_tauren_scene()
	if _loaded_model_scene == null:
		push_warning("TaurenSpawner 无法加载小怪模型。")
		return

	_ensure_base_unit_stats_cache()
	_spawn_initial_units(_loaded_model_scene)


func _load_tauren_scene() -> PackedScene:
	var loaded := load(tauren_scene_path) as PackedScene
	if loaded != null:
		return loaded
	if fallback_tauren_scene != null:
		push_warning("未找到 %s，已回退到 HeroTaurenChieftain.glb。" % tauren_scene_path)
	return fallback_tauren_scene


func _spawn_initial_units(model_scene: PackedScene) -> void:
	_spawn_units(maxi(unit_count, 0), global_position, spawn_radius, spawn_radius_jitter, min_spawn_distance, model_scene, _spawn_rect_enabled)


func _spawn_units(count: int, center_position: Vector3, base_radius: float, radius_jitter: float, min_distance: float, model_scene: PackedScene, use_random_positions: bool) -> void:
	if count <= 0 or model_scene == null:
		return
	var spawned_positions: Array[Vector3] = _collect_existing_unit_positions()
	var seeded_rng: RandomNumberGenerator = null
	if _spawn_rect_enabled:
		seeded_rng = RandomNumberGenerator.new()
		if _spawn_rect_seed > 0:
			seeded_rng.seed = _spawn_rect_seed
		else:
			seeded_rng.randomize()
	for i in range(count):
		var unit := TAUREN_UNIT_SCENE.instantiate() as TaurenUnitAI
		if unit == null:
			continue
		unit.name = _next_unit_name()
		var spawn_pos: Vector3 = Vector3.ZERO
		if _spawn_rect_enabled:
			spawn_pos = _pick_spawn_position_in_rect(spawned_positions, min_distance, seeded_rng)
		elif use_random_positions:
			spawn_pos = _pick_spawn_position_random(spawned_positions, center_position, base_radius, radius_jitter, min_distance)
		else:
			spawn_pos = _pick_spawn_position_deterministic(i, count, spawned_positions, center_position, base_radius, radius_jitter, min_distance)
		spawned_positions.append(spawn_pos)
		_apply_profile_to_unit(unit)
		unit.setup_unit(model_scene, spawn_pos, unit_scale)
		add_child(unit)
		if unit.has_method("set_network_authority"):
			unit.call("set_network_authority", _network_authority_enabled)


func _pick_spawn_position_deterministic(slot_index: int, slot_total: int, existing_positions: Array[Vector3], center_position: Vector3, base_radius: float, radius_jitter: float, min_distance: float) -> Vector3:
	var min_radius: float = maxf(80.0, base_radius - radius_jitter)
	var max_radius: float = maxf(min_radius + 1.0, base_radius + radius_jitter)
	var safe_min_distance: float = maxf(min_distance, 60.0)
	var safe_total: int = maxi(slot_total, 1)
	var normalized: float = (float(slot_index) + 0.5) / float(safe_total)
	var initial_radius: float = lerpf(min_radius, max_radius, sqrt(normalized))
	var golden_angle_rad: float = deg_to_rad(137.507764)
	var base_angle: float = (float(slot_index) + float(_spawn_serial)) * golden_angle_rad
	var result: Vector3 = center_position + Vector3(cos(base_angle) * initial_radius, spawn_height, sin(base_angle) * initial_radius)

	for attempt in range(maxi(spawn_try_count, 1)):
		var radius_offset: float = floorf(float(attempt) / 6.0) * maxf(safe_min_distance * 0.35, 24.0)
		var angle_offset: float = float(attempt) * deg_to_rad(17.5)
		var candidate_radius: float = clampf(initial_radius + radius_offset, min_radius, max_radius + radius_offset)
		var candidate_angle: float = base_angle + angle_offset
		var candidate := center_position + Vector3(cos(candidate_angle) * candidate_radius, spawn_height, sin(candidate_angle) * candidate_radius)
		if _is_position_far_enough(candidate, existing_positions, safe_min_distance):
			return candidate
		result = candidate

	return result


func _pick_spawn_position_random(existing_positions: Array[Vector3], center_position: Vector3, base_radius: float, radius_jitter: float, min_distance: float) -> Vector3:
	var min_radius: float = maxf(80.0, base_radius - radius_jitter)
	var max_radius: float = maxf(min_radius + 1.0, base_radius + radius_jitter)
	var safe_min_distance: float = maxf(min_distance, 60.0)
	var result: Vector3 = center_position + Vector3(min_radius, spawn_height, 0.0)

	for _i in range(maxi(spawn_try_count, 1)):
		var angle := randf() * TAU
		var radius := randf_range(min_radius, max_radius)
		var candidate := center_position + Vector3(cos(angle) * radius, spawn_height, sin(angle) * radius)
		if _is_position_far_enough(candidate, existing_positions, safe_min_distance):
			return candidate
		result = candidate

	return result


func _pick_spawn_position_in_rect(existing_positions: Array[Vector3], min_distance: float, rng: RandomNumberGenerator) -> Vector3:
	var safe_rng := rng
	if safe_rng == null:
		safe_rng = RandomNumberGenerator.new()
		safe_rng.randomize()
	var safe_min_distance: float = maxf(min_distance, 60.0)
	var safe_margin_x: float = minf(_spawn_rect_margin, _spawn_rect_size_xz.x * 0.45)
	var safe_margin_z: float = minf(_spawn_rect_margin, _spawn_rect_size_xz.y * 0.45)
	var min_x: float = _spawn_rect_origin_xz.x + safe_margin_x
	var max_x: float = _spawn_rect_origin_xz.x + _spawn_rect_size_xz.x - safe_margin_x
	var min_z: float = _spawn_rect_origin_xz.y + safe_margin_z
	var max_z: float = _spawn_rect_origin_xz.y + _spawn_rect_size_xz.y - safe_margin_z
	var result := Vector3(min_x, spawn_height, min_z)

	for _i in range(maxi(spawn_try_count, 1)):
		var candidate := Vector3(
			safe_rng.randf_range(min_x, maxf(min_x, max_x)),
			spawn_height,
			safe_rng.randf_range(min_z, maxf(min_z, max_z))
		)
		if _is_position_far_enough(candidate, existing_positions, safe_min_distance):
			return candidate
		result = candidate

	return result


func _is_position_far_enough(candidate: Vector3, existing_positions: Array[Vector3], min_distance: float) -> bool:
	for p in existing_positions:
		if candidate.distance_to(p) < min_distance:
			return false
	return true


func set_network_authority(enabled: bool) -> void:
	_network_authority_enabled = enabled
	if enabled:
		_sync_spawn_serial_from_existing_units()
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if unit.has_method("set_network_authority"):
			unit.call("set_network_authority", enabled)


func configure_spawn_rect(origin_xz: Vector2, size_xz: Vector2, seed: int = 0, margin: float = 0.0) -> void:
	_spawn_rect_origin_xz = origin_xz
	_spawn_rect_size_xz = Vector2(maxf(size_xz.x, 0.0), maxf(size_xz.y, 0.0))
	_spawn_rect_seed = maxi(seed, 0)
	_spawn_rect_margin = maxf(margin, 0.0)
	_spawn_rect_enabled = _spawn_rect_size_xz.x > 0.0 and _spawn_rect_size_xz.y > 0.0


func apply_floor_profile(profile: Dictionary) -> void:
	_floor_profile = profile.duplicate(true)
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if unit.has_method("apply_floor_profile"):
			unit.call("apply_floor_profile", _floor_profile)


func reset_for_floor(profile: Dictionary) -> void:
	_floor_profile = profile.duplicate(true)
	_clear_all_units()
	_spawn_serial = 0
	if _loaded_model_scene == null:
		_loaded_model_scene = _load_tauren_scene()
	if _loaded_model_scene == null:
		return
	_spawn_initial_units(_loaded_model_scene)


func clear_units() -> void:
	_clear_all_units()


func has_living_units() -> bool:
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if unit.has_method("is_dead") and not bool(unit.call("is_dead")):
			return true
	return false


func get_living_unit_count() -> int:
	var count: int = 0
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if unit.has_method("is_dead") and not bool(unit.call("is_dead")):
			count += 1
	return count


func collect_network_states() -> Array:
	var states: Array = []
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if unit.has_method("export_network_state"):
			var state_variant: Variant = unit.call("export_network_state")
			if state_variant is Dictionary:
				states.append(state_variant)
	return states


func apply_network_states(states: Array, is_partial: bool = false) -> void:
	if _loaded_model_scene == null:
		_loaded_model_scene = _load_tauren_scene()
	var units_by_id: Dictionary = {}
	var seen_ids: Dictionary = {}
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		units_by_id[unit.name] = unit

	for state_variant in states:
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var unit_id: String = str(state.get("id", ""))
		if unit_id.is_empty():
			continue
		seen_ids[unit_id] = true
		var unit_ref: TaurenUnitAI = units_by_id.get(unit_id, null) as TaurenUnitAI
		if unit_ref == null and _loaded_model_scene != null:
			var spawn_pos: Vector3 = global_position
			var pos_variant: Variant = state.get("pos", null)
			if pos_variant is Vector3:
				spawn_pos = pos_variant
			var spawned := TAUREN_UNIT_SCENE.instantiate() as TaurenUnitAI
			if spawned != null:
				spawned.name = unit_id
				spawned.setup_unit(_loaded_model_scene, spawn_pos, unit_scale)
				add_child(spawned)
				if spawned.has_method("set_network_authority"):
					spawned.call("set_network_authority", _network_authority_enabled)
				unit_ref = spawned
				units_by_id[unit_id] = spawned
		if unit_ref == null:
			continue
		if unit_ref.has_method("apply_network_state"):
			unit_ref.call("apply_network_state", state)
	_sync_spawn_serial_from_existing_units()

	# 仅在完整快照时清理残留单位，避免分片快照误删。
	if is_partial:
		return
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		if seen_ids.has(unit.name):
			continue
		unit.queue_free()


func spawn_wave_at_position(count: int, around_position: Vector3) -> void:
	if count <= 0:
		return
	if _loaded_model_scene == null:
		_loaded_model_scene = _load_tauren_scene()
	if _loaded_model_scene == null:
		return
	var center: Vector3 = around_position
	center.y = global_position.y
	_spawn_units(
		count,
		center,
		phase_wave_spawn_radius,
		phase_wave_spawn_radius_jitter,
		phase_wave_min_spawn_distance,
		_loaded_model_scene,
		true
	)


func _collect_existing_unit_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		positions.append(unit.global_position)
	return positions


func _next_unit_name() -> String:
	var next_name: String = "TaurenUnit_%d" % _spawn_serial
	_spawn_serial += 1
	return next_name


func _apply_profile_to_unit(unit: TaurenUnitAI) -> void:
	if unit == null:
		return
	_ensure_base_unit_stats_cache()
	if _floor_profile.is_empty():
		unit.max_hp = int(_base_unit_stats.get("max_hp", unit.max_hp))
		unit.damage_per_hit = int(_base_unit_stats.get("damage_per_hit", unit.damage_per_hit))
		unit.armor = float(_base_unit_stats.get("armor", unit.armor))
		return
	unit.max_hp = maxi(int(round(float(_base_unit_stats.get("max_hp", unit.max_hp)) * float(_floor_profile.get("mob_hp_multiplier", 1.0)))), 1)
	unit.damage_per_hit = maxi(int(round(float(_base_unit_stats.get("damage_per_hit", unit.damage_per_hit)) * float(_floor_profile.get("mob_damage_multiplier", 1.0)))), 1)
	unit.armor = float(_base_unit_stats.get("armor", unit.armor))


func _ensure_base_unit_stats_cache() -> void:
	if not _base_unit_stats.is_empty():
		return
	var probe := TAUREN_UNIT_SCENE.instantiate() as TaurenUnitAI
	if probe == null:
		return
	_base_unit_stats = {
		"max_hp": probe.max_hp,
		"damage_per_hit": probe.damage_per_hit,
		"armor": probe.armor,
	}
	probe.free()


func _clear_all_units() -> void:
	var units: Array[TaurenUnitAI] = []
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit != null:
			units.append(unit)
	for unit in units:
		if unit.get_parent() != null:
			unit.get_parent().remove_child(unit)
		unit.free()


func _sync_spawn_serial_from_existing_units() -> void:
	var max_serial: int = -1
	for child in get_children():
		var unit: TaurenUnitAI = child as TaurenUnitAI
		if unit == null:
			continue
		var unit_name: String = str(unit.name)
		if not unit_name.begins_with("TaurenUnit_"):
			continue
		var serial_text: String = unit_name.trim_prefix("TaurenUnit_")
		if not serial_text.is_valid_int():
			continue
		max_serial = max(max_serial, serial_text.to_int())
	_spawn_serial = max(_spawn_serial, max_serial + 1)
