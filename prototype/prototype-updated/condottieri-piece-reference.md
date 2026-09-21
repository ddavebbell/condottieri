# CONDOTTIERI — Piece & Terrain Reference
*Current as of prototype v2*

---

## The seven pieces

| Piece | Chess kin | How it moves | How it kills | Its job |
|---|---|---|---|---|
| **Fante** ♟ | Pawn | One tile, any direction, backwards included | Diagonal only — never straight ahead | The wall. Screens the Cavaliere's leg, breaks archer sightlines, plugs gaps. |
| **Cavaliere** ♞ | Knight (Xiangqi horse) | One orthogonal step, then one diagonal step outward | By landing on it | Fast flanker. Leaps rock walls. The only piece that ignores barriers. |
| **Lanciere** ♝ | Bishop | Slides any distance on the diagonals | By landing on it | Long diagonal reach across open ground. |
| **Carro** ♜ | Rook | Slides any distance on ranks and files | By landing on it | Owns streets, corridors and open lanes. |
| **Balestriere** ✦ | — | One tile, any direction | **Shoots** at range 2 without moving. Cannot kill by walking into anything. | Area denial. Makes ground too dangerous to cross. |
| **Condottiero** ♛ | Queen | Slides any distance, any direction | By landing on it | Your captain. Strongest piece on the board. |
| **Signore** ♚ | King | One tile, any direction | Any direction | The noble. Losing it loses the mission. |

---

## Movement classes

Terrain reads differently depending on who's walking on it. Three classes, four facts:

| Class | Pieces | What's special |
|---|---|---|
| **On foot** | Fante, Lanciere, Balestriere, Condottiero, Signore | Wades rivers — and stops in them |
| **Mounted** | Cavaliere | Leaps rock walls. **Cannot touch water at all** |
| **Wheeled** | Carro | **Cannot enter forest at all** |

---

## Terrain

| Tile | On foot | Mounted | Wheeled | Blocks shots |
|---|---|---|---|---|
| **Field** | Open | Open | Open | No |
| **Forest** | Stops you | Stops you | Cannot enter | **Yes** |
| **River** | Stops you | Cannot enter | Cannot enter | No |
| **Ford** | Stops you | Stops you | Stops you | No |
| **Bridge** | Open | Open | Open | No |
| **Rocks** | Cannot enter | Leaps over | Cannot enter | **Yes** |
| **Void** | Off the board | Off the board | Off the board | Yes |

**"Stops you"** means a sliding piece entering that tile ends its move there, even with distance remaining. Forest is both cover and a trap: safe from bolts, but you lose your momentum getting in.

---

## The two rules that aren't obvious

**The Cavaliere's leg.** It steps one tile orthogonally, then one diagonally outward. That first tile — the leg — is what can stop it:

- An **enemy piece** on the leg blocks the move. A friendly piece does not.
- **Water** on the leg blocks it. A horse doesn't cross a river.
- **Rocks** on the leg do *not* block it. That's the leap.

**The Balestriere's line.** Range 2, all eight directions, straight lines only. The bolt is stopped by anything that breaks sight: rocks, forest, the board edge, and **any body in the way — including its own side's.** Water doesn't block, so archers cover rivers and bridges well. An archer surrounded by trees is nearly blind.

---

## Turn structure

**Three commands per side per turn.** One command moves one piece, or fires one Balestriere. No piece can act twice in a turn. End the turn early if you don't want to spend them all.

The number lives in the map file, so it's a per-mission design lever — a wide front might get five, a delicate infiltration might get one.

---

## Winning

In the prototype: take the enemy Signore. In the campaign, most missions won't be about that — see GDD §8 for the six objective types.
