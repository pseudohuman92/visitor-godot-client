#!/usr/bin/env python3
"""Build OMEN's monochrome, transparent utility icons and 64 px raster exports."""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent
SVG_DIR = ROOT / "svg"
PNG_DIR = ROOT / "png_64"
INKSCAPE = shutil.which("inkscape")

# All marks share a 64-unit grid, a 4-unit stroke, square terminals, and a
# warm neutral master colour. Tint monochrome SVG/PNG instances in the engine.
ICONS: dict[str, str] = {
    "attack": '<path d="M12 42 42 12l10 10-30 30-10-10Z"/><path d="m10 54 12-12M44 10l10 10M35 19l10 10"/>',
    "health": '<path d="M32 54 10 34c-9-10 2-27 15-18l7 6 7-6c13-9 24 8 15 18L32 54Z"/><path d="M20 35h8l4-9 4 15 4-6h5"/>',
    "defense": '<path d="M32 7 51 15v15c0 13-8 22-19 27-11-5-19-14-19-27V15L32 7Z"/><path d="M22 32h20M32 20v24"/>',
    "knowledge": '<path d="M32 15c-8-6-16-7-23-5v35c8-2 16-1 23 5 7-6 15-7 23-5V10c-7-2-15-1-23 5Z"/><path d="M32 15v35M16 20c5 0 8 1 11 3M37 23c3-2 6-3 11-3M16 29c5 0 8 1 11 3M37 32c3-2 6-3 11-3"/>',
    "energy": '<path d="M36 6 15 35h15l-2 23 21-30H34l2-22Z"/>',
    "deck": '<path d="M18 11h32v39H18zM13 16H9v39h32v-4M23 19h22M23 27h18"/>',
    "hand": '<path d="M9 39 16 14l8 2M16 43l3-27 17 2M22 49l5-29 18 3-4 29-19-3ZM31 26l8 1M30 33l8 1"/><path d="M40 16 51 18l-3 29-6-1"/>',
    "discard": '<path d="M11 37v17h37V37M18 39h23M18 16h28v20H18zM32 9v16m-7-7 7 7 7-7"/>',
    "clock": '<circle cx="32" cy="34" r="22"/><path d="M32 19v16l10 6M25 6h14M32 6v6"/>',
    "turn": '<path d="M50 27c-3-12-14-19-26-16-10 2-16 9-18 17M14 20l-8 8-4-9M14 37c3 12 14 19 26 16 10-2 16-9 18-17M50 44l8-8 4 9"/>',
    "target": '<circle cx="32" cy="32" r="18"/><circle cx="32" cy="32" r="6"/><path d="M32 4v16M32 44v16M4 32h16M44 32h16"/>',
    "reveal": '<path d="M5 32c8-12 17-18 27-18s19 6 27 18c-8 12-17 18-27 18S13 44 5 32Z"/><circle cx="32" cy="32" r="9"/><circle cx="32" cy="32" r="3" fill="#E8E6E0" stroke="none"/>',
    "death": '<path d="M15 26c0-11 7-18 17-18s17 7 17 18c0 8-3 13-8 16v10H23V42c-5-3-8-8-8-16Z"/><path d="m21 28 7 4-7 3m22-7-7 4 7 3M27 43v8M37 43v8M24 56h16"/>',
    "study": '<path d="M10 8h24v31H10zM15 16h13M15 23h11"/><circle cx="40" cy="39" r="11"/><path d="m48 47 9 9"/>',
    "spell": '<path d="M32 6 49 32 32 58 15 32 32 6Z"/><path d="M32 15v34M23 32h18"/><circle cx="32" cy="32" r="5"/>',
    "lock": '<path d="M16 28h32v28H16zM22 28v-9c0-8 4-13 10-13s10 5 10 13v9M32 37v11"/>',
    "unlock": '<path d="M16 28h32v28H16zM22 28v-9c0-8 4-13 10-13 5 0 9 4 10 9M32 37v11"/>',
    "search": '<circle cx="27" cy="27" r="16"/><path d="m39 39 16 16"/>',
    "settings": '<path d="M27 6h10l2 7 6 3 7-3 5 9-5 5v10l5 5-5 9-7-3-6 3-2 7H27l-2-7-6-3-7 3-5-9 5-5V27l-5-5 5-9 7 3 6-3 2-7Z"/><circle cx="32" cy="32" r="9"/>',
    "warning": '<path d="M32 6 59 55H5L32 6Z"/><path d="M32 23v16M32 47v2"/>',
    "success": '<path d="M11 33 26 48 53 18M8 8h48v48H8z"/>',
    "error": '<path d="M19 8h26l11 11v26L45 56H19L8 45V19L19 8Z"/><path d="m23 23 18 18m0-18L23 41"/>',
    "info": '<circle cx="32" cy="32" r="24"/><path d="M32 28v16M32 18v2"/>',
    "inventory": '<path d="M7 20h50v36H7zM14 20v-9h36v9M7 31h50M27 30v8h10v-8"/>',
    "currency": '<path d="M32 6 52 17v30L32 58 12 47V17L32 6Z"/><path d="M40 22c-3-3-6-4-9-4-6 0-9 3-9 7s3 6 10 7 10 4 10 8-4 7-10 7c-4 0-8-2-11-5M32 13v38"/>',
    "filter": '<path d="M7 11h50L37 33v16l-10 7V33L7 11Z"/>',
    "sort": '<path d="M14 13v38m-8-8 8 8 8-8M32 17h24M32 29h18M32 41h12M32 53h6"/>',
    "close": '<path d="M14 14 50 50M50 14 14 50"/>',
    "duplicate": '<path d="M19 9h34v39H19zM12 16H8v39h34v-7M27 18h18M27 26h18M27 34h13"/>',
    "delete": '<path d="M14 17h36M20 17l2 39h20l2-39M25 17v-7h14v7M28 27v20M36 27v20"/>',
    "edit": '<path d="m10 47 29-29 8 8-29 29-10 2 2-10ZM35 22l8 8M44 13l5-5 8 8-5 5"/>',
    "arrow_left": '<path d="M53 32H11m18-18L11 32l18 18"/>',
    "arrow_right": '<path d="M11 32h42M35 14l18 18-18 18"/>',
    "chevron_down": '<path d="m13 23 19 19 19-19"/>',
    "chevron_up": '<path d="m13 41 19-19 19 19"/>',
    "menu": '<path d="M9 15h46M9 32h46M9 49h46"/>',
    "play": '<path d="M17 10 53 32 17 54V10Z"/>',
    "pause": '<path d="M15 10h11v44H15zM38 10h11v44H38z"/>',
    "plus": '<path d="M32 10v44M10 32h44"/>',
    "minus": '<path d="M10 32h44"/>',
    "check": '<path d="M9 33 25 49 55 15"/>',
    "home": '<path d="M8 30 32 9l24 21M15 28v27h34V28M26 55V39h12v16"/>',
    "notifications": '<path d="M19 42V26c0-10 5-16 13-16s13 6 13 16v16l6 7H13l6-7ZM27 54h10"/>',
    "profile": '<circle cx="32" cy="22" r="11"/><path d="M10 55c1-13 9-19 22-19s21 6 22 19H10Z"/>',
    "volume_on": '<path d="M8 26h11l14-12v36L19 38H8V26ZM41 23c5 5 5 13 0 18M47 16c9 9 9 23 0 32"/>',
    "volume_off": '<path d="M8 26h11l14-12v36L19 38H8V26ZM42 23l14 18m0-18L42 41"/>',
    "fullscreen": '<path d="M8 24V8h16M40 8h16v16M56 40v16H40M24 56H8V40"/>',
    "quest": '<path d="M16 7h32v50H16zM23 18h18M23 28h18M23 38h10M39 39l3 3 6-7"/>',
    "status": '<path d="M32 6 54 17v16c0 12-8 19-22 25C18 52 10 45 10 33V17L32 6Z"/><path d="M22 31h20M32 21v20"/>',
    "download": '<path d="M32 7v34m-11-11 11 11 11-11M11 47v9h42v-9"/>',
    "upload": '<path d="M32 41V7M21 18 32 7l11 11M11 47v9h42v-9"/>',
}

SVG_TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
<g fill="none" stroke="#E8E6E0" stroke-width="4" stroke-linecap="square" stroke-linejoin="miter">{shape}</g>
</svg>
'''


def render_png(item: tuple[str, Path]) -> None:
    name, svg_path = item
    png_path = PNG_DIR / f"ui_icon_{name}_64.png"
    subprocess.run(
        [INKSCAPE, str(svg_path), "--export-type=png",
         f"--export-filename={png_path}", "--export-width=64", "--export-height=64"],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    exports: list[tuple[str, Path]] = []
    for name, shape in ICONS.items():
        svg_path = SVG_DIR / f"ui_icon_{name}.svg"
        svg_path.write_text(SVG_TEMPLATE.format(shape=shape), encoding="utf-8")
        ET.parse(svg_path)
        exports.append((name, svg_path))
    if INKSCAPE is None:
        raise SystemExit("Inkscape is required for the 64 px PNG exports")
    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(render_png, exports))
    print(f"Wrote {len(exports)} SVG masters and {len(exports)} PNG exports")


if __name__ == "__main__":
    main()
