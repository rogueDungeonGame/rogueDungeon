extends RefCounted
class_name CombatSceneUtils

const DAMAGE_POPUP_MAGIC_COLOR := Color(0.32, 0.68, 1.0, 1.0)
const DAMAGE_POPUP_PHYSICAL_COLOR := Color(1.0, 0.25, 0.25, 1.0)
const DAMAGE_POPUP_CRIT_ICON_COLOR := Color(1.0, 0.96, 0.72, 1.0)
const DAMAGE_POPUP_LIFETIME_SEC: float = 0.5
const DAMAGE_POPUP_RISE_DISTANCE: float = 36.0
const DAMAGE_POPUP_SIDEWAYS_JITTER: float = 16.0
const DAMAGE_POPUP_HEIGHT_OFFSET: float = 18.0
const DAMAGE_POPUP_PIXEL_SIZE: float = 0.00075
const DAMAGE_POPUP_FONT_SIZE: int = 72
const DAMAGE_POPUP_NON_CRIT_FONT_SCALE: float = 0.5
const DAMAGE_POPUP_CRIT_FONT_SCALE: float = 2.0 / 3.0
const DAMAGE_POPUP_CRIT_ICON_PIXEL_SCALE: float = 0.95
const DAMAGE_POPUP_CRIT_LABEL_OFFSET_PX: float = 12.0
const DAMAGE_POPUP_CRIT_ICON_OFFSET_X_PX: float = -26.0
const DAMAGE_POPUP_CRIT_ICON_OFFSET_Y_PX: float = 6.0
const DAMAGE_POPUP_CRIT_ICON_TEXTURE: Texture2D = preload(
	"res://icons/skills/BTNCriticalStrike.png"
)


static func is_obstacle_collider(collider: Node, obstacle_root_name: String = "Obstacles") -> bool:
	var cursor: Node = collider
	while cursor != null:
		if cursor.name == obstacle_root_name:
			return true
		cursor = cursor.get_parent()
	return false


static func is_move_segment_blocked(
	world_3d: World3D,
	from_pos: Vector3,
	to_pos: Vector3,
	probe_half_width: float,
	probe_height: float,
	collision_mask: int,
	obstacle_root_name: String = "Obstacles"
) -> bool:
	if world_3d == null:
		return false
	var horizontal: Vector3 = to_pos - from_pos
	horizontal.y = 0.0
	if horizontal.length() <= 0.01:
		return false

	var right: Vector3 = horizontal.cross(Vector3.UP)
	if right.length() > 0.001:
		right = right.normalized() * probe_half_width
	else:
		right = Vector3.ZERO

	var offsets: Array[Vector3] = [Vector3.ZERO, right, -right]
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	for offset in offsets:
		var start: Vector3 = from_pos + offset + Vector3(0.0, probe_height, 0.0)
		var finish: Vector3 = to_pos + offset + Vector3(0.0, probe_height, 0.0)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish)
		query.collision_mask = collision_mask
		var hit: Dictionary = space_state.intersect_ray(query)
		if hit.is_empty() or not hit.has("collider"):
			continue
		var collider_node: Node = hit["collider"] as Node
		if collider_node != null and is_obstacle_collider(collider_node, obstacle_root_name):
			return true
	return false


static func compute_node_mesh_height(root_node: Node3D, ignored_nodes: Array = []) -> float:
	if root_node == null or not is_instance_valid(root_node):
		return 0.0
	var ignored_ids: Dictionary = {}
	for ignored_variant in ignored_nodes:
		var ignored_node: Node = ignored_variant as Node
		if ignored_node == null or not is_instance_valid(ignored_node):
			continue
		ignored_ids[ignored_node.get_instance_id()] = true

	var root_inv: Transform3D = root_node.global_transform.affine_inverse()
	var has_bounds: bool = false
	var min_y: float = INF
	var max_y: float = -INF
	var pending: Array[Node] = [root_node]
	while not pending.is_empty():
		var current_node: Node = pending.pop_back() as Node
		if current_node == null:
			continue
		for child_variant in current_node.get_children():
			var child_node: Node = child_variant as Node
			if child_node != null:
				pending.append(child_node)
		var node_3d: Node3D = current_node as Node3D
		if node_3d == null:
			continue
		if ignored_ids.has(node_3d.get_instance_id()):
			continue
		if not (node_3d.is_class("MeshInstance3D") or node_3d.is_class("ImporterMeshInstance3D")):
			continue
		if not node_3d.has_method("get_aabb"):
			continue
		var aabb_variant: Variant = node_3d.call("get_aabb")
		if not (aabb_variant is AABB):
			continue
		var local_aabb: AABB = aabb_variant
		var mesh_to_root: Transform3D = root_inv * node_3d.global_transform
		for x_idx in range(2):
			for y_idx in range(2):
				for z_idx in range(2):
					var corner_local: Vector3 = (
						local_aabb.position
						+ Vector3(
							local_aabb.size.x * float(x_idx),
							local_aabb.size.y * float(y_idx),
							local_aabb.size.z * float(z_idx)
						)
					)
					var corner_root: Vector3 = mesh_to_root * corner_local
					min_y = minf(min_y, corner_root.y)
					max_y = maxf(max_y, corner_root.y)
					has_bounds = true
	if not has_bounds:
		return 0.0
	return maxf(max_y - min_y, 0.0)


static func spawn_damage_popup(
	anchor_node: Node3D,
	amount: int,
	anchor_height: float,
	is_magic: bool,
	is_critical: bool = false,
	height_offset: float = DAMAGE_POPUP_HEIGHT_OFFSET
) -> void:
	if anchor_node == null or not is_instance_valid(anchor_node):
		return
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return

	var popup_color: Color = DAMAGE_POPUP_MAGIC_COLOR if is_magic else DAMAGE_POPUP_PHYSICAL_COLOR
	var font_scale: float = (
		DAMAGE_POPUP_CRIT_FONT_SCALE if is_critical else DAMAGE_POPUP_NON_CRIT_FONT_SCALE
	)
	var start_pos := Vector3(
		randf_range(-DAMAGE_POPUP_SIDEWAYS_JITTER, DAMAGE_POPUP_SIDEWAYS_JITTER),
		anchor_height + height_offset,
		randf_range(-DAMAGE_POPUP_SIDEWAYS_JITTER * 0.35, DAMAGE_POPUP_SIDEWAYS_JITTER * 0.35)
	)
	var popup_root := Node3D.new()
	popup_root.position = start_pos
	anchor_node.add_child(popup_root)

	var popup := Label3D.new()
	popup.text = "%d" % safe_amount
	popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.no_depth_test = true
	popup.fixed_size = true
	popup.double_sided = true
	popup.shaded = false
	popup.render_priority = 30
	popup.pixel_size = DAMAGE_POPUP_PIXEL_SIZE
	popup.font_size = maxi(int(round(float(DAMAGE_POPUP_FONT_SIZE) * font_scale)), 1)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.outline_size = maxi(int(round(4.0 * font_scale)), 1)
	popup.outline_modulate = Color(0.0, 0.0, 0.0, 0.92)
	popup.modulate = popup_color
	if is_critical:
		popup.position.x = DAMAGE_POPUP_CRIT_LABEL_OFFSET_PX * DAMAGE_POPUP_PIXEL_SIZE
	popup_root.add_child(popup)

	var crit_icon: Sprite3D = null
	if is_critical and DAMAGE_POPUP_CRIT_ICON_TEXTURE != null:
		crit_icon = Sprite3D.new()
		crit_icon.texture = DAMAGE_POPUP_CRIT_ICON_TEXTURE
		crit_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		crit_icon.no_depth_test = true
		crit_icon.fixed_size = true
		crit_icon.pixel_size = DAMAGE_POPUP_PIXEL_SIZE * DAMAGE_POPUP_CRIT_ICON_PIXEL_SCALE
		crit_icon.double_sided = true
		crit_icon.shaded = false
		crit_icon.modulate = DAMAGE_POPUP_CRIT_ICON_COLOR
		crit_icon.position = Vector3(
			DAMAGE_POPUP_CRIT_ICON_OFFSET_X_PX * DAMAGE_POPUP_PIXEL_SIZE,
			DAMAGE_POPUP_CRIT_ICON_OFFSET_Y_PX * DAMAGE_POPUP_PIXEL_SIZE,
			0.0
		)
		popup_root.add_child(crit_icon)

	var tween: Tween = popup_root.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		popup_root,
		"position",
		start_pos + Vector3(0.0, DAMAGE_POPUP_RISE_DISTANCE, 0.0),
		DAMAGE_POPUP_LIFETIME_SEC
	)
	tween.tween_property(
		popup,
		"modulate",
		Color(popup_color.r, popup_color.g, popup_color.b, 0.0),
		DAMAGE_POPUP_LIFETIME_SEC
	)
	if crit_icon != null:
		tween.tween_property(
			crit_icon,
			"modulate",
			Color(
				DAMAGE_POPUP_CRIT_ICON_COLOR.r,
				DAMAGE_POPUP_CRIT_ICON_COLOR.g,
				DAMAGE_POPUP_CRIT_ICON_COLOR.b,
				0.0
			),
			DAMAGE_POPUP_LIFETIME_SEC
		)
	tween.finished.connect(
		func() -> void:
			if is_instance_valid(popup_root):
				popup_root.queue_free()
	)


static func sync_top_level_billboard_to_camera(
	billboard_node: Node3D, anchor_node: Node3D, anchor_height: float, viewport: Viewport
) -> void:
	if billboard_node == null or not is_instance_valid(billboard_node):
		return
	if anchor_node == null or not is_instance_valid(anchor_node):
		return
	billboard_node.global_position = anchor_node.global_position + Vector3(0.0, anchor_height, 0.0)
	if viewport == null:
		return
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return
	var node_scale: Vector3 = billboard_node.scale
	var node_transform: Transform3D = billboard_node.global_transform
	node_transform.basis = camera.global_transform.basis.orthonormalized()
	billboard_node.global_transform = node_transform
	billboard_node.scale = node_scale
