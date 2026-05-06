extends RefCounted
class_name SnapshotSerializationService

const NETWORK_HERO_ALLOWED_KEYS := [
	"pos", "yaw", "visible", "scale",
	"hp", "max_hp", "mana", "max_mana",
	"is_dead", "is_moving", "is_attacking",
	"move_speed", "attack_range",
	"hero_id", "hero_profile", "hero_selected", "hp_bar_anchor_height", "is_transformed",
	"flash_cd", "haste_cd", "haste_active", "haste_left",
	"r_cooldown", "skill_q_id", "skill_w_id", "skill_r_id",
	"damage", "flash_damage", "flash_origin_damage_radius", "flash_destination_damage_radius",
	"ranged_q_ray_damage", "ranged_q_ray_length",
	"ranged_r_damage", "ranged_r_radius", "ranged_r_cast_max_distance",
	"poison_damage_per_second", "poison_tick_interval", "attack_interval",
	"physical_crit_chance", "physical_crit_multiplier", "spell_crit_multiplier",
	"strength", "agility", "intelligence",
	"anim_name", "anim_playing", "anim_speed",
	"skill_event", "command_bus", "necromancy", "battle_banner", "battle_prep", "coin"
]

const CLIENT_INPUT_HERO_ALLOWED_KEYS := [
	"pos", "yaw", "visible", "scale",
	"hp", "max_hp", "mana", "max_mana",
	"is_dead", "is_moving", "is_attacking",
	"move_speed", "attack_range",
	"hero_id", "hero_profile", "hero_selected", "hp_bar_anchor_height", "is_transformed",
	"flash_cd", "haste_cd", "haste_active", "haste_left",
	"r_cooldown", "skill_q_id", "skill_w_id", "skill_r_id",
	"damage", "flash_damage", "flash_origin_damage_radius", "flash_destination_damage_radius",
	"ranged_q_ray_damage", "ranged_q_ray_length",
	"ranged_r_damage", "ranged_r_radius", "ranged_r_cast_max_distance",
	"poison_damage_per_second", "poison_tick_interval", "attack_interval",
	"physical_crit_chance", "physical_crit_multiplier", "spell_crit_multiplier",
	"strength", "agility", "intelligence",
	"anim_name", "anim_playing", "anim_speed",
	"skill_event", "necromancy", "battle_banner", "battle_prep", "coin"
]

const NETWORK_BOSS_ALLOWED_KEYS := [
	"pos", "yaw", "visible",
	"hp", "max_hp", "armor", "dead",
	"damage_popup_seq", "damage_popup_amount", "damage_popup_source", "damage_popup_critical",
	"is_moving", "is_attacking",
	"casting_skill", "casting_skill2",
	"attack_cooldown", "skill_cast_left", "skill_cooldown",
	"engage_timer", "chase_timer", "target_lock_active",
	"skill2_timer", "skill2_cooldown", "skill2_total_time", "skill2_hit_applied",
	"skill2_hit_targets", "skill2_start_pos", "skill2_end_pos",
	"current_hp_phase", "death_finalized",
	"current_attack_index", "stop_attack_combo",
	"engage_initialized", "was_in_engage_range", "engaged",
	"pending_idle_after_animation",
	"skill_warning_visible", "skill_warning_pos",
	"anim_name", "anim_playing", "anim_speed"
]

const NETWORK_MOB_ALLOWED_KEYS := [
	"id",
	"pos", "yaw", "visible",
	"hp", "max_hp", "armor", "dead",
	"damage_popup_seq", "damage_popup_amount", "damage_popup_source", "damage_popup_critical",
	"is_moving", "is_attacking",
	"anim_name", "anim_playing", "anim_speed", "summon_kind"
]

const UNRELIABLE_WORLD_BOSS_ALLOWED_KEYS := [
	"pos", "yaw", "visible",
	"hp", "max_hp", "armor", "dead",
	"damage_popup_seq", "damage_popup_amount", "damage_popup_source", "damage_popup_critical",
	"is_moving", "is_attacking",
	"casting_skill", "casting_skill2",
	"target_lock_active",
	"current_hp_phase", "death_finalized",
	"skill_warning_visible", "skill_warning_pos",
	"anim_name", "anim_playing", "anim_speed"
]


func build_world_snapshot(input: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	var next_world_seq: int = int(input.get("current_world_seq", 0)) + 1
	var next_cursor: int = int(input.get("current_mob_chunk_cursor", 0))
	snapshot["world_seq"] = next_world_seq
	snapshot["timestamp_ms"] = int(input.get("timestamp_ms", 0))
	snapshot["ack_input_seq"] = _dict_copy(input.get("ack_input_seq", {}))
	if bool(input.get("sync_boss_state", false)):
		snapshot["boss"] = _dict_copy(input.get("boss_state", {}))
	if bool(input.get("sync_mob_state", false)):
		var all_mobs: Array = _array_copy(input.get("all_mobs", []))
		var total_mobs: int = all_mobs.size()
		snapshot["mobs_total"] = total_mobs
		if total_mobs <= 0:
			snapshot["mobs"] = []
			snapshot["mobs_partial"] = false
			snapshot["mobs_start"] = 0
			next_cursor = 0
		elif bool(input.get("force_full_sync", false)):
			snapshot["mobs"] = all_mobs
			snapshot["mobs_partial"] = false
			snapshot["mobs_start"] = 0
			next_cursor = 0
		else:
			var chunk_size: int = clampi(int(input.get("chunk_size", 1)), 1, total_mobs)
			var start_idx: int = clampi(next_cursor, 0, maxi(total_mobs - 1, 0))
			if start_idx >= total_mobs:
				start_idx = 0
			var end_idx: int = mini(start_idx + chunk_size, total_mobs)
			var mobs_chunk: Array = []
			for i in range(start_idx, end_idx):
				mobs_chunk.append(all_mobs[i])
			var sent_full_set: bool = (start_idx == 0 and end_idx >= total_mobs)
			snapshot["mobs"] = mobs_chunk
			snapshot["mobs_partial"] = not sent_full_set
			snapshot["mobs_start"] = start_idx
			if end_idx >= total_mobs:
				next_cursor = 0
			else:
				next_cursor = end_idx
	if bool(input.get("sync_breakable_state", false)):
		snapshot["breakables"] = _array_copy(input.get("breakables", []))
	return {
		"snapshot": snapshot,
		"next_world_seq": next_world_seq,
		"next_mob_chunk_cursor": next_cursor,
	}


func trim_unreliable_world_snapshot_to_mtu(snapshot: Dictionary, mtu_budget_bytes: int) -> Dictionary:
	var trimmed: Dictionary = snapshot.duplicate(true)
	# Leave room for Godot RPC and ENet framing so the serialized payload stays under the actual MTU.
	var envelope_margin_bytes: int = 320
	var safe_budget: int = clampi(maxi(mtu_budget_bytes - envelope_margin_bytes, 0), 640, 1024)
	var current_bytes: int = estimate_payload_bytes(trimmed)
	if current_bytes <= safe_budget:
		return trimmed
	if current_bytes > safe_budget and trimmed.has("breakables"):
		trimmed["breakables"] = []
	current_bytes = estimate_payload_bytes(trimmed)
	if current_bytes <= safe_budget:
		return trimmed
	if current_bytes > safe_budget and trimmed.has("boss"):
		var boss_variant: Variant = trimmed.get("boss", {})
		if boss_variant is Dictionary:
			trimmed["boss"] = filter_state_with_allowed_keys(boss_variant as Dictionary, UNRELIABLE_WORLD_BOSS_ALLOWED_KEYS)
	current_bytes = estimate_payload_bytes(trimmed)
	if current_bytes <= safe_budget:
		return trimmed
	var mobs_variant: Variant = trimmed.get("mobs", [])
	if mobs_variant is Array:
		var mobs: Array = (mobs_variant as Array).duplicate(true)
		while mobs.size() > 1:
			mobs.resize(mobs.size() - 1)
			trimmed["mobs"] = mobs
			trimmed["mobs_partial"] = true
			current_bytes = estimate_payload_bytes(trimmed)
			if current_bytes <= safe_budget:
				return trimmed
		if current_bytes > safe_budget:
			trimmed["mobs"] = []
			trimmed["mobs_partial"] = true
	return trimmed


func build_hero_snapshot(input: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	var next_hero_seq: int = int(input.get("current_hero_seq", 0)) + 1
	var host_peer_id: int = int(input.get("host_peer_id", 0))
	snapshot["hero_seq"] = next_hero_seq
	snapshot["timestamp_ms"] = int(input.get("timestamp_ms", 0))
	snapshot["host_peer_id"] = host_peer_id
	snapshot["ack_input_seq"] = _dict_copy(input.get("ack_input_seq", {}))
	if bool(input.get("sync_hero_state", false)):
		snapshot["host_hero"] = _dict_copy(input.get("host_hero_state", {}))
	if bool(input.get("sync_equipment_state", false)):
		snapshot["host_equipment"] = _dict_copy(input.get("host_equipment_state", {}))

	var peer_latest_hero_state: Dictionary = _dict_copy(input.get("peer_latest_hero_state", {}))
	var peer_latest_hero_command: Dictionary = _dict_copy(input.get("peer_latest_hero_command", {}))
	var peer_latest_equipment_state: Dictionary = _dict_copy(input.get("peer_latest_equipment_state", {}))
	var peers_payload: Dictionary = {}
	for key_variant in peer_latest_hero_state.keys():
		var peer_id: int = int(key_variant)
		if peer_id == host_peer_id:
			continue
		var payload: Dictionary = {}
		if bool(input.get("sync_hero_state", false)) and peer_latest_hero_state.has(peer_id):
			var peer_hero_state: Dictionary = _dict_copy(peer_latest_hero_state[peer_id])
			if not peer_hero_state.has("command_bus") and peer_latest_hero_command.has(peer_id):
				var cmd_variant: Variant = peer_latest_hero_command[peer_id]
				if cmd_variant is Dictionary:
					peer_hero_state["command_bus"] = (cmd_variant as Dictionary).duplicate(true)
			payload["hero"] = peer_hero_state
		if bool(input.get("sync_equipment_state", false)) and peer_latest_equipment_state.has(peer_id):
			payload["equipment"] = _dict_copy(peer_latest_equipment_state[peer_id])
		peers_payload[str(peer_id)] = payload
	snapshot["peers"] = peers_payload
	return {
		"snapshot": snapshot,
		"next_hero_seq": next_hero_seq,
	}


func build_network_hero_state(full_state: Dictionary) -> Dictionary:
	return filter_state_with_allowed_keys(full_state, NETWORK_HERO_ALLOWED_KEYS)


func build_client_input_hero_state(full_state: Dictionary) -> Dictionary:
	return filter_state_with_allowed_keys(full_state, CLIENT_INPUT_HERO_ALLOWED_KEYS)


func build_network_boss_state(full_state: Dictionary) -> Dictionary:
	return filter_state_with_allowed_keys(full_state, NETWORK_BOSS_ALLOWED_KEYS)


func build_network_mob_state(full_state: Dictionary) -> Dictionary:
	return filter_state_with_allowed_keys(full_state, NETWORK_MOB_ALLOWED_KEYS)


func filter_state_with_allowed_keys(full_state: Dictionary, allowed_keys: Array) -> Dictionary:
	if full_state.is_empty():
		return {}
	var filtered: Dictionary = {}
	for key_variant in allowed_keys:
		var key: String = String(key_variant)
		if not full_state.has(key):
			continue
		var value: Variant = full_state[key]
		if value is Dictionary:
			filtered[key] = (value as Dictionary).duplicate(true)
		elif value is Array:
			filtered[key] = (value as Array).duplicate(true)
		else:
			filtered[key] = value
	return filtered


func build_client_input_bundle(current_seq: int, timestamp_ms: int, hero_state: Dictionary, packet_budget: int) -> Dictionary:
	var next_seq: int = current_seq + 1
	var bundle: Dictionary = {
		"seq": next_seq,
		"t_ms": timestamp_ms,
		"hero": hero_state
	}
	var safe_budget: int = clampi(packet_budget, 640, 1100)
	if estimate_payload_bytes(bundle) > safe_budget:
		bundle = trim_client_input_payload_for_budget(bundle, safe_budget)
	return {
		"bundle": bundle,
		"next_client_input_seq": next_seq,
	}


func trim_client_input_payload_for_budget(payload: Dictionary, packet_budget: int) -> Dictionary:
	var trimmed: Dictionary = payload.duplicate(true)
	if estimate_payload_bytes(trimmed) <= packet_budget:
		return trimmed
	var hero_variant: Variant = trimmed.get("hero", {})
	if not (hero_variant is Dictionary):
		return trimmed
	var hero_state: Dictionary = (hero_variant as Dictionary).duplicate(true)
	var drop_order: PackedStringArray = PackedStringArray([
		"necromancy", "battle_banner", "battle_prep", "coin",
		"skill_event",
		"flash_destination_damage_radius", "flash_origin_damage_radius",
		"ranged_r_cast_max_distance", "ranged_q_ray_length",
		"poison_tick_interval", "poison_damage_per_second",
		"ranged_r_radius", "ranged_r_damage",
		"ranged_q_ray_damage", "flash_damage",
		"attack_interval", "attack_range",
		"damage",
		"physical_crit_chance", "physical_crit_multiplier", "spell_crit_multiplier",
		"strength", "agility", "intelligence",
		"hero_profile", "hero_selected", "hp_bar_anchor_height",
		"is_transformed",
		"skill_r_id", "skill_w_id", "skill_q_id",
		"visible"
	])
	for key_variant in drop_order:
		if estimate_payload_bytes(trimmed) <= packet_budget:
			break
		var key: String = String(key_variant)
		if not hero_state.has(key):
			continue
		hero_state.erase(key)
	trimmed["hero"] = hero_state
	return trimmed


func estimate_payload_bytes(payload: Variant) -> int:
	var payload_bytes: PackedByteArray = var_to_bytes(payload)
	return payload_bytes.size()


func build_state_signature(payload: Variant) -> String:
	var payload_bytes: PackedByteArray = var_to_bytes(payload)
	return str(hash(payload_bytes))


func extract_mob_count_from_snapshot(snapshot: Dictionary) -> int:
	var total_variant: Variant = snapshot.get("mobs_total", null)
	if total_variant != null:
		return _int_from_variant(total_variant, 0)
	var mobs_variant: Variant = snapshot.get("mobs", [])
	if mobs_variant is Array:
		return (mobs_variant as Array).size()
	return 0


func _dict_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _array_copy(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


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
