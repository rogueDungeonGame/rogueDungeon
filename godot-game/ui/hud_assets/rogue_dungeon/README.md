# Rogue Dungeon HUD Assets

Source mockup:
`design-mockups/rogue-dungeon-main-hud-1920x1080-equipment-3x2-skills-3x4.png`

Use in Godot:

- `panel_*_frame.png`: use with `NinePatchRect` or `StyleBoxTexture`.
- `slot_item_*.png`: item slot frame by rarity color.
- `skill_button_*.png`: skill or command button frame.
- `bar_frame_*.png`: draw as frame above a dynamic fill bar.
- `hud_bottom_shell.png`: full-width HUD shell for fixed 1920x1080 layout reference.
- `rogue_hud_assets.json`: source rects and suggested nine-patch margins.
- `_preview_rogue_hud_assets.png`: visual check sheet only.

Dynamic content should remain separate: text, icons, minimap, stats, item images, skill images, and bar fill values.
