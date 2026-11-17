#!/usr/bin/env python3
"""Render OMEN's original, seamless 32-bar ambient theme to a 48 kHz WAV.

Usage: python3 generate.py /tmp/omen_dead_signal.wav
Requires NumPy and SciPy. Encode the resulting WAV to Ogg Vorbis for Godot.
"""

from __future__ import annotations

import argparse
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt


SAMPLE_RATE = 48_000
BPM = 78
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 32
SAMPLES = round(BARS * BAR * SAMPLE_RATE)
LENGTH = SAMPLES / SAMPLE_RATE
RNG = np.random.default_rng(920017)
MIX = np.zeros((SAMPLES, 2), dtype=np.float32)
SPACE = np.zeros_like(MIX)


def timeline(seconds: float) -> np.ndarray:
    return np.arange(round(seconds * SAMPLE_RATE), dtype=np.float32) / SAMPLE_RATE


def pitch(midi: int) -> float:
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def place(sound: np.ndarray, seconds: float, gain: float, pan: float = 0.0,
          space: float = 0.0) -> None:
    """Place a sound on a circular timeline so tails cross the loop point."""
    sound = np.asarray(sound, dtype=np.float32)
    start = round(seconds * SAMPLE_RATE) % SAMPLES
    frames = min(len(sound), SAMPLES)
    left = np.sqrt((1.0 - pan) * 0.5) * gain
    right = np.sqrt((1.0 + pan) * 0.5) * gain
    first = min(frames, SAMPLES - start)
    for target, amount in ((MIX, 1.0), (SPACE, space)):
        if amount == 0.0:
            continue
        target[start:start + first, 0] += sound[:first] * left * amount
        target[start:start + first, 1] += sound[:first] * right * amount
        if first < frames:
            target[:frames - first, 0] += sound[first:frames] * left * amount
            target[:frames - first, 1] += sound[first:frames] * right * amount


def soft_envelope(t: np.ndarray, duration: float, attack: float,
                  release: float) -> np.ndarray:
    onset = np.clip(t / attack, 0.0, 1.0)
    exit_ = np.clip((duration - t) / release, 0.0, 1.0)
    return np.sin(onset * np.pi * 0.5) ** 2 * np.sin(exit_ * np.pi * 0.5) ** 2


def pad(midi: int, duration: float, phase_offset: float) -> np.ndarray:
    t = timeline(duration)
    f = pitch(midi)
    phase = 2 * np.pi * f * t + 0.23 * np.sin(2 * np.pi * 0.17 * t + phase_offset)
    tone = (0.64 * np.sin(phase) + 0.25 * np.sin(2.003 * phase + 0.3)
            + 0.11 * np.sin(3.997 * phase + 1.0))
    return (tone * soft_envelope(t, duration, 1.3, 2.0)).astype(np.float32)


def pulse(midi: int) -> np.ndarray:
    t = timeline(0.92)
    f = pitch(midi)
    phase = 2 * np.pi * f * t + 0.45 * (1.0 - np.exp(-24.0 * t))
    tone = np.sin(phase) + 0.22 * np.sin(2.0 * phase + 0.35)
    return (np.tanh(tone * 1.3) * np.exp(-4.2 * t)
            * (1.0 - np.exp(-95.0 * t))).astype(np.float32)


def kick() -> np.ndarray:
    t = timeline(0.52)
    frequency = 44.0 + 86.0 * np.exp(-28.0 * t)
    phase = 2 * np.pi * np.cumsum(frequency, dtype=np.float64) / SAMPLE_RATE
    body = np.sin(phase) * np.exp(-11.0 * t) * (1.0 - np.exp(-250.0 * t))
    click = RNG.standard_normal(len(t)) * np.exp(-120.0 * t) * 0.045
    return (body + click).astype(np.float32)


def metal_tick() -> np.ndarray:
    t = timeline(0.22)
    noise = RNG.standard_normal(len(t)).astype(np.float32)
    highpass = butter(2, 1800, btype="highpass", fs=SAMPLE_RATE, output="sos")
    scrape = sosfilt(highpass, noise) * np.exp(-48.0 * t) * 0.18
    ring = (np.sin(2 * np.pi * 1081 * t) * 0.48
            + np.sin(2 * np.pi * 1763 * t) * 0.30
            + np.sin(2 * np.pi * 2897 * t) * 0.22) * np.exp(-24.0 * t)
    return ((ring + scrape) * (1.0 - np.exp(-480.0 * t))).astype(np.float32)


def dry_snare() -> np.ndarray:
    t = timeline(0.39)
    noise = RNG.standard_normal(len(t)).astype(np.float32)
    band = butter(2, [730, 4900], btype="bandpass", fs=SAMPLE_RATE,
                  output="sos")
    scrape = sosfilt(band, noise) * np.exp(-19.0 * t)
    shell = np.sin(2 * np.pi * 186 * t) * np.exp(-16.0 * t)
    return (0.55 * scrape + 0.20 * shell).astype(np.float32)


def signal_bell(midi: int, duration: float = 2.8) -> np.ndarray:
    t = timeline(duration)
    f = pitch(midi)
    strike = (np.sin(2 * np.pi * f * t) * np.exp(-1.25 * t)
              + 0.32 * np.sin(2 * np.pi * f * 2.016 * t) * np.exp(-2.1 * t)
              + 0.16 * np.sin(2 * np.pi * f * 3.79 * t) * np.exp(-3.3 * t)
              + 0.07 * np.sin(2 * np.pi * f * 5.41 * t) * np.exp(-4.4 * t))
    return (strike * (1.0 - np.exp(-420.0 * t))).astype(np.float32)


def radio_rise() -> np.ndarray:
    t = timeline(BAR * 0.75)
    noise = RNG.standard_normal(len(t)).astype(np.float32)
    band = butter(2, [330, 3600], btype="bandpass", fs=SAMPLE_RATE,
                  output="sos")
    wash = sosfilt(band, noise)
    signal = np.sin(2 * np.pi * (205.0 * t + 67.0 * t * t))
    envelope = np.sin(np.pi * t / t[-1]) ** 2
    return ((wash * 0.38 + signal * 0.12) * envelope).astype(np.float32)


def render() -> np.ndarray:
    # Low, periodic electrical hum. Quantized cycle counts make its phase join.
    t = np.arange(SAMPLES, dtype=np.float32) / SAMPLE_RATE
    cycles = round(pitch(26) * LENGTH)
    phase = 2 * np.pi * cycles * t / LENGTH
    sway = 0.72 + 0.13 * np.sin(2 * np.pi * 4 * t / LENGTH)
    hum = (0.62 * np.sin(phase) + 0.26 * np.sin(2 * phase + 0.15)
           + 0.12 * np.sin(4 * phase + 0.4)) * sway
    place(hum, 0.0, 0.065, space=0.3)
    del t, phase, hum

    # Eight four-bar voicings: minor seconds and open fifths, returning to D.
    chords = [
        (0, (50, 57, 63)), (4, (51, 58, 62)),
        (8, (50, 57, 65)), (12, (46, 53, 62)),
        (16, (50, 57, 63)), (20, (53, 60, 63)),
        (24, (45, 51, 60)), (28, (50, 57, 63)),
    ]
    for chord_index, (bar, notes) in enumerate(chords):
        for voice_index, note in enumerate(notes):
            voice = pad(note, 4 * BAR + 1.3, voice_index * 1.7)
            place(voice, bar * BAR, 0.055 if voice_index < 2 else 0.038,
                  pan=(-0.28, 0.24, 0.03)[voice_index], space=0.7)

    roots = (38, 39, 38, 34, 38, 41, 33, 38)
    for bar in range(BARS):
        root = roots[bar // 4]
        active = 8 <= bar < 24
        pressure = 16 <= bar < 24
        steps = (0.0, 1.5, 2.5, 3.5) if pressure else ((0.0, 2.0, 3.5) if active else (0.0, 2.5))
        for step_index, step in enumerate(steps):
            note = root + (1 if step_index == len(steps) - 1 and bar % 4 == 3 else 0)
            place(pulse(note), bar * BAR + step * BEAT,
                  0.078 if active else 0.043, pan=-0.08 if step_index % 2 else 0.08)
        for beat in ((0.0, 2.0) if active else (0.0,)):
            place(kick(), bar * BAR + beat * BEAT,
                  (0.13 if pressure else 0.10) if active else 0.047)
        if active:
            place(dry_snare(), bar * BAR + 3 * BEAT,
                  0.077 if pressure else 0.05, pan=0.13)
        ticks = (0.75, 1.75, 2.75, 3.5) if pressure else (0.75, 2.75)
        for index, beat in enumerate(ticks):
            if bar < 8 and index == 1 and bar % 2 == 0:
                continue
            place(metal_tick(), bar * BAR + beat * BEAT,
                  (0.027 if pressure else 0.017) * (0.85 if bar % 4 == 3 else 1.0),
                  pan=-0.47 if (bar + index) % 2 else 0.47, space=0.18)

    # Sparse four-note signal motif; later phrases answer it at other octaves.
    melody = [
        (1, 2.0, 62, 0.045), (2, 0.0, 63, 0.038),
        (3, 1.5, 57, 0.043), (6, 2.0, 60, 0.034),
        (8, 1.0, 62, 0.055), (9, 2.5, 63, 0.048),
        (11, 0.0, 57, 0.049), (13, 3.0, 60, 0.041),
        (15, 1.5, 62, 0.045), (16, 0.5, 65, 0.063),
        (17, 2.0, 63, 0.057), (18, 3.0, 62, 0.053),
        (20, 1.0, 57, 0.056), (22, 2.5, 60, 0.046),
        (23, 3.0, 63, 0.045), (25, 1.0, 62, 0.047),
        (26, 2.5, 63, 0.041), (28, 0.0, 57, 0.040),
        (30, 2.0, 62, 0.038),
    ]
    for index, (bar, beat, note, gain) in enumerate(melody):
        place(signal_bell(note), bar * BAR + beat * BEAT,
              gain, pan=-0.34 if index % 2 else 0.34, space=0.95)
    for bar in (7, 15, 23, 31):
        place(radio_rise(), (bar + 0.25) * BAR, 0.024,
              pan=-0.22 if bar % 2 else 0.22, space=0.55)

    # Distant machine room: narrowband air and a little low mechanical rumble.
    noise = RNG.standard_normal(SAMPLES).astype(np.float32)
    air_filter = butter(2, [900, 5200], btype="bandpass", fs=SAMPLE_RATE,
                        output="sos")
    air = sosfilt(air_filter, noise).astype(np.float32)
    mod = 0.7 + 0.3 * np.sin(2 * np.pi * 2 * np.arange(SAMPLES) / SAMPLES)
    place(air * mod, 0.0, 0.007, pan=-0.22)
    del air, noise, mod

    # Circular reflections let the last chord and its room decay feed bar one.
    reflections = ((0.091, 0.11), (0.157, 0.095), (0.239, 0.075),
                   (0.371, 0.057), (0.647, 0.039), (1.193, 0.023))
    for delay, gain in reflections:
        shift = round(delay * SAMPLE_RATE)
        MIX[:, 0] += np.roll(SPACE[:, 1], shift) * gain
        MIX[:, 1] += np.roll(SPACE[:, 0], shift) * gain

    MIX[:] = np.tanh(MIX * 1.16) / 1.16
    MIX[:] -= MIX.mean(axis=0)
    rms = float(np.sqrt(np.mean(MIX * MIX)))
    peak = float(np.max(np.abs(MIX)))
    target_rms = 10 ** (-20.0 / 20.0)
    gain = min(target_rms / max(rms, 1e-8), 0.48 / max(peak, 1e-8))
    MIX[:] *= gain

    # Match the endpoint exactly without touching the musical phrase.
    join = round(0.06 * SAMPLE_RATE)
    correction = (MIX[-1] - MIX[0]).copy()
    ramp = np.linspace(0.0, 1.0, join, dtype=np.float32) ** 2
    MIX[-join:] -= ramp[:, None] * correction
    return MIX


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="WAV master output path")
    path = parser.parse_args().output
    audio = render()
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setparams((2, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
        output.writeframes((audio * 32767.0).astype("<i2").tobytes())
    peak = 20 * np.log10(float(np.max(np.abs(audio))))
    rms = 20 * np.log10(float(np.sqrt(np.mean(audio * audio))))
    seam = float(np.max(np.abs(audio[0] - audio[-1])))
    print(f"{path}: {LENGTH:.3f}s, {BPM} BPM, 48 kHz stereo")
    print(f"peak {peak:.1f} dBFS, RMS {rms:.1f} dBFS, seam {seam:.7f}")


if __name__ == "__main__":
    main()
