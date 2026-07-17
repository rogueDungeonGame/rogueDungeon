extends SceneTree

const SOURCE_RELATIVE_PATH := "design-mockups/rogue-dungeon-main-hud-1920x1080-equipment-3x2-skills-3x4.png"
const OUTPUT_RESOURCE_DIR := "res://ui/hud_assets/rogue_dungeon"
const HUD_CLEAR_FILL_COLOR := Color(0.055, 0.045, 0.075, 1.0)
const TRANSPARENT_CLEAR_COLOR := Color(0, 0, 0, 0)

var _exported: Array = []


func _init() -> void:
	var project_dir := ProjectSettings.globalize_path("res://").rstrip("/")
	var repo_dir := project_dir.get_base_dir()
	var source_path := repo_dir.path_join(SOURCE_RELATIVE_PATH)
	var output_dir := ProjectSettings.globalize_path(OUTPUT_RESOURCE_DIR)
	var make_dir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if make_dir_error != OK:
		push_error("Cannot create output directory: %s" % output_dir)
		quit(make_dir_error)
		return

	var source := Image.load_from_file(source_path)
	if source == null:
		push_error("Cannot load source image: %s" % source_path)
		quit(ERR_FILE_CANT_OPEN)
		return
	source.convert(Image.FORMAT_RGBA8)

	var specs := _asset_specs()
	for spec in specs:
		_export_asset(source, output_dir, spec)

	_write_metadata(output_dir)
	_write_preview(output_dir)
	print("Exported %d HUD assets to %s" % [_exported.size(), output_dir])
	quit(OK)


func _asset_specs() -> Array:
	return [
		{
			"name": "hud_bottom_shell",
			"rect": Rect2i(0, 592, 1920, 438),
			"clear_fill_color": HUD_CLEAR_FILL_COLOR,
			"clear":
			[
				Rect2i(22, 35, 333, 357),
				Rect2i(392, 31, 68, 268),
				Rect2i(504, 36, 443, 354),
				Rect2i(1017, 69, 106, 88),
				Rect2i(1149, 69, 106, 88),
				Rect2i(1017, 180, 106, 99),
				Rect2i(1149, 180, 106, 99),
				Rect2i(1017, 296, 106, 105),
				Rect2i(1149, 296, 106, 105),
				Rect2i(1351, 73, 100, 86),
				Rect2i(1482, 73, 100, 86),
				Rect2i(1611, 73, 100, 86),
				Rect2i(1740, 73, 112, 86),
				Rect2i(1851, 136, 9, 16),
				Rect2i(1351, 184, 100, 97),
				Rect2i(1482, 184, 100, 97),
				Rect2i(1611, 184, 100, 97),
				Rect2i(1740, 184, 100, 97),
				Rect2i(1351, 298, 100, 104),
				Rect2i(1482, 298, 100, 104),
				Rect2i(1611, 298, 100, 104),
				Rect2i(1740, 298, 100, 104),
				Rect2i(1085, 16, 125, 31),
				Rect2i(1515, 16, 210, 31)
			],
			"nine_patch_margins": [32, 32, 32, 32]
		},
		{
			"name": "panel_minimap_frame",
			"rect": Rect2i(0, 592, 380, 438),
			"clear": [Rect2i(22, 35, 333, 357)],
			"nine_patch_margins": [30, 30, 30, 30]
		},
		{
			"name": "panel_side_tabs_frame",
			"rect": Rect2i(379, 592, 84, 438),
			"clear_fill_color": HUD_CLEAR_FILL_COLOR,
			"clear": [Rect2i(13, 31, 68, 268)],
			"nine_patch_margins": [18, 18, 18, 18]
		},
		{
			"name": "panel_hero_stats_frame",
			"rect": Rect2i(462, 592, 519, 438),
			"clear": [Rect2i(42, 36, 443, 354)],
			"nine_patch_margins": [34, 34, 34, 34]
		},
		{
			"name": "panel_inventory_frame",
			"rect": Rect2i(980, 592, 333, 438),
			"clear":
			[
				Rect2i(105, 16, 125, 31),
				Rect2i(37, 69, 106, 88),
				Rect2i(169, 69, 106, 88),
				Rect2i(37, 180, 106, 99),
				Rect2i(169, 180, 106, 99),
				Rect2i(37, 296, 106, 105),
				Rect2i(169, 296, 106, 105)
			],
			"nine_patch_margins": [30, 30, 30, 30]
		},
		{
			"name": "panel_skills_frame",
			"rect": Rect2i(1313, 592, 607, 438),
			"clear":
			[
				Rect2i(202, 16, 210, 31),
				Rect2i(38, 73, 100, 86),
				Rect2i(169, 73, 100, 86),
				Rect2i(298, 73, 100, 86),
				Rect2i(427, 73, 112, 86),
				Rect2i(538, 136, 9, 16),
				Rect2i(38, 184, 100, 97),
				Rect2i(169, 184, 100, 97),
				Rect2i(298, 184, 100, 97),
				Rect2i(427, 184, 100, 97),
				Rect2i(38, 298, 100, 104),
				Rect2i(169, 298, 100, 104),
				Rect2i(298, 298, 100, 104),
				Rect2i(427, 298, 100, 104)
			],
			"nine_patch_margins": [30, 30, 30, 30]
		},
		{
			"name": "slot_item_gold",
			"rect": Rect2i(1009, 653, 124, 106),
			"clear": [Rect2i(9, 9, 106, 88)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "slot_item_orange",
			"rect": Rect2i(1141, 653, 124, 106),
			"clear": [Rect2i(9, 9, 106, 88)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "slot_item_red",
			"rect": Rect2i(1009, 763, 124, 117),
			"clear": [Rect2i(9, 9, 106, 99)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "slot_item_blue",
			"rect": Rect2i(1141, 763, 124, 117),
			"clear": [Rect2i(9, 9, 106, 99)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "slot_item_green",
			"rect": Rect2i(1009, 886, 124, 116),
			"clear": [Rect2i(9, 0, 106, 107)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "slot_item_purple",
			"rect": Rect2i(1141, 886, 124, 116),
			"clear": [Rect2i(9, 0, 106, 107)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "skill_button_frame",
			"rect": Rect2i(1341, 653, 120, 106),
			"clear": [Rect2i(10, 10, 100, 86)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "skill_button_wide_frame",
			"rect": Rect2i(1341, 763, 120, 117),
			"clear": [Rect2i(10, 0, 100, 107)],
			"nine_patch_margins": [16, 16, 16, 16]
		},
		{
			"name": "bar_frame_health",
			"rect": Rect2i(527, 839, 157, 38),
			"clear_fill_color": TRANSPARENT_CLEAR_COLOR,
			"clear": [Rect2i(7, 7, 143, 24)],
			"nine_patch_margins": [8, 8, 8, 8]
		},
		{
			"name": "bar_frame_mana",
			"rect": Rect2i(527, 880, 157, 39),
			"clear_fill_color": TRANSPARENT_CLEAR_COLOR,
			"clear": [Rect2i(7, 7, 143, 25)],
			"nine_patch_margins": [8, 8, 8, 8]
		},
		{
			"name": "bar_frame_experience",
			"rect": Rect2i(766, 722, 180, 21),
			"clear_fill_color": TRANSPARENT_CLEAR_COLOR,
			"clear": [Rect2i(4, 5, 148, 12)],
			"nine_patch_margins": [8, 8, 8, 8]
		},
		{
			"name": "ornament_large_corner",
			"rect": Rect2i(457, 589, 70, 72),
			"clear": [],
			"nine_patch_margins": [0, 0, 0, 0]
		},
		{
			"name": "divider_panel_vertical",
			"rect": Rect2i(972, 592, 36, 438),
			"clear": [],
			"nine_patch_margins": [12, 24, 12, 24]
		}
	]


func _export_asset(source: Image, output_dir: String, spec: Dictionary) -> void:
	var rect: Rect2i = spec["rect"]
	var asset := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	asset.fill(Color(0, 0, 0, 0))
	asset.blit_rect(source, rect, Vector2i.ZERO)
	var clear_fill_color: Color = spec.get("clear_fill_color", HUD_CLEAR_FILL_COLOR)
	for clear_rect in spec.get("clear", []):
		_fill_rect(asset, clear_rect, clear_fill_color)

	var output_path := output_dir.path_join("%s.png" % spec["name"])
	var save_error := asset.save_png(output_path)
	if save_error != OK:
		push_error("Cannot save asset: %s" % output_path)
		return

	_exported.append(
		{
			"name": spec["name"],
			"file": ProjectSettings.localize_path(output_path),
			"source_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"nine_patch_margins": spec.get("nine_patch_margins", [0, 0, 0, 0])
		}
	)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	var clipped := rect.intersection(bounds)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return

	for y in range(clipped.position.y, clipped.position.y + clipped.size.y):
		for x in range(clipped.position.x, clipped.position.x + clipped.size.x):
			image.set_pixel(x, y, color)


func _write_metadata(output_dir: String) -> void:
	var metadata_path := output_dir.path_join("rogue_hud_assets.json")
	var file := FileAccess.open(metadata_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write metadata: %s" % metadata_path)
		return

	file.store_string(JSON.stringify({"source": SOURCE_RELATIVE_PATH, "assets": _exported}, "\t"))


func _write_preview(output_dir: String) -> void:
	var preview := Image.create(1500, 980, false, Image.FORMAT_RGBA8)
	preview.fill(Color(0.08, 0.08, 0.08, 1.0))
	_draw_checker(preview, Rect2i(0, 0, preview.get_width(), preview.get_height()))

	var preview_specs := [
		["hud_bottom_shell", Vector2i(20, 20), 0.35],
		["panel_minimap_frame", Vector2i(20, 210), 0.55],
		["panel_side_tabs_frame", Vector2i(245, 210), 0.55],
		["panel_hero_stats_frame", Vector2i(320, 210), 0.55],
		["panel_inventory_frame", Vector2i(630, 210), 0.55],
		["panel_skills_frame", Vector2i(835, 210), 0.55],
		["slot_item_gold", Vector2i(20, 510), 1.0],
		["slot_item_orange", Vector2i(160, 510), 1.0],
		["slot_item_red", Vector2i(300, 510), 1.0],
		["slot_item_blue", Vector2i(440, 510), 1.0],
		["slot_item_green", Vector2i(580, 510), 1.0],
		["slot_item_purple", Vector2i(720, 510), 1.0],
		["skill_button_frame", Vector2i(860, 510), 1.0],
		["skill_button_wide_frame", Vector2i(1000, 510), 1.0],
		["bar_frame_health", Vector2i(20, 680), 1.0],
		["bar_frame_mana", Vector2i(200, 680), 1.0],
		["bar_frame_experience", Vector2i(380, 688), 1.0],
		["ornament_large_corner", Vector2i(600, 660), 1.0],
		["divider_panel_vertical", Vector2i(720, 600), 0.7]
	]

	for preview_spec in preview_specs:
		var asset_path := _asset_path_by_name(str(preview_spec[0]))
		if asset_path.is_empty():
			continue
		var asset := Image.load_from_file(asset_path)
		if asset == null:
			continue
		asset.convert(Image.FORMAT_RGBA8)
		var scale := float(preview_spec[2])
		if not is_equal_approx(scale, 1.0):
			var scaled_size := Vector2i(
				maxi(1, int(round(asset.get_width() * scale))),
				maxi(1, int(round(asset.get_height() * scale)))
			)
			asset.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(asset, Rect2i(Vector2i.ZERO, asset.get_size()), preview_spec[1])

	var preview_path := output_dir.path_join("_preview_rogue_hud_assets.png")
	preview.save_png(preview_path)


func _asset_path_by_name(asset_name: String) -> String:
	for entry in _exported:
		if str(entry["name"]) == asset_name:
			return ProjectSettings.globalize_path(str(entry["file"]))
	return ""


func _draw_checker(image: Image, rect: Rect2i) -> void:
	var cell := 24
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var even := ((x / cell) + (y / cell)) % 2 == 0
			var value := 0.12 if even else 0.17
			image.set_pixel(x, y, Color(value, value, value, 1.0))
