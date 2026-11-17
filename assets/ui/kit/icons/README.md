# OMEN utility icons

The `svg/` folder holds original monochrome masters; `png_64/` holds 64×64
sRGB raster exports for controls that prefer PNG. Every icon has a transparent
background and contains no text, numbers, or enclosing button. The 64-unit
grid uses a 4-unit warm off-white stroke (`#E8E6E0`) with square terminals.
Tint instances with Godot's `modulate` for accent and state colours; keep
critical status labels or accessible descriptions in the UI.

Intended displayed size: 16–32 px, usually 24 px. The functional icons cover
gameplay, resources, navigation, editing, settings, and status. Use a minimum
40×40 px clickable control around the icon. The safe artwork bounds are about
`x/y = 4..60`; there is no 9-slice region. SVG is the vector source; the PNG
is a direct raster export, not an independently painted variant.

Regenerate with `python3 assets/ui/kit/icons/generate.py` (requires Inkscape).
The five faction insignia remain in `assets/icons/factions/` and can be used
alongside this set.
