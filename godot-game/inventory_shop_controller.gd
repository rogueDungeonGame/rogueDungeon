extends RefCounted
class_name InventoryShopController

const EQUIPMENT_ACTION_SERVICE_SCRIPT := preload("res://equipment_action_service.gd")
const EQUIPMENT_AUTHORITY_SERVICE_SCRIPT := preload("res://equipment_authority_service.gd")
const EQUIPMENT_RUNTIME_HELPER_SCRIPT := preload("res://equipment_runtime_helper.gd")
const SHOP_CATALOG_HELPER_SCRIPT := preload("res://shop_catalog_helper.gd")
const SHOP_ITEM_CARD_FACTORY_SCRIPT := preload("res://shop_item_card_factory.gd")
const EQUIPMENT_EFFECTS_SERVICE_SCRIPT := preload("res://equipment_effects_service.gd")
const SHOP_PANEL_CONTROLLER_SCRIPT := preload("res://shop_panel_controller.gd")
const OBSERVE_SYNC_SERVICE_SCRIPT := preload("res://observe_sync_service.gd")
const HUD_SLOT_ITEM_GOLD_TEXTURE := preload("res://ui/hud_assets/rogue_dungeon/slot_item_gold.png")
const HUD_SKILL_BUTTON_TEXTURE := preload(
	"res://ui/hud_assets/rogue_dungeon/skill_button_frame.png"
)

var _owner: Node = null
var _hero_ctrl: Node = null
var _net_ctrl: Node = null
var _ui_state: Object = null
var _resolve_net_ctrl_callback: Callable = Callable()
var _set_observed_peer_callback: Callable = Callable()
var _input_lock_changed_callback: Callable = Callable()
var _debug_shop_click_logs: bool = true

var _shop_visible: bool = false
var _shop_access_enabled: bool = true
var _inventory_slots: Array[PanelContainer] = []
var _inventory_icons: Array[TextureRect] = []
var _inventory_panel_root: Control
var _command_panel_root: Control
var _shop_level: int = 1
var _gold: int = 10000
var _shop_offered: Array[int] = []
var _destroy_mode: bool = false
var _destroy_hover_index: int = -1
var _last_inventory_signature: String = ""
var _inventory_display_override: Array = []
var _inventory_display_override_slot_map: Array = []
var _inventory_display_override_signature: String = ""
var _shop_panel_controller = null
var _active_shop_owner_peer_id: int = 0
var _shop_debug_label: Label
var _last_shop_click_debug_text: String = "-"
var _pending_shop_action: String = ""
var _local_battle_phase_active: bool = false
var _destroy_skill_panel: PanelContainer
var _skill_button_by_key: Dictionary = {}
var _skill_mana_masks: Dictionary = {}
var _skill_cd_masks: Dictionary = {}
var _skill_cd_mask_materials: Dictionary = {}
var _item_icon_index_ready: bool = false
var _item_icon_lookup: Dictionary = {}
var _item_icon_resolve_cache: Dictionary = {}
var _missing_item_icon_names: Dictionary = {}
var _equipment_inventory_meta: Array = []
var _destroy_faction_state: Dictionary = {}
var _coin_faction_state: Dictionary = {}
var _equipment_action_service = null
var _equipment_authority_service = null
var _equipment_runtime_helper = null
var _shop_catalog_helper = null
var _shop_item_card_factory = null
var _observe_sync_service = null
var _equipment_effects_service = null

const SKILL_ICON_DIR := "res://icons/skills"
const PASSIVE_ICON_DIR := "res://icons/passives"
const NEW_PASSIVE_ICON_DIR := "res://new_icons/passive"
const P := SKILL_ICON_DIR + "/"
const ITEM_DB_MAP_JSON_PATH := "res://data/item_db_map.json"
const FALLBACK_ITEM_ICON := "BTNTemp.png"
const ITEM_ICON_FALLBACK_PATH := P + FALLBACK_ITEM_ICON
const ITEM_ICON_SEARCH_DIRS := [SKILL_ICON_DIR, PASSIVE_ICON_DIR, NEW_PASSIVE_ICON_DIR]
const ITEM_ICON_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const HERO_ID_MELEE: int = 1
const HERO_ID_RANGED: int = 2
const HERO_NAME_MELEE: String = "守望者"
const HERO_NAME_RANGED: String = "火枪手"
const BOSS_DISPLAY_NAME: String = "牛肉人酋长"
const ENEMY_DISPLAY_NAME: String = "牛头人"
const DESTROY_DEFAULT_STRENGTH_BASE: float = 24.0
const DESTROY_DEFAULT_AGILITY_BASE: float = 12.0
const DESTROY_DEFAULT_INTELLIGENCE_BASE: float = 14.0
const DESTROY_DEFAULT_STRENGTH_GROWTH: float = 2.5
const DESTROY_DEFAULT_AGILITY_GROWTH: float = 2.0
const DESTROY_DEFAULT_INTELLIGENCE_GROWTH: float = 1.8

const BUILD_TABS := [
	"全部", "摧毁", "负债", "神器", "泰坦", "通灵", "战旗", "备战", "结算", "充能", "咒文", "火花", "硬币", "无派系"
]
const BUILD_ALIAS_MAP := {
	"初始": "无派系",
	"过渡": "无派系",
	"贷款": "负债",
	"战备": "备战",
	"三月": "无派系",
	"消耗": "无派系",
	"灵翁": "灵魂",
	"灵瓮": "灵魂",
	"闯祸": "传火",
	"次轮": "齿轮",
	"特性": "无派系",
	"特摧": "无派系",
	"后期": "无派系",
}
const ITEM_NAME_OVERRIDES := {
	"怨恨头骨": "怨恨币",
}
const ITEM_BUILD_OVERRIDES := {
	"火花手套": "火花",
	"闪耀之爪": "火花",
	"破败巫毒之剑": "火花",
	"破板巫毒之剑": "火花",
	"霜火之珠": "火花",
	"骨制风铃": "摧毁",
	"霜火皇冠": "火花",
	"泰坦图腾": "泰坦",
	"火焰风衣": "泰坦",
	"巨人之力图腾": "泰坦",
	"通天锤": "摧毁",
	"通天滕": "咒文",
	"通天藤": "咒文",
	"勇气勋章": "结算",
	"雄鹰戒子": "结算",
	"雄鹰戒指": "结算",
	"金色勋章": "结算",
	"圣兽之戒": "结算",
	"远古战斧": "泰坦",
	"万宝锤": "摧毁",
	"月牙塔": "通灵",
	"三月": "结算",
	"三月之珠": "结算",
	"三月状态": "无派系",
	"裁决者圣剑": "结算",
	"开辟者": "结算",
	"恶鬼剑": "结算",
	"泰坦化身": "泰坦",
	"化身泰坦之杖": "泰坦",
	"灵魂": "灵魂",
	"亚煞极魂珠": "灵魂",
	"噬魂": "灵魂",
	"窃魂": "灵魂",
	"账本": "结算",
	"窃魂灵翁": "灵魂",
	"结算灵瓮": "结算",
	"唤醒泰坦之杖": "泰坦",
	"劣质充能瓶": "充能",
	"充能瓶": "充能",
	"强效充能瓶": "充能",
	"战术头盔": "负债",
	"蓝港头盔": "负债",
	"休闲耳机": "负债",
	"试做型注射剂": "负债",
	"私人贷卷": "负债",
	"挑战头巾": "备战",
	"诅咒之书": "邪能",
	"禁忌之书": "邪能",
	"纯金宝钥": "魔戒",
	"嗜戒狂之盔": "魔戒",
	"许愿星": "魔戒",
	"解咒石": "魔戒",
	"铭咒金印": "咒文",
	"阿卡兰的魔匝": "咒文",
	"阿卡兰的魔匣": "咒文",
	"卡德加的咒文书": "咒文",
	"蜘蛛戒指": "咒文",
	"蜘蛛戒子": "咒文",
	"星落法杖": "自动",
	"星落怀表": "自动",
	"十尾神剑": "神器",
	"神灵之杖": "神器",
	"怨恨头骨": "硬币",
	"夹层硬币": "硬币",
	"硬币箱": "硬币",
	"耗尽的驱动核心": "齿轮",
	"驱动核心": "齿轮",
	"改装钳": "齿轮",
	"机械飞升": "齿轮",
	"万用齿轮": "齿轮",
}
const BLOCKED_SHOP_BUILDS := {
	"自动": true,
	"灵魂": true,
	"灵瓮": true,
	"传火": true,
	"齿轮": true,
	"魔戒": true,
	"邪能": true,
	"诅咒": true,
	"配件": true,
}
const BLOCKED_SHOP_ITEM_NAME_KEYWORDS := ["至尊"]
const ITEM_SECONDARY_BUILDS := {
	"灵魂": ["灵魂"],
	"结算灵瓮": ["灵魂", "灵翁"],
	"结算灵翁": ["灵魂", "灵翁"],
	"咒文灵瓮": ["灵魂", "灵翁"],
	"咒文灵翁": ["灵魂", "灵翁"],
	"火花灵瓮": ["灵魂", "灵翁"],
	"火花灵翁": ["灵魂", "灵翁"],
	"净化者": ["邪能"],
}
const SPARK_FORCE_ITEM_NAMES := {
	"加速手套": true,
	"符文石": true,
	"火花灵瓮": true,
	"火花灵翁": true,
	"霓虹棍剑": true,
	"毁灭之怒": true,
	"泰坦之怒": true,
	"火花末刃": true,
	"火花奇术手": true,
	"遗留者眼球": true,
	"火花飞矢": true,
	"疾风短剑": true,
	"破败火花剑": true,
	"破败之刃": true,
	"火花环刃": true,
	"霜火之珠": true,
	"闪耀之爪": true,
	"幻影对剑": true,
	"蓝港棍剑": true,
	"陨灭泰坦之锤": true,
	"陨灭泰坦锤": true,
	"火花手套": true,
	"霜火皇冠": true,
}
const BLOCKED_SHOP_ITEM_EXACT_NAMES := {
	"木盾": true,
	"小盾": true,
	"小刀": true,
	"诡变魔方": true,
	"诡辩魔方": true,
	"赌徒吉祥物": true,
	"鲜血钥匙": true,
	"私人贷券": true,
	"冻结之杖移除": true,
	"点金术": true,
	"点金手": true,
	"流星": true,
	"魔戒": true,
	"金印": true,
	"咒文消耗": true,
	"疯狂药剂": true,
	"疯狂的药剂": true,
	"喷火器": true,
	"巫毒权杖": true,
	"巫毒项链": true,
	"巫毒小玩意": true,
	"储备蛇棒": true,
	"龙蛋": true,
	"无敌斩": true,
	"牛肉人诅咒": true,
	"牛头人诅咒": true,
	"萨满诅咒": true,
	"剑圣诅咒": true,
	"血法诅咒": true,
	"血法的诅咒": true,
	"毒液之珠": true,
	"æ¯æ¶²ä¹ç": true,
	"暗影之珠": true,
	"æå½±ä¹ç": true,
}

const SHOP_ITEM_COUNT := {1: 4, 2: 4, 3: 5, 4: 5, 5: 5, 6: 6, 7: 6}
const SHOP_UPGRADE_COST := {1: 100, 2: 150, 3: 250, 4: 400, 5: 600, 6: 1000, 7: 0}
const SHOP_REFRESH_COST := 50
const SHOP_UI_SCALE := 2.0
const ITEM_COST := {1: 50, 2: 100, 3: 150, 4: 250, 5: 400, 6: 600, 7: 1000}
const SHOP_ITEM_DETAIL_HOVER_DELAY_SEC := 0.05
const SHOP_ITEM_DETAIL_WIDTH := 290.0 * SHOP_UI_SCALE
const SHOP_ITEM_DETAIL_MIN_HEIGHT := 108.0 * SHOP_UI_SCALE
const SHOP_ITEM_DETAIL_MAX_HEIGHT := 156.0 * SHOP_UI_SCALE
const SHOP_ITEM_DETAIL_EST_CHARS_PER_LINE := 26.0
const CHARGE_BUILD_NAME := "充能"
const CHARGE_STACK_AGILITY := 2
const CHARGE_TELESCOPE_RANGE_PER_CONSUMABLE := 20
const CHARGE_SHIELD_HP_PER_STACK := 20
const CHARGE_SHIELD_SPELL_DAMAGE_PER_STACK := 2
const CHARGE_STAFF_SUMMON_BONUS_PER_STACK := 5.0
const CHARGE_FUTURE_ENGINE_REFRESH_PROC_CHANCE := 0.6
const CHARGE_FUTURE_ENGINE_CRIT_DAMAGE_PER_PROC := 2
const CHARGE_BOTTLE_REPEAT_COUNT := {
	"劣质充能瓶": 3,
	"充能瓶": 6,
	"强效充能瓶": 9,
}
const CHARGE_BOTTLE_APPEARANCE_ITEM_NAMES := {
	"完美核心": true,
	"完美火花石": true,
}
const CHARGE_BOTTLE_SHOP_ITEM_NAMES := {
	"劣质充能瓶": true,
	"充能瓶": true,
	"强效充能瓶": true,
}
const CHARGE_ACTIVE_USE_ITEM_NAMES := {
	"充能电池": true,
	"瓶装粒子": true,
}
const COIN_BUILD_NAME := "硬币"
const COIN_LAYER_GAIN_PER_COIN_GAIN := 1
const COIN_BUTTON_ATTACK_SPEED_PER_LAYER := 25
const COIN_SMILE_DAMAGE_TENTHS_PER_COIN_OWNED := 15
const COIN_LUCKY_GOLD_PER_TRIGGER := 85
const COIN_GOLD_GOLD_PER_LAYER := 20
const COIN_GOLD_REFRESH_LIMIT_PER_ITEM := 10
const COIN_GOLD_INITIAL_EXTRA_LAYERS := 2
const LEVEL_WEIGHTS := {
	1: {1: 100},
	2: {1: 50, 2: 50},
	3: {1: 20, 2: 40, 3: 40},
	4: {1: 10, 2: 20, 3: 35, 4: 35},
	5: {1: 5, 2: 15, 3: 20, 4: 30, 5: 30},
	6: {1: 5, 2: 10, 3: 15, 4: 20, 5: 25, 6: 25},
	7: {1: 5, 2: 5, 3: 10, 4: 15, 5: 20, 6: 25, 7: 20},
}


func _get_shop_roll_weights_for_level(level: int) -> Dictionary:
	return _get_shop_catalog_helper().get_shop_roll_weights_for_level(level)


func _get_charge_bottle_shop_bonus_count(inventory: Array) -> int:
	var bonus_count: int = 0
	for slot_idx in range(inventory.size()):
		var item_idx: int = int(inventory[slot_idx])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		var item_name: String = _get_item_name_by_index(item_idx)
		if CHARGE_BOTTLE_APPEARANCE_ITEM_NAMES.has(item_name):
			bonus_count += 1
	return bonus_count


func _append_shop_candidate_with_runtime_weight(
	candidates: Array[int], item_idx: int, inventory: Array
) -> void:
	_get_shop_catalog_helper().append_shop_candidate_with_runtime_weight(
		candidates, item_idx, inventory, item_db
	)


const RECIPES := [
	{"inputs": {"流星": 3}, "output": "星落怀表"},
	{"inputs": {"金色勋章": 2}, "output": "雄狮之戒"},
	{"inputs": {"审判金剑": 3}, "output": "裁决者圣剑"},
	{"inputs": {"毁灭之怒": 3}, "output": "陨灭泰坦之锤"},
	{"inputs": {"泰坦之怒": 3}, "output": "陨灭泰坦之锤"},
	{"inputs": {"三月": 3}, "output": "泰坦化身"},
	{"inputs": {"霜火之珠": 1}, "output": "霜火皇冠", "extra_cost": 500},
]

var item_db: Array = [
	{"name": "木盾", "icon": "BTNThornShield.png", "stat": "Lv1 | +3护甲 +50生命", "build": "初始"},
	{"name": "小刀", "icon": "BTNClawsOfAttack.png", "stat": "Lv1 | +5攻击力", "build": "初始"},
	{"name": "勇气勋章", "icon": "BTNMedalionOfCourage.png", "stat": "Lv1 | +2全属性", "build": "初始"},
	{"name": "生命护符", "icon": "BTNAmulet.png", "stat": "Lv1 | +150生命 喂宝珠垫子", "build": "过渡"},
	{"name": "橡果", "icon": "BTNAcorn.png", "stat": "Lv1 | +100生命 7级道具垫子", "build": "过渡"},
	{"name": "小树枝", "icon": "BTNEnchantedGemstone.png", "stat": "Lv2 | +1全属性 嫖6商店", "build": "过渡"},
	{"name": "火焰风衣", "icon": "BTNCloakOfFlames.png", "stat": "Lv3 | +8%法伤 反弹火伤", "build": "过渡"},
	{"name": "吊命娃娃", "icon": "BTNVialFull.png", "stat": "Lv3 | 死亡复活50%HP一次", "build": "过渡"},
	{"name": "窃魂灵翁", "icon": "BTNSoulGem.png", "stat": "Lv3 | 击杀+灵魂 +2全属性/层", "build": "过渡"},
	{"name": "雄鹰戒指", "icon": "BTNRingJadeFalcon.png", "stat": "Lv3 | +5敏 结算+100HP", "build": "过渡"},
	{"name": "私人贷卷", "icon": "BTNScroll.png", "stat": "Lv3 | 贷款200金 每波还息", "build": "过渡"},
	{
		"name": "空洞宝珠",
		"icon": "BTNSoulGem.png",
		"stat": "Lv4 | +18智力 以器养器：在你摧毁一个装备后，+1层数。 在你摧毁一个装备后，如果你有3层层数，进化为邪灵宝珠。 结算效果会在每轮战斗结束后触发",
		"build": "摧毁"
	},
	{
		"name": "回收锤",
		"icon": "BTNDivineShieldOff.png",
		"stat": "Lv5 | +14力量 +18智力 +300生命值 回收：摧毁一个装备后，获得摧毁目标等级*2的随机属性（可能是力量，敏捷，或智力）",
		"build": "摧毁"
	},
	{
		"name": "血羽之心",
		"icon": "BTNPhilosophersStone.png",
		"stat": "Lv6 | +15力量 +10敏捷 +28智力 秘力：在你摧毁一个其他道具后，血羽之心获得等同于该道具的道具等级。",
		"build": "摧毁"
	},
	{
		"name": "骨制风铃",
		"icon": "BTNBoneChimes.png",
		"stat": "Lv4 | +20攻击力 +30%攻击速度 +5三围 摧毁：提高你的基础三围属性（白字），使其不低于你的总道具等级。 摧毁效果会在道具被摧毁时触发",
		"build": "摧毁"
	},
	{
		"name": "邪灵宝珠",
		"icon": "BTNOrb.png",
		"stat": "Lv7 | +32智力 邪珠：该道具等级相当于你献祭的道具总等级。 该道具每级提供额外4%的魔法伤害加成。",
		"build": "摧毁"
	},
	{
		"name": "万宝锤",
		"icon": "BTNwbc.png",
		"stat": "Lv3 | +8力量 +250生命值 砸！：当你摧毁一个装备后，永久提高装备等级*20点生命值上限",
		"build": "摧毁"
	},
	{"name": "蓝港补给箱", "icon": "BTNIcyTreasureBox.png", "stat": "Lv5 | 每波补给+还贷 核心", "build": "贷款"},
	{"name": "VIP卡", "icon": "BTNChestOfGold.png", "stat": "Lv5 | 钱少概率高 +200%收益", "build": "贷款"},
	{"name": "流星", "icon": "BTNStarFall.png", "stat": "Lv5 | +15%法伤 3个合成怀表", "build": "贷款"},
	{"name": "星落怀表", "icon": "BTNStarWand.png", "stat": "Lv7 | 3流星合 +45%法伤+陨落", "build": "贷款"},
	{"name": "贷款头盔", "icon": "BTNHelmOfValor.png", "stat": "Lv5 | +8%暴击 贷款毕业装", "build": "贷款"},
	{"name": "贷款盾", "icon": "BTNManaShield.png", "stat": "Lv5 | +12护甲 +格挡 毕业装", "build": "贷款"},
	{"name": "夹层硬币", "icon": "BTNTransmute.png", "stat": "Lv3 | 免费嫖VIP 减少花费", "build": "贷款"},
	{"name": "三月", "icon": "BTN3M3.png", "stat": "Lv6 | 3个合成Lv7 +大量全属性", "build": "三月"},
	{"name": "账本", "icon": "BTNTome.png", "stat": "Lv6 | 结算效果额外触发一次", "build": "三月"},
	{"name": "窃魂", "icon": "BTNUsedSoulGem.png", "stat": "Lv4 | 叠灵魂层数 词缀装备", "build": "三月"},
	{"name": "泰坦图腾", "icon": "BTNTaurenTotem.png", "stat": "Lv4 | +12力量 词缀加成", "build": "三月"},
	{"name": "自动机枪", "icon": "BTNInfernalCannon.png", "stat": "Lv6 | 自动攻击 装入组装器", "build": "自动"},
	{
		"name": "闪光放射器",
		"icon": "BTNInfernalFlameCannon.png",
		"stat": "Lv6 | 信标触发+法伤叠加",
		"build": "自动"
	},
	{"name": "组装器", "icon": "BTNBox.png", "stat": "Lv6 | 装入武器 可升级为信标", "build": "自动"},
	{"name": "信标", "icon": "BTNInfernalStone.png", "stat": "Lv6 | 定期触发武器 自动核心", "build": "自动"},
	{"name": "耐文合金", "icon": "BTNThoriumArmor.png", "stat": "Lv5 | +15护甲 +500生命", "build": "自动"},
	{"name": "英灵旗布", "icon": "BTNHumanCaptureFlag.png", "stat": "Lv5 | 旗帜层数翻倍 核心", "build": "战旗"},
	{"name": "银月", "icon": "BTNMoonKey.png", "stat": "Lv5 | +20%法伤 +10智力", "build": "战旗"},
	{"name": "全属性旗", "icon": "BTNNightElfCaptureFlag.png", "stat": "Lv4 | +3全属性/每层", "build": "战旗"},
	{"name": "法伤旗", "icon": "BTNOrcCaptureFlag.png", "stat": "Lv4 | +5%法伤/每层", "build": "战旗"},
	{"name": "审判金剑", "icon": "BTNFrostMourne.png", "stat": "Lv6 | 每结算装+2敏智+1%暴击", "build": "结算"},
	{"name": "金色账簿", "icon": "BTNTomeBrown.png", "stat": "Lv6 | 结算效果额外触发 核心", "build": "结算"},
	{"name": "雄狮之戒", "icon": "BTNRingLionHead.png", "stat": "Lv5 | +8敏 结算+200HP", "build": "结算"},
	{"name": "开辟者", "icon": "BTNScepterOfMastery.png", "stat": "Lv5 | +25%暴击伤害", "build": "结算"},
	{"name": "恶鬼剑", "icon": "BTNSacrificialSkull.png", "stat": "Lv5 | +15%暴击伤害", "build": "结算"},
	{"name": "钥匙", "icon": "BTNGhostKey.png", "stat": "Lv4 | +10%暴击率 英雄适配", "build": "结算"},
	{"name": "充能剑", "icon": "BTNDaggerOfEscape.png", "stat": "Lv5 | 充能攻击+50%伤害", "build": "充能"},
	{"name": "扳指", "icon": "BTNRingPurple.png", "stat": "Lv5 | +5全属性 攻击获充能层", "build": "充能"},
	{
		"name": "通灵杖",
		"icon": "BTNStaffOfNegation.png",
		"stat": "Lv5 | +10智力 技能伤害+20%",
		"build": "充能"
	},
	{"name": "完美核心", "icon": "BTNCrystalBall.png", "stat": "Lv6 | 充能满释放能量波 +8全属性", "build": "充能"},
	{"name": "充能齿轮", "icon": "BTNPocketFactory.png", "stat": "Lv5 | 充能核心装备 +充能效率", "build": "充能"},
	{"name": "粒子充能瓶", "icon": "BTNPotionBlueBig.png", "stat": "Lv5 | 高级充能瓶 大量充能层", "build": "充能"},
	{"name": "卡德加", "icon": "BTNSpellBookBLS.png", "stat": "Lv6 | 咒文效果+50% 法器核心", "build": "咒文"},
	{"name": "通灵长袍", "icon": "BTNRobeOfTheMagi.png", "stat": "Lv5 | +15智力 召唤物+30%伤", "build": "咒文"},
	{"name": "咒文灵翁", "icon": "BTNSobiMask.png", "stat": "Lv5 | 吃灵魂补主属性 咒文+1层", "build": "咒文"},
	{"name": "咒文匣子", "icon": "BTNCrate.png", "stat": "Lv6 | 存储咒文自动释放 法伤核心", "build": "咒文"},
	{
		"name": "毁灭之怒",
		"icon": "BTNAmuletOftheWild.png",
		"stat":
		"Lv3 | +600最大生命值 毁灭之怒：攻击时，造成自身最大生命值2%的额外范围伤害（攻击特效） 大部分由攻击触发的额外效果都属于攻击特效 三个泰坦之怒可以合成为陨灭泰坦之锤",
		"build": "火花"
	},
	{
		"name": "火花环刃",
		"icon": "BTNUpgradeMoonGlaive.png",
		"stat": "Lv5 | +500生命 叠血核心",
		"build": "火花"
	},
	{"name": "遗留者眼球", "icon": "BTNOrbOfFire.png", "stat": "Lv5 | +法伤 火花伤害×10倍", "build": "火花"},
	{"name": "符文石", "icon": "BTNRunedBracers.png", "stat": "Lv4 | +300生命 叠血辅助", "build": "火花"},
	{"name": "破败之刃", "icon": "BTNOrbOfCorruption.png", "stat": "Lv5 | 按%目标最大生命造伤", "build": "火花"},
	{
		"name": "陨灭泰坦之锤",
		"icon": "BTNGolemThunderclap.png",
		"stat": "Lv7 | +1800最大生命值 陨灭之怒：攻击时，造成自身最大生命值4%的额外范围伤害（攻击特效） 大部分由攻击触发的额外效果都属于攻击特效",
		"build": "火花"
	},
	{"name": "火花灵翁", "icon": "BTNMarkOfFire.png", "stat": "Lv5 | 吃灵魂加攻速 火花辅助", "build": "火花"},
	{"name": "闪耀之爪", "icon": "BTNBearBlink.png", "stat": "Lv5 | 闪耀特效 300层超破败", "build": "特摧"},
	{"name": "霜火之珠", "icon": "BTNOrbOfFrost.png", "stat": "Lv5 | 升级成皇冠白嫖火花等级", "build": "特摧"},
	{"name": "霜火皇冠", "icon": "BTNHelmutPurple.png", "stat": "Lv6 | 白嫖火花等级 可喂宝珠", "build": "特摧"},
	{"name": "刷新币", "icon": "BTNPotionOfClarity.png", "stat": "Lv5 | 刷新商店获额外效果 必买", "build": "硬币"},
	{"name": "金硬币", "icon": "BTNPotionOfDivinity.png", "stat": "Lv5 | 获大量金币经验 核心", "build": "硬币"},
	{
		"name": "通天锤",
		"icon": "BTNStormHammer.png",
		"stat":
		"Lv6 | +600生命值 +14力量 +18智力 +20攻击力 在你摧毁一个道具后，+1层数 启智：拥有6层层数后，消耗所有层数，使你下次升级选择的两个天赋强化次数+1",
		"build": "摧毁"
	},
	{"name": "剑圣诅咒", "icon": "BTNWandSkull.png", "stat": "Lv5 | 攻击力转化全伤害 物理神", "build": "诅咒"},
	{"name": "血法诅咒", "icon": "BTNBloodLust.png", "stat": "Lv5 | 法术攻击+暴击 充能15波锁", "build": "诅咒"},
	{"name": "牛头人诅咒", "icon": "BTNCurse.png", "stat": "Lv5 | 燃烧+全能加成 牛头核心", "build": "诅咒"},
	{
		"name": "萨满诅咒",
		"icon": "BTNBigBadVoodooSpell.png",
		"stat": "Lv5 | 咒文召唤强化 咒文流用",
		"build": "诅咒"
	},
	{"name": "充能瓶", "icon": "BTNPotionBlue.png", "stat": "Lv3 | 消耗品 充n个电池叠充能", "build": "消耗"},
	{"name": "充能电池", "icon": "BTNPendantOfEnergy.png", "stat": "Lv3 | 消耗品 电池充充能瓶循环", "build": "消耗"},
	{"name": "经验币", "icon": "BTNPotionGreen.png", "stat": "Lv3 | 消耗品 获大量经验值", "build": "消耗"},
	{"name": "金印", "icon": "BTNGlyph.png", "stat": "Lv4 | 消耗品 咒文替代 没匣子先用", "build": "消耗"},
	{"name": "灵魂", "icon": "BTNSpiritWolf.png", "stat": "Lv2 | 消耗品 灵翁/窃魂获得", "build": "消耗"},
	{"name": "咒文消耗", "icon": "BTNSpellSteal.png", "stat": "Lv3 | 消耗品 吃加主属性 挑便宜", "build": "消耗"},
	{"name": "龙蛋", "icon": "BTNPhoenixEgg.png", "stat": "Lv4 | 配件 龙血沸腾+5特效/层", "build": "配件"},
	{"name": "望远镜", "icon": "BTNFarSight.png", "stat": "Lv4 | 配件 龙蛋流 电池点给它", "build": "配件"},
	{"name": "电磁屏障", "icon": "BTNNeutralManaShield.png", "stat": "Lv4 | 配件 防御护盾减伤", "build": "配件"},
	{"name": "无敌斩", "icon": "BTNDivineShieldOff.png", "stat": "Lv4 | 配件 剑圣专用 无敌W", "build": "配件"},
	{"name": "怨恨头骨", "icon": "BTNRingSkull.png", "stat": "Lv4 | 配件 死后灵体无敌平A", "build": "配件"},
	{"name": "不详", "icon": "BTNGuldanSkull.png", "stat": "Lv6 | +25%暴击率 15波后锁", "build": "后期"},
	{
		"name": "蓝港护盾",
		"icon": "BTNlzhdup.png",
		"stat":
		"Lv7 | 负债：1200 +24力量 +12智力 +50生命值 离子护盾：在你受到伤害时，将魔法值转化为等额护盾。每点魔法值可以提供3点护盾，在你的魔法值低于50%时失效。 蓝港补给：在你偿还负债后，永久获得等额魔法最大值。",
		"build": "泰坦"
	},
	{
		"name": "唤醒泰坦之杖",
		"icon": "BTNWitchDoctorMaster.png",
		"stat": "Lv4 | +25力量 主动使用：如果你有6件泰坦装备，消耗它们，转化为1件泰坦化身。",
		"build": "泰坦"
	},
	{"name": "泰坦化身", "icon": "BTNFleshGolem.png", "stat": "Lv7 | 全属性翻倍 8K+血 10W+伤", "build": "后期"},
	{"name": "月牙塔", "icon": "BTNAncientOfTheMoon.png", "stat": "Lv6 | +法伤 后期4月牙2合金", "build": "通灵"},
	{"name": "噬魂", "icon": "BTNSpiritLink.png", "stat": "Lv6 | 吃灵魂+攻速 几万攻速可达", "build": "后期"},
	{
		"name": "暴击头盔",
		"icon": "BTNHumanArmorUpThree.png",
		"stat": "Lv5 | +10%暴击率 18波换装",
		"build": "后期"
	},
	{"name": "暴击斧", "icon": "BTNCriticalStrike.png", "stat": "Lv5 | +20%暴击伤害 恶鬼替代", "build": "后期"},
]

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


func configure(
	owner: Node,
	hero_ctrl: Node,
	net_ctrl: Node,
	ui_state: Object,
	resolve_net_ctrl_callback: Callable,
	set_observed_peer_callback: Callable,
	input_lock_changed_callback: Callable,
	debug_shop_click_logs: bool
) -> void:
	_owner = owner
	_hero_ctrl = hero_ctrl
	_net_ctrl = net_ctrl
	_ui_state = ui_state
	_resolve_net_ctrl_callback = resolve_net_ctrl_callback
	_set_observed_peer_callback = set_observed_peer_callback
	_input_lock_changed_callback = input_lock_changed_callback
	_debug_shop_click_logs = debug_shop_click_logs


func set_ui_refs(refs: Dictionary) -> void:
	_inventory_panel_root = refs.get("inventory_panel_root", null) as Control
	_inventory_slots.clear()
	_inventory_icons.clear()
	var inventory_slots_variant: Variant = refs.get("inventory_slots", [])
	if inventory_slots_variant is Array:
		_inventory_slots.assign(inventory_slots_variant)
	var inventory_icons_variant: Variant = refs.get("inventory_icons", [])
	if inventory_icons_variant is Array:
		_inventory_icons.assign(inventory_icons_variant)
	_destroy_skill_panel = refs.get("destroy_skill_panel", null) as PanelContainer


func set_shop_debug_label(label: Label) -> void:
	_shop_debug_label = label
	if _shop_debug_label != null:
		_shop_debug_label.visible = _debug_shop_click_logs


func initialize() -> void:
	_load_item_db_from_map_json()


func initialize_after_ui_ready() -> void:
	_apply_inventory_bonuses_to_hero()
	if _hero_ctrl != null and _hero_ctrl.has_method("set_destroy_cursor_mode"):
		_hero_ctrl.call("set_destroy_cursor_mode", false)
	_sync_destroy_hover_cursor()
	_refresh_inventory()


func process() -> void:
	_update_shop_debug_overlay()
	_check_shop_click()
	if _shop_visible:
		_update_shop_info()
	_refresh_inventory()


func is_shop_visible() -> bool:
	return _shop_visible


func build_shop_panel(root: Control) -> void:
	_build_shop_panel(root)


func handle_input(event: InputEvent) -> void:
	_input(event)


func on_inventory_slot_input(event: InputEvent, index: int) -> void:
	_on_inv_slot_input(event, index)


func on_inventory_slot_mouse_entered(index: int) -> void:
	_on_inv_slot_mouse_entered(index)


func on_inventory_slot_mouse_exited(index: int) -> void:
	_on_inv_slot_mouse_exited(index)


func on_observe_state_changed(reset_local_destroy_mode: bool) -> void:
	_last_inventory_signature = ""
	if reset_local_destroy_mode:
		_destroy_mode = false
		_destroy_hover_index = -1
		if _hero_ctrl != null and _hero_ctrl.has_method("set_destroy_cursor_mode"):
			_hero_ctrl.call("set_destroy_cursor_mode", false)
	_sync_destroy_hover_cursor()
	_update_destroy_visual()
	_update_shop_info()
	_update_inventory_panel_visibility()
	_update_skill_panel_visibility()


func is_local_equipment_state_synced(authority_state: Dictionary) -> bool:
	_ensure_local_equipment_runtime_state()
	var local_inventory: Array = []
	if _hero_ctrl != null:
		local_inventory = _to_int_array(_hero_ctrl.get("inventory"))
	var authority_inventory: Array = _to_int_array(authority_state.get("inventory", []))
	var authority_meta: Array = _sanitize_inventory_meta_array(
		authority_state.get("inventory_meta", []), authority_inventory
	)
	var authority_destroy_state: Dictionary = _sanitize_destroy_faction_state(
		authority_state.get("destroy_faction_state", {})
	)
	var authority_coin_state: Dictionary = _sanitize_coin_faction_state(
		authority_state.get("coin_faction_state", {})
	)
	return (
		_get_observe_sync_service()
		. is_local_equipment_state_synced(
			authority_state,
			{
				"inventory": local_inventory,
				"gold": _gold,
				"shop_level": _shop_level,
				"shop_offer_ids": _shop_offered.duplicate(true),
				"destroy_mode": _destroy_mode,
				"inventory_meta": _equipment_inventory_meta.duplicate(true),
				"destroy_faction_state": _destroy_faction_state.duplicate(true),
				"coin_faction_state": _coin_faction_state.duplicate(true),
				"authority_inventory": authority_inventory,
				"authority_inventory_meta": authority_meta,
				"authority_destroy_faction_state": authority_destroy_state,
				"authority_coin_faction_state": authority_coin_state,
			}
		)
	)


func _resolve_net_ctrl() -> void:
	if _resolve_net_ctrl_callback.is_valid():
		var resolved_variant: Variant = _resolve_net_ctrl_callback.call()
		if resolved_variant is Node:
			_net_ctrl = resolved_variant as Node


func _notify_input_lock_changed() -> void:
	if _input_lock_changed_callback.is_valid():
		_input_lock_changed_callback.call()


func _request_clear_observed_peer() -> void:
	if _set_observed_peer_callback.is_valid():
		_set_observed_peer_callback.call(0)


func _get_viewport_mouse_position() -> Vector2:
	if _owner == null or _owner.get_viewport() == null:
		return Vector2.ZERO
	return _owner.get_viewport().get_mouse_position()


func _get_equipment_action_service():
	if _equipment_action_service == null:
		_equipment_action_service = EQUIPMENT_ACTION_SERVICE_SCRIPT.new()
	return _equipment_action_service


func _get_equipment_authority_service():
	if _equipment_authority_service == null:
		_equipment_authority_service = EQUIPMENT_AUTHORITY_SERVICE_SCRIPT.new()
	return _equipment_authority_service


func _get_equipment_runtime_helper():
	if _equipment_runtime_helper == null:
		_equipment_runtime_helper = EQUIPMENT_RUNTIME_HELPER_SCRIPT.new()
	return _equipment_runtime_helper


func _get_shop_catalog_helper():
	if _shop_catalog_helper == null:
		_shop_catalog_helper = (
			SHOP_CATALOG_HELPER_SCRIPT
			. new(
				{
					"default_build_name": "无派系",
					"build_alias_map": BUILD_ALIAS_MAP,
					"item_name_overrides": ITEM_NAME_OVERRIDES,
					"item_build_overrides": ITEM_BUILD_OVERRIDES,
					"blocked_shop_builds": BLOCKED_SHOP_BUILDS,
					"item_secondary_builds": ITEM_SECONDARY_BUILDS,
					"blocked_shop_item_exact_names": BLOCKED_SHOP_ITEM_EXACT_NAMES,
					"blocked_shop_item_name_keywords": BLOCKED_SHOP_ITEM_NAME_KEYWORDS,
					"level_weights": LEVEL_WEIGHTS,
					"charge_bottle_appearance_item_names": CHARGE_BOTTLE_APPEARANCE_ITEM_NAMES,
					"charge_bottle_shop_item_names": CHARGE_BOTTLE_SHOP_ITEM_NAMES,
					"shop_item_count": SHOP_ITEM_COUNT,
					"build_tabs": BUILD_TABS,
				}
			)
		)
	return _shop_catalog_helper


func _get_shop_panel_controller():
	if _shop_panel_controller == null:
		_shop_panel_controller = SHOP_PANEL_CONTROLLER_SCRIPT.new()
	return _shop_panel_controller


func _get_shop_item_card_factory():
	if _shop_item_card_factory == null:
		_shop_item_card_factory = SHOP_ITEM_CARD_FACTORY_SCRIPT.new()
	return _shop_item_card_factory


func _get_observe_sync_service():
	if _observe_sync_service == null:
		_observe_sync_service = OBSERVE_SYNC_SERVICE_SCRIPT.new()
	return _observe_sync_service


func _get_equipment_effects_service():
	if _equipment_effects_service == null:
		_equipment_effects_service = (
			EQUIPMENT_EFFECTS_SERVICE_SCRIPT
			. new(
				{
					"default_build_name": "无派系",
					"build_alias_map": BUILD_ALIAS_MAP,
					"spark_force_item_names": SPARK_FORCE_ITEM_NAMES,
					"charge_build_name": CHARGE_BUILD_NAME,
					"coin_build_name": COIN_BUILD_NAME,
					"charge_stack_agility": CHARGE_STACK_AGILITY,
					"charge_staff_summon_bonus_per_stack": CHARGE_STAFF_SUMMON_BONUS_PER_STACK,
					"coin_button_attack_speed_per_layer": COIN_BUTTON_ATTACK_SPEED_PER_LAYER,
					"coin_smile_damage_tenths_per_coin_owned":
					COIN_SMILE_DAMAGE_TENTHS_PER_COIN_OWNED,
					"coin_gold_refresh_limit_per_item": COIN_GOLD_REFRESH_LIMIT_PER_ITEM,
					"coin_lucky_gold_per_trigger": COIN_LUCKY_GOLD_PER_TRIGGER,
					"coin_gold_gold_per_layer": COIN_GOLD_GOLD_PER_LAYER,
				}
			)
		)
	return _equipment_effects_service


func _get_ui_state():
	return _ui_state


func _shop_px(value: float) -> float:
	return value * SHOP_UI_SCALE


func _shop_px_i(value: int) -> int:
	return maxi(int(round(float(value) * SHOP_UI_SCALE)), 1)


func _append_icon_candidate(candidates: Array[String], candidate: String) -> void:
	var trimmed: String = candidate.strip_edges()
	if trimmed == "":
		return
	if not candidates.has(trimmed):
		candidates.append(trimmed)


func _build_item_icon_candidates(icon_name: String) -> Array[String]:
	var candidates: Array[String] = []
	var trimmed: String = icon_name.strip_edges()
	if trimmed == "":
		_append_icon_candidate(candidates, ITEM_ICON_FALLBACK_PATH)
		return candidates
	var icon_file: String = trimmed.get_file()
	if icon_file == "":
		icon_file = trimmed
	_append_icon_candidate(candidates, trimmed)
	_append_icon_candidate(candidates, icon_file)
	var base_name: String = icon_file.get_basename()
	var extension: String = icon_file.get_extension().to_lower()
	if extension == "blp":
		_append_icon_candidate(candidates, "%s.png" % base_name)
		_append_icon_candidate(candidates, base_name)
	elif extension == "":
		for ext_variant in ITEM_ICON_EXTENSIONS:
			var ext: String = str(ext_variant)
			_append_icon_candidate(candidates, "%s.%s" % [icon_file, ext])
			_append_icon_candidate(candidates, "%s.%s" % [base_name, ext])
	else:
		_append_icon_candidate(candidates, base_name)
	return candidates


func _index_item_icons_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry: String = dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		if entry.get_extension().to_lower() == "import":
			continue
		var entry_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			_index_item_icons_recursive(entry_path)
			continue
		var file_key: String = entry.to_lower()
		if not _item_icon_lookup.has(file_key):
			_item_icon_lookup[file_key] = entry_path
		var base_key: String = entry.get_basename().to_lower()
		if not _item_icon_lookup.has(base_key):
			_item_icon_lookup[base_key] = entry_path
	dir.list_dir_end()


func _ensure_item_icon_lookup() -> void:
	if _item_icon_index_ready:
		return
	_item_icon_lookup.clear()
	for dir_variant in ITEM_ICON_SEARCH_DIRS:
		_index_item_icons_recursive(str(dir_variant))
	_item_icon_index_ready = true


func _resolve_item_icon_path(icon_name: String) -> String:
	var cache_key: String = icon_name.strip_edges()
	if _item_icon_resolve_cache.has(cache_key):
		return str(_item_icon_resolve_cache[cache_key])
	var candidates: Array[String] = _build_item_icon_candidates(icon_name)
	for candidate in candidates:
		if candidate.begins_with("res://") and ResourceLoader.exists(candidate):
			_item_icon_resolve_cache[cache_key] = candidate
			return candidate
	_ensure_item_icon_lookup()
	for candidate in candidates:
		var lookup_key: String = candidate.to_lower()
		if _item_icon_lookup.has(lookup_key):
			var resolved_path: String = str(_item_icon_lookup[lookup_key])
			_item_icon_resolve_cache[cache_key] = resolved_path
			return resolved_path
	if cache_key != "":
		_missing_item_icon_names[cache_key] = true
	_item_icon_resolve_cache[cache_key] = ITEM_ICON_FALLBACK_PATH
	return ITEM_ICON_FALLBACK_PATH


func _sanitize_item_icon_name(icon_name: String) -> String:
	return _resolve_item_icon_path(icon_name)


func _resource_file_exists(path: String) -> bool:
	var safe_path: String = path.strip_edges()
	if safe_path.is_empty():
		return false
	if FileAccess.file_exists(safe_path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(safe_path))


func _load_texture_resource_or_file(path: String) -> Texture2D:
	var safe_path: String = path.strip_edges()
	if safe_path.is_empty():
		return null
	if not _resource_file_exists(safe_path):
		return null
	if ResourceLoader.exists(safe_path, "Texture2D"):
		var tex_res: Resource = ResourceLoader.load(safe_path, "Texture2D")
		if tex_res is Texture2D:
			return tex_res as Texture2D
	var image := Image.new()
	var err: int = image.load(ProjectSettings.globalize_path(safe_path))
	if err != OK:
		err = image.load(safe_path)
		if err != OK:
			return null
	return ImageTexture.create_from_image(image)


func _load_item_texture(icon_name: String) -> Texture2D:
	var icon_path: String = _resolve_item_icon_path(icon_name)
	var tex := _load_texture_resource_or_file(icon_path)
	if tex == null:
		tex = _load_texture_resource_or_file(ITEM_ICON_FALLBACK_PATH)
	return tex


func _report_missing_item_icons() -> void:
	if _missing_item_icon_names.is_empty():
		return
	var missing_names: PackedStringArray = PackedStringArray()
	for missing_variant in _missing_item_icon_names.keys():
		missing_names.append(str(missing_variant))
	missing_names.sort()
	push_warning(
		"装备图标未匹配，已回退默认图标（%d）: %s" % [missing_names.size(), ", ".join(Array(missing_names))]
	)


func _normalize_build_name(raw_build_name: String) -> String:
	return _get_shop_catalog_helper().normalize_build_name(raw_build_name)


func _is_blocked_shop_build(build_name: String) -> bool:
	return _get_shop_catalog_helper().is_blocked_shop_build(build_name)


func _is_blocked_shop_item(item_data: Dictionary) -> bool:
	return _get_shop_catalog_helper().is_blocked_shop_item(item_data)


func _resolve_item_name(raw_item_name: String) -> String:
	return _get_shop_catalog_helper().resolve_item_name(raw_item_name)


func _resolve_item_build_name(
	item_name: String, raw_build_name: String, stat_text: String = ""
) -> String:
	return _get_shop_catalog_helper().resolve_item_build_name(item_name, raw_build_name, stat_text)


func _load_item_db_from_map_json() -> void:
	_item_icon_resolve_cache.clear()
	_missing_item_icon_names.clear()
	if not FileAccess.file_exists(ITEM_DB_MAP_JSON_PATH):
		return
	var file := FileAccess.open(ITEM_DB_MAP_JSON_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return
	var loaded: Array = []
	for row_variant in parsed:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var raw_item_name: String = str(row.get("name", "")).strip_edges()
		if raw_item_name == "":
			continue
		var item_name: String = _resolve_item_name(raw_item_name)
		var icon_name: String = _sanitize_item_icon_name(str(row.get("icon", "")))
		var stat_text: String = str(row.get("stat", "")).strip_edges()
		if stat_text == "":
			stat_text = "Lv1 | 地图装备"
		elif not stat_text.begins_with("Lv"):
			stat_text = "Lv1 | %s" % stat_text
		var build_name: String = _resolve_item_build_name(
			raw_item_name, str(row.get("build", "无派系")), stat_text
		)
		var loaded_item: Dictionary = {
			"name": item_name,
			"icon": icon_name,
			"stat": stat_text,
			"build": build_name,
		}
		if row.has("cost"):
			loaded_item["cost"] = maxi(_variant_to_int(row.get("cost", 0), 0), 0)
		loaded.append(loaded_item)
	if not loaded.is_empty():
		item_db = loaded
	_report_missing_item_icons()


func _create_default_destroy_faction_state() -> Dictionary:
	return _get_equipment_runtime_helper().create_default_destroy_faction_state()


func _create_default_coin_faction_state() -> Dictionary:
	return _get_equipment_runtime_helper().create_default_coin_faction_state()


func _sanitize_coin_faction_state(state_variant: Variant) -> Dictionary:
	return _get_equipment_runtime_helper().sanitize_coin_faction_state(state_variant)


func _sanitize_destroy_faction_state(state_variant: Variant) -> Dictionary:
	return _get_equipment_runtime_helper().sanitize_destroy_faction_state(state_variant)


func _get_item_name_by_index(item_idx: int) -> String:
	return _get_equipment_runtime_helper().get_item_name_by_index(item_db, item_idx)


func _create_default_inventory_meta_entry(item_idx: int = -1) -> Dictionary:
	return _get_equipment_runtime_helper().create_default_inventory_meta_entry(item_db, item_idx)


func _sanitize_inventory_meta_entry(entry_variant: Variant, item_idx: int = -1) -> Dictionary:
	return _get_equipment_runtime_helper().sanitize_inventory_meta_entry(
		item_db, entry_variant, item_idx
	)


func _sanitize_inventory_meta_array(meta_variant: Variant, inventory: Array) -> Array:
	return _get_equipment_runtime_helper().sanitize_inventory_meta_array(
		item_db, meta_variant, inventory
	)


func _get_inventory_meta_entry(meta_array: Array, slot_idx: int, item_idx: int = -1) -> Dictionary:
	return _get_equipment_runtime_helper().get_inventory_meta_entry(
		item_db, meta_array, slot_idx, item_idx
	)


func _set_inventory_meta_entry(
	meta_array: Array, slot_idx: int, entry: Dictionary, item_idx: int = -1
) -> void:
	_get_equipment_runtime_helper().set_inventory_meta_entry(
		item_db, meta_array, slot_idx, entry, item_idx
	)


func _get_effective_inventory_item_level(
	item_idx: int, slot_idx: int, meta_array: Array, inventory: Array = []
) -> int:
	return _get_equipment_runtime_helper().get_effective_inventory_item_level(
		item_db, item_idx, slot_idx, meta_array, inventory
	)


func _get_inventory_total_item_level(inventory: Array, meta_array: Array) -> int:
	return _get_equipment_runtime_helper().get_inventory_total_item_level(
		item_db, inventory, meta_array
	)


func _ensure_local_equipment_runtime_state() -> void:
	var inventory: Array = []
	if _hero_ctrl != null:
		inventory = _to_int_array(_hero_ctrl.get("inventory"))
	_equipment_inventory_meta = _sanitize_inventory_meta_array(_equipment_inventory_meta, inventory)
	_destroy_faction_state = _sanitize_destroy_faction_state(_destroy_faction_state)
	_coin_faction_state = _sanitize_coin_faction_state(_coin_faction_state)


func get_local_equipment_runtime_state() -> Dictionary:
	_ensure_local_equipment_runtime_state()
	return {
		"inventory_meta": _equipment_inventory_meta.duplicate(true),
		"destroy_faction_state": _destroy_faction_state.duplicate(true),
		"coin_faction_state": _coin_faction_state.duplicate(true),
	}


func _build_local_equipment_baseline_state() -> Dictionary:
	_ensure_local_equipment_runtime_state()
	var baseline: Dictionary = {
		"inventory_meta": _equipment_inventory_meta.duplicate(true),
		"destroy_faction_state": _destroy_faction_state.duplicate(true),
		"coin_faction_state": _coin_faction_state.duplicate(true),
		"gold": _gold,
		"shop_level": _shop_level,
		"shop_offer_ids": _shop_offered.duplicate(true),
		"destroy_mode": _destroy_mode,
	}
	if _hero_ctrl != null:
		baseline["inventory"] = _to_int_array(_hero_ctrl.get("inventory"))
		baseline["hero_level"] = int(_hero_ctrl.get("hero_level"))
	return baseline


func _estimate_hero_base_stats_for_state(
	state: Dictionary, destroy_state: Dictionary
) -> Dictionary:
	var hero_level: int = maxi(int(state.get("hero_level", 1)), 1)
	return {
		"strength":
		(
			int(
				round(
					(
						DESTROY_DEFAULT_STRENGTH_BASE
						+ DESTROY_DEFAULT_STRENGTH_GROWTH * float(hero_level - 1)
					)
				)
			)
			+ int(destroy_state.get("permanent_strength", 0))
		),
		"agility":
		(
			int(
				round(
					(
						DESTROY_DEFAULT_AGILITY_BASE
						+ DESTROY_DEFAULT_AGILITY_GROWTH * float(hero_level - 1)
					)
				)
			)
			+ int(destroy_state.get("permanent_agility", 0))
		),
		"intelligence":
		(
			int(
				round(
					(
						DESTROY_DEFAULT_INTELLIGENCE_BASE
						+ DESTROY_DEFAULT_INTELLIGENCE_GROWTH * float(hero_level - 1)
					)
				)
			)
			+ int(destroy_state.get("permanent_intelligence", 0))
		),
	}


func _get_destroy_runtime_bonus_bundle(
	inventory: Array, meta_array: Array, destroy_state: Dictionary
) -> Dictionary:
	var out: Dictionary = {
		"strength": maxi(int(destroy_state.get("permanent_strength", 0)), 0),
		"agility": maxi(int(destroy_state.get("permanent_agility", 0)), 0),
		"intelligence": maxi(int(destroy_state.get("permanent_intelligence", 0)), 0),
		"hp": maxi(int(destroy_state.get("permanent_hp", 0)), 0),
		"spell_damage_percent": 0.0,
	}
	for i in range(inventory.size()):
		var item_idx: int = int(inventory[i])
		var item_name: String = _get_item_name_by_index(item_idx)
		if item_name == "邪灵宝珠":
			out["spell_damage_percent"] = (
				float(out["spell_damage_percent"])
				+ (
					float(
						maxi(
							_get_effective_inventory_item_level(item_idx, i, meta_array, inventory),
							0
						)
					)
					* 4.0
				)
			)
	return out


func _build_inventory_tooltip_text(
	item_idx: int,
	slot_idx: int,
	meta_array: Array,
	destroy_state: Dictionary,
	coin_state: Dictionary = {}
) -> String:
	var item_name: String = _get_item_name_by_index(item_idx)
	if item_name == "":
		return ""
	var parts: Array[String] = [item_name]
	var entry: Dictionary = _get_inventory_meta_entry(meta_array, slot_idx, item_idx)
	match item_name:
		"空洞宝珠":
			parts.append("层数: %d/3" % maxi(int(entry.get("charges", 0)), 0))
			parts.append("献祭等级: %d" % maxi(int(entry.get("stored_level", 0)), 0))
		"通天锤":
			parts.append("层数: %d/6" % clampi(maxi(int(entry.get("charges", 0)), 0), 0, 5))
			var ready_loops: int = maxi(int(destroy_state.get("tongtian_bonus_loops", 0)), 0)
			if ready_loops > 0:
				parts.append("启智就绪: %d" % ready_loops)
		"血羽之心":
			parts.append(
				(
					"动态等级: %d"
					% maxi(
						int(entry.get("dynamic_level", _get_item_level(item_db[item_idx]))),
						_get_item_level(item_db[item_idx])
					)
				)
			)
		"邪灵宝珠":
			var evil_level: int = maxi(int(entry.get("dynamic_level", 0)), 0)
			parts.append("邪珠等级: %d" % evil_level)
			parts.append("额外法伤: +%d%%" % maxi(evil_level * 4, 0))
	if _is_charge_item_for_effects(item_db[item_idx]):
		var charge_count: int = maxi(int(entry.get("charges", 0)), 0)
		if charge_count > 0:
			parts.append("充能层数: %d" % charge_count)
		var permanent_agility: int = maxi(int(entry.get("permanent_agility", 0)), 0)
		if permanent_agility > 0:
			parts.append("永久敏捷: +%d" % permanent_agility)
		var permanent_hp: int = maxi(int(entry.get("permanent_hp", 0)), 0)
		if permanent_hp > 0:
			parts.append("永久生命: +%d" % permanent_hp)
		var permanent_spell_damage: int = maxi(
			int(entry.get("permanent_spell_damage_percent", 0)), 0
		)
		if permanent_spell_damage > 0:
			parts.append("永久法伤: +%d%%" % permanent_spell_damage)
		var permanent_range: int = maxi(int(entry.get("permanent_attack_range", 0)), 0)
		if permanent_range > 0:
			parts.append("永久射程: +%d" % permanent_range)
		var permanent_crit_damage: int = maxi(
			int(entry.get("permanent_physical_crit_multiplier", 0)), 0
		)
		if permanent_crit_damage > 0:
			parts.append("永久暴伤: +%d%%" % permanent_crit_damage)
		var particle_bonus: int = maxi(int(entry.get("particle_bonus_per_two_charges", 0)), 0)
		if particle_bonus > 0:
			parts.append("粒子加成: 每2层充能额外+%d敏捷" % particle_bonus)
		if item_name == "通灵杖" and charge_count > 0:
			parts.append(
				(
					"召唤攻击/射程: +%d%%"
					% int(round(float(charge_count) * CHARGE_STAFF_SUMMON_BONUS_PER_STACK))
				)
			)
	if _is_coin_item_for_effects(item_db[item_idx]):
		var coin_layers: int = maxi(int(entry.get("coin_layers", 0)), 0)
		parts.append("硬币层数: %d" % coin_layers)
		var coin_str: int = int(entry.get("permanent_strength", 0))
		var coin_agi: int = int(entry.get("permanent_agility", 0))
		var coin_int: int = int(entry.get("permanent_intelligence", 0))
		var coin_damage: int = (
			int(entry.get("permanent_damage", 0))
			+ int(int(entry.get("permanent_damage_tenths", 0)) / 10)
		)
		var coin_ias: int = int(entry.get("permanent_attack_speed_percent", 0))
		if coin_str != 0:
			parts.append("永久力量: %+d" % coin_str)
		if coin_agi != 0:
			parts.append("永久敏捷: %+d" % coin_agi)
		if coin_int != 0:
			parts.append("永久智力: %+d" % coin_int)
		if coin_damage != 0:
			parts.append("永久攻击: %+d" % coin_damage)
		if coin_ias != 0:
			parts.append("永久攻速: %+d%%" % coin_ias)
		var deferred_child_count: int = maxi(int(entry.get("deferred_child_coin_on_destroy", 0)), 0)
		if deferred_child_count > 0:
			parts.append("摧毁时提供子币: %d" % deferred_child_count)
		if item_name == "金硬币":
			var auto_destroy_enabled: bool = _variant_to_bool(
				coin_state.get("auto_destroy_coin_enabled", false), false
			)
			parts.append("自动摧毁硬币: %s" % ("开启" if auto_destroy_enabled else "关闭"))
	if _is_charge_active_item_name(item_name):
		parts.append("右键主动使用")
	if item_name == "纪念币" or item_name == "金硬币":
		parts.append("右键主动使用")
	return "\n".join(parts)


func _update_shop_debug_overlay() -> void:
	if _shop_debug_label == null:
		return
	_shop_debug_label.visible = _debug_shop_click_logs
	if not _debug_shop_click_logs:
		return
	var self_peer_id: int = int(_get_ui_state().self_peer_id)
	var local_owner_peer_id: int = _get_local_shop_owner_peer_id()
	if self_peer_id <= 0:
		self_peer_id = local_owner_peer_id
	var net_mode_debug: String = ""
	if _net_ctrl != null:
		net_mode_debug = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
	var owners_text: String = "-"
	var right_top_owner: int = -1
	var scene_root: Node = _owner.get_parent() if _owner != null else null
	if scene_root != null and scene_root.has_method("debug_get_shop_owner_peer_ids"):
		var owners_variant: Variant = scene_root.call("debug_get_shop_owner_peer_ids")
		if owners_variant is Array:
			var owners: Array = owners_variant
			owners_text = str(owners)
			if owners.size() > 1:
				right_top_owner = int(owners[1])
	var ray_text: String = "-"
	if _hero_ctrl != null:
		ray_text = str(_hero_ctrl.get("shop_click_debug_last_result"))
	_shop_debug_label.text = (
		"shop_debug mode=%s self=%d local_owner=%d active_owner=%d observed=%d visible=%s\nowners=%s right_top_owner=%d\nlast_click=%s ray=%s"
		% [
			net_mode_debug,
			self_peer_id,
			local_owner_peer_id,
			_get_active_shop_owner_peer_id(),
			int(_get_ui_state().observed_peer_id),
			"true" if _shop_visible else "false",
			owners_text,
			right_top_owner,
			_last_shop_click_debug_text,
			ray_text
		]
	)


func _variant_to_float(value: Variant, fallback: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is String:
		var text: String = (value as String).strip_edges()
		if text.is_valid_float():
			return text.to_float()
	return fallback


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


func _is_observing_boss() -> bool:
	return _get_ui_state().is_observing_boss()


func _is_observing_enemy() -> bool:
	return _get_ui_state().is_observing_enemy()


func _update_inventory_panel_visibility() -> void:
	if _inventory_panel_root == null:
		return
	_inventory_panel_root.visible = not (_is_observing_boss() or _is_observing_enemy())


func _update_skill_panel_visibility() -> void:
	if _command_panel_root == null:
		return
	var show_local_skill_panel: bool = (
		not _is_observing_remote() and not _is_observing_boss() and not _is_observing_enemy()
	)
	_command_panel_root.visible = show_local_skill_panel


func _is_observing_remote() -> bool:
	return _get_ui_state().is_observing_remote()


func _get_observed_hero_state() -> Dictionary:
	return _get_ui_state().get_observed_hero_state()


func _get_observed_equipment_state() -> Dictionary:
	return _get_ui_state().get_observed_equipment_state()


func _check_shop_click() -> void:
	if not _shop_access_enabled:
		return
	if _hero_ctrl == null:
		return
	var clicked = _hero_ctrl.get("shop_clicked")
	if clicked == true:
		_hero_ctrl.set("shop_clicked", false)
		var clicked_owner_peer_id: int = maxi(
			_variant_to_int(_hero_ctrl.get("shop_clicked_owner_peer_id"), 0), 0
		)
		_hero_ctrl.set("shop_clicked_owner_peer_id", 0)
		var local_owner_peer_id: int = _get_local_shop_owner_peer_id()
		var is_local_shop_click: bool = (
			clicked_owner_peer_id > 0
			and local_owner_peer_id > 0
			and clicked_owner_peer_id == local_owner_peer_id
		)
		_last_shop_click_debug_text = (
			"clicked=%d local=%d allow=%s"
			% [
				clicked_owner_peer_id,
				local_owner_peer_id,
				"true" if is_local_shop_click else "false"
			]
		)
		if _debug_shop_click_logs:
			var self_peer_id_debug: int = int(_get_ui_state().self_peer_id)
			if self_peer_id_debug <= 0:
				self_peer_id_debug = local_owner_peer_id
			var net_mode_debug: String = ""
			if _net_ctrl != null:
				net_mode_debug = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
			print(
				(
					"[shop-click] self=%d local_owner=%d clicked_owner=%d allow=%s mode=%s"
					% [
						self_peer_id_debug,
						local_owner_peer_id,
						clicked_owner_peer_id,
						"true" if is_local_shop_click else "false",
						net_mode_debug
					]
				)
			)
		if not is_local_shop_click:
			_active_shop_owner_peer_id = 0
			if _shop_visible:
				_shop_visible = false
				_get_shop_panel_controller().set_visible(false)
				_clear_shop_item_hover_state()
				_notify_input_lock_changed()
			return
		_active_shop_owner_peer_id = clicked_owner_peer_id
		_request_clear_observed_peer()
		if not _shop_visible:
			_toggle_shop()
		else:
			_update_shop_info()
			_populate_offered_items()


func _toggle_shop() -> void:
	if not _shop_access_enabled:
		if _shop_visible:
			_shop_visible = false
			_get_shop_panel_controller().set_visible(false)
			_clear_shop_item_hover_state()
			_active_shop_owner_peer_id = 0
			_notify_input_lock_changed()
		return
	_shop_visible = not _shop_visible
	_get_shop_panel_controller().set_visible(_shop_visible)
	_notify_input_lock_changed()
	if _shop_visible:
		_update_shop_info()
		_populate_offered_items()
	else:
		_clear_shop_item_hover_state()
		_active_shop_owner_peer_id = 0


func set_shop_access_enabled(enabled: bool) -> void:
	_shop_access_enabled = bool(enabled)
	if not _shop_access_enabled and _shop_visible:
		_shop_visible = false
		_get_shop_panel_controller().set_visible(false)
		_clear_shop_item_hover_state()
		_active_shop_owner_peer_id = 0
		_notify_input_lock_changed()


func _build_shop_panel(root: Control) -> void:
	_get_shop_panel_controller().build(
		root,
		SHOP_UI_SCALE,
		COLOR_BORDER,
		COLOR_BORDER_DARK,
		COLOR_TEXT,
		SHOP_ITEM_DETAIL_WIDTH,
		SHOP_ITEM_DETAIL_MIN_HEIGHT,
		SHOP_ITEM_DETAIL_MAX_HEIGHT,
		SHOP_ITEM_DETAIL_EST_CHARS_PER_LINE,
		Callable(self, "_toggle_shop"),
		Callable(self, "_on_upgrade_shop"),
		Callable(self, "_on_refresh_pressed")
	)
	_roll_shop_items()
	_populate_offered_items()


func _clear_shop_item_hover_state() -> void:
	_get_shop_panel_controller().clear_item_hover_state()


func _on_shop_item_mouse_entered(item_panel: Control, detail_text: String) -> void:
	_get_shop_panel_controller().on_item_mouse_entered(
		item_panel, detail_text, SHOP_ITEM_DETAIL_HOVER_DELAY_SEC
	)


func _on_shop_item_mouse_exited(item_panel: Control) -> void:
	if item_panel == null:
		return
	_get_shop_panel_controller().on_item_mouse_exited(item_panel, _get_viewport_mouse_position())


func _get_item_level(item: Dictionary) -> int:
	return _get_shop_catalog_helper().get_item_level(item)


func _get_shop_item_cost(item_data: Dictionary) -> int:
	if item_data.is_empty():
		return 50
	var explicit_cost: int = _variant_to_int(item_data.get("cost", -1), -1)
	if explicit_cost >= 0:
		return explicit_cost
	var item_level: int = _get_item_level(item_data)
	return int(ITEM_COST.get(item_level, 50))


func _get_shop_item_cost_by_index(item_idx: int) -> int:
	if item_idx < 0 or item_idx >= item_db.size():
		return 50
	var item_data: Dictionary = item_db[item_idx] if item_db[item_idx] is Dictionary else {}
	return _get_shop_item_cost(item_data)


func _get_local_shop_owner_peer_id() -> int:
	var self_peer_id: int = int(_get_ui_state().self_peer_id)
	if self_peer_id > 0:
		return self_peer_id
	_resolve_net_ctrl()
	if _net_ctrl != null and _net_ctrl.has_method("get_ui_self_peer_id"):
		var peer_id_variant: Variant = _net_ctrl.call("get_ui_self_peer_id")
		var peer_id: int = int(peer_id_variant)
		if peer_id > 0:
			return peer_id
	var net_mode: String = ""
	if _net_ctrl != null:
		net_mode = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
	if net_mode == "host":
		return 1
	if net_mode == "client":
		return 2
	return 1


func _get_active_shop_owner_peer_id() -> int:
	if _active_shop_owner_peer_id > 0:
		return _active_shop_owner_peer_id
	return 0


func _is_active_shop_owned_by_local() -> bool:
	var active_owner_peer_id: int = _get_active_shop_owner_peer_id()
	return active_owner_peer_id > 0 and active_owner_peer_id == _get_local_shop_owner_peer_id()


func _is_shop_action(action: String) -> bool:
	var action_text: String = action.strip_edges().to_lower()
	return (
		action_text == "buy_item" or action_text == "refresh_shop" or action_text == "upgrade_shop"
	)


func _is_shop_action_pending() -> bool:
	if _pending_shop_action.is_empty():
		return false
	if not _should_sync_local_shop_offers_from_authority():
		_pending_shop_action = ""
		return false
	return true


func _refresh_shop_panel_state() -> void:
	if _shop_panel_controller == null:
		return
	_populate_offered_items()
	_update_shop_info()


func _set_shop_action_pending(action: String) -> void:
	if not _is_shop_action(action):
		return
	_pending_shop_action = action.strip_edges().to_lower()
	_refresh_shop_panel_state()


func _clear_shop_action_pending(refresh_ui: bool = true) -> void:
	var had_pending: bool = not _pending_shop_action.is_empty()
	_pending_shop_action = ""
	if had_pending and refresh_ui:
		_refresh_shop_panel_state()


func _can_operate_current_shop() -> bool:
	if _is_observing_boss() or _is_observing_enemy():
		return false
	if _is_observing_remote():
		return false
	return _is_active_shop_owned_by_local()


func _get_shop_state_for_owner(owner_peer_id: int) -> Dictionary:
	if owner_peer_id <= 0:
		return {}
	if owner_peer_id == _get_local_shop_owner_peer_id():
		return {"shop_level": _shop_level, "gold": _gold, "shop_offer_ids": _shop_offered}
	if _is_observing_remote() and int(_get_ui_state().observed_peer_id) == owner_peer_id:
		var observed_state: Dictionary = _get_observed_equipment_state()
		if not observed_state.is_empty():
			return observed_state
	_resolve_net_ctrl()
	if _net_ctrl != null and _net_ctrl.has_method("get_ui_peer_equipment_state"):
		var state_variant: Variant = _net_ctrl.call("get_ui_peer_equipment_state", owner_peer_id)
		if state_variant is Dictionary:
			return state_variant as Dictionary
	return {}


func _get_display_shop_offer_ids() -> Array[int]:
	if _is_active_shop_owned_by_local():
		var local_offers: Array[int] = _to_int_array(_shop_offered)
		if not local_offers.is_empty():
			return local_offers
		if not _should_sync_local_shop_offers_from_authority():
			return local_offers
		var authority_state: Dictionary = _get_local_authority_shop_state()
		var authority_offers: Array[int] = _to_int_array(authority_state.get("shop_offer_ids", []))
		if not authority_offers.is_empty():
			_shop_level = clampi(int(authority_state.get("shop_level", _shop_level)), 1, 7)
			_gold = maxi(int(authority_state.get("gold", _gold)), 0)
			_set_shop_offered_from_variant(authority_offers)
			return _to_int_array(_shop_offered)
		return local_offers
	var owner_state: Dictionary = _get_shop_state_for_owner(_get_active_shop_owner_peer_id())
	return _to_int_array(owner_state.get("shop_offer_ids", []))


func _should_sync_local_shop_offers_from_authority() -> bool:
	_resolve_net_ctrl()
	if _net_ctrl == null:
		return false
	var net_mode: String = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
	return net_mode == "client"


func _get_local_authority_shop_state() -> Dictionary:
	_resolve_net_ctrl()
	if _net_ctrl == null:
		return {}
	if (
		not _net_ctrl.has_method("get_ui_self_peer_id")
		or not _net_ctrl.has_method("get_ui_peer_equipment_state")
	):
		return {}
	var self_peer_id: int = int(_net_ctrl.call("get_ui_self_peer_id"))
	if self_peer_id <= 0:
		return {}
	var state_variant: Variant = _net_ctrl.call("get_ui_peer_equipment_state", self_peer_id)
	if state_variant is Dictionary:
		return state_variant as Dictionary
	return {}


func _set_shop_offered_from_variant(values_variant: Variant) -> void:
	var next_offers: Array[int] = _to_int_array(values_variant)
	_shop_offered.clear()
	for offer_id in next_offers:
		if offer_id < 0 or offer_id >= item_db.size():
			continue
		if _is_blocked_shop_item(item_db[offer_id]):
			continue
		if offer_id in _shop_offered:
			continue
		_shop_offered.append(offer_id)


func _update_shop_info() -> void:
	var display_shop_level: int = _shop_level
	var display_gold: int = _gold
	var active_owner_peer_id: int = _get_active_shop_owner_peer_id()
	var is_local_shop: bool = _is_active_shop_owned_by_local()
	if not is_local_shop:
		var owner_state: Dictionary = _get_shop_state_for_owner(active_owner_peer_id)
		if not owner_state.is_empty():
			display_shop_level = maxi(int(owner_state.get("shop_level", _shop_level)), 1)
			display_gold = int(owner_state.get("gold", _gold))
	var stars := ""
	for i in range(7):
		stars += "★" if i < display_shop_level else "☆"
	var owner_text: String = ""
	if is_local_shop:
		owner_text = "（玩家P%d）" % _get_local_shop_owner_peer_id()
	elif active_owner_peer_id > 0:
		owner_text = "（玩家P%d）" % active_owner_peer_id
	var level_text: String = "商店等级: %s Lv%d %s" % [stars, display_shop_level, owner_text]
	var gold_text: String = "金币: %d" % display_gold
	var can_operate: bool = _can_operate_current_shop()
	var shop_action_pending: bool = can_operate and _is_shop_action_pending()
	var upgrade_text: String = ""
	var upgrade_disabled: bool = true
	if not can_operate:
		upgrade_text = "观战中"
		upgrade_disabled = true
	elif shop_action_pending:
		upgrade_text = "Syncing..."
		upgrade_disabled = true
	elif _shop_level >= 7:
		upgrade_text = "已满级"
		upgrade_disabled = true
	else:
		var cost: int = SHOP_UPGRADE_COST[_shop_level]
		upgrade_text = "升级商店 (%d金)" % cost
		upgrade_disabled = _gold < cost
	var refresh_text: String = ""
	var refresh_disabled: bool = true
	if not can_operate:
		refresh_text = "观战中"
		refresh_disabled = true
	elif shop_action_pending:
		refresh_text = "Syncing..."
		refresh_disabled = true
	else:
		refresh_text = "刷新商品 (%d金)" % SHOP_REFRESH_COST
		refresh_disabled = _gold < SHOP_REFRESH_COST
	_get_shop_panel_controller().update_summary(level_text, gold_text)
	_get_shop_panel_controller().update_action_buttons(
		upgrade_text, upgrade_disabled, refresh_text, refresh_disabled
	)


func _roll_shop_items() -> void:
	var local_inventory: Array = []
	if _hero_ctrl != null:
		local_inventory = _to_int_array(_hero_ctrl.get("inventory"))
	_shop_offered = _get_shop_catalog_helper().roll_shop_offer_ids(
		_shop_level, item_db, local_inventory
	)


func _is_shop_offer_before_for_display(left_idx: int, right_idx: int) -> bool:
	return _get_shop_catalog_helper().is_shop_offer_before_for_display(left_idx, right_idx, item_db)


func _get_shop_build_sort_rank(build_name: String) -> int:
	return _get_shop_catalog_helper().get_shop_build_sort_rank(build_name)


func _sorted_shop_offer_ids_for_display(offer_ids: Array[int]) -> Array[int]:
	return _get_shop_catalog_helper().sort_shop_offer_ids_for_display(offer_ids, item_db)


func _populate_offered_items() -> void:
	_clear_shop_item_hover_state()
	var offered_grid: GridContainer = _get_shop_panel_controller().get_offered_grid()
	if offered_grid == null:
		return
	for child in offered_grid.get_children():
		child.queue_free()
	var display_offers: Array[int] = _sorted_shop_offer_ids_for_display(
		_get_display_shop_offer_ids()
	)
	var can_buy_items: bool = _can_operate_current_shop()
	for idx in display_offers:
		var item: Dictionary = item_db[idx]
		var card := _create_shop_item(item, idx, can_buy_items)
		offered_grid.add_child(card)


func _on_refresh_pressed() -> void:
	if _is_shop_action_pending():
		return
	if not _can_operate_current_shop():
		return
	if _request_authority_equipment_action("refresh_shop"):
		return
	if _gold < SHOP_REFRESH_COST:
		return
	_ensure_local_equipment_runtime_state()
	_gold -= SHOP_REFRESH_COST
	var inv: Array = _get_display_inventory()
	if not _can_refresh_with_coin_rules(inv, _coin_faction_state):
		_gold += SHOP_REFRESH_COST
		return
	_apply_charge_refresh_effects(inv, _equipment_inventory_meta)
	_roll_shop_items()
	_apply_coin_refresh_effects(
		inv, _equipment_inventory_meta, _coin_faction_state, _shop_offered, _shop_level
	)
	_refresh_inventory()
	_populate_offered_items()
	_update_shop_info()


func _on_upgrade_shop() -> void:
	if _is_shop_action_pending():
		return
	if not _can_operate_current_shop():
		return
	if _request_authority_equipment_action("upgrade_shop"):
		return
	if _shop_level >= 7:
		return
	var cost: int = SHOP_UPGRADE_COST[_shop_level]
	if _gold < cost:
		return
	_gold -= cost
	_shop_level += 1
	_populate_offered_items()
	_update_shop_info()


func _request_authority_equipment_action(action: String, payload: Dictionary = {}) -> bool:
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		return false
	_resolve_net_ctrl()
	if _net_ctrl == null:
		return false
	var normalized_action: String = action.strip_edges().to_lower()
	var is_shop_action_request: bool = _is_shop_action(normalized_action)
	var net_mode: String = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
	if net_mode == "client":
		if is_shop_action_request and _is_shop_action_pending():
			return true
		if _net_ctrl.has_method("request_equipment_action"):
			var request_payload_client: Dictionary = payload.duplicate(true)
			var sent_variant: Variant = _net_ctrl.call(
				"request_equipment_action", normalized_action, request_payload_client
			)
			var sent_ok: bool = _variant_to_bool(sent_variant, false)
			if sent_ok and is_shop_action_request:
				_set_shop_action_pending(normalized_action)
			return true
		return true
	return _apply_local_authority_equipment_action(normalized_action, payload)


func _get_local_authority_peer_id() -> int:
	var self_peer_id: int = int(_get_ui_state().self_peer_id)
	if self_peer_id > 0:
		return self_peer_id
	if _owner != null and _owner.multiplayer.multiplayer_peer != null:
		var peer_id: int = _owner.multiplayer.get_unique_id()
		if peer_id > 0:
			return peer_id
	return 1


func _apply_local_authority_equipment_action(action: String, payload: Dictionary = {}) -> bool:
	var peer_id: int = _get_local_authority_peer_id()
	var request: Dictionary = {
		"action": action.strip_edges().to_lower(),
		"request_seq": -1,
		"payload": payload.duplicate(true),
	}
	var baseline_state: Dictionary = _build_local_equipment_baseline_state()
	var commit: Dictionary = authority_handle_equipment_action(peer_id, request, baseline_state)
	if commit.is_empty():
		return false
	apply_authoritative_equipment_commit(commit)
	return true


func _get_build_color(build_name: String) -> Color:
	var normalized_build: String = _normalize_build_name(build_name)
	match normalized_build:
		"初始":
			return Color(0.6, 0.8, 0.6, 1.0)
		"过渡":
			return Color(0.7, 0.7, 0.7, 1.0)
		"摧毁":
			return Color(0.9, 0.3, 0.9, 1.0)
		"贷款", "负债":
			return Color(1.0, 0.85, 0.2, 1.0)
		"三月":
			return Color(0.5, 0.8, 1.0, 1.0)
		"灵魂":
			return Color(0.45, 0.9, 0.6, 1.0)
		"灵瓮":
			return Color(0.45, 0.9, 0.6, 1.0)
		"传火":
			return Color(1.0, 0.5, 0.2, 1.0)
		"齿轮":
			return Color(0.8, 0.8, 0.8, 1.0)
		"神器":
			return Color(0.95, 0.78, 0.25, 1.0)
		"泰坦":
			return Color(0.85, 0.65, 0.25, 1.0)
		"通灵":
			return Color(0.45, 0.85, 0.75, 1.0)
		"自动":
			return Color(0.6, 0.6, 0.6, 1.0)
		"战旗":
			return Color(0.2, 0.9, 0.5, 1.0)
		"备战":
			return Color(0.95, 0.55, 0.25, 1.0)
		"结算":
			return Color(0.9, 0.6, 0.2, 1.0)
		"充能":
			return Color(0.3, 0.7, 1.0, 1.0)
		"咒文":
			return Color(0.7, 0.4, 1.0, 1.0)
		"火花":
			return Color(1.0, 0.4, 0.2, 1.0)
		"特摧":
			return Color(1.0, 0.2, 0.6, 1.0)
		"硬币":
			return Color(1.0, 0.9, 0.3, 1.0)
		"诅咒":
			return Color(0.8, 0.2, 0.2, 1.0)
		"邪能":
			return Color(0.6, 0.2, 0.8, 1.0)
		"消耗":
			return Color(0.4, 0.8, 0.8, 1.0)
		"配件":
			return Color(0.8, 0.6, 0.3, 1.0)
		"后期":
			return Color(1.0, 0.3, 0.3, 1.0)
		"无派系":
			return Color(0.75, 0.75, 0.75, 1.0)
		_:
			return COLOR_TEXT


func _build_shop_item_tooltip(data: Dictionary, cost: int) -> String:
	var level: int = _get_item_level(data)
	var build_name: String = _normalize_build_name(str(data.get("build", "未知")))
	var item_name: String = str(data.get("name", "未知装备"))
	var stat_text: String = str(data.get("stat", ""))
	return "【%s】%s\n等级: Lv%d\n价格: %d金\n\n%s" % [build_name, item_name, level, cost, stat_text]


func _create_shop_item(data: Dictionary, index: int, can_buy: bool) -> PanelContainer:
	var build_name: String = _normalize_build_name(str(data.get("build", "无派系")))
	var build_color: Color = _get_build_color(build_name)
	var item_lv := _get_item_level(data)
	var cost: int = _get_shop_item_cost(data)
	var tooltip_text: String = _build_shop_item_tooltip(data, cost)
	var tex := _load_item_texture(str(data.get("icon", "")))
	var buy_disabled: bool = can_buy and _is_shop_action_pending()
	return _get_shop_item_card_factory().create_card(
		data,
		index,
		can_buy,
		buy_disabled,
		SHOP_UI_SCALE,
		build_name,
		build_color,
		item_lv,
		cost,
		tex,
		tooltip_text,
		Callable(self, "_on_buy_item"),
		Callable(self, "_on_shop_item_mouse_entered"),
		Callable(self, "_on_shop_item_mouse_exited")
	)


func _on_buy_item(index: int) -> void:
	if _is_shop_action_pending():
		return
	if not _can_operate_current_shop():
		return
	if _request_authority_equipment_action("buy_item", {"item_idx": index}):
		return
	if _hero_ctrl == null:
		return
	_ensure_local_equipment_runtime_state()
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if not (inv_variant is Array):
		return
	var inv: Array = inv_variant
	var item_data: Dictionary = item_db[index]
	if _is_blocked_shop_item(item_data):
		_shop_offered.erase(index)
		_populate_offered_items()
		return
	var item_name: String = _normalize_item_name_for_effects(item_data)
	var is_auto_consume_charge_bottle: bool = _is_charge_bottle_item_name(item_name)
	var is_coin_item: bool = _is_coin_item_for_effects(item_data)
	var auto_destroy_coin_purchase: bool = (
		is_coin_item
		and item_name != "金硬币"
		and _variant_to_bool(_coin_faction_state.get("auto_destroy_coin_enabled", false), false)
	)
	if inv.size() >= 6 and not is_auto_consume_charge_bottle and not auto_destroy_coin_purchase:
		return
	var cost: int = _get_shop_item_cost(item_data)
	if _gold < cost:
		return
	_gold -= cost
	inv.append(index)
	_equipment_inventory_meta.append(_create_default_inventory_meta_entry(index))
	_apply_charge_item_gain_effects(inv, _equipment_inventory_meta, index)
	if is_coin_item:
		_apply_coin_item_gain_effects(inv, _equipment_inventory_meta, _coin_faction_state, index)
	if is_auto_consume_charge_bottle:
		var remove_idx: int = inv.rfind(index)
		if remove_idx >= 0:
			inv.remove_at(remove_idx)
			if remove_idx < _equipment_inventory_meta.size():
				_equipment_inventory_meta.remove_at(remove_idx)
	if auto_destroy_coin_purchase:
		var auto_remove_idx: int = inv.rfind(index)
		if auto_remove_idx >= 0:
			inv.remove_at(auto_remove_idx)
			if auto_remove_idx < _equipment_inventory_meta.size():
				_equipment_inventory_meta.remove_at(auto_remove_idx)
	_shop_offered.erase(index)
	_try_synthesize()
	_refresh_inventory()
	_populate_offered_items()
	_update_shop_info()


func apply_authoritative_equipment_commit(commit: Dictionary) -> void:
	if commit.is_empty():
		return
	var previous_inventory: Array = []
	if _hero_ctrl != null:
		previous_inventory = _to_int_array(_hero_ctrl.get("inventory"))
	var action: String = str(commit.get("action", "")).strip_edges().to_lower()
	var commit_ok: bool = _variant_to_bool(commit.get("ok", true), true)
	var payload: Dictionary = {}
	var payload_variant: Variant = commit.get("payload", {})
	if payload_variant is Dictionary:
		payload = payload_variant as Dictionary
	var destroyed_slot_idx: int = int(payload.get("slot_idx", -1))
	var state_variant: Variant = commit.get("state", null)
	if not (state_variant is Dictionary):
		_clear_inventory_display_override()
		_clear_shop_action_pending()
		return
	_clear_shop_action_pending(false)
	var state: Dictionary = state_variant as Dictionary
	var inv: Array = _to_int_array(state.get("inventory", []))
	_equipment_inventory_meta = _sanitize_inventory_meta_array(state.get("inventory_meta", []), inv)
	_destroy_faction_state = _sanitize_destroy_faction_state(state.get("destroy_faction_state", {}))
	_coin_faction_state = _sanitize_coin_faction_state(state.get("coin_faction_state", {}))
	var next_destroy_mode: bool = _variant_to_bool(
		state.get("destroy_mode", _destroy_mode), _destroy_mode
	)
	if _hero_ctrl != null:
		_hero_ctrl.set("inventory", inv)
		if _hero_ctrl.has_method("set_destroy_cursor_mode"):
			_hero_ctrl.call("set_destroy_cursor_mode", next_destroy_mode)
	_gold = int(state.get("gold", _gold))
	_shop_level = clampi(int(state.get("shop_level", _shop_level)), 1, 7)
	_set_shop_offered_from_variant(state.get("shop_offer_ids", _shop_offered))
	_destroy_mode = next_destroy_mode
	_destroy_hover_index = -1
	if action == "destroy_item" and commit_ok:
		var stable_result: Dictionary = _build_destroy_stable_inventory_view(
			previous_inventory, inv, destroyed_slot_idx
		)
		var stable_view: Array = _to_int_array(stable_result.get("display", []))
		var stable_slot_map: Array = _to_int_array(stable_result.get("slot_map", []))
		if not stable_view.is_empty() and stable_view.size() == stable_slot_map.size():
			_inventory_display_override = stable_view
			_inventory_display_override_slot_map = stable_slot_map
			_inventory_display_override_signature = _build_inventory_signature(inv)
		else:
			_clear_inventory_display_override()
	else:
		_clear_inventory_display_override()
	_last_inventory_signature = ""
	_refresh_inventory()
	var offered_grid: GridContainer = _get_shop_panel_controller().get_offered_grid()
	if offered_grid != null and is_instance_valid(offered_grid):
		_populate_offered_items()
	_update_shop_info()
	_update_destroy_visual()
	_sync_destroy_hover_cursor()


func _to_int_array(values_variant: Variant) -> Array[int]:
	var out: Array[int] = []
	if values_variant is Array:
		var values: Array = values_variant
		for value in values:
			out.append(int(value))
	return out


func _clear_inventory_display_override() -> void:
	_inventory_display_override.clear()
	_inventory_display_override_slot_map.clear()
	_inventory_display_override_signature = ""


func _is_inventory_display_override_active(real_inventory: Array) -> bool:
	if _inventory_display_override.is_empty():
		return false
	var current_signature: String = _build_inventory_signature(real_inventory)
	if current_signature != _inventory_display_override_signature:
		_clear_inventory_display_override()
		return false
	return true


func _resolve_inventory_real_slot(display_slot_idx: int, real_inventory: Array) -> int:
	if display_slot_idx < 0:
		return -1
	if not _is_inventory_display_override_active(real_inventory):
		return display_slot_idx
	if display_slot_idx >= _inventory_display_override_slot_map.size():
		return -1
	return int(_inventory_display_override_slot_map[display_slot_idx])


func _build_destroy_stable_inventory_view(
	previous_inventory_variant: Variant, next_inventory_variant: Variant, destroyed_slot_idx: int
) -> Dictionary:
	var previous_inventory: Array = _to_int_array(previous_inventory_variant)
	var next_inventory: Array = _to_int_array(next_inventory_variant)
	if destroyed_slot_idx < 0 or destroyed_slot_idx >= previous_inventory.size():
		return {}
	var display_size: int = clampi(max(previous_inventory.size(), next_inventory.size()), 0, 6)
	if display_size <= 0:
		return {}
	var display_inventory: Array = []
	var display_slot_map: Array = []
	for _idx in range(display_size):
		display_inventory.append(-1)
		display_slot_map.append(-1)
	var slots_by_item: Dictionary = {}
	for real_slot_idx in range(next_inventory.size()):
		var item_idx: int = int(next_inventory[real_slot_idx])
		if not slots_by_item.has(item_idx):
			slots_by_item[item_idx] = []
		var slot_list: Array = slots_by_item[item_idx]
		slot_list.append(real_slot_idx)
		slots_by_item[item_idx] = slot_list
	var consumed_real_slots: Dictionary = {}
	for slot_idx in range(previous_inventory.size()):
		if slot_idx == destroyed_slot_idx or slot_idx >= display_size:
			continue
		var item_idx: int = int(previous_inventory[slot_idx])
		var available_slots: Array = slots_by_item.get(item_idx, [])
		if available_slots.is_empty():
			continue
		var real_slot_idx: int = int(available_slots[0])
		available_slots.remove_at(0)
		slots_by_item[item_idx] = available_slots
		display_inventory[slot_idx] = item_idx
		display_slot_map[slot_idx] = real_slot_idx
		consumed_real_slots[real_slot_idx] = true
	var next_empty_display_slot: int = 0
	for real_slot_idx in range(next_inventory.size()):
		if consumed_real_slots.has(real_slot_idx):
			continue
		while (
			next_empty_display_slot < display_inventory.size()
			and int(display_slot_map[next_empty_display_slot]) >= 0
		):
			next_empty_display_slot += 1
		if next_empty_display_slot < display_inventory.size():
			display_inventory[next_empty_display_slot] = int(next_inventory[real_slot_idx])
			display_slot_map[next_empty_display_slot] = real_slot_idx
			next_empty_display_slot += 1
			continue
		if display_inventory.size() >= 6:
			break
		display_inventory.append(int(next_inventory[real_slot_idx]))
		display_slot_map.append(real_slot_idx)
	return {"display": display_inventory, "slot_map": display_slot_map}


func _find_item_index_by_name(item_name: String) -> int:
	for i in range(item_db.size()):
		if item_db[i]["name"] == item_name:
			return i
	return -1


func _sum_regex_int(text: String, pattern: String) -> int:
	var regex := RegEx.new()
	var compile_err: int = regex.compile(pattern)
	if compile_err != OK:
		return 0
	var total: int = 0
	for match_variant in regex.search_all(text):
		var match := match_variant as RegExMatch
		if match == null:
			continue
		var value_text: String = match.get_string(1)
		if value_text != "":
			total += int(value_text)
	return total


func _sum_regex_float(text: String, pattern: String) -> float:
	var regex := RegEx.new()
	var compile_err: int = regex.compile(pattern)
	if compile_err != OK:
		return 0.0
	var total: float = 0.0
	for match_variant in regex.search_all(text):
		var match := match_variant as RegExMatch
		if match == null:
			continue
		var value_text: String = match.get_string(1)
		if value_text == "":
			continue
		total += float(value_text)
	return total


func _normalize_item_name_for_effects(item_data: Dictionary) -> String:
	return str(item_data.get("name", "")).strip_edges()


func _count_named_items(count_by_name: Dictionary, names: Array) -> int:
	var total: int = 0
	for name_variant in names:
		total += int(count_by_name.get(str(name_variant), 0))
	return total


func _is_charge_item_for_effects(item_data: Dictionary) -> bool:
	return _normalize_build_name(str(item_data.get("build", "无派系"))) == CHARGE_BUILD_NAME


func _is_charge_bottle_item_name(item_name: String) -> bool:
	return CHARGE_BOTTLE_REPEAT_COUNT.has(item_name)


func _is_charge_consumable_trigger_item(item_data: Dictionary) -> bool:
	var item_name: String = _normalize_item_name_for_effects(item_data)
	if _is_charge_bottle_item_name(item_name):
		return true
	return _normalize_build_name(str(item_data.get("build", "无派系"))) == "消耗"


func _is_charge_active_item_name(item_name: String) -> bool:
	return CHARGE_ACTIVE_USE_ITEM_NAMES.has(item_name)


func _is_coin_item_for_effects(item_data: Dictionary) -> bool:
	var item_name: String = _normalize_item_name_for_effects(item_data)
	if item_name == "":
		return false
	if item_name == "硬币箱":
		return false
	if item_name == "夹层硬币" or item_name == "经验币":
		return true
	return _normalize_build_name(str(item_data.get("build", "无派系"))) == COIN_BUILD_NAME


func _get_coin_item_slots(inventory: Array, exclusions: Array[int] = []) -> Array[int]:
	var out: Array[int] = []
	for slot_idx in range(inventory.size()):
		if slot_idx in exclusions:
			continue
		var item_idx: int = int(inventory[slot_idx])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		if not _is_coin_item_for_effects(item_db[item_idx]):
			continue
		out.append(slot_idx)
	return out


func _count_coin_items_in_inventory(inventory: Array) -> int:
	return _get_coin_item_slots(inventory).size()


func _get_total_coin_layers(inventory: Array, inventory_meta: Array) -> int:
	var total_layers: int = 0
	for slot_idx in _get_coin_item_slots(inventory):
		var item_idx: int = int(inventory[slot_idx])
		var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
		total_layers += maxi(int(entry.get("coin_layers", 0)), 0)
	return total_layers


func _get_primary_attr_key_for_coin_effects() -> String:
	if _hero_ctrl == null:
		return "permanent_agility"
	var primary_attr_variant: Variant = _hero_ctrl.get("primary_attribute")
	var primary_attr: String = "敏捷"
	if primary_attr_variant != null:
		primary_attr = str(primary_attr_variant).strip_edges()
	match primary_attr:
		"力量":
			return "permanent_strength"
		"智力":
			return "permanent_intelligence"
		_:
			return "permanent_agility"


func _apply_coin_layer_gain_side_effects(
	item_name: String, entry: Dictionary, layers_gained: int
) -> void:
	var safe_layers: int = maxi(layers_gained, 0)
	if safe_layers <= 0:
		return
	match item_name:
		"纽扣硬币":
			entry["permanent_attack_speed_percent"] = (
				int(entry.get("permanent_attack_speed_percent", 0))
				+ safe_layers * COIN_BUTTON_ATTACK_SPEED_PER_LAYER
			)
		"强化硬币":
			var primary_key: String = _get_primary_attr_key_for_coin_effects()
			for _idx in range(safe_layers):
				entry[primary_key] = int(entry.get(primary_key, 0)) + 1
				var roll: int = randi() % 3
				match roll:
					0:
						entry["permanent_strength"] = int(entry.get("permanent_strength", 0)) + 1
					1:
						entry["permanent_agility"] = int(entry.get("permanent_agility", 0)) + 1
					_:
						entry["permanent_intelligence"] = (
							int(entry.get("permanent_intelligence", 0)) + 1
						)
		_:
			pass


func _apply_coin_layers_gain_to_all(
	inventory: Array, inventory_meta: Array, _coin_state: Dictionary, layers_gained: int
) -> bool:
	var safe_layers: int = maxi(layers_gained, 0)
	if safe_layers <= 0:
		return false
	var changed: bool = false
	for slot_idx in _get_coin_item_slots(inventory):
		var item_idx: int = int(inventory[slot_idx])
		var item_name: String = _get_item_name_by_index(item_idx)
		var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
		entry["coin_layers"] = maxi(int(entry.get("coin_layers", 0)), 0) + safe_layers
		_apply_coin_layer_gain_side_effects(item_name, entry, safe_layers)
		_set_inventory_meta_entry(inventory_meta, slot_idx, entry, item_idx)
		changed = true
	return changed


func _register_single_coin_gain(
	inventory: Array, inventory_meta: Array, coin_state: Dictionary, gained_slot_idx: int
) -> bool:
	if gained_slot_idx < 0 or gained_slot_idx >= inventory.size():
		return false
	var gained_item_idx: int = int(inventory[gained_slot_idx])
	if gained_item_idx < 0 or gained_item_idx >= item_db.size():
		return false
	if not _is_coin_item_for_effects(item_db[gained_item_idx]):
		return false
	var changed: bool = false
	coin_state["total_coins_gained_run"] = (
		maxi(int(coin_state.get("total_coins_gained_run", 0)), 0) + 1
	)
	var coin_count: int = maxi(_count_coin_items_in_inventory(inventory), 0)
	for slot_idx in _find_item_slots_by_name(inventory, "笑脸硬币"):
		var smile_idx: int = int(inventory[slot_idx])
		var smile_entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, smile_idx)
		smile_entry["permanent_damage_tenths"] = (
			int(smile_entry.get("permanent_damage_tenths", 0))
			+ coin_count * COIN_SMILE_DAMAGE_TENTHS_PER_COIN_OWNED
		)
		_set_inventory_meta_entry(inventory_meta, slot_idx, smile_entry, smile_idx)
		changed = true
	var gained_entry: Dictionary = _get_inventory_meta_entry(
		inventory_meta, gained_slot_idx, gained_item_idx
	)
	var gained_item_name: String = _get_item_name_by_index(gained_item_idx)
	if gained_item_name == "金硬币":
		gained_entry["coin_layers"] = (
			maxi(int(gained_entry.get("coin_layers", 0)), 0) + COIN_GOLD_INITIAL_EXTRA_LAYERS
		)
		_set_inventory_meta_entry(inventory_meta, gained_slot_idx, gained_entry, gained_item_idx)
		changed = true
	if gained_item_name == "经验币":
		gained_entry["coin_layers"] = (
			maxi(int(gained_entry.get("coin_layers", 0)), 0)
			+ maxi(int(coin_state.get("total_coins_gained_run", 0)), 0)
		)
		_set_inventory_meta_entry(inventory_meta, gained_slot_idx, gained_entry, gained_item_idx)
		changed = true
	if gained_item_name == "复活币":
		coin_state["revive_event_charges"] = (
			maxi(int(coin_state.get("revive_event_charges", 0)), 0) + 1
		)
		changed = true
	changed = (
		_apply_coin_layers_gain_to_all(
			inventory, inventory_meta, coin_state, COIN_LAYER_GAIN_PER_COIN_GAIN
		)
		or changed
	)
	if gained_item_name == "母币":
		var child_idx: int = _find_item_index_by_name("子币")
		if child_idx >= 0:
			if inventory.size() < 6:
				inventory.append(child_idx)
				inventory_meta.append(_create_default_inventory_meta_entry(child_idx))
				changed = (
					_register_single_coin_gain(
						inventory, inventory_meta, coin_state, inventory.size() - 1
					)
					or changed
				)
			else:
				gained_entry = _get_inventory_meta_entry(
					inventory_meta, gained_slot_idx, gained_item_idx
				)
				gained_entry["deferred_child_coin_on_destroy"] = (
					maxi(int(gained_entry.get("deferred_child_coin_on_destroy", 0)), 0) + 1
				)
				_set_inventory_meta_entry(
					inventory_meta, gained_slot_idx, gained_entry, gained_item_idx
				)
				changed = true
	return changed


func _apply_coin_item_gain_effects(
	inventory: Array, inventory_meta: Array, coin_state: Dictionary, gained_item_idx: int
) -> bool:
	if gained_item_idx < 0 or gained_item_idx >= item_db.size():
		return false
	if inventory.is_empty():
		return false
	if not _is_coin_item_for_effects(item_db[gained_item_idx]):
		return false
	var gained_slot_idx: int = inventory.rfind(gained_item_idx)
	if gained_slot_idx < 0:
		return false
	return _register_single_coin_gain(inventory, inventory_meta, coin_state, gained_slot_idx)


func _append_random_coin_offer_to_shop_offers(
	offers: Array, inventory: Array, shop_level: int
) -> bool:
	var candidates: Array[int] = []
	for item_idx in range(item_db.size()):
		var item_data: Dictionary = item_db[item_idx]
		if not _is_coin_item_for_effects(item_data):
			continue
		if shop_level < 7 and _get_item_name_by_index(item_idx) == "金硬币":
			continue
		if item_idx in offers:
			continue
		_append_shop_candidate_with_runtime_weight(candidates, item_idx, inventory)
	if candidates.is_empty():
		return false
	offers.append(candidates[randi() % candidates.size()])
	return true


func _apply_coin_refresh_effects(
	inventory: Array, _inventory_meta: Array, coin_state: Dictionary, offers: Array, shop_level: int
) -> bool:
	var changed: bool = false
	var refresh_coin_count: int = _find_item_slots_by_name(inventory, "刷新币").size()
	for _idx in range(refresh_coin_count):
		changed = _append_random_coin_offer_to_shop_offers(offers, inventory, shop_level) or changed
	var gold_coin_count: int = _find_item_slots_by_name(inventory, "金硬币").size()
	if gold_coin_count > 0:
		coin_state["refreshes_used_this_battle"] = (
			maxi(int(coin_state.get("refreshes_used_this_battle", 0)), 0) + 1
		)
		changed = true
	return changed


func _get_coin_refresh_limit_per_battle(inventory: Array) -> int:
	return _find_item_slots_by_name(inventory, "金硬币").size() * COIN_GOLD_REFRESH_LIMIT_PER_ITEM


func _can_refresh_with_coin_rules(inventory: Array, coin_state: Dictionary) -> bool:
	var refresh_limit: int = _get_coin_refresh_limit_per_battle(inventory)
	if refresh_limit <= 0:
		return true
	return maxi(int(coin_state.get("refreshes_used_this_battle", 0)), 0) < refresh_limit


func _use_coin_item_in_place(
	inventory: Array, inventory_meta: Array, coin_state: Dictionary, slot_idx: int
) -> bool:
	if slot_idx < 0 or slot_idx >= inventory.size():
		return false
	var item_idx: int = int(inventory[slot_idx])
	if item_idx < 0 or item_idx >= item_db.size():
		return false
	var item_name: String = _get_item_name_by_index(item_idx)
	var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
	match item_name:
		"纪念币":
			var coin_layers: int = maxi(int(entry.get("coin_layers", 0)), 0)
			var remaining_layers: int = coin_layers - 1
			if remaining_layers <= 0:
				return false
			var target_slots: Array[int] = _get_coin_item_slots(inventory, [slot_idx])
			if target_slots.is_empty():
				return false
			entry["coin_layers"] = 0
			_set_inventory_meta_entry(inventory_meta, slot_idx, entry, item_idx)
			for _layer_idx in range(remaining_layers):
				var target_slot: int = target_slots[randi() % target_slots.size()]
				var target_idx: int = int(inventory[target_slot])
				var target_entry: Dictionary = _get_inventory_meta_entry(
					inventory_meta, target_slot, target_idx
				)
				target_entry["coin_layers"] = maxi(int(target_entry.get("coin_layers", 0)), 0) + 1
				_apply_coin_layer_gain_side_effects(
					_get_item_name_by_index(target_idx), target_entry, 1
				)
				_set_inventory_meta_entry(inventory_meta, target_slot, target_entry, target_idx)
			return true
		"金硬币":
			coin_state["auto_destroy_coin_enabled"] = not _variant_to_bool(
				coin_state.get("auto_destroy_coin_enabled", false), false
			)
			return true
		_:
			return false


func _apply_coin_battle_phase_start_effects(inventory: Array, coin_state: Dictionary) -> bool:
	var gold_coin_count: int = _find_item_slots_by_name(inventory, "金硬币").size()
	if gold_coin_count <= 0:
		return false
	coin_state["refreshes_used_this_battle"] = 0
	return true


func _get_coin_battle_phase_end_gold_reward(inventory: Array, inventory_meta: Array) -> int:
	var lucky_coin_count: int = _find_item_slots_by_name(inventory, "幸运币").size()
	var gold_coin_count: int = _find_item_slots_by_name(inventory, "金硬币").size()
	var total_coin_layers: int = _get_total_coin_layers(inventory, inventory_meta)
	return (
		lucky_coin_count * COIN_LUCKY_GOLD_PER_TRIGGER
		+ gold_coin_count * total_coin_layers * COIN_GOLD_GOLD_PER_LAYER
	)


func _apply_coin_destroy_effects_before_removal(
	state: Dictionary,
	inventory: Array,
	inventory_meta: Array,
	coin_state: Dictionary,
	slot_idx: int
) -> void:
	if slot_idx < 0 or slot_idx >= inventory.size():
		return
	var item_idx: int = int(inventory[slot_idx])
	if item_idx < 0 or item_idx >= item_db.size():
		return
	var item_name: String = _get_item_name_by_index(item_idx)
	match item_name:
		"夹层硬币":
			state["gold"] = maxi(int(state.get("gold", 0)), 0) + 300
		"铜硬币":
			coin_state["retained_copper_damage"] = (
				maxi(int(coin_state.get("retained_copper_damage", 0)), 0)
				+ _get_total_coin_layers(inventory, inventory_meta)
			)
		"复活币":
			coin_state["revive_event_charges"] = (
				maxi(int(coin_state.get("revive_event_charges", 0)), 0) + 1
			)
		_:
			pass


func _apply_coin_destroy_effects_after_removal(
	inventory: Array,
	inventory_meta: Array,
	coin_state: Dictionary,
	removed_item_name: String,
	removed_entry: Dictionary
) -> bool:
	var changed: bool = false
	if removed_item_name == "母币":
		var child_idx: int = _find_item_index_by_name("子币")
		var child_count: int = maxi(int(removed_entry.get("deferred_child_coin_on_destroy", 0)), 0)
		while child_idx >= 0 and child_count > 0 and inventory.size() < 6:
			inventory.append(child_idx)
			inventory_meta.append(_create_default_inventory_meta_entry(child_idx))
			changed = (
				_register_single_coin_gain(
					inventory, inventory_meta, coin_state, inventory.size() - 1
				)
				or changed
			)
			child_count -= 1
	return changed


func _is_coin_dream_active(coin_state: Dictionary) -> bool:
	return maxi(int(coin_state.get("dream_active_count", 0)), 0) > 0


func _find_item_slots_by_name(inventory: Array, item_name: String) -> Array[int]:
	return _get_equipment_runtime_helper().find_item_slots_by_name(item_db, inventory, item_name)


func _get_charge_item_slots(inventory: Array, exclude_slots: Array[int] = []) -> Array[int]:
	var out: Array[int] = []
	for i in range(inventory.size()):
		if i in exclude_slots:
			continue
		var item_idx: int = int(inventory[i])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		if _is_charge_item_for_effects(item_db[item_idx]):
			out.append(i)
	return out


func _get_primary_charge_redirect_slot(inventory: Array, exclude_slots: Array[int] = []) -> int:
	for i in range(inventory.size()):
		if i in exclude_slots:
			continue
		if _get_item_name_by_index(int(inventory[i])) == "蓄能器":
			return i
	return -1


func _get_charge_bottle_repeat_count(item_name: String, inventory: Array) -> int:
	var base_repeat: int = maxi(int(CHARGE_BOTTLE_REPEAT_COUNT.get(item_name, 0)), 0)
	if base_repeat <= 0:
		return 0
	var boost_count: int = _find_item_slots_by_name(inventory, "增压电荷").size()
	var multiplier: float = 1.0 + 0.5 * float(boost_count)
	return maxi(int(round(float(base_repeat) * multiplier)), 0)


func _apply_charge_shield_conversion(entry: Dictionary) -> Dictionary:
	var charge_count: int = maxi(int(entry.get("charges", 0)), 0)
	if charge_count <= 0:
		return entry
	entry["permanent_agility"] = (
		maxi(int(entry.get("permanent_agility", 0)), 0) + charge_count * CHARGE_STACK_AGILITY
	)
	entry["permanent_hp"] = (
		maxi(int(entry.get("permanent_hp", 0)), 0) + charge_count * CHARGE_SHIELD_HP_PER_STACK
	)
	entry["permanent_spell_damage_percent"] = (
		maxi(int(entry.get("permanent_spell_damage_percent", 0)), 0)
		+ charge_count * CHARGE_SHIELD_SPELL_DAMAGE_PER_STACK
	)
	entry["charges"] = 0
	return entry


func _add_charge_to_slot(
	inventory: Array,
	inventory_meta: Array,
	slot_idx: int,
	amount: int,
	exclude_redirect_slots: Array[int] = []
) -> bool:
	if amount <= 0 or slot_idx < 0 or slot_idx >= inventory.size():
		return false
	var redirect_slot: int = _get_primary_charge_redirect_slot(inventory, exclude_redirect_slots)
	var final_slot: int = slot_idx
	if redirect_slot >= 0 and redirect_slot != slot_idx:
		final_slot = redirect_slot
	if final_slot < 0 or final_slot >= inventory.size():
		return false
	var item_idx: int = int(inventory[final_slot])
	if item_idx < 0 or item_idx >= item_db.size():
		return false
	if not _is_charge_item_for_effects(item_db[item_idx]):
		return false
	var item_name: String = _get_item_name_by_index(item_idx)
	var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, final_slot, item_idx)
	entry["charges"] = maxi(int(entry.get("charges", 0)), 0) + amount
	if item_name == "充能盾":
		entry = _apply_charge_shield_conversion(entry)
	_set_inventory_meta_entry(inventory_meta, final_slot, entry, item_idx)
	return true


func _apply_charge_bottle_effect(
	item_name: String, inventory: Array, inventory_meta: Array, excluded_slots: Array[int] = []
) -> bool:
	var repeat_count: int = _get_charge_bottle_repeat_count(item_name, inventory)
	if repeat_count <= 0:
		return false
	var changed: bool = false
	for _repeat_idx in range(repeat_count):
		var candidates: Array[int] = _get_charge_item_slots(inventory, excluded_slots)
		if candidates.is_empty():
			break
		var target_slot: int = candidates[randi() % candidates.size()]
		if _add_charge_to_slot(inventory, inventory_meta, target_slot, 1, excluded_slots):
			changed = true
	return changed


func _apply_charge_consumable_gain_effects(inventory: Array, inventory_meta: Array) -> bool:
	var changed: bool = false
	for slot_idx in _find_item_slots_by_name(inventory, "充能望远镜"):
		var item_idx: int = int(inventory[slot_idx])
		var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
		entry["permanent_attack_range"] = (
			maxi(int(entry.get("permanent_attack_range", 0)), 0)
			+ CHARGE_TELESCOPE_RANGE_PER_CONSUMABLE
		)
		_set_inventory_meta_entry(inventory_meta, slot_idx, entry, item_idx)
		changed = true
	return changed


func _apply_charge_item_gain_effects(
	inventory: Array, inventory_meta: Array, gained_item_idx: int
) -> bool:
	if gained_item_idx < 0 or gained_item_idx >= item_db.size():
		return false
	var item_data: Dictionary = item_db[gained_item_idx]
	var item_name: String = _normalize_item_name_for_effects(item_data)
	var changed: bool = false
	if _is_charge_consumable_trigger_item(item_data):
		changed = _apply_charge_consumable_gain_effects(inventory, inventory_meta) or changed
	if _is_charge_bottle_item_name(item_name):
		changed = _apply_charge_bottle_effect(item_name, inventory, inventory_meta) or changed
	return changed


func _redistribute_all_charge_stacks(
	inventory: Array,
	inventory_meta: Array,
	source_slot: int = -1,
	grant_particle_bonus: bool = false
) -> bool:
	var source_exclusions: Array[int] = []
	if source_slot >= 0:
		source_exclusions.append(source_slot)
	var target_slots: Array[int] = _get_charge_item_slots(inventory, source_exclusions)
	if target_slots.is_empty():
		return false
	var carried_charges: int = 0
	for i in range(inventory.size()):
		if i == source_slot:
			continue
		var item_idx: int = int(inventory[i])
		if item_idx < 0 or item_idx >= item_db.size():
			continue
		if not _is_charge_item_for_effects(item_db[item_idx]):
			continue
		var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, i, item_idx)
		carried_charges += maxi(int(entry.get("charges", 0)), 0)
		entry["charges"] = 0
		_set_inventory_meta_entry(inventory_meta, i, entry, item_idx)
	if carried_charges <= 0:
		return false
	for _charge_idx in range(carried_charges):
		var refreshed_targets: Array[int] = _get_charge_item_slots(inventory, source_exclusions)
		if refreshed_targets.is_empty():
			break
		var target_slot: int = refreshed_targets[randi() % refreshed_targets.size()]
		_add_charge_to_slot(inventory, inventory_meta, target_slot, 1, source_exclusions)
	if grant_particle_bonus:
		var highest_slot: int = -1
		var highest_charges: int = -1
		for slot_idx in _get_charge_item_slots(inventory, source_exclusions):
			var item_idx: int = int(inventory[slot_idx])
			var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
			var charge_count: int = maxi(int(entry.get("charges", 0)), 0)
			if charge_count > highest_charges:
				highest_charges = charge_count
				highest_slot = slot_idx
		if highest_slot >= 0:
			var highest_item_idx: int = int(inventory[highest_slot])
			var highest_entry: Dictionary = _get_inventory_meta_entry(
				inventory_meta, highest_slot, highest_item_idx
			)
			highest_entry["particle_bonus_per_two_charges"] = (
				maxi(int(highest_entry.get("particle_bonus_per_two_charges", 0)), 0) + 1
			)
			_set_inventory_meta_entry(inventory_meta, highest_slot, highest_entry, highest_item_idx)
	return true


func _apply_charge_refresh_effects(inventory: Array, inventory_meta: Array) -> bool:
	var changed: bool = false
	for slot_idx in _find_item_slots_by_name(inventory, "未来引擎"):
		if randf() > CHARGE_FUTURE_ENGINE_REFRESH_PROC_CHANCE:
			continue
		for target_slot in _get_charge_item_slots(inventory):
			changed = _add_charge_to_slot(inventory, inventory_meta, target_slot, 1) or changed
		var item_idx: int = int(inventory[slot_idx])
		var entry: Dictionary = _get_inventory_meta_entry(inventory_meta, slot_idx, item_idx)
		entry["permanent_physical_crit_multiplier"] = (
			maxi(int(entry.get("permanent_physical_crit_multiplier", 0)), 0)
			+ CHARGE_FUTURE_ENGINE_CRIT_DAMAGE_PER_PROC
		)
		_set_inventory_meta_entry(inventory_meta, slot_idx, entry, item_idx)
		changed = true
	return changed


func _apply_charge_battle_phase_start_effects(inventory: Array, inventory_meta: Array) -> bool:
	var charge_sword_count: int = _find_item_slots_by_name(inventory, "充能剑").size()
	var changed: bool = false
	for _idx in range(charge_sword_count):
		changed = _apply_charge_bottle_effect("劣质充能瓶", inventory, inventory_meta) or changed
	return changed


func _apply_charge_battle_phase_end_effects(inventory: Array, inventory_meta: Array) -> bool:
	var changed: bool = _apply_charge_battle_phase_start_effects(inventory, inventory_meta)
	for slot_idx in _find_item_slots_by_name(inventory, "充能电池"):
		changed = _add_charge_to_slot(inventory, inventory_meta, slot_idx, 1) or changed
	return changed


func _apply_charge_destroy_absorb_effect(
	inventory: Array, inventory_meta: Array, destroyed_slot_idx: int
) -> bool:
	if destroyed_slot_idx < 0 or destroyed_slot_idx >= inventory.size():
		return false
	var destroyed_item_idx: int = int(inventory[destroyed_slot_idx])
	if destroyed_item_idx < 0 or destroyed_item_idx >= item_db.size():
		return false
	if not _is_charge_item_for_effects(item_db[destroyed_item_idx]):
		return false
	var destroyed_entry: Dictionary = _get_inventory_meta_entry(
		inventory_meta, destroyed_slot_idx, destroyed_item_idx
	)
	var destroyed_charges: int = maxi(int(destroyed_entry.get("charges", 0)), 0)
	if destroyed_charges <= 0:
		return false
	for slot_idx in _find_item_slots_by_name(inventory, "瓶装粒子"):
		if slot_idx == destroyed_slot_idx:
			continue
		var particle_item_idx: int = int(inventory[slot_idx])
		var particle_entry: Dictionary = _get_inventory_meta_entry(
			inventory_meta, slot_idx, particle_item_idx
		)
		if maxi(int(particle_entry.get("charges", 0)), 0) > 0:
			continue
		particle_entry["charges"] = destroyed_charges
		_set_inventory_meta_entry(inventory_meta, slot_idx, particle_entry, particle_item_idx)
		return true
	return false


func _use_inventory_item_in_place(
	inventory: Array, inventory_meta: Array, coin_state: Dictionary, slot_idx: int
) -> bool:
	if slot_idx < 0 or slot_idx >= inventory.size():
		return false
	var item_idx: int = int(inventory[slot_idx])
	if item_idx < 0 or item_idx >= item_db.size():
		return false
	if _use_coin_item_in_place(inventory, inventory_meta, coin_state, slot_idx):
		return true
	var item_name: String = _get_item_name_by_index(item_idx)
	match item_name:
		"充能电池":
			if not _redistribute_all_charge_stacks(inventory, inventory_meta, slot_idx, false):
				return false
		"瓶装粒子":
			if not _redistribute_all_charge_stacks(inventory, inventory_meta, slot_idx, true):
				return false
		_:
			return false
	inventory.remove_at(slot_idx)
	if slot_idx < inventory_meta.size():
		inventory_meta.remove_at(slot_idx)
	return true


func _calculate_inventory_bonuses(inv: Array) -> Dictionary:
	_ensure_local_equipment_runtime_state()
	var destroy_bonus: Dictionary = _get_destroy_runtime_bonus_bundle(
		inv, _equipment_inventory_meta, _destroy_faction_state
	)
	return _get_equipment_effects_service().calculate_inventory_bonuses(
		item_db, inv, _equipment_inventory_meta, _coin_faction_state, destroy_bonus
	)


func _apply_inventory_bonuses_to_hero() -> void:
	if _hero_ctrl == null:
		return
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if not (inv_variant is Array):
		return
	var inv: Array = inv_variant
	var total_bonus: Dictionary = _calculate_inventory_bonuses(inv)
	if _hero_ctrl.has_method("apply_equipment_bonuses"):
		_hero_ctrl.call("apply_equipment_bonuses", total_bonus)


func notify_local_battle_phase_started() -> void:
	if _hero_ctrl == null:
		return
	if _local_battle_phase_active:
		return
	_local_battle_phase_active = true
	if _request_authority_equipment_action("battle_phase_started"):
		return
	_ensure_local_equipment_runtime_state()
	var inv: Array = _to_int_array(_hero_ctrl.get("inventory"))
	var changed: bool = false
	changed = _apply_charge_battle_phase_start_effects(inv, _equipment_inventory_meta) or changed
	if _apply_coin_battle_phase_start_effects(inv, _coin_faction_state):
		_gold = 0
		changed = true
	if changed:
		_refresh_inventory()


func notify_local_battle_phase_ended() -> void:
	if _hero_ctrl == null:
		return
	if not _local_battle_phase_active:
		return
	_local_battle_phase_active = false
	var net_mode: String = ""
	_resolve_net_ctrl()
	if _net_ctrl != null:
		net_mode = str(_net_ctrl.get("network_mode")).strip_edges().to_lower()
	var sent_to_authority: bool = _request_authority_equipment_action("battle_phase_ended")
	if sent_to_authority:
		if net_mode != "client":
			_apply_local_hero_level_gain(1)
		return
	_apply_local_hero_level_gain(1)
	_ensure_local_equipment_runtime_state()
	var inv: Array = _to_int_array(_hero_ctrl.get("inventory"))
	var changed: bool = false
	changed = _apply_charge_battle_phase_end_effects(inv, _equipment_inventory_meta) or changed
	var coin_reward: int = _get_coin_battle_phase_end_gold_reward(inv, _equipment_inventory_meta)
	if coin_reward > 0:
		_gold = maxi(_gold + coin_reward, 0)
		changed = true
	if (
		maxi(_get_coin_refresh_limit_per_battle(inv), 0) > 0
		and maxi(int(_coin_faction_state.get("refreshes_used_this_battle", 0)), 0) != 0
	):
		_coin_faction_state["refreshes_used_this_battle"] = 0
		changed = true
	if changed:
		_refresh_inventory()


func apply_local_floor_clear_progression() -> void:
	if _hero_ctrl == null:
		return
	_apply_local_hero_level_gain(1)


func _apply_local_hero_level_gain(level_gain: int) -> void:
	if _hero_ctrl == null:
		return
	var safe_gain: int = maxi(level_gain, 0)
	if safe_gain <= 0:
		return
	var current_level: int = maxi(_variant_to_int(_hero_ctrl.get("hero_level"), 1), 1)
	_hero_ctrl.set("hero_level", current_level + safe_gain)


func _try_synthesize() -> void:
	if _hero_ctrl == null:
		return
	_ensure_local_equipment_runtime_state()
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if not (inv_variant is Array):
		return
	var inv: Array = inv_variant

	for r_idx in range(RECIPES.size()):
		var recipe: Dictionary = RECIPES[r_idx]
		var inputs: Dictionary = recipe["inputs"]
		var can_craft := true

		for item_name: String in inputs:
			var needed: int = int(inputs[item_name])
			var item_idx: int = _find_item_index_by_name(item_name)
			if item_idx < 0:
				can_craft = false
				break
			var count: int = 0
			for s in range(inv.size()):
				if int(inv[s]) == item_idx:
					count += 1
			if count < needed:
				can_craft = false
				break

		if not can_craft:
			continue

		for item_name: String in inputs:
			var needed: int = int(inputs[item_name])
			var item_idx: int = _find_item_index_by_name(item_name)
			for _i in range(needed):
				var pos: int = inv.find(item_idx)
				if pos >= 0:
					inv.remove_at(pos)
					if pos < _equipment_inventory_meta.size():
						_equipment_inventory_meta.remove_at(pos)

		var output_name: String = str(recipe["output"])
		var result_idx: int = _find_item_index_by_name(output_name)
		if result_idx >= 0:
			inv.append(result_idx)
			_equipment_inventory_meta.append(_create_default_inventory_meta_entry(result_idx))

		_try_synthesize()
		return


func authority_ensure_peer_equipment_state(peer_id: int, baseline_state: Dictionary = {}) -> void:
	_get_equipment_authority_service().ensure_peer_state(
		peer_id, baseline_state, Callable(self, "_authority_build_peer_state")
	)


func authority_drop_peer_state(peer_id: int) -> void:
	_get_equipment_authority_service().drop_peer_state(peer_id)


func authority_get_peer_equipment_state(peer_id: int) -> Dictionary:
	return _get_equipment_authority_service().get_peer_state(peer_id)


func authority_grant_gold_reward(peer_id: int, amount: int) -> Dictionary:
	if peer_id <= 0 or amount == 0:
		return {}
	var safe_amount: int = amount
	var local_peer_id: int = _get_local_authority_peer_id()
	if peer_id == local_peer_id:
		_gold = maxi(_gold + safe_amount, 0)
		_update_shop_info()
		return _build_local_equipment_baseline_state()
	return _get_equipment_authority_service().grant_remote_gold_reward(
		peer_id, safe_amount, Callable(self, "_authority_build_peer_state")
	)


func authority_handle_equipment_action(
	peer_id: int, request: Dictionary, baseline_state: Dictionary = {}
) -> Dictionary:
	return _get_equipment_authority_service().handle_action(
		peer_id,
		request,
		baseline_state,
		Callable(self, "_authority_build_peer_state"),
		Callable(self, "_apply_authority_action_to_state")
	)


func _apply_authority_action_to_state(
	action: String, next_state: Dictionary, payload: Dictionary
) -> String:
	match action:
		"buy_item":
			return _authority_buy_item(next_state, payload)
		"refresh_shop":
			return _authority_refresh_shop(next_state)
		"upgrade_shop":
			return _authority_upgrade_shop(next_state)
		"use_item":
			return _authority_use_item(next_state, payload)
		"destroy_item":
			return _authority_destroy_item(next_state, payload)
		"battle_phase_started":
			return _authority_battle_phase_started(next_state)
		"battle_phase_ended":
			return _authority_battle_phase_ended(next_state)
		"set_destroy_mode":
			return _authority_set_destroy_mode(next_state, payload)
		_:
			return "unknown_action"


func _authority_build_peer_state(baseline_state: Dictionary) -> Dictionary:
	return _get_equipment_action_service().build_peer_state(
		baseline_state,
		_gold,
		item_db.size(),
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_destroy_faction_state"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_sanitize_offer_ids"),
		Callable(self, "_authority_roll_shop_items_for_level"),
		Callable(self, "_variant_to_bool")
	)


func _sanitize_inventory(values: Array) -> Array:
	return _get_equipment_action_service().sanitize_inventory(values, item_db.size(), 6)


func _sanitize_offer_ids(values: Array, shop_level: int) -> Array:
	return _get_shop_catalog_helper().sanitize_offer_ids(values, shop_level, item_db)


func _authority_buy_item(state: Dictionary, payload: Dictionary) -> String:
	return _get_equipment_action_service().apply_buy_item(
		state,
		payload,
		item_db,
		Callable(self, "_get_shop_item_cost_by_index"),
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_get_item_name_by_index"),
		Callable(self, "_is_charge_bottle_item_name"),
		Callable(self, "_is_coin_item_for_effects"),
		Callable(self, "_variant_to_bool"),
		Callable(self, "_get_item_level"),
		Callable(self, "_is_blocked_shop_item"),
		Callable(self, "_create_default_inventory_meta_entry"),
		Callable(self, "_apply_charge_item_gain_effects"),
		Callable(self, "_apply_coin_item_gain_effects"),
		Callable(self, "_synthesize_inventory_in_place"),
		6,
		"金硬币"
	)


func _authority_refresh_shop(state: Dictionary) -> String:
	return _get_equipment_action_service().apply_refresh_shop(
		state,
		SHOP_REFRESH_COST,
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_can_refresh_with_coin_rules"),
		Callable(self, "_apply_charge_refresh_effects"),
		Callable(self, "_authority_roll_shop_items_for_level"),
		Callable(self, "_apply_coin_refresh_effects")
	)


func _authority_upgrade_shop(state: Dictionary) -> String:
	return _get_equipment_action_service().apply_upgrade_shop(
		state, SHOP_UPGRADE_COST, Callable(self, "_authority_roll_shop_items_for_level")
	)


func _authority_use_item(state: Dictionary, payload: Dictionary) -> String:
	return _get_equipment_action_service().apply_use_item(
		state,
		payload,
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_use_inventory_item_in_place")
	)


func _apply_recovery_hammer_random_bonus(destroy_state: Dictionary, destroyed_level: int) -> void:
	var safe_level: int = maxi(destroyed_level, 0)
	for _roll_idx in range(2):
		var roll: int = (randi() % 3) + 1
		match roll:
			1:
				destroy_state["permanent_agility"] = (
					int(destroy_state.get("permanent_agility", 0)) + safe_level
				)
			2:
				destroy_state["permanent_intelligence"] = (
					int(destroy_state.get("permanent_intelligence", 0)) + safe_level
				)
			_:
				destroy_state["permanent_strength"] = (
					int(destroy_state.get("permanent_strength", 0)) + safe_level
				)


func _apply_destroy_faction_effects_before_removal(
	state: Dictionary,
	inventory: Array,
	inventory_meta: Array,
	destroy_state: Dictionary,
	slot_idx: int
) -> void:
	if slot_idx < 0 or slot_idx >= inventory.size():
		return
	var destroyed_item_idx: int = int(inventory[slot_idx])
	if destroyed_item_idx < 0 or destroyed_item_idx >= item_db.size():
		return
	var destroyed_item_name: String = _get_item_name_by_index(destroyed_item_idx)
	var destroyed_item_level: int = maxi(
		_get_effective_inventory_item_level(
			destroyed_item_idx, slot_idx, inventory_meta, inventory
		),
		0
	)
	var total_item_level_before_destroy: int = maxi(
		_get_inventory_total_item_level(inventory, inventory_meta), 0
	)
	if destroyed_item_name == "骨制风铃":
		var estimated_base_stats: Dictionary = _estimate_hero_base_stats_for_state(
			state, destroy_state
		)
		var target_floor: int = total_item_level_before_destroy
		var current_strength: int = int(estimated_base_stats.get("strength", 0))
		var current_agility: int = int(estimated_base_stats.get("agility", 0))
		var current_intelligence: int = int(estimated_base_stats.get("intelligence", 0))
		if current_strength < target_floor:
			destroy_state["permanent_strength"] = (
				int(destroy_state.get("permanent_strength", 0)) + (target_floor - current_strength)
			)
		if current_agility < target_floor:
			destroy_state["permanent_agility"] = (
				int(destroy_state.get("permanent_agility", 0)) + (target_floor - current_agility)
			)
		if current_intelligence < target_floor:
			destroy_state["permanent_intelligence"] = (
				int(destroy_state.get("permanent_intelligence", 0))
				+ (target_floor - current_intelligence)
			)

	var first_void_orb_slot: int = -1
	for i in range(inventory.size()):
		var held_item_idx: int = int(inventory[i])
		var held_item_name: String = _get_item_name_by_index(held_item_idx)
		match held_item_name:
			"万宝锤":
				destroy_state["permanent_hp"] = (
					int(destroy_state.get("permanent_hp", 0)) + destroyed_item_level * 20
				)
			"回收锤":
				_apply_recovery_hammer_random_bonus(destroy_state, destroyed_item_level)
			"通天锤":
				var tongtian_meta: Dictionary = _get_inventory_meta_entry(
					inventory_meta, i, held_item_idx
				)
				var tongtian_charges: int = maxi(int(tongtian_meta.get("charges", 0)), 0)
				if tongtian_charges >= 5:
					destroy_state["tongtian_ready_stages"] = (
						int(destroy_state.get("tongtian_ready_stages", 0)) + 2
					)
					destroy_state["tongtian_bonus_loops"] = (
						int(destroy_state.get("tongtian_bonus_loops", 0)) + 1
					)
					tongtian_meta["charges"] = 0
				else:
					tongtian_meta["charges"] = tongtian_charges + 1
				_set_inventory_meta_entry(inventory_meta, i, tongtian_meta, held_item_idx)
			"血羽之心":
				if destroyed_item_name != "血羽之心":
					var bloodheart_meta: Dictionary = _get_inventory_meta_entry(
						inventory_meta, i, held_item_idx
					)
					var current_bloodheart_level: int = maxi(
						int(
							bloodheart_meta.get(
								"dynamic_level", _get_item_level(item_db[held_item_idx])
							)
						),
						_get_item_level(item_db[held_item_idx])
					)
					bloodheart_meta["dynamic_level"] = (
						current_bloodheart_level + destroyed_item_level
					)
					_set_inventory_meta_entry(inventory_meta, i, bloodheart_meta, held_item_idx)
			"空洞宝珠":
				if first_void_orb_slot < 0:
					first_void_orb_slot = i
			_:
				pass

	if first_void_orb_slot >= 0:
		var void_orb_item_idx: int = int(inventory[first_void_orb_slot])
		var void_orb_meta: Dictionary = _get_inventory_meta_entry(
			inventory_meta, first_void_orb_slot, void_orb_item_idx
		)
		void_orb_meta["charges"] = maxi(int(void_orb_meta.get("charges", 0)), 0) + 1
		void_orb_meta["stored_level"] = (
			maxi(int(void_orb_meta.get("stored_level", 0)), 0) + destroyed_item_level
		)
		_set_inventory_meta_entry(
			inventory_meta, first_void_orb_slot, void_orb_meta, void_orb_item_idx
		)


func _apply_destroy_faction_effects_after_removal(inventory: Array, inventory_meta: Array) -> void:
	var empty_orb_idx: int = _find_item_index_by_name("空洞宝珠")
	var evil_orb_idx: int = _find_item_index_by_name("邪灵宝珠")
	if empty_orb_idx < 0 or evil_orb_idx < 0:
		return
	var slot_idx: int = 0
	while slot_idx < inventory.size():
		var item_idx: int = int(inventory[slot_idx])
		if item_idx != empty_orb_idx:
			slot_idx += 1
			continue
		var empty_orb_meta: Dictionary = _get_inventory_meta_entry(
			inventory_meta, slot_idx, item_idx
		)
		if maxi(int(empty_orb_meta.get("charges", 0)), 0) < 3:
			slot_idx += 1
			continue
		var evil_orb_meta: Dictionary = _create_default_inventory_meta_entry(evil_orb_idx)
		evil_orb_meta["dynamic_level"] = maxi(int(empty_orb_meta.get("stored_level", 0)), 0)
		inventory[slot_idx] = evil_orb_idx
		_set_inventory_meta_entry(inventory_meta, slot_idx, evil_orb_meta, evil_orb_idx)
		slot_idx += 1


func _authority_destroy_item(state: Dictionary, payload: Dictionary) -> String:
	return _get_equipment_action_service().apply_destroy_item(
		state,
		payload,
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_destroy_faction_state"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_get_item_name_by_index"),
		Callable(self, "_get_inventory_meta_entry"),
		Callable(self, "_apply_destroy_faction_effects_before_removal"),
		Callable(self, "_apply_coin_destroy_effects_before_removal"),
		Callable(self, "_apply_charge_destroy_absorb_effect"),
		Callable(self, "_apply_destroy_faction_effects_after_removal"),
		Callable(self, "_apply_coin_destroy_effects_after_removal"),
		"金硬币"
	)


func _authority_set_destroy_mode(state: Dictionary, payload: Dictionary) -> String:
	return _get_equipment_action_service().apply_set_destroy_mode(
		state, payload, Callable(self, "_variant_to_bool")
	)


func _authority_battle_phase_started(state: Dictionary) -> String:
	return _get_equipment_action_service().apply_battle_phase_started(
		state,
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_apply_charge_battle_phase_start_effects"),
		Callable(self, "_apply_coin_battle_phase_start_effects")
	)


func _authority_battle_phase_ended(state: Dictionary) -> String:
	return _get_equipment_action_service().apply_battle_phase_ended(
		state,
		Callable(self, "_to_int_array"),
		Callable(self, "_sanitize_inventory_meta_array"),
		Callable(self, "_sanitize_coin_faction_state"),
		Callable(self, "_apply_charge_battle_phase_end_effects"),
		Callable(self, "_get_coin_battle_phase_end_gold_reward")
	)


func _authority_roll_shop_items_for_level(level: int, state: Dictionary = {}) -> Array:
	var inventory: Array = _sanitize_inventory(_to_int_array(state.get("inventory", [])))
	return _get_shop_catalog_helper().roll_shop_offer_ids(level, item_db, inventory)


func _synthesize_inventory_in_place(inventory: Array, inventory_meta: Array = []) -> void:
	var crafted_any: bool = true
	while crafted_any:
		crafted_any = false
		for recipe_variant in RECIPES:
			if not (recipe_variant is Dictionary):
				continue
			var recipe: Dictionary = recipe_variant
			var inputs_variant: Variant = recipe.get("inputs", {})
			if not (inputs_variant is Dictionary):
				continue
			var inputs: Dictionary = inputs_variant
			var can_craft: bool = true
			for item_name_variant in inputs.keys():
				var item_name: String = str(item_name_variant)
				var needed: int = maxi(int(inputs[item_name_variant]), 0)
				var item_idx: int = _find_item_index_by_name(item_name)
				if item_idx < 0:
					can_craft = false
					break
				var count: int = 0
				for held_variant in inventory:
					if int(held_variant) == item_idx:
						count += 1
				if count < needed:
					can_craft = false
					break
			if not can_craft:
				continue
			for item_name_variant in inputs.keys():
				var item_name: String = str(item_name_variant)
				var needed: int = maxi(int(inputs[item_name_variant]), 0)
				var item_idx: int = _find_item_index_by_name(item_name)
				for _i in range(needed):
					var remove_idx: int = inventory.find(item_idx)
					if remove_idx >= 0:
						inventory.remove_at(remove_idx)
						if remove_idx < inventory_meta.size():
							inventory_meta.remove_at(remove_idx)
			var output_name: String = str(recipe.get("output", ""))
			var output_idx: int = _find_item_index_by_name(output_name)
			if output_idx >= 0:
				inventory.append(output_idx)
				inventory_meta.append(_create_default_inventory_meta_entry(output_idx))
			crafted_any = true
			break


func _get_display_inventory() -> Array:
	var out: Array = []
	if _is_observing_remote():
		var eq_state: Dictionary = _get_observed_equipment_state()
		var inv_variant: Variant = eq_state.get("inventory", [])
		if inv_variant is Array:
			for value in inv_variant:
				out.append(int(value))
		return out
	if _hero_ctrl == null:
		return out
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if inv_variant is Array:
		for value in inv_variant:
			out.append(int(value))
	if _is_inventory_display_override_active(out):
		return _inventory_display_override.duplicate(true)
	return out


func _build_inventory_signature(inv: Array) -> String:
	var owner_key: int = 0
	if _is_observing_remote():
		owner_key = int(_get_ui_state().observed_peer_id)
		var observed_state: Dictionary = _get_observed_equipment_state()
		var observed_meta: Array = _sanitize_inventory_meta_array(
			observed_state.get("inventory_meta", []), inv
		)
		var observed_destroy_state: Dictionary = _sanitize_destroy_faction_state(
			observed_state.get("destroy_faction_state", {})
		)
		var observed_coin_state: Dictionary = _sanitize_coin_faction_state(
			observed_state.get("coin_faction_state", {})
		)
		return _get_equipment_runtime_helper().build_inventory_signature(
			inv, owner_key, observed_meta, observed_destroy_state, observed_coin_state
		)
	return _get_equipment_runtime_helper().build_inventory_signature(
		inv, owner_key, _equipment_inventory_meta, _destroy_faction_state, _coin_faction_state
	)


func _refresh_inventory() -> void:
	var inv: Array = _get_display_inventory()
	if not _is_observing_remote():
		_ensure_local_equipment_runtime_state()
	var real_inv: Array = inv
	if not _is_observing_remote() and _hero_ctrl != null:
		real_inv = _to_int_array(_hero_ctrl.get("inventory"))
	var tooltip_meta: Array = []
	var tooltip_state: Dictionary = {}
	var tooltip_coin_state: Dictionary = {}
	if _is_observing_remote():
		var observed_state: Dictionary = _get_observed_equipment_state()
		tooltip_meta = _sanitize_inventory_meta_array(observed_state.get("inventory_meta", []), inv)
		tooltip_state = _sanitize_destroy_faction_state(
			observed_state.get("destroy_faction_state", {})
		)
		tooltip_coin_state = _sanitize_coin_faction_state(
			observed_state.get("coin_faction_state", {})
		)
	else:
		tooltip_meta = _equipment_inventory_meta
		tooltip_state = _destroy_faction_state
		tooltip_coin_state = _coin_faction_state
	var signature: String = _build_inventory_signature(real_inv)
	if signature == _last_inventory_signature:
		_sync_destroy_hover_cursor()
		return
	_last_inventory_signature = signature
	for i in range(6):
		if i < inv.size():
			var item_idx: int = inv[i]
			if item_idx >= 0 and item_idx < item_db.size():
				var tex := _load_item_texture(str(item_db[item_idx].get("icon", "")))
				if tex and i < _inventory_icons.size():
					_inventory_icons[i].texture = tex
					_inventory_icons[i].visible = true
				if i < _inventory_slots.size():
					var tooltip_slot_idx: int = _resolve_inventory_real_slot(i, real_inv)
					if tooltip_slot_idx >= 0:
						_inventory_slots[i].tooltip_text = _build_inventory_tooltip_text(
							item_idx,
							tooltip_slot_idx,
							tooltip_meta,
							tooltip_state,
							tooltip_coin_state
						)
					else:
						_inventory_slots[i].tooltip_text = ""
			else:
				if i < _inventory_icons.size():
					_inventory_icons[i].visible = false
				if i < _inventory_slots.size():
					_inventory_slots[i].tooltip_text = ""
		else:
			if i < _inventory_icons.size():
				_inventory_icons[i].visible = false
			if i < _inventory_slots.size():
				_inventory_slots[i].tooltip_text = ""
	if not _is_observing_remote():
		_apply_inventory_bonuses_to_hero()
	_update_destroy_visual()
	_sync_destroy_hover_cursor()


func _is_inventory_slot_has_item(index: int) -> bool:
	var inv: Array = _get_display_inventory()
	if index < 0 or index >= inv.size():
		return false
	var item_idx: int = int(inv[index])
	return item_idx >= 0 and item_idx < item_db.size()


func _find_hovered_inventory_index() -> int:
	var mouse_pos: Vector2 = _get_viewport_mouse_position()
	for i in range(_inventory_slots.size()):
		var slot: PanelContainer = _inventory_slots[i]
		if slot == null or not slot.visible:
			continue
		if slot.get_global_rect().has_point(mouse_pos):
			return i
	return -1


func _sync_destroy_hover_cursor() -> void:
	if _hero_ctrl == null or not _hero_ctrl.has_method("set_destroy_cursor_item_hover"):
		return
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		_destroy_hover_index = -1
		_hero_ctrl.call("set_destroy_cursor_item_hover", false)
		return
	if not _destroy_mode:
		_destroy_hover_index = -1
		_hero_ctrl.call("set_destroy_cursor_item_hover", false)
		return
	if _destroy_hover_index < 0:
		_destroy_hover_index = _find_hovered_inventory_index()
	var hovering_item: bool = _is_inventory_slot_has_item(_destroy_hover_index)
	_hero_ctrl.call("set_destroy_cursor_item_hover", hovering_item)


func _on_inv_slot_mouse_entered(index: int) -> void:
	_destroy_hover_index = index
	_sync_destroy_hover_cursor()


func _on_inv_slot_mouse_exited(index: int) -> void:
	if _destroy_hover_index == index:
		_destroy_hover_index = -1
	_sync_destroy_hover_cursor()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _shop_visible:
			_toggle_shop()
			return
		if event.keycode == KEY_F:
			_toggle_destroy_mode()


func _toggle_destroy_mode() -> void:
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		return
	var target_mode: bool = not _destroy_mode
	if _request_authority_equipment_action("set_destroy_mode", {"enabled": target_mode}):
		return
	_destroy_mode = not _destroy_mode
	if _hero_ctrl != null and _hero_ctrl.has_method("set_destroy_cursor_mode"):
		_hero_ctrl.call("set_destroy_cursor_mode", _destroy_mode)
	_sync_destroy_hover_cursor()
	_update_destroy_visual()


func _update_destroy_visual() -> void:
	if _destroy_skill_panel:
		if _destroy_mode:
			var dsb := StyleBoxFlat.new()
			dsb.bg_color = Color(0.5, 0.1, 0.1, 1.0)
			dsb.border_color = Color(1.0, 0.2, 0.2, 1.0)
			dsb.set_border_width_all(2)
			dsb.corner_radius_top_left = 3
			dsb.corner_radius_top_right = 3
			dsb.corner_radius_bottom_left = 3
			dsb.corner_radius_bottom_right = 3
			_destroy_skill_panel.add_theme_stylebox_override("panel", dsb)
		else:
			_destroy_skill_panel.add_theme_stylebox_override(
				"panel", _create_transparent_stylebox([6, 6, 6, 6])
			)

	for i in range(_inventory_slots.size()):
		var slot := _inventory_slots[i]
		var has_item: bool = _is_inventory_slot_has_item(i)
		if _destroy_mode and has_item:
			var ssb := StyleBoxFlat.new()
			ssb.bg_color = Color(0.25, 0.05, 0.05, 1.0)
			ssb.border_color = Color(1.0, 0.2, 0.2, 0.8)
			ssb.set_border_width_all(1)
			ssb.corner_radius_top_left = 2
			ssb.corner_radius_top_right = 2
			ssb.corner_radius_bottom_left = 2
			ssb.corner_radius_bottom_right = 2
			slot.add_theme_stylebox_override("panel", ssb)
		else:
			slot.add_theme_stylebox_override("panel", _create_transparent_stylebox([4, 4, 4, 4]))


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


func _create_transparent_stylebox(content_margins: Array = []) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	if content_margins.size() >= 4:
		sb.content_margin_left = float(content_margins[0])
		sb.content_margin_top = float(content_margins[1])
		sb.content_margin_right = float(content_margins[2])
		sb.content_margin_bottom = float(content_margins[3])
	return sb


func _on_inv_slot_input(event: InputEvent, index: int) -> void:
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		return
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		_use_inventory_item(index)
		return
	if (
		_destroy_mode
		and event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		_destroy_item(index)


func _use_inventory_item(index: int) -> void:
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		return
	if _hero_ctrl == null:
		return
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if not (inv_variant is Array):
		return
	var inv: Array = inv_variant
	var resolved_slot_idx: int = _resolve_inventory_real_slot(index, _to_int_array(inv))
	if resolved_slot_idx < 0 or resolved_slot_idx >= inv.size():
		return
	if _request_authority_equipment_action("use_item", {"slot_idx": resolved_slot_idx}):
		return
	_ensure_local_equipment_runtime_state()
	if not _use_inventory_item_in_place(
		inv, _equipment_inventory_meta, _coin_faction_state, resolved_slot_idx
	):
		return
	_destroy_mode = false
	_destroy_hover_index = -1
	if _hero_ctrl != null and _hero_ctrl.has_method("set_destroy_cursor_mode"):
		_hero_ctrl.call("set_destroy_cursor_mode", false)
	_refresh_inventory()
	_sync_destroy_hover_cursor()
	_update_destroy_visual()


func _destroy_item(index: int) -> void:
	if _is_observing_remote() or _is_observing_boss() or _is_observing_enemy():
		return
	if _hero_ctrl == null:
		return
	var inv_variant: Variant = _hero_ctrl.get("inventory")
	if not (inv_variant is Array):
		return
	var inv: Array = inv_variant
	var resolved_slot_idx: int = _resolve_inventory_real_slot(index, _to_int_array(inv))
	if resolved_slot_idx < 0 or resolved_slot_idx >= inv.size():
		return
	if _request_authority_equipment_action("destroy_item", {"slot_idx": resolved_slot_idx}):
		return
	_ensure_local_equipment_runtime_state()
	var removed_item_idx: int = int(inv[resolved_slot_idx])
	var removed_item_name: String = _get_item_name_by_index(removed_item_idx)
	if removed_item_name == "金硬币":
		return
	var removed_entry: Dictionary = _get_inventory_meta_entry(
		_equipment_inventory_meta, resolved_slot_idx, removed_item_idx
	)
	var local_state: Dictionary = _build_local_equipment_baseline_state()
	_apply_destroy_faction_effects_before_removal(
		local_state, inv, _equipment_inventory_meta, _destroy_faction_state, resolved_slot_idx
	)
	_apply_coin_destroy_effects_before_removal(
		local_state, inv, _equipment_inventory_meta, _coin_faction_state, resolved_slot_idx
	)
	_gold = maxi(int(local_state.get("gold", _gold)), 0)
	_apply_charge_destroy_absorb_effect(inv, _equipment_inventory_meta, resolved_slot_idx)
	inv.remove_at(resolved_slot_idx)
	if resolved_slot_idx < _equipment_inventory_meta.size():
		_equipment_inventory_meta.remove_at(resolved_slot_idx)
	_apply_destroy_faction_effects_after_removal(inv, _equipment_inventory_meta)
	_apply_coin_destroy_effects_after_removal(
		inv, _equipment_inventory_meta, _coin_faction_state, removed_item_name, removed_entry
	)
	_refresh_inventory()
	_destroy_mode = false
	_destroy_hover_index = -1
	if _hero_ctrl != null and _hero_ctrl.has_method("set_destroy_cursor_mode"):
		_hero_ctrl.call("set_destroy_cursor_mode", false)
	_sync_destroy_hover_cursor()
	_update_destroy_visual()
