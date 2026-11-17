# OMEN UI asset kit

A reusable production kit for OMEN's contemporary industrial interface. The
art follows the project's visual direction: precise clipped geometry, worn
graphite and steel, localized edge distress, quiet text areas, and restrained
faction accents. Production images contain no labels or card values; the
labelled images in `previews/` demonstrate composition only.

## Contents

| Family | Production assets | What it covers |
|---|---:|---|
| Backgrounds | 4 PNG | Graphite/concrete tiles, 1080p backdrop, edge overlay |
| Surfaces | 86 PNG + 86 Godot StyleBoxTexture | Six-state buttons, faction actions, panels, fields, tabs, separators |
| Controls | 123 PNG | Inputs, selectors, meters, HUD, deck/quest/inventory, feedback |
| Icons | 51 SVG + 51 PNG | Gameplay, navigation, editing, resources, status |
| Cards | 20 SVG + 20 PNG | Neutral frame, faction/rarity/state layers, badges |
| Theme | 2 Godot resources | Drop-in Barlow theme and focus ring |

The five existing faction insignia are at `assets/icons/factions/`. The theme
uses the already licensed Barlow and Barlow Condensed fonts in `assets/fonts/`.
The downloadable archive includes those dependencies.

## Use in Godot

1. Assign `res://assets/ui/kit/OMENKitTheme.tres` to a `Control`'s `theme`, or
   use it as the project-wide UI theme. This gives Button, OptionButton,
   CheckBox, CheckButton, LineEdit, Panel, TooltipPanel, HSlider, ProgressBar,
   and TabBar a coherent starting style. Existing game scenes are not changed
   merely by adding the kit.
2. Load a surface's `.tres` resource for a `StyleBoxTexture` with configured
   nine-slice margins. A matching transparent PNG sits beside every surface
   resource. `surfaces/manifest.json` lists states, slice margins, and safe
   content rectangles for every file.
3. Use controls as `TextureRect`, themed icons, or texture inputs to Godot
   controls. `controls/manifest.json` documents their states and margins.
   Composite fills should be clipped to progress, not scaled across their
   entire width.
4. Place one neutral card frame above art, then one faction overlay and one
   rarity overlay. Add state overlays last. See `cards/README.md` for the art
   window and text-safe coordinates. Keep text and values as Godot labels.
5. Tint the monochrome global and faction icons with `CanvasItem.modulate`.
   Use shape and wording alongside colour for important gameplay states.

All measurements target a 1920×1080 desktop interface. Buttons, panels, tabs,
and fields are nine-slice ready; icons are designed for 16–32 px display and
40×40 px or larger hit areas. The card system uses a fixed 5:7 aspect ratio.
Refer to each family README and `catalog.json` for dimensions, alpha, state,
safe area, source, and resource details.

## Palette and typography

The source of truth is `assets/ui/STYLE_TOKENS.md`. Shared surfaces are
charcoal `#0B0D0E` through `#343A3D`, with steel lines `#41474A` and
`#6C7375`. Functional text is warm off-white `#E8E6E0`. Ash `#B44743`,
Parallax `#5B9FC4`, Strain `#64A477`, Covenant `#A87DC2`, and Aegis
`#C6A451` identify specific factions. Barlow Condensed is used for headings,
controls, and counters; Barlow is used for longer copy.

## Rebuild and validate

Run from the client repository root. The source generators use Pillow and
NumPy/SciPy; vector export needs Inkscape.

```sh
python3 assets/ui/kit/scripts/build_backgrounds.py
python3 assets/ui/kit/scripts/build_surfaces.py
python3 assets/ui/kit/controls/generate.py
python3 assets/ui/kit/icons/generate.py
python3 assets/ui/kit/cards/build_cards.py
python3 assets/ui/kit/scripts/build_theme.py
python3 assets/ui/kit/scripts/build_catalog.py
python3 assets/ui/kit/scripts/build_preview.py
```

`catalog.json` is a validated inventory of production PNG and SVG assets,
including dimensions, transparency, hashes, and applicable nine-slice data.
The `previews/` contact sheets are labelled presentation images and must not
be used as production sprites.
