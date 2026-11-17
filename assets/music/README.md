# OMEN — Dead Signal

An original, instrumental gameplay theme centered on D Phrygian at 78 BPM.
The 32-bar arrangement lasts about 98.46 seconds and loops from its end to
its beginning. It moves from a distant electrical hum into a restrained
industrial pulse, adds a sparse metal motif, then returns to the opening
texture. The mix leaves space for the game's card and combat effects.

`omen_dead_signal.ogg` is the 48 kHz stereo game asset. The composition is
generated entirely from oscillators and noise in `generate.py`; it contains
no external recordings or samples.

Godot imports the Ogg as a looping stream with a 78 BPM, 128-beat grid.

To regenerate with Python 3, NumPy, SciPy, and FFmpeg:

```sh
python3 assets/music/generate.py /tmp/omen_dead_signal.wav
ffmpeg -i /tmp/omen_dead_signal.wav -c:a libvorbis -q:a 5 assets/music/omen_dead_signal.ogg
```
