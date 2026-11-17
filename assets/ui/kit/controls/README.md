# OMEN control, HUD, and collection skins

These are isolated, text-free sRGB PNG assets for Godot controls. The editable
source is `generate.py`; run it with Python 3 and Pillow to rebuild the PNGs and
`manifest.json`. Geometry is clipped steel over graphite, with subtle wear
confined to the corner slices. Labels, values, and icons belong in Godot nodes.

The dimensions below are working sizes for a 1920×1080 desktop interface.
Scale with the UI when needed. Each named state is a separate PNG. All files
have transparent pixels outside their silhouettes; portrait and thumbnail
frames also have transparent centers. Palette values match
`assets/ui/STYLE_TOKENS.md`.

| Asset family | Size (px) | States/variants | 9-slice margin (all sides) | Text/content safe area |
|---|---:|---|---:|---|
| `ui_checkbox` | 48×48 | unchecked, unchecked_hover, checked, checked_hover, indeterminate, focused, disabled | fixed | 10,10–38,38 |
| `ui_radio` | 48×48 | off, off_hover, on, on_hover, focused, disabled | fixed | 8,8–40,40 |
| `ui_toggle` | 104×48 | off, off_hover, on, on_hover, focused, disabled | fixed | thumb and indicator only |
| `ui_slider_track` | 360×28 | default, disabled | 8 px | 12,8–348,20 |
| `ui_slider_fill` | 360×28 | ash, parallax, strain, covenant, aegis | clipped fill | no text |
| `ui_slider_thumb` | 38×44 | default, hover, pressed, disabled | fixed | no text |
| `ui_scrollbar_*_track` | 24×192 vertical, 192×24 horizontal | default | 6 px | no text |
| `ui_scrollbar_*_thumb` | 24×64 vertical, 64×24 horizontal | default, hover, pressed | 6 px | no text |
| `ui_progress_track` | 480×48 | default, disabled | 12 px | 16,4–464,44 |
| `ui_progress_fill` | 480×48 | success, warning, error | clipped fill | no text |
| `ui_resource_track` | 320×48 | default, disabled | 12 px | 16,4–304,44 |
| `ui_resource_fill` | 320×48 | five faction accents | clipped fill | no text |
| `ui_histogram_track` | 32×148 | default, disabled | 8 px | no text |
| `ui_histogram_fill` | 32×148 | five faction accents | clipped fill | no text |
| `ui_tab` | 240×64 | default, hover, selected, disabled | 16 px | 24,8–216,56 |
| `ui_filter_chip` | 160×48 | default, hover, selected, disabled | 12 px | 20,8–140,40 |
| `ui_segmented_option` | 160×52 | default, hover, selected, disabled | 12 px | 20,8–140,44 |
| `ui_pagination_button` | 48×48 | default, hover, selected, disabled | 8 px | centered icon |
| `ui_hud_portrait_frame` | 128×128 | default, targeted, damaged | fixed | transparent 16,16–112,112 |
| `ui_hud_health`, `ui_hud_resource`, `ui_hud_timer` | 160×64 | default, active, disabled | 16 px | 28,12–136,52 |
| `ui_hud_counter` | 96×48 | default, active, disabled | 16 px | 28,12–72,36 |
| `ui_hud_phase` | 228×64 | default, active, disabled | 16 px | 28,12–204,52 |
| `ui_hud_action` | 320×72 | default, active, disabled | 16 px | 28,12–296,60 |
| `ui_hud_turn_marker` | 48×48 | default, active, complete | fixed | symbol only |
| `ui_deck_row` | 640×72 | default, hover, selected, disabled | 16 px | 110,10–617,62 |
| `ui_card_thumbnail_slot` | 128×160 | default, hover, selected | fixed | transparent 14,14–114,146 |
| `ui_quantity_chip` | 80×48 | default, selected | 12 px | 19,10–61,38 |
| `ui_status_chip` | 180×48 | neutral, buff, debuff | 12 px | 19,10–161,38 |
| `ui_inventory_slot` | 144×144 | default, hover, selected, locked | fixed | 14,14–130,130 |
| `ui_quest_row` | 400×72 | active, complete, locked | 16 px | 78,10–377,62 |
| `ui_objective_chip` | 240×48 | active, complete, locked | 12 px | 19,10–221,38 |
| `ui_toast_indicator` | 24×128 | success, warning, error, info | 6 px | decorative edge |

For stretchable skins, assign the PNG to `StyleBoxTexture` and set all four
texture margins to the listed value. The `*_fill` images are meant to be
clipped by a `TextureProgressBar` or shader as their value changes, not stretched.
Use the appropriate state image with corresponding text contrast in the theme.
The selected tabs/chips have a bottom rule as well as a colour accent, and
semantic states carry their own geometry so the UI does not rely on colour
alone. Put the global icon SVGs on top of icon-only controls where needed.

`manifest.json` records each individual file's size, state, safe area, and
slice margin in a machine-readable form. No external textures or recordings
are used. The source generator is available; the controls have no SVG
equivalents because their edge wear and bevel are raster-rendered.
