extends RefCounted
class_name RemoteAvatarVisualService


func update_remote_avatar_hp_bar(
	peer_id: int,
	avatar: Node3D,
	hero_state: Dictionary,
	is_dead: bool,
	remote_hp_bar_height: float,
	remote_hp_bar_width: float,
	remote_avatar_hp_bars: Dictionary,
	remote_avatar_hp_bar_materials: Dictionary
) -> void:
	if avatar == null or not is_instance_valid(avatar):
		return
	var bar_height: float = resolve_remote_avatar_hp_bar_height(
		hero_state, avatar, remote_hp_bar_height
	)
	var hp_bar: MeshInstance3D = ensure_remote_avatar_hp_bar(
		peer_id,
		avatar,
		bar_height,
		remote_hp_bar_width,
		remote_avatar_hp_bars,
		remote_avatar_hp_bar_materials
	)
	if hp_bar == null:
		return
	var max_hp: int = maxi(int(hero_state.get("max_hp", 1)), 1)
	var hp: int = clampi(int(hero_state.get("hp", max_hp)), 0, max_hp)
	var material: ShaderMaterial = (
		remote_avatar_hp_bar_materials.get(peer_id, null) as ShaderMaterial
	)
	if material != null:
		material.set_shader_parameter("hp_ratio", float(hp) / float(max_hp))
	var bar_mesh: QuadMesh = hp_bar.mesh as QuadMesh
	if bar_mesh != null:
		bar_mesh.size = Vector2(maxf(remote_hp_bar_width, 20.0), 25.5)
	hp_bar.set_meta("anchor_height", bar_height)
	sync_remote_avatar_hp_bar_transform(avatar, hp_bar, bar_height)
	hp_bar.visible = avatar.visible and not is_dead and hp > 0


func ensure_remote_avatar_hp_bar(
	peer_id: int,
	avatar: Node3D,
	bar_height: float,
	remote_hp_bar_width: float,
	remote_avatar_hp_bars: Dictionary,
	remote_avatar_hp_bar_materials: Dictionary
) -> MeshInstance3D:
	var existing_bar: MeshInstance3D = remote_avatar_hp_bars.get(peer_id, null) as MeshInstance3D
	if (
		existing_bar != null
		and is_instance_valid(existing_bar)
		and existing_bar.get_parent() == avatar
	):
		existing_bar.top_level = true
		return existing_bar
	var hp_bar := avatar.get_node_or_null("RemoteHPBar") as MeshInstance3D
	if hp_bar != null and is_instance_valid(hp_bar):
		remote_avatar_hp_bars[peer_id] = hp_bar
		var existing_material: ShaderMaterial = hp_bar.material_override as ShaderMaterial
		if existing_material != null:
			remote_avatar_hp_bar_materials[peer_id] = existing_material
		hp_bar.top_level = true
		hp_bar.set_meta("anchor_height", bar_height)
		return hp_bar

	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nuniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat bw = 0.04;\n\tfloat bh = 0.12;\n\tif (uv.x < bw || uv.x > 1.0 - bw || uv.y < bh || uv.y > 1.0 - bh) {\n\t\tALBEDO = vec3(0.0);\n\t\tALPHA = 0.9;\n\t} else {\n\t\tfloat ix = (uv.x - bw) / (1.0 - 2.0 * bw);\n\t\tif (ix <= hp_ratio) {\n\t\t\tALBEDO = vec3(1.0 - hp_ratio, hp_ratio, 0.0);\n\t\t\tALPHA = 0.9;\n\t\t} else {\n\t\t\tALBEDO = vec3(0.15);\n\t\t\tALPHA = 0.5;\n\t\t}\n\t}\n}\n"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("hp_ratio", 1.0)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(maxf(remote_hp_bar_width, 20.0), 25.5)
	hp_bar = MeshInstance3D.new()
	hp_bar.name = "RemoteHPBar"
	hp_bar.mesh = mesh
	hp_bar.material_override = material
	hp_bar.top_level = true
	hp_bar.set_meta("anchor_height", bar_height)
	avatar.add_child(hp_bar)
	remote_avatar_hp_bars[peer_id] = hp_bar
	remote_avatar_hp_bar_materials[peer_id] = material
	return hp_bar


func resolve_remote_avatar_hp_bar_height(
	hero_state: Dictionary, avatar: Node3D, remote_hp_bar_height: float
) -> float:
	if hero_state.has("hp_bar_anchor_height"):
		return maxf(float(hero_state.get("hp_bar_anchor_height", remote_hp_bar_height)), 0.0)
	if hero_state.has("hp_bar_height"):
		return maxf(float(hero_state.get("hp_bar_height", remote_hp_bar_height)), 0.0)
	var anchor_height: float = resolve_avatar_anchor_height(avatar, "HeadAnchor")
	if anchor_height > 0.0:
		return anchor_height
	var computed_height: float = compute_node_mesh_height(avatar, "RemoteHPBar")
	if computed_height > 0.0:
		return computed_height + 20.0
	return maxf(remote_hp_bar_height, 0.0)


func sync_remote_avatar_hp_bar_transform(
	avatar: Node3D, hp_bar: MeshInstance3D, bar_height: float
) -> void:
	if avatar == null or not is_instance_valid(avatar):
		return
	if hp_bar == null or not is_instance_valid(hp_bar):
		return
	hp_bar.global_position = avatar.global_position + Vector3(0.0, bar_height, 0.0)
	var viewport: Viewport = avatar.get_viewport()
	if viewport == null:
		return
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return
	var bar_scale: Vector3 = hp_bar.scale
	var bar_transform: Transform3D = hp_bar.global_transform
	bar_transform.basis = camera.global_transform.basis.orthonormalized()
	hp_bar.global_transform = bar_transform
	hp_bar.scale = bar_scale


func resolve_avatar_anchor_height(avatar: Node3D, anchor_name: String) -> float:
	if avatar == null or not is_instance_valid(avatar):
		return -1.0
	var anchor_node := find_avatar_anchor_node(avatar, anchor_name)
	if anchor_node == null or not is_instance_valid(anchor_node):
		return -1.0
	return maxf(anchor_node.global_position.y - avatar.global_position.y, 0.0)


func find_avatar_anchor_node(avatar: Node3D, anchor_name: String) -> Node3D:
	if avatar == null or not is_instance_valid(avatar):
		return null
	var anchor_root := avatar.get_node_or_null("AnchorRoot") as Node3D
	if anchor_root != null and is_instance_valid(anchor_root):
		var direct_anchor := anchor_root.get_node_or_null(anchor_name) as Node3D
		if direct_anchor != null:
			return direct_anchor
	return avatar.find_child(anchor_name, true, false) as Node3D


func compute_node_mesh_height(root_node: Node3D, ignored_mesh_name: String = "") -> float:
	if root_node == null or not is_instance_valid(root_node):
		return 0.0
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
		if ignored_mesh_name != "" and node_3d.name == ignored_mesh_name:
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
