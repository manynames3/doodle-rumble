"""Render the six original Doodle Rumble themes and their synchronized phases.

Run this file to regenerate the adjacent 16-bit mono WAVs. No samples, MIDI files,
or borrowed melodies are used. The fixed seed makes each render reproducible.
"""

from pathlib import Path
import wave

import numpy as np


RATE = 22050
OUT = Path(__file__).parent
RNG = np.random.default_rng(723194)


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def envelope(length, attack=0.008, release=0.08, decay=0.0):
    t = np.arange(length) / RATE
    duration = length / RATE
    attack_curve = np.minimum(1.0, t / max(attack, 1 / RATE))
    tail_curve = np.minimum(1.0, (duration - t) / max(release, 1 / RATE))
    return attack_curve * np.maximum(0, tail_curve) * np.exp(-decay * t)


def oscillator(midi, duration, kind):
    count = max(1, round(duration * RATE))
    t = np.arange(count) / RATE
    freq = hz(midi)
    phase = 2 * np.pi * freq * t
    if kind == "toy":
        tone = np.sin(phase) + 0.28 * np.sin(2 * phase) + 0.11 * np.sin(3 * phase)
        env = envelope(count, release=0.09, decay=1.8)
    elif kind == "bell":
        tone = np.sin(phase) + 0.34 * np.sin(2.01 * phase) + 0.18 * np.sin(3.94 * phase)
        env = envelope(count, attack=0.002, release=0.12, decay=2.0)
    elif kind == "reed":
        vibrato = 0.012 * np.sin(2 * np.pi * 5.2 * t)
        tone = np.sin(phase + vibrato) + 0.42 * np.sin(2 * phase) + 0.15 * np.sin(3 * phase)
        env = envelope(count, attack=0.018, release=0.075, decay=0.15)
    elif kind == "pixel":
        # Softened chiptune pulse: the harmonic rolloff avoids brittle square waves.
        tone = np.sin(phase) + 0.43 * np.sin(3 * phase) + 0.19 * np.sin(5 * phase)
        env = envelope(count, attack=0.003, release=0.04, decay=0.35)
    elif kind == "brass":
        tone = np.sin(phase) + 0.51 * np.sin(2 * phase) + 0.26 * np.sin(3 * phase)
        env = envelope(count, attack=0.018, release=0.12, decay=0.12)
    elif kind == "pad":
        wobble = 0.55 + 0.45 * np.sin(2 * np.pi * 0.72 * t + 0.8)
        tone = (np.sin(phase) + 0.20 * np.sin(2.005 * phase)) * wobble
        env = envelope(count, attack=0.085, release=0.18)
    elif kind == "bass":
        tone = np.sin(phase) + 0.27 * np.sin(2 * phase) + 0.06 * np.sin(3 * phase)
        env = envelope(count, attack=0.006, release=0.08, decay=0.65)
    else:
        raise ValueError(kind)
    return tone * env


def place(mix, beat_seconds, beat, signal, gain):
    start = round(beat * beat_seconds * RATE)
    end = min(len(mix), start + len(signal))
    if end > start:
        mix[start:end] += signal[: end - start] * gain


def drum(kind, duration):
    count = round(duration * RATE)
    t = np.arange(count) / RATE
    if kind == "kick":
        freq = 48 + 115 * np.exp(-t * 31)
        phase = 2 * np.pi * np.cumsum(freq) / RATE
        return (np.sin(phase) * np.exp(-t * 24) + 0.12 * RNG.uniform(-1, 1, count) * np.exp(-t * 95)) * envelope(count, attack=0.001, release=0.03)
    noise = RNG.uniform(-1, 1, count)
    if kind == "snare":
        noise = noise - np.convolve(noise, np.ones(13) / 13, mode="same")
        return (noise * 0.64 + np.sin(2 * np.pi * 182 * t) * 0.36) * np.exp(-t * 27) * envelope(count, attack=0.001, release=0.025)
    if kind == "hat":
        noise = noise - np.convolve(noise, np.ones(9) / 9, mode="same")
        return noise * np.exp(-t * 85) * envelope(count, attack=0.001, release=0.012)
    if kind == "tick":
        return (np.sin(2 * np.pi * 1260 * t) + 0.45 * np.sin(2 * np.pi * 1840 * t)) * np.exp(-t * 105)
    raise ValueError(kind)


SONGS = {
    "desktop": {
        "bpm": 112, "lead": "toy", "lead_gain": 0.17, "bass_gain": 0.19,
        "roots": [48, 43, 45, 41], "chords": [[60, 64, 67], [59, 62, 67], [60, 64, 69], [60, 65, 69]],
        "melody": [
            [(0, 72, .55), (.75, 76, .34), (1.25, 79, .50), (2, 76, .50), (3, 74, .45)],
            [(0, 71, .50), (.75, 74, .35), (1.25, 79, .50), (2, 81, .50), (3, 79, .52)],
            [(0, 76, .50), (.75, 72, .40), (1.5, 69, .45), (2.25, 72, .50), (3, 76, .55)],
            [(0, 77, .50), (.75, 76, .40), (1.5, 72, .50), (2.25, 69, .40), (3, 72, .75)],
        ],
        "roots_b": [45, 41, 48, 43], "chords_b": [[60, 64, 69], [60, 65, 69], [62, 64, 67], [59, 62, 67]],
        "melody_b": [
            [(0, 81, .42), (.5, 79, .32), (1, 76, .48), (2, 72, .42), (2.75, 74, .34), (3.25, 76, .48)],
            [(0, 77, .45), (.75, 81, .35), (1.5, 84, .48), (2.5, 81, .36), (3, 79, .52)],
            [(0, 79, .40), (.5, 76, .30), (1, 74, .38), (1.75, 76, .30), (2.5, 81, .42), (3.25, 79, .48)],
            [(0, 74, .42), (.75, 71, .32), (1.5, 74, .40), (2.25, 76, .38), (3, 79, .72)],
        ],
        "arp": "bell", "arp_pattern": [0, 1, 2, 1, 0, 1, 2, 1], "arp_gain": .045,
        "drums": "soft", "pad_gain": .048, "bass_pattern": [0, 2, 3.0],
    },
    "quarry": {
        "bpm": 138, "lead": "reed", "lead_gain": .17, "bass_gain": .25,
        "roots": [38, 34, 41, 36], "chords": [[62, 65, 69], [58, 62, 65], [60, 65, 69], [60, 64, 67]],
        "melody": [
            [(0, 74, .45), (.5, 77, .33), (1, 81, .55), (2, 77, .50), (2.75, 74, .32), (3.25, 72, .45)],
            [(0, 70, .45), (.5, 74, .36), (1, 77, .50), (2, 82, .50), (3, 79, .58)],
            [(0, 77, .50), (.75, 81, .42), (1.5, 84, .50), (2.5, 81, .34), (3, 77, .50)],
            [(0, 76, .55), (.75, 72, .40), (1.5, 79, .45), (2.5, 76, .32), (3, 74, .65)],
        ],
        "roots_b": [41, 36, 38, 34], "chords_b": [[60, 65, 69], [60, 64, 67], [62, 65, 70], [58, 62, 65]],
        "melody_b": [
            [(0, 81, .42), (.5, 84, .34), (1, 86, .52), (2, 84, .36), (2.75, 81, .34), (3.25, 77, .42)],
            [(0, 79, .45), (.75, 76, .34), (1.5, 72, .44), (2.25, 76, .36), (3, 79, .55)],
            [(0, 74, .38), (.5, 77, .30), (1, 82, .48), (1.75, 81, .34), (2.5, 77, .34), (3.25, 74, .46)],
            [(0, 70, .44), (.75, 74, .32), (1.5, 77, .40), (2.25, 81, .38), (3, 82, .68)],
        ],
        "arp": "toy", "arp_pattern": [0, 2, 1, 2, 0, 2, 1, 2], "arp_gain": .054,
        "drums": "drive", "pad_gain": .040, "bass_pattern": [0, 1.5, 2.0, 3.5],
    },
    "journey_green": {
        "bpm": 126, "lead": "bell", "lead_gain": .16, "bass_gain": .18,
        "roots": [43, 41, 36, 38], "chords": [[59, 62, 67], [57, 60, 65], [60, 64, 67], [57, 62, 66]],
        "melody": [
            [(0, 79, .40), (.5, 83, .34), (1, 86, .40), (1.75, 83, .35), (2.5, 79, .40), (3, 76, .50)],
            [(0, 77, .40), (.5, 81, .34), (1, 84, .48), (2, 81, .40), (2.75, 77, .36), (3.25, 74, .40)],
            [(0, 76, .40), (.5, 79, .36), (1, 84, .45), (2, 83, .40), (2.75, 79, .32), (3.25, 76, .50)],
            [(0, 78, .40), (.5, 81, .36), (1, 86, .50), (2, 81, .40), (2.75, 78, .38), (3.25, 79, .58)],
        ],
        "roots_b": [36, 38, 43, 41], "chords_b": [[60, 64, 67], [57, 62, 66], [59, 62, 67], [57, 60, 65]],
        "melody_b": [
            [(0, 84, .38), (.5, 83, .30), (1, 79, .40), (1.75, 76, .32), (2.5, 79, .38), (3.25, 83, .46)],
            [(0, 81, .40), (.75, 78, .32), (1.5, 74, .42), (2.25, 78, .34), (3, 81, .52)],
            [(0, 86, .38), (.5, 83, .30), (1, 79, .38), (1.75, 83, .32), (2.5, 86, .42), (3.25, 88, .46)],
            [(0, 84, .40), (.75, 81, .32), (1.5, 77, .40), (2.25, 78, .34), (3, 79, .68)],
        ],
        "arp": "pixel", "arp_pattern": [2, 1, 0, 1, 2, 1, 0, 1], "arp_gain": .036,
        "drums": "sync", "pad_gain": .052, "bass_pattern": [0, 1.5, 2.75],
    },
    "glitch": {
        "bpm": 142, "lead": "pixel", "lead_gain": .16, "bass_gain": .22,
        "roots": [42, 40, 38, 37], "chords": [[66, 69, 72], [64, 68, 71], [62, 65, 69], [61, 64, 68]],
        "melody": [
            [(0, 78, .35), (.75, 81, .25), (1.25, 84, .45), (2.25, 81, .30), (2.75, 78, .28), (3.5, 75, .30)],
            [(0, 76, .30), (.5, 80, .30), (1.5, 83, .45), (2.5, 80, .28), (3, 76, .45)],
            [(0, 74, .35), (.75, 77, .25), (1.25, 81, .45), (2.25, 77, .30), (2.75, 74, .28), (3.5, 72, .30)],
            [(0, 73, .30), (.5, 76, .30), (1.5, 80, .45), (2.5, 76, .28), (3, 78, .45)],
        ],
        "roots_b": [38, 37, 42, 40], "chords_b": [[62, 65, 69], [61, 64, 68], [66, 69, 72], [64, 68, 71]],
        "melody_b": [
            [(0, 86, .26), (.5, 81, .24), (1, 78, .30), (1.75, 75, .24), (2.5, 78, .28), (3, 81, .30)],
            [(0, 85, .28), (.75, 80, .24), (1.25, 76, .30), (2, 73, .24), (2.75, 76, .28), (3.5, 80, .26)],
            [(0, 78, .24), (.5, 81, .22), (1, 84, .28), (1.5, 87, .22), (2.5, 84, .26), (3.25, 81, .28)],
            [(0, 80, .28), (.75, 76, .22), (1.5, 73, .30), (2.25, 76, .24), (3, 78, .46)],
        ],
        "arp": "pixel", "arp_pattern": [2, 0, 1, 2, 1, 0, 2, 1], "arp_gain": .038,
        "drums": "sync", "pad_gain": .049, "bass_pattern": [0, .75, 2, 2.75],
    },
    "pac_man": {
        "bpm": 158, "lead": "pixel", "lead_gain": .18, "bass_gain": .21,
        "roots": [40, 36, 43, 38], "chords": [[64, 67, 71], [60, 64, 67], [62, 67, 71], [62, 66, 69]],
        "melody": [
            [(0, 76, .28), (.5, 79, .28), (1, 83, .28), (1.5, 79, .28), (2, 88, .30), (2.5, 83, .28), (3, 79, .28), (3.5, 76, .28)],
            [(0, 84, .28), (.5, 79, .28), (1, 76, .28), (1.5, 72, .28), (2, 76, .28), (2.5, 79, .28), (3, 83, .28), (3.5, 79, .28)],
            [(0, 79, .28), (.5, 83, .28), (1, 86, .28), (1.5, 83, .28), (2, 79, .28), (2.5, 74, .28), (3, 79, .28), (3.5, 83, .28)],
            [(0, 78, .28), (.5, 81, .28), (1, 86, .28), (1.5, 81, .28), (2, 78, .28), (2.5, 74, .28), (3, 76, .28), (3.5, 78, .28)],
        ],
        "roots_b": [43, 38, 40, 36], "chords_b": [[62, 67, 71], [62, 66, 69], [64, 67, 71], [60, 64, 67]],
        "melody_b": [
            [(0, 83, .24), (.25, 86, .22), (.75, 88, .24), (1.25, 86, .22), (2, 83, .24), (2.5, 79, .24), (3, 74, .28), (3.5, 79, .22)],
            [(0, 81, .24), (.5, 78, .22), (1, 74, .24), (1.5, 78, .22), (2, 81, .24), (2.5, 86, .26), (3.25, 81, .24)],
            [(0, 88, .24), (.5, 83, .22), (1, 79, .24), (1.5, 76, .22), (2, 79, .24), (2.5, 83, .22), (3, 86, .24), (3.5, 83, .22)],
            [(0, 84, .24), (.5, 81, .22), (1, 78, .24), (1.5, 74, .22), (2, 76, .24), (2.5, 78, .22), (3, 81, .24), (3.5, 84, .30)],
        ],
        "arp": "bell", "arp_pattern": [0, 1, 2, 1, 0, 1, 2, 1], "arp_gain": .027,
        "drums": "chase", "pad_gain": .026, "bass_pattern": [0, .75, 1.5, 2, 2.75, 3.5],
    },
    "dark_lord": {
        "bpm": 132, "lead": "brass", "lead_gain": .18, "bass_gain": .27,
        "roots": [33, 41, 38, 40], "chords": [[57, 60, 64], [60, 65, 69], [57, 62, 65], [56, 59, 64]],
        "melody": [
            [(0, 69, .80), (1, 72, .60), (2, 76, .75), (3, 79, .65)],
            [(0, 77, .70), (1, 76, .40), (1.5, 72, .50), (2.25, 81, .75), (3.25, 77, .40)],
            [(0, 74, .75), (1, 77, .50), (2, 81, .70), (3, 77, .55)],
            [(0, 80, .75), (1, 76, .50), (2, 71, .75), (3, 69, .70)],
        ],
        "roots_b": [38, 40, 33, 32], "chords_b": [[57, 62, 65], [56, 59, 64], [57, 60, 64], [56, 59, 63]],
        "melody_b": [
            [(0, 74, .58), (.75, 77, .38), (1.5, 81, .62), (2.5, 84, .55), (3.25, 81, .36)],
            [(0, 80, .62), (1, 76, .42), (1.75, 71, .50), (2.5, 68, .62), (3.5, 71, .32)],
            [(0, 81, .64), (.75, 84, .42), (1.5, 88, .64), (2.5, 84, .46), (3.25, 81, .38)],
            [(0, 80, .54), (.75, 75, .40), (1.5, 71, .52), (2.25, 68, .46), (3, 69, .78)],
        ],
        "arp": "bell", "arp_pattern": [0, 2, 1, 2, 0, 2, 1, 2], "arp_gain": .047,
        "drums": "final", "pad_gain": .085, "bass_pattern": [0, 1.5, 2, 3],
    },
}


def render(name, song, phase="battle"):
    beat_seconds = 60 / song["bpm"]
    # Keep a whole phrase-form soundtrack under a typical 60-second round.
    # Eight-bar section rounding preserves a clean loop at every tempo.
    bars = max(32, int(np.ceil((60.0 / (beat_seconds * 4)) / 8) * 8))
    mix = np.zeros(round(bars * 4 * beat_seconds * RATE), dtype=np.float64)
    drums = {kind: drum(kind, duration) for kind, duration in [("kick", .24), ("snare", .19), ("hat", .085), ("tick", .06)]}
    # Phase versions retain every stage's tempo, harmony, and melodic identity.
    # Identical sample lengths allow the game to crossfade at the same bar offset.
    # Each arrangement follows A / B / A-return / C across a full minute,
    # instead of cycling a short four-bar backing under the whole match.
    lead_scale = .76 if phase == "intro" else 1.08 if phase == "climax" else 1.0
    bass_scale = .72 if phase == "intro" else 1.12 if phase == "climax" else 1.0
    arp_scale = .52 if phase == "intro" else 1.12 if phase == "climax" else 1.0
    pad_scale = .85 if phase == "intro" else 1.04 if phase == "climax" else 1.0
    drum_scale = .68 if phase == "intro" else 1.06 if phase == "climax" else 1.0
    for bar in range(bars):
        base = bar * 4
        form_section = (bar // 8) % 4
        in_b_section = form_section in (1, 3)
        section_index = bar % 4
        chord = (song["chords_b"] if in_b_section else song["chords"])[section_index]
        root = (song["roots_b"] if in_b_section else song["roots"])[section_index]
        melody = (song["melody_b"] if in_b_section else song["melody"])[section_index]
        if form_section == 3:
            # Turn the B-theme back on itself for a distinct closing passage.
            melody = [
                (3.5 - offset, note + (2 if event_index % 2 else -2), duration * .90)
                for event_index, (offset, note, duration) in enumerate(reversed(melody))
            ]
        # Quiet sustained harmony leaves room for action sounds and the melody.
        for note in chord:
            place(mix, beat_seconds, base, oscillator(note, 3.95 * beat_seconds, "pad"), song["pad_gain"] * pad_scale / 3)
        arp_pattern = song["arp_pattern"] if not in_b_section else list(reversed(song["arp_pattern"]))
        if phase == "climax" and not in_b_section:
            arp_pattern = arp_pattern[2:] + arp_pattern[:2]
        for step, note_index in enumerate(arp_pattern):
            if phase == "intro" and step % 2:
                continue
            place(mix, beat_seconds, base + step * .5, oscillator(chord[note_index] + 12, .37 * beat_seconds, song["arp"]), song["arp_gain"] * arp_scale)
        for i, offset in enumerate(song["bass_pattern"]):
            if phase == "intro" and i not in (0, len(song["bass_pattern"]) - 1):
                continue
            note = root + (12 if i == len(song["bass_pattern"]) - 1 and bar % 2 else 0)
            place(mix, beat_seconds, base + offset, oscillator(note, (.58 if name != "dark_lord" else .76) * beat_seconds, "bass"), song["bass_gain"] * bass_scale)
        if phase == "climax" and bar % 2 == 1:
            place(mix, beat_seconds, base + 3.5, oscillator(root + 7, .34 * beat_seconds, "bass"), song["bass_gain"] * .58)
        for offset, note, duration in melody:
            # A' and the return vary the opening note without losing the motif.
            if phase != "intro" and offset == 0 and bar % 8 in (5, 7):
                note += 12
            place(mix, beat_seconds, base + offset, oscillator(note, duration * beat_seconds, song["lead"]), song["lead_gain"] * lead_scale)
            if phase == "climax" and (in_b_section or bar >= 12) and offset in (0, 2, 2.5):
                place(mix, beat_seconds, base + offset, oscillator(note - 12, duration * beat_seconds, "brass" if name == "dark_lord" else "toy"), song["lead_gain"] * .26)
        if phase == "climax" and bar >= 4:
            # A short counter-line gives the climax its own arrangement rather
            # than making the battle mix merely louder.
            answer = chord[(bar + 1) % 3] + 12
            answer_offset = 2.5 if bar % 2 == 0 else 3.25
            place(mix, beat_seconds, base + answer_offset, oscillator(answer, .42 * beat_seconds, song["arp"]), song["arp_gain"] * (1.12 if in_b_section else .9))
            counter_instrument = "brass" if name in ("quarry", "dark_lord") else song["arp"]
            for pulse, offset in enumerate((.75, 1.75, 2.75, 3.5)):
                counter_note = chord[(pulse + bar) % 3] + (12 if pulse % 2 == 0 else 24)
                place(mix, beat_seconds, base + offset, oscillator(counter_note, .22 * beat_seconds, counter_instrument), song["arp_gain"] * .36)
            if bar % 8 == 7:
                for note in chord:
                    place(mix, beat_seconds, base + 3.5, oscillator(note + 12, .34 * beat_seconds, "brass"), song["pad_gain"] * .34)
        style = song["drums"]
        kicks = [0, 2] if style == "soft" else [0, 1.5, 2, 3.5] if style in ("drive", "chase") else [0, 2, 2.75] if style == "sync" else [0, 1.5, 2, 3]
        if phase == "intro" and bar < 2:
            kicks = [0, 2]
        elif phase == "climax" and in_b_section:
            kicks = sorted(set(kicks + [1, 3]))
        for offset in kicks:
            place(mix, beat_seconds, base + offset, drums["kick"], (.27 if style == "soft" else .31) * drum_scale)
        snares = [2] if style == "soft" else [1, 3]
        for offset in snares:
            place(mix, beat_seconds, base + offset, drums["snare"], (.13 if style == "soft" else .16) * drum_scale)
        hat_step = 1 if style == "soft" else .5 if style != "chase" else .25
        if phase == "intro" and bar < 2:
            hat_step = max(1, hat_step)
        for offset in np.arange(0, 4, hat_step):
            place(mix, beat_seconds, base + offset, drums["hat"], (.025 if style == "soft" else .032 if style != "chase" else .024) * (.4 if phase == "intro" else 1.15 if phase == "climax" else 1.0))
        if style in ("sync", "chase"):
            for offset in (1.75, 3.75):
                place(mix, beat_seconds, base + offset, drums["tick"], .03 * drum_scale)
        if phase == "climax" and bar % 8 == 7:
            for offset in (3.0, 3.25, 3.5, 3.75):
                place(mix, beat_seconds, base + offset, drums["tick"], .021)

    # A 35 ms tail fade prevents a click without obscuring the next downbeat.
    fade = round(.035 * RATE)
    mix[-fade:] *= np.linspace(1, 0, fade)
    mix[:round(.004 * RATE)] *= np.linspace(0, 1, round(.004 * RATE))
    # Keep distinct phase loudness even on already-dense boss themes, while
    # leaving room for attack and warning sounds above the score.
    if phase == "battle":
        mix *= .96
    elif phase == "climax":
        mix *= 1.04
    peak = np.max(np.abs(mix))
    mix = np.tanh(mix * min(1.0, .83 / max(peak, .001)))
    pcm = np.round(np.clip(mix, -1, 1) * 32767).astype("<i2")
    filename = name if phase == "battle" else f"{name}_{phase}"
    target = OUT / f"{filename}.wav"
    with wave.open(str(target), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())
    print(f"{target.name}: {len(mix) / RATE:.2f}s, peak {np.max(np.abs(mix)):.3f}, rms {np.sqrt(np.mean(mix ** 2)):.3f}")


if __name__ == "__main__":
    for title, score in SONGS.items():
        render(title, score)
    for phase in ("intro", "climax"):
        for title, score in SONGS.items():
            render(title, score, phase)
