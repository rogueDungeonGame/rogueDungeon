extends Node3D

signal gate_destroyed

@export var max_hp: int = 100
@export var hp_bar_height: float = 200.0
@export var hp_bar_width: float = 200.0

var current_hp: int = 100
var _is_dead: bool = false
var _hp_bar: MeshInstance3D
var _hp_bar_material: ShaderMaterial
var _hp_bar_anchor_height: float = 0.0
const HP_BAR_HEIGHT_OFFSET: float = 200.0


func _ready() -> void:
	add_to_group("breakable")
	max_hp = maxi(max_hp, 1)
	current_hp = max_hp
	_create_hp_bar()
	_update_hp_bar()
	call_deferred("_refresh_hp_bar_anchor_position")


func apply_damage(amount: int, _attacker: Node3D = null, _damage_source: String = "physical", _hit_context: Dictionary = {}) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	if not _is_gate_damage_enabled():
		return
	if _is_dead:
		return
	var real_damage: int = maxi(amount, 0)
	if real_damage <= 0:
		return
	current_hp = maxi(current_hp - real_damage, 0)
	_update_hp_bar()
	if current_hp <= 0:
		_die()


func is_dead() -> bool:
	return _is_dead


func can_receive_skill_damage() -> bool:
	return false


func export_network_state() -> Dictionary:
	return {
		"id": str(get_path()),
		"hp": current_hp,
		"max_hp": max_hp,
		"dead": _is_dead,
		"visible": visible
	}


func apply_network_state(state: Dictionary) -> void:
	if state.has("max_hp"):
		max_hp = maxi(int(state["max_hp"]), 1)
	if state.has("hp"):
		current_hp = clampi(int(state["hp"]), 0, max_hp)
	var incoming_dead: bool = bool(state.get("dead", _is_dead))
	if incoming_dead and not _is_dead:
		_die()
		return
	if state.has("visible"):
		visible = bool(state["visible"])
	if _hp_bar != null:
		_hp_bar.visible = visible and not _is_dead
	_update_hp_bar()


func _create_hp_bar() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nuniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat bw = 0.04;\n\tfloat bh = 0.12;\n\tif (uv.x < bw || uv.x > 1.0 - bw || uv.y < bh || uv.y > 1.0 - bh) {\n\t\tALBEDO = vec3(0.0);\n\t\tALPHA = 0.9;\n\t} else {\n\t\tfloat ix = (uv.x - bw) / (1.0 - 2.0 * bw);\n\t\tif (ix <= hp_ratio) {\n\t\t\tALBEDO = vec3(1.0 - hp_ratio, hp_ratio, 0.0);\n\t\t\tALPHA = 0.9;\n\t\t} else {\n\t\t\tALBEDO = vec3(0.15);\n\t\t\tALPHA = 0.5;\n\t\t}\n\t}\n}\n"
	_hp_bar_material = ShaderMaterial.new()
	_hp_bar_material.shader = shader
	_hp_bar_material.set_shader_parameter("hp_ratio", 1.0)

	var mesh := QuadMesh.new()
	mesh.size = Vector2(hp_bar_width, 24.0)
	_hp_bar = MeshInstance3D.new()
	_hp_bar.mesh = mesh
	_hp_bar.material_override = _hp_bar_material
	_refresh_hp_bar_anchor_position()
	add_child(_hp_bar)


func _update_hp_bar() -> void:
	if _hp_bar_material == null:
		return
	_hp_bar_material.set_shader_parameter("hp_ratio", float(current_hp) / float(maxi(max_hp, 1)))


func _refresh_hp_bar_anchor_position() -> void:
	_hp_bar_anchor_height = _resolve_hp_bar_anchor_height()
	if _hp_bar != null and is_instance_valid(_hp_bar):
		_hp_bar.position = Vector3(0.0, _hp_bar_anchor_height, 0.0)


func _resolve_hp_bar_anchor_height() -> float:
	var model_height: float = _compute_node_mesh_height(self)
	if model_height > 0.0:
		return model_height + HP_BAR_HEIGHT_OFFSET
	return HP_BAR_HEIGHT_OFFSET


func _compute_node_mesh_height(root_node: Node3D) -> float:
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
		var mesh_node: MeshInstance3D = current_node as MeshInstance3D
		if mesh_node == null:
			continue
		if mesh_node == _hp_bar:
			continue
		if mesh_node.mesh == null:
			continue
		var local_aabb: AABB = mesh_node.get_aabb()
		var mesh_to_root: Transform3D = root_inv * mesh_node.global_transform
		for x_idx in range(2):
			for y_idx in range(2):
				for z_idx in range(2):
					var corner_local: Vector3 = local_aabb.position + Vector3(
						local_aabb.size.x * float(x_idx),
						local_aabb.size.y * float(y_idx),
						local_aabb.size.z * float(z_idx)
					)
					var corner_root: Vector3 = mesh_to_root * corner_local
					min_y = minf(min_y, corner_root.y)
					max_y = maxf(max_y, corner_root.y)
					has_bounds = true
	if not has_bounds:
		return 0.0
	return maxf(max_y - min_y, 0.0)


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	current_hp = 0
	_update_hp_bar()

	var collision_body := find_child("CollisionBody", true, false) as CollisionObject3D
	if collision_body != null:
		collision_body.remove_from_group("enemy")
		collision_body.collision_layer = 0
		collision_body.collision_mask = 0

	if _hp_bar != null:
		_hp_bar.visible = false
	visible = false
	emit_signal("gate_destroyed")


func _is_gate_damage_enabled() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return true
	var net_ctrl: Node = tree.get_first_node_in_group("net_session_controller")
	if net_ctrl == null:
		return true
	if not net_ctrl.has_method("is_gate_damage_enabled"):
		return true
	return bool(net_ctrl.call("is_gate_damage_enabled"))
