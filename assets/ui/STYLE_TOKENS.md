# OMEN interface style tokens

The game uses Barlow Condensed for navigation, headings, card names, buttons, and counters, and Barlow for rules text, tooltips, and longer copy. Functional text stays clean; wear belongs on surfaces and decorative marks.

## Palette

| Use | Token | HEX |
|---|---|---|
| Deep canvas | `bg.void` | `#0B0D0E` |
| Main screen | `bg.base` | `#141719` |
| Standard panel | `surface.1` | `#1C2022` |
| Elevated panel | `surface.2` | `#282D2F` |
| Active neutral | `surface.3` | `#343A3D` |
| Subtle border | `border.subtle` | `#41474A` |
| Strong edge | `border.strong` | `#6C7375` |
| Main text | `text.primary` | `#E8E6E0` |
| Supporting text | `text.secondary` | `#B3B5B2` |
| Muted text | `text.muted` | `#838A8A` |
| Ash / primary action | `accent.ash` | `#B44743` |
| Parallax | `accent.parallax` | `#5B9FC4` |
| Strain | `accent.strain` | `#64A477` |
| Covenant | `accent.covenant` | `#A87DC2` |
| Aegis | `accent.aegis` | `#C6A451` |
| Success | `state.success` | `#7FA36E` |
| Warning | `state.warning` | `#C99A4D` |
| Error | `state.error` | `#CB5A52` |

The shared Theme and reusable StyleBoxFlat resources apply these colors to buttons, fields, panels, tooltips, and text. Faction insignia are monochrome masters; tint them with the matching faction accent. Use shape or wording alongside color for important states.

## Scale at a 1080p desktop size

| Element | Face | Size |
|---|---|---:|
| Screen title | Barlow Condensed | 28–40 px |
| Main navigation | Barlow Condensed SemiBold | 20–24 px |
| Panel heading | Barlow Condensed SemiBold | 18–22 px |
| Button label | Barlow Condensed SemiBold | 16–20 px |
| Card name | Barlow Condensed SemiBold | 20–26 px |
| Rules text | Barlow | 15–17 px |
| Tooltip | Barlow | 14–16 px |
| Counter | Barlow Condensed SemiBold | 18–26 px |

Godot's glyph tracking is an integer pixel value. The tracked font variations use 1 px for body display labels and button text, and 2 px for navigation where the guide recommends 1.5 px.
