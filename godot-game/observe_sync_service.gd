extends RefCounted
class_name ObserveSyncService


func apply_observed_peer(current_state: Dictionary, peer_id: int) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	var safe_peer_id: int = maxi(peer_id, 0)
	var should_clear_boss: bool = _bool_from_variant(next_state.get("observing_boss", false), false)
	var observed_enemy_state: Dictionary = _dict_copy(next_state.get("observed_enemy_state", {}))
	if int(next_state.get("observed_peer_id", 0)) == safe_peer_id and not should_clear_boss and observed_enemy_state.is_empty():
		return {
			"changed": false,
			"state": next_state,
			"reset_local_destroy_mode": false,
		}
	next_state["observing_boss"] = false
	next_state["observed_enemy_state"] = {}
	next_state["observed_peer_id"] = safe_peer_id
	return {
		"changed": true,
		"state": next_state,
		"reset_local_destroy_mode": _is_observing_remote(next_state),
	}


func apply_observed_boss(current_state: Dictionary, enabled: bool) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	var should_observe_boss: bool = _bool_from_variant(enabled, false)
	var current_observing_boss: bool = _bool_from_variant(next_state.get("observing_boss", false), false)
	var current_observed_peer_id: int = int(next_state.get("observed_peer_id", 0))
	var current_enemy_state: Dictionary = _dict_copy(next_state.get("observed_enemy_state", {}))
	if current_observing_boss == should_observe_boss and (not should_observe_boss or (current_observed_peer_id == 0 and current_enemy_state.is_empty())):
		return {
			"changed": false,
			"state": next_state,
		}
	next_state["observing_boss"] = should_observe_boss
	next_state["observed_enemy_state"] = {}
	if should_observe_boss:
		next_state["observed_peer_id"] = 0
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
	return {
		"changed": true,
		"state": next_state,
	}


func apply_observed_enemy(current_state: Dictionary, enemy_state_variant: Variant) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	var next_enemy_state: Dictionary = _dict_copy(enemy_state_variant)
	var enable_enemy_observe: bool = not next_enemy_state.is_empty()
	var current_enemy_state: Dictionary = _dict_copy(next_state.get("observed_enemy_state", {}))
	if not enable_enemy_observe and current_enemy_state.is_empty():
		return {
			"changed": false,
			"state": next_state,
		}
	if enable_enemy_observe:
		next_state["observing_boss"] = false
		next_state["observed_peer_id"] = 0
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
		next_state["observed_enemy_state"] = next_enemy_state
	else:
		next_state["observed_enemy_state"] = {}
	return {
		"changed": true,
		"state": next_state,
	}


func update_network_view_state(net_ctrl: Node, current_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _copy_state(current_state)
	var clear_observed_peer: bool = false

	if net_ctrl == null:
		next_state["self_peer_id"] = 0
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
		return {
			"state": next_state,
			"clear_observed_peer": clear_observed_peer,
		}

	if net_ctrl.has_method("get_ui_self_peer_id"):
		next_state["self_peer_id"] = int(net_ctrl.call("get_ui_self_peer_id"))
	else:
		next_state["self_peer_id"] = 0

	if _bool_from_variant(next_state.get("observing_boss", false), false) or not _dict_copy(next_state.get("observed_enemy_state", {})).is_empty():
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
		return {
			"state": next_state,
			"clear_observed_peer": clear_observed_peer,
		}

	var observed_peer_id: int = int(next_state.get("observed_peer_id", 0))
	var self_peer_id: int = int(next_state.get("self_peer_id", 0))
	if observed_peer_id > 0 and self_peer_id > 0 and observed_peer_id == self_peer_id:
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
		clear_observed_peer = true
		return {
			"state": next_state,
			"clear_observed_peer": clear_observed_peer,
		}

	if observed_peer_id <= 0:
		next_state["observed_remote_hero_state"] = {}
		next_state["observed_remote_equipment_state"] = {}
		return {
			"state": next_state,
			"clear_observed_peer": clear_observed_peer,
		}

	var observed_remote_hero_state: Dictionary = {}
	if net_ctrl.has_method("get_ui_peer_hero_state"):
		var hero_state_variant: Variant = net_ctrl.call("get_ui_peer_hero_state", observed_peer_id)
		observed_remote_hero_state = _dict_copy(hero_state_variant)
	var observed_remote_equipment_state: Dictionary = {}
	if net_ctrl.has_method("get_ui_peer_equipment_state"):
		var equip_state_variant: Variant = net_ctrl.call("get_ui_peer_equipment_state", observed_peer_id)
		observed_remote_equipment_state = _dict_copy(equip_state_variant)
	next_state["observed_remote_hero_state"] = observed_remote_hero_state
	next_state["observed_remote_equipment_state"] = observed_remote_equipment_state
	if observed_remote_hero_state.is_empty() and observed_remote_equipment_state.is_empty():
		clear_observed_peer = true
	return {
		"state": next_state,
		"clear_observed_peer": clear_observed_peer,
	}


func fetch_local_authority_equipment_state(net_ctrl: Node, observing_remote: bool, self_peer_id: int) -> Dictionary:
	if net_ctrl == null:
		return {}
	if observing_remote:
		return {}
	if self_peer_id <= 0:
		return {}
	var net_mode: String = str(net_ctrl.get("network_mode")).strip_edges().to_lower()
	if net_mode != "client":
		return {}
	if not net_ctrl.has_method("get_ui_peer_equipment_state"):
		return {}
	var state_variant: Variant = net_ctrl.call("get_ui_peer_equipment_state", self_peer_id)
	return _dict_copy(state_variant)


func is_local_equipment_state_synced(authority_state: Dictionary, local_state: Dictionary) -> bool:
	var local_inventory: Array = _int_array_copy(local_state.get("inventory", []))
	var authority_inventory: Array = _int_array_copy(local_state.get("authority_inventory", authority_state.get("inventory", [])))
	if not _int_array_equals(local_inventory, authority_inventory):
		return false
	if int(authority_state.get("gold", local_state.get("gold", 0))) != int(local_state.get("gold", 0)):
		return false
	var authority_shop_level: int = clampi(int(authority_state.get("shop_level", local_state.get("shop_level", 1))), 1, 7)
	if authority_shop_level != int(local_state.get("shop_level", 1)):
		return false
	var authority_offers: Array = _int_array_copy(authority_state.get("shop_offer_ids", []))
	var local_offers: Array = _int_array_copy(local_state.get("shop_offer_ids", []))
	if not _int_array_equals(local_offers, authority_offers):
		return false
	if _bool_from_variant(authority_state.get("destroy_mode", local_state.get("destroy_mode", false)), _bool_from_variant(local_state.get("destroy_mode", false), false)) != _bool_from_variant(local_state.get("destroy_mode", false), false):
		return false
	if JSON.stringify(_copy_array(local_state.get("authority_inventory_meta", authority_state.get("inventory_meta", [])))) != JSON.stringify(_copy_array(local_state.get("inventory_meta", []))):
		return false
	if JSON.stringify(_dict_copy(local_state.get("authority_destroy_faction_state", authority_state.get("destroy_faction_state", {})))) != JSON.stringify(_dict_copy(local_state.get("destroy_faction_state", {}))):
		return false
	if JSON.stringify(_dict_copy(local_state.get("authority_coin_faction_state", authority_state.get("coin_faction_state", {})))) != JSON.stringify(_dict_copy(local_state.get("coin_faction_state", {}))):
		return false
	return true


func _is_observing_remote(state: Dictionary) -> bool:
	var observed_peer_id: int = int(state.get("observed_peer_id", 0))
	var self_peer_id: int = int(state.get("self_peer_id", 0))
	return observed_peer_id > 0 and (self_peer_id <= 0 or observed_peer_id != self_peer_id)


func _copy_state(state: Dictionary) -> Dictionary:
	return {
		"observed_peer_id": int(state.get("observed_peer_id", 0)),
		"observing_boss": _bool_from_variant(state.get("observing_boss", false), false),
		"observed_enemy_state": _dict_copy(state.get("observed_enemy_state", {})),
		"self_peer_id": int(state.get("self_peer_id", 0)),
		"observed_remote_hero_state": _dict_copy(state.get("observed_remote_hero_state", {})),
		"observed_remote_equipment_state": _dict_copy(state.get("observed_remote_equipment_state", {})),
	}


func _dict_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _copy_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


func _int_array_copy(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			out.append(int(item))
	return out


func _int_array_equals(lhs: Array, rhs: Array) -> bool:
	if lhs.size() != rhs.size():
		return false
	for i in range(lhs.size()):
		if int(lhs[i]) != int(rhs[i]):
			return false
	return true


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
