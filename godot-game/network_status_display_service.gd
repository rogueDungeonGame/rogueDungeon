extends RefCounted
class_name NetworkStatusDisplayService


func create_overlay(host: Node) -> Dictionary:
	var status_layer := CanvasLayer.new()
	status_layer.name = "NetStatusLayer"
	status_layer.layer = 20
	host.add_child(status_layer)

	var status_panel := PanelContainer.new()
	status_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_panel.offset_left = 12.0
	status_panel.offset_top = 12.0
	status_panel.offset_right = 720.0
	status_panel.offset_bottom = 130.0
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_layer.add_child(status_panel)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.06, 0.08, 0.85)
	panel_style.border_color = Color(0.88, 0.72, 0.22, 1.0)
	panel_style.set_border_width_all(1)
	status_panel.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	status_panel.add_child(margin)

	var status_label := RichTextLabel.new()
	status_label.bbcode_enabled = true
	status_label.fit_content = true
	status_label.scroll_active = false
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.focus_mode = Control.FOCUS_NONE
	status_label.add_theme_font_size_override("normal_font_size", 14)
	margin.add_child(status_label)

	return {
		"status_layer": status_layer,
		"status_panel": status_panel,
		"status_label": status_label,
	}


func set_status_text(status_label: RichTextLabel, text: String) -> String:
	if status_label != null:
		status_label.clear()
		status_label.append_text(text)
	return text


func build_status_text(input: Dictionary) -> String:
	var mode_raw: String = str(input.get("mode_raw", "")).strip_edges().to_lower()
	var mode: String = mode_raw.to_upper()
	var self_id: int = int(input.get("self_id", 0))
	var room_ids: Array[int] = _int_array_copy(input.get("room_ids", []))
	var peers_count: int = maxi(room_ids.size() - 1, 0)
	var room_ids_text: String = _format_player_ids(room_ids)
	var state_text: String = _get_link_state_text(
		mode_raw, peers_count, bool(input.get("network_running", false))
	)
	var fps_value: int = maxi(int(input.get("fps", 0)), 0)
	var sync_delay_text: String = _build_sync_latency_summary(mode_raw, room_ids, input)
	var running_text: String = "ON" if bool(input.get("network_running", false)) else "OFF"
	var running_color: String = "#66FF7A" if running_text == "ON" else "#FF6B6B"
	var state_color: String = _resolve_link_state_color(state_text)
	var mode_color: String = _resolve_mode_color(mode_raw)
	var peers_color: String = "#66FF7A" if peers_count > 0 else "#FFD166"
	var sync_delay_color: String = "#7CFFEE" if sync_delay_text != "-" else "#9AA0A6"
	var text: String = (
		"perf=fps:%s sync_delay=%s\nNET(%s) mode=%s state=%s self=%s peers=%s host=%s\nroom_ids=%s"
		% [
			_colorize(str(fps_value), "#B8F2E6"),
			_colorize(sync_delay_text, sync_delay_color),
			_colorize(running_text, running_color),
			_colorize(mode, mode_color),
			_colorize(state_text, state_color),
			_colorize(str(self_id), "#FFF59D"),
			_colorize(str(peers_count), peers_color),
			_colorize(
				"%s:%d" % [str(input.get("server_host", "")), int(input.get("server_port", 0))],
				"#C5D1FF"
			),
			_colorize(room_ids_text, "#7FDBFF")
		]
	)

	var transport_mode: String = str(input.get("transport_mode", "")).strip_edges().to_lower()
	if transport_mode == "steam_relay":
		var local_id_relay: String = str(input.get("relay_local_id", "")).strip_edges()
		var target_relay_id: String = str(input.get("relay_target_id", "")).strip_edges()
		var steam_ready: String = "on" if bool(input.get("steam_initialized", false)) else "off"
		text += (
			"\ntransport=%s app=%s local=%s host_id=%s vport=%s steam=%s"
			% [
				_colorize("steam_relay", "#8EC5FF"),
				_colorize(str(int(input.get("steam_app_id", 0))), "#C5D1FF"),
				_colorize(local_id_relay if not local_id_relay.is_empty() else "-", "#C5D1FF"),
				_colorize(target_relay_id if not target_relay_id.is_empty() else "-", "#C5D1FF"),
				_colorize(str(maxi(int(input.get("steam_virtual_port", 0)), 0)), "#C5D1FF"),
				_colorize(steam_ready, "#66FF7A" if steam_ready == "on" else "#FF6B6B")
			]
		)
	elif transport_mode == "steam_stub":
		var local_id: String = str(input.get("stub_local_id", "")).strip_edges()
		var target_id: String = str(input.get("stub_target_id", "")).strip_edges()
		var endpoint_host: String = str(input.get("stub_endpoint_host", "")).strip_edges()
		var endpoint_port: int = int(input.get("stub_endpoint_port", 0))
		var endpoint_text: String = "-"
		if not endpoint_host.is_empty() and endpoint_port > 0:
			endpoint_text = "%s:%d" % [endpoint_host, endpoint_port]
		text += (
			"\ntransport=%s app=%s local=%s host_id=%s endpoint=%s"
			% [
				_colorize("steam_stub", "#8EC5FF"),
				_colorize(str(int(input.get("steam_app_id", 0))), "#C5D1FF"),
				_colorize(local_id if not local_id.is_empty() else "-", "#C5D1FF"),
				_colorize(target_id if not target_id.is_empty() else "-", "#C5D1FF"),
				_colorize(endpoint_text, "#C5D1FF")
			]
		)
	else:
		text += "\ntransport=%s" % _colorize("enet_direct", "#8EC5FF")

	var steam_lobby_id: int = int(input.get("steam_lobby_id", 0))
	if steam_lobby_id > 0:
		var lobby_host_text: String = "-"
		var lobby_owner_steam_id: int = int(input.get("steam_lobby_owner_steam_id", 0))
		if lobby_owner_steam_id > 0:
			lobby_host_text = str(lobby_owner_steam_id)
		var migration_text: String = "off"
		if bool(input.get("host_migration_in_progress", false)):
			var target_steam_id: int = int(input.get("host_migration_target_steam_id", 0))
			migration_text = "wait->%s" % (str(target_steam_id) if target_steam_id > 0 else "-")
		text += (
			"\nlobby=id:%s owner:%s members:%s migration:%s"
			% [
				_colorize(str(steam_lobby_id), "#B9FBC0"),
				_colorize(lobby_host_text, "#B9FBC0"),
				_colorize(
					str(_int_array_copy(input.get("steam_lobby_member_steam_ids", [])).size()),
					"#B9FBC0"
				),
				_colorize(migration_text, "#FFD166" if migration_text != "off" else "#66FF7A")
			]
		)

	var hero_summary: String = _build_hero_summary(room_ids, input)
	if not hero_summary.is_empty():
		text += "\nheroes=%s" % _colorize(hero_summary, "#72F1B8")
	var equip_summary: String = _build_equipment_summary(room_ids, input)
	if not equip_summary.is_empty():
		text += "\nequip=%s" % _colorize(equip_summary, "#A0C4FF")

	var active_world_ms: int = int(
		round(float(input.get("active_world_sync_interval_sec", 0.0)) * 1000.0)
	)
	var hero_sync_ms: int = int(
		round(maxf(float(input.get("hero_sync_interval_sec", 0.02)), 0.02) * 1000.0)
	)
	var chunk_size_info: int = int(input.get("world_mob_chunk_size", 0))
	if bool(input.get("adaptive_world_sync_enabled", false)):
		chunk_size_info = int(input.get("dynamic_world_mob_chunk_size", chunk_size_info))
	text += (
		"\nsync=hero/%s world/%s chunk=%s pkt=%s adaptive=%s"
		% [
			_colorize("%dms" % hero_sync_ms, "#FDE68A"),
			_colorize("%dms" % active_world_ms, "#FDE68A"),
			_colorize(str(chunk_size_info), "#FDE68A"),
			_colorize("%dB" % int(input.get("last_world_packet_bytes", 0)), "#FDE68A"),
			_colorize(
				"on" if bool(input.get("adaptive_world_sync_enabled", false)) else "off",
				"#66FF7A" if bool(input.get("adaptive_world_sync_enabled", false)) else "#9AA0A6"
			)
		]
	)

	if mode_raw == "client":
		text += (
			"\ninput=seq:%s ack:%s pending:%s"
			% [
				_colorize(str(int(input.get("client_input_seq", 0))), "#E0AAFF"),
				_colorize(str(int(input.get("last_ack_input_seq_from_host", 0))), "#E0AAFF"),
				_colorize(str(int(input.get("client_recent_input_frames_size", 0))), "#E0AAFF")
			]
		)
	elif mode_raw == "host":
		text += (
			"\ninput_ack_peers=%s world_seq=%s"
			% [
				_colorize(str(int(input.get("peer_last_input_seq_size", 0))), "#E0AAFF"),
				_colorize(str(int(input.get("host_world_snapshot_seq", 0))), "#E0AAFF")
			]
		)
		text += (
			" dmg_budget=%s x%s active=%s"
			% [
				_colorize(
					"%.0f/s" % maxf(float(input.get("damage_request_budget_per_sec", 0.0)), 0.0),
					"#FFC6FF"
				),
				_colorize(
					(
						"%.1f"
						% clampf(float(input.get("damage_request_budget_burst_sec", 1.0)), 1.0, 4.0)
					),
					"#FFC6FF"
				),
				_colorize(str(int(input.get("peer_damage_budget_tokens_size", 0))), "#FFC6FF")
			]
		)
		var breaker_summary: String = _build_damage_breaker_summary(room_ids, input)
		if not breaker_summary.is_empty():
			text += " breaker=%s" % _colorize(breaker_summary, "#FFADAD")
		var damage_audit_summary: String = _build_damage_request_audit_summary(room_ids, input)
		if not damage_audit_summary.is_empty():
			text += "\ndmg_audit=%s" % _colorize(damage_audit_summary, "#FFADAD")

	var status_event_hint: String = str(input.get("status_event_hint", "")).strip_edges()
	if not status_event_hint.is_empty():
		text += "\nevent=%s" % _colorize(status_event_hint, "#FFA94D")
	return text


func get_room_player_ids(
	network_running: bool, has_multiplayer_peer: bool, self_id: int, peer_ids: Array
) -> Array[int]:
	var ids: Array[int] = []
	if not network_running:
		return ids
	if not has_multiplayer_peer:
		return ids
	if self_id > 0:
		ids.append(self_id)
	for peer_variant in peer_ids:
		var peer_id: int = int(peer_variant)
		if peer_id <= 0 or peer_id == self_id:
			continue
		ids.append(peer_id)
	ids.sort()
	return ids


func _build_sync_latency_summary(
	mode_raw: String, room_ids: Array[int], input: Dictionary
) -> String:
	if mode_raw == "client":
		var client_last_rtt_ms: int = int(input.get("client_last_rtt_ms", -1))
		if client_last_rtt_ms < 0:
			return "-"
		var client_avg_rtt_ms: float = float(input.get("client_avg_rtt_ms", -1.0))
		if client_avg_rtt_ms >= 0.0:
			return "%dms(avg %.0fms)" % [client_last_rtt_ms, client_avg_rtt_ms]
		return "%dms" % client_last_rtt_ms
	if mode_raw == "host":
		var self_id: int = int(input.get("self_id", 0))
		var peer_input_latency_ms: Dictionary = _dict_copy(input.get("peer_input_latency_ms", {}))
		var parts: Array[String] = []
		var total_ms: int = 0
		var count: int = 0
		for peer_id in room_ids:
			if peer_id == self_id:
				continue
			if not peer_input_latency_ms.has(peer_id):
				continue
			var latency_ms: int = int(peer_input_latency_ms[peer_id])
			if latency_ms < 0:
				continue
			parts.append("P%d:%dms" % [peer_id, latency_ms])
			total_ms += latency_ms
			count += 1
		if count <= 0:
			return "-"
		return "avg %.0fms [%s]" % [float(total_ms) / float(count), ", ".join(parts)]
	return "-"


func _build_hero_summary(room_ids: Array[int], input: Dictionary) -> String:
	var peer_latest_hero_state: Dictionary = _dict_copy(input.get("peer_latest_hero_state", {}))
	var parts: Array[String] = []
	for peer_id in room_ids:
		if not peer_latest_hero_state.has(peer_id):
			continue
		var state: Dictionary = _dict_copy(peer_latest_hero_state[peer_id])
		if state.is_empty():
			continue
		var hp: int = int(state.get("hp", 0))
		var max_hp: int = int(state.get("max_hp", 0))
		var mana: int = int(state.get("mana", 0))
		var max_mana: int = int(state.get("max_mana", 0))
		var profile: String = str(state.get("hero_profile", "-"))
		var cmd_type: String = "-"
		var command_variant: Variant = state.get("command_bus", null)
		if command_variant is Dictionary:
			cmd_type = str((command_variant as Dictionary).get("type", "-"))
		parts.append(
			(
				"P%d hp=%d/%d mp=%d/%d profile=%s cmd=%s"
				% [peer_id, hp, max_hp, mana, max_mana, profile, cmd_type]
			)
		)
	return " | ".join(parts)


func _build_equipment_summary(room_ids: Array[int], input: Dictionary) -> String:
	var peer_latest_equipment_state: Dictionary = _dict_copy(
		input.get("peer_latest_equipment_state", {})
	)
	var parts: Array[String] = []
	for peer_id in room_ids:
		if not peer_latest_equipment_state.has(peer_id):
			continue
		var state: Dictionary = _dict_copy(peer_latest_equipment_state[peer_id])
		if state.is_empty():
			continue
		var inv_text: String = "[]"
		var inv_variant: Variant = state.get("inventory", [])
		if inv_variant is Array:
			inv_text = _format_int_array(inv_variant)
		var gold: int = int(state.get("gold", -1))
		var shop_level: int = int(state.get("shop_level", -1))
		var offer_count: int = 0
		var offer_variant: Variant = state.get("shop_offer_ids", [])
		if offer_variant is Array:
			offer_count = (offer_variant as Array).size()
		parts.append(
			(
				"P%d inv=%s gold=%d shop=%d offer=%d"
				% [peer_id, inv_text, gold, shop_level, offer_count]
			)
		)
	return " | ".join(parts)


func _build_damage_request_audit_summary(room_ids: Array[int], input: Dictionary) -> String:
	var peer_damage_accept_total: Dictionary = _dict_copy(input.get("peer_damage_accept_total", {}))
	var peer_damage_reject_total: Dictionary = _dict_copy(input.get("peer_damage_reject_total", {}))
	var peer_damage_reject_reason_counts: Dictionary = _dict_copy(
		input.get("peer_damage_reject_reason_counts", {})
	)
	var parts: Array[String] = []
	for peer_id in room_ids:
		var ok_count: int = int(peer_damage_accept_total.get(peer_id, 0))
		var reject_count: int = int(peer_damage_reject_total.get(peer_id, 0))
		if ok_count <= 0 and reject_count <= 0:
			continue
		var top_reason: String = "-"
		var top_reason_count: int = 0
		var reasons: Dictionary = _dict_copy(peer_damage_reject_reason_counts.get(peer_id, {}))
		for reason_key_variant in reasons.keys():
			var reason_key: String = str(reason_key_variant)
			var reason_hits: int = int(reasons[reason_key_variant])
			if reason_hits > top_reason_count:
				top_reason_count = reason_hits
				top_reason = reason_key
		parts.append(
			(
				"P%d ok=%d rej=%d top=%s(%d)"
				% [peer_id, ok_count, reject_count, top_reason, top_reason_count]
			)
		)
	return " | ".join(parts)


func _build_damage_breaker_summary(room_ids: Array[int], input: Dictionary) -> String:
	var now_ms: int = int(input.get("now_ms", 0))
	var blocked_until_by_peer: Dictionary = _dict_copy(
		input.get("peer_damage_breaker_blocked_until_ms", {})
	)
	var active_parts: Array[String] = []
	for peer_id in room_ids:
		var blocked_until_ms: int = int(blocked_until_by_peer.get(peer_id, 0))
		if blocked_until_ms <= now_ms:
			continue
		var left_sec: float = maxf(float(blocked_until_ms - now_ms) * 0.001, 0.0)
		active_parts.append("P%d %.1fs" % [peer_id, left_sec])
	if active_parts.is_empty():
		return "active=0"
	return "active=%d [%s]" % [active_parts.size(), ", ".join(active_parts)]


func _format_player_ids(ids: Array[int]) -> String:
	if ids.is_empty():
		return "[]"
	var parts: Array[String] = []
	for player_id in ids:
		parts.append(str(player_id))
	return "[" + ",".join(parts) + "]"


func _format_int_array(values: Array) -> String:
	if values.is_empty():
		return "[]"
	var parts: Array[String] = []
	for value in values:
		parts.append(str(int(value)))
	return "[" + ",".join(parts) + "]"


func _get_link_state_text(mode: String, peers_count: int, network_running: bool) -> String:
	if mode == "offline":
		return "OFFLINE"
	if not network_running:
		return "STOPPED"
	if mode == "host":
		if peers_count > 0:
			return "LISTENING_CONNECTED"
		return "LISTENING_WAITING"
	if mode == "client":
		if peers_count > 0:
			return "CONNECTED"
		return "CONNECTING"
	return "RUNNING"


func _resolve_link_state_color(state_text: String) -> String:
	match state_text:
		"CONNECTED", "LISTENING_CONNECTED":
			return "#66FF7A"
		"CONNECTING", "LISTENING_WAITING":
			return "#FFD166"
		"OFFLINE", "STOPPED":
			return "#FF6B6B"
		_:
			return "#A5B4FC"


func _resolve_mode_color(mode_raw: String) -> String:
	match mode_raw:
		"host":
			return "#6EE7FF"
		"client":
			return "#FF8CF8"
		"offline":
			return "#9AA0A6"
		_:
			return "#A5B4FC"


func _colorize(text: String, color_hex: String) -> String:
	return "[color=%s]%s[/color]" % [color_hex, _escape_bbcode_text(text)]


func _escape_bbcode_text(text: String) -> String:
	var escaped: String = text.replace("\\", "\\\\")
	escaped = escaped.replace("[", "\\[")
	escaped = escaped.replace("]", "\\]")
	return escaped


func _dict_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _int_array_copy(value: Variant) -> Array[int]:
	var out: Array[int] = []
	if value is Array:
		for entry in value:
			out.append(int(entry))
	return out
