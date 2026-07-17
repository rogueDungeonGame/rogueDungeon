extends Node3D

const CombatSceneUtils := preload("res://combat_scene_utils.gd")
const HeroStatsService := preload("res://hero_stats_service.gd")

@export var hero_path: NodePath = NodePath("herowarden")
@export var move_speed: float = 335.0
@export var attack_range: float = 250.0
@export var engage_range: float = 900.0
@export var auto_attack_on_enemy_engage: bool = true
@export var enemy_group_name: StringName = &"enemy"
@export var max_hp: int = 550
@export var damage_per_hit: int = 20
@export var attack_speed: float = 0.625
@export var hero_level: int = 1
@export var primary_attribute: String = "敏捷"
@export var strength_base: int = 24
@export var agility_base: int = 12
@export var intelligence_base: int = 14
@export var strength_growth: float = 2.5
@export var agility_growth: float = 2.0
@export var intelligence_growth: float = 1.8
@export var base_hp_flat: int = -50
@export var base_mana_flat: int = 30
@export var initial_mana_multiplier: float = 2.0
@export var base_damage_flat: int = 8
@export var base_armor_flat: float = 3.3
@export var base_attack_speed: float = 0.50403225
@export var base_physical_crit_chance: float = 0.0
@export var base_physical_crit_multiplier: float = 2.0
@export var base_spell_crit_chance: float = 0.0
@export var base_spell_crit_multiplier: float = 2.0
@export_range(0.0, 100.0, 0.1) var magic_immunity_rate: float = 0.0
@export var base_hp_regen_flat: float = 0.0
@export var base_mana_regen_flat: float = 0.0
@export var base_cooldown_reduction_percent: float = 0.0
@export var death_animation: String = "Death_GLTF"
@export var hp_bar_height: float = 200.0
@export var hp_bar_width: float = 180.0
@export var attack_count_label_height_offset: float = 14.0
@export var attack_count_label_pixel_size: float = 0.0007
@export var attack_count_label_font_size: int = 64
@export var idle_animation: String = "Idle"
@export var walk_animation: String = "Run"
@export var attack_animation_1: String = "Attack - 1_GLTF"
@export var attack_animation_2: String = "Attack - 2_GLTF"
@export var attack_animation_3: String = "Attack - 3_GLTF"
@export var melee_attack_damage_timing_ratio: float = 0.45
@export var ranged_attack_damage_timing_ratio: float = 0.33333334
@export var flash_max_distance: float = 2000.0
@export var flash_cooldown_time: float = 6.0
@export var flash_origin_damage_radius: float = 500.0
@export var flash_destination_damage_radius: float = 500.0
@export var flash_damage: int = 100
@export var flash_mana_cost: int = 100
@export var haste_multiplier: float = 2.0
@export var haste_duration: float = 10.0
@export var haste_cooldown_time: float = 25.0
@export var haste_mana_cost: int = 40
@export var poison_damage_per_second: int = 20
@export var poison_duration: float = 15.0
@export var poison_tick_interval: float = 1.0
@export var passive_transform_attack_count: int = 20
@export var transform_duration: float = 8.0
@export var transformed_attack_speed_multiplier: float = 2.0
@export var transformed_attack_animation_1: String = "Attack - 1_GLTF"
@export var transformed_attack_animation_2: String = "Attack - 2_GLTF"
@export
var transformed_model_scene: PackedScene = preload("res://placeholders/hero_transformed_2d.tscn")
@export var flash_effect_scene: PackedScene = preload(
	"res://effects/HeroWarden/FanOfKnivesCaster/FanOfKnivesCaster.glb"
)
@export var move_confirmation_scene: PackedScene = preload("res://modles/Confirmation.glb")
@export var move_confirmation_scale: Vector3 = Vector3.ONE
@export var move_confirmation_lifetime: float = 2.0
@export var cursor_default_texture: Texture2D = preload("res://icons/passives/frame_00_r0c0.png")
@export
var cursor_enemy_texture: Texture2D = preload("res://icons/passives/frame_24_r3c0_red_variant.png")
@export
var cursor_attack_default_texture: Texture2D = preload("res://icons/passives/frame_19_r2c3.png")
@export var cursor_attack_enemy_texture: Texture2D = preload(
	"res://icons/passives/frame_23_r2c7_red_variant.png"
)
@export var cursor_r_skill_texture: Texture2D
@export var ranged_r_cursor_scale_multiplier: float = 1.5
@export var ranged_r_ground_selector_enabled: bool = true
@export var ranged_r_ground_selector_alpha: float = 0.85
@export var ranged_r_ground_selector_height_offset: float = 2.0
@export var ranged_r_impact_scale_multiplier: float = 3.0
@export var cursor_hotspot: Vector2 = Vector2.ZERO
@export var melee_skill_q_name: String = "刀阵旋风"
@export var melee_skill_w_name: String = "淬毒环刃"
@export var melee_skill_e_name: String = "淬魂匕"
@export var melee_skill_passive_name: String = "杀戮天神"
@export var ranged_skill_q_name: String = "穿透弹"
@export var ranged_skill_w_name: String = "脚底抹油"
@export var ranged_skill_e_name: String = "精准射击"
@export var ranged_skill_passive_name: String = "精准射击"
@export var ranged_skill_r_name: String = "地毯式轰炸"
@export var evasive_mana_cost: int = 35
@export var evasive_cooldown_time: float = 6.0
@export var melee_evasive_distance: float = 240.0
@export var melee_evasive_duration: float = 0.2
@export var ranged_evasive_distance: float = 280.0
@export var ranged_evasive_duration: float = 0.22
@export var ranged_attack_range: float = 600.0
@export var ranged_flash_max_distance: float = 1400.0
@export var ranged_flash_cooldown_time: float = 12.0
@export var ranged_flash_damage: int = 120
@export var ranged_flash_mana_cost: int = 100
@export var ranged_haste_multiplier: float = 2.4
@export var ranged_haste_duration: float = 6.0
@export var ranged_haste_cooldown_time: float = 15.0
@export var ranged_haste_mana_cost: int = 30
@export var ranged_haste_move_speed_bonus: float = 600.0
@export var ranged_haste_walk_anim_speed_multiplier: float = 3.0
@export var ranged_w_backstep_distance: float = 200.0
@export var ranged_w_backstep_duration: float = 0.28
@export var ranged_poison_damage_per_second: int = 20
@export var ranged_poison_duration: float = 4.0
@export var ranged_poison_tick_interval: float = 0.5
@export var ranged_passive_transform_attack_count: int = 16
@export var ranged_idle_animation: String = "Stand_GLTF"
@export var ranged_walk_animation: String = "Walk_GLTF"
@export var ranged_death_animation: String = "Death_GLTF"
@export var ranged_attack_animation_1: String = "Attack_GLTF"
@export var ranged_attack_animation_2: String = ""
@export var ranged_attack_animation_3: String = ""
@export var ranged_model_scale_multiplier: float = 1.6666667
@export var ranged_q_ray_length: float = 3000.0
@export var ranged_q_ray_damage: int = 100
@export var ranged_q_ray_hit_radius: float = 100.0
@export var ranged_q_ray_knockback_distance: float = 100.0
@export var ranged_q_ray_knockback_duration: float = 0.2
@export var ranged_q_ray_knockback_priority: int = 5
@export var ranged_q_backstep_distance: float = 200.0
@export var ranged_q_backstep_duration: float = 0.28
@export var ranged_q_ray_width: float = 24.0
@export var ranged_q_ray_thickness: float = 8.0
@export var ranged_q_ray_height_offset: float = 80.0
@export var ranged_q_ray_lifetime: float = 0.2
@export var ranged_r_missile_scene: PackedScene
@export var ranged_r_impact_scene: PackedScene
@export var ranged_r_damage: int = 120
@export var ranged_r_radius: float = 250.0
@export var ranged_r_mana_cost: int = 120
@export var ranged_r_cooldown_time: float = 12.0
@export var ranged_r_cast_max_distance: float = 3000.0
@export var ranged_r_projectile_speed: float = 1800.0
@export var ranged_r_projectile_min_flight_time: float = 0.12
@export var dynamic_detour_enabled: bool = true
@export var dynamic_detour_duration_sec: float = 0.45
@export var dynamic_detour_side_strength: float = 0.95
@export var dynamic_blocker_avoid_radius: float = 88.0
@export var start_area_full_recovery_enabled: bool = true
@export var start_area_full_recovery_radius_fallback: float = 1200.0
@export var melee_body_radius: float = 50.0
@export var melee_body_height: float = 150.0
@export var melee_body_offset_y: float = 75.0
@export var melee_head_anchor_height: float = 200.0
@export var melee_projectile_origin_offset: Vector3 = Vector3(0.0, 100.0, 16.0)
@export var ranged_body_radius: float = 50.0
@export var ranged_body_height: float = 150.0
@export var ranged_body_offset_y: float = 75.0
@export var ranged_head_anchor_height: float = 200.0
@export var ranged_projectile_origin_offset: Vector3 = Vector3(0.0, 95.0, 22.0)
@export var transformed_body_radius: float = 50.0
@export var transformed_body_height: float = 150.0
@export var transformed_body_offset_y: float = 75.0
@export var transformed_head_anchor_height: float = 220.0
@export var transformed_projectile_origin_offset: Vector3 = Vector3(0.0, 120.0, 20.0)
@export var selection_anchor_height: float = 0.0
@export var shadow_anchor_height: float = 0.0

var _hero: Node3D
var _animation_player: AnimationPlayer
var _target_position: Vector3
var _target_enemy: Node3D = null
var _plane_height: float = 0.0
var _has_move_target: bool = false
var _is_moving: bool = false
var _is_attacking: bool = false
var _attack_mode: bool = false
var _focus_lock: bool = false
var _current_attack_index: int = 0
var _attack_animations: Array[String] = []
var _auto_aggro_initialized: bool = false
var _was_in_enemy_engage_range: bool = false
var _last_auto_enemy: Node3D = null
var _attack_cooldown: float = 0.0
var _current_hp: int = 0
var _is_dead: bool = false
var _hp_bar: MeshInstance3D
var _attack_count_label: Label3D
var _hp_bar_material: ShaderMaterial
var _hp_bar_anchor_height: float = 0.0
var _death_finalized: bool = false
var _flash_mode: bool = false
var _r_skill_mode: bool = false
var _flash_cooldown: float = 0.0
var _e_cooldown: float = 0.0
var _r_cooldown: float = 0.0
var _haste_active: bool = false
var _haste_time_left: float = 0.0
var _haste_cooldown: float = 0.0
var _poison_targets: Dictionary = {}
var _attack_count: int = 0
var _is_transformed: bool = false
var _transform_time_left: float = 0.0
var _original_hero: Node3D = null
var _transformed_hero: Node3D = null
var strength: int = 0
var agility: int = 0
var intelligence: int = 0
var armor: float = 0.0
var max_mana: int = 0
var current_mana: int = 0
var hp_regen_per_second: float = 0.0
var mana_regen_per_second: float = 0.0
var attack_interval: float = 0.0
var attack_speed_percent_total: float = 0.0
var cooldown_reduction_percent_total: float = 0.0
var physical_crit_chance: float = 0.0
var physical_crit_multiplier: float = 2.0
var spell_crit_chance: float = 0.0
var spell_crit_multiplier: float = 2.0
var _equip_strength_bonus: int = 0
var _equip_agility_bonus: int = 0
var _equip_intelligence_bonus: int = 0
var _equip_hp_bonus: int = 0
var _equip_mana_bonus: int = 0
var _equip_damage_bonus: int = 0
var _equip_armor_bonus: float = 0.0
var _equip_attack_range_bonus: float = 0.0
var _equip_attack_speed_percent_bonus: float = 0.0
var _equip_move_speed_bonus: float = 0.0
var _equip_hp_regen_bonus: float = 0.0
var _equip_cooldown_reduction_percent_bonus: float = 0.0
var _equip_physical_crit_chance_bonus: float = 0.0
var _equip_physical_crit_multiplier_bonus: float = 0.0
var _equip_spell_crit_chance_bonus: float = 0.0
var _equip_spell_crit_multiplier_bonus: float = 0.0
var _equip_spell_damage_percent_bonus: float = 0.0
var _equip_magic_damage_reduction_percent_bonus: float = 0.0
var _equip_spark_effects: Dictionary = {}
var _equip_charge_effects: Dictionary = {}
var _equip_necromancy_effects: Dictionary = {}
var _equip_battle_banner_effects: Dictionary = {}
var _equip_battle_prep_effects: Dictionary = {}
var _equip_settlement_effects: Dictionary = {}
var _equip_coin_effects: Dictionary = {}
var _spark_permanent_hp_bonus_from_procs: int = 0
var _charge_permanent_hp_bonus_from_procs: int = 0
var _spark_permanent_attack_speed_bonus_from_soul: float = 0.0
var _spark_attack_speed_stack_time_lefts: Array[float] = []
var _spark_spell_damage_buff_time_left: float = 0.0
var _necro_bonus_max_hp_from_summons: int = 0
var _necro_bonus_int_from_flute: int = 0
var _necro_flute_summon_stacks: int = 0
var _necro_summon_power_percent_from_spells: float = 0.0
var _necro_charge_stacks: int = 0
var _necro_last_battle_phase_active: bool = false
var _battle_banner_elapsed_sec: float = 0.0
var _battle_banner_last_phase_active: bool = false
var _battle_banner_emitted_strength_bonus: int = 0
var _battle_banner_emitted_agility_bonus: int = 0
var _battle_banner_emitted_intelligence_bonus: int = 0
var _battle_banner_emitted_damage_bonus: int = 0
var _battle_banner_emitted_attack_speed_percent_bonus: float = 0.0
var _battle_banner_emitted_spell_damage_percent_bonus: float = 0.0
var _battle_banner_applied_strength_bonus: int = 0
var _battle_banner_applied_agility_bonus: int = 0
var _battle_banner_applied_intelligence_bonus: int = 0
var _battle_banner_applied_damage_bonus: int = 0
var _battle_banner_applied_attack_speed_percent_bonus: float = 0.0
var _battle_banner_applied_spell_damage_percent_bonus: float = 0.0
var _settlement_permanent_hp_bonus: int = 0
var _settlement_permanent_agility_bonus: int = 0
var _settlement_permanent_intelligence_bonus: int = 0
var _settlement_permanent_physical_crit_chance_bonus: float = 0.0
var _battle_prep_last_phase_active: bool = false
var _battle_prep_revive_charges: int = 0
var _battle_prep_fatal_guard_charges: int = 0
var _coin_revive_charges_used: int = 0
var _local_battle_phase_active_notified: bool = false
var _talent_bundle: Dictionary = {}
var _input_locked_by_ui: bool = false
var _enemy_damage_bonus_runtime: Dictionary = {}
var _network_attack_lock_active: bool = false
var _network_attack_lock_required_ack_seq: int = -1
var _network_attack_lock_timeout_at_ms: int = 0
var _base_move_speed: float = -1.0
var _base_attack_range: float = -1.0
var _hp_regen_pool: float = 0.0
var _mana_regen_pool: float = 0.0
var _slow_percent: float = 0.0
var _slow_time_left: float = 0.0
var _last_stat_level: int = -1
var _nav_agent: NavigationAgent3D
var shop_clicked: bool = false
var shop_clicked_owner_peer_id: int = 0
var shop_click_debug_last_result: String = "-"
var inventory: Array = []
var _using_enemy_cursor: bool = false
var _using_attack_cursor: bool = false
var _using_selected_cursor: bool = false
var _using_r_skill_cursor: bool = false
var _cursor_initialized: bool = false
var _r_skill_cursor_resource_checked: bool = false
var _r_skill_cursor_visual_texture: Texture2D
var _r_skill_cursor_visual_source: Texture2D
var _r_skill_cursor_visual_scale_cached: float = -1.0
var _r_skill_ground_selector_root: Node3D
var _r_skill_ground_selector_mesh: MeshInstance3D
var _r_skill_ground_selector_material: StandardMaterial3D
var _r_skill_ground_selector_texture_source: Texture2D
var _r_skill_missile_resource_checked: bool = false
var _r_skill_impact_resource_checked: bool = false
var _destroy_cursor_mode: bool = false
var _destroy_hover_item: bool = false
var hero_id: int = 1
var hero_profile: String = "守望者"
var skill_q_id: int = 101
var skill_q_name: String = "刀阵旋风"
var skill_w_id: int = 102
var skill_w_name: String = "淬毒环刃"
var skill_e_id: int = 104
var skill_e_name: String = "淬魂匕"
var skill_e_active: bool = false
var skill_passive_id: int = 103
var skill_passive_name: String = "杀戮天神"
var skill_r_id: int = 0
var skill_r_name: String = "被动"
var skill_r_active: bool = false
var _warden_ring_attacks_left: int = 0
var _rifleman_precision_counter: int = 0
var _melee_profile_cache: Dictionary = {}
var _current_collision_profile: Dictionary = {}
var _current_collision_profile_id: String = ""
var _ranged_q_backstep_tween: Tween
var _ranged_q_backstep_active: bool = false
var _ranged_q_backstep_time_left: float = 0.0
var _ranged_q_backstep_total_time: float = 0.0
var _ranged_q_backstep_start_pos: Vector3 = Vector3.ZERO
var _ranged_q_backstep_end_pos: Vector3 = Vector3.ZERO
var _resolved_idle_animation: String = ""
var _resolved_walk_animation: String = ""
var _resolved_death_animation: String = ""
var _start_area_center: Vector3 = Vector3.ZERO
var _start_area_full_recovery_radius_runtime: float = 0.0
var _has_start_area_recovery_zone: bool = false
var _network_command_seq: int = 0
var _network_last_command: Dictionary = {}
var _network_skill_event_seq: int = 0
var _network_last_skill_event: Dictionary = {}
var _pending_damage_confirmations: Dictionary = {}
var _dynamic_detour_time_left: float = 0.0
var _dynamic_detour_side: float = 1.0
var _stop_move_hold_active: bool = false
var _attack_damage_schedule_id: int = 0
var hero_selection_confirmed: bool = false

const STR_HP_PER_POINT: int = 25
const INT_MANA_PER_POINT: int = 15
const AGI_ARMOR_PER_POINT: float = 0.3
const AGI_ATTACK_SPEED_PER_POINT: float = 0.02
const STR_HP_REGEN_PER_POINT: float = 0.05
const INT_MANA_REGEN_PER_POINT: float = 0.05
const WC3_MIN_MOVE_SPEED: float = 100.0
const WC3_MAX_MOVE_SPEED: float = 522.0
const WC3_IAS_MIN: float = -80.0
const WC3_IAS_MAX: float = 400.0
const MAX_COOLDOWN_REDUCTION_PERCENT: float = 80.0
const HP_BAR_HEIGHT_OFFSET: float = 200.0
const ARMOR_K_MELEE_DEFAULT: float = 0.06
const NEGATIVE_ARMOR_BASE_MELEE_DEFAULT: float = 0.94
const HERO_ID_MELEE: int = 1
const HERO_ID_RANGED: int = 2
const COLLISION_PROFILE_MELEE: String = "hero_melee"
const COLLISION_PROFILE_RANGED: String = "hero_ranged"
const COLLISION_PROFILE_TRANSFORMED: String = "hero_transformed"
const COLLISION_PROFILE_ID_META_KEY: String = "collision_profile_id"
const ANCHOR_ROOT_NODE_NAME: String = "AnchorRoot"
const HEAD_ANCHOR_NODE_NAME: String = "HeadAnchor"
const PROJECTILE_ORIGIN_NODE_NAME: String = "ProjectileOrigin"
const SHADOW_ANCHOR_NODE_NAME: String = "ShadowAnchor"
const SELECTION_ANCHOR_NODE_NAME: String = "SelectionAnchor"
const AUTO_GENERATED_ANCHOR_META_KEY: String = "auto_generated_anchor"
const MAP_WARDEN_MAX_HP: int = 550
const MAP_WARDEN_MAX_MANA: int = 270
const MAP_WARDEN_MOVE_SPEED: float = 335.0
const MAP_WARDEN_ATTACK_INTERVAL: float = 0.8
const MAP_RIFLEMAN_MAX_HP: int = 550
const MAP_RIFLEMAN_MAX_MANA: int = 300
const MAP_RIFLEMAN_MOVE_SPEED: float = 270.0
const MAP_RIFLEMAN_ATTACK_RANGE: float = 1800.0
const MAP_RIFLEMAN_ATTACK_INTERVAL: float = 0.85
const SKILL_ID_Q_FLASH: int = 101
const SKILL_ID_W_HASTE: int = 102
const SKILL_ID_E_EVASIVE: int = 104
const SKILL_ID_PASSIVE_TRANSFORM: int = 103
const SKILL_ID_Q_RANGED_SHOT: int = 201
const SKILL_ID_W_RANGED_SPEED: int = 202
const SKILL_ID_PASSIVE_RANGED: int = 203
const SKILL_ID_R_RANGED_CLUSTER: int = 204
const MAX_CURSOR_TEXTURE_SIZE: int = 256
const R_SKILL_CURSOR_TEXTURE_PATH: String = "res://effects/SkillRangeSelector/ExtraTextures/SpellAreaOfEffect.png"
const R_SKILL_MISSILE_SCENE_PATH: String = "res://effects/HeroTinker/ClusterRocketsWeaponMissile/RocketMissile_clean.glb"
const R_SKILL_MISSILE_SCENE_FALLBACK_PATH: String = "res://effects/HeroTinker/ClusterRocketsWeaponMissile/RocketMissile.glb"
const R_SKILL_IMPACT_SCENE_PATH: String = "res://effects/HeroTinker/ClusterRocketsMissile/TinkerRocketMissile.glb"
const RANGED_R_LOGIC_POINT_LIFETIME_SEC: float = 0.3
const INTERACTION_RAY_MASK: int = (1 << 0) | (1 << 1)
const OBSTACLE_RAY_MASK: int = 1 << 0
const OBSTACLE_STEER_ANGLES := [20.0, -20.0, 40.0, -40.0, 60.0, -60.0, 80.0, -80.0, 100.0, -100.0]
const SPARK_DEFAULT_AOE_RADIUS: float = 260.0
const WARDEN_DAGGER_CRIT_CHANCE_BONUS: float = 14.0
const WARDEN_RING_MAX_ATTACKS: int = 5
const WARDEN_VENGEANCE_TRIGGER_COUNT: int = 20
const WARDEN_VENGEANCE_HEAL_RATIO_PER_ATTACK: float = 0.1
const RIFLEMAN_OIL_PASSIVE_DAMAGE_BONUS: int = 20
const RIFLEMAN_PRECISION_TRIGGER_ATTACKS: int = 3
const RIFLEMAN_PRECISION_EXTRA_DAMAGE_RATIO: float = 1.25
const RIFLEMAN_PRECISION_Q_KNOCKBACK_MULTIPLIER: float = 2.0
const RIFLEMAN_OIL_COOLDOWN_REFUND_RATIO: float = 0.3
const RIFLEMAN_BOMBARDMENT_TICK_COUNT: int = 5
const RIFLEMAN_BOMBARDMENT_TICK_INTERVAL_SEC: float = 0.5


func _ready() -> void:
	_hero = get_node_or_null(hero_path) as Node3D
	if _hero == null:
		push_warning("hero_path 未指向有效的 Node3D。")
		set_process(false)
		return

	_target_position = _hero.global_position
	_plane_height = _hero.global_position.y
	_base_move_speed = move_speed
	_cache_melee_profile()
	apply_hero_profile("近战")
	var initial_rotation := _hero.rotation
	initial_rotation.z = 0.0
	_hero.rotation = initial_rotation

	_nav_agent = NavigationAgent3D.new()
	_nav_agent.path_desired_distance = 20.0
	_nav_agent.target_desired_distance = 20.0
	_hero.add_child(_nav_agent)

	_animation_player = _hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		push_warning("未在英雄中找到 AnimationPlayer 节点。")
	_refresh_motion_animation_aliases()

	_recalculate_war3_stats(true)
	_refresh_attack_animations()
	_create_hp_bar()
	_update_hp_bar()
	_play_idle_animation()
	_push_network_control_command("idle", {"target_pos": _hero.global_position})
	_apply_mouse_cursor(false, false, false)


func _ensure_r_skill_runtime_resources() -> void:
	if not _r_skill_cursor_resource_checked and cursor_r_skill_texture == null:
		cursor_r_skill_texture = _load_texture_resource_or_file(R_SKILL_CURSOR_TEXTURE_PATH)
	_r_skill_cursor_resource_checked = true
	if not _r_skill_missile_resource_checked and ranged_r_missile_scene == null:
		ranged_r_missile_scene = _load_packed_scene_resource(R_SKILL_MISSILE_SCENE_PATH)
		if ranged_r_missile_scene == null:
			ranged_r_missile_scene = _load_packed_scene_resource(
				R_SKILL_MISSILE_SCENE_FALLBACK_PATH
			)
	_r_skill_missile_resource_checked = true
	if not _r_skill_impact_resource_checked and ranged_r_impact_scene == null:
		ranged_r_impact_scene = _load_packed_scene_resource(R_SKILL_IMPACT_SCENE_PATH)
	_r_skill_impact_resource_checked = true


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


func _load_texture_resource_or_file(path: String) -> Texture2D:
	var safe_path: String = path.strip_edges()
	if safe_path.is_empty():
		return null
	if not _resource_file_exists(safe_path):
		return null
	var image := Image.new()
	var err: int = image.load(ProjectSettings.globalize_path(safe_path))
	if err != OK:
		err = image.load(safe_path)
		if err != OK:
			return null
	return ImageTexture.create_from_image(image)


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
	var err: int = _variant_to_int(
		gltf_doc_obj.call("append_from_file", abs_path, gltf_state_obj), ERR_CANT_OPEN
	)
	if err != OK:
		err = _variant_to_int(
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


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


func _refresh_motion_animation_aliases() -> void:
	_resolved_idle_animation = _resolve_motion_animation(idle_animation, ["stand", "idle", "wait"])
	_resolved_walk_animation = _resolve_motion_animation(
		walk_animation, ["walk", "run", "move", "locomotion", "go"]
	)
	_resolved_death_animation = _resolve_motion_animation(death_animation, ["death", "die"])


func _resolve_motion_animation(preferred: String, keywords: Array[String]) -> String:
	if _animation_player == null:
		return ""
	if preferred != "" and _animation_player.has_animation(preferred):
		return preferred
	var anim_list: PackedStringArray = _animation_player.get_animation_list()
	for anim_name_sn in anim_list:
		var anim_name: String = String(anim_name_sn)
		var lower_name: String = anim_name.to_lower()
		for kw in keywords:
			if lower_name.find(kw) >= 0:
				return anim_name
	return ""


func _play_idle_animation() -> void:
	if _animation_player == null:
		return
	if _resolved_idle_animation == "":
		_refresh_motion_animation_aliases()
	if _resolved_idle_animation == "":
		return
	if (
		_animation_player.is_playing()
		and String(_animation_player.current_animation) == _resolved_idle_animation
	):
		return
	_animation_player.speed_scale = 1.0
	var anim = _animation_player.get_animation(_resolved_idle_animation)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(_resolved_idle_animation)


func _get_primary_attr_value() -> int:
	return HeroStatsService.get_primary_attr_value(
		primary_attribute, strength, agility, intelligence
	)


func _recalculate_war3_stats(reset_hp_mp: bool) -> void:
	var lv: int = maxi(hero_level, 1)
	hero_level = lv
	_last_stat_level = lv
	if _base_move_speed <= 0.0:
		_base_move_speed = move_speed
	if _base_attack_range <= 0.0:
		_base_attack_range = attack_range
	var computed: Dictionary = (
		HeroStatsService
		. build_recalculated_stats(
			{
				"hero_level": lv,
				"strength_base": strength_base,
				"strength_growth": strength_growth,
				"strength_growth_bonus": _talent_float("strength_growth_bonus", 0.0),
				"agility_base": agility_base,
				"agility_growth": agility_growth,
				"agility_growth_bonus": _talent_float("agility_growth_bonus", 0.0),
				"intelligence_base": intelligence_base,
				"intelligence_growth": intelligence_growth,
				"equip_strength_bonus": _equip_strength_bonus,
				"equip_agility_bonus": _equip_agility_bonus,
				"equip_intelligence_bonus": _equip_intelligence_bonus,
				"battle_banner_applied_strength_bonus": _battle_banner_applied_strength_bonus,
				"battle_banner_applied_agility_bonus": _battle_banner_applied_agility_bonus,
				"battle_banner_applied_intelligence_bonus":
				_battle_banner_applied_intelligence_bonus,
				"settlement_permanent_agility_bonus": _settlement_permanent_agility_bonus,
				"settlement_permanent_intelligence_bonus": _settlement_permanent_intelligence_bonus,
				"necro_bonus_int_from_flute": _necro_bonus_int_from_flute,
				"base_hp_flat": base_hp_flat,
				"equip_hp_bonus": _equip_hp_bonus,
				"spark_permanent_hp_bonus_from_procs": _spark_permanent_hp_bonus_from_procs,
				"charge_permanent_hp_bonus_from_procs": _charge_permanent_hp_bonus_from_procs,
				"necro_bonus_max_hp_from_summons": _necro_bonus_max_hp_from_summons,
				"settlement_permanent_hp_bonus": _settlement_permanent_hp_bonus,
				"str_hp_per_point": STR_HP_PER_POINT,
				"base_mana_flat": base_mana_flat,
				"initial_mana_multiplier": initial_mana_multiplier,
				"equip_mana_bonus": _equip_mana_bonus,
				"int_mana_per_point": INT_MANA_PER_POINT,
				"base_damage_flat": base_damage_flat,
				"equip_damage_bonus": _equip_damage_bonus,
				"battle_banner_applied_damage_bonus": _battle_banner_applied_damage_bonus,
				"primary_attribute": primary_attribute,
				"talent_flat_damage_bonus": _talent_int("flat_damage_bonus", 0),
				"talent_damage_growth_per_level": _talent_int("damage_growth_per_level", 0),
				"is_rifleman": _is_rifleman_hero(),
				"rifleman_oil_passive_damage_bonus": RIFLEMAN_OIL_PASSIVE_DAMAGE_BONUS,
				"base_armor_flat": base_armor_flat,
				"equip_armor_bonus": _equip_armor_bonus,
				"agi_armor_per_point": AGI_ARMOR_PER_POINT,
				"settlement_raw_physical_crit_chance": _get_settlement_raw_physical_crit_chance(),
				"settlement_dynamic_physical_crit_multiplier_bonus":
				_get_settlement_dynamic_physical_crit_multiplier_bonus_percent(
					_get_settlement_raw_physical_crit_chance()
				),
				"is_warden": _is_warden_hero(),
				"warden_dagger_crit_chance_bonus": WARDEN_DAGGER_CRIT_CHANCE_BONUS,
				"talent_physical_crit_chance_bonus":
				_talent_float("physical_crit_chance_bonus", 0.0),
				"base_physical_crit_multiplier": base_physical_crit_multiplier,
				"equip_physical_crit_multiplier_bonus": _equip_physical_crit_multiplier_bonus,
				"base_spell_crit_chance": base_spell_crit_chance,
				"equip_spell_crit_chance_bonus": _equip_spell_crit_chance_bonus,
				"base_spell_crit_multiplier": base_spell_crit_multiplier,
				"equip_spell_crit_multiplier_bonus": _equip_spell_crit_multiplier_bonus,
				"base_cooldown_reduction_percent": base_cooldown_reduction_percent,
				"equip_cooldown_reduction_percent_bonus": _equip_cooldown_reduction_percent_bonus,
				"max_cooldown_reduction_percent": MAX_COOLDOWN_REDUCTION_PERCENT,
				"base_hp_regen_flat": base_hp_regen_flat,
				"equip_hp_regen_bonus": _equip_hp_regen_bonus,
				"str_hp_regen_per_point": STR_HP_REGEN_PER_POINT,
				"base_mana_regen_flat": base_mana_regen_flat,
				"int_mana_regen_per_point": INT_MANA_REGEN_PER_POINT,
				"base_move_speed": _base_move_speed,
				"equip_move_speed_bonus": _equip_move_speed_bonus,
				"talent_move_speed_bonus_flat": _talent_float("move_speed_bonus_flat", 0.0),
				"wc3_min_move_speed": WC3_MIN_MOVE_SPEED,
				"wc3_max_move_speed": WC3_MAX_MOVE_SPEED,
				"base_attack_range": _base_attack_range,
				"equip_attack_range_bonus": _equip_attack_range_bonus,
				"talent_attack_range_bonus_flat": _talent_float("attack_range_bonus_flat", 0.0),
			}
		)
	)
	strength = int(computed.get("strength", strength))
	agility = int(computed.get("agility", agility))
	intelligence = int(computed.get("intelligence", intelligence))
	max_hp = int(computed.get("max_hp", max_hp))
	max_mana = int(computed.get("max_mana", max_mana))
	damage_per_hit = int(computed.get("damage_per_hit", damage_per_hit))
	armor = float(computed.get("armor", armor))
	physical_crit_chance = float(computed.get("physical_crit_chance", physical_crit_chance))
	physical_crit_multiplier = float(
		computed.get("physical_crit_multiplier", physical_crit_multiplier)
	)
	spell_crit_chance = float(computed.get("spell_crit_chance", spell_crit_chance))
	spell_crit_multiplier = float(computed.get("spell_crit_multiplier", spell_crit_multiplier))
	cooldown_reduction_percent_total = float(
		computed.get("cooldown_reduction_percent_total", cooldown_reduction_percent_total)
	)
	hp_regen_per_second = float(computed.get("hp_regen_per_second", hp_regen_per_second))
	mana_regen_per_second = float(computed.get("mana_regen_per_second", mana_regen_per_second))
	move_speed = float(computed.get("move_speed", move_speed))
	attack_range = float(computed.get("attack_range", attack_range))
	_refresh_runtime_combat_stats()
	if reset_hp_mp:
		_current_hp = max_hp
		current_mana = max_mana
	else:
		_current_hp = clampi(_current_hp, 0, max_hp)
		current_mana = clampi(current_mana, 0, max_mana)


func apply_equipment_bonuses(bonuses: Dictionary) -> void:
	var prev_max_hp: int = max_hp
	var prev_max_mana: int = max_mana
	_equip_strength_bonus = int(bonuses.get("strength", 0))
	_equip_agility_bonus = int(bonuses.get("agility", 0))
	_equip_intelligence_bonus = int(bonuses.get("intelligence", 0))
	_equip_hp_bonus = int(bonuses.get("hp", 0))
	_equip_mana_bonus = int(bonuses.get("mana", 0))
	_equip_damage_bonus = int(bonuses.get("damage", 0))
	_equip_armor_bonus = float(bonuses.get("armor", 0.0))
	_equip_attack_range_bonus = float(bonuses.get("attack_range", 0.0))
	_equip_attack_speed_percent_bonus = float(bonuses.get("attack_speed_percent", 0.0))
	_equip_move_speed_bonus = float(bonuses.get("move_speed", 0.0))
	_equip_hp_regen_bonus = float(bonuses.get("hp_regen", 0.0))
	_equip_cooldown_reduction_percent_bonus = float(bonuses.get("cooldown_reduction_percent", 0.0))
	_equip_physical_crit_chance_bonus = float(bonuses.get("physical_crit_chance", 0.0))
	_equip_physical_crit_multiplier_bonus = float(bonuses.get("physical_crit_multiplier", 0.0))
	_equip_spell_crit_chance_bonus = float(bonuses.get("spell_crit_chance", 0.0))
	_equip_spell_crit_multiplier_bonus = float(bonuses.get("spell_crit_multiplier", 0.0))
	_equip_spell_damage_percent_bonus = float(bonuses.get("spell_damage_percent", 0.0))
	_equip_magic_damage_reduction_percent_bonus = float(
		bonuses.get("magic_damage_reduction_percent", 0.0)
	)
	var spark_effects_variant: Variant = bonuses.get("spark_effects", {})
	if spark_effects_variant is Dictionary:
		_equip_spark_effects = (spark_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_spark_effects = {}
	var charge_effects_variant: Variant = bonuses.get("charge_effects", {})
	if charge_effects_variant is Dictionary:
		_equip_charge_effects = (charge_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_charge_effects = {}
	var necromancy_effects_variant: Variant = bonuses.get("necromancy_effects", {})
	if necromancy_effects_variant is Dictionary:
		_equip_necromancy_effects = (necromancy_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_necromancy_effects = {}
	var battle_banner_effects_variant: Variant = bonuses.get("battle_banner_effects", {})
	if battle_banner_effects_variant is Dictionary:
		_equip_battle_banner_effects = (battle_banner_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_battle_banner_effects = {}
	var battle_prep_effects_variant: Variant = bonuses.get("battle_prep_effects", {})
	if battle_prep_effects_variant is Dictionary:
		_equip_battle_prep_effects = (battle_prep_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_battle_prep_effects = {}
	var settlement_effects_variant: Variant = bonuses.get("settlement_effects", {})
	if settlement_effects_variant is Dictionary:
		_equip_settlement_effects = (settlement_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_settlement_effects = {}
	var coin_effects_variant: Variant = bonuses.get("coin_effects", {})
	if coin_effects_variant is Dictionary:
		_equip_coin_effects = (coin_effects_variant as Dictionary).duplicate(true)
	else:
		_equip_coin_effects = {}
	if _battle_prep_effect_int("revive_charge_if_empty", 0) <= 0:
		_battle_prep_revive_charges = 0
	var coin_revive_total: int = maxi(_coin_effect_int("revive_charge_total", 0), 0)
	_coin_revive_charges_used = clampi(_coin_revive_charges_used, 0, coin_revive_total)
	if _battle_prep_effect_int("titan_helmet_count", 0) <= 0:
		_battle_prep_fatal_guard_charges = 0
	if (
		_spark_effect_float("on_hit_attack_speed_bonus_percent", 0.0) <= 0.0
		or _spark_effect_float("on_hit_attack_speed_bonus_duration_sec", 0.0) <= 0.0
	):
		_spark_attack_speed_stack_time_lefts.clear()
	if (
		_spark_effect_float("on_hit_spell_damage_bonus_percent", 0.0) <= 0.0
		or _spark_effect_float("on_hit_spell_damage_bonus_duration_sec", 0.0) <= 0.0
	):
		_spark_spell_damage_buff_time_left = 0.0
	if _spark_effect_float("soul_consume_attack_speed_permanent_bonus_per_use", 0.0) <= 0.0:
		_spark_permanent_attack_speed_bonus_from_soul = 0.0
	var max_charge_stacks: int = maxi(_necro_effect_int("max_charge_stacks", 0), 0)
	if max_charge_stacks <= 0:
		_necro_charge_stacks = 0
	else:
		_necro_charge_stacks = clampi(_necro_charge_stacks, 0, max_charge_stacks)
	_recalculate_war3_stats(false)
	if max_hp > prev_max_hp or max_mana > prev_max_mana:
		_current_hp = max_hp
		current_mana = max_mana
		_hp_regen_pool = 0.0
		_mana_regen_pool = 0.0
	_enforce_start_area_full_hp_mana()
	_update_hp_bar()


func _cache_melee_profile() -> void:
	if not _melee_profile_cache.is_empty():
		return
	_melee_profile_cache = {
		"move_speed": MAP_WARDEN_MOVE_SPEED,
		"attack_range": attack_range,
		"base_hp_flat": _resolve_profile_base_hp_flat(MAP_WARDEN_MAX_HP),
		"base_mana_flat": _resolve_profile_base_mana_flat(MAP_WARDEN_MAX_MANA),
		"base_attack_speed": _resolve_profile_base_attack_speed(MAP_WARDEN_ATTACK_INTERVAL),
		"flash_max_distance": flash_max_distance,
		"flash_cooldown_time": flash_cooldown_time,
		"flash_origin_damage_radius": flash_origin_damage_radius,
		"flash_destination_damage_radius": flash_destination_damage_radius,
		"flash_damage": flash_damage,
		"flash_mana_cost": flash_mana_cost,
		"haste_multiplier": haste_multiplier,
		"haste_duration": haste_duration,
		"haste_cooldown_time": haste_cooldown_time,
		"haste_mana_cost": haste_mana_cost,
		"poison_damage_per_second": poison_damage_per_second,
		"poison_duration": poison_duration,
		"poison_tick_interval": poison_tick_interval,
		"passive_transform_attack_count": passive_transform_attack_count,
		"idle_animation": idle_animation,
		"walk_animation": walk_animation,
		"death_animation": death_animation,
		"attack_animation_1": attack_animation_1,
		"attack_animation_2": attack_animation_2,
		"attack_animation_3": attack_animation_3
	}


func _apply_profile_values(values: Dictionary) -> void:
	move_speed = float(values.get("move_speed", move_speed))
	_base_move_speed = move_speed
	attack_range = float(values.get("attack_range", attack_range))
	_base_attack_range = attack_range
	base_hp_flat = int(values.get("base_hp_flat", base_hp_flat))
	base_mana_flat = int(values.get("base_mana_flat", base_mana_flat))
	base_attack_speed = float(values.get("base_attack_speed", base_attack_speed))
	flash_max_distance = float(values.get("flash_max_distance", flash_max_distance))
	flash_cooldown_time = float(values.get("flash_cooldown_time", flash_cooldown_time))
	flash_origin_damage_radius = float(
		values.get("flash_origin_damage_radius", flash_origin_damage_radius)
	)
	flash_destination_damage_radius = float(
		values.get("flash_destination_damage_radius", flash_destination_damage_radius)
	)
	flash_damage = int(values.get("flash_damage", flash_damage))
	flash_mana_cost = int(values.get("flash_mana_cost", flash_mana_cost))
	haste_multiplier = float(values.get("haste_multiplier", haste_multiplier))
	haste_duration = float(values.get("haste_duration", haste_duration))
	haste_cooldown_time = float(values.get("haste_cooldown_time", haste_cooldown_time))
	haste_mana_cost = int(values.get("haste_mana_cost", haste_mana_cost))
	poison_damage_per_second = int(values.get("poison_damage_per_second", poison_damage_per_second))
	poison_duration = float(values.get("poison_duration", poison_duration))
	poison_tick_interval = float(values.get("poison_tick_interval", poison_tick_interval))
	passive_transform_attack_count = int(
		values.get("passive_transform_attack_count", passive_transform_attack_count)
	)
	idle_animation = str(values.get("idle_animation", idle_animation))
	walk_animation = str(values.get("walk_animation", walk_animation))
	death_animation = str(values.get("death_animation", death_animation))
	attack_animation_1 = str(values.get("attack_animation_1", attack_animation_1))
	attack_animation_2 = str(values.get("attack_animation_2", attack_animation_2))
	attack_animation_3 = str(values.get("attack_animation_3", attack_animation_3))


func _resolve_profile_base_hp_flat(target_max_hp: int) -> int:
	return target_max_hp - strength_base * STR_HP_PER_POINT


func _resolve_profile_base_mana_flat(target_max_mana: int) -> int:
	var scaled_base_mana: int = target_max_mana - intelligence_base * INT_MANA_PER_POINT
	if initial_mana_multiplier <= 0.0:
		return maxi(scaled_base_mana, 0)
	return maxi(int(round(float(scaled_base_mana) / initial_mana_multiplier)), 0)


func _resolve_profile_base_attack_speed(target_attack_interval: float) -> float:
	var safe_interval: float = maxf(target_attack_interval, 0.05)
	var agi_speed_factor: float = maxf(1.0 + float(agility_base) * AGI_ATTACK_SPEED_PER_POINT, 0.05)
	return (1.0 / safe_interval) / agi_speed_factor


func _is_ranged_hero() -> bool:
	return hero_id == HERO_ID_RANGED


func _uses_transform_passive() -> bool:
	return skill_passive_id == SKILL_ID_PASSIVE_TRANSFORM


func get_skill_binding_ids() -> Dictionary:
	return {
		"hero_id": hero_id,
		"skill_q_id": skill_q_id,
		"skill_w_id": skill_w_id,
		"skill_e_id": skill_e_id,
		"skill_passive_id": skill_passive_id,
		"skill_r_id": skill_r_id
	}


func _should_show_attack_count_label() -> bool:
	return hero_id == HERO_ID_MELEE


func set_input_locked_by_ui(locked: bool) -> void:
	_input_locked_by_ui = bool(locked)


func apply_talent_bonuses(bundle: Dictionary) -> void:
	_talent_bundle = bundle.duplicate(true)
	_recalculate_war3_stats(false)
	_update_hp_bar()


func _talent_int(key: String, fallback: int = 0) -> int:
	return int(_talent_bundle.get(key, fallback))


func _talent_float(key: String, fallback: float = 0.0) -> float:
	return float(_talent_bundle.get(key, fallback))


func _talent_bool(key: String, fallback: bool = false) -> bool:
	return bool(_talent_bundle.get(key, fallback))


func _update_enemy_damage_bonus_runtime(delta: float) -> void:
	if _enemy_damage_bonus_runtime.is_empty():
		return
	var remove_ids: Array[int] = []
	for enemy_id_variant in _enemy_damage_bonus_runtime.keys():
		var enemy_id: int = int(enemy_id_variant)
		var entry_variant: Variant = _enemy_damage_bonus_runtime.get(enemy_id, {})
		if not (entry_variant is Dictionary):
			remove_ids.append(enemy_id)
			continue
		var entry: Dictionary = entry_variant
		var enemy: Node3D = entry.get("node", null) as Node3D
		if enemy == null or not is_instance_valid(enemy) or _is_enemy_dead(enemy):
			remove_ids.append(enemy_id)
			continue
		var time_left: float = maxf(float(entry.get("time_left", 0.0)) - delta, 0.0)
		if time_left <= 0.0 and float(entry.get("permanent_percent", 0.0)) <= 0.0:
			remove_ids.append(enemy_id)
			continue
		entry["time_left"] = time_left
		_enemy_damage_bonus_runtime[enemy_id] = entry
	for enemy_id in remove_ids:
		_enemy_damage_bonus_runtime.erase(enemy_id)


func _get_enemy_damage_bonus_percent(enemy: Node3D) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	var enemy_controller: Node = enemy.get_parent()
	if (
		enemy_controller != null
		and enemy_controller.has_method("get_incoming_damage_bonus_percent")
	):
		return maxf(float(enemy_controller.call("get_incoming_damage_bonus_percent")), 0.0)
	var enemy_id: int = enemy.get_instance_id()
	var entry_variant: Variant = _enemy_damage_bonus_runtime.get(enemy_id, {})
	if not (entry_variant is Dictionary):
		return 0.0
	var entry: Dictionary = entry_variant
	return (
		maxf(float(entry.get("temporary_percent", 0.0)), 0.0)
		+ maxf(float(entry.get("permanent_percent", 0.0)), 0.0)
	)


func _apply_enemy_damage_bonus(
	enemy: Node3D, bonus_percent: float, duration_sec: float = 0.0, permanent: bool = false
) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if bonus_percent <= 0.0:
		return
	var enemy_controller: Node = enemy.get_parent()
	if enemy_controller != null and enemy_controller.has_method("apply_incoming_damage_bonus"):
		enemy_controller.call("apply_incoming_damage_bonus", bonus_percent, duration_sec, permanent)
		return
	var enemy_id: int = enemy.get_instance_id()
	var entry_variant: Variant = _enemy_damage_bonus_runtime.get(enemy_id, {})
	var entry: Dictionary = {}
	if entry_variant is Dictionary:
		entry = (entry_variant as Dictionary).duplicate(true)
	entry["node"] = enemy
	if permanent:
		entry["permanent_percent"] = float(entry.get("permanent_percent", 0.0)) + bonus_percent
	else:
		entry["temporary_percent"] = float(entry.get("temporary_percent", 0.0)) + bonus_percent
		entry["time_left"] = maxf(float(entry.get("time_left", 0.0)), duration_sec)
	_enemy_damage_bonus_runtime[enemy_id] = entry


func _is_warden_hero() -> bool:
	return hero_id == HERO_ID_MELEE


func _is_rifleman_hero() -> bool:
	return hero_id == HERO_ID_RANGED


func _should_apply_warden_poison_on_basic_attack() -> bool:
	return _is_warden_hero() and skill_w_id == SKILL_ID_W_HASTE


func _consume_warden_ring_attack() -> void:
	if not _is_warden_hero():
		return
	if _warden_ring_attacks_left <= 0:
		return
	_warden_ring_attacks_left -= 1
	if _warden_ring_attacks_left <= 0:
		_haste_active = false
		_haste_time_left = 0.0


func _apply_warden_vengeance_heal_on_attack() -> void:
	if not _is_warden_hero() or not _is_transformed:
		return
	var heal_amount: int = maxi(
		int(round(maxf(attack_speed_percent_total, 0.0) * WARDEN_VENGEANCE_HEAL_RATIO_PER_ATTACK)),
		0
	)
	_heal_self(heal_amount)


func _consume_rifleman_precision_trigger() -> bool:
	if not _is_rifleman_hero():
		return false
	_rifleman_precision_counter += 1
	if _rifleman_precision_counter < RIFLEMAN_PRECISION_TRIGGER_ATTACKS:
		return false
	_rifleman_precision_counter = 0
	if _haste_cooldown > 0.0:
		var total_refund_ratio: float = clampf(
			(
				RIFLEMAN_OIL_COOLDOWN_REFUND_RATIO
				+ _talent_float("rifleman_w_refund_ratio_bonus", 0.0)
			),
			0.0,
			0.95
		)
		_haste_cooldown = maxf(_haste_cooldown * maxf(1.0 - total_refund_ratio, 0.0), 0.0)
	return true


func _apply_rifleman_precision_bonus(
	enemy_controller: Node, enemy: Node3D, knockback_multiplier: float = 1.0
) -> void:
	if enemy_controller == null or enemy == null:
		return
	var extra_damage_ratio: float = (
		RIFLEMAN_PRECISION_EXTRA_DAMAGE_RATIO * _talent_float("rifleman_e_damage_multiplier", 1.0)
	)
	extra_damage_ratio *= 1.0 + _talent_float("rifleman_precision_ignore_armor_damage_bonus", 0.0)
	var extra_damage: int = maxi(int(round(float(damage_per_hit) * extra_damage_ratio)), 1)
	var current_pos: Vector3 = (
		_hero.global_position
		if _hero != null and is_instance_valid(_hero)
		else enemy.global_position
	)
	var knockback_dir: Vector3 = (enemy.global_position - current_pos).normalized()
	var knockback_distance: float = (
		ranged_q_ray_knockback_distance * maxf(knockback_multiplier, 0.1)
	)
	var knockback_duration: float = ranged_q_ray_knockback_duration
	var knockback_priority: int = ranged_q_ray_knockback_priority
	var request_context: Dictionary = {
		"knockback_dir": knockback_dir,
		"knockback_distance": knockback_distance,
		"knockback_duration": knockback_duration,
		"knockback_priority": knockback_priority
	}
	if _apply_enemy_damage_with_network(
		enemy_controller,
		enemy,
		extra_damage,
		attack_range + 60.0,
		"precision_attack",
		request_context
	):
		_apply_q_ray_knockback_local_if_authority(
			enemy_controller,
			knockback_dir,
			knockback_distance,
			knockback_duration,
			knockback_priority
		)


func apply_hero_profile_by_id(target_hero_id: int) -> void:
	if target_hero_id == HERO_ID_RANGED:
		apply_hero_profile("远程")
		return
	apply_hero_profile("近战")


func apply_hero_profile(profile_name: String) -> void:
	_cache_melee_profile()
	var normalized_profile: String = profile_name.strip_edges().to_lower()
	var use_ranged_profile: bool = (
		normalized_profile == "远程"
		or normalized_profile == "ranged"
		or profile_name.find("火枪手") >= 0
	)
	if use_ranged_profile:
		hero_id = HERO_ID_RANGED
		hero_profile = "火枪手"
		skill_q_id = SKILL_ID_Q_RANGED_SHOT
		skill_q_name = ranged_skill_q_name
		skill_w_id = SKILL_ID_W_RANGED_SPEED
		skill_w_name = ranged_skill_w_name
		skill_e_id = SKILL_ID_PASSIVE_RANGED
		skill_e_name = ranged_skill_e_name
		skill_e_active = false
		skill_passive_id = SKILL_ID_PASSIVE_RANGED
		skill_passive_name = ranged_skill_passive_name
		skill_r_id = SKILL_ID_R_RANGED_CLUSTER
		skill_r_name = ranged_skill_r_name
		skill_r_active = true
		_apply_profile_values(
			{
				"move_speed": MAP_RIFLEMAN_MOVE_SPEED,
				"attack_range": MAP_RIFLEMAN_ATTACK_RANGE,
				"base_hp_flat": _resolve_profile_base_hp_flat(MAP_RIFLEMAN_MAX_HP),
				"base_mana_flat": _resolve_profile_base_mana_flat(MAP_RIFLEMAN_MAX_MANA),
				"base_attack_speed":
				_resolve_profile_base_attack_speed(MAP_RIFLEMAN_ATTACK_INTERVAL),
				"flash_max_distance": ranged_flash_max_distance,
				"flash_cooldown_time": ranged_flash_cooldown_time,
				"flash_damage": ranged_flash_damage,
				"flash_mana_cost": ranged_flash_mana_cost,
				"haste_multiplier": ranged_haste_multiplier,
				"haste_duration": ranged_haste_duration,
				"haste_cooldown_time": ranged_haste_cooldown_time,
				"haste_mana_cost": ranged_haste_mana_cost,
				"poison_damage_per_second": ranged_poison_damage_per_second,
				"poison_duration": ranged_poison_duration,
				"poison_tick_interval": ranged_poison_tick_interval,
				"passive_transform_attack_count": ranged_passive_transform_attack_count,
				"idle_animation": ranged_idle_animation,
				"walk_animation": ranged_walk_animation,
				"death_animation": ranged_death_animation,
				"attack_animation_1": ranged_attack_animation_1,
				"attack_animation_2": ranged_attack_animation_2,
				"attack_animation_3": ranged_attack_animation_3
			}
		)
	else:
		hero_id = HERO_ID_MELEE
		hero_profile = "守望者"
		skill_q_id = SKILL_ID_Q_FLASH
		skill_q_name = melee_skill_q_name
		skill_w_id = SKILL_ID_W_HASTE
		skill_w_name = melee_skill_w_name
		skill_e_id = SKILL_ID_E_EVASIVE
		skill_e_name = melee_skill_e_name
		skill_e_active = false
		skill_passive_id = SKILL_ID_PASSIVE_TRANSFORM
		skill_passive_name = melee_skill_passive_name
		skill_r_id = 0
		skill_r_name = skill_passive_name
		skill_r_active = false
		_apply_profile_values(_melee_profile_cache)

	_poison_targets.clear()
	_haste_active = false
	_haste_time_left = 0.0
	_warden_ring_attacks_left = 0
	_rifleman_precision_counter = 0
	_e_cooldown = 0.0
	_r_cooldown = 0.0
	_r_skill_mode = false
	_refresh_motion_animation_aliases()
	_refresh_attack_animations()
	_update_attack_count_label()
	if _hero != null and is_instance_valid(_hero):
		_recalculate_war3_stats(false)
		apply_collision_profile("", _hero)
		_update_hp_bar()
	_play_idle_animation()


func select_hero_model(model_scene: PackedScene, hero_name: String = "SelectedHero") -> void:
	if model_scene == null:
		return
	if _is_transformed:
		_revert_transform_model()
	if _hero == null or not is_instance_valid(_hero):
		return

	var old_hero: Node3D = _hero
	var parent_node: Node = old_hero.get_parent()
	if parent_node == null:
		return

	var new_hero: Node3D = model_scene.instantiate() as Node3D
	if new_hero == null:
		return

	var old_transform: Transform3D = old_hero.global_transform
	var old_scale: Vector3 = old_hero.scale
	var old_rotation: Vector3 = old_hero.rotation

	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()
	_is_attacking = false
	_invalidate_pending_attack_damage()
	_is_moving = false
	_has_move_target = false
	_focus_lock = false
	_target_enemy = null
	_ranged_q_backstep_active = false
	_ranged_q_backstep_time_left = 0.0
	_ranged_q_backstep_total_time = 0.0
	_current_attack_index = 0

	new_hero.name = hero_name
	parent_node.add_child(new_hero)
	new_hero.global_transform = old_transform
	if _is_ranged_hero():
		new_hero.scale = old_scale * maxf(ranged_model_scale_multiplier, 0.01)
	else:
		new_hero.scale = old_scale
	new_hero.rotation = old_rotation
	var fixed_rotation: Vector3 = new_hero.rotation
	fixed_rotation.z = 0.0
	new_hero.rotation = fixed_rotation

	if _nav_agent != null and _nav_agent.get_parent() != null:
		_nav_agent.reparent(new_hero)
	if _hp_bar != null and _hp_bar.get_parent() != null:
		_hp_bar.reparent(new_hero)
	if _attack_count_label != null and _attack_count_label.get_parent() != null:
		_attack_count_label.reparent(new_hero)

	var old_collision_body := old_hero.get_node_or_null("CollisionBody") as Node3D
	if old_collision_body != null and old_collision_body.get_parent() != null:
		old_collision_body.reparent(new_hero)
	_ensure_hero_collision_body(new_hero)

	if old_hero.is_in_group("hero"):
		old_hero.remove_from_group("hero")
	new_hero.add_to_group("hero")
	old_hero.queue_free()

	_hero = new_hero
	apply_collision_profile("", _hero)
	_refresh_hp_bar_anchor_height_and_positions()
	_original_hero = _hero
	_transformed_hero = null
	_is_transformed = false
	_transform_time_left = 0.0
	_target_position = _hero.global_position
	_plane_height = _hero.global_position.y
	_animation_player = _hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_refresh_motion_animation_aliases()
	_refresh_attack_animations()
	_play_idle_animation()
	_notify_network_local_hero_ready()


func _ensure_hero_collision_body(target_hero: Node3D) -> void:
	if target_hero == null:
		return
	var profile_id: String = get_collision_profile_id()
	if target_hero != _hero:
		profile_id = _resolve_current_collision_profile_id()
	apply_collision_profile(profile_id, target_hero)


func get_collision_profile_id() -> String:
	var resolved_profile_id: String = _resolve_current_collision_profile_id()
	if _current_collision_profile_id.is_empty():
		return resolved_profile_id
	if (
		_current_collision_profile_id != resolved_profile_id
		and not _current_collision_profile.is_empty()
	):
		return resolved_profile_id
	return _current_collision_profile_id


func get_collision_profile() -> Dictionary:
	var resolved_profile_id: String = _resolve_current_collision_profile_id()
	if (
		_current_collision_profile.is_empty()
		or _current_collision_profile_id != resolved_profile_id
	):
		_current_collision_profile = _build_collision_profile(resolved_profile_id)
		_current_collision_profile_id = str(
			_current_collision_profile.get("profile_id", resolved_profile_id)
		)
	return _current_collision_profile.duplicate(true)


func apply_collision_profile(profile_id: String = "", target_hero: Node3D = null) -> void:
	var safe_target: Node3D = target_hero if target_hero != null else _hero
	if safe_target == null or not is_instance_valid(safe_target):
		return
	var resolved_profile_id: String = profile_id.strip_edges()
	if resolved_profile_id.is_empty():
		resolved_profile_id = _resolve_current_collision_profile_id()
	resolved_profile_id = _normalize_collision_profile_id(resolved_profile_id)
	var profile: Dictionary = _build_collision_profile(resolved_profile_id)
	_apply_collision_profile_to_hero(safe_target, profile)


func _resolve_current_collision_profile_id() -> String:
	if _is_transformed:
		return COLLISION_PROFILE_TRANSFORMED
	if _is_ranged_hero():
		return COLLISION_PROFILE_RANGED
	return COLLISION_PROFILE_MELEE


func _normalize_collision_profile_id(profile_id: String) -> String:
	var normalized_profile_id: String = profile_id.strip_edges().to_lower()
	match normalized_profile_id:
		"melee", "hero_melee":
			return COLLISION_PROFILE_MELEE
		"ranged", "hero_ranged":
			return COLLISION_PROFILE_RANGED
		"transformed", "hero_transformed":
			return COLLISION_PROFILE_TRANSFORMED
	return COLLISION_PROFILE_MELEE


func _build_collision_profile(profile_id: String) -> Dictionary:
	match _normalize_collision_profile_id(profile_id):
		COLLISION_PROFILE_RANGED:
			return {
				"profile_id": COLLISION_PROFILE_RANGED,
				"body_shape": "capsule",
				"body_radius": ranged_body_radius,
				"body_height": ranged_body_height,
				"body_offset_y": ranged_body_offset_y,
				"head_anchor_height": ranged_head_anchor_height,
				"projectile_origin_offset": ranged_projectile_origin_offset
			}
		COLLISION_PROFILE_TRANSFORMED:
			return {
				"profile_id": COLLISION_PROFILE_TRANSFORMED,
				"body_shape": "capsule",
				"body_radius": transformed_body_radius,
				"body_height": transformed_body_height,
				"body_offset_y": transformed_body_offset_y,
				"head_anchor_height": transformed_head_anchor_height,
				"projectile_origin_offset": transformed_projectile_origin_offset
			}
		_:
			return {
				"profile_id": COLLISION_PROFILE_MELEE,
				"body_shape": "capsule",
				"body_radius": melee_body_radius,
				"body_height": melee_body_height,
				"body_offset_y": melee_body_offset_y,
				"head_anchor_height": melee_head_anchor_height,
				"projectile_origin_offset": melee_projectile_origin_offset
			}


func _apply_collision_profile_to_hero(target_hero: Node3D, profile: Dictionary) -> void:
	if target_hero == null or not is_instance_valid(target_hero):
		return
	var collision_body := target_hero.get_node_or_null("CollisionBody") as StaticBody3D
	if collision_body == null:
		collision_body = StaticBody3D.new()
		collision_body.name = "CollisionBody"
		target_hero.add_child(collision_body)
	var collision_shape := collision_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_body.add_child(collision_shape)
	var shape_kind: String = str(profile.get("body_shape", "capsule")).strip_edges().to_lower()
	match shape_kind:
		"box":
			var box := collision_shape.shape as BoxShape3D
			if box == null:
				box = BoxShape3D.new()
				collision_shape.shape = box
			var box_size_variant: Variant = profile.get("body_size", Vector3.ONE * 100.0)
			if box_size_variant is Vector3:
				box.size = box_size_variant
		"cylinder":
			var cylinder := collision_shape.shape as CylinderShape3D
			if cylinder == null:
				cylinder = CylinderShape3D.new()
				collision_shape.shape = cylinder
			cylinder.radius = maxf(float(profile.get("body_radius", melee_body_radius)), 0.0)
			cylinder.height = maxf(float(profile.get("body_height", melee_body_height)), 0.0)
		_:
			var capsule := collision_shape.shape as CapsuleShape3D
			if capsule == null:
				capsule = CapsuleShape3D.new()
				collision_shape.shape = capsule
			capsule.radius = maxf(float(profile.get("body_radius", melee_body_radius)), 0.0)
			capsule.height = maxf(float(profile.get("body_height", melee_body_height)), 0.0)
	collision_shape.position = Vector3(
		0.0, float(profile.get("body_offset_y", melee_body_offset_y)), 0.0
	)
	var profile_name: String = str(profile.get("profile_id", COLLISION_PROFILE_MELEE))
	target_hero.set_meta(COLLISION_PROFILE_ID_META_KEY, profile_name)
	collision_body.set_meta(COLLISION_PROFILE_ID_META_KEY, profile_name)
	_ensure_hero_anchor_nodes(target_hero, profile)
	if target_hero == _hero:
		_current_collision_profile = profile.duplicate(true)
		_current_collision_profile_id = profile_name
		if _hp_bar != null or _attack_count_label != null:
			_refresh_hp_bar_anchor_height_and_positions()


func _ensure_hero_anchor_nodes(target_hero: Node3D, profile: Dictionary = {}) -> void:
	if target_hero == null or not is_instance_valid(target_hero):
		return
	var anchor_root := target_hero.get_node_or_null(ANCHOR_ROOT_NODE_NAME) as Node3D
	if anchor_root == null:
		anchor_root = Node3D.new()
		anchor_root.name = ANCHOR_ROOT_NODE_NAME
		target_hero.add_child(anchor_root)
	var head_height: float = float(profile.get("head_anchor_height", hp_bar_height))
	var projectile_origin_variant: Variant = profile.get(
		"projectile_origin_offset", Vector3(0.0, head_height * 0.5, 0.0)
	)
	var projectile_origin_offset: Vector3 = (
		projectile_origin_variant as Vector3
		if projectile_origin_variant is Vector3
		else Vector3(0.0, head_height * 0.5, 0.0)
	)
	_ensure_anchor_node(anchor_root, HEAD_ANCHOR_NODE_NAME, Vector3(0.0, head_height, 0.0))
	_ensure_anchor_node(anchor_root, PROJECTILE_ORIGIN_NODE_NAME, projectile_origin_offset)
	_ensure_anchor_node(
		anchor_root, SHADOW_ANCHOR_NODE_NAME, Vector3(0.0, shadow_anchor_height, 0.0)
	)
	_ensure_anchor_node(
		anchor_root, SELECTION_ANCHOR_NODE_NAME, Vector3(0.0, selection_anchor_height, 0.0)
	)


func _ensure_anchor_node(
	anchor_root: Node3D, anchor_name: String, default_position: Vector3
) -> Node3D:
	if anchor_root == null or not is_instance_valid(anchor_root):
		return null
	var anchor_node := anchor_root.get_node_or_null(anchor_name) as Node3D
	if anchor_node == null:
		anchor_node = Node3D.new()
		anchor_node.name = anchor_name
		anchor_node.position = default_position
		anchor_node.set_meta(AUTO_GENERATED_ANCHOR_META_KEY, true)
		anchor_root.add_child(anchor_node)
	elif bool(anchor_node.get_meta(AUTO_GENERATED_ANCHOR_META_KEY, false)):
		anchor_node.position = default_position
	return anchor_node


func _get_anchor_node(target_hero: Node3D, anchor_name: String) -> Node3D:
	if target_hero == null or not is_instance_valid(target_hero):
		return null
	var anchor_root := target_hero.get_node_or_null(ANCHOR_ROOT_NODE_NAME) as Node3D
	if anchor_root != null and is_instance_valid(anchor_root):
		var direct_anchor := anchor_root.get_node_or_null(anchor_name) as Node3D
		if direct_anchor != null:
			return direct_anchor
	return target_hero.find_child(anchor_name, true, false) as Node3D


func _resolve_anchor_height_from_hero(target_hero: Node3D, anchor_name: String) -> float:
	var anchor_node := _get_anchor_node(target_hero, anchor_name)
	if anchor_node == null or not is_instance_valid(anchor_node):
		return -1.0
	return maxf(anchor_node.global_position.y - target_hero.global_position.y, 0.0)


func _resolve_anchor_local_y(target_hero: Node3D, anchor_name: String) -> float:
	var anchor_node := _get_anchor_node(target_hero, anchor_name)
	if anchor_node == null or not is_instance_valid(anchor_node):
		return -1.0
	return anchor_node.position.y


func get_anchor_global_position(anchor_name: String = HEAD_ANCHOR_NODE_NAME) -> Vector3:
	if _hero == null or not is_instance_valid(_hero):
		return Vector3.ZERO
	var anchor_node := _get_anchor_node(_hero, anchor_name)
	if anchor_node != null and is_instance_valid(anchor_node):
		return anchor_node.global_position
	var fallback_height: float = _resolve_anchor_height_from_hero(_hero, HEAD_ANCHOR_NODE_NAME)
	if fallback_height < 0.0:
		fallback_height = get_hp_bar_anchor_height()
	return _hero.global_position + Vector3(0.0, fallback_height, 0.0)


func get_projectile_origin_global_position() -> Vector3:
	return get_anchor_global_position(PROJECTILE_ORIGIN_NODE_NAME)


func set_destroy_cursor_mode(enabled: bool) -> void:
	_destroy_cursor_mode = enabled
	if not enabled:
		_destroy_hover_item = false
	_update_mouse_cursor_icon()


func set_destroy_cursor_item_hover(enabled: bool) -> void:
	_destroy_hover_item = enabled and _destroy_cursor_mode
	_update_mouse_cursor_icon()


func is_mouse_idle_for_model_inspect() -> bool:
	if _attack_mode or _flash_mode or _r_skill_mode:
		return false
	if _destroy_cursor_mode:
		return false
	if _using_attack_cursor or _using_selected_cursor:
		return false
	return true


func apply_temporary_slow(slow_percent: float, duration: float) -> void:
	if _is_dead:
		return
	if duration <= 0.0:
		return
	var clamped_percent: float = clampf(slow_percent, 0.0, 95.0)
	if clamped_percent <= 0.0:
		return
	_slow_percent = clamped_percent
	_slow_time_left = maxf(duration, 0.01)


func _refresh_runtime_combat_stats() -> void:
	attack_speed = _get_attack_speed_scale()
	attack_interval = _get_attack_interval()


func _get_current_move_speed() -> float:
	var current_speed: float = move_speed
	if _is_warden_hero() and _is_transformed:
		current_speed = maxf(current_speed, WC3_MAX_MOVE_SPEED)
	if _haste_active and skill_w_id == SKILL_ID_W_RANGED_SPEED:
		var duration: float = maxf(haste_duration, 0.01)
		var ratio: float = clampf(_haste_time_left / duration, 0.0, 1.0)
		current_speed += ranged_haste_move_speed_bonus * ratio
	if _slow_time_left > 0.0 and _slow_percent > 0.0:
		current_speed *= maxf(1.0 - _slow_percent * 0.01, 0.0)
	return maxf(current_speed, 1.0)


func _variant_to_positive_float(value: Variant, fallback: float = 0.0) -> float:
	if value is float:
		return maxf(value, 0.0)
	if value is int:
		return maxf(float(value), 0.0)
	return maxf(fallback, 0.0)


func _spark_effect_float(key: String, fallback: float = 0.0) -> float:
	if _equip_spark_effects.is_empty():
		return fallback
	return float(_equip_spark_effects.get(key, fallback))


func _spark_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_spark_effects.is_empty():
		return fallback
	return int(_equip_spark_effects.get(key, fallback))


func _charge_effect_float(key: String, fallback: float = 0.0) -> float:
	if _equip_charge_effects.is_empty():
		return fallback
	return float(_equip_charge_effects.get(key, fallback))


func _charge_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_charge_effects.is_empty():
		return fallback
	return int(_equip_charge_effects.get(key, fallback))


func _necro_effect_float(key: String, fallback: float = 0.0) -> float:
	if _equip_necromancy_effects.is_empty():
		return fallback
	return float(_equip_necromancy_effects.get(key, fallback))


func _necro_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_necromancy_effects.is_empty():
		return fallback
	return int(_equip_necromancy_effects.get(key, fallback))


func _battle_prep_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_battle_prep_effects.is_empty():
		return fallback
	return int(_equip_battle_prep_effects.get(key, fallback))


func _settlement_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_settlement_effects.is_empty():
		return fallback
	return int(_equip_settlement_effects.get(key, fallback))


func _coin_effect_float(key: String, fallback: float = 0.0) -> float:
	if _equip_coin_effects.is_empty():
		return fallback
	return float(_equip_coin_effects.get(key, fallback))


func _coin_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_coin_effects.is_empty():
		return fallback
	return int(_equip_coin_effects.get(key, fallback))


func _get_coin_revive_charge_total() -> int:
	return maxi(_coin_effect_int("revive_charge_total", 0), 0)


func _get_coin_available_revive_charges() -> int:
	return maxi(_get_coin_revive_charge_total() - _coin_revive_charges_used, 0)


func _consume_coin_revive_charge() -> bool:
	var available: int = _get_coin_available_revive_charges()
	if available <= 0:
		return false
	_coin_revive_charges_used = mini(_coin_revive_charges_used + 1, _get_coin_revive_charge_total())
	return true


func get_coin_sync_state() -> Dictionary:
	return {
		"revive_available": _get_coin_available_revive_charges(),
		"total_coin_layers": maxi(_coin_effect_int("total_coin_layers", 0), 0),
		"revenge_spirit_count": maxi(_coin_effect_int("revenge_spirit_count", 0), 0),
		"revenge_spirit_attack_percent":
		maxf(_coin_effect_float("revenge_spirit_attack_percent", 0.0), 0.0),
	}


func _get_game_ui_node() -> Node:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("GameUI")


func _refresh_local_battle_phase_notifications() -> void:
	var battle_phase_active: bool = (
		_hero != null
		and is_instance_valid(_hero)
		and _hero.visible
		and not _is_dead
		and not _is_inside_start_area_recovery_zone()
	)
	if battle_phase_active == _local_battle_phase_active_notified:
		return
	_local_battle_phase_active_notified = battle_phase_active
	var ui: Node = _get_game_ui_node()
	if ui == null:
		return
	if battle_phase_active:
		if ui.has_method("notify_local_battle_phase_started"):
			ui.call("notify_local_battle_phase_started")
	else:
		if ui.has_method("notify_local_battle_phase_ended"):
			ui.call("notify_local_battle_phase_ended")


func _get_settlement_crit_rate_multiplier() -> float:
	if _settlement_effect_int("double_crit_item_count", 0) > 0:
		return 2.0
	return 1.0


func _get_settlement_crit_pool() -> float:
	return maxf(
		(
			base_physical_crit_chance
			+ _equip_physical_crit_chance_bonus
			+ _settlement_permanent_physical_crit_chance_bonus
		),
		0.0
	)


func _get_settlement_raw_physical_crit_chance() -> float:
	return _get_settlement_crit_pool() * _get_settlement_crit_rate_multiplier()


func _get_settlement_dynamic_physical_crit_multiplier_bonus_percent(
	raw_crit_chance: float = -1.0
) -> float:
	var effective_raw_crit: float = raw_crit_chance
	if effective_raw_crit < 0.0:
		effective_raw_crit = _get_settlement_raw_physical_crit_chance()
	var bonus_percent: float = 0.0
	var holy_sword_count: int = maxi(_settlement_effect_int("holy_sword_count", 0), 0)
	if holy_sword_count > 0:
		bonus_percent += effective_raw_crit * 0.3 * float(holy_sword_count)
	if _settlement_effect_int("crit_overflow_item_count", 0) > 0 and effective_raw_crit > 100.0:
		bonus_percent += effective_raw_crit - 100.0
	return bonus_percent


func _get_total_necro_summon_power_percent() -> float:
	return maxf(_necro_summon_power_percent_from_spells, 0.0)


func _get_total_necro_summon_magic_resist_percent() -> float:
	return maxf(_necro_effect_float("summon_magic_resist_percent", 0.0), 0.0)


func _get_total_necro_summon_attack_bonus_percent() -> float:
	var flat_bonus: float = maxf(_necro_effect_float("summon_attack_bonus_percent_flat", 0.0), 0.0)
	if flat_bonus > 0.0:
		return flat_bonus
	var per_charge: float = maxf(
		_necro_effect_float("summon_attack_and_range_percent_per_charge", 0.0), 0.0
	)
	return per_charge * float(maxi(_necro_charge_stacks, 0))


func _get_total_necro_summon_range_bonus_percent() -> float:
	var flat_bonus: float = maxf(_necro_effect_float("summon_range_bonus_percent_flat", 0.0), 0.0)
	if flat_bonus > 0.0:
		return flat_bonus
	var per_charge: float = maxf(
		_necro_effect_float("summon_attack_and_range_percent_per_charge", 0.0), 0.0
	)
	return per_charge * float(maxi(_necro_charge_stacks, 0))


func get_necromancy_sync_state() -> Dictionary:
	return {
		"book_count": maxi(_necro_effect_int("spirit_book_count", 0), 0),
		"flute_count": maxi(_necro_effect_int("spirit_flute_count", 0), 0),
		"robe_count": maxi(_necro_effect_int("spellcaster_necro_robe_count", 0), 0),
		"moon_tower_count": maxi(_necro_effect_int("moon_tower_count", 0), 0),
		"spirit_staff_count": maxi(_necro_effect_int("spirit_staff_count", 0), 0),
		"battle_prep_owl_count": maxi(_necro_effect_int("battle_prep_owl_count", 0), 0),
		"battle_prep_tower_count": maxi(_necro_effect_int("battle_prep_tower_count", 0), 0),
		"summon_magic_resist_percent": _get_total_necro_summon_magic_resist_percent(),
		"summon_power_percent": _get_total_necro_summon_power_percent(),
		"summon_attack_bonus_percent": _get_total_necro_summon_attack_bonus_percent(),
		"summon_range_bonus_percent": _get_total_necro_summon_range_bonus_percent(),
		"charge_stacks": maxi(_necro_charge_stacks, 0),
		"bonus_hp_from_summons": maxi(_necro_bonus_max_hp_from_summons, 0),
		"bonus_int_from_flute": maxi(_necro_bonus_int_from_flute, 0),
		"flute_pending_stacks": maxi(_necro_flute_summon_stacks, 0),
	}


func get_battle_prep_sync_state() -> Dictionary:
	return {
		"battle_active": _battle_prep_last_phase_active,
		"trigger_multiplier": maxi(_battle_prep_effect_int("trigger_multiplier", 1), 1),
		"snake_ward_count": maxi(_battle_prep_effect_int("snake_ward_count", 0), 0),
		"challenge_griffin_count": maxi(_battle_prep_effect_int("challenge_griffin_count", 0), 0),
	}


func _is_battle_prep_phase_active() -> bool:
	if _hero == null or not is_instance_valid(_hero):
		return false
	if _is_dead or not _hero.visible:
		return false
	if (
		maxi(_battle_prep_effect_int("snake_ward_count", 0), 0) <= 0
		and maxi(_battle_prep_effect_int("challenge_griffin_count", 0), 0) <= 0
		and maxi(_battle_prep_effect_int("revive_charge_if_empty", 0), 0) <= 0
		and maxi(_battle_prep_effect_int("titan_helmet_count", 0), 0) <= 0
	):
		return false
	return not _is_inside_start_area_recovery_zone()


func _on_battle_prep_phase_started() -> void:
	if _battle_prep_revive_charges <= 0:
		_battle_prep_revive_charges = maxi(_battle_prep_effect_int("revive_charge_if_empty", 0), 0)
	var titan_helmet_count: int = maxi(_battle_prep_effect_int("titan_helmet_count", 0), 0)
	var trigger_multiplier: int = maxi(_battle_prep_effect_int("trigger_multiplier", 1), 1)
	var charges_per_helmet: int = 6 if max_hp < 3000 else 3
	_battle_prep_fatal_guard_charges = titan_helmet_count * charges_per_helmet * trigger_multiplier


func _refresh_battle_prep_phase_state() -> void:
	var battle_phase_active: bool = _is_battle_prep_phase_active()
	if battle_phase_active == _battle_prep_last_phase_active:
		return
	_battle_prep_last_phase_active = battle_phase_active
	if battle_phase_active:
		_on_battle_prep_phase_started()
	else:
		_battle_prep_fatal_guard_charges = 0


func _banner_effect_float(key: String, fallback: float = 0.0) -> float:
	if _equip_battle_banner_effects.is_empty():
		return fallback
	return float(_equip_battle_banner_effects.get(key, fallback))


func _banner_effect_int(key: String, fallback: int = 0) -> int:
	if _equip_battle_banner_effects.is_empty():
		return fallback
	return int(_equip_battle_banner_effects.get(key, fallback))


func get_battle_banner_sync_state() -> Dictionary:
	return {
		"battle_active": _battle_banner_last_phase_active,
		"emitted_strength_bonus": _battle_banner_emitted_strength_bonus,
		"emitted_agility_bonus": _battle_banner_emitted_agility_bonus,
		"emitted_intelligence_bonus": _battle_banner_emitted_intelligence_bonus,
		"emitted_damage_bonus": _battle_banner_emitted_damage_bonus,
		"emitted_attack_speed_percent_bonus": _battle_banner_emitted_attack_speed_percent_bonus,
		"emitted_spell_damage_percent_bonus": _battle_banner_emitted_spell_damage_percent_bonus,
	}


func _reset_battle_banner_emitted_bonuses() -> void:
	_battle_banner_emitted_strength_bonus = 0
	_battle_banner_emitted_agility_bonus = 0
	_battle_banner_emitted_intelligence_bonus = 0
	_battle_banner_emitted_damage_bonus = 0
	_battle_banner_emitted_attack_speed_percent_bonus = 0.0
	_battle_banner_emitted_spell_damage_percent_bonus = 0.0


func _get_battle_banner_double_multiplier() -> float:
	var double_count: int = maxi(_banner_effect_int("inspiration_double_count", 0), 0)
	if double_count <= 0:
		return 1.0
	return pow(2.0, float(double_count))


func _refresh_battle_banner_applied_bonuses() -> void:
	var total_strength_bonus: int = _battle_banner_emitted_strength_bonus
	var total_agility_bonus: int = _battle_banner_emitted_agility_bonus
	var total_intelligence_bonus: int = _battle_banner_emitted_intelligence_bonus
	var total_damage_bonus: int = _battle_banner_emitted_damage_bonus
	var total_attack_speed_bonus: float = _battle_banner_emitted_attack_speed_percent_bonus
	var total_spell_damage_bonus: float = _battle_banner_emitted_spell_damage_percent_bonus

	if _hero != null and is_instance_valid(_hero):
		var net_ctrl: Node = _get_network_session_controller()
		if (
			net_ctrl != null
			and net_ctrl.has_method("get_synced_peer_ids")
			and net_ctrl.has_method("get_ui_peer_hero_state")
		):
			var self_peer_id: int = 0
			if net_ctrl.has_method("get_ui_self_peer_id"):
				self_peer_id = int(net_ctrl.call("get_ui_self_peer_id"))
			var peer_ids_variant: Variant = net_ctrl.call("get_synced_peer_ids")
			if peer_ids_variant is Array:
				for peer_id_variant in peer_ids_variant:
					var peer_id: int = int(peer_id_variant)
					if peer_id <= 0 or peer_id == self_peer_id:
						continue
					var hero_state_variant: Variant = net_ctrl.call(
						"get_ui_peer_hero_state", peer_id
					)
					if not (hero_state_variant is Dictionary):
						continue
					var hero_state: Dictionary = hero_state_variant as Dictionary
					if bool(hero_state.get("is_dead", false)):
						continue
					if not bool(hero_state.get("visible", true)):
						continue
					var ally_pos_variant: Variant = hero_state.get("pos", null)
					if not (ally_pos_variant is Vector3):
						continue
					var ally_pos: Vector3 = ally_pos_variant as Vector3
					if _distance_xz(_hero.global_position, ally_pos) > 900.0:
						continue
					var banner_state_variant: Variant = hero_state.get("battle_banner", null)
					if not (banner_state_variant is Dictionary):
						continue
					var banner_state: Dictionary = banner_state_variant as Dictionary
					if not bool(banner_state.get("battle_active", false)):
						continue
					total_strength_bonus += int(banner_state.get("emitted_strength_bonus", 0))
					total_agility_bonus += int(banner_state.get("emitted_agility_bonus", 0))
					total_intelligence_bonus += int(
						banner_state.get("emitted_intelligence_bonus", 0)
					)
					total_damage_bonus += int(banner_state.get("emitted_damage_bonus", 0))
					total_attack_speed_bonus += float(
						banner_state.get("emitted_attack_speed_percent_bonus", 0.0)
					)
					total_spell_damage_bonus += float(
						banner_state.get("emitted_spell_damage_percent_bonus", 0.0)
					)

	var double_multiplier: float = _get_battle_banner_double_multiplier()
	total_strength_bonus = int(round(float(total_strength_bonus) * double_multiplier))
	total_agility_bonus = int(round(float(total_agility_bonus) * double_multiplier))
	total_intelligence_bonus = int(round(float(total_intelligence_bonus) * double_multiplier))
	total_damage_bonus = int(round(float(total_damage_bonus) * double_multiplier))
	total_attack_speed_bonus *= double_multiplier
	total_spell_damage_bonus *= double_multiplier

	var changed: bool = false
	changed = changed or _battle_banner_applied_strength_bonus != total_strength_bonus
	changed = changed or _battle_banner_applied_agility_bonus != total_agility_bonus
	changed = changed or _battle_banner_applied_intelligence_bonus != total_intelligence_bonus
	changed = changed or _battle_banner_applied_damage_bonus != total_damage_bonus
	changed = (
		changed
		or not is_equal_approx(
			_battle_banner_applied_attack_speed_percent_bonus, total_attack_speed_bonus
		)
	)
	changed = (
		changed
		or not is_equal_approx(
			_battle_banner_applied_spell_damage_percent_bonus, total_spell_damage_bonus
		)
	)

	if not changed:
		return
	_battle_banner_applied_strength_bonus = total_strength_bonus
	_battle_banner_applied_agility_bonus = total_agility_bonus
	_battle_banner_applied_intelligence_bonus = total_intelligence_bonus
	_battle_banner_applied_damage_bonus = total_damage_bonus
	_battle_banner_applied_attack_speed_percent_bonus = total_attack_speed_bonus
	_battle_banner_applied_spell_damage_percent_bonus = total_spell_damage_bonus
	_recalculate_war3_stats(false)
	_update_hp_bar()


func _apply_battle_banner_pulses(pulse_count: int) -> void:
	var safe_pulse_count: int = maxi(pulse_count, 0)
	if safe_pulse_count <= 0:
		return
	_battle_banner_emitted_attack_speed_percent_bonus += (
		float(_banner_effect_int("elf_banner_count", 0))
		* _banner_effect_float("elf_attack_speed_percent_per_pulse", 5.0)
		* float(safe_pulse_count)
	)
	_battle_banner_emitted_damage_bonus += (
		maxi(_banner_effect_int("kingdom_banner_count", 0), 0)
		* maxi(_banner_effect_int("kingdom_damage_per_pulse", 5), 0)
		* safe_pulse_count
	)
	_battle_banner_emitted_spell_damage_percent_bonus += (
		float(_banner_effect_int("wasteland_banner_count", 0))
		* _banner_effect_float("wasteland_spell_damage_percent_per_pulse", 2.0)
		* float(safe_pulse_count)
	)
	var heroic_all_attr_gain: int = (
		maxi(_banner_effect_int("heroic_banner_count", 0), 0)
		* maxi(_banner_effect_int("heroic_all_attributes_per_pulse", 1), 0)
		* safe_pulse_count
	)
	_battle_banner_emitted_strength_bonus += heroic_all_attr_gain
	_battle_banner_emitted_agility_bonus += heroic_all_attr_gain
	_battle_banner_emitted_intelligence_bonus += heroic_all_attr_gain
	_battle_banner_emitted_intelligence_bonus += (
		maxi(_banner_effect_int("council_banner_count", 0), 0)
		* maxi(_banner_effect_int("council_intelligence_per_pulse", 3), 0)
		* safe_pulse_count
	)
	_refresh_battle_banner_applied_bonuses()


func _compute_silvermoon_battle_prep_pulse_count() -> int:
	var silvermoon_count: int = maxi(_banner_effect_int("silvermoon_banner_count", 0), 0)
	if silvermoon_count <= 0:
		return 0
	var total_banner_count: int = maxi(_banner_effect_int("total_banner_count", 0), 0)
	var multiplier: float = maxf(
		_banner_effect_float("silvermoon_battle_prep_multiplier", 1.25), 0.0
	)
	return maxi(int(round(float(total_banner_count * silvermoon_count) * multiplier)), 0)


func _is_battle_banner_phase_active() -> bool:
	if _hero == null or not is_instance_valid(_hero):
		return false
	if _is_dead or not _hero.visible:
		return false
	if maxi(_banner_effect_int("total_banner_count", 0), 0) <= 0:
		return false
	return not _is_inside_start_area_recovery_zone()


func _update_battle_banner_runtime(delta: float) -> void:
	var battle_phase_active: bool = _is_battle_banner_phase_active()
	if battle_phase_active != _battle_banner_last_phase_active:
		_battle_banner_last_phase_active = battle_phase_active
		_battle_banner_elapsed_sec = 0.0
		_reset_battle_banner_emitted_bonuses()
		if battle_phase_active:
			var prep_pulses: int = _compute_silvermoon_battle_prep_pulse_count()
			if prep_pulses > 0:
				_apply_battle_banner_pulses(prep_pulses)
			else:
				_refresh_battle_banner_applied_bonuses()
		else:
			_refresh_battle_banner_applied_bonuses()
			return
	if not battle_phase_active:
		_refresh_battle_banner_applied_bonuses()
		return
	var interval_sec: float = maxf(_banner_effect_float("pulse_interval_sec", 16.0), 0.1)
	_battle_banner_elapsed_sec += maxf(delta, 0.0)
	var pulse_count: int = int(floor(_battle_banner_elapsed_sec / interval_sec))
	if pulse_count > 0:
		_battle_banner_elapsed_sec -= float(pulse_count) * interval_sec
		_apply_battle_banner_pulses(pulse_count)
	else:
		_refresh_battle_banner_applied_bonuses()


func _refresh_necromancy_progression_stats() -> void:
	var prev_max_hp: int = max_hp
	var prev_max_mana: int = max_mana
	_recalculate_war3_stats(false)
	var hp_delta: int = maxi(max_hp - prev_max_hp, 0)
	var mana_delta: int = maxi(max_mana - prev_max_mana, 0)
	if hp_delta > 0:
		_current_hp = mini(_current_hp + hp_delta, max_hp)
	if mana_delta > 0:
		current_mana = mini(current_mana + mana_delta, max_mana)
	_update_hp_bar()


func _refresh_settlement_progression_stats() -> void:
	var prev_max_hp: int = max_hp
	var prev_max_mana: int = max_mana
	_recalculate_war3_stats(false)
	var hp_delta: int = maxi(max_hp - prev_max_hp, 0)
	var mana_delta: int = maxi(max_mana - prev_max_mana, 0)
	if hp_delta > 0:
		_current_hp = mini(_current_hp + hp_delta, max_hp)
	if mana_delta > 0:
		current_mana = mini(current_mana + mana_delta, max_mana)
	_update_hp_bar()


func _apply_settlement_end_of_battle_effects() -> void:
	var settlement_item_count: int = maxi(_settlement_effect_int("settlement_item_count", 0), 0)
	if settlement_item_count <= 0:
		return
	var total_triggers: int = 1 + maxi(_settlement_effect_int("extra_trigger_count", 0), 0)
	if total_triggers <= 0:
		return

	var hero_lv: int = maxi(hero_level, 1)
	var crit_pool: float = _get_settlement_crit_pool()
	var crit_rate_multiplier: float = _get_settlement_crit_rate_multiplier()
	var current_agility: int = agility
	var current_intelligence: int = intelligence
	var judgement_sword_count: int = maxi(_settlement_effect_int("judgement_sword_count", 0), 0)
	var holy_sword_count: int = maxi(_settlement_effect_int("holy_sword_count", 0), 0)
	var hawkeye_ring_count: int = maxi(_settlement_effect_int("hawkeye_ring_count", 0), 0)
	var gold_medal_count: int = maxi(_settlement_effect_int("gold_medal_count", 0), 0)
	var lion_ring_count: int = maxi(_settlement_effect_int("lion_ring_count", 0), 0)
	var changed: bool = false

	for _trigger_idx in range(total_triggers):
		for _judge_idx in range(judgement_sword_count):
			var judge_crit_gain: float = 2.0 * float(settlement_item_count)
			crit_pool += judge_crit_gain
			_settlement_permanent_physical_crit_chance_bonus += judge_crit_gain
			var effective_judge_crit: float = crit_pool * crit_rate_multiplier
			var judge_attr_gain: int = maxi(int(floor(effective_judge_crit / 12.0)), hero_lv)
			if judge_attr_gain > 0:
				current_agility += judge_attr_gain
				current_intelligence += judge_attr_gain
				_settlement_permanent_agility_bonus += judge_attr_gain
				_settlement_permanent_intelligence_bonus += judge_attr_gain
			changed = true

		for _holy_idx in range(holy_sword_count):
			var holy_crit_gain: float = 4.0 * float(settlement_item_count)
			crit_pool += holy_crit_gain
			_settlement_permanent_physical_crit_chance_bonus += holy_crit_gain
			var effective_holy_crit: float = crit_pool * crit_rate_multiplier
			var holy_attr_gain: int = maxi(int(floor(effective_holy_crit / 12.0)) * 2, hero_lv * 2)
			if holy_attr_gain > 0:
				current_agility += holy_attr_gain
				current_intelligence += holy_attr_gain
				_settlement_permanent_agility_bonus += holy_attr_gain
				_settlement_permanent_intelligence_bonus += holy_attr_gain
			changed = true

		if hawkeye_ring_count > 0:
			_settlement_permanent_hp_bonus += 100 * hawkeye_ring_count
			changed = true

		for _medal_idx in range(gold_medal_count):
			var medal_hp_gain: int = maxi(
				int(round(float(current_agility + current_intelligence) * 0.2)), 200
			)
			if medal_hp_gain > 0:
				_settlement_permanent_hp_bonus += medal_hp_gain
				changed = true

		for _lion_idx in range(lion_ring_count):
			var lion_hp_gain: int = maxi(
				int(round(float(current_agility + current_intelligence) * 0.4)), 400
			)
			if lion_hp_gain > 0:
				_settlement_permanent_hp_bonus += lion_hp_gain
				changed = true

	if changed:
		_refresh_settlement_progression_stats()


func _apply_necromancy_summon_events(summon_count: int) -> void:
	var safe_count: int = maxi(summon_count, 0)
	if safe_count <= 0:
		return
	var hp_gain_per_summon: int = maxi(_necro_effect_int("book_max_hp_per_summon", 0), 0)
	var flute_stack_gain_per_summon: int = maxi(
		_necro_effect_int("flute_stack_gain_per_summon", 0), 0
	)
	var flute_stacks_per_int: int = maxi(_necro_effect_int("flute_stacks_per_int", 7), 1)
	var flute_int_per_threshold: int = maxi(_necro_effect_int("flute_int_per_threshold", 1), 1)
	var changed: bool = false
	if hp_gain_per_summon > 0:
		_necro_bonus_max_hp_from_summons += hp_gain_per_summon * safe_count
		changed = true
	if flute_stack_gain_per_summon > 0:
		_necro_flute_summon_stacks += flute_stack_gain_per_summon * safe_count
		var completed_thresholds: int = _necro_flute_summon_stacks / flute_stacks_per_int
		if completed_thresholds > 0:
			_necro_bonus_int_from_flute += completed_thresholds * flute_int_per_threshold
			_necro_flute_summon_stacks = _necro_flute_summon_stacks % flute_stacks_per_int
			changed = true
	if changed:
		_refresh_necromancy_progression_stats()


func _register_necromancy_skill_cast() -> void:
	var summon_power_gain: float = maxf(
		_necro_effect_float("summon_power_percent_per_spell_cast", 0.0), 0.0
	)
	if summon_power_gain <= 0.0:
		return
	_necro_summon_power_percent_from_spells += summon_power_gain


func _register_necromancy_basic_attack_charge_gain() -> void:
	var charge_gain: int = maxi(_necro_effect_int("charge_gain_per_basic_attack", 0), 0)
	var max_charge_stacks: int = maxi(_necro_effect_int("max_charge_stacks", 0), 0)
	if charge_gain <= 0 or max_charge_stacks <= 0:
		return
	_necro_charge_stacks = clampi(_necro_charge_stacks + charge_gain, 0, max_charge_stacks)


func _on_necromancy_battle_phase_started() -> void:
	_necro_charge_stacks = 0
	var summon_count: int = (
		maxi(_necro_effect_int("battle_prep_owl_count", 0), 0)
		+ maxi(_necro_effect_int("battle_prep_tower_count", 0), 0)
	)
	_apply_necromancy_summon_events(summon_count)


func _refresh_necromancy_battle_phase_state() -> void:
	var battle_phase_active: bool = (
		_hero != null
		and is_instance_valid(_hero)
		and _hero.visible
		and not _is_dead
		and not _is_inside_start_area_recovery_zone()
	)
	if battle_phase_active == _necro_last_battle_phase_active:
		return
	_necro_last_battle_phase_active = battle_phase_active
	var game_ui: Node = _get_game_ui_node()
	if battle_phase_active:
		_on_necromancy_battle_phase_started()
		if game_ui != null and game_ui.has_method("notify_local_battle_phase_started"):
			game_ui.call("notify_local_battle_phase_started")
	else:
		_apply_settlement_end_of_battle_effects()
		if (
			not _is_dead
			and game_ui != null
			and game_ui.has_method("notify_local_battle_phase_ended")
		):
			game_ui.call("notify_local_battle_phase_ended")
		_necro_charge_stacks = 0


func _get_spark_temp_attack_speed_bonus_percent() -> float:
	var bonus_per_stack: float = _spark_effect_float("on_hit_attack_speed_bonus_percent", 0.0)
	if bonus_per_stack <= 0.0:
		return 0.0
	return bonus_per_stack * float(_spark_attack_speed_stack_time_lefts.size())


func _get_total_spell_damage_bonus_percent() -> float:
	var total_bonus: float = _equip_spell_damage_percent_bonus
	if _spark_spell_damage_buff_time_left > 0.0:
		total_bonus += _spark_effect_float("on_hit_spell_damage_bonus_percent", 0.0)
	total_bonus += _battle_banner_applied_spell_damage_percent_bonus
	return total_bonus


func _update_equipment_effect_timers(delta: float) -> void:
	if _spark_spell_damage_buff_time_left > 0.0:
		_spark_spell_damage_buff_time_left = maxf(_spark_spell_damage_buff_time_left - delta, 0.0)
	if not _spark_attack_speed_stack_time_lefts.is_empty():
		for i in range(_spark_attack_speed_stack_time_lefts.size() - 1, -1, -1):
			var time_left: float = maxf(float(_spark_attack_speed_stack_time_lefts[i]) - delta, 0.0)
			if time_left <= 0.0:
				_spark_attack_speed_stack_time_lefts.remove_at(i)
			else:
				_spark_attack_speed_stack_time_lefts[i] = time_left


func _register_spark_on_hit_bonuses() -> void:
	var attack_speed_bonus: float = _spark_effect_float("on_hit_attack_speed_bonus_percent", 0.0)
	var attack_speed_duration: float = _spark_effect_float(
		"on_hit_attack_speed_bonus_duration_sec", 0.0
	)
	if attack_speed_bonus > 0.0 and attack_speed_duration > 0.0:
		if _spark_attack_speed_stack_time_lefts.size() < 200:
			_spark_attack_speed_stack_time_lefts.append(attack_speed_duration)
	var spell_damage_bonus: float = _spark_effect_float("on_hit_spell_damage_bonus_percent", 0.0)
	var spell_damage_duration: float = _spark_effect_float(
		"on_hit_spell_damage_bonus_duration_sec", 0.0
	)
	if spell_damage_bonus > 0.0 and spell_damage_duration > 0.0:
		_spark_spell_damage_buff_time_left = maxf(
			_spark_spell_damage_buff_time_left, spell_damage_duration
		)


func _gain_spark_permanent_hp(amount: int) -> void:
	if amount <= 0:
		return
	_spark_permanent_hp_bonus_from_procs += amount
	_recalculate_war3_stats(false)
	_current_hp = mini(_current_hp + amount, max_hp)
	_update_hp_bar()


func _apply_spark_permanent_on_hit_progress() -> void:
	var hp_gain_per_hit: int = maxi(_spark_effect_int("on_hit_permanent_hp_gain", 0), 0)
	if hp_gain_per_hit > 0:
		_gain_spark_permanent_hp(hp_gain_per_hit)


func _gain_charge_permanent_hp(amount: int) -> void:
	if amount <= 0:
		return
	_charge_permanent_hp_bonus_from_procs += amount
	_recalculate_war3_stats(false)
	_current_hp = mini(_current_hp + amount, max_hp)
	_update_hp_bar()


func _apply_charge_permanent_on_hit_progress() -> void:
	var hp_gain_per_hit: int = maxi(_charge_effect_int("on_hit_permanent_hp_gain", 0), 0)
	if hp_gain_per_hit > 0:
		_gain_charge_permanent_hp(hp_gain_per_hit)


func _apply_charge_attack_effect_damage(primary_enemy: Node3D) -> void:
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return
	var primary_enemy_controller: Node = primary_enemy.get_parent()
	if primary_enemy_controller == null or not primary_enemy_controller.has_method("apply_damage"):
		return
	var agility_ratio: float = maxf(_charge_effect_float("attack_effect_agility_ratio", 0.0), 0.0)
	if agility_ratio <= 0.0:
		return
	var effect_base_damage: float = float(maxi(agility, 0)) * agility_ratio
	var damage_result: Dictionary = _compute_spell_damage_result(int(round(effect_base_damage)))
	var effect_damage: int = _get_damage_amount(damage_result)
	if effect_damage <= 0:
		return
	_apply_enemy_damage_with_network(
		primary_enemy_controller,
		primary_enemy,
		effect_damage,
		attack_range + 320.0,
		"charge_attack_effect",
		_build_damage_hit_context(damage_result)
	)


func _heal_self(amount: int) -> void:
	if amount <= 0:
		return
	if _is_dead:
		return
	_current_hp = mini(_current_hp + amount, max_hp)
	_update_hp_bar()


func _apply_spark_aoe_damage(
	center: Vector3, damage: int, radius: float, hit_context: Dictionary = {}
) -> void:
	if damage <= 0:
		return
	var safe_radius: float = maxf(radius, 1.0)
	var seen_enemy_ids: Dictionary = {}
	var candidates: Array = get_tree().get_nodes_in_group(enemy_group_name)
	for candidate_variant in candidates:
		var collider: Node3D = candidate_variant as Node3D
		if collider == null:
			continue
		var enemy: Node3D = collider.get_parent() as Node3D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_id: int = enemy.get_instance_id()
		if seen_enemy_ids.has(enemy_id):
			continue
		seen_enemy_ids[enemy_id] = true
		if _is_enemy_dead(enemy):
			continue
		if _distance_xz(center, enemy.global_position) > safe_radius:
			continue
		var enemy_controller: Node = enemy.get_parent()
		if enemy_controller == null or not enemy_controller.has_method("apply_damage"):
			continue
		_apply_enemy_damage_with_network(
			enemy_controller,
			enemy,
			damage,
			attack_range + safe_radius + 320.0,
			"attack_effect_aoe",
			hit_context
		)


func _apply_spark_attack_effect_damage(primary_enemy: Node3D) -> void:
	if primary_enemy == null or not is_instance_valid(primary_enemy):
		return
	var primary_enemy_controller: Node = primary_enemy.get_parent()
	if primary_enemy_controller == null or not primary_enemy_controller.has_method("apply_damage"):
		return

	var effect_multiplier: float = maxf(_spark_effect_float("attack_effect_multiplier", 1.0), 1.0)
	var low_hp_threshold: float = clampf(
		_spark_effect_float("attack_effect_low_hp_double_threshold", 0.0), 0.0, 1.0
	)
	var should_double_low_hp_effect: bool = false
	if low_hp_threshold > 0.0 and max_hp > 0:
		should_double_low_hp_effect = float(_current_hp) <= float(max_hp) * low_hp_threshold

	var flat_damage_component: float = maxf(
		_spark_effect_float("attack_effect_flat_damage", 0.0), 0.0
	)
	var heal_component: float = maxf(_spark_effect_float("attack_effect_flat_heal", 0.0), 0.0)
	if should_double_low_hp_effect:
		flat_damage_component *= 2.0
		heal_component *= 2.0

	var primary_base_damage: float = flat_damage_component
	primary_base_damage += (
		float(agility) * maxf(_spark_effect_float("attack_effect_agility_ratio", 0.0), 0.0)
	)
	primary_base_damage += (
		maxf(attack_speed_percent_total, 0.0)
		* maxf(_spark_effect_float("attack_effect_attack_speed_ratio", 0.0), 0.0)
	)
	primary_base_damage += (
		float(maxi(current_mana, 0))
		* maxf(_spark_effect_float("attack_effect_current_mana_ratio", 0.0), 0.0)
	)
	var total_item_level_scale: float = maxf(
		_spark_effect_float("attack_effect_total_item_level_scale", 0.0), 0.0
	)
	var inventory_level_sum: int = maxi(_spark_effect_int("inventory_level_sum", 0), 0)
	primary_base_damage += total_item_level_scale * float(inventory_level_sum)

	var primary_damage_result: Dictionary = _compute_spell_damage_result(
		int(round(primary_base_damage * effect_multiplier))
	)
	var primary_damage: int = _get_damage_amount(primary_damage_result)
	if primary_damage > 0:
		_apply_enemy_damage_with_network(
			primary_enemy_controller,
			primary_enemy,
			primary_damage,
			attack_range + 320.0,
			"attack_effect_primary",
			_build_damage_hit_context(primary_damage_result)
		)

	if heal_component > 0.0:
		_heal_self(int(round(heal_component)))

	var hp_ratio_aoe: float = maxf(_spark_effect_float("attack_effect_max_hp_ratio", 0.0), 0.0)
	if hp_ratio_aoe <= 0.0:
		return
	var aoe_base_damage: float = float(maxi(max_hp, 0)) * hp_ratio_aoe
	var aoe_damage_result: Dictionary = _compute_spell_damage_result(
		int(round(aoe_base_damage * effect_multiplier))
	)
	var aoe_damage: int = _get_damage_amount(aoe_damage_result)
	if aoe_damage <= 0:
		return
	var aoe_radius: float = maxf(
		_spark_effect_float("attack_effect_aoe_radius", SPARK_DEFAULT_AOE_RADIUS), 1.0
	)
	_apply_spark_aoe_damage(
		primary_enemy.global_position,
		aoe_damage,
		aoe_radius,
		_build_damage_hit_context(aoe_damage_result)
	)


func _refresh_start_area_recovery_zone() -> void:
	var owner_node: Node = get_parent()
	if owner_node == null:
		return
	if owner_node.has_method("get_start_area_center"):
		var center_variant: Variant = owner_node.call("get_start_area_center")
		if center_variant is Vector3:
			_start_area_center = center_variant
			_has_start_area_recovery_zone = true
	if owner_node.has_method("get_start_area_full_recovery_radius"):
		var radius_variant: Variant = owner_node.call("get_start_area_full_recovery_radius")
		_start_area_full_recovery_radius_runtime = _variant_to_positive_float(
			radius_variant, _start_area_full_recovery_radius_runtime
		)
	if _start_area_full_recovery_radius_runtime <= 0.0:
		_start_area_full_recovery_radius_runtime = maxf(
			start_area_full_recovery_radius_fallback, 0.0
		)


func _is_inside_start_area_recovery_zone() -> bool:
	if not start_area_full_recovery_enabled:
		return false
	if _hero == null:
		return false
	if not _has_start_area_recovery_zone:
		return false
	var radius: float = _start_area_full_recovery_radius_runtime
	if radius <= 0.0:
		radius = maxf(start_area_full_recovery_radius_fallback, 0.0)
	if radius <= 0.0:
		return false
	return _distance_xz(_hero.global_position, _start_area_center) <= radius


func _enforce_start_area_full_hp_mana() -> void:
	if not _is_inside_start_area_recovery_zone():
		return
	var changed: bool = false
	if _current_hp < max_hp:
		_current_hp = max_hp
		changed = true
	if current_mana < max_mana:
		current_mana = max_mana
		changed = true
	if changed:
		_hp_regen_pool = 0.0
		_mana_regen_pool = 0.0
		_update_hp_bar()


func _apply_regeneration(delta: float) -> void:
	if _is_dead:
		return
	if hp_regen_per_second > 0.0 and _current_hp < max_hp:
		_hp_regen_pool += hp_regen_per_second * delta
		var hp_gain: int = int(floor(_hp_regen_pool))
		if hp_gain > 0:
			_current_hp = mini(_current_hp + hp_gain, max_hp)
			_hp_regen_pool -= float(hp_gain)
			_update_hp_bar()
	elif _current_hp >= max_hp:
		_hp_regen_pool = 0.0
	if mana_regen_per_second > 0.0 and current_mana < max_mana:
		_mana_regen_pool += mana_regen_per_second * delta
		var mana_gain: int = int(floor(_mana_regen_pool))
		if mana_gain > 0:
			current_mana = mini(current_mana + mana_gain, max_mana)
			_mana_regen_pool -= float(mana_gain)
	elif current_mana >= max_mana:
		_mana_regen_pool = 0.0


func _try_consume_mana(cost: int) -> bool:
	var safe_cost: int = maxi(cost, 0)
	if safe_cost <= 0:
		return true
	if current_mana < safe_cost:
		return false
	current_mana = maxi(current_mana - safe_cost, 0)
	return true


func _refresh_attack_animations() -> void:
	_attack_animations.clear()
	if _animation_player == null:
		return

	var preferred: Array[String] = []
	if _is_transformed:
		if transformed_attack_animation_1 != "":
			preferred.append(transformed_attack_animation_1)
		if transformed_attack_animation_2 != "":
			preferred.append(transformed_attack_animation_2)
	else:
		if attack_animation_1 != "":
			preferred.append(attack_animation_1)
		if attack_animation_2 != "":
			preferred.append(attack_animation_2)
		if attack_animation_3 != "":
			preferred.append(attack_animation_3)

	for anim_name in preferred:
		if _animation_player.has_animation(anim_name):
			_attack_animations.append(anim_name)

	if _attack_animations.is_empty():
		var fallback_limit: int = 2 if _is_transformed else 3
		var anim_list: PackedStringArray = _animation_player.get_animation_list()
		for anim_name_sn in anim_list:
			var anim_name: String = String(anim_name_sn)
			if anim_name.to_lower().find("attack") >= 0:
				_attack_animations.append(anim_name)
				if _attack_animations.size() >= fallback_limit:
					break


func _input(event: InputEvent) -> void:
	if _hero == null or _is_dead:
		return
	if _input_locked_by_ui:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_A and key_event.pressed and not key_event.echo:
			_attack_mode = true
			_flash_mode = false
			_r_skill_mode = false
			_update_mouse_cursor_icon()
			return
		if key_event.keycode == KEY_Q and key_event.pressed and not key_event.echo:
			var can_cast_q: bool = (
				skill_q_id == SKILL_ID_Q_FLASH or skill_q_id == SKILL_ID_Q_RANGED_SHOT
			)
			var has_q_mana: bool = current_mana >= maxi(flash_mana_cost, 0)
			if can_cast_q and _flash_cooldown <= 0.0 and has_q_mana:
				_flash_mode = true
				_attack_mode = false
				_r_skill_mode = false
				_update_mouse_cursor_icon()
			return
		if key_event.keycode == KEY_W and key_event.pressed and not key_event.echo:
			_r_skill_mode = false
			_activate_haste()
			return
		if key_event.keycode == KEY_E and key_event.pressed and not key_event.echo:
			if skill_e_active:
				_r_skill_mode = false
				_activate_evasive_step()
			return
		if key_event.keycode == KEY_R and key_event.pressed and not key_event.echo:
			if (
				skill_r_active
				and _is_ranged_hero()
				and _r_cooldown <= 0.0
				and current_mana >= maxi(ranged_r_mana_cost, 0)
			):
				_r_skill_mode = true
				_flash_mode = false
				_attack_mode = false
				_update_mouse_cursor_icon()
			return
		if key_event.keycode == KEY_S:
			if key_event.pressed:
				if key_event.echo:
					return
				_stop_move_hold_active = true
				_apply_stop_movement_order()
			else:
				_stop_move_hold_active = false
			return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if _r_skill_mode:
				_r_skill_mode = false
				_update_mouse_cursor_icon()
				return
			_flash_mode = false
			_update_mouse_cursor_icon()
			_handle_right_click()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _flash_mode:
			get_viewport().set_input_as_handled()
			_handle_flash_click()
			_flash_mode = false
			_update_mouse_cursor_icon()
		elif (
			mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _r_skill_mode
		):
			get_viewport().set_input_as_handled()
			_handle_r_skill_click()
			_r_skill_mode = false
			_update_mouse_cursor_icon()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _attack_mode:
			get_viewport().set_input_as_handled()
			_handle_attack_click()
			_attack_mode = false
			_update_mouse_cursor_icon()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_left_click()


func _create_interaction_ray_query(from: Vector3, to: Vector3) -> PhysicsRayQueryParameters3D:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = INTERACTION_RAY_MASK
	return query


func _find_enemy_group_node(start: Node) -> Node3D:
	var cursor: Node = start
	while cursor != null:
		if cursor.is_in_group(enemy_group_name):
			return cursor as Node3D
		cursor = cursor.get_parent()
	return null


func _resolve_enemy_from_collider(collider: Node) -> Node3D:
	if collider == null:
		return null
	var enemy_group_node := _find_enemy_group_node(collider)
	if enemy_group_node == null:
		return null
	var enemy := enemy_group_node.get_parent() as Node3D
	if enemy == null or not is_instance_valid(enemy):
		return null
	return enemy


func _can_receive_skill_damage(enemy_controller: Node) -> bool:
	if enemy_controller == null:
		return false
	if enemy_controller.has_method("can_receive_skill_damage"):
		return bool(enemy_controller.call("can_receive_skill_damage"))
	return true


func _handle_left_click() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var space_state := get_world_3d().direct_space_state
	var query := _create_interaction_ray_query(ray_origin, ray_origin + ray_dir * 10000)
	var result := space_state.intersect_ray(query)
	if result and result.collider:
		var hit_node: Node = result.collider as Node
		var hit_name: String = "-"
		var hit_path: String = "-"
		var shop_owner_peer_id: int = 0
		if hit_node != null:
			hit_name = hit_node.name
			hit_path = str(hit_node.get_path())
			shop_owner_peer_id = _resolve_shop_owner_peer_id_from_node(hit_node)
		shop_click_debug_last_result = (
			"hit=%s path=%s in_shop=%s"
			% [hit_name, hit_path, "true" if shop_owner_peer_id > 0 else "false"]
		)
		if shop_owner_peer_id > 0:
			shop_clicked_owner_peer_id = shop_owner_peer_id
			shop_click_debug_last_result += " owner=%d" % shop_clicked_owner_peer_id
			shop_clicked = true
			return
	else:
		shop_click_debug_last_result = "hit=<none>"


func _resolve_shop_owner_peer_id_from_node(start_node: Node) -> int:
	var cursor: Node = start_node
	while cursor != null:
		if cursor.has_meta("shop_owner_peer_id"):
			return maxi(int(cursor.get_meta("shop_owner_peer_id")), 0)
		cursor = cursor.get_parent()
	return 0


func _handle_right_click() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	var space_state := get_world_3d().direct_space_state
	var query := _create_interaction_ray_query(ray_origin, ray_origin + ray_dir * 10000)
	var result := space_state.intersect_ray(query)

	if result and result.collider:
		var collider: Node = result.collider as Node
		var shop_owner_peer_id: int = _resolve_shop_owner_peer_id_from_node(collider)
		if shop_owner_peer_id > 0:
			# 右键命中商店碰撞体时，按地面点处理，避免角色被“吸”向商店。
			_interrupt_attack_for_move()
			_target_enemy = null
			_focus_lock = false
			_target_position = _get_ground_position(mouse_pos)
			_has_move_target = true
			_push_network_control_command("move_to", {"target_pos": _target_position})
			_spawn_move_confirmation_effect(_target_position)
			return
		var clicked_enemy := _resolve_enemy_from_collider(collider)
		if clicked_enemy != null and not _is_enemy_dead(clicked_enemy):
			_target_enemy = clicked_enemy
			_has_move_target = false
			_focus_lock = false
			_push_network_control_command(
				"chase_target",
				{
					"target_path": str(clicked_enemy.get_path()),
					"target_pos": clicked_enemy.global_position
				}
			)
		else:
			var click_pos: Vector3 = _get_ground_position(mouse_pos)
			_interrupt_attack_for_move()
			_target_enemy = null
			_focus_lock = false
			_target_position = Vector3(click_pos.x, _plane_height, click_pos.z)
			_has_move_target = true
			_push_network_control_command("move_to", {"target_pos": _target_position})
			_spawn_move_confirmation_effect(_target_position)
	else:
		_interrupt_attack_for_move()
		_target_enemy = null
		_focus_lock = false
		_target_position = _get_ground_position(mouse_pos)
		_has_move_target = true
		_push_network_control_command("move_to", {"target_pos": _target_position})
		_spawn_move_confirmation_effect(_target_position)


func _handle_flash_click() -> void:
	if _is_network_attack_locked():
		return
	if _flash_cooldown > 0.0:
		return
	if not _try_consume_mana(flash_mana_cost):
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var target := _get_ground_position(mouse_pos)
	if skill_q_id == SKILL_ID_Q_RANGED_SHOT:
		_cast_ranged_q(target)
		return
	var had_enemy_target: bool = (
		_target_enemy != null
		and is_instance_valid(_target_enemy)
		and not _is_enemy_dead(_target_enemy)
	)
	var current := _hero.global_position
	var direction := target - current
	direction.y = 0.0
	var dist := direction.length()
	var q_max_distance: float = flash_max_distance + _talent_float("q_distance_bonus_flat", 0.0)
	if dist > q_max_distance:
		target = current + direction.normalized() * q_max_distance
		target.y = _plane_height
	var q_damage: int = int(round(float(flash_damage) * _talent_float("q_damage_multiplier", 1.0)))
	_apply_flash_area_damage(current, flash_origin_damage_radius, q_damage, "flash_origin")
	_spawn_flash_effect(current)
	_interrupt_attack_for_move()
	_has_move_target = false
	_is_moving = false
	_hero.global_position = target
	_apply_flash_area_damage(target, flash_destination_damage_radius, q_damage, "flash_destination")
	if _is_warden_hero():
		var phantom_ratio: float = _talent_float("q_origin_echo_ratio", 0.0)
		if phantom_ratio > 0.0:
			_apply_flash_area_damage(
				current,
				flash_origin_damage_radius,
				int(round(float(q_damage) * phantom_ratio)),
				"flash_origin_echo"
			)
	_flash_cooldown = _compute_skill_cooldown(
		flash_cooldown_time * _talent_float("q_cooldown_multiplier", 1.0)
	)
	_push_network_skill_event(
		"q", skill_q_id, {"from_pos": current, "to_pos": target, "yaw": _hero.rotation.y}
	)
	_push_network_control_command("cast_skill", {"skill_id": skill_q_id, "target_pos": target})
	_stop_animation()
	if had_enemy_target:
		_resume_enemy_target_after_skill()


func _handle_r_skill_click() -> void:
	if _is_network_attack_locked():
		return
	if not skill_r_active or not _is_ranged_hero():
		return
	if _r_cooldown > 0.0:
		return
	if not _try_consume_mana(ranged_r_mana_cost):
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var target := _get_ground_position(mouse_pos)
	_cast_ranged_r(target)


func _cast_ranged_r(target: Vector3) -> void:
	if _hero == null:
		return
	var start_pos: Vector3 = _hero.global_position
	var impact_pos: Vector3 = target
	impact_pos.y = _plane_height
	var cast_delta: Vector3 = impact_pos - start_pos
	cast_delta.y = 0.0
	var cast_dist: float = cast_delta.length()
	var cast_range: float = maxf(ranged_r_cast_max_distance, 0.0)
	if cast_range > 0.0 and cast_dist > cast_range and cast_delta.length() > 0.01:
		impact_pos = start_pos + cast_delta.normalized() * cast_range
		impact_pos.y = _plane_height
	_face_toward(impact_pos)
	_spawn_ranged_r_projectile_and_impact(start_pos, impact_pos)
	_r_cooldown = _compute_skill_cooldown(
		ranged_r_cooldown_time * _talent_float("r_cooldown_multiplier", 1.0)
	)
	_push_network_skill_event(
		"r",
		skill_r_id,
		{
			"from_pos": start_pos,
			"to_pos": impact_pos,
			"radius": maxf(ranged_r_radius, 0.0),
			"visual_scale": _get_ranged_r_impact_scale_multiplier()
		}
	)
	_push_network_control_command("cast_skill", {"skill_id": skill_r_id, "target_pos": impact_pos})


func _spawn_ranged_r_projectile_and_impact(start_pos: Vector3, impact_pos: Vector3) -> void:
	_ensure_r_skill_runtime_resources()
	var host: Node = get_parent()
	if host == null:
		_spawn_ranged_r_bombardment(impact_pos, start_pos)
		return
	var planar_delta: Vector3 = impact_pos - start_pos
	planar_delta.y = 0.0
	var flight_distance: float = maxf(planar_delta.length(), 0.0)
	var speed: float = maxf(ranged_r_projectile_speed, 1.0)
	var min_flight: float = maxf(ranged_r_projectile_min_flight_time, 0.02)
	var flight_duration: float = maxf(flight_distance / speed, min_flight)
	if ranged_r_missile_scene == null:
		get_tree().create_timer(flight_duration).timeout.connect(
			func() -> void: _spawn_ranged_r_bombardment(impact_pos, start_pos)
		)
		return
	var projectile := ranged_r_missile_scene.instantiate() as Node3D
	if projectile == null:
		get_tree().create_timer(flight_duration).timeout.connect(
			func() -> void: _spawn_ranged_r_bombardment(impact_pos, start_pos)
		)
		return
	host.add_child(projectile)
	projectile.global_position = start_pos
	projectile.scale = projectile.scale * _get_ranged_r_impact_scale_multiplier()
	if planar_delta.length() > 0.01:
		projectile.look_at(impact_pos, Vector3.UP)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(projectile, "global_position", impact_pos, flight_duration)
	tween.finished.connect(
		func() -> void:
			if projectile != null and is_instance_valid(projectile):
				projectile.queue_free()
			_spawn_ranged_r_bombardment(impact_pos, start_pos)
	)


func _spawn_ranged_r_bombardment(center: Vector3, cast_origin: Vector3) -> void:
	var tick_count: int = maxi(
		RIFLEMAN_BOMBARDMENT_TICK_COUNT + _talent_int("r_tick_count_bonus", 0), 1
	)
	var tick_interval: float = maxf(RIFLEMAN_BOMBARDMENT_TICK_INTERVAL_SEC, 0.05)
	_spawn_ranged_r_impact_effect(center)
	for tick_idx in range(tick_count):
		var delay_sec: float = float(tick_idx) * tick_interval
		var hit_center: Vector3 = center
		var hit_origin: Vector3 = cast_origin
		get_tree().create_timer(delay_sec).timeout.connect(
			func() -> void: _apply_ranged_r_area_damage(hit_center, hit_origin)
		)


func _spawn_ranged_r_impact_effect(impact_pos: Vector3) -> void:
	var center: Vector3 = impact_pos
	center.y = _plane_height
	if ranged_r_impact_scene == null:
		return
	var host: Node = get_parent()
	if host == null:
		return
	var effect := ranged_r_impact_scene.instantiate() as Node3D
	if effect == null:
		return
	var effect_root := Node3D.new()
	effect_root.name = "RangedRImpactRoot"
	host.add_child(effect_root)
	effect_root.global_position = center
	effect_root.scale = Vector3.ONE * _get_ranged_r_impact_scale_multiplier()
	effect_root.add_child(effect)
	effect.position = Vector3.ZERO
	var duration: float = _play_one_shot_effect_animation(
		effect, "Birth", RANGED_R_LOGIC_POINT_LIFETIME_SEC
	)
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if effect_root != null and is_instance_valid(effect_root):
				effect_root.queue_free()
	)


func _play_one_shot_effect_animation(
	effect: Node3D, preferred_animation: String = "", forced_duration_sec: float = -1.0
) -> float:
	var duration: float = 0.8
	if forced_duration_sec > 0.0:
		duration = maxf(forced_duration_sec, 0.05)
	if effect == null or not is_instance_valid(effect):
		return duration
	var anim_player := effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
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


func _apply_ranged_r_area_damage(center: Vector3, cast_origin: Vector3) -> void:
	var radius: float = maxf(ranged_r_radius + _talent_float("r_radius_bonus_flat", 0.0), 0.0)
	var damage: int = maxi(
		int(round(float(ranged_r_damage) * _talent_float("r_damage_multiplier", 1.0))), 0
	)
	if radius <= 0.0 or damage <= 0:
		return
	var request_context: Dictionary = {
		"center": center,
		"radius": radius,
		"cast_range": maxf(ranged_r_cast_max_distance, 0.0),
		"origin": cast_origin
	}
	var hit_controllers: Dictionary = {}
	var candidates := get_tree().get_nodes_in_group(enemy_group_name)
	for candidate in candidates:
		var collider := candidate as Node3D
		if collider == null:
			continue
		var enemy := collider.get_parent() as Node3D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if _is_enemy_dead(enemy):
			continue
		var distance: float = _distance_xz(center, enemy.global_position)
		if distance > radius:
			continue
		var enemy_controller := enemy.get_parent()
		if enemy_controller == null or not enemy_controller.has_method("apply_damage"):
			continue
		if not _can_receive_skill_damage(enemy_controller):
			continue
		var controller_id: int = enemy_controller.get_instance_id()
		if hit_controllers.has(controller_id):
			continue
		hit_controllers[controller_id] = true
		var r_armor_shred_percent: float = _talent_float(
			"rifleman_r_permanent_armor_shred_percent", 0.0
		)
		if _submit_enemy_damage_with_confirmation(
			enemy_controller,
			enemy,
			damage,
			-1.0,
			"r_cluster",
			request_context,
			{
				"kind": "attack_count_only",
				"attack_count": 1,
				"armor_shred_percent": r_armor_shred_percent,
				"armor_shred_permanent": true
			}
		):
			_add_attack_count(1)


func _cast_ranged_q(target: Vector3) -> void:
	if _hero == null:
		return
	var current := _hero.global_position
	var direction := target - current
	direction.y = 0.0
	if direction.length() <= 0.01:
		var fallback_forward := -_hero.global_basis.z
		direction = Vector3(fallback_forward.x, 0.0, fallback_forward.z)
	if direction.length() <= 0.01:
		direction = Vector3.FORWARD
	direction = direction.normalized()
	var ray_length: float = maxf(
		ranged_q_ray_length + _talent_float("q_distance_bonus_flat", 0.0), 1.0
	)
	var ray_end: Vector3 = current + direction * ray_length
	ray_end.y = current.y

	_face_toward(current + direction * 10.0)
	_spawn_ranged_q_ray(current, ray_end)
	_apply_ranged_q_ray_damage(current, ray_end)
	_push_network_skill_event(
		"q", skill_q_id, {"from_pos": current, "to_pos": ray_end, "yaw": _hero.rotation.y}
	)
	_push_network_control_command("cast_skill", {"skill_id": skill_q_id, "target_pos": ray_end})
	_interrupt_attack_for_move()
	_has_move_target = false
	_is_moving = false
	_perform_ranged_q_backstep(-direction)
	_flash_cooldown = _compute_skill_cooldown(
		flash_cooldown_time * _talent_float("q_cooldown_multiplier", 1.0)
	)


func _perform_ranged_q_backstep(
	back_direction: Vector3,
	ignore_obstacle_avoidance: bool = false,
	custom_distance: float = -1.0,
	custom_duration: float = -1.0
) -> void:
	if _hero == null:
		return
	var safe_back_dir: Vector3 = back_direction
	safe_back_dir.y = 0.0
	if safe_back_dir.length() <= 0.01:
		return
	safe_back_dir = safe_back_dir.normalized()
	var safe_distance: float = maxf(
		custom_distance if custom_distance >= 0.0 else ranged_q_backstep_distance, 0.0
	)
	if safe_distance <= 0.0:
		return

	var current := _hero.global_position
	var intended_target := current + safe_back_dir * safe_distance
	intended_target.y = _plane_height
	var final_target: Vector3 = intended_target
	if not ignore_obstacle_avoidance:
		final_target = _compute_next_move_with_obstacle_avoidance(
			current, intended_target, safe_distance
		)
	final_target.y = _plane_height
	_target_position = final_target

	if _ranged_q_backstep_tween != null and _ranged_q_backstep_tween.is_valid():
		_ranged_q_backstep_tween.kill()
	_ranged_q_backstep_tween = null

	var duration: float = maxf(
		custom_duration if custom_duration >= 0.0 else ranged_q_backstep_duration, 0.01
	)
	_ranged_q_backstep_active = true
	_ranged_q_backstep_total_time = duration
	_ranged_q_backstep_time_left = duration
	_ranged_q_backstep_start_pos = current
	_ranged_q_backstep_end_pos = final_target
	_is_moving = true
	_play_walk_animation()


func _update_ranged_q_backstep(delta: float) -> void:
	if not _ranged_q_backstep_active:
		return
	if _hero == null or not is_instance_valid(_hero):
		_ranged_q_backstep_active = false
		_ranged_q_backstep_time_left = 0.0
		_ranged_q_backstep_total_time = 0.0
		return
	_ranged_q_backstep_time_left = maxf(_ranged_q_backstep_time_left - delta, 0.0)
	var total_time: float = maxf(_ranged_q_backstep_total_time, 0.001)
	var progress: float = 1.0 - (_ranged_q_backstep_time_left / total_time)
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var eased_progress: float = clamped_progress * clamped_progress * (3.0 - 2.0 * clamped_progress)
	var next_pos: Vector3 = _ranged_q_backstep_start_pos.lerp(
		_ranged_q_backstep_end_pos, eased_progress
	)
	next_pos.y = _plane_height
	_hero.global_position = next_pos
	_target_position = next_pos
	if _ranged_q_backstep_time_left <= 0.0:
		_hero.global_position = _ranged_q_backstep_end_pos
		_ranged_q_backstep_active = false
		_ranged_q_backstep_total_time = 0.0
		_is_moving = false
		_stop_animation()


func _apply_ranged_q_ray_damage(ray_start: Vector3, ray_end: Vector3) -> void:
	var ray_vec: Vector3 = ray_end - ray_start
	ray_vec.y = 0.0
	var ray_len: float = ray_vec.length()
	if ray_len <= 0.01:
		return
	var ray_dir: Vector3 = ray_vec / ray_len
	var safe_damage: int = maxi(
		int(round(float(ranged_q_ray_damage) * _talent_float("q_damage_multiplier", 1.0))), 0
	)
	if safe_damage <= 0:
		return
	var knockback_distance: float = maxf(ranged_q_ray_knockback_distance, 0.0)
	var knockback_duration: float = clampf(ranged_q_ray_knockback_duration, 0.05, 0.2)
	var knockback_priority: int = maxi(ranged_q_ray_knockback_priority, 0)
	var safe_hit_radius: float = maxf(ranged_q_ray_hit_radius, 1.0)
	var precision_triggered: bool = _consume_rifleman_precision_trigger()
	var request_context: Dictionary = {
		"ray_start": ray_start,
		"ray_end": ray_end,
		"ray_radius": safe_hit_radius,
		"knockback_dir": ray_dir,
		"knockback_distance": knockback_distance,
		"knockback_duration": knockback_duration,
		"knockback_priority": knockback_priority
	}
	var hit_controllers: Dictionary = {}
	var candidates := get_tree().get_nodes_in_group(enemy_group_name)
	for candidate in candidates:
		var collider := candidate as Node3D
		if collider == null:
			continue
		var enemy := collider.get_parent() as Node3D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if _is_enemy_dead(enemy):
			continue
		var rel: Vector3 = enemy.global_position - ray_start
		rel.y = 0.0
		var projection: float = rel.dot(ray_dir)
		if projection < 0.0 or projection > ray_len:
			continue
		var closest: Vector3 = ray_start + ray_dir * projection
		var lateral_distance: float = _distance_xz(enemy.global_position, closest)
		if lateral_distance > safe_hit_radius:
			continue
		var enemy_controller := enemy.get_parent()
		if enemy_controller == null or not enemy_controller.has_method("apply_damage"):
			continue
		if not _can_receive_skill_damage(enemy_controller):
			continue
		var controller_id: int = enemy_controller.get_instance_id()
		if hit_controllers.has(controller_id):
			continue
		hit_controllers[controller_id] = true
		var q_armor_shred_percent: float = _talent_float("rifleman_q_armor_shred_percent", 0.0)
		if _submit_enemy_damage_with_confirmation(
			enemy_controller,
			enemy,
			safe_damage,
			ray_len + 40.0,
			"q_ray",
			request_context,
			{
				"kind": "q_ray",
				"attack_count": 1,
				"precision_triggered": precision_triggered,
				"precision_knockback_multiplier": RIFLEMAN_PRECISION_Q_KNOCKBACK_MULTIPLIER,
				"armor_shred_percent": q_armor_shred_percent,
				"armor_shred_duration_sec":
				_talent_float("rifleman_q_armor_shred_duration_sec", 10.0)
			}
		):
			if precision_triggered:
				_apply_rifleman_precision_bonus(
					enemy_controller, enemy, RIFLEMAN_PRECISION_Q_KNOCKBACK_MULTIPLIER
				)
			_apply_q_ray_knockback_local_if_authority(
				enemy_controller,
				ray_dir,
				knockback_distance,
				knockback_duration,
				knockback_priority
			)
			_add_attack_count(1)


func _apply_q_ray_knockback_local_if_authority(
	enemy_controller: Node,
	knockback_dir: Vector3,
	distance: float,
	duration_sec: float,
	priority: int
) -> void:
	if enemy_controller == null:
		return
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl != null and net_ctrl.has_method("is_local_world_authority"):
		if not bool(net_ctrl.call("is_local_world_authority")):
			return
	if distance <= 0.0:
		return
	if not enemy_controller.has_method("apply_knockback"):
		return
	var planar_dir: Vector3 = knockback_dir
	planar_dir.y = 0.0
	if planar_dir.length_squared() <= 0.0001:
		return
	enemy_controller.call(
		"apply_knockback",
		planar_dir.normalized(),
		distance,
		clampf(duration_sec, 0.05, 0.5),
		maxi(priority, 0)
	)


func _apply_flash_area_damage(
	center: Vector3, radius: float, damage: int, source: String = "flash"
) -> void:
	if radius <= 0.0 or damage <= 0:
		return
	var request_context: Dictionary = {"center": center, "radius": radius}
	var hit_controllers: Dictionary = {}
	var candidates := get_tree().get_nodes_in_group(enemy_group_name)
	for candidate in candidates:
		var collider := candidate as Node3D
		if collider == null:
			continue
		var enemy := collider.get_parent() as Node3D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if _is_enemy_dead(enemy):
			continue
		var distance: float = _distance_xz(center, enemy.global_position)
		if distance > radius:
			continue
		var enemy_controller := enemy.get_parent()
		if enemy_controller == null or not enemy_controller.has_method("apply_damage"):
			continue
		if not _can_receive_skill_damage(enemy_controller):
			continue
		var controller_id: int = enemy_controller.get_instance_id()
		if hit_controllers.has(controller_id):
			continue
		hit_controllers[controller_id] = true
		var damage_result: Dictionary = _compute_spell_damage_result(damage)
		var final_damage: int = _get_damage_amount(damage_result)
		if _submit_enemy_damage_with_confirmation(
			enemy_controller,
			enemy,
			final_damage,
			radius + 40.0,
			source,
			_merge_damage_hit_context(request_context, damage_result),
			{"kind": "attack_count_only", "attack_count": 1}
		):
			_add_attack_count(1)


func _activate_haste() -> void:
	if skill_w_id != SKILL_ID_W_HASTE and skill_w_id != SKILL_ID_W_RANGED_SPEED:
		return
	if _haste_active:
		return
	if _haste_cooldown > 0.0:
		return
	if not _try_consume_mana(haste_mana_cost):
		return
	_haste_active = true
	_haste_time_left = haste_duration + _talent_float("w_duration_bonus_sec", 0.0)
	_haste_cooldown = _compute_skill_cooldown(
		haste_cooldown_time * _talent_float("w_cooldown_multiplier", 1.0)
	)
	if _is_warden_hero():
		_warden_ring_attacks_left = (
			WARDEN_RING_MAX_ATTACKS + _talent_int("warden_w_attack_count_bonus", 0)
		)
	var event_pos: Vector3 = Vector3.ZERO
	if _hero != null:
		event_pos = _hero.global_position
	_push_network_skill_event("w", skill_w_id, {"pos": event_pos})
	_push_network_control_command("cast_skill", {"skill_id": skill_w_id, "target_pos": event_pos})
	_sync_walk_animation_speed_if_needed()


func _activate_evasive_step() -> void:
	if not skill_e_active:
		return
	if _e_cooldown > 0.0:
		return
	if not _try_consume_mana(evasive_mana_cost):
		return
	var back_direction := Vector3.BACK
	if _hero != null and is_instance_valid(_hero):
		var forward := -_hero.global_basis.z
		back_direction = Vector3(-forward.x, 0.0, -forward.z)
	var evasive_distance: float = melee_evasive_distance
	var evasive_duration: float = melee_evasive_duration
	if _is_ranged_hero():
		evasive_distance = ranged_evasive_distance
		evasive_duration = ranged_evasive_duration
	_interrupt_attack_for_move()
	_has_move_target = false
	_is_moving = false
	_perform_ranged_q_backstep(back_direction, false, evasive_distance, evasive_duration)
	_e_cooldown = _compute_skill_cooldown(evasive_cooldown_time)
	var event_pos: Vector3 = Vector3.ZERO
	if _hero != null and is_instance_valid(_hero):
		event_pos = _hero.global_position
	_push_network_skill_event("e", skill_e_id, {"pos": event_pos})
	_push_network_control_command("cast_skill", {"skill_id": skill_e_id, "target_pos": event_pos})


func _push_network_control_command(command_type: String, extra: Dictionary = {}) -> void:
	var normalized_type: String = command_type.strip_edges().to_lower()
	if normalized_type.is_empty():
		normalized_type = "idle"
	_network_command_seq += 1
	var payload: Dictionary = {
		"seq": _network_command_seq, "type": normalized_type, "t_ms": Time.get_ticks_msec()
	}
	if _hero != null and is_instance_valid(_hero):
		payload["target_pos"] = _hero.global_position
	for key_variant in extra.keys():
		payload[key_variant] = extra[key_variant]
	_network_last_command = payload
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl == null:
		return
	var mode_text: String = str(net_ctrl.get("network_mode")).strip_edges().to_lower()
	if mode_text == "client" and net_ctrl.has_method("request_hero_control_command_from_client"):
		net_ctrl.call("request_hero_control_command_from_client", payload.duplicate(true))


func get_network_command_state() -> Dictionary:
	if _network_last_command.is_empty():
		return {}
	return _network_last_command.duplicate(true)


func _push_network_skill_event(
	event_type: String, event_skill_id: int, extra: Dictionary = {}
) -> void:
	_network_skill_event_seq += 1
	var payload: Dictionary = {
		"seq": _network_skill_event_seq,
		"type": event_type,
		"skill_id": event_skill_id,
		"t_ms": Time.get_ticks_msec()
	}
	for key_variant in extra.keys():
		payload[key_variant] = extra[key_variant]
	_network_last_skill_event = payload
	_register_necromancy_skill_cast()


func _apply_poison_to_enemy(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if poison_damage_per_second <= 0:
		return
	var enemy_controller: Node = enemy.get_parent()
	if enemy_controller == null or not _can_receive_skill_damage(enemy_controller):
		return
	var safe_duration: float = maxf(
		poison_duration + _talent_float("w_poison_duration_bonus_sec", 0.0), 0.1
	)
	var safe_tick_interval: float = maxf(poison_tick_interval, 0.05)
	var target_id: int = enemy.get_instance_id()
	var entry: Dictionary = {
		"node": enemy, "time_left": safe_duration, "tick_left": safe_tick_interval
	}
	_poison_targets[target_id] = entry


func _apply_poison_tick_damage(enemy: Node3D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if _is_enemy_dead(enemy):
		return
	var enemy_controller: Node = enemy.get_parent()
	if (
		enemy_controller != null
		and enemy_controller.has_method("apply_damage")
		and _can_receive_skill_damage(enemy_controller)
	):
		var poison_multiplier: float = _talent_float("w_poison_damage_multiplier", 1.0)
		var damage_result: Dictionary = _compute_spell_damage_result(
			int(round(float(poison_damage_per_second) * poison_multiplier))
		)
		var final_damage: int = _get_damage_amount(damage_result)
		if _submit_enemy_damage_with_confirmation(
			enemy_controller,
			enemy,
			final_damage,
			-1.0,
			"poison",
			_build_damage_hit_context(damage_result),
			{"kind": "attack_count_only", "attack_count": 1, "retarget_on_kill": true}
		):
			_add_attack_count(1)
			if _target_enemy == enemy and _is_enemy_dead(enemy):
				_acquire_next_enemy_target_after_kill()


func _apply_enemy_damage_with_network(
	enemy_controller: Node,
	enemy: Node3D,
	damage: int,
	max_range: float,
	source: String,
	context: Dictionary = {}
) -> bool:
	if enemy_controller == null:
		return false
	var safe_damage: int = _sanitize_network_damage_amount(enemy, damage)
	if safe_damage <= 0:
		return false
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl != null:
		var mode_text: String = str(net_ctrl.get("network_mode")).strip_edges().to_lower()
		if mode_text == "client":
			if not net_ctrl.has_method("request_enemy_damage_from_client"):
				return false
			var target_path: String = ""
			if enemy != null and is_instance_valid(enemy):
				target_path = str(enemy.get_path())
			if target_path.is_empty():
				target_path = str(enemy_controller.get_path())
			if target_path.is_empty():
				return false
			var accepted_variant: Variant = net_ctrl.call(
				"request_enemy_damage_from_client",
				target_path,
				safe_damage,
				max_range,
				source,
				context
			)
			return bool(accepted_variant)
	if enemy_controller.has_method("apply_damage"):
		var attacker: Node3D = null
		if _hero != null and is_instance_valid(_hero):
			attacker = _hero
		enemy_controller.call("apply_damage", safe_damage, attacker, source, context)
		return true
	return false


func _sanitize_network_damage_amount(enemy: Node3D, damage: int) -> int:
	var safe_damage: int = maxi(damage, 0)
	if safe_damage <= 0:
		return 0
	if enemy != null and is_instance_valid(enemy):
		var bonus_percent: float = _get_enemy_damage_bonus_percent(enemy)
		if bonus_percent > 0.0:
			safe_damage = maxi(int(round(float(safe_damage) * (1.0 + bonus_percent * 0.01))), 1)
	return safe_damage


func _build_enemy_damage_target_path(enemy_controller: Node, enemy: Node3D) -> String:
	var target_path: String = ""
	if enemy != null and is_instance_valid(enemy):
		target_path = str(enemy.get_path())
	if target_path.is_empty() and enemy_controller != null:
		target_path = str(enemy_controller.get_path())
	return target_path


func _submit_enemy_damage_with_confirmation(
	enemy_controller: Node,
	enemy: Node3D,
	damage: int,
	max_range: float,
	source: String,
	context: Dictionary = {},
	pending_confirmation: Dictionary = {}
) -> bool:
	if enemy_controller == null:
		return false
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl != null:
		var mode_text: String = str(net_ctrl.get("network_mode")).strip_edges().to_lower()
		if mode_text == "client":
			if not net_ctrl.has_method("request_enemy_damage_from_client"):
				return false
			var target_path: String = _build_enemy_damage_target_path(enemy_controller, enemy)
			if target_path.is_empty():
				return false
			var safe_damage: int = _sanitize_network_damage_amount(enemy, damage)
			if safe_damage <= 0:
				return false
			var sent_variant: Variant = net_ctrl.call(
				"request_enemy_damage_from_client",
				target_path,
				safe_damage,
				max_range,
				source,
				context
			)
			if not bool(sent_variant):
				return false
			if (
				not pending_confirmation.is_empty()
				and net_ctrl.has_method("get_last_sent_enemy_damage_request_seq")
			):
				var request_seq: int = int(net_ctrl.call("get_last_sent_enemy_damage_request_seq"))
				if request_seq >= 0:
					var pending_entry: Dictionary = pending_confirmation.duplicate(true)
					pending_entry["source"] = source.strip_edges().to_lower()
					pending_entry["target_path"] = target_path
					_pending_damage_confirmations[request_seq] = pending_entry
			return false
	return _apply_enemy_damage_with_network(
		enemy_controller, enemy, damage, max_range, source, context
	)


func _resolve_enemy_from_damage_target_path(target_path: String) -> Node3D:
	if target_path.strip_edges().is_empty():
		return null
	var target_node: Node = get_node_or_null(NodePath(target_path))
	if target_node == null:
		return null
	var resolved_enemy: Node3D = _resolve_enemy_from_collider(target_node)
	if resolved_enemy != null and is_instance_valid(resolved_enemy):
		return resolved_enemy
	var direct_enemy: Node3D = target_node as Node3D
	if direct_enemy != null and is_instance_valid(direct_enemy):
		var parent_node: Node = direct_enemy.get_parent()
		if parent_node != null and parent_node.has_method("apply_damage"):
			return direct_enemy
	return null


func on_authority_enemy_damage_confirmed(result: Dictionary) -> void:
	if result.is_empty():
		return
	var request_seq: int = int(result.get("request_seq", -1))
	if request_seq < 0:
		return
	if not _pending_damage_confirmations.has(request_seq):
		return
	var pending_variant: Variant = _pending_damage_confirmations.get(request_seq, {})
	_pending_damage_confirmations.erase(request_seq)
	if not bool(result.get("accepted", false)):
		return
	if not (pending_variant is Dictionary):
		return
	_apply_confirmed_enemy_damage_effects(pending_variant as Dictionary)


func _apply_confirmed_enemy_damage_effects(pending: Dictionary) -> void:
	var kind: String = str(pending.get("kind", "")).strip_edges().to_lower()
	match kind:
		"basic_attack":
			_apply_confirmed_basic_attack_effects(pending)
		"q_ray":
			_apply_confirmed_q_ray_effects(pending)
		"attack_count_only":
			_apply_confirmed_attack_count_only_effects(pending)
		_:
			pass


func _apply_confirmed_attack_count_only_effects(pending: Dictionary) -> void:
	var target_enemy: Node3D = _resolve_enemy_from_damage_target_path(
		str(pending.get("target_path", ""))
	)
	_apply_confirmed_enemy_armor_shred(target_enemy, pending)
	var attack_count_gain: int = maxi(int(pending.get("attack_count", 0)), 0)
	if attack_count_gain > 0:
		_add_attack_count(attack_count_gain)
	if bool(pending.get("retarget_on_kill", false)):
		if target_enemy != null and target_enemy == _target_enemy and _is_enemy_dead(target_enemy):
			_acquire_next_enemy_target_after_kill()


func _apply_confirmed_q_ray_effects(pending: Dictionary) -> void:
	var target_enemy: Node3D = _resolve_enemy_from_damage_target_path(
		str(pending.get("target_path", ""))
	)
	_apply_confirmed_enemy_armor_shred(target_enemy, pending)
	if (
		bool(pending.get("precision_triggered", false))
		and target_enemy != null
		and is_instance_valid(target_enemy)
	):
		var enemy_controller: Node = target_enemy.get_parent()
		if enemy_controller != null and enemy_controller.has_method("apply_damage"):
			_apply_rifleman_precision_bonus(
				enemy_controller,
				target_enemy,
				float(pending.get("precision_knockback_multiplier", 1.0))
			)
	var attack_count_gain: int = maxi(int(pending.get("attack_count", 0)), 0)
	if attack_count_gain > 0:
		_add_attack_count(attack_count_gain)


func _apply_confirmed_basic_attack_effects(pending: Dictionary) -> void:
	var target_enemy: Node3D = _resolve_enemy_from_damage_target_path(
		str(pending.get("target_path", ""))
	)
	_register_necromancy_basic_attack_charge_gain()
	_register_spark_on_hit_bonuses()
	_apply_spark_permanent_on_hit_progress()
	if target_enemy != null and is_instance_valid(target_enemy):
		_apply_spark_attack_effect_damage(target_enemy)
	_apply_charge_permanent_on_hit_progress()
	if target_enemy != null and is_instance_valid(target_enemy):
		_apply_charge_attack_effect_damage(target_enemy)
	var precision_triggered: bool = _consume_rifleman_precision_trigger()
	if precision_triggered and target_enemy != null and is_instance_valid(target_enemy):
		var enemy_controller: Node = target_enemy.get_parent()
		if enemy_controller != null and enemy_controller.has_method("apply_damage"):
			_apply_rifleman_precision_bonus(enemy_controller, target_enemy)
	var attack_count_gain: int = maxi(int(pending.get("attack_count", 0)), 0)
	if attack_count_gain > 0:
		_add_attack_count(attack_count_gain)
	var w_cdr_refund_sec: float = _talent_float("warden_w_cooldown_refund_on_attack_sec", 0.0)
	if w_cdr_refund_sec > 0.0 and _haste_cooldown > 0.0:
		_haste_cooldown = maxf(_haste_cooldown - w_cdr_refund_sec, 0.0)
	var mana_gain_on_attack: int = _talent_int("warden_e_mana_gain_on_attack", 0)
	if mana_gain_on_attack > 0:
		current_mana = mini(current_mana + mana_gain_on_attack, max_mana)
	if target_enemy != null and is_instance_valid(target_enemy):
		var armor_shred_percent: float = _talent_float("warden_armor_shred_on_hit_percent", 0.0)
		if armor_shred_percent > 0.0:
			_apply_enemy_damage_bonus(
				target_enemy,
				armor_shred_percent,
				_talent_float("warden_armor_shred_duration_sec", 5.0)
			)
		if _should_apply_warden_poison_on_basic_attack():
			_apply_poison_to_enemy(target_enemy)
	if _is_warden_hero() and _haste_active:
		_apply_warden_vengeance_heal_on_attack()
		_consume_warden_ring_attack()
	if target_enemy != null and target_enemy == _target_enemy and _is_enemy_dead(target_enemy):
		_acquire_next_enemy_target_after_kill()


func _apply_confirmed_enemy_armor_shred(target_enemy: Node3D, pending: Dictionary) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy):
		return
	var armor_shred_percent: float = float(pending.get("armor_shred_percent", 0.0))
	if armor_shred_percent <= 0.0:
		return
	var duration_sec: float = float(pending.get("armor_shred_duration_sec", 0.0))
	var permanent: bool = bool(pending.get("armor_shred_permanent", false))
	_apply_enemy_damage_bonus(target_enemy, armor_shred_percent, duration_sec, permanent)


func _get_network_session_controller() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("net_session_controller")


func _notify_network_local_hero_ready() -> void:
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl == null:
		return
	if net_ctrl.has_method("notify_local_hero_ready"):
		net_ctrl.call("notify_local_hero_ready")


func begin_network_attack_lock_after_reposition(timeout_ms: int = 1200) -> void:
	var net_ctrl: Node = _get_network_session_controller()
	_network_attack_lock_active = false
	_network_attack_lock_required_ack_seq = -1
	_network_attack_lock_timeout_at_ms = 0
	if net_ctrl == null:
		return
	if str(net_ctrl.get("network_mode")).strip_edges().to_lower() != "client":
		return
	if (
		not net_ctrl.has_method("get_last_sent_client_input_seq")
		or not net_ctrl.has_method("get_last_acknowledged_client_input_seq")
	):
		return
	var required_ack_seq: int = int(net_ctrl.call("get_last_sent_client_input_seq"))
	var current_ack_seq: int = int(net_ctrl.call("get_last_acknowledged_client_input_seq"))
	if required_ack_seq <= current_ack_seq:
		return
	_network_attack_lock_active = true
	_network_attack_lock_required_ack_seq = required_ack_seq
	_network_attack_lock_timeout_at_ms = Time.get_ticks_msec() + maxi(timeout_ms, 100)


func _update_network_attack_lock_state() -> void:
	if not _network_attack_lock_active:
		return
	var now_ms: int = Time.get_ticks_msec()
	if _network_attack_lock_timeout_at_ms > 0 and now_ms >= _network_attack_lock_timeout_at_ms:
		_clear_network_attack_lock()
		return
	var net_ctrl: Node = _get_network_session_controller()
	if net_ctrl == null or not net_ctrl.has_method("get_last_acknowledged_client_input_seq"):
		return
	var current_ack_seq: int = int(net_ctrl.call("get_last_acknowledged_client_input_seq"))
	if current_ack_seq >= _network_attack_lock_required_ack_seq:
		_clear_network_attack_lock()


func _clear_network_attack_lock() -> void:
	_network_attack_lock_active = false
	_network_attack_lock_required_ack_seq = -1
	_network_attack_lock_timeout_at_ms = 0


func _is_network_attack_locked() -> bool:
	return _network_attack_lock_active


func _roll_critical(chance_percent: float) -> bool:
	var clamped_chance: float = clampf(chance_percent, 0.0, 100.0)
	if clamped_chance <= 0.0:
		return false
	return randf() * 100.0 < clamped_chance


func _compute_physical_damage(base_damage_amount: int) -> int:
	return _get_damage_amount(_compute_physical_damage_result(base_damage_amount))


func _compute_spell_damage(base_damage_amount: int) -> int:
	return _get_damage_amount(_compute_spell_damage_result(base_damage_amount))


func _compute_physical_damage_result(base_damage_amount: int) -> Dictionary:
	return HeroStatsService.compute_physical_damage_result(
		base_damage_amount, physical_crit_chance, physical_crit_multiplier
	)


func _compute_spell_damage_result(base_damage_amount: int) -> Dictionary:
	return HeroStatsService.compute_spell_damage_result(
		base_damage_amount,
		_get_total_spell_damage_bonus_percent(),
		spell_crit_chance,
		spell_crit_multiplier
	)


func _get_damage_amount(damage_result: Dictionary) -> int:
	return maxi(int(damage_result.get("damage", 0)), 0)


func _build_damage_hit_context(damage_result: Dictionary) -> Dictionary:
	return {"is_critical": bool(damage_result.get("is_critical", false))}


func _merge_damage_hit_context(base_context: Dictionary, damage_result: Dictionary) -> Dictionary:
	var merged_context: Dictionary = base_context.duplicate(true)
	merged_context["is_critical"] = bool(damage_result.get("is_critical", false))
	return merged_context


func _update_poison_effects(delta: float) -> void:
	if _poison_targets.is_empty():
		return
	var safe_tick_interval: float = maxf(poison_tick_interval, 0.05)
	var remove_ids: Array[int] = []
	for id_variant in _poison_targets.keys():
		var target_id: int = int(id_variant)
		var entry_value: Variant = _poison_targets[target_id]
		if not (entry_value is Dictionary):
			remove_ids.append(target_id)
			continue
		var entry: Dictionary = entry_value
		var enemy: Node3D = null
		if entry.has("node"):
			enemy = entry["node"] as Node3D
		if enemy == null or not is_instance_valid(enemy) or _is_enemy_dead(enemy):
			remove_ids.append(target_id)
			continue

		var time_left: float = float(entry.get("time_left", 0.0))
		var tick_left: float = float(entry.get("tick_left", safe_tick_interval))
		time_left -= delta
		tick_left -= delta

		while tick_left <= 0.0 and time_left > 0.0:
			_apply_poison_tick_damage(enemy)
			tick_left += safe_tick_interval
			if enemy == null or not is_instance_valid(enemy) or _is_enemy_dead(enemy):
				break

		if (
			enemy == null
			or not is_instance_valid(enemy)
			or _is_enemy_dead(enemy)
			or time_left <= 0.0
		):
			remove_ids.append(target_id)
			continue

		entry["node"] = enemy
		entry["time_left"] = time_left
		entry["tick_left"] = tick_left
		_poison_targets[target_id] = entry

	for target_id in remove_ids:
		_poison_targets.erase(target_id)


func _add_attack_count(value: int = 1) -> void:
	if value <= 0:
		return
	if _is_transformed:
		return
	_attack_count += value
	_update_attack_count_label()
	_check_passive_transform()


func _resume_enemy_target_after_skill() -> void:
	if _hero == null:
		return
	if (
		_target_enemy == null
		or not is_instance_valid(_target_enemy)
		or _is_enemy_dead(_target_enemy)
	):
		return

	var distance: float = _distance_xz(_hero.global_position, _target_enemy.global_position)
	_has_move_target = false
	if distance <= attack_range:
		_is_moving = false
		_face_toward(_target_enemy.global_position)
		if _attack_cooldown <= 0.0:
			_start_attack()
		else:
			_play_idle_animation()
	else:
		_is_moving = true
		_nav_agent.target_position = _target_enemy.global_position
		_play_walk_animation()
		_push_network_control_command(
			"chase_target",
			{
				"target_path": str(_target_enemy.get_path()),
				"target_pos": _target_enemy.global_position
			}
		)


func _check_passive_transform() -> void:
	if not _uses_transform_passive():
		return
	if _is_transformed:
		return
	var required_count: int = passive_transform_attack_count
	if _is_warden_hero():
		required_count = WARDEN_VENGEANCE_TRIGGER_COUNT
	if _attack_count < required_count:
		return
	_transform_model()


func _transform_model() -> void:
	if transformed_model_scene == null:
		return
	if _hero == null:
		return

	var base_hero: Node3D = _hero
	var parent_node: Node = base_hero.get_parent()
	if parent_node == null:
		return

	var transformed_hero: Node3D = transformed_model_scene.instantiate() as Node3D
	if transformed_hero == null:
		return

	var base_transform: Transform3D = base_hero.global_transform
	var base_scale: Vector3 = base_hero.scale
	var base_rotation: Vector3 = base_hero.rotation

	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()
	_is_attacking = false
	_invalidate_pending_attack_damage()
	_current_attack_index = 0

	parent_node.add_child(transformed_hero)
	transformed_hero.global_transform = base_transform
	transformed_hero.scale = base_scale
	transformed_hero.rotation = base_rotation
	var fixed_rotation: Vector3 = transformed_hero.rotation
	fixed_rotation.z = 0.0
	transformed_hero.rotation = fixed_rotation

	if _nav_agent != null and _nav_agent.get_parent() != null:
		_nav_agent.reparent(transformed_hero)
	if _hp_bar != null and _hp_bar.get_parent() != null:
		_hp_bar.reparent(transformed_hero)
	if _attack_count_label != null and _attack_count_label.get_parent() != null:
		_attack_count_label.reparent(transformed_hero)
	var base_collision_body := base_hero.get_node_or_null("CollisionBody") as Node3D
	if base_collision_body != null and base_collision_body.get_parent() != null:
		base_collision_body.reparent(transformed_hero)
	if base_hero.is_in_group("hero"):
		base_hero.remove_from_group("hero")
	transformed_hero.add_to_group("hero")

	base_hero.visible = false
	_original_hero = base_hero
	_transformed_hero = transformed_hero
	_hero = transformed_hero
	_is_transformed = true
	_transform_time_left = transform_duration + _talent_float("transform_duration_bonus_sec", 0.0)
	apply_collision_profile("", _hero)
	_refresh_hp_bar_anchor_height_and_positions()
	_animation_player = _hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_refresh_motion_animation_aliases()
	var transform_heal: int = _talent_int("transform_enter_heal_flat", 0)
	if transform_heal > 0:
		transform_heal += int(
			round(
				(
					float(maxi(max_hp - _current_hp, 0))
					* _talent_float("transform_enter_missing_hp_heal_ratio", 0.0)
				)
			)
		)
		_heal_self(transform_heal)
	_attack_count = 0
	_update_attack_count_label()
	_refresh_attack_animations()
	_play_idle_animation()
	_notify_network_local_hero_ready()


func _revert_transform_model() -> void:
	if not _is_transformed:
		return
	if _original_hero == null or not is_instance_valid(_original_hero):
		return

	var was_attacking: bool = _is_attacking
	var current_hero: Node3D = _hero
	var current_transform: Transform3D = _original_hero.global_transform
	var current_scale: Vector3 = _original_hero.scale
	var current_rotation: Vector3 = _original_hero.rotation
	if current_hero != null and is_instance_valid(current_hero):
		current_transform = current_hero.global_transform
		current_scale = current_hero.scale
		current_rotation = current_hero.rotation

	if _nav_agent != null and _nav_agent.get_parent() != null:
		_nav_agent.reparent(_original_hero)
	if _hp_bar != null and _hp_bar.get_parent() != null:
		_hp_bar.reparent(_original_hero)
	if _attack_count_label != null and _attack_count_label.get_parent() != null:
		_attack_count_label.reparent(_original_hero)
	if current_hero != null and is_instance_valid(current_hero):
		var transformed_collision_body := current_hero.get_node_or_null("CollisionBody") as Node3D
		if transformed_collision_body != null and transformed_collision_body.get_parent() != null:
			transformed_collision_body.reparent(_original_hero)

	_original_hero.visible = true
	_original_hero.add_to_group("hero")
	_original_hero.global_transform = current_transform
	_original_hero.scale = current_scale
	_original_hero.rotation = current_rotation
	var fixed_rotation: Vector3 = _original_hero.rotation
	fixed_rotation.z = 0.0
	_original_hero.rotation = fixed_rotation

	if current_hero != null and is_instance_valid(current_hero):
		if current_hero.is_in_group("hero"):
			current_hero.remove_from_group("hero")
		current_hero.queue_free()

	_transformed_hero = null
	_hero = _original_hero
	_is_transformed = false
	_transform_time_left = 0.0
	apply_collision_profile("", _hero)
	_refresh_hp_bar_anchor_height_and_positions()
	_animation_player = _hero.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_refresh_motion_animation_aliases()
	_update_attack_count_label()
	_refresh_attack_animations()
	_notify_network_local_hero_ready()
	_resume_after_transform_cancel(was_attacking)


func _resume_after_transform_cancel(was_attacking: bool) -> void:
	_is_attacking = false
	_invalidate_pending_attack_damage()
	_current_attack_index = 0
	_is_moving = false

	var has_enemy_target: bool = false
	if (
		_target_enemy != null
		and is_instance_valid(_target_enemy)
		and not _is_enemy_dead(_target_enemy)
	):
		has_enemy_target = true

	if has_enemy_target:
		var enemy_pos: Vector3 = _target_enemy.global_position
		var distance: float = _distance_xz(_hero.global_position, enemy_pos)
		if distance <= attack_range:
			if was_attacking:
				_attack_cooldown = 0.0
			if _attack_cooldown <= 0.0:
				_start_attack()
			else:
				_face_toward(enemy_pos)
				_play_idle_animation()
		else:
			_nav_agent.target_position = enemy_pos
			_is_moving = true
			_play_walk_animation()
		return

	if _has_move_target:
		_nav_agent.target_position = _target_position
		_is_moving = true
		_play_walk_animation()
		return

	_play_idle_animation()


func _spawn_flash_effect(pos: Vector3) -> void:
	if flash_effect_scene == null:
		return
	var effect := flash_effect_scene.instantiate() as Node3D
	if effect == null:
		return
	var host: Node = get_parent()
	if host == null:
		return
	host.add_child(effect)
	effect.global_position = pos
	effect.scale = Vector3(2, 2, 2)
	var anim_player := effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player != null:
		var anim_list := anim_player.get_animation_list()
		if anim_list.size() > 0:
			var anim_name := anim_list[0]
			var anim := anim_player.get_animation(anim_name)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
			anim_player.play(anim_name)
			var duration := 2.0
			if anim != null:
				duration = maxf(anim.length, 0.1)
			get_tree().create_timer(duration).timeout.connect(effect.queue_free)
		else:
			get_tree().create_timer(2.0).timeout.connect(effect.queue_free)
	else:
		get_tree().create_timer(2.0).timeout.connect(effect.queue_free)


func _spawn_ranged_q_ray(ray_start: Vector3, ray_end: Vector3) -> void:
	var delta := ray_end - ray_start
	if delta.length() <= 0.01:
		return
	var safe_dir := delta.normalized()

	var safe_length: float = maxf(delta.length(), 1.0)
	var safe_width: float = maxf(ranged_q_ray_width, 0.5)
	var safe_thickness: float = maxf(ranged_q_ray_thickness, 0.5)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(safe_length, safe_thickness, safe_width)
	var beam := MeshInstance3D.new()
	beam.mesh = mesh
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.1, 0.1, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.15, 0.15, 1.0)
	mat.emission_energy_multiplier = 2.0
	beam.material_override = mat

	var center := (ray_start + ray_end) * 0.5
	var up_axis := Vector3.UP
	if absf(safe_dir.dot(up_axis)) > 0.99:
		up_axis = Vector3.FORWARD
	var z_axis := safe_dir.cross(up_axis).normalized()
	var y_axis := z_axis.cross(safe_dir).normalized()
	beam.global_transform = Transform3D(Basis(safe_dir, y_axis, z_axis), center)

	var host: Node = get_parent()
	if host == null:
		return
	host.add_child(beam)
	get_tree().create_timer(maxf(ranged_q_ray_lifetime, 0.03)).timeout.connect(beam.queue_free)


func _spawn_move_confirmation_effect(pos: Vector3) -> void:
	if move_confirmation_scene == null:
		return

	var effect := move_confirmation_scene.instantiate() as Node3D
	if effect == null:
		return

	var host: Node = get_parent()
	if host == null:
		return
	host.add_child(effect)
	effect.global_position = Vector3(pos.x, _plane_height, pos.z)
	effect.scale = move_confirmation_scale

	var duration := maxf(move_confirmation_lifetime, 0.1)
	var anim_player := effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player != null:
		var anim_name: StringName = &""
		if anim_player.autoplay != "":
			anim_name = StringName(anim_player.autoplay)
		elif anim_player.is_playing():
			anim_name = anim_player.current_animation
		else:
			var anim_list := anim_player.get_animation_list()
			if anim_list.size() > 0:
				anim_name = anim_list[0]

		if anim_name != &"" and anim_player.has_animation(anim_name):
			var anim := anim_player.get_animation(anim_name)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
				duration = maxf(anim.length * 0.5, 0.1)
			if not anim_player.is_playing():
				anim_player.play(anim_name)

	get_tree().create_timer(duration).timeout.connect(effect.queue_free)


func _handle_attack_click() -> void:
	if _is_network_attack_locked():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	var space_state := get_world_3d().direct_space_state
	var query := _create_interaction_ray_query(ray_origin, ray_origin + ray_dir * 10000)
	var result := space_state.intersect_ray(query)

	var selected_enemy: Node3D = null
	if result and result.collider:
		var collider_node := result.collider as Node
		if collider_node != null:
			selected_enemy = _resolve_enemy_from_collider(collider_node)

	if selected_enemy == null:
		var nearest_enemy: Node3D = _find_nearest_enemy()
		if nearest_enemy != null:
			var nearest_distance: float = _distance_xz(
				_hero.global_position, nearest_enemy.global_position
			)
			if nearest_distance <= attack_range:
				selected_enemy = nearest_enemy
			elif nearest_distance <= engage_range:
				selected_enemy = nearest_enemy

	if (
		selected_enemy != null
		and is_instance_valid(selected_enemy)
		and not _is_enemy_dead(selected_enemy)
	):
		_issue_attack_target_order(selected_enemy, true)
	else:
		# A 键攻击点击未命中且附近没有可索敌目标时，取消当前攻击目标。
		_target_enemy = null
		_target_enemy = null
		_has_move_target = false
		_focus_lock = false
		_interrupt_attack_for_chase()
		_push_network_control_command("idle")


func _issue_attack_target_order(target_enemy: Node3D, lock_focus: bool = true) -> void:
	if (
		_hero == null
		or target_enemy == null
		or not is_instance_valid(target_enemy)
		or _is_enemy_dead(target_enemy)
	):
		return

	_target_enemy = target_enemy
	_has_move_target = false
	_focus_lock = lock_focus
	_ranged_q_backstep_active = false
	_ranged_q_backstep_time_left = 0.0
	_ranged_q_backstep_total_time = 0.0

	if _is_attacking:
		_interrupt_attack_for_chase()

	var distance_to_enemy: float = _distance_xz(_hero.global_position, target_enemy.global_position)
	if distance_to_enemy <= attack_range:
		_is_moving = false
		_face_toward(target_enemy.global_position)
		if _attack_cooldown <= 0.0:
			_start_attack()
		else:
			_play_idle_animation()
			_push_network_control_command(
				"attack_target",
				{
					"target_path": str(target_enemy.get_path()),
					"target_pos": target_enemy.global_position
				}
			)
		return

	_nav_agent.target_position = target_enemy.global_position
	_is_moving = true
	_play_walk_animation()
	_push_network_control_command(
		"chase_target",
		{"target_path": str(target_enemy.get_path()), "target_pos": target_enemy.global_position}
	)


func _get_ground_position(mouse_pos: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return _hero.global_position

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	if absf(ray_dir.y) < 0.0001:
		return _hero.global_position

	var t := (_plane_height - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return _hero.global_position

	return ray_origin + ray_dir * t


func _move_directly_toward_target(target_pos: Vector3, delta: float) -> void:
	var current_pos: Vector3 = _hero.global_position
	var to_target: Vector3 = target_pos - current_pos
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance <= 20.0:
		_has_move_target = false
		_is_moving = false
		_stop_animation()
		_push_network_control_command("idle")
		return
	var step: float = minf(_get_current_move_speed() * maxf(delta, 0.0), distance)
	if step <= 0.0:
		return
	var next_pos: Vector3 = current_pos + to_target.normalized() * step
	next_pos.y = _plane_height
	_hero.global_position = next_pos
	_look_at_target(target_pos)
	if not _is_moving:
		_is_moving = true
		_play_walk_animation()
		_push_network_control_command("move_to", {"target_pos": _target_position})


func _apply_stop_movement_order() -> void:
	var had_motion_intent: bool = _has_move_target or _is_moving or _is_attacking
	if _target_enemy != null and is_instance_valid(_target_enemy):
		had_motion_intent = true
	_interrupt_attack_for_move()
	_has_move_target = false
	_target_enemy = null
	_focus_lock = false
	if _is_moving:
		_is_moving = false
		_stop_animation()
	if had_motion_intent:
		_push_network_control_command("idle")


func _process(delta: float) -> void:
	_update_mouse_cursor_icon()
	_sync_hp_bar_follow_and_facing()
	if _hero == null or _is_dead:
		_set_r_skill_ground_selector_visible(false)
		return
	_update_r_skill_ground_selector()
	if start_area_full_recovery_enabled:
		_refresh_start_area_recovery_zone()
	_refresh_local_battle_phase_notifications()
	if _attack_count_label == null or not is_instance_valid(_attack_count_label):
		_create_attack_count_label()
	if hero_level != _last_stat_level:
		_recalculate_war3_stats(false)

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _flash_cooldown > 0.0:
		_flash_cooldown -= delta
	if _e_cooldown > 0.0:
		_e_cooldown -= delta
	if _r_cooldown > 0.0:
		_r_cooldown -= delta
	if _haste_cooldown > 0.0:
		_haste_cooldown -= delta
	if _haste_active:
		_haste_time_left -= delta
		if _haste_time_left <= 0.0:
			_haste_active = false
			_haste_time_left = 0.0
			_warden_ring_attacks_left = 0
	_sync_walk_animation_speed_if_needed()
	if _slow_time_left > 0.0:
		_slow_time_left -= delta
		if _slow_time_left <= 0.0:
			_slow_time_left = 0.0
			_slow_percent = 0.0
	_update_equipment_effect_timers(delta)
	_update_enemy_damage_bonus_runtime(delta)
	_update_battle_banner_runtime(delta)
	_refresh_battle_prep_phase_state()
	_refresh_necromancy_battle_phase_state()
	_enforce_start_area_full_hp_mana()
	_apply_regeneration(delta)
	_update_poison_effects(delta)
	_refresh_runtime_combat_stats()
	_update_network_attack_lock_state()
	if _is_transformed:
		_transform_time_left = maxf(_transform_time_left - delta, 0.0)
		_update_attack_count_label()
		if _transform_time_left <= 0.0:
			_revert_transform_model()
	if _attack_count_label != null and _attack_count_label.visible:
		_attack_count_label.position = Vector3(
			0.0, _hp_bar_anchor_height + attack_count_label_height_offset, 0.0
		)
	if _ranged_q_backstep_active:
		_update_ranged_q_backstep(delta)
		return
	var stop_move_pressed: bool = _stop_move_hold_active or Input.is_key_pressed(KEY_S)
	if stop_move_pressed:
		_stop_move_hold_active = true
		_apply_stop_movement_order()
		return
	_stop_move_hold_active = false

	_update_auto_attack_target()

	if _is_attacking:
		if (
			_target_enemy == null
			or not is_instance_valid(_target_enemy)
			or _is_enemy_dead(_target_enemy)
		):
			_interrupt_attack_for_chase()
			_target_enemy = null
			_focus_lock = false
			return

		_face_toward(_target_enemy.global_position)

		var attack_distance := _distance_xz(_hero.global_position, _target_enemy.global_position)
		if attack_distance > attack_range:
			_interrupt_attack_for_chase()

		return

	var current := _hero.global_position

	if _has_move_target:
		var dist_to_target := _distance_xz(current, _target_position)
		if dist_to_target < 20.0:
			_has_move_target = false
			_is_moving = false
			_stop_animation()
			_push_network_control_command("idle")
		else:
			if _is_inside_start_area_recovery_zone():
				_move_directly_toward_target(_target_position, delta)
				return
			var move_target := _target_position
			_nav_agent.target_position = _target_position
			if not _nav_agent.is_navigation_finished():
				var next_nav := _nav_agent.get_next_path_position()
				if _distance_xz(next_nav, current) > 1.0:
					move_target = next_nav
			var next := _compute_next_move_with_obstacle_avoidance(
				current, move_target, _get_current_move_speed() * delta, delta
			)
			next.y = _plane_height
			_hero.global_position = next
			_look_at_target(move_target)

			if not _is_moving:
				_is_moving = true
				_play_walk_animation()
				_push_network_control_command("move_to", {"target_pos": _target_position})
	elif _target_enemy != null and is_instance_valid(_target_enemy):
		var enemy_pos := _target_enemy.global_position
		var distance := _distance_xz(current, enemy_pos)

		if distance > engage_range and not _focus_lock:
			_target_enemy = null
			_focus_lock = false
			if _is_moving:
				_is_moving = false
				_stop_animation()
				_push_network_control_command("idle")
			return

		if distance > attack_range:
			_nav_agent.target_position = enemy_pos
			var move_target := enemy_pos
			if not _nav_agent.is_navigation_finished():
				var next_nav := _nav_agent.get_next_path_position()
				if _distance_xz(next_nav, current) > 1.0:
					move_target = next_nav
			var next := _compute_next_move_with_obstacle_avoidance(
				current, move_target, _get_current_move_speed() * delta, delta
			)
			next.y = _plane_height
			_hero.global_position = next
			_look_at_target(move_target)

			if not _is_moving:
				_is_moving = true
				_play_walk_animation()
				if _target_enemy != null and is_instance_valid(_target_enemy):
					_push_network_control_command(
						"chase_target",
						{
							"target_path": str(_target_enemy.get_path()),
							"target_pos": _target_enemy.global_position
						}
					)
		else:
			if _is_moving:
				_is_moving = false
				_stop_animation()
				_push_network_control_command("idle")
			_face_toward(enemy_pos)
			if _attack_cooldown <= 0.0:
				_start_attack()
	else:
		if _is_moving:
			_is_moving = false
			_stop_animation()
			_push_network_control_command("idle")


func _update_mouse_cursor_icon() -> void:
	if _r_skill_mode:
		_apply_mouse_cursor(false, false, false, true)
		return
	_set_r_skill_ground_selector_visible(false)
	var is_aim_mode: bool = _attack_mode or _flash_mode
	if is_aim_mode:
		var over_enemy := _is_mouse_over_enemy()
		_apply_mouse_cursor(over_enemy, true, false)
		return
	if _destroy_cursor_mode:
		_apply_mouse_cursor(_destroy_hover_item, false, true)
		return
	var over_enemy := _is_mouse_over_enemy()
	_apply_mouse_cursor(over_enemy, false, false)


func _get_ranged_r_visual_scale_multiplier() -> float:
	return maxf(ranged_r_cursor_scale_multiplier, 0.1)


func _get_ranged_r_impact_scale_multiplier() -> float:
	return maxf(ranged_r_impact_scale_multiplier, 0.1)


func _set_r_skill_ground_selector_visible(visible: bool) -> void:
	if (
		_r_skill_ground_selector_root == null
		or not is_instance_valid(_r_skill_ground_selector_root)
	):
		return
	_r_skill_ground_selector_root.visible = visible


func _ensure_r_skill_ground_selector_node(host: Node) -> void:
	var host_3d := host as Node3D
	if host_3d == null:
		return
	if (
		_r_skill_ground_selector_root != null
		and not is_instance_valid(_r_skill_ground_selector_root)
	):
		_r_skill_ground_selector_root = null
		_r_skill_ground_selector_mesh = null
		_r_skill_ground_selector_material = null
		_r_skill_ground_selector_texture_source = null
	if _r_skill_ground_selector_root == null:
		var selector_root := Node3D.new()
		selector_root.name = "RSkillGroundSelector"
		selector_root.top_level = true
		selector_root.visible = false
		var selector_mesh := MeshInstance3D.new()
		selector_mesh.name = "GroundRing"
		selector_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var quad := QuadMesh.new()
		var initial_diameter: float = maxf(ranged_r_radius * 2.0, 1.0)
		quad.size = Vector2(initial_diameter, initial_diameter)
		selector_mesh.mesh = quad
		var selector_material := StandardMaterial3D.new()
		selector_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		selector_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		selector_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		selector_material.albedo_color = Color(
			1.0, 1.0, 1.0, clampf(ranged_r_ground_selector_alpha, 0.05, 1.0)
		)
		selector_mesh.material_override = selector_material
		selector_root.add_child(selector_mesh)
		host_3d.add_child(selector_root)
		_r_skill_ground_selector_root = selector_root
		_r_skill_ground_selector_mesh = selector_mesh
		_r_skill_ground_selector_material = selector_material
		_r_skill_ground_selector_texture_source = null
		return
	if _r_skill_ground_selector_root.get_parent() != host_3d:
		var old_parent: Node = _r_skill_ground_selector_root.get_parent()
		if old_parent != null:
			old_parent.remove_child(_r_skill_ground_selector_root)
		host_3d.add_child(_r_skill_ground_selector_root)


func _update_r_skill_ground_selector() -> void:
	if (
		not ranged_r_ground_selector_enabled
		or not _r_skill_mode
		or not skill_r_active
		or not _is_ranged_hero()
	):
		_set_r_skill_ground_selector_visible(false)
		return
	if cursor_r_skill_texture == null and not _r_skill_cursor_resource_checked:
		cursor_r_skill_texture = _load_texture_resource_or_file(R_SKILL_CURSOR_TEXTURE_PATH)
		_r_skill_cursor_resource_checked = true
	var host: Node = get_parent()
	if host == null:
		_set_r_skill_ground_selector_visible(false)
		return
	_ensure_r_skill_ground_selector_node(host)
	if (
		_r_skill_ground_selector_root == null
		or not is_instance_valid(_r_skill_ground_selector_root)
	):
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var center: Vector3 = _get_ground_position(mouse_pos)
	center.y = _plane_height + maxf(ranged_r_ground_selector_height_offset, 0.01)
	_r_skill_ground_selector_root.global_position = center
	_r_skill_ground_selector_root.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	_r_skill_ground_selector_root.visible = true
	if _r_skill_ground_selector_mesh != null and is_instance_valid(_r_skill_ground_selector_mesh):
		var quad := _r_skill_ground_selector_mesh.mesh as QuadMesh
		if quad == null:
			quad = QuadMesh.new()
			_r_skill_ground_selector_mesh.mesh = quad
		var diameter: float = maxf(ranged_r_radius * 2.0, 1.0)
		quad.size = Vector2(diameter, diameter)
	if (
		_r_skill_ground_selector_material != null
		and is_instance_valid(_r_skill_ground_selector_material)
	):
		_r_skill_ground_selector_material.albedo_color = Color(
			1.0, 1.0, 1.0, clampf(ranged_r_ground_selector_alpha, 0.05, 1.0)
		)
		var selector_texture: Texture2D = cursor_r_skill_texture
		if selector_texture != _r_skill_ground_selector_texture_source:
			_r_skill_ground_selector_material.albedo_texture = selector_texture
			_r_skill_ground_selector_texture_source = selector_texture


func _get_r_skill_cursor_visual_texture() -> Texture2D:
	if cursor_r_skill_texture == null:
		_r_skill_cursor_visual_texture = null
		_r_skill_cursor_visual_source = null
		_r_skill_cursor_visual_scale_cached = -1.0
		return null
	var target_scale: float = _get_ranged_r_visual_scale_multiplier()
	if (
		_r_skill_cursor_visual_texture != null
		and _r_skill_cursor_visual_source == cursor_r_skill_texture
		and is_equal_approx(_r_skill_cursor_visual_scale_cached, target_scale)
	):
		return _r_skill_cursor_visual_texture
	_r_skill_cursor_visual_source = cursor_r_skill_texture
	_r_skill_cursor_visual_scale_cached = target_scale
	var image: Image = cursor_r_skill_texture.get_image()
	if image == null:
		_r_skill_cursor_visual_texture = cursor_r_skill_texture
		return _r_skill_cursor_visual_texture
	var source_width: int = maxi(image.get_width(), 1)
	var source_height: int = maxi(image.get_height(), 1)
	var target_width: int = maxi(roundi(float(source_width) * target_scale), 1)
	var target_height: int = maxi(roundi(float(source_height) * target_scale), 1)
	if target_width > MAX_CURSOR_TEXTURE_SIZE or target_height > MAX_CURSOR_TEXTURE_SIZE:
		var clamp_ratio: float = minf(
			float(MAX_CURSOR_TEXTURE_SIZE) / float(maxi(target_width, 1)),
			float(MAX_CURSOR_TEXTURE_SIZE) / float(maxi(target_height, 1))
		)
		target_width = maxi(roundi(float(target_width) * clamp_ratio), 1)
		target_height = maxi(roundi(float(target_height) * clamp_ratio), 1)
	if target_width == source_width and target_height == source_height:
		_r_skill_cursor_visual_texture = cursor_r_skill_texture
		return _r_skill_cursor_visual_texture
	image.resize(target_width, target_height)
	_r_skill_cursor_visual_texture = ImageTexture.create_from_image(image)
	return _r_skill_cursor_visual_texture


func _is_mouse_over_enemy() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var query := _create_interaction_ray_query(ray_origin, ray_origin + ray_dir * 10000.0)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() or not result.has("collider"):
		return false
	var collider := result["collider"] as Node
	if collider == null:
		return false
	var enemy := _resolve_enemy_from_collider(collider)
	return enemy != null and not _is_enemy_dead(enemy)


func _apply_mouse_cursor(
	use_enemy_cursor: bool,
	attack_mode_cursor: bool,
	selected_cursor_mode: bool,
	r_skill_cursor_mode: bool = false
) -> void:
	if (
		_cursor_initialized
		and use_enemy_cursor == _using_enemy_cursor
		and attack_mode_cursor == _using_attack_cursor
		and selected_cursor_mode == _using_selected_cursor
		and r_skill_cursor_mode == _using_r_skill_cursor
	):
		return
	_cursor_initialized = true
	_using_enemy_cursor = use_enemy_cursor
	_using_attack_cursor = attack_mode_cursor
	_using_selected_cursor = selected_cursor_mode
	_using_r_skill_cursor = r_skill_cursor_mode
	var target_cursor: Texture2D
	var applied_hotspot: Vector2 = cursor_hotspot
	if r_skill_cursor_mode:
		if ranged_r_ground_selector_enabled:
			target_cursor = null
		else:
			if cursor_r_skill_texture == null and not _r_skill_cursor_resource_checked:
				cursor_r_skill_texture = _load_texture_resource_or_file(R_SKILL_CURSOR_TEXTURE_PATH)
				_r_skill_cursor_resource_checked = true
			var visual_cursor: Texture2D = _get_r_skill_cursor_visual_texture()
			target_cursor = (
				visual_cursor if visual_cursor != null else cursor_attack_default_texture
			)
			if visual_cursor != null:
				applied_hotspot = visual_cursor.get_size() * 0.5
	elif selected_cursor_mode:
		target_cursor = (
			cursor_attack_enemy_texture if use_enemy_cursor else cursor_attack_default_texture
		)
	elif attack_mode_cursor:
		target_cursor = (
			cursor_attack_enemy_texture if use_enemy_cursor else cursor_attack_default_texture
		)
	else:
		target_cursor = cursor_enemy_texture if use_enemy_cursor else cursor_default_texture
	if target_cursor != null:
		var cursor_size: Vector2 = target_cursor.get_size()
		if (
			cursor_size.x > float(MAX_CURSOR_TEXTURE_SIZE)
			or cursor_size.y > float(MAX_CURSOR_TEXTURE_SIZE)
		):
			target_cursor = cursor_attack_default_texture
			applied_hotspot = cursor_hotspot
		Input.set_custom_mouse_cursor(target_cursor, Input.CURSOR_ARROW, applied_hotspot)
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


func _look_at_target(target_pos: Vector3) -> void:
	var direction = target_pos - _hero.global_position
	direction.y = 0
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		_hero.rotation.y = target_rotation - PI / 2.0


func _face_toward(target_pos: Vector3) -> void:
	var direction = target_pos - _hero.global_position
	direction.y = 0
	if direction.length() > 0.01:
		_hero.rotation.y = atan2(direction.x, direction.z) - PI / 2.0


func _start_attack() -> void:
	if _is_network_attack_locked():
		return
	if _animation_player == null:
		return
	_refresh_attack_animations()
	if _attack_animations.is_empty():
		_is_attacking = false
		_invalidate_pending_attack_damage()
		return

	_is_attacking = true
	_has_move_target = false
	_current_attack_index = 0
	if _target_enemy != null and is_instance_valid(_target_enemy):
		_push_network_control_command(
			"attack_target",
			{
				"target_path": str(_target_enemy.get_path()),
				"target_pos": _target_enemy.global_position
			}
		)

	if not _animation_player.animation_finished.is_connected(_on_attack_finished):
		_animation_player.animation_finished.connect(_on_attack_finished)

	_play_current_attack_animation()


func _get_walk_animation_speed_scale() -> float:
	if _haste_active and skill_w_id == SKILL_ID_W_RANGED_SPEED:
		return maxf(ranged_haste_walk_anim_speed_multiplier, 0.1)
	return 1.0


func _sync_walk_animation_speed_if_needed() -> void:
	if _animation_player == null:
		return
	if _resolved_walk_animation == "":
		_animation_player.speed_scale = 1.0
		return
	if not _animation_player.is_playing():
		_animation_player.speed_scale = 1.0
		return
	if String(_animation_player.current_animation) != _resolved_walk_animation:
		_animation_player.speed_scale = 1.0
		return
	_animation_player.speed_scale = _get_walk_animation_speed_scale()


func _play_walk_animation() -> void:
	if _animation_player == null:
		return
	if _resolved_walk_animation == "":
		_refresh_motion_animation_aliases()
	if _resolved_walk_animation == "":
		return
	var walk_speed_scale: float = _get_walk_animation_speed_scale()
	if (
		_animation_player.is_playing()
		and String(_animation_player.current_animation) == _resolved_walk_animation
	):
		_animation_player.speed_scale = walk_speed_scale
		return
	_animation_player.speed_scale = walk_speed_scale
	_animation_player.play(_resolved_walk_animation, -1, 1.0, false)
	var anim = _animation_player.get_animation(_resolved_walk_animation)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR


func _play_current_attack_animation() -> void:
	if _animation_player == null:
		return

	if _current_attack_index >= _attack_animations.size():
		_is_attacking = false
		_invalidate_pending_attack_damage()
		return

	var anim_name = _attack_animations[_current_attack_index]

	if not _animation_player.has_animation(anim_name):
		push_warning("未找到攻击动画: " + anim_name)
		_current_attack_index += 1
		if _current_attack_index < _attack_animations.size():
			_play_current_attack_animation()
		else:
			_is_attacking = false
			_invalidate_pending_attack_damage()
		return

	var anim = _animation_player.get_animation(anim_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE

	_animation_player.play(anim_name, -1.0, _get_attack_speed_scale(), false)
	_schedule_attack_damage_for_current_animation(anim)


func _on_attack_finished(_anim_name: StringName) -> void:
	if _is_attacking:
		_current_attack_index += 1

		if _current_attack_index < _attack_animations.size():
			_play_current_attack_animation()
		else:
			_is_attacking = false
			_invalidate_pending_attack_damage()
			_attack_cooldown = _get_attack_interval()
			if _target_enemy != null and is_instance_valid(_target_enemy):
				if _is_enemy_dead(_target_enemy):
					_acquire_next_enemy_target_after_kill()
					return
				var distance := _distance_xz(_hero.global_position, _target_enemy.global_position)
				if distance <= attack_range and _attack_cooldown <= 0.0:
					_start_attack()


func _stop_animation() -> void:
	if _animation_player == null:
		return
	_animation_player.stop()
	_play_idle_animation()


func _distance_xz(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()


func _is_obstacle_collider(collider: Node) -> bool:
	return CombatSceneUtils.is_obstacle_collider(collider)


func _is_move_segment_blocked(
	from_pos: Vector3, to_pos: Vector3, probe_half_width: float, probe_height: float
) -> bool:
	return CombatSceneUtils.is_move_segment_blocked(
		get_world_3d(), from_pos, to_pos, probe_half_width, probe_height, OBSTACLE_RAY_MASK
	)


func _compute_next_move_with_obstacle_avoidance(
	current: Vector3, move_target: Vector3, max_step: float, delta: float = 0.0
) -> Vector3:
	var to_target: Vector3 = move_target - current
	to_target.y = 0.0
	if to_target.length() <= 0.01 or max_step <= 0.0:
		return current

	var step: float = minf(max_step, to_target.length())
	var forward_dir: Vector3 = to_target.normalized()
	var steer_dir: Vector3 = forward_dir
	if dynamic_detour_enabled and delta > 0.0 and _dynamic_detour_time_left > 0.0:
		var side_vec: Vector3 = forward_dir.cross(Vector3.UP)
		if side_vec.length() > 0.001:
			side_vec = side_vec.normalized()
			steer_dir = (
				(
					forward_dir
					+ side_vec * _dynamic_detour_side * maxf(dynamic_detour_side_strength, 0.0)
				)
				. normalized()
			)
		_dynamic_detour_time_left = maxf(_dynamic_detour_time_left - delta, 0.0)
	var direct_next: Vector3 = current + steer_dir * step
	var dynamic_blocked: bool = _is_dynamic_unit_blocking_segment(
		current, direct_next, maxf(dynamic_blocker_avoid_radius, 32.0)
	)
	if not _is_move_segment_blocked(current, direct_next, 42.0, 38.0) and not dynamic_blocked:
		return direct_next
	if dynamic_detour_enabled and delta > 0.0 and _dynamic_detour_time_left <= 0.0:
		_dynamic_detour_time_left = maxf(dynamic_detour_duration_sec, 0.08)
		_dynamic_detour_side = -_dynamic_detour_side

	var best_next: Vector3 = current
	var best_score: float = -INF
	for angle_deg in OBSTACLE_STEER_ANGLES:
		var candidate_dir: Vector3 = forward_dir.rotated(Vector3.UP, deg_to_rad(angle_deg))
		var candidate_next: Vector3 = current + candidate_dir * step
		var blocked_static: bool = _is_move_segment_blocked(current, candidate_next, 42.0, 38.0)
		var blocked_dynamic: bool = _is_dynamic_unit_blocking_segment(
			current, candidate_next, maxf(dynamic_blocker_avoid_radius, 32.0)
		)
		if blocked_static or blocked_dynamic:
			continue
		var remain: Vector3 = move_target - candidate_next
		remain.y = 0.0
		var score: float = -remain.length()
		var angle_sign: float = sign(float(angle_deg))
		if dynamic_detour_enabled and angle_sign != 0.0 and angle_sign == _dynamic_detour_side:
			score += 3.5
		if score > best_score:
			best_score = score
			best_next = candidate_next
	return best_next


func _is_dynamic_unit_blocking_segment(
	from_pos: Vector3, to_pos: Vector3, probe_radius: float
) -> bool:
	if _hero == null:
		return false
	var seg: Vector3 = to_pos - from_pos
	seg.y = 0.0
	var seg_len: float = seg.length()
	if seg_len <= 0.01:
		return false
	var seg_dir: Vector3 = seg / seg_len
	var safe_radius: float = maxf(probe_radius, 8.0)

	var groups: Array[StringName] = [enemy_group_name, StringName("hero")]
	for group_name in groups:
		var candidates: Array = get_tree().get_nodes_in_group(group_name)
		for candidate_variant in candidates:
			var candidate_node: Node = candidate_variant as Node
			var blocker: Node3D = candidate_node as Node3D
			if blocker == null:
				continue
			if blocker == _hero:
				continue
			if not is_instance_valid(blocker):
				continue
			if not blocker.visible:
				continue
			var blocker_pos: Vector3 = blocker.global_position
			var rel: Vector3 = blocker_pos - from_pos
			rel.y = 0.0
			var proj: float = rel.dot(seg_dir)
			if proj < 0.0 or proj > seg_len:
				continue
			var nearest: Vector3 = from_pos + seg_dir * proj
			var lateral_dist: float = _distance_xz(blocker_pos, nearest)
			if lateral_dist <= safe_radius:
				return true
	return false


func _update_auto_attack_target() -> void:
	if not auto_attack_on_enemy_engage:
		return
	if _is_network_attack_locked():
		return

	if _focus_lock:
		if (
			_target_enemy != null
			and is_instance_valid(_target_enemy)
			and not _is_enemy_dead(_target_enemy)
		):
			return
		_focus_lock = false

	# 玩家下达了移动指令时，不自动切回攻击目标
	if _has_move_target:
		return

	var enemy := _find_nearest_enemy()
	if enemy == null:
		_was_in_enemy_engage_range = false
		_last_auto_enemy = null
		_auto_aggro_initialized = true
		return

	var distance := _distance_xz(_hero.global_position, enemy.global_position)
	var enemy_engage_range := _get_enemy_engage_range(enemy)
	var in_enemy_engage_range := distance <= enemy_engage_range

	# 首帧只记录状态，避免开局就在范围内时自动开打
	if not _auto_aggro_initialized:
		_auto_aggro_initialized = true
		_was_in_enemy_engage_range = in_enemy_engage_range
		_last_auto_enemy = enemy
		return

	if in_enemy_engage_range and (not _was_in_enemy_engage_range or _last_auto_enemy != enemy):
		_target_enemy = enemy
		_has_move_target = false
		_push_network_control_command(
			"chase_target",
			{"target_path": str(enemy.get_path()), "target_pos": enemy.global_position}
		)

	_was_in_enemy_engage_range = in_enemy_engage_range
	_last_auto_enemy = enemy


func _interrupt_attack_for_move() -> void:
	if not _is_attacking:
		return

	_is_attacking = false
	_invalidate_pending_attack_damage()
	_current_attack_index = 0
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()


func _interrupt_attack_for_chase() -> void:
	if not _is_attacking:
		return

	_is_attacking = false
	_invalidate_pending_attack_damage()
	_current_attack_index = 0
	if _animation_player != null and _animation_player.is_playing():
		_animation_player.stop()


func _get_basic_attack_damage_timing_ratio() -> float:
	if _is_ranged_hero():
		return clampf(ranged_attack_damage_timing_ratio, 0.0, 1.0)
	return clampf(melee_attack_damage_timing_ratio, 0.0, 1.0)


func _schedule_attack_damage_for_current_animation(anim: Animation) -> void:
	_attack_damage_schedule_id += 1
	var schedule_id: int = _attack_damage_schedule_id
	var expected_attack_index: int = _current_attack_index
	var timing_ratio: float = _get_basic_attack_damage_timing_ratio()
	var playback_length: float = 0.0
	if anim != null:
		var speed_scale: float = maxf(_get_attack_speed_scale(), 0.05)
		playback_length = maxf(anim.length, 0.0) / speed_scale
	var delay_sec: float = playback_length * timing_ratio
	if delay_sec <= 0.001:
		_try_apply_damage_to_enemy_if_timing_matches(schedule_id, expected_attack_index)
		return
	var timer: SceneTreeTimer = get_tree().create_timer(delay_sec)
	timer.timeout.connect(
		func() -> void:
			_try_apply_damage_to_enemy_if_timing_matches(schedule_id, expected_attack_index)
	)


func _try_apply_damage_to_enemy_if_timing_matches(
	schedule_id: int, expected_attack_index: int
) -> void:
	if schedule_id != _attack_damage_schedule_id:
		return
	if not _is_attacking:
		return
	if expected_attack_index != _current_attack_index:
		return
	_try_apply_damage_to_enemy()


func _invalidate_pending_attack_damage() -> void:
	_attack_damage_schedule_id += 1


func _try_apply_damage_to_enemy() -> void:
	if _target_enemy == null or not is_instance_valid(_target_enemy):
		return

	if _is_enemy_dead(_target_enemy):
		_acquire_next_enemy_target_after_kill()
		return

	if not _is_ranged_hero():
		var distance := _distance_xz(_hero.global_position, _target_enemy.global_position)
		if distance > attack_range:
			return

	var enemy_controller := _target_enemy.get_parent()
	if enemy_controller != null and enemy_controller.has_method("apply_damage"):
		var damage_result: Dictionary = _compute_physical_damage_result(damage_per_hit)
		var final_damage: int = _get_damage_amount(damage_result)
		if _submit_enemy_damage_with_confirmation(
			enemy_controller,
			_target_enemy,
			final_damage,
			attack_range + 30.0,
			"basic_attack",
			_build_damage_hit_context(damage_result),
			{"kind": "basic_attack", "attack_count": 1}
		):
			_register_necromancy_basic_attack_charge_gain()
			_register_spark_on_hit_bonuses()
			_apply_spark_permanent_on_hit_progress()
			_apply_spark_attack_effect_damage(_target_enemy)
			_apply_charge_permanent_on_hit_progress()
			_apply_charge_attack_effect_damage(_target_enemy)
			var precision_triggered: bool = _consume_rifleman_precision_trigger()
			if precision_triggered:
				_apply_rifleman_precision_bonus(enemy_controller, _target_enemy)
			_add_attack_count(1)
			var w_cdr_refund_sec: float = _talent_float(
				"warden_w_cooldown_refund_on_attack_sec", 0.0
			)
			if w_cdr_refund_sec > 0.0 and _haste_cooldown > 0.0:
				_haste_cooldown = maxf(_haste_cooldown - w_cdr_refund_sec, 0.0)
			var mana_gain_on_attack: int = _talent_int("warden_e_mana_gain_on_attack", 0)
			if mana_gain_on_attack > 0:
				current_mana = mini(current_mana + mana_gain_on_attack, max_mana)
			var armor_shred_percent: float = _talent_float("warden_armor_shred_on_hit_percent", 0.0)
			if armor_shred_percent > 0.0:
				_apply_enemy_damage_bonus(
					_target_enemy,
					armor_shred_percent,
					_talent_float("warden_armor_shred_duration_sec", 5.0)
				)
			if _should_apply_warden_poison_on_basic_attack():
				_apply_poison_to_enemy(_target_enemy)
			if _is_warden_hero() and _haste_active:
				_apply_warden_vengeance_heal_on_attack()
				_consume_warden_ring_attack()
			if _is_enemy_dead(_target_enemy):
				_acquire_next_enemy_target_after_kill()


func _acquire_next_enemy_target_after_kill() -> void:
	var next_enemy := _find_nearest_enemy_in_engage_range()
	_target_enemy = next_enemy
	_focus_lock = false
	if next_enemy != null:
		_has_move_target = false
		_was_in_enemy_engage_range = true
		_last_auto_enemy = next_enemy


func _find_nearest_enemy_in_engage_range() -> Node3D:
	if _hero == null:
		return null
	var nearest: Node3D = null
	var nearest_distance := INF
	var candidates := get_tree().get_nodes_in_group(enemy_group_name)
	for candidate in candidates:
		var collider := candidate as Node3D
		if collider == null:
			continue
		var enemy := collider.get_parent() as Node3D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if _is_enemy_dead(enemy):
			continue
		var distance := _distance_xz(_hero.global_position, enemy.global_position)
		if distance > engage_range:
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func apply_damage(
	amount: int,
	ignore_armor: bool = false,
	attacker: Node3D = null,
	damage_type: String = "physical"
) -> void:
	if _is_dead:
		return
	if _is_transformed and amount > 0:
		return

	var incoming: int = maxi(amount, 0)
	var final_damage: int = incoming
	if final_damage > 0:
		if _is_magic_damage_type(damage_type):
			final_damage = maxi(int(round(float(incoming) * _get_magic_damage_multiplier())), 0)
		elif not ignore_armor:
			final_damage = int(round(float(incoming) * _get_armor_damage_multiplier()))
			final_damage = maxi(final_damage, 1)
	if final_damage > 0 and _current_hp - final_damage <= 0:
		if _battle_prep_fatal_guard_charges > 0:
			_battle_prep_fatal_guard_charges = maxi(_battle_prep_fatal_guard_charges - 1, 0)
			_current_hp = 1
			_update_hp_bar()
			_retarget_to_attacker(attacker)
			return
		if _battle_prep_revive_charges > 0:
			_battle_prep_revive_charges = maxi(_battle_prep_revive_charges - 1, 0)
			_current_hp = maxi(int(round(float(max_hp) * 0.5)), 1)
			_update_hp_bar()
			_retarget_to_attacker(attacker)
			return
		if _consume_coin_revive_charge():
			_current_hp = maxi(int(round(float(max_hp) * 0.5)), 1)
			_update_hp_bar()
			_retarget_to_attacker(attacker)
			return
	_current_hp = maxi(_current_hp - final_damage, 0)
	_update_hp_bar()
	if final_damage > 0 and _current_hp > 0:
		_retarget_to_attacker(attacker)

	if _current_hp <= 0:
		_die()


func _retarget_to_attacker(attacker: Node3D) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	# 移动指令优先级高于受击反击：存在移动目标时不抢夺控制权。
	if _has_move_target:
		return
	var target_enemy: Node3D = attacker
	if target_enemy.is_in_group(enemy_group_name):
		target_enemy = target_enemy.get_parent() as Node3D
	if target_enemy == null or not is_instance_valid(target_enemy):
		return
	if _is_enemy_dead(target_enemy):
		return
	_target_enemy = target_enemy
	_focus_lock = true
	_has_move_target = false
	_ranged_q_backstep_active = false
	_ranged_q_backstep_time_left = 0.0
	_ranged_q_backstep_total_time = 0.0
	if _is_attacking:
		_interrupt_attack_for_chase()
	_face_toward(target_enemy.global_position)
	_push_network_control_command(
		"chase_target",
		{"target_path": str(target_enemy.get_path()), "target_pos": target_enemy.global_position}
	)


func is_dead() -> bool:
	return _is_dead


func prepare_for_next_floor() -> void:
	if _is_transformed:
		_revert_transform_model()
	_is_dead = false
	_death_finalized = false
	_is_attacking = false
	_has_move_target = false
	_is_moving = false
	_focus_lock = false
	_target_enemy = null
	_attack_mode = false
	_flash_mode = false
	_r_skill_mode = false
	_set_r_skill_ground_selector_visible(false)
	_flash_cooldown = 0.0
	_e_cooldown = 0.0
	_r_cooldown = 0.0
	_pending_damage_confirmations.clear()
	_clear_network_attack_lock()
	_haste_active = false
	_haste_time_left = 0.0
	_haste_cooldown = 0.0
	_poison_targets.clear()
	_slow_percent = 0.0
	_slow_time_left = 0.0
	_hp_regen_pool = 0.0
	_mana_regen_pool = 0.0
	_current_hp = max_hp
	current_mana = max_mana
	if _hero != null and is_instance_valid(_hero):
		_hero.visible = true
	if _hp_bar != null:
		_hp_bar.visible = true
	if _attack_count_label != null:
		_attack_count_label.visible = _should_show_attack_count_label()
	_stop_animation()
	_update_hp_bar()
	_notify_network_local_hero_ready()


func _die() -> void:
	if _is_dead:
		return

	_is_dead = true
	_necro_last_battle_phase_active = false
	_necro_charge_stacks = 0
	_battle_prep_last_phase_active = false
	_battle_prep_fatal_guard_charges = 0
	_local_battle_phase_active_notified = false
	_battle_banner_last_phase_active = false
	_battle_banner_elapsed_sec = 0.0
	_reset_battle_banner_emitted_bonuses()
	_battle_banner_applied_strength_bonus = 0
	_battle_banner_applied_agility_bonus = 0
	_battle_banner_applied_intelligence_bonus = 0
	_battle_banner_applied_damage_bonus = 0
	_battle_banner_applied_attack_speed_percent_bonus = 0.0
	_battle_banner_applied_spell_damage_percent_bonus = 0.0
	_pending_damage_confirmations.clear()
	_clear_network_attack_lock()
	_is_attacking = false
	_invalidate_pending_attack_damage()
	_is_moving = false
	_has_move_target = false
	_focus_lock = false
	_target_enemy = null
	_r_skill_mode = false
	_set_r_skill_ground_selector_visible(false)
	_ranged_q_backstep_active = false
	_ranged_q_backstep_time_left = 0.0
	_ranged_q_backstep_total_time = 0.0
	_poison_targets.clear()
	_spark_attack_speed_stack_time_lefts.clear()
	_spark_spell_damage_buff_time_left = 0.0
	_hp_regen_pool = 0.0
	_mana_regen_pool = 0.0
	_slow_percent = 0.0
	_slow_time_left = 0.0
	_push_network_control_command("dead")

	if _animation_player != null:
		_animation_player.stop()
		_animation_player.speed_scale = 1.0
		if _resolved_death_animation == "":
			_refresh_motion_animation_aliases()
		if (
			_resolved_death_animation != ""
			and _animation_player.has_animation(_resolved_death_animation)
		):
			var anim = _animation_player.get_animation(_resolved_death_animation)
			if anim != null:
				anim.loop_mode = Animation.LOOP_NONE
			_animation_player.play(_resolved_death_animation, -1.0, 1.5, false)
			var death_duration := 0.1
			if anim != null:
				death_duration = maxf(anim.length / 1.5, 0.1)
			_schedule_finalize_death(death_duration)
		else:
			_animation_player.stop()
			_finalize_death()
	else:
		_finalize_death()


func _create_hp_bar() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, shadows_disabled;\nuniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat bw = 0.04;\n\tfloat bh = 0.12;\n\tif (uv.x < bw || uv.x > 1.0 - bw || uv.y < bh || uv.y > 1.0 - bh) {\n\t\tALBEDO = vec3(0.0);\n\t\tALPHA = 0.9;\n\t} else {\n\t\tfloat ix = (uv.x - bw) / (1.0 - 2.0 * bw);\n\t\tif (ix <= hp_ratio) {\n\t\t\tALBEDO = vec3(1.0 - hp_ratio, hp_ratio, 0.0);\n\t\t\tALPHA = 0.9;\n\t\t} else {\n\t\t\tALBEDO = vec3(0.15);\n\t\t\tALPHA = 0.5;\n\t\t}\n\t}\n}\n"
	_hp_bar_material = ShaderMaterial.new()
	_hp_bar_material.shader = shader
	_hp_bar_material.set_shader_parameter("hp_ratio", 1.0)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(hp_bar_width, 25.5)
	_hp_bar = MeshInstance3D.new()
	_hp_bar.mesh = mesh
	_hp_bar.material_override = _hp_bar_material
	_hp_bar.top_level = true
	_hero.add_child(_hp_bar)
	_refresh_hp_bar_anchor_height_and_positions()
	call_deferred("_refresh_hp_bar_anchor_height_and_positions")
	_create_attack_count_label()


func _update_hp_bar() -> void:
	if _hp_bar_material == null:
		return
	_hp_bar_material.set_shader_parameter("hp_ratio", float(_current_hp) / float(max_hp))


func get_hp_bar_anchor_height() -> float:
	if _hp_bar_anchor_height <= 0.0:
		_refresh_hp_bar_anchor_height_and_positions()
	return maxf(_hp_bar_anchor_height, HP_BAR_HEIGHT_OFFSET)


func _refresh_hp_bar_anchor_height_and_positions() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	var anchor_height: float = _resolve_anchor_height_from_hero(_hero, HEAD_ANCHOR_NODE_NAME)
	if anchor_height > 0.0:
		_hp_bar_anchor_height = anchor_height
	else:
		var extra_offset: float = HP_BAR_HEIGHT_OFFSET
		var model_height: float = _compute_node_mesh_height(_hero)
		if model_height > 0.0:
			_hp_bar_anchor_height = model_height + extra_offset
		else:
			_hp_bar_anchor_height = extra_offset
	if _hp_bar != null and is_instance_valid(_hp_bar):
		_sync_hp_bar_follow_and_facing()
	if _attack_count_label != null and is_instance_valid(_attack_count_label):
		var attack_label_anchor_y: float = _resolve_anchor_local_y(_hero, HEAD_ANCHOR_NODE_NAME)
		if attack_label_anchor_y > 0.0:
			_attack_count_label.position = Vector3(
				0.0, attack_label_anchor_y + attack_count_label_height_offset, 0.0
			)
		else:
			_attack_count_label.position = Vector3(
				0.0, _hp_bar_anchor_height + attack_count_label_height_offset, 0.0
			)


func _sync_hp_bar_follow_and_facing() -> void:
	var head_anchor := _get_anchor_node(_hero, HEAD_ANCHOR_NODE_NAME)
	if head_anchor != null and is_instance_valid(head_anchor):
		CombatSceneUtils.sync_top_level_billboard_to_camera(
			_hp_bar, head_anchor, 0.0, get_viewport()
		)
		return
	CombatSceneUtils.sync_top_level_billboard_to_camera(
		_hp_bar, _hero, _hp_bar_anchor_height, get_viewport()
	)


func _compute_node_mesh_height(root_node: Node3D) -> float:
	var ignored_nodes: Array = [_hp_bar]
	if _attack_count_label != null:
		ignored_nodes.append(_attack_count_label)
	return CombatSceneUtils.compute_node_mesh_height(root_node, ignored_nodes)


func _create_attack_count_label() -> void:
	if _hero == null:
		return
	if _attack_count_label != null and is_instance_valid(_attack_count_label):
		_attack_count_label.queue_free()

	_attack_count_label = Label3D.new()
	_attack_count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_attack_count_label.no_depth_test = true
	_attack_count_label.fixed_size = true
	_attack_count_label.double_sided = true
	_attack_count_label.shaded = false
	_attack_count_label.render_priority = 20
	_attack_count_label.pixel_size = attack_count_label_pixel_size
	_attack_count_label.font_size = attack_count_label_font_size
	_attack_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_attack_count_label.modulate = Color(1.0, 0.92, 0.2, 1.0)
	_attack_count_label.outline_size = 2
	_attack_count_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	_attack_count_label.visible = _should_show_attack_count_label()
	var attack_label_anchor_y: float = _resolve_anchor_local_y(_hero, HEAD_ANCHOR_NODE_NAME)
	if attack_label_anchor_y > 0.0:
		_attack_count_label.position = Vector3(
			0.0, attack_label_anchor_y + attack_count_label_height_offset, 0.0
		)
	else:
		_attack_count_label.position = Vector3(
			0.0, _hp_bar_anchor_height + attack_count_label_height_offset, 0.0
		)
	_hero.add_child(_attack_count_label)
	_update_attack_count_label()


func _update_attack_count_label() -> void:
	if _attack_count_label == null:
		return
	if not _should_show_attack_count_label():
		_attack_count_label.visible = false
		return
	_attack_count_label.visible = true
	if _is_transformed:
		var left_sec: float = maxf(_transform_time_left, 0.0)
		_attack_count_label.text = "%.1fs" % left_sec
	else:
		var current_count: int = maxi(_attack_count, 0)
		_attack_count_label.text = "%d" % current_count
	var attack_label_anchor_y: float = _resolve_anchor_local_y(_hero, HEAD_ANCHOR_NODE_NAME)
	if attack_label_anchor_y > 0.0:
		_attack_count_label.position = Vector3(
			0.0, attack_label_anchor_y + attack_count_label_height_offset, 0.0
		)
	else:
		_attack_count_label.position = Vector3(
			0.0, _hp_bar_anchor_height + attack_count_label_height_offset, 0.0
		)


func _is_enemy_dead(enemy: Node3D) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return true
	var enemy_controller := enemy.get_parent()
	if enemy_controller != null and enemy_controller.has_method("is_dead"):
		return bool(enemy_controller.call("is_dead"))
	return false


func _get_effective_ias_percent() -> float:
	return HeroStatsService.get_effective_ias_percent(
		agility,
		_equip_attack_speed_percent_bonus,
		_spark_permanent_attack_speed_bonus_from_soul,
		_get_spark_temp_attack_speed_bonus_percent(),
		_battle_banner_applied_attack_speed_percent_bonus,
		_talent_float("attack_speed_percent_bonus", 0.0),
		AGI_ATTACK_SPEED_PER_POINT,
		WC3_IAS_MIN,
		WC3_IAS_MAX
	)


func _get_attack_speed_scale() -> float:
	attack_speed_percent_total = _get_effective_ias_percent()
	return HeroStatsService.get_attack_speed_scale(
		base_attack_speed,
		attack_speed_percent_total,
		_is_transformed,
		transformed_attack_speed_multiplier,
		_haste_active,
		skill_w_id,
		SKILL_ID_W_HASTE,
		haste_multiplier,
		_talent_float("warden_w_attack_speed_multiplier_bonus", 0.0)
	)


func _get_attack_interval() -> float:
	return HeroStatsService.get_attack_interval(
		_get_attack_speed_scale(), _spark_effect_float("attack_interval_reduction_sec", 0.0)
	)


func _get_effective_cooldown_reduction_percent() -> float:
	return HeroStatsService.compute_cooldown_reduction_percent(
		base_cooldown_reduction_percent,
		_equip_cooldown_reduction_percent_bonus,
		MAX_COOLDOWN_REDUCTION_PERCENT
	)


func _compute_skill_cooldown(base_cooldown: float) -> float:
	return HeroStatsService.compute_skill_cooldown(
		base_cooldown, cooldown_reduction_percent_total, MAX_COOLDOWN_REDUCTION_PERCENT
	)


func _get_armor_damage_multiplier() -> float:
	return HeroStatsService.get_armor_damage_multiplier(
		armor, ARMOR_K_MELEE_DEFAULT, NEGATIVE_ARMOR_BASE_MELEE_DEFAULT
	)


func _get_magic_damage_multiplier() -> float:
	return HeroStatsService.get_magic_damage_multiplier(
		(
			magic_immunity_rate
			+ _equip_magic_damage_reduction_percent_bonus
			+ _talent_float("magic_damage_reduction_percent_bonus", 0.0)
		)
	)


func _is_magic_damage_type(damage_type: String) -> bool:
	return HeroStatsService.is_magic_damage_type(damage_type)


func _schedule_finalize_death(delay_sec: float) -> void:
	var timer := get_tree().create_timer(maxf(delay_sec, 0.05))
	timer.timeout.connect(_finalize_death)


func _finalize_death() -> void:
	if _death_finalized:
		return
	_death_finalized = true

	if _hp_bar != null:
		_hp_bar.visible = false
	if _attack_count_label != null:
		_attack_count_label.visible = false

	if _hero != null:
		_hero.visible = false


func _find_nearest_enemy() -> Node3D:
	if _hero == null:
		return null
	var nearest: Node3D = null
	var nearest_distance := INF

	var candidates := get_tree().get_nodes_in_group(enemy_group_name)
	for candidate in candidates:
		var collider := candidate as Node3D
		if collider == null:
			continue

		var enemy := collider.get_parent() as Node3D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if _is_enemy_dead(enemy):
			continue

		var distance := _distance_xz(_hero.global_position, enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest


func _get_enemy_engage_range(enemy: Node3D) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return engage_range
	var ai_node := enemy.get_parent()
	if ai_node != null:
		var value = ai_node.get("engage_range")
		if value is float or value is int:
			return float(value)

	return engage_range
