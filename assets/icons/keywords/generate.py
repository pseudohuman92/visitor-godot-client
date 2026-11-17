#!/usr/bin/env python3
"""Generate original OMEN combat keyword badges and 64 px PNG exports."""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path
from xml.etree import ElementTree

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
INKSCAPE = shutil.which("inkscape")
if INKSCAPE is None:
    raise SystemExit("Inkscape is required to export the SVG masters")

STEEL = "#E8E6E0"

# Glyphs are intentionally sparse at the 64-unit master scale. Each icon has
# its own silhouette, while the steel enclosure stays identical across states.
KEYWORDS = {
    "Deadly": (
        "#B44743", "skull and fangs",
        '<path d="M17 28c0-10 6-16 15-16s15 6 15 16c0 6-3 11-7 14v9H24v-9c-4-3-7-8-7-14Z"/>'
        '<path d="m22 29 6 3-6 3m20-6-6 3 6 3M27 43v8m10-8v8"/>'),
    "Defender": (
        "#C6A451", "reinforced shield",
        '<path d="M32 10 50 18v15c0 11-6 18-18 23-12-5-18-12-18-23V18L32 10Z"/>'
        '<path d="M21 33h22M32 22v22M23 47l9 4 9-4"/>'),
    "FirstStrike": (
        "#B44743", "forward blade and impact rays",
        '<path d="M19 48 43 15l8-5-2 9-25 32-5-3ZM19 45l-7 6m9-7 8 7M12 18h11M9 27h8M14 36h6"/>'),
    "Trample": (
        "#B44743", "armoured boot and fractured ground",
        '<path d="M19 13h17v22l12 6v9H15v-9l4-5V13Z"/>'
        '<path d="M15 50h34M13 56h11m7 0h10m7 0h5M22 20h9"/>'),
    "Evasive": (
        "#5B9FC4", "curved path around an obstacle",
        '<path d="M13 48c-1-20 7-31 26-32h9m-8-7 8 7-8 7"/>'
        '<path d="M28 31h15v17H28zM14 48h10"/>'),
    "Vigilance": (
        "#C6A451", "watchful eye and radar ticks",
        '<path d="M10 33c7-10 14-15 22-15s15 5 22 15c-7 10-14 15-22 15S17 43 10 33Z"/>'
        '<circle cx="32" cy="33" r="7"/><path d="M32 9v6M14 13l4 4m32-4-4 4"/>'),
    "Lifelink": (
        "#64A477", "heart joined by a chain link",
        '<path d="M32 50 14 33c-8-9 1-21 11-14l7 5 7-5c10-7 19 5 11 14L32 50Z"/>'
        '<path d="M22 33h8l4-5 7 8h5"/>'),
    "Reach": (
        "#5B9FC4", "extended spear above a barricade",
        '<path d="M32 8 25 22h14L32 8ZM32 22v33M17 46h30M21 36l-7 10m29-10 7 10"/>'),
    "Drain": (
        "#A87DC2", "life droplet pulled into a vessel",
        '<path d="M32 11c-4 8-12 15-12 24a12 12 0 0 0 24 0c0-9-8-16-12-24Z"/>'
        '<path d="M32 23v18m-6-6 6 6 6-6M20 51h24"/>'),
    "Unblockable": (
        "#B44743", "arrow through a split shield",
        '<path d="M27 13 15 18v16c0 7 3 13 10 17M37 13l12 5v16c0 7-3 13-10 17"/>'
        '<path d="M12 32h39m-9-9 9 9-9 9M32 12v12m0 16v14"/>'),
    "Blitz": (
        "#B44743", "angular lightning strike",
        '<path d="M36 7 15 35h15l-2 22 21-29H34l2-21Z" fill="#E8E6E0"/>'
        '<path d="M12 18h9M9 27h7M44 46h9"/>'),
    "Decay": (
        "#A87DC2", "fractured hourglass",
        '<path d="M17 10h30M17 54h30M21 12c0 10 3 15 11 20-8 5-11 10-11 20m22-40c0 10-3 15-11 20 8 5 11 10 11 20"/>'
        '<path d="m26 23 8 7-4 5 7 6m-10 5h10"/>'),
    "Regenerate": (
        "#64A477", "renewal arrow around a medical cross",
        '<path d="M49 23c-4-9-13-13-22-11-9 2-15 9-16 18m0-9v9h9M15 42c4 9 13 13 22 11 9-2 15-9 16-18m0 9v-9h-9"/>'
        '<path d="M29 24h6v6h6v6h-6v6h-6v-6h-6v-6h6z"/>'),
}


def snake(name: str) -> str:
    result = []
    for char in name:
        if char.isupper() and result:
            result.append("_")
        result.append(char.lower())
    return "".join(result)


def svg(accent: str, glyph: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M9 3H55L61 9V55L55 61H9L3 55V9Z" fill="#1C2022" fill-opacity="0.96" stroke="#6C7375" stroke-width="2.5"/>
  <path d="M27 5H37" stroke="{accent}" stroke-width="2.5"/>
  <g fill="none" stroke="{STEEL}" stroke-width="3.7" stroke-linecap="square" stroke-linejoin="miter">{glyph}</g>
</svg>
'''


def main() -> None:
    svg_dir = ROOT / "svg"
    png_dir = ROOT / "png_64"
    svg_dir.mkdir(exist_ok=True)
    png_dir.mkdir(exist_ok=True)
    manifest = []
    for keyword, (accent, motif, glyph) in KEYWORDS.items():
        basename = snake(keyword)
        source = svg_dir / f"{basename}.svg"
        output = png_dir / f"{basename}.png"
        source.write_text(svg(accent, glyph))
        ElementTree.parse(source)
        subprocess.run([INKSCAPE, str(source), "--export-type=png",
                        f"--export-filename={output}", "--export-width=64",
                        "--export-height=64"], check=True, capture_output=True)
        with Image.open(output) as image:
            assert image.size == (64, 64) and image.mode == "RGBA", output
            assert image.getchannel("A").getextrema() == (0, 255), output
        source.chmod(0o644)
        output.chmod(0o644)
        manifest.append({"keyword": keyword, "svg": f"svg/{basename}.svg",
                         "png": f"png_64/{basename}.png", "motif": motif,
                         "accent": accent, "size_px": [64, 64],
                         "display_px": [24, 32], "transparent": True})
    (ROOT / "manifest.json").write_text(json.dumps({"assets": manifest}, indent=2) + "\n")
    preview = Image.new("RGB", (1490, 510), "#0B0D0E")
    draw = ImageDraw.Draw(preview)
    face = ImageFont.truetype(ROOT.parents[2] / "assets/fonts/BarlowCondensed-SemiBold.ttf", 21)
    heading = ImageFont.truetype(ROOT.parents[2] / "assets/fonts/BarlowCondensed-Bold.ttf", 35)
    draw.text((42, 25), "OMEN  /  COMBAT KEYWORD BADGES", font=heading, fill="#E8E6E0")
    draw.text((43, 68), "Production icons are text-free  /  presentation labels below", font=face, fill="#838A8A")
    draw.line((42, 105, 1448, 105), fill="#41474A", width=2)
    for index, entry in enumerate(manifest):
        col, row = index % 7, index // 7
        x, y = 43 + col * 206, 122 + row * 186
        draw.rounded_rectangle((x, y, x + 188, y + 166), radius=3,
                               fill="#141719", outline="#41474A", width=1)
        draw.rectangle((x + 12, y + 10, x + 46, y + 13), fill=entry["accent"])
        icon = Image.open(ROOT / entry["png"]).convert("RGBA")
        preview.paste(icon, (x + 57, y + 17), icon)
        small = icon.resize((32, 32), Image.Resampling.LANCZOS)
        preview.paste(small, (x + 138, y + 45), small)
        draw.text((x + 15, y + 107), entry["keyword"], font=face, fill="#E8E6E0")
        draw.text((x + 15, y + 137), "64 px master / 32 px", font=face, fill="#838A8A")
    preview_dir = ROOT / "previews"
    preview_dir.mkdir(exist_ok=True)
    preview.save(preview_dir / "keyword_contact_sheet.png", optimize=True)
    print(f"Generated {len(manifest)} keyword badges")


if __name__ == "__main__":
    main()
