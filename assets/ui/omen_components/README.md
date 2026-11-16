# OMEN UI assets

## Production resources

- `assets/ui/styles/` contains reusable Godot `StyleBoxFlat` resources for primary, secondary, danger, ghost, focused, disabled, field, panel, and tooltip states. These are resolution-independent, scale cleanly in controls, and need no 9-slice margins. The center regions are plain and text-safe.
- `assets/icons/factions/` contains five independent, single-colour SVG faction marks with transparent backgrounds. They contain no faction names; tint them with the palette tokens in the visual direction guide.
- `assets/icons/global/colorless.svg` is the neutral deck-builder filter mark. It is a clean transparent vector with no baked label.

### Production metadata

| Family | Dimensions | Transparency | States / scale | 9-slice / safe area |
|---|---|---|---|---|
| Button StyleBoxes | Engine-scaled vector resources | Not raster | Primary, secondary, danger, and ghost each have default/hover/pressed/disabled; shared focus outline. Toggled filters use the outline for selected state. | 9-slice not applicable; engine-rendered labels have 16 px horizontal and 10 px vertical padding |
| Icon-only / faction-accent buttons | Engine-scaled StyleBoxFlat | Not raster | Use the ghost family at a 40×40 px control size; use secondary styles with a faction palette tint for faction actions. | 9-slice not applicable; icon itself stays centered in a clear hit area |
| Field StyleBoxes | Engine-scaled vector resources | Not raster | Default/focus | 9-slice not applicable; smooth center for typed text |
| Panel StyleBoxes | Engine-scaled vector resources | Not raster | Standard/tooltip | 9-slice not applicable; clean center for content |
| Faction insignia | 256×256 viewBox, scalable SVG | Transparent | Monochrome master; display at 16–32 px or larger | No baked labels; tint via CanvasItem modulate |

Style resources use the guide's graphite surfaces, thin steel borders, warm off-white text, and controlled red, blue, and amber accents. Source vectors are the SVG files themselves. StyleBoxFlat resources are editable Godot vector-style resources.

## User-supplied references

`reference/` preserves all 19 supplied concept-sheet crops. `reference/extracted_crops/` keeps the smaller button, rarity, faction, and stat samples extracted from those sheets. The archive README describes these images as raster crops of a concept image. Their text, texture, and background are baked in, so they are references only; they are not production controls, clean transparent icons, or 9-slice skins.

`logo/omen_nav_logo.png` is the navigation-sheet logo crop selected by the user for the main menu. It is decorative fixed artwork, not an editable UI component.
