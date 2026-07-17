extends CharacterBody3D
class_name TaurenUnitAI

const CombatSceneUtils := preload("res://combat_scene_utils.gd")

@export var move_speed: float = 140.0
@export var chase_nav_update_interval_ms: int = 300
@export var attack_range: float = 280.0
@export var engage_range: float = 1500.0
@export var max_hp: int = 1050
@export_range(0.0, 100.0, 0.1) var magic_immunity_rate: float = 0.0
@export var damage_per_hit: int = 12
@export var armor: float = 0.0
@export var attack_speed: float = 1.1
@export_range(0.0, 100.0, 0.1) var critical_chance_percent: float = 0.0
@export var critical_multiplier: float = 2.0
@export var invulnerable: bool = false
@export var target_group_name: StringName = &"hero"
@export var collision_group_name: StringName = &"enemy"
@export var allow_target_chase: bool = true
@export var follow_anchor_enabled: bool = false
@export var follow_anchor_offset: Vector3 = Vector3.ZERO
@export var follow_anchor_orbit_radius: float = 0.0
@export var follow_anchor_orbit_height: float = 0.0
@export var follow_anchor_angular_speed_deg: float = 0.0
@export var follow_anchor_speed: float = 420.0
@export var idle_animation: String = "Stand - 1_GLTF"
@export var walk_animation: String = "Walk_GLTF"
@export var death_animation: String = "Death_GLTF"
@export var attack_animation_1: String = "Attack - 1_GLTF"
@export var attack_animation_2: String = ""
@export var attack_animation_3: String = ""
@export var hp_bar_height: float = 200.0
@export var hp_bar_width: float = 170.0
@export var collision_radius: float = 72.0
@export var collision_height: float = 192.0
@export_flags_3d_physics var movement_collision_layer: int = 8
@export_flags_3d_physics var movement_collision_mask: int = 9
@export_flags_3d_physics var click_collision_layer: int = 2
@export_flags_3d_physics var click_collision_mask: int = 0
@export var network_authoritative: bool = true
@export var remote_sync_position_smooth_speed: float = 14.0
@export var remote_sync_rotation_smooth_speed: float = 12.0
@export var remote_sync_snap_distance: float = 260.0
@export var remote_sync_prediction_sec: float = 0.10
@export var remote_sync_prediction_max_sec: float = 0.45
@export var remote_sync_prediction_timeout_sec: float = 1.0
@export var remote_sync_prediction_velocity_damping: float = 4.0
@export var dynamic_detour_enabled: bool = true
@export var dynamic_detour_trigger_sec: float = 0.18
@export var dynamic_detour_duration_sec: float = 0.55
@export var dynamic_detour_side_strength: float = 0.95
@export var dynamic_detour_progress_ratio_threshold: float = 0.25
@export var attack_action_priority: int = 2
@export var knockback_action_priority: int = 5

var _model: Node3D
var _target: Node3D = null
var _animation_player: AnimationPlayer
var _nav_agent: NavigationAgent3D
var _move_collision_shape: CollisionShape3D
var _hp_bar: MeshInstance3D
var _hp_bar_material: ShaderMaterial
var _hp_bar_anchor_height: float = 0.0
var _current_hp: int = 0
var _is_dead: bool = false
var _is_moving: bool = false
var _is_attacking: bool = false
var _attack_cooldown: float = 0.0
var _attack_anims: Array[String] = []
var _resolved_idle_animation: String = ""
var _resolved_walk_animation: String = ""
var _resolved_death_animation: String = ""
var _warned_missing_walk: bool = false
var _pending_idle_after_animation: bool = false
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_yaw: float = 0.0
var _remote_velocity: Vector3 = Vector3.ZERO
var _remote_last_receive_ms: int = 0
var _remote_has_target: bool = false
var _network_command_seq: int = 0
var _network_last_command: Dictionary = {}
var _dynamic_detour_time_left: float = 0.0
var _dynamic_detour_side: float = 1.0
var _dynamic_blocked_time: float = 0.0
var _pending_spawn_position: Vector3 = Vector3.ZERO
var _has_pending_spawn_position: bool = false
var _knockback_tween: Tween
var _knockback_active: bool = false
var _last_chase_nav_update_ms: int = -1
var _follow_anchor_node: Node3D = null
var _base_progression_stats: Dictionary = {}
var _damage_popup_sync_seq: int = 0
var _damage_popup_sync_amount: int = 0
var _damage_popup_sync_source: String = "basic_attack"
var _damage_popup_sync_critical: bool = false
var _last_applied_damage_popup_sync_seq: int = 0
var _damage_popup_sync_initialized: bool = false
var _incoming_damage_bonus_temporary_percent: float = 0.0
var _incoming_damage_bonus_permanent_percent: float = 0.0
var _incoming_damage_bonus_time_left: float = 0.0
const HP_BAR_HEIGHT_OFFSET: float = 200.0


func setup_unit(model_scene: PackedScene, spawn_pos: Vector3, spawn_scale: Vector3) -> void:
	if is_inside_tree():
		global_position = spawn_pos
		_has_pending_spawn_position = false
	else:
		_pending_spawn_position = spawn_pos
		_has_pending_spawn_position = true
	if _model != null and is_instance_valid(_model):
		_model.queue_free()
	_model = model_scene.instantiate() as Node3D
	if _model == null:
		return
	_model.name = "Model"
	add_child(_model)
	_model.scale = spawn_scale
	_setup_movement_collision()
	_setup_collision_body()
	if is_inside_tree():
		_bind_runtime_after_model_ready()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = movement_collision_layer
	collision_mask = movement_collision_mask
	velocity = Vector3.ZERO
	if _has_pending_spawn_position:
		global_position = _pending_spawn_position
		_has_pending_spawn_position = false

	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 20.0
	_nav_agent.target_desired_distance = 20.0
	add_child(_nav_agent)

	_current_hp = max_hp
	_cache_base_progression_stats()
	_remote_target_position = global_position
	_remote_target_yaw = rotation.y
	_remote_last_receive_ms = Time.get_ticks_msec()
	_remote_has_target = true

	if _model == null:
		push_warning("TaurenUnitAI 缺少模型实例。等待 setup_unit 初始化。")
		return

	_bind_runtime_after_model_ready()


func _bind_runtime_after_model_ready() -> void:
	if _model == null:
		return
	if _hp_bar == null or not is_instance_valid(_hp_bar):
		_create_hp_bar()
	_update_hp_bar()
	_animation_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_resolve_animations()
	_play_idle_animation()
	_push_network_control_command("idle", {"target_pos": global_position})
	if (
		_animation_player != null
		and not _animation_player.animation_finished.is_connected(_on_animation_finished)
	):
		_animation_player.animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	_sync_hp_bar_follow_and_facing()
	if _is_dead:
		if not network_authoritative:
			_update_remote_sync_smoothing(delta)
		return
	if _knockback_active:
		velocity = Vector3.ZERO
		return
	if not network_authoritative:
		_update_remote_sync_smoothing(delta)
		return
	_update_incoming_damage_bonus_runtime(delta)

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	_update_target()
	var has_anchor_follow: bool = _has_follow_anchor()
	var anchor_target_pos: Vector3 = global_position
	if has_anchor_follow:
		anchor_target_pos = _get_follow_anchor_target_position()
	if _target == null:
		if has_anchor_follow:
			if _is_attacking:
				_is_attacking = false
			_move_toward_anchor_target(anchor_target_pos, delta)
		else:
			velocity = Vector3.ZERO
			if _is_attacking:
				_queue_idle_after_current_animation()
				if _pending_idle_after_animation:
					return
				_is_attacking = false
				_push_network_control_command("idle")
			else:
				if (
					_pending_idle_after_animation
					and _animation_player != null
					and _animation_player.is_playing()
				):
					return
				_stop_move_and_idle()
		return

	var target_pos: Vector3 = _target.global_position
	var distance: float = _distance_xz(global_position, target_pos)

	if _is_attacking:
		if distance > attack_range:
			if allow_target_chase:
				_interrupt_attack_for_chase()
			else:
				_is_attacking = false
				_target = null
				if has_anchor_follow:
					_move_toward_anchor_target(anchor_target_pos, delta)
				else:
					_stop_move_and_idle()
			return
		_face_toward(target_pos)
		return

	if distance > attack_range:
		if allow_target_chase:
			_chase_target(target_pos, delta)
		elif has_anchor_follow:
			_target = null
			_move_toward_anchor_target(anchor_target_pos, delta)
		else:
			_target = null
			_stop_move_and_idle()
	else:
		_reset_dynamic_detour_runtime()
		_stop_move_and_idle()
		_face_toward(target_pos)
		if _attack_cooldown <= 0.0:
			_start_attack()


func apply_damage(
	amount: int,
	attacker: Node3D = null,
	damage_source: String = "basic_attack",
	hit_context: Dictionary = {}
) -> void:
	if invulnerable:
		return
	if _is_dead:
		return
	var incoming: int = maxi(amount, 0)
	var final_damage: int = incoming
	if final_damage > 0 and _is_magic_damage_source(damage_source):
		final_damage = maxi(int(round(float(incoming) * _get_magic_damage_multiplier())), 0)
	elif final_damage > 0:
		final_damage = maxi(int(round(float(incoming) * _get_physical_damage_multiplier())), 0)
	_current_hp = max(_current_hp - final_damage, 0)
	_update_hp_bar()
	if final_damage > 0:
		_emit_damage_popup(final_damage, damage_source, bool(hit_context.get("is_critical", false)))
	_apply_incoming_damage_bonus_from_context(hit_context)
	if final_damage > 0 and _current_hp > 0:
		_retarget_to_attacker(attacker)
	if _current_hp <= 0:
		_die()


func _get_magic_damage_multiplier() -> float:
	var clamped_rate: float = clampf(magic_immunity_rate, 0.0, 100.0)
	return maxf(1.0 - clamped_rate * 0.01, 0.0)


func _get_physical_damage_multiplier() -> float:
	var effective_armor: float = maxf(armor - get_incoming_damage_bonus_percent(), 0.0)
	if effective_armor <= 0.0:
		return 1.0
	return maxf(1.0 - (0.06 * effective_armor) / (1.0 + 0.06 * effective_armor), 0.0)


func get_incoming_damage_bonus_percent() -> float:
	return (
		maxf(_incoming_damage_bonus_temporary_percent, 0.0)
		+ maxf(_incoming_damage_bonus_permanent_percent, 0.0)
	)


func apply_incoming_damage_bonus(
	bonus_percent: float, duration_sec: float = 0.0, permanent: bool = false
) -> void:
	var safe_bonus: float = maxf(bonus_percent, 0.0)
	if safe_bonus <= 0.0:
		return
	if permanent:
		_incoming_damage_bonus_permanent_percent += safe_bonus
		return
	_incoming_damage_bonus_temporary_percent += safe_bonus
	_incoming_damage_bonus_time_left = maxf(_incoming_damage_bonus_time_left, duration_sec)


func _apply_incoming_damage_bonus_from_context(hit_context: Dictionary) -> void:
	if hit_context.is_empty():
		return
	var bonus_percent: float = maxf(float(hit_context.get("armor_shred_percent", 0.0)), 0.0)
	if bonus_percent <= 0.0:
		return
	var duration_sec: float = maxf(float(hit_context.get("armor_shred_duration_sec", 0.0)), 0.0)
	var permanent: bool = bool(hit_context.get("armor_shred_permanent", false))
	apply_incoming_damage_bonus(bonus_percent, duration_sec, permanent)


func _update_incoming_damage_bonus_runtime(delta: float) -> void:
	if _incoming_damage_bonus_temporary_percent <= 0.0 and _incoming_damage_bonus_time_left <= 0.0:
		return
	_incoming_damage_bonus_time_left = maxf(
		_incoming_damage_bonus_time_left - maxf(delta, 0.0), 0.0
	)
	if _incoming_damage_bonus_time_left <= 0.0:
		_incoming_damage_bonus_temporary_percent = 0.0


func apply_floor_profile(profile: Dictionary) -> void:
	_cache_base_progression_stats()
	if profile.is_empty():
		return
	max_hp = maxi(
		int(
			round(
				(
					float(_base_progression_stats.get("max_hp", max_hp))
					* float(profile.get("mob_hp_multiplier", 1.0))
				)
			)
		),
		1
	)
	damage_per_hit = maxi(
		int(
			round(
				(
					float(_base_progression_stats.get("damage_per_hit", damage_per_hit))
					* float(profile.get("mob_damage_multiplier", 1.0))
				)
			)
		),
		1
	)
	armor = float(_base_progression_stats.get("armor", armor))
	_current_hp = max_hp
	_update_hp_bar()


func _cache_base_progression_stats() -> void:
	if not _base_progression_stats.is_empty():
		return
	_base_progression_stats = {
		"max_hp": max_hp,
		"damage_per_hit": damage_per_hit,
		"armor": armor,
	}


func _is_magic_damage_source(source: String) -> bool:
	var kind: String = source.strip_edges().to_lower()
	if kind.begins_with("attack_effect"):
		return true
	match kind:
		"magic", "spell", "q_ray", "flash", "poison", "skill", "r_cluster":
			return true
		_:
			return false


func _emit_damage_popup(amount: int, damage_source: String, is_critical: bool = false) -> void:
	if amount <= 0:
		return
	_record_damage_popup_sync(amount, damage_source, is_critical)
	_show_damage_popup(amount, damage_source, is_critical)


func _show_damage_popup(amount: int, damage_source: String, is_critical: bool = false) -> void:
	if amount <= 0:
		return
	if _hp_bar_anchor_height <= 0.0:
		_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	CombatSceneUtils.spawn_damage_popup(
		self, amount, _hp_bar_anchor_height, _is_magic_damage_source(damage_source), is_critical
	)


func _record_damage_popup_sync(amount: int, damage_source: String, is_critical: bool) -> void:
	_damage_popup_sync_seq = maxi(_damage_popup_sync_seq + 1, 1)
	_damage_popup_sync_amount = maxi(amount, 0)
	_damage_popup_sync_source = damage_source
	_damage_popup_sync_critical = is_critical


func _apply_remote_damage_popup_sync(state: Dictionary) -> void:
	var seq: int = maxi(int(state.get("damage_popup_seq", _damage_popup_sync_seq)), 0)
	var amount: int = maxi(int(state.get("damage_popup_amount", 0)), 0)
	var source: String = str(state.get("damage_popup_source", "basic_attack"))
	var is_critical: bool = bool(state.get("damage_popup_critical", false))
	_damage_popup_sync_seq = seq
	_damage_popup_sync_amount = amount
	_damage_popup_sync_source = source
	_damage_popup_sync_critical = is_critical
	if not _damage_popup_sync_initialized:
		_last_applied_damage_popup_sync_seq = seq
		_damage_popup_sync_initialized = true
		return
	if seq <= _last_applied_damage_popup_sync_seq:
		return
	_last_applied_damage_popup_sync_seq = seq
	if amount > 0:
		_show_damage_popup(amount, source, is_critical)


func apply_knockback(
	push_direction: Vector3, distance: float, duration_sec: float = 0.2, source_priority: int = 0
) -> bool:
	if _is_dead:
		return false
	var safe_distance: float = clampf(distance, 0.0, 280.0)
	if safe_distance <= 0.0:
		return false
	var incoming_priority: int = maxi(source_priority, 0)
	if incoming_priority < _get_current_action_priority():
		return false
	var safe_duration: float = clampf(duration_sec, 0.05, 0.2)
	var planar_dir: Vector3 = push_direction
	planar_dir.y = 0.0
	if planar_dir.length_squared() <= 0.0001:
		return false
	var from_pos: Vector3 = global_position
	var to_pos: Vector3 = from_pos + planar_dir.normalized() * safe_distance
	to_pos.y = from_pos.y
	if _knockback_tween != null and _knockback_tween.is_valid():
		_knockback_tween.kill()
	_knockback_active = true
	_pending_idle_after_animation = false
	_is_moving = false
	_reset_chase_nav_throttle()
	_is_attacking = false
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()
	_knockback_tween = create_tween()
	_knockback_tween.set_trans(Tween.TRANS_LINEAR)
	_knockback_tween.set_ease(Tween.EASE_IN_OUT)
	_knockback_tween.tween_property(self, "global_position", to_pos, safe_duration)
	_knockback_tween.finished.connect(
		func() -> void:
			_knockback_active = false
			_knockback_tween = null
	)
	velocity = Vector3.ZERO
	_reset_dynamic_detour_runtime()
	return true


func _get_current_action_priority() -> int:
	var priority: int = 0
	if _is_attacking:
		priority = maxi(priority, attack_action_priority)
	if _knockback_active:
		priority = maxi(priority, knockback_action_priority)
	return priority


func _retarget_to_attacker(attacker: Node3D) -> void:
	# 有攻击对象时保持当前仇恨；仅在无目标时才由受击触发追击。
	if _target != null and is_instance_valid(_target) and not _is_target_dead(_target):
		return
	if attacker == null or not is_instance_valid(attacker):
		return
	if _is_target_dead(attacker):
		return
	_target = attacker
	_reset_chase_nav_throttle()
	if _is_attacking:
		_interrupt_attack_for_chase()
	_pending_idle_after_animation = false
	_face_toward(attacker.global_position)
	if not _is_moving:
		_is_moving = true
		_play_walk_animation()
		_push_network_control_command(
			"chase_target",
			{"target_path": str(attacker.get_path()), "target_pos": attacker.global_position}
		)


func is_dead() -> bool:
	return _is_dead


func _setup_movement_collision() -> void:
	_move_collision_shape = get_node_or_null("MovementCollision") as CollisionShape3D
	if _move_collision_shape == null:
		_move_collision_shape = CollisionShape3D.new()
		_move_collision_shape.name = "MovementCollision"
		add_child(_move_collision_shape)

	var capsule := CapsuleShape3D.new()
	capsule.radius = collision_radius
	capsule.height = collision_height
	_move_collision_shape.shape = capsule
	_move_collision_shape.position = Vector3(0.0, collision_height * 0.5, 0.0)


func _setup_collision_body() -> void:
	if _model == null:
		return
	var collision_body := _model.get_node_or_null("CollisionBody") as StaticBody3D
	if collision_body == null:
		collision_body = StaticBody3D.new()
		collision_body.name = "CollisionBody"
		_model.add_child(collision_body)
	collision_body.collision_layer = click_collision_layer
	collision_body.collision_mask = click_collision_mask
	collision_body.remove_from_group("enemy")
	collision_body.remove_from_group("hero")
	collision_body.remove_from_group("ally_summon")
	var group_name_text: String = String(collision_group_name).strip_edges()
	if not group_name_text.is_empty():
		collision_body.add_to_group(StringName(group_name_text))

	var collision_shape := collision_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_body.add_child(collision_shape)

	var capsule := CapsuleShape3D.new()
	capsule.radius = collision_radius
	capsule.height = collision_height
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, collision_height * 0.5, 0.0)


func _update_target() -> void:
	# 一旦锁定目标，只在目标死亡/失效时才丢失
	if _target != null and is_instance_valid(_target) and not _is_target_dead(_target):
		return
	# 仅在索敌范围内获取新目标
	_target = _find_nearest_target()


func _find_nearest_target() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group(target_group_name):
		var target := node as Node3D
		if target == null:
			continue
		if not target.visible:
			continue
		if _is_target_dead(target):
			continue
		var distance: float = _distance_xz(global_position, target.global_position)
		if distance > engage_range:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	return nearest


func set_follow_anchor(node: Node3D) -> void:
	_follow_anchor_node = node


func clear_follow_anchor() -> void:
	_follow_anchor_node = null


func _has_follow_anchor() -> bool:
	return (
		follow_anchor_enabled
		and _follow_anchor_node != null
		and is_instance_valid(_follow_anchor_node)
	)


func _get_follow_anchor_target_position() -> Vector3:
	if not _has_follow_anchor():
		return global_position
	var anchor_pos: Vector3 = _follow_anchor_node.global_position
	var orbit_angle_rad: float = (
		deg_to_rad(follow_anchor_angular_speed_deg) * float(Time.get_ticks_msec()) * 0.001
	)
	var orbit_offset := Vector3(
		cos(orbit_angle_rad) * follow_anchor_orbit_radius,
		follow_anchor_orbit_height,
		sin(orbit_angle_rad) * follow_anchor_orbit_radius
	)
	return anchor_pos + follow_anchor_offset + orbit_offset


func _move_toward_anchor_target(anchor_pos: Vector3, _delta: float) -> void:
	var target_pos: Vector3 = anchor_pos
	target_pos.y = global_position.y
	var move_delta: Vector3 = target_pos - global_position
	move_delta.y = 0.0
	var distance: float = move_delta.length()
	if distance <= 4.0 or follow_anchor_speed <= 0.0:
		_stop_move_and_idle()
		return
	velocity = move_delta.normalized() * follow_anchor_speed
	move_and_slide()
	_look_at_target(target_pos)
	if not _is_moving:
		_is_moving = true
		_play_walk_animation()
		_push_network_control_command("move_to", {"target_pos": target_pos})


func _is_target_dead(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return true
	if not target.visible:
		return true
	var controller := target.get_parent()
	if controller != null and controller.has_method("is_dead"):
		return bool(controller.call("is_dead"))
	var peer_id: int = _get_remote_target_peer_id(target)
	if peer_id > 0:
		var net_ctrl: NetSessionController = _get_network_session_controller()
		if net_ctrl != null:
			var state_variant: Variant = net_ctrl.get_ui_peer_hero_state(peer_id)
			if state_variant is Dictionary:
				var state: Dictionary = state_variant as Dictionary
				if bool(state.get("is_dead", false)):
					return true
				if int(state.get("hp", 1)) <= 0:
					return true
	return false


func _chase_target(target_pos: Vector3, delta: float) -> void:
	_update_chase_nav_target_throttled(target_pos)
	var move_target := target_pos
	if not _nav_agent.is_navigation_finished():
		var next_nav := _nav_agent.get_next_path_position()
		if _distance_xz(next_nav, global_position) > 1.0:
			move_target = next_nav

	var move_dir := move_target - global_position
	move_dir.y = 0.0
	var has_move_intent: bool = move_dir.length() > 0.01
	if not has_move_intent:
		velocity = Vector3.ZERO
		_reset_dynamic_detour_runtime()
		return

	var base_dir: Vector3 = move_dir.normalized()
	var steering_dir: Vector3 = base_dir
	if dynamic_detour_enabled and _dynamic_detour_time_left > 0.0:
		var side_vec: Vector3 = base_dir.cross(Vector3.UP)
		if side_vec.length() > 0.001:
			side_vec = side_vec.normalized()
			steering_dir = (
				(
					base_dir
					+ side_vec * _dynamic_detour_side * maxf(dynamic_detour_side_strength, 0.0)
				)
				. normalized()
			)
		_dynamic_detour_time_left = maxf(_dynamic_detour_time_left - maxf(delta, 0.0), 0.0)

	var before_pos: Vector3 = global_position
	velocity = Vector3(steering_dir.x * move_speed, 0.0, steering_dir.z * move_speed)
	move_and_slide()
	if dynamic_detour_enabled:
		var moved_dist: float = _distance_xz(global_position, before_pos)
		var expected_step: float = maxf(move_speed * maxf(delta, 0.0), 0.001)
		var progress_ratio: float = moved_dist / expected_step
		if progress_ratio < clampf(dynamic_detour_progress_ratio_threshold, 0.05, 0.95):
			_dynamic_blocked_time += maxf(delta, 0.0)
			if _dynamic_blocked_time >= maxf(dynamic_detour_trigger_sec, 0.05):
				_dynamic_detour_time_left = maxf(dynamic_detour_duration_sec, 0.08)
				_dynamic_blocked_time = 0.0
				_dynamic_detour_side = -_dynamic_detour_side
		else:
			_dynamic_blocked_time = maxf(_dynamic_blocked_time - maxf(delta, 0.0) * 1.6, 0.0)

	_look_at_target(move_target)
	if not _is_moving:
		_is_moving = true
		_play_walk_animation()
		if _target != null and is_instance_valid(_target):
			_push_network_control_command(
				"chase_target",
				{"target_path": str(_target.get_path()), "target_pos": _target.global_position}
			)


func _update_chase_nav_target_throttled(target_pos: Vector3, force: bool = false) -> void:
	if _nav_agent == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	var interval_ms: int = maxi(chase_nav_update_interval_ms, 0)
	var should_refresh: bool = force or _last_chase_nav_update_ms < 0
	if not should_refresh:
		if interval_ms <= 0:
			should_refresh = true
		elif now_ms - _last_chase_nav_update_ms >= interval_ms:
			should_refresh = true
	if not should_refresh:
		return
	_nav_agent.target_position = target_pos
	_last_chase_nav_update_ms = now_ms


func _reset_chase_nav_throttle() -> void:
	_last_chase_nav_update_ms = -1


func _start_attack() -> void:
	if _target != null and is_instance_valid(_target) and not _is_target_dead(_target):
		_face_toward(_target.global_position)
	_is_attacking = true
	velocity = Vector3.ZERO
	_attack_cooldown = _get_attack_interval()
	if _target != null and is_instance_valid(_target):
		_push_network_control_command(
			"attack_target",
			{"target_path": str(_target.get_path()), "target_pos": _target.global_position}
		)
	var attack_anim := _choose_attack_animation()
	if _animation_player != null and attack_anim != "":
		var anim := _animation_player.get_animation(attack_anim)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
		_animation_player.play(attack_anim, -1.0, _get_attack_speed_scale(), false)
	_try_apply_damage_to_target()


func _choose_attack_animation() -> String:
	if _attack_anims.is_empty():
		return ""
	return _attack_anims[randi() % _attack_anims.size()]


func _try_apply_damage_to_target() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if _is_target_dead(_target):
		return
	_face_toward(_target.global_position)
	var distance: float = _distance_xz(global_position, _target.global_position)
	if distance > attack_range:
		return
	var target_controller := _target.get_parent()
	var final_damage: int = _compute_attack_damage()
	if target_controller != null and target_controller.has_method("apply_damage"):
		if String(target_group_name) == "enemy":
			if _model != null:
				target_controller.call("apply_damage", final_damage, _model, "physical")
			else:
				target_controller.call("apply_damage", final_damage, null, "physical")
		else:
			if _model != null:
				target_controller.call("apply_damage", final_damage, false, _model)
			else:
				target_controller.call("apply_damage", final_damage)
		if _is_target_dead(_target):
			_target = _find_nearest_target()
			return
			# 当前目标死亡时，保留本次攻击动作播完，再在后续帧重新索敌。
			_target = null
		return
	var target_peer_id: int = _get_remote_target_peer_id(_target)
	if target_peer_id > 0:
		var net_ctrl: NetSessionController = _get_network_session_controller()
		if net_ctrl != null:
			net_ctrl.request_damage_remote_hero(target_peer_id, final_damage, false, "physical")
		if _is_target_dead(_target):
			_target = _find_nearest_target()
			return


func _on_animation_finished(_anim_name: StringName) -> void:
	var finished_attack: bool = _is_attacking
	if _is_attacking:
		_is_attacking = false
	if _pending_idle_after_animation:
		_pending_idle_after_animation = false
		_resolve_target_after_attack_end()
		return
	if (
		finished_attack
		and (_target == null or not is_instance_valid(_target) or _is_target_dead(_target))
	):
		_resolve_target_after_attack_end()


func _stop_move_and_idle() -> void:
	var had_motion: bool = _is_moving or _is_attacking
	velocity = Vector3.ZERO
	_reset_dynamic_detour_runtime()
	_reset_chase_nav_throttle()
	if _is_moving:
		_is_moving = false
	_play_idle_animation()
	if had_motion:
		_push_network_control_command("idle")


func _resolve_target_after_attack_end() -> void:
	_update_target()
	var has_anchor_follow: bool = _has_follow_anchor()
	if _target == null:
		if has_anchor_follow:
			_move_toward_anchor_target(_get_follow_anchor_target_position(), 0.0)
			return
		velocity = Vector3.ZERO
		_reset_dynamic_detour_runtime()
		_reset_chase_nav_throttle()
		_is_moving = false
		_play_idle_animation()
		_push_network_control_command("idle")
		return
	var target_pos: Vector3 = _target.global_position
	var distance: float = _distance_xz(global_position, target_pos)
	_face_toward(target_pos)
	if distance > attack_range:
		if allow_target_chase:
			_update_chase_nav_target_throttled(target_pos, true)
			velocity = Vector3.ZERO
			_is_moving = true
			_play_walk_animation()
			_push_network_control_command(
				"chase_target",
				{"target_path": str(_target.get_path()), "target_pos": _target.global_position}
			)
			return
		_target = null
		if has_anchor_follow:
			_move_toward_anchor_target(_get_follow_anchor_target_position(), 0.0)
			return
		velocity = Vector3.ZERO
		_reset_dynamic_detour_runtime()
		_reset_chase_nav_throttle()
		_is_moving = false
		_play_idle_animation()
		_push_network_control_command("idle")
		return
	velocity = Vector3.ZERO
	_reset_dynamic_detour_runtime()
	_reset_chase_nav_throttle()
	_is_moving = false
	_play_idle_animation()
	_push_network_control_command("idle")


func _queue_idle_after_current_animation() -> void:
	if _animation_player == null:
		_play_idle_animation()
		return
	if not _animation_player.is_playing():
		_play_idle_animation()
		return
	var current_anim_name: String = String(_animation_player.current_animation)
	if current_anim_name == _resolved_idle_animation:
		return
	if _resolved_walk_animation != "" and current_anim_name == _resolved_walk_animation:
		_play_idle_animation()
		return
	var current_anim: Animation = _animation_player.get_animation(
		_animation_player.current_animation
	)
	if current_anim != null and current_anim.loop_mode == Animation.LOOP_NONE:
		_pending_idle_after_animation = true
		return
	_play_idle_animation()


func _interrupt_attack_for_chase() -> void:
	if not _is_attacking:
		return
	_is_attacking = false
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	if _knockback_tween != null and _knockback_tween.is_valid():
		_knockback_tween.kill()
	_knockback_tween = null
	_knockback_active = false
	_is_attacking = false
	_pending_idle_after_animation = false
	_is_moving = false
	_reset_chase_nav_throttle()
	_reset_dynamic_detour_runtime()
	velocity = Vector3.ZERO
	_target = null
	_push_network_control_command("dead")
	if _hp_bar != null:
		_hp_bar.visible = false
	if _animation_player != null and _resolved_death_animation != "":
		var anim := _animation_player.get_animation(_resolved_death_animation)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
		_animation_player.play(_resolved_death_animation, -1.0, 1.0, false)
		var death_duration := 0.8
		if anim != null:
			death_duration = maxf(anim.length, 0.1)
		get_tree().create_timer(death_duration).timeout.connect(queue_free)
	else:
		queue_free()


func _resolve_animations() -> void:
	if _animation_player == null:
		return
	_resolved_idle_animation = _resolve_animation(idle_animation, ["stand", "idle", "wait"])
	_resolved_walk_animation = _resolve_animation(
		walk_animation, ["walk", "run", "move", "locomotion", "go"]
	)
	_resolved_death_animation = _resolve_animation(death_animation, ["death", "die"])
	_resolve_attack_animations()
	if _resolved_walk_animation == "":
		_resolved_walk_animation = _fallback_walk_animation()
	if _resolved_walk_animation == "" and not _warned_missing_walk:
		_warned_missing_walk = true
		push_warning(
			"TaurenUnitAI 未找到行走动画，可用动画: %s" % [str(_animation_player.get_animation_list())]
		)


func _is_playable_animation(anim_name: String) -> bool:
	if _animation_player == null:
		return false
	if anim_name == "" or not _animation_player.has_animation(anim_name):
		return false
	var anim: Animation = _animation_player.get_animation(anim_name)
	return anim != null and anim.length > 0.01


func _resolve_animation(preferred_name: String, keywords: Array[String]) -> String:
	if preferred_name != "" and _is_playable_animation(preferred_name):
		return preferred_name
	var anim_list: PackedStringArray = _animation_player.get_animation_list()
	var fallback_match: String = ""
	for anim_name_sn in anim_list:
		var anim_name: String = String(anim_name_sn)
		var lower: String = anim_name.to_lower()
		for kw in keywords:
			if lower.find(kw) >= 0:
				if _is_playable_animation(anim_name):
					return anim_name
				if fallback_match == "":
					fallback_match = anim_name
				break
	return fallback_match


func _resolve_attack_animations() -> void:
	_attack_anims.clear()
	if _animation_player == null:
		return
	var preferred: Array[String] = [attack_animation_1, attack_animation_2, attack_animation_3]
	for anim_name in preferred:
		if anim_name != "" and _is_playable_animation(anim_name) and anim_name not in _attack_anims:
			_attack_anims.append(anim_name)

	if _attack_anims.is_empty():
		var anim_list: PackedStringArray = _animation_player.get_animation_list()
		var fallback_attack_candidates: Array[String] = []
		for anim_name_sn in anim_list:
			var anim_name: String = String(anim_name_sn)
			var lower: String = anim_name.to_lower()
			if lower.find("attack") >= 0 and lower.find("slam") < 0 and lower.find("spell") < 0:
				if _is_playable_animation(anim_name):
					_attack_anims.append(anim_name)
					if _attack_anims.size() >= 3:
						break
				elif anim_name not in fallback_attack_candidates:
					fallback_attack_candidates.append(anim_name)
		if _attack_anims.is_empty():
			for anim_name_sn in anim_list:
				var anim_name: String = String(anim_name_sn)
				if anim_name.to_lower().find("attack") >= 0:
					if _is_playable_animation(anim_name):
						_attack_anims.append(anim_name)
					elif not fallback_attack_candidates.is_empty():
						_attack_anims.append(String(fallback_attack_candidates[0]))
					else:
						_attack_anims.append(anim_name)
					break


func _fallback_walk_animation() -> String:
	if _animation_player == null:
		return ""
	var anim_list: PackedStringArray = _animation_player.get_animation_list()
	for anim_name_sn in anim_list:
		var anim_name: String = String(anim_name_sn)
		var lower: String = anim_name.to_lower()
		if anim_name == _resolved_idle_animation or anim_name == _resolved_death_animation:
			continue
		if lower.find("attack") >= 0 or lower.find("spell") >= 0 or lower.find("slam") >= 0:
			continue
		if (
			lower.find("death") >= 0
			or lower.find("die") >= 0
			or lower.find("stand") >= 0
			or lower.find("idle") >= 0
		):
			continue
		if not _is_playable_animation(anim_name):
			continue
		return anim_name
	return ""


func _play_idle_animation() -> void:
	if _animation_player == null or _resolved_idle_animation == "":
		return
	if (
		_animation_player.is_playing()
		and _animation_player.current_animation == _resolved_idle_animation
	):
		return
	var anim := _animation_player.get_animation(_resolved_idle_animation)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(_resolved_idle_animation, -1.0, 1.0, false)


func _play_walk_animation() -> void:
	if _animation_player == null or _resolved_walk_animation == "":
		return
	if (
		_animation_player.is_playing()
		and _animation_player.current_animation == _resolved_walk_animation
	):
		return
	var anim := _animation_player.get_animation(_resolved_walk_animation)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(_resolved_walk_animation, -1.0, 1.0, false)


func _look_at_target(target_pos: Vector3) -> void:
	var direction := target_pos - global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		rotation.y = atan2(direction.x, direction.z) - PI / 2.0


func _face_toward(target_pos: Vector3) -> void:
	var direction := target_pos - global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		rotation.y = atan2(direction.x, direction.z) - PI / 2.0


func _distance_xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()


func _reset_dynamic_detour_runtime() -> void:
	_dynamic_detour_time_left = 0.0
	_dynamic_blocked_time = 0.0


func _get_network_session_controller() -> NetSessionController:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("net_session_controller") as NetSessionController


func _get_remote_target_peer_id(target: Node3D) -> int:
	if target == null or not is_instance_valid(target):
		return 0
	if not target.has_meta("network_peer_id"):
		return 0
	var peer_variant: Variant = target.get_meta("network_peer_id")
	if peer_variant is int:
		return int(peer_variant)
	if peer_variant is String and String(peer_variant).is_valid_int():
		return int(String(peer_variant).to_int())
	return 0


func _get_attack_speed_scale() -> float:
	return maxf(attack_speed, 0.05)


func _compute_attack_damage() -> int:
	var safe_damage: int = maxi(damage_per_hit, 0)
	if safe_damage <= 0:
		return 0
	var crit_chance: float = clampf(critical_chance_percent, 0.0, 100.0)
	if crit_chance > 0.0 and randf() * 100.0 < crit_chance:
		return maxi(int(round(float(safe_damage) * maxf(critical_multiplier, 1.0))), 1)
	return safe_damage


func _get_attack_interval() -> float:
	return 1.0 / _get_attack_speed_scale()


func _push_network_control_command(command_type: String, extra: Dictionary = {}) -> void:
	var normalized_type: String = command_type.strip_edges().to_lower()
	if normalized_type.is_empty():
		normalized_type = "idle"
	_network_command_seq += 1
	var payload: Dictionary = {
		"seq": _network_command_seq, "type": normalized_type, "t_ms": Time.get_ticks_msec()
	}
	payload["target_pos"] = global_position
	for key_variant in extra.keys():
		payload[key_variant] = extra[key_variant]
	_network_last_command = payload


func get_network_command_state() -> Dictionary:
	if _network_last_command.is_empty():
		return {}
	return _network_last_command.duplicate(true)


func _create_hp_bar() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nuniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat bw = 0.04;\n\tfloat bh = 0.12;\n\tif (uv.x < bw || uv.x > 1.0 - bw || uv.y < bh || uv.y > 1.0 - bh) {\n\t\tALBEDO = vec3(0.0);\n\t\tALPHA = 0.9;\n\t} else {\n\t\tfloat ix = (uv.x - bw) / (1.0 - 2.0 * bw);\n\t\tif (ix <= hp_ratio) {\n\t\t\tALBEDO = vec3(1.0 - hp_ratio, hp_ratio, 0.0);\n\t\t\tALPHA = 0.9;\n\t\t} else {\n\t\t\tALBEDO = vec3(0.15);\n\t\t\tALPHA = 0.5;\n\t\t}\n\t}\n}\n"
	_hp_bar_material = ShaderMaterial.new()
	_hp_bar_material.shader = shader
	_hp_bar_material.set_shader_parameter("hp_ratio", 1.0)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(hp_bar_width, 20.0)
	_hp_bar = MeshInstance3D.new()
	_hp_bar.mesh = mesh
	_hp_bar.material_override = _hp_bar_material
	_hp_bar.top_level = true
	_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	add_child(_hp_bar)
	_sync_hp_bar_follow_and_facing()
	call_deferred("_refresh_hp_bar_anchor_height_and_position")


func _update_hp_bar() -> void:
	if _hp_bar_material == null:
		return
	if max_hp <= 0:
		_hp_bar_material.set_shader_parameter("hp_ratio", 0.0)
		return
	_hp_bar_material.set_shader_parameter("hp_ratio", float(_current_hp) / float(max_hp))


func _resolve_hp_bar_anchor_height() -> float:
	var model_root: Node3D = _model
	if model_root == null or not is_instance_valid(model_root):
		model_root = self
	var model_height: float = _compute_node_mesh_height(model_root)
	if model_height > 0.0:
		return model_height + HP_BAR_HEIGHT_OFFSET
	return HP_BAR_HEIGHT_OFFSET


func _refresh_hp_bar_anchor_height_and_position() -> void:
	_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	_sync_hp_bar_follow_and_facing()


func _sync_hp_bar_follow_and_facing() -> void:
	CombatSceneUtils.sync_top_level_billboard_to_camera(
		_hp_bar, self, _hp_bar_anchor_height, get_viewport()
	)


func _compute_node_mesh_height(root_node: Node3D) -> float:
	return CombatSceneUtils.compute_node_mesh_height(root_node, [_hp_bar])


func set_network_authority(enabled: bool) -> void:
	network_authoritative = enabled
	_reset_chase_nav_throttle()
	if enabled:
		_remote_target_position = global_position
		_remote_target_yaw = rotation.y
		_remote_velocity = Vector3.ZERO
		_remote_last_receive_ms = Time.get_ticks_msec()
		_remote_has_target = true
		_reset_dynamic_detour_runtime()
		return
	velocity = Vector3.ZERO
	_is_moving = false
	_is_attacking = false
	_pending_idle_after_animation = false
	_remote_target_position = global_position
	_remote_target_yaw = rotation.y
	_remote_velocity = Vector3.ZERO
	_remote_last_receive_ms = Time.get_ticks_msec()
	_remote_has_target = true
	_reset_dynamic_detour_runtime()


func export_network_state() -> Dictionary:
	var state: Dictionary = {}
	state["id"] = name
	state["pos"] = global_position
	state["yaw"] = rotation.y
	state["hp"] = _current_hp
	state["damage_popup_seq"] = _damage_popup_sync_seq
	state["damage_popup_amount"] = _damage_popup_sync_amount
	state["damage_popup_source"] = _damage_popup_sync_source
	state["damage_popup_critical"] = _damage_popup_sync_critical
	state["incoming_damage_bonus_temp_percent"] = _incoming_damage_bonus_temporary_percent
	state["incoming_damage_bonus_permanent_percent"] = _incoming_damage_bonus_permanent_percent
	state["incoming_damage_bonus_time_left"] = _incoming_damage_bonus_time_left
	state["max_hp"] = max_hp
	state["armor"] = armor
	state["dead"] = _is_dead
	state["visible"] = visible
	state["is_moving"] = _is_moving
	state["is_attacking"] = _is_attacking
	if _animation_player != null:
		state["anim_name"] = String(_animation_player.current_animation)
		state["anim_playing"] = _animation_player.is_playing()
		state["anim_speed"] = _animation_player.speed_scale
	state["command_bus"] = get_network_command_state()
	return state


func apply_network_state(state: Dictionary) -> void:
	var pos_variant: Variant = state.get("pos", global_position)
	if pos_variant is Vector3:
		_on_remote_position_received(pos_variant)
	_on_remote_yaw_received(float(state.get("yaw", rotation.y)))

	if state.has("max_hp"):
		max_hp = maxi(int(state["max_hp"]), 1)
	if state.has("hp"):
		_current_hp = clampi(int(state["hp"]), 0, maxi(max_hp, 1))
	_apply_remote_damage_popup_sync(state)
	if state.has("incoming_damage_bonus_temp_percent"):
		_incoming_damage_bonus_temporary_percent = maxf(
			float(state["incoming_damage_bonus_temp_percent"]), 0.0
		)
	if state.has("incoming_damage_bonus_permanent_percent"):
		_incoming_damage_bonus_permanent_percent = maxf(
			float(state["incoming_damage_bonus_permanent_percent"]), 0.0
		)
	if state.has("incoming_damage_bonus_time_left"):
		_incoming_damage_bonus_time_left = maxf(
			float(state["incoming_damage_bonus_time_left"]), 0.0
		)
	if state.has("armor"):
		armor = float(state["armor"])
	if state.has("dead"):
		_is_dead = bool(state["dead"])
	if state.has("is_moving"):
		_is_moving = bool(state["is_moving"])
	if state.has("is_attacking"):
		_is_attacking = bool(state["is_attacking"])
	var command_variant: Variant = state.get("command_bus", null)
	if command_variant is Dictionary:
		_network_last_command = (command_variant as Dictionary).duplicate(true)

	var visible_target: bool = not _is_dead
	if state.has("visible"):
		visible_target = bool(state["visible"])
	visible = visible_target
	if _hp_bar != null:
		_hp_bar.visible = visible_target and not _is_dead
	_update_hp_bar()
	_apply_network_animation_state(state)


func _apply_network_animation_state(state: Dictionary) -> void:
	if _animation_player == null:
		return
	var desired_anim: String = str(state.get("anim_name", "")).strip_edges()
	var should_play: bool = bool(state.get("anim_playing", true))
	var speed_scale: float = clampf(float(state.get("anim_speed", 1.0)), 0.05, 8.0)

	if _is_dead:
		if (
			_resolved_death_animation != ""
			and _animation_player.has_animation(_resolved_death_animation)
		):
			_configure_remote_animation_loop(_resolved_death_animation)
			if String(_animation_player.current_animation) != _resolved_death_animation:
				_animation_player.play(_resolved_death_animation, -1.0, 1.0, false)
		return
	if _is_attacking:
		var fallback_attack_anim: String = ""
		if not _attack_anims.is_empty():
			fallback_attack_anim = String(_attack_anims[0])
		if fallback_attack_anim != "" and _animation_player.has_animation(fallback_attack_anim):
			_configure_remote_animation_loop(fallback_attack_anim)
			if String(_animation_player.current_animation) != fallback_attack_anim:
				_animation_player.play(
					fallback_attack_anim, -1.0, maxf(_get_attack_speed_scale(), 0.05), false
				)
			return
	if _is_moving:
		_play_walk_animation()
		return
	if desired_anim != "" and should_play and _animation_player.has_animation(desired_anim):
		_configure_remote_animation_loop(desired_anim)
		if (
			not _animation_player.is_playing()
			or String(_animation_player.current_animation) != desired_anim
		):
			_animation_player.play(desired_anim)
		_animation_player.speed_scale = speed_scale
		return
	_play_idle_animation()


func _configure_remote_animation_loop(anim_name: String) -> void:
	if _animation_player == null:
		return
	if anim_name.is_empty():
		return
	if not _animation_player.has_animation(anim_name):
		return
	var anim: Animation = _animation_player.get_animation(anim_name)
	if anim == null:
		return
	var should_loop: bool = (
		anim_name == _resolved_idle_animation or anim_name == _resolved_walk_animation
	)
	var desired_loop_mode: int = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if anim.loop_mode != desired_loop_mode:
		anim.loop_mode = desired_loop_mode


func _on_remote_position_received(incoming_pos: Vector3) -> void:
	if network_authoritative:
		global_position = incoming_pos
		return
	var now_ms: int = Time.get_ticks_msec()
	if _remote_has_target:
		var delta_sec: float = maxf(float(now_ms - _remote_last_receive_ms) * 0.001, 0.016)
		var delta_pos: Vector3 = incoming_pos - _remote_target_position
		delta_pos.y = 0.0
		_remote_velocity = delta_pos / delta_sec
	else:
		_remote_velocity = Vector3.ZERO
	_remote_target_position = incoming_pos
	_remote_last_receive_ms = now_ms
	_remote_has_target = true
	if global_position.distance_to(incoming_pos) >= maxf(remote_sync_snap_distance, 1.0):
		global_position = incoming_pos


func _on_remote_yaw_received(incoming_yaw: float) -> void:
	if network_authoritative:
		var rot: Vector3 = rotation
		rot.y = incoming_yaw
		rotation = rot
		return
	_remote_target_yaw = incoming_yaw


func _update_remote_sync_smoothing(delta: float) -> void:
	if not _remote_has_target:
		return
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0:
		return
	var now_ms: int = Time.get_ticks_msec()
	var pos_alpha: float = 1.0 - exp(-maxf(remote_sync_position_smooth_speed, 0.01) * safe_delta)
	var rot_alpha: float = 1.0 - exp(-maxf(remote_sync_rotation_smooth_speed, 0.01) * safe_delta)
	var predicted_pos: Vector3 = _remote_target_position
	var base_predict_sec: float = maxf(remote_sync_prediction_sec, 0.0)
	var max_predict_sec: float = maxf(remote_sync_prediction_max_sec, base_predict_sec)
	var timeout_sec: float = clampf(remote_sync_prediction_timeout_sec, 0.05, 2.0)
	var velocity_damping: float = maxf(remote_sync_prediction_velocity_damping, 0.01)
	if max_predict_sec > 0.0:
		var projected_vel: Vector3 = _remote_velocity
		projected_vel.y = 0.0
		var gap_sec: float = maxf(float(now_ms - _remote_last_receive_ms) * 0.001, 0.0)
		if gap_sec <= timeout_sec:
			var damping: float = exp(-velocity_damping * gap_sec)
			projected_vel *= damping
			var lead_sec: float = clampf(base_predict_sec + gap_sec, 0.0, max_predict_sec)
			predicted_pos += projected_vel * lead_sec
		else:
			_remote_velocity = Vector3.ZERO
	predicted_pos.y = _remote_target_position.y
	global_position = global_position.lerp(predicted_pos, pos_alpha)
	var next_rot: Vector3 = rotation
	next_rot.y = lerp_angle(next_rot.y, _remote_target_yaw, rot_alpha)
	rotation = next_rot
