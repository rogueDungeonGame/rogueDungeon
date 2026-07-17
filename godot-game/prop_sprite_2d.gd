extends Node3D

@export var texture_path: String = ""
@export var sprite_node_path: NodePath = NodePath("VisualRoot/Sprite3D")
@export var pixel_size: float = 0.12
@export var vertical_offset: float = 0.0
@export var draw_as_billboard: bool = false
@export var auto_align_to_bottom: bool = true
@export var alpha_occlusion_enabled: bool = false
@export var occlusion_alpha: float = 0.35
@export var occlusion_margin_y: float = 12.0
@export var occlusion_margin_x: float = 12.0
@export var occlusion_hero_group: StringName = &"hero"
@export var occlusion_check_interval: float = 0.08

var _sprite: Sprite3D = null
var _cached_texture_path: String = ""
var _texture_image_size: Vector2i = Vector2i.ZERO
var _texture_bottom_center_px: Vector2 = Vector2.ZERO
var _occlusion_time_left: float = 0.0
var _current_alpha: float = 1.0


func _ready() -> void:
	_sprite = get_node_or_null(sprite_node_path) as Sprite3D
	if _sprite == null:
		_sprite = find_child("Sprite3D", true, false) as Sprite3D
	if _sprite == null:
		push_warning("prop_sprite_2d.gd requires a Sprite3D child.")
		set_process(false)
		return
	_apply_texture_if_needed(true)


func _process(_delta: float) -> void:
	_apply_texture_if_needed(false)
	_update_occlusion(_delta)


func _apply_texture_if_needed(force: bool) -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	if not force and _cached_texture_path == texture_path:
		return
	var next_texture: Texture2D = _load_texture_from_file(texture_path)
	if next_texture == null:
		return
	_sprite.texture = next_texture
	_sprite.pixel_size = maxf(pixel_size, 0.0001)
	_sprite.double_sided = true
	_sprite.billboard = (
		BaseMaterial3D.BILLBOARD_ENABLED if draw_as_billboard else BaseMaterial3D.BILLBOARD_DISABLED
	)
	var local_pos: Vector3 = _sprite.position
	local_pos.y = _resolve_sprite_local_y()
	_sprite.position = local_pos
	_apply_sprite_alpha(1.0)
	_cached_texture_path = texture_path


func _load_texture_from_file(path_text: String) -> Texture2D:
	var safe_path: String = path_text.strip_edges()
	if safe_path.is_empty():
		return null
	if not FileAccess.file_exists(safe_path):
		return null
	var image := Image.new()
	var load_error: int = image.load(ProjectSettings.globalize_path(safe_path))
	if load_error != OK:
		load_error = image.load(safe_path)
	if load_error != OK:
		return null
	_texture_image_size = Vector2i(image.get_width(), image.get_height())
	_texture_bottom_center_px = _compute_bottom_center_from_alpha(image)
	return ImageTexture.create_from_image(image)


func _compute_bottom_center_from_alpha(image: Image) -> Vector2:
	var w: int = image.get_width()
	var h: int = image.get_height()
	if w <= 0 or h <= 0:
		return Vector2.ZERO
	var found_y: int = -1
	var min_x: int = w
	var max_x: int = -1
	for y in range(h - 1, -1, -1):
		for x in range(w):
			var color: Color = image.get_pixel(x, y)
			if color.a <= 0.05:
				continue
			if found_y < 0:
				found_y = y
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
		if found_y >= 0:
			break
	if found_y < 0 or max_x < min_x:
		return Vector2(float(w) * 0.5, float(h))
	return Vector2(float(min_x + max_x) * 0.5, float(found_y))


func _resolve_sprite_local_y() -> float:
	if not auto_align_to_bottom:
		return vertical_offset
	if _texture_image_size.y <= 0:
		return vertical_offset
	var bottom_gap_px: float = float(_texture_image_size.y) - _texture_bottom_center_px.y
	return vertical_offset + bottom_gap_px * maxf(pixel_size, 0.0001)


func _update_occlusion(delta: float) -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	if not alpha_occlusion_enabled:
		_apply_sprite_alpha(1.0)
		return
	_occlusion_time_left -= delta
	if _occlusion_time_left > 0.0:
		return
	_occlusion_time_left = maxf(occlusion_check_interval, 0.01)
	var should_fade: bool = _is_local_hero_behind_sprite()
	var target_alpha: float = clampf(occlusion_alpha, 0.05, 1.0) if should_fade else 1.0
	_apply_sprite_alpha(target_alpha)


func _is_local_hero_behind_sprite() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var heroes: Array = tree.get_nodes_in_group(occlusion_hero_group)
	if heroes.is_empty():
		return false
	var sprite_pos: Vector3 = global_position
	var threshold_x: float = maxf(occlusion_margin_x, 0.0)
	var threshold_y: float = maxf(occlusion_margin_y, 0.0)
	for hero_variant in heroes:
		var hero_node: Node3D = hero_variant as Node3D
		if hero_node == null or not is_instance_valid(hero_node) or not hero_node.visible:
			continue
		var hero_pos: Vector3 = hero_node.global_position
		if absf(hero_pos.x - sprite_pos.x) > threshold_x:
			continue
		if hero_pos.z < sprite_pos.z:
			continue
		if hero_pos.y > sprite_pos.y + threshold_y:
			continue
		return true
	return false


func _apply_sprite_alpha(alpha_value: float) -> void:
	var clamped_alpha: float = clampf(alpha_value, 0.0, 1.0)
	if is_equal_approx(_current_alpha, clamped_alpha):
		return
	_current_alpha = clamped_alpha
	var modulate_color: Color = _sprite.modulate
	modulate_color.a = clamped_alpha
	_sprite.modulate = modulate_color
