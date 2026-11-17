#!/usr/bin/env python3
"""Validate the OMEN UI kit and rebuild its file catalog."""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


def family_metadata() -> dict[str, dict]:
    result: dict[str, dict] = {}
    for folder in ("surfaces", "controls"):
        path = ROOT / folder / "manifest.json"
        if not path.exists():
            raise SystemExit(f"Missing family manifest: {path}")
        data = json.loads(path.read_text())
        for entry in data["assets"]:
            key = f"{folder}/{entry['file']}"
            if key in result:
                raise SystemExit(f"Duplicate asset metadata: {key}")
            result[key] = entry
    return result


def inspect_png(path: Path, metadata: dict | None) -> dict:
    with Image.open(path) as image:
        image.load()
        size = list(image.size)
        if image.mode not in ("RGB", "RGBA"):
            raise SystemExit(f"Unexpected image mode: {path} ({image.mode})")
        if image.getbbox() is None:
            raise SystemExit(f"Empty image: {path}")
        transparent = image.mode == "RGBA" and image.getchannel("A").getextrema()[0] < 255
    if metadata is not None:
        documented_size = metadata.get("size") or metadata.get("size_px")
        if documented_size != size:
            raise SystemExit(f"Wrong size in manifest: {path}, {documented_size} != {size}")
        if bool(metadata.get("transparent")) != transparent:
            raise SystemExit(f"Wrong transparency in manifest: {path}")
    relative = path.relative_to(ROOT).as_posix()
    entry = {
        "path": relative,
        "kind": "png",
        "size_px": size,
        "transparent": transparent,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    if metadata:
        entry["family"] = metadata["family"]
        entry["state"] = metadata.get("state", "default")
        entry["slice_px"] = metadata.get("nine_slice", metadata.get("slice_margin_px"))
        entry["safe_content_px"] = metadata.get("safe_content_rect", metadata.get("safe_region_px"))
    else:
        entry["family"] = relative.split("/")[0]
    companion = path.with_suffix(".tres")
    if companion.exists():
        entry["godot_stylebox"] = companion.relative_to(ROOT).as_posix()
    return entry


def main() -> None:
    metadata = family_metadata()
    assets: list[dict] = []
    png_paths = sorted(path for path in ROOT.rglob("*.png") if "previews" not in path.parts)
    for path in png_paths:
        key = path.relative_to(ROOT).as_posix()
        assets.append(inspect_png(path, metadata.get(key)))
    missing = sorted(set(metadata) - {path.relative_to(ROOT).as_posix() for path in png_paths})
    if missing:
        raise SystemExit(f"Metadata points to missing PNGs: {missing[:5]}")

    for path in sorted(ROOT.rglob("*.svg")):
        ElementTree.parse(path)
        assets.append({
            "path": path.relative_to(ROOT).as_posix(),
            "kind": "svg",
            "family": path.relative_to(ROOT).parts[0],
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    for path in sorted(ROOT.rglob("*.tres")):
        content = path.read_text()
        if "[gd_resource" not in content:
            raise SystemExit(f"Invalid Godot resource header: {path}")
        if path != ROOT / "OMENKitTheme.tres" and "theme" not in path.relative_to(ROOT).parts:
            matching_png = path.with_suffix(".png")
            if not matching_png.exists():
                raise SystemExit(f"StyleBoxTexture has no PNG: {path}")
            if f"res://assets/ui/kit/{matching_png.relative_to(ROOT).as_posix()}" not in content:
                raise SystemExit(f"StyleBoxTexture has wrong path: {path}")

    counts = dict(Counter(asset["kind"] for asset in assets))
    catalog = {
        "name": "OMEN UI asset kit",
        "version": 1,
        "reference": "OMEN_Visual_Art_Direction.md; assets/ui/STYLE_TOKENS.md",
        "godot": "4.x",
        "counts": counts,
        "assets": assets,
    }
    (ROOT / "catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
    print(f"Validated {counts.get('png', 0)} PNGs, {counts.get('svg', 0)} SVGs, "
          f"{len(list(ROOT.rglob('*.tres')))} Godot resources")


if __name__ == "__main__":
    main()
