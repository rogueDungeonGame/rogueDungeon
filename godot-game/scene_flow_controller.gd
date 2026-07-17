extends Node3D
class_name SceneFlowController

const GATE_SCRIPT := preload("res://boss_gate.gd")
const FLOOR_BALANCE_SCRIPT := preload("res://rogue_floor_balance.gd")
const BATTLE_FENCE_SCENE := preload("res://placeholders/fence_2d.tscn")
const DEFAULT_CAMERA_OFFSET := Vector3(0.0, 1700.0, 1050.0)
const SHOP_OWNER_META_KEY := "shop_owner_peer_id"
const SHOP_SLOT_META_KEY := "shop_slot_index"
const SHOP_COLLISION_LAYER_META_KEY := "shop_saved_collision_layer"
const SHOP_COLLISION_MASK_META_KEY := "shop_saved_collision_mask"
const SHOP_INTERACTION_ONLY_LAYER: int = 1 << 1

@export var navigation_region_path: NodePath = NodePath("NavigationRegion")
@export var shop_path: NodePath = NodePath("NavigationRegion/Shop")
@export var hero_controller_path: NodePath = NodePath("HeroController")
@export var hero_path: NodePath = NodePath("HeroController/herowarden")
@export var boss_path: NodePath = NodePath("EnemyAI/HeroTaurenChieftain2")
@export var camera_path: NodePath = NodePath("Camera3D")
@export var net_session_controller_path: NodePath = NodePath("NetSessionController")
@export var game_ui_path: NodePath = NodePath("GameUI")
@export var debug_shop_owner_binding_logs: bool = true
@export var total_floor_count: int = 21
@export var starting_floor_index: int = 1
@export_enum("simple", "normal", "hard", "cruel", "inferno") var floor_difficulty: String = "simple"
@export var floor_overlay_enabled: bool = true
@export var reward_last_floor_index: int = 17
@export var shop_last_floor_index: int = 18

@export var battle_map_origin_xz: Vector2 = Vector2(500.0, 1000.0)
@export var battle_map_size_xz: Vector2 = Vector2(7000.0, 4000.0)
@export var battle_map_boundary_thickness: float = 240.0
@export var battle_map_boundary_height: float = 320.0
@export var battle_map_boundary_visible: bool = false
@export var battle_map_boundary_color: Color = Color(0.14, 0.14, 0.14, 0.92)
@export var outside_region_fill_visible: bool = false
@export var outside_region_fill_color: Color = Color(0.18, 0.18, 0.18, 1.0)
@export var outside_region_fill_margin: float = 6000.0
@export var outside_region_fill_below_floor_offset: float = 1.0
@export var battle_map_fence_scene: PackedScene = BATTLE_FENCE_SCENE
@export var battle_map_fence_scale_multiplier: float = 2.0
@export var battle_map_fence_collision_size: Vector3 = Vector3(80.0, 40.0, 10.0)
@export var battle_map_fence_spacing: float = 80.0
@export var battle_map_fence_height_offset: float = 20.0
@export var battle_map_fence_horizontal_yaw_degrees: float = 45.0
@export var battle_map_fence_vertical_yaw_degrees: float = -45.0
@export var battle_map_fence_line_start_x: float = 1500.0
@export var battle_map_fence_line_end_x: float = 5500.0
@export var battle_map_fence_line_z_a: float = 2250.0
@export var battle_map_fence_line_z_b: float = 3750.0
@export var battle_map_fence_vertical_x: float = 6500.0
@export var battle_map_fence_vertical_start_z: float = 2000.0
@export var battle_map_fence_vertical_end_z: float = 4000.0
@export var battle_map_spawn_seed_base: int = 260427
@export var battle_map_boss_spawn_margin: float = 520.0
@export var battle_map_mob_spawn_margin: float = 280.0

@export var start_point: Vector3 = Vector3(0.0, 0.0, 100000.0)
@export var start_area_shift_distance: float = 0.0
@export var start_area_shift_direction: Vector3 = Vector3(-1.0, 0.0, -1.0)
@export var shop_ring_half_size_x: float = 1333.3334
@export var shop_ring_half_size_z: float = 666.6667
@export var hero_start_offset: Vector3 = Vector3(-220.0, 0.0, 140.0)
@export var host_start_extra_offset: Vector3 = Vector3(-180.0, 0.0, 0.0)
@export var client_start_extra_offset: Vector3 = Vector3(180.0, 0.0, 0.0)
@export var hero_spawn_min_radius: float = 560.0
@export var hero_spawn_scatter_radius: float = 280.0
@export var hero_spawn_role_bias_max: float = 180.0
@export var gate_above_shop_distance: float = 500.0
@export var gate_offset: Vector3 = Vector3.ZERO
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp")
var start_area_floor_texture_path: String = "res://effects/ground/StartAreaFloor.png"
@export var start_area_floor_y_offset: float = 0.4
@export var start_area_floor_uv_tiling: float = 14.0
@export var start_area_floor_extra_margin: float = 120.0
@export var start_area_wall_padding: float = 320.0
@export var start_area_wall_thickness: float = 100.0
@export var start_area_wall_height: float = 320.0
@export var start_area_wall_visible: bool = false
@export var start_area_wall_color: Color = Color(0.46, 0.48, 0.52, 0.32)
@export var boss_entry_offset: Vector3 = Vector3(-260.0, 0.0, -100.0)
@export var boss_battle_role_offset_scale: float = 1.0
@export var boss_entry_random_min_radius: float = 320.0
@export var boss_entry_random_max_radius: float = 820.0
@export var boss_entry_random_min_distance: float = 140.0
@export var boss_entry_random_try_count: int = 28
@export var camera_focus_height: float = 120.0
@export var camera_initial_height_boost: float = 400.0
@export var camera_tilt_reduce_degrees: float = 5.0
@export var edge_scroll_enabled: bool = true
@export var edge_scroll_margin_px: int = 24
@export var edge_scroll_speed: float = 2400.0
@export var edge_scroll_accel_curve: float = 3
@export var camera_height_min: float = 500.0
@export var camera_height_max: float = 3200.0
@export var camera_height_wheel_step: float = 120.0
@export var camera_height_anim_duration: float = 0.18
@export var camera_refocus_double_tap_ms: int = 320

@export var gate_scene: PackedScene = preload("res://placeholders/gate_2d.tscn")
@export var gate_model_scale: Vector3 = Vector3(1.3333334, 1.3333334, 1.3333334)
@export var gate_collider_size: Vector3 = Vector3(173.33334, 146.66667, 80.0)
@export var gate_max_hp: int = 100
@export var melee_hero_scene: PackedScene = preload("res://placeholders/hero_melee_2d.tscn")
@export var ranged_hero_scene: PackedScene = preload("res://placeholders/hero_ranged_2d.tscn")
@export var melee_hero_name: String = "守望者"
@export var ranged_hero_name: String = "火枪手"

var _camera_offset_from_hero: Vector3 = DEFAULT_CAMERA_OFFSET
var _hero_selected: bool = false
var _hero_select_layer: CanvasLayer
var _camera_height_target: float = DEFAULT_CAMERA_OFFSET.y
var _camera_height_tween: Tween
var _network_role: String = "offline"
var _last_refocus_key_time_ms: int = -1000000
var _boss_battle_started: bool = false
var _awaiting_floor_clear: bool = false
var _current_floor_index: int = 1
var _run_completed: bool = false
var _start_area_center: Vector3 = Vector3.ZERO
var _has_start_area_center: bool = false
var _shop_cluster_positions: Array[Vector3] = []
var _shop_owner_peer_ids: Array[int] = []
var _shop_owner_binding_poll_elapsed: float = 0.0
var _floor_overlay_layer: CanvasLayer = null
var _floor_overlay_label: Label = null
var _battle_map_layout_applied: bool = false
var _nav_rebake_queued: bool = false


func _ready() -> void:
	set_process(true)
	set_process_input(true)
	_setup_battle_map_layout()
	_parse_network_role_from_cmdline()
	var hero := _get_current_hero()
	var camera := get_node_or_null(camera_path) as Camera3D
	if hero != null and camera != null:
		_camera_offset_from_hero = camera.global_position - hero.global_position
		# 聚焦时保持英雄水平居中，避免继承场景初始站位导致的横向偏移。
		_camera_offset_from_hero.x = 0.0
		_camera_height_target = camera.global_position.y
		_apply_initial_camera_adjustments(camera, hero)

	_move_shop_to_start_point()
	_setup_start_area_floor_patch()
	_spawn_gate_near_shop()
	_connect_boss_controller_signals()
	_setup_start_area_air_walls()
	_create_floor_overlay()
	_initialize_floor_progression()
	_move_hero_to_start_point()

	hero = _get_current_hero()
	if hero != null and camera != null:
		_focus_camera_on(hero.global_position, camera)
	_show_hero_select_ui()


func _setup_battle_map_layout() -> void:
	if _battle_map_layout_applied:
		return

	var map_size := Vector2(maxf(battle_map_size_xz.x, 100.0), maxf(battle_map_size_xz.y, 100.0))
	var map_center := Vector3(
		battle_map_origin_xz.x + map_size.x * 0.5, 0.0, battle_map_origin_xz.y + map_size.y * 0.5
	)

	_shift_initial_battle_map_content(map_center)
	_configure_battle_map_floor(map_center, map_size)
	_setup_outside_region_fill(map_size)
	_rebuild_battle_map_obstacles(map_size)
	_battle_map_layout_applied = true
	_request_navigation_rebake()


func _request_navigation_rebake() -> void:
	if _nav_rebake_queued:
		return
	var nav_region := get_node_or_null(navigation_region_path) as NavigationRegion3D
	if nav_region == null:
		return
	_nav_rebake_queued = true
	call_deferred("_rebake_navigation_region_deferred")


func _rebake_navigation_region_deferred() -> void:
	_nav_rebake_queued = false
	var nav_region := get_node_or_null(navigation_region_path) as NavigationRegion3D
	if nav_region == null:
		return
	nav_region.bake_navigation_mesh()


func _shift_initial_battle_map_content(offset: Vector3) -> void:
	var candidate_paths: Array[NodePath] = [
		navigation_region_path,
		hero_controller_path,
		NodePath("EnemyAI"),
		NodePath("TaurenSpawner"),
		camera_path,
		NodePath("DirectionalLight3D")
	]
	var shifted_ids: Dictionary = {}
	for path in candidate_paths:
		var node := get_node_or_null(path) as Node3D
		if node == null:
			continue
		var node_id: int = node.get_instance_id()
		if shifted_ids.has(node_id):
			continue
		node.global_position += offset
		shifted_ids[node_id] = true


func _configure_battle_map_floor(map_center: Vector3, map_size: Vector2) -> void:
	var floor := get_node_or_null("Floor") as MeshInstance3D
	if floor != null:
		var floor_mesh := floor.mesh as PlaneMesh
		if floor_mesh != null:
			floor_mesh.size = map_size
		var floor_pos := floor.global_position
		floor.global_position = Vector3(map_center.x, floor_pos.y, map_center.z)
		var floor_material := floor.get_surface_override_material(0) as StandardMaterial3D
		if floor_material != null:
			floor_material.uv1_scale = Vector3(
				maxf(map_size.x / 500.0, 1.0), maxf(map_size.y / 500.0, 1.0), 1.0
			)

	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	if nav_root == null:
		return
	var floor_collision := nav_root.get_node_or_null("FloorBody/FloorCollision") as CollisionShape3D
	if floor_collision == null:
		return
	var floor_shape := floor_collision.shape as BoxShape3D
	if floor_shape == null:
		return
	floor_shape.size = Vector3(map_size.x, maxf(floor_shape.size.y, 2.0), map_size.y)


func _setup_outside_region_fill(map_size: Vector2) -> void:
	var old_fill := get_node_or_null("OutsideRegionFill") as MeshInstance3D
	if not outside_region_fill_visible:
		if old_fill != null:
			old_fill.queue_free()
		return

	var battle_min_x: float = battle_map_origin_xz.x
	var battle_max_x: float = battle_map_origin_xz.x + map_size.x
	var battle_min_z: float = battle_map_origin_xz.y
	var battle_max_z: float = battle_map_origin_xz.y + map_size.y

	var start_center: Vector3 = _compute_start_area_center()
	var start_bounds: Dictionary = _compute_start_area_bounds()
	var bound_half_x: float = float(start_bounds.get("bound_half_x", _get_shop_half_size_x()))
	var north_depth: float = float(start_bounds.get("north_depth", _get_shop_half_size_z()))
	var south_depth: float = float(start_bounds.get("south_depth", _get_shop_half_size_z()))
	var thickness: float = float(
		start_bounds.get("thickness", maxf(start_area_wall_thickness, 20.0))
	)
	var margin: float = maxf(start_area_floor_extra_margin, 0.0)
	var start_half_width: float = bound_half_x + margin + thickness * 0.5
	var start_half_depth: float = (north_depth + south_depth + margin * 2.0 + thickness) * 0.5
	var start_center_z: float = start_center.z + (south_depth - north_depth) * 0.5

	var fill_margin: float = maxf(outside_region_fill_margin, 0.0)
	var fill_min_x: float = minf(battle_min_x, start_center.x - start_half_width) - fill_margin
	var fill_max_x: float = maxf(battle_max_x, start_center.x + start_half_width) + fill_margin
	var fill_min_z: float = minf(battle_min_z, start_center_z - start_half_depth) - fill_margin
	var fill_max_z: float = maxf(battle_max_z, start_center_z + start_half_depth) + fill_margin
	var fill_size := Vector2(
		maxf(fill_max_x - fill_min_x, 64.0), maxf(fill_max_z - fill_min_z, 64.0)
	)
	var fill_center := Vector3(
		(fill_min_x + fill_max_x) * 0.5, 0.0, (fill_min_z + fill_max_z) * 0.5
	)

	var floor := get_node_or_null("Floor") as MeshInstance3D
	var floor_y: float = -0.5
	if floor != null:
		floor_y = floor.global_position.y
	fill_center.y = floor_y - maxf(outside_region_fill_below_floor_offset, 0.01)

	var fill := old_fill
	if fill == null:
		fill = MeshInstance3D.new()
		fill.name = "OutsideRegionFill"
		fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fill)

	var mesh := PlaneMesh.new()
	mesh.size = fill_size
	fill.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = outside_region_fill_color
	material.roughness = 1.0
	fill.material_override = material
	fill.global_position = fill_center


func _rebuild_battle_map_obstacles(map_size: Vector2) -> void:
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	if nav_root == null:
		return
	var obstacles_root := nav_root.get_node_or_null("Obstacles") as Node3D
	if obstacles_root == null:
		obstacles_root = Node3D.new()
		obstacles_root.name = "Obstacles"
		nav_root.add_child(obstacles_root)

	_remove_obstacle_nodes_by_prefix(obstacles_root, "Fence")
	var old_bounds := obstacles_root.get_node_or_null("BattleMapBounds")
	if old_bounds != null:
		old_bounds.free()
	var old_lines := obstacles_root.get_node_or_null("BattleFenceLines")
	if old_lines != null:
		old_lines.free()

	_build_battle_map_bounds(obstacles_root, map_size)
	_build_battle_map_fence_lines(obstacles_root)


func _remove_obstacle_nodes_by_prefix(obstacles_root: Node3D, name_prefix: String) -> void:
	if obstacles_root == null:
		return
	var pending_free: Array[Node] = []
	for child_variant in obstacles_root.get_children():
		var child := child_variant as Node
		if child == null:
			continue
		if child.name.begins_with(name_prefix):
			pending_free.append(child)
	for child in pending_free:
		child.free()


func _build_battle_map_bounds(obstacles_root: Node3D, map_size: Vector2) -> void:
	if obstacles_root == null:
		return
	var bounds_root := Node3D.new()
	bounds_root.name = "BattleMapBounds"
	obstacles_root.add_child(bounds_root)

	var thickness: float = maxf(battle_map_boundary_thickness, 20.0)
	var wall_height: float = maxf(battle_map_boundary_height, 120.0)
	var y_center: float = wall_height * 0.5
	var min_x: float = battle_map_origin_xz.x
	var max_x: float = battle_map_origin_xz.x + map_size.x
	var min_z: float = battle_map_origin_xz.y
	var max_z: float = battle_map_origin_xz.y + map_size.y
	var center_x: float = (min_x + max_x) * 0.5
	var center_z: float = (min_z + max_z) * 0.5

	_create_invisible_wall(
		bounds_root,
		"SouthBoundary",
		Vector3(center_x, y_center, min_z - thickness * 0.5),
		Vector3(map_size.x, wall_height, thickness)
	)
	_create_invisible_wall(
		bounds_root,
		"NorthBoundary",
		Vector3(center_x, y_center, max_z + thickness * 0.5),
		Vector3(map_size.x, wall_height, thickness)
	)
	_create_invisible_wall(
		bounds_root,
		"WestBoundary",
		Vector3(min_x - thickness * 0.5, y_center, center_z),
		Vector3(thickness, wall_height, map_size.y)
	)
	_create_invisible_wall(
		bounds_root,
		"EastBoundary",
		Vector3(max_x + thickness * 0.5, y_center, center_z),
		Vector3(thickness, wall_height, map_size.y)
	)


func _create_invisible_wall(
	parent: Node3D, wall_name: String, world_pos: Vector3, box_size: Vector3
) -> void:
	if parent == null:
		return
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	body.global_position = world_pos

	var shape := BoxShape3D.new()
	shape.size = box_size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	if not battle_map_boundary_visible:
		return

	var wall_mesh := MeshInstance3D.new()
	wall_mesh.name = "Visual"
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	wall_mesh.mesh = box_mesh
	wall_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wall_material := StandardMaterial3D.new()
	wall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_material.albedo_color = battle_map_boundary_color
	wall_mesh.material_override = wall_material
	body.add_child(wall_mesh)


func _build_battle_map_fence_lines(obstacles_root: Node3D) -> void:
	if obstacles_root == null:
		return
	var fences_root := Node3D.new()
	fences_root.name = "BattleFenceLines"
	obstacles_root.add_child(fences_root)

	_build_battle_map_fence_segment(
		fences_root,
		Vector2(battle_map_fence_line_start_x, battle_map_fence_line_z_a),
		Vector2(battle_map_fence_line_end_x, battle_map_fence_line_z_a),
		battle_map_fence_horizontal_yaw_degrees
	)
	_build_battle_map_fence_segment(
		fences_root,
		Vector2(battle_map_fence_line_start_x, battle_map_fence_line_z_b),
		Vector2(battle_map_fence_line_end_x, battle_map_fence_line_z_b),
		battle_map_fence_horizontal_yaw_degrees
	)
	_build_battle_map_fence_segment(
		fences_root,
		Vector2(battle_map_fence_vertical_x, battle_map_fence_vertical_start_z),
		Vector2(battle_map_fence_vertical_x, battle_map_fence_vertical_end_z),
		battle_map_fence_vertical_yaw_degrees
	)


func _build_battle_map_fence_segment(
	parent: Node3D, from_xz: Vector2, to_xz: Vector2, yaw_degrees: float
) -> void:
	if parent == null:
		return
	var delta: Vector2 = to_xz - from_xz
	var total_length: float = delta.length()
	if total_length <= 0.01:
		_create_battle_map_fence(parent, Vector3(from_xz.x, 0.0, from_xz.y), yaw_degrees)
		return
	var fence_scale_multiplier: float = maxf(battle_map_fence_scale_multiplier, 0.01)
	var spacing: float = maxf(battle_map_fence_spacing * fence_scale_multiplier, 1.0)
	var direction: Vector2 = delta / total_length
	var traveled: float = 0.0
	while traveled <= total_length + 0.01:
		var pos_xz: Vector2 = from_xz + direction * minf(traveled, total_length)
		_create_battle_map_fence(parent, Vector3(pos_xz.x, 0.0, pos_xz.y), yaw_degrees)
		traveled += spacing
	var last_step: float = maxf(traveled - spacing, 0.0)
	if absf(last_step - total_length) > 0.01:
		_create_battle_map_fence(parent, Vector3(to_xz.x, 0.0, to_xz.y), yaw_degrees)


func _create_battle_map_fence(parent: Node3D, world_pos: Vector3, yaw_degrees: float) -> void:
	if parent == null:
		return
	var fence_scale_multiplier: float = maxf(battle_map_fence_scale_multiplier, 0.01)
	var fence_root := Node3D.new()
	fence_root.name = "Fence_%d_%d" % [roundi(world_pos.x), roundi(world_pos.z)]
	parent.add_child(fence_root)
	fence_root.global_position = world_pos

	if battle_map_fence_scene != null:
		var model := battle_map_fence_scene.instantiate()
		if model != null:
			model.name = "Model"
			if model is Node3D:
				var model_node := model as Node3D
				model_node.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
				model_node.scale = Vector3.ONE * fence_scale_multiplier
			_disable_collision_on_model(model)
			fence_root.add_child(model)

	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	fence_root.add_child(body)

	var shape := BoxShape3D.new()
	shape.size = battle_map_fence_collision_size * fence_scale_multiplier
	var collision := CollisionShape3D.new()
	collision.name = "Col"
	collision.shape = shape
	collision.position = Vector3(
		0.0, maxf(battle_map_fence_height_offset * fence_scale_multiplier, shape.size.y * 0.5), 0.0
	)
	collision.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	body.add_child(collision)


func _input(event: InputEvent) -> void:
	if not _hero_selected:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and (key_event.keycode == KEY_1 or key_event.keycode == KEY_KP_1)
		):
			var now_ms: int = Time.get_ticks_msec()
			var elapsed_ms: int = now_ms - _last_refocus_key_time_ms
			_last_refocus_key_time_ms = now_ms
			if elapsed_ms <= maxi(camera_refocus_double_tap_ms, 1):
				_refocus_camera_to_hero()
			return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_adjust_camera_height(-absf(camera_height_wheel_step))
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_adjust_camera_height(absf(camera_height_wheel_step))


func _refocus_camera_to_hero() -> void:
	var camera := get_node_or_null(camera_path) as Camera3D
	var hero := _get_current_hero()
	if camera == null or hero == null:
		return
	_focus_camera_on(hero.global_position, camera)
	_reset_ui_observe_to_self()


func _reset_ui_observe_to_self() -> void:
	var net_ctrl := get_node_or_null(net_session_controller_path) as NetSessionController
	if net_ctrl != null:
		net_ctrl.focus_ui_on_self()
		return
	var ui := get_node_or_null(game_ui_path) as GameUI
	if ui != null:
		ui.set_observed_peer(0)


func _adjust_camera_height(delta_y: float) -> void:
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		return
	var min_h: float = minf(camera_height_min, camera_height_max)
	var max_h: float = maxf(camera_height_min, camera_height_max)
	_camera_height_target = clampf(_camera_height_target + delta_y, min_h, max_h)
	_start_camera_height_tween(camera)


func _start_camera_height_tween(camera: Camera3D) -> void:
	if camera == null:
		return
	if _camera_height_tween != null and _camera_height_tween.is_valid():
		_camera_height_tween.kill()
	var from_h: float = camera.global_position.y
	var to_h: float = _camera_height_target
	if absf(to_h - from_h) <= 0.001:
		_apply_camera_height(to_h)
		return
	var duration: float = maxf(camera_height_anim_duration, 0.01)
	_camera_height_tween = create_tween()
	_camera_height_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_height_tween.tween_method(
		Callable(self, "_apply_camera_height"), from_h, to_h, duration
	)


func _apply_camera_height(height: float) -> void:
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		return
	var pos: Vector3 = camera.global_position
	pos.y = height
	camera.global_position = pos
	var hero := _get_current_hero()
	if hero != null:
		_camera_offset_from_hero.y = height - hero.global_position.y


func _process(delta: float) -> void:
	_poll_shop_owner_binding(delta)
	_process_floor_clear_resolution()
	if not _hero_selected:
		return
	if not edge_scroll_enabled:
		return
	var camera := get_node_or_null(camera_path) as Camera3D
	if camera == null:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var view_size: Vector2 = viewport.get_visible_rect().size
	if view_size.x <= 1.0 or view_size.y <= 1.0:
		return
	var mouse_pos: Vector2 = viewport.get_mouse_position()

	var margin: float = float(maxi(edge_scroll_margin_px, 1))
	var planar_right: Vector3 = camera.global_basis.x
	planar_right.y = 0.0
	planar_right = planar_right.normalized()
	var planar_forward: Vector3 = -camera.global_basis.z
	planar_forward.y = 0.0
	planar_forward = planar_forward.normalized()
	if planar_right.length() <= 0.001 or planar_forward.length() <= 0.001:
		return

	var left_strength: float = clampf((margin - mouse_pos.x) / margin, 0.0, 1.0)
	var right_strength: float = clampf((mouse_pos.x - (view_size.x - margin)) / margin, 0.0, 1.0)
	var top_strength: float = clampf((margin - mouse_pos.y) / margin, 0.0, 1.0)
	var bottom_strength: float = clampf((mouse_pos.y - (view_size.y - margin)) / margin, 0.0, 1.0)

	var move_axis := Vector2(right_strength - left_strength, top_strength - bottom_strength)
	if move_axis.length() <= 0.001:
		return

	var move_dir: Vector3 = planar_right * move_axis.x + planar_forward * move_axis.y
	if move_dir.length() <= 0.001:
		return
	move_dir = move_dir.normalized()

	var intensity: float = clampf(move_axis.length(), 0.0, 1.0)
	intensity = pow(intensity, maxf(edge_scroll_accel_curve, 0.01))
	camera.global_position += move_dir * edge_scroll_speed * intensity * delta


func _get_hero_controller() -> HeroController:
	return get_node_or_null(hero_controller_path) as HeroController


func _get_current_hero() -> Node3D:
	var hero_controller := _get_hero_controller()
	if hero_controller != null:
		var hero_variant: Variant = hero_controller.get("_hero")
		if hero_variant is Node3D:
			var hero_node := hero_variant as Node3D
			if hero_node != null and is_instance_valid(hero_node):
				return hero_node
	var fallback := get_node_or_null(hero_path) as Node3D
	if fallback != null and is_instance_valid(fallback):
		return fallback
	return null


func _set_hero_control_enabled(enabled: bool) -> void:
	var hero_controller := _get_hero_controller()
	if hero_controller == null:
		return
	hero_controller.set_process(enabled)
	hero_controller.set_process_input(enabled)


func _notify_network_hero_selection_confirmed(confirmed: bool) -> void:
	var net_ctrl := get_node_or_null(net_session_controller_path) as NetSessionController
	if net_ctrl == null:
		return
	net_ctrl.notify_local_hero_selection_confirmed(bool(confirmed))


func _show_hero_select_ui() -> void:
	_set_hero_control_enabled(false)
	_hero_selected = false
	var hero_controller := _get_hero_controller()
	if hero_controller != null:
		hero_controller.set("hero_selection_confirmed", false)
	_notify_network_hero_selection_confirmed(false)
	if _hero_select_layer != null and is_instance_valid(_hero_select_layer):
		_hero_select_layer.queue_free()

	_hero_select_layer = CanvasLayer.new()
	_hero_select_layer.name = "HeroSelectLayer"
	add_child(_hero_select_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_hero_select_layer.add_child(root)

	var mask := ColorRect.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.color = Color(0.0, 0.0, 0.0, 0.62)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(mask)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -110
	panel.offset_bottom = 110
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.07, 0.12, 0.96)
	panel_style.border_color = Color(0.78, 0.66, 0.2, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 16
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "请选择英雄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78, 1.0))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "1号: 守望者    2号: 火枪手"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	vbox.add_child(hint)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 18)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var melee_btn := Button.new()
	melee_btn.text = "1号 %s" % melee_hero_name
	melee_btn.custom_minimum_size = Vector2(160, 52)
	melee_btn.pressed.connect(func() -> void: _on_hero_selected(false))
	btn_row.add_child(melee_btn)

	var ranged_btn := Button.new()
	ranged_btn.text = "2号 %s" % ranged_hero_name
	ranged_btn.custom_minimum_size = Vector2(160, 52)
	ranged_btn.pressed.connect(func() -> void: _on_hero_selected(true))
	btn_row.add_child(ranged_btn)


func _on_hero_selected(use_ranged: bool) -> void:
	var hero_controller := _get_hero_controller()
	if hero_controller != null:
		hero_controller.apply_hero_profile_by_id(2 if use_ranged else 1)
		if use_ranged:
			hero_controller.select_hero_model(ranged_hero_scene, ranged_hero_name)
		else:
			hero_controller.select_hero_model(melee_hero_scene, melee_hero_name)

	_move_hero_to_start_point()
	var camera := get_node_or_null(camera_path) as Camera3D
	var hero := _get_current_hero()
	if camera != null and hero != null:
		_focus_camera_on(hero.global_position, camera)

	if _hero_select_layer != null and is_instance_valid(_hero_select_layer):
		_hero_select_layer.queue_free()
	_hero_select_layer = null
	_hero_selected = true
	if hero_controller != null:
		hero_controller.set("hero_selection_confirmed", true)
	_notify_network_hero_selection_confirmed(true)
	_set_hero_control_enabled(true)


func _move_shop_to_start_point() -> void:
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	var shop := get_node_or_null(shop_path) as Node3D
	_start_area_center = _compute_start_area_center()
	_has_start_area_center = true
	_shop_cluster_positions = _build_shop_cluster_positions(_start_area_center)
	_shop_owner_peer_ids = _resolve_shop_owner_peer_ids(_shop_cluster_positions.size())
	_shop_owner_binding_poll_elapsed = 0.0
	if nav_root == null or shop == null:
		return
	_clear_generated_shop_clones(nav_root)
	if _shop_cluster_positions.is_empty():
		shop.global_position = _start_area_center
		_apply_shop_owner_metadata(shop, _resolve_shop_owner_peer_id_by_slot(0), 0)
		_request_navigation_rebake()
		return
	var base_transform: Transform3D = shop.global_transform
	shop.global_position = _shop_cluster_positions[0]
	_apply_shop_owner_metadata(shop, _resolve_shop_owner_peer_id_by_slot(0), 0)
	for i in range(1, _shop_cluster_positions.size()):
		var clone_variant: Variant = shop.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
		if not (clone_variant is Node3D):
			continue
		var clone_shop: Node3D = clone_variant as Node3D
		clone_shop.name = "ShopCluster_%d" % i
		nav_root.add_child(clone_shop)
		clone_shop.global_transform = base_transform
		clone_shop.global_position = _shop_cluster_positions[i]
		_apply_shop_owner_metadata(clone_shop, _resolve_shop_owner_peer_id_by_slot(i), i)
	_refresh_shop_owner_bindings(true)
	_request_navigation_rebake()


func _spawn_gate_near_shop() -> void:
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	if nav_root == null:
		return

	var old_gate := nav_root.get_node_or_null("CityEnteranceGate")
	if old_gate != null:
		old_gate.queue_free()

	var gate := Node3D.new()
	gate.name = "CityEnteranceGate"
	gate.set_script(GATE_SCRIPT)
	gate.set("max_hp", maxi(gate_max_hp, 1))
	nav_root.add_child(gate)
	gate.global_position = _get_gate_spawn_position()

	var gate_body := Node3D.new()
	gate_body.name = "GateBody"
	gate_body.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	gate.add_child(gate_body)

	if gate_scene != null:
		var gate_model := gate_scene.instantiate()
		if gate_model != null:
			gate_model.name = "Model"
			if gate_model is Node3D:
				(gate_model as Node3D).scale = gate_model_scale
			_disable_collision_on_model(gate_model)
			gate_body.add_child(gate_model)

	var collision_body := StaticBody3D.new()
	collision_body.name = "CollisionBody"
	collision_body.add_to_group("enemy")
	gate_body.add_child(collision_body)

	var shape := BoxShape3D.new()
	shape.size = gate_collider_size
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_shape.shape = shape
	collision_shape.position = Vector3(0.0, gate_collider_size.y * 0.5, 0.0)
	collision_body.add_child(collision_shape)

	if gate.has_signal("gate_destroyed"):
		gate.connect("gate_destroyed", Callable(self, "_on_gate_destroyed"))
	_request_navigation_rebake()


func _connect_boss_controller_signals() -> void:
	var boss_model := get_node_or_null(boss_path) as Node3D
	if boss_model == null:
		return
	var boss_controller: Node = boss_model.get_parent()
	if boss_controller == null:
		return
	if (
		boss_controller.has_signal("boss_defeated")
		and not boss_controller.is_connected("boss_defeated", Callable(self, "_on_boss_defeated"))
	):
		boss_controller.connect("boss_defeated", Callable(self, "_on_boss_defeated"))


func _initialize_floor_progression() -> void:
	_run_completed = false
	_awaiting_floor_clear = false
	_current_floor_index = clampi(starting_floor_index, 1, maxi(total_floor_count, 1))
	_apply_floor_state_locally(_current_floor_index, true)


func _build_current_floor_profile() -> Dictionary:
	return FLOOR_BALANCE_SCRIPT.build_floor_profile(_current_floor_index, floor_difficulty)


func _apply_floor_state_locally(floor_index: int, reset_units: bool) -> void:
	_current_floor_index = clampi(floor_index, 1, maxi(total_floor_count, 1))
	var profile: Dictionary = FLOOR_BALANCE_SCRIPT.build_floor_profile(
		_current_floor_index, floor_difficulty
	)
	if reset_units:
		_configure_floor_randomized_hostiles(_current_floor_index)
	var boss_controller: EnemyAI = _get_boss_controller_node()
	if boss_controller != null:
		boss_controller.apply_floor_profile(profile, reset_units)
	var spawner: TaurenSpawner = get_node_or_null(NodePath("TaurenSpawner")) as TaurenSpawner
	if spawner != null:
		var should_spawn_local_mobs: bool = not (
			_network_role == "client" and multiplayer.multiplayer_peer != null
		)
		if reset_units and should_spawn_local_mobs:
			spawner.reset_for_floor(profile)
		elif reset_units:
			spawner.clear_units()
		else:
			spawner.apply_floor_profile(profile)
	_apply_shop_availability_for_floor(_current_floor_index)
	_refresh_floor_overlay()


func _create_floor_overlay() -> void:
	if not floor_overlay_enabled:
		return
	if _floor_overlay_layer != null and is_instance_valid(_floor_overlay_layer):
		return
	_floor_overlay_layer = CanvasLayer.new()
	_floor_overlay_layer.name = "FloorOverlayLayer"
	_floor_overlay_layer.layer = 15
	add_child(_floor_overlay_layer)
	var label := Label.new()
	label.name = "FloorOverlayLabel"
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 18.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	_floor_overlay_layer.add_child(label)
	_floor_overlay_label = label


func _refresh_floor_overlay() -> void:
	if _floor_overlay_label == null or not is_instance_valid(_floor_overlay_label):
		return
	var total_floors: int = maxi(total_floor_count, 1)
	var difficulty_name: String = FLOOR_BALANCE_SCRIPT.get_difficulty_display_name(floor_difficulty)
	if _run_completed:
		_floor_overlay_label.text = "Floor %d / %d  Cleared" % [total_floors, total_floors]
		return
	_floor_overlay_label.text = (
		"Floor %d / %d  %s" % [_current_floor_index, total_floors, difficulty_name]
	)


func _process_floor_clear_resolution() -> void:
	if not _awaiting_floor_clear:
		return
	if _network_role == "client":
		return
	if not _are_all_hostiles_cleared():
		return
	_finalize_floor_clear()


func _are_all_hostiles_cleared() -> bool:
	var boss_controller: EnemyAI = _get_boss_controller_node()
	if boss_controller != null and not bool(boss_controller.is_dead()):
		return false
	var spawner: TaurenSpawner = get_node_or_null(NodePath("TaurenSpawner")) as TaurenSpawner
	if spawner != null:
		if bool(spawner.has_living_units()):
			return false
	return true


func _finalize_floor_clear() -> void:
	_awaiting_floor_clear = false
	_boss_battle_started = false
	var next_floor_index: int = _current_floor_index + 1
	var has_next_floor: bool = next_floor_index <= maxi(total_floor_count, 1)
	if _is_reward_enabled_after_floor_clear(_current_floor_index):
		_apply_floor_clear_rewards()
	if _network_role == "host" and multiplayer.multiplayer_peer != null:
		if _is_reward_enabled_after_floor_clear(_current_floor_index):
			rpc("rpc_floor_clear_local_feedback")
		if has_next_floor:
			rpc("rpc_prepare_next_floor", next_floor_index)
		else:
			rpc("rpc_complete_floor_run")
	if has_next_floor:
		_prepare_next_floor_locally(next_floor_index)
	else:
		_complete_run_locally()


func _apply_floor_clear_rewards() -> void:
	var ui := get_node_or_null(game_ui_path) as GameUI
	if ui == null:
		return
	var net_ctrl := get_node_or_null(net_session_controller_path) as NetSessionController
	ui.notify_local_battle_phase_ended()
	var player_ids: Array[int] = _collect_active_peer_ids_for_boss_entry()
	for peer_id in player_ids:
		if peer_id <= 0:
			continue
		if peer_id != _resolve_local_shop_owner_peer_id():
			var baseline_state: Dictionary = {}
			if net_ctrl != null:
				var baseline_variant: Variant = net_ctrl.get_ui_peer_equipment_state(peer_id)
				if baseline_variant is Dictionary:
					baseline_state = (baseline_variant as Dictionary).duplicate(true)
			var request: Dictionary = {
				"action": "battle_phase_ended", "request_seq": -1, "payload": {}
			}
			var commit_variant: Variant = ui.authority_handle_equipment_action(
				peer_id, request, baseline_state
			)
			if commit_variant is Dictionary:
				var commit: Dictionary = commit_variant
				var state_variant: Variant = commit.get("state", null)
				if state_variant is Dictionary and net_ctrl != null:
					net_ctrl.host_override_peer_equipment_state(
						peer_id, state_variant as Dictionary
					)
		var reward_gold: int = _get_floor_clear_gold_reward(peer_id)
		if reward_gold <= 0:
			continue
		var reward_state_variant: Variant = ui.authority_grant_gold_reward(peer_id, reward_gold)
		if (
			reward_state_variant is Dictionary
			and peer_id != _resolve_local_shop_owner_peer_id()
			and net_ctrl != null
		):
			net_ctrl.host_override_peer_equipment_state(peer_id, reward_state_variant as Dictionary)


func _get_floor_clear_gold_reward(peer_id: int) -> int:
	var base_reward: int = FLOOR_BALANCE_SCRIPT.get_round_clear_base_gold(_current_floor_index)
	var reward_total: int = base_reward
	if _is_peer_alive_for_floor_reward(peer_id):
		reward_total += FLOOR_BALANCE_SCRIPT.get_round_clear_survivor_bonus()
	return reward_total


func _is_peer_alive_for_floor_reward(peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	if multiplayer.multiplayer_peer != null:
		var local_peer_id: int = multiplayer.get_unique_id()
		if peer_id == local_peer_id:
			var hero_controller: HeroController = _get_hero_controller()
			if hero_controller != null:
				return not bool(hero_controller.is_dead())
			return true
	var net_ctrl := get_node_or_null(net_session_controller_path) as NetSessionController
	if net_ctrl != null:
		var hero_state_variant: Variant = net_ctrl.get_ui_peer_hero_state(peer_id)
		if hero_state_variant is Dictionary:
			var hero_state: Dictionary = hero_state_variant
			return not bool(hero_state.get("is_dead", false))
	return true


@rpc("authority", "call_remote", "reliable")
func rpc_floor_clear_local_feedback() -> void:
	var ui := get_node_or_null(game_ui_path) as GameUI
	if ui != null:
		ui.apply_local_floor_clear_progression()


func _get_boss_controller_node() -> EnemyAI:
	var boss_model := get_node_or_null(boss_path) as Node3D
	if boss_model == null:
		return null
	return boss_model.get_parent() as EnemyAI


func _configure_floor_randomized_hostiles(floor_index: int) -> void:
	var boss_rng := RandomNumberGenerator.new()
	boss_rng.seed = _build_battle_map_spawn_seed(floor_index, 11)
	var boss_controller: EnemyAI = _get_boss_controller_node()
	if boss_controller != null:
		var boss_pos := _pick_random_battle_map_position(
			boss_rng, maxf(battle_map_boss_spawn_margin, 0.0)
		)
		var boss_yaw: float = boss_rng.randf_range(-PI, PI)
		boss_controller.set_spawn_origin(boss_pos, boss_yaw, true)

	var spawner := get_node_or_null(NodePath("TaurenSpawner")) as TaurenSpawner
	if spawner != null:
		var spawner_rng := RandomNumberGenerator.new()
		spawner_rng.seed = _build_battle_map_spawn_seed(floor_index, 29)
		spawner.global_position = _pick_random_battle_map_position(
			spawner_rng, maxf(battle_map_mob_spawn_margin, 0.0)
		)
		spawner.configure_spawn_rect(
			battle_map_origin_xz,
			_get_battle_map_size(),
			_build_battle_map_spawn_seed(floor_index, 97),
			maxf(battle_map_mob_spawn_margin, 0.0)
		)


func _build_battle_map_spawn_seed(floor_index: int, salt: int) -> int:
	var seed_text: String = (
		"battle_spawn_%d_%d_%d" % [battle_map_spawn_seed_base, floor_index, salt]
	)
	var seed: int = int(hash(seed_text)) & 0x7fffffff
	if seed <= 0:
		return 1
	return seed


func _get_battle_map_size() -> Vector2:
	return Vector2(maxf(battle_map_size_xz.x, 100.0), maxf(battle_map_size_xz.y, 100.0))


func _pick_random_battle_map_position(rng: RandomNumberGenerator, margin: float = 0.0) -> Vector3:
	var safe_rng := rng
	if safe_rng == null:
		safe_rng = RandomNumberGenerator.new()
		safe_rng.randomize()
	var map_size := _get_battle_map_size()
	var safe_margin_x: float = minf(maxf(margin, 0.0), map_size.x * 0.45)
	var safe_margin_z: float = minf(maxf(margin, 0.0), map_size.y * 0.45)
	var min_x: float = battle_map_origin_xz.x + safe_margin_x
	var max_x: float = battle_map_origin_xz.x + map_size.x - safe_margin_x
	var min_z: float = battle_map_origin_xz.y + safe_margin_z
	var max_z: float = battle_map_origin_xz.y + map_size.y - safe_margin_z
	return Vector3(
		safe_rng.randf_range(min_x, maxf(min_x, max_x)),
		0.0,
		safe_rng.randf_range(min_z, maxf(min_z, max_z))
	)


func _is_reward_enabled_after_floor_clear(floor_index: int) -> bool:
	return floor_index < maxi(reward_last_floor_index + 1, 1)


func _is_shop_enabled_for_floor(floor_index: int) -> bool:
	return floor_index <= maxi(shop_last_floor_index, 0)


func _apply_shop_availability_for_floor(floor_index: int) -> void:
	var enabled: bool = _is_shop_enabled_for_floor(floor_index)
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	var primary_shop := get_node_or_null(shop_path) as Node3D
	if nav_root != null and primary_shop != null:
		for slot_index in range(_shop_cluster_positions.size()):
			var shop_root: Node3D = _get_shop_root_for_slot(nav_root, primary_shop, slot_index)
			if shop_root == null:
				continue
			var owner_peer_id: int = 0
			if enabled:
				owner_peer_id = _resolve_shop_owner_peer_id_by_slot(slot_index)
			_apply_shop_root_availability(shop_root, enabled, owner_peer_id, slot_index)
	var ui := get_node_or_null(game_ui_path) as GameUI
	if ui != null:
		ui.set_shop_access_enabled(enabled)


func _apply_shop_root_availability(
	shop_root: Node, enabled: bool, owner_peer_id: int, slot_index: int
) -> void:
	if shop_root == null:
		return
	_apply_shop_root_availability_recursive(shop_root, enabled, owner_peer_id, slot_index)


func _apply_shop_root_availability_recursive(
	node: Node, enabled: bool, owner_peer_id: int, slot_index: int
) -> void:
	if node == null:
		return
	if node is Node3D:
		(node as Node3D).visible = enabled
	node.set_meta(SHOP_OWNER_META_KEY, owner_peer_id if enabled else 0)
	node.set_meta(SHOP_SLOT_META_KEY, slot_index if enabled else -1)
	var collision_node: CollisionObject3D = node as CollisionObject3D
	if collision_node != null:
		if enabled:
			if collision_node.has_meta(SHOP_COLLISION_LAYER_META_KEY):
				collision_node.collision_layer = int(
					collision_node.get_meta(SHOP_COLLISION_LAYER_META_KEY)
				)
			if collision_node.has_meta(SHOP_COLLISION_MASK_META_KEY):
				collision_node.collision_mask = int(
					collision_node.get_meta(SHOP_COLLISION_MASK_META_KEY)
				)
			collision_node.collision_layer = SHOP_INTERACTION_ONLY_LAYER
			collision_node.collision_mask = 0
		else:
			if not collision_node.has_meta(SHOP_COLLISION_LAYER_META_KEY):
				collision_node.set_meta(
					SHOP_COLLISION_LAYER_META_KEY, collision_node.collision_layer
				)
			if not collision_node.has_meta(SHOP_COLLISION_MASK_META_KEY):
				collision_node.set_meta(SHOP_COLLISION_MASK_META_KEY, collision_node.collision_mask)
			collision_node.collision_layer = 0
			collision_node.collision_mask = 0
	for child_variant in node.get_children():
		var child: Node = child_variant as Node
		if child != null:
			_apply_shop_root_availability_recursive(child, enabled, owner_peer_id, slot_index)


func _prepare_next_floor_locally(next_floor_index: int) -> void:
	_run_completed = false
	_boss_battle_started = false
	_awaiting_floor_clear = false
	var hero_controller := _get_hero_controller()
	if hero_controller != null:
		hero_controller.prepare_for_next_floor()
	_move_hero_to_start_point()
	var camera := get_node_or_null(camera_path) as Camera3D
	var hero := _get_current_hero()
	if camera != null and hero != null:
		_focus_camera_on(hero.global_position, camera)
	_spawn_gate_near_shop()
	_connect_boss_controller_signals()
	_apply_floor_state_locally(next_floor_index, true)


func _complete_run_locally() -> void:
	_run_completed = true
	_boss_battle_started = false
	_awaiting_floor_clear = false
	var hero_controller := _get_hero_controller()
	if hero_controller != null:
		hero_controller.prepare_for_next_floor()
	var spawner := get_node_or_null(NodePath("TaurenSpawner")) as TaurenSpawner
	if spawner != null:
		spawner.clear_units()
	_move_hero_to_start_point()
	var camera := get_node_or_null(camera_path) as Camera3D
	var hero := _get_current_hero()
	if camera != null and hero != null:
		_focus_camera_on(hero.global_position, camera)
	_refresh_floor_overlay()


@rpc("authority", "call_remote", "reliable")
func rpc_prepare_next_floor(next_floor_index: int) -> void:
	_prepare_next_floor_locally(next_floor_index)


@rpc("authority", "call_remote", "reliable")
func rpc_complete_floor_run() -> void:
	_complete_run_locally()


func _compute_start_area_center() -> Vector3:
	var planar_dir: Vector3 = start_area_shift_direction
	planar_dir.y = 0.0
	if planar_dir.length_squared() <= 0.0001:
		planar_dir = Vector3(-1.0, 0.0, -1.0)
	planar_dir = planar_dir.normalized()
	var shift_dist: float = maxf(start_area_shift_distance, 0.0)
	var center: Vector3 = start_point + planar_dir * shift_dist
	center.y = start_point.y
	return center


func _get_shop_half_size_x() -> float:
	return maxf(shop_ring_half_size_x, 80.0)


func _get_shop_half_size_z() -> float:
	return maxf(shop_ring_half_size_z, 80.0)


func _build_shop_cluster_positions(center: Vector3) -> Array[Vector3]:
	var half_x: float = _get_shop_half_size_x()
	var half_z: float = _get_shop_half_size_z()
	return [
		center + Vector3(-half_x, 0.0, -half_z),
		center + Vector3(half_x, 0.0, -half_z),
		center + Vector3(half_x, 0.0, half_z),
		center + Vector3(-half_x, 0.0, half_z)
	]


func _clear_generated_shop_clones(nav_root: Node3D) -> void:
	if nav_root == null:
		return
	for child_variant in nav_root.get_children():
		var child: Node = child_variant as Node
		if child == null:
			continue
		if child.name.begins_with("ShopCluster_"):
			child.queue_free()


func _get_gate_spawn_position() -> Vector3:
	var center: Vector3 = _get_shop_center_position()
	var half_z: float = _get_shop_half_size_z()
	var gate_dist: float = maxf(gate_above_shop_distance, 0.0)
	return center + Vector3(0.0, 0.0, -(half_z + gate_dist)) + gate_offset


func _compute_start_area_bounds() -> Dictionary:
	var half_x: float = _get_shop_half_size_x()
	var half_z: float = _get_shop_half_size_z()
	var padding: float = maxf(start_area_wall_padding, 0.0)
	var thickness: float = maxf(start_area_wall_thickness, 20.0)
	var wall_height: float = maxf(start_area_wall_height, 120.0)
	var bound_half_x: float = half_x + padding
	var bound_half_z: float = half_z + padding
	var north_depth: float = bound_half_z
	var south_depth: float = bound_half_z
	var side_depth: float = bound_half_z * 2.0 + thickness * 2.0
	var side_center_z: float = 0.0
	var north_south_width: float = (bound_half_x + thickness) * 2.0
	return {
		"bound_half_x": bound_half_x,
		"bound_half_z": bound_half_z,
		"north_depth": north_depth,
		"south_depth": south_depth,
		"side_depth": side_depth,
		"side_center_z": side_center_z,
		"north_south_width": north_south_width,
		"thickness": thickness,
		"wall_height": wall_height
	}


func _setup_start_area_floor_patch() -> void:
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	if nav_root == null:
		return
	var old_patch := nav_root.get_node_or_null("StartAreaFloorPatch")
	if old_patch != null:
		old_patch.queue_free()
	var floor_texture: Texture2D = _resolve_start_area_floor_texture()
	if floor_texture == null:
		return

	var center: Vector3 = _get_shop_center_position()
	var bounds: Dictionary = _compute_start_area_bounds()
	var bound_half_x: float = float(bounds.get("bound_half_x", _get_shop_half_size_x()))
	var north_depth: float = float(bounds.get("north_depth", _get_shop_half_size_z()))
	var south_depth: float = float(bounds.get("south_depth", _get_shop_half_size_z()))
	var thickness: float = float(bounds.get("thickness", maxf(start_area_wall_thickness, 20.0)))
	var margin: float = maxf(start_area_floor_extra_margin, 0.0)
	var patch_width: float = (bound_half_x + margin + thickness * 0.5) * 2.0
	var patch_depth: float = north_depth + south_depth + margin * 2.0 + thickness
	var patch_center_z: float = (south_depth - north_depth) * 0.5

	var patch := MeshInstance3D.new()
	patch.name = "StartAreaFloorPatch"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(maxf(patch_width, 64.0), maxf(patch_depth, 64.0))
	patch.mesh = mesh
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var material := StandardMaterial3D.new()
	material.albedo_texture = floor_texture
	var uv_tiling: float = maxf(start_area_floor_uv_tiling, 0.01)
	material.uv1_scale = Vector3(uv_tiling, uv_tiling, 1.0)
	material.roughness = 1.0
	patch.material_override = material
	nav_root.add_child(patch)
	patch.global_position = center + Vector3(0.0, start_area_floor_y_offset, patch_center_z)


func _resolve_start_area_floor_texture() -> Texture2D:
	var path: String = start_area_floor_texture_path.strip_edges()
	if path.is_empty():
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("初始化区域地板贴图加载失败或类型错误: %s" % path)
		return null
	return texture


func _setup_start_area_air_walls() -> void:
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	if nav_root == null:
		return
	var obstacles_root := nav_root.get_node_or_null("Obstacles") as Node3D
	if obstacles_root == null:
		obstacles_root = Node3D.new()
		obstacles_root.name = "Obstacles"
		nav_root.add_child(obstacles_root)
	var old_walls := obstacles_root.get_node_or_null("StartAreaAirWalls")
	if old_walls != null:
		old_walls.queue_free()

	var walls_root := Node3D.new()
	walls_root.name = "StartAreaAirWalls"
	obstacles_root.add_child(walls_root)

	var center: Vector3 = _get_shop_center_position()
	var bounds: Dictionary = _compute_start_area_bounds()
	var half_x: float = float(bounds.get("bound_half_x", _get_shop_half_size_x()))
	var north_depth: float = float(bounds.get("north_depth", _get_shop_half_size_z()))
	var south_depth: float = float(bounds.get("south_depth", _get_shop_half_size_z()))
	var side_depth: float = float(bounds.get("side_depth", 0.0))
	var side_center_z: float = float(bounds.get("side_center_z", 0.0))
	var north_south_width: float = float(bounds.get("north_south_width", 0.0))
	var thickness: float = float(bounds.get("thickness", maxf(start_area_wall_thickness, 20.0)))
	var wall_height: float = float(bounds.get("wall_height", maxf(start_area_wall_height, 120.0)))
	var y_center: float = wall_height * 0.5

	_create_air_wall(
		walls_root,
		"NorthWall",
		center + Vector3(0.0, y_center, -(north_depth + thickness * 0.5)),
		Vector3(north_south_width, wall_height, thickness)
	)
	_create_air_wall(
		walls_root,
		"SouthWall",
		center + Vector3(0.0, y_center, south_depth + thickness * 0.5),
		Vector3(north_south_width, wall_height, thickness)
	)
	_create_air_wall(
		walls_root,
		"WestWall",
		center + Vector3(-(half_x + thickness * 0.5), y_center, side_center_z),
		Vector3(thickness, wall_height, side_depth)
	)
	_create_air_wall(
		walls_root,
		"EastWall",
		center + Vector3(half_x + thickness * 0.5, y_center, side_center_z),
		Vector3(thickness, wall_height, side_depth)
	)
	_request_navigation_rebake()


func _create_air_wall(
	parent: Node3D, wall_name: String, world_pos: Vector3, box_size: Vector3
) -> void:
	if parent == null:
		return
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	body.global_position = world_pos

	var shape := BoxShape3D.new()
	shape.size = box_size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	if not start_area_wall_visible:
		return

	var wall_mesh := MeshInstance3D.new()
	wall_mesh.name = "Visual"
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	wall_mesh.mesh = box_mesh
	wall_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wall_material := StandardMaterial3D.new()
	wall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_material.albedo_color = start_area_wall_color
	wall_mesh.material_override = wall_material
	body.add_child(wall_mesh)


func _move_hero_to_start_point() -> void:
	var hero := _get_current_hero()
	if hero == null:
		return
	var target: Vector3 = _get_spawn_position_around_shop()
	target.y = hero.global_position.y
	hero.global_position = target
	_reset_hero_controller_state(target)


func _on_gate_destroyed() -> void:
	if _boss_battle_started:
		return
	_request_navigation_rebake()
	var boss := get_node_or_null(boss_path) as Node3D
	if boss == null:
		return
	var boss_anchor: Vector3 = boss.global_position
	var entry_positions: Dictionary = _build_boss_battle_entry_positions(boss_anchor)
	if _network_role == "host" and multiplayer.multiplayer_peer != null:
		rpc("rpc_start_boss_battle", boss_anchor, entry_positions)
	elif _network_role == "client":
		# 客户端等待 host 广播统一开战时机，避免本地误触发。
		return
	_start_boss_battle_locally(boss_anchor, entry_positions)


@rpc("authority", "call_remote", "reliable")
func rpc_start_boss_battle(boss_anchor: Vector3, entry_positions: Dictionary = {}) -> void:
	_start_boss_battle_locally(boss_anchor, entry_positions)


func _start_boss_battle_locally(boss_anchor: Vector3, entry_positions: Dictionary = {}) -> void:
	if _boss_battle_started:
		return
	var hero := _get_current_hero()
	if hero == null:
		return
	_boss_battle_started = true
	var entry_position := _resolve_local_boss_entry_position(boss_anchor, entry_positions)
	entry_position.y = hero.global_position.y
	hero.global_position = entry_position
	_reset_hero_controller_state(entry_position)

	var camera := get_node_or_null(camera_path) as Camera3D
	if camera != null:
		_focus_camera_on(entry_position, camera)


func _on_boss_defeated() -> void:
	if not _boss_battle_started:
		return
	if _network_role == "client":
		return
	_awaiting_floor_clear = true
	_process_floor_clear_resolution()


@rpc("authority", "call_remote", "reliable")
func rpc_finish_boss_battle() -> void:
	_finish_boss_battle_locally()


func _finish_boss_battle_locally() -> void:
	if not _boss_battle_started:
		return
	_boss_battle_started = false
	_awaiting_floor_clear = false


func _reset_hero_controller_state(hero_position: Vector3) -> void:
	var hero_controller := get_node_or_null(hero_controller_path)
	if hero_controller == null:
		return

	hero_controller._target_enemy = null
	hero_controller._has_move_target = false
	hero_controller._is_moving = false
	hero_controller._is_attacking = false
	hero_controller._focus_lock = false
	hero_controller._flash_mode = false
	hero_controller._attack_mode = false
	hero_controller._target_position = hero_position

	hero_controller._stop_animation()
	hero_controller._push_network_control_command("idle", {"target_pos": hero_position})
	hero_controller._notify_network_local_hero_ready()
	hero_controller.begin_network_attack_lock_after_reposition()


func _focus_camera_on(hero_position: Vector3, camera: Camera3D) -> void:
	var min_h: float = minf(camera_height_min, camera_height_max)
	var max_h: float = maxf(camera_height_min, camera_height_max)
	var focus_offset := _camera_offset_from_hero
	focus_offset.x = 0.0
	var target_pos := hero_position + focus_offset
	target_pos.y = clampf(target_pos.y, min_h, max_h)
	if _camera_height_tween != null and _camera_height_tween.is_valid():
		_camera_height_tween.kill()
	camera.global_position = target_pos
	_camera_height_target = target_pos.y
	_camera_offset_from_hero.x = 0.0
	_camera_offset_from_hero.y = target_pos.y - hero_position.y


func _apply_initial_camera_adjustments(camera: Camera3D, hero: Node3D) -> void:
	if camera == null:
		return
	var reduce_deg: float = absf(camera_tilt_reduce_degrees)
	if reduce_deg > 0.001:
		var rot_deg: Vector3 = camera.rotation_degrees
		if rot_deg.x < 0.0:
			rot_deg.x = minf(rot_deg.x + reduce_deg, 0.0)
		elif rot_deg.x > 0.0:
			rot_deg.x = maxf(rot_deg.x - reduce_deg, 0.0)
		camera.rotation_degrees = rot_deg
	if hero == null:
		return
	if absf(camera_initial_height_boost) <= 0.001:
		return
	_camera_offset_from_hero.y += camera_initial_height_boost
	_camera_height_target = camera.global_position.y + camera_initial_height_boost


func _disable_collision_on_model(root: Node) -> void:
	if root == null:
		return
	if root is CollisionObject3D:
		var collision_obj := root as CollisionObject3D
		collision_obj.collision_layer = 0
		collision_obj.collision_mask = 0
	for child in root.get_children():
		var child_node := child as Node
		if child_node != null:
			_disable_collision_on_model(child_node)


func _parse_network_role_from_cmdline() -> void:
	_network_role = "offline"
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
		value = value.strip_edges().to_lower()
		if (
			key == "net"
			or key == "network"
			or key == "mode"
			or key == "net-mode"
			or key == "net_mode"
		):
			if value == "host" or value == "client" or value == "offline":
				_network_role = value
				return


func _get_network_spawn_extra_offset() -> Vector3:
	if _network_role == "host":
		return host_start_extra_offset
	if _network_role == "client":
		return client_start_extra_offset
	return Vector3.ZERO


func _get_spawn_position_around_shop() -> Vector3:
	var center: Vector3 = _get_shop_center_position()
	var rng := RandomNumberGenerator.new()
	rng.seed = _build_spawn_seed()

	var scatter_radius: float = maxf(hero_spawn_scatter_radius, 0.0)
	var rand_radius: float = sqrt(rng.randf()) * scatter_radius
	var rand_angle: float = rng.randf_range(0.0, TAU)
	var random_offset := Vector3(cos(rand_angle) * rand_radius, 0.0, sin(rand_angle) * rand_radius)
	return center + random_offset


func _resolve_local_shop_owner_peer_id() -> int:
	if multiplayer.multiplayer_peer != null:
		var peer_id: int = multiplayer.get_unique_id()
		if peer_id > 0:
			return peer_id
	if _network_role == "host":
		return 1
	if _network_role == "client":
		return 2
	return 1


func _resolve_shop_owner_peer_id_by_slot(slot_index: int) -> int:
	if slot_index >= 0 and slot_index < _shop_owner_peer_ids.size():
		return maxi(_shop_owner_peer_ids[slot_index], 0)
	return 0


func _resolve_shop_slot_index_for_peer(peer_id: int) -> int:
	if _shop_cluster_positions.is_empty():
		return -1
	if peer_id <= 0:
		return -1
	return _shop_owner_peer_ids.find(peer_id)


func _get_shop_center_for_peer(peer_id: int) -> Vector3:
	var slot_index: int = _resolve_shop_slot_index_for_peer(peer_id)
	if slot_index >= 0 and slot_index < _shop_cluster_positions.size():
		return _shop_cluster_positions[slot_index]
	return _get_shop_center_position()


func _apply_shop_owner_metadata(shop_root: Node, owner_peer_id: int, slot_index: int) -> void:
	if shop_root == null:
		return
	_apply_shop_owner_metadata_recursive(shop_root, owner_peer_id, slot_index)


func _apply_shop_owner_metadata_recursive(node: Node, owner_peer_id: int, slot_index: int) -> void:
	if node == null:
		return
	node.set_meta(SHOP_OWNER_META_KEY, owner_peer_id)
	node.set_meta(SHOP_SLOT_META_KEY, slot_index)
	for child_variant in node.get_children():
		var child: Node = child_variant as Node
		if child != null:
			_apply_shop_owner_metadata_recursive(child, owner_peer_id, slot_index)


func _poll_shop_owner_binding(delta: float) -> void:
	_shop_owner_binding_poll_elapsed += maxf(delta, 0.0)
	if _shop_owner_binding_poll_elapsed < 0.35:
		return
	_shop_owner_binding_poll_elapsed = 0.0
	_refresh_shop_owner_bindings()


func _refresh_shop_owner_bindings(force: bool = false) -> void:
	if _shop_cluster_positions.is_empty():
		return
	var next_owner_ids: Array[int] = _resolve_shop_owner_peer_ids(_shop_cluster_positions.size())
	if not force and _int_array_equals(_shop_owner_peer_ids, next_owner_ids):
		return
	_shop_owner_peer_ids = next_owner_ids.duplicate()
	if debug_shop_owner_binding_logs:
		var self_peer_id: int = 0
		if multiplayer.multiplayer_peer != null:
			self_peer_id = multiplayer.get_unique_id()
		var room_peer_ids: Array[int] = _collect_active_peer_ids_for_boss_entry()
		print(
			(
				"[shop-bind] role=%s self=%d owners=%s room=%s"
				% [_network_role, self_peer_id, str(_shop_owner_peer_ids), str(room_peer_ids)]
			)
		)
	var nav_root := get_node_or_null(navigation_region_path) as Node3D
	var primary_shop := get_node_or_null(shop_path) as Node3D
	if nav_root == null or primary_shop == null:
		return
	for slot_index in range(_shop_cluster_positions.size()):
		var shop_root: Node3D = _get_shop_root_for_slot(nav_root, primary_shop, slot_index)
		if shop_root == null:
			continue
		_apply_shop_owner_metadata(
			shop_root, _resolve_shop_owner_peer_id_by_slot(slot_index), slot_index
		)


func _resolve_shop_owner_peer_ids(slot_count: int) -> Array[int]:
	var owners: Array[int] = []
	if slot_count <= 0:
		return owners
	var active_peer_ids: Array[int] = _collect_active_peer_ids_for_boss_entry()
	# 某些客户端阶段 get_peers() 可能暂时拿不到 host，补齐后避免 owner 槽位错位。
	if _network_role == "client" and not active_peer_ids.has(1):
		active_peer_ids.append(1)
	active_peer_ids.sort()
	var unique_active_peer_ids: Array[int] = []
	for peer_id in active_peer_ids:
		if peer_id <= 0:
			continue
		if unique_active_peer_ids.has(peer_id):
			continue
		unique_active_peer_ids.append(peer_id)
	if unique_active_peer_ids.is_empty():
		var local_owner_peer_id: int = _resolve_local_shop_owner_peer_id()
		if local_owner_peer_id > 0:
			unique_active_peer_ids.append(local_owner_peer_id)
	for peer_id in unique_active_peer_ids:
		if owners.size() >= slot_count:
			break
		owners.append(peer_id)
	while owners.size() < slot_count:
		owners.append(0)
	return owners


func _int_array_equals(a: Array[int], b: Array[int]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


func _get_shop_root_for_slot(nav_root: Node3D, primary_shop: Node3D, slot_index: int) -> Node3D:
	if slot_index <= 0:
		return primary_shop
	return nav_root.get_node_or_null("ShopCluster_%d" % slot_index) as Node3D


func debug_get_shop_owner_peer_ids() -> Array[int]:
	return _shop_owner_peer_ids.duplicate()


func _build_spawn_seed() -> int:
	var peer_id: int = 0
	if multiplayer.multiplayer_peer != null:
		peer_id = multiplayer.get_unique_id()
	var seed_text: String
	if peer_id > 0:
		seed_text = "spawn_peer_%d" % peer_id
	else:
		seed_text = "spawn_%s_%d" % [_network_role, Time.get_ticks_usec()]
	var seed: int = int(hash(seed_text)) & 0x7fffffff
	if seed <= 0:
		seed = 1
	return seed


func _get_shop_center_position() -> Vector3:
	if _shop_cluster_positions.size() > 0:
		var center: Vector3 = Vector3.ZERO
		for pos in _shop_cluster_positions:
			center += pos
		return center / float(_shop_cluster_positions.size())
	if _has_start_area_center:
		return _start_area_center
	var shop := get_node_or_null(shop_path) as Node3D
	if shop != null:
		return shop.global_position
	return start_point


func get_start_area_center() -> Vector3:
	if _has_start_area_center:
		return _start_area_center
	return _compute_start_area_center()


func get_start_area_full_recovery_radius() -> float:
	var bounds: Dictionary = _compute_start_area_bounds()
	var half_x: float = float(bounds.get("bound_half_x", maxf(hero_spawn_min_radius, 0.0)))
	var half_z: float = float(bounds.get("bound_half_z", maxf(hero_spawn_min_radius, 0.0)))
	var diagonal_radius: float = sqrt(half_x * half_x + half_z * half_z)
	var spawn_radius: float = maxf(hero_spawn_min_radius + hero_spawn_scatter_radius, 0.0)
	return maxf(diagonal_radius, spawn_radius)


func _get_boss_battle_entry_position(boss_anchor: Vector3) -> Vector3:
	var role_offset: Vector3 = (
		_get_network_spawn_extra_offset() * maxf(boss_battle_role_offset_scale, 0.0)
	)
	return boss_anchor + boss_entry_offset + role_offset


func _resolve_local_boss_entry_position(
	boss_anchor: Vector3, entry_positions: Dictionary
) -> Vector3:
	if not entry_positions.is_empty():
		var local_peer_id: int = 1
		if multiplayer.multiplayer_peer != null:
			local_peer_id = multiplayer.get_unique_id()
		var pos_variant: Variant = null
		if entry_positions.has(local_peer_id):
			pos_variant = entry_positions[local_peer_id]
		elif entry_positions.has(str(local_peer_id)):
			pos_variant = entry_positions[str(local_peer_id)]
		if pos_variant is Vector3:
			var candidate: Vector3 = pos_variant
			var max_allowed_distance: float = (
				maxf(
					maxf(boss_entry_random_max_radius, boss_entry_random_min_radius),
					(
						Vector2(boss_entry_offset.x, boss_entry_offset.z).length()
						+ maxf(boss_entry_random_min_distance, 0.0)
					)
				)
				+ 240.0
			)
			if candidate.distance_to(boss_anchor) <= max_allowed_distance:
				return candidate
	return _get_boss_battle_entry_position(boss_anchor)


func _build_boss_battle_entry_positions(boss_anchor: Vector3) -> Dictionary:
	var peer_ids: Array[int] = _collect_active_peer_ids_for_boss_entry()
	if peer_ids.is_empty():
		return {}
	var center: Vector3 = boss_anchor
	center.y = 0.0
	var peer_count: int = peer_ids.size()
	var base_offset_xz := Vector2(boss_entry_offset.x, boss_entry_offset.z)
	var base_radius: float = base_offset_xz.length()
	if base_radius <= 0.001:
		base_radius = 240.0
	var configured_max_radius: float = maxf(boss_entry_random_max_radius, base_radius)
	var min_distance: float = maxf(boss_entry_random_min_distance, 40.0)
	var required_radius_for_spacing: float = base_radius
	if peer_count > 1:
		var half_step_angle: float = PI / float(peer_count)
		var sin_value: float = sin(half_step_angle)
		if sin_value > 0.001:
			required_radius_for_spacing = maxf(
				required_radius_for_spacing, min_distance / (2.0 * sin_value)
			)
	var entry_radius: float = clampf(
		required_radius_for_spacing, base_radius, configured_max_radius
	)
	var start_angle: float = atan2(base_offset_xz.y, base_offset_xz.x)
	if base_offset_xz.length_squared() <= 0.0001:
		start_angle = -PI * 0.5
	var result: Dictionary = {}
	for i in range(peer_count):
		var peer_id: int = peer_ids[i]
		var angle: float = start_angle + TAU * (float(i) / float(peer_count))
		var candidate: Vector3 = (
			center + Vector3(cos(angle) * entry_radius, 0.0, sin(angle) * entry_radius)
		)
		result[peer_id] = candidate
	return result


func _collect_active_peer_ids_for_boss_entry() -> Array[int]:
	var ids: Array[int] = []
	if multiplayer.multiplayer_peer == null:
		ids.append(1)
		return ids
	var self_id: int = multiplayer.get_unique_id()
	if self_id > 0:
		ids.append(self_id)
	for peer_variant in multiplayer.get_peers():
		var peer_id: int = int(peer_variant)
		if peer_id <= 0:
			continue
		if ids.has(peer_id):
			continue
		ids.append(peer_id)
	ids.sort()
	return ids
