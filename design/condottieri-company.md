# The Company

The campaign layer. Five skilled men against many unskilled ones, carried
forward from contract to contract, where the score is not whether you won but
who came home.

Every one of the thirteen maps is verified winnable **without losing a man**, so
this promise is keepable. That verification is what makes the whole layer safe
to build.

---

## The spine

- You begin with **five men**. Two footmen, the Cavaliere, the Lanciere, the Condottiero.
- **Losses are permanent.** A man who falls does not come back.
- **Recruits are rare and earned.** A few contracts pay in men rather than only in coin.
- **The company caps at seven.** Above that it stops being few against many.

The Condottiero is not a member of the company — he is you. Losing him ends the
contract on the spot, as now.

---

## The one thing that can ruin it

Permanent losses create a death spiral: you lose two men, the next mission is
harder, you lose two more, and by the fourth you are grinding an unwinnable
mission that still looks playable.

**The fix is a snapshot, not a safety net.**

> Your company is recorded at the moment a mission begins. Retry, and you start
> that mission again with exactly the men you had walking into it.

So the worst case is ever replaying one mission, never a ruined campaign. Losses
only carry forward when you accept a result and move on. Nobody is punished for
a bad turn three missions ago, and attrition still means something because the
choice to accept a costly win is yours.

This also means you never need a free top-up mechanic. The floor is the retry.

---

## Names

The men are named from the day they join, not after they have survived
something. Mercenaries have names.

Draw from the real rolls of the period — Bartolomeo, Niccolò, Erasmo, Gattamelata,
Braccio, Micheletto — and let them keep those names for the whole campaign.

Two consequences worth designing for:

**The roll call is the end-of-mission screen.** Not a victory banner. A list of
who is standing, and a gap where anyone is missing. A clean mission shows five
names and nothing else — which should feel better than a win with four.

**A veteran is not a stronger piece.** No upgrades, ever. What you get for
keeping Bartolomeo alive through six contracts is that Bartolomeo is still
there. That is the whole reward and it is enough, because the fantasy is a band
of men, not a build.

---

## Recruits

Three kinds, all rare:

**The replacement.** A contract that pays in a body. Offered after a mission
where you took losses, so it reads as the employer making good rather than as
the game handing you a gift.

**The specialist.** A man with a skill your company lacks — and the obvious
first one is the **Balestriere**, who was cut when the company dropped to five.
He is the only answer to a position you cannot approach, so getting him back
should feel like an unlock, not a refill.

**The turncoat.** One of theirs, taken alive on a specific map, who joins for
the rest of the campaign. Mechanically a recruit; narratively the best one you
will get, because you chose to spare him.

Suggested cadence over a thirteen-mission campaign: a recruit at missions 4, 7
and 11, with mission 7 offering a **choice of two** rather than a hand-out. One
choice, no takebacks, and it changes what your company can do for the rest of
the run.

---

## Difficulty, over a campaign

The curve is the ratio, not the rules. Contracts get harder by putting more of
them on the field, never by making your men worse or the rules fiddlier.

| Contract | Missions | Their numbers |
|---|---|---|
| 1 | 1–3 | 6–7 against your 5 |
| 2 | 4–7 | 8 against your 5 or 6 |
| 3 | 8–10 | 9 |
| 4 | 11–13 | 10, with waves |

The solver grades any of these in ten seconds, so the curve can be tuned by
measurement rather than by feel. A mission that comes back **unsolvable without
losses** does not belong in the campaign at all — that is the hard rule the
whole layer rests on.

---

## What to build, in order

1. **Persist the roster between missions** — a list of surviving men, snapshotted on entry.
2. **The roll call screen** — names standing, names missing.
3. **Deployment from the roster** — maps declare where the company forms up, not which men are in it. The map data already carries a `deployment` region for exactly this.
4. **Recruits** at fixed missions.
5. **The choice at mission 7.**

Step 3 is the only one that touches the engine, and the field it needs is
already in every map file.
