#!/usr/bin/env python3
"""Render OMEN's text-free control and HUD skins from editable geometry."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


OUT = Path(__file__).parent
SCALE = 3
PALETTE = {
    "void": "#0B0D0E", "base": "#141719", "surface1": "#1C2022",
    "surface2": "#282D2F", "surface3": "#343A3D",
    "border": "#41474A", "steel": "#6C7375", "text": "#E8E6E0",
    "muted": "#838A8A", "ash": "#B44743", "parallax": "#5B9FC4",
    "strain": "#64A477", "covenant": "#A87DC2", "aegis": "#C6A451",
    "success": "#7FA36E", "warning": "#C99A4D", "error": "#CB5A52",
}
MANIFEST: list[dict] = []


def color(name: str, opacity: int = 255) -> tuple[int, int, int, int]:
    value = PALETTE.get(name, name).lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (opacity,)


def polygon(x0: float, y0: float, x1: float, y1: float, cut: float):
    return [(x0 + cut, y0), (x1 - cut, y0), (x1, y0 + cut),
            (x1, y1 - cut), (x1 - cut, y1), (x0 + cut, y1),
            (x0, y1 - cut), (x0, y0 + cut)]


class Canvas:
    def __init__(self, width: int, height: int):
        self.w, self.h = width, height
        self.image = Image.new("RGBA", (width * SCALE, height * SCALE))
        self.draw = ImageDraw.Draw(self.image)

    def poly(self, points, fill):
        self.draw.polygon([(round(x * SCALE), round(y * SCALE)) for x, y in points],
                          fill=color(fill) if isinstance(fill, str) else fill)

    def rect(self, box, fill):
        self.draw.rectangle(tuple(round(v * SCALE) for v in box),
                            fill=color(fill) if isinstance(fill, str) else fill)

    def line(self, points, fill, width=1):
        self.draw.line([(round(x * SCALE), round(y * SCALE)) for x, y in points],
                       fill=color(fill) if isinstance(fill, str) else fill,
                       width=round(width * SCALE), joint="curve")

    def ellipse(self, box, fill, outline=None, width=1):
        self.draw.ellipse(tuple(round(v * SCALE) for v in box),
                          fill=color(fill) if isinstance(fill, str) else fill,
                          outline=color(outline) if isinstance(outline, str) else outline,
                          width=round(width * SCALE))

    def frame(self, cut=8, face="surface1", edge="border", accent=None,
              inset=3, worn=True, selected=False):
        w, h = self.w, self.h
        self.poly(polygon(0, 0, w - 1, h - 1, cut), edge)
        self.poly(polygon(inset, inset, w - 1 - inset, h - 1 - inset,
                          max(1, cut - inset)), face)
        # Two directional rules imply brushed metal while leaving the center quiet.
        self.line([(cut + 5, inset + 1), (w - cut - 6, inset + 1)],
                  color("steel", 78), 1)
        self.line([(cut + 5, h - inset - 2), (w - cut - 6, h - inset - 2)],
                  color("void", 155), 1)
        if accent:
            self.rect((inset + 2, max(cut + 3, 8), inset + 5,
                       min(h - cut - 4, h - 9)), accent)
        if selected:
            self.line([(cut + 8, h - 6), (w - cut - 8, h - 6)], accent or "steel", 3)
        if worn:
            # Small fixed chips are confined to the corner slices.
            self.rect((cut + 3, 0, cut + 5, 1), color("surface2", 180))
            self.rect((w - cut - 8, h - 2, w - cut - 5, h - 1), color("void", 200))
            self.line([(3, cut + 2), (3, cut + 6)], color("steel", 72), 1)

    def save(self, name: str, family: str, state: str, slice_margin=0,
             safe_region=None, purpose="functional"):
        path = OUT / name
        self.image.resize((self.w, self.h), Image.Resampling.LANCZOS).save(path)
        MANIFEST.append({"file": name, "family": family, "state": state,
                         "size_px": [self.w, self.h], "transparent": True,
                         "slice_margin_px": slice_margin,
                         "safe_region_px": safe_region,
                         "purpose": purpose})


def finish(c, family, state, width, height, margin, safe):
    c.save(f"ui_{family}_{state}.png", family, state, margin, safe)


def draw_box_controls():
    for state in ("unchecked", "unchecked_hover", "checked", "checked_hover",
                  "indeterminate", "focused", "disabled"):
        c = Canvas(48, 48)
        active = state.startswith("checked") or state == "indeterminate"
        edge = "steel" if "hover" in state else "aegis" if state == "focused" else "border"
        c.frame(7, "surface2" if active else "surface1", edge,
                worn=state != "disabled")
        if state.startswith("checked"):
            c.line([(13, 24), (21, 32), (35, 16)], "text", 4)
        elif state == "indeterminate":
            c.rect((13, 22, 35, 26), "text")
        if state == "focused":
            c.line([(8, 4), (40, 4)], "aegis", 2)
        if state == "disabled":
            c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.5)))
        finish(c, "checkbox", state, 48, 48, 0, [10, 10, 38, 38])

    for state in ("off", "off_hover", "on", "on_hover", "focused", "disabled"):
        c = Canvas(48, 48)
        c.ellipse((3, 3, 45, 45), "surface1", "steel" if "hover" in state else "border", 3)
        c.ellipse((8, 8, 40, 40), "surface2", "void", 1)
        if state.startswith("on"):
            c.ellipse((15, 15, 33, 33), "text")
        if state == "focused":
            for x0, y0, x1, y1 in ((3, 4, 12, 4), (36, 4, 45, 4),
                                   (3, 44, 12, 44), (36, 44, 45, 44)):
                c.line([(x0, y0), (x1, y1)], "aegis", 2)
        if state == "disabled":
            c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.5)))
        finish(c, "radio", state, 48, 48, 0, [8, 8, 40, 40])

    for state in ("off", "off_hover", "on", "on_hover", "focused", "disabled"):
        c = Canvas(104, 48)
        edge = "aegis" if state == "focused" else "steel" if "hover" in state else "border"
        c.frame(8, "surface1", edge)
        on = state.startswith("on")
        x = 59 if on else 7
        c.poly(polygon(x, 7, x + 38, 40, 5), "steel" if on else "border")
        c.poly(polygon(x + 3, 10, x + 35, 37, 3), "surface3" if on else "surface2")
        c.line([(x + 11, 19), (x + 27, 19)], "text" if on else "muted", 2)
        c.line([(x + 11, 27), (x + 27, 27)], "text" if on else "muted", 2)
        if on:
            c.rect((11, 21, 15, 27), "strain")
        if state == "disabled":
            c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.5)))
        finish(c, "toggle", state, 104, 48, 0, [48, 9, 56, 39])


def draw_tracks():
    for family, w, h, cut, margin in (("slider_track", 360, 28, 5, 8),
                                     ("progress_track", 480, 48, 7, 12),
                                     ("resource_track", 320, 48, 7, 12),
                                     ("histogram_track", 32, 148, 5, 8)):
        for state in ("default", "disabled"):
            c = Canvas(w, h)
            c.frame(cut, "void", "border", inset=2, worn=False)
            if family == "slider_track":
                c.line([(12, h // 2), (w - 12, h // 2)], "surface3", 5)
                for x in (13, w - 13):
                    c.line([(x, 9), (x, 19)], "steel", 1)
            elif family == "histogram_track":
                c.line([(9, 18), (9, h - 17)], color("steel", 56), 1)
            else:
                c.line([(14, 9), (w - 14, 9)], color("steel", 74), 1)
            if state == "disabled":
                c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.52)))
            finish(c, family, state, w, h, margin,
                   [margin + 4, 4, w - margin - 4, h - 4])

    for family, w, h, cut, colors in (
        ("slider_fill", 360, 28, 5, ["ash", "parallax", "strain", "covenant", "aegis"]),
        ("progress_fill", 480, 48, 7, ["success", "warning", "error"]),
        ("resource_fill", 320, 48, 7, ["ash", "parallax", "strain", "covenant", "aegis"]),
        ("histogram_fill", 32, 148, 5, ["ash", "parallax", "strain", "covenant", "aegis"]),
    ):
        for accent in colors:
            c = Canvas(w, h)
            if family == "slider_fill":
                c.line([(12, h // 2), (w - 12, h // 2)], accent, 5)
            else:
                c.poly(polygon(3, 3, w - 4, h - 4, max(2, cut - 2)), accent)
                c.line([(cut + 3, 7), (w - cut - 4, 7)], color("text", 53), 1)
                c.line([(cut + 3, h - 8), (w - cut - 4, h - 8)], color("void", 110), 1)
            finish(c, family, accent, w, h, 0, [8, 8, w - 8, h - 8])

    for state in ("default", "hover", "pressed", "disabled"):
        c = Canvas(38, 44)
        c.frame(7, "surface3" if state == "hover" else "surface2",
                "steel" if state in ("hover", "pressed") else "border",
                accent="ash" if state != "disabled" else None)
        for x in (18, 23):
            c.line([(x, 15), (x, 30)], color("text", 125), 1)
        if state == "disabled":
            c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.52)))
        finish(c, "slider_thumb", state, 38, 44, 0, [10, 8, 30, 36])

    for direction, w, h, thumb_w, thumb_h in (
        ("vertical", 24, 192, 24, 64),
        ("horizontal", 192, 24, 64, 24),
    ):
        c = Canvas(w, h)
        c.frame(4, "void", "border", inset=2, worn=False)
        finish(c, f"scrollbar_{direction}_track", "default", w, h, 6,
               [5, 5, w - 5, h - 5])
        for state in ("default", "hover", "pressed"):
            c = Canvas(thumb_w, thumb_h)
            c.frame(4, "surface3" if state == "hover" else "surface2",
                    "steel" if state != "default" else "border", inset=2,
                    worn=False)
            cx, cy = thumb_w // 2, thumb_h // 2
            for d in (-5, 0, 5):
                if direction == "vertical":
                    c.line([(cx - 5, cy + d), (cx + 5, cy + d)], "steel", 1)
                else:
                    c.line([(cx + d, cy - 5), (cx + d, cy + 5)], "steel", 1)
            finish(c, f"scrollbar_{direction}_thumb", state,
                   thumb_w, thumb_h, 6, [5, 5, thumb_w - 5, thumb_h - 5])


def draw_tabs_and_chips():
    for family, w, h, cut, margin in (("tab", 240, 64, 10, 16),
                                     ("filter_chip", 160, 48, 8, 12),
                                     ("segmented_option", 160, 52, 8, 12),
                                     ("pagination_button", 48, 48, 7, 8)):
        for state in ("default", "hover", "selected", "disabled"):
            c = Canvas(w, h)
            accent = "ash" if state == "selected" else None
            c.frame(cut, "surface2" if state in ("hover", "selected") else "surface1",
                    "steel" if state in ("hover", "selected") else "border",
                    accent=accent, selected=state == "selected")
            if state == "disabled":
                c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.52)))
            finish(c, family, state, w, h, margin,
                   [margin + 8, 8, w - margin - 8, h - 8])


def draw_hud():
    for state in ("default", "targeted", "damaged"):
        c = Canvas(128, 128)
        accent = "ash" if state == "damaged" else "aegis" if state == "targeted" else None
        c.frame(16, "surface1", accent or "border", accent=accent, inset=5)
        c.poly(polygon(16, 16, 111, 111, 8), (0, 0, 0, 0))
        c.line([(15, 17), (15, 35)], accent or "steel", 3)
        c.line([(112, 92), (112, 110)], accent or "steel", 3)
        finish(c, "hud_portrait_frame", state, 128, 128, 0, [16, 16, 112, 112])

    for family, w, h, cut in (("hud_health", 160, 64, 9),
                              ("hud_resource", 160, 64, 9),
                              ("hud_counter", 96, 48, 7),
                              ("hud_timer", 160, 64, 9),
                              ("hud_phase", 228, 64, 10),
                              ("hud_action", 320, 72, 12)):
        states = ("default", "active", "disabled")
        for state in states:
            c = Canvas(w, h)
            accent = ("ash" if family in ("hud_health", "hud_action") else
                      "parallax" if family == "hud_resource" else "aegis") if state == "active" else None
            c.frame(cut, "surface2" if state == "active" else "surface1",
                    "steel" if state == "active" else "border", accent=accent,
                    selected=state == "active")
            if family in ("hud_health", "hud_resource"):
                c.line([(w - 20, 15), (w - 20, h - 15)], color("steel", 106), 1)
            if state == "disabled":
                c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.52)))
            finish(c, family, state, w, h, 16,
                   [28, 12, w - 24, h - 12])

    for state in ("default", "active", "complete"):
        c = Canvas(48, 48)
        accent = "aegis" if state == "active" else "success" if state == "complete" else "steel"
        c.poly([(24, 1), (46, 24), (24, 46), (1, 24)], accent)
        c.poly([(24, 5), (42, 24), (24, 42), (5, 24)], "surface1")
        if state == "complete":
            c.line([(15, 24), (21, 30), (33, 17)], "text", 3)
        elif state == "active":
            c.line([(24, 12), (24, 36)], "aegis", 2)
        finish(c, "hud_turn_marker", state, 48, 48, 0, [10, 10, 38, 38])


def draw_collection_and_quest():
    for family, w, h, cut, margin, states in (
        ("deck_row", 640, 72, 11, 16, ("default", "hover", "selected", "disabled")),
        ("card_thumbnail_slot", 128, 160, 10, 16, ("default", "hover", "selected")),
        ("quantity_chip", 80, 48, 8, 12, ("default", "selected")),
        ("status_chip", 180, 48, 8, 12, ("neutral", "buff", "debuff")),
        ("inventory_slot", 144, 144, 12, 18, ("default", "hover", "selected", "locked")),
        ("quest_row", 400, 72, 11, 16, ("active", "complete", "locked")),
        ("objective_chip", 240, 48, 8, 12, ("active", "complete", "locked")),
    ):
        for state in states:
            c = Canvas(w, h)
            accent = ("ash" if state in ("selected", "debuff") else
                      "success" if state in ("complete", "buff") else
                      "aegis" if state == "active" else None)
            c.frame(cut, "surface2" if state in ("hover", "selected", "active") else "surface1",
                    "steel" if state in ("hover", "selected", "active", "complete") else "border",
                    accent=accent, selected=state in ("selected", "active", "complete"))
            if family == "deck_row":
                c.line([(98, 12), (98, 60)], color("steel", 120), 1)
            if family == "quest_row":
                c.line([(66, 12), (66, 60)], color("steel", 120), 1)
            if family == "inventory_slot":
                c.poly(polygon(14, 14, 129, 129, 7), "void")
                c.line([(16, 16), (31, 16)], "steel", 2)
                c.line([(112, 128), (127, 128)], "steel", 2)
                if state == "locked":
                    c.poly(polygon(11, 102, 133, 133, 4), "surface2")
            if family == "card_thumbnail_slot":
                c.poly(polygon(11, 11, 116, 148, 5), (0, 0, 0, 0))
            if state in ("disabled", "locked"):
                c.image.putalpha(c.image.getchannel("A").point(lambda a: int(a * 0.58)))
            safe = [margin + 7, 10, w - margin - 7, h - 10]
            if family in ("deck_row", "quest_row"):
                safe[0] = 110 if family == "deck_row" else 78
            if family in ("inventory_slot", "card_thumbnail_slot"):
                safe = [14, 14, w - 14, h - 14]
            finish(c, family, state, w, h,
                   0 if family in ("inventory_slot", "card_thumbnail_slot") else margin,
                   safe)

    for state, accent in (("success", "success"), ("warning", "warning"),
                          ("error", "error"), ("info", "parallax")):
        c = Canvas(24, 128)
        c.poly(polygon(0, 0, 23, 127, 4), "surface2")
        c.rect((6, 12, 12, 115), accent)
        c.line([(15, 11), (19, 11)], "steel", 1)
        finish(c, "toast_indicator", state, 24, 128, 6, [5, 8, 19, 120])


def main():
    draw_box_controls()
    draw_tracks()
    draw_tabs_and_chips()
    draw_hud()
    draw_collection_and_quest()
    (OUT / "manifest.json").write_text(json.dumps({"generator": "generate.py",
                                                   "color_space": "sRGB",
                                                   "assets": MANIFEST}, indent=2) + "\n")
    print(f"Rendered {len(MANIFEST)} control skins")


if __name__ == "__main__":
    main()
