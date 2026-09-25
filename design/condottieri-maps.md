# The thirteen maps

In play order, easiest first. Five men against seven or eight, every map
solvable and **every map winnable without losing anybody**.

`node tools/grade.js 0 12 8` reproduces this in about 70 seconds.

**4 easy · 6 medium · 3 hard · 0 brutal**

| # | Map | Objective | Band | d | W* | Turns | Limit | Slack | Loss % |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Skirmish on the Road | clear | easy | 2.23 | 3 | 6 | 16 | 10 | 13 |
| 2 | The Villa Gate | muster | easy | 2.07 | 3 | 13 | 20 | 7 | 10 |
| 3 | The Bridge | hold | easy | 2.25 | 3 | 3 | 21 | 18 | 13 |
| 4 | Horse Country | clear | easy | 2.84 | 3 | 13 | 19 | 6 | 25 |
| 5 | The Treeline | clear | medium | 3.38 | 3 | 11 | 19 | 8 | 36 |
| 6 | The Gauntlet | muster | medium | 3.59 | 6 | 3 | 21 | 18 | 20 |
| 7 | The Long Hold | hold | medium | 3.62 | 3 | 4 | 21 | 17 | 41 |
| 8 | The Ford | muster | medium | 4.04 | 3 | 8 | 18 | 10 | 49 |
| 9 | Hold the Crossroads | hold | medium | 4.38 | 12 | 10 | 21 | 11 | 16 |
| 10 | The Watchtower | clear | medium | 4.50 | 6 | 13 | 19 | 6 | 38 |
| 11 | Two Knots | clear | hard | 5.08 | 12 | 8 | 17 | 9 | 30 |
| 12 | Ambush in the Countryside | clear | hard | 5.23 | 12 | 8 | 19 | 11 | 33 |
| 13 | The Courtyard | muster | hard | 5.24 | 12 | 13 | 19 | 6 | 33 |

Skirmish on the Road opens the campaign despite grading a hair above The Villa
Gate — it is the map written as a first contract: four of them on open ground,
no crossbow, nothing clever.

## How difficulty is measured

    difficulty = log2(W*) + 0.8 x max(0, 6 - slack) + 5 x lossRate

| | What it measures |
|---|---|
| **W\*** | the narrowest beam that still finds a win. 3 means a player taking the obvious move gets there; 12 means several pieces have to be planned together. |
| **slack** | turn limit minus turns needed — room for error. |
| **lossRate** | share of explored lines ending in defeat. |

**easy** under 3 · **medium** under 5 · **hard** under 7 · **brutal** above

## The two things the solver taught us

**Difficulty is time, not enemy count.** The first draft of these maps graded
easy across the board while carrying eight or ten spare turns, and adding more
men barely moved the number. Cutting the limit moved it immediately.

**Depth is the ratio.** Three attempts to add depth through rules — fewer
commands, anchors that must brace, capped slider reach — all left W\* at 3.
Outnumbering the player was the only change that moved it, because being
outnumbered is what puts your men in danger, and danger is what turns a move
into a decision.

## What each map is for

| # | Map | The thing it asks |
|---|---|---|
| 1 | Skirmish on the Road | men beside an anchor cannot be touched |
| 2 | The Villa Gate | bodies stop bolts |
| 3 | The Bridge | only foot wades |
| 4 | Horse Country | hobbling — a body on the leg stops a charge |
| 5 | The Treeline | rough ground ends a slider's move |
| 6 | The Gauntlet | a column, with nowhere to flank |
| 7 | The Long Hold | a long hold is a rotation, not a stand |
| 8 | The Ford | water costs two turns |
| 9 | Hold the Crossroads | the discipline is what lets you stand still |
| 10 | The Watchtower | bolts go through the discipline; only the horse leaps rock |
| 11 | Two Knots | order of killing — a trigger is a clock you start yourself |
| 12 | Ambush in the Countryside | keep your men touching while you move |
| 13 | The Courtyard | a wall costs no ground; a column pushes a gate |

That last column is still a claim rather than a measurement. Step 5 of the
solver plan — checking that a winning line actually uses the thing a map claims
to teach — is the next tool worth building.
