# Notes — sourcing session, 27 Sep 2026

**All 20 sounds replaced: 15 sourced, 5 composed and synthesised from scratch. Font chosen: Cardo.** Nothing I took needs an account, a payment or a sign-up. Only one sound is CC-BY, and it's marked in ATTRIBUTION.md.

**How I checked sounds without hearing them.** I made a spectrogram (a picture of a sound's frequencies over time) for every candidate. I also measured each one's length and how "noisy" or "tonal" it is. A sound with a musical note shows up as flat horizontal lines on the spectrogram. Each pick has the right length and shape on paper, but **please listen before you commit to any of them**, most of all `move.wav`.

## Status per file

| File | Status | Confidence | Comment |
|---|---|---|---|
| `move.wav` | ✅ replaced | high | Kenney carpet footstep: a single soft, dry scuff with about 70 ms of real sound. No tonal lines at all. Three alternates are in `sfx/variants/`. Rotating between 3–4 takes stops the 12-times-a-turn repetition from sounding mechanical. |
| `select.wav` | ✅ | medium-high | light wood knock, warm (centre around 450 Hz). It has a faint woody pitch, as any *tok* does. |
| `deselect.wav` | ✅ | medium-high | a different take of the same knock, 2 semitones lower and 5 dB quieter |
| `move_water.wav` | ⚠️ provisional | medium | the only CC0 single water step I could get. It was quite bright, so I darkened it with a filter. It's still a bit thin. |
| `move_rough.wav` | ✅ | medium | crackly grass/leaf step. The Kenney snow steps in the same pack are a crunchier option. |
| `deny.wav` | ✅ | high | almost all sub-bass: you feel it more than hear it |
| `kill.wav` | ✅ | high | heavy wood thud, low and dry, no metal |
| `kill_them.wav` | ✅ | medium | a body-fall thud with a quiet, muffled metal plate on top. Lower and heavier than `kill`. |
| `bolt.wav` | ✅ | high | a real crossbow recording, 200 ms: a snap with a short hiss |
| `charge.wav` | ⚠️ provisional | low-medium | three hoof falls cut from a longer gallop. No whinny, but it's quiet and dirt-heavy. **CC-BY, so it needs a credit.** |
| `arrive.wav` | ⚠️ provisional | medium | the opening of a home-made horn (a plastic pipe) that steps up in pitch. It has reverb added, and the reverb can't be removed. |
| `anchor.wav` | ✅ | medium | small leather handling sound, set very quiet |
| `objective.wav` | ✅ | medium | one strike of a small bell, cut to 500 ms. Clean, but high (about 4 kHz), so it may feel bright next to everything else. |
| `recruit.wav` | ✅ | medium | coins handled in the palm. It's warmer than a single coin drop. |
| `ui.wav` | ✅ | medium-high | book opening (a paper flick). Clearly different from the wood `select`. |
| `arrive_them.wav` | 🎼 synthesised | medium | natural horn falling A–F♯–D, the last note sagging flat. A matching rising version is in `variants/arrive_synth.wav` if the recorded `arrive.wav` feels like a different instrument. |
| `turn.wav` | 🎼 synthesised | medium-high | frame drum: modelled drum-skin tones with a pitch drop, plus a short slap. Easy to retune in the script. |
| `victory.wav` | 🎼 synthesised | listen first | two sackbuts play an "amen" (plagal) cadence ending on a bare open fifth: finished, not celebrated. |
| `victory_clean.wav` | 🎼 synthesised | listen first | same bones, warmer: a cornetto joins and sings a suspension (G resolving to F♯), so the ending blooms into a full, sweet major chord. |
| `defeat.wav` | 🎼 synthesised | listen first | viol drone on D; a second viol sighs down A–G–F and settles on the minor third. No brass, no drums. |

## The five synthesised cues

No library had these, so I composed them and built them from scratch with code (`tools/make_music_sfx.py`). **They contain no third-party audio, so there's nothing to licence and nothing to credit.**

- **Instruments:** sackbut (Renaissance trombone), cornetto, viola da gamba, natural horn and frame drum. Each is modelled from its harmonic makeup rather than sampled.
- **Tuning:** quarter-comma meantone, the standard keyboard tuning of 16th-century Italy. Its major thirds are pure, which is why the final chord of `victory_clean` should sound sweet rather than "piano".
- **Mode:** everything is in D Dorian, and every note sits at G3 or above, because phone speakers drop the bass.
- **Honest caveat:** synthesised brass can tip into "MIDI". I checked timing, pitch and length on spectrograms, but I can't hear them. If one sounds cheap, the fastest fixes are in the script: turn down `bright` in `sackbut()` for a mellower tone, or raise `wet` in `render()` for more hall. Or keep the composition and have a player record it. The score is written out in the script's SCORE section.

To regenerate after edits: `pip install numpy scipy`, then `python tools/make_music_sfx.py`.

## Where to upgrade next

1. **The three ⚠️ files** (`move_water`, `charge`, `arrive`). Freesound CC0 searches: `wading single step`, `puddle step`, `horse trot dirt short`, `natural horn call`.
2. **BBC Sound Effects is off-limits.** Its RemArc licence covers personal, educational and research use only.

**Pixabay licence note.** Pixabay isn't CC0. It has its own "Pixabay Content License", which allows commercial use in a game without attribution. It forbids selling or redistributing the sounds on their own. That's fine for Socii, but it's a third licence category, so list it as "Pixabay License" in the attribution file rather than "CC0".

## Typeface

**Chosen: Cardo (Bold for headings, Regular/Italic for other text).** It's the only one of the shortlisted faces modelled directly on Italian printing: Aldus Manutius's type in Venice, 1495. It stays solid and readable at 26 px. EB Garamond is equally good but is the French descendant of the same line. Cormorant looks beautiful large but turns hairline-thin at 26 px. WOFF2 files are in `font/`. A 26 px / 46 px comparison of every candidate is in `font/specimen-comparison.png`.

**About rotunda.** I found a true open-licence rotunda: **Rotunda Pommerania** by Peter Wiegel (OFL). It's in `font/alternates/`. **But it fails the accent test.** In this font the accented letters are used for ligatures, so typing *Niccolò* displays "Niccolſi". The same goes for à, è, ì, ù and all the acute accents. It also turns a plain `s` into a long `ſ`, so "Balestriere" looks like "Baleftriere". The specimen image shows this. To use it for the **title only**:
- set the title as artwork (outlined in Figma), or
- add real grave-accent glyphs in a font editor. The OFL allows that, but the edited font must then be renamed (for example "Socii Rotunda"), because "Rotunda Pommerania" is a Reserved Font Name.

Grenze Gotisch (Google Fonts, OFL) was the other blackletter I checked. It's legible and has accents, but it reads as northern/German, so I left it out.
