extends CanvasLayer
class_name GameUI

const HUD_STATUS_PANELS_CONTROLLER_SCRIPT := preload("res://hud_status_panels_controller.gd")
const COMMAND_SECTION_CONTROLLER_SCRIPT := preload("res://command_section_controller.gd")
const SKILL_STATUS_SERVICE_SCRIPT := preload("res://skill_status_service.gd")
const OBSERVE_SYNC_SERVICE_SCRIPT := preload("res://observe_sync_service.gd")
const TALENT_POPUP_CONTROLLER_SCRIPT := preload("res://talent_popup_controller.gd")
const TALENT_SELECTION_CONTROLLER_SCRIPT := preload("res://talent_selection_controller.gd")
const HUD_PRESENTER_SCRIPT := preload("res://hud_presenter.gd")
const UI_STATE_SERVICE_SCRIPT := preload("res://ui_state_service.gd")
const INVENTORY_SHOP_CONTROLLER_SCRIPT := preload("res://inventory_shop_controller.gd")
const HUD_BOTTOM_SHELL_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/hud_bottom_shell_exact_ratio_2_5_1_5_2_5.png"
)
const HUD_PANEL_MINIMAP_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/panel_minimap_frame.png"
)
const HUD_PANEL_HERO_STATS_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/panel_hero_stats_frame.png"
)
const HUD_SLOT_ITEM_GOLD_TEXTURE := preload("res://ui/hud_assets/rogue_dungeon/slot_item_gold.png")
const HUD_SKILL_BUTTON_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/skill_button_frame.png"
)
const HUD_BAR_HEALTH_TEXTURE := preload("res://ui/hud_assets/rogue_dungeon/bar_frame_health.png")
const HUD_BAR_MANA_TEXTURE := preload("res://ui/hud_assets/rogue_dungeon/bar_frame_mana.png")
const HUD_PANEL_INVENTORY_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/panel_inventory_frame.png"
)
const HERO_PORTRAIT_MELEE_TEXTURE := preload("res://icons/skills/BTNHeroWarden.png")
const HERO_PORTRAIT_RANGED_TEXTURE := preload("res://icons/skills/BTNRifleman.png")

@export var hero_controller_path: NodePath = NodePath("../HeroController")
@export var enemy_ai_path: NodePath = NodePath("../EnemyAI")
@export var net_session_controller_path: NodePath = NodePath("../NetSessionController")
@export var debug_shop_click_logs: bool = true

var _hero_ctrl: HeroController
var _enemy_ai: Node3D
var _net_ctrl: NetSessionController
var _hero_hp_bar: ProgressBar
var _hero_hp_label: Label
var _hero_mp_bar: ProgressBar
var _hero_mp_label: Label
var _hero_name_label: Label
var _hero_portrait_texture_rect: TextureRect
var _flash_cd_label: Label
var _haste_cd_label: Label
var _q_skill_name_label: Label
var _w_skill_name_label: Label
var _e_skill_name_label: Label
var _e_skill_cd_label: Label
var _r_skill_name_label: Label
var _r_skill_cd_label: Label
var _portrait_rect: ColorRect
var _atk_label: Label
var _def_label: Label
var _spd_label: Label
var _atk_speed_label: Label
var _atk_interval_label: Label
var _atk_range_label: Label
var _cdr_label: Label
var _phys_crit_rate_label: Label
var _phys_crit_mul_label: Label
var _spell_crit_rate_label: Label
var _spell_crit_mul_label: Label
var _hp_regen_label: Label
var _mp_regen_label: Label
var _str_label: Label
var _agi_label: Label
var _int_label: Label
var _inventory_slots: Array[PanelContainer] = []
var _inventory_icons: Array[TextureRect] = []
var _inventory_panel_root: Control
var _command_panel_root: Control
var _shop_debug_label: Label
var _destroy_skill_panel: PanelContainer
var _skill_button_by_key: Dictionary = {}
var _skill_mana_masks: Dictionary = {}
var _skill_cd_masks: Dictionary = {}
var _skill_cd_mask_materials: Dictionary = {}
var _ui_root: Control
var _bottom_panel: Panel
var _hud_scale_root: Control
var _hud_bottom_shell: TextureRect
var _talent_popup_controller = null
var _talent_selection_controller = null
var _hud_status_panels_controller = null
var _command_section_controller = null
var _skill_status_service = null
var _observe_sync_service = null
var _ui_state = null
var _hud_presenter = null
var _inventory_shop_controller = null

const COLOR_BG := Color(0.08, 0.06, 0.12, 0.92)
const COLOR_BORDER := Color(0.78, 0.66, 0.2, 1.0)
const COLOR_BORDER_DARK := Color(0.45, 0.35, 0.1, 1.0)
const COLOR_HP_FULL := Color(0.1, 0.85, 0.1, 1.0)
const COLOR_HP_LOW := Color(0.9, 0.15, 0.1, 1.0)
const COLOR_MP := Color(0.15, 0.35, 0.95, 1.0)
const COLOR_TEXT := Color(0.95, 0.92, 0.78, 1.0)
const COLOR_TEXT_DIM := Color(0.6, 0.55, 0.45, 1.0)
const COLOR_BUTTON_BG := Color(0.12, 0.1, 0.18, 1.0)
const COLOR_BUTTON_BORDER := Color(0.55, 0.45, 0.15, 1.0)
const COLOR_PORTRAIT_BG := Color(0.05, 0.04, 0.08, 1.0)
const COLOR_SKILL_MANA_MASK := Color(0.18, 0.5, 1.0, 0.45)
const SKILL_CD_MASK_SHADER_CODE := "shader_type canvas_item;\nuniform float progress : hint_range(0.0, 1.0) = 0.0;\nuniform vec4 mask_color : source_color = vec4(1.0, 1.0, 1.0, 0.45);\nvoid fragment() {\n\tvec2 p = UV * 2.0 - vec2(1.0);\n\tif (length(p) > 1.0) {\n\t\tCOLOR = vec4(0.0);\n\t} else {\n\t\tfloat angle = atan(p.x, -p.y);\n\t\tif (angle < 0.0) {\n\t\t\tangle += 6.28318530718;\n\t\t}\n\t\tfloat sweep = clamp(progress, 0.0, 1.0) * 6.28318530718;\n\t\tif (angle <= sweep) {\n\t\t\tCOLOR = mask_color;\n\t\t} else {\n\t\t\tCOLOR = vec4(0.0);\n\t\t}\n\t}\n}\n"

const HUD_BASE_WIDTH := 1920.0
const HUD_BASE_HEIGHT := 438.0
const HUD_MIN_SCALE := 0.5


func _ready() -> void:
	_hero_ctrl = get_node_or_null(hero_controller_path) as HeroController
	_enemy_ai = get_node_or_null(enemy_ai_path)
	_net_ctrl = get_node_or_null(net_session_controller_path) as NetSessionController
	_get_talent_selection_controller().randomize_rng()
	_configure_inventory_shop_controller()
	_get_inventory_shop_controller().initialize()
	_build_ui()
	get_viewport().size_changed.connect(_apply_hud_scale)
	_get_inventory_shop_controller().initialize_after_ui_ready()


func _get_talent_popup_controller():
	if _talent_popup_controller == null:
		_talent_popup_controller = TALENT_POPUP_CONTROLLER_SCRIPT.new()
	return _talent_popup_controller


func _get_talent_selection_controller():
	if _talent_selection_controller == null:
		_talent_selection_controller = TALENT_SELECTION_CONTROLLER_SCRIPT.new()
	return _talent_selection_controller


func _get_hud_status_panels_controller():
	if _hud_status_panels_controller == null:
		_hud_status_panels_controller = HUD_STATUS_PANELS_CONTROLLER_SCRIPT.new()
	return _hud_status_panels_controller


func _get_command_section_controller():
	if _command_section_controller == null:
		_command_section_controller = COMMAND_SECTION_CONTROLLER_SCRIPT.new()
	return _command_section_controller


func _get_skill_status_service():
	if _skill_status_service == null:
		_skill_status_service = SKILL_STATUS_SERVICE_SCRIPT.new()
	return _skill_status_service


func _get_observe_sync_service():
	if _observe_sync_service == null:
		_observe_sync_service = OBSERVE_SYNC_SERVICE_SCRIPT.new()
	return _observe_sync_service


func _get_ui_state():
	if _ui_state == null:
		_ui_state = UI_STATE_SERVICE_SCRIPT.new()
	return _ui_state


func _get_hud_presenter():
	if _hud_presenter == null:
		_hud_presenter = HUD_PRESENTER_SCRIPT.new()
	return _hud_presenter


func _get_inventory_shop_controller():
	if _inventory_shop_controller == null:
		_inventory_shop_controller = INVENTORY_SHOP_CONTROLLER_SCRIPT.new()
	return _inventory_shop_controller


func _resolve_net_ctrl_for_controller() -> Node:
	if _net_ctrl == null:
		_net_ctrl = get_node_or_null(net_session_controller_path) as NetSessionController
	return _net_ctrl


func _configure_inventory_shop_controller() -> void:
	_get_inventory_shop_controller().configure(
		self,
		_hero_ctrl,
		_net_ctrl,
		_get_ui_state(),
		Callable(self, "_resolve_net_ctrl_for_controller"),
		Callable(self, "set_observed_peer"),
		Callable(self, "_sync_hero_input_lock_by_ui_state"),
		debug_shop_click_logs
	)


func _build_current_observe_state() -> Dictionary:
	return _get_ui_state().build_observe_snapshot()


func _apply_observe_state_snapshot(state: Dictionary) -> void:
	_get_ui_state().apply_observe_snapshot(state)


func _process(_delta: float) -> void:
	_update_network_view_state()
	_update_talent_selection_flow()
	_update_hud()
	_get_inventory_shop_controller().process()


func get_local_equipment_runtime_state() -> Dictionary:
	return _get_inventory_shop_controller().get_local_equipment_runtime_state()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "UIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_ui_root = root

	var bottom_panel := Panel.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -HUD_BASE_HEIGHT
	bottom_panel.offset_bottom = 0
	bottom_panel.offset_left = 0
	bottom_panel.offset_right = 0
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0, 0, 0, 0)
	bottom_panel.add_theme_stylebox_override("panel", panel_sb)
	root.add_child(bottom_panel)
	_bottom_panel = bottom_panel

	var hud_scale_root := Control.new()
	hud_scale_root.name = "HudScaleRoot"
	hud_scale_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bottom_panel.add_child(hud_scale_root)
	_hud_scale_root = hud_scale_root

	var shell := TextureRect.new()
	shell.name = "HudBottomShell"
	shell.texture = HUD_BOTTOM_SHELL_TEXTURE
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shell.stretch_mode = TextureRect.STRETCH_SCALE
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_scale_root.add_child(shell)
	_hud_bottom_shell = shell

	var content := Control.new()
	content.name = "HudContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_scale_root.add_child(content)

	_build_minimap_section(content)
	_build_hero_info_section(content)
	_build_command_section(content)
	_build_shop_panel(root)
	_build_shop_debug_overlay(root)
	_configure_inventory_shop_refs()
	_build_talent_popup(root)
	_configure_hud_presenter()
	_apply_hud_scale()


func _apply_hud_scale() -> void:
	if _bottom_panel == null or _hud_scale_root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor: float = maxf(HUD_MIN_SCALE, viewport_size.x / HUD_BASE_WIDTH)
	var scaled_height := HUD_BASE_HEIGHT * scale_factor
	var scaled_width := HUD_BASE_WIDTH * scale_factor
	_bottom_panel.offset_top = -scaled_height
	_hud_scale_root.position = Vector2(maxf((viewport_size.x - scaled_width) * 0.5, 0.0), 0.0)
	_hud_scale_root.scale = Vector2(scale_factor, scale_factor)
	_hud_scale_root.size = Vector2(HUD_BASE_WIDTH, HUD_BASE_HEIGHT)


func _configure_hud_presenter() -> void:
	(
		_get_hud_presenter()
		. configure(
			{
				"hero_hp_bar": _hero_hp_bar,
				"hero_hp_label": _hero_hp_label,
				"hero_mp_bar": _hero_mp_bar,
				"hero_mp_label": _hero_mp_label,
				"hero_name_label": _hero_name_label,
				"hero_portrait_texture_rect": _hero_portrait_texture_rect,
				"hero_portrait_melee_texture": HERO_PORTRAIT_MELEE_TEXTURE,
				"hero_portrait_ranged_texture": HERO_PORTRAIT_RANGED_TEXTURE,
				"flash_cd_label": _flash_cd_label,
				"haste_cd_label": _haste_cd_label,
				"q_skill_name_label": _q_skill_name_label,
				"w_skill_name_label": _w_skill_name_label,
				"e_skill_name_label": _e_skill_name_label,
				"e_skill_cd_label": _e_skill_cd_label,
				"r_skill_name_label": _r_skill_name_label,
				"r_skill_cd_label": _r_skill_cd_label,
				"atk_label": _atk_label,
				"def_label": _def_label,
				"spd_label": _spd_label,
				"atk_speed_label": _atk_speed_label,
				"atk_interval_label": _atk_interval_label,
				"atk_range_label": _atk_range_label,
				"cdr_label": _cdr_label,
				"phys_crit_rate_label": _phys_crit_rate_label,
				"phys_crit_mul_label": _phys_crit_mul_label,
				"spell_crit_rate_label": _spell_crit_rate_label,
				"spell_crit_mul_label": _spell_crit_mul_label,
				"hp_regen_label": _hp_regen_label,
				"mp_regen_label": _mp_regen_label,
				"str_label": _str_label,
				"agi_label": _agi_label,
				"int_label": _int_label,
				"skill_button_by_key": _skill_button_by_key,
				"skill_mana_masks": _skill_mana_masks,
				"skill_cd_masks": _skill_cd_masks,
				"skill_cd_mask_materials": _skill_cd_mask_materials,
			},
			{
				"hp_full": COLOR_HP_FULL,
				"hp_low": COLOR_HP_LOW,
			}
		)
	)


func _update_hud() -> void:
	_get_hud_presenter().update(_hero_ctrl, _enemy_ai, _get_ui_state(), _get_skill_status_service())


func _build_shop_debug_overlay(root: Control) -> void:
	_shop_debug_label = Label.new()
	_shop_debug_label.name = "ShopDebugLabel"
	_shop_debug_label.visible = debug_shop_click_logs
	_shop_debug_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_shop_debug_label.offset_left = -760
	_shop_debug_label.offset_top = 12
	_shop_debug_label.offset_right = -12
	_shop_debug_label.offset_bottom = 132
	_shop_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_debug_label.add_theme_font_size_override("font_size", 12)
	_shop_debug_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1.0))
	_shop_debug_label.text = ""
	root.add_child(_shop_debug_label)


func _create_hud_texture_stylebox(
	texture: Texture2D, texture_margins: Array, content_margins: Array = []
) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = texture
	sb.texture_margin_left = float(texture_margins[0])
	sb.texture_margin_top = float(texture_margins[1])
	sb.texture_margin_right = float(texture_margins[2])
	sb.texture_margin_bottom = float(texture_margins[3])
	if content_margins.size() >= 4:
		sb.content_margin_left = float(content_margins[0])
		sb.content_margin_top = float(content_margins[1])
		sb.content_margin_right = float(content_margins[2])
		sb.content_margin_bottom = float(content_margins[3])
	return sb


func _create_hud_transparent_stylebox(content_margins: Array = []) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	if content_margins.size() >= 4:
		sb.content_margin_left = float(content_margins[0])
		sb.content_margin_top = float(content_margins[1])
		sb.content_margin_right = float(content_margins[2])
		sb.content_margin_bottom = float(content_margins[3])
	return sb


func _create_hud_assets_config() -> Dictionary:
	return {
		"minimap_panel_stylebox": _create_hud_transparent_stylebox(),
		"hero_panel_stylebox": _create_hud_transparent_stylebox(),
		"inventory_panel_stylebox": _create_hud_transparent_stylebox(),
		"inventory_slot_stylebox": _create_hud_transparent_stylebox(),
		"skill_button_stylebox": _create_hud_transparent_stylebox(),
		"health_bar_frame_texture": HUD_BAR_HEALTH_TEXTURE,
		"mana_bar_frame_texture": HUD_BAR_MANA_TEXTURE,
		"hero_portrait_melee_texture": HERO_PORTRAIT_MELEE_TEXTURE,
		"hero_portrait_ranged_texture": HERO_PORTRAIT_RANGED_TEXTURE,
	}


func _configure_inventory_shop_refs() -> void:
	(
		_get_inventory_shop_controller()
		. set_ui_refs(
			{
				"inventory_panel_root": _inventory_panel_root,
				"inventory_slots": _inventory_slots,
				"inventory_icons": _inventory_icons,
				"destroy_skill_panel": _destroy_skill_panel,
			}
		)
	)
	_get_inventory_shop_controller().set_shop_debug_label(_shop_debug_label)


func _build_talent_popup(root: Control) -> void:
	_get_talent_popup_controller().build(
		root,
		_get_talent_selection_controller().get_options_per_roll(),
		COLOR_BORDER,
		COLOR_TEXT_DIM,
		Callable(self, "_on_talent_option_pressed")
	)


func _update_talent_selection_flow() -> void:
	var is_observing_any: bool = (
		_is_observing_remote() or _is_observing_boss() or _is_observing_enemy()
	)
	_get_talent_selection_controller().update(
		_hero_ctrl,
		is_observing_any,
		_get_talent_popup_controller(),
		Callable(self, "_sync_hero_input_lock_by_ui_state")
	)


func _sync_hero_input_lock_by_ui_state() -> void:
	if _hero_ctrl == null:
		return
	var should_lock_input: bool = (
		_get_inventory_shop_controller().is_shop_visible()
		or _get_talent_selection_controller().is_popup_open()
	)
	_hero_ctrl.set_input_locked_by_ui(should_lock_input)


func _on_talent_option_pressed(option_index: int) -> void:
	_get_talent_selection_controller().on_option_pressed(
		option_index,
		_hero_ctrl,
		_get_talent_popup_controller(),
		Callable(self, "_sync_hero_input_lock_by_ui_state")
	)


func _build_minimap_section(parent: Control) -> void:
	var container := Control.new()
	container.position = Vector2(42, 54)
	container.size = Vector2(256, 328)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)

	var label := Label.new()
	label.text = "MINIMAP"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)


func _build_hero_info_section(parent: Control) -> void:
	var hud_assets := _create_hud_assets_config()
	var refs: Dictionary = (
		_get_hud_status_panels_controller()
		. build_hero_section(
			parent,
			{
				"fixed_layout": true,
				"hero_rect": Rect2(349, 36, 860, 354),
				"inventory_rect": Rect2(1222, 0, 262, 438),
				"panel_stylebox": hud_assets.get("hero_panel_stylebox"),
				"inventory_slot_stylebox": hud_assets.get("inventory_slot_stylebox"),
				"health_bar_frame_texture": hud_assets.get("health_bar_frame_texture"),
				"mana_bar_frame_texture": hud_assets.get("mana_bar_frame_texture"),
				"inventory_panel_stylebox": hud_assets.get("inventory_panel_stylebox"),
				"portrait_texture": hud_assets.get("hero_portrait_melee_texture"),
				"portrait_size": 158.0,
				"portrait_inset": 6,
				"inventory_slot_rects":
				[
					Rect2(30, 73, 79, 91),
					Rect2(126, 73, 79, 91),
					Rect2(30, 176, 79, 91),
					Rect2(126, 176, 79, 91),
					Rect2(30, 278, 79, 91),
					Rect2(126, 278, 79, 91),
				],
				"inventory_icon_inset": 6,
				"stat_font_size": 18,
				"panel_bg": Color(0.06, 0.05, 0.1, 1.0),
				"panel_border": COLOR_BORDER_DARK,
				"portrait_bg": COLOR_PORTRAIT_BG,
				"accent_color": COLOR_BORDER,
				"text_color": COLOR_TEXT,
				"text_dim": COLOR_TEXT_DIM,
				"hp_bar_color": COLOR_HP_FULL,
				"mp_bar_color": COLOR_MP,
			},
			{
				"on_inv_slot_input": Callable(self, "_on_inv_slot_input"),
				"on_inv_slot_mouse_entered": Callable(self, "_on_inv_slot_mouse_entered"),
				"on_inv_slot_mouse_exited": Callable(self, "_on_inv_slot_mouse_exited"),
			}
		)
	)
	_portrait_rect = refs.get("portrait_rect", null) as ColorRect
	_hero_portrait_texture_rect = refs.get("hero_portrait_texture_rect", null) as TextureRect
	_hero_name_label = refs.get("hero_name_label", null) as Label
	_hero_hp_bar = refs.get("hero_hp_bar", null) as ProgressBar
	_hero_hp_label = refs.get("hero_hp_label", null) as Label
	_hero_mp_bar = refs.get("hero_mp_bar", null) as ProgressBar
	_hero_mp_label = refs.get("hero_mp_label", null) as Label
	_atk_label = refs.get("atk_label", null) as Label
	_def_label = refs.get("def_label", null) as Label
	_spd_label = refs.get("spd_label", null) as Label
	_atk_speed_label = refs.get("atk_speed_label", null) as Label
	_atk_interval_label = refs.get("atk_interval_label", null) as Label
	_atk_range_label = refs.get("atk_range_label", null) as Label
	_cdr_label = refs.get("cdr_label", null) as Label
	_phys_crit_rate_label = refs.get("phys_crit_rate_label", null) as Label
	_phys_crit_mul_label = refs.get("phys_crit_mul_label", null) as Label
	_spell_crit_rate_label = refs.get("spell_crit_rate_label", null) as Label
	_spell_crit_mul_label = refs.get("spell_crit_mul_label", null) as Label
	_hp_regen_label = refs.get("hp_regen_label", null) as Label
	_mp_regen_label = refs.get("mp_regen_label", null) as Label
	_str_label = refs.get("str_label", null) as Label
	_agi_label = refs.get("agi_label", null) as Label
	_int_label = refs.get("int_label", null) as Label
	_inventory_panel_root = refs.get("inventory_panel_root", null) as Control
	_inventory_slots.clear()
	_inventory_icons.clear()
	var inventory_slots_variant: Variant = refs.get("inventory_slots", [])
	if inventory_slots_variant is Array:
		_inventory_slots.assign(inventory_slots_variant)
	var inventory_icons_variant: Variant = refs.get("inventory_icons", [])
	if inventory_icons_variant is Array:
		_inventory_icons.assign(inventory_icons_variant)


func _build_command_section(parent: Control) -> void:
	var hud_assets := _create_hud_assets_config()
	var refs: Dictionary = (
		_get_command_section_controller()
		. build(
			parent,
			{
				"fixed_layout": true,
				"panel_rect": Rect2(1484, 0, 436, 438),
				"skill_slot_rects":
				[
					Rect2(27, 73, 79, 91),
					Rect2(120, 73, 79, 91),
					Rect2(212, 73, 79, 91),
					Rect2(305, 73, 79, 91),
					Rect2(27, 176, 79, 91),
					Rect2(120, 176, 79, 91),
					Rect2(212, 176, 79, 91),
					Rect2(305, 176, 79, 91),
					Rect2(27, 278, 79, 91),
					Rect2(120, 278, 79, 91),
					Rect2(212, 278, 79, 91),
					Rect2(305, 278, 79, 91),
				],
				"skill_button_stylebox": hud_assets.get("skill_button_stylebox"),
				"skill_button_size": Vector2(79, 91),
				"skill_slot_count": 12,
				"panel_bg": Color(0.06, 0.05, 0.1, 1.0),
				"panel_border": COLOR_BORDER_DARK,
				"button_bg_active": COLOR_BUTTON_BG,
				"button_bg_inactive": Color(0.08, 0.07, 0.1, 1.0),
				"button_border_active": COLOR_BUTTON_BORDER,
				"button_border_inactive": Color(0.25, 0.2, 0.15, 1.0),
				"accent_color": COLOR_BORDER,
				"text_color": COLOR_TEXT,
				"text_dim": COLOR_TEXT_DIM,
				"cooldown_text_color": Color(1.0, 0.5, 0.3, 1.0),
				"skill_mana_mask_color": COLOR_SKILL_MANA_MASK,
				"skill_cd_mask_shader_code": SKILL_CD_MASK_SHADER_CODE,
				"skill_data":
				[
					{"key": "Q", "name": "闪现", "active": true},
					{"key": "W", "name": "急速", "active": true},
					{"key": "E", "name": "回避", "active": true},
					{"key": "R", "name": "被动", "active": true},
					{"key": "A", "name": "攻击", "active": true},
					{"key": "F", "name": "摧毁", "active": true},
					{"key": "S", "name": "停止", "active": false},
					{"key": "P", "name": "巡逻", "active": false},
				],
			}
		)
	)
	_command_panel_root = refs.get("command_panel_root", null) as Control
	_skill_button_by_key = refs.get("skill_button_by_key", {})
	_skill_mana_masks = refs.get("skill_mana_masks", {})
	_skill_cd_masks = refs.get("skill_cd_masks", {})
	_skill_cd_mask_materials = refs.get("skill_cd_mask_materials", {})
	_flash_cd_label = refs.get("flash_cd_label", null) as Label
	_haste_cd_label = refs.get("haste_cd_label", null) as Label
	_q_skill_name_label = refs.get("q_skill_name_label", null) as Label
	_w_skill_name_label = refs.get("w_skill_name_label", null) as Label
	_e_skill_name_label = refs.get("e_skill_name_label", null) as Label
	_e_skill_cd_label = refs.get("e_skill_cd_label", null) as Label
	_r_skill_name_label = refs.get("r_skill_name_label", null) as Label
	_r_skill_cd_label = refs.get("r_skill_cd_label", null) as Label
	_destroy_skill_panel = refs.get("destroy_skill_panel", null) as PanelContainer


func _variant_to_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return roundi(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_int():
			return text.to_int()
	return fallback


func _variant_to_bool(value: Variant, fallback: bool = false) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return absf(value) > 0.0001
	if value is String:
		var text: String = (value as String).strip_edges().to_lower()
		if text == "true" or text == "1" or text == "yes" or text == "on":
			return true
		if text == "false" or text == "0" or text == "no" or text == "off":
			return false
	return fallback


func set_observed_peer(peer_id: int) -> void:
	var result: Dictionary = _get_observe_sync_service().apply_observed_peer(
		_build_current_observe_state(), peer_id
	)
	if not _variant_to_bool(result.get("changed", false), false):
		return
	_apply_observe_state_snapshot(result.get("state", {}))
	_get_inventory_shop_controller().on_observe_state_changed(
		_variant_to_bool(result.get("reset_local_destroy_mode", false), false)
	)


func set_observed_boss(enabled: bool) -> void:
	var result: Dictionary = _get_observe_sync_service().apply_observed_boss(
		_build_current_observe_state(), enabled
	)
	if not _variant_to_bool(result.get("changed", false), false):
		return
	_apply_observe_state_snapshot(result.get("state", {}))
	_get_inventory_shop_controller().on_observe_state_changed(false)


func set_observed_enemy(enemy_state_variant: Variant) -> void:
	var result: Dictionary = _get_observe_sync_service().apply_observed_enemy(
		_build_current_observe_state(), enemy_state_variant
	)
	if not _variant_to_bool(result.get("changed", false), false):
		return
	_apply_observe_state_snapshot(result.get("state", {}))
	_get_inventory_shop_controller().on_observe_state_changed(false)


func _update_network_view_state() -> void:
	if _net_ctrl == null:
		_net_ctrl = get_node_or_null(net_session_controller_path) as NetSessionController
	var result: Dictionary = _get_observe_sync_service().update_network_view_state(
		_net_ctrl, _build_current_observe_state()
	)
	_apply_observe_state_snapshot(result.get("state", {}))
	_sync_local_equipment_state_from_authority()
	if _variant_to_bool(result.get("clear_observed_peer", false), false):
		set_observed_peer(0)


func _sync_local_equipment_state_from_authority() -> void:
	var authority_state: Dictionary = (
		_get_observe_sync_service()
		. fetch_local_authority_equipment_state(
			_net_ctrl, _is_observing_remote(), int(_get_ui_state().self_peer_id)
		)
	)
	if authority_state.is_empty():
		return
	if _get_inventory_shop_controller().is_local_equipment_state_synced(authority_state):
		return
	apply_authoritative_equipment_commit({"state": authority_state})


func _is_observing_boss() -> bool:
	return _get_ui_state().is_observing_boss()


func _is_observing_enemy() -> bool:
	return _get_ui_state().is_observing_enemy()


func _is_observing_remote() -> bool:
	return _get_ui_state().is_observing_remote()


func set_shop_access_enabled(enabled: bool) -> void:
	_get_inventory_shop_controller().set_shop_access_enabled(enabled)


func _build_shop_panel(root: Control) -> void:
	_get_inventory_shop_controller().build_shop_panel(root)


func apply_authoritative_equipment_commit(commit: Dictionary) -> void:
	_get_inventory_shop_controller().apply_authoritative_equipment_commit(commit)


func notify_local_battle_phase_started() -> void:
	_get_inventory_shop_controller().notify_local_battle_phase_started()


func notify_local_battle_phase_ended() -> void:
	_get_inventory_shop_controller().notify_local_battle_phase_ended()


func apply_local_floor_clear_progression() -> void:
	_get_inventory_shop_controller().apply_local_floor_clear_progression()


func authority_ensure_peer_equipment_state(peer_id: int, baseline_state: Dictionary = {}) -> void:
	_get_inventory_shop_controller().authority_ensure_peer_equipment_state(peer_id, baseline_state)


func authority_drop_peer_state(peer_id: int) -> void:
	_get_inventory_shop_controller().authority_drop_peer_state(peer_id)


func authority_get_peer_equipment_state(peer_id: int) -> Dictionary:
	return _get_inventory_shop_controller().authority_get_peer_equipment_state(peer_id)


func authority_grant_gold_reward(peer_id: int, amount: int) -> Dictionary:
	return _get_inventory_shop_controller().authority_grant_gold_reward(peer_id, amount)


func authority_handle_equipment_action(
	peer_id: int, request: Dictionary, baseline_state: Dictionary = {}
) -> Dictionary:
	return _get_inventory_shop_controller().authority_handle_equipment_action(
		peer_id, request, baseline_state
	)


func _input(event: InputEvent) -> void:
	_get_inventory_shop_controller().handle_input(event)


func _on_inv_slot_input(event: InputEvent, index: int) -> void:
	_get_inventory_shop_controller().on_inventory_slot_input(event, index)


func _on_inv_slot_mouse_entered(index: int) -> void:
	_get_inventory_shop_controller().on_inventory_slot_mouse_entered(index)


func _on_inv_slot_mouse_exited(index: int) -> void:
	_get_inventory_shop_controller().on_inventory_slot_mouse_exited(index)
