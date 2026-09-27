"""
Socii — generator for the five cues no library had.

Everything here is made from scratch by this script: no samples, no soundfonts,
no third-party audio. You own the output outright.

    python make_music_sfx.py            # writes into ../sfx/

Needs: numpy, scipy  (pip install numpy scipy)

Instruments (all additive synthesis):
    sackbut   — Renaissance trombone: harmonic series that brightens as it swells
    cornetto  — wooden cornett: few harmonics, breathy, a little vocal
    viol      — viola da gamba: sawtooth-like string through a wooden-body filter
    horn      — natural (valveless) horn, played only on its natural notes
    drum      — frame drum / tabor: circular-membrane modes plus a skin slap

Tuning is quarter-comma meantone, the usual keyboard tuning of 16th-c. Italy:
pure major thirds, slightly narrow fifths. It is why the chords sound "sweet".

To change a cue, edit the SCORE section near the bottom. Each note is
(voice, note, start_seconds, length_seconds, loudness 0-1).
"""
import os
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve, iirpeak, lfilter

SR = 44100
rng = np.random.default_rng(1441)          # fixed seed: same output every run

# ---------------------------------------------------------------- tuning
FIFTH = 5 ** 0.25                            # quarter-comma meantone fifth
D4 = 293.66 * 1.0                           # reference pitch (A4 ~ 440)
# position on the circle of fifths, counted from D
CIRCLE = {'Bb': -4, 'F': -3, 'C': -2, 'G': -1, 'D': 0, 'A': 1, 'E': 2,
          'B': 3, 'F#': 4, 'C#': 5, 'G#': 6}
LETTER_ORDER = ['C', 'D', 'E', 'F', 'G', 'A', 'B']


def hz(name):
    """'F#4' -> frequency in meantone, with D4 = 293.66 Hz."""
    pitch, octave = name[:-1], int(name[-1])
    r = FIFTH ** CIRCLE[pitch]
    while r >= 2: r /= 2
    while r < 1: r *= 2
    # r is now the ratio above the D at or below the note; work out which D
    below_d = LETTER_ORDER.index(pitch[0]) < LETTER_ORDER.index('D')
    base_oct = octave - 1 if below_d else octave
    return D4 * r * 2 ** (base_oct - 4)


# ---------------------------------------------------------------- helpers
def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def adsr(dur, att, rel, sustain_decay=0.0):
    t = t_axis(dur)
    env = 1 - np.exp(-t / max(att, 1e-4) * 3)
    env *= np.exp(-t * sustain_decay)
    r = int(rel * SR)
    if r and r < len(env):
        env[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return env


def phase_of(freq_curve):
    return 2 * np.pi * np.cumsum(freq_curve) / SR


def drift(n, cents=4, rate=3.0):
    """slow random pitch wander so held notes are not machine-still"""
    k = max(int(n / SR * rate) + 2, 2)
    pts = rng.normal(0, 1, k)
    curve = np.interp(np.linspace(0, k - 1, n), np.arange(k), pts)
    return 2 ** (curve * cents / 1200)


def lp(x, f):  return sosfilt(butter(2, f, 'low', fs=SR, output='sos'), x)
def hp(x, f):  return sosfilt(butter(2, f, 'high', fs=SR, output='sos'), x)
def bp(x, lo, hi): return sosfilt(butter(2, [lo, hi], 'band', fs=SR, output='sos'), x)


def peak(x, f, q, gain):
    b, a = iirpeak(f, q, fs=SR)
    return x + gain * lfilter(b, a, x)


# ---------------------------------------------------------------- instruments
def sackbut(f, dur, amp=1.0):
    n = int(dur * SR); t = t_axis(dur)
    env = adsr(dur, att=0.06, rel=min(0.25, dur * 0.4), sustain_decay=0.25)
    scoop = 1 - 0.018 * np.exp(-t / 0.035)             # lip settles onto the note
    ph = phase_of(f * scoop * drift(n, 3))
    bright = 1.2 + 5.5 * env                           # louder = brighter, like real brass
    out = np.zeros(n)
    for k in range(1, 28):
        if k * f > 9000: break
        out += np.exp(-(k - 1) / bright) * np.sin(k * ph) / k ** 0.3
    breath = bp(rng.normal(0, 1, n), 800, 3000) * 0.015 * np.exp(-t / 0.05)
    out = out * env + breath
    return amp * lp(out, 5000)


def cornetto(f, dur, amp=1.0):
    n = int(dur * SR); t = t_axis(dur)
    env = adsr(dur, att=0.05, rel=min(0.3, dur * 0.45), sustain_decay=0.15)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.25) / 0.3, 0, 1)
    ph = phase_of(f * vib * drift(n, 3))
    out = np.zeros(n)
    for k, a in enumerate([1, .45, .30, .12, .10, .05, .03], start=1):
        out += a * np.sin(k * ph)
    out = peak(out, 1100, 3, 0.6)                      # the slightly vocal "ah"
    breath = bp(rng.normal(0, 1, n), 1500, 6000) * 0.02
    return amp * (out * env + breath * env)


def viol(f, dur, amp=1.0):
    n = int(dur * SR); t = t_axis(dur)
    env = adsr(dur, att=0.11, rel=min(0.5, dur * 0.5), sustain_decay=0.35)
    vib = 1 + 0.003 * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.3) / 0.4, 0, 1)
    ph = phase_of(f * vib * drift(n, 4))
    out = np.zeros(n)
    for k in range(1, 40):
        if k * f > 10000: break
        out += np.sin(k * ph) / k ** 1.15
    for fc, q, g in [(280, 2, 1.2), (520, 3, 0.8), (1150, 4, 0.5), (2600, 3, 0.4)]:
        out = peak(out, fc, q, g)                      # wooden body resonances
    bow = hp(rng.normal(0, 1, n), 2500) * 0.02
    return amp * lp(out * env + bow * env, 7000)


def horn(f, dur, amp=1.0, fall_cents=0):
    n = int(dur * SR); t = t_axis(dur)
    env = adsr(dur, att=0.05, rel=min(0.25, dur * 0.4), sustain_decay=0.4)
    fall = 2 ** (-fall_cents * np.clip((t - dur * 0.55) / (dur * 0.45), 0, 1) ** 2 / 1200)
    ph = phase_of(f * (1 - 0.025 * np.exp(-t / 0.03)) * fall * drift(n, 5))
    bright = 1.0 + 3.0 * env                           # darker than the sackbut
    out = np.zeros(n)
    for k in range(1, 20):
        if k * f > 7000: break
        out += np.exp(-(k - 1) / bright) * np.sin(k * ph)
    out = peak(out, 700, 2, 0.8)                       # horn/bone "honk"
    breath = bp(rng.normal(0, 1, n), 500, 2500) * 0.03 * np.exp(-t / 0.06)
    return amp * lp(out * env + breath, 4000)


def drum(dur=0.21, f0=118, amp=1.0):
    n = int(dur * SR); t = t_axis(dur)
    bend = 1 + 0.06 * np.exp(-t / 0.025)               # skin pitch drops after the hit
    out = np.zeros(n)
    for ratio, a, decay in [(1, 1, .09), (1.59, .5, .06), (2.14, .35, .045),
                            (2.30, .25, .04), (2.65, .18, .03), (2.92, .12, .025)]:
        out += a * np.sin(phase_of(f0 * ratio * bend)) * np.exp(-t / decay)
    slap = bp(rng.normal(0, 1, n), 700, 3500) * np.exp(-t / 0.008) * 0.5
    out = (out + slap) * adsr(dur, 0.001, 0.03)
    return amp * out


# ---------------------------------------------------------------- room
def room(x, rt=1.1, wet=0.18):
    """small stone hall: decaying noise impulse, a few early reflections"""
    n = int(rt * SR); t = np.arange(n) / SR
    ir = rng.normal(0, 1, n) * np.exp(-6.9 * t / rt)
    ir = lp(ir, 4500)
    ir[:int(0.012 * SR)] = 0
    for d, g in [(0.017, .5), (0.029, .35), (0.041, .25)]:
        ir[int(d * SR)] += g * np.abs(ir).max() * 4
    ir /= np.sqrt(np.sum(ir ** 2))
    y = fftconvolve(x, ir)[:len(x)]
    return (1 - wet) * x + wet * y * 3


# ---------------------------------------------------------------- render
VOICES = {'sackbut': sackbut, 'cornetto': cornetto, 'viol': viol, 'horn': horn}


def render(score, length, peak_db=-3.0, wet=0.18, fade=0.25):
    buf = np.zeros(int(length * SR) + SR)
    for item in score:
        voice, note, start, dur, amp = item[:5]
        kw = item[5] if len(item) > 5 else {}
        if voice == 'drum':
            s = drum(amp=amp, **kw)
        else:
            s = VOICES[voice](hz(note), dur, amp, **kw)
        i = int(start * SR)
        buf[i:i + len(s)] += s
    buf = room(buf, wet=wet)[:int(length * SR)]
    f = int(fade * SR)
    buf[-f:] *= np.cos(np.linspace(0, np.pi / 2, f)) ** 2
    buf = hp(buf, 70)                                  # phones can't play below this anyway
    buf *= 10 ** (peak_db / 20) / np.abs(buf).max()
    return buf


def save(path, x):
    import wave
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# ================================================================ SCORE
# Everything sits in D, the mode (Dorian) most common in Italian music of the
# time. Pitches are kept at G3 and above because phone speakers lose the bass.

# victory — "they were paid, not crowned". A plagal (IV–I, "amen") cadence
# played by two sackbuts, ending on a bare open fifth with no third: done,
# not celebrated.
VICTORY = [
    ('drum', None, 0.00, 0.21, 0.35),
    ('sackbut', 'D3', 0.00, 0.18, 0.55), ('sackbut', 'A3', 0.00, 0.18, 0.5),
    ('sackbut', 'G3', 0.20, 0.58, 0.75), ('sackbut', 'B3', 0.20, 0.58, 0.6),
    ('sackbut', 'D4', 0.20, 0.58, 0.55),
    ('sackbut', 'D3', 0.80, 1.20, 0.8), ('sackbut', 'A3', 0.80, 1.20, 0.65),
    ('sackbut', 'D4', 0.80, 1.20, 0.55),
]

# victory_clean — same bones, warmer: a cornetto joins on top and sings a 4–3
# suspension (G falls to F#) over the final chord, so the ending blooms into a
# full, sweet major triad. The best sound in the game.
VICTORY_CLEAN = [
    ('drum', None, 0.00, 0.21, 0.35),
    ('sackbut', 'D3', 0.00, 0.20, 0.5), ('sackbut', 'A3', 0.00, 0.20, 0.45),
    ('cornetto', 'A4', 0.00, 0.20, 0.35),
    ('sackbut', 'G3', 0.22, 0.60, 0.7), ('sackbut', 'D4', 0.22, 0.60, 0.5),
    ('cornetto', 'B4', 0.22, 0.60, 0.42),
    ('sackbut', 'D3', 0.84, 1.66, 0.75), ('sackbut', 'A3', 0.84, 1.66, 0.6),
    ('cornetto', 'G4', 0.84, 0.46, 0.45),
    ('cornetto', 'F#4', 1.30, 1.20, 0.45),
    ('viol', 'D4', 1.30, 1.20, 0.25),
]

# defeat — "disappointed, not punishing". A viol drone on D; a second viol
# sighs down A–G–F and settles on the minor third. No drums, no brass.
DEFEAT = [
    ('viol', 'D3', 0.00, 1.80, 0.7),
    ('viol', 'A3', 0.05, 0.45, 0.6),
    ('viol', 'G3', 0.48, 0.42, 0.6),
    ('viol', 'F3', 0.88, 0.92, 0.65),
]

# arrive_them — natural horn falling A4 → D4 with the last note sagging flat,
# the opposite of the player's rising call.
ARRIVE_THEM = [
    ('horn', 'A4', 0.00, 0.16, 0.8),
    ('horn', 'F#4', 0.17, 0.13, 0.7),
    ('horn', 'D4', 0.31, 0.55, 0.85, {'fall_cents': 45}),
]

# arrive (optional alternate) — the same horn rising D4 → A4, so the two calls
# match. The recorded horn stays in sfx/arrive.wav; this goes in variants/.
ARRIVE_SYNTH = [
    ('horn', 'D4', 0.00, 0.16, 0.75),
    ('horn', 'F#4', 0.17, 0.13, 0.7),
    ('horn', 'A4', 0.31, 0.51, 0.85),
]

if __name__ == '__main__':
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'sfx')
    os.makedirs(os.path.join(out, 'variants'), exist_ok=True)
    save(os.path.join(out, 'victory.wav'), render(VICTORY, 2.0, -3, fade=0.35))
    save(os.path.join(out, 'victory_clean.wav'), render(VICTORY_CLEAN, 2.5, -3, fade=0.45))
    save(os.path.join(out, 'defeat.wav'), render(DEFEAT, 1.8, -5, wet=0.22, fade=0.5))
    save(os.path.join(out, 'arrive_them.wav'), render(ARRIVE_THEM, 0.86, -4, wet=0.15, fade=0.12))
    save(os.path.join(out, 'variants', 'arrive_synth.wav'), render(ARRIVE_SYNTH, 0.82, -4, wet=0.15, fade=0.12))
    save(os.path.join(out, 'turn.wav'), render([('drum', None, 0, 0.21, 1.0)], 0.21, -6, wet=0.08, fade=0.03))
    print('done')
