extends RefCounted
class_name ShopCatalogHelper

var _default_build_name: String = "无派系"
var _build_alias_map: Dictionary = {}
var _item_name_overrides: Dictionary = {}
var _item_build_overrides: Dictionary = {}
var _blocked_shop_builds: Dictionary = {}
var _item_secondary_builds: Dictionary = {}
var _blocked_shop_item_exact_names: Dictionary = {}
var _blocked_shop_item_name_keywords: Array = []
var _level_weights: Dictionary = {}
var _charge_bottle_appearance_item_names: Dictionary = {}
var _charge_bottle_shop_item_names: Dictionary = {}
var _shop_item_count: Dictionary = {}
var _build_tabs: Array = []


func _init(config: Dictionary = {}) -> void:
	_default_build_name = str(config.get("default_build_name", _default_build_name)).strip_edges()
	if _default_build_name == "":
		_default_build_name = "无派系"
	_build_alias_map = _dict_copy(config.get("build_alias_map", {}))
	_item_name_overrides = _dict_copy(config.get("item_name_overrides", {}))
	_item_build_overrides = _dict_copy(config.get("item_build_overrides", {}))
	_blocked_shop_builds = _dict_copy(config.get("blocked_shop_builds", {}))
	_item_secondary_builds = _dict_copy(config.get("item_secondary_builds", {}))
	_blocked_shop_item_exact_names = _dict_copy(config.get("blocked_shop_item_exact_names", {}))
	_blocked_shop_item_name_keywords = _array_copy(config.get("blocked_shop_item_name_keywords", []))
	_level_weights = _dict_copy(config.get("level_weights", {}))
	_charge_bottle_appearance_item_names = _dict_copy(config.get("charge_bottle_appearance_item_names", {}))
	_charge_bottle_shop_item_names = _dict_copy(config.get("charge_bottle_shop_item_names", {}))
	_shop_item_count = _dict_copy(config.get("shop_item_count", {}))
	_build_tabs = _array_copy(config.get("build_tabs", []))


func normalize_build_name(raw_build_name: String) -> String:
	var build_name: String = raw_build_name.strip_edges()
	if build_name == "":
		return _default_build_name
	var alias_variant: Variant = _build_alias_map.get(build_name, null)
	if alias_variant != null:
		var mapped_build: String = str(alias_variant).strip_edges()
		if mapped_build != "":
			return mapped_build
	return build_name


func is_blocked_shop_build(build_name: String) -> bool:
	return _blocked_shop_builds.has(normalize_build_name(build_name))


func is_blocked_shop_item(item_data: Dictionary) -> bool:
	if is_blocked_shop_build(str(item_data.get("build", _default_build_name))):
		return true
	var item_name: String = str(item_data.get("name", "")).strip_edges()
	if item_name == "":
		return false
	var secondary_builds_variant: Variant = _item_secondary_builds.get(item_name, [])
	if secondary_builds_variant is Array:
		var secondary_builds: Array = secondary_builds_variant
		for secondary_build_variant in secondary_builds:
			if is_blocked_shop_build(str(secondary_build_variant)):
				return true
	if _blocked_shop_item_exact_names.has(item_name):
		return true
	for keyword_variant in _blocked_shop_item_name_keywords:
		var keyword: String = str(keyword_variant).strip_edges()
		if keyword != "" and item_name.find(keyword) != -1:
			return true
	return false


func resolve_item_name(raw_item_name: String) -> String:
	var item_name: String = raw_item_name.strip_edges()
	if item_name == "":
		return ""
	var override_variant: Variant = _item_name_overrides.get(item_name, null)
	if override_variant == null:
		return item_name
	var override_name: String = str(override_variant).strip_edges()
	if override_name == "":
		return item_name
	return override_name


func resolve_item_build_name(item_name: String, raw_build_name: String, stat_text: String = "") -> String:
	var normalized_build: String = normalize_build_name(raw_build_name)
	var override_variant: Variant = _item_build_overrides.get(item_name, null)
	if override_variant != null:
		var override_build: String = normalize_build_name(str(override_variant))
		if override_build != "":
			return override_build
	if normalized_build == _default_build_name and item_name.find("咒文") != -1:
		return "咒文"
	if normalized_build == _default_build_name and stat_text.find("战备") != -1:
		return "备战"
	return normalized_build


func get_item_level(item: Dictionary) -> int:
	var stat: String = str(item.get("stat", ""))
	if stat.begins_with("Lv"):
		var space_idx: int = stat.find(" ")
		if space_idx > 2:
			return int(stat.substr(2, space_idx - 2))
	return 1


func get_shop_roll_weights_for_level(level: int) -> Dictionary:
	var safe_level: int = clampi(level, 1, 7)
	var base_weights_variant: Variant = _level_weights.get(safe_level, {1: 100})
	if not (base_weights_variant is Dictionary):
		return {1: 100}
	var base_weights: Dictionary = base_weights_variant
	var adjusted_weights: Dictionary = {}
	for lv_variant in base_weights.keys():
		var lv: int = int(lv_variant)
		adjusted_weights[lv] = maxi(int(base_weights[lv_variant]), 0) * 2

	var same_level_weight: int = int(adjusted_weights.get(safe_level, 0))
	if same_level_weight <= 0:
		return adjusted_weights

	var moved_weight: int = same_level_weight / 2
	adjusted_weights[safe_level] = same_level_weight - moved_weight
	var receiver_level: int = safe_level - 1
	if safe_level == 1:
		receiver_level = 2
	adjusted_weights[receiver_level] = int(adjusted_weights.get(receiver_level, 0)) + moved_weight
	return adjusted_weights


func get_shop_build_sort_rank(build_name: String) -> int:
	for i in range(_build_tabs.size()):
		if str(_build_tabs[i]) == build_name:
			return i
	return _build_tabs.size() + 100


func is_shop_offer_before_for_display(left_idx: int, right_idx: int, item_db: Array) -> bool:
	if left_idx == right_idx:
		return false
	if left_idx < 0 or left_idx >= item_db.size():
		return false
	if right_idx < 0 or right_idx >= item_db.size():
		return true
	var left_data: Dictionary = item_db[left_idx] if item_db[left_idx] is Dictionary else {}
	var right_data: Dictionary = item_db[right_idx] if item_db[right_idx] is Dictionary else {}
	var left_level: int = get_item_level(left_data)
	var right_level: int = get_item_level(right_data)
	if left_level != right_level:
		return left_level < right_level
	var left_build: String = normalize_build_name(str(left_data.get("build", _default_build_name)))
	var right_build: String = normalize_build_name(str(right_data.get("build", _default_build_name)))
	var left_build_rank: int = get_shop_build_sort_rank(left_build)
	var right_build_rank: int = get_shop_build_sort_rank(right_build)
	if left_build_rank != right_build_rank:
		return left_build_rank < right_build_rank
	var build_cmp: int = left_build.nocasecmp_to(right_build)
	if build_cmp != 0:
		return build_cmp < 0
	var left_name: String = str(left_data.get("name", ""))
	var right_name: String = str(right_data.get("name", ""))
	var name_cmp: int = left_name.nocasecmp_to(right_name)
	if name_cmp != 0:
		return name_cmp < 0
	return left_idx < right_idx


func sort_shop_offer_ids_for_display(offer_ids: Array, item_db: Array) -> Array[int]:
	var sorted_ids: Array[int] = []
	for offer_variant in offer_ids:
		var offer_idx: int = int(offer_variant)
		if offer_idx < 0 or offer_idx >= item_db.size():
			continue
		var item_data: Dictionary = item_db[offer_idx] if item_db[offer_idx] is Dictionary else {}
		if is_blocked_shop_item(item_data):
			continue
		var insert_at: int = sorted_ids.size()
		for i in range(sorted_ids.size()):
			if is_shop_offer_before_for_display(offer_idx, sorted_ids[i], item_db):
				insert_at = i
				break
		sorted_ids.insert(insert_at, offer_idx)
	return sorted_ids


func sanitize_offer_ids(values: Array, shop_level: int, item_db: Array) -> Array:
	var out: Array = []
	var max_count: int = clampi(int(_shop_item_count.get(shop_level, 4)), 1, 8)
	for value in values:
		var idx: int = int(value)
		if idx < 0 or idx >= item_db.size():
			continue
		var item_data: Dictionary = item_db[idx] if item_db[idx] is Dictionary else {}
		if is_blocked_shop_item(item_data):
			continue
		if idx in out:
			continue
		out.append(idx)
		if out.size() >= max_count:
			break
	return out


func roll_shop_offer_ids(shop_level: int, item_db: Array, inventory: Array) -> Array[int]:
	var safe_level: int = clampi(shop_level, 1, 7)
	var offered: Array[int] = []
	var target_count: int = int(_shop_item_count.get(safe_level, 4))
	var weights: Dictionary = get_shop_roll_weights_for_level(safe_level)
	if item_db.is_empty() or weights.is_empty():
		return offered
	var total_weight: int = 0
	for w_variant in weights.values():
		total_weight += maxi(int(w_variant), 0)
	total_weight = maxi(total_weight, 1)
	for _n in range(maxi(target_count, 1)):
		var rolled_level: int = 1
		var roll: int = randi() % total_weight
		var accum: int = 0
		for lv_variant in weights.keys():
			var weight_value: int = maxi(int(weights[lv_variant]), 0)
			accum += weight_value
			if roll < accum:
				rolled_level = int(lv_variant)
				break
		var candidates: Array[int] = []
		for i in range(item_db.size()):
			var item_data: Dictionary = item_db[i] if item_db[i] is Dictionary else {}
			if is_blocked_shop_item(item_data):
				continue
			if i in offered:
				continue
			if get_item_level(item_data) == rolled_level:
				append_shop_candidate_with_runtime_weight(candidates, i, inventory, item_db)
		if candidates.is_empty():
			for i in range(item_db.size()):
				var item_data: Dictionary = item_db[i] if item_db[i] is Dictionary else {}
				if is_blocked_shop_item(item_data):
					continue
				if i in offered:
					continue
				if get_item_level(item_data) <= rolled_level:
					append_shop_candidate_with_runtime_weight(candidates, i, inventory, item_db)
		if not candidates.is_empty():
			offered.append(candidates[randi() % candidates.size()])
	return offered


func _get_charge_bottle_shop_bonus_count(inventory: Array, item_db: Array) -> int:
	var bonus_count: int = 0
	for slot_idx in range(inventory.size()):
		var item_idx: int = int(inventory[slot_idx])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_name: String = _get_item_name_by_index(item_db, item_idx)
		if _charge_bottle_appearance_item_names.has(item_name):
			bonus_count += 1
	return bonus_count


func append_shop_candidate_with_runtime_weight(candidates: Array[int], item_idx: int, inventory: Array, item_db: Array) -> void:
	candidates.append(item_idx)
	if item_idx < 0 or item_idx >= item_db.size():
		return
	var item_name: String = _get_item_name_by_index(item_db, item_idx)
	if not _charge_bottle_shop_item_names.has(item_name):
		return
	var bonus_count: int = _get_charge_bottle_shop_bonus_count(inventory, item_db)
	for _idx in range(bonus_count):
		candidates.append(item_idx)


func _get_item_name_by_index(item_db: Array, item_idx: int) -> String:
	if item_idx < 0 or item_idx >= item_db.size():
		return ""
	var item_data: Dictionary = item_db[item_idx] if item_db[item_idx] is Dictionary else {}
	return str(item_data.get("name", "")).strip_edges()


func _dict_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _array_copy(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []
