extends GdUnitTestSuite

var _service := SteamLobbyService.new()


func test_should_start_with_lobby() -> void:
	# 表驱动：[lobby_enabled, action, id_text, parsed_id, expected]
	var cases := [
		[false, "create", "", 0, false],
		[true, "create", "", 0, true],
		[true, " CREATE ", "", 0, true],
		[true, "join", "123", 123, true],
		[true, "join", "0", 0, false],
		[true, "unknown", "", 0, false],
	]
	for c: Array in cases:
		assert_bool(_service.should_start_with_lobby(c[0], c[1], c[2], c[3])).is_equal(c[4])


func test_begin_create_host_sets_pending_action() -> void:
	var result: Dictionary = _service.begin_create_host({"network_mode": "host"})
	var state: Dictionary = result["state"]
	assert_str(state["steam_lobby_action"]).is_equal("create")
	assert_str(state["_steam_lobby_pending_action"]).is_equal("create_host")
	# _copy_state 是白名单拷贝：已知字段透传，未知字段丢弃
	assert_str(state["network_mode"]).is_equal("host")


func test_handle_lobby_created_rejects_invalid_id() -> void:
	var result: Dictionary = _service.handle_lobby_created({}, 0, 0, true)
	assert_bool(result["changed"]).is_false()
