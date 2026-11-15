# Sound effects

Original synthesized effects, stored as 48 kHz, 16-bit stereo WAVs.
Regenerate with `python3 generate.py` (requires NumPy).

`SFX` is an autoload with one polyphonic player per effect. All effects go to
the `SFX` audio bus, initially at -8 dB. Adjust or mute that bus through
`AudioServer` to control the effects without affecting future music.

Gameplay cues follow changes in server snapshots: initial deal/draw,
new cards on the stack or battlefield, studying (maximum energy increases),
new attackers, player health loss, and turn changes. Identical updates and
stack-to-battlefield resolution do not replay cues. Victory plays once on a
winning game-end message. Menu and action buttons play UI confirmation.

Run `godot --headless --path . res://tests/sound_effects.tscn` from the project
root to check event transitions, duplicate suppression and actual mixed samples.

The stack scroll area reserves its vertical scrollbar gutter. This keeps card
text width stable as cards enter the stack, avoiding a text-wrap/scrollbar
layout feedback loop encountered while recording gameplay.
