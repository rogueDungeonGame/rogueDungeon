extends GdUnitTestSuite

var _service := HostSyncFlowService.new()

# 自适应调节的公共参数：预算 1000B，退避步长 0.01s，恢复步长 0.005s
# 区间 [0.05, 0.5]s，chunk 区间 [1, 10]，当前 interval 0.1 / chunk 5
const BUDGET := 1000
const BACKOFF := 0.01
const RECOVER := 0.005

var _mob_count_fn := func(snapshot: Dictionary) -> int: return int(snapshot.get("mobs_total", 0))


func _adjust(packet_bytes: int, mob_count: int) -> Dictionary:
	return _service.adjust_dynamic_world_sync_interval(
		true,
		{"mobs_total": mob_count},
		packet_bytes,
		BUDGET,
		0.05,
		0.5,
		0.1,
		BACKOFF,
		RECOVER,
		1,
		10,
		5,
		_mob_count_fn
	)


func test_reset_runtime_clamps_and_zeroes_cursor() -> void:
	# min/max 传反也能纠正
	var runtime := _service.reset_world_sync_adaptive_runtime(1.0, 0.5, 0.05, 99, 10, 1)
	assert_float(runtime["dynamic_world_sync_interval_sec"]).is_equal_approx(0.5, 0.0001)
	assert_int(runtime["dynamic_world_mob_chunk_size"]).is_equal(10)
	assert_int(runtime["world_mob_chunk_cursor"]).is_equal(0)


func test_active_interval_disabled_uses_static_with_floor() -> void:
	(
		assert_float(_service.get_active_world_sync_interval_sec(false, 0.2, 0.9, 0.05, 0.5))
		. is_equal_approx(0.2, 0.0001)
	)
	# 下限 0.02
	(
		assert_float(_service.get_active_world_sync_interval_sec(false, 0.0, 0.9, 0.05, 0.5))
		. is_equal_approx(0.02, 0.0001)
	)


func test_active_interval_enabled_clamps_dynamic() -> void:
	(
		assert_float(_service.get_active_world_sync_interval_sec(true, 0.2, 0.9, 0.05, 0.5))
		. is_equal_approx(0.5, 0.0001)
	)


func test_active_chunk_size() -> void:
	# 无怪 → 0；自适应关闭用静态值；chunk 不超过总怪数
	assert_int(_service.get_active_world_mob_chunk_size(0, true, 4, 7)).is_equal(0)
	assert_int(_service.get_active_world_mob_chunk_size(20, false, 4, 7)).is_equal(4)
	assert_int(_service.get_active_world_mob_chunk_size(20, true, 4, 7)).is_equal(7)
	assert_int(_service.get_active_world_mob_chunk_size(3, true, 4, 7)).is_equal(3)


func test_tick_plan_without_peers_only_accumulates() -> void:
	var plan := _service.build_host_tick_plan(
		{"delta": 0.1, "hero_send_elapsed_sec": 0.2, "has_peers": false}
	)
	assert_float(plan["hero_send_elapsed_sec"]).is_equal_approx(0.3, 0.0001)
	assert_bool(plan.has("send_hero_snapshot")).is_false()


func test_tick_plan_fires_on_interval_and_keeps_remainder() -> void:
	var plan := (
		_service
		. build_host_tick_plan(
			{
				"delta": 0.05,
				"has_peers": true,
				"hero_sync_interval_sec": 0.04,
				"active_world_interval_sec": 0.1,
				"world_reliable_keyframe_interval_sec": 0.25,
			}
		)
	)
	# 0.05 >= 0.04 → 发送，余数 fmod(0.05, 0.04) = 0.01
	assert_bool(plan["send_hero_snapshot"]).is_true()
	assert_float(plan["hero_send_elapsed_sec"]).is_equal_approx(0.01, 0.0001)
	# 0.05 < 0.1 → 世界快照不发
	assert_bool(plan["send_world_snapshot"]).is_false()
	assert_bool(plan["send_world_keyframe"]).is_false()


func test_adjust_disabled_returns_unchanged() -> void:
	var result := _service.adjust_dynamic_world_sync_interval(
		false, {}, 99999, BUDGET, 0.05, 0.5, 0.1, BACKOFF, RECOVER, 1, 10, 5, _mob_count_fn
	)
	assert_float(result["dynamic_world_sync_interval_sec"]).is_equal_approx(0.1, 0.0001)
	assert_int(result["dynamic_world_mob_chunk_size"]).is_equal(5)


func test_adjust_severe_over_budget_backs_off_hard() -> void:
	# 1400 > 1000*1.35 → interval +0.01*1.8，chunk -1
	var result := _adjust(1400, 3)
	assert_float(result["dynamic_world_sync_interval_sec"]).is_equal_approx(0.118, 0.0001)
	assert_int(result["dynamic_world_mob_chunk_size"]).is_equal(4)


func test_adjust_over_budget_backs_off() -> void:
	# 1200 > 1000 → interval +0.01，chunk -1
	var result := _adjust(1200, 3)
	assert_float(result["dynamic_world_sync_interval_sec"]).is_equal_approx(0.11, 0.0001)
	assert_int(result["dynamic_world_mob_chunk_size"]).is_equal(4)


func test_adjust_heavy_mobs_medium_pressure_soft_backoff() -> void:
	# 800 > 1000*0.78 且怪数 >= 8 → interval +0.01*0.35，chunk 不变（未超预算也未低载）
	var result := _adjust(800, 8)
	assert_float(result["dynamic_world_sync_interval_sec"]).is_equal_approx(0.1035, 0.0001)
	assert_int(result["dynamic_world_mob_chunk_size"]).is_equal(5)


func test_adjust_low_load_recovers() -> void:
	# 300 < 1000*0.55 → interval -0.005，chunk +1
	var result := _adjust(300, 2)
	assert_float(result["dynamic_world_sync_interval_sec"]).is_equal_approx(0.095, 0.0001)
	assert_int(result["dynamic_world_mob_chunk_size"]).is_equal(6)


func test_adjust_respects_interval_bounds() -> void:
	# 已到上限再退避 → 停在 0.5；已到下限再恢复 → 停在 0.05
	var at_max := _service.adjust_dynamic_world_sync_interval(
		true, {}, 9999, BUDGET, 0.05, 0.5, 0.5, BACKOFF, RECOVER, 1, 10, 1, _mob_count_fn
	)
	assert_float(at_max["dynamic_world_sync_interval_sec"]).is_equal_approx(0.5, 0.0001)
	var at_min := _service.adjust_dynamic_world_sync_interval(
		true, {}, 100, BUDGET, 0.05, 0.5, 0.05, BACKOFF, RECOVER, 1, 10, 10, _mob_count_fn
	)
	assert_float(at_min["dynamic_world_sync_interval_sec"]).is_equal_approx(0.05, 0.0001)
	# chunk 同步触界：超预算时已在 min 不再减，低载时已在 max 不再加
	assert_int(at_max["dynamic_world_mob_chunk_size"]).is_equal(1)
	assert_int(at_min["dynamic_world_mob_chunk_size"]).is_equal(10)
