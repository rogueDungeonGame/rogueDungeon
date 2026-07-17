extends RefCounted
class_name EquipmentActionService


func sanitize_inventory(values: Array, item_db_size: int, max_slots: int = 6) -> Array:
	var out: Array = []
	for value in values:
		var idx: int = int(value)
		if idx < 0 or idx >= item_db_size:
			continue
		out.append(idx)
		if out.size() >= max_slots:
			break
	return out


func build_peer_state(
	baseline_state: Dictionary,
	fallback_gold: int,
	item_db_size: int,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_destroy_faction_state_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	sanitize_offer_ids_fn: Callable,
	roll_shop_items_fn: Callable,
	variant_to_bool_fn: Callable
) -> Dictionary:
	var shop_level: int = clampi(int(baseline_state.get("shop_level", 1)), 1, 7)
	var gold: int = clampi(int(baseline_state.get("gold", fallback_gold)), 0, 200000)
	var inventory_values: Array = _call_array(
		to_int_array_fn, [baseline_state.get("inventory", [])]
	)
	var inventory: Array = sanitize_inventory(inventory_values, item_db_size)
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [baseline_state.get("inventory_meta", []), inventory]
	)
	var destroy_faction_state: Dictionary = _call_dict(
		sanitize_destroy_faction_state_fn, [baseline_state.get("destroy_faction_state", {})]
	)
	var coin_faction_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [baseline_state.get("coin_faction_state", {})]
	)
	var offer_values: Array = _call_array(
		to_int_array_fn, [baseline_state.get("shop_offer_ids", [])]
	)
	var offer_ids: Array = _call_array(sanitize_offer_ids_fn, [offer_values, shop_level])
	if offer_ids.is_empty():
		offer_ids = _call_array(
			roll_shop_items_fn,
			[
				shop_level,
				{
					"inventory": inventory,
				}
			]
		)
	return {
		"inventory": inventory,
		"inventory_meta": inventory_meta,
		"destroy_faction_state": destroy_faction_state,
		"coin_faction_state": coin_faction_state,
		"gold": gold,
		"shop_level": shop_level,
		"shop_offer_ids": offer_ids,
		"destroy_mode":
		_call_bool(variant_to_bool_fn, [baseline_state.get("destroy_mode", false), false]),
		"hero_level": maxi(int(baseline_state.get("hero_level", 1)), 1),
	}


func apply_refresh_shop(
	state: Dictionary,
	shop_refresh_cost: int,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	can_refresh_with_coin_rules_fn: Callable,
	apply_charge_refresh_effects_fn: Callable,
	roll_shop_items_fn: Callable,
	apply_coin_refresh_effects_fn: Callable
) -> String:
	var gold: int = maxi(int(state.get("gold", 0)), 0)
	if gold < shop_refresh_cost:
		return "gold_not_enough"
	var shop_level: int = clampi(int(state.get("shop_level", 1)), 1, 7)
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	var can_refresh_variant: Variant = can_refresh_with_coin_rules_fn.call(inventory, coin_state)
	if not _bool_from_variant(can_refresh_variant, false):
		return "coin_refresh_limit_reached"
	gold -= shop_refresh_cost
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	apply_charge_refresh_effects_fn.call(inventory, inventory_meta)
	state["gold"] = gold
	state["shop_level"] = shop_level
	state["inventory_meta"] = inventory_meta
	state["shop_offer_ids"] = _call_array(roll_shop_items_fn, [shop_level, state])
	var offers: Array = _call_array(to_int_array_fn, [state.get("shop_offer_ids", [])])
	apply_coin_refresh_effects_fn.call(inventory, inventory_meta, coin_state, offers, shop_level)
	state["shop_offer_ids"] = offers
	state["coin_faction_state"] = coin_state
	return ""


func apply_upgrade_shop(
	state: Dictionary, shop_upgrade_cost: Dictionary, _roll_shop_items_fn: Callable
) -> String:
	var shop_level: int = clampi(int(state.get("shop_level", 1)), 1, 7)
	if shop_level >= 7:
		return "shop_max_level"
	var upgrade_cost: int = int(shop_upgrade_cost.get(shop_level, 0))
	var gold: int = maxi(int(state.get("gold", 0)), 0)
	if gold < upgrade_cost:
		return "gold_not_enough"
	gold -= upgrade_cost
	shop_level = clampi(shop_level + 1, 1, 7)
	state["gold"] = gold
	state["shop_level"] = shop_level
	if not state.has("shop_offer_ids"):
		state["shop_offer_ids"] = []
	return ""


func apply_set_destroy_mode(
	state: Dictionary, payload: Dictionary, variant_to_bool_fn: Callable
) -> String:
	state["destroy_mode"] = _call_bool(variant_to_bool_fn, [payload.get("enabled", false), false])
	return ""


func apply_buy_item(
	state: Dictionary,
	payload: Dictionary,
	item_db: Array,
	get_item_cost_fn: Callable,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	get_item_name_by_index_fn: Callable,
	is_charge_bottle_item_name_fn: Callable,
	is_coin_item_for_effects_fn: Callable,
	variant_to_bool_fn: Callable,
	_get_item_level_fn: Callable,
	is_blocked_shop_item_fn: Callable,
	create_default_inventory_meta_entry_fn: Callable,
	apply_charge_item_gain_effects_fn: Callable,
	apply_coin_item_gain_effects_fn: Callable,
	synthesize_inventory_in_place_fn: Callable,
	max_slots: int = 6,
	protected_coin_name: String = "金硬币"
) -> String:
	var item_idx: int = int(payload.get("item_idx", -1))
	if item_idx < 0 or item_idx >= item_db.size():
		return "invalid_item_idx"
	var offers: Array = _call_array(to_int_array_fn, [state.get("shop_offer_ids", [])])
	var offer_pos: int = offers.find(item_idx)
	if offer_pos < 0:
		return "item_not_offered"
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	var item_data: Dictionary = item_db[item_idx] if item_db[item_idx] is Dictionary else {}
	if _call_bool(is_blocked_shop_item_fn, [item_data]):
		offers.remove_at(offer_pos)
		state["shop_offer_ids"] = offers
		return "item_blocked"
	var item_name: String = _call_string(get_item_name_by_index_fn, [item_idx])
	var is_auto_consume_charge_bottle: bool = _call_bool(is_charge_bottle_item_name_fn, [item_name])
	var is_coin_item: bool = _call_bool(is_coin_item_for_effects_fn, [item_data])
	var auto_destroy_coin_purchase: bool = (
		is_coin_item
		and item_name != protected_coin_name
		and _call_bool(
			variant_to_bool_fn, [coin_state.get("auto_destroy_coin_enabled", false), false]
		)
	)
	if (
		inventory.size() >= max_slots
		and not is_auto_consume_charge_bottle
		and not auto_destroy_coin_purchase
	):
		return "inventory_full"
	var item_cost: int = maxi(_call_int(get_item_cost_fn, [item_idx], 50), 0)
	var gold: int = maxi(int(state.get("gold", 0)), 0)
	if gold < item_cost:
		return "gold_not_enough"
	gold -= item_cost
	inventory.append(item_idx)
	inventory_meta.append(_call_dict(create_default_inventory_meta_entry_fn, [item_idx]))
	_call_any(apply_charge_item_gain_effects_fn, [inventory, inventory_meta, item_idx])
	if is_coin_item:
		_call_any(
			apply_coin_item_gain_effects_fn, [inventory, inventory_meta, coin_state, item_idx]
		)
	if is_auto_consume_charge_bottle:
		var remove_idx: int = inventory.rfind(item_idx)
		if remove_idx >= 0:
			inventory.remove_at(remove_idx)
			if remove_idx < inventory_meta.size():
				inventory_meta.remove_at(remove_idx)
	if auto_destroy_coin_purchase:
		var auto_remove_idx: int = inventory.rfind(item_idx)
		if auto_remove_idx >= 0:
			inventory.remove_at(auto_remove_idx)
			if auto_remove_idx < inventory_meta.size():
				inventory_meta.remove_at(auto_remove_idx)
	offers.remove_at(offer_pos)
	_call_any(synthesize_inventory_in_place_fn, [inventory, inventory_meta])
	state["gold"] = gold
	state["inventory"] = inventory
	state["inventory_meta"] = inventory_meta
	state["coin_faction_state"] = coin_state
	state["shop_offer_ids"] = offers
	return ""


func apply_use_item(
	state: Dictionary,
	payload: Dictionary,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	use_inventory_item_in_place_fn: Callable
) -> String:
	var slot_idx: int = int(payload.get("slot_idx", -1))
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	if slot_idx < 0 or slot_idx >= inventory.size():
		return "invalid_slot_idx"
	if not _bool_from_variant(
		_call_any(
			use_inventory_item_in_place_fn, [inventory, inventory_meta, coin_state, slot_idx]
		),
		false
	):
		return "item_cannot_be_used"
	state["inventory"] = inventory
	state["inventory_meta"] = inventory_meta
	state["coin_faction_state"] = coin_state
	state["destroy_mode"] = false
	return ""


func apply_destroy_item(
	state: Dictionary,
	payload: Dictionary,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_destroy_faction_state_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	get_item_name_by_index_fn: Callable,
	get_inventory_meta_entry_fn: Callable,
	apply_destroy_faction_effects_before_removal_fn: Callable,
	apply_coin_destroy_effects_before_removal_fn: Callable,
	apply_charge_destroy_absorb_effect_fn: Callable,
	apply_destroy_faction_effects_after_removal_fn: Callable,
	apply_coin_destroy_effects_after_removal_fn: Callable,
	protected_coin_name: String = "金硬币"
) -> String:
	var slot_idx: int = int(payload.get("slot_idx", -1))
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	var destroy_state: Dictionary = _call_dict(
		sanitize_destroy_faction_state_fn, [state.get("destroy_faction_state", {})]
	)
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	if slot_idx < 0 or slot_idx >= inventory.size():
		return "invalid_slot_idx"
	var removed_item_idx: int = int(inventory[slot_idx])
	var removed_item_name: String = _call_string(get_item_name_by_index_fn, [removed_item_idx])
	if removed_item_name == protected_coin_name:
		return "item_cannot_be_destroyed"
	var removed_entry: Dictionary = _call_dict(
		get_inventory_meta_entry_fn, [inventory_meta, slot_idx, removed_item_idx]
	)
	_call_any(
		apply_destroy_faction_effects_before_removal_fn,
		[state, inventory, inventory_meta, destroy_state, slot_idx]
	)
	_call_any(
		apply_coin_destroy_effects_before_removal_fn,
		[state, inventory, inventory_meta, coin_state, slot_idx]
	)
	_call_any(apply_charge_destroy_absorb_effect_fn, [inventory, inventory_meta, slot_idx])
	inventory.remove_at(slot_idx)
	if slot_idx < inventory_meta.size():
		inventory_meta.remove_at(slot_idx)
	_call_any(apply_destroy_faction_effects_after_removal_fn, [inventory, inventory_meta])
	_call_any(
		apply_coin_destroy_effects_after_removal_fn,
		[inventory, inventory_meta, coin_state, removed_item_name, removed_entry]
	)
	state["inventory"] = inventory
	state["inventory_meta"] = inventory_meta
	state["destroy_faction_state"] = destroy_state
	state["coin_faction_state"] = coin_state
	state["destroy_mode"] = false
	return ""


func apply_battle_phase_started(
	state: Dictionary,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	apply_charge_battle_phase_start_effects_fn: Callable,
	apply_coin_battle_phase_start_effects_fn: Callable
) -> String:
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	var gold: int = maxi(int(state.get("gold", 0)), 0)
	_call_any(apply_charge_battle_phase_start_effects_fn, [inventory, inventory_meta])
	if _bool_from_variant(
		_call_any(apply_coin_battle_phase_start_effects_fn, [inventory, coin_state]), false
	):
		gold = 0
	state["gold"] = gold
	state["inventory_meta"] = inventory_meta
	state["coin_faction_state"] = coin_state
	return ""


func apply_battle_phase_ended(
	state: Dictionary,
	to_int_array_fn: Callable,
	sanitize_inventory_meta_array_fn: Callable,
	sanitize_coin_faction_state_fn: Callable,
	apply_charge_battle_phase_end_effects_fn: Callable,
	get_coin_battle_phase_end_gold_reward_fn: Callable
) -> String:
	var inventory: Array = _call_array(to_int_array_fn, [state.get("inventory", [])])
	var inventory_meta: Array = _call_array(
		sanitize_inventory_meta_array_fn, [state.get("inventory_meta", []), inventory]
	)
	var coin_state: Dictionary = _call_dict(
		sanitize_coin_faction_state_fn, [state.get("coin_faction_state", {})]
	)
	var gold: int = maxi(int(state.get("gold", 0)), 0)
	_call_any(apply_charge_battle_phase_end_effects_fn, [inventory, inventory_meta])
	gold += _call_int(get_coin_battle_phase_end_gold_reward_fn, [inventory, inventory_meta], 0)
	coin_state["refreshes_used_this_battle"] = 0
	state["gold"] = gold
	state["inventory_meta"] = inventory_meta
	state["coin_faction_state"] = coin_state
	return ""


func _call_array(callable_fn: Callable, args: Array = []) -> Array:
	var result: Variant = _call_any(callable_fn, args)
	if result is Array:
		return (result as Array).duplicate(true)
	return []


func _call_dict(callable_fn: Callable, args: Array = []) -> Dictionary:
	var result: Variant = _call_any(callable_fn, args)
	if result is Dictionary:
		return (result as Dictionary).duplicate(true)
	return {}


func _call_bool(callable_fn: Callable, args: Array = [], fallback: bool = false) -> bool:
	var result: Variant = _call_any(callable_fn, args)
	return _bool_from_variant(result, fallback)


func _call_string(callable_fn: Callable, args: Array = []) -> String:
	var result: Variant = _call_any(callable_fn, args)
	if result == null:
		return ""
	return str(result)


func _call_int(callable_fn: Callable, args: Array = [], fallback: int = 0) -> int:
	var result: Variant = _call_any(callable_fn, args)
	if result is int:
		return result
	if result is float:
		return roundi(result)
	if result is String:
		var text: String = (result as String).strip_edges()
		if text.is_valid_int():
			return text.to_int()
	return fallback


func _call_any(callable_fn: Callable, raw_args: Array = []) -> Variant:
	if callable_fn == null or not callable_fn.is_valid():
		return null
	var args: Array = raw_args.duplicate()
	while not args.is_empty() and args[args.size() - 1] == null:
		args.remove_at(args.size() - 1)
	return callable_fn.callv(args)


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
