#!/usr/bin/env python3
"""Generate OMEN's quiet, tileable graphite UI backgrounds."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter


ROOT = Path(__file__).resolve().parents[1] / "backgrounds"
RNG = np.random.default_rng(160119)
TILE = 512


def field(sigma: float, strength: float) -> np.ndarray:
    values = RNG.standard_normal((TILE, TILE)).astype(np.float32)
    values = gaussian_filter(values, sigma=sigma, mode="wrap")
    values /= max(values.std(), 1e-6)
    return values * strength


def make_tile(base: tuple[int, int, int], concrete: bool = False) -> Image.Image:
    # Periodic fields make the texture repeat without a hard seam.
    fine = field(0.6, 1.25 if concrete else 0.85)
    small = field(3.2, 1.7 if concrete else 1.15)
    broad = field(29, 2.8 if concrete else 1.7)
    diagonal = field(13, 0.9)
    grain = fine + small + broad + diagonal
    if concrete:
        pores = (field(1.15, 1.0) < -1.2).astype(np.float32)
        grain -= pores * 2.3
    else:
        # A few shallow, periodic brushed-metal lines.
        y = np.arange(TILE, dtype=np.float32)
        grain += (np.sin(y[:, None] * 0.72) * 0.43
                  + np.sin(y[:, None] * 0.11) * 0.29)
    pixels = np.empty((TILE, TILE, 3), dtype=np.uint8)
    for channel, value in enumerate(base):
        pixels[:, :, channel] = np.clip(value + grain, 0, 255)
    tile = Image.fromarray(pixels, "RGB")
    # Thin rub marks are sparse and confined to narrow strips.
    detail = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(detail)
    for _ in range(27 if concrete else 17):
        x = int(RNG.integers(0, TILE))
        y = int(RNG.integers(0, TILE))
        length = int(RNG.integers(9, 85))
        shade = (160, 163, 160, int(RNG.integers(4, 12)))
        draw.line((x, y, x + length, y - (2 if concrete else 0)), fill=shade)
    tile = Image.alpha_composite(tile.convert("RGBA"), detail).convert("RGB")
    return tile


def fill_screen(tile: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (1920, 1080))
    for y in range(0, 1080, TILE):
        for x in range(0, 1920, TILE):
            canvas.paste(tile, (x, y))
    yy, xx = np.mgrid[0:1080, 0:1920].astype(np.float32)
    distance = ((xx - 960) / 1010) ** 2 + ((yy - 540) / 680) ** 2
    vignette = np.clip(distance, 0, 1) * 7
    # Keep the middle quiet so card art and body text stay legible.
    screen = np.asarray(canvas, dtype=np.float32).copy()
    screen -= vignette[:, :, None]
    return Image.fromarray(np.clip(screen, 0, 255).astype(np.uint8), "RGB")


def make_edge_overlay() -> Image.Image:
    width, height = 1920, 1080
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    marks = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(marks)
    # Worn structural edges, faint framing and one broken left-hand datum.
    draw.rectangle((18, 18, width - 19, height - 19), outline=(130, 139, 140, 24), width=1)
    draw.line((20, 80, 20, 266), fill=(158, 163, 157, 31), width=2)
    draw.line((20, 802, 20, 1040), fill=(158, 163, 157, 25), width=2)
    draw.line((1900, 37, 1900, 347), fill=(158, 163, 157, 23), width=2)
    draw.line((1900, 821, 1900, 1041), fill=(158, 163, 157, 29), width=2)
    for _ in range(160):
        edge = int(RNG.integers(0, 4))
        if edge in (0, 1):
            x = int(RNG.integers(0, width))
            y = int(RNG.integers(0, 110) if edge == 0 else RNG.integers(height - 110, height))
            ex = x + int(RNG.integers(-22, 42))
            ey = y + int(RNG.integers(-3, 4))
        else:
            x = int(RNG.integers(0, 92) if edge == 2 else RNG.integers(width - 92, width))
            y = int(RNG.integers(0, height))
            ex = x + int(RNG.integers(-3, 4))
            ey = y + int(RNG.integers(-12, 32))
        draw.line((x, y, ex, ey), fill=(167, 171, 164, int(RNG.integers(5, 21))), width=1)
    overlay = Image.alpha_composite(overlay, marks.filter(ImageFilter.GaussianBlur(0.25)))
    return overlay


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    graphite = make_tile((20, 23, 25))
    concrete = make_tile((25, 28, 29), concrete=True)
    graphite.save(ROOT / "ui_bg_graphite_tile_512.png", optimize=True)
    concrete.save(ROOT / "ui_bg_concrete_tile_512.png", optimize=True)
    fill_screen(graphite).save(ROOT / "ui_bg_graphite_1920x1080.png", optimize=True)
    make_edge_overlay().save(ROOT / "ui_overlay_edge_wear_1920x1080.png", optimize=True)


if __name__ == "__main__":
    main()
