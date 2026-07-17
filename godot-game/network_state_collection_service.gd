extends RefCounted
class_name NetworkStateCollectionService


func extract_int_array(values_variant: Variant) -> Array:
	var out: Array = []
	if values_variant is Array:
		var values: Array = values_variant
		for value in values:
			out.append(int(value))
	return out


func extract_inventory_from_hero_controller(hero_controller: Node) -> Array:
	if hero_controller == null:
		return []
	return extract_int_array(hero_controller.get("inventory"))


func collect_local_hero_base_state(
	hero: Node3D,
	hero_controller: Node,
	int_from_variant_fn: Callable,
	float_from_variant_fn: Callable,
	bool_from_variant_fn: Callable,
	sanitize_peer_hero_command_fn: Callable
) -> Dictionary:
	var state: Dictionary = {}
	if hero == null:
		return state
	state["pos"] = hero.global_position
	state["yaw"] = hero.rotation.y
	state["visible"] = hero.visible
	state["scale"] = hero.scale

	if hero_controller != null:
		state["hp"] = _call_int(int_from_variant_fn, [hero_controller.get("_current_hp"), 0], 0)
		state["max_hp"] = _call_int(int_from_variant_fn, [hero_controller.get("max_hp"), 0], 0)
		state["mana"] = _call_int(int_from_variant_fn, [hero_controller.get("current_mana"), 0], 0)
		state["max_mana"] = _call_int(int_from_variant_fn, [hero_controller.get("max_mana"), 0], 0)
		state["flash_cd"] = _call_float(
			float_from_variant_fn, [hero_controller.get("_flash_cooldown"), 0.0], 0.0
		)
		state["haste_cd"] = _call_float(
			float_from_variant_fn, [hero_controller.get("_haste_cooldown"), 0.0], 0.0
		)
		state["haste_active"] = _call_bool(
			bool_from_variant_fn, [hero_controller.get("_haste_active"), false], false
		)
		state["haste_left"] = _call_float(
			float_from_variant_fn, [hero_controller.get("_haste_time_left"), 0.0], 0.0
		)
		state["r_cooldown"] = _call_float(
			float_from_variant_fn, [hero_controller.get("_r_cooldown"), 0.0], 0.0
		)
		state["is_moving"] = _call_bool(
			bool_from_variant_fn, [hero_controller.get("_is_moving"), false], false
		)
		state["is_attacking"] = _call_bool(
			bool_from_variant_fn, [hero_controller.get("_is_attacking"), false], false
		)
		state["skill_q_id"] = _call_int(
			int_from_variant_fn, [hero_controller.get("skill_q_id"), 0], 0
		)
		state["skill_q_name"] = str(hero_controller.get("skill_q_name"))
		state["skill_w_id"] = _call_int(
			int_from_variant_fn, [hero_controller.get("skill_w_id"), 0], 0
		)
		state["skill_w_name"] = str(hero_controller.get("skill_w_name"))
		state["skill_r_id"] = _call_int(
			int_from_variant_fn, [hero_controller.get("skill_r_id"), 0], 0
		)
		state["hero_id"] = _call_int(int_from_variant_fn, [hero_controller.get("hero_id"), 1], 1)
		state["hero_profile"] = str(hero_controller.get("hero_profile"))
		state["hero_selected"] = _call_bool(
			bool_from_variant_fn, [hero_controller.get("hero_selection_confirmed"), false], false
		)
		if hero_controller.has_method("get_hp_bar_anchor_height"):
			state["hp_bar_anchor_height"] = _call_float(
				float_from_variant_fn, [hero_controller.call("get_hp_bar_anchor_height"), 0.0], 0.0
			)
		if hero_controller.has_method("get_collision_profile_id"):
			state["collision_profile_id"] = str(hero_controller.call("get_collision_profile_id"))
		if hero_controller.has_method("get_projectile_origin_global_position"):
			var projectile_origin_variant: Variant = hero_controller.call(
				"get_projectile_origin_global_position"
			)
			if projectile_origin_variant is Vector3:
				state["projectile_origin_pos"] = projectile_origin_variant
		state["is_transformed"] = _call_bool(
			bool_from_variant_fn, [hero_controller.get("_is_transformed"), false], false
		)
		state["transform_left"] = _call_float(
			float_from_variant_fn, [hero_controller.get("_transform_time_left"), 0.0], 0.0
		)
		state["damage"] = _call_int(
			int_from_variant_fn, [hero_controller.get("damage_per_hit"), 0], 0
		)
		state["flash_damage"] = _call_int(
			int_from_variant_fn, [hero_controller.get("flash_damage"), 0], 0
		)
		state["flash_origin_damage_radius"] = _call_float(
			float_from_variant_fn, [hero_controller.get("flash_origin_damage_radius"), 0.0], 0.0
		)
		state["flash_destination_damage_radius"] = _call_float(
			float_from_variant_fn,
			[hero_controller.get("flash_destination_damage_radius"), 0.0],
			0.0
		)
		state["ranged_q_ray_damage"] = _call_int(
			int_from_variant_fn, [hero_controller.get("ranged_q_ray_damage"), 0], 0
		)
		state["ranged_q_ray_length"] = _call_float(
			float_from_variant_fn, [hero_controller.get("ranged_q_ray_length"), 0.0], 0.0
		)
		state["ranged_r_damage"] = _call_int(
			int_from_variant_fn, [hero_controller.get("ranged_r_damage"), 0], 0
		)
		state["ranged_r_radius"] = _call_float(
			float_from_variant_fn, [hero_controller.get("ranged_r_radius"), 0.0], 0.0
		)
		state["ranged_r_cast_max_distance"] = _call_float(
			float_from_variant_fn, [hero_controller.get("ranged_r_cast_max_distance"), 0.0], 0.0
		)
		state["poison_damage_per_second"] = _call_int(
			int_from_variant_fn, [hero_controller.get("poison_damage_per_second"), 0], 0
		)
		state["poison_tick_interval"] = _call_float(
			float_from_variant_fn, [hero_controller.get("poison_tick_interval"), 1.0], 1.0
		)
		state["armor"] = _call_float(
			float_from_variant_fn, [hero_controller.get("armor"), 0.0], 0.0
		)
		state["move_speed"] = _call_float(
			float_from_variant_fn, [hero_controller.get("move_speed"), 0.0], 0.0
		)
		state["attack_speed"] = _call_float(
			float_from_variant_fn, [hero_controller.get("attack_speed"), 0.0], 0.0
		)
		state["attack_interval"] = _call_float(
			float_from_variant_fn, [hero_controller.get("attack_interval"), 0.0], 0.0
		)
		state["attack_range"] = _call_float(
			float_from_variant_fn, [hero_controller.get("attack_range"), 0.0], 0.0
		)
		state["cooldown_reduction_percent_total"] = _call_float(
			float_from_variant_fn,
			[hero_controller.get("cooldown_reduction_percent_total"), 0.0],
			0.0
		)
		state["physical_crit_chance"] = _call_float(
			float_from_variant_fn, [hero_controller.get("physical_crit_chance"), 0.0], 0.0
		)
		state["physical_crit_multiplier"] = _call_float(
			float_from_variant_fn, [hero_controller.get("physical_crit_multiplier"), 0.0], 0.0
		)
		state["spell_crit_chance"] = _call_float(
			float_from_variant_fn, [hero_controller.get("spell_crit_chance"), 0.0], 0.0
		)
		state["spell_crit_multiplier"] = _call_float(
			float_from_variant_fn, [hero_controller.get("spell_crit_multiplier"), 0.0], 0.0
		)
		state["strength"] = _call_int(int_from_variant_fn, [hero_controller.get("strength"), 0], 0)
		state["agility"] = _call_int(int_from_variant_fn, [hero_controller.get("agility"), 0], 0)
		state["intelligence"] = _call_int(
			int_from_variant_fn, [hero_controller.get("intelligence"), 0], 0
		)
		state["hp_regen_per_second"] = _call_float(
			float_from_variant_fn, [hero_controller.get("hp_regen_per_second"), 0.0], 0.0
		)
		state["mana_regen_per_second"] = _call_float(
			float_from_variant_fn, [hero_controller.get("mana_regen_per_second"), 0.0], 0.0
		)
		if hero_controller.has_method("get_necromancy_sync_state"):
			var necro_variant: Variant = hero_controller.call("get_necromancy_sync_state")
			if necro_variant is Dictionary:
				state["necromancy"] = (necro_variant as Dictionary).duplicate(true)
		if hero_controller.has_method("get_battle_banner_sync_state"):
			var banner_variant: Variant = hero_controller.call("get_battle_banner_sync_state")
			if banner_variant is Dictionary:
				state["battle_banner"] = (banner_variant as Dictionary).duplicate(true)
		if hero_controller.has_method("get_battle_prep_sync_state"):
			var battle_prep_variant: Variant = hero_controller.call("get_battle_prep_sync_state")
			if battle_prep_variant is Dictionary:
				state["battle_prep"] = (battle_prep_variant as Dictionary).duplicate(true)
		if hero_controller.has_method("get_coin_sync_state"):
			var coin_variant: Variant = hero_controller.call("get_coin_sync_state")
			if coin_variant is Dictionary:
				state["coin"] = (coin_variant as Dictionary).duplicate(true)
		if hero_controller.has_method("is_dead"):
			state["is_dead"] = bool(hero_controller.call("is_dead"))
		else:
			state["is_dead"] = false
		if hero_controller.has_method("get_network_command_state"):
			var command_state_variant: Variant = hero_controller.call("get_network_command_state")
			if (
				sanitize_peer_hero_command_fn != null
				and sanitize_peer_hero_command_fn.is_valid()
				and command_state_variant is Dictionary
			):
				state["command_bus"] = sanitize_peer_hero_command_fn.call(
					command_state_variant as Dictionary
				)

	var anim_player: AnimationPlayer = (
		hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	)
	if anim_player != null:
		state["anim_name"] = String(anim_player.current_animation)
		state["anim_playing"] = anim_player.is_playing()
		state["anim_speed"] = anim_player.speed_scale
	return state


func collect_local_equipment_state(
	hero_controller: Node, ui: Node, int_from_variant_fn: Callable
) -> Dictionary:
	var state: Dictionary = {}
	if hero_controller != null:
		state["inventory"] = extract_inventory_from_hero_controller(hero_controller)
		state["hero_level"] = _call_int(
			int_from_variant_fn, [hero_controller.get("hero_level"), 1], 1
		)
	if ui != null:
		state["gold"] = _call_int(int_from_variant_fn, [ui.get("_gold"), 0], 0)
		state["shop_level"] = _call_int(int_from_variant_fn, [ui.get("_shop_level"), 1], 1)
		state["shop_offer_ids"] = extract_int_array(ui.get("_shop_offered"))
		state["destroy_mode"] = bool(ui.get("_destroy_mode"))
		if ui.has_method("get_local_equipment_runtime_state"):
			var runtime_variant: Variant = ui.call("get_local_equipment_runtime_state")
			if runtime_variant is Dictionary:
				var runtime_state: Dictionary = runtime_variant
				state["inventory_meta"] = runtime_state.get("inventory_meta", [])
				state["destroy_faction_state"] = runtime_state.get("destroy_faction_state", {})
				state["coin_faction_state"] = runtime_state.get("coin_faction_state", {})
	return state


func collect_boss_state(
	boss_controller: Node,
	build_network_boss_state_fn: Callable,
	int_from_variant_fn: Callable,
	_float_from_variant_fn: Callable,
	bool_from_variant_fn: Callable
) -> Dictionary:
	if boss_controller == null:
		return {}
	if boss_controller.has_method("export_network_state"):
		var exported_variant: Variant = boss_controller.call("export_network_state")
		if exported_variant is Dictionary:
			return _call_dict(build_network_boss_state_fn, [exported_variant])
	var state: Dictionary = {}
	var boss_model_variant: Variant = boss_controller.get("_enemy")
	if boss_model_variant is Node3D:
		var boss_model: Node3D = boss_model_variant
		state["pos"] = boss_model.global_position
		state["yaw"] = boss_model.rotation.y
		state["visible"] = boss_model.visible
	state["hp"] = _call_int(int_from_variant_fn, [boss_controller.get("_current_hp"), 0], 0)
	state["max_hp"] = _call_int(int_from_variant_fn, [boss_controller.get("max_hp"), 0], 0)
	state["dead"] = _call_bool(
		bool_from_variant_fn, [boss_controller.get("_is_dead"), false], false
	)
	return _call_dict(build_network_boss_state_fn, [state])


func collect_mob_states_from_node(node: Node, build_network_mob_state_fn: Callable) -> Array:
	if node == null:
		return []
	if not node.has_method("collect_network_states"):
		return []
	var states_variant: Variant = node.call("collect_network_states")
	if not (states_variant is Array):
		return []
	var filtered_states: Array = []
	for state_variant in states_variant as Array:
		if not (state_variant is Dictionary):
			continue
		var filtered_state: Dictionary = _call_dict(build_network_mob_state_fn, [state_variant])
		if filtered_state.is_empty():
			continue
		filtered_states.append(filtered_state)
	return filtered_states


func collect_breakable_states(
	scene_tree: SceneTree,
	breakable_group_name: StringName,
	object_has_property_fn: Callable,
	int_from_variant_fn: Callable
) -> Array:
	var states: Array = []
	if scene_tree == null:
		return states
	var breakables: Array = scene_tree.get_nodes_in_group(breakable_group_name)
	for node_variant in breakables:
		var breakable_node: Node = node_variant as Node
		if breakable_node == null:
			continue
		if breakable_node.has_method("export_network_state"):
			var exported_variant: Variant = breakable_node.call("export_network_state")
			if exported_variant is Dictionary:
				var exported_state: Dictionary = (exported_variant as Dictionary).duplicate(true)
				if not exported_state.has("id"):
					exported_state["id"] = str(breakable_node.get_path())
				states.append(exported_state)
			continue
		var fallback_state: Dictionary = build_breakable_fallback_state(
			breakable_node, object_has_property_fn, int_from_variant_fn
		)
		if not fallback_state.is_empty():
			states.append(fallback_state)
	return states


func build_breakable_fallback_state(
	node: Node, object_has_property_fn: Callable, int_from_variant_fn: Callable
) -> Dictionary:
	if node == null:
		return {}
	var state: Dictionary = {}
	var has_syncable_field: bool = false
	if node.has_method("is_dead"):
		state["dead"] = bool(node.call("is_dead"))
		has_syncable_field = true
	if _call_bool(object_has_property_fn, [node, "current_hp"], false):
		state["hp"] = _call_int(int_from_variant_fn, [node.get("current_hp"), 0], 0)
		has_syncable_field = true
	if _call_bool(object_has_property_fn, [node, "max_hp"], false):
		state["max_hp"] = _call_int(int_from_variant_fn, [node.get("max_hp"), 1], 1)
		has_syncable_field = true
	if not has_syncable_field:
		return {}
	state["id"] = str(node.get_path())
	if node is Node3D:
		state["visible"] = (node as Node3D).visible
	return state


func _call_dict(callable_fn: Callable, args: Array = []) -> Dictionary:
	if callable_fn == null or not callable_fn.is_valid():
		return {}
	var result: Variant = callable_fn.callv(args)
	if result is Dictionary:
		return (result as Dictionary).duplicate(true)
	return {}


func _call_int(callable_fn: Callable, args: Array = [], fallback: int = 0) -> int:
	if callable_fn == null or not callable_fn.is_valid():
		return fallback
	var result: Variant = callable_fn.callv(args)
	if result is int:
		return result
	if result is float:
		return roundi(result)
	if result is String:
		var text: String = (result as String).strip_edges()
		if text.is_valid_int():
			return text.to_int()
	return fallback


func _call_float(callable_fn: Callable, args: Array = [], fallback: float = 0.0) -> float:
	if callable_fn == null or not callable_fn.is_valid():
		return fallback
	var result: Variant = callable_fn.callv(args)
	if result is float:
		return result
	if result is int:
		return float(result)
	if result is String:
		var text: String = (result as String).strip_edges()
		if text.is_valid_float():
			return text.to_float()
	return fallback


func _call_bool(callable_fn: Callable, args: Array = [], fallback: bool = false) -> bool:
	if callable_fn == null or not callable_fn.is_valid():
		return fallback
	var result: Variant = callable_fn.callv(args)
	if result is bool:
		return result
	if result is int:
		return result != 0
	if result is float:
		return absf(result) > 0.0001
	if result is String:
		var text: String = (result as String).strip_edges().to_lower()
		if text == "true" or text == "1" or text == "yes" or text == "on":
			return true
		if text == "false" or text == "0" or text == "no" or text == "off":
			return false
	return fallback
