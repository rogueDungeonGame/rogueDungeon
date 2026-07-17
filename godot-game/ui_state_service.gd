extends RefCounted
class_name UIStateService

var observed_peer_id: int = 0
var observing_boss: bool = false
var observed_enemy_state: Dictionary = {}
var self_peer_id: int = 0
var observed_remote_hero_state: Dictionary = {}
var observed_remote_equipment_state: Dictionary = {}


func build_observe_snapshot() -> Dictionary:
	return {
		"observed_peer_id": observed_peer_id,
		"observing_boss": observing_boss,
		"observed_enemy_state": observed_enemy_state.duplicate(true),
		"self_peer_id": self_peer_id,
		"observed_remote_hero_state": observed_remote_hero_state.duplicate(true),
		"observed_remote_equipment_state": observed_remote_equipment_state.duplicate(true),
	}


func apply_observe_snapshot(state: Dictionary) -> void:
	observed_peer_id = maxi(int(state.get("observed_peer_id", observed_peer_id)), 0)
	observing_boss = _bool_from_variant(state.get("observing_boss", observing_boss), observing_boss)
	var enemy_state_variant: Variant = state.get("observed_enemy_state", observed_enemy_state)
	if enemy_state_variant is Dictionary:
		observed_enemy_state = (enemy_state_variant as Dictionary).duplicate(true)
	var self_peer_variant: Variant = state.get("self_peer_id", self_peer_id)
	self_peer_id = int(self_peer_variant)
	var remote_hero_variant: Variant = state.get(
		"observed_remote_hero_state", observed_remote_hero_state
	)
	if remote_hero_variant is Dictionary:
		observed_remote_hero_state = (remote_hero_variant as Dictionary).duplicate(true)
	var remote_equipment_variant: Variant = state.get(
		"observed_remote_equipment_state", observed_remote_equipment_state
	)
	if remote_equipment_variant is Dictionary:
		observed_remote_equipment_state = (remote_equipment_variant as Dictionary).duplicate(true)


func is_observing_boss() -> bool:
	return observing_boss


func is_observing_enemy() -> bool:
	return not observed_enemy_state.is_empty()


func is_observing_remote() -> bool:
	return observed_peer_id > 0 and (self_peer_id <= 0 or observed_peer_id != self_peer_id)


func get_observed_hero_state() -> Dictionary:
	if not is_observing_remote():
		return {}
	return observed_remote_hero_state.duplicate(true)


func get_observed_equipment_state() -> Dictionary:
	if not is_observing_remote():
		return {}
	return observed_remote_equipment_state.duplicate(true)


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
