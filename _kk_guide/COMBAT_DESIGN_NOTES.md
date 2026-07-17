# 开源战斗/角色封装模式研究

> 生成日期：2026-07-18
> 研究对象：三个公认设计良好的开源 Godot 项目的战斗代码（均已通读源码）
> 目的：对照 rogueDungeon 现状，决定哪些模式值得引入、哪些不该抄

## 研究的三个来源

| 项目 | 规模 | 看点 |
|---|---|---|
| [HeartBeast youtube-action-rpg](https://github.com/uheartbeast/youtube-action-rpg) | 极简（Stats 13 行） | Hitbox/Hurtbox + Stats Resource 的最小可用形态 |
| [GDQuest godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) | 中型教学项目 | BattlerStats 修饰器系统、BattlerHit 伤害事件对象 |
| [cluttered-code/godot-health-hitbox-hurtbox](https://github.com/cluttered-code/godot-health-hitbox-hurtbox) | 完整组件插件 | Health 组件的信号面设计、HealthAction 数据驱动伤害 |

---

## 模式一：生命值组件（Health extends Node）—— 值得引入 ★★★

cluttered-code 的核心设计：`Health` 是一个挂在任意节点下的**子节点组件**，
只管数值记账和信号广播：

```gdscript
class_name Health extends Node
signal damaged(entity, type, amount, ..., applied)
signal died(entity)
signal healed(...)
signal first_hit(entity)          # 信号面很细：满血首击、已死再击、不可杀……
@export var current: int = 100:
    set(curr): current = clampi(curr, 0, max)
@export var max: int = 100
```

**这正是我们 CombatUnit 基类问题的正解。** GDScript 单继承卡死了基类方案
（TaurenUnitAI 是 CharacterBody3D，其他是 Node3D），但**组合不受继承限制**：
任何节点都能挂一个 Health 子节点。四个类各自手写的
`_current_hp / _is_dead / max_hp / _update_hp_bar / _die` 是完全平行的重复代码，
收进组件后：

- HP 条改为订阅 `health_changed` 信号（现在是每处手动调 `_update_hp_bar()`）
- CombatTarget 分发器的 is_dead/apply_damage 分支塌缩成 `target.get_node("Health")`
- 网络快照的 hp/max_hp/dead 字段采集统一从组件读

**引入路径（增量，不做大爆炸）**：BossGate 先行（最小，200 行）→ TaurenUnitAI
→ EnemyAI → HeroController 最后。每迁一个，删掉它手写的记账代码。

**本项目特有的约束**：伤害的"路由"（客户端请求 → 主机校验 → 应用 → 快照回传）
是反作弊核心，**必须留在 CombatTarget/NetSession 层**，组件只管被主机调用后的
数值变更。开源项目全是单机直调，这一层它们没有，不能照抄调用链。

## 模式二：伤害事件对象（BattlerHit / HealthAction）—— 值得引入 ★★★

GDQuest 用 RefCounted 封装一次伤害的全部语义：

```gdscript
class_name BattlerHit extends RefCounted
var damage := 0
var hit_chance := 100.0
func is_successful() -> bool: return randf() * 100.0 < hit_chance
```

cluttered-code 更进一步做成 Resource（可在编辑器配置）：

```gdscript
class_name HealthAction extends Resource
@export var affect: Health.Affect = DAMAGE
@export var type: HealthActionType.Enum = KINETIC
@export var amount: int = 1
```

**对照我们的现状**：`apply_damage(amount, attacker, damage_source, hit_context)`
里的 `hit_context` 是无 schema 的字典（`knockback_distance`、`is_critical`……
字符串 key 散落在 hero_controller 和 net_session 两端），这和当年的
snapshot 白名单是同一种病。引入 `DamageHit extends RefCounted`：

```gdscript
class_name DamageHit extends RefCounted
var amount: int
var source: String          # basic_attack / q_ray / flash / poison...
var attacker_path: NodePath
var is_critical: bool
var knockback_distance: float
var knockback_duration: float
func to_dict() -> Dictionary   # 网络序列化收口在此
static func from_dict(d: Dictionary) -> DamageHit
```

`to_dict/from_dict` 一并解决了伤害请求跨网络的 schema 问题——主机校验
时拿到的是结构化对象而不是裸字典。**迁移起点**：CombatTarget 加一个
`apply_hit(target, hit)` 重载，新代码走它，旧的四参签名保留，碰到就迁。

## 模式三：属性 Resource 化（Stats/BattlerStats extends Resource）—— 值得引入 ★★☆

HeartBeast 的 13 行版本展示了本质——**数值放 Resource，变更走 setter 信号**：

```gdscript
class_name Stats extends Resource
@export var health := 1:
    set(value):
        health = value
        if health != previous: health_changed.emit(health)
        if health <= 0: no_health.emit()
```

GDQuest 版本加上了修饰器系统：base_attack 等基础值 + `_modifiers/_multipliers`
两个按 uid 索引的字典，装备/buff 挂一个修饰器拿到 uid，过期时凭 uid 摘除，
`attack` 永远是重算结果。

**对照我们的现状**：`hero_controller` 上 144 个 `@export` 就是评审里的 P1-4，
而且装备加成是 `equip_strength_bonus` 这类散装字段手动累加。方案：

- `HeroProfile extends Resource`（.tres）：近战/远程两份，装基础值和成长
- 我们已有的 `HeroStatsService`（纯函数计算器）保持不动——它比 GDQuest 的
  写法更可测，这是我们做得比开源项目**好**的地方，别退化
- 修饰器字典模式值得抄给装备/天赋加成，替代散装 bonus 字段

工作量大（144 个字段迁移），**放到 R3 拆 hero_controller 时一起做**，不单独动。

## 模式四：Hitbox/Hurtbox 碰撞区（Area 物理驱动命中）—— 不引入 ✗

HeartBeast/cluttered-code 都用 `Area2D/3D` 物理重叠驱动命中：

```gdscript
class_name Hurtbox extends Area2D
signal hurt(hitbox: Hitbox)
func _on_area_entered(area): if area is Hitbox: hurt.emit(area)
```

单机动作游戏的标准做法，但**和我们的架构冲突**：我们的命中是主机权威下的
手动扫描 + 距离校验（`_distance_xz + attack_range`，反作弊需要它可重放、可裁决），
改成物理事件驱动等于重写命中判定和整套网络裁决。收益不明，风险巨大。跳过。

## 总结：抄什么、不抄什么、我们已经领先什么

| 模式 | 结论 | 时机 |
|---|---|---|
| Health 组件 | 引入，BossGate 先行逐类迁移 | 下一个战斗改动时启动 |
| DamageHit 伤害对象 | 引入，从 CombatTarget 重载起步 | 随时可做，低风险 |
| Stats Resource + 修饰器 | 引入，绑定 R3 一起做 | 拆 hero_controller 时 |
| Hitbox/Hurtbox 物理命中 | 不引入（与主机权威裁决冲突） | — |
| 信号驱动 UI（HP 条） | 随 Health 组件自然获得 | — |

已经比这三个项目做得好、注意别退化的：**纯函数 Service 层**（它们的伤害计算
都内嵌在节点里，我们的 HeroStatsService/快照服务可以无头测试）；**网络裁决层**
（预算、熔断、幂等确认，开源单机项目根本没有这个问题域）。

参考源码副本在会话 scratchpad `refs/` 下，仓库里不留三方代码。
