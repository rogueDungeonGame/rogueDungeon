extends Node
class_name NetSessionController

const NetworkStatusDisplayService := preload("res://network_status_display_service.gd")
const RemoteAvatarMotionService := preload("res://remote_avatar_motion_service.gd")
const RemoteAvatarRuntimeService := preload("res://remote_avatar_runtime_service.gd")
const RemoteAvatarVisualService := preload("res://remote_avatar_visual_service.gd")
const SnapshotSerializationService := preload("res://snapshot_serialization_service.gd")
const SteamLobbyService := preload("res://steam_lobby_service.gd")
const NetworkStateCollectionService := preload("res://network_state_collection_service.gd")
const ClientSyncFlowService := preload("res://client_sync_flow_service.gd")
const HostSyncFlowService := preload("res://host_sync_flow_service.gd")

signal steam_lobby_changed(lobby_id: int, owner_steam_id: int, member_count: int)
signal steam_lobby_join_requested(lobby_id: int, inviter_steam_id: int)
signal host_migration_state_changed(in_progress: bool, local_is_host: bool, target_steam_id: int)

@export_enum("offline", "host", "client") var network_mode: String = "offline"
@export_enum("enet_direct", "steam_stub", "steam_relay")
var net_transport_mode: String = "enet_direct"
@export var transport_config_enabled: bool = true
@export var transport_config_path: String = "res://net_transport.cfg"
@export var auto_start_network: bool = false
@export var server_host: String = "127.0.0.1"
@export var server_port: int = 19090
@export var steam_app_id: int = 480
@export var steam_embed_callbacks: bool = true
@export var steam_virtual_port: int = 0
@export var steam_local_id: String = ""
@export var steam_target_host_id: String = ""
@export_enum("disabled", "create", "join") var steam_lobby_action: String = "disabled"
@export_enum("private", "friends_only", "public", "invisible")
var steam_lobby_visibility: String = "friends_only"
@export var steam_lobby_enabled: bool = false
@export var steam_lobby_max_members: int = 4
@export var steam_lobby_id_text: String = ""
@export var steam_lobby_name: String = "RogueDungeon"
@export var steam_lobby_connect_on_join_requested: bool = true
@export var host_migration_enabled: bool = false
@export var host_migration_owner_poll_interval_sec: float = 0.50
@export var host_migration_takeover_delay_sec: float = 0.60
@export var host_migration_reconnect_delay_sec: float = 0.85
@export var steam_stub_listen_port: int = 19090
@export var steam_stub_default_remote_host: String = "127.0.0.1"
@export var steam_stub_default_remote_port: int = 19090
@export var steam_stub_endpoint_map_csv: String = ""
@export var send_interval_sec: float = 0.05
@export var hero_sync_interval_sec: float = 0.08
@export var equipment_sync_interval_sec: float = 0.30
@export var client_input_redundancy_count: int = 1
@export var client_input_packet_budget_bytes: int = 1050
@export var client_input_unreliable_max_bytes: int = 1300
@export var client_initial_hero_state_resend_interval_sec: float = 0.25
@export var world_sync_interval_sec: float = 0.08
@export var hero_reliable_keyframe_interval_sec: float = 0.75
@export var world_reliable_keyframe_interval_sec: float = 0.75
@export var adaptive_world_sync_enabled: bool = true
@export var keep_host_active_in_background: bool = true
@export var world_sync_interval_min_sec: float = 0.05
@export var world_sync_interval_max_sec: float = 0.12
@export var world_sync_backoff_step_sec: float = 0.01
@export var world_sync_recover_step_sec: float = 0.01
@export var world_packet_budget_bytes: int = 1180
@export var world_mob_chunk_size: int = 8
@export var world_mob_chunk_size_min: int = 6
@export var world_mob_chunk_size_max: int = 12
@export var world_full_sync_mob_threshold: int = 40
@export var force_full_mob_sync_below_count: int = 28

@export var hero_controller_path: NodePath = NodePath("../HeroController")
@export var fallback_local_hero_path: NodePath = NodePath("../HeroController/herowarden")
@export var game_ui_path: NodePath = NodePath("../GameUI")
@export var boss_controller_path: NodePath = NodePath("../EnemyAI")
@export var tauren_spawner_path: NodePath = NodePath("../TaurenSpawner")
@export var summon_manager_path: NodePath = NodePath("../SummonManager")
@export var remote_players_root_path: NodePath = NodePath("../NetworkPlayers")
const HeroMelee2DScene := preload("res://placeholders/hero_melee_2d.tscn")

@export var remote_melee_player_scene: PackedScene = HeroMelee2DScene
@export
var remote_ranged_player_scene: PackedScene = preload("res://placeholders/hero_ranged_2d.tscn")
@export var remote_transformed_player_scene: PackedScene = preload(
	"res://placeholders/hero_transformed_2d.tscn"
)
@export var remote_player_scene: PackedScene = HeroMelee2DScene
@export var remote_player_scale: Vector3 = Vector3.ONE
@export var remote_position_smooth_speed: float = 16.0
@export var remote_rotation_smooth_speed: float = 14.0
@export var remote_snap_distance: float = 260.0
@export var host_large_displacement_snap_distance: float = 120.0
@export var remote_position_prediction_sec: float = 0.10
@export var remote_prediction_timeout_sec: float = 0.30
@export var remote_prediction_velocity_damping: float = 8.0
@export var remote_prediction_max_speed: float = 2400.0
@export var remote_command_drive_enabled: bool = true
@export var remote_command_drive_stop_distance: float = 18.0
@export var remote_command_drive_soft_correction_distance: float = 48.0
@export var remote_command_drive_hard_snap_distance: float = 220.0
@export var remote_command_drive_correction_speed: float = 7.5
@export var remote_command_drive_turn_speed: float = 20.0
@export var net_ping_interval_sec: float = 0.5
@export var remote_select_screen_radius: float = 72.0
@export var sync_skill_effects: bool = true
@export var remote_flash_effect_scene: PackedScene = preload(
	"res://effects/HeroWarden/FanOfKnivesCaster/FanOfKnivesCaster.glb"
)
@export var remote_flash_effect_scale: Vector3 = Vector3(2.0, 2.0, 2.0)
@export var remote_haste_effect_scale: Vector3 = Vector3(1.35, 1.35, 1.35)
@export var remote_skill_effect_fallback_lifetime: float = 1.8
@export var remote_ranged_q_ray_length: float = 780.0
@export var remote_ranged_q_ray_width: float = 16.0
@export var remote_ranged_q_ray_thickness: float = 2.0
@export var remote_ranged_q_ray_lifetime: float = 0.12
@export var remote_ranged_r_projectile_scene: PackedScene
@export var remote_ranged_r_impact_scene: PackedScene
@export var remote_ranged_r_projectile_speed: float = 1800.0
@export var remote_ranged_r_projectile_min_flight_time: float = 0.12
@export var remote_ranged_r_impact_scale_multiplier: float = 3.0
@export var remote_hp_bar_height: float = 200.0
@export var remote_hp_bar_width: float = 180.0

@export var sync_hero_state: bool = true
@export var sync_equipment_state: bool = true
@export var sync_boss_state: bool = true
@export var sync_mob_state: bool = true
@export var sync_breakable_state: bool = true
@export var breakable_group_name: StringName = &"breakable"
@export var damage_request_budget_per_sec: float = 180.0
@export var damage_request_budget_burst_sec: float = 1.5
@export var damage_request_breaker_window_sec: float = 8.0
@export var damage_request_breaker_reject_threshold: int = 40
@export var damage_request_breaker_block_sec: float = 5.0

const SKILL_ID_W_RANGED_SPEED: int = 202
const SKILL_ID_R_RANGED_CLUSTER: int = 204
const REMOTE_R_SKILL_PROJECTILE_SCENE_PATH: String = "res://effects/HeroTinker/ClusterRocketsWeaponMissile/RocketMissile_clean.glb"
const REMOTE_R_SKILL_PROJECTILE_SCENE_FALLBACK_PATH: String = "res://effects/HeroTinker/ClusterRocketsWeaponMissile/RocketMissile.glb"
const REMOTE_R_SKILL_IMPACT_SCENE_PATH: String = "res://effects/HeroTinker/ClusterRocketsMissile/TinkerRocketMissile.glb"
const REMOTE_RANGED_R_LOGIC_POINT_LIFETIME_SEC: float = 0.3
const MOB_MOTION_FLAG_VISIBLE: int = 1
const MOB_MOTION_FLAG_DEAD: int = 1 << 1
const MOB_MOTION_FLAG_MOVING: int = 1 << 2
const MOB_MOTION_FLAG_ATTACKING: int = 1 << 3

var _peer: MultiplayerPeer = null
var _is_network_running: bool = false
var _send_elapsed_sec: float = 0.0
var _equipment_send_elapsed_sec: float = 0.0
var _hero_send_elapsed_sec: float = 0.0
var _hero_reliable_keyframe_elapsed_sec: float = 0.0
var _world_send_elapsed_sec: float = 0.0
var _world_reliable_keyframe_elapsed_sec: float = 0.0
var _dynamic_world_sync_interval_sec: float = 0.08
var _dynamic_world_mob_chunk_size: int = 4
var _world_mob_chunk_cursor: int = 0
var _last_world_packet_bytes: int = 0
var _host_world_snapshot_seq: int = 0
var _last_applied_world_snapshot_seq: int = -1
var _status_refresh_elapsed_sec: float = 0.0
var _remote_players_root: Node3D = null
var _remote_avatars: Dictionary = {}
var _remote_avatar_model_keys: Dictionary = {}
var _remote_avatar_last_anims: Dictionary = {}
var _remote_avatar_target_positions: Dictionary = {}
var _remote_avatar_target_yaws: Dictionary = {}
var _remote_avatar_velocities: Dictionary = {}
var _remote_avatar_last_receive_ms: Dictionary = {}
var _remote_avatar_hp_bars: Dictionary = {}
var _remote_avatar_hp_bar_materials: Dictionary = {}
var _remote_last_flash_cd: Dictionary = {}
var _remote_last_haste_active: Dictionary = {}
var _remote_last_skill_event_seq: Dictionary = {}

var _peer_latest_hero_state: Dictionary = {}
var _peer_latest_hero_command: Dictionary = {}
var _peer_latest_skill_event: Dictionary = {}
var _peer_latest_equipment_state: Dictionary = {}
var _peer_latest_equipment_signatures: Dictionary = {}
var _peer_last_input_seq: Dictionary = {}
var _peer_last_hero_command_seq: Dictionary = {}
var _peer_last_damage_request_seq: Dictionary = {}
var _peer_last_damage_request_ms: Dictionary = {}
var _peer_last_hero_positions: Dictionary = {}
var _peer_last_hero_pos_ms: Dictionary = {}
var _peer_damage_budget_tokens: Dictionary = {}
var _peer_damage_budget_last_ms: Dictionary = {}
var _peer_damage_accept_total: Dictionary = {}
var _peer_damage_reject_total: Dictionary = {}
var _peer_damage_reject_reason_counts: Dictionary = {}
var _peer_damage_breaker_window_start_ms: Dictionary = {}
var _peer_damage_breaker_reject_count: Dictionary = {}
var _peer_damage_breaker_blocked_until_ms: Dictionary = {}
var _peer_input_latency_ms: Dictionary = {}
var _peer_hero_selection_confirmed: Dictionary = {}
var _host_hero_snapshot_seq: int = 0
var _last_applied_hero_snapshot_seq: int = -1
var _client_input_seq: int = 0
var _client_recent_input_frames: Array = []
var _client_ping_elapsed_sec: float = 0.0
var _client_ping_seq: int = 0
var _client_ping_sent_ms: Dictionary = {}
var _client_last_rtt_ms: int = -1
var _client_avg_rtt_ms: float = -1.0
var _local_last_sent_hero_command_seq: int = -1
var _client_last_sent_skill_event_seq: int = -1
var _client_enemy_damage_request_seq: int = 0
var _client_last_sent_enemy_damage_request_seq: int = -1
var _client_initial_hero_state_sent: bool = false
var _client_last_local_hero_instance_id: int = 0
var _client_initial_hero_state_ack_required_seq: int = -1
var _client_initial_hero_state_resend_elapsed_sec: float = 0.0
var _last_sent_equipment_signature: String = ""
var _last_ack_input_seq_from_host: int = -1
var _local_equipment_request_seq: int = 0
var _local_prev_flash_cd: float = 0.0
var _local_prev_haste_active: bool = false
var _local_skill_event_seq: int = 0
var _local_last_skill_event: Dictionary = {}
var _local_prev_explicit_skill_event_seq: int = -1
var _steam_stub_endpoint_map: Dictionary = {}
var _steam_singleton: Object = null
var _steam_initialized: bool = false
var _steam_signal_handlers_connected: bool = false
var _steam_lobby_id: int = 0
var _steam_lobby_owner_steam_id: int = 0
var _steam_lobby_member_steam_ids: Array[int] = []
var _steam_lobby_pending_action: String = ""
var _steam_lobby_poll_elapsed_sec: float = 0.0
var _steam_lobby_explicit_leave_in_progress: bool = false
var _current_host_steam_id: int = 0
var _host_migration_in_progress: bool = false
var _host_migration_takeover_ready_ms: int = 0
var _host_migration_reconnect_ready_ms: int = 0
var _host_migration_target_steam_id: int = 0
var _migration_pause_world_authority: bool = false

var _status_layer: CanvasLayer = null
var _status_panel: PanelContainer = null
var _status_label: RichTextLabel = null
var _last_status_text: String = ""
var _status_event_hint: String = ""
var _ui_observed_peer_id: int = 0
var _last_snapshot_latency_ms: int = -1
var _avg_snapshot_latency_ms: float = -1.0
var _remote_r_skill_projectile_resource_checked: bool = false
var _remote_r_skill_impact_resource_checked: bool = false
var _steam_lobby_service = null
var _network_status_display_service = null
var _remote_avatar_motion_service = null
var _remote_avatar_runtime_service = null
var _remote_avatar_visual_service = null
var _snapshot_serialization_service = null
var _network_state_collection_service = null
var _client_sync_flow_service = null
var _host_sync_flow_service = null
var _host_background_runtime_override_active: bool = false
var _saved_low_processor_usage_mode_valid: bool = false
var _saved_low_processor_usage_mode: bool = false
var _saved_low_processor_usage_sleep_usec_valid: bool = false
var _saved_low_processor_usage_sleep_usec: int = 0


func _ready() -> void:
	set_process(true)
	set_physics_process(true)
	set_process_unhandled_input(true)
	add_to_group("net_session_controller")
	_reset_world_sync_adaptive_runtime()
	_reset_local_skill_event_runtime(true)
	_connect_multiplayer_signals_once()
	_ensure_remote_players_root()
	_create_status_overlay()
	_apply_transport_config_overrides()
	_apply_cmdline_overrides()
	_refresh_steam_stub_endpoint_map()
	_connect_steam_signals_once()
	_refresh_steam_lobby_state_from_backend()
	_apply_network_authority_mode()
	_notify_game_ui_observe_peer(0)
	_notify_game_ui_observe_enemy({})
	if auto_start_network and network_mode != "offline":
		if _should_start_with_steam_lobby():
			_begin_network_start_via_steam_lobby()
		else:
			start_network()
	else:
		_status_event_hint = ""
		_refresh_status_text()


func _ensure_remote_r_skill_effect_resources_loaded() -> void:
	if not _remote_r_skill_projectile_resource_checked and remote_ranged_r_projectile_scene == null:
		remote_ranged_r_projectile_scene = _load_packed_scene_resource(
			REMOTE_R_SKILL_PROJECTILE_SCENE_PATH
		)
		if remote_ranged_r_projectile_scene == null:
			remote_ranged_r_projectile_scene = _load_packed_scene_resource(
				REMOTE_R_SKILL_PROJECTILE_SCENE_FALLBACK_PATH
			)
	_remote_r_skill_projectile_resource_checked = true
	if not _remote_r_skill_impact_resource_checked and remote_ranged_r_impact_scene == null:
		remote_ranged_r_impact_scene = _load_packed_scene_resource(REMOTE_R_SKILL_IMPACT_SCENE_PATH)
	_remote_r_skill_impact_resource_checked = true


func _load_packed_scene_resource(path: String) -> PackedScene:
	var safe_path: String = path.strip_edges()
	if safe_path.is_empty():
		return null
	if not _resource_file_exists(safe_path):
		return null
	var ext: String = safe_path.get_extension().to_lower()
	if ext == "glb" or ext == "gltf":
		return _load_packed_scene_from_gltf_runtime(safe_path)
	if ResourceLoader.exists(safe_path, "PackedScene"):
		var resource: Resource = ResourceLoader.load(safe_path, "PackedScene")
		if resource is PackedScene:
			return resource as PackedScene
	return null


func _get_steam_lobby_service():
	if _steam_lobby_service == null:
		_steam_lobby_service = SteamLobbyService.new()
	return _steam_lobby_service


func _get_network_status_display_service():
	if _network_status_display_service == null:
		_network_status_display_service = NetworkStatusDisplayService.new()
	return _network_status_display_service


func _get_remote_avatar_motion_service():
	if _remote_avatar_motion_service == null:
		_remote_avatar_motion_service = RemoteAvatarMotionService.new()
	return _remote_avatar_motion_service


func _get_remote_avatar_runtime_service():
	if _remote_avatar_runtime_service == null:
		_remote_avatar_runtime_service = RemoteAvatarRuntimeService.new()
	return _remote_avatar_runtime_service


func _get_remote_avatar_visual_service():
	if _remote_avatar_visual_service == null:
		_remote_avatar_visual_service = RemoteAvatarVisualService.new()
	return _remote_avatar_visual_service


func _get_snapshot_serialization_service():
	if _snapshot_serialization_service == null:
		_snapshot_serialization_service = SnapshotSerializationService.new()
	return _snapshot_serialization_service


func _get_network_state_collection_service():
	if _network_state_collection_service == null:
		_network_state_collection_service = NetworkStateCollectionService.new()
	return _network_state_collection_service


func _get_client_sync_flow_service():
	if _client_sync_flow_service == null:
		_client_sync_flow_service = ClientSyncFlowService.new()
	return _client_sync_flow_service


func _get_host_sync_flow_service():
	if _host_sync_flow_service == null:
		_host_sync_flow_service = HostSyncFlowService.new()
	return _host_sync_flow_service


func _build_steam_lobby_state_snapshot() -> Dictionary:
	return {
		"steam_lobby_action": steam_lobby_action,
		"steam_lobby_id_text": steam_lobby_id_text,
		"_steam_lobby_id": _steam_lobby_id,
		"_steam_lobby_owner_steam_id": _steam_lobby_owner_steam_id,
		"_steam_lobby_member_steam_ids": _steam_lobby_member_steam_ids.duplicate(true),
		"_steam_lobby_pending_action": _steam_lobby_pending_action,
		"network_mode": network_mode,
		"net_transport_mode": net_transport_mode,
		"_migration_pause_world_authority": _migration_pause_world_authority,
		"_current_host_steam_id": _current_host_steam_id,
		"_host_migration_target_steam_id": _host_migration_target_steam_id,
		"_host_migration_in_progress": _host_migration_in_progress,
	}


func _apply_steam_lobby_state_snapshot(state: Dictionary) -> void:
	steam_lobby_action = str(state.get("steam_lobby_action", steam_lobby_action))
	steam_lobby_id_text = str(state.get("steam_lobby_id_text", steam_lobby_id_text))
	_steam_lobby_id = int(state.get("_steam_lobby_id", _steam_lobby_id))
	_steam_lobby_owner_steam_id = int(
		state.get("_steam_lobby_owner_steam_id", _steam_lobby_owner_steam_id)
	)
	var members_variant: Variant = state.get(
		"_steam_lobby_member_steam_ids", _steam_lobby_member_steam_ids
	)
	if members_variant is Array:
		_steam_lobby_member_steam_ids.clear()
		for member_variant in members_variant:
			_steam_lobby_member_steam_ids.append(int(member_variant))
	_steam_lobby_pending_action = str(
		state.get("_steam_lobby_pending_action", _steam_lobby_pending_action)
	)
	network_mode = str(state.get("network_mode", network_mode))
	net_transport_mode = str(state.get("net_transport_mode", net_transport_mode))
	_migration_pause_world_authority = bool(
		state.get("_migration_pause_world_authority", _migration_pause_world_authority)
	)
	_current_host_steam_id = int(state.get("_current_host_steam_id", _current_host_steam_id))
	_host_migration_target_steam_id = int(
		state.get("_host_migration_target_steam_id", _host_migration_target_steam_id)
	)
	_host_migration_in_progress = bool(
		state.get("_host_migration_in_progress", _host_migration_in_progress)
	)


func _resource_file_exists(path: String) -> bool:
	var safe_path: String = path.strip_edges()
	if safe_path.is_empty():
		return false
	if FileAccess.file_exists(safe_path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(safe_path))


func _load_packed_scene_from_gltf_runtime(path: String) -> PackedScene:
	if not ClassDB.class_exists("GLTFDocument") or not ClassDB.class_exists("GLTFState"):
		return null
	var gltf_doc_obj: Object = ClassDB.instantiate("GLTFDocument")
	var gltf_state_obj: Object = ClassDB.instantiate("GLTFState")
	if gltf_doc_obj == null or gltf_state_obj == null:
		return null
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: int = _int_from_variant(
		gltf_doc_obj.call("append_from_file", abs_path, gltf_state_obj), ERR_CANT_OPEN
	)
	if err != OK:
		err = _int_from_variant(
			gltf_doc_obj.call("append_from_file", path, gltf_state_obj), ERR_CANT_OPEN
		)
	if err != OK:
		return null
	var scene_variant: Variant = gltf_doc_obj.call("generate_scene", gltf_state_obj)
	if not (scene_variant is Node):
		return null
	var scene_root: Node = scene_variant as Node
	var packed: PackedScene = PackedScene.new()
	if packed.pack(scene_root) != OK:
		scene_root.free()
		return null
	scene_root.free()
	return packed


func _exit_tree() -> void:
	leave_steam_lobby(true)


func _process(delta: float) -> void:
	_pump_steam_callbacks_if_needed()
	_update_remote_avatar_smoothing(delta)
	_tick_steam_lobby_runtime(maxf(delta, 0.0))
	_status_refresh_elapsed_sec += maxf(delta, 0.0)
	if _status_refresh_elapsed_sec >= 0.5:
		_status_refresh_elapsed_sec = 0.0
		_refresh_status_text()


func _physics_process(delta: float) -> void:
	if not _is_network_running:
		return
	var mode: String = network_mode.strip_edges().to_lower()
	if mode == "host":
		_tick_host(delta)
	elif mode == "client":
		_tick_client(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_network_running:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if not mouse_event.pressed:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _is_mouse_idle_for_model_inspect():
		return
	var clicked_peer_id: int = _pick_remote_peer_by_mouse_position(mouse_event.position)
	if clicked_peer_id > 0:
		if _ui_observed_peer_id != clicked_peer_id:
			_ui_observed_peer_id = clicked_peer_id
			_notify_game_ui_observe_peer(_ui_observed_peer_id)
		_notify_game_ui_observe_boss(false)
		_notify_game_ui_observe_enemy({})
		return
	if _is_click_on_local_hero(mouse_event.position):
		if _ui_observed_peer_id != 0:
			_ui_observed_peer_id = 0
			_notify_game_ui_observe_peer(0)
		_notify_game_ui_observe_boss(false)
		_notify_game_ui_observe_enemy({})
		return
	if _is_click_on_boss(mouse_event.position):
		if _ui_observed_peer_id != 0:
			_ui_observed_peer_id = 0
			_notify_game_ui_observe_peer(0)
		_notify_game_ui_observe_boss(true)
		_notify_game_ui_observe_enemy({})
		return
	var enemy_observe_state: Dictionary = _pick_enemy_observe_state_by_mouse_position(
		mouse_event.position
	)
	if not enemy_observe_state.is_empty():
		if _ui_observed_peer_id != 0:
			_ui_observed_peer_id = 0
			_notify_game_ui_observe_peer(0)
		_notify_game_ui_observe_boss(false)
		_notify_game_ui_observe_enemy(enemy_observe_state)


func _is_mouse_idle_for_model_inspect() -> bool:
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller == null:
		return true
	return bool(hero_controller.is_mouse_idle_for_model_inspect())
	return true


func create_steam_lobby_and_host() -> bool:
	if not steam_lobby_enabled:
		return false
	var init_result: Dictionary = _ensure_steam_initialized()
	if not bool(init_result.get("ok", false)):
		_status_event_hint = str(init_result.get("hint", "lobby_create_failed"))
		_refresh_status_text()
		return false
	var steam: Object = init_result.get("steam", null)
	if steam == null or not steam.has_method("createLobby"):
		_status_event_hint = "lobby_create_failed(api_missing)"
		_refresh_status_text()
		return false
	var requested_members: int = clampi(steam_lobby_max_members, 2, 8)
	var next_state: Dictionary = _get_steam_lobby_service().begin_create_host(
		_build_steam_lobby_state_snapshot()
	)
	_apply_steam_lobby_state_snapshot(next_state.get("state", {}))
	steam.call("createLobby", _resolve_steam_lobby_type_constant(), requested_members)
	_status_event_hint = str(next_state.get("hint", "lobby_create_requested"))
	_refresh_status_text()
	return true


func join_steam_lobby_and_connect(lobby_id_value: String) -> bool:
	if not steam_lobby_enabled:
		return false
	var lobby_id: int = _parse_steam_id_text(lobby_id_value)
	if lobby_id <= 0:
		return false
	var init_result: Dictionary = _ensure_steam_initialized()
	if not bool(init_result.get("ok", false)):
		_status_event_hint = str(init_result.get("hint", "lobby_join_failed"))
		_refresh_status_text()
		return false
	var steam: Object = init_result.get("steam", null)
	if steam == null or not steam.has_method("joinLobby"):
		_status_event_hint = "lobby_join_failed(api_missing)"
		_refresh_status_text()
		return false
	var next_state: Dictionary = _get_steam_lobby_service().begin_join_client(
		_build_steam_lobby_state_snapshot(), lobby_id
	)
	_apply_steam_lobby_state_snapshot(next_state.get("state", {}))
	steam.call("joinLobby", lobby_id)
	_status_event_hint = str(next_state.get("hint", "lobby_join_requested(%d)" % lobby_id))
	_refresh_status_text()
	return true


func leave_steam_lobby(close_network: bool = true) -> void:
	_steam_lobby_explicit_leave_in_progress = true
	if close_network:
		_transfer_lobby_owner_before_leave()
	if close_network and _is_network_running:
		stop_network()
	var lobby_id: int = _steam_lobby_id
	var steam: Object = _get_steam_singleton()
	if lobby_id > 0 and steam != null and steam.has_method("leaveLobby"):
		steam.call("leaveLobby", lobby_id)
	_clear_steam_lobby_runtime_state()
	_steam_lobby_explicit_leave_in_progress = false


func invite_friend_to_steam_lobby(friend_steam_id: String) -> bool:
	if _steam_lobby_id <= 0:
		return false
	var steam: Object = _get_steam_singleton()
	if steam == null or not steam.has_method("inviteUserToLobby"):
		return false
	var invitee_id: int = _parse_steam_id_text(friend_steam_id)
	if invitee_id <= 0:
		return false
	return bool(steam.call("inviteUserToLobby", _steam_lobby_id, invitee_id))


func _transfer_lobby_owner_before_leave() -> void:
	if _steam_lobby_id <= 0:
		return
	var local_steam_id: int = _get_local_steam_id_int()
	var successor_steam_id: int = _get_steam_lobby_service().pick_successor_owner(
		_steam_lobby_id, local_steam_id, _steam_lobby_owner_steam_id, _steam_lobby_member_steam_ids
	)
	if successor_steam_id <= 0:
		return
	var steam: Object = _get_steam_singleton()
	if steam == null or not steam.has_method("setLobbyOwner"):
		return
	steam.call("setLobbyOwner", _steam_lobby_id, successor_steam_id)
	_host_migration_target_steam_id = successor_steam_id
	_status_event_hint = "lobby_owner_transfer(%d)" % successor_steam_id
	_refresh_status_text()


func has_active_steam_lobby() -> bool:
	return _steam_lobby_id > 0


func get_active_steam_lobby_id() -> int:
	return _steam_lobby_id


func is_local_world_authority() -> bool:
	if _migration_pause_world_authority:
		return false
	var mode_text: String = network_mode.strip_edges().to_lower()
	if mode_text == "client":
		return false
	if mode_text == "host":
		return true
	return multiplayer.multiplayer_peer == null


func _should_start_with_steam_lobby() -> bool:
	return _get_steam_lobby_service().should_start_with_lobby(
		steam_lobby_enabled,
		steam_lobby_action,
		steam_lobby_id_text,
		_parse_steam_id_text(steam_lobby_id_text)
	)


func _begin_network_start_via_steam_lobby() -> void:
	var action_text: String = steam_lobby_action.strip_edges().to_lower()
	match action_text:
		"create":
			create_steam_lobby_and_host()
		"join":
			join_steam_lobby_and_connect(steam_lobby_id_text)
		_:
			start_network()


func _connect_steam_signals_once() -> void:
	if _steam_signal_handlers_connected:
		return
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return
	if (
		steam.has_signal("lobby_created")
		and not steam.is_connected("lobby_created", Callable(self, "_on_steam_lobby_created"))
	):
		steam.connect("lobby_created", Callable(self, "_on_steam_lobby_created"))
	if (
		steam.has_signal("lobby_joined")
		and not steam.is_connected("lobby_joined", Callable(self, "_on_steam_lobby_joined"))
	):
		steam.connect("lobby_joined", Callable(self, "_on_steam_lobby_joined"))
	if (
		steam.has_signal("lobby_chat_update")
		and not steam.is_connected(
			"lobby_chat_update", Callable(self, "_on_steam_lobby_chat_update")
		)
	):
		steam.connect("lobby_chat_update", Callable(self, "_on_steam_lobby_chat_update"))
	if (
		steam.has_signal("lobby_data_update")
		and not steam.is_connected(
			"lobby_data_update", Callable(self, "_on_steam_lobby_data_update")
		)
	):
		steam.connect("lobby_data_update", Callable(self, "_on_steam_lobby_data_update"))
	if (
		steam.has_signal("join_requested")
		and not steam.is_connected("join_requested", Callable(self, "_on_steam_join_requested"))
	):
		steam.connect("join_requested", Callable(self, "_on_steam_join_requested"))
	_steam_signal_handlers_connected = true


func _on_steam_lobby_created(connect_status: int, lobby_id: int) -> void:
	if lobby_id <= 0:
		return
	var result: Dictionary = _get_steam_lobby_service().handle_lobby_created(
		_build_steam_lobby_state_snapshot(),
		connect_status,
		lobby_id,
		_is_steam_result_ok(connect_status)
	)
	_apply_steam_lobby_state_snapshot(result.get("state", {}))
	if not bool(result.get("changed", false)):
		return
	_refresh_steam_lobby_state_from_backend()
	_status_event_hint = str(result.get("hint", "lobby_created(%d)" % lobby_id))
	_refresh_status_text()


func _on_steam_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if lobby_id <= 0:
		return
	var result: Dictionary = _get_steam_lobby_service().handle_lobby_joined(
		_build_steam_lobby_state_snapshot(), lobby_id, response, _is_steam_result_ok(response)
	)
	_apply_steam_lobby_state_snapshot(result.get("state", {}))
	if not bool(result.get("changed", false)):
		return
	_refresh_steam_lobby_state_from_backend()
	_sync_local_lobby_member_data()
	if bool(result.get("should_start_network", false)):
		start_network()
	_status_event_hint = str(result.get("hint", "lobby_joined(%d)" % lobby_id))
	_refresh_status_text()


func _on_steam_lobby_chat_update(
	lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int
) -> void:
	if lobby_id != _steam_lobby_id:
		return
	_refresh_steam_lobby_state_from_backend()


func _on_steam_lobby_data_update(success: int, lobby_id: int, _member_id: int) -> void:
	if lobby_id != _steam_lobby_id:
		return
	if not _is_steam_result_ok(success):
		return
	_refresh_steam_lobby_state_from_backend()


func _on_steam_join_requested(lobby_id: int, inviter_steam_id: int) -> void:
	emit_signal("steam_lobby_join_requested", lobby_id, inviter_steam_id)
	if not steam_lobby_connect_on_join_requested:
		return
	join_steam_lobby_and_connect(str(lobby_id))


func _tick_steam_lobby_runtime(delta: float) -> void:
	var local_steam_id: int = 0
	if _steam_lobby_id > 0:
		local_steam_id = _get_local_steam_id_int()
	var lobby_tick: Dictionary = _get_steam_lobby_service().advance_lobby_poll(
		_steam_lobby_id,
		_steam_lobby_poll_elapsed_sec,
		delta,
		host_migration_owner_poll_interval_sec,
		_steam_lobby_owner_steam_id,
		local_steam_id
	)
	_steam_lobby_poll_elapsed_sec = float(
		lobby_tick.get("poll_elapsed_sec", _steam_lobby_poll_elapsed_sec)
	)
	if bool(lobby_tick.get("should_refresh", false)):
		_refresh_steam_lobby_state_from_backend()
		if bool(lobby_tick.get("should_sync_metadata", false)):
			_sync_steam_lobby_metadata()
		if bool(lobby_tick.get("should_sync_member_data", false)):
			_sync_local_lobby_member_data()
	if _host_migration_in_progress:
		_tick_host_migration_recovery()


func _refresh_steam_lobby_state_from_backend() -> void:
	if _steam_lobby_id <= 0:
		return
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return
	var next_owner: int = _steam_lobby_owner_steam_id
	if steam.has_method("getLobbyOwner"):
		next_owner = _int_from_variant(steam.call("getLobbyOwner", _steam_lobby_id), next_owner)
	var next_members: Array[int] = []
	if steam.has_method("getNumLobbyMembers") and steam.has_method("getLobbyMemberByIndex"):
		var member_count: int = maxi(
			_int_from_variant(steam.call("getNumLobbyMembers", _steam_lobby_id), 0), 0
		)
		for member_index in range(member_count):
			var member_steam_id: int = _int_from_variant(
				steam.call("getLobbyMemberByIndex", _steam_lobby_id, member_index), 0
			)
			if member_steam_id > 0:
				next_members.append(member_steam_id)
	next_members.sort()
	var result: Dictionary = _get_steam_lobby_service().apply_backend_snapshot(
		_build_steam_lobby_state_snapshot(), next_owner, next_members
	)
	_apply_steam_lobby_state_snapshot(result.get("state", {}))
	if bool(result.get("changed", false)):
		emit_signal(
			"steam_lobby_changed",
			_steam_lobby_id,
			_steam_lobby_owner_steam_id,
			_steam_lobby_member_steam_ids.size()
		)
		if result.has("hint"):
			_status_event_hint = str(result.get("hint", ""))
			_refresh_status_text()


func _sync_steam_lobby_metadata() -> void:
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return
	var local_steam_id: int = _get_local_steam_id_int()
	if not _get_steam_lobby_service().should_sync_metadata(
		_steam_lobby_id, _steam_lobby_owner_steam_id, local_steam_id
	):
		return
	if not steam.has_method("setLobbyData"):
		return
	var payload: Dictionary = _get_steam_lobby_service().build_metadata_payload(
		_steam_lobby_id, steam_lobby_name, local_steam_id, network_mode, host_migration_enabled
	)
	for key_variant in payload.keys():
		var key: String = str(key_variant)
		steam.call("setLobbyData", _steam_lobby_id, key, str(payload[key_variant]))


func _sync_local_lobby_member_data() -> void:
	var steam: Object = _get_steam_singleton()
	if steam == null or not steam.has_method("setLobbyMemberData"):
		return
	if not _get_steam_lobby_service().should_sync_member_data(_steam_lobby_id):
		return
	var hero_state: Dictionary = _collect_local_hero_state()
	var hero_profile: String = str(hero_state.get("hero_profile", "")).strip_edges()
	var payload: Dictionary = _get_steam_lobby_service().build_member_data_payload(
		_get_local_steam_id_int(), _is_local_hero_selection_confirmed(), hero_profile
	)
	for key_variant in payload.keys():
		var key: String = str(key_variant)
		steam.call("setLobbyMemberData", _steam_lobby_id, key, str(payload[key_variant]))


func _begin_host_migration_wait(reason: String) -> void:
	if not host_migration_enabled or _steam_lobby_id <= 0:
		return
	_migration_pause_world_authority = true
	_host_migration_in_progress = true
	_refresh_steam_lobby_state_from_backend()
	_host_migration_target_steam_id = _steam_lobby_owner_steam_id
	var now_ms: int = Time.get_ticks_msec()
	_host_migration_takeover_ready_ms = (
		now_ms + int(round(maxf(host_migration_takeover_delay_sec, 0.2) * 1000.0))
	)
	_host_migration_reconnect_ready_ms = (
		now_ms + int(round(maxf(host_migration_reconnect_delay_sec, 0.25) * 1000.0))
	)
	emit_signal("host_migration_state_changed", true, false, _host_migration_target_steam_id)
	_status_event_hint = "host_migration_wait(%s)" % reason
	_refresh_status_text()


func _tick_host_migration_recovery() -> void:
	if _steam_lobby_id <= 0:
		_host_migration_in_progress = false
		_migration_pause_world_authority = false
		emit_signal("host_migration_state_changed", false, false, 0)
		return
	_refresh_steam_lobby_state_from_backend()
	var owner_steam_id: int = _steam_lobby_owner_steam_id
	if owner_steam_id <= 0:
		return
	_host_migration_target_steam_id = owner_steam_id
	var now_ms: int = Time.get_ticks_msec()
	var local_steam_id: int = _get_local_steam_id_int()
	if owner_steam_id == local_steam_id:
		if (
			now_ms >= _host_migration_takeover_ready_ms
			and (network_mode.strip_edges().to_lower() != "host" or not _is_network_running)
		):
			_attempt_host_takeover_from_lobby()
		return
	if (
		now_ms >= _host_migration_reconnect_ready_ms
		and (network_mode.strip_edges().to_lower() != "client" or not _is_network_running)
	):
		_attempt_client_reconnect_from_lobby()


func _attempt_host_takeover_from_lobby() -> void:
	_clear_cached_peer_runtime_for_migration()
	network_mode = "host"
	_set_transport_mode("steam_relay")
	_migration_pause_world_authority = false
	start_network()
	if not _is_network_running:
		_migration_pause_world_authority = true
		_host_migration_takeover_ready_ms = (
			Time.get_ticks_msec()
			+ int(round(maxf(host_migration_takeover_delay_sec, 0.2) * 1000.0))
		)
		return
	_finalize_host_migration_after_start(true)


func _attempt_client_reconnect_from_lobby() -> void:
	network_mode = "client"
	_set_transport_mode("steam_relay")
	_migration_pause_world_authority = true
	start_network()
	if _is_network_running:
		_status_event_hint = "host_migration_reconnect_pending"
		_refresh_status_text()
		return
	_host_migration_reconnect_ready_ms = (
		Time.get_ticks_msec() + int(round(maxf(host_migration_reconnect_delay_sec, 0.25) * 1000.0))
	)


func _finalize_host_migration_after_start(local_is_host: bool) -> void:
	_host_migration_in_progress = false
	_migration_pause_world_authority = false
	_current_host_steam_id = _steam_lobby_owner_steam_id
	emit_signal("host_migration_state_changed", false, local_is_host, _current_host_steam_id)
	_status_event_hint = "host_migration_done(host=%d)" % _current_host_steam_id
	_refresh_status_text()


func _clear_cached_peer_runtime_for_migration() -> void:
	var cached_peer_ids: Array = _peer_latest_equipment_state.keys()
	var ui: GameUI = _get_game_ui()
	if ui != null:
		for peer_id_variant in cached_peer_ids:
			ui.authority_drop_peer_state(int(peer_id_variant))
	_clear_remote_avatars()
	_peer_latest_hero_state.clear()
	_peer_latest_equipment_state.clear()
	_peer_latest_hero_command.clear()
	_peer_latest_skill_event.clear()
	_peer_latest_equipment_signatures.clear()
	_peer_last_input_seq.clear()
	_peer_last_hero_command_seq.clear()
	_peer_last_damage_request_seq.clear()
	_peer_last_damage_request_ms.clear()
	_peer_last_hero_positions.clear()
	_peer_last_hero_pos_ms.clear()
	_peer_damage_budget_tokens.clear()
	_peer_damage_budget_last_ms.clear()
	_peer_damage_accept_total.clear()
	_peer_damage_reject_total.clear()
	_peer_damage_reject_reason_counts.clear()
	_peer_damage_breaker_window_start_ms.clear()
	_peer_damage_breaker_reject_count.clear()
	_peer_damage_breaker_blocked_until_ms.clear()
	_peer_input_latency_ms.clear()
	_peer_hero_selection_confirmed.clear()
	focus_ui_on_self()


func _clear_steam_lobby_runtime_state() -> void:
	var next_state: Dictionary = _get_steam_lobby_service().clear_runtime_state(
		_build_steam_lobby_state_snapshot()
	)
	_apply_steam_lobby_state_snapshot(next_state)


func _resolve_steam_lobby_type_constant() -> int:
	match steam_lobby_visibility.strip_edges().to_lower():
		"private":
			return _get_steam_constant("LOBBY_TYPE_PRIVATE", 0)
		"public":
			return _get_steam_constant("LOBBY_TYPE_PUBLIC", 2)
		"invisible":
			return _get_steam_constant("LOBBY_TYPE_INVISIBLE", 3)
		_:
			return _get_steam_constant("LOBBY_TYPE_FRIENDS_ONLY", 1)


func _get_steam_constant(constant_name: String, fallback: int) -> int:
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return fallback
	if not _object_has_property(steam, constant_name):
		return fallback
	return _int_from_variant(steam.get(constant_name), fallback)


func _is_steam_result_ok(result_value: int) -> bool:
	if result_value == 1:
		return true
	var ok_result: int = _get_steam_constant("RESULT_OK", 1)
	if result_value == ok_result:
		return true
	var room_success: int = _get_steam_constant("CHAT_ROOM_ENTER_RESPONSE_SUCCESS", 1)
	return result_value == room_success


func _get_local_steam_id_int() -> int:
	if not _steam_initialized and _steam_lobby_id <= 0:
		return 0
	return _parse_steam_id_text(_resolve_effective_steam_local_id())


func _tick_host(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	var host_id: int = multiplayer.get_unique_id()
	if host_id > 0:
		if sync_hero_state:
			_peer_latest_hero_state[host_id] = _build_network_hero_state(
				_collect_local_hero_state()
			)
		if sync_equipment_state:
			_peer_latest_equipment_state[host_id] = _collect_local_equipment_state()

	if multiplayer.get_peers().is_empty():
		return

	var host_plan: Dictionary = (
		_get_host_sync_flow_service()
		. build_host_tick_plan(
			{
				"delta": safe_delta,
				"hero_send_elapsed_sec": _hero_send_elapsed_sec,
				"world_send_elapsed_sec": _world_send_elapsed_sec,
				"world_reliable_keyframe_elapsed_sec": _world_reliable_keyframe_elapsed_sec,
				"has_peers": not multiplayer.get_peers().is_empty(),
				"hero_sync_interval_sec": hero_sync_interval_sec,
				"active_world_interval_sec": _get_active_world_sync_interval_sec(),
				"world_reliable_keyframe_interval_sec": world_reliable_keyframe_interval_sec,
			}
		)
	)
	_hero_send_elapsed_sec = float(host_plan.get("hero_send_elapsed_sec", _hero_send_elapsed_sec))
	_world_send_elapsed_sec = float(
		host_plan.get("world_send_elapsed_sec", _world_send_elapsed_sec)
	)
	_world_reliable_keyframe_elapsed_sec = float(
		host_plan.get("world_reliable_keyframe_elapsed_sec", _world_reliable_keyframe_elapsed_sec)
	)
	_equipment_send_elapsed_sec += safe_delta
	_hero_reliable_keyframe_elapsed_sec += safe_delta
	if bool(host_plan.get("send_hero_snapshot", false)):
		var hero_snapshot: Dictionary = _build_hero_snapshot(false)
		rpc("rpc_hero_snapshot", hero_snapshot)
	if (
		sync_equipment_state
		and _hero_reliable_keyframe_elapsed_sec >= maxf(hero_reliable_keyframe_interval_sec, 0.2)
	):
		_hero_reliable_keyframe_elapsed_sec = fmod(
			_hero_reliable_keyframe_elapsed_sec, maxf(hero_reliable_keyframe_interval_sec, 0.2)
		)
		_equipment_send_elapsed_sec = 0.0
		var hero_keyframe_snapshot: Dictionary = _build_hero_snapshot(true)
		rpc("rpc_hero_snapshot_keyframe", hero_keyframe_snapshot)
	elif (
		sync_equipment_state
		and _equipment_send_elapsed_sec >= maxf(equipment_sync_interval_sec, 0.15)
	):
		_equipment_send_elapsed_sec = fmod(
			_equipment_send_elapsed_sec, maxf(equipment_sync_interval_sec, 0.15)
		)
		var equipment_snapshot: Dictionary = _build_equipment_snapshot()
		rpc("rpc_equipment_snapshot", equipment_snapshot)

	if bool(host_plan.get("send_world_snapshot", false)):
		var world_snapshot: Dictionary = _build_world_snapshot(false)
		world_snapshot = _trim_unreliable_world_snapshot_to_mtu(
			world_snapshot, world_packet_budget_bytes
		)
		_last_world_packet_bytes = _estimate_payload_bytes(world_snapshot)
		_adjust_dynamic_world_sync_interval(world_snapshot, _last_world_packet_bytes)
		rpc("rpc_world_snapshot", world_snapshot)
		if sync_mob_state:
			_send_mob_motion_snapshots()
	if bool(host_plan.get("send_world_keyframe", false)):
		var keyframe_snapshot: Dictionary = _build_world_snapshot(true)
		keyframe_snapshot["keyframe"] = true
		keyframe_snapshot = _trim_unreliable_world_snapshot_to_mtu(
			keyframe_snapshot, world_packet_budget_bytes
		)
		rpc("rpc_world_snapshot_keyframe", keyframe_snapshot)


func _tick_client(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	_send_elapsed_sec += safe_delta
	_equipment_send_elapsed_sec += safe_delta
	_client_ping_elapsed_sec += safe_delta
	_client_initial_hero_state_resend_elapsed_sec += safe_delta
	if multiplayer.get_peers().is_empty():
		return
	_try_send_client_ping()
	var equipment_state: Dictionary = _collect_local_equipment_state()
	var equipment_signature: String = _build_state_signature(equipment_state)
	var should_send_equipment: bool = _get_client_sync_flow_service().should_send_equipment_state(
		equipment_signature, _last_sent_equipment_signature
	)
	if should_send_equipment:
		rpc_id(1, "rpc_submit_client_equipment_state", equipment_state, equipment_signature)
		_last_sent_equipment_signature = equipment_signature
		_equipment_send_elapsed_sec = 0.0
	var hero_state_full: Dictionary = _collect_local_hero_state()
	_refresh_client_local_hero_bootstrap_state()
	_try_send_initial_client_hero_state(hero_state_full)
	_send_latest_skill_event_if_needed(hero_state_full)
	var send_gate: Dictionary = _get_client_sync_flow_service().should_send_client_input(
		_send_elapsed_sec, send_interval_sec
	)
	_send_elapsed_sec = float(send_gate.get("next_send_elapsed_sec", _send_elapsed_sec))
	if not bool(send_gate.get("should_send", false)):
		return
	_send_latest_hero_command_if_needed(hero_state_full)
	var hero_state: Dictionary = _build_client_input_hero_state(hero_state_full)
	var event_filter: Dictionary = _get_client_sync_flow_service().filter_skill_event_for_send(
		hero_state, _client_last_sent_skill_event_seq
	)
	hero_state = event_filter.get("hero_state", hero_state)
	_client_last_sent_skill_event_seq = int(
		event_filter.get("next_last_sent_skill_event_seq", _client_last_sent_skill_event_seq)
	)
	var input_bundle: Dictionary = _build_client_input_bundle(hero_state)
	var input_payload_bytes: int = _estimate_payload_bytes(input_bundle)
	var unreliable_max_bytes: int = clampi(client_input_unreliable_max_bytes, 512, 1300)
	if input_payload_bytes > unreliable_max_bytes:
		rpc_id(1, "rpc_submit_client_input_reliable", input_bundle)
	else:
		rpc_id(1, "rpc_submit_client_input", input_bundle)


func _try_send_client_ping() -> void:
	var result: Dictionary = _get_client_sync_flow_service().advance_client_ping(
		network_mode,
		_client_ping_elapsed_sec,
		net_ping_interval_sec,
		_client_ping_seq,
		_client_ping_sent_ms,
		Time.get_ticks_msec()
	)
	_client_ping_elapsed_sec = float(result.get("ping_elapsed_sec", _client_ping_elapsed_sec))
	_client_ping_seq = int(result.get("next_ping_seq", _client_ping_seq))
	var ping_sent_variant: Variant = result.get("ping_sent_ms", _client_ping_sent_ms)
	if ping_sent_variant is Dictionary:
		_client_ping_sent_ms = (ping_sent_variant as Dictionary).duplicate(true)
	if not bool(result.get("should_send", false)):
		return
	rpc_id(
		1,
		"rpc_client_ping",
		int(result.get("seq", _client_ping_seq)),
		int(result.get("sent_ms", Time.get_ticks_msec()))
	)


func start_network() -> void:
	stop_network()

	var mode: String = network_mode.strip_edges().to_lower()
	if mode == "offline":
		_status_event_hint = ""
		_refresh_status_text()
		return

	_refresh_steam_stub_endpoint_map()
	if steam_lobby_enabled and _steam_lobby_id > 0:
		_refresh_steam_lobby_state_from_backend()
	var transport_mode: String = net_transport_mode.strip_edges().to_lower()
	var err: int = ERR_CANT_CREATE
	var start_hint: String = "network_started"
	if transport_mode == "steam_relay":
		var relay_result: Dictionary = _create_steam_relay_peer(mode)
		err = _int_from_variant(relay_result.get("err", ERR_CANT_CREATE), ERR_CANT_CREATE)
		if bool(relay_result.get("ok", false)):
			var relay_peer_variant: Variant = relay_result.get("peer", null)
			if relay_peer_variant is MultiplayerPeer:
				_peer = relay_peer_variant as MultiplayerPeer
			else:
				_peer = null
				err = ERR_CANT_CREATE
		if relay_result.has("hint"):
			start_hint = str(relay_result.get("hint", start_hint))
	elif transport_mode == "steam_stub":
		var steam_stub_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		var local_id: String = _resolve_effective_steam_local_id()
		var target_host_id: String = steam_target_host_id.strip_edges()
		if target_host_id.is_empty():
			if mode == "host":
				target_host_id = local_id
			elif not server_host.strip_edges().is_empty():
				target_host_id = server_host.strip_edges()
		if mode == "host":
			var listen_port: int = maxi(steam_stub_listen_port, 1)
			err = steam_stub_peer.create_server(listen_port, 8)
			start_hint = (
				"network_started(steam_stub app=%d local=%s host_id=%s listen=%d)"
				% [
					steam_app_id,
					local_id if not local_id.is_empty() else "-",
					target_host_id if not target_host_id.is_empty() else "-",
					listen_port
				]
			)
		else:
			var endpoint: Dictionary = _resolve_steam_stub_endpoint(target_host_id)
			var remote_host: String = str(endpoint.get("host", "")).strip_edges()
			var remote_port: int = _int_from_variant(
				endpoint.get("port", steam_stub_default_remote_port), steam_stub_default_remote_port
			)
			if remote_host.is_empty() or remote_port <= 0:
				err = ERR_INVALID_PARAMETER
			else:
				err = steam_stub_peer.create_client(remote_host, maxi(remote_port, 1))
				start_hint = (
					"network_started(steam_stub app=%d local=%s host_id=%s dial=%s:%d)"
					% [
						steam_app_id,
						local_id if not local_id.is_empty() else "-",
						target_host_id if not target_host_id.is_empty() else "-",
						remote_host,
						remote_port
					]
				)
		if err == OK:
			_peer = steam_stub_peer
	else:
		var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		if mode == "host":
			err = enet_peer.create_server(maxi(server_port, 1), 8)
		else:
			err = enet_peer.create_client(server_host.strip_edges(), maxi(server_port, 1))
		start_hint = "network_started(enet_direct)"
		if err == OK:
			_peer = enet_peer

	if err != OK:
		_peer = null
		var fail_hint: String = "start_failed(err=%d)" % err
		if start_hint.begins_with("start_failed("):
			fail_hint = start_hint
		_status_event_hint = fail_hint
		_refresh_status_text()
		push_error("net_session_controller: %s" % fail_hint)
		return

	multiplayer.multiplayer_peer = _peer
	_is_network_running = true
	_apply_host_background_runtime_override(mode == "host")
	_send_elapsed_sec = 0.0
	_equipment_send_elapsed_sec = 0.0
	_hero_send_elapsed_sec = 0.0
	_hero_reliable_keyframe_elapsed_sec = maxf(hero_reliable_keyframe_interval_sec, 0.2)
	_world_send_elapsed_sec = 0.0
	_world_reliable_keyframe_elapsed_sec = 0.0
	_host_hero_snapshot_seq = 0
	_host_world_snapshot_seq = 0
	_last_applied_hero_snapshot_seq = -1
	_last_applied_world_snapshot_seq = -1
	_client_input_seq = 0
	_client_recent_input_frames.clear()
	_client_ping_elapsed_sec = 0.0
	_client_ping_seq = 0
	_client_ping_sent_ms.clear()
	_client_last_rtt_ms = -1
	_client_avg_rtt_ms = -1.0
	_local_last_sent_hero_command_seq = -1
	_client_last_sent_skill_event_seq = -1
	_client_enemy_damage_request_seq = 0
	_client_last_sent_enemy_damage_request_seq = -1
	_client_initial_hero_state_sent = false
	_client_last_local_hero_instance_id = 0
	_client_initial_hero_state_ack_required_seq = -1
	_client_initial_hero_state_resend_elapsed_sec = 0.0
	_last_sent_equipment_signature = ""
	_last_ack_input_seq_from_host = -1
	_local_equipment_request_seq = 0
	_peer_last_input_seq.clear()
	_peer_last_hero_command_seq.clear()
	_peer_last_damage_request_seq.clear()
	_peer_last_damage_request_ms.clear()
	_peer_last_hero_positions.clear()
	_peer_last_hero_pos_ms.clear()
	_peer_damage_budget_tokens.clear()
	_peer_damage_budget_last_ms.clear()
	_peer_damage_accept_total.clear()
	_peer_damage_reject_total.clear()
	_peer_damage_reject_reason_counts.clear()
	_peer_damage_breaker_window_start_ms.clear()
	_peer_damage_breaker_reject_count.clear()
	_peer_damage_breaker_blocked_until_ms.clear()
	_peer_input_latency_ms.clear()
	_peer_hero_selection_confirmed.clear()
	_peer_latest_hero_command.clear()
	_peer_latest_skill_event.clear()
	_peer_latest_equipment_signatures.clear()
	_last_snapshot_latency_ms = -1
	_avg_snapshot_latency_ms = -1.0
	_reset_world_sync_adaptive_runtime()
	_reset_local_skill_event_runtime(true)
	_status_refresh_elapsed_sec = 0.0
	_status_event_hint = start_hint
	_apply_network_authority_mode()
	var transport_mode_after_start: String = net_transport_mode.strip_edges().to_lower()
	var use_steam_identity: bool = (
		transport_mode_after_start == "steam_relay"
		or transport_mode_after_start == "steam_stub"
		or _steam_lobby_id > 0
	)
	if mode == "host":
		if use_steam_identity:
			_current_host_steam_id = _get_local_steam_id_int()
		else:
			_current_host_steam_id = 0
	else:
		_current_host_steam_id = _steam_lobby_owner_steam_id
		if _current_host_steam_id <= 0 and use_steam_identity:
			_current_host_steam_id = _parse_steam_id_text(_resolve_target_steam_host_id(mode))
	if _steam_lobby_id > 0:
		_sync_local_lobby_member_data()
		if mode == "host":
			_sync_steam_lobby_metadata()
	_refresh_status_text()


func stop_network() -> void:
	_apply_host_background_runtime_override(false)
	_clear_remote_avatars()
	_peer_latest_hero_state.clear()
	_peer_latest_equipment_state.clear()
	_peer_latest_hero_command.clear()
	_peer_latest_skill_event.clear()
	_peer_latest_equipment_signatures.clear()
	_peer_last_input_seq.clear()
	_peer_last_hero_command_seq.clear()
	_peer_last_damage_request_seq.clear()
	_peer_last_damage_request_ms.clear()
	_peer_last_hero_positions.clear()
	_peer_last_hero_pos_ms.clear()
	_peer_damage_budget_tokens.clear()
	_peer_damage_budget_last_ms.clear()
	_peer_damage_accept_total.clear()
	_peer_damage_reject_total.clear()
	_peer_damage_reject_reason_counts.clear()
	_peer_damage_breaker_window_start_ms.clear()
	_peer_damage_breaker_reject_count.clear()
	_peer_damage_breaker_blocked_until_ms.clear()
	_peer_input_latency_ms.clear()
	_peer_hero_selection_confirmed.clear()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_peer = null
	_is_network_running = false
	_send_elapsed_sec = 0.0
	_equipment_send_elapsed_sec = 0.0
	_hero_send_elapsed_sec = 0.0
	_hero_reliable_keyframe_elapsed_sec = 0.0
	_world_send_elapsed_sec = 0.0
	_world_reliable_keyframe_elapsed_sec = 0.0
	_host_hero_snapshot_seq = 0
	_host_world_snapshot_seq = 0
	_last_applied_hero_snapshot_seq = -1
	_last_applied_world_snapshot_seq = -1
	_client_input_seq = 0
	_client_recent_input_frames.clear()
	_client_ping_elapsed_sec = 0.0
	_client_ping_seq = 0
	_client_ping_sent_ms.clear()
	_client_last_rtt_ms = -1
	_client_avg_rtt_ms = -1.0
	_local_last_sent_hero_command_seq = -1
	_client_last_sent_skill_event_seq = -1
	_client_enemy_damage_request_seq = 0
	_client_last_sent_enemy_damage_request_seq = -1
	_client_initial_hero_state_sent = false
	_client_last_local_hero_instance_id = 0
	_client_initial_hero_state_ack_required_seq = -1
	_client_initial_hero_state_resend_elapsed_sec = 0.0
	_last_sent_equipment_signature = ""
	_last_ack_input_seq_from_host = -1
	_last_snapshot_latency_ms = -1
	_avg_snapshot_latency_ms = -1.0
	_local_equipment_request_seq = 0
	_current_host_steam_id = 0
	_reset_world_sync_adaptive_runtime()
	_reset_local_skill_event_runtime(false)
	_status_refresh_elapsed_sec = 0.0
	_status_event_hint = ""
	_ui_observed_peer_id = 0
	_notify_game_ui_observe_peer(0)
	_apply_network_authority_mode()
	_refresh_status_text()


func _apply_host_background_runtime_override(enable_for_host: bool) -> void:
	if not keep_host_active_in_background:
		_restore_host_background_runtime_override()
		return
	if enable_for_host:
		_enable_host_background_runtime_override()
	else:
		_restore_host_background_runtime_override()


func _enable_host_background_runtime_override() -> void:
	if _host_background_runtime_override_active:
		return
	if _object_has_property(OS, "low_processor_usage_mode"):
		_saved_low_processor_usage_mode = bool(OS.get("low_processor_usage_mode"))
		_saved_low_processor_usage_mode_valid = true
		OS.set("low_processor_usage_mode", false)
	if _object_has_property(OS, "low_processor_usage_mode_sleep_usec"):
		_saved_low_processor_usage_sleep_usec = _int_from_variant(
			OS.get("low_processor_usage_mode_sleep_usec"), 6900
		)
		_saved_low_processor_usage_sleep_usec_valid = true
		OS.set("low_processor_usage_mode_sleep_usec", 0)
	_host_background_runtime_override_active = true


func _restore_host_background_runtime_override() -> void:
	if not _host_background_runtime_override_active:
		return
	if (
		_saved_low_processor_usage_mode_valid
		and _object_has_property(OS, "low_processor_usage_mode")
	):
		OS.set("low_processor_usage_mode", _saved_low_processor_usage_mode)
	if (
		_saved_low_processor_usage_sleep_usec_valid
		and _object_has_property(OS, "low_processor_usage_mode_sleep_usec")
	):
		OS.set("low_processor_usage_mode_sleep_usec", _saved_low_processor_usage_sleep_usec)
	_saved_low_processor_usage_mode_valid = false
	_saved_low_processor_usage_sleep_usec_valid = false
	_host_background_runtime_override_active = false


func _connect_multiplayer_signals_once() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(peer_id: int) -> void:
	_status_event_hint = "peer_connected(id=%d)" % peer_id
	_refresh_status_text()


func _on_peer_disconnected(peer_id: int) -> void:
	_remove_remote_avatar(peer_id)
	_peer_latest_hero_state.erase(peer_id)
	_peer_latest_equipment_state.erase(peer_id)
	_peer_latest_equipment_signatures.erase(peer_id)
	_peer_latest_skill_event.erase(peer_id)
	_peer_last_input_seq.erase(peer_id)
	_peer_last_hero_command_seq.erase(peer_id)
	_peer_last_damage_request_seq.erase(peer_id)
	_peer_last_damage_request_ms.erase(peer_id)
	_peer_last_hero_positions.erase(peer_id)
	_peer_last_hero_pos_ms.erase(peer_id)
	_peer_damage_budget_tokens.erase(peer_id)
	_peer_damage_budget_last_ms.erase(peer_id)
	_peer_damage_accept_total.erase(peer_id)
	_peer_damage_reject_total.erase(peer_id)
	_peer_damage_reject_reason_counts.erase(peer_id)
	_peer_damage_breaker_window_start_ms.erase(peer_id)
	_peer_damage_breaker_reject_count.erase(peer_id)
	_peer_damage_breaker_blocked_until_ms.erase(peer_id)
	_peer_input_latency_ms.erase(peer_id)
	_peer_hero_selection_confirmed.erase(peer_id)
	_peer_latest_hero_command.erase(peer_id)
	var ui: GameUI = _get_game_ui()
	if ui != null:
		ui.authority_drop_peer_state(peer_id)
	if _ui_observed_peer_id == peer_id:
		_ui_observed_peer_id = 0
		_notify_game_ui_observe_peer(0)
	_status_event_hint = "peer_disconnected(id=%d)" % peer_id
	_refresh_status_text()


func _on_connected_to_server() -> void:
	_status_event_hint = "connected_to_server"
	_current_host_steam_id = _steam_lobby_owner_steam_id
	if _current_host_steam_id <= 0:
		_current_host_steam_id = _parse_steam_id_text(_resolve_target_steam_host_id("client"))
	_migration_pause_world_authority = false
	_send_elapsed_sec = maxf(send_interval_sec, 0.01)
	_client_initial_hero_state_sent = false
	_client_last_local_hero_instance_id = 0
	if _is_local_hero_selection_confirmed():
		notify_local_hero_selection_confirmed(true)
	_sync_local_lobby_member_data()
	if _host_migration_in_progress:
		_finalize_host_migration_after_start(false)
	_refresh_status_text()


func _on_connection_failed() -> void:
	if _host_migration_in_progress and _steam_lobby_id > 0:
		if _is_network_running:
			stop_network()
		_migration_pause_world_authority = true
		_host_migration_reconnect_ready_ms = (
			Time.get_ticks_msec()
			+ int(round(maxf(host_migration_reconnect_delay_sec, 0.25) * 1000.0))
		)
		_status_event_hint = "migration_connection_failed"
		_refresh_status_text()
		return
	if _is_network_running:
		stop_network()
	_status_event_hint = "connection_failed"
	_refresh_status_text()


func _on_server_disconnected() -> void:
	if (
		host_migration_enabled
		and _steam_lobby_id > 0
		and network_mode.strip_edges().to_lower() == "client"
		and not _steam_lobby_explicit_leave_in_progress
	):
		_migration_pause_world_authority = true
		if _is_network_running:
			stop_network()
		_begin_host_migration_wait("server_disconnected")
		return
	if _is_network_running:
		stop_network()
	_status_event_hint = "server_disconnected"
	_refresh_status_text()


@rpc("any_peer", "unreliable_ordered")
func rpc_submit_client_input(input_bundle: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_consume_client_input_from_sender(sender_id, input_bundle)


@rpc("any_peer", "reliable")
func rpc_submit_client_input_reliable(input_bundle: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_consume_client_input_from_sender(sender_id, input_bundle)


func _consume_client_input_from_sender(sender_id: int, input_bundle: Dictionary) -> void:
	var latest_frame: Dictionary = _extract_latest_input_frame(input_bundle, sender_id)
	if latest_frame.is_empty():
		return
	var allow_bootstrap_teleport: bool = _bool_from_variant(
		input_bundle.get("bootstrap_teleport", false), false
	)
	if not allow_bootstrap_teleport:
		allow_bootstrap_teleport = _bool_from_variant(
			latest_frame.get("bootstrap_teleport", false), false
		)
	var hero_variant: Variant = latest_frame.get("hero", {})
	if hero_variant is Dictionary:
		_apply_client_hero_state_from_sender(sender_id, hero_variant, allow_bootstrap_teleport)


@rpc("any_peer", "unreliable")
func rpc_client_ping(seq: int, client_sent_ms: int) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	rpc_id(sender_id, "rpc_client_pong", seq, client_sent_ms, Time.get_ticks_msec())


@rpc("authority", "call_remote", "unreliable")
func rpc_client_pong(seq: int, client_sent_ms: int, _host_recv_ms: int = 0) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	var now_ms: int = Time.get_ticks_msec()
	var sent_ms: int = _int_from_variant(
		_client_ping_sent_ms.get(seq, client_sent_ms), client_sent_ms
	)
	if sent_ms <= 0 or now_ms < sent_ms:
		return
	var rtt_ms: int = clampi(now_ms - sent_ms, 0, 60000)
	_client_last_rtt_ms = rtt_ms
	if _client_avg_rtt_ms < 0.0:
		_client_avg_rtt_ms = float(rtt_ms)
	else:
		_client_avg_rtt_ms = lerpf(_client_avg_rtt_ms, float(rtt_ms), 0.25)
	rpc_id(1, "rpc_report_client_rtt", rtt_ms)


@rpc("any_peer", "unreliable")
func rpc_report_client_rtt(rtt_ms: int) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_peer_input_latency_ms[sender_id] = clampi(rtt_ms, 0, 60000)


@rpc("any_peer", "reliable")
func rpc_submit_client_hero_command(command: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_consume_client_hero_command(sender_id, command)


@rpc("any_peer", "reliable")
func rpc_submit_client_skill_event(event: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_consume_client_skill_event(sender_id, event)


@rpc("any_peer", "reliable")
func rpc_submit_client_enemy_damage_request(event: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_consume_client_enemy_damage_request(sender_id, event)


@rpc("any_peer", "reliable")
func rpc_report_hero_selection_confirmed(confirmed: bool) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_peer_hero_selection_confirmed[sender_id] = bool(confirmed)


@rpc("any_peer", "reliable")
func rpc_submit_client_equipment_state(equipment_state: Dictionary, signature: String = "") -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_apply_client_equipment_state_from_sender(sender_id, equipment_state, signature)


@rpc("any_peer", "reliable")
func rpc_request_equipment_action(request: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	var commit: Dictionary = _process_equipment_action_request(sender_id, request)
	rpc_id(sender_id, "rpc_apply_equipment_commit_from_authority", commit)


@rpc("authority", "call_remote", "reliable")
func rpc_enemy_damage_result_from_authority(result: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller != null:
		hero_controller.on_authority_enemy_damage_confirmed(result)


@rpc("authority", "call_remote", "reliable")
func rpc_apply_equipment_commit_from_authority(commit: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	var ui: GameUI = _get_game_ui()
	if ui != null:
		ui.apply_authoritative_equipment_commit(commit)
	var state_variant: Variant = commit.get("state", null)
	if state_variant is Dictionary:
		var state: Dictionary = (state_variant as Dictionary).duplicate(true)
		_last_sent_equipment_signature = _build_state_signature(state)
		if multiplayer.multiplayer_peer != null:
			var self_id: int = multiplayer.get_unique_id()
			if self_id > 0:
				_peer_latest_equipment_state[self_id] = state
				_peer_latest_equipment_signatures[self_id] = _last_sent_equipment_signature


@rpc("authority", "unreliable_ordered")
func rpc_hero_snapshot(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	_apply_world_snapshot(snapshot)


@rpc("authority", "reliable")
func rpc_hero_snapshot_keyframe(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	_apply_world_snapshot(snapshot)


@rpc("authority", "unreliable_ordered")
func rpc_world_snapshot(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	_apply_world_snapshot(snapshot)


@rpc("authority", "unreliable_ordered")
func rpc_mob_motion_snapshot(entries: Array) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	if not sync_mob_state:
		return
	_apply_mob_motion_snapshot(entries)


@rpc("authority", "reliable")
func rpc_world_snapshot_keyframe(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	_apply_world_snapshot(snapshot)


@rpc("authority", "reliable")
func rpc_equipment_snapshot(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	_apply_equipment_snapshot(snapshot)


@rpc("authority", "call_remote", "reliable")
func rpc_apply_hero_damage_from_authority(
	amount: int, ignore_armor: bool = false, damage_type: String = "physical"
) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller != null:
		hero_controller.apply_damage(maxi(amount, 0), ignore_armor, null, damage_type)


@rpc("authority", "call_remote", "reliable")
func rpc_apply_hero_slow_from_authority(slow_percent: float, duration: float) -> void:
	if network_mode.strip_edges().to_lower() == "host":
		return
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller != null:
		hero_controller.apply_temporary_slow(slow_percent, duration)


func _build_world_snapshot(force_full_sync: bool = false) -> Dictionary:
	var all_mobs: Array = []
	var chunk_size: int = 1
	if sync_mob_state:
		all_mobs = _collect_mob_states()
		if not all_mobs.is_empty():
			chunk_size = _get_active_world_mob_chunk_size(all_mobs.size())
	if not force_full_sync and sync_mob_state and not all_mobs.is_empty():
		var hard_full_limit: int = maxi(force_full_mob_sync_below_count, 0)
		var soft_full_limit: int = maxi(world_full_sync_mob_threshold, hard_full_limit)
		var should_try_full_sync: bool = all_mobs.size() <= hard_full_limit
		if not should_try_full_sync and soft_full_limit > 0 and all_mobs.size() <= soft_full_limit:
			should_try_full_sync = true
		if should_try_full_sync:
			var full_result: Dictionary = _build_world_snapshot_result(all_mobs, chunk_size, true)
			var full_snapshot_variant: Variant = full_result.get("snapshot", {})
			if full_snapshot_variant is Dictionary:
				var full_snapshot: Dictionary = full_snapshot_variant
				if _can_preserve_full_mob_sync_for_snapshot(full_snapshot, all_mobs.size()):
					_host_world_snapshot_seq = int(
						full_result.get("next_world_seq", _host_world_snapshot_seq)
					)
					_world_mob_chunk_cursor = int(
						full_result.get("next_mob_chunk_cursor", _world_mob_chunk_cursor)
					)
					return full_snapshot
	var result: Dictionary = _build_world_snapshot_result(all_mobs, chunk_size, force_full_sync)
	_host_world_snapshot_seq = int(result.get("next_world_seq", _host_world_snapshot_seq))
	_world_mob_chunk_cursor = int(result.get("next_mob_chunk_cursor", _world_mob_chunk_cursor))
	return result.get("snapshot", {})


func _build_world_snapshot_result(
	all_mobs: Array, chunk_size: int, force_full_sync: bool
) -> Dictionary:
	return (
		_get_snapshot_serialization_service()
		. build_world_snapshot(
			{
				"current_world_seq": _host_world_snapshot_seq,
				"timestamp_ms": Time.get_ticks_msec(),
				"ack_input_seq": _peer_last_input_seq,
				"sync_boss_state": sync_boss_state,
				"boss_state": _collect_boss_state() if sync_boss_state else {},
				"sync_mob_state": sync_mob_state,
				"all_mobs": all_mobs,
				"force_full_sync": force_full_sync,
				"chunk_size": chunk_size,
				"current_mob_chunk_cursor": _world_mob_chunk_cursor,
				"sync_breakable_state": sync_breakable_state,
				"breakables": _collect_breakable_states() if sync_breakable_state else [],
			}
		)
	)


func _can_preserve_full_mob_sync_for_snapshot(snapshot: Dictionary, total_mobs: int) -> bool:
	if total_mobs <= 0:
		return true
	var trimmed_snapshot: Dictionary = _trim_unreliable_world_snapshot_to_mtu(
		snapshot, world_packet_budget_bytes
	)
	if _bool_from_variant(trimmed_snapshot.get("mobs_partial", false), false):
		return false
	var mobs_variant: Variant = trimmed_snapshot.get("mobs", [])
	if not (mobs_variant is Array):
		return false
	return (mobs_variant as Array).size() >= total_mobs


func _trim_unreliable_world_snapshot_to_mtu(
	snapshot: Dictionary, mtu_budget_bytes: int
) -> Dictionary:
	return _get_snapshot_serialization_service().trim_unreliable_world_snapshot_to_mtu(
		snapshot, mtu_budget_bytes
	)


func _build_hero_snapshot(include_equipment_state: bool = false) -> Dictionary:
	var host_peer_id: int = multiplayer.get_unique_id()
	var host_hero_state: Dictionary = {}
	if sync_hero_state:
		host_hero_state = _build_network_hero_state(_collect_local_hero_state())
		_consume_peer_hero_command_from_state(host_peer_id, host_hero_state)
	var result: Dictionary = (
		_get_snapshot_serialization_service()
		. build_hero_snapshot(
			{
				"current_hero_seq": _host_hero_snapshot_seq,
				"timestamp_ms": Time.get_ticks_msec(),
				"host_peer_id": host_peer_id,
				"ack_input_seq": _peer_last_input_seq,
				"sync_hero_state": sync_hero_state,
				"host_hero_state": host_hero_state,
				"include_equipment_state": include_equipment_state,
				"sync_equipment_state": sync_equipment_state,
				"host_equipment_state":
				_collect_local_equipment_state() if sync_equipment_state else {},
				"peer_latest_hero_state": _peer_latest_hero_state,
				"peer_latest_hero_command": _peer_latest_hero_command,
				"peer_latest_equipment_state": _peer_latest_equipment_state,
			}
		)
	)
	_host_hero_snapshot_seq = int(result.get("next_hero_seq", _host_hero_snapshot_seq))
	return result.get("snapshot", {})


func _build_equipment_snapshot() -> Dictionary:
	return (
		_get_snapshot_serialization_service()
		. build_equipment_snapshot(
			{
				"timestamp_ms": Time.get_ticks_msec(),
				"host_peer_id": multiplayer.get_unique_id(),
				"sync_equipment_state": sync_equipment_state,
				"host_equipment_state":
				_collect_local_equipment_state() if sync_equipment_state else {},
				"peer_latest_equipment_state": _peer_latest_equipment_state,
			}
		)
	)


func _build_network_hero_state(full_state: Dictionary) -> Dictionary:
	return _get_snapshot_serialization_service().build_network_hero_state(full_state)


func _build_client_input_hero_state(full_state: Dictionary) -> Dictionary:
	return _get_snapshot_serialization_service().build_client_input_hero_state(full_state)


func _build_network_boss_state(full_state: Dictionary) -> Dictionary:
	return _get_snapshot_serialization_service().build_network_boss_state(full_state)


func _build_network_mob_state(full_state: Dictionary) -> Dictionary:
	return _get_snapshot_serialization_service().build_network_mob_state(full_state)


func _filter_state_with_allowed_keys(
	full_state: Dictionary, allowed_keys: PackedStringArray
) -> Dictionary:
	return _get_snapshot_serialization_service().filter_state_with_allowed_keys(
		full_state, allowed_keys
	)


func _build_client_input_bundle(hero_state: Dictionary) -> Dictionary:
	var result: Dictionary = _get_snapshot_serialization_service().build_client_input_bundle(
		_client_input_seq, Time.get_ticks_msec(), hero_state, client_input_packet_budget_bytes
	)
	_client_input_seq = int(result.get("next_client_input_seq", _client_input_seq))
	var bundle: Dictionary = result.get("bundle", {})
	_client_recent_input_frames.clear()
	_client_recent_input_frames.append(bundle.duplicate(true))
	return bundle


func _trim_client_input_payload_for_budget(payload: Dictionary, packet_budget: int) -> Dictionary:
	return _get_snapshot_serialization_service().trim_client_input_payload_for_budget(
		payload, packet_budget
	)


func _send_latest_hero_command_if_needed(hero_state: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	var command_variant: Variant = hero_state.get("command_bus", null)
	if not (command_variant is Dictionary):
		return
	var command: Dictionary = command_variant
	var seq: int = _int_from_variant(command.get("seq", -1), -1)
	if seq <= _local_last_sent_hero_command_seq:
		return
	request_hero_control_command_from_client(command)


func _extract_latest_input_frame(input_bundle: Dictionary, sender_id: int) -> Dictionary:
	var last_seq: int = _int_from_variant(_peer_last_input_seq.get(sender_id, -1), -1)
	var best_seq: int = last_seq
	var best_frame: Dictionary = {}
	var frames_variant: Variant = input_bundle.get("frames", null)
	if frames_variant is Array:
		var frames: Array = frames_variant
		for frame_variant in frames:
			if not (frame_variant is Dictionary):
				continue
			var frame: Dictionary = frame_variant
			var seq: int = _int_from_variant(frame.get("seq", -1), -1)
			if seq > best_seq:
				best_seq = seq
				best_frame = frame
	if best_frame.is_empty():
		var direct_seq: int = _int_from_variant(input_bundle.get("seq", -1), -1)
		if direct_seq > best_seq:
			best_seq = direct_seq
			best_frame = input_bundle
	if best_seq <= last_seq:
		return {}
	_peer_last_input_seq[sender_id] = best_seq
	return best_frame


func _apply_client_hero_state_from_sender(
	sender_id: int, hero_state: Dictionary, allow_bootstrap_teleport: bool = false
) -> void:
	if sender_id <= 0:
		return
	if not sync_hero_state:
		return
	var sanitized_state: Dictionary = _sanitize_peer_hero_state(
		sender_id, hero_state, allow_bootstrap_teleport
	)
	if _peer_latest_hero_state.has(sender_id):
		var previous_state_variant: Variant = _peer_latest_hero_state[sender_id]
		if previous_state_variant is Dictionary:
			var previous_state: Dictionary = previous_state_variant as Dictionary
			if not sanitized_state.has("scale"):
				var previous_scale_variant: Variant = previous_state.get("scale", null)
				if previous_scale_variant is Vector3:
					sanitized_state["scale"] = previous_scale_variant
			if not sanitized_state.has("yaw") and previous_state.has("yaw"):
				sanitized_state["yaw"] = previous_state.get("yaw")
			if not sanitized_state.has("is_moving") and previous_state.has("is_moving"):
				sanitized_state["is_moving"] = previous_state.get("is_moving")
			if not sanitized_state.has("is_attacking") and previous_state.has("is_attacking"):
				sanitized_state["is_attacking"] = previous_state.get("is_attacking")
			if not sanitized_state.has("anim_name") and previous_state.has("anim_name"):
				sanitized_state["anim_name"] = previous_state.get("anim_name")
			if not sanitized_state.has("anim_playing") and previous_state.has("anim_playing"):
				sanitized_state["anim_playing"] = previous_state.get("anim_playing")
			if not sanitized_state.has("anim_speed") and previous_state.has("anim_speed"):
				sanitized_state["anim_speed"] = previous_state.get("anim_speed")
			# Client input packets can drop non-essential keys under MTU pressure.
			# Keep prior numeric stats so host-side observe UI does not fall back to 1/1.
			var sticky_stat_keys: PackedStringArray = PackedStringArray(
				[
					"hp",
					"max_hp",
					"mana",
					"max_mana",
					"damage",
					"armor",
					"move_speed",
					"attack_speed",
					"attack_interval",
					"attack_range",
					"cooldown_reduction_percent_total",
					"physical_crit_chance",
					"physical_crit_multiplier",
					"spell_crit_chance",
					"spell_crit_multiplier",
					"strength",
					"agility",
					"intelligence",
					"hp_regen_per_second",
					"mana_regen_per_second",
					"hero_id",
					"hero_profile",
					"hero_selected",
					"hp_bar_anchor_height",
					"collision_profile_id",
					"projectile_origin_pos"
				]
			)
			for key_variant in sticky_stat_keys:
				var key: String = String(key_variant)
				if sanitized_state.has(key):
					continue
				if previous_state.has(key):
					sanitized_state[key] = previous_state.get(key)
	_consume_peer_skill_event_from_state(sender_id, sanitized_state)
	_consume_peer_hero_command_from_state(sender_id, sanitized_state)
	_peer_latest_hero_state[sender_id] = sanitized_state
	_upsert_remote_avatar_from_state(sender_id, sanitized_state)


func _consume_client_skill_event(sender_id: int, event: Dictionary) -> void:
	if sender_id <= 0:
		return
	var sanitized: Dictionary = _sanitize_peer_skill_event(event)
	if sanitized.is_empty():
		return
	var event_seq: int = _int_from_variant(sanitized.get("seq", -1), -1)
	var last_seq: int = -1
	if _peer_latest_skill_event.has(sender_id):
		var last_variant: Variant = _peer_latest_skill_event[sender_id]
		if last_variant is Dictionary:
			last_seq = _int_from_variant((last_variant as Dictionary).get("seq", -1), -1)
	if event_seq <= last_seq:
		return
	_peer_latest_skill_event[sender_id] = sanitized.duplicate(true)
	if _peer_latest_hero_state.has(sender_id):
		var state_variant: Variant = _peer_latest_hero_state[sender_id]
		if state_variant is Dictionary:
			var state: Dictionary = (state_variant as Dictionary).duplicate(true)
			state["skill_event"] = sanitized.duplicate(true)
			_peer_latest_hero_state[sender_id] = state
			_upsert_remote_avatar_from_state(sender_id, state)


func _consume_client_hero_command(sender_id: int, command: Dictionary) -> void:
	if sender_id <= 0:
		return
	if command.is_empty():
		return
	var sanitized: Dictionary = _sanitize_peer_hero_command(command)
	if sanitized.is_empty():
		return
	var command_seq: int = _int_from_variant(sanitized.get("seq", -1), -1)
	var last_seq: int = _int_from_variant(_peer_last_hero_command_seq.get(sender_id, -1), -1)
	if command_seq <= last_seq:
		return
	_peer_last_hero_command_seq[sender_id] = command_seq
	_peer_latest_hero_command[sender_id] = sanitized
	if _peer_latest_hero_state.has(sender_id):
		var state_variant: Variant = _peer_latest_hero_state[sender_id]
		if state_variant is Dictionary:
			var state: Dictionary = (state_variant as Dictionary).duplicate(true)
			state["command_bus"] = sanitized.duplicate(true)
			_peer_latest_hero_state[sender_id] = state


func _consume_peer_skill_event_from_state(peer_id: int, hero_state: Dictionary) -> void:
	if peer_id <= 0:
		return
	var event_variant: Variant = hero_state.get("skill_event", null)
	if not (event_variant is Dictionary):
		if _peer_latest_skill_event.has(peer_id):
			var latest_event_variant: Variant = _peer_latest_skill_event[peer_id]
			if latest_event_variant is Dictionary:
				hero_state["skill_event"] = (latest_event_variant as Dictionary).duplicate(true)
		return
	var sanitized: Dictionary = _sanitize_peer_skill_event(event_variant as Dictionary)
	if sanitized.is_empty():
		if _peer_latest_skill_event.has(peer_id):
			var fallback_event_variant: Variant = _peer_latest_skill_event[peer_id]
			if fallback_event_variant is Dictionary:
				hero_state["skill_event"] = (fallback_event_variant as Dictionary).duplicate(true)
		else:
			hero_state.erase("skill_event")
		return
	var event_seq: int = _int_from_variant(sanitized.get("seq", -1), -1)
	var last_seq: int = -1
	if _peer_latest_skill_event.has(peer_id):
		var latest_event_variant: Variant = _peer_latest_skill_event[peer_id]
		if latest_event_variant is Dictionary:
			last_seq = _int_from_variant((latest_event_variant as Dictionary).get("seq", -1), -1)
	if event_seq > last_seq:
		_peer_latest_skill_event[peer_id] = sanitized.duplicate(true)
	if _peer_latest_skill_event.has(peer_id):
		var active_event_variant: Variant = _peer_latest_skill_event[peer_id]
		if active_event_variant is Dictionary:
			hero_state["skill_event"] = (active_event_variant as Dictionary).duplicate(true)


func _consume_peer_hero_command_from_state(peer_id: int, hero_state: Dictionary) -> void:
	if peer_id <= 0:
		return
	var command_variant: Variant = hero_state.get("command_bus", null)
	if not (command_variant is Dictionary):
		if _peer_latest_hero_command.has(peer_id):
			var latest_cmd_variant: Variant = _peer_latest_hero_command[peer_id]
			if latest_cmd_variant is Dictionary:
				hero_state["command_bus"] = (latest_cmd_variant as Dictionary).duplicate(true)
		return
	var sanitized: Dictionary = _sanitize_peer_hero_command(command_variant as Dictionary)
	if sanitized.is_empty():
		return
	var command_seq: int = _int_from_variant(sanitized.get("seq", -1), -1)
	var last_seq: int = _int_from_variant(_peer_last_hero_command_seq.get(peer_id, -1), -1)
	if command_seq > last_seq:
		_peer_last_hero_command_seq[peer_id] = command_seq
		_peer_latest_hero_command[peer_id] = sanitized.duplicate(true)
	if _peer_latest_hero_command.has(peer_id):
		var active_cmd_variant: Variant = _peer_latest_hero_command[peer_id]
		if active_cmd_variant is Dictionary:
			hero_state["command_bus"] = (active_cmd_variant as Dictionary).duplicate(true)


func _sanitize_peer_skill_event(event: Dictionary) -> Dictionary:
	if event.is_empty():
		return {}
	var sanitized: Dictionary = {}
	var seq: int = _int_from_variant(event.get("seq", -1), -1)
	if seq < 0:
		return {}
	var event_type: String = str(event.get("type", "")).strip_edges().to_lower()
	match event_type:
		"q", "w", "e", "r":
			pass
		_:
			return {}
	sanitized["seq"] = seq
	sanitized["type"] = event_type
	sanitized["skill_id"] = _int_from_variant(event.get("skill_id", 0), 0)
	sanitized["t_ms"] = _int_from_variant(
		event.get("t_ms", Time.get_ticks_msec()), Time.get_ticks_msec()
	)
	var pos_variant: Variant = event.get("pos", null)
	if pos_variant is Vector3:
		sanitized["pos"] = pos_variant
	var from_variant: Variant = event.get("from_pos", null)
	if from_variant is Vector3:
		sanitized["from_pos"] = from_variant
	var to_variant: Variant = event.get("to_pos", null)
	if to_variant is Vector3:
		sanitized["to_pos"] = to_variant
	var yaw_variant: Variant = event.get("yaw", null)
	if yaw_variant is float or yaw_variant is int:
		sanitized["yaw"] = float(yaw_variant)
	var radius_variant: Variant = event.get("radius", null)
	if radius_variant is float or radius_variant is int:
		sanitized["radius"] = float(radius_variant)
	var visual_scale_variant: Variant = event.get("visual_scale", null)
	if visual_scale_variant is float or visual_scale_variant is int:
		sanitized["visual_scale"] = float(visual_scale_variant)
	return sanitized


func _sanitize_peer_hero_command(command: Dictionary) -> Dictionary:
	if command.is_empty():
		return {}
	var sanitized: Dictionary = {}
	var seq: int = _int_from_variant(command.get("seq", -1), -1)
	if seq < 0:
		return {}
	var cmd_type: String = str(command.get("type", "idle")).strip_edges().to_lower()
	if cmd_type.is_empty():
		cmd_type = "idle"
	match cmd_type:
		"idle", "move_to", "chase_target", "attack_target", "cast_skill", "dead":
			pass
		_:
			cmd_type = "idle"
	sanitized["seq"] = seq
	sanitized["type"] = cmd_type
	sanitized["t_ms"] = _int_from_variant(
		command.get("t_ms", Time.get_ticks_msec()), Time.get_ticks_msec()
	)
	var target_path: String = str(command.get("target_path", "")).strip_edges()
	if not target_path.is_empty():
		sanitized["target_path"] = target_path
	var target_pos_variant: Variant = command.get("target_pos", null)
	if target_pos_variant is Vector3:
		sanitized["target_pos"] = target_pos_variant
	var skill_id: int = _int_from_variant(command.get("skill_id", -1), -1)
	if skill_id >= 0:
		sanitized["skill_id"] = skill_id
	return sanitized


func _sanitize_peer_hero_state(
	sender_id: int, hero_state: Dictionary, allow_bootstrap_teleport: bool = false
) -> Dictionary:
	var sanitized: Dictionary = hero_state.duplicate(true)
	var pos_variant: Variant = sanitized.get("pos", null)
	if not (pos_variant is Vector3):
		return sanitized
	var incoming_pos: Vector3 = pos_variant
	var now_ms: int = Time.get_ticks_msec()
	if _peer_last_hero_positions.has(sender_id):
		var prev_pos_variant: Variant = _peer_last_hero_positions[sender_id]
		if prev_pos_variant is Vector3:
			var prev_pos: Vector3 = prev_pos_variant
			var prev_ms: int = _int_from_variant(
				_peer_last_hero_pos_ms.get(sender_id, now_ms), now_ms
			)
			var dt_sec: float = clampf(float(now_ms - prev_ms) * 0.001, 0.0, 0.6)
			if dt_sec > 0.0:
				var move_speed: float = clampf(
					_float_from_variant(sanitized.get("move_speed", 320.0), 320.0), 80.0, 1400.0
				)
				var allowed_step: float = maxf(move_speed * dt_sec * 2.5 + 80.0, 40.0)
				var dist: float = prev_pos.distance_to(incoming_pos)
				if dist > allowed_step:
					var bootstrap_snap_threshold: float = maxf(
						host_large_displacement_snap_distance, 1.0
					)
					var can_use_bootstrap_teleport: bool = (
						allow_bootstrap_teleport and dist >= bootstrap_snap_threshold
					)
					if can_use_bootstrap_teleport:
						sanitized["pos"] = incoming_pos
					else:
						incoming_pos = prev_pos.move_toward(incoming_pos, allowed_step)
						sanitized["pos"] = incoming_pos
	_peer_last_hero_positions[sender_id] = incoming_pos
	_peer_last_hero_pos_ms[sender_id] = now_ms
	return sanitized


func _apply_client_equipment_state_from_sender(
	sender_id: int, equipment_state: Dictionary, signature: String = ""
) -> void:
	if sender_id <= 0:
		return
	if not sync_equipment_state:
		return
	var applied_state: Dictionary = equipment_state.duplicate(true)
	if network_mode.strip_edges().to_lower() == "host":
		var ui: GameUI = _get_game_ui()
		if ui != null:
			ui.authority_ensure_peer_equipment_state(sender_id, applied_state)
		if ui != null:
			var auth_state_variant: Variant = ui.call(
				"authority_get_peer_equipment_state", sender_id
			)
			if auth_state_variant is Dictionary:
				var auth_state: Dictionary = auth_state_variant
				if not auth_state.is_empty():
					applied_state = auth_state.duplicate(true)
	var state_signature: String = signature.strip_edges()
	if network_mode.strip_edges().to_lower() == "host" or state_signature.is_empty():
		state_signature = _build_state_signature(applied_state)
	var last_signature: String = str(_peer_latest_equipment_signatures.get(sender_id, ""))
	if state_signature == last_signature and _peer_latest_equipment_state.has(sender_id):
		return
	_peer_latest_equipment_state[sender_id] = applied_state
	_peer_latest_equipment_signatures[sender_id] = state_signature


func _reset_world_sync_adaptive_runtime() -> void:
	var result: Dictionary = _get_host_sync_flow_service().reset_world_sync_adaptive_runtime(
		world_sync_interval_sec,
		world_sync_interval_min_sec,
		world_sync_interval_max_sec,
		world_mob_chunk_size,
		world_mob_chunk_size_min,
		world_mob_chunk_size_max
	)
	_dynamic_world_sync_interval_sec = float(
		result.get("dynamic_world_sync_interval_sec", _dynamic_world_sync_interval_sec)
	)
	_dynamic_world_mob_chunk_size = int(
		result.get("dynamic_world_mob_chunk_size", _dynamic_world_mob_chunk_size)
	)
	_world_mob_chunk_cursor = int(result.get("world_mob_chunk_cursor", _world_mob_chunk_cursor))
	_last_world_packet_bytes = int(result.get("last_world_packet_bytes", _last_world_packet_bytes))


func _get_active_world_sync_interval_sec() -> float:
	return _get_host_sync_flow_service().get_active_world_sync_interval_sec(
		adaptive_world_sync_enabled,
		world_sync_interval_sec,
		_dynamic_world_sync_interval_sec,
		world_sync_interval_min_sec,
		world_sync_interval_max_sec
	)


func _get_active_world_mob_chunk_size(total_mobs: int) -> int:
	return _get_host_sync_flow_service().get_active_world_mob_chunk_size(
		total_mobs, adaptive_world_sync_enabled, world_mob_chunk_size, _dynamic_world_mob_chunk_size
	)


func _estimate_payload_bytes(payload: Variant) -> int:
	return _get_snapshot_serialization_service().estimate_payload_bytes(payload)


func _build_state_signature(payload: Variant) -> String:
	return _get_snapshot_serialization_service().build_state_signature(payload)


func _extract_mob_count_from_snapshot(snapshot: Dictionary) -> int:
	return _get_snapshot_serialization_service().extract_mob_count_from_snapshot(snapshot)


func _adjust_dynamic_world_sync_interval(snapshot: Dictionary, packet_bytes: int) -> void:
	var result: Dictionary = _get_host_sync_flow_service().adjust_dynamic_world_sync_interval(
		adaptive_world_sync_enabled,
		snapshot,
		packet_bytes,
		world_packet_budget_bytes,
		world_sync_interval_min_sec,
		world_sync_interval_max_sec,
		_dynamic_world_sync_interval_sec,
		world_sync_backoff_step_sec,
		world_sync_recover_step_sec,
		world_mob_chunk_size_min,
		world_mob_chunk_size_max,
		_dynamic_world_mob_chunk_size,
		Callable(self, "_extract_mob_count_from_snapshot")
	)
	_dynamic_world_sync_interval_sec = float(
		result.get("dynamic_world_sync_interval_sec", _dynamic_world_sync_interval_sec)
	)
	_dynamic_world_mob_chunk_size = int(
		result.get("dynamic_world_mob_chunk_size", _dynamic_world_mob_chunk_size)
	)


func _apply_world_snapshot(snapshot: Dictionary) -> void:
	var incoming_world_seq: int = _int_from_variant(snapshot.get("world_seq", -1), -1)
	if incoming_world_seq >= 0:
		if incoming_world_seq <= _last_applied_world_snapshot_seq:
			return
		_last_applied_world_snapshot_seq = incoming_world_seq
	_update_snapshot_latency_from_snapshot(snapshot)
	if snapshot.has("ack_input_seq"):
		_consume_ack_input_seq(snapshot["ack_input_seq"])
	var self_id: int = 0
	if multiplayer.multiplayer_peer != null:
		self_id = multiplayer.get_unique_id()

	var host_id: int = int(snapshot.get("host_peer_id", 1))
	var valid_remote_ids: Dictionary = {}
	var has_hero_payload: bool = false
	if sync_hero_state:
		if snapshot.has("host_hero"):
			has_hero_payload = true
		elif snapshot.has("peers"):
			has_hero_payload = true

	if has_hero_payload and snapshot.has("hero_seq"):
		var incoming_seq: int = _int_from_variant(snapshot.get("hero_seq", -1), -1)
		if incoming_seq >= 0:
			if incoming_seq <= _last_applied_hero_snapshot_seq:
				return
			_last_applied_hero_snapshot_seq = incoming_seq

	if sync_hero_state and snapshot.has("host_hero"):
		var host_hero_variant: Variant = snapshot["host_hero"]
		if host_hero_variant is Dictionary:
			var host_hero: Dictionary = (host_hero_variant as Dictionary).duplicate(true)
			_consume_peer_hero_command_from_state(host_id, host_hero)
			_peer_latest_hero_state[host_id] = host_hero
			if host_id != self_id:
				_upsert_remote_avatar_from_state(host_id, host_hero)
				valid_remote_ids[host_id] = true

	if sync_equipment_state and snapshot.has("host_equipment"):
		var host_eq_variant: Variant = snapshot["host_equipment"]
		if host_eq_variant is Dictionary:
			_peer_latest_equipment_state[host_id] = host_eq_variant

	var peers_variant: Variant = null
	if snapshot.has("peers"):
		peers_variant = snapshot["peers"]
	if peers_variant is Dictionary:
		var peers_payload: Dictionary = peers_variant
		for key_variant in peers_payload.keys():
			var peer_id: int = int(str(key_variant))
			var payload_variant: Variant = peers_payload[key_variant]
			if not (payload_variant is Dictionary):
				continue
			var payload: Dictionary = payload_variant
			if sync_hero_state and payload.has("hero"):
				var hero_variant: Variant = payload["hero"]
				if hero_variant is Dictionary:
					var hero_state: Dictionary = (hero_variant as Dictionary).duplicate(true)
					_consume_peer_hero_command_from_state(peer_id, hero_state)
					_peer_latest_hero_state[peer_id] = hero_state
					if peer_id != self_id:
						_upsert_remote_avatar_from_state(peer_id, hero_state)
						valid_remote_ids[peer_id] = true
			if sync_equipment_state and payload.has("equipment"):
				var eq_variant: Variant = payload["equipment"]
				if eq_variant is Dictionary:
					_peer_latest_equipment_state[peer_id] = eq_variant

	if sync_boss_state and snapshot.has("boss"):
		var boss_variant: Variant = snapshot["boss"]
		if boss_variant is Dictionary:
			_apply_boss_state(boss_variant)

	if sync_mob_state and snapshot.has("mobs"):
		var mobs_variant: Variant = snapshot["mobs"]
		if mobs_variant is Array:
			var mobs_partial: bool = _bool_from_variant(snapshot.get("mobs_partial", false), false)
			_apply_mob_states(mobs_variant, mobs_partial)
	if sync_breakable_state and snapshot.has("breakables"):
		var breakables_variant: Variant = snapshot["breakables"]
		if breakables_variant is Array:
			_apply_breakable_states(breakables_variant)

	if has_hero_payload:
		_remove_absent_remote_avatars(valid_remote_ids)
	_refresh_status_text()


func _apply_equipment_snapshot(snapshot: Dictionary) -> void:
	if not sync_equipment_state:
		return
	var host_id: int = int(snapshot.get("host_peer_id", 1))
	var host_eq_variant: Variant = snapshot.get("host_equipment", null)
	if host_eq_variant is Dictionary:
		_peer_latest_equipment_state[host_id] = (host_eq_variant as Dictionary).duplicate(true)
	var peers_variant: Variant = snapshot.get("peers", null)
	if peers_variant is Dictionary:
		var peers_payload: Dictionary = peers_variant
		for key_variant in peers_payload.keys():
			var peer_id: int = int(str(key_variant))
			var payload_variant: Variant = peers_payload[key_variant]
			if not (payload_variant is Dictionary):
				continue
			var payload: Dictionary = payload_variant
			var eq_variant: Variant = payload.get("equipment", null)
			if eq_variant is Dictionary:
				_peer_latest_equipment_state[peer_id] = (eq_variant as Dictionary).duplicate(true)
	_refresh_status_text()


func _update_snapshot_latency_from_snapshot(snapshot: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	var sent_ms: int = _int_from_variant(snapshot.get("timestamp_ms", -1), -1)
	if sent_ms <= 0:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < sent_ms:
		return
	var latency_ms: int = clampi(now_ms - sent_ms, 0, 60000)
	_last_snapshot_latency_ms = latency_ms
	if _avg_snapshot_latency_ms < 0.0:
		_avg_snapshot_latency_ms = float(latency_ms)
	else:
		_avg_snapshot_latency_ms = lerpf(_avg_snapshot_latency_ms, float(latency_ms), 0.25)


func _consume_ack_input_seq(ack_variant: Variant) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	if not (ack_variant is Dictionary):
		return
	if multiplayer.multiplayer_peer == null:
		return
	var self_id: int = multiplayer.get_unique_id()
	if self_id <= 0:
		return
	var ack_map: Dictionary = ack_variant
	var ack_seq: int = -1
	if ack_map.has(self_id):
		ack_seq = _int_from_variant(ack_map[self_id], -1)
	elif ack_map.has(str(self_id)):
		ack_seq = _int_from_variant(ack_map[str(self_id)], -1)
	if ack_seq <= _last_ack_input_seq_from_host:
		return
	_last_ack_input_seq_from_host = ack_seq
	if (
		_client_initial_hero_state_ack_required_seq >= 0
		and ack_seq >= _client_initial_hero_state_ack_required_seq
	):
		_client_initial_hero_state_ack_required_seq = -1
	_trim_acked_client_inputs(ack_seq)


func _trim_acked_client_inputs(ack_seq: int) -> void:
	if _client_recent_input_frames.is_empty():
		return
	var pending_frames: Array = []
	for frame_variant in _client_recent_input_frames:
		if not (frame_variant is Dictionary):
			continue
		var frame: Dictionary = frame_variant
		var frame_seq: int = _int_from_variant(frame.get("seq", -1), -1)
		if frame_seq > ack_seq:
			pending_frames.append(frame)
	_client_recent_input_frames = pending_frames


func _collect_local_hero_state() -> Dictionary:
	var hero: Node3D = _get_local_hero()
	if hero == null:
		return {}
	var hero_controller: HeroController = _get_hero_controller()
	var state: Dictionary = _get_network_state_collection_service().collect_local_hero_base_state(
		hero,
		hero_controller,
		Callable(self, "_int_from_variant"),
		Callable(self, "_float_from_variant"),
		Callable(self, "_bool_from_variant"),
		Callable(self, "_sanitize_peer_hero_command")
	)
	var has_explicit_skill_event: bool = false
	if hero_controller != null:
		var explicit_event_variant: Variant = hero_controller.get("_network_last_skill_event")
		if explicit_event_variant is Dictionary:
			var explicit_event: Dictionary = explicit_event_variant
			var explicit_seq: int = _int_from_variant(explicit_event.get("seq", -1), -1)
			if explicit_seq >= 0:
				has_explicit_skill_event = true
				if explicit_seq > _local_prev_explicit_skill_event_seq:
					_local_prev_explicit_skill_event_seq = explicit_seq
					_local_last_skill_event = explicit_event.duplicate(true)
	if not has_explicit_skill_event:
		_update_local_skill_event_from_state(state)
	if not _local_last_skill_event.is_empty():
		state["skill_event"] = _local_last_skill_event.duplicate(true)
	return state


func _refresh_client_local_hero_bootstrap_state() -> void:
	var hero: Node3D = _get_local_hero()
	var hero_instance_id: int = 0
	if hero != null and is_instance_valid(hero):
		hero_instance_id = hero.get_instance_id()
	if hero_instance_id != _client_last_local_hero_instance_id:
		_client_last_local_hero_instance_id = hero_instance_id
		_client_initial_hero_state_sent = false
		_client_initial_hero_state_ack_required_seq = -1
		_client_initial_hero_state_resend_elapsed_sec = 0.0


func _try_send_initial_client_hero_state(hero_state_full: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	if hero_state_full.is_empty():
		return
	var pos_variant: Variant = hero_state_full.get("pos", null)
	if not (pos_variant is Vector3):
		return
	if multiplayer.multiplayer_peer == null or multiplayer.get_peers().is_empty():
		return
	var ack_pending: bool = (
		_client_initial_hero_state_ack_required_seq >= 0
		and _last_ack_input_seq_from_host < _client_initial_hero_state_ack_required_seq
	)
	var should_send: bool = false
	if not _client_initial_hero_state_sent:
		should_send = true
	elif ack_pending:
		var resend_interval: float = maxf(client_initial_hero_state_resend_interval_sec, 0.05)
		should_send = _client_initial_hero_state_resend_elapsed_sec >= resend_interval
	if not should_send:
		return
	var hero_state: Dictionary = _build_client_input_hero_state(hero_state_full)
	var event_filter: Dictionary = _get_client_sync_flow_service().filter_skill_event_for_send(
		hero_state, _client_last_sent_skill_event_seq
	)
	hero_state = event_filter.get("hero_state", hero_state)
	_client_last_sent_skill_event_seq = int(
		event_filter.get("next_last_sent_skill_event_seq", _client_last_sent_skill_event_seq)
	)
	var input_bundle: Dictionary = _build_client_input_bundle(hero_state)
	input_bundle["bootstrap_teleport"] = true
	rpc_id(1, "rpc_submit_client_input_reliable", input_bundle)
	var sent_seq: int = _int_from_variant(input_bundle.get("seq", -1), -1)
	if sent_seq >= 0:
		_client_initial_hero_state_ack_required_seq = sent_seq
	_client_initial_hero_state_sent = true
	_client_initial_hero_state_resend_elapsed_sec = 0.0
	_send_elapsed_sec = 0.0


func notify_local_hero_ready() -> void:
	_client_initial_hero_state_sent = false
	_client_last_local_hero_instance_id = 0
	_client_initial_hero_state_ack_required_seq = -1
	_client_initial_hero_state_resend_elapsed_sec = 0.0
	if network_mode.strip_edges().to_lower() != "client":
		return
	if not _is_network_running:
		return
	if multiplayer.multiplayer_peer == null or multiplayer.get_peers().is_empty():
		return
	var hero_state_full: Dictionary = _collect_local_hero_state()
	if hero_state_full.is_empty():
		return
	_refresh_client_local_hero_bootstrap_state()
	_try_send_initial_client_hero_state(hero_state_full)


func _collect_local_equipment_state() -> Dictionary:
	return _get_network_state_collection_service().collect_local_equipment_state(
		_get_hero_controller(), _get_game_ui(), Callable(self, "_int_from_variant")
	)


func _extract_inventory_from_hero_controller(hero_controller: Node) -> Array:
	return _get_network_state_collection_service().extract_inventory_from_hero_controller(
		hero_controller
	)


func _extract_int_array(values_variant: Variant) -> Array:
	return _get_network_state_collection_service().extract_int_array(values_variant)


func _collect_boss_state() -> Dictionary:
	return _get_network_state_collection_service().collect_boss_state(
		_get_boss_controller(),
		Callable(self, "_build_network_boss_state"),
		Callable(self, "_int_from_variant"),
		Callable(self, "_float_from_variant"),
		Callable(self, "_bool_from_variant")
	)


func _apply_boss_state(state: Dictionary) -> void:
	var boss_controller: EnemyAI = _get_boss_controller()
	if boss_controller == null:
		return
	boss_controller.apply_network_state(state)


func _collect_mob_states() -> Array:
	var states: Array = []
	states.append_array(_collect_mob_states_from_node(_get_tauren_spawner()))
	states.append_array(_collect_mob_states_from_node(_get_summon_manager()))
	return states


func _build_mob_motion_snapshot() -> Array:
	var entries: Array = []
	for state_variant in _collect_mob_states():
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant as Dictionary
		var mob_id: String = str(state.get("id", "")).strip_edges()
		var pos_variant: Variant = state.get("pos", null)
		if mob_id.is_empty() or not (pos_variant is Vector3):
			continue
		var flags: int = 0
		if _bool_from_variant(state.get("visible", true), true):
			flags |= MOB_MOTION_FLAG_VISIBLE
		if _bool_from_variant(state.get("dead", false), false):
			flags |= MOB_MOTION_FLAG_DEAD
		if _bool_from_variant(state.get("is_moving", false), false):
			flags |= MOB_MOTION_FLAG_MOVING
		if _bool_from_variant(state.get("is_attacking", false), false):
			flags |= MOB_MOTION_FLAG_ATTACKING
		var entry: Array = [
			mob_id,
			pos_variant,
			_float_from_variant(state.get("yaw", 0.0), 0.0),
			flags,
		]
		var summon_kind: String = str(state.get("summon_kind", "")).strip_edges()
		if not summon_kind.is_empty():
			entry.append(summon_kind)
		entries.append(entry)
	return entries


func _send_mob_motion_snapshots() -> void:
	var entries: Array = _build_mob_motion_snapshot()
	if entries.is_empty():
		return
	var safe_budget: int = clampi(world_packet_budget_bytes - 220, 480, 1100)
	var chunk: Array = []
	for entry_variant in entries:
		var candidate_chunk: Array = chunk.duplicate(true)
		candidate_chunk.append(entry_variant)
		if not chunk.is_empty() and _estimate_payload_bytes(candidate_chunk) > safe_budget:
			rpc("rpc_mob_motion_snapshot", chunk)
			chunk = [entry_variant]
			continue
		chunk = candidate_chunk
	if not chunk.is_empty():
		rpc("rpc_mob_motion_snapshot", chunk)


func _apply_mob_motion_snapshot(entries: Array) -> void:
	var states: Array = []
	for entry_variant in entries:
		if not (entry_variant is Array):
			continue
		var entry: Array = entry_variant as Array
		if entry.size() < 4:
			continue
		var mob_id: String = str(entry[0]).strip_edges()
		var pos_variant: Variant = entry[1]
		if mob_id.is_empty() or not (pos_variant is Vector3):
			continue
		var flags: int = _int_from_variant(entry[3], 0)
		var state: Dictionary = {
			"id": mob_id,
			"pos": pos_variant,
			"yaw": _float_from_variant(entry[2], 0.0),
			"visible": (flags & MOB_MOTION_FLAG_VISIBLE) != 0,
			"dead": (flags & MOB_MOTION_FLAG_DEAD) != 0,
			"is_moving": (flags & MOB_MOTION_FLAG_MOVING) != 0,
			"is_attacking": (flags & MOB_MOTION_FLAG_ATTACKING) != 0,
		}
		if entry.size() >= 5:
			var summon_kind: String = str(entry[4]).strip_edges()
			if not summon_kind.is_empty():
				state["summon_kind"] = summon_kind
		states.append(state)
	if states.is_empty():
		return
	_apply_mob_states(states, true)


func _apply_mob_states(states: Array, is_partial: bool = false) -> void:
	var spawner_states: Array = []
	var summon_states: Array = []
	for state_variant in states:
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant as Dictionary
		var summon_kind: String = str(state.get("summon_kind", "")).strip_edges()
		if summon_kind.is_empty():
			spawner_states.append(state)
		else:
			summon_states.append(state)
	_apply_mob_states_to_node(_get_tauren_spawner(), spawner_states, is_partial)
	_apply_mob_states_to_node(_get_summon_manager(), summon_states, is_partial)


func _collect_mob_states_from_node(node: Node) -> Array:
	return _get_network_state_collection_service().collect_mob_states_from_node(
		node, Callable(self, "_build_network_mob_state")
	)


func _apply_mob_states_to_node(node: Node, states: Array, is_partial: bool = false) -> void:
	if node == null:
		return
	# ponytail: node 是 TaurenSpawner 或 SummonedUnitManager，二型多态，保留动态探测
	if not node.has_method("apply_network_states"):
		return
	node.call("apply_network_states", states, is_partial)


func _collect_breakable_states() -> Array:
	return _get_network_state_collection_service().collect_breakable_states(
		get_tree(),
		breakable_group_name,
		Callable(self, "_object_has_property"),
		Callable(self, "_int_from_variant")
	)


func _apply_breakable_states(states: Array) -> void:
	var scene_tree: SceneTree = get_tree()
	if scene_tree == null:
		return
	var nodes_by_id: Dictionary = {}
	var breakables: Array = scene_tree.get_nodes_in_group(breakable_group_name)
	for node_variant in breakables:
		var breakable_node: Node = node_variant as Node
		if breakable_node == null:
			continue
		nodes_by_id[str(breakable_node.get_path())] = breakable_node
	for state_variant in states:
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var breakable_id: String = str(state.get("id", "")).strip_edges()
		if breakable_id.is_empty():
			continue
		if not nodes_by_id.has(breakable_id):
			continue
		var target_node: Node = nodes_by_id[breakable_id] as Node
		if target_node == null:
			continue
		if target_node.has_method("apply_network_state"):
			target_node.call("apply_network_state", state)
			continue
		_apply_breakable_fallback_state(target_node, state)


func _build_breakable_fallback_state(node: Node) -> Dictionary:
	return _get_network_state_collection_service().build_breakable_fallback_state(
		node, Callable(self, "_object_has_property"), Callable(self, "_int_from_variant")
	)


func _apply_breakable_fallback_state(node: Node, state: Dictionary) -> void:
	if node == null:
		return
	if state.has("max_hp") and _object_has_property(node, "max_hp"):
		node.set("max_hp", maxi(int(state["max_hp"]), 1))
	if state.has("hp") and _object_has_property(node, "current_hp"):
		var max_hp_value: int = 1
		if _object_has_property(node, "max_hp"):
			max_hp_value = maxi(_int_from_variant(node.get("max_hp"), 1), 1)
		node.set("current_hp", clampi(int(state["hp"]), 0, max_hp_value))
	if state.has("dead"):
		var is_dead: bool = _bool_from_variant(state["dead"], false)
		if is_dead:
			if node.has_method("_die"):
				node.call("_die")
			elif node is Node3D:
				(node as Node3D).visible = false
		elif state.has("visible") and node is Node3D:
			(node as Node3D).visible = _bool_from_variant(state["visible"], true)
	elif state.has("visible") and node is Node3D:
		(node as Node3D).visible = _bool_from_variant(state["visible"], true)


func _consume_client_enemy_damage_request(sender_id: int, event: Dictionary) -> void:
	if sender_id <= 0:
		return
	var event_seq: int = _int_from_variant(event.get("seq", -1), -1)
	var source_text_raw: String = str(event.get("source", "attack")).strip_edges().to_lower()
	if _is_damage_request_breaker_blocked(sender_id):
		_record_damage_request_reject(sender_id, "breaker_blocked")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "breaker_blocked")
		return
	if event.is_empty():
		_record_damage_request_reject(sender_id, "empty_event")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "empty_event")
		return
	if event_seq >= 0:
		var last_seq: int = _int_from_variant(_peer_last_damage_request_seq.get(sender_id, -1), -1)
		if event_seq <= last_seq:
			_record_damage_request_reject(sender_id, "seq_replay")
			_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "seq_replay")
			return
		_peer_last_damage_request_seq[sender_id] = event_seq
	var target_path: String = str(event.get("target_path", "")).strip_edges()
	if target_path.is_empty():
		_record_damage_request_reject(sender_id, "missing_target_path")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "missing_target_path"
		)
		return
	var target_node: Node = get_node_or_null(NodePath(target_path))
	if target_node == null:
		_record_damage_request_reject(sender_id, "target_node_missing")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "target_node_missing"
		)
		return
	var enemy_controller: Node = _resolve_enemy_damage_controller(target_node)
	if enemy_controller == null:
		_record_damage_request_reject(sender_id, "target_not_authorized")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "target_not_authorized"
		)
		return
	var target_pos: Vector3 = _resolve_enemy_damage_target_position(target_node, enemy_controller)
	var max_range: float = _float_from_variant(event.get("max_range", -1.0), -1.0)
	var context: Dictionary = {}
	var context_variant: Variant = event.get("context", {})
	if context_variant is Dictionary:
		context = context_variant as Dictionary
	var requested_damage: int = _int_from_variant(event.get("amount", 0), 0)
	if requested_damage <= 0:
		_record_damage_request_reject(sender_id, "invalid_damage")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "invalid_damage")
		return
	if enemy_controller.is_in_group(breakable_group_name):
		if not is_gate_damage_enabled():
			_record_damage_request_reject(sender_id, "gate_locked")
			_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "gate_locked")
			return
		if enemy_controller.has_method("is_dead") and bool(enemy_controller.call("is_dead")):
			_record_damage_request_reject(sender_id, "target_dead")
			_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "target_dead")
			return
		# 门是静态可破坏物，不需要套用怪物的远端化身/几何严格校验，避免客户端在同步抖动时被误拒。
		var safe_gate_damage: int = clampi(requested_damage, 1, 200000)
		enemy_controller.call("apply_damage", safe_gate_damage, null, "basic_attack")
		_record_damage_request_accept(sender_id)
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, true)
		return
	var hero_state: Dictionary = {}
	var hero_state_variant: Variant = _peer_latest_hero_state.get(sender_id, {})
	if hero_state_variant is Dictionary:
		hero_state = hero_state_variant
	if hero_state.is_empty():
		_record_damage_request_reject(sender_id, "hero_state_missing")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "hero_state_missing"
		)
		return
	var attacker_avatar: Node3D = _get_remote_avatar_for_peer(sender_id)
	var attacker_position: Vector3 = Vector3.ZERO
	var has_attacker_position: bool = false
	var hero_pos_variant: Variant = hero_state.get("pos", null)
	if hero_pos_variant is Vector3:
		attacker_position = hero_pos_variant
		has_attacker_position = true
	elif attacker_avatar != null and is_instance_valid(attacker_avatar):
		attacker_position = attacker_avatar.global_position
		has_attacker_position = true
	if not has_attacker_position:
		_record_damage_request_reject(sender_id, "attacker_avatar_missing")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "attacker_avatar_missing"
		)
		return
	if enemy_controller.is_in_group(breakable_group_name) and not is_gate_damage_enabled():
		_record_damage_request_reject(sender_id, "gate_locked")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "gate_locked")
		return
	var source_kind: String = _normalize_damage_source(source_text_raw)
	if not _consume_damage_request_budget(sender_id, source_kind):
		_record_damage_request_reject(sender_id, "budget_exceeded")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "budget_exceeded")
		return
	var attack_range: float = clampf(
		_float_from_variant(hero_state.get("attack_range", 220.0), 220.0), 80.0, 2200.0
	)
	var q_ray_length: float = clampf(
		_float_from_variant(hero_state.get("ranged_q_ray_length", 1200.0), 1200.0), 120.0, 5200.0
	)
	var flash_origin_radius: float = clampf(
		_float_from_variant(hero_state.get("flash_origin_damage_radius", 420.0), 420.0),
		40.0,
		2200.0
	)
	var flash_destination_radius: float = clampf(
		_float_from_variant(hero_state.get("flash_destination_damage_radius", 320.0), 320.0),
		40.0,
		2200.0
	)
	var flash_radius: float = maxf(flash_origin_radius, flash_destination_radius)
	var r_cluster_radius: float = clampf(
		_float_from_variant(hero_state.get("ranged_r_radius", 250.0), 250.0), 1.0, 800.0
	)
	var r_cluster_cast_range: float = clampf(
		_float_from_variant(hero_state.get("ranged_r_cast_max_distance", 3000.0), 3000.0),
		80.0,
		3200.0
	)
	if not _consume_damage_request_interval(
		sender_id, source_text_raw, source_kind, target_path, hero_state
	):
		_record_damage_request_reject(sender_id, "interval_limited")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "interval_limited"
		)
		return
	var allowed_dist: float = attack_range + 260.0
	match source_kind:
		"basic_attack":
			allowed_dist = attack_range + 120.0
		"attack_effect":
			allowed_dist = attack_range + 320.0
		"poison":
			allowed_dist = attack_range + 420.0
		"q_ray":
			allowed_dist = q_ray_length + 200.0
		"flash":
			allowed_dist = flash_radius + 180.0
		"r_cluster":
			allowed_dist = r_cluster_cast_range + r_cluster_radius + 220.0
		_:
			allowed_dist = attack_range + 260.0
	if max_range > 0.0:
		allowed_dist = minf(allowed_dist, clampf(max_range, 1.0, 2600.0) + 120.0)
	if attacker_position.distance_to(target_pos) > allowed_dist:
		_record_damage_request_reject(sender_id, "distance_exceeded")
		_reply_enemy_damage_request_result_to_client(
			sender_id, event_seq, false, "distance_exceeded"
		)
		return
	var requires_avatar_geometry: bool = (
		source_kind == "q_ray" or source_kind == "flash" or source_kind == "r_cluster"
	)
	if requires_avatar_geometry:
		if attacker_avatar == null or not is_instance_valid(attacker_avatar):
			_record_damage_request_reject(sender_id, "attacker_avatar_missing")
			_reply_enemy_damage_request_result_to_client(
				sender_id, event_seq, false, "attacker_avatar_missing"
			)
			return
		if not _validate_enemy_damage_geometry(source_kind, attacker_avatar, target_pos, context):
			_record_damage_request_reject(sender_id, "geometry_invalid")
			_reply_enemy_damage_request_result_to_client(
				sender_id, event_seq, false, "geometry_invalid"
			)
			return
	var base_damage: int = _int_from_variant(hero_state.get("damage", 0), 0)
	var physical_crit_multiplier: float = clampf(
		_float_from_variant(hero_state.get("physical_crit_multiplier", 2.0), 2.0), 1.0, 6.0
	)
	var spell_crit_multiplier: float = clampf(
		_float_from_variant(hero_state.get("spell_crit_multiplier", 2.0), 2.0), 1.0, 6.0
	)
	var source_base_damage: int = maxi(base_damage, 1)
	var damage_cap_multiplier: float = 6.0
	var min_cap_floor: int = 120
	match source_kind:
		"basic_attack":
			source_base_damage = maxi(base_damage, 1)
			damage_cap_multiplier = maxf(physical_crit_multiplier + 0.8, 2.2)
			min_cap_floor = 100
		"attack_effect":
			var max_hp_for_cap: int = maxi(_int_from_variant(hero_state.get("max_hp", 0), 0), 1)
			var mana_for_cap: int = maxi(_int_from_variant(hero_state.get("mana", 0), 0), 0)
			source_base_damage = maxi(base_damage, 1)
			source_base_damage = maxi(source_base_damage, int(round(float(max_hp_for_cap) * 0.04)))
			source_base_damage = maxi(source_base_damage, int(round(float(mana_for_cap) * 0.04)))
			damage_cap_multiplier = maxf(spell_crit_multiplier + 6.0, 10.0)
			min_cap_floor = 320
		"poison":
			source_base_damage = maxi(
				_int_from_variant(
					hero_state.get("poison_damage_per_second", base_damage), base_damage
				),
				1
			)
			damage_cap_multiplier = maxf(spell_crit_multiplier + 1.2, 2.8)
			min_cap_floor = 120
		"q_ray":
			source_base_damage = maxi(
				_int_from_variant(hero_state.get("ranged_q_ray_damage", base_damage), base_damage),
				1
			)
			damage_cap_multiplier = maxf(spell_crit_multiplier + 2.0, 3.8)
			min_cap_floor = 260
		"flash":
			source_base_damage = maxi(
				_int_from_variant(hero_state.get("flash_damage", base_damage), base_damage), 1
			)
			damage_cap_multiplier = maxf(spell_crit_multiplier + 2.0, 3.8)
			min_cap_floor = 260
		"r_cluster":
			source_base_damage = maxi(
				_int_from_variant(hero_state.get("ranged_r_damage", base_damage), base_damage), 1
			)
			damage_cap_multiplier = maxf(spell_crit_multiplier + 1.6, 3.2)
			min_cap_floor = 400
		_:
			source_base_damage = maxi(base_damage, 1)
			damage_cap_multiplier = 6.0
			min_cap_floor = 120
	var max_allowed_damage: int = maxi(
		int(round(float(source_base_damage) * damage_cap_multiplier)), min_cap_floor
	)
	var safe_damage: int = clampi(requested_damage, 1, max_allowed_damage)
	if enemy_controller.has_method("is_dead") and bool(enemy_controller.call("is_dead")):
		_record_damage_request_reject(sender_id, "target_dead")
		_reply_enemy_damage_request_result_to_client(sender_id, event_seq, false, "target_dead")
		return
	enemy_controller.call("apply_damage", safe_damage, attacker_avatar, source_kind, context)
	if source_kind == "q_ray" or source_kind == "precision_attack":
		_apply_enemy_knockback_from_context(enemy_controller, context)
	_record_damage_request_accept(sender_id)
	_reply_enemy_damage_request_result_to_client(sender_id, event_seq, true)


func _reply_enemy_damage_request_result_to_client(
	sender_id: int, event_seq: int, accepted: bool, reason: String = ""
) -> void:
	if sender_id <= 0 or event_seq < 0:
		return
	var result: Dictionary = {
		"request_seq": event_seq,
		"accepted": accepted,
	}
	if not reason.is_empty():
		result["reason"] = reason
	rpc_id(sender_id, "rpc_enemy_damage_result_from_authority", result)


func _record_damage_request_accept(sender_id: int) -> void:
	if sender_id <= 0:
		return
	var count: int = _int_from_variant(_peer_damage_accept_total.get(sender_id, 0), 0) + 1
	_peer_damage_accept_total[sender_id] = count


func _record_damage_request_reject(sender_id: int, reason: String) -> void:
	if sender_id <= 0:
		return
	var reason_key: String = reason.strip_edges().to_lower()
	if reason_key.is_empty():
		reason_key = "unknown"
	var total_count: int = _int_from_variant(_peer_damage_reject_total.get(sender_id, 0), 0) + 1
	_peer_damage_reject_total[sender_id] = total_count
	var reason_counts_variant: Variant = _peer_damage_reject_reason_counts.get(sender_id, {})
	var reason_counts: Dictionary = {}
	if reason_counts_variant is Dictionary:
		reason_counts = (reason_counts_variant as Dictionary).duplicate(true)
	var reason_count: int = _int_from_variant(reason_counts.get(reason_key, 0), 0) + 1
	reason_counts[reason_key] = reason_count
	_peer_damage_reject_reason_counts[sender_id] = reason_counts
	_update_damage_request_breaker_on_reject(sender_id, reason_key)


func _is_damage_request_breaker_blocked(sender_id: int) -> bool:
	if sender_id <= 0:
		return false
	var now_ms: int = Time.get_ticks_msec()
	var blocked_until_ms: int = _int_from_variant(
		_peer_damage_breaker_blocked_until_ms.get(sender_id, 0), 0
	)
	if blocked_until_ms <= 0:
		return false
	if blocked_until_ms <= now_ms:
		_peer_damage_breaker_blocked_until_ms.erase(sender_id)
		return false
	return true


func _update_damage_request_breaker_on_reject(sender_id: int, reason_key: String) -> void:
	if sender_id <= 0:
		return
	if not _is_breaker_counted_reject_reason(reason_key):
		return
	var threshold: int = maxi(damage_request_breaker_reject_threshold, 0)
	if threshold <= 0:
		return
	var window_ms: int = int(round(clampf(damage_request_breaker_window_sec, 1.0, 120.0) * 1000.0))
	var now_ms: int = Time.get_ticks_msec()
	var window_start_ms: int = _int_from_variant(
		_peer_damage_breaker_window_start_ms.get(sender_id, now_ms), now_ms
	)
	var reject_count: int = _int_from_variant(
		_peer_damage_breaker_reject_count.get(sender_id, 0), 0
	)
	if now_ms - window_start_ms > window_ms:
		window_start_ms = now_ms
		reject_count = 0
	reject_count += 1
	if reject_count >= threshold:
		var block_ms: int = int(
			round(clampf(damage_request_breaker_block_sec, 0.5, 120.0) * 1000.0)
		)
		_peer_damage_breaker_blocked_until_ms[sender_id] = now_ms + block_ms
		window_start_ms = now_ms
		reject_count = 0
	_peer_damage_breaker_window_start_ms[sender_id] = window_start_ms
	_peer_damage_breaker_reject_count[sender_id] = reject_count


func _is_breaker_counted_reject_reason(reason_key: String) -> bool:
	match reason_key:
		"target_dead", "interval_limited", "seq_replay", "breaker_blocked":
			return false
		_:
			return true


func _resolve_enemy_damage_controller(target_node: Node) -> Node:
	if target_node == null:
		return null
	var candidate: Node = target_node
	if not candidate.has_method("apply_damage"):
		candidate = target_node.get_parent()
	if candidate == null:
		return null
	if not candidate.has_method("apply_damage"):
		return null
	if not candidate.has_method("is_dead"):
		return null
	# 可破坏物（如大门）没有 set_network_authority，但允许走客户端伤害请求。
	if candidate.is_in_group(breakable_group_name):
		return candidate
	if not candidate.has_method("set_network_authority"):
		return null
	var boss_controller: EnemyAI = _get_boss_controller()
	if candidate == boss_controller:
		return candidate
	var spawner: Node = _get_tauren_spawner()
	if spawner != null and candidate.get_parent() == spawner:
		return candidate
	if candidate.is_in_group("boss"):
		return candidate
	return null


func _resolve_enemy_damage_target_position(target_node: Node, enemy_controller: Node) -> Vector3:
	if enemy_controller != null:
		var model_variant: Variant = enemy_controller.get("_enemy")
		if model_variant is Node3D:
			var enemy_model: Node3D = model_variant as Node3D
			if enemy_model != null and is_instance_valid(enemy_model):
				return enemy_model.global_position
	var target_node_3d: Node3D = target_node as Node3D
	if target_node_3d != null and is_instance_valid(target_node_3d):
		return target_node_3d.global_position
	var controller_3d: Node3D = enemy_controller as Node3D
	if controller_3d != null and is_instance_valid(controller_3d):
		return controller_3d.global_position
	return Vector3.ZERO


func _consume_damage_request_interval(
	sender_id: int,
	source_key: String,
	source_kind: String,
	target_path: String,
	hero_state: Dictionary
) -> bool:
	var key: String = "%s|%s" % [source_key, target_path]
	var now_ms: int = Time.get_ticks_msec()
	var min_interval_ms: int = _compute_damage_request_min_interval_ms(source_kind, hero_state)
	if min_interval_ms <= 0:
		return true
	var peer_cache_variant: Variant = _peer_last_damage_request_ms.get(sender_id, {})
	var peer_cache: Dictionary = {}
	if peer_cache_variant is Dictionary:
		peer_cache = (peer_cache_variant as Dictionary).duplicate(true)
	var last_ms: int = _int_from_variant(peer_cache.get(key, -1000000), -1000000)
	if now_ms - last_ms < min_interval_ms:
		return false
	peer_cache[key] = now_ms
	_peer_last_damage_request_ms[sender_id] = peer_cache
	return true


func _consume_damage_request_budget(sender_id: int, source_kind: String) -> bool:
	var refill_per_sec: float = maxf(damage_request_budget_per_sec, 20.0)
	var burst_sec: float = clampf(damage_request_budget_burst_sec, 1.0, 4.0)
	var max_tokens: float = refill_per_sec * burst_sec
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _int_from_variant(_peer_damage_budget_last_ms.get(sender_id, now_ms), now_ms)
	var elapsed_sec: float = maxf(float(now_ms - last_ms) * 0.001, 0.0)
	var tokens: float = _float_from_variant(
		_peer_damage_budget_tokens.get(sender_id, max_tokens), max_tokens
	)
	tokens = minf(max_tokens, tokens + elapsed_sec * refill_per_sec)
	var cost: float = _damage_request_budget_cost(source_kind)
	if tokens < cost:
		_peer_damage_budget_tokens[sender_id] = tokens
		_peer_damage_budget_last_ms[sender_id] = now_ms
		return false
	tokens -= cost
	_peer_damage_budget_tokens[sender_id] = tokens
	_peer_damage_budget_last_ms[sender_id] = now_ms
	return true


func _damage_request_budget_cost(source_kind: String) -> float:
	match source_kind:
		"basic_attack":
			return 1.0
		"attack_effect":
			return 1.0
		"poison":
			return 0.7
		"q_ray":
			return 1.2
		"flash":
			return 1.2
		"r_cluster":
			return 1.35
		_:
			return 1.0


func _compute_damage_request_min_interval_ms(source_kind: String, hero_state: Dictionary) -> int:
	var attack_interval_sec: float = clampf(
		_float_from_variant(hero_state.get("attack_interval", 0.45), 0.45), 0.08, 2.5
	)
	var poison_tick_sec: float = clampf(
		_float_from_variant(hero_state.get("poison_tick_interval", 0.6), 0.6), 0.1, 3.0
	)
	var attack_interval_ms: int = int(round(attack_interval_sec * 1000.0))
	var poison_tick_ms: int = int(round(poison_tick_sec * 1000.0))
	match source_kind:
		"basic_attack":
			return maxi(int(round(float(attack_interval_ms) * 0.28)), 45)
		"attack_effect":
			return maxi(int(round(float(attack_interval_ms) * 0.18)), 30)
		"poison":
			return maxi(int(round(float(poison_tick_ms) * 0.55)), 90)
		"q_ray":
			return 90
		"flash":
			return 90
		"r_cluster":
			return 120
		_:
			return 70


func _normalize_damage_source(source_text: String) -> String:
	var source: String = source_text.strip_edges().to_lower()
	if source.begins_with("attack_effect"):
		return "attack_effect"
	if source.begins_with("flash"):
		return "flash"
	if source.begins_with("q_ray"):
		return "q_ray"
	if source.begins_with("r_cluster"):
		return "r_cluster"
	if source.begins_with("poison"):
		return "poison"
	if source.begins_with("basic_attack"):
		return "basic_attack"
	return source


func _validate_enemy_damage_geometry(
	source_kind: String, attacker_avatar: Node3D, target_pos: Vector3, context: Dictionary
) -> bool:
	if attacker_avatar == null or not is_instance_valid(attacker_avatar):
		return false
	match source_kind:
		"q_ray":
			var ray_start_variant: Variant = context.get("ray_start", null)
			var ray_end_variant: Variant = context.get("ray_end", null)
			if not (ray_start_variant is Vector3) or not (ray_end_variant is Vector3):
				return false
			var ray_start: Vector3 = ray_start_variant
			var ray_end: Vector3 = ray_end_variant
			var ray_vec: Vector3 = ray_end - ray_start
			ray_vec.y = 0.0
			var ray_len: float = ray_vec.length()
			if ray_len <= 1.0:
				return false
			var attacker_offset: Vector3 = attacker_avatar.global_position - ray_start
			attacker_offset.y = 0.0
			if attacker_offset.length() > 220.0:
				return false
			var ray_dir: Vector3 = ray_vec / ray_len
			var rel: Vector3 = target_pos - ray_start
			rel.y = 0.0
			var projection: float = rel.dot(ray_dir)
			if projection < -80.0 or projection > ray_len + 80.0:
				return false
			var closest: Vector3 = ray_start + ray_dir * clampf(projection, 0.0, ray_len)
			var lateral: Vector3 = target_pos - closest
			lateral.y = 0.0
			var ray_radius: float = clampf(
				_float_from_variant(context.get("ray_radius", 48.0), 48.0), 1.0, 280.0
			)
			if lateral.length() > ray_radius + 60.0:
				return false
			return true
		"flash":
			var center_variant: Variant = context.get("center", null)
			if not (center_variant is Vector3):
				return false
			var center: Vector3 = center_variant
			var radius: float = clampf(
				_float_from_variant(context.get("radius", 380.0), 380.0), 1.0, 2600.0
			)
			var to_target: Vector3 = target_pos - center
			to_target.y = 0.0
			if to_target.length() > radius + 80.0:
				return false
			var attacker_to_center: Vector3 = attacker_avatar.global_position - center
			attacker_to_center.y = 0.0
			if attacker_to_center.length() > 1800.0:
				return false
			return true
		"r_cluster":
			var center_variant_r: Variant = context.get("center", null)
			if not (center_variant_r is Vector3):
				return false
			var center_r: Vector3 = center_variant_r
			var radius_r: float = clampf(
				_float_from_variant(context.get("radius", 250.0), 250.0), 1.0, 800.0
			)
			var cast_range_r: float = clampf(
				_float_from_variant(context.get("cast_range", 3000.0), 3000.0), 80.0, 3200.0
			)
			var to_target_r: Vector3 = target_pos - center_r
			to_target_r.y = 0.0
			if to_target_r.length() > radius_r + 80.0:
				return false
			var cast_origin_r: Vector3 = attacker_avatar.global_position
			var origin_variant_r: Variant = context.get("origin", null)
			if origin_variant_r is Vector3:
				cast_origin_r = origin_variant_r
				var attacker_to_origin_r: Vector3 = attacker_avatar.global_position - cast_origin_r
				attacker_to_origin_r.y = 0.0
				if attacker_to_origin_r.length() > 260.0:
					return false
			var origin_to_center_r: Vector3 = cast_origin_r - center_r
			origin_to_center_r.y = 0.0
			if origin_to_center_r.length() > cast_range_r + 220.0:
				return false
			return true
		_:
			return true


func _apply_enemy_knockback_from_context(enemy_controller: Node, context: Dictionary) -> void:
	if enemy_controller == null:
		return
	if not enemy_controller.has_method("apply_knockback"):
		return
	var distance: float = clampf(
		_float_from_variant(context.get("knockback_distance", 0.0), 0.0), 0.0, 240.0
	)
	if distance <= 0.0:
		return
	var duration_sec: float = clampf(
		_float_from_variant(context.get("knockback_duration", 0.2), 0.2), 0.05, 0.2
	)
	var priority: int = clampi(_int_from_variant(context.get("knockback_priority", 0), 0), 0, 100)
	var dir_variant: Variant = context.get("knockback_dir", null)
	if not (dir_variant is Vector3):
		return
	var knockback_dir: Vector3 = dir_variant
	knockback_dir.y = 0.0
	if knockback_dir.length_squared() <= 0.0001:
		return
	if context.has("ray_start") and context.has("ray_end"):
		var ray_start_variant: Variant = context.get("ray_start", null)
		var ray_end_variant: Variant = context.get("ray_end", null)
		if ray_start_variant is Vector3 and ray_end_variant is Vector3:
			var ray_vec: Vector3 = (ray_end_variant as Vector3) - (ray_start_variant as Vector3)
			ray_vec.y = 0.0
			if ray_vec.length_squared() > 0.0001:
				var ray_dir: Vector3 = ray_vec.normalized()
				var direction_dot: float = ray_dir.dot(knockback_dir.normalized())
				if direction_dot < 0.55:
					return
	enemy_controller.call(
		"apply_knockback", knockback_dir.normalized(), distance, duration_sec, priority
	)


func _get_remote_avatar_for_peer(peer_id: int) -> Node3D:
	if peer_id <= 0:
		return null
	if not _remote_avatars.has(peer_id):
		return null
	var avatar: Node3D = _remote_avatars[peer_id] as Node3D
	if avatar == null or not is_instance_valid(avatar):
		return null
	return avatar


func request_damage_remote_hero(
	peer_id: int, amount: int, ignore_armor: bool = false, damage_type: String = "physical"
) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	if multiplayer.multiplayer_peer == null:
		return
	if peer_id <= 0:
		return
	rpc_id(
		peer_id, "rpc_apply_hero_damage_from_authority", maxi(amount, 0), ignore_armor, damage_type
	)


func request_slow_remote_hero(peer_id: int, slow_percent: float, duration: float) -> void:
	if network_mode.strip_edges().to_lower() != "host":
		return
	if multiplayer.multiplayer_peer == null:
		return
	if peer_id <= 0:
		return
	rpc_id(peer_id, "rpc_apply_hero_slow_from_authority", slow_percent, duration)


func is_gate_damage_enabled() -> bool:
	var mode_text: String = network_mode.strip_edges().to_lower()
	if mode_text != "host":
		return _is_local_hero_selection_confirmed()
	var room_ids: Array[int] = _get_room_player_ids()
	if room_ids.is_empty():
		return _is_local_hero_selection_confirmed()
	for peer_id in room_ids:
		if not _is_peer_hero_selection_confirmed(peer_id):
			return false
	return true


func _is_peer_hero_selection_confirmed(peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	if _peer_hero_selection_confirmed.has(peer_id):
		var rpc_confirmed: bool = _bool_from_variant(
			_peer_hero_selection_confirmed.get(peer_id, false), false
		)
		if rpc_confirmed:
			return true
	if multiplayer.multiplayer_peer != null and peer_id == multiplayer.get_unique_id():
		return _is_local_hero_selection_confirmed()
	if not _peer_latest_hero_state.has(peer_id):
		return false
	var state_variant: Variant = _peer_latest_hero_state[peer_id]
	if not (state_variant is Dictionary):
		return false
	var state: Dictionary = state_variant as Dictionary
	return _bool_from_variant(state.get("hero_selected", false), false)


func _is_local_hero_selection_confirmed() -> bool:
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller == null:
		return false
	return _bool_from_variant(hero_controller.get("hero_selection_confirmed"), false)


func notify_local_hero_selection_confirmed(confirmed: bool) -> void:
	var confirmed_flag: bool = bool(confirmed)
	if multiplayer.multiplayer_peer != null:
		var self_id: int = multiplayer.get_unique_id()
		if self_id > 0:
			_peer_hero_selection_confirmed[self_id] = confirmed_flag
	_sync_local_lobby_member_data()
	if network_mode.strip_edges().to_lower() != "client":
		return
	if not _is_network_running:
		return
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.get_peers().is_empty():
		return
	rpc_id(1, "rpc_report_hero_selection_confirmed", confirmed_flag)


func request_hero_control_command_from_client(command: Dictionary) -> bool:
	if multiplayer.multiplayer_peer == null:
		return false
	var has_connected_peer: bool = not multiplayer.get_peers().is_empty()
	var sanitized: Dictionary = _sanitize_peer_hero_command(command)
	if sanitized.is_empty():
		return false
	var result: Dictionary = _get_client_sync_flow_service().should_send_hero_command(
		network_mode,
		_is_network_running,
		has_connected_peer,
		sanitized,
		_local_last_sent_hero_command_seq,
		Callable(self, "_int_from_variant")
	)
	if not bool(result.get("should_send", false)):
		return false
	rpc_id(1, "rpc_submit_client_hero_command", result.get("command", sanitized))
	_local_last_sent_hero_command_seq = int(
		result.get("next_last_sent_seq", _local_last_sent_hero_command_seq)
	)
	return true


func _send_latest_skill_event_if_needed(hero_state: Dictionary) -> void:
	if network_mode.strip_edges().to_lower() != "client":
		return
	if multiplayer.multiplayer_peer == null or multiplayer.get_peers().is_empty():
		return
	var event_variant: Variant = hero_state.get("skill_event", null)
	if not (event_variant is Dictionary):
		return
	var event: Dictionary = _sanitize_peer_skill_event(event_variant as Dictionary)
	if event.is_empty():
		return
	var seq: int = _int_from_variant(event.get("seq", -1), -1)
	if seq <= _client_last_sent_skill_event_seq:
		return
	rpc_id(1, "rpc_submit_client_skill_event", event)
	_client_last_sent_skill_event_seq = seq


func request_enemy_damage_from_client(
	target_path: String,
	amount: int,
	max_range: float = -1.0,
	source: String = "attack",
	context: Dictionary = {}
) -> bool:
	if network_mode.strip_edges().to_lower() != "client":
		return false
	if not _is_network_running:
		return false
	if multiplayer.multiplayer_peer == null:
		return false
	if multiplayer.get_peers().is_empty():
		return false
	var result: Dictionary = _get_client_sync_flow_service().build_enemy_damage_request(
		_client_enemy_damage_request_seq, target_path, amount, max_range, source, context
	)
	if not bool(result.get("ok", false)):
		return false
	_client_enemy_damage_request_seq = int(result.get("next_seq", _client_enemy_damage_request_seq))
	var event: Dictionary = result.get("event", {})
	_client_last_sent_enemy_damage_request_seq = int(event.get("seq", -1))
	rpc_id(1, "rpc_submit_client_enemy_damage_request", event)
	return true


func get_last_sent_enemy_damage_request_seq() -> int:
	return _client_last_sent_enemy_damage_request_seq


func get_last_sent_client_input_seq() -> int:
	return _client_input_seq


func get_last_acknowledged_client_input_seq() -> int:
	return _last_ack_input_seq_from_host


func request_equipment_action(action: String, payload: Dictionary = {}) -> bool:
	if network_mode.strip_edges().to_lower() != "client":
		return false
	if not _is_network_running:
		return false
	if multiplayer.multiplayer_peer == null:
		return false
	if multiplayer.get_peers().is_empty():
		return false
	var result: Dictionary = _get_client_sync_flow_service().build_equipment_action_request(
		_local_equipment_request_seq, action, payload, _collect_local_equipment_state()
	)
	if not bool(result.get("ok", false)):
		return false
	_local_equipment_request_seq = int(result.get("next_request_seq", _local_equipment_request_seq))
	var request: Dictionary = result.get("request", {})
	rpc_id(1, "rpc_request_equipment_action", request)
	return true


func _process_equipment_action_request(sender_id: int, request: Dictionary) -> Dictionary:
	var action_text: String = str(request.get("action", "")).strip_edges().to_lower()
	var request_seq: int = _int_from_variant(request.get("request_seq", -1), -1)
	var baseline_variant: Variant = request.get("baseline", {})
	var baseline_state: Dictionary = {}
	if baseline_variant is Dictionary:
		baseline_state = (baseline_variant as Dictionary).duplicate(true)
	var commit: Dictionary = {}
	var ui: GameUI = _get_game_ui()
	if ui != null:
		var commit_variant: Variant = ui.call(
			"authority_handle_equipment_action", sender_id, request, baseline_state
		)
		if commit_variant is Dictionary:
			commit = commit_variant
	if commit.is_empty():
		commit = {
			"ok": false,
			"peer_id": sender_id,
			"action": action_text,
			"request_seq": request_seq,
			"reason": "authority_handler_missing",
			"state": baseline_state
		}
	var state_variant: Variant = commit.get("state", null)
	if state_variant is Dictionary:
		_apply_client_equipment_state_from_sender(sender_id, state_variant as Dictionary)
	return commit


func _upsert_remote_avatar_from_state(peer_id: int, hero_state: Dictionary) -> void:
	var pos_variant: Variant = hero_state.get("pos", null)
	if not (pos_variant is Vector3):
		return
	var pos: Vector3 = pos_variant
	var previous_pos: Vector3 = pos
	var has_previous_pos: bool = false
	if _remote_avatar_target_positions.has(peer_id):
		var prev_pos_variant: Variant = _remote_avatar_target_positions[peer_id]
		if prev_pos_variant is Vector3:
			previous_pos = prev_pos_variant
			has_previous_pos = true
	var now_ms: int = Time.get_ticks_msec()
	var prev_receive_ms: int = _int_from_variant(
		_remote_avatar_last_receive_ms.get(peer_id, now_ms), now_ms
	)
	if has_previous_pos:
		var dt_sec: float = clampf(float(now_ms - prev_receive_ms) * 0.001, 0.016, 0.5)
		var remote_velocity: Vector3 = (pos - previous_pos) / dt_sec
		remote_velocity.y = 0.0
		var max_predict_speed: float = maxf(remote_prediction_max_speed, 200.0)
		var velocity_len: float = remote_velocity.length()
		if velocity_len > max_predict_speed:
			remote_velocity = remote_velocity / velocity_len * max_predict_speed
		_remote_avatar_velocities[peer_id] = remote_velocity
	else:
		_remote_avatar_velocities[peer_id] = Vector3.ZERO
	_remote_avatar_last_receive_ms[peer_id] = now_ms
	var prev_flash_cd: float = _float_from_variant(_remote_last_flash_cd.get(peer_id, 0.0), 0.0)
	var prev_haste_active: bool = _bool_from_variant(
		_remote_last_haste_active.get(peer_id, false), false
	)
	var yaw: float = _float_from_variant(hero_state.get("yaw", 0.0), 0.0)
	var model_key: String = _get_remote_model_key(hero_state)
	var avatar: Node3D = _upsert_remote_avatar(peer_id, pos, yaw, model_key)
	if avatar == null:
		return
	if not avatar.is_in_group("hero"):
		avatar.add_to_group("hero")
	avatar.set_meta("network_peer_id", peer_id)
	var scale_variant: Variant = hero_state.get("scale", avatar.scale)
	if scale_variant is Vector3:
		avatar.scale = scale_variant
	_apply_remote_avatar_animation(peer_id, avatar, hero_state)
	if avatar != null and is_instance_valid(avatar):
		var is_dead: bool = _bool_from_variant(hero_state.get("is_dead", false), false)
		avatar.visible = not is_dead
		_update_remote_avatar_hp_bar(peer_id, avatar, hero_state, is_dead)
	if sync_skill_effects:
		_apply_remote_skill_effects(
			peer_id, avatar, hero_state, previous_pos, prev_flash_cd, prev_haste_active
		)
	_remote_last_flash_cd[peer_id] = _float_from_variant(
		hero_state.get("flash_cd", prev_flash_cd), prev_flash_cd
	)
	_remote_last_haste_active[peer_id] = _bool_from_variant(
		hero_state.get("haste_active", prev_haste_active), prev_haste_active
	)


func _upsert_remote_avatar(
	peer_id: int, position: Vector3, yaw: float, model_key: String
) -> Node3D:
	var self_id: int = 0
	if multiplayer.multiplayer_peer != null:
		self_id = multiplayer.get_unique_id()
	return _get_remote_avatar_runtime_service().upsert_remote_avatar(
		peer_id,
		self_id,
		position,
		yaw,
		model_key,
		remote_snap_distance,
		remote_player_scale,
		_remote_players_root,
		_remote_avatars,
		_remote_avatar_model_keys,
		_remote_avatar_last_anims,
		_remote_avatar_target_positions,
		_remote_avatar_target_yaws,
		Callable(self, "_resolve_remote_player_scene"),
		Callable(self, "_disable_collisions_recursive")
	)


func _get_peer_latest_hero_command(peer_id: int) -> Dictionary:
	return _get_remote_avatar_motion_service().get_peer_latest_hero_command(
		peer_id, _peer_latest_hero_command
	)


func _is_remote_avatar_command_drive_active(peer_id: int) -> bool:
	var command: Dictionary = _get_peer_latest_hero_command(peer_id)
	return _get_remote_avatar_motion_service().is_remote_avatar_command_drive_active(
		remote_command_drive_enabled, network_mode, command
	)


func _resolve_remote_command_target_node(command: Dictionary) -> Node3D:
	var target_path: String = str(command.get("target_path", "")).strip_edges()
	if target_path.is_empty():
		return null
	var target_node: Node = get_node_or_null(NodePath(target_path))
	if target_node is Node3D:
		return target_node as Node3D
	if target_node != null:
		var parent_node_3d: Node3D = target_node.get_parent() as Node3D
		if parent_node_3d != null:
			return parent_node_3d
	return null


func _resolve_remote_command_target_position(
	peer_id: int, command: Dictionary, fallback: Vector3
) -> Vector3:
	var target_node: Node3D = _resolve_remote_command_target_node(command)
	return _get_remote_avatar_motion_service().resolve_remote_command_target_position(
		command, fallback, target_node, _remote_avatar_target_positions, peer_id
	)


func _resolve_peer_move_speed(peer_id: int) -> float:
	return _get_remote_avatar_motion_service().resolve_peer_move_speed(
		peer_id, _peer_latest_hero_state
	)


func _resolve_peer_attack_range(peer_id: int) -> float:
	return _get_remote_avatar_motion_service().resolve_peer_attack_range(
		peer_id, _peer_latest_hero_state
	)


func _resolve_remote_avatar_visual_target_yaw(
	peer_id: int, fallback_yaw: float, prefer_movement_heading: bool = false
) -> float:
	var target_yaw: float = fallback_yaw
	if _remote_avatar_target_yaws.has(peer_id):
		target_yaw = _float_from_variant(_remote_avatar_target_yaws[peer_id], target_yaw)
	if not prefer_movement_heading:
		return target_yaw
	if not _peer_latest_hero_state.has(peer_id):
		return target_yaw
	var state_variant: Variant = _peer_latest_hero_state[peer_id]
	if not (state_variant is Dictionary):
		return target_yaw
	var hero_state: Dictionary = state_variant as Dictionary
	if not _bool_from_variant(hero_state.get("is_moving", false), false):
		return target_yaw
	var command: Dictionary = _get_peer_latest_hero_command(peer_id)
	var cmd_type: String = str(command.get("type", "")).strip_edges().to_lower()
	if cmd_type != "move_to" and cmd_type != "chase_target" and cmd_type != "attack_target":
		return target_yaw
	if not _remote_avatar_velocities.has(peer_id):
		return target_yaw
	var velocity_variant: Variant = _remote_avatar_velocities[peer_id]
	if not (velocity_variant is Vector3):
		return target_yaw
	var velocity: Vector3 = velocity_variant
	velocity.y = 0.0
	if velocity.length() <= 18.0:
		return target_yaw
	var movement_yaw: float = atan2(velocity.x, velocity.z) - PI / 2.0
	var yaw_delta: float = absf(wrapf(target_yaw - movement_yaw, -PI, PI))
	if yaw_delta >= PI * 0.35:
		return movement_yaw
	return lerp_angle(target_yaw, movement_yaw, 0.35)


func _should_use_remote_avatar_command_drive(peer_id: int, command: Dictionary) -> bool:
	if not _get_remote_avatar_motion_service().is_remote_avatar_command_drive_active(
		remote_command_drive_enabled, network_mode, command
	):
		return false
	if not _remote_avatar_target_positions.has(peer_id):
		return true
	var last_receive_ms: int = _int_from_variant(
		_remote_avatar_last_receive_ms.get(peer_id, -1), -1
	)
	if last_receive_ms < 0:
		return true
	var authority_stale_threshold_sec: float = clampf(
		maxf(hero_sync_interval_sec, send_interval_sec) * 2.5, 0.08, 0.35
	)
	var elapsed_sec: float = maxf(float(Time.get_ticks_msec() - last_receive_ms) * 0.001, 0.0)
	return elapsed_sec >= authority_stale_threshold_sec


func _apply_remote_avatar_command_correction(peer_id: int, avatar: Node3D, delta: float) -> void:
	_get_remote_avatar_motion_service().apply_remote_avatar_command_correction(
		peer_id,
		avatar,
		delta,
		_remote_avatar_target_positions,
		_remote_avatar_velocities,
		remote_command_drive_soft_correction_distance,
		remote_command_drive_hard_snap_distance,
		remote_command_drive_correction_speed
	)


func _update_remote_avatar_command_drive(
	peer_id: int, avatar: Node3D, delta: float, rot_alpha: float
) -> bool:
	var command: Dictionary = _get_peer_latest_hero_command(peer_id)
	if not _should_use_remote_avatar_command_drive(peer_id, command):
		return false
	var current_pos: Vector3 = avatar.global_position
	var target_pos: Vector3 = _resolve_remote_command_target_position(peer_id, command, current_pos)
	return _get_remote_avatar_motion_service().update_remote_avatar_command_drive(
		peer_id,
		avatar,
		delta,
		rot_alpha,
		command,
		target_pos,
		_resolve_peer_move_speed(peer_id),
		_resolve_peer_attack_range(peer_id),
		remote_command_drive_stop_distance,
		remote_command_drive_soft_correction_distance,
		remote_command_drive_hard_snap_distance,
		remote_command_drive_correction_speed,
		remote_command_drive_turn_speed,
		_remote_avatar_target_positions,
		_remote_avatar_target_yaws,
		_remote_avatar_velocities
	)


func _update_remote_avatar_smoothing(delta: float) -> void:
	if delta <= 0.0:
		return
	if _remote_avatars.is_empty():
		return
	var mode_text: String = network_mode.strip_edges().to_lower()
	var host_snap_mode: bool = mode_text == "host"

	var now_ms: int = Time.get_ticks_msec()
	var pos_alpha: float = 1.0 - exp(-maxf(remote_position_smooth_speed, 0.01) * delta)
	var rot_alpha: float = 1.0 - exp(-maxf(remote_rotation_smooth_speed, 0.01) * delta)
	var prediction_sec: float = clampf(remote_position_prediction_sec, 0.0, 0.25)
	var prediction_timeout_sec: float = clampf(remote_prediction_timeout_sec, 0.05, 1.2)
	var prediction_velocity_damping: float = maxf(remote_prediction_velocity_damping, 0.01)
	var host_large_snap_distance: float = maxf(host_large_displacement_snap_distance, 1.0)

	for key_variant in _remote_avatars.keys():
		var peer_id: int = int(key_variant)
		var avatar: Node3D = _remote_avatars[peer_id] as Node3D
		if avatar == null or not is_instance_valid(avatar):
			continue
		if (
			not host_snap_mode
			and _update_remote_avatar_command_drive(peer_id, avatar, delta, rot_alpha)
		):
			continue

		var target_pos: Vector3 = avatar.global_position
		if _remote_avatar_target_positions.has(peer_id):
			var pos_variant: Variant = _remote_avatar_target_positions[peer_id]
			if pos_variant is Vector3:
				target_pos = pos_variant
		var predicted_pos: Vector3 = target_pos
		if prediction_sec > 0.0 and _remote_avatar_velocities.has(peer_id):
			var velocity_variant: Variant = _remote_avatar_velocities[peer_id]
			if velocity_variant is Vector3:
				var velocity: Vector3 = velocity_variant
				var receive_ms: int = _int_from_variant(
					_remote_avatar_last_receive_ms.get(peer_id, now_ms), now_ms
				)
				var gap_sec: float = maxf(float(now_ms - receive_ms) * 0.001, 0.0)
				if gap_sec <= prediction_timeout_sec:
					var damping: float = exp(-prediction_velocity_damping * gap_sec)
					velocity *= damping
					predicted_pos += velocity * prediction_sec
				else:
					_remote_avatar_velocities[peer_id] = Vector3.ZERO
		predicted_pos.y = target_pos.y
		var should_hard_snap: bool = (
			host_snap_mode
			and avatar.global_position.distance_to(predicted_pos) >= host_large_snap_distance
		)
		if should_hard_snap:
			avatar.global_position = predicted_pos
			_remote_avatar_velocities[peer_id] = Vector3.ZERO
		else:
			avatar.global_position = avatar.global_position.lerp(predicted_pos, pos_alpha)

		var target_yaw: float = _resolve_remote_avatar_visual_target_yaw(
			peer_id, avatar.rotation.y, host_snap_mode
		)
		var next_rot: Vector3 = avatar.rotation
		if should_hard_snap:
			next_rot.y = target_yaw
		else:
			next_rot.y = lerp_angle(next_rot.y, target_yaw, rot_alpha)
		avatar.rotation = next_rot
		var hp_bar: MeshInstance3D = _remote_avatar_hp_bars.get(peer_id, null) as MeshInstance3D
		if hp_bar != null and is_instance_valid(hp_bar):
			var bar_height: float = maxf(remote_hp_bar_height, 0.0)
			if hp_bar.has_meta("anchor_height"):
				bar_height = _float_from_variant(hp_bar.get_meta("anchor_height"), bar_height)
			_sync_remote_avatar_hp_bar_transform(avatar, hp_bar, bar_height)


func _create_remote_avatar(peer_id: int, model_key: String) -> Node3D:
	_ensure_remote_players_root()
	return _get_remote_avatar_runtime_service().create_remote_avatar(
		_remote_players_root,
		peer_id,
		model_key,
		remote_player_scale,
		Callable(self, "_resolve_remote_player_scene"),
		Callable(self, "_disable_collisions_recursive")
	)


func _update_remote_avatar_hp_bar(
	peer_id: int, avatar: Node3D, hero_state: Dictionary, is_dead: bool
) -> void:
	_get_remote_avatar_visual_service().update_remote_avatar_hp_bar(
		peer_id,
		avatar,
		hero_state,
		is_dead,
		remote_hp_bar_height,
		remote_hp_bar_width,
		_remote_avatar_hp_bars,
		_remote_avatar_hp_bar_materials
	)


func _ensure_remote_avatar_hp_bar(
	peer_id: int, avatar: Node3D, bar_height: float
) -> MeshInstance3D:
	return _get_remote_avatar_visual_service().ensure_remote_avatar_hp_bar(
		peer_id,
		avatar,
		bar_height,
		remote_hp_bar_width,
		_remote_avatar_hp_bars,
		_remote_avatar_hp_bar_materials
	)


func _resolve_remote_avatar_hp_bar_height(hero_state: Dictionary, avatar: Node3D) -> float:
	return _get_remote_avatar_visual_service().resolve_remote_avatar_hp_bar_height(
		hero_state, avatar, remote_hp_bar_height
	)


func _sync_remote_avatar_hp_bar_transform(
	avatar: Node3D, hp_bar: MeshInstance3D, bar_height: float
) -> void:
	_get_remote_avatar_visual_service().sync_remote_avatar_hp_bar_transform(
		avatar, hp_bar, bar_height
	)


func _compute_node_mesh_height(root_node: Node3D, ignored_mesh_name: String = "") -> float:
	return _get_remote_avatar_visual_service().compute_node_mesh_height(
		root_node, ignored_mesh_name
	)


func _resolve_remote_player_scene(model_key: String) -> PackedScene:
	return _get_remote_avatar_runtime_service().resolve_remote_player_scene(
		model_key,
		remote_player_scene,
		remote_melee_player_scene,
		remote_ranged_player_scene,
		remote_transformed_player_scene
	)


func _get_remote_model_key(hero_state: Dictionary) -> String:
	return _get_remote_avatar_runtime_service().get_remote_model_key(hero_state)


func _apply_remote_avatar_animation(peer_id: int, avatar: Node3D, hero_state: Dictionary) -> void:
	_get_remote_avatar_runtime_service().apply_remote_avatar_animation(
		peer_id, avatar, hero_state, _remote_avatar_last_anims
	)


func _apply_remote_skill_effects(
	peer_id: int,
	avatar: Node3D,
	hero_state: Dictionary,
	previous_pos: Vector3,
	prev_flash_cd: float,
	prev_haste_active: bool
) -> void:
	if avatar == null or not is_instance_valid(avatar):
		return
	if _apply_remote_skill_event_from_state(peer_id, avatar, hero_state, previous_pos):
		return
	var flash_cd: float = _float_from_variant(
		hero_state.get("flash_cd", prev_flash_cd), prev_flash_cd
	)
	var just_cast_q: bool = (
		flash_cd > 0.2 and (prev_flash_cd <= 0.05 or flash_cd > prev_flash_cd + 0.35)
	)
	if just_cast_q:
		var model_key: String = _get_remote_model_key(hero_state)
		if model_key == "ranged":
			var cast_yaw: float = _float_from_variant(
				hero_state.get("yaw", avatar.rotation.y), avatar.rotation.y
			)
			_spawn_remote_ranged_q_ray(avatar.global_position, cast_yaw)
		else:
			_spawn_remote_flash_pair(previous_pos, avatar.global_position)

	var haste_active: bool = _bool_from_variant(
		hero_state.get("haste_active", prev_haste_active), prev_haste_active
	)
	if haste_active and not prev_haste_active and _should_spawn_remote_w_effect(hero_state):
		_spawn_remote_flash_effect(avatar.global_position, remote_haste_effect_scale)


func _should_spawn_remote_w_effect(hero_state: Dictionary, event_state: Dictionary = {}) -> bool:
	var skill_w_id: int = 0
	if not event_state.is_empty():
		skill_w_id = _int_from_variant(event_state.get("skill_id", 0), 0)
	if skill_w_id <= 0:
		skill_w_id = _int_from_variant(hero_state.get("skill_w_id", 0), 0)
	if skill_w_id > 0:
		return true
	return not _get_remote_model_key(hero_state).is_empty()


func _apply_remote_skill_event_from_state(
	peer_id: int, avatar: Node3D, hero_state: Dictionary, previous_pos: Vector3
) -> bool:
	if not hero_state.has("skill_event"):
		return false
	var event_variant: Variant = hero_state["skill_event"]
	if not (event_variant is Dictionary):
		return false
	var event_state: Dictionary = event_variant
	var event_seq: int = _int_from_variant(event_state.get("seq", -1), -1)
	if event_seq < 0:
		return false
	var last_seq: int = _int_from_variant(_remote_last_skill_event_seq.get(peer_id, -1), -1)
	if event_seq <= last_seq:
		return false
	_remote_last_skill_event_seq[peer_id] = event_seq
	var event_from_pos: Vector3 = previous_pos
	var from_variant: Variant = event_state.get("from_pos", null)
	if from_variant is Vector3:
		event_from_pos = from_variant
	var event_to_pos: Vector3 = avatar.global_position
	var to_variant: Variant = event_state.get("to_pos", null)
	if to_variant is Vector3:
		event_to_pos = to_variant
	var event_type: String = str(event_state.get("type", "")).strip_edges().to_lower()
	match event_type:
		"q":
			var model_key: String = _get_remote_model_key(hero_state)
			if model_key == "ranged":
				# 远程Q优先使用事件中的起止点回放，避免依赖朝向角造成90度偏差。
				var beam_delta: Vector3 = event_to_pos - event_from_pos
				beam_delta.y = 0.0
				if beam_delta.length() > 0.01:
					_spawn_remote_ranged_beam(event_from_pos, event_to_pos)
				else:
					var cast_yaw: float = _float_from_variant(
						event_state.get("yaw", hero_state.get("yaw", avatar.rotation.y)),
						avatar.rotation.y
					)
					_spawn_remote_ranged_q_ray(event_from_pos, cast_yaw)
			else:
				_spawn_remote_flash_pair(event_from_pos, event_to_pos)
			return true
		"w":
			if not _should_spawn_remote_w_effect(hero_state, event_state):
				return true
			var haste_pos: Vector3 = avatar.global_position
			var haste_pos_variant: Variant = event_state.get("pos", null)
			if haste_pos_variant is Vector3:
				haste_pos = haste_pos_variant
			_spawn_remote_flash_effect(haste_pos, remote_haste_effect_scale)
			return true
		"e":
			var evade_pos: Vector3 = avatar.global_position
			var evade_pos_variant: Variant = event_state.get("pos", null)
			if evade_pos_variant is Vector3:
				evade_pos = evade_pos_variant
			_spawn_remote_flash_effect(evade_pos, remote_flash_effect_scale * 0.8)
			return true
		"r":
			var skill_id: int = _int_from_variant(event_state.get("skill_id", 0), 0)
			if (
				skill_id != SKILL_ID_R_RANGED_CLUSTER
				and _get_remote_model_key(hero_state) != "ranged"
			):
				return true
			var visual_scale: float = _float_from_variant(
				event_state.get("visual_scale", remote_ranged_r_impact_scale_multiplier),
				remote_ranged_r_impact_scale_multiplier
			)
			_spawn_remote_ranged_r_strike(event_from_pos, event_to_pos, maxf(visual_scale, 0.1))
			return true
		_:
			return false


func _spawn_remote_flash_pair(origin_pos: Vector3, destination_pos: Vector3) -> void:
	_spawn_remote_flash_effect(origin_pos, remote_flash_effect_scale)
	if origin_pos.distance_to(destination_pos) >= 8.0:
		var destination_scale: Vector3 = remote_flash_effect_scale * 0.85
		_spawn_remote_flash_effect(destination_pos, destination_scale)


func _spawn_remote_flash_effect(effect_pos: Vector3, effect_scale: Vector3) -> void:
	if remote_flash_effect_scene == null:
		return
	var effect: Node3D = remote_flash_effect_scene.instantiate() as Node3D
	if effect == null:
		return
	var host: Node = get_parent()
	if host == null:
		host = self
	host.add_child(effect)
	effect.global_position = effect_pos
	effect.scale = effect_scale

	var duration: float = maxf(remote_skill_effect_fallback_lifetime, 0.08)
	var anim_player: AnimationPlayer = (
		effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
	)
	if anim_player != null:
		var anim_list: PackedStringArray = anim_player.get_animation_list()
		if anim_list.size() > 0:
			var anim_name: String = String(anim_list[0])
			var anim: Animation = anim_player.get_animation(anim_name)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
				duration = maxf(anim.length, 0.08)
			anim_player.play(anim_name)
	get_tree().create_timer(duration).timeout.connect(effect.queue_free)


func _spawn_remote_ranged_r_strike(
	start_pos: Vector3, impact_pos: Vector3, impact_scale: float = 1.0
) -> void:
	_ensure_remote_r_skill_effect_resources_loaded()
	var host: Node = get_parent()
	if host == null:
		host = self
	var planar_delta: Vector3 = impact_pos - start_pos
	planar_delta.y = 0.0
	var distance: float = maxf(planar_delta.length(), 0.0)
	var speed: float = maxf(remote_ranged_r_projectile_speed, 1.0)
	var min_flight: float = maxf(remote_ranged_r_projectile_min_flight_time, 0.02)
	var flight_duration: float = maxf(distance / speed, min_flight)
	if remote_ranged_r_projectile_scene == null:
		get_tree().create_timer(flight_duration).timeout.connect(
			func() -> void: _spawn_remote_ranged_r_impact_effect(impact_pos, impact_scale)
		)
		return
	var projectile: Node3D = remote_ranged_r_projectile_scene.instantiate() as Node3D
	if projectile == null:
		get_tree().create_timer(flight_duration).timeout.connect(
			func() -> void: _spawn_remote_ranged_r_impact_effect(impact_pos, impact_scale)
		)
		return
	host.add_child(projectile)
	projectile.global_position = start_pos
	projectile.scale = projectile.scale * maxf(impact_scale, 0.1)
	if planar_delta.length() > 0.01:
		projectile.look_at(impact_pos, Vector3.UP)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(projectile, "global_position", impact_pos, flight_duration)
	tween.finished.connect(
		func() -> void:
			if projectile != null and is_instance_valid(projectile):
				projectile.queue_free()
			_spawn_remote_ranged_r_impact_effect(impact_pos, impact_scale)
	)


func _spawn_remote_ranged_r_impact_effect(impact_pos: Vector3, impact_scale: float = 1.0) -> void:
	_ensure_remote_r_skill_effect_resources_loaded()
	if remote_ranged_r_impact_scene == null:
		return
	var effect: Node3D = remote_ranged_r_impact_scene.instantiate() as Node3D
	if effect == null:
		return
	var host: Node = get_parent()
	if host == null:
		host = self
	var effect_root := Node3D.new()
	effect_root.name = "RemoteRangedRImpactRoot"
	host.add_child(effect_root)
	effect_root.global_position = impact_pos
	effect_root.scale = Vector3.ONE * maxf(impact_scale, 0.1)
	effect_root.add_child(effect)
	effect.position = Vector3.ZERO
	var duration: float = _play_remote_effect_animation_once(
		effect, "Birth", REMOTE_RANGED_R_LOGIC_POINT_LIFETIME_SEC
	)
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if effect_root != null and is_instance_valid(effect_root):
				effect_root.queue_free()
	)


func _play_remote_effect_animation_once(
	effect: Node3D, preferred_animation: String = "", forced_duration_sec: float = -1.0
) -> float:
	var duration: float = maxf(remote_skill_effect_fallback_lifetime, 0.08)
	if forced_duration_sec > 0.0:
		duration = maxf(forced_duration_sec, 0.05)
	if effect == null or not is_instance_valid(effect):
		return duration
	var anim_player: AnimationPlayer = (
		effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
	)
	if anim_player == null:
		return duration
	var anim_name: String = preferred_animation.strip_edges()
	if anim_name.is_empty() or not anim_player.has_animation(anim_name):
		var anim_list: PackedStringArray = anim_player.get_animation_list()
		if anim_list.is_empty():
			return duration
		anim_name = String(anim_list[0])
	var anim: Animation = anim_player.get_animation(anim_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE
		var anim_length: float = maxf(anim.length, 0.08)
		if forced_duration_sec > 0.0:
			anim_player.speed_scale = maxf(anim_length / duration, 0.01)
		else:
			duration = anim_length
			anim_player.speed_scale = 1.0
	else:
		anim_player.speed_scale = 1.0
	anim_player.play(anim_name)
	return duration


func _spawn_remote_ranged_q_ray(ray_start: Vector3, yaw: float) -> void:
	# 英雄朝向在本项目中有 -PI/2 偏移，这里做回补，保证朝向兜底时方向正确。
	var corrected_yaw: float = yaw + PI / 2.0
	var safe_dir: Vector3 = Vector3(sin(corrected_yaw), 0.0, cos(corrected_yaw))
	if safe_dir.length() <= 0.001:
		safe_dir = Vector3.FORWARD
	safe_dir = safe_dir.normalized()
	var ray_end: Vector3 = ray_start + safe_dir * maxf(remote_ranged_q_ray_length, 1.0)
	_spawn_remote_ranged_beam(ray_start, ray_end)


func _spawn_remote_ranged_beam(ray_start: Vector3, ray_end: Vector3) -> void:
	var delta: Vector3 = ray_end - ray_start
	if delta.length() <= 0.01:
		return
	var safe_dir: Vector3 = delta.normalized()
	var safe_length: float = maxf(delta.length(), 1.0)
	var safe_width: float = maxf(remote_ranged_q_ray_width, 0.5)
	var safe_thickness: float = maxf(remote_ranged_q_ray_thickness, 0.5)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(safe_length, safe_thickness, safe_width)
	var beam: MeshInstance3D = MeshInstance3D.new()
	beam.mesh = mesh
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.12, 0.12, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.2, 1.0)
	mat.emission_energy_multiplier = 2.2
	beam.material_override = mat

	var center: Vector3 = (ray_start + ray_end) * 0.5
	var up_axis: Vector3 = Vector3.UP
	if absf(safe_dir.dot(up_axis)) > 0.99:
		up_axis = Vector3.FORWARD
	var z_axis: Vector3 = safe_dir.cross(up_axis).normalized()
	var y_axis: Vector3 = z_axis.cross(safe_dir).normalized()
	beam.global_transform = Transform3D(Basis(safe_dir, y_axis, z_axis), center)

	var host: Node = get_parent()
	if host == null:
		host = self
	host.add_child(beam)
	get_tree().create_timer(maxf(remote_ranged_q_ray_lifetime, 0.03)).timeout.connect(
		beam.queue_free
	)


func _pick_remote_fallback_animation(
	anim_player: AnimationPlayer, hero_state: Dictionary
) -> String:
	return _get_remote_avatar_runtime_service().pick_remote_fallback_animation(
		anim_player, hero_state
	)


func _find_anim_by_keywords(anim_player: AnimationPlayer, keywords: Array[String]) -> String:
	return _get_remote_avatar_runtime_service().find_anim_by_keywords(anim_player, keywords)


func _remove_absent_remote_avatars(valid_remote_ids: Dictionary) -> void:
	_get_remote_avatar_runtime_service().remove_absent_remote_avatars(
		valid_remote_ids, _remote_avatars, Callable(self, "_remove_remote_avatar")
	)


func _remove_remote_avatar(peer_id: int) -> void:
	_get_remote_avatar_runtime_service().remove_remote_avatar(
		peer_id,
		_remote_avatars,
		_remote_avatar_model_keys,
		_remote_avatar_last_anims,
		_remote_avatar_target_positions,
		_remote_avatar_target_yaws,
		_remote_avatar_velocities,
		_remote_avatar_last_receive_ms,
		_remote_avatar_hp_bars,
		_remote_avatar_hp_bar_materials,
		_remote_last_flash_cd,
		_remote_last_haste_active,
		_remote_last_skill_event_seq
	)


func _clear_remote_avatars() -> void:
	_get_remote_avatar_runtime_service().clear_remote_avatars(
		_remote_avatars,
		_remote_avatar_model_keys,
		_remote_avatar_last_anims,
		_remote_avatar_target_positions,
		_remote_avatar_target_yaws,
		_remote_avatar_velocities,
		_remote_avatar_last_receive_ms,
		_remote_avatar_hp_bars,
		_remote_avatar_hp_bar_materials,
		_remote_last_flash_cd,
		_remote_last_haste_active,
		_remote_last_skill_event_seq,
		Callable(self, "_remove_remote_avatar")
	)


func _reset_local_skill_event_runtime(prime_from_hero: bool) -> void:
	_local_skill_event_seq = 0
	_local_last_skill_event.clear()
	_local_prev_explicit_skill_event_seq = -1
	_local_prev_flash_cd = 0.0
	_local_prev_haste_active = false
	if not prime_from_hero:
		return
	var hero_controller: HeroController = _get_hero_controller()
	if hero_controller == null:
		return
	_local_prev_flash_cd = _float_from_variant(hero_controller.get("_flash_cooldown"), 0.0)
	_local_prev_haste_active = _bool_from_variant(hero_controller.get("_haste_active"), false)


func _update_local_skill_event_from_state(state: Dictionary) -> void:
	var flash_cd: float = _float_from_variant(
		state.get("flash_cd", _local_prev_flash_cd), _local_prev_flash_cd
	)
	var just_cast_q: bool = (
		flash_cd > 0.2 and (_local_prev_flash_cd <= 0.05 or flash_cd > _local_prev_flash_cd + 0.35)
	)
	if just_cast_q:
		_local_skill_event_seq += 1
		_local_last_skill_event = {
			"seq": _local_skill_event_seq,
			"type": "q",
			"skill_id": _int_from_variant(state.get("skill_q_id", 0), 0),
			"t_ms": Time.get_ticks_msec()
		}
	_local_prev_flash_cd = flash_cd

	var haste_active: bool = _bool_from_variant(
		state.get("haste_active", _local_prev_haste_active), _local_prev_haste_active
	)
	var just_cast_w: bool = haste_active and not _local_prev_haste_active
	if just_cast_w:
		_local_skill_event_seq += 1
		_local_last_skill_event = {
			"seq": _local_skill_event_seq,
			"type": "w",
			"skill_id": _int_from_variant(state.get("skill_w_id", 0), 0),
			"t_ms": Time.get_ticks_msec()
		}
	_local_prev_haste_active = haste_active


func _disable_collisions_recursive(root: Node) -> void:
	if root == null:
		return
	var collision_obj: CollisionObject3D = root as CollisionObject3D
	if collision_obj != null:
		collision_obj.collision_layer = 0
		collision_obj.collision_mask = 0
	for child in root.get_children():
		var child_node: Node = child as Node
		if child_node != null:
			_disable_collisions_recursive(child_node)


func _ensure_remote_players_root() -> void:
	var existing: Node3D = get_node_or_null(remote_players_root_path) as Node3D
	if existing != null:
		_remote_players_root = existing
		return
	var parent_node: Node3D = get_parent() as Node3D
	if parent_node == null:
		_remote_players_root = null
		return
	var fallback_root: Node3D = Node3D.new()
	fallback_root.name = "NetworkPlayers"
	parent_node.add_child(fallback_root)
	_remote_players_root = fallback_root


func _apply_network_authority_mode() -> void:
	var use_local_authority: bool = is_local_world_authority()

	var boss_controller: EnemyAI = _get_boss_controller()
	if boss_controller != null and boss_controller.has_method("set_network_authority"):
		boss_controller.call("set_network_authority", use_local_authority)

	var spawner: Node = _get_tauren_spawner()
	if spawner != null and spawner.has_method("set_network_authority"):
		spawner.call("set_network_authority", use_local_authority)


func _get_hero_controller() -> HeroController:
	return get_node_or_null(hero_controller_path) as HeroController


func _get_game_ui() -> GameUI:
	return get_node_or_null(game_ui_path) as GameUI


func _get_boss_controller() -> EnemyAI:
	return get_node_or_null(boss_controller_path) as EnemyAI


func _get_tauren_spawner() -> TaurenSpawner:
	return get_node_or_null(tauren_spawner_path) as TaurenSpawner


func _get_summon_manager() -> Node:
	return get_node_or_null(summon_manager_path)


func _get_local_hero() -> Node3D:
	var controller: Node = _get_hero_controller()
	if controller != null:
		var hero_variant: Variant = controller.get("_hero")
		if hero_variant is Node3D:
			var hero_node: Node3D = hero_variant as Node3D
			if hero_node != null and is_instance_valid(hero_node):
				return hero_node
	var fallback: Node3D = get_node_or_null(fallback_local_hero_path) as Node3D
	if fallback != null and is_instance_valid(fallback):
		return fallback
	return null


func _pump_steam_callbacks_if_needed() -> void:
	if net_transport_mode.strip_edges().to_lower() != "steam_relay":
		return
	if steam_embed_callbacks:
		return
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return
	if steam.has_method("run_callbacks"):
		steam.call("run_callbacks")


func _get_steam_singleton() -> Object:
	if _steam_singleton != null:
		return _steam_singleton
	if Engine.has_singleton("Steam"):
		_steam_singleton = Engine.get_singleton("Steam")
	return _steam_singleton


func _ensure_steam_initialized() -> Dictionary:
	var steam: Object = _get_steam_singleton()
	if steam == null:
		return {
			"ok": false, "err": ERR_UNAVAILABLE, "hint": "start_failed(steam_missing_singleton)"
		}

	if _steam_initialized:
		return {"ok": true, "steam": steam}

	var init_ok: bool = false
	var init_status: int = 1
	var init_variant: Variant = null
	if steam.has_method("steamInitEx"):
		init_variant = steam.call("steamInitEx", steam_app_id, steam_embed_callbacks)
	elif steam.has_method("steamInit"):
		init_variant = steam.call("steamInit", steam_app_id, steam_embed_callbacks)
	else:
		return {
			"ok": false, "err": ERR_UNAVAILABLE, "hint": "start_failed(steam_init_method_missing)"
		}

	if init_variant is Dictionary:
		var init_dict: Dictionary = init_variant
		init_status = _int_from_variant(init_dict.get("status", 1), 1)
		init_ok = init_status == 0
	elif init_variant is bool:
		init_ok = bool(init_variant)
		init_status = 0 if init_ok else 1
	else:
		init_ok = init_variant != null
		init_status = 0 if init_ok else 1

	if not init_ok:
		var init_debug_text: String = str(init_variant)
		if steam.has_method("get_steam_init_result"):
			init_debug_text = str(steam.call("get_steam_init_result"))
		return {
			"ok": false,
			"err": ERR_CANT_OPEN,
			"hint": "start_failed(steam_init status=%d data=%s)" % [init_status, init_debug_text]
		}

	_steam_initialized = true
	return {"ok": true, "steam": steam}


func _resolve_target_steam_host_id(mode: String) -> String:
	if _steam_lobby_owner_steam_id > 0:
		return str(_steam_lobby_owner_steam_id)
	var host_id: String = steam_target_host_id.strip_edges()
	if host_id.is_empty() and mode == "host":
		host_id = _resolve_effective_steam_local_id()
	if host_id.is_empty():
		host_id = server_host.strip_edges()
	return host_id


func _parse_steam_id_text(raw_text: String) -> int:
	var text: String = raw_text.strip_edges()
	if text.is_empty():
		return 0
	if not text.is_valid_int():
		return 0
	var parsed: int = text.to_int()
	if parsed <= 0:
		return 0
	return parsed


func _create_steam_relay_peer(mode: String) -> Dictionary:
	var init_result: Dictionary = _ensure_steam_initialized()
	if not bool(init_result.get("ok", false)):
		return init_result
	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		return {
			"ok": false,
			"err": ERR_UNAVAILABLE,
			"hint": "start_failed(steam_relay_peer_class_missing)"
		}

	var peer_obj: Object = ClassDB.instantiate("SteamMultiplayerPeer")
	if peer_obj == null:
		return {
			"ok": false,
			"err": ERR_CANT_CREATE,
			"hint": "start_failed(steam_relay_peer_create_failed)"
		}
	if not (peer_obj is MultiplayerPeer):
		return {
			"ok": false,
			"err": ERR_CANT_CREATE,
			"hint": "start_failed(steam_relay_peer_invalid_type)"
		}
	var steam_peer: MultiplayerPeer = peer_obj as MultiplayerPeer
	var virtual_port: int = maxi(steam_virtual_port, 0)
	var local_id: String = _resolve_effective_steam_local_id()
	var active_lobby_id: int = _steam_lobby_id
	var err: int = ERR_CANT_CREATE

	if mode == "host":
		if active_lobby_id > 0 and virtual_port == 0 and steam_peer.has_method("host_with_lobby"):
			err = _int_from_variant(
				steam_peer.call("host_with_lobby", active_lobby_id), ERR_CANT_CREATE
			)
		elif steam_peer.has_method("create_host"):
			err = _int_from_variant(steam_peer.call("create_host", virtual_port), ERR_CANT_CREATE)
		else:
			err = ERR_UNAVAILABLE
		if err != OK:
			if steam_peer.has_method("close"):
				steam_peer.call("close")
			return {"ok": false, "err": err, "hint": "start_failed(steam_relay_host err=%d)" % err}
		var host_hint: String = (
			"network_started(steam_relay app=%d local=%s host_id=%s vport=%d)"
			% [
				steam_app_id,
				local_id if not local_id.is_empty() else "-",
				local_id if not local_id.is_empty() else "-",
				virtual_port
			]
		)
		if active_lobby_id > 0:
			host_hint = (
				"network_started(steam_relay_lobby lobby=%d app=%d local=%s host_id=%s)"
				% [
					active_lobby_id,
					steam_app_id,
					local_id if not local_id.is_empty() else "-",
					local_id if not local_id.is_empty() else "-"
				]
			)
		return {"ok": true, "err": OK, "peer": steam_peer, "hint": host_hint}

	var target_host_id: String = _resolve_target_steam_host_id(mode)
	var target_host_steam_id: int = _parse_steam_id_text(target_host_id)
	var can_connect_via_lobby: bool = (
		active_lobby_id > 0 and virtual_port == 0 and steam_peer.has_method("connect_to_lobby")
	)
	if target_host_steam_id <= 0 and not can_connect_via_lobby:
		return {
			"ok": false,
			"err": ERR_INVALID_PARAMETER,
			"hint": "start_failed(steam_relay_invalid_host_id=%s)" % target_host_id
		}
	if can_connect_via_lobby:
		err = _int_from_variant(
			steam_peer.call("connect_to_lobby", active_lobby_id), ERR_CANT_CREATE
		)
	elif steam_peer.has_method("create_client"):
		err = _int_from_variant(
			steam_peer.call("create_client", target_host_steam_id, virtual_port), ERR_CANT_CREATE
		)
	else:
		err = ERR_UNAVAILABLE
	if err != OK:
		if steam_peer.has_method("close"):
			steam_peer.call("close")
		return {
			"ok": false,
			"err": err,
			"hint": "start_failed(steam_relay_client err=%d host=%s)" % [err, target_host_id]
		}
	var client_hint: String = (
		"network_started(steam_relay app=%d local=%s host_id=%s vport=%d)"
		% [steam_app_id, local_id if not local_id.is_empty() else "-", target_host_id, virtual_port]
	)
	if active_lobby_id > 0:
		client_hint = (
			"network_started(steam_relay_lobby lobby=%d app=%d local=%s host_id=%s)"
			% [
				active_lobby_id,
				steam_app_id,
				local_id if not local_id.is_empty() else "-",
				(
					str(_steam_lobby_owner_steam_id)
					if _steam_lobby_owner_steam_id > 0
					else (target_host_id if not target_host_id.is_empty() else "-")
				)
			]
		)
	return {"ok": true, "err": OK, "peer": steam_peer, "hint": client_hint}


func _resolve_effective_steam_local_id() -> String:
	var local_id: String = steam_local_id.strip_edges()
	if not local_id.is_empty():
		return local_id
	var steam: Object = _get_steam_singleton()
	if steam != null and steam.has_method("getSteamID"):
		var steam_id_variant: Variant = steam.call("getSteamID")
		var steam_id_text: String = str(steam_id_variant).strip_edges()
		if not steam_id_text.is_empty() and steam_id_text != "0":
			return steam_id_text
	if multiplayer.multiplayer_peer != null:
		var uid: int = multiplayer.get_unique_id()
		if uid > 0:
			return str(uid)
	return ""


func _refresh_steam_stub_endpoint_map() -> void:
	_steam_stub_endpoint_map = _parse_endpoint_map_csv(steam_stub_endpoint_map_csv)


func _resolve_steam_stub_endpoint(target_host_id: String) -> Dictionary:
	var target: String = target_host_id.strip_edges()
	if not target.is_empty() and _steam_stub_endpoint_map.has(target):
		var mapped_variant: Variant = _steam_stub_endpoint_map[target]
		if mapped_variant is Dictionary:
			return mapped_variant

	var fallback_host: String = steam_stub_default_remote_host.strip_edges()
	if fallback_host.is_empty():
		fallback_host = server_host.strip_edges()
	if fallback_host.is_empty():
		return {}
	var fallback_port: int = maxi(steam_stub_default_remote_port, 1)
	if fallback_port <= 0:
		fallback_port = maxi(server_port, 1)
	return {"host": fallback_host, "port": fallback_port}


func _parse_endpoint_map_csv(raw_text: String) -> Dictionary:
	var output: Dictionary = {}
	var tokens: PackedStringArray = raw_text.split(",", false)
	for token_sn in tokens:
		var token: String = String(token_sn).strip_edges()
		if token.is_empty():
			continue
		var eq_idx: int = token.find("=")
		if eq_idx <= 0:
			continue
		var steam_id: String = token.substr(0, eq_idx).strip_edges()
		var endpoint: String = token.substr(eq_idx + 1).strip_edges()
		if steam_id.is_empty() or endpoint.is_empty():
			continue

		var host: String = endpoint
		var port: int = maxi(steam_stub_default_remote_port, 1)
		var colon_idx: int = endpoint.rfind(":")
		if colon_idx > 0 and colon_idx < endpoint.length() - 1:
			host = endpoint.substr(0, colon_idx).strip_edges()
			var port_text: String = endpoint.substr(colon_idx + 1).strip_edges()
			if port_text.is_valid_int():
				port = maxi(port_text.to_int(), 1)
		host = host.strip_edges()
		if host.is_empty():
			continue
		output[steam_id] = {"host": host, "port": port}
	return output


func _pick_remote_peer_by_mouse_position(mouse_pos: Vector2) -> int:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return 0
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return 0
	var pick_radius: float = maxf(remote_select_screen_radius, 8.0)
	var best_distance: float = pick_radius
	var best_peer: int = 0
	for key_variant in _remote_avatars.keys():
		var peer_id: int = int(key_variant)
		var avatar: Node3D = _remote_avatars[peer_id] as Node3D
		if avatar == null or not is_instance_valid(avatar):
			continue
		if not avatar.visible:
			continue
		var world_pos: Vector3 = avatar.global_position + Vector3(0.0, 90.0, 0.0)
		if camera.is_position_behind(world_pos):
			continue
		var screen_pos: Vector2 = camera.unproject_position(world_pos)
		var distance: float = mouse_pos.distance_to(screen_pos)
		if distance <= best_distance:
			best_distance = distance
			best_peer = peer_id
	return best_peer


func _is_click_on_local_hero(mouse_pos: Vector2) -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return false
	var hero: Node3D = _get_local_hero()
	if hero == null or not is_instance_valid(hero):
		return false
	var world_pos: Vector3 = hero.global_position + Vector3(0.0, 90.0, 0.0)
	if camera.is_position_behind(world_pos):
		return false
	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	return mouse_pos.distance_to(screen_pos) <= maxf(remote_select_screen_radius, 8.0)


func _is_click_on_boss(mouse_pos: Vector2) -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return false
	var boss_controller: EnemyAI = _get_boss_controller()
	if boss_controller == null:
		return false
	var boss_model: Node3D = null
	var boss_variant: Variant = boss_controller.get("_enemy")
	if boss_variant is Node3D:
		boss_model = boss_variant as Node3D
	if boss_model == null:
		boss_model = boss_controller as Node3D
	if boss_model == null or not is_instance_valid(boss_model) or not boss_model.visible:
		return false
	var world_pos: Vector3 = boss_model.global_position + Vector3(0.0, 120.0, 0.0)
	if camera.is_position_behind(world_pos):
		return false
	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	return mouse_pos.distance_to(screen_pos) <= maxf(remote_select_screen_radius, 8.0)


func _pick_enemy_observe_state_by_mouse_position(mouse_pos: Vector2) -> Dictionary:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return {}
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return {}
	var tree: SceneTree = get_tree()
	if tree == null:
		return {}
	var boss_controller: EnemyAI = _get_boss_controller()
	var pick_radius: float = maxf(remote_select_screen_radius, 8.0)
	var best_distance: float = pick_radius
	var best_state: Dictionary = {}
	for enemy_node_variant in tree.get_nodes_in_group("enemy"):
		var enemy_node: Node = enemy_node_variant as Node
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		var controller: Node = _resolve_observable_enemy_controller(enemy_node)
		if controller == null or not is_instance_valid(controller):
			continue
		if boss_controller != null and controller == boss_controller:
			continue
		var controller_3d: Node3D = controller as Node3D
		if controller_3d == null or not controller_3d.visible:
			continue
		var anchor_pos: Vector3 = controller_3d.global_position + Vector3(0.0, 100.0, 0.0)
		var model_variant: Variant = controller.get("_model")
		if model_variant is Node3D:
			var model_node: Node3D = model_variant as Node3D
			if model_node != null and is_instance_valid(model_node) and model_node.visible:
				anchor_pos = model_node.global_position + Vector3(0.0, 100.0, 0.0)
		if camera.is_position_behind(anchor_pos):
			continue
		var screen_pos: Vector2 = camera.unproject_position(anchor_pos)
		var distance: float = mouse_pos.distance_to(screen_pos)
		if distance > best_distance:
			continue
		var observe_state: Dictionary = _build_enemy_observe_state_from_controller(controller)
		if observe_state.is_empty():
			continue
		best_distance = distance
		best_state = observe_state
	return best_state


func _resolve_observable_enemy_controller(source_node: Node) -> Node:
	var cursor: Node = source_node
	var steps: int = 0
	while cursor != null and steps < 8:
		if _looks_like_observable_enemy(cursor):
			return cursor
		cursor = cursor.get_parent()
		steps += 1
	return null


func _looks_like_observable_enemy(node: Node) -> bool:
	if node == null:
		return false
	if not (node is Node3D):
		return false
	var has_hp: bool = (
		_object_has_property(node, "_current_hp") or _object_has_property(node, "current_hp")
	)
	var has_max_hp: bool = _object_has_property(node, "max_hp")
	var has_damage: bool = _object_has_property(node, "damage_per_hit")
	return has_hp and has_max_hp and has_damage


func _build_enemy_observe_state_from_controller(controller: Node) -> Dictionary:
	if controller == null:
		return {}
	if controller.has_method("is_dead") and bool(controller.call("is_dead")):
		return {}
	if _object_has_property(controller, "_is_dead") and bool(controller.get("_is_dead")):
		return {}
	if not _object_has_property(controller, "max_hp"):
		return {}
	var max_hp: int = maxi(int(controller.get("max_hp")), 1)
	var current_hp: int = 0
	if _object_has_property(controller, "_current_hp"):
		current_hp = maxi(int(controller.get("_current_hp")), 0)
	elif _object_has_property(controller, "current_hp"):
		current_hp = maxi(int(controller.get("current_hp")), 0)
	var observe_state: Dictionary = {"name": "牛头人", "hp": current_hp, "max_hp": max_hp}
	if _object_has_property(controller, "damage_per_hit"):
		observe_state["damage"] = int(controller.get("damage_per_hit"))
	if _object_has_property(controller, "armor"):
		observe_state["armor"] = float(controller.get("armor"))
	if _object_has_property(controller, "move_speed"):
		observe_state["move_speed"] = float(controller.get("move_speed"))
	if _object_has_property(controller, "attack_speed"):
		observe_state["attack_speed"] = float(controller.get("attack_speed"))
	if _object_has_property(controller, "attack_range"):
		observe_state["attack_range"] = float(controller.get("attack_range"))
	return observe_state


func _notify_game_ui_observe_peer(peer_id: int) -> void:
	var ui: GameUI = _get_game_ui()
	if ui == null:
		return
	ui.set_observed_peer(maxi(peer_id, 0))


func _notify_game_ui_observe_boss(enabled: bool) -> void:
	var ui: GameUI = _get_game_ui()
	if ui == null:
		return
	ui.set_observed_boss(bool(enabled))


func _notify_game_ui_observe_enemy(enemy_state: Dictionary) -> void:
	var ui: GameUI = _get_game_ui()
	if ui == null:
		return
	ui.set_observed_enemy(enemy_state)


func get_ui_self_peer_id() -> int:
	if multiplayer.multiplayer_peer != null:
		return multiplayer.get_unique_id()
	return 0


func get_synced_peer_ids() -> Array:
	var ids: Array = []
	for key_variant in _peer_latest_hero_state.keys():
		ids.append(int(key_variant))
	return ids


func get_ui_peer_hero_state(peer_id: int) -> Dictionary:
	if _peer_latest_hero_state.has(peer_id):
		var state_variant: Variant = _peer_latest_hero_state[peer_id]
		if state_variant is Dictionary:
			return state_variant
	return {}


func get_ui_peer_equipment_state(peer_id: int) -> Dictionary:
	if _peer_latest_equipment_state.has(peer_id):
		var state_variant: Variant = _peer_latest_equipment_state[peer_id]
		if state_variant is Dictionary:
			return state_variant
	return {}


func host_override_peer_equipment_state(peer_id: int, equipment_state: Dictionary) -> void:
	if peer_id <= 0 or equipment_state.is_empty():
		return
	var next_state: Dictionary = equipment_state.duplicate(true)
	_peer_latest_equipment_state[peer_id] = next_state
	_peer_latest_equipment_signatures[peer_id] = _build_state_signature(next_state)


func focus_ui_on_self() -> void:
	_ui_observed_peer_id = 0
	_notify_game_ui_observe_peer(0)
	_notify_game_ui_observe_boss(false)
	_notify_game_ui_observe_enemy({})


func _create_status_overlay() -> void:
	var refs: Dictionary = _get_network_status_display_service().create_overlay(self)
	_status_layer = refs.get("status_layer", null) as CanvasLayer
	_status_panel = refs.get("status_panel", null) as PanelContainer
	_status_label = refs.get("status_label", null) as RichTextLabel


func _refresh_status_text() -> void:
	if _status_label == null:
		return
	var mode_raw: String = network_mode.strip_edges().to_lower()
	var self_id: int = 0
	if multiplayer.multiplayer_peer != null:
		self_id = multiplayer.get_unique_id()
	var room_ids: Array[int] = _get_room_player_ids()
	var transport_mode: String = net_transport_mode.strip_edges().to_lower()
	var relay_local_id: String = ""
	var relay_target_id: String = ""
	var stub_local_id: String = ""
	var stub_target_id: String = ""
	var stub_endpoint_host: String = ""
	var stub_endpoint_port: int = 0
	if transport_mode == "steam_relay":
		relay_local_id = _resolve_effective_steam_local_id()
		relay_target_id = _resolve_target_steam_host_id(mode_raw)
	elif transport_mode == "steam_stub":
		stub_local_id = _resolve_effective_steam_local_id()
		stub_target_id = steam_target_host_id.strip_edges()
		var endpoint: Dictionary = _resolve_steam_stub_endpoint(stub_target_id)
		stub_endpoint_host = str(endpoint.get("host", "")).strip_edges()
		stub_endpoint_port = _int_from_variant(
			endpoint.get("port", steam_stub_default_remote_port), steam_stub_default_remote_port
		)
	var text: String = (
		_get_network_status_display_service()
		. build_status_text(
			{
				"mode_raw": mode_raw,
				"network_running": _is_network_running,
				"self_id": self_id,
				"room_ids": room_ids,
				"server_host": server_host,
				"server_port": server_port,
				"fps": Engine.get_frames_per_second(),
				"transport_mode": transport_mode,
				"steam_initialized": _steam_initialized,
				"steam_app_id": steam_app_id,
				"steam_virtual_port": steam_virtual_port,
				"relay_local_id": relay_local_id,
				"relay_target_id": relay_target_id,
				"stub_local_id": stub_local_id,
				"stub_target_id": stub_target_id,
				"stub_endpoint_host": stub_endpoint_host,
				"stub_endpoint_port": stub_endpoint_port,
				"steam_lobby_id": _steam_lobby_id,
				"steam_lobby_owner_steam_id": _steam_lobby_owner_steam_id,
				"steam_lobby_member_steam_ids": _steam_lobby_member_steam_ids,
				"host_migration_in_progress": _host_migration_in_progress,
				"host_migration_target_steam_id": _host_migration_target_steam_id,
				"peer_latest_hero_state": _peer_latest_hero_state,
				"peer_latest_equipment_state": _peer_latest_equipment_state,
				"active_world_sync_interval_sec": _get_active_world_sync_interval_sec(),
				"hero_sync_interval_sec": hero_sync_interval_sec,
				"world_mob_chunk_size": world_mob_chunk_size,
				"dynamic_world_mob_chunk_size": _dynamic_world_mob_chunk_size,
				"last_world_packet_bytes": _last_world_packet_bytes,
				"adaptive_world_sync_enabled": adaptive_world_sync_enabled,
				"client_input_seq": _client_input_seq,
				"last_ack_input_seq_from_host": _last_ack_input_seq_from_host,
				"client_recent_input_frames_size": _client_recent_input_frames.size(),
				"peer_last_input_seq_size": _peer_last_input_seq.size(),
				"host_world_snapshot_seq": _host_world_snapshot_seq,
				"damage_request_budget_per_sec": damage_request_budget_per_sec,
				"damage_request_budget_burst_sec": damage_request_budget_burst_sec,
				"peer_damage_budget_tokens_size": _peer_damage_budget_tokens.size(),
				"peer_input_latency_ms": _peer_input_latency_ms,
				"peer_damage_accept_total": _peer_damage_accept_total,
				"peer_damage_reject_total": _peer_damage_reject_total,
				"peer_damage_reject_reason_counts": _peer_damage_reject_reason_counts,
				"peer_damage_breaker_blocked_until_ms": _peer_damage_breaker_blocked_until_ms,
				"client_last_rtt_ms": _client_last_rtt_ms,
				"client_avg_rtt_ms": _client_avg_rtt_ms,
				"status_event_hint": _status_event_hint,
				"now_ms": Time.get_ticks_msec(),
			}
		)
	)
	_set_status_text(text)


func _set_status_text(text: String) -> void:
	_last_status_text = _get_network_status_display_service().set_status_text(_status_label, text)


func _get_room_player_ids() -> Array[int]:
	var self_id: int = 0
	var peer_ids: Array = []
	if multiplayer.multiplayer_peer != null:
		self_id = multiplayer.get_unique_id()
		peer_ids = multiplayer.get_peers()
	return _get_network_status_display_service().get_room_player_ids(
		_is_network_running, multiplayer.multiplayer_peer != null, self_id, peer_ids
	)


func _normalize_transport_mode(raw_mode: String) -> String:
	var mode: String = raw_mode.strip_edges().to_lower()
	match mode:
		"enet", "enet_direct", "enet-direct":
			return "enet_direct"
		"sdr", "steam_relay", "steam-relay", "relay":
			return "steam_relay"
		"steam_stub", "steam-stub":
			return "steam_stub"
		_:
			return mode


func _set_transport_mode(raw_mode: String) -> void:
	var normalized: String = _normalize_transport_mode(raw_mode)
	match normalized:
		"enet_direct", "steam_stub", "steam_relay":
			net_transport_mode = normalized
		_:
			pass


func _apply_transport_config_overrides() -> void:
	if not transport_config_enabled:
		return
	var cfg_path: String = transport_config_path.strip_edges()
	if cfg_path.is_empty():
		return
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(cfg_path)
	if err != OK:
		return

	var transport_variant: Variant = cfg.get_value("network", "transport", null)
	if transport_variant != null:
		_set_transport_mode(str(transport_variant))

	var app_id_variant: Variant = cfg.get_value("network", "steam_app_id", null)
	if app_id_variant != null:
		steam_app_id = _int_from_variant(app_id_variant, steam_app_id)

	var embed_variant: Variant = cfg.get_value("network", "steam_embed_callbacks", null)
	if embed_variant != null:
		steam_embed_callbacks = _bool_from_variant(embed_variant, steam_embed_callbacks)

	var vport_variant: Variant = cfg.get_value("network", "steam_virtual_port", null)
	if vport_variant != null:
		steam_virtual_port = _int_from_variant(vport_variant, steam_virtual_port)

	var local_id_variant: Variant = cfg.get_value("network", "steam_local_id", null)
	if local_id_variant != null:
		steam_local_id = str(local_id_variant).strip_edges()

	var host_id_variant: Variant = cfg.get_value("network", "steam_host_id", null)
	if host_id_variant != null:
		steam_target_host_id = str(host_id_variant).strip_edges()

	var lobby_enabled_variant: Variant = cfg.get_value("network", "steam_lobby_enabled", null)
	if lobby_enabled_variant != null:
		steam_lobby_enabled = _bool_from_variant(lobby_enabled_variant, steam_lobby_enabled)

	var lobby_action_variant: Variant = cfg.get_value("network", "steam_lobby_action", null)
	if lobby_action_variant != null:
		steam_lobby_action = str(lobby_action_variant).strip_edges().to_lower()

	var lobby_visibility_variant: Variant = cfg.get_value("network", "steam_lobby_visibility", null)
	if lobby_visibility_variant != null:
		steam_lobby_visibility = str(lobby_visibility_variant).strip_edges().to_lower()

	var lobby_members_variant: Variant = cfg.get_value("network", "steam_lobby_max_members", null)
	if lobby_members_variant != null:
		steam_lobby_max_members = _int_from_variant(lobby_members_variant, steam_lobby_max_members)

	var lobby_id_variant: Variant = cfg.get_value("network", "steam_lobby_id", null)
	if lobby_id_variant != null:
		steam_lobby_id_text = str(lobby_id_variant).strip_edges()

	var lobby_name_variant: Variant = cfg.get_value("network", "steam_lobby_name", null)
	if lobby_name_variant != null:
		steam_lobby_name = str(lobby_name_variant).strip_edges()

	var host_migration_variant: Variant = cfg.get_value("network", "host_migration_enabled", null)
	if host_migration_variant != null:
		host_migration_enabled = _bool_from_variant(host_migration_variant, host_migration_enabled)


func _apply_cmdline_overrides() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for raw_arg in args:
		var arg: String = raw_arg.strip_edges()
		if arg.is_empty():
			continue
		var key: String = arg
		var value: String = "true"
		var eq_idx: int = arg.find("=")
		if eq_idx >= 0:
			key = arg.substr(0, eq_idx)
			value = arg.substr(eq_idx + 1)
		key = key.strip_edges().to_lower()
		if key.begins_with("--"):
			key = key.substr(2)
		value = value.strip_edges()
		_apply_cmdline_kv(key, value)
	var full_args: PackedStringArray = OS.get_cmdline_args()
	for arg_idx in range(full_args.size()):
		var arg_text: String = String(full_args[arg_idx]).strip_edges()
		if arg_text == "+connect_lobby" and arg_idx + 1 < full_args.size():
			steam_lobby_enabled = true
			steam_lobby_action = "join"
			steam_lobby_id_text = String(full_args[arg_idx + 1]).strip_edges()
			network_mode = "client"
			_set_transport_mode("steam_relay")
			auto_start_network = true
		elif arg_text.begins_with("+connect_lobby="):
			steam_lobby_enabled = true
			steam_lobby_action = "join"
			steam_lobby_id_text = arg_text.trim_prefix("+connect_lobby=").strip_edges()
			network_mode = "client"
			_set_transport_mode("steam_relay")
			auto_start_network = true


func _apply_cmdline_kv(key: String, value: String) -> void:
	match key:
		"net", "network", "mode", "net-mode", "net_mode":
			network_mode = value.strip_edges().to_lower()
		"transport", "net-transport", "net_transport":
			_set_transport_mode(value)
		"host", "server", "server-host", "server_host":
			server_host = value
		"port", "server-port", "server_port":
			server_port = _parse_int_or_default(value, server_port)
		"steam-app-id", "steam_app_id", "appid", "app_id":
			steam_app_id = _parse_int_or_default(value, steam_app_id)
		"steam-embed-callbacks", "steam_embed_callbacks":
			steam_embed_callbacks = _parse_bool_or_default(value, steam_embed_callbacks)
		"steam-virtual-port", "steam_virtual_port", "virtual-port", "virtual_port":
			steam_virtual_port = _parse_int_or_default(value, steam_virtual_port)
		"steam-id", "steam_id", "local-steam-id", "local_steam_id":
			steam_local_id = value.strip_edges()
		"steam-host-id", "steam_host_id", "target-host-id", "target_host_id":
			steam_target_host_id = value.strip_edges()
		"lobby", "steam-lobby", "steam_lobby", "lobby-action", "lobby_action":
			steam_lobby_action = value.strip_edges().to_lower()
		"lobby-id", "lobby_id", "steam-lobby-id", "steam_lobby_id":
			steam_lobby_id_text = value.strip_edges()
		"lobby-enabled", "lobby_enabled", "steam-lobby-enabled", "steam_lobby_enabled":
			steam_lobby_enabled = _parse_bool_or_default(value, steam_lobby_enabled)
		"lobby-visibility", "lobby_visibility", "steam-lobby-visibility", "steam_lobby_visibility":
			steam_lobby_visibility = value.strip_edges().to_lower()
		"lobby-members", "lobby_members", "steam-lobby-members", "steam_lobby_max_members":
			steam_lobby_max_members = _parse_int_or_default(value, steam_lobby_max_members)
		"lobby-name", "lobby_name", "steam-lobby-name", "steam_lobby_name":
			steam_lobby_name = value.strip_edges()
		"host-migration", "host_migration", "host-migration-enabled", "host_migration_enabled":
			host_migration_enabled = _parse_bool_or_default(value, host_migration_enabled)
		"steam-listen-port", "steam_listen_port", "listen-port", "listen_port":
			steam_stub_listen_port = _parse_int_or_default(value, steam_stub_listen_port)
		"steam-remote-host", "steam_remote_host", "remote-host", "remote_host":
			steam_stub_default_remote_host = value.strip_edges()
		"steam-remote-port", "steam_remote_port", "remote-port", "remote_port":
			steam_stub_default_remote_port = _parse_int_or_default(
				value, steam_stub_default_remote_port
			)
		"steam-endpoint-map", "steam_endpoint_map", "endpoint-map", "endpoint_map":
			steam_stub_endpoint_map_csv = value
		"auto-connect", "auto_connect", "autostart", "auto_start_network":
			auto_start_network = _parse_bool_or_default(value, auto_start_network)
		_:
			pass


func _parse_int_or_default(raw: String, fallback: int) -> int:
	var text: String = raw.strip_edges()
	if text.is_empty():
		return fallback
	if not text.is_valid_int():
		return fallback
	return text.to_int()


func _parse_bool_or_default(raw: String, fallback: bool) -> bool:
	var text: String = raw.strip_edges().to_lower()
	if text.is_empty():
		return fallback
	if text == "1" or text == "true" or text == "yes" or text == "on":
		return true
	if text == "0" or text == "false" or text == "no" or text == "off":
		return false
	return fallback


func _object_has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false
	if property_name.strip_edges().is_empty():
		return false
	var properties: Array = target.get_property_list()
	for property_variant in properties:
		if not (property_variant is Dictionary):
			continue
		var property_info: Dictionary = property_variant
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _int_from_variant(value: Variant, fallback: int) -> int:
	if value == null:
		return fallback
	if value is int:
		return value
	if value is float:
		return int(round(value))
	if value is String and value.is_valid_int():
		return value.to_int()
	return fallback


func _float_from_variant(value: Variant, fallback: float) -> float:
	if value == null:
		return fallback
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String and value.is_valid_float():
		return value.to_float()
	return fallback


func _bool_from_variant(value: Variant, fallback: bool) -> bool:
	if value == null:
		return fallback
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return absf(value) > 0.0001
	if value is String:
		var lower: String = value.strip_edges().to_lower()
		if lower == "true" or lower == "1" or lower == "yes" or lower == "on":
			return true
		if lower == "false" or lower == "0" or lower == "no" or lower == "off":
			return false
	return fallback
