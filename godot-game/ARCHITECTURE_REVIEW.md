# rogueDungeon 架构与代码审查报告

> 生成日期：2026-05-07
> 分析范围：`godot-game/`（Godot 4.6 客户端）+ `be/`（Go 后端）+ 根目录资产工具链
> 报告目的：为后续重构、新成员上手、技术决策评审提供单一事实来源

---

## 目录

1. [项目结构](#1-项目结构)
2. [整体架构设计](#2-整体架构设计)
3. [Godot 客户端架构](#3-godot-客户端架构)
4. [Go 后端架构](#4-go-后端架构)
5. [客户端 ↔ 后端 协议契约](#5-客户端--后端-协议契约)
6. [资产工具链](#6-资产工具链)
7. [客户端代码审查](#7-客户端代码审查)
8. [关键架构决策与取舍](#8-关键架构决策与取舍)
9. [重构路线图](#9-重构路线图)
10. [一句话总结](#10-一句话总结)

---

## 1. 项目结构

```
rogueDungeon/
├── godot-game/      # Godot 4.6 客户端（主项目）
├── be/              # Go 后端服务
├── scripts/         # 构建/工具脚本
├── tools/           # 工具
├── _kk_diff/, _kk_guide/, _kk_post/, _kk_video/   # 文档/素材/视频资料
├── blender_convert.js                              # 模型转换入口
└── package.json     # Node 资产处理工具链（gltf-transform / w3x-parser）
```

| 子项目 | 角色 | 技术栈 |
|---|---|---|
| `godot-game/` | 客户端 + P2P 主机 | Godot 4.6, GDScript, Jolt Physics, Forward+, Steam SDK |
| `be/` | 权威结算后端 | Go 1.23, Gin, pgx, JWT, PostgreSQL |
| 根目录 Node 工具 | 资产转换流水线 | Node.js, gltf-transform, w3x-parser, war3-model, node-unrar-js |

---

## 2. 整体架构设计

`rogueDungeon` 是一款**联机肉鸽地下城**，采用 **"权威主机 (P2P Host) + Steam 中继 + 后端权威结算"** 的混合架构：实时玩法走 P2P，关键经济/反作弊/进度走后端 REST。

```
┌──────────────────────────────────────────────────────────────┐
│  Godot Client (godot-game/)                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ Hero/Combat  │  │ UI / HUD     │  │ Scene Flow       │    │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘    │
│         └──── 调用本地 Service 层 ─────────────┘             │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  NetSessionController (权威主机，状态同步)            │    │
│  │  ├─ HostSyncFlow / ClientSyncFlow / ObserveSync       │    │
│  │  ├─ SnapshotSerialization / RemoteAvatar*Service      │    │
│  │  └─ SteamLobbyService (大厅、Host Migration)          │    │
│  └──────────────┬───────────────────────────────────────┘    │
└─────────────────┼─────────────────────────────────────────────┘
                  │ ENet/Steam Relay (P2P 实时)
                  │ HTTPS REST (鉴权 + 结算)
                  ▼
┌──────────────────────────────────────────────────────────────┐
│  Go Backend (be/)  Gin + pgx + JWT                           │
│  cmd/api  ──►  bootstrap (DI)  ──►  modules/{auth, run,      │
│                                       inventory, commerce,   │
│                                       player, risk, audit}   │
│  cmd/worker  ──►  reward_jobs_processor (异步发奖)           │
│  platform: db / jwt / migrate                                │
│  PostgreSQL: users / runs / rewards / risk / audit / idempo. │
└──────────────────────────────────────────────────────────────┘
                  ▲
┌─────────────────┴────────────────────────────────────────────┐
│  Asset Toolchain (Node.js)                                   │
│  blender_convert.js + gltf-transform + w3x-parser/war3-model │
│  (W3X/MDX → glTF → Godot 资源)                               │
└──────────────────────────────────────────────────────────────┘
```

**核心设计原则**：
- 实时性 → P2P（避免做"全权威服务器"的成本与延迟）
- 公平性/经济 → 后端权威（开局 / 结算 / 迁移 / 断线重连）
- 异步发奖（reward_jobs）保证下游故障不丢奖

---

## 3. Godot 客户端架构

### 3.1 设计模式：Controller + Service 扁平架构

所有脚本平铺在 `godot-game/` 根目录，命名上严格区分两类职责：

- **Controller**（编排/生命周期/输入）：`hero_controller.gd`、`scene_flow_controller.gd`、`net_session_controller.gd`、`shop_panel_controller.gd`、`command_section_controller.gd`、`talent_popup_controller.gd`、`hud_status_panels_controller.gd`
- **Service**（无状态/单一职责，多为 `RefCounted`）：`hero_stats_service.gd`、`equipment_action_service.gd`、`equipment_effects_service.gd`、`equipment_authority_service.gd`、`skill_status_service.gd`、`snapshot_serialization_service.gd`、`steam_lobby_service.gd`、`{client,host,observe}_sync_flow_service.gd`、`network_state_collection_service.gd`、`network_status_display_service.gd`、`remote_avatar_{motion,runtime,visual}_service.gd`

控制器持有服务引用，并通过 **`NodePath` 导出 + `signal` 总线**解耦（典型 Godot 风格，没有 DI 容器）。

### 3.2 联机子系统（核心复杂度所在）

`net_session_controller.gd` 是整个客户端最大的脚本（4930 行），统一负责：

- **传输层抽象**：`enet_direct` / `steam_stub` / `steam_relay` 三种模式可切换，配置 `net_transport.cfg`
- **角色模型**：`offline / host / client`，`@export_enum`
- **大厅流程**：`SteamLobbyService`（创建/加入/可见性/邀请），暴露 `steam_lobby_changed`、`steam_lobby_join_requested` 信号
- **状态同步**：`HostSyncFlowService`（主机权威广播）、`ClientSyncFlowService`（客户端输入上行 + 远端预测）、`ObserveSyncService`（观战）、`SnapshotSerializationService`（紧凑序列化）、`NetworkStateCollectionService`（聚合英雄/装备/Boss/小怪/可破坏物）
- **远端 Avatar 三件套**：`Runtime`（生命/状态机）+ `Motion`（位置插值/预测）+ `Visual`（贴图特效）
- **Host Migration**：参数化 + 信号 `host_migration_state_changed`，与后端 `/host-migration/claim|confirm` 协同
- **自适应同步**：根据 mob 数量动态调整 `world_sync_interval`、chunk size、packet budget
- **预算/熔断**：`damage_request_budget_per_sec`、`damage_request_breaker_window_sec` —— 客户端到主机的伤害请求带 token bucket 限流和熔断器

### 3.3 数据驱动

| 文件 | 内容 |
|---|---|
| `data/item_db_map.json` (77 KB) | 物品/装备数据库 |
| `data/rogue_floor_progression_21.json` (61 KB) | 21 层楼层 + 5 档难度的怪物/奖励/Boss 配置 |
| `rogue_floor_balance.gd` | 平衡计算器（数值缩放） |
| `scene_flow_controller.gd` | 节奏点配置：`total_floor_count=21`, `reward_last_floor_index=17`, `shop_last_floor_index=18` |

---

## 4. Go 后端架构

### 4.1 设计模式：清洁架构 / 模块化单体

```
be/
├── cmd/
│   ├── api/       # HTTP API 入口
│   └── worker/    # 后台 Worker 入口（reward_jobs_processor）
├── internal/
│   ├── bootstrap/ # 手写 DI 容器（app.go / router.go / adapters.go / middleware.go）
│   ├── common/    # ctxkeys / identity
│   ├── platform/  # db (pgx pool) / jwt / migrate
│   ├── transport/ # http/response 统一错误响应
│   └── modules/
│       ├── auth/       # 鉴权（Steam Web + JWT）
│       ├── player/     # 玩家档案、天赋、Loadout
│       ├── inventory/  # 物品/货币/外观，版本号乐观锁
│       ├── commerce/   # 商店目录、DLC entitlement
│       ├── run/        # 单局（最大，16 文件）
│       ├── risk/       # 风控旗标
│       └── audit/      # 管理员审计
├── migrations/    # 数据库迁移
└── scripts/
```

### 4.2 关键工程化决策

- **Repo 双实现**：`Memory` + `Postgres` 共享同一接口，`bootstrap/app.go` 根据 `DATABASE_URL` 决定，便于本地/单测零依赖启动
- **集中路由**：`bootstrap/router.go` 是唯一的路由聚合点，便于审视 API 全貌
- **三层鉴权**：公开 / 玩家 JWT (`Authorization: Bearer`) / 管理员 (`X-Admin-Token` + `X-Admin-Actor`)
- **`RequestIDMiddleware`**：每请求注入 `X-Request-ID`，写入 `ctxkeys`，便于贯穿日志
- **错误码语义化**：领域错误 (`ErrProofInvalid`、`ErrRunAlreadyFinalized`、`ErrIdempotencyReplayMismatch` 等) 精确映射到 HTTP 状态码

### 4.3 `run` 模块 —— 反作弊 & 一致性中心

`be/internal/modules/run/` 是后端复杂度的核心：

- **`model.go`** 定义协议：`StartRunInput`、`ProofPayload`（30 秒分段哈希链 head/tail + segments）、`FinalStats`、`ClientMeta`
- **`service.go`** (42 KB) 编排：开局发 `runToken` + `seed` + `proofRule`，结束验证 proof，触发 risk + reward
- **`anti_cheat.go`** + `BasicRiskEngine`：根据 proof 段、清关时间、伤害峰值等判定 `accepted / pending_review / rejected`
- **`reward.go` + `reward_jobs*.go`**：奖励异步化——结算后写 `reward_jobs` 表，由 worker 进程拉取重试，管理员可 retry/approve/deny
- **`idempotency_postgres.go`**：所有写操作要求 `X-Idempotency-Key`（`finish-run`、`abort` 等），表 `idempotency_keys` 缓存请求哈希 + 响应体 24h
- **Host Migration / Reconnect 状态机**：DB 字段 `migration_epoch`、`reconnect_token_hash`、`host_migration_deadline_at`、`host_reconnect_deadline_at` + 多组超时窗（`RUN_HOST_RECONNECT_WINDOW`、`RUN_HOST_MIGRATION_WINDOW`、`RUN_RECONNECT_TOKEN_TTL`），全部环境变量可调

### 4.4 数据库设计要点

- **强外键 + ON DELETE CASCADE**：删除用户即清干净所有衍生数据
- **JSONB 半结构化**：`talents`、`loadout`、`items`、`proof_payload`、`evidence` 都用 JSONB
- **状态机用 SMALLINT + CHECK**：`run_sessions.status (0..4)`、`reward_status (1..3)`、`verdict (0..3)`
- **复合索引面向查询**：`(host_steam_id, created_at DESC)`、`(status, next_retry_at)` 为 worker 调度优化
- **乐观并发**：`inventories.version` 字段
- **审计独立表**：`admin_audit_logs` 不与业务表关联，纯追加

---

## 5. 客户端 ↔ 后端 协议契约

| Godot 行为 | 后端路由 | 关键负载 |
|---|---|---|
| 登录 | `POST /v1/auth/steam/login` | Steam ticket → JWT |
| 进商店 | `GET /v1/store/catalog` | 公开 |
| 同步 DLC | `POST /v1/entitlements/sync` | Steam DLC 列表 |
| 玩家档案 | `GET /v1/me/profile` / `PATCH /v1/me/loadout` | 天赋、装备槽 |
| 背包 | `GET /v1/me/inventory` | 物品/货币 |
| 历史 | `GET /v1/me/runs[/:id/detail|/reasons]` | 单局回放/风控理由 |
| 开局（Host） | `POST /v1/runs/start` | 模式/难度/Party → `runId+seed+runToken+proofRule` |
| 心跳 | `POST /v1/runs/:id/heartbeat` | 防止超时进入 `host_migration_wait` |
| Host 迁移 | `POST /v1/runs/:id/host-migration/{claim,confirm}` | `migration_epoch` 单调递增 |
| 玩家断线重连 | `POST /v1/runs/:id/reconnect/{request,confirm}` | TTL 60s 的一次性 token |
| 结算 | `POST /v1/runs/:id/finish` | proof + finalStats + rewardDraft，需 `X-Idempotency-Key` |
| 中止 | `POST /v1/runs/:id/abort` | 需 `X-Idempotency-Key` |
| 管理员 | `/v1/admin/{risk-flags,reward-jobs,audit-logs}` | `X-Admin-Token` |

**实时玩法不走后端**——通过 P2P/Steam Relay 直连，后端只在边界点（开局/结算/迁移/断线）介入并做权威裁决。

---

## 6. 资产工具链

`blender_convert.js` + `package.json` 揭示了**魔兽 3 资源 → glTF** 的转换流水线：

- `node-unrar-js` 解压 `.w3x`
- `w3x-parser` / `war3-model` 解析地图与 MDX 模型
- `@gltf-transform/*` 输出/优化 `.glb` 给 Godot 用
- 大量 `godot-game/modles/`（注：拼写应为 `models/`）和 `godot-game/effects/` 资源印证此链路

---

## 7. 客户端代码审查

### 7.1 统计快照

| 指标 | 数值 | 评价 |
|---|---|---|
| GDScript 总行数 | **26 659** | 单仓客户端规模中等偏大 |
| 超 1000 行脚本 | 6 个 | `net_session_controller` 4930、`hero_controller` 4925、`game_ui` 4400、`scene_flow_controller` 1874、`enemy_ai` 1790、`tauren_unit_ai` 1323 |
| `hero_controller.gd` 的 `@export` | **144 个** | 极端参数爆炸 |
| `hero_controller.gd` 的函数 | 243 个 | God Object |
| `net_session_controller.gd` 的 `@export` | 104 个 | 同上 |
| `class_name` 声明 | 25 / 31 个脚本 | 良好 |
| `has_method(...) + .call(...)` | **387 处** | 严重的"鸭子类型"耦合 |
| `TODO/FIXME/HACK` 注释 | **0 处** | 不合常理 |
| `push_warning / push_error` | 仅 16 处 | 错误日志几乎缺失 |
| Autoload（全局单例） | 0 | 全靠 `NodePath` + group 查找 |

### 7.2 致命问题（P0）

#### P0-1 三个 4000+ 行的 God Object

`hero_controller.gd`、`net_session_controller.gd`、`game_ui.gd` 三个文件占客户端代码 **52%**。

**`hero_controller.gd` 单类身兼数职**：输入处理、移动、自动攻击、闪现、急速、变身、毒、暴击、复活币、变身计数、网络指令推送、HP 条跟随、冷却管理、攻击锁、起始区恢复、装备效果、敌人伤害加成、战旗。

**布尔状态机失控**：同时存在 `_is_dead/_is_moving/_is_attacking/_haste_active/_is_transformed/_flash_mode/_attack_mode/_r_skill_mode/_input_locked_by_ui/_focus_lock/_ranged_q_backstep_active/_stop_move_hold_active/_network_attack_lock_active/...`，没有显式 FSM。组合爆炸时极易出现"复活动画期间又触发闪现"这种竞态。

**建议拆分**（`hero_controller.gd`）：

```
HeroInputController       ← 鼠标/键盘 → 意图
HeroMovementService       ← move_to / chase / backstep
HeroCombatService         ← 自动攻击 + 暴击 + 攻击动画时序
HeroSkillRouter           ← Q/W/E/R 四技能 + 闪现
HeroBuffService           ← haste / poison / transform
HeroNetSyncBridge         ← 与 NetSession 通信
HeroHUDAnchor             ← HP 条 / 攻击计数标签
HeroFSM                   ← 显式 enum 状态 + 转移表
```

`net_session_controller` 同理，可拆为 `NetTransport`、`HostBroadcaster`、`ClientInputSender`、`HostMigrationFSM`、`SteamLobbyAdapter`、`DamageArbiter`。

#### P0-2 鸭子类型滥用（387 处 `has_method+call`）

```gdscript
# 反模式
if net_ctrl.has_method("notify_local_hero_ready"):
    net_ctrl.call("notify_local_hero_ready")
```

**问题**：方法名是字符串，重命名编辑器搜不到；返回值类型未知，运行期才报错；阻断 IDE 跳转/补全。

**修法**：改为 `class_name NetSessionController` + 静态类型引用：

```gdscript
const NetSessionController := preload("res://net_session_controller.gd")
@onready var _net: NetSessionController = ...
_net.notify_local_hero_ready()  # 编译期检查 + 重命名安全
```

#### P0-3 网络协议字段表硬编码在客户端

`snapshot_serialization_service.gd:4-77` 把 5 张 `*_ALLOWED_KEYS` 数组写死在客户端。Host 和 Client 必须**字符串完全一致**才能正确序列化反序列化。

- 没有版本号、字段加减无法做向后兼容
- 后端 `proofRule.version` 已埋点，但客户端协议没有
- 重命名一个 key 需要全仓搜索 + 双端同步

**修法**：抽出 `network_schema.gd` 定义 schema + version；序列化器自动读取；为协议 fuzzing 做准备。

#### P0-4 `_process` 单帧任务过重

`hero_controller._process` 每帧无差别调用 20+ 子任务（光标、HP 条、再生、冷却、毒、装备效果、起始区恢复、战旗、变身、攻击锁……）。可拆分到不同频率：

- 60 Hz：移动、动画
- 10–20 Hz：HP/MP 再生、冷却 UI、毒计时
- 1–5 Hz：起始区恢复、装备效果计时
- 事件驱动：HP 条只在受伤时刷新，光标只在状态变化时更新

### 7.3 严重问题（P1）

| ID | 问题 | 简述 |
|---|---|---|
| P1-1 | **缺乏错误日志** | 全仓仅 16 处 `push_warning/push_error`，需 Logger autoload + 分类 + 节流 + 上传 audit |
| P1-2 | **节点查找双轨** | `get_first_node_in_group` 与 `@export NodePath` 混用。建议引入 `Services` autoload 统一持有 |
| P1-3 | **`preload` 散落** | 同样的资源在多个文件重复 preload，建议 `paths.gd` 常量类 + class_name 引用 |
| P1-4 | **`@export` 参数爆炸** | `hero_controller` 144 个 @export，应迁移至 `.tres` Resource 数据驱动 |
| P1-5 | **Boolean flag soup** | 多种"模式"互斥关系隐藏在分散 if 中，应改为显式 `enum InputMode` + `_set_input_mode` |
| P1-6 | **零客户端测试** | `test-results/` 空目录，建议引入 GdUnit4，优先覆盖纯函数 service |

### 7.4 中等问题（P2）

| ID | 问题 | 简述 |
|---|---|---|
| P2-1 | 网络数值在 inspector 上调，会污染场景文件版本控制 |
| P2-2 | `modles/` 拼写错误；`tmp/` 应入 `.gitignore`；50+ 脚本平铺根目录 |
| P2-3 | 根目录 `a.tscn` 命名不规范 |
| P2-4 | 协议层缺统一错误码客户端封装 |
| P2-5 | `combat_scene_utils.gd` 8KB "utils" 是反模式 |

### 7.5 做得好的地方（保留 / 推广）

1. **`HostSyncFlowService` 是教科书级别的"纯函数式服务"**：全 `RefCounted` + 输入字典 → 输出字典，无副作用。自适应丢包退避（`severe_over_budget` / `medium_pressure` / chunk size 升降）设计成熟。**这种风格应推广到其他 service**。
2. **传输层抽象**（`enet_direct / steam_stub / steam_relay`）+ `net_transport.cfg` 配置化是优秀工程化决策。
3. **Snapshot 用 allow-list 过滤字段**（虽然字段表本身有问题）防止序列化敏感/不必要数据，思路正确。
4. **远端 Avatar 三件套分层** (`Runtime` + `Motion` + `Visual`) 职责清晰。
5. **客户端伤害请求带预算 + 熔断器**——客户端就做了限流，是反作弊纵深防御。
6. **Host Migration 状态机参数化**（4 个时间窗）和后端的 `migration_epoch` 设计协同得当。

---

## 8. 关键架构决策与取舍

### ✅ 优点

1. **关注点清晰分离**：实时性 → P2P；公平性/经济 → 后端权威。避免"全权威服务器"的成本，又不放弃反作弊。
2. **Repo 双实现**（Memory + Postgres）：后端零依赖即可启动，单测无需 DB。
3. **奖励异步化 + 幂等键**：结算请求安全可重放，下游故障不影响玩家结算体验。
4. **proof 链 + 风控双轨**：拒绝 / 人工复核 / 接受三档，比"非黑即白"更稳。
5. **环境变量调参**：迁移/重连窗口全部可调，便于线上根据网络质量动态调整。
6. **集中路由**：`router.go` 一眼看完所有 API，新成员上手快。

### ⚠️ 风险 / 可改进

1. **客户端 God Object**：3 个文件占 52% 代码量；`net_session_controller`、`hero_controller`、`game_ui` 必须拆分。
2. **后端 `run` 服务巨大**：`service.go` 42 KB，建议按用例切分（`start` / `finish` / `migration` / `reconnect`）。
3. **目录扁平**：`godot-game/` 根目录 50+ 脚本，`run/` 子包 16 文件——都应进一步分组。
4. **拼写**：`modles/` → `models/`；`tmp/` 进 `.gitignore`。
5. **后端无限流**：仅靠 idempotency 防重放，建议加 IP/用户级 rate limit 中间件。
6. **协议版本化不完整**：`ProofRule.Version` 已埋点，但 API 路径只有 `/v1`，缺 `clientBuild` ↔ `proofRule.version` 兼容矩阵。
7. **Steam Web 验证 5s 超时**：海外 RTT 可能不够。

---

## 9. 重构路线图

| 阶段 | 工作量 | 价值 | 风险 | 内容 |
|---|---|---|---|---|
| **R1** | 2-3 天 | 极高 | 低 | 建立日志 / Autoload / 单元测试基础设施（`Services` autoload + `Logger` + GdUnit4） |
| **R2** | 3-5 天 | 高 | 低 | 给 5 个纯函数式 service 写测试，固化协议 schema（抽 `network_schema.gd`） |
| **R3** | 1-2 周 | 极高 | 中 | `hero_controller` 拆成 7-8 个组件 + 显式 FSM |
| **R4** | 1-2 周 | 极高 | 中高 | `net_session_controller` 拆成 6 个子模块 |
| **R5** | 3-5 天 | 高 | 低 | 消除 `has_method+call`，全部走 `class_name` 静态类型 |
| **R6** | 1-2 天 | 中 | 低 | 脚本目录化 + 资源路径统一 + 修拼写 |
| **R7** | 1-2 周 | 中 | 中 | `game_ui` 按 panel 拆分 |
| **R8** | 3-5 天 | 中 | 低 | 后端 `run/service.go` 按用例切包；加 rate limit 中间件 |

**最低成本最高回报组合**：R1 + R2 + R5（合计约一周），可立刻让代码具备演进能力。

---

## 10. 一句话总结

> **整体架构**：模块化单体后端 + 权威主机客户端 + 异步奖励管线，思路与边界划分都很对。
>
> **工程亮点**：`run` 模块的"状态机 / proof / 幂等"三件套；客户端可热切换的传输层抽象；`HostSyncFlowService` 纯函数式自适应同步。
>
> **最大债务**：客户端 3 个 5000 行 God Object、387 处鸭子类型调用、零客户端测试、扁平目录结构。
>
> **建议下一步**：先做 R1+R2+R5 的脚手架重构，再分模块逐步拆 god class。

---

*— 报告完 —*
