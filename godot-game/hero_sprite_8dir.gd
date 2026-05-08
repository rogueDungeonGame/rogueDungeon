extends Node3D

@export var texture_base_path: String = "res://placeholders/hero_8dir"
@export var idle_suffix: String = "_idle"
@export var move_suffix: String = "_move"
@export var dead_suffix: String = "_dead"
@export var sprite_pixel_size: float = 0.8

const DIRECTIONS: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const PLACEHOLDER_ANIMATION_LENGTHS := {
	"Idle": 0.6,
	"Run": 0.5,
	"Death_GLTF": 1.0,
	"Attack - 1_GLTF": 0.45,
	"Attack - 2_GLTF": 0.45,
	"Attack - 3_GLTF": 0.45,
	"Stand Ready 1_GLTF": 0.6,
	"Walk_GLTF": 0.5,
	"Attack 1_GLTF": 0.45,
	"Attack 2_GLTF": 0.45,
	"Attack 3_GLTF": 0.45,
	"Stand_GLTF": 0.6,
	"Attack_GLTF": 0.45
}

var _sprite: Sprite3D = null
var _hero_controller: Node = null
var _animation_player: AnimationPlayer = null
var _last_direction_name: String = "s"
var _texture_cache: Dictionary = {}


func _ready() -> void:
	_sprite = find_child("Sprite3D", true, false) as Sprite3D
	if _sprite == null:
		push_warning("hero_sprite_8dir.gd requires a Sprite3D child.")
		set_process(false)
		return
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = maxf(sprite_pixel_size, 0.001)
	_sprite.double_sided = true
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		_animation_player = AnimationPlayer.new()
		_animation_player.name = "AnimationPlayer"
		add_child(_animation_player)
	_ensure_placeholder_animations()
	_hero_controller = _find_hero_controller()
	_preload_textures()
	_apply_visual_state()


func _process(_delta: float) -> void:
	_apply_visual_state()


func _find_hero_controller() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("get_collision_profile_id") and node.has_method("get_hp_bar_anchor_height"):
			return node
		node = node.get_parent()
	return null


func _preload_textures() -> void:
	_texture_cache.clear()
	var normalized_base_path: String = texture_base_path
	if normalized_base_path.ends_with("/"):
		normalized_base_path = normalized_base_path.left(normalized_base_path.length() - 1)
	for direction_name in DIRECTIONS:
		for state_suffix in [idle_suffix, move_suffix, dead_suffix]:
			var texture_key: String = direction_name + state_suffix
			var texture_path: String = "%s/%s.png" % [normalized_base_path, texture_key]
			if not FileAccess.file_exists(texture_path):
				continue
			var texture_res: Texture2D = _load_texture_from_file(texture_path)
			if texture_res != null:
				_texture_cache[texture_key] = texture_res


func _apply_visual_state() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	var direction_name: String = _resolve_direction_name()
	var state_suffix: String = _resolve_state_suffix()
	var texture_key: String = direction_name + state_suffix
	if not _texture_cache.has(texture_key):
		texture_key = direction_name + idle_suffix
	if not _texture_cache.has(texture_key):
		texture_key = "s" + idle_suffix
	var next_texture: Texture2D = _texture_cache.get(texture_key, null) as Texture2D
	if next_texture != null and _sprite.texture != next_texture:
		_sprite.texture = next_texture


func _resolve_state_suffix() -> String:
	var can_show_dead: bool = _texture_cache.has(_last_direction_name + dead_suffix)
	if _hero_controller != null and is_instance_valid(_hero_controller):
		var is_dead: bool = bool(_hero_controller.get("_is_dead"))
		if is_dead and can_show_dead:
			return dead_suffix
		var is_moving: bool = bool(_hero_controller.get("_is_moving"))
		if is_moving and _texture_cache.has(_last_direction_name + move_suffix):
			return move_suffix
	if _animation_player != null and is_instance_valid(_animation_player):
		var current_animation_name: String = String(_animation_player.current_animation).to_lower()
		if current_animation_name.find("death") >= 0 and can_show_dead:
			return dead_suffix
		if (current_animation_name.find("walk") >= 0 or current_animation_name.find("run") >= 0 or current_animation_name.find("move") >= 0) and _texture_cache.has(_last_direction_name + move_suffix):
			return move_suffix
	return idle_suffix


func _resolve_direction_name() -> String:
	var yaw: float = rotation.y
	var angle_deg: float = rad_to_deg(yaw + PI / 2.0)
	angle_deg = fposmod(angle_deg, 360.0)
	var direction_index: int = int(floor((angle_deg + 22.5) / 45.0)) % 8
	_last_direction_name = DIRECTIONS[direction_index]
	return _last_direction_name


func _ensure_placeholder_animations() -> void:
	if _animation_player == null or not is_instance_valid(_animation_player):
		return
	var library: AnimationLibrary = null
	if _animation_player.has_animation_library(""):
		library = _animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		_animation_player.add_animation_library("", library)
	for anim_name_variant in PLACEHOLDER_ANIMATION_LENGTHS.keys():
		var anim_name: String = str(anim_name_variant)
		if library.has_animation(anim_name):
			continue
		var anim := Animation.new()
		anim.length = maxf(float(PLACEHOLDER_ANIMATION_LENGTHS.get(anim_name_variant, 0.5)), 0.05)
		anim.loop_mode = Animation.LOOP_NONE
		library.add_animation(anim_name, anim)


func _load_texture_from_file(texture_path: String) -> Texture2D:
	var image := Image.new()
	var load_error: int = image.load(ProjectSettings.globalize_path(texture_path))
	if load_error != OK:
		load_error = image.load(texture_path)
	if load_error != OK:
		return null
	return ImageTexture.create_from_image(image)
