extends Node3D

signal boss_defeated

const CombatSceneUtils := preload("res://combat_scene_utils.gd")

@export var enemy_path: NodePath = NodePath("boss_027")
@export var hero_path: NodePath = NodePath("../herowarden")
@export var hero_group_name: StringName = &"hero"
@export var move_speed: float = 280.0
@export var chase_nav_update_interval_ms: int = 300
@export var attack_range: float = 450.0
@export var engage_range_multiplier: float = 3.0
@export var max_hp: int = 750
@export_range(0.0, 100.0, 0.1) var magic_immunity_rate: float = 0.0
@export var damage_per_hit: int = 20
@export var armor: float = 0.0
@export var attack_speed: float = 0.5882353
@export var death_animation: String = "Death_GLTF"
@export var hp_bar_height: float = 200.0
@export var hp_bar_width: float = 300.0
@export var idle_animation: String = "Idle"
@export var walk_animation: String = "walk"
@export var attack_animation_1: String = "attack1"
@export var attack_animation_2: String = "attack2"
@export var attack_animation_3: String = "attack3"
@export var skill_animation: String = "Skill"
@export var skill_range_multiplier: float = 2.0
@export var skill_cast_time: float = 1.5
@export var skill_damage: int = 50
@export var skill_cooldown_time: float = 15.0
@export var skill2_animation: String = "Skill2"
@export var skill2_distance_multiplier: float = 2.5
@export var skill2_cast_time: float = 1.5
@export var skill2_damage: int = 50
@export var skill2_cooldown_time: float = 10.0
@export var skill2_hit_range: float = 150.0
@export var skill2_slow_percent: float = 50.0
@export var skill2_slow_duration: float = 1.5
@export var network_authoritative: bool = true
@export var remote_sync_position_smooth_speed: float = 12.0
@export var remote_sync_rotation_smooth_speed: float = 10.0
@export var remote_sync_snap_distance: float = 320.0
@export var remote_sync_prediction_sec: float = 0.10
@export var remote_sync_prediction_max_sec: float = 0.45
@export var remote_sync_prediction_timeout_sec: float = 1.0
@export var remote_sync_prediction_velocity_damping: float = 4.0
@export var tauren_spawner_path: NodePath = NodePath("../TaurenSpawner")
@export var hp_phase_count: int = 5
@export var phase_wave_unit_count: int = 8
@export var phase_spawn_follow_boss: bool = false
@export var attack_action_priority: int = 3
@export var skill_action_priority: int = 8
@export var skill2_action_priority: int = 10
@export var knockback_action_priority: int = 5

var _enemy: Node3D
var _hero: Node3D
var _animation_player: AnimationPlayer
var _is_moving: bool = false
var _is_attacking: bool = false
var _attack_cooldown: float = 0.0
var _current_attack_index: int = 0
var _attack_animations: Array[String] = []
var _stop_attack_combo_after_current: bool = false
var _engage_initialized: bool = false
var _was_in_engage_range: bool = false
var _is_engaged: bool = false
var _current_hp: int = 0
var _is_dead: bool = false
var _hp_bar: MeshInstance3D
var _hp_bar_material: ShaderMaterial
var _hp_bar_anchor_height: float = 0.0
var _death_finalized: bool = false
var _nav_agent: NavigationAgent3D
var _is_casting_skill: bool = false
var _skill_cast_timer: float = 0.0
var _skill_cooldown: float = 0.0
var _skill_warning: MeshInstance3D = null
var _engage_timer: float = 0.0
var _chase_timer: float = 0.0
var _target_lock_active: bool = false
var _is_casting_skill2: bool = false
var _skill2_timer: float = 0.0
var _skill2_cooldown: float = 0.0
var _skill2_start_pos: Vector3
var _skill2_end_pos: Vector3
var _skill2_total_time: float = 0.0
var _skill2_hit_applied: bool = false
var _skill2_hit_targets: Dictionary = {}
var _pending_idle_after_animation: bool = false
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_yaw: float = 0.0
var _remote_velocity: Vector3 = Vector3.ZERO
var _remote_last_receive_ms: int = 0
var _remote_has_target: bool = false
var _network_command_seq: int = 0
var _network_last_command: Dictionary = {}
var _current_hp_phase: int = 1
var _knockback_tween: Tween
var _knockback_active: bool = false
var _last_chase_nav_update_ms: int = -1
var _base_progression_stats: Dictionary = {}
var _spawn_origin: Vector3 = Vector3.ZERO
var _spawn_yaw: float = 0.0
var _damage_popup_sync_seq: int = 0
var _damage_popup_sync_amount: int = 0
var _damage_popup_sync_source: String = "basic_attack"
var _damage_popup_sync_critical: bool = false
var _last_applied_damage_popup_sync_seq: int = 0
var _damage_popup_sync_initialized: bool = false
var _incoming_damage_bonus_temporary_percent: float = 0.0
var _incoming_damage_bonus_permanent_percent: float = 0.0
var _incoming_damage_bonus_time_left: float = 0.0
const OBSTACLE_RAY_MASK: int = 1 << 0
const OBSTACLE_STEER_ANGLES := [20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 80.0, -80.0, 100.0, -100.0]
const HP_BAR_HEIGHT_OFFSET: float = 200.0


func _ready() -> void:
	_enemy = get_node_or_null(enemy_path) as Node3D
	if _enemy == null:
		push_warning("enemy_path 未指向有效的 Node3D。")
		set_process(false)
		return

	_hero = get_node_or_null(hero_path) as Node3D
	if _hero == null:
		_hero = _find_nearest_hero()

	var initial_rotation := _enemy.rotation
	initial_rotation.z = 0.0
	_enemy.rotation = initial_rotation

	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 20.0
	_nav_agent.target_desired_distance = 20.0
	_enemy.add_child(_nav_agent)

	_animation_player = _enemy.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		push_warning("未在小怪中找到 AnimationPlayer 节点。")
	elif not _animation_player.animation_finished.is_connected(_on_attack_finished):
		_animation_player.animation_finished.connect(_on_attack_finished)

	var raw := [attack_animation_1, attack_animation_2, attack_animation_3].filter(
		func(a): return a != ""
	)
	_attack_animations.clear()
	for a in raw:
		_attack_animations.append(a)
	_current_hp = max_hp
	_current_hp_phase = _resolve_hp_phase(_current_hp)
	_cache_base_progression_stats()
	_spawn_origin = _enemy.global_position
	_spawn_yaw = _enemy.rotation.y
	_remote_target_position = _enemy.global_position
	_remote_target_yaw = _enemy.rotation.y
	_remote_last_receive_ms = Time.get_ticks_msec()
	_remote_has_target = true
	_create_hp_bar()
	_update_hp_bar()
	_play_idle_animation()
	_push_network_control_command("idle", {"target_pos": _enemy.global_position})


func _play_idle_animation() -> void:
	if _animation_player != null and _animation_player.has_animation(idle_animation):
		var anim = _animation_player.get_animation(idle_animation)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR
		_animation_player.play(idle_animation)


func _process(delta: float) -> void:
	_sync_hp_bar_follow_and_facing()
	if _enemy == null or _is_dead:
		return
	if _knockback_active:
		if network_authoritative:
			return
		return
	if not network_authoritative:
		_update_remote_sync_smoothing(delta)
		return
	_update_incoming_damage_bonus_runtime(delta)

	if _hero == null or not is_instance_valid(_hero) or _is_hero_dead(_hero) or not _hero.visible:
		_hero = _find_nearest_hero()
		_target_lock_active = false
	elif not _target_lock_active and not _is_casting_skill and not _is_casting_skill2:
		var nearest := _find_nearest_hero()
		if nearest != null:
			_hero = nearest

	if _hero == null:
		_reset_chase_nav_throttle()
		_is_engaged = false
		_target_lock_active = false
		_engage_timer = 0.0
		_chase_timer = 0.0
		if _is_attacking or _is_casting_skill or _is_casting_skill2:
			_is_attacking = false
			_is_casting_skill = false
			_is_casting_skill2 = false
			_hide_skill_warning()
			_queue_idle_after_current_animation()
			_push_network_control_command("idle")
			return
		if _is_moving:
			_is_moving = false
			_stop_animation()
			_push_network_control_command("idle")
		return

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _skill_cooldown > 0.0:
		_skill_cooldown -= delta
	if _skill2_cooldown > 0.0:
		_skill2_cooldown -= delta

	if _is_casting_skill2:
		_skill2_timer += delta
		var progress := clampf(_skill2_timer / _skill2_total_time, 0.0, 1.0)
		_enemy.global_position = _skill2_start_pos.lerp(_skill2_end_pos, progress)
		_apply_skill2_hit_to_heroes_in_range()
		if _skill2_timer >= _skill2_total_time:
			_finish_skill2()
		return

	if _is_casting_skill:
		_skill_cast_timer -= delta
		if _hero != null and is_instance_valid(_hero):
			_face_toward(_hero.global_position)
		if _skill_warning != null:
			_skill_warning.position = Vector3(
				_enemy.global_position.x, 1.0, _enemy.global_position.z
			)
		if _skill_cast_timer <= 0.0:
			_finish_skill()
		return

	if _is_attacking:
		if (
			_hero == null
			or not is_instance_valid(_hero)
			or not _hero.visible
			or _is_hero_dead(_hero)
		):
			_is_attacking = false
			_current_attack_index = 0
			_hero = null
			_is_engaged = false
			_target_lock_active = false
			_queue_idle_after_current_animation()
			return

		_face_toward(_hero.global_position)

		var attack_distance := _distance_xz(_enemy.global_position, _hero.global_position)
		if attack_distance > attack_range:
			_interrupt_attack_for_chase()

		return

	var enemy_pos := _enemy.global_position
	var hero_pos := _hero.global_position
	var distance := _distance_xz(enemy_pos, hero_pos)
	var engage_range := attack_range * engage_range_multiplier
	var in_engage_range := distance <= engage_range

	if not _engage_initialized:
		_engage_initialized = true
		return

	if not _is_engaged:
		if in_engage_range:
			_is_engaged = true
			_target_lock_active = true
			_chase_timer = 0.0

	if not _is_engaged:
		_engage_timer = 0.0
		_reset_chase_nav_throttle()
		if _is_moving:
			_is_moving = false
			_stop_animation()
			_push_network_control_command("idle")
		return

	if distance <= attack_range:
		_chase_timer = 0.0
	else:
		_chase_timer += delta

	_engage_timer += delta

	if _engage_timer >= 1.0 and _skill2_cooldown <= 0.0 and distance <= engage_range:
		if _is_moving:
			_is_moving = false
		_start_skill2()
		return

	var skill_range := attack_range * skill_range_multiplier

	if _engage_timer >= 1.0 and _skill_cooldown <= 0.0 and distance <= skill_range:
		if _is_moving:
			_is_moving = false
		_face_toward(hero_pos)
		_start_skill()
		return

	if distance <= attack_range:
		_reset_chase_nav_throttle()
		if _is_moving:
			_is_moving = false
			_stop_animation()

		_face_toward(hero_pos)

		if _attack_cooldown <= 0.0:
			_start_attack()
		return

	if distance > engage_range and not _target_lock_active:
		_reset_chase_nav_throttle()
		if _is_moving:
			_is_moving = false
			_stop_animation()
			_push_network_control_command("idle")
		return

	_update_chase_nav_target_throttled(hero_pos)
	var move_target := hero_pos
	if not _nav_agent.is_navigation_finished():
		var next_nav := _nav_agent.get_next_path_position()
		if _distance_xz(next_nav, enemy_pos) > 1.0:
			move_target = next_nav
	var next := _compute_next_move_with_obstacle_avoidance(
		enemy_pos, move_target, move_speed * delta
	)
	next.y = enemy_pos.y
	_enemy.global_position = next
	_look_at_target(move_target)

	if not _is_moving:
		_is_moving = true
		_play_walk_animation()
		if _hero != null and is_instance_valid(_hero):
			_push_network_control_command(
				"chase_target",
				{"target_path": str(_hero.get_path()), "target_pos": _hero.global_position}
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


func _look_at_target(target_pos: Vector3) -> void:
	var direction = target_pos - _enemy.global_position
	direction.y = 0
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		_enemy.rotation.y = target_rotation - PI / 2.0


func _face_toward(target_pos: Vector3) -> void:
	var direction = target_pos - _enemy.global_position
	direction.y = 0
	if direction.length() > 0.01:
		_enemy.rotation.y = atan2(direction.x, direction.z) - PI / 2.0


func _start_attack() -> void:
	if _animation_player == null:
		return

	if _hero != null and is_instance_valid(_hero) and not _is_hero_dead(_hero):
		_face_toward(_hero.global_position)
	_is_attacking = true
	_stop_attack_combo_after_current = false
	_attack_cooldown = _get_attack_interval()
	_current_attack_index = 0
	if _hero != null and is_instance_valid(_hero):
		_push_network_control_command(
			"attack_target",
			{"target_path": str(_hero.get_path()), "target_pos": _hero.global_position}
		)

	if not _animation_player.animation_finished.is_connected(_on_attack_finished):
		_animation_player.animation_finished.connect(_on_attack_finished)

	_play_current_attack_animation()


func _play_current_attack_animation() -> void:
	if _animation_player == null:
		return

	if _hero != null and is_instance_valid(_hero) and not _is_hero_dead(_hero):
		_face_toward(_hero.global_position)
	if _current_attack_index >= _attack_animations.size():
		return

	var anim_name = _attack_animations[_current_attack_index]

	if not _animation_player.has_animation(anim_name):
		push_warning("未找到攻击动画: " + anim_name)
		_current_attack_index += 1
		if _current_attack_index < _attack_animations.size():
			_play_current_attack_animation()
		else:
			_is_attacking = false
		return

	var anim = _animation_player.get_animation(anim_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE

	_animation_player.play(anim_name, -1.0, _get_attack_speed_scale(), false)
	_try_apply_damage_to_hero()


func _play_walk_animation() -> void:
	if _animation_player != null and _animation_player.has_animation(walk_animation):
		if (
			not _animation_player.is_playing()
			or _animation_player.current_animation != walk_animation
		):
			_animation_player.play(walk_animation, -1, 1.0, false)
			var anim = _animation_player.get_animation(walk_animation)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR


func _on_attack_finished(_anim_name: StringName) -> void:
	if _is_attacking:
		if _stop_attack_combo_after_current:
			_stop_attack_combo_after_current = false
			_is_attacking = false
			_current_attack_index = 0
		else:
			_current_attack_index += 1
			if _current_attack_index < _attack_animations.size():
				_play_current_attack_animation()
			else:
				_is_attacking = false
				_current_attack_index = 0
	if _pending_idle_after_animation:
		_pending_idle_after_animation = false
		_resolve_target_after_attack_end()
		return
	if not _is_attacking and not _is_moving and not _is_casting_skill and not _is_casting_skill2:
		if (
			_hero == null
			or not is_instance_valid(_hero)
			or _is_hero_dead(_hero)
			or not _hero.visible
		):
			_resolve_target_after_attack_end()


func _stop_animation() -> void:
	if _animation_player == null:
		return
	_animation_player.stop()
	_play_idle_animation()


func _queue_idle_after_current_animation() -> void:
	if _animation_player == null:
		_play_idle_animation()
		return
	if not _animation_player.is_playing():
		_play_idle_animation()
		return
	var current_anim_name: StringName = _animation_player.current_animation
	if current_anim_name == StringName(idle_animation):
		return
	if current_anim_name == StringName(walk_animation):
		_play_idle_animation()
		return
	var current_anim: Animation = _animation_player.get_animation(current_anim_name)
	if current_anim != null and current_anim.loop_mode == Animation.LOOP_NONE:
		_pending_idle_after_animation = true
		return
	_play_idle_animation()


func _distance_xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()


func _is_obstacle_collider(collider: Node) -> bool:
	return CombatSceneUtils.is_obstacle_collider(collider)


func _is_move_segment_blocked(
	from_pos: Vector3, to_pos: Vector3, probe_half_width: float, probe_height: float
) -> bool:
	return CombatSceneUtils.is_move_segment_blocked(
		get_world_3d(), from_pos, to_pos, probe_half_width, probe_height, OBSTACLE_RAY_MASK
	)


func _compute_next_move_with_obstacle_avoidance(
	current: Vector3, move_target: Vector3, max_step: float
) -> Vector3:
	var to_target: Vector3 = move_target - current
	to_target.y = 0.0
	if to_target.length() <= 0.01 or max_step <= 0.0:
		return current

	var step: float = minf(max_step, to_target.length())
	var forward_dir: Vector3 = to_target.normalized()
	var direct_next: Vector3 = current + forward_dir * step
	if not _is_move_segment_blocked(current, direct_next, 50.0, 42.0):
		return direct_next

	var best_next: Vector3 = current
	var best_score: float = -INF
	for angle_deg in OBSTACLE_STEER_ANGLES:
		var steer_dir: Vector3 = forward_dir.rotated(Vector3.UP, deg_to_rad(angle_deg))
		var candidate_next: Vector3 = current + steer_dir * step
		if _is_move_segment_blocked(current, candidate_next, 50.0, 42.0):
			continue
		var remain: Vector3 = move_target - candidate_next
		remain.y = 0.0
		var score: float = -remain.length()
		if score > best_score:
			best_score = score
			best_next = candidate_next
	return best_next


func _find_nearest_hero(max_distance: float = INF) -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := INF

	var candidates := get_tree().get_nodes_in_group(hero_group_name)
	for candidate in candidates:
		var hero := candidate as Node3D
		if hero == null:
			continue
		if not hero.visible:
			continue
		if _is_hero_dead(hero):
			continue

		var distance := _distance_xz(_enemy.global_position, hero.global_position)
		if distance > max_distance:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = hero

	if nearest != null:
		return nearest

	var fallback := get_node_or_null(hero_path) as Node3D
	if (
		fallback != null
		and is_instance_valid(fallback)
		and fallback.visible
		and not _is_hero_dead(fallback)
	):
		var fallback_distance := _distance_xz(_enemy.global_position, fallback.global_position)
		if fallback_distance <= max_distance:
			return fallback
	return null


func _try_apply_damage_to_hero() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	if _is_hero_dead(_hero):
		return
	_face_toward(_hero.global_position)

	var distance := _distance_xz(_enemy.global_position, _hero.global_position)
	if distance > attack_range:
		return

	var hero_controller := _hero.get_parent()
	if hero_controller != null and hero_controller.has_method("apply_damage"):
		hero_controller.call("apply_damage", damage_per_hit, false, _enemy, "physical")
		if _is_hero_dead(_hero):
			_stop_attack_combo_after_current = true
			_retarget_hero_after_kill()
		return
	var target_peer_id: int = _get_remote_target_peer_id(_hero)
	if target_peer_id > 0:
		var net_ctrl: Node = _get_network_session_controller()
		if net_ctrl != null and net_ctrl.has_method("request_damage_remote_hero"):
			net_ctrl.call(
				"request_damage_remote_hero", target_peer_id, damage_per_hit, false, "physical"
			)
		if _is_hero_dead(_hero):
			_stop_attack_combo_after_current = true
			_retarget_hero_after_kill()


func _apply_skill1_damage_to_heroes_in_range() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	var skill_range: float = attack_range * skill_range_multiplier
	if skill_range <= 0.0:
		return
	var heroes: Array = get_tree().get_nodes_in_group(hero_group_name)
	for hero_node in heroes:
		var hero: Node3D = hero_node as Node3D
		if hero == null or not is_instance_valid(hero):
			continue
		if not hero.visible:
			continue
		if _is_hero_dead(hero):
			continue
		var distance: float = _distance_xz(_enemy.global_position, hero.global_position)
		if distance > skill_range:
			continue
		_apply_damage_and_optional_slow_to_hero(hero, skill_damage, 0.0, 0.0, "magic")


func _apply_skill2_hit_to_heroes_in_range() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	var fallback_radius: float = maxf(skill2_hit_range * 0.5, 1.0)
	var boss_radius: float = _get_horizontal_collision_radius(_enemy, fallback_radius)
	if boss_radius <= 0.0:
		return
	var heroes: Array = get_tree().get_nodes_in_group(hero_group_name)
	for hero_node in heroes:
		var hero: Node3D = hero_node as Node3D
		if hero == null or not is_instance_valid(hero):
			continue
		if not hero.visible:
			continue
		if _is_hero_dead(hero):
			continue
		var hit_key: String = _build_skill2_hit_key(hero)
		if _skill2_hit_targets.has(hit_key):
			continue
		var hero_radius: float = _get_horizontal_collision_radius(hero, fallback_radius)
		var overlap_distance: float = boss_radius + hero_radius
		var distance: float = _distance_xz(_enemy.global_position, hero.global_position)
		if distance > overlap_distance:
			continue
		var applied: bool = _apply_damage_and_optional_slow_to_hero(
			hero, skill2_damage, skill2_slow_percent, skill2_slow_duration, "magic"
		)
		if applied:
			_skill2_hit_targets[hit_key] = true
			_skill2_hit_applied = true


func _build_skill2_hit_key(hero: Node3D) -> String:
	var target_peer_id: int = _get_remote_target_peer_id(hero)
	if target_peer_id > 0:
		return "peer_%d" % target_peer_id
	return "inst_%d" % hero.get_instance_id()


func _get_horizontal_collision_radius(target: Node3D, fallback_radius: float) -> float:
	if target == null or not is_instance_valid(target):
		return maxf(fallback_radius, 0.0)
	var collision_shape: CollisionShape3D = (
		target.get_node_or_null("CollisionBody/CollisionShape3D") as CollisionShape3D
	)
	if collision_shape == null:
		collision_shape = target.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return maxf(fallback_radius, 0.0)
	return _shape_horizontal_radius(
		collision_shape.shape, collision_shape.global_basis.get_scale(), fallback_radius
	)


func _shape_horizontal_radius(
	shape: Shape3D, world_scale: Vector3, fallback_radius: float
) -> float:
	if shape == null:
		return maxf(fallback_radius, 0.0)
	var scale_xz: float = maxf(maxf(absf(world_scale.x), absf(world_scale.z)), 0.0001)
	if shape is CapsuleShape3D:
		return maxf((shape as CapsuleShape3D).radius * scale_xz, 0.0)
	if shape is CylinderShape3D:
		return maxf((shape as CylinderShape3D).radius * scale_xz, 0.0)
	if shape is SphereShape3D:
		return maxf((shape as SphereShape3D).radius * scale_xz, 0.0)
	if shape is BoxShape3D:
		var box_shape: BoxShape3D = shape as BoxShape3D
		var half_x: float = box_shape.size.x * absf(world_scale.x) * 0.5
		var half_z: float = box_shape.size.z * absf(world_scale.z) * 0.5
		return maxf(sqrt(half_x * half_x + half_z * half_z), 0.0)
	return maxf(fallback_radius, 0.0)


func _apply_damage_and_optional_slow_to_hero(
	hero: Node3D,
	damage: int,
	slow_percent: float,
	slow_duration: float,
	damage_type: String = "physical"
) -> bool:
	if hero == null or not is_instance_valid(hero):
		return false
	if _is_hero_dead(hero):
		return false
	var dealt: bool = false
	var hero_controller: Node = hero.get_parent()
	if hero_controller != null and hero_controller.has_method("apply_damage"):
		hero_controller.call("apply_damage", maxi(damage, 0), false, _enemy, damage_type)
		dealt = true
		if (
			slow_percent > 0.0
			and slow_duration > 0.0
			and hero_controller.has_method("apply_temporary_slow")
		):
			hero_controller.call("apply_temporary_slow", slow_percent, slow_duration)
		return true
	var target_peer_id: int = _get_remote_target_peer_id(hero)
	if target_peer_id <= 0:
		return dealt
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl == null:
		return dealt
	if net_ctrl.has_method("request_damage_remote_hero"):
		net_ctrl.call(
			"request_damage_remote_hero", target_peer_id, maxi(damage, 0), false, damage_type
		)
		dealt = true
	if (
		slow_percent > 0.0
		and slow_duration > 0.0
		and net_ctrl.has_method("request_slow_remote_hero")
	):
		net_ctrl.call("request_slow_remote_hero", target_peer_id, slow_percent, slow_duration)
	return dealt


func _retarget_hero_after_kill() -> void:
	var engage_range: float = attack_range * engage_range_multiplier
	_hero = _find_nearest_hero(engage_range)
	_target_lock_active = _hero != null
	if _hero != null:
		_is_engaged = true
		_chase_timer = 0.0
	else:
		_is_engaged = false
		_engage_timer = 0.0
		_chase_timer = 0.0


func _resolve_target_after_attack_end() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	var engage_range: float = attack_range * engage_range_multiplier
	if _hero == null or not is_instance_valid(_hero) or _is_hero_dead(_hero) or not _hero.visible:
		_hero = _find_nearest_hero(engage_range)
	_target_lock_active = _hero != null
	if _hero == null:
		_is_engaged = false
		_engage_timer = 0.0
		_chase_timer = 0.0
		_reset_chase_nav_throttle()
		_is_moving = false
		_play_idle_animation()
		_push_network_control_command("idle")
		return
	var hero_pos: Vector3 = _hero.global_position
	var enemy_pos: Vector3 = _enemy.global_position
	var distance: float = _distance_xz(enemy_pos, hero_pos)
	if distance > engage_range:
		_hero = null
		_is_engaged = false
		_target_lock_active = false
		_engage_timer = 0.0
		_chase_timer = 0.0
		_reset_chase_nav_throttle()
		_is_moving = false
		_play_idle_animation()
		_push_network_control_command("idle")
		return
	_is_engaged = true
	_target_lock_active = true
	_chase_timer = 0.0
	_face_toward(hero_pos)
	if distance > attack_range:
		_update_chase_nav_target_throttled(hero_pos, true)
		_is_moving = true
		_play_walk_animation()
		_push_network_control_command(
			"chase_target",
			{"target_path": str(_hero.get_path()), "target_pos": _hero.global_position}
		)
		return
	_reset_chase_nav_throttle()
	_is_moving = false
	_play_idle_animation()
	_push_network_control_command("idle")


func apply_damage(
	amount: int,
	attacker: Node3D = null,
	damage_source: String = "basic_attack",
	hit_context: Dictionary = {}
) -> void:
	if _is_dead:
		return
	var incoming: int = maxi(amount, 0)
	var final_damage: int = incoming
	if final_damage > 0 and _is_magic_damage_source(damage_source):
		final_damage = maxi(int(round(float(incoming) * _get_magic_damage_multiplier())), 0)
	elif final_damage > 0:
		final_damage = maxi(int(round(float(incoming) * _get_physical_damage_multiplier())), 0)
	_current_hp = max(_current_hp - final_damage, 0)
	_handle_hp_phase_spawn()
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
	if _enemy == null or not is_instance_valid(_enemy):
		return
	if _hp_bar_anchor_height <= 0.0:
		_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	CombatSceneUtils.spawn_damage_popup(
		_enemy, amount, _hp_bar_anchor_height, _is_magic_damage_source(damage_source), is_critical
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
	if _enemy == null or not is_instance_valid(_enemy):
		return false
	var safe_distance: float = clampf(distance, 0.0, 320.0)
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
	var from_pos: Vector3 = _enemy.global_position
	var to_pos: Vector3 = from_pos + planar_dir.normalized() * safe_distance
	to_pos.y = from_pos.y
	if _knockback_tween != null and _knockback_tween.is_valid():
		_knockback_tween.kill()
	_knockback_active = true
	_is_moving = false
	_reset_chase_nav_throttle()
	_is_attacking = false
	_stop_attack_combo_after_current = false
	_is_casting_skill = false
	_is_casting_skill2 = false
	_pending_idle_after_animation = false
	_hide_skill_warning()
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()
	_knockback_tween = create_tween()
	_knockback_tween.set_trans(Tween.TRANS_LINEAR)
	_knockback_tween.set_ease(Tween.EASE_IN_OUT)
	_knockback_tween.tween_property(_enemy, "global_position", to_pos, safe_duration)
	_knockback_tween.finished.connect(
		func() -> void:
			_knockback_active = false
			_knockback_tween = null
			if _nav_agent != null:
				_nav_agent.target_position = _enemy.global_position
	)
	return true


func _get_current_action_priority() -> int:
	var priority: int = 0
	if _is_casting_skill2:
		priority = maxi(priority, skill2_action_priority)
	elif _is_casting_skill:
		priority = maxi(priority, skill_action_priority)
	elif _is_attacking:
		priority = maxi(priority, attack_action_priority)
	if _knockback_active:
		priority = maxi(priority, knockback_action_priority)
	return priority


func _retarget_to_attacker(attacker: Node3D) -> void:
	# 仅在当前没有有效攻击目标时，才根据受击来源切换追击对象。
	if _hero != null and is_instance_valid(_hero) and not _is_hero_dead(_hero) and _hero.visible:
		return
	if attacker == null or not is_instance_valid(attacker):
		return
	if _is_hero_dead(attacker):
		return
	_hero = attacker
	_reset_chase_nav_throttle()
	_is_engaged = true
	_target_lock_active = true
	_engage_initialized = true
	_engage_timer = 0.0
	_chase_timer = 0.0
	if _is_casting_skill or _is_casting_skill2:
		_is_casting_skill = false
		_is_casting_skill2 = false
		_skill_cast_timer = 0.0
		_skill2_timer = 0.0
		_skill2_hit_applied = false
		_skill2_hit_targets.clear()
		_hide_skill_warning()
	if _is_attacking:
		_interrupt_attack_for_chase()
	_face_toward(attacker.global_position)
	_push_network_control_command(
		"chase_target",
		{"target_path": str(attacker.get_path()), "target_pos": attacker.global_position}
	)


func is_dead() -> bool:
	return _is_dead


func _die() -> void:
	if _is_dead:
		return

	_is_dead = true
	emit_signal("boss_defeated")
	if _knockback_tween != null and _knockback_tween.is_valid():
		_knockback_tween.kill()
	_knockback_tween = null
	_knockback_active = false
	_is_attacking = false
	_stop_attack_combo_after_current = false
	_pending_idle_after_animation = false
	_is_moving = false
	_reset_chase_nav_throttle()
	_is_engaged = false
	_target_lock_active = false
	_is_casting_skill = false
	_is_casting_skill2 = false
	_hero = null
	_hide_skill_warning()
	_push_network_control_command("dead")

	if _animation_player != null:
		_animation_player.stop()
		if _animation_player.has_animation(death_animation):
			var anim = _animation_player.get_animation(death_animation)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
			_animation_player.play(death_animation, -1.0, 1.5, false)
			var death_duration := 0.1
			if anim != null:
				death_duration = maxf(anim.length / 1.5, 0.1)
			_schedule_finalize_death(death_duration)
		else:
			_animation_player.stop()
			_finalize_death()
	else:
		_finalize_death()


func _create_hp_bar() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nuniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat bw = 0.04;\n\tfloat bh = 0.12;\n\tif (uv.x < bw || uv.x > 1.0 - bw || uv.y < bh || uv.y > 1.0 - bh) {\n\t\tALBEDO = vec3(0.0);\n\t\tALPHA = 0.9;\n\t} else {\n\t\tfloat ix = (uv.x - bw) / (1.0 - 2.0 * bw);\n\t\tif (ix <= hp_ratio) {\n\t\t\tALBEDO = vec3(1.0 - hp_ratio, hp_ratio, 0.0);\n\t\t\tALPHA = 0.9;\n\t\t} else {\n\t\t\tALBEDO = vec3(0.15);\n\t\t\tALPHA = 0.5;\n\t\t}\n\t}\n}\n"
	_hp_bar_material = ShaderMaterial.new()
	_hp_bar_material.shader = shader
	_hp_bar_material.set_shader_parameter("hp_ratio", 1.0)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(hp_bar_width, 25.5)
	_hp_bar = MeshInstance3D.new()
	_hp_bar.mesh = mesh
	_hp_bar.material_override = _hp_bar_material
	_hp_bar.top_level = true
	_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	_enemy.add_child(_hp_bar)
	_sync_hp_bar_follow_and_facing()
	call_deferred("_refresh_hp_bar_anchor_height_and_position")


func _update_hp_bar() -> void:
	if _hp_bar_material == null:
		return
	_hp_bar_material.set_shader_parameter("hp_ratio", float(_current_hp) / float(max_hp))


func _resolve_hp_bar_anchor_height() -> float:
	var model_height_local: float = _compute_node_mesh_height(_enemy)
	if model_height_local > 0.0:
		var world_scale_y: float = 1.0
		if _enemy != null and is_instance_valid(_enemy):
			world_scale_y = maxf(_enemy.global_basis.y.length(), 0.0001)
		var model_height_world: float = model_height_local * world_scale_y
		return model_height_world + HP_BAR_HEIGHT_OFFSET
	return HP_BAR_HEIGHT_OFFSET


func _refresh_hp_bar_anchor_height_and_position() -> void:
	_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	_sync_hp_bar_follow_and_facing()


func _sync_hp_bar_follow_and_facing() -> void:
	CombatSceneUtils.sync_top_level_billboard_to_camera(
		_hp_bar, _enemy, _hp_bar_anchor_height, get_viewport()
	)


func _compute_node_mesh_height(root_node: Node3D) -> float:
	return CombatSceneUtils.compute_node_mesh_height(root_node, [_hp_bar])


func _is_hero_dead(hero: Node3D) -> bool:
	if hero == null or not is_instance_valid(hero):
		return true
	if not hero.visible:
		return true
	var hero_controller := hero.get_parent()
	if hero_controller != null and hero_controller.has_method("is_dead"):
		return bool(hero_controller.call("is_dead"))
	var peer_id: int = _get_remote_target_peer_id(hero)
	if peer_id > 0:
		var net_ctrl: Node = _get_network_session_controller()
		if net_ctrl != null and net_ctrl.has_method("get_ui_peer_hero_state"):
			var state_variant: Variant = net_ctrl.call("get_ui_peer_hero_state", peer_id)
			if state_variant is Dictionary:
				var state: Dictionary = state_variant as Dictionary
				if bool(state.get("is_dead", false)):
					return true
				if int(state.get("hp", 1)) <= 0:
					return true
	return false


func _get_network_session_controller() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("net_session_controller")


func _get_tauren_spawner() -> Node:
	return get_node_or_null(tauren_spawner_path)


func _handle_hp_phase_spawn() -> void:
	var max_phase: int = maxi(hp_phase_count, 1)
	_current_hp_phase = clampi(_current_hp_phase, 1, max_phase)
	if phase_wave_unit_count <= 0:
		_current_hp_phase = _resolve_hp_phase(_current_hp)
		return
	if max_hp <= 0:
		return
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		_current_hp_phase = _resolve_hp_phase(_current_hp)
		return
	var next_phase: int = _resolve_hp_phase(_current_hp)
	if next_phase >= _current_hp_phase:
		return
	var wave_count: int = _current_hp_phase - next_phase
	for _i in range(wave_count):
		_spawn_phase_wave()
	_current_hp_phase = next_phase


func _resolve_hp_phase(hp_value: int) -> int:
	var max_phase: int = maxi(hp_phase_count, 1)
	var safe_max_hp: int = maxi(max_hp, 1)
	var safe_hp: int = clampi(hp_value, 0, safe_max_hp)
	if safe_hp <= 0:
		return 1
	var ratio: float = float(safe_hp) / float(safe_max_hp)
	return clampi(int(ceil(ratio * float(max_phase))), 1, max_phase)


func _spawn_phase_wave() -> void:
	var spawner: Node = _get_tauren_spawner()
	if spawner == null:
		return
	if not spawner.has_method("spawn_wave_at_position"):
		return
	var spawn_center: Vector3 = global_position
	if phase_spawn_follow_boss and _enemy != null and is_instance_valid(_enemy):
		spawn_center = _enemy.global_position
	spawner.call("spawn_wave_at_position", phase_wave_unit_count, spawn_center)


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
	if _enemy != null and is_instance_valid(_enemy):
		payload["target_pos"] = _enemy.global_position
	for key_variant in extra.keys():
		payload[key_variant] = extra[key_variant]
	_network_last_command = payload


func get_network_command_state() -> Dictionary:
	if _network_last_command.is_empty():
		return {}
	return _network_last_command.duplicate(true)


func _start_skill() -> void:
	if _animation_player == null:
		return
	var cast_duration: float = maxf(skill_cast_time, 0.05)
	if _hero != null and is_instance_valid(_hero) and not _is_hero_dead(_hero):
		_face_toward(_hero.global_position)
	_is_casting_skill = true
	_is_attacking = false
	_skill_cast_timer = cast_duration
	_push_network_control_command("cast_skill", {"skill_id": 1})
	if _animation_player.has_animation(skill_animation):
		var anim = _animation_player.get_animation(skill_animation)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
		var speed_scale := 1.0
		if anim != null and anim.length > 0.0:
			speed_scale = anim.length / cast_duration
		_animation_player.play(skill_animation, -1.0, speed_scale, false)
	_show_skill_warning()


func _finish_skill() -> void:
	_is_casting_skill = false
	_skill_cooldown = skill_cooldown_time
	_hide_skill_warning()

	_apply_skill1_damage_to_heroes_in_range()

	_stop_animation()
	_resume_target_after_skill()


func _start_skill2() -> void:
	if _animation_player == null:
		return
	if _hero != null and is_instance_valid(_hero) and not _is_hero_dead(_hero):
		_face_toward(_hero.global_position)
	_is_casting_skill2 = true
	_is_attacking = false
	_is_moving = false
	_skill2_hit_applied = false
	_skill2_hit_targets.clear()
	_skill2_timer = 0.0
	_skill2_total_time = skill2_cast_time

	_skill2_start_pos = _enemy.global_position
	var angle := _enemy.rotation.y + PI / 2.0
	var forward := Vector3(sin(angle), 0.0, cos(angle))
	if forward.length() < 0.01:
		forward = Vector3(0, 0, -1)
	var charge_distance := attack_range * skill2_distance_multiplier
	_skill2_end_pos = _skill2_start_pos + forward * charge_distance
	_skill2_end_pos.y = _skill2_start_pos.y
	_push_network_control_command("cast_skill", {"skill_id": 2, "target_pos": _skill2_end_pos})

	if _animation_player.has_animation(skill2_animation):
		var anim = _animation_player.get_animation(skill2_animation)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
		var speed_scale := 1.0
		if anim != null and anim.length > 0.0:
			speed_scale = anim.length / skill2_cast_time
		_animation_player.play(skill2_animation, -1.0, speed_scale, false)


func _finish_skill2() -> void:
	_is_casting_skill2 = false
	_skill2_cooldown = skill2_cooldown_time
	_stop_animation()
	_resume_target_after_skill()


func _resume_target_after_skill() -> void:
	if _enemy == null:
		return
	if _hero == null or not is_instance_valid(_hero) or _is_hero_dead(_hero):
		var engage_range: float = attack_range * engage_range_multiplier
		_hero = _find_nearest_hero(engage_range)
		if _hero == null:
			if _is_moving:
				_is_moving = false
			_stop_animation()
			return

	var hero_pos: Vector3 = _hero.global_position
	var enemy_pos: Vector3 = _enemy.global_position
	var distance: float = _distance_xz(enemy_pos, hero_pos)
	var engage_range: float = attack_range * engage_range_multiplier

	_is_engaged = true
	_target_lock_active = true
	_chase_timer = 0.0
	_face_toward(hero_pos)

	if distance <= attack_range:
		_reset_chase_nav_throttle()
		_is_moving = false
		if _attack_cooldown <= 0.0:
			_start_attack()
		else:
			_play_idle_animation()
	elif distance <= engage_range:
		_update_chase_nav_target_throttled(hero_pos, true)
		_is_moving = true
		_play_walk_animation()
	else:
		_reset_chase_nav_throttle()
		_is_moving = false
		_stop_animation()


func _show_skill_warning() -> void:
	if _skill_warning != null:
		return

	var skill_range := attack_range * skill_range_multiplier

	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nvoid fragment() {\n\tvec2 uv = UV * 2.0 - 1.0;\n\tfloat dist = length(uv);\n\tif (dist > 1.0) { discard; }\n\tif (dist > 0.96) {\n\t\tALBEDO = vec3(1.0, 0.0, 0.0);\n\t\tALPHA = 0.85;\n\t} else {\n\t\tALBEDO = vec3(1.0, 0.2, 0.2);\n\t\tALPHA = 0.25;\n\t}\n}\n"

	var mat := ShaderMaterial.new()
	mat.shader = shader

	var mesh := PlaneMesh.new()
	mesh.size = Vector2(skill_range * 2.0, skill_range * 2.0)

	_skill_warning = MeshInstance3D.new()
	_skill_warning.mesh = mesh
	_skill_warning.material_override = mat
	_skill_warning.position = Vector3(_enemy.global_position.x, 1.0, _enemy.global_position.z)

	get_parent().add_child(_skill_warning)


func _hide_skill_warning() -> void:
	if _skill_warning != null and is_instance_valid(_skill_warning):
		_skill_warning.get_parent().remove_child(_skill_warning)
		_skill_warning.queue_free()
	_skill_warning = null


func _interrupt_attack_for_chase() -> void:
	if not _is_attacking:
		return

	_is_attacking = false
	_stop_attack_combo_after_current = false
	_current_attack_index = 0
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()


func _schedule_finalize_death(delay_sec: float) -> void:
	var timer := get_tree().create_timer(maxf(delay_sec, 0.05))
	timer.timeout.connect(_finalize_death)


func _finalize_death() -> void:
	if _death_finalized:
		return
	_death_finalized = true

	if _hp_bar != null:
		_hp_bar.visible = false

	if _enemy != null:
		_enemy.visible = false


func set_network_authority(enabled: bool) -> void:
	network_authoritative = enabled
	_reset_chase_nav_throttle()
	if enabled:
		if _enemy != null and is_instance_valid(_enemy):
			_remote_target_position = _enemy.global_position
			_remote_target_yaw = _enemy.rotation.y
			_remote_velocity = Vector3.ZERO
			_remote_last_receive_ms = Time.get_ticks_msec()
			_remote_has_target = true
		return
	_is_moving = false
	_is_attacking = false
	_is_casting_skill = false
	_is_casting_skill2 = false
	_pending_idle_after_animation = false
	_hide_skill_warning()
	if _enemy != null and is_instance_valid(_enemy):
		_remote_target_position = _enemy.global_position
		_remote_target_yaw = _enemy.rotation.y
		_remote_velocity = Vector3.ZERO
		_remote_last_receive_ms = Time.get_ticks_msec()
		_remote_has_target = true


func _cache_base_progression_stats() -> void:
	if not _base_progression_stats.is_empty():
		return
	_base_progression_stats = {
		"move_speed": move_speed,
		"attack_range": attack_range,
		"max_hp": max_hp,
		"damage_per_hit": damage_per_hit,
		"armor": armor,
		"attack_speed": attack_speed,
		"skill_damage": skill_damage,
		"skill2_damage": skill2_damage,
		"phase_wave_unit_count": phase_wave_unit_count,
	}


func apply_floor_profile(profile: Dictionary, reset_runtime: bool = true) -> void:
	_cache_base_progression_stats()
	if profile.is_empty():
		return
	max_hp = maxi(
		int(
			round(
				(
					float(_base_progression_stats.get("max_hp", max_hp))
					* float(profile.get("boss_hp_multiplier", 1.0))
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
					* float(profile.get("boss_damage_multiplier", 1.0))
				)
			)
		),
		1
	)
	skill_damage = maxi(
		int(
			round(
				(
					float(_base_progression_stats.get("skill_damage", skill_damage))
					* float(profile.get("boss_skill_damage_multiplier", 1.0))
				)
			)
		),
		1
	)
	skill2_damage = maxi(
		int(
			round(
				(
					float(_base_progression_stats.get("skill2_damage", skill2_damage))
					* float(profile.get("boss_skill_damage_multiplier", 1.0))
				)
			)
		),
		1
	)
	armor = (
		float(_base_progression_stats.get("armor", armor))
		+ float(profile.get("boss_armor_bonus", 0.0))
	)
	phase_wave_unit_count = maxi(
		int(_base_progression_stats.get("phase_wave_unit_count", phase_wave_unit_count)), 0
	)
	if not reset_runtime:
		_current_hp = clampi(_current_hp, 0, max_hp)
		_current_hp_phase = _resolve_hp_phase(_current_hp)
		_update_hp_bar()
		return
	_reset_for_new_floor()


func reset_to_spawn_origin() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	_enemy.global_position = _spawn_origin
	var next_rotation: Vector3 = _enemy.rotation
	next_rotation.y = _spawn_yaw
	_enemy.rotation = next_rotation


func set_spawn_origin(
	world_position: Vector3, yaw: float = 0.0, move_immediately: bool = false
) -> void:
	_spawn_origin = world_position
	_spawn_yaw = yaw
	if _enemy == null or not is_instance_valid(_enemy):
		return
	if move_immediately:
		_enemy.global_position = _spawn_origin
		var next_rotation: Vector3 = _enemy.rotation
		next_rotation.y = _spawn_yaw
		_enemy.rotation = next_rotation
	_remote_target_position = _enemy.global_position
	_remote_target_yaw = _enemy.rotation.y


func _reset_for_new_floor() -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	if _knockback_tween != null and _knockback_tween.is_valid():
		_knockback_tween.kill()
	_knockback_tween = null
	_knockback_active = false
	_is_dead = false
	_death_finalized = false
	_is_moving = false
	_is_attacking = false
	_stop_attack_combo_after_current = false
	_pending_idle_after_animation = false
	_is_engaged = false
	_target_lock_active = false
	_is_casting_skill = false
	_is_casting_skill2 = false
	_attack_cooldown = 0.0
	_skill_cast_timer = 0.0
	_skill_cooldown = 0.0
	_engage_timer = 0.0
	_chase_timer = 0.0
	_skill2_timer = 0.0
	_skill2_cooldown = 0.0
	_skill2_total_time = 0.0
	_skill2_hit_applied = false
	_skill2_hit_targets.clear()
	_incoming_damage_bonus_temporary_percent = 0.0
	_incoming_damage_bonus_permanent_percent = 0.0
	_incoming_damage_bonus_time_left = 0.0
	_current_attack_index = 0
	_current_hp = max_hp
	_current_hp_phase = _resolve_hp_phase(_current_hp)
	_hero = _find_nearest_hero()
	reset_to_spawn_origin()
	_remote_target_position = _enemy.global_position
	_remote_target_yaw = _enemy.rotation.y
	_remote_velocity = Vector3.ZERO
	_remote_last_receive_ms = Time.get_ticks_msec()
	_remote_has_target = true
	_reset_chase_nav_throttle()
	_hide_skill_warning()
	_enemy.visible = true
	if _hp_bar != null:
		_hp_bar.visible = true
	_refresh_hp_bar_anchor_height_and_position()
	_update_hp_bar()
	_play_idle_animation()
	_push_network_control_command("idle", {"target_pos": _enemy.global_position})


func export_network_state() -> Dictionary:
	var state: Dictionary = {}
	if _enemy != null and is_instance_valid(_enemy):
		state["pos"] = _enemy.global_position
		state["yaw"] = _enemy.rotation.y
		state["visible"] = _enemy.visible
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
	state["is_moving"] = _is_moving
	state["is_attacking"] = _is_attacking
	state["casting_skill"] = _is_casting_skill
	state["casting_skill2"] = _is_casting_skill2
	state["attack_cooldown"] = _attack_cooldown
	state["skill_cast_left"] = _skill_cast_timer
	state["skill_cooldown"] = _skill_cooldown
	state["engage_timer"] = _engage_timer
	state["chase_timer"] = _chase_timer
	state["target_lock_active"] = _target_lock_active
	state["skill2_timer"] = _skill2_timer
	state["skill2_cooldown"] = _skill2_cooldown
	state["skill2_total_time"] = _skill2_total_time
	state["skill2_hit_applied"] = _skill2_hit_applied
	state["current_hp_phase"] = _current_hp_phase
	state["death_finalized"] = _death_finalized
	state["current_attack_index"] = _current_attack_index
	state["stop_attack_combo"] = _stop_attack_combo_after_current
	state["engage_initialized"] = _engage_initialized
	state["was_in_engage_range"] = _was_in_engage_range
	state["engaged"] = _is_engaged
	state["pending_idle_after_animation"] = _pending_idle_after_animation
	state["skill2_hit_targets"] = _skill2_hit_targets.duplicate(true)
	state["skill2_start_pos"] = _skill2_start_pos
	state["skill2_end_pos"] = _skill2_end_pos
	var warning_visible: bool = _skill_warning != null and is_instance_valid(_skill_warning)
	state["skill_warning_visible"] = warning_visible
	if warning_visible:
		state["skill_warning_pos"] = _skill_warning.global_position
	if _animation_player != null:
		state["anim_name"] = String(_animation_player.current_animation)
		state["anim_playing"] = _animation_player.is_playing()
		state["anim_speed"] = _animation_player.speed_scale
	state["command_bus"] = get_network_command_state()
	return state


func apply_network_state(state: Dictionary) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	var pos_variant: Variant = state.get("pos", _enemy.global_position)
	if pos_variant is Vector3:
		_on_remote_enemy_position_received(pos_variant)
	_on_remote_enemy_yaw_received(float(state.get("yaw", _enemy.rotation.y)))

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
	if state.has("casting_skill"):
		_is_casting_skill = bool(state["casting_skill"])
	if state.has("casting_skill2"):
		_is_casting_skill2 = bool(state["casting_skill2"])
	if state.has("attack_cooldown"):
		_attack_cooldown = clampf(float(state["attack_cooldown"]), 0.0, 120.0)
	if state.has("skill_cast_left"):
		_skill_cast_timer = clampf(float(state["skill_cast_left"]), 0.0, 120.0)
	if state.has("skill_cooldown"):
		_skill_cooldown = clampf(float(state["skill_cooldown"]), 0.0, 120.0)
	if state.has("engage_timer"):
		_engage_timer = clampf(float(state["engage_timer"]), 0.0, 120.0)
	if state.has("chase_timer"):
		_chase_timer = clampf(float(state["chase_timer"]), 0.0, 120.0)
	if state.has("target_lock_active"):
		_target_lock_active = bool(state["target_lock_active"])
	if state.has("skill2_timer"):
		_skill2_timer = clampf(float(state["skill2_timer"]), 0.0, 120.0)
	if state.has("skill2_cooldown"):
		_skill2_cooldown = clampf(float(state["skill2_cooldown"]), 0.0, 120.0)
	if state.has("skill2_total_time"):
		_skill2_total_time = clampf(float(state["skill2_total_time"]), 0.0, 120.0)
	if state.has("skill2_hit_applied"):
		_skill2_hit_applied = bool(state["skill2_hit_applied"])
	if state.has("current_hp_phase"):
		_current_hp_phase = maxi(int(state["current_hp_phase"]), 1)
	if state.has("death_finalized"):
		_death_finalized = bool(state["death_finalized"])
	if state.has("current_attack_index"):
		_current_attack_index = maxi(int(state["current_attack_index"]), 0)
	if state.has("stop_attack_combo"):
		_stop_attack_combo_after_current = bool(state["stop_attack_combo"])
	if state.has("engage_initialized"):
		_engage_initialized = bool(state["engage_initialized"])
	if state.has("was_in_engage_range"):
		_was_in_engage_range = bool(state["was_in_engage_range"])
	if state.has("engaged"):
		_is_engaged = bool(state["engaged"])
	if state.has("pending_idle_after_animation"):
		_pending_idle_after_animation = bool(state["pending_idle_after_animation"])
	var skill2_hit_targets_variant: Variant = state.get("skill2_hit_targets", null)
	if skill2_hit_targets_variant is Dictionary:
		_skill2_hit_targets = (skill2_hit_targets_variant as Dictionary).duplicate(true)
	var skill2_start_variant: Variant = state.get("skill2_start_pos", null)
	if skill2_start_variant is Vector3:
		_skill2_start_pos = skill2_start_variant
	var skill2_end_variant: Variant = state.get("skill2_end_pos", null)
	if skill2_end_variant is Vector3:
		_skill2_end_pos = skill2_end_variant
	var command_variant: Variant = state.get("command_bus", null)
	if command_variant is Dictionary:
		_network_last_command = (command_variant as Dictionary).duplicate(true)

	var visible_target: bool = not _is_dead
	if state.has("visible"):
		visible_target = bool(state["visible"])
	_enemy.visible = visible_target
	if _hp_bar != null:
		_hp_bar.visible = visible_target and not _is_dead
	var warning_visible: bool = bool(state.get("skill_warning_visible", false))
	if _is_dead:
		warning_visible = false
	if warning_visible:
		_show_skill_warning()
		var warning_pos_variant: Variant = state.get("skill_warning_pos", null)
		if warning_pos_variant is Vector3 and _skill_warning != null:
			_skill_warning.global_position = warning_pos_variant
	else:
		_hide_skill_warning()
	_update_hp_bar()
	_apply_network_animation_state(state)


func _apply_network_animation_state(state: Dictionary) -> void:
	if _animation_player == null:
		return
	var desired_anim: String = str(state.get("anim_name", "")).strip_edges()
	var should_play: bool = bool(state.get("anim_playing", true))
	var speed_scale: float = clampf(float(state.get("anim_speed", 1.0)), 0.05, 8.0)

	if _is_dead:
		if death_animation != "" and _animation_player.has_animation(death_animation):
			_configure_remote_animation_loop(death_animation)
			if String(_animation_player.current_animation) != death_animation:
				_animation_player.play(death_animation, -1.0, 1.0, false)
		return
	if (
		_is_casting_skill2
		and skill2_animation != ""
		and _animation_player.has_animation(skill2_animation)
	):
		_configure_remote_animation_loop(skill2_animation)
		if String(_animation_player.current_animation) != skill2_animation:
			_animation_player.play(skill2_animation, -1.0, 1.0, false)
		return
	if (
		_is_casting_skill
		and skill_animation != ""
		and _animation_player.has_animation(skill_animation)
	):
		_configure_remote_animation_loop(skill_animation)
		if (
			not _animation_player.is_playing()
			or String(_animation_player.current_animation) != skill_animation
		):
			_animation_player.play(skill_animation, -1.0, speed_scale, false)
		else:
			_animation_player.speed_scale = speed_scale
		return
	if _is_attacking and _attack_animations.size() > 0:
		var fallback_attack_anim: String = String(_attack_animations[0])
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
	var should_loop: bool = anim_name == idle_animation or anim_name == walk_animation
	var desired_loop_mode: int = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	if anim.loop_mode != desired_loop_mode:
		anim.loop_mode = desired_loop_mode


func _on_remote_enemy_position_received(incoming_pos: Vector3) -> void:
	if network_authoritative:
		_enemy.global_position = incoming_pos
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
	if _enemy.global_position.distance_to(incoming_pos) >= maxf(remote_sync_snap_distance, 1.0):
		_enemy.global_position = incoming_pos


func _on_remote_enemy_yaw_received(incoming_yaw: float) -> void:
	if network_authoritative:
		var rot: Vector3 = _enemy.rotation
		rot.y = incoming_yaw
		_enemy.rotation = rot
		return
	_remote_target_yaw = incoming_yaw


func _update_remote_sync_smoothing(delta: float) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
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
	_enemy.global_position = _enemy.global_position.lerp(predicted_pos, pos_alpha)
	var next_rot: Vector3 = _enemy.rotation
	next_rot.y = lerp_angle(next_rot.y, _remote_target_yaw, rot_alpha)
	_enemy.rotation = next_rot
