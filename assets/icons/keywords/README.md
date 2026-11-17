# OMEN combat keyword badges

Each keyword has a 64×64 transparent SVG master and matching PNG export.
Display at 24–32 px on cards. A clipped graphite plate and steel edge keep
the glyph readable over bright or dark artwork. The colored top mark is a
restrained semantic accent; the silhouette carries the meaning. Production
files contain no text or numbers.

| Rules keyword | Motif |
|---|---|
| Deadly | Skull and fangs |
| Defender | Reinforced shield |
| FirstStrike | Forward blade and impact rays |
| Trample | Armoured boot and fractured ground |
| Evasive | Curved route around an obstacle |
| Vigilance | Watchful eye and radar ticks |
| Lifelink | Heart and link pulse |
| Reach | Extended spear above a barricade |
| Drain | Life droplet pulled into a vessel |
| Unblockable | Arrow through a split shield |
| Blitz | Angular lightning strike |
| Decay | Fractured hourglass |
| Regenerate | Renewal arrow around a medical cross |

`manifest.json` maps the exact rules-engine property name to each file. Run
`python3 assets/icons/keywords/generate.py` to rebuild the SVG and PNG files
(requires Pillow and Inkscape). Keyword names remain in the regular card text;
the badge files contain no lettering. The Deploying badge remains at
`assets/icons/properties/`.
The labelled `previews/keyword_contact_sheet.png` is for review only.
