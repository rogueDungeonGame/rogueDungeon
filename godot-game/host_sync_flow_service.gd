extends RefCounted
class_name HostSyncFlowService


func reset_world_sync_adaptive_runtime(
		world_sync_interval_sec: float,
		world_sync_interval_min_sec: float,
		world_sync_interval_max_sec: float,
		world_mob_chunk_size: int,
		world_mob_chunk_size_min: int,
		world_mob_chunk_size_max: int
	) -> Dictionary:
	var min_interval: float = minf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	var max_interval: float = maxf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	var dynamic_world_sync_interval_sec: float = clampf(world_sync_interval_sec, min_interval, max_interval)
	var min_chunk: int = maxi(mini(world_mob_chunk_size_min, world_mob_chunk_size_max), 1)
	var max_chunk: int = maxi(maxi(world_mob_chunk_size_min, world_mob_chunk_size_max), min_chunk)
	var dynamic_world_mob_chunk_size: int = clampi(world_mob_chunk_size, min_chunk, max_chunk)
	return {
		"dynamic_world_sync_interval_sec": dynamic_world_sync_interval_sec,
		"dynamic_world_mob_chunk_size": dynamic_world_mob_chunk_size,
		"world_mob_chunk_cursor": 0,
		"last_world_packet_bytes": 0,
	}


func get_active_world_sync_interval_sec(
		adaptive_world_sync_enabled: bool,
		world_sync_interval_sec: float,
		dynamic_world_sync_interval_sec: float,
		world_sync_interval_min_sec: float,
		world_sync_interval_max_sec: float
	) -> float:
	if not adaptive_world_sync_enabled:
		return maxf(world_sync_interval_sec, 0.02)
	var min_interval: float = minf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	var max_interval: float = maxf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	return clampf(dynamic_world_sync_interval_sec, min_interval, max_interval)


func get_active_world_mob_chunk_size(
		total_mobs: int,
		adaptive_world_sync_enabled: bool,
		world_mob_chunk_size: int,
		dynamic_world_mob_chunk_size: int
	) -> int:
	if total_mobs <= 0:
		return 0
	var base_chunk: int = world_mob_chunk_size
	if adaptive_world_sync_enabled:
		base_chunk = dynamic_world_mob_chunk_size
	return clampi(base_chunk, 1, total_mobs)


func build_host_tick_plan(input: Dictionary) -> Dictionary:
	var safe_delta: float = maxf(float(input.get("delta", 0.0)), 0.0)
	var hero_send_elapsed_sec: float = float(input.get("hero_send_elapsed_sec", 0.0))
	var world_send_elapsed_sec: float = float(input.get("world_send_elapsed_sec", 0.0))
	var world_reliable_keyframe_elapsed_sec: float = float(input.get("world_reliable_keyframe_elapsed_sec", 0.0))
	var has_peers: bool = bool(input.get("has_peers", false))
	hero_send_elapsed_sec += safe_delta
	world_send_elapsed_sec += safe_delta
	world_reliable_keyframe_elapsed_sec += safe_delta

	var result: Dictionary = {
		"hero_send_elapsed_sec": hero_send_elapsed_sec,
		"world_send_elapsed_sec": world_send_elapsed_sec,
		"world_reliable_keyframe_elapsed_sec": world_reliable_keyframe_elapsed_sec,
	}
	if not has_peers:
		return result

	var hero_snapshot_interval: float = maxf(float(input.get("hero_sync_interval_sec", 0.02)), 0.02)
	if hero_send_elapsed_sec >= hero_snapshot_interval:
		result["hero_send_elapsed_sec"] = fmod(hero_send_elapsed_sec, hero_snapshot_interval)
		result["send_hero_snapshot"] = true
	else:
		result["send_hero_snapshot"] = false

	var active_world_interval: float = maxf(float(input.get("active_world_interval_sec", 0.02)), 0.02)
	if world_send_elapsed_sec >= active_world_interval:
		result["world_send_elapsed_sec"] = fmod(world_send_elapsed_sec, active_world_interval)
		result["send_world_snapshot"] = true
	else:
		result["send_world_snapshot"] = false

	var keyframe_interval: float = maxf(float(input.get("world_reliable_keyframe_interval_sec", 0.25)), 0.25)
	if world_reliable_keyframe_elapsed_sec >= keyframe_interval:
		result["world_reliable_keyframe_elapsed_sec"] = fmod(world_reliable_keyframe_elapsed_sec, keyframe_interval)
		result["send_world_keyframe"] = true
	else:
		result["send_world_keyframe"] = false
	return result


func adjust_dynamic_world_sync_interval(
		adaptive_world_sync_enabled: bool,
		snapshot: Dictionary,
		packet_bytes: int,
		world_packet_budget_bytes: int,
		world_sync_interval_min_sec: float,
		world_sync_interval_max_sec: float,
		dynamic_world_sync_interval_sec: float,
		world_sync_backoff_step_sec: float,
		world_sync_recover_step_sec: float,
		world_mob_chunk_size_min: int,
		world_mob_chunk_size_max: int,
		dynamic_world_mob_chunk_size: int,
		extract_mob_count_fn: Callable
	) -> Dictionary:
	if not adaptive_world_sync_enabled:
		return {
			"dynamic_world_sync_interval_sec": dynamic_world_sync_interval_sec,
			"dynamic_world_mob_chunk_size": dynamic_world_mob_chunk_size,
		}
	var min_interval: float = minf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	var max_interval: float = maxf(world_sync_interval_min_sec, world_sync_interval_max_sec)
	var budget: int = maxi(world_packet_budget_bytes, 256)
	var mob_count: int = _call_int(extract_mob_count_fn, [snapshot], 0)
	var over_budget: bool = packet_bytes > budget
	var severe_over_budget: bool = packet_bytes > int(round(float(budget) * 1.35))
	var heavy_mobs: bool = mob_count >= 8
	var medium_pressure: bool = packet_bytes > int(round(float(budget) * 0.78))
	var next_interval: float = dynamic_world_sync_interval_sec
	if severe_over_budget:
		next_interval = minf(next_interval + maxf(world_sync_backoff_step_sec, 0.005) * 1.8, max_interval)
	elif over_budget:
		next_interval = minf(next_interval + maxf(world_sync_backoff_step_sec, 0.005), max_interval)
	elif heavy_mobs and medium_pressure:
		next_interval = minf(next_interval + maxf(world_sync_backoff_step_sec, 0.005) * 0.35, max_interval)
	else:
		next_interval = maxf(next_interval - maxf(world_sync_recover_step_sec, 0.003), min_interval)

	var min_chunk: int = maxi(mini(world_mob_chunk_size_min, world_mob_chunk_size_max), 1)
	var max_chunk: int = maxi(maxi(world_mob_chunk_size_min, world_mob_chunk_size_max), min_chunk)
	var next_chunk: int = dynamic_world_mob_chunk_size
	if severe_over_budget or over_budget:
		if next_chunk > min_chunk:
			next_chunk -= 1
	elif packet_bytes < int(round(float(budget) * 0.55)):
		if next_chunk < max_chunk:
			next_chunk += 1
	next_chunk = clampi(next_chunk, min_chunk, max_chunk)
	return {
		"dynamic_world_sync_interval_sec": next_interval,
		"dynamic_world_mob_chunk_size": next_chunk,
	}


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
