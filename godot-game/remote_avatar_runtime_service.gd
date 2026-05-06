extends RefCounted
class_name RemoteAvatarRuntimeService


func upsert_remote_avatar(
		peer_id: int,
		self_id: int,
		position: Vector3,
		yaw: float,
		model_key: String,
		remote_snap_distance: float,
		remote_player_scale: Vector3,
		remote_players_root: Node3D,
		remote_avatars: Dictionary,
		remote_avatar_model_keys: Dictionary,
		remote_avatar_last_anims: Dictionary,
		remote_avatar_target_positions: Dictionary,
		remote_avatar_target_yaws: Dictionary,
		resolve_scene_fn: Callable,
		disable_collisions_fn: Callable
	) -> Node3D:
	if peer_id <= 0 or peer_id == self_id:
		return null
	var avatar: Node3D = null
	if remote_avatars.has(peer_id):
		avatar = remote_avatars[peer_id] as Node3D
	var current_model_key: String = str(remote_avatar_model_keys.get(peer_id, ""))
	var needs_recreate: bool = avatar == null or not is_instance_valid(avatar)
	if not needs_recreate and current_model_key != model_key:
		avatar.queue_free()
		avatar = null
		needs_recreate = true
	if needs_recreate:
		avatar = create_remote_avatar(
			remote_players_root,
			peer_id,
			model_key,
			remote_player_scale,
			resolve_scene_fn,
			disable_collisions_fn
		)
		if avatar == null:
			return null
		remote_avatars[peer_id] = avatar
		remote_avatar_model_keys[peer_id] = model_key
		remote_avatar_last_anims.erase(peer_id)
		avatar.global_position = position
		var init_rot: Vector3 = avatar.rotation
		init_rot.x = 0.0
		init_rot.y = yaw
		init_rot.z = 0.0
		avatar.rotation = init_rot

	remote_avatar_target_positions[peer_id] = position
	remote_avatar_target_yaws[peer_id] = yaw

	if not needs_recreate and avatar != null and is_instance_valid(avatar):
		var snap_limit: float = maxf(remote_snap_distance, 1.0)
		if avatar.global_position.distance_to(position) >= snap_limit:
			avatar.global_position = position
			var snap_rot: Vector3 = avatar.rotation
			snap_rot.x = 0.0
			snap_rot.y = yaw
			snap_rot.z = 0.0
			avatar.rotation = snap_rot
	return avatar


func create_remote_avatar(
		remote_players_root: Node3D,
		peer_id: int,
		model_key: String,
		remote_player_scale: Vector3,
		resolve_scene_fn: Callable,
		disable_collisions_fn: Callable
	) -> Node3D:
	if remote_players_root == null:
		return null
	var avatar: Node3D = null
	var preferred_scene: PackedScene = resolve_scene_fn.call(model_key) as PackedScene
	if preferred_scene != null:
		var inst: Node = preferred_scene.instantiate()
		avatar = inst as Node3D
	if avatar == null:
		avatar = Node3D.new()
		var marker_mesh: MeshInstance3D = MeshInstance3D.new()
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = 24.0
		capsule.height = 80.0
		marker_mesh.mesh = capsule
		avatar.add_child(marker_mesh)

	avatar.name = "RemotePeer_%d" % peer_id
	avatar.scale = remote_player_scale
	avatar.add_to_group("hero")
	avatar.set_meta("network_peer_id", peer_id)
	remote_players_root.add_child(avatar)
	if disable_collisions_fn != null and disable_collisions_fn.is_valid():
		disable_collisions_fn.call(avatar)
	return avatar


func resolve_remote_player_scene(
		model_key: String,
		remote_player_scene: PackedScene,
		remote_melee_player_scene: PackedScene,
		remote_ranged_player_scene: PackedScene,
		remote_transformed_player_scene: PackedScene
	) -> PackedScene:
	if model_key == "transformed":
		if remote_transformed_player_scene != null:
			return remote_transformed_player_scene
		if remote_melee_player_scene != null:
			return remote_melee_player_scene
	elif model_key == "ranged":
		if remote_ranged_player_scene != null:
			return remote_ranged_player_scene
	elif model_key == "melee":
		if remote_melee_player_scene != null:
			return remote_melee_player_scene
	if remote_player_scene != null:
		return remote_player_scene
	if remote_melee_player_scene != null:
		return remote_melee_player_scene
	return null


func get_remote_model_key(hero_state: Dictionary) -> String:
	var is_transformed: bool = _bool_from_variant(hero_state.get("is_transformed", false), false)
	if is_transformed:
		return "transformed"
	var hero_id: int = _int_from_variant(hero_state.get("hero_id", 0), 0)
	if hero_id == 2:
		return "ranged"
	var profile: String = str(hero_state.get("hero_profile", "")).strip_edges().to_lower()
	if profile == "远程" or profile == "ranged" or profile.find("火枪手") >= 0:
		return "ranged"
	return "melee"


func apply_remote_avatar_animation(peer_id: int, avatar: Node3D, hero_state: Dictionary, remote_avatar_last_anims: Dictionary) -> void:
	var anim_player: AnimationPlayer = avatar.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		return
	var desired_anim: String = str(hero_state.get("anim_name", ""))
	if desired_anim.is_empty() or not anim_player.has_animation(desired_anim):
		desired_anim = pick_remote_fallback_animation(anim_player, hero_state)
	if desired_anim.is_empty():
		return

	var should_play: bool = _bool_from_variant(hero_state.get("anim_playing", true), true)
	if not should_play:
		if anim_player.is_playing():
			anim_player.stop()
		return

	var last_anim: String = str(remote_avatar_last_anims.get(peer_id, ""))
	var need_restart: bool = not anim_player.is_playing() or String(anim_player.current_animation) != desired_anim or last_anim != desired_anim
	if need_restart:
		anim_player.play(desired_anim)
	remote_avatar_last_anims[peer_id] = desired_anim
	var speed_scale: float = _float_from_variant(hero_state.get("anim_speed", 1.0), 1.0)
	anim_player.speed_scale = clampf(speed_scale, 0.05, 8.0)


func pick_remote_fallback_animation(anim_player: AnimationPlayer, hero_state: Dictionary) -> String:
	var current_anim: String = str(hero_state.get("anim_name", "")).strip_edges()
	if current_anim != "" and anim_player.has_animation(current_anim):
		return current_anim
	var is_dead: bool = _bool_from_variant(hero_state.get("is_dead", false), false)
	var is_moving: bool = _bool_from_variant(hero_state.get("moving", false), false)
	var is_attacking: bool = _bool_from_variant(hero_state.get("attacking", false), false)
	if is_dead:
		return find_anim_by_keywords(anim_player, ["death", "die"])
	if is_attacking:
		return find_anim_by_keywords(anim_player, ["attack"])
	if is_moving:
		return find_anim_by_keywords(anim_player, ["walk", "run", "move"])
	return find_anim_by_keywords(anim_player, ["stand", "idle"])


func find_anim_by_keywords(anim_player: AnimationPlayer, keywords: Array[String]) -> String:
	var anim_list: PackedStringArray = anim_player.get_animation_list()
	for anim_name_sn in anim_list:
		var anim_name: String = String(anim_name_sn)
		var lower_name: String = anim_name.to_lower()
		for keyword in keywords:
			if lower_name.find(keyword) >= 0:
				return anim_name
	return ""


func remove_absent_remote_avatars(valid_remote_ids: Dictionary, remote_avatars: Dictionary, remove_fn: Callable) -> void:
	var stale_ids: Array[int] = []
	for key_variant in remote_avatars.keys():
		var peer_id: int = int(key_variant)
		if not valid_remote_ids.has(peer_id):
			stale_ids.append(peer_id)
	for peer_id in stale_ids:
		if remove_fn != null and remove_fn.is_valid():
			remove_fn.call(peer_id)


func remove_remote_avatar(
		peer_id: int,
		remote_avatars: Dictionary,
		remote_avatar_model_keys: Dictionary,
		remote_avatar_last_anims: Dictionary,
		remote_avatar_target_positions: Dictionary,
		remote_avatar_target_yaws: Dictionary,
		remote_avatar_velocities: Dictionary,
		remote_avatar_last_receive_ms: Dictionary,
		remote_avatar_hp_bars: Dictionary,
		remote_avatar_hp_bar_materials: Dictionary,
		remote_last_flash_cd: Dictionary,
		remote_last_haste_active: Dictionary,
		remote_last_skill_event_seq: Dictionary
	) -> void:
	if not remote_avatars.has(peer_id):
		return
	var avatar: Node3D = remote_avatars[peer_id] as Node3D
	remote_avatars.erase(peer_id)
	remote_avatar_model_keys.erase(peer_id)
	remote_avatar_last_anims.erase(peer_id)
	remote_avatar_target_positions.erase(peer_id)
	remote_avatar_target_yaws.erase(peer_id)
	remote_avatar_velocities.erase(peer_id)
	remote_avatar_last_receive_ms.erase(peer_id)
	remote_avatar_hp_bars.erase(peer_id)
	remote_avatar_hp_bar_materials.erase(peer_id)
	remote_last_flash_cd.erase(peer_id)
	remote_last_haste_active.erase(peer_id)
	remote_last_skill_event_seq.erase(peer_id)
	if avatar != null and is_instance_valid(avatar):
		avatar.queue_free()


func clear_remote_avatars(
		remote_avatars: Dictionary,
		remote_avatar_model_keys: Dictionary,
		remote_avatar_last_anims: Dictionary,
		remote_avatar_target_positions: Dictionary,
		remote_avatar_target_yaws: Dictionary,
		remote_avatar_velocities: Dictionary,
		remote_avatar_last_receive_ms: Dictionary,
		remote_avatar_hp_bars: Dictionary,
		remote_avatar_hp_bar_materials: Dictionary,
		remote_last_flash_cd: Dictionary,
		remote_last_haste_active: Dictionary,
		remote_last_skill_event_seq: Dictionary,
		remove_fn: Callable
	) -> void:
	for key_variant in remote_avatars.keys():
		var key: int = int(key_variant)
		if remove_fn != null and remove_fn.is_valid():
			remove_fn.call(key)
	remote_avatars.clear()
	remote_avatar_model_keys.clear()
	remote_avatar_last_anims.clear()
	remote_avatar_target_positions.clear()
	remote_avatar_target_yaws.clear()
	remote_avatar_velocities.clear()
	remote_avatar_last_receive_ms.clear()
	remote_avatar_hp_bars.clear()
	remote_avatar_hp_bar_materials.clear()
	remote_last_flash_cd.clear()
	remote_last_haste_active.clear()
	remote_last_skill_event_seq.clear()


func _bool_from_variant(value: Variant, fallback: bool = false) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return absf(value) > 0.0001
	if value is String:
		var text: String = (value as String).strip_edges().to_lower()
		if text == "true" or text == "1" or text == "yes" or text == "on":
			return true
		if text == "false" or text == "0" or text == "no" or text == "off":
			return false
	return fallback


func _int_from_variant(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return roundi(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_int():
			return text.to_int()
	return fallback


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
