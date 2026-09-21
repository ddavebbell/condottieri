# CONDOTTIERI — The Balance Solver
### Plan, v1

The solver is the thing that makes map authoring safe. Once it exists, every map you write gets an answer to *is this actually a puzzle, and does it teach what it claims* before you ever play it. Without it, you are hand-testing 30 missions against a rule set that keeps moving.

It is possible at all because the game is deterministic: no dice, fixed enemy behaviours, documented tie-breaks. That was a design decision made for the player's benefit, and it turns out to hand you a verifiable game for free.

---

## 1. What it must answer

Per map, in priority order:

| Question | Why it matters |
|---|---|
| **Is it winnable?** | The floor. A map that isn't is a bug, not a difficulty setting. |
| **In how few turns?** | Compared against the turn limit, this is the slack. Too much slack is a boring map; none is a fiddly one. |
| **Is there a no-loss line?** | You promised the player a perfect run. This is the only way to know the promise is keepable. |
| **Which rules does the winning line use?** | Does the ambush map actually require the discipline, or can it be brute-forced? This validates the `teaches` field. |
| **How many distinct winning openings?** | One is a tight puzzle. Forty is a sandbox. This is your difficulty dial. |
| **Is anything dead?** | Enemies never engaged, terrain never entered, pieces never moved, triggers never fired. |
| **Does a trigger make it unwinnable?** | Killing the keyed unit spawns a wave. Verify it doesn't lock the map. |

---

## 2. Why it is hard, and the shape of the answer

**The branching is the problem.** Three commands a turn, seven pieces, roughly eight destinations each: about 56 × 48 × 40 ≈ 100,000 command sequences per turn before the enemy even moves. Over an 18-turn limit, brute force is hopeless.

Three things make it tractable:

**Order collapses.** Most of those 100,000 sequences end in the same board position. Canonicalise on the *end-of-turn state* — piece positions and types, whose turn, turn number, objective progress, which waves have fired — hash it, and keep one. The real branching factor is the number of distinct end-of-turn states, which is far smaller. Nobody knows how much smaller yet, which is why step one is to measure it.

**Finding a win is far cheaper than proving none exists.** So split the job:
- A **beam search** always runs: keep the best N states per turn by heuristic, look for a win. If it finds one, the map is winnable and you have a line to show. Cheap, and it answers the common case.
- An **exact search** runs only when the beam fails: full breadth-first over canonical states with a transposition table, bounded by the turn limit. Slow, but it is the only thing that can say *unwinnable* with authority.

**No-loss is a smaller problem than winning.** Prune any line that loses a piece and the tree shrinks hard. Run it as its own search rather than filtering the general one.

---

## 3. Build order

### Step 0 — Extract the engine *(prerequisite, do not skip)*

The rules currently live inside the HTML and read module-level `map` and `state`. Every test in this project has had to slice the engine out of the page with a regex first. That is fine for a prototype and fatal for a solver, which needs to hold thousands of states at once.

- Move the rules into `engine.js`, imported by the page and by the solver.
- Make the core pure: `legalActions(state, side)`, `applyAction(state, action) -> newState`, `endEnemyTurn(state) -> newState`, `outcome(state)`. No globals, no in-place mutation of shared objects.
- This also permanently kills the class of bug that broke the exposure preview: a helper that borrowed the board and gave back a copy.

**Definition of done:** the existing test suite runs against `engine.js` with no regex extraction.

### Step 1 — Measure the state space

Before promising exactness, instrument it. Count distinct canonical end-of-turn states reachable in 1, 2, 3, 4 turns on each of the three maps.

This is half a day and it decides the architecture. If turn 4 is in the thousands, exact search is viable to the turn limit. If it is in the millions, the exact solver is only ever a spot-check tool and the beam is the workhorse.

**Deliverable:** a table of state counts per turn per map. No solver yet.

### Step 2 — The beam solver

- Heuristic: enemies remaining, objective progress, pieces alive, distance to objective region, number of your men anchored.
- Keep the top N (start at 2,000) states per turn.
- Output: winnable yes/no, turns taken, the move list.

**Deliverable:** `solve(map) -> {winnable, turns, line}` for all three maps.

### Step 3 — The no-loss solver

Same search, with any state that has lost a piece discarded outright. Answers the perfect-run promise.

**Deliverable:** per map, `noLoss: {possible, turns, line}`.

### Step 4 — Exact search

Breadth-first over canonical states with a transposition table, iterative deepening on turn count. Run only when the beam finds nothing, or when you want a proven minimum rather than an upper bound.

**Deliverable:** `prove(map) -> {winnable, minTurns}` or a clean timeout.

### Step 5 — The balance report

One page per map, generated:

```
The Bridge                                      13x13 · 7v7 · limit 18
  Winnable            yes, 9 turns   (slack 9 — consider tightening to 13)
  No-loss line        yes, 11 turns
  Winning openings    6 distinct first turns
  Rules exercised     wading ✓   discipline ✓   hobbling ✗   gate column —
  Claimed teaching    "Only foot wades"                      ✓ matches
  Dead content        their Fante at 7,2 never engaged
                      the ford at 3,6 never entered
  Trigger check       killing 'bridgeguard' keeps it winnable (9 → 11 turns)
```

The **rules exercised** row is the one that earns its keep. It tells you whether the map teaches what the `teaches` field claims, and it is the only automated way to catch a map that looks clever and plays as a brawl.

### Step 6 — Run it as a test

Every map, on every change to the rules. A map that becomes unwinnable, or loses its no-loss line, fails the build the same way a broken terrain grid does now.

This is what makes the rules safe to keep changing — which, twenty-four versions in, is clearly something this project needs.

---

## 4. Honest risks

**The state space may not collapse enough.** Step 1 exists precisely because I do not know yet. If exact search is out of reach, you still get the beam, which answers "winnable" and "here is a line" — just not "provably unwinnable."

**The solver must model the enemy exactly.** Any divergence between the solver's enemy and the game's enemy invalidates every result. Mitigation: they share `engine.js`. No second implementation, ever.

**A solver measures solvability, not fun.** It will happily certify a map that is technically a puzzle and emotionally a chore. It replaces hand-testing for correctness, not for judgement. Keep playing them.

**Scope creep toward a learning agent.** Resist. There is no opponent to learn against — the enemy is part of the map. A search over your own moves gives exact answers where a learned policy gives statistics, and exact is what map authoring needs.

---

## 5. Where this leads

The solver is the missing half of the map editor you started with. StarEdit worked because the simulation underneath it was finished and tuned; the editor only exposed it. When you come back to the editor, the solver is what turns it from a level-drawing tool into a level-*designing* tool: draw a map, and it tells you immediately whether it is a puzzle, how tight it is, and whether it teaches the thing you meant.

That is the version of your original idea worth building. It just has to come second.
