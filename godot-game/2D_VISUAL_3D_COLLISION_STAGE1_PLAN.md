# 2D Visual + 3D Collision Stage 1 Plan

> Date: 2026-05-07
> Scope: `godot-game/`
> Goal: Keep combat, navigation, and networking in 3D while replacing gameplay-facing visuals with 2D assets.

---

## 1. Decision Summary

The project will use a `2D visual layer + 3D collision layer + profile-driven state collision` architecture.

This means:

- Characters, props, gates, trees, fences, shops, and most gameplay effects can become 2D visuals.
- Navigation, blocking, combat range checks, line tests, and network geometry validation stay 3D.
- Visual presentation and gameplay collision are separate systems.
- The main body collider stays stable in most states.
- State changes mostly affect `hurtbox` and `hitbox`, not the main body collider.
- Only large body-form changes such as transform, mount, giant mode, or death pass-through switch the main body collision profile.

This approach fits the current codebase because several systems already assume a stable `CollisionBody/CollisionShape3D` layout:

- `hero_controller.gd`
- `enemy_ai.gd`
- `scene_flow_controller.gd`
- `net_session_controller.gd`

---

## 2. Stage 1 Goal

Stage 1 is not a full migration. Its goal is to prove the architecture with the smallest safe slice.

Stage 1 target scope:

- 1 local hero converted to 2D visuals
- 1 enemy converted to 2D visuals
- trees converted to 2D visuals
- shop converted to 2D visuals
- gate converted to 2D visuals
- 1 projectile effect converted to 2D visuals
- 1 ground AOE effect converted to 2D visuals
- remote avatars still work with correct HP bar anchors

Stage 1 explicitly does not require:

- full roster conversion
- all skills migrated
- perfect occlusion polish
- all summons migrated
- full animation direction system

---

## 3. Architecture Rules

### 3.1 Hard Rules

- Do not bind gameplay collision to sprite silhouette.
- Do not remove existing `CollisionBody/CollisionShape3D` nodes during visual migration.
- Do not let normal attack or cast animation resize the main body collider every frame.
- Do not use mesh bounds as the primary long-term anchor source for 2D units.
- Do not make 2D art responsible for hit detection.

### 3.2 Stable Gameplay Contracts

These contracts must remain true after Stage 1:

- click enemy still selects the enemy
- click shop still opens shop interaction flow
- gate still blocks and can still be destroyed
- trees still block movement
- local and remote damage geometry checks still operate in 3D
- knockback, overlap, and chase distance remain stable

---

## 4. Node Naming Standard

All future converted units and props should use these names exactly where applicable.

### 4.1 Character Template

```text
UnitRoot (Node3D)
VisualRoot (Node3D)
SpritePivot (Node3D)
Sprite3D or AnimatedSprite3D
CollisionRoot (Node3D)
CollisionBody (StaticBody3D or CharacterBody3D-owned helper)
CollisionShape3D
HurtboxRoot (Node3D)
Hurtbox (Area3D)
HurtboxShape3D
HitboxRoot (Node3D)
BasicAttackHitbox (Area3D)
SkillHitboxPrimary (Area3D)
SkillHitboxSecondary (Area3D)
AnchorRoot (Node3D)
HeadAnchor (Node3D)
ProjectileOrigin (Node3D)
ShadowAnchor (Node3D)
SelectionAnchor (Node3D)
OccluderAnchor (Node3D)
```

### 4.2 Prop Template

```text
PropRoot (Node3D)
VisualRoot (Node3D)
CollisionBody (StaticBody3D)
CollisionShape3D
InteractionArea (Area3D)
InteractionShape3D
AnchorRoot (Node3D)
HeadAnchor (Node3D)
OccluderRoot (Node3D)
```

### 4.3 Gate Template

```text
GateRoot (Node3D)
GateBody (Node3D)
VisualRoot (Node3D)
CollisionBody (StaticBody3D)
CollisionShape3D
AnchorRoot (Node3D)
HpBarAnchor (Node3D)
ProjectileOrigin (Node3D)
```

---

## 5. Collision Layer Model

Each actor or interactable object should treat collision as multiple responsibilities.

### 5.1 Body Collider

Purpose:

- navigation blocking
- physical occupancy
- overlap radius lookup
- click ray target chain
- network geometry reference

Rules:

- should be stable in most states
- should be simple geometry
- should roughly match ground footprint, not visual silhouette

Recommended shapes:

- hero or enemy: `CapsuleShape3D`
- gate: `BoxShape3D`
- tree trunk: `BoxShape3D` or `CylinderShape3D`
- fence segment: thin `BoxShape3D`
- shop building: `BoxShape3D`

### 5.2 Hurtbox

Purpose:

- whether this target can be hit right now

Rules:

- may change by state
- may be disabled during invulnerable windows
- may be shorter or thinner than the sprite in some poses

### 5.3 Hitbox

Purpose:

- where this action deals damage

Rules:

- driven by animation timing or skill timing
- can be ephemeral
- should be disabled by default

### 5.4 Interaction and Selection

Purpose:

- shop click
- object focus
- destroy cursor hover
- future pickup or talk interactions

Rules:

- should be independent from visual size when needed
- should not require precise sprite clicking

---

## 6. CollisionProfile Definition

Stage 1 should introduce one reusable data structure: `CollisionProfile`.

Suggested first version:

```text
profile_id: String
body_shape: String
body_radius: float
body_height: float
body_size: Vector3
body_offset_y: float
hurtbox_shape: String
hurtbox_radius: float
hurtbox_height: float
hurtbox_size: Vector3
hurtbox_offset: Vector3
selection_radius: float
head_anchor_height: float
projectile_origin_offset: Vector3
shadow_anchor_offset: Vector3
occluder_anchor_height: float
hp_bar_height: float
network_radius_override: float
allow_body_passthrough_when_dead: bool
```

Notes:

- `body_shape` supports `capsule`, `box`, `cylinder`
- `body_size` is only used for box-based profiles
- `hurtbox_shape` can differ from `body_shape`
- `hp_bar_height` should become the primary source for bars after 2D conversion
- `network_radius_override` is useful when visual scaling differs from gameplay radius

### 6.1 Example Profiles

#### Melee Hero Base

```text
profile_id = "hero_melee_base"
body_shape = "capsule"
body_radius = 50.0
body_height = 150.0
body_offset_y = 75.0
hurtbox_shape = "capsule"
hurtbox_radius = 46.0
hurtbox_height = 138.0
hurtbox_offset = Vector3(0.0, 72.0, 0.0)
selection_radius = 58.0
head_anchor_height = 180.0
projectile_origin_offset = Vector3(0.0, 100.0, 12.0)
shadow_anchor_offset = Vector3.ZERO
occluder_anchor_height = 120.0
hp_bar_height = 200.0
network_radius_override = 50.0
allow_body_passthrough_when_dead = true
```

#### Gate Base

```text
profile_id = "gate_base"
body_shape = "box"
body_size = Vector3(180.0, 220.0, 60.0)
body_offset_y = 110.0
hurtbox_shape = "box"
hurtbox_size = Vector3(180.0, 220.0, 60.0)
hurtbox_offset = Vector3(0.0, 110.0, 0.0)
selection_radius = 120.0
head_anchor_height = 260.0
projectile_origin_offset = Vector3(0.0, 140.0, 0.0)
shadow_anchor_offset = Vector3.ZERO
occluder_anchor_height = 180.0
hp_bar_height = 280.0
network_radius_override = 90.0
allow_body_passthrough_when_dead = true
```

---

## 7. State Collision Matrix

This matrix defines what changes during runtime.

| State | Body Collider | Hurtbox | Hitbox | Notes |
|---|---|---|---|---|
| `idle` | stable | enabled | disabled | default |
| `move` | stable | enabled | disabled | default |
| `chase` | stable | enabled | disabled | default |
| `basic_attack` | stable | enabled | timed | hitbox turns on only in attack window |
| `cast` | stable | enabled | skill-dependent | usually projectile or area-based |
| `dash` | stable | reduced or disabled | disabled | depends on invulnerability design |
| `flash` | stable | disabled during travel | disabled | teleport should not resize body |
| `knockback` | stable | enabled | disabled | geometry remains consistent |
| `dead` | disabled or zero-layer | disabled | disabled | may allow pass-through |
| `transformed` | switch profile | switch profile | profile-dependent | only major body-form change |

Implementation rule:

- normal animation states do not swap main body profile
- form-change states do swap main body profile

---

## 8. Visual Placement Standard

### 8.1 Character Sprites

- sprite pivot must be at foot center
- shadow uses `ShadowAnchor`
- HP bar uses `HeadAnchor` or profile `hp_bar_height`
- projectile launch uses `ProjectileOrigin`
- selection circle aligns to `SelectionAnchor` or body center

### 8.2 Trees

- collision only covers trunk
- crown is visual only
- crown can later fade when hero passes behind

### 8.3 Fences

- collision uses separate thin box per segment
- corners use dedicated short segments
- avoid one oversized collider for a full chain

### 8.4 Shop

- collision covers only the impassable footprint
- decorative roof and sign do not block
- keep a dedicated interaction area if needed

### 8.5 Gate

- collision body stays authoritative
- HP bar anchor becomes explicit
- model collision stays disabled

---

## 9. Files To Touch In Stage 1

### 9.1 Required First-Wave Files

- `hero_controller.gd`
- `enemy_ai.gd`
- `boss_gate.gd`
- `scene_flow_controller.gd`
- `remote_avatar_runtime_service.gd`
- `remote_avatar_visual_service.gd`
- primary hero scene
- primary enemy scene
- tree visual scene or main scene tree nodes
- shop visual scene or main scene tree nodes
- gate visual scene or gate creation flow

### 9.2 Recommended Responsibility Split

#### `hero_controller.gd`

Add or refactor:

- `apply_collision_profile(profile_id)`
- `apply_runtime_collision_state(state_id)`
- `ensure_anchor_nodes()`
- `ensure_hurtbox_nodes()`
- `ensure_hitbox_nodes()`

Keep compatibility:

- preserve `CollisionBody/CollisionShape3D`
- preserve click and target resolution flow

#### `enemy_ai.gd`

Refactor carefully:

- keep `_get_horizontal_collision_radius()` contract intact
- allow profile-driven radius if profile metadata is present
- future-proof skill overlap logic against transformed sizes

#### `boss_gate.gd`

Change:

- prefer explicit `HpBarAnchor` over mesh height estimation
- keep destroy flow unchanged

#### `scene_flow_controller.gd`

Change:

- gate creation should instantiate `VisualRoot`
- keep generated `CollisionBody` authoritative
- allow future 2D gate scene swap without logic rewrite

#### `remote_avatar_runtime_service.gd`

Change:

- resolve remote 2D avatar scenes by profile or model key
- keep collision disabled for remote avatars

#### `remote_avatar_visual_service.gd`

Change:

- HP bar height priority:
  1. `hero_state["hp_bar_height"]`
  2. `HeadAnchor`
  3. mesh bound fallback

---

## 10. Stage 1 Checklist

### 10.1 Data and Structure

- Define initial `CollisionProfile` schema
- Add 1 melee hero profile
- Add 1 enemy profile
- Add 1 gate profile
- Add explicit anchor nodes to hero, enemy, and gate

### 10.2 Hero Conversion

- Create `VisualRoot` under hero
- Replace 3D hero model with 2D visual node
- Keep `CollisionBody/CollisionShape3D`
- Add `HeadAnchor`
- Add `ProjectileOrigin`
- Add `ShadowAnchor`
- Verify click selection still works
- Verify melee attack range still feels correct

### 10.3 Enemy Conversion

- Create `VisualRoot` under enemy
- Replace 3D enemy model with 2D visual node
- Keep current collider contract
- Add `HeadAnchor`
- Verify AI chase and overlap damage still work

### 10.4 Environment Conversion

- Replace tree visuals with 2D visuals
- keep tree `StaticBody3D` colliders
- replace shop visuals with 2D visuals
- keep shop body collider and click chain
- replace gate visuals with 2D visuals
- keep gate collision and destroy logic

### 10.5 Effect Conversion

- convert 1 projectile visual to 2D
- convert 1 ground targeting or AOE visual to 2D
- verify effect origin uses anchors, not mesh assumptions

### 10.6 Networking

- verify local state still exports `pos` and `yaw`
- export `hp_bar_height` from local hero state
- verify remote avatar HP bar placement
- verify remote hit validation still passes existing geometry checks

---

## 11. Acceptance Criteria

Stage 1 is complete only if all items below are true.

- hero can move, chase, attack, cast, and take damage normally
- enemy can move, chase, attack, cast, and take damage normally
- tree collision still blocks movement correctly
- shop click still works
- gate blocks before destruction and opens flow after destruction
- local melee range still feels consistent
- local projectile origin looks believable
- damage popups and HP bars do not float far off the unit
- remote avatars display correctly with stable HP bar placement
- no regression in gate destroy flow
- no regression in enemy overlap or knockback edge cases

---

## 12. Risks To Watch

### 12.1 High Risk

- body collider accidentally tied to sprite size
- gate HP bar anchor breaks after 2D swap
- remote avatars lose anchor accuracy
- click detection breaks because collider chain changes

### 12.2 Medium Risk

- tree crowns visually overlap heroes in awkward ways
- sprite pivot placement causes foot sliding illusion
- projectile spawn point looks too low or too high

### 12.3 Low Risk

- billboard visuals look flat before direction system is added
- temporary mixed 2D and 3D visuals look stylistically inconsistent

---

## 13. Recommended Implementation Order

1. Add `CollisionProfile` data structure.
2. Refactor hero collider setup to use profiles.
3. Add hero anchors and runtime collision state API.
4. Convert one local hero visual to 2D.
5. Convert one enemy visual to 2D.
6. Convert gate visual and explicit HP anchor.
7. Convert trees and shop visuals.
8. Export and consume HP bar anchor metadata for remote avatars.
9. Convert one projectile and one ground effect.
10. Run focused gameplay verification.

---

## 14. Suggested Stage 1 Deliverables

- 1 planning doc: this file
- 1 `CollisionProfile` implementation
- 1 converted hero scene
- 1 converted enemy scene
- 1 converted gate visual path
- 1 converted tree visual path
- 1 converted shop visual path
- 1 remote avatar anchor fix

---

## 15. Immediate Next Step

The next practical task should be:

`Introduce CollisionProfile support in hero_controller.gd and add explicit anchor nodes to the current hero scene without changing gameplay behavior yet.`

That gives the project a safe foundation before any large visual swap.
