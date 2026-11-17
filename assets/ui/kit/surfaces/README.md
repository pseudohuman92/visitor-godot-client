# OMEN production surfaces

These are isolated, text-free interface skins for the dark industrial OMEN
visual system. Their centers are quiet graphite; fine scratches, bevels and
small accent marks stay near the corners. Each transparent PNG has a matching
Godot 4 `StyleBoxTexture` `.tres` with four configured slice margins and
content padding. Load the `.tres` directly in a Theme override or a Control's
style override. The horizontal and vertical center regions stretch smoothly.

`manifest.json` is the per-file source of dimensions, state, accent token,
safe content rectangle and nine-slice margins. Coordinates are in source
pixels, with the safe rectangle written as `[left, top, right, bottom]`.

| Family | Source size | Slice margins (L/T/R/B) | States or variants |
|---|---:|---:|---|
| Text buttons | 320×96 | 24/24/24/24 | Primary, secondary, danger, ghost; default, hover, pressed, disabled, focused, selected |
| Icon button | 96×96 | 24/24/24/24 | Same six states; icon remains a separate overlay |
| Faction buttons | 320×96 | 24/24/24/24 | Ash, Parallax, Strain, Covenant, Aegis; same six states |
| Standard panel | 1024×768 | 32/32/32/32 | Default |
| Modal panel | 1024×768 | 40/40/40/40 | Default |
| Inset panel | 512×384 | 24/24/24/24 | Default |
| Tooltip panel | 480×240 | 24/24/24/24 | Default |
| Navigation bar | 1024×96 | 24/24/24/24 | Default |
| Heading strip | 512×96 | 24/24/24/24 | Default |
| Toast panel | 640×160 | 24/24/24/24 | Success, warning, error |
| Inventory slot | 160×160 | 24/24/24/24 | Default |
| Card slot | 300×420 | 24/24/24/24 | Default |
| Input field | 480×96 | 24/24/24/24 | Default, hover, focused, disabled, error, warning, success |
| Tab | 320×80 | 24/20/24/20 | Default, hover, pressed, disabled, focused, selected |
| Separator | 512×12 or 12×512 | 24 px at each long-axis end | Horizontal, vertical |

Use Barlow Condensed for controls and headings and Barlow for longer copy, as
defined in `assets/ui/STYLE_TOKENS.md`. Labels, values, icons and faction
emblems are separate engine-rendered layers. Status field marks use a cross,
triangle or check as well as a colour change; selected buttons use an underline
and corner diamonds. Content regions and the complete source list are in the
manifest.

Regenerate the PNGs, `.tres` files and manifest with Pillow:

```sh
python3 assets/ui/kit/scripts/build_surfaces.py
```

The generator is the editable source for this raster family. It uses the exact
palette tokens in `assets/ui/STYLE_TOKENS.md`, fixed geometry, and a fixed
scratch seed so every interaction state retains the same silhouette and wear.
