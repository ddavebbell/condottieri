# Five against eight

The company is **five men**: two footmen, the Cavaliere, the Lanciere and the
Condottiero. Their forces are **eight**, on every map.

Thirteen maps, all solvable, all winnable without losing anybody.
`node tools/grade.js 0 12 8` reproduces the table in about 80 seconds.

**bands:** 4 easy · 6 medium · 3 hard · 0 brutal
**W\* spread:** seven maps at 3, two at 6, four at 12

## Why the ratio is the lever

Three earlier experiments all failed to make the game deeper, and it is worth
recording what did not work:

| Change | Effect on W\* |
|---|---|
| Two commands instead of three | unchanged on 11 of 13 maps |
| Anchors must brace to shelter | **identical numbers to the baseline** |
| Sliders capped at three tiles | unchanged, and broke one map |

Each of those made maps longer or riskier without ever making the obvious move
wrong. The instrumentation said why: your men were anchored almost every turn
and *in danger* on one turn in six. The discipline was insuring against a
danger that did not exist, which is why charging rent for it changed nothing.

Outnumbering you is the thing that worked. At five against ten, W\* went to 24
and 48 — real planning, not time pressure — but four maps turned brutal. Five
against eight keeps the depth and loses the grind: **four maps now need a beam
of 12, where before every map fell to a beam of 3.**

## The play order

| # | Map | Objective | d | Band | W* | Turns | Limit | Slack | Loss % |
|---|---|---|---|---|---|---|---|---|---|
| 1 | The Villa Gate | muster | 2.07 | easy | 3 | 13 | 20 | 7 | 10 |
| 2 | Skirmish on the Road | clear | 2.23 | easy | 3 | 6 | 16 | 10 | 13 |
| 3 | The Bridge | hold | 2.25 | easy | 3 | 3 | 21 | 18 | 13 |
| 4 | Horse Country | clear | 2.84 | easy | 3 | 13 | 19 | 6 | 25 |
| 5 | The Treeline | clear | 3.38 | medium | 3 | 11 | 19 | 8 | 36 |
| 6 | The Gauntlet | muster | 3.59 | medium | 6 | 3 | 21 | 18 | 20 |
| 7 | The Long Hold | hold | 3.62 | medium | 3 | 4 | 21 | 17 | 41 |
| 8 | The Ford | muster | 4.04 | medium | 3 | 8 | 18 | 10 | 49 |
| 9 | Hold the Crossroads | hold | 4.38 | medium | 12 | 10 | 21 | 11 | 16 |
| 10 | The Watchtower | clear | 4.50 | medium | 6 | 13 | 19 | 6 | 38 |
| 11 | Two Knots | clear | 5.08 | hard | 12 | 8 | 17 | 9 | 30 |
| 12 | Ambush in the Countryside | clear | 5.23 | hard | 12 | 8 | 19 | 11 | 33 |
| 13 | The Courtyard | muster | 5.24 | hard | 12 | 13 | 19 | 6 | 33 |

## What changed in the company

Dropping from seven men to five cost the **Balestriere** his place. The audit
had already shown him firing zero to two bolts a game, so he was the obvious
one to leave behind — but that is a decision worth revisiting, because he is
the only answer to a formation that cannot be approached. He may want to come
back as a hired specialist rather than a standing member of the company.

The two anchors both stayed. With five men and two anchors the discipline is
now a real budget: you cannot shelter everybody, and choosing who is covered
while you advance is most of the game.

## Still open

- W\* is 3 on seven maps. There is room to push further, and the ratio is the
  dial that works.
- Step 5 of the solver plan — checking that a winning line actually uses the
  mechanic each map claims to teach — is still unbuilt.
