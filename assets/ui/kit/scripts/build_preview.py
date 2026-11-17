#!/usr/bin/env python3
"""Make a labelled presentation preview; production textures stay text-free."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


KIT = Path(__file__).resolve().parents[1]
CLIENT = KIT.parents[2]
OUT = KIT / "previews"
FG = "#E8E6E0"
MUTED = "#B3B5B2"
ASH = "#B44743"
BLUE = "#5B9FC4"


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(CLIENT / "assets/fonts" / name, size)


DISPLAY = font("BarlowCondensed-Bold.ttf", 48)
HEADING = font("BarlowCondensed-SemiBold.ttf", 25)
LABEL = font("BarlowCondensed-SemiBold.ttf", 20)
BODY = font("Barlow-Regular.ttf", 17)
SMALL = font("Barlow-Regular.ttf", 14)


def asset(path: str) -> Image.Image:
    return Image.open(KIT / path).convert("RGBA")


def paste(canvas: Image.Image, item: Image.Image, x: int, y: int,
          size: tuple[int, int] | None = None) -> None:
    if size is not None:
        item = item.resize(size, Image.Resampling.LANCZOS)
    canvas.alpha_composite(item, (x, y))


def nine_slice(image: Image.Image, target: tuple[int, int], margin: int) -> Image.Image:
    width, height = image.size
    tw, th = target
    dst = Image.new("RGBA", target)
    xs = (0, margin, width - margin, width)
    ys = (0, margin, height - margin, height)
    dxs = (0, margin, tw - margin, tw)
    dys = (0, margin, th - margin, th)
    for row in range(3):
        for col in range(3):
            source = image.crop((xs[col], ys[row], xs[col + 1], ys[row + 1]))
            piece = source.resize((dxs[col + 1] - dxs[col], dys[row + 1] - dys[row]),
                                  Image.Resampling.LANCZOS)
            dst.alpha_composite(piece, (dxs[col], dys[row]))
    return dst


def make_card() -> Image.Image:
    card = Image.new("RGBA", (750, 1050))
    art = Image.open(CLIENT / "assets/card-images/base2/Tactical Genius.png").convert("RGB")
    cropped = ImageOps.fit(art, (658, 512), Image.Resampling.LANCZOS, centering=(0.5, 0.43))
    card.paste(cropped, (46, 173))
    for name in ("card_frame_neutral", "card_faction_ash", "card_rarity_rare"):
        card.alpha_composite(asset(f"cards/{name}.png"))
    card.alpha_composite(asset("cards/card_cost_diamond.png"), (618, 43))
    card.alpha_composite(asset("cards/card_stat_attack.png"), (36, 962))
    card.alpha_composite(asset("cards/card_stat_health.png"), (594, 962))
    d = ImageDraw.Draw(card)
    d.text((83, 56), "TACTICAL GENIUS", font=font("BarlowCondensed-Bold.ttf", 40), fill=FG)
    d.text((83, 120), "UNIT  /  ASH FRONT", font=font("BarlowCondensed-Medium.ttf", 24), fill=MUTED)
    d.text((674, 98), "4", anchor="mm", font=font("BarlowCondensed-Bold.ttf", 40), fill=FG)
    d.text((82, 755), "When this enters play, draw a card.",
           font=font("Barlow-Regular.ttf", 24), fill=FG)
    d.text((96, 997), "3", anchor="mm", font=font("BarlowCondensed-Bold.ttf", 40), fill=FG)
    d.text((654, 997), "4", anchor="mm", font=font("BarlowCondensed-Bold.ttf", 40), fill=FG)
    return card


def text_center(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str,
                face: ImageFont.FreeTypeFont = LABEL, fill: str = FG) -> None:
    draw.text(xy, value, anchor="mm", font=face, fill=fill)


def main() -> None:
    OUT.mkdir(exist_ok=True)
    canvas = asset("backgrounds/ui_bg_graphite_1920x1080.png")
    d = ImageDraw.Draw(canvas)
    d.rectangle((48, 38, 55, 117), fill=ASH)
    d.text((78, 36), "OMEN", font=DISPLAY, fill=FG)
    d.text((263, 54), "/  UI ASSET KIT", font=HEADING, fill=MUTED)
    d.text((79, 95), "CONTEMPORARY  /  INDUSTRIAL  /  OCCULT  /  RESTRAINED", font=SMALL, fill="#838A8A")
    d.line((72, 134, 1850, 134), fill="#41474A", width=2)

    d.text((80, 155), "INTERACTION STATES", font=HEADING, fill=FG)
    button_items = (
        ("primary", "default", "PLAY", 80, 200),
        ("secondary", "default", "DECK BUILDER", 410, 200),
        ("danger", "default", "DELETE", 740, 200),
        ("primary", "hover", "HOVER", 80, 310),
        ("primary", "disabled", "DISABLED", 410, 310),
        ("faction_parallax", "selected", "SELECTED", 740, 310),
    )
    for family, state, label, x, y in button_items:
        texture = asset(f"surfaces/buttons/ui_button_{family}_{state}.png")
        paste(canvas, texture, x, y, (300, 90))
        text_center(d, (x + 150, y + 45), label, fill="#838A8A" if state == "disabled" else FG)

    d.text((80, 432), "MODULAR PANEL  /  INPUTS", font=HEADING, fill=FG)
    panel = nine_slice(asset("surfaces/panels/ui_panel_modal.png"), (990, 404), 36)
    paste(canvas, panel, 80, 475)
    d.text((122, 505), "CONTAINMENT REPORT", font=font("BarlowCondensed-Bold.ttf", 31), fill=FG)
    d.text((123, 550), "Quiet surfaces keep the interface legible while the edges carry wear.",
           font=BODY, fill=MUTED)
    field = nine_slice(asset("surfaces/fields/ui_field_focused.png"), (602, 68), 24)
    paste(canvas, field, 122, 603)
    d.text((152, 625), "Search the archive", font=BODY, fill=MUTED)
    paste(canvas, asset("icons/png_64/ui_icon_search_64.png"), 665, 617, (36, 36))
    paste(canvas, asset("controls/ui_checkbox_checked.png"), 122, 706, (45, 45))
    d.text((179, 715), "Show anomaly alerts", font=BODY, fill=FG)
    paste(canvas, asset("controls/ui_toggle_on.png"), 478, 704, (104, 48))
    d.text((597, 715), "Audio cues", font=BODY, fill=FG)
    track = asset("controls/ui_progress_track_default.png")
    fill = asset("controls/ui_progress_fill_warning.png")
    paste(canvas, track, 122, 798, (602, 46))
    paste(canvas, fill.crop((0, 0, 310, fill.height)), 122, 798, (390, 46))
    d.text((748, 804), "61%", font=LABEL, fill=FG)

    d.text((80, 907), "MATCH HUD", font=HEADING, fill=FG)
    hud_items = (
        ("health", "24", 80, 956), ("resource", "6 / 8", 270, 956),
        ("timer", "02:15", 460, 956), ("phase", "COMBAT", 650, 956),
    )
    for kind, label, x, y in hud_items:
        texture = asset(f"controls/ui_hud_{kind}_active.png")
        size = (180, 64) if kind != "phase" else (245, 64)
        paste(canvas, texture, x, y, size)
        text_center(d, (x + size[0] // 2, y + 31), label)

    d.text((1220, 155), "LAYERED CARD SYSTEM", font=HEADING, fill=FG)
    card = make_card()
    paste(canvas, card, 1360, 205, (430, 602))
    d.line((1206, 830, 1850, 830), fill="#41474A", width=2)
    d.text((1218, 849), "UTILITY ICONS  /  24 PX TARGET", font=LABEL, fill=MUTED)
    for index, name in enumerate(("attack", "health", "defense", "knowledge", "deck", "clock", "target", "warning", "settings")):
        paste(canvas, asset(f"icons/png_64/ui_icon_{name}_64.png"),
              1220 + index * 70, 894, (32, 32))
    for index, color in enumerate((ASH, BLUE, "#64A477", "#A87DC2", "#C6A451")):
        x = 1220 + index * 124
        d.rectangle((x, 976, x + 103, 986), fill=color)
    d.text((1219, 1000), "ASH       PARALLAX       STRAIN       COVENANT       AEGIS", font=SMALL, fill=MUTED)

    paste(canvas, asset("backgrounds/ui_overlay_edge_wear_1920x1080.png"), 0, 0)
    canvas.convert("RGB").save(OUT / "overview.png", optimize=True)


if __name__ == "__main__":
    main()
