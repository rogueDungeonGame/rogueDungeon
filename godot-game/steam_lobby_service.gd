extends RefCounted
class_name SteamLobbyService


func should_start_with_lobby(lobby_enabled: bool, lobby_action: String, lobby_id_text: String, parsed_lobby_id: int) -> bool:
	if not lobby_enabled:
		return false
	var action_text: String = lobby_action.strip_edges().to_lower()
	if action_text == "create":
		return true
	if action_text == "join" and parsed_lobby_id > 0:
		return true
	return false


func begin_create_host(current_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	next_state["steam_lobby_action"] = "create"
	next_state["steam_lobby_id_text"] = ""
	next_state["_steam_lobby_pending_action"] = "create_host"
	return {
		"state": next_state,
		"hint": "lobby_create_requested",
	}


func begin_join_client(current_state: Dictionary, lobby_id: int) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	next_state["steam_lobby_action"] = "join"
	next_state["steam_lobby_id_text"] = str(lobby_id)
	next_state["_steam_lobby_pending_action"] = "join_client"
	return {
		"state": next_state,
		"hint": "lobby_join_requested(%d)" % lobby_id,
	}


func handle_lobby_created(current_state: Dictionary, connect_status: int, lobby_id: int, is_ok: bool) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	if lobby_id <= 0:
		return {
			"state": next_state,
			"changed": false,
		}
	if not is_ok:
		next_state["_steam_lobby_pending_action"] = ""
		return {
			"state": next_state,
			"changed": true,
			"hint": "lobby_create_failed(status=%d)" % connect_status,
		}
	next_state["_steam_lobby_id"] = lobby_id
	next_state["steam_lobby_id_text"] = str(lobby_id)
	return {
		"state": next_state,
		"changed": true,
		"hint": "lobby_created(%d)" % lobby_id,
	}


func handle_lobby_joined(current_state: Dictionary, lobby_id: int, response: int, is_ok: bool) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	if lobby_id <= 0:
		return {
			"state": next_state,
			"changed": false,
		}
	if not is_ok:
		next_state["_steam_lobby_pending_action"] = ""
		return {
			"state": next_state,
			"changed": true,
			"hint": "lobby_join_failed(status=%d)" % response,
			"should_start_network": false,
		}
	var pending_action: String = str(next_state.get("_steam_lobby_pending_action", "")).strip_edges()
	next_state["_steam_lobby_id"] = lobby_id
	next_state["steam_lobby_id_text"] = str(lobby_id)
	next_state["_steam_lobby_pending_action"] = ""
	var should_start_network: bool = false
	if pending_action == "create_host":
		next_state["network_mode"] = "host"
		next_state["net_transport_mode"] = "steam_relay"
		next_state["_migration_pause_world_authority"] = false
		should_start_network = true
	elif pending_action == "join_client":
		next_state["network_mode"] = "client"
		next_state["net_transport_mode"] = "steam_relay"
		next_state["_migration_pause_world_authority"] = true
		should_start_network = true
	return {
		"state": next_state,
		"changed": true,
		"hint": "lobby_joined(%d)" % lobby_id,
		"should_start_network": should_start_network,
	}


func apply_backend_snapshot(current_state: Dictionary, next_owner: int, next_members: Array) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	var prev_owner: int = int(next_state.get("_steam_lobby_owner_steam_id", 0))
	var current_members: Array = _int_array_copy(next_state.get("_steam_lobby_member_steam_ids", []))
	var owner_changed: bool = next_owner != prev_owner
	var members_changed: bool = next_members != current_members
	next_state["_steam_lobby_owner_steam_id"] = next_owner
	next_state["_steam_lobby_member_steam_ids"] = _int_array_copy(next_members)
	var result: Dictionary = {
		"state": next_state,
		"changed": owner_changed or members_changed,
		"owner_changed": owner_changed,
		"members_changed": members_changed,
	}
	if owner_changed and prev_owner > 0 and next_owner > 0:
		result["hint"] = "lobby_owner_changed(%d->%d)" % [prev_owner, next_owner]
	return result


func clear_runtime_state(current_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	next_state["_steam_lobby_id"] = 0
	next_state["_steam_lobby_owner_steam_id"] = 0
	next_state["_steam_lobby_member_steam_ids"] = []
	next_state["_steam_lobby_pending_action"] = ""
	next_state["steam_lobby_id_text"] = ""
	next_state["_current_host_steam_id"] = 0
	next_state["_host_migration_target_steam_id"] = 0
	next_state["_host_migration_in_progress"] = false
	next_state["_migration_pause_world_authority"] = false
	return next_state


func pick_successor_owner(lobby_id: int, local_steam_id: int, current_owner_steam_id: int, member_steam_ids: Array) -> int:
	if lobby_id <= 0:
		return 0
	if local_steam_id <= 0 or current_owner_steam_id != local_steam_id:
		return 0
	for member_steam_id_variant in member_steam_ids:
		var member_steam_id: int = int(member_steam_id_variant)
		if member_steam_id <= 0 or member_steam_id == local_steam_id:
			continue
		return member_steam_id
	return 0


func advance_lobby_poll(lobby_id: int, poll_elapsed_sec: float, delta: float, poll_interval_sec: float, owner_steam_id: int, local_steam_id: int) -> Dictionary:
	var next_elapsed: float = poll_elapsed_sec
	var should_refresh: bool = false
	var should_sync_metadata: bool = false
	var should_sync_member_data: bool = false
	if lobby_id > 0:
		next_elapsed += delta
		if next_elapsed >= maxf(poll_interval_sec, 0.2):
			next_elapsed = 0.0
			should_refresh = true
			should_sync_metadata = owner_steam_id > 0 and owner_steam_id == local_steam_id
			should_sync_member_data = true
	return {
		"poll_elapsed_sec": next_elapsed,
		"should_refresh": should_refresh,
		"should_sync_metadata": should_sync_metadata,
		"should_sync_member_data": should_sync_member_data,
	}


func should_sync_metadata(lobby_id: int, owner_steam_id: int, local_steam_id: int) -> bool:
	if lobby_id <= 0:
		return false
	if local_steam_id <= 0:
		return false
	return owner_steam_id == local_steam_id


func build_metadata_payload(lobby_id: int, lobby_name: String, local_steam_id: int, network_mode: String, host_migration_enabled: bool) -> Dictionary:
	if lobby_id <= 0:
		return {}
	return {
		"rgd_name": lobby_name.strip_edges(),
		"rgd_transport": "steam_relay",
		"rgd_host_steam_id": str(local_steam_id),
		"rgd_mode": network_mode.strip_edges().to_lower(),
		"rgd_host_migration": "1" if host_migration_enabled else "0",
	}


func should_sync_member_data(lobby_id: int) -> bool:
	return lobby_id > 0


func build_member_data_payload(local_steam_id: int, hero_selected: bool, hero_profile: String) -> Dictionary:
	return {
		"steam_id": str(local_steam_id),
		"hero_selected": "1" if hero_selected else "0",
		"hero_profile": hero_profile,
	}


func _copy_state(state: Dictionary) -> Dictionary:
	return {
		"steam_lobby_action": str(state.get("steam_lobby_action", "disabled")),
		"steam_lobby_id_text": str(state.get("steam_lobby_id_text", "")),
		"_steam_lobby_id": int(state.get("_steam_lobby_id", 0)),
		"_steam_lobby_owner_steam_id": int(state.get("_steam_lobby_owner_steam_id", 0)),
		"_steam_lobby_member_steam_ids": _int_array_copy(state.get("_steam_lobby_member_steam_ids", [])),
		"_steam_lobby_pending_action": str(state.get("_steam_lobby_pending_action", "")),
		"network_mode": str(state.get("network_mode", "offline")),
		"net_transport_mode": str(state.get("net_transport_mode", "enet_direct")),
		"_migration_pause_world_authority": bool(state.get("_migration_pause_world_authority", false)),
		"_current_host_steam_id": int(state.get("_current_host_steam_id", 0)),
		"_host_migration_target_steam_id": int(state.get("_host_migration_target_steam_id", 0)),
		"_host_migration_in_progress": bool(state.get("_host_migration_in_progress", false)),
	}


func _int_array_copy(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			out.append(int(item))
	return out
