#!/usr/bin/env python3
"""Build the text-free, layered OMEN card UI kit from SVG masters.

Requires Inkscape for the PNG exports. Run from any working directory.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


HERE = Path(__file__).resolve().parent

INK = "#0B0D0E"
SURFACE = "#1C2022"
RAISED = "#282D2F"
EDGE = "#41474A"
STEEL = "#6C7375"
TEXT = "#E8E6E0"
MUTED = "#838A8A"
ASH = "#B44743"
PARALLAX = "#5B9FC4"
STRAIN = "#64A477"
COVENANT = "#A87DC2"
AEGIS = "#C6A451"
SUCCESS = "#7FA36E"


def svg(width: int, height: int, body: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}"
  viewBox="0 0 {width} {height}">
  <defs>
    <linearGradient id="metal" x1="0" y1="0" x2="0.95" y2="1">
      <stop offset="0" stop-color="#353B3E"/>
      <stop offset="0.5" stop-color="{SURFACE}"/>
      <stop offset="1" stop-color="{INK}"/>
    </linearGradient>
    <linearGradient id="face" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{RAISED}"/>
      <stop offset="1" stop-color="{SURFACE}"/>
    </linearGradient>
  </defs>
  {body}
</svg>
'''


def export(name: str, width: int, height: int, body: str) -> None:
    source = HERE / f"{name}.svg"
    raster = HERE / f"{name}.png"
    source.write_text(svg(width, height, body), encoding="utf-8")
    environment = os.environ.copy()
    for key in ("XDG_CACHE_HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME"):
        environment.setdefault(key, f"/tmp/omen-cardkit-{key.lower()}")
    result = subprocess.run(
        ["inkscape", str(source), "--export-type=png",
         f"--export-filename={raster}", "--export-background-opacity=0"],
        env=environment, text=True, capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(f"Could not export {source}:\n{result.stderr}")


def outer_path() -> str:
    return "M30 8 H720 L742 30 V1020 L720 1042 H30 L8 1020 V30 Z"


def art_path() -> str:
    return "M50 173 H700 L704 177 V681 L700 685 H50 L46 681 V177 Z"


def card_frame() -> str:
    # Even-odd fill leaves a truly transparent window for the illustration.
    body = f'''
      <path d="{outer_path()} {art_path()}" fill="url(#metal)" fill-rule="evenodd"/>
      <path d="{outer_path()}" fill="none" stroke="{STEEL}" stroke-width="5"/>
      <path d="{outer_path()}" fill="none" stroke="{INK}" stroke-width="2"
        transform="translate(0,0) scale(0.985,0.985) translate(5.625,7.875)"/>
      <path d="{art_path()}" fill="none" stroke="{STEEL}" stroke-width="3"/>
      <path d="M46 692 H704" stroke="{EDGE}" stroke-width="3"/>
      <path d="M54 29 H696 L718 51 V139 L696 158 H54 L32 139 V51 Z"
        fill="url(#face)" stroke="{EDGE}" stroke-width="2"/>
      <path d="M52 714 H698 V968 H52 Z" fill="{SURFACE}" stroke="{EDGE}" stroke-width="2"/>
      <path d="M52 714 H698" stroke="{STEEL}" stroke-width="3"/>
      <path d="M52 978 H698" stroke="{EDGE}" stroke-width="2"/>
      <path d="M52 1026 H698" stroke="{STEEL}" stroke-width="2"/>
      <path d="M37 58 V141 M713 58 V141 M38 718 V970 M712 718 V970"
        stroke="{STEEL}" stroke-opacity="0.45" stroke-width="2"/>
      <path d="M60 40 H138 M60 45 H110 M610 100 H684 M595 106 H664
        M75 728 H186 M560 957 H672 M58 996 H137 M628 996 H690"
        fill="none" stroke="{TEXT}" stroke-opacity="0.12" stroke-width="2"/>
      <path d="M50 164 H700 M52 702 H698" stroke="{INK}" stroke-width="4"/>
      <path d="M17 42 L42 17 M708 17 L733 42 M17 1008 L42 1033 M708 1033 L733 1008"
        stroke="{TEXT}" stroke-opacity="0.18" stroke-width="2"/>
      <path d="M56 145 H92 M658 145 H694 M56 1001 H92 M658 1001 H694"
        stroke="{STEEL}" stroke-width="2"/>
    '''
    return body


def faction_motif(name: str, color: str) -> str:
    common = f'fill="none" stroke="{color}" stroke-width="3" stroke-linecap="square"'
    if name == "parallax":
        return f'''<circle cx="59" cy="67" r="14" {common}/>
          <circle cx="59" cy="67" r="6" {common}/>
          <path d="M59 48 V54 M59 80 V86 M40 67 H46 M72 67 H78" {common}/>'''
    if name == "strain":
        return f'''<path d="M58 84 V65 L47 54 M58 65 L70 52 M58 72 L74 80
          M47 54 L44 48 M70 52 L76 46 M74 80 L80 81" {common}/>
          <circle cx="58" cy="64" r="3" fill="{color}"/>'''
    if name == "covenant":
        return f'''<path d="M74 53 A18 18 0 1 0 75 78 M47 51 A14 14 0 0 1 69 57"
          {common}/><path d="M49 82 L56 75 L63 82" {common}/>'''
    if name == "ash":
        return f'''<path d="M45 53 A18 18 0 0 1 73 52 M74 77 A18 18 0 0 1 48 81
          M40 84 L76 47 M67 47 H78 V58" {common}/>'''
    return f'''<path d="M59 47 L76 53 V68 Q76 78 59 87 Q42 78 42 68 V53 Z"
      {common}/><path d="M48 62 H70 M59 56 V78" {common}/>'''


def faction_overlay(name: str, color: str) -> str:
    # The same touchpoints bind each faction to the neutral frame. The insignia
    # shape at the top left differs, so identity is never carried by hue alone.
    return f'''
      <path d="M55 154 H697 M52 703 H698" stroke="{color}" stroke-width="4"
        stroke-opacity="0.85"/>
      <path d="M31 178 V304 M31 571 V682 M719 178 V304 M719 571 V682"
        stroke="{color}" stroke-width="6" stroke-opacity="0.66"/>
      <path d="M54 714 H89 M661 714 H696 M54 970 H89 M661 970 H696"
        stroke="{color}" stroke-width="5"/>
      <path d="M121 46 H534" stroke="{color}" stroke-width="3" stroke-opacity="0.5"/>
      <path d="M37 36 L58 15 M692 1035 L713 1014" stroke="{color}"
        stroke-width="4" stroke-opacity="0.55"/>
      {faction_motif(name, color)}
    '''


def rarity_overlay(name: str, color: str, glyph: str) -> str:
    # The bottom center mount is reserved for a rarity marker.  The five
    # silhouettes are independently recognizable when desaturated.
    return f'''
      <path d="M327 975 H423 L436 989 V1031 H314 V989 Z" fill="{INK}"
        stroke="{STEEL}" stroke-width="3"/>
      <path d="M331 980 H419" stroke="{color}" stroke-width="4"/>
      <g fill="none" stroke="{color}" stroke-width="5" stroke-linejoin="miter"
        stroke-linecap="square">{glyph}</g>
    '''


def corner_brackets(color: str, thickness: int = 7) -> str:
    return f'''
      <path d="M17 110 V39 L39 17 H111 M639 17 H711 L733 39 V110
        M17 940 V1011 L39 1033 H111 M639 1033 H711 L733 1011 V940"
        fill="none" stroke="{color}" stroke-width="{thickness}"/>
    '''


def state_overlay(name: str) -> str:
    if name == "selected":
        return corner_brackets(TEXT, 8) + f'''
          <path d="M119 18 H631 M119 1032 H631" stroke="{ASH}" stroke-width="4"/>
        '''
    if name == "targetable":
        return corner_brackets(SUCCESS, 7) + f'''
          <path d="M364 19 H386 M364 1031 H386 M18 515 V535 M732 515 V535"
            stroke="{SUCCESS}" stroke-width="5"/>
        '''
    if name == "exhausted":
        return f'''
          <path d="{art_path()}" fill="{INK}" fill-opacity="0.58"/>
          <path d="M104 181 L317 675 M265 181 L478 675 M426 181 L639 675"
            stroke="{MUTED}" stroke-width="11" stroke-opacity="0.32"/>
          <path d="M52 698 H698" stroke="{MUTED}" stroke-width="6"/>
        '''
    if name == "locked":
        return f'''
          <path d="{art_path()}" fill="{INK}" fill-opacity="0.68"/>
          <path d="M294 394 H456 L470 409 V500 L456 515 H294 L280 500 V409 Z"
            fill="{SURFACE}" stroke="{STEEL}" stroke-width="7"/>
          <path d="M329 394 V357 A46 46 0 0 1 421 357 V394"
            fill="none" stroke="{STEEL}" stroke-width="12"/>
          <circle cx="375" cy="452" r="10" fill="{MUTED}"/>
          <path d="M375 461 V480" stroke="{MUTED}" stroke-width="10"/>
        '''
    raise ValueError(name)


def cost_diamond() -> str:
    return f'''
      <path d="M56 4 L108 56 L56 108 L4 56 Z" fill="{INK}"
        stroke="{STEEL}" stroke-width="4"/>
      <path d="M56 12 L100 56 L56 100 L12 56 Z" fill="{RAISED}"
        stroke="{EDGE}" stroke-width="3"/>
      <path d="M56 13 L99 56" stroke="{TEXT}" stroke-opacity="0.22" stroke-width="3"/>
      <path d="M56 4 L74 22 M4 56 L22 74" stroke="{AEGIS}" stroke-width="5"/>
    '''


def attack_badge() -> str:
    return f'''
      <path d="M21 6 H91 L115 26 V58 L91 78 H21 L5 58 V26 Z"
        fill="{INK}" stroke="{STEEL}" stroke-width="4"/>
      <path d="M22 13 H87 L106 28 V55 L87 71 H22 L13 55 V28 Z"
        fill="{SURFACE}" stroke="{EDGE}" stroke-width="2"/>
      <path d="M12 52 L34 72 M20 24 L39 11" stroke="{ASH}" stroke-width="5"/>
      <path d="M42 18 L35 25 M78 17 L71 24" stroke="{TEXT}" stroke-opacity="0.2"
        stroke-width="3"/>
    '''


def health_badge() -> str:
    return f'''
      <path d="M60 3 L112 21 V45 Q112 66 60 78 Q8 66 8 45 V21 Z"
        fill="{INK}" stroke="{STEEL}" stroke-width="4"/>
      <path d="M60 11 L104 26 V44 Q104 60 60 70 Q16 60 16 44 V26 Z"
        fill="{SURFACE}" stroke="{EDGE}" stroke-width="2"/>
      <path d="M13 25 L60 8 L105 25" fill="none" stroke="{SUCCESS}"
        stroke-width="4"/>
      <path d="M28 32 V49 M92 32 V49" stroke="{TEXT}" stroke-opacity="0.18"
        stroke-width="3"/>
    '''


def keyword_chip() -> str:
    return f'''
      <path d="M11 3 H212 L221 12 V45 L212 54 H11 L3 45 V12 Z"
        fill="{SURFACE}" stroke="{STEEL}" stroke-width="3"/>
      <path d="M13 10 H211 M13 47 H211" stroke="{EDGE}" stroke-width="2"/>
      <path d="M4 28 H20 M205 28 H220" stroke="{ASH}" stroke-width="4"/>
    '''


def main() -> None:
    HERE.mkdir(parents=True, exist_ok=True)
    export("card_frame_neutral", 750, 1050, card_frame())
    export("card_art_mask", 750, 1050,
           f'<path d="{art_path()}" fill="white"/>')

    factions = {
        "parallax": PARALLAX, "strain": STRAIN, "covenant": COVENANT,
        "ash": ASH, "aegis": AEGIS,
    }
    for name, color in factions.items():
        export(f"card_faction_{name}", 750, 1050,
               faction_overlay(name, color))

    rarity = {
        "common": (STEEL, '<path d="M349 1006 H401"/>'),
        "uncommon": (SUCCESS, '<path d="M345 1000 H405 M345 1012 H405"/>'),
        "rare": (PARALLAX, '<path d="M375 987 L399 1006 L375 1025 L351 1006 Z"/>'),
        "epic": (COVENANT, '<path d="M375 986 L400 1006 L375 1026 L350 1006 Z"/>'
                '<path d="M345 1006 H405 M375 981 V1031"/>'),
        "legendary": (AEGIS, '<path d="M375 985 L381 999 L402 1002 L387 1012 '
                       'L391 1026 L375 1017 L359 1026 L363 1012 L348 1002 '
                       'L369 999 Z"/>'),
    }
    for name, (color, glyph) in rarity.items():
        export(f"card_rarity_{name}", 750, 1050,
               rarity_overlay(name, color, glyph))

    for name in ("selected", "targetable", "exhausted", "locked"):
        export(f"card_state_{name}", 750, 1050, state_overlay(name))

    export("card_cost_diamond", 112, 112, cost_diamond())
    export("card_stat_attack", 120, 80, attack_badge())
    export("card_stat_health", 120, 80, health_badge())
    export("card_keyword_chip", 224, 56, keyword_chip())


if __name__ == "__main__":
    main()
