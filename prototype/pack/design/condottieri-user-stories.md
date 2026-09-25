# CONDOTTIERI — User Stories
### Backlog derived from GDD v2.0

Split MVP / V2 to match GDD §4. Build order follows GDD §23.

**M0** prototype (done) · **M1** map loading · **M2** enemy · **M3** objectives · **M4** engagements · **V2** deferred

Acceptance criteria are written to be *checkable* — they're what tells you, or an AI writing the code, whether the thing is actually done.

---

# MVP

## Epic A — Board & interaction *(M0 — done)*

**A1 · See the board**
As a player, I want the board drawn from map data so I can see the terrain I'm playing on.
- Grid renders at the size declared in the data
- Each terrain type is visually distinct
- Void tiles don't render and aren't part of the board
- The whole board fits on screen without scrolling

**A2 · See the pieces** — every piece shows its type and side; pieces sit on tile centres and never overlap.

**A3 · Select a piece**
- Only pieces belonging to the side to move can be selected
- A piece that has already acted this turn cannot be selected, and is visibly spent
- Tapping empty ground deselects

**A4 · See legal moves**
- Highlights show every legal destination and nothing else
- Captures are visually distinct from empty destinations
- Ranged shots are visually distinct from both
- Highlights account for terrain and movement class, not just move-set

**A5 · Move a piece** — tapping a highlighted tile moves there and spends one command; tapping a non-highlighted tile does nothing.

**A6 · Capture** — the captured piece is removed permanently. No hitpoints, no damage state.

**A7 · Reject illegal moves** — no input path exists that produces an illegal board state.

**A8 · Undo** *(designer tool)* — restores the exact previous state including commands spent and pieces captured.

**A9 · Restart** — board and command count reset to the engagement's declared starting state.

**A10 · See enemy crossbow range**
As a player, I want to see which tiles enemy Balestrieri cover so I can plan an approach rather than discover it by dying.
- Every tile within a live enemy shot line is marked
- Marking respects sight blockers exactly as the shot rule does

---

## Epic B — Pieces *(M0 — done)*

**B1 · Fante**
- Moves one tile in any of eight directions, onto empty ground only
- Captures on the four diagonals only — never straight ahead
- Has no facing; backwards is a legal move

**B2 · Cavaliere**
- One orthogonal step (the leg), then one diagonal step outward
- An **enemy** piece on the leg blocks the move; a friendly piece does not
- **Water** on the leg blocks the move
- **Rocks** on the leg do *not* block the move
- Cannot land on any tile its movement class can't enter

**B3 · Lanciere** — slides on the diagonals; stops at the first occupied tile, capturing if it's an enemy.

**B4 · Carro** — slides on ranks and files, same blocking rules as B3.

**B5 · Condottiero** — combines B3 and B4.

**B6 · Signore** — one tile in any direction, captures in any direction.

**B7 · Balestriere — moving**
- Moves one tile in any direction
- **Cannot capture by moving**, ever

**B8 · Balestriere — shooting**
As a player, I want the Balestriere to kill at range without moving so that some ground is simply too dangerous to cross.
- Range 2, all eight directions, straight lines only
- The shot stops at rocks, forest, the board edge, and **any** body in the way including friendly ones
- Water does not block a shot
- The shooter does not move
- Shooting spends one command

---

## Epic C — Terrain & movement classes *(M0 — done)*

**C1 · Movement classes**
As a player, I want terrain to read differently for different pieces so that the same map asks a different question of each unit.
- Every piece belongs to exactly one class: foot, mounted, or wheeled
- Terrain effect is looked up per class, not per piece
- Foot wades rivers and stops in them
- Mounted cannot enter water at any point, including as a Cavaliere leg
- Wheeled cannot enter forest at all

**C2 · Stops-you terrain** — a sliding piece entering forest, river or ford ends its move on that tile even with distance remaining. Capturing into it is legal and still ends the move.

**C3 · Impassable terrain** — no piece may enter or slide through rocks or void; the Cavaliere may leap over rocks but not void.

**C4 · Sight blockers** — rocks, forest and void block ranged shots. Water, ford and bridge do not.

**C5 · Crossings** — bridges are open at full speed; fords stop every class. Both are ordinary ground otherwise.

**C6 · Non-square maps** — void tiles are outside the board, don't render, and block movement, leaps and shots.

---

## Epic D — Turn structure *(M0 — done)*

**D1 · Command points**
As a player, I want several actions per turn so that the game moves faster than chess.
- Each side gets the number of commands declared by the engagement
- One command moves one piece or fires one Balestriere
- No piece can act twice in a turn
- The count is visible at all times

**D2 · End turn early** — the player can pass remaining commands; the turn also ends automatically when commands run out.

**D3 · Resolution order**
- Order is: capture → events → victory check → failure check
- If victory and failure trigger on the same action, the mission is **won**

**D4 · Turn counter** — increments after both sides have acted; displayed.

---

## Epic E — Map loading *(M1)*

**E1 · Load an engagement from a file**
As the designer, I want a mission built entirely from one data file so I can author maps without touching code.
- Terrain grid, void tiles, command points per side, enemy pieces with behaviours, deployment zone, force floor, objective, failure conditions, events and mission text all read from the file
- The renderer is unchanged from M0 — only the source of the map object differs
- A malformed file fails with a readable error, not a crash

**E2 · V2-aware schema**
As the designer, I want the MVP schema to already contain the fields V2 needs so that adding the campaign later doesn't mean rebuilding every existing map.
- Deployment zone and force floor are parsed and stored even though the MVP places fixed companies
- Unknown-but-reserved fields don't cause errors

**E3 · Validate a map**
- Warns on: pieces on impassable tiles, objective regions that are unreachable, events pointing at tiles that don't exist, patrol routes crossing impassable terrain, deployment zones smaller than the force floor

**E4 · Deployment zone** *(parsed in M1, used in V2)*
- A declared region plus a placement order
- In the MVP the map's fixed company is placed directly; the zone is stored, not used

---

## Epic F — The enemy *(M2)*

**F1 · Guard** — never leaves its tile; acts only when a player piece enters its reach.

**F2 · Patrol**
- Follows a fixed route declared in the map file, looping
- The full route is drawn on the board
- The player can see where each patrol will be next turn before committing

**F3 · Charge** — moves toward the nearest player piece each turn by the shortest legal path for its movement class.

**F4 · Hold-until** — remains on its tile until a named trigger fires, then behaves as Charge.

**F5 · Enemy commands**
- The enemy spends command points exactly as the player does, per the engagement's declared number
- Each enemy action is shown one at a time and the acting piece is highlighted

**F6 · Determinism**
As a player, I want the enemy to be predictable so that the map is a puzzle I can solve rather than an opponent I guess at.
- Given identical board states, an enemy piece always makes the same choice
- Ties are broken by a fixed, documented rule — never randomly

---

## Epic G — Objectives *(M3)*

**G1 · Clear** — remove every enemy piece from a declared region; the region may be the whole board.

**G2 · Hold**
- Occupy every tile of a declared region for N consecutive turns
- The count resets to zero the moment the region is not fully held
- The remaining count is displayed

**G3 · Muster**
- Get N pieces into a declared region **simultaneously**
- Checked at the end of the player's turn
- Current count against target is displayed

**G4 · Failure conditions** — the Condottiero is lost, or the turn limit expires; the failure screen names which one fired.

**G5 · Mission briefing** — the objective is shown before the first turn.

**G6 · Objective readout** — objective, progress and turn count are visible during play.

---

## Epic H — Engagements *(M4)*

**H1 · Ambush in the Countryside** — Clear. Teaches forest, screening, and the Cavaliere's leg.
**H2 · The Bridge** — Hold for 2 turns. Teaches water, fords, and crossbows covering a crossing.
**H3 · The Villa Gate** — Muster 4 pieces. Teaches rock chokepoints and command-point pressure.
**H4 · Victory and defeat screens** — with retry and return-to-contract.
**H5 · Free retry** — any engagement can be restarted from its opening state at any time.

---

## Epic I — Events *(M4, minimal set)*

**I1 · Dialogue on mission start** — shown before the first turn, dismissable.
**I2 · Spawn on turn N** — listed pieces appear at listed tiles at the start of that turn.
**I3 · Spawn on entering a tile** — fires when a named side's piece enters; occupied spawn tiles are skipped.

---

# V2

## Epic J — Company & contracts

**J1 · Persistent company** — pieces lost in an engagement stay lost for the rest of the contract.
**J2 · Force floor** — a company below the engagement's declared minimum is topped up to it free of charge, so no engagement is ever unwinnable on arrival.
**J3 · Deployment** — the company is placed into the map's deployment zone in its declared order rather than at fixed positions.
**J4 · Named roster** — pieces surviving a full contract earn names; a roll call is shown at settlement.
**J5 · Contract structure** — three engagements per contract, with a briefing and a settlement screen.

## Epic K — Money

**K1 · Contract fee** — stated in the briefing before the contract is accepted, with a bonus for the optional secondary objective.
**K2 · Buying pieces** — anything above the free force floor is purchased at declared costs; the Condottiero is never for sale.
**K3 · Loadout** — company composition is chosen before an engagement against a visible map briefing.
**K4 · The estate** — has a price; reaching it ends the campaign.

## Epic L — Captains & orders

**L1 · Enemy Captain** — while alive, enemy pieces run their assigned behaviour.
**L2 · Orders collapse** — when the Captain falls, every enemy piece drops to Guard. Visible, immediate, no numbers.
**L3 · Command points from the Condottiero** — the player's command count depends on whether their Condottiero is alive; recalculated at the start of each turn.

## Epic M — Terrain additions

**M1 · Elevation and ramps** — a second level; a piece changes level only by moving off a ramp. The test reads the move's start and end tiles only, never history.
**M2 · Archers on high ground** — a Balestriere on elevated ground shoots over sight blockers on the level below.
**M3 · Sanctuary** — a piece on a sanctuary tile can only be captured by a piece also standing inside it. Positional only.
**M4 · Gates** — the only open tiles in a wall; destructible by event; no capture rule of their own.

## Epic N — Concealment

**N1 · Hidden in the trees** — a piece on a forest tile is not shown until an enemy piece is adjacent to it.
- Terrain is always fully visible; only occupancy is hidden
- Revealing is immediate and permanent for as long as an enemy stays adjacent
- Nothing else in the game is ever hidden

## Epic O — Remaining objectives & events

**O1 · Escort** · **O2 · Survive** · **O3 · Infiltrate** (eight-way adjacency, checked at end of turn, all patrol routes drawn)
**O4 · Trap on entry** · **O5 · Tile wear** — the rickety bridge · **O6 · Named piece captured** · **O7 · Region cleared**

## Epic P — Polish

**P1 · Art pass** · **P2 · Move and capture animation** · **P3 · Sound** · **P4 · Touch targets sized for a phone** · **P5 · Settings** · **P6 · Save progress**

---

## Decision gates

Not stories. Points where the project stops and a call gets made.

**DG1 · Is it fun?** *(after M0)* — twenty games on the prototype. If solving terrain puzzles isn't interesting with the current rules, more rules won't save it.

**DG2 · Do maps carry the variety?** *(after M4)* — three engagements must feel meaningfully different using the same pieces.

**DG3 · Ship target** *(after DG2)* — run it on a phone. Web wrapper, or port to an engine. Made while the codebase is still small enough to move, and before a campaign is designed around an untested screen size.

**DG4 · Editor or not** *(after V2 ships)*

---

## Open questions blocking nothing

Per GDD §22: phone board-size ceiling, Balestriere range, whether three commands is the right number, and whether neutral pieces exist. The first three are answered by playing, not by deciding. None of them block M1.

---

## A note on shape

Stories marked "as the designer" are tooling — A8, E1, E2, E3. If that list starts growing, the work has drifted from the game toward infrastructure. That's what stalled this project the first time.
