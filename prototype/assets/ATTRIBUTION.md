# Attribution — Socii audio and type

Every file below is CC0 or CC-BY, except the fonts, which are OFL. **Only one file needs a credit line in the game: `charge.wav` (CC-BY).** The five synthesised cues are original and use no third-party material.

Each file was trimmed, faded, converted to mono 44.1 kHz 16-bit WAV and set to a working level. Any other processing is listed with that file. The source links point to the original page, not to the mirror the file was downloaded from.

## Sound effects — `sfx/`

    move.wav        — "footstep_carpet_000" by Kenney (Impact Sounds pack) — CC0 — https://kenney.nl/assets/impact-sounds
    variants/move_2.wav — "footstep_carpet_001" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    variants/move_3.wav — "footstep_carpet_003" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    variants/move_4_grittier.wav — "footstep_concrete_001" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    select.wav      — "impact_wood_light_000" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
                      tail cut to 120 ms
    deselect.wav    — "impact_wood_light_003" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
                      pitched down ~2 semitones, 5 dB quieter than select
    move_water.wav  — "water step.wav" by nathanaelj83 — CC0 — https://freesound.org/s/145242/
                      low-passed at 2.2 kHz to make it darker; cut to 400 ms
    move_rough.wav  — "footstep_grass_001" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    deny.wav        — "impact_soft_medium_000" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    kill.wav        — "impact_wood_heavy_003" by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    kill_them.wav   — layer of "impact_punch_heavy_002" + "impact_plate_heavy_001" (−12 dB, low-passed)
                      by Kenney (Impact Sounds) — CC0 — https://kenney.nl/assets/impact-sounds
    bolt.wav        — "Crossbow Shot" by LeMudCrab — CC0 — https://freesound.org/s/163453/
    charge.wav      — "Horse_Gallop_And_Stop_In_Dirt 01.WAV" by n_audioman — CC-BY 4.0 — https://freesound.org/s/321951/
                      460 ms excerpt (0.63 s in, three hoof falls). CREDIT REQUIRED:
                      "Horse gallop" by n_audioman (freesound.org), CC BY 4.0
    arrive.wav      — "War horn" by adharca — CC0 — https://freesound.org/s/539956/
                      first 0.95 s (low note stepping up), faded. Original is 4.4 s.
    anchor.wav      — "handle_small_leather" by Kenney (RPG Audio pack) — CC0 — https://kenney.nl/assets/rpg-audio
                      set very quiet (−16 dBFS peak)
    objective.wav   — "small bell" by steffcaffrey — CC0 — https://freesound.org/s/452371/
                      single strike from 0.10 s, 500 ms with fade. Original is 2.1 s.
    recruit.wav     — "handle_coins_2" by Kenney (RPG Audio) — CC0 — https://kenney.nl/assets/rpg-audio
    ui.wav          — "book_open" by Kenney (RPG Audio) — CC0 — https://kenney.nl/assets/rpg-audio

### Original — synthesised for Socii (no licence needed, no one else holds rights)

    victory.wav, victory_clean.wav, defeat.wav, arrive_them.wav, turn.wav,
    variants/arrive_synth.wav
                    — made from scratch by tools/make_music_sfx.py (additive synthesis,
                      quarter-comma meantone). No samples, soundfonts or recordings used.

Where the files came from: Kenney's packs came from GitHub mirrors (Boyquotes/kenney-impact-sounds-for-godot and Boyquotes/kenney-rpg-audio-for-godot). The Freesound files came from GitHub game repos that kept Freesound's original `ID__user__name` filenames. I checked each ID's licence on its Freesound page. For a final release, re-download each one from the Freesound link above to be sure you have the original file.

## Typeface — `font/`

    Cardo (Regular, Italic, Bold) — David J. Perry — SIL OFL 1.1 — https://fonts.google.com/specimen/Cardo
                      WOFF2 files cut down to Latin + Latin Extended (the OFL allows this; Cardo has no Reserved Font Name). Full TTFs in font/ttf/.
    alternates/eb-garamond/EBGaramond[wght].ttf — Georg Duffner & Octavio Pardo — SIL OFL 1.1 — https://fonts.google.com/specimen/EB+Garamond
    alternates/rotunda-pommerania/Rotunda_Pommerania.ttf — Peter Wiegel — SIL OFL 1.1 (Reserved Font Name "Rotunda Pommerania") — http://www.peter-wiegel.de
