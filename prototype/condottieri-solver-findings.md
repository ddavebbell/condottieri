# Solver — first findings

Built overnight: steps 0, 1, 2 and 3 of the plan. Code in `/solver`, results below.

The short version: **the solver worked, and the first thing it found is that the game is broken.** The Condottiero solves every map on his own.

---

## 1. What got built

**Step 0 — the engine is out of the page.** `src/engine.js` holds the rules plus a pure interface: `initialState(map)`, `actions(map, state)`, `apply(map, state, action) -> newState`, `pass`, `outcome`, `hash`. The 29 rule tests now run straight against it with no regex extraction.

The page is *built* from the same file (`tools/build.js` → `dist.html`), so there is one implementation of the rules and the solver can never drift from the game it is measuring.

**Step 1 — the state space is measured.** Distinct end-of-turn positions reachable from the opening:

| Map | after turn 1 | applies | time |
|---|---|---|---|
| Ambush | 2,619 | 7,535 | 1.3 s |
| The Bridge | 5,521 | 15,672 | 2.1 s |
| The Villa Gate | 2,425 | 7,001 | 1.1 s |

Turn 2 is therefore in the millions, and an exact search to an 18-turn limit is out of reach. **The beam is the workhorse; exact search is a spot-check tool only.** That is the architecture question answered, and it went the way the plan feared.

**Steps 2 and 3 — the beam solver runs**, with a no-loss mode. About 20,000 positions per second.

---

## 2. Three bugs the solver found

**In my measurement, not the game:** the walk never terminated because after the enemy replies it is the player's turn again — turn-end has to be detected on the turn *counter*, not on whose move it is.

**In the solver wrapper, not the game:** I checked the objective after every command. The game only counts a Hold at the end of a turn. Checking per command ticked the counter three times a turn and reported a one-turn win on a two-turn hold. Fixed, and `tools/parity.js` now guards it.

That one is worth dwelling on: it is exactly the failure the plan warned about — a solver that plays a slightly different game tells you confident lies. It is also why the parity check has to stay in the suite.

**A heuristic trap that looks like a broken map.** The first search on the Ambush stalled at *one enemy remaining* for ten straight turns. The survivor was always their Lanciere — who is the **capo**. Killing him spawns two reinforcements, so the greedy search correctly refused: the enemy count goes up.

The fix is to count waves that have not arrived yet as enemies you already owe. With that, the same map solves in seven turns. Any map with a death trigger needs this, or the solver will report it unwinnable.

---

## 3. The finding that matters

| Map | Winnable | Turns | Limit | Slack | Your losses |
|---|---|---|---|---|---|
| Ambush in the Countryside | yes | **7** | 16 | 9 | 1 |
| The Bridge | yes | **2** | 18 | **16** | 0 |
| The Villa Gate | not yet found | — | 16 | — | — |

The Bridge, in full:

```
t1  Condottiero 4,6 takes Balestriere at 4,3
t1  Lanciere 6,6 to 4,4
t2  Fante 1,6 to 1,5
```

The captain slides three tiles down the file, kills the crossbowman that the whole mission is built around, the Lanciere steps onto the planks, and it is over on turn two of eighteen.

On the Ambush he personally takes **six of the ten**.

### Why

Nothing on their side is ever sheltered — the discipline is yours alone. So a piece that moves sixteen ways and kills for free has no counterplay at all. The discipline protects your men beautifully and does nothing whatsoever to restrain your offence, and the Condottiero is both your best anchor *and* your best killer.

Every map's stated lesson is bypassed. Wading, the gate column, hobbling the horse, keeping the rank together — the solver used none of them.

### Four ways out, cheapest first

1. **The Condottiero cannot capture.** He anchors all eight squares and commands, and never kills. Thematically right — he is a captain, not a duellist — and it immediately makes the footmen, the lanciere and the horse do the work. Losing him already fails the contract, so he keeps his weight.
2. **Cap movement per command.** No piece moves more than three tiles in one command. Nerfs every slider without touching protection.
3. **Give them a capo shelter.** Their men adjacent to their keyed unit cannot be taken by ordinary pieces. Restores the need for tactics, at the cost of the asymmetry you liked.
4. **Cut the turn limits.** Real, but cosmetic next to the above — a two-turn solution against an eighteen-turn limit is not a pacing problem.

My recommendation is **(1)**. It is one line, it is the most thematic, and it turns your most interesting piece from a wrecking ball into something you position and protect.

---

## 4. Where to pick up

- Make the design call above, then re-solve. The numbers to watch are turns-to-win and whether the winning line uses more than one piece.
- The Villa Gate has not been solved yet — the search was still going at turn 12 when I stopped it. It is the hardest of the three, which is a good sign.
- Steps 4–6 of the plan are untouched: exact search, the rules-exercised report, and wiring the solver into the test suite.
- `tools/lib.js` holds the heuristic. It is the crudest part of what I built and the easiest thing to improve.

---

# Addendum — the Condottiero disarmed

**Change made:** the Condottiero may move and anchor as before, but may not capture. One filter in `legalMoves`; he keeps every square of his reach for movement and still shelters all eight tiles around him. Losing him still fails the contract.

## Before and after

| Map | Before | After |
|---|---|---|
| Ambush | won t7, **1 lost**, captain takes 6 of 10 | won **t6, 0 lost**, kills spread across Lanciere ×3, Cavaliere ×4, Fanti ×2 |
| The Bridge | won t2, 0 lost, captain kills the bridge guard | won t2, 1 lost — **still trivial, see below** |
| The Villa Gate | unsolved | unsolved at turn 15, stuck at 4 enemies and 1 man in the courtyard |

**The Ambush is fixed.** Nobody dies, it takes six turns, and no single piece carries it. The captain moves only to position and shelter — which is exactly what he is for.

## Two things the change did not fix

### The Bridge is a map problem, not a rules problem

```
t1  Lanciere 6,6 to 4,4        (onto the planks; the hold counts at turn end)
    ...their crossbowman shoots him
t2  Condottiero 4,6 to 4,4     (steps onto the empty square; hold reaches 2)
```

Two turns of eighteen. Throw one man onto the bridge to bank the first count, walk a second man on to bank the second. The crossbowman, the river, the flanking wade — none of it is needed.

The causes are all in the map, not the rules:

- **Hold is only 2 turns**, and the bridge is two tiles from your starting line.
- **The count banks even if the man dies afterwards**, so a body is enough.
- **Eighteen turns is nine times what the map needs.**

Worth trying, in order: raise the hold to 4 or 5 turns; move the muster line back two rows; and consider whether a hold should count only if the man is *still standing* at the start of your next turn, which would make the sacrifice trick fail.

### The Villa Gate may be unwinnable

Fifteen turns, four enemies still standing, and never more than **one** man inside the courtyard against a target of three. The suspects:

- The gate is one tile wide and sighted by a crossbowman who kills for free.
- Killing him turns the household out — two more footmen spawn **inside the courtyard**, in the very tiles you are trying to muster into.
- Muster is checked at a moment in time, so all three must be in there at once.

This needs the exact solver to settle, or a deliberate loosening: a wider gate, muster of 2, or the household spawning outside the walls rather than in them.

## Where that leaves it

One rules change fixed one map and proved the other two have design problems of their own — which is the solver doing its job. The next moves are map edits, not rules edits, and each one can be re-measured in about two minutes.
