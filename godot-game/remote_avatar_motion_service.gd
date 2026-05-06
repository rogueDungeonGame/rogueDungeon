extends RefCounted
class_name RemoteAvatarMotionService


func get_peer_latest_hero_command(peer_id: int, peer_latest_hero_command: Dictionary) -> Dictionary:
	if not peer_latest_hero_command.has(peer_id):
		return {}
	var command_variant: Variant = peer_latest_hero_command[peer_id]
	if command_variant is Dictionary:
		return (command_variant as Dictionary).duplicate(true)
	return {}


func is_remote_avatar_command_drive_active(remote_command_drive_enabled: bool, mode_raw: String, command: Dictionary) -> bool:
	if not remote_command_drive_enabled:
		return false
	var mode_text: String = mode_raw.strip_edges().to_lower()
	if mode_text != "host" and mode_text != "client":
		return false
	if command.is_empty():
		return false
	var cmd_type: String = str(command.get("type", "")).strip_edges().to_lower()
	return cmd_type == "move_to" or cmd_type == "chase_target" or cmd_type == "attack_target"


func resolve_remote_command_target_position(command: Dictionary, fallback: Vector3, target_node: Node3D, remote_avatar_target_positions: Dictionary, peer_id: int) -> Vector3:
	var target_pos: Vector3 = fallback
	if target_node != null and is_instance_valid(target_node):
		target_pos = target_node.global_position
	else:
		var target_pos_variant: Variant = command.get("target_pos", null)
		if target_pos_variant is Vector3:
			target_pos = target_pos_variant
		elif remote_avatar_target_positions.has(peer_id):
			var sync_pos_variant: Variant = remote_avatar_target_positions[peer_id]
			if sync_pos_variant is Vector3:
				target_pos = sync_pos_variant
	target_pos.y = fallback.y
	return target_pos


func resolve_peer_move_speed(peer_id: int, peer_latest_hero_state: Dictionary) -> float:
	var speed: float = 360.0
	if peer_latest_hero_state.has(peer_id):
		var state_variant: Variant = peer_latest_hero_state[peer_id]
		if state_variant is Dictionary:
			var state: Dictionary = state_variant as Dictionary
			speed = _float_from_variant(state.get("move_speed", speed), speed)
	return clampf(speed, 80.0, 1400.0)


func resolve_peer_attack_range(peer_id: int, peer_latest_hero_state: Dictionary) -> float:
	var attack_range: float = 220.0
	if peer_latest_hero_state.has(peer_id):
		var state_variant: Variant = peer_latest_hero_state[peer_id]
		if state_variant is Dictionary:
			var state: Dictionary = state_variant as Dictionary
			attack_range = _float_from_variant(state.get("attack_range", attack_range), attack_range)
	return clampf(attack_range, 80.0, 2200.0)


func apply_remote_avatar_command_correction(
		peer_id: int,
		avatar: Node3D,
		delta: float,
		remote_avatar_target_positions: Dictionary,
		remote_avatar_velocities: Dictionary,
		soft_distance: float,
		hard_distance: float,
		correction_speed: float
	) -> void:
	if not remote_avatar_target_positions.has(peer_id):
		return
	var sync_pos_variant: Variant = remote_avatar_target_positions[peer_id]
	if not (sync_pos_variant is Vector3):
		return
	var sync_pos: Vector3 = sync_pos_variant
	var delta_vec: Vector3 = sync_pos - avatar.global_position
	delta_vec.y = 0.0
	var dist: float = delta_vec.length()
	var safe_soft: float = maxf(soft_distance, 0.0)
	var safe_hard: float = maxf(hard_distance, safe_soft + 1.0)
	if dist >= safe_hard:
		avatar.global_position = sync_pos
		remote_avatar_velocities[peer_id] = Vector3.ZERO
		return
	if dist <= safe_soft:
		return
	var alpha: float = 1.0 - exp(-maxf(correction_speed, 0.01) * maxf(delta, 0.0))
	avatar.global_position = avatar.global_position.lerp(sync_pos, alpha)


func update_remote_avatar_command_drive(
		peer_id: int,
		avatar: Node3D,
		delta: float,
		rot_alpha: float,
		command: Dictionary,
		target_pos: Vector3,
		move_speed: float,
		attack_range: float,
		remote_command_drive_stop_distance: float,
		remote_command_drive_soft_correction_distance: float,
		remote_command_drive_hard_snap_distance: float,
		remote_command_drive_correction_speed: float,
		remote_command_drive_turn_speed: float,
		remote_avatar_target_positions: Dictionary,
		remote_avatar_target_yaws: Dictionary,
		remote_avatar_velocities: Dictionary
	) -> bool:
	if command.is_empty():
		return false
	var cmd_type: String = str(command.get("type", "idle")).strip_edges().to_lower()
	var current_pos: Vector3 = avatar.global_position
	var to_target: Vector3 = target_pos - current_pos
	to_target.y = 0.0
	var dist: float = to_target.length()
	var stop_distance: float = maxf(remote_command_drive_stop_distance, 2.0)
	if cmd_type == "attack_target":
		stop_distance = maxf(attack_range * 0.88, stop_distance)
	if dist > stop_distance:
		var dir: Vector3 = to_target / dist
		var max_step: float = maxf(move_speed * maxf(delta, 0.0), 0.0)
		var step: float = minf(max_step, dist - stop_distance)
		if step > 0.0:
			var next_pos: Vector3 = current_pos + dir * step
			next_pos.y = current_pos.y
			avatar.global_position = next_pos
		remote_avatar_velocities[peer_id] = Vector3(dir.x * move_speed, 0.0, dir.z * move_speed)
	else:
		remote_avatar_velocities[peer_id] = Vector3.ZERO
	var face_dir: Vector3 = target_pos - avatar.global_position
	face_dir.y = 0.0
	if face_dir.length() > 0.01:
		var desired_yaw: float = atan2(face_dir.x, face_dir.z) - PI / 2.0
		var turn_alpha: float = 1.0 - exp(-maxf(remote_command_drive_turn_speed, 0.01) * maxf(delta, 0.0))
		turn_alpha = maxf(turn_alpha, rot_alpha)
		var next_rot: Vector3 = avatar.rotation
		next_rot.y = lerp_angle(next_rot.y, desired_yaw, turn_alpha)
		avatar.rotation = next_rot
		remote_avatar_target_yaws[peer_id] = desired_yaw
	apply_remote_avatar_command_correction(
		peer_id,
		avatar,
		delta,
		remote_avatar_target_positions,
		remote_avatar_velocities,
		remote_command_drive_soft_correction_distance,
		remote_command_drive_hard_snap_distance,
		remote_command_drive_correction_speed
	)
	return true


func _float_from_variant(value: Variant, fallback: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_float():
			return text.to_float()
	return fallback
