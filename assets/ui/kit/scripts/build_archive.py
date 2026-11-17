#!/usr/bin/env python3
"""Package the OMEN kit with its existing font and faction dependencies."""

from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


KIT = Path(__file__).resolve().parents[1]
CLIENT = KIT.parents[2]
ARCHIVE = CLIENT.parent / "artifacts/omen_ui_asset_kit.zip"
PREVIEW = CLIENT.parent / "artifacts/omen_ui_asset_kit_preview.png"


def files() -> list[Path]:
    result = [path for path in KIT.rglob("*") if path.is_file()
              and path.suffix != ".import" and "__pycache__" not in path.parts]
    result += list((CLIENT / "assets/icons/factions").glob("*.svg"))
    result.append(CLIENT / "assets/icons/global/colorless.svg")
    result += [path for path in (CLIENT / "assets/fonts").glob("Barlow*")
               if path.suffix in (".ttf", ".tres")]
    result += list((CLIENT / "assets/fonts").glob("OFL-Barlow*.txt"))
    result += [CLIENT / "assets/ui/STYLE_TOKENS.md",
               CLIENT / "assets/ui/omen_components/logo/omen_nav_logo.png"]
    return sorted(set(result))


def main() -> None:
    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(ARCHIVE, "w", ZIP_DEFLATED, compresslevel=9) as output:
        for path in files():
            name = path.relative_to(CLIENT).as_posix()
            info = ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            output.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED,
                            compresslevel=9)
    PREVIEW.write_bytes((KIT / "previews/overview.png").read_bytes())
    PREVIEW.chmod(0o644)
    ARCHIVE.chmod(0o644)
    print(f"{ARCHIVE} ({ARCHIVE.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
