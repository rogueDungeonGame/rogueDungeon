extends RefCounted
class_name EquipmentRuntimeHelper

const BLOODHEART_ITEM_NAME := "血羽之心"
const EVIL_ORB_ITEM_NAME := "邪灵宝珠"
const GOLD_COIN_ITEM_NAME := "金硬币"


func create_default_destroy_faction_state() -> Dictionary:
	return {
		"permanent_strength": 0,
		"permanent_agility": 0,
		"permanent_intelligence": 0,
		"permanent_hp": 0,
		"tongtian_ready_stages": 0,
		"tongtian_bonus_loops": 0,
	}


func create_default_coin_faction_state() -> Dictionary:
	return {
		"total_coins_gained_run": 0,
		"revive_event_charges": 0,
		"retained_copper_damage": 0,
		"auto_destroy_coin_enabled": false,
		"refreshes_used_this_battle": 0,
	}


func sanitize_coin_faction_state(state_variant: Variant) -> Dictionary:
	var out: Dictionary = create_default_coin_faction_state()
	if not (state_variant is Dictionary):
		return out
	var state: Dictionary = state_variant
	out["total_coins_gained_run"] = maxi(int(state.get("total_coins_gained_run", 0)), 0)
	out["revive_event_charges"] = maxi(int(state.get("revive_event_charges", 0)), 0)
	out["retained_copper_damage"] = maxi(int(state.get("retained_copper_damage", 0)), 0)
	out["auto_destroy_coin_enabled"] = _variant_to_bool(state.get("auto_destroy_coin_enabled", false), false)
	out["refreshes_used_this_battle"] = maxi(int(state.get("refreshes_used_this_battle", 0)), 0)
	return out


func sanitize_destroy_faction_state(state_variant: Variant) -> Dictionary:
	var out: Dictionary = create_default_destroy_faction_state()
	if not (state_variant is Dictionary):
		return out
	var state: Dictionary = state_variant
	for key_variant in out.keys():
		var key: String = str(key_variant)
		out[key] = maxi(int(state.get(key, out[key])), 0)
	return out


func get_item_name_by_index(item_db: Array, item_idx: int) -> String:
	if item_idx < 0 or item_idx >= item_db.size():
		return ""
	var item_data: Dictionary = item_db[item_idx] if item_db[item_idx] is Dictionary else {}
	return str(item_data.get("name", "")).strip_edges()


func create_default_inventory_meta_entry(item_db: Array, item_idx: int = -1) -> Dictionary:
	var out: Dictionary = {
		"charges": 0,
		"stored_level": 0,
		"dynamic_level": 0,
		"coin_layers": 0,
		"permanent_strength": 0,
		"permanent_agility": 0,
		"permanent_intelligence": 0,
		"permanent_hp": 0,
		"permanent_damage": 0,
		"permanent_damage_tenths": 0,
		"permanent_attack_speed_percent": 0,
		"permanent_spell_damage_percent": 0,
		"permanent_attack_range": 0,
		"permanent_physical_crit_multiplier": 0,
		"particle_bonus_per_two_charges": 0,
		"deferred_child_coin_on_destroy": 0,
	}
	if item_idx < 0 or item_idx >= item_db.size():
		return out
	var item_name: String = get_item_name_by_index(item_db, item_idx)
	var base_level: int = _get_item_level(item_db, item_idx)
	if item_name == BLOODHEART_ITEM_NAME:
		out["dynamic_level"] = base_level
	return out


func sanitize_inventory_meta_entry(item_db: Array, entry_variant: Variant, item_idx: int = -1) -> Dictionary:
	var out: Dictionary = create_default_inventory_meta_entry(item_db, item_idx)
	if entry_variant is Dictionary:
		var entry: Dictionary = entry_variant
		out["charges"] = maxi(int(entry.get("charges", out["charges"])), 0)
		out["stored_level"] = maxi(int(entry.get("stored_level", out["stored_level"])), 0)
		out["dynamic_level"] = maxi(int(entry.get("dynamic_level", out["dynamic_level"])), 0)
		out["coin_layers"] = maxi(int(entry.get("coin_layers", out["coin_layers"])), 0)
		out["permanent_strength"] = int(entry.get("permanent_strength", out["permanent_strength"]))
		out["permanent_agility"] = maxi(int(entry.get("permanent_agility", out["permanent_agility"])), 0)
		out["permanent_intelligence"] = int(entry.get("permanent_intelligence", out["permanent_intelligence"]))
		out["permanent_hp"] = maxi(int(entry.get("permanent_hp", out["permanent_hp"])), 0)
		out["permanent_damage"] = int(entry.get("permanent_damage", out["permanent_damage"]))
		out["permanent_damage_tenths"] = int(entry.get("permanent_damage_tenths", out["permanent_damage_tenths"]))
		out["permanent_attack_speed_percent"] = int(entry.get("permanent_attack_speed_percent", out["permanent_attack_speed_percent"]))
		out["permanent_spell_damage_percent"] = maxi(int(entry.get("permanent_spell_damage_percent", out["permanent_spell_damage_percent"])), 0)
		out["permanent_attack_range"] = maxi(int(entry.get("permanent_attack_range", out["permanent_attack_range"])), 0)
		out["permanent_physical_crit_multiplier"] = maxi(int(entry.get("permanent_physical_crit_multiplier", out["permanent_physical_crit_multiplier"])), 0)
		out["particle_bonus_per_two_charges"] = maxi(int(entry.get("particle_bonus_per_two_charges", out["particle_bonus_per_two_charges"])), 0)
		out["deferred_child_coin_on_destroy"] = maxi(int(entry.get("deferred_child_coin_on_destroy", out["deferred_child_coin_on_destroy"])), 0)
	var item_name: String = get_item_name_by_index(item_db, item_idx)
	var base_level: int = 0
	if item_idx >= 0 and item_idx < item_db.size():
		base_level = _get_item_level(item_db, item_idx)
	if item_name == BLOODHEART_ITEM_NAME:
		out["dynamic_level"] = maxi(int(out.get("dynamic_level", 0)), base_level)
	return out


func sanitize_inventory_meta_array(item_db: Array, meta_variant: Variant, inventory: Array) -> Array:
	var out: Array = []
	var source: Array = []
	if meta_variant is Array:
		source = meta_variant
	for i in range(inventory.size()):
		var entry_variant: Variant = {}
		if i < source.size():
			entry_variant = source[i]
		out.append(sanitize_inventory_meta_entry(item_db, entry_variant, int(inventory[i])))
	return out


func get_inventory_meta_entry(item_db: Array, meta_array: Array, slot_idx: int, item_idx: int = -1) -> Dictionary:
	if slot_idx >= 0 and slot_idx < meta_array.size() and meta_array[slot_idx] is Dictionary:
		return (meta_array[slot_idx] as Dictionary).duplicate(true)
	return create_default_inventory_meta_entry(item_db, item_idx)


func set_inventory_meta_entry(item_db: Array, meta_array: Array, slot_idx: int, entry: Dictionary, item_idx: int = -1) -> void:
	if slot_idx < 0:
		return
	while meta_array.size() <= slot_idx:
		meta_array.append(create_default_inventory_meta_entry(item_db, item_idx))
	meta_array[slot_idx] = sanitize_inventory_meta_entry(item_db, entry, item_idx)


func find_item_slots_by_name(item_db: Array, inventory: Array, item_name: String) -> Array[int]:
	var slots: Array[int] = []
	for i in range(inventory.size()):
		if get_item_name_by_index(item_db, int(inventory[i])) == item_name:
			slots.append(i)
	return slots


func get_effective_inventory_item_level(item_db: Array, item_idx: int, slot_idx: int, meta_array: Array, inventory: Array = []) -> int:
	if item_idx < 0 or item_idx >= item_db.size():
		return 0
	var item_name: String = get_item_name_by_index(item_db, item_idx)
	if not inventory.is_empty() and find_item_slots_by_name(item_db, inventory, GOLD_COIN_ITEM_NAME).size() > 0 and item_name != GOLD_COIN_ITEM_NAME:
		return 0
	var base_level: int = _get_item_level(item_db, item_idx)
	var entry: Dictionary = get_inventory_meta_entry(item_db, meta_array, slot_idx, item_idx)
	if item_name == BLOODHEART_ITEM_NAME:
		return maxi(int(entry.get("dynamic_level", base_level)), base_level)
	if item_name == EVIL_ORB_ITEM_NAME:
		return maxi(int(entry.get("dynamic_level", 0)), 0)
	return base_level


func get_inventory_total_item_level(item_db: Array, inventory: Array, meta_array: Array) -> int:
	var total: int = 0
	for i in range(inventory.size()):
		total += maxi(get_effective_inventory_item_level(item_db, int(inventory[i]), i, meta_array, inventory), 0)
	return total


func build_inventory_signature(inv: Array, owner_key: int, runtime_meta: Array, destroy_state: Dictionary, coin_state: Dictionary) -> String:
	var parts: Array[String] = []
	for value in inv:
		parts.append(str(int(value)))
	var runtime_suffix: String = "|%s|%s|%s" % [
		JSON.stringify(runtime_meta),
		JSON.stringify(destroy_state),
		JSON.stringify(coin_state),
	]
	return "%d|%s%s" % [owner_key, ",".join(parts), runtime_suffix]


func _get_item_level(item_db: Array, item_idx: int) -> int:
	if item_idx < 0 or item_idx >= item_db.size():
		return 0
	var item_data: Dictionary = item_db[item_idx] if item_db[item_idx] is Dictionary else {}
	var stat: String = str(item_data.get("stat", ""))
	if stat.begins_with("Lv"):
		var space_idx: int = stat.find(" ")
		if space_idx > 2:
			return int(stat.substr(2, space_idx - 2))
	return 1


func _variant_to_bool(value: Variant, fallback: bool = false) -> bool:
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
