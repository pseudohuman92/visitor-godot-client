#!/usr/bin/env python3
"""Build OMEN's text-free, nine-slice UI surfaces.

The PNGs are deterministic production assets. Wear is confined to the corners
and border so their center regions remain quiet for engine-rendered text.
Requires Pillow; run from any working directory.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1] / "surfaces"
SCALE = 2
PALETTE = {
    "void": "#0B0D0E", "base": "#141719", "surface_1": "#1C2022",
    "surface_2": "#282D2F", "surface_3": "#343A3D",
    "border_subtle": "#41474A", "border_strong": "#6C7375",
    "text": "#E8E6E0", "muted": "#838A8A",
    "ash": "#B44743", "parallax": "#5B9FC4",
    "strain": "#64A477", "covenant": "#A87DC2",
    "aegis": "#C6A451", "success": "#7FA36E",
    "warning": "#C99A4D", "error": "#CB5A52",
}
FACTIONS = ("ash", "parallax", "strain", "covenant", "aegis")
BUTTON_STATES = ("default", "hover", "pressed", "disabled", "focused", "selected")
MANIFEST: list[dict] = []


def rgb(value: str) -> tuple[int, int, int]:
    value = PALETTE.get(value, value).lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def blend(a: str | tuple, b: str | tuple, fraction: float) -> tuple[int, int, int]:
    left = rgb(a) if isinstance(a, str) else a
    right = rgb(b) if isinstance(b, str) else b
    return tuple(round(x * (1 - fraction) + y * fraction) for x, y in zip(left, right))


def rgba(color: str | tuple, alpha: int = 255) -> tuple[int, int, int, int]:
    color = rgb(color) if isinstance(color, str) else color
    return (*color, alpha)


def points(w: int, h: int, corners: tuple[int, int, int, int], inset: int = 0) -> list[tuple[int, int]]:
    """A clipped rectangle with TL, TR, BR, BL cuts, in logical pixels."""
    tl, tr, br, bl = (max(0, c - inset) for c in corners)
    x0, y0, x1, y1 = inset, inset, w - 1 - inset, h - 1 - inset
    return [
        (x0 + tl, y0), (x1 - tr, y0), (x1, y0 + tr),
        (x1, y1 - br), (x1 - br, y1), (x0 + bl, y1),
        (x0, y1 - bl), (x0, y0 + tl),
    ]


def scaled(items: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return [(x * SCALE, y * SCALE) for x, y in items]


def line(draw: ImageDraw.ImageDraw, xy: list[tuple[float, float]], fill: tuple,
         width: float = 1) -> None:
    draw.line([(round(x * SCALE), round(y * SCALE)) for x, y in xy],
              fill=fill, width=max(1, round(width * SCALE)), joint="curve")


def rect(draw: ImageDraw.ImageDraw, xy: tuple[float, float, float, float],
         fill: tuple, width: float = 0) -> None:
    box = tuple(round(x * SCALE) for x in xy)
    if width:
        draw.rectangle(box, outline=fill, width=round(width * SCALE))
    else:
        draw.rectangle(box, fill=fill)


def polygon(draw: ImageDraw.ImageDraw, xy: list[tuple[int, int]], fill: tuple) -> None:
    draw.polygon(scaled(xy), fill=fill)


def make_canvas(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (w * SCALE, h * SCALE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image, "RGBA")


def finish(image: Image.Image, name: str, margin: tuple[int, int, int, int],
           safe: tuple[int, int, int, int], family: str, purpose: str,
           state: str = "default", accent: str | None = None) -> None:
    image = image.resize((image.width // SCALE, image.height // SCALE),
                         Image.Resampling.LANCZOS)
    path = ROOT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    w, h = image.size
    MANIFEST.append({
        "file": name, "family": family, "purpose": purpose, "state": state,
        "size": [w, h], "transparent": True,
        "nine_slice": dict(zip(("left", "top", "right", "bottom"), margin)),
        "safe_content_rect": list(safe), "accent_token": accent,
        "source": "assets/ui/kit/scripts/build_surfaces.py",
    })
    # Godot's StyleBoxTexture uses the exact same four margins. A resource per
    # state lets scenes use this pack without manually configuring a nine-slice.
    stem = path.stem
    resource = path.with_suffix(".tres")
    target = "res://assets/ui/kit/surfaces/" + name
    left, top, right, bottom = margin
    resource.write_text(
        '[gd_resource type="StyleBoxTexture" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{target}" id="1"]\n\n'
        '[resource]\n'
        'texture = ExtResource("1")\n'
        f'texture_margin_left = {left}.0\ntexture_margin_top = {top}.0\n'
        f'texture_margin_right = {right}.0\ntexture_margin_bottom = {bottom}.0\n'
        'axis_stretch_horizontal = 0\naxis_stretch_vertical = 0\n'
        f'content_margin_left = {max(8, safe[0])}.0\n'
        f'content_margin_top = {max(4, safe[1])}.0\n'
        f'content_margin_right = {max(8, w - safe[2])}.0\n'
        f'content_margin_bottom = {max(4, h - safe[3])}.0\n'
    )


def wear(draw: ImageDraw.ImageDraw, w: int, h: int, limit: int,
         seed: str, tint: tuple[int, int, int], amount: int) -> None:
    """Small machining scratches, restricted to the four 9-slice corners."""
    randomizer = random.Random(seed)
    for corner_x in (0, w - limit):
        for corner_y in (0, h - limit):
            for index in range(amount):
                x = corner_x + randomizer.randrange(5, max(6, limit - 4))
                y = corner_y + randomizer.randrange(5, max(6, limit - 4))
                length = randomizer.randrange(2, 9)
                alpha = randomizer.randrange(24, 58)
                if index % 3 == 0:
                    line(draw, [(x, y), (x, y + length)], (*tint, alpha))
                else:
                    line(draw, [(x, y), (x + length, y)], (*tint, alpha))


def base_surface(w: int, h: int, cuts: tuple[int, int, int, int],
                 face: tuple[int, int, int], edge: tuple[int, int, int],
                 inner: tuple[int, int, int], wear_seed: str,
                 wear_amount: int = 5) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image, draw = make_canvas(w, h)
    # The two inset silhouettes make a thin machined perimeter. Keep all
    # decorative detail inside the future nine-slice corner area.
    polygon(draw, points(w, h, cuts), rgba("void", 220))
    polygon(draw, points(w, h, cuts, 2), rgba(edge))
    polygon(draw, points(w, h, cuts, 4), rgba(face))
    line(draw, [(cuts[0] + 4, 4), (w - cuts[1] - 5, 4)],
         (*blend(edge, "text", 0.22), 115))
    line(draw, [(cuts[3] + 5, h - 5), (w - cuts[2] - 5, h - 5)],
         rgba("void", 145))
    # Inset top-left practical light, not a broad glossy gradient.
    line(draw, [(4, cuts[0] + 3), (4, h - cuts[3] - 5)],
         rgba(inner, 110))
    wear(draw, w, h, min(28, w // 4, h // 3), wear_seed,
         blend(edge, "text", 0.18), wear_amount)
    return image, draw


def button(family: str, state: str, faction: str | None = None) -> None:
    icon_only = family == "icon"
    w, h = (96, 96) if icon_only else (320, 96)
    corners = (15, 5, 15, 5)
    accent_name = faction or {"primary": "ash", "danger": "error"}.get(family)
    accent = rgb(accent_name) if accent_name else rgb("border_strong")
    surface = rgb("surface_1")
    edge = rgb("border_subtle")
    if family == "primary":
        surface = blend("surface_1", "ash", 0.12)
        edge = blend("border_subtle", "ash", 0.40)
    elif family == "danger":
        surface = blend("surface_1", "error", 0.10)
        edge = blend("border_subtle", "error", 0.42)
    elif family == "ghost":
        surface = rgb("base")
        edge = blend("border_subtle", "base", 0.35)
    elif family == "faction":
        surface = blend("surface_1", accent, 0.055)
        edge = blend("border_subtle", accent, 0.30)
    if state == "hover":
        surface = blend(surface, "surface_3", 0.47)
        edge = blend(edge, accent, 0.45)
    elif state == "pressed":
        surface = blend(surface, "void", 0.31)
        edge = blend(edge, accent, 0.22)
    elif state == "disabled":
        surface = blend(surface, "base", 0.42)
        edge = blend(edge, "border_subtle", 0.38)
        accent = blend(accent, "border_subtle", 0.70)
    elif state == "focused":
        surface = blend(surface, "surface_2", 0.25)
        edge = blend(edge, "text", 0.58)
    elif state == "selected":
        surface = blend(surface, accent, 0.15)
        edge = blend(edge, accent, 0.72)

    image, draw = base_surface(w, h, corners, surface, edge,
                               blend(edge, "text", 0.25),
                               f"button-{family}-{faction}", 4)
    # Small angle brackets identify the hit target without constraining text.
    marker_alpha = 88 if state == "disabled" else 195
    if icon_only:
        line(draw, [(17, 25), (17, 17), (25, 17)], (*accent, marker_alpha), 2)
        line(draw, [(71, 79), (79, 79), (79, 71)], (*accent, marker_alpha), 2)
    else:
        line(draw, [(20, 37), (16, 48), (20, 59)], (*accent, marker_alpha), 2)
        line(draw, [(w - 21, 37), (w - 17, 48), (w - 21, 59)],
             (*accent, marker_alpha), 2)
        if family in ("primary", "danger", "faction"):
            rect(draw, (4, 30, 7, 66), (*accent, 185 if state != "disabled" else 70))
    if state == "hover":
        line(draw, [(32, 8), (w - 32, 8)], (*accent, 150), 2)
    if state == "pressed":
        line(draw, [(25, 10), (w - 25, 10)], rgba("void", 210), 3)
        line(draw, [(25, h - 10), (w - 25, h - 10)], (*accent, 90))
    if state == "focused":
        outline = points(w, h, corners, 1)
        line(draw, outline + [outline[0]], rgba("text", 210), 2)
    if state == "selected":
        line(draw, [(29, h - 10), (w - 29, h - 10)], (*accent, 225), 3)
        for x in (25, w - 25):
            polygon(draw, [(x, h - 14), (x + 4, h - 10),
                           (x, h - 6), (x - 4, h - 10)], (*accent, 220))

    label = f"faction_{faction}" if faction else family
    name = f"buttons/ui_button_{label}_{state}.png"
    safe = (27, 21, 69, 75) if icon_only else (44, 18, 276, 78)
    finish(image, name, (24, 24, 24, 24), safe, "button", family,
           state, f"accent.{accent_name}" if faction else accent_name)


def panel(kind: str, status: str | None = None) -> None:
    specs = {
        "standard": (1024, 768, (22, 7, 22, 7), 32),
        "inset": (512, 384, (10, 3, 10, 3), 24),
        "modal": (1024, 768, (26, 8, 26, 8), 40),
        "tooltip": (480, 240, (10, 3, 10, 3), 24),
        "navigation": (1024, 96, (10, 3, 10, 3), 24),
        "header": (512, 96, (9, 3, 9, 3), 24),
        "toast": (640, 160, (12, 4, 12, 4), 24),
        "inventory_slot": (160, 160, (10, 3, 10, 3), 24),
        "card_slot": (300, 420, (12, 4, 12, 4), 24),
    }
    w, h, corners, slice_size = specs[kind]
    face = rgb("surface_1")
    edge = rgb("border_subtle")
    accent_name = None
    if kind in ("modal", "navigation", "header"):
        face = blend("surface_1", "base", 0.25)
        edge = rgb("border_strong") if kind == "modal" else edge
    elif kind == "tooltip":
        face = rgb("base")
        edge = blend("border_subtle", "aegis", 0.29)
        accent_name = "aegis"
    elif kind == "inset":
        face = rgb("base")
    elif kind == "card_slot":
        face = blend("surface_1", "base", 0.4)
    if status:
        accent_name = status
        edge = blend(edge, status, 0.38)
    image, draw = base_surface(w, h, corners, face, edge,
                               blend(edge, "text", 0.2), f"panel-{kind}", 6)
    if kind == "inset":
        line(draw, [(18, 10), (w - 18, 10)], rgba("void", 170), 2)
        line(draw, [(18, h - 10), (w - 18, h - 10)], rgba("border_subtle", 125))
    elif kind == "modal":
        line(draw, [(40, 13), (w - 40, 13)], rgba("border_strong", 100))
        for x in (16, w - 16):
            line(draw, [(x, 34), (x, 52)], rgba("ash", 145), 2)
            line(draw, [(x, h - 52), (x, h - 34)], rgba("ash", 145), 2)
    elif kind == "tooltip":
        rect(draw, (4, 32, 6, h - 32), rgba("aegis", 148))
    elif kind == "navigation":
        line(draw, [(24, h - 9), (w - 24, h - 9)], rgba("border_strong", 95))
        for x in (18, w - 18):
            line(draw, [(x, 23), (x, 38)], rgba("ash", 140), 2)
    elif kind == "header":
        line(draw, [(24, h - 10), (w - 24, h - 10)], rgba("ash", 125), 2)
    elif kind == "toast":
        accent = rgb(status or "border_strong")
        rect(draw, (5, 30, 9, h - 30), (*accent, 220))
        line(draw, [(19, 24), (19, 38), (33, 38)], (*accent, 180), 2)
    elif kind in ("inventory_slot", "card_slot"):
        # Fixed corners and a clear center allow an icon or card artwork on top.
        for x, y, dx, dy in ((18, 18, 1, 1), (w - 18, 18, -1, 1),
                             (18, h - 18, 1, -1), (w - 18, h - 18, -1, -1)):
            line(draw, [(x + 9 * dx, y), (x, y), (x, y + 9 * dy)],
                 rgba("border_strong", 105))
    suffix = f"_{status}" if status else ""
    safe = (slice_size + 8, slice_size + 8,
            w - slice_size - 8, h - slice_size - 8)
    if kind in ("navigation", "header"):
        safe = (slice_size + 8, 18, w - slice_size - 8, h - 18)
    name = f"panels/ui_panel_{kind}{suffix}.png"
    finish(image, name, (slice_size,) * 4, safe, "panel", kind,
           status or "default", f"state.{status}" if status else accent_name)


def field(state: str) -> None:
    w, h = 480, 96
    face = rgb("base")
    edge = rgb("border_subtle")
    accent = rgb("border_strong")
    if state in ("hover", "focused"):
        edge = rgb("border_strong")
    if state == "focused":
        accent = rgb("parallax")
    elif state in ("error", "warning", "success"):
        accent = rgb(state)
        edge = blend(edge, accent, 0.5)
    elif state == "disabled":
        face = blend(face, "surface_1", 0.25)
        edge = blend(edge, "base", 0.55)
        accent = edge
    image, draw = base_surface(w, h, (9, 3, 9, 3), face, edge,
                               blend(edge, "text", 0.10), "field", 3)
    if state == "focused":
        line(draw, [(17, 7), (w - 17, 7)], (*accent, 190), 2)
        line(draw, [(18, h - 8), (w - 18, h - 8)], (*accent, 155), 2)
    elif state in ("error", "warning", "success"):
        rect(draw, (5, 24, 8, h - 24), (*accent, 210))
        # A small distinct geometry supplements the colour cue.
        if state == "error":
            line(draw, [(w - 32, 22), (w - 22, 32)], (*accent, 200), 2)
            line(draw, [(w - 22, 22), (w - 32, 32)], (*accent, 200), 2)
        elif state == "warning":
            polygon(draw, [(w - 33, 32), (w - 27, 20), (w - 21, 32)],
                    (*accent, 190))
        else:
            line(draw, [(w - 35, 25), (w - 29, 31), (w - 20, 20)],
                 (*accent, 190), 2)
    if state == "disabled":
        line(draw, [(15, h - 9), (w - 15, h - 9)], rgba("border_subtle", 65))
    finish(image, f"fields/ui_field_{state}.png", (24,) * 4,
           (26, 15, w - 42, h - 15), "field", "text/search/dropdown", state,
           f"state.{state}" if state in ("error", "warning", "success") else None)


def tab(state: str) -> None:
    w, h = 320, 80
    face = rgb("surface_1")
    edge = rgb("border_subtle")
    accent = rgb("border_strong")
    if state == "hover":
        face = blend(face, "surface_2", 0.72)
        edge = rgb("border_strong")
    elif state == "selected":
        face = rgb("surface_2")
        edge = rgb("border_strong")
        accent = rgb("ash")
    elif state == "pressed":
        face = blend(face, "void", 0.2)
    elif state == "focused":
        edge = blend(edge, "text", 0.6)
    elif state == "disabled":
        edge = blend(edge, "base", 0.6)
        accent = edge
    image, draw = base_surface(w, h, (9, 2, 0, 0), face, edge,
                               blend(edge, "text", 0.2), "tab", 3)
    if state == "selected":
        line(draw, [(20, h - 8), (w - 20, h - 8)], (*accent, 220), 3)
        rect(draw, (13, 22, 16, h - 18), (*accent, 195))
    elif state == "focused":
        line(draw, [(12, 2), (w - 12, 2)], rgba("text", 195), 2)
    elif state == "pressed":
        line(draw, [(20, 9), (w - 20, 9)], rgba("void", 180), 2)
    finish(image, f"tabs/ui_tab_{state}.png", (24, 20, 24, 20),
           (30, 14, w - 24, h - 15), "tab", "navigation/filter tab", state)


def separator(vertical: bool) -> None:
    w, h = (12, 512) if vertical else (512, 12)
    image, draw = make_canvas(w, h)
    if vertical:
        line(draw, [(5, 0), (5, h)], rgba("void", 140))
        line(draw, [(6, 0), (6, h)], rgba("border_strong", 145))
        line(draw, [(7, 0), (7, h)], rgba("surface_2", 120))
        rect(draw, (4, 8, 8, 18), rgba("ash", 120))
        rect(draw, (4, h - 19, 8, h - 9), rgba("ash", 120))
    else:
        line(draw, [(0, 5), (w, 5)], rgba("void", 140))
        line(draw, [(0, 6), (w, 6)], rgba("border_strong", 145))
        line(draw, [(0, 7), (w, 7)], rgba("surface_2", 120))
        rect(draw, (8, 4, 18, 8), rgba("ash", 120))
        rect(draw, (w - 19, 4, w - 9, 8), rgba("ash", 120))
    kind = "vertical" if vertical else "horizontal"
    margin = (0, 24, 0, 24) if vertical else (24, 0, 24, 0)
    finish(image, f"separators/ui_separator_{kind}.png", margin,
           (0, 0, w, h), "separator", kind)


def main() -> None:
    for family in ("primary", "secondary", "danger", "ghost", "icon"):
        for state in BUTTON_STATES:
            button(family, state)
    for faction in FACTIONS:
        for state in BUTTON_STATES:
            button("faction", state, faction)
    for kind in ("standard", "inset", "modal", "tooltip", "navigation",
                 "header", "inventory_slot", "card_slot"):
        panel(kind)
    for status in ("success", "warning", "error"):
        panel("toast", status)
    for state in ("default", "hover", "focused", "disabled", "error",
                  "warning", "success"):
        field(state)
    for state in ("default", "hover", "pressed", "disabled", "focused",
                  "selected"):
        tab(state)
    separator(False)
    separator(True)
    (ROOT / "manifest.json").write_text(json.dumps({
        "version": 1,
        "palette_reference": "assets/ui/STYLE_TOKENS.md",
        "godot": "4.x StyleBoxTexture resources alongside PNGs",
        "assets": MANIFEST,
    }, indent=2) + "\n")
    print(f"Wrote {len(MANIFEST)} OMEN surface PNGs and StyleBoxTexture resources")


if __name__ == "__main__":
    main()
