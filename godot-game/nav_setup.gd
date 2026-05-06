extends NavigationRegion3D

func _ready() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = _compute_nav_cell_size()
	nav_mesh.cell_height = 5.0
	nav_mesh.agent_height = 150.0
	nav_mesh.agent_radius = 75.0
	nav_mesh.agent_max_climb = 10.0
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh = nav_mesh


func _compute_nav_cell_size() -> float:
	var floor_collision := get_node_or_null("FloorBody/FloorCollision") as CollisionShape3D
	if floor_collision == null:
		return 15.0
	var floor_shape := floor_collision.shape as BoxShape3D
	if floor_shape == null:
		return 15.0
	var longest_side: float = maxf(floor_shape.size.x, floor_shape.size.z)
	return clampf(longest_side / 1200.0, 15.0, 75.0)
