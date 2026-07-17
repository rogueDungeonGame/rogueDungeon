extends RefCounted
class_name EquipmentAuthorityService

var _peer_states: Dictionary = {}
var _last_commits: Dictionary = {}


func ensure_peer_state(peer_id: int, baseline_state: Dictionary, build_state_fn: Callable) -> void:
	if peer_id <= 0:
		return
	if _peer_states.has(peer_id):
		return
	_peer_states[peer_id] = _build_state(baseline_state, build_state_fn)


func drop_peer_state(peer_id: int) -> void:
	if peer_id <= 0:
		return
	_peer_states.erase(peer_id)
	_last_commits.erase(peer_id)


func get_peer_state(peer_id: int) -> Dictionary:
	if peer_id <= 0:
		return {}
	var state_variant: Variant = _peer_states.get(peer_id, {})
	if state_variant is Dictionary:
		return (state_variant as Dictionary).duplicate(true)
	return {}


func grant_remote_gold_reward(peer_id: int, amount: int, build_state_fn: Callable) -> Dictionary:
	if peer_id <= 0 or amount == 0:
		return {}
	ensure_peer_state(peer_id, {}, build_state_fn)
	var next_state: Dictionary = get_peer_state(peer_id)
	if next_state.is_empty():
		next_state = _build_state({}, build_state_fn)
	next_state["gold"] = maxi(int(next_state.get("gold", 0)) + amount, 0)
	_peer_states[peer_id] = next_state.duplicate(true)
	return next_state


func handle_action(
	peer_id: int,
	request: Dictionary,
	baseline_state: Dictionary,
	build_state_fn: Callable,
	apply_action_fn: Callable
) -> Dictionary:
	if peer_id <= 0:
		return {
			"ok": false,
			"peer_id": peer_id,
			"action": "",
			"request_seq": -1,
			"reason": "invalid_peer_id",
			"state": {}
		}
	ensure_peer_state(peer_id, baseline_state, build_state_fn)
	var request_seq: int = int(request.get("request_seq", -1))
	var action: String = str(request.get("action", "")).strip_edges().to_lower()
	var last_commit_variant: Variant = _last_commits.get(peer_id, null)
	if request_seq >= 0 and last_commit_variant is Dictionary:
		var last_commit: Dictionary = last_commit_variant
		var last_request_seq: int = int(last_commit.get("request_seq", -2))
		if request_seq <= last_request_seq:
			return last_commit.duplicate(true)

	var payload: Dictionary = {}
	var payload_variant: Variant = request.get("payload", {})
	if payload_variant is Dictionary:
		payload = payload_variant

	var current_state: Dictionary = get_peer_state(peer_id)
	if current_state.is_empty():
		current_state = _build_state(baseline_state, build_state_fn)
	var next_state: Dictionary = current_state.duplicate(true)
	var reason: String = str(apply_action_fn.call(action, next_state, payload))
	var ok: bool = reason.is_empty()
	var commit_state: Dictionary = current_state
	if ok:
		_peer_states[peer_id] = next_state.duplicate(true)
		commit_state = next_state

	var commit: Dictionary = {
		"ok": ok,
		"peer_id": peer_id,
		"action": action,
		"request_seq": request_seq,
		"payload": payload.duplicate(true),
		"state": commit_state
	}
	if not ok:
		commit["reason"] = reason
	_last_commits[peer_id] = commit.duplicate(true)
	return commit


func _build_state(baseline_state: Dictionary, build_state_fn: Callable) -> Dictionary:
	if build_state_fn == null or not build_state_fn.is_valid():
		return {}
	var built_variant: Variant = build_state_fn.call(baseline_state)
	if built_variant is Dictionary:
		return (built_variant as Dictionary).duplicate(true)
	return {}
