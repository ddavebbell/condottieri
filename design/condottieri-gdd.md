# CONDOTTIERI
### Game Design Document — v2.0
*Restructured into MVP and V2. Everything in MVP is required to know whether the game works. Everything in V2 is deliberately deferred.*

---

## 1. The pitch

A single-player tactics game played with chess pieces, where the map is the content.

Players already know how a knight moves. Condottieri uses that free knowledge as the on-ramp, then spends all its design energy on terrain and mission design: rivers only infantry can wade, forests that stop you dead and hide you from crossbows, rock walls only cavalry can leap. Every mission is a hand-built puzzle with its own win condition.

Setting: the Italian Renaissance. You are a condottiero — a mercenary captain taking contracts across the countryside, ending with an estate of your own.

**One line:** *Chess intuition. Tactics-game maps. Played on a phone, alone.*

---

## 2. Design pillars

**Single-player first.** This is a puzzle game you play on a bus. It is not a competitive duel and does not wait on another human. Local two-player exists only as a testing tool.

**Perfect information.** No dice, no hidden rolls, no percentages, no fog of war. Everything on the board is visible and every outcome is knowable before you commit. A puzzle you can't see is not a puzzle. *(One narrow amendment arrives in V2 — see §12.)*

**Terrain restricts; it doesn't reward.** Terrain changes what a piece is allowed to do. It never grants points, resources or buffs.

**No power levels, no arithmetic.** A capture is instant and total. There are no hitpoints, no damage numbers, no strength comparisons. If resolving a move requires mental maths, the rule is wrong.

**Rules are positional, not historical.** Every rule resolves from where pieces are right now. Nothing depends on how a piece got somewhere.

**Nothing passes through a body.** Sliders stop at pieces, the Cavaliere is hobbled by an enemy in its way, crossbow bolts are stopped by anyone standing in the line. One principle, applied to every piece, is what makes formations matter.

**One new idea per engagement.** Each mission introduces exactly one new terrain rule or objective type, and is built to teach it.

---

## 3. Genre position

Not a chess variant. Nearest neighbours: *Into the Breach* (small board, perfect information, deterministic puzzle missions) and *Advance Wars* (campaign structure).

Dropped from chess: castling, en passant, stalemate, draws, promotion, piece facing, and any goal of tournament-grade balance. Asymmetry between the two sides is normal and expected — the enemy is part of the puzzle, not an equal opponent.

---

## 4. Scope

| | MVP | V2 |
|---|---|---|
| **Structure** | One contract, three engagements | Full campaign of contracts |
| **Company** | Fixed per engagement | Persists across a contract; roster with names |
| **Economy** | None | Florins, replacement costs, the estate |
| **Pieces** | All seven | Unchanged |
| **Terrain** | Field, forest, river, ford, bridge, rocks, void | Elevation, ramps, sanctuary, gates |
| **Enemy** | Four fixed behaviours | Captains, orders collapsing |
| **Objectives** | Clear, Hold, Muster | Escort, Survive, Infiltrate |
| **Hidden info** | None | Concealment in forest |
| **Events** | Spawn on turn, spawn on entry, dialogue | Traps, tile wear, region triggers |
| **Art** | Placeholder | Full pass |

The MVP exists to answer one question: **is solving these maps fun?** Nothing that doesn't help answer it is in scope.

---

# MVP

## 5. The board

- Square grid inside a bounding box, roughly 10×10 to 14×14.
- **Void tiles** are outside the board and don't render, so maps are any shape: a mountain pass, a bridge, a courtyard, a street plan.
- Every tile has one terrain type and optionally one event.
- Whole board visible at once on a phone. No scrolling.
- There is no forward direction. Nothing in the game has a facing.

## 6. Pieces

| Piece | Moves | Kills | Class |
|---|---|---|---|
| **Fante** | One tile, any direction, backwards included | Diagonal only — never straight ahead | Foot |
| **Cavaliere** | One orthogonal step, then one diagonal step outward | By landing on it | Mounted |
| **Lanciere** | Slides on the diagonals | By landing on it | Foot |
| **Carro** | Slides on ranks and files | By landing on it | Wheeled |
| **Balestriere** | One tile, any direction | **Shoots** at range 2. Never kills by moving. | Foot |
| **Condottiero** | Slides any direction | By landing on it | Foot |
| **Signore** | One tile, any direction | Any direction | Foot |

**The Cavaliere's leg.** It steps one tile orthogonally, then one diagonally outward. That first tile is what stops it: an **enemy** piece blocks it, **water** blocks it, **rocks do not** — that's the leap. Friendly pieces never block it. This is the Xiangqi horse, which is the correct place to borrow from given the game's source material.

**The Balestriere's line.** Range 2, all eight directions, straight lines. Stopped by rocks, forest, the board edge, and any body in the way including its own side's. Water doesn't block, so archers cover crossings. An archer surrounded by trees is nearly blind.

**No upgrades, no promotion.** Pieces do not improve. Missions are the content.

## 7. Movement classes

Terrain reads differently depending on who walks on it. Three classes, four facts:

- **On foot** — Fante, Lanciere, Balestriere, Condottiero, Signore. Wades rivers, and stops in them.
- **Mounted** — Cavaliere. Leaps rock walls. Cannot touch water at all.
- **Wheeled** — Carro. Cannot enter forest at all.

Infantry ford the river anywhere; cavalry queues at the bridge. That inversion is the backbone of most map design.

## 8. Terrain

| Tile | Foot | Mounted | Wheeled | Blocks shots |
|---|---|---|---|---|
| Field | Open | Open | Open | No |
| Forest | Stops you | Stops you | Cannot enter | **Yes** |
| River | Stops you | Cannot enter | Cannot enter | No |
| Ford | Stops you | Stops you | Stops you | No |
| Bridge | Open | Open | Open | No |
| Rocks | Cannot enter | Leaps over | Cannot enter | **Yes** |
| Void | Off the board | Off the board | Off the board | Yes |

**"Stops you"** — a sliding piece entering the tile ends its move there, even with distance remaining.

Forest is the model rule: it's cover *and* a trap. Safe from bolts, but you lose your momentum getting in. Bridges cross at full speed and are therefore contested; fords cross slowly and are therefore safe. Every terrain type should read that way — a cost paired with a benefit.

## 9. Commands

**Three commands per side per turn.** One command moves one piece, or fires one Balestriere. No piece acts twice in a turn. The turn can be ended early.

The number is declared per engagement, so it's a design lever: a wide front might get five, a delicate approach one.

## 10. The enemy

The enemy is part of the map, not an opponent. It does not need to play well — it needs to be **predictable enough to solve**. There is no search algorithm.

Every enemy piece is tagged in the map file with one behaviour:

- **Guard** — never leaves its tile; acts only when something enters its reach
- **Patrol** — walks a fixed route, drawn on the board
- **Charge** — moves toward the nearest player piece every turn
- **Hold-until** — sits still until a trigger fires, then charges

The enemy gets command points like the player, declared per engagement, which controls the pace of pressure.

## 11. Objectives

Three in the MVP. None of them is checkmate.

- **Clear** — remove every enemy piece from a declared region.
- **Hold** — occupy a declared region for N consecutive turns; the count resets if it's lost.
- **Muster** — get N pieces into a declared region **simultaneously**. Distinct from Hold, and it bites against command points: assembling four pieces at three commands a turn takes real planning.

Failure: the Condottiero is lost, or the turn limit expires.

**Resolution order** after every action: capture → events → victory check → failure check. **Victory wins ties.**

## 12. The contract

The MVP is one contract of three engagements, with a fixed company on each. It teaches the game in order:

| # | Engagement | Teaches | Objective |
|---|---|---|---|
| 1 | Ambush in the Countryside | Forest, screening, the Cavaliere's leg | Clear |
| 2 | The Bridge | Water, fords, crossbows covering a crossing | Hold, 2 turns |
| 3 | The Villa Gate | Rock chokepoints, command-point pressure | Muster, 4 pieces |

Free retry on any engagement.

---

# V2

## 13. Campaign, company and contracts

**Vocabulary.** An **engagement** is one map. A **contract** is a set of about three engagements. Your **company** is your surviving roster. The campaign is a run of contracts.

**The company persists and never resets.** Pieces lost stay lost. This is the spine of the meta-game.

**The force floor.** Every engagement declares a minimum company — say four pieces including the Condottiero. If you arrive with fewer, you're topped up **free of charge**: your employer supplies bodies because he needs the job done. You can never be too poor to take the field, only too poor to take it well. This is what makes a permanent company survivable rather than a slow strangle.

**Deployment zones.** Because the game can't know in advance what you'll bring, player pieces aren't placed by the map. Each map declares a deployment region and a placement order, and the company fills it. Enemy pieces stay hardcoded — they're the puzzle.

**Named roster.** Pieces that survive a full contract earn names drawn from real condottieri, and a roll call at settlement. With free retry available, roster attachment has to be earned through character rather than enforced through punishment.

## 14. Money

Two jobs, because an economy with one sink becomes a hoarding puzzle.

**Composition.** Pieces above the free floor are bought. Rough costs: Fante 1, Lanciere 3, Balestriere 3, Cavaliere 4, Carro 4. The Condottiero is not for sale — he's you, and losing him fails the contract. So each contract starts with a loadout decision against a known map: river country and archer country want different companies.

**The estate.** The campaign's ending is buying a nobleman's estate. It has a price. Every florin not spent on replacements is progress toward the actual goal, so hoarding stops being degenerate — it *is* the win condition.

Contract fees are stated in the briefing before you accept, with a bonus for an optional secondary objective.

## 15. The Captain

Enemy forces get a Captain. While he lives, enemy pieces run their assigned behaviour. When he falls, **the force loses its orders** — every enemy piece drops to Guard. They stop advancing, stop patrolling, stop charging.

Binary, visible, no arithmetic. It makes killing the enemy leader an *optional shortcut* that degrades the opposition, rather than a win condition.

**Paired idea:** the player's command points could work the same way — three while your Condottiero lives, one if he's lost. One number recalculated each turn, and it gives the Condottiero a reason to exist beyond being a strong slider.

## 16. Additional terrain

- **Elevated** — a second level of ground. A piece changes level only by moving off a **ramp** tile. Archers on high ground shoot *over* blockers, which makes a hill the most valuable tile on any map with crossbows.
- **Sanctuary** — a piece standing here can only be captured by a piece also standing inside the sanctuary. **Gates** are simply the only open tiles in a wall; they carry no capture rule of their own and can be destroyed by event.

## 17. Concealment

The one amendment to perfect information, and it is deliberately narrow.

**A piece standing on a forest tile is hidden until an enemy is adjacent to it.** You always see the whole board and all the terrain. You just don't see who's lying in the treeline.

This is not fog of war. Fog breaks puzzles — the first attempt becomes a blind death and the "solution" is remembering what killed you. Concealment keeps the board legible while making forests genuinely dangerous: you can see the hiding place, you just can't see into it.

## 18. Additional objectives

**Escort** (get a named piece to a tile alive), **Survive** (last N turns), **Infiltrate** (reach a tile without ending a turn within one tile of a patrol, diagonals included, with all routes drawn on the board).

## 19. Events

MVP ships three: dialogue on start, spawn on turn N, spawn on entering a tile. V2 adds traps, tile wear (the rickety bridge), named-piece-captured, and region-cleared.

A fixed list, hardcoded. No authoring UI and no scripting language — that design is what stalled the project the first time.

---

## 20. Data

The **map file format is the most durable asset in this project.** Rules logic ports between engines in an afternoon; UI never ports.

The MVP schema must already include the fields V2 needs, even where nothing reads them yet — retrofitting deployment zones after three missions exist means rebuilding all three.

A map file holds: board size · terrain grid · void tiles · command points for each side · enemy pieces with positions and behaviours · **deployment zone and force floor** · objective and its parameters · failure conditions · event list · mission text. V2 adds: level grid and ramps · gates and destructible tiles · patrol routes · contract fee.

## 21. Art direction

*Proposal, to react to:* flat 2D, top-down, orthogonal. Renaissance woodcut and fresco language — cross-hatching, aged paper, muted earth palette with two saturated faction colours. Pieces read as carved wooden figures on a painted board. The board looks like a map table in a war tent.

Small art budget, no animation dependency, scales to phone screens.

## 22. Open decisions

1. Board size ceiling for phone screens — feeds the ship-target test.
2. Is the Balestriere's range-2-in-eight-directions too much reach? Fallbacks: diagonals only, or straight lines only.
3. Do three commands make the game fast, or just make trades happen before anyone develops? Two may be right.
4. Do neutral pieces exist — civilians, livestock, a caravan?

*Settled and off this list: fog of war (none, see §17), Fante promotion (no promotion, no facing), Condottiero active ability (replaced by the command-point pairing in §15), hitpoints (none, ever).*

## 23. Build order

**MVP**
1. Rules prototype — hot seat, placeholder art. *Done.*
2. Map file loading, with the full V2-aware schema.
3. Enemy behaviours.
4. The three objectives.
5. Three engagements, fixed companies.
6. **Ship-target test** — run it on a phone and decide: web wrapper or engine port. Made here, while the codebase is small enough to move.

**V2**
7. Company persistence, deployment zones, force floor.
8. Economy and the estate.
9. Captains, elevation, sanctuary, concealment.
10. Remaining objectives and events.
11. Art pass.
12. Map editor, if wanted.
