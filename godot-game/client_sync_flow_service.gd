extends RefCounted
class_name ClientSyncFlowService


func advance_client_ping(
	mode_raw: String,
	ping_elapsed_sec: float,
	interval_sec: float,
	current_ping_seq: int,
	ping_sent_ms: Dictionary,
	now_ms: int
) -> Dictionary:
	if mode_raw.strip_edges().to_lower() != "client":
		return {
			"should_send": false,
			"ping_elapsed_sec": ping_elapsed_sec,
			"next_ping_seq": current_ping_seq,
			"ping_sent_ms": _dict_copy(ping_sent_ms),
		}
	var safe_interval: float = maxf(interval_sec, 0.1)
	if ping_elapsed_sec < safe_interval:
		return {
			"should_send": false,
			"ping_elapsed_sec": ping_elapsed_sec,
			"next_ping_seq": current_ping_seq,
			"ping_sent_ms": _dict_copy(ping_sent_ms),
		}
	var next_seq: int = current_ping_seq + 1
	var next_sent_ms: Dictionary = _dict_copy(ping_sent_ms)
	next_sent_ms[next_seq] = now_ms
	var keep_from_seq: int = maxi(next_seq - 64, 0)
	for key_variant in next_sent_ms.keys():
		var old_seq: int = int(key_variant)
		if old_seq < keep_from_seq:
			next_sent_ms.erase(old_seq)
	return {
		"should_send": true,
		"ping_elapsed_sec": fmod(ping_elapsed_sec, safe_interval),
		"next_ping_seq": next_seq,
		"ping_sent_ms": next_sent_ms,
		"seq": next_seq,
		"sent_ms": now_ms,
	}


func should_send_equipment_state(
	equipment_signature: String, last_sent_equipment_signature: String
) -> bool:
	return equipment_signature != last_sent_equipment_signature


func should_send_client_input(send_elapsed_sec: float, send_interval_sec: float) -> Dictionary:
	var safe_interval: float = maxf(send_interval_sec, 0.01)
	var should_send: bool = send_elapsed_sec >= safe_interval
	return {
		"should_send": should_send,
		"next_send_elapsed_sec":
		fmod(send_elapsed_sec, safe_interval) if should_send else send_elapsed_sec,
	}


func filter_skill_event_for_send(
	hero_state: Dictionary, last_sent_skill_event_seq: int
) -> Dictionary:
	var next_state: Dictionary = hero_state.duplicate(true)
	var next_last_seq: int = last_sent_skill_event_seq
	if next_state.has("skill_event"):
		var event_variant: Variant = next_state.get("skill_event", null)
		if event_variant is Dictionary:
			var event_state: Dictionary = event_variant
			var event_seq: int = _int_from_variant(event_state.get("seq", -1), -1)
			if event_seq > next_last_seq:
				next_last_seq = event_seq
			else:
				next_state.erase("skill_event")
		else:
			next_state.erase("skill_event")
	return {
		"hero_state": next_state,
		"next_last_sent_skill_event_seq": next_last_seq,
	}


func should_send_hero_command(
	mode_raw: String,
	network_running: bool,
	has_connected_peer: bool,
	command: Dictionary,
	last_sent_seq: int,
	int_from_variant_fn: Callable
) -> Dictionary:
	if mode_raw.strip_edges().to_lower() != "client":
		return {"should_send": false, "next_last_sent_seq": last_sent_seq}
	if not network_running or not has_connected_peer or command.is_empty():
		return {"should_send": false, "next_last_sent_seq": last_sent_seq}
	var seq: int = _call_int(int_from_variant_fn, [command.get("seq", -1), -1], -1)
	if seq <= last_sent_seq:
		return {"should_send": false, "next_last_sent_seq": last_sent_seq}
	return {
		"should_send": true,
		"next_last_sent_seq": seq,
		"command": command.duplicate(true),
	}


func build_enemy_damage_request(
	current_seq: int,
	target_path: String,
	amount: int,
	max_range: float,
	source: String,
	context: Dictionary
) -> Dictionary:
	var normalized_target_path: String = target_path.strip_edges()
	var safe_amount: int = maxi(amount, 0)
	if normalized_target_path.is_empty() or safe_amount <= 0:
		return {
			"ok": false,
			"next_seq": current_seq,
		}
	var next_seq: int = current_seq + 1
	return {
		"ok": true,
		"next_seq": next_seq,
		"event":
		{
			"seq": next_seq,
			"target_path": normalized_target_path,
			"amount": safe_amount,
			"max_range": max_range,
			"source": source.strip_edges().to_lower(),
			"context": context.duplicate(true),
		}
	}


func build_equipment_action_request(
	current_request_seq: int, action: String, payload: Dictionary, baseline_state: Dictionary
) -> Dictionary:
	var action_text: String = action.strip_edges().to_lower()
	if action_text.is_empty():
		return {
			"ok": false,
			"next_request_seq": current_request_seq,
		}
	var next_request_seq: int = current_request_seq + 1
	return {
		"ok": true,
		"next_request_seq": next_request_seq,
		"request":
		{
			"action": action_text,
			"request_seq": next_request_seq,
			"payload": payload.duplicate(true),
			"baseline": baseline_state.duplicate(true),
		}
	}


func _dict_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


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


func _call_int(callable_fn: Callable, args: Array = [], fallback: int = 0) -> int:
	if callable_fn == null or not callable_fn.is_valid():
		return fallback
	var result: Variant = callable_fn.callv(args)
	return _int_from_variant(result, fallback)
