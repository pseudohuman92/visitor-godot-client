# OMEN card interface assets

These are production UI layers for a 5:7 portrait card. The frame and all
registered overlays are 750 × 1050 px so they can be stacked in Godot and
scaled together. They have transparent backgrounds and contain no card art,
words, or numbers. SVG files are editable masters; the matching PNG files are
sRGB exports for Godot. `build_cards.py` regenerates both from the same
geometry with Inkscape.

## Assembly order

1. Crop illustration behind the frame to the art window, x=46–704,
   y=173–685. `card_art_mask` is a white alpha mask for this window.
2. Draw `card_frame_neutral` over the art.
3. Add one `card_faction_*` overlay and one `card_rarity_*` overlay.
4. Put engine-rendered name, type, rules, cost, and stats in their safe areas.
5. Draw a `card_state_*` overlay above the other layers when applicable.

Godot can place the registered layers in `TextureRect` controls with matching
anchors and `STRETCH_SCALE`; use uniform scaling to preserve the 5:7 ratio.
Keep the illustration clipped to the art window so it does not cover the
nameplate or rules zone. The assets are fixed-ratio layers; **9-slice does not
apply**. Small badges and chips are separately scalable components.

## Registered layers

| Family | Purpose | Size | Variants / states | Transparency | Safe text area |
|---|---|---:|---|---|---|
| `card_frame_neutral` | Structural card frame | 750×1050 | neutral | Art window and exterior transparent | Name x=82–570, y=54–114; type x=82–570, y=121–150; rules x=72–680, y=734–958 |
| `card_art_mask` | Alpha mask for artwork | 750×1050 | white mask | Transparent except art window | None |
| `card_faction_*` | Faction edge and distinctive small insignia | 750×1050 | parallax, strain, covenant, ash, aegis | Transparent except marks | Same as frame |
| `card_rarity_*` | Shape-coded rarity marker at lower center | 750×1050 | common, uncommon, rare, epic, legendary | Transparent except lower center | Same as frame |
| `card_state_*` | Gameplay state feedback | 750×1050 | selected, targetable, exhausted, locked | Transparent outside state marks; exhausted and locked shade only the art window | Same as frame; locked/exhausted art is intentionally obscured |

Faction colours use `accent.parallax` `#5B9FC4`, `accent.strain`
`#64A477`, `accent.covenant` `#A87DC2`, `accent.ash` `#B44743`, and
`accent.aegis` `#C6A451`. The insignia geometry differs for every faction.
Rarity shapes also differ when seen without colour: one rule, two rules,
diamond, cross diamond, and star. State shapes include corner brackets,
crosshatching, and a lock silhouette, so state is not carried by hue alone.

## Freestanding components

| Asset | Purpose | Size | Transparency | Text / number safe area |
|---|---|---:|---|---|
| `card_cost_diamond` | Cost counter housing | 112×112 | Transparent outside diamond | Center 40×40 |
| `card_stat_attack` | Attack counter housing | 120×80 | Transparent outside angled badge | Center 50×44 |
| `card_stat_health` | Health counter housing | 120×80 | Transparent outside shield badge | Center 50×44 |
| `card_keyword_chip` | Keyword label housing | 224×56 | Transparent outside clipped rectangle | x=28–196, y=10–46 |

Suggested card positions: cost diamond at x=618, y=43; attack badge at
x=36, y=962; health badge at x=594, y=962; rarity is already registered
at the lower center. Put numerical text in Godot, never in the textures.
The freestanding components can scale down to half size. Their interiors are
quiet and functional, and their edge scratches are decorative.

These layers use the guide's graphite/steel base and restrained accents.
They are a new optional system and do not change the game's existing card
layout until a scene explicitly adopts them.
