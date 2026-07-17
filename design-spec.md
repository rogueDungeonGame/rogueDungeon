# Rogue Dungeon Design Specification

> Generated from a design consultation with oiloil-ui-ux-guide.
> Style direction: Pixel Rogue Dungeon + Warcraft III: The Frozen Throne HUD structure.

## 1. Design Direction

- **Product**: 多人肉鸽地牢游戏，玩家在战斗、商店、装备、天赋选择之间快速切换。
- **Style family**: brand-driven game HUD.
- **References**: Warcraft III: The Frozen Throne bottom command HUD; pixel roguelike dungeon UI.
- **Tone**: 暗黑、战斗感、地牢、像素、紧凑。
- **Hard constraints**: 战斗中信息必须可快速读取；中文优先；不做现代网页卡片风。
- **Locale**: primary `zh-CN`.

## 2. Color

### Core

- `ui_bg`: `#130F18` — 主 HUD 底色，接近黑紫。
- `ui_surface`: `#1B1522` — 面板内部底色。
- `ui_surface_deep`: `#08070B` — 小地图、头像、空槽底。
- `ui_border`: `#C7A833` — 主金色边框。
- `ui_border_dark`: `#73591A` — 暗铜边框。
- `ui_text`: `#F2EAC7` — 主文字。
- `ui_text_dim`: `#9A8C6B` — 次级文字。
- `ui_disabled`: `#4A4234` — 禁用状态。

### Semantic

- `hp`: `#D9332E` — 生命。
- `hp_high`: `#20D93D` — 满血/安全生命条。
- `mp`: `#245CFF` — 魔法。
- `gold`: `#FFD75A` — 金币、关键资源。
- `danger`: `#E04436` — Boss、摧毁、危险。
- `poison`: `#63D86B` — 毒、自然、回复。
- `cooldown`: `#FF8A3A` — 冷却与等待。
- `observe`: `#6EC8FF` — 观察模式。

### Equipment Faction Colors

- 摧毁：`#E04AE0`
- 负债：`#FFD84A`
- 神器：`#F2C84A`
- 泰坦：`#D9A64A`
- 通灵：`#72D9C2`
- 战旗：`#33E680`
- 备战：`#F28C3F`
- 结算：`#E6A342`
- 充能：`#4AAFFF`
- 咒文：`#A866FF`
- 火花：`#FF663D`
- 硬币：`#FFE64A`
- 无派系：`#BFBFBF`

## 3. Typography

- **UI body**: Godot default sans until a pixel-capable CJK font is added.
- **Future font target**: pixel-style CJK readable font for headings and numbers.
- **Numbers**: prefer tabular/monospace appearance where possible.

### Type Scale

- Tiny labels: `10px`
- Slot numbers / captions: `11px`
- Dense stats: `12px`
- Buttons: `13px`
- Section titles: `14px`
- Hero name / resources: `16px`
- Shop title: `20px`
- Talent title: `28px`

### Copy Rules

- Visible copy must describe game state or player action.
- No explanatory meta text inside the HUD.
- Chinese labels stay short: `攻击`、`护甲`、`刷新`、`升级`、`摧毁`、`观战中`。

## 4. Spacing

- Base unit: `4px`.
- Allowed scale: `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64`.
- Density: compact.
- Bottom HUD height target: `240px` at `1600x900`.
- Inner panel gap: `8-12px`.
- Inventory slot size: `38-44px`.
- Skill button size: `60-64px`.

## 5. Radius

- `radius_none`: `0px` — bottom HUD outer shell.
- `radius_pixel`: `2px` — inventory slots, bars.
- `radius_panel`: `4px` — HUD inner panels.
- `radius_popup`: `6px` — shop and tooltip panels.
- Avoid large modern rounded corners. Talent cards may use `4-6px`, not `18px`.

## 6. Border And Elevation

- Strategy: border.
- Main HUD border: `3px` top gold line.
- Inner panels: `2px` dark copper border.
- Slots/buttons: `1-2px` border.
- Shadows: N/A — use borders and dark surfaces instead.
- Hover state: brighten border to `ui_border`.
- Disabled state: darken border and text.

## 7. Motion

- Vocabulary: minimal.
- Button hover: instant or `80ms`.
- Popup open/close: `120ms` fade only.
- Forbidden: bounce, elastic scale, large slide animations.

## 8. Icon System

- **Set**: brand-custom game icons.
- **Treatment**: pixel/art icon first; monochrome text fallback allowed.
- **Sizes**: inventory `32px`, skill `36-44px`, shop item `48-64px`.
- **Mixing**: do not mix modern line icons into game HUD.
- Skill buttons may keep text labels until icons exist.

## 9. Decoration

| Surface | Gradients | Textures | Motifs |
|---|---|---|---|
| Main HUD | none | subtle stone / metal texture later | gold/copper frame |
| Inventory | none | slot dark stone | rarity/faction border |
| Shop | none | merchant shelf / parchment-dark later | item grid |
| Talent | none | rune card / carved stone later | rune marks |
| Debug overlay | none | none | none |

## 10. Component Conventions

### Main HUD

- Fixed at bottom.
- Warcraft III-like sections:
  - left: minimap
  - middle-left: hero portrait, HP/MP, stats, inventory
  - middle-right: skills and commands
  - right: Boss or current target
- No nested decorative cards.
- Information should be readable in one scan while fighting.

### Buttons

- Shape: square or near-square.
- Border: copper by default, gold when active.
- Active background: `#1F1930`.
- Inactive background: `#141119`.
- Disabled text: `ui_text_dim`.
- Primary action should use label text, not icon-only.

### Bars

- HP/MP bars use flat fill.
- Border radius `2px`.
- Values shown as `current / max`.
- HP danger state switches toward red below threshold.

### Inventory

- 6 fixed slots.
- Empty slot uses deep surface and dim slot number.
- Item rarity/faction is shown by border color.
- Use/destroy states must visibly change slot border.

### Shop

- Large overlay panel, dark stone surface.
- Item cards are grid cells, not product cards.
- Gold, shop level, refresh, upgrade stay near top.
- Hover tooltip may show item name, level, faction, price, stat text.

### Talent Selection

- Three choices.
- Style as rune/card panels.
- Must show title, short effect, pending choice count.
- Selection feedback must be immediate.

### Debug Overlay

- Debug overlay may stay plain.
- It must not define the production visual language.

## 11. Surfaces

### Battle HUD

- Primary surface.
- Keep current bottom layout.
- Reduce visual noise before adding new decoration.
- First improvement target: consistent colors, radii, borders, font sizes.

### Shop

- Secondary high-use surface.
- Needs pixel dungeon merchant feel.
- Avoid modern web-store spacing or large blank panels.

### Talent Popup

- Important decision surface.
- Should feel like choosing dungeon runes.
- Current large rounded card style should be changed to pixel/rune panels.

### Observe Mode

- Use `observe` blue accents.
- Observed target should be obvious without hiding the local HUD structure.

## 12. Anti-Patterns

- No modern SaaS card layout.
- No large rounded cards.
- No gradient orbs or decorative blobs.
- No oversized hero sections.
- No icon-only controls unless the icon is already game-standard.
- No hiding combat-critical values behind hover.
- No bright neon cyberpunk palette.
- No beige parchment as the dominant theme.

## 13. Implementation Notes For Godot

- Centralize tokens before major visual changes.
- Keep `GameUI` as orchestration only.
- Visual token ownership should move into a small UI theme/config script or resource.
- Existing controllers should receive style tokens rather than hardcoding colors.
- Do not change gameplay logic while applying visual style.

## 14. Open Questions

- Final pixel-capable Chinese font is not selected.
- Final production icon pack is not selected.
- 2D placeholder art versus 3D model direction remains separate from UI design.
