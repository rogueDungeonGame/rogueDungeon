extends GdUnitTestSuite

var _service := SnapshotSerializationService.new()


func test_filter_state_drops_unknown_keys() -> void:
	var full := {"pos": Vector3.ONE, "hp": 50, "secret_debug_field": "leak"}
	var filtered := _service.build_network_hero_state(full)
	assert_bool(filtered.has("pos")).is_true()
	assert_bool(filtered.has("hp")).is_true()
	assert_bool(filtered.has("secret_debug_field")).is_false()


func test_filter_state_deep_copies_nested() -> void:
	var nested := {"cmd": 1}
	var filtered := _service.build_network_hero_state({"command_bus": nested})
	nested["cmd"] = 999
	# 过滤结果是深拷贝，改原字典不应影响快照
	assert_int(filtered["command_bus"]["cmd"]).is_equal(1)


func test_world_snapshot_seq_increments() -> void:
	var result := _service.build_world_snapshot({"current_world_seq": 7})
	assert_int(result["next_world_seq"]).is_equal(8)
	assert_int(result["snapshot"]["world_seq"]).is_equal(8)


func test_world_snapshot_mob_chunking() -> void:
	var mobs := [{"id": 0}, {"id": 1}, {"id": 2}, {"id": 3}, {"id": 4}]
	var input := {
		"sync_mob_state": true,
		"all_mobs": mobs,
		"chunk_size": 2,
		"current_mob_chunk_cursor": 0,
	}
	# 第一块：[0,1]，游标推进到 2
	var r1: Dictionary = _service.build_world_snapshot(input)
	assert_int(r1["snapshot"]["mobs"].size()).is_equal(2)
	assert_int(r1["snapshot"]["mobs_start"]).is_equal(0)
	assert_bool(r1["snapshot"]["mobs_partial"]).is_true()
	assert_int(r1["next_mob_chunk_cursor"]).is_equal(2)
	# 末块：游标 4 → [4]，发完回绕到 0
	input["current_mob_chunk_cursor"] = 4
	var r2: Dictionary = _service.build_world_snapshot(input)
	assert_int(r2["snapshot"]["mobs"].size()).is_equal(1)
	assert_int(r2["next_mob_chunk_cursor"]).is_equal(0)


func test_world_snapshot_force_full_sync() -> void:
	var result := (
		_service
		. build_world_snapshot(
			{
				"sync_mob_state": true,
				"all_mobs": [{"id": 0}, {"id": 1}],
				"chunk_size": 1,
				"force_full_sync": true,
			}
		)
	)
	assert_int(result["snapshot"]["mobs"].size()).is_equal(2)
	assert_bool(result["snapshot"]["mobs_partial"]).is_false()
	assert_int(result["next_mob_chunk_cursor"]).is_equal(0)


func test_hero_snapshot_excludes_host_from_peers() -> void:
	var result := (
		_service
		. build_hero_snapshot(
			{
				"host_peer_id": 1,
				"sync_hero_state": true,
				"host_hero_state": {"hp": 100},
				"peer_latest_hero_state": {1: {"hp": 100}, 2: {"hp": 80}},
			}
		)
	)
	var peers: Dictionary = result["snapshot"]["peers"]
	assert_bool(peers.has("1")).is_false()
	assert_bool(peers.has("2")).is_true()


func test_hero_snapshot_injects_command_bus_from_latest_command() -> void:
	# peer 状态里没有 command_bus 时，从 peer_latest_hero_command 补上
	var result := (
		_service
		. build_hero_snapshot(
			{
				"host_peer_id": 1,
				"sync_hero_state": true,
				"peer_latest_hero_state": {2: {"hp": 80}},
				"peer_latest_hero_command": {2: {"move_to": Vector3.ONE}},
			}
		)
	)
	var peer_hero: Dictionary = result["snapshot"]["peers"]["2"]["hero"]
	assert_bool(peer_hero.has("command_bus")).is_true()


func test_client_input_bundle_under_budget_untouched() -> void:
	var result := _service.build_client_input_bundle(3, 1000, {"pos": Vector3.ONE, "hp": 50}, 1100)
	assert_int(result["next_client_input_seq"]).is_equal(4)
	assert_int(result["bundle"]["seq"]).is_equal(4)
	assert_bool(result["bundle"]["hero"].has("pos")).is_true()


func test_trim_client_input_drops_by_priority() -> void:
	# 塞一个大块的 necromancy 字段（丢弃优先级最高），预算压到下限
	var big_junk := []
	for i in range(200):
		big_junk.append("padding_string_%d" % i)
	var payload := {
		"seq": 1,
		"t_ms": 0,
		"hero": {"pos": Vector3.ONE, "necromancy": big_junk},
	}
	var trimmed := _service.trim_client_input_payload_for_budget(payload, 640)
	assert_bool(trimmed["hero"].has("necromancy")).is_false()
	# 位置这类核心字段永不丢弃（不在 drop_order 里）
	assert_bool(trimmed["hero"].has("pos")).is_true()


func test_extract_mob_count() -> void:
	# 表驱动：[snapshot, expected]
	var cases := [
		[{"mobs_total": 7}, 7],
		[{"mobs_total": "12"}, 12],
		[{"mobs": [{}, {}, {}]}, 3],
		[{}, 0],
	]
	for c: Array in cases:
		assert_int(_service.extract_mob_count_from_snapshot(c[0])).is_equal(c[1])


func test_state_signature_stable_and_distinct() -> void:
	var a := {"hp": 100, "pos": Vector3.ONE}
	assert_str(_service.build_state_signature(a)).is_equal(_service.build_state_signature(a))
	assert_str(_service.build_state_signature(a)).is_not_equal(
		_service.build_state_signature({"hp": 99, "pos": Vector3.ONE})
	)
