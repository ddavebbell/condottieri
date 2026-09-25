/* Condottieri — the rules. One implementation, shared by the game and the solver. */

/* ============================================================
   TERRAIN
   effect is per movement class: open | rough | blocked
   ============================================================ */

const TERRAIN = {
  '.': { name:'Field',  css:'t-open',   leap:true,
         effect:{ foot:'open',    mounted:'open',    wheeled:'open'    } },
  'f': { name:'Forest', css:'t-rough',  leap:true,  blocksShot:true,
         effect:{ foot:'rough',   mounted:'rough',   wheeled:'blocked' } },
  '~': { name:'River',  css:'t-water',  leap:false, mire:true,
         effect:{ foot:'rough',   mounted:'blocked', wheeled:'blocked' } },
  ':': { name:'Ford',   css:'t-ford',   leap:true,  mire:true,
         effect:{ foot:'rough',   mounted:'rough',   wheeled:'rough'   } },
  '=': { name:'Bridge', css:'t-bridge', leap:true,
         effect:{ foot:'open',    mounted:'open',    wheeled:'open'    } },
  '#': { name:'Rocks',  css:'t-rock',   leap:true,  blocksShot:true,
         effect:{ foot:'blocked', mounted:'blocked', wheeled:'blocked' } },
  'm': { name:'Marble', css:'t-marble', leap:true,
         effect:{ foot:'open',    mounted:'open',    wheeled:'open'    } },
  ' ': { name:'',       css:'t-void',   leap:false, blocksShot:true, void:true,
         effect:{ foot:'blocked', mounted:'blocked', wheeled:'blocked' } }
};

const PIECES = {
  fante:       { label:'Fante',       glyph:'♟', move:'foot',    value:1 },
  cavaliere:   { label:'Cavaliere',   glyph:'♞', move:'mounted', value:4 },
  lanciere:    { label:'Lanciere',    glyph:'♝', move:'foot',    value:3 },
  carro:       { label:'Carro',       glyph:'♜', move:'wheeled', value:4 },
  balestriere: { label:'Balestriere', glyph:'✦', move:'foot',    value:3 },
  condottiero: { label:'Condottiero', glyph:'♛', move:'foot',    value:9 },
  signore:     { label:'Signore',     glyph:'♚', move:'foot',    value:9 }
};

const PLAYER = 'rosso', FOE = 'azzurro';
const SIDE_NAME = { rosso:'Rosso', azzurro:'Azzurro' };
const SHOT_RANGE = 1;

/*  WALLS
    A wall sits on the border between two tiles rather than eating a tile.
    Nothing crosses it — not a man, not a horse, not a bolt — but both
    tiles either side stay playable. This is how a building is drawn
    without spending half the board on it.                              */

const wallKey = (x1,y1,x2,y2) =>
  (x1 < x2 || (x1 === x2 && y1 < y2)) ? `${x1},${y1}|${x2},${y2}` : `${x2},${y2}|${x1},${y1}`;

let WALLS = new Set();

function loadWalls(list) {
  WALLS = new Set((list || []).map(w => wallKey(w[0][0], w[0][1], w[1][0], w[1][1])));
}

/* Is there a wall between these two neighbouring tiles? Diagonals may not
   be squeezed past a wall corner. */
function walled(x1, y1, x2, y2) {
  const dx = x2 - x1, dy = y2 - y1;
  if (dx && dy) {
    return WALLS.has(wallKey(x1, y1, x1 + dx, y1))
        || WALLS.has(wallKey(x1, y1, x1, y1 + dy))
        || WALLS.has(wallKey(x1 + dx, y1, x2, y2))
        || WALLS.has(wallKey(x1, y1 + dy, x2, y2));
  }
  return WALLS.has(wallKey(x1, y1, x2, y2));
}

/* The perimeter of a rectangle, as a wall list. */
function wallRect(x1, y1, x2, y2) {
  const out = [];
  for (let x = x1; x <= x2; x++) { out.push([[x,y1-1],[x,y1]]); out.push([[x,y2],[x,y2+1]]); }
  for (let y = y1; y <= y2; y++) { out.push([[x1-1,y],[x1,y]]); out.push([[x2,y],[x2+1,y]]); }
  return out;
}

/* Knock a gate through a wall list. */
function gateAt(list, ax, ay, bx, by) {
  const k = wallKey(ax, ay, bx, by);
  return list.filter(w => wallKey(w[0][0], w[0][1], w[1][0], w[1][1]) !== k);
}

/* rect(x1,y1,x2,y2) -> list of tiles, for objective regions */
function rect(x1, y1, x2, y2) {
  const out = [];
  for (let y = y1; y <= y2; y++) for (let x = x1; x <= x2; x++) out.push([x, y]);
  return out;
}

/* ============================================================
   ENGAGEMENTS
   Schema carries the V2 fields (deployment, floor) even though
   the MVP places fixed companies — see GDD §20 / story E2.
   ============================================================ */

/* MAPS are injected by the build */


/* ============================================================
   STATE
   ============================================================ */

let map, state, history, selected, lastMove, busy = false;

function newState() {
  return {
    pieces: map.pieces.map((p, i) => ({ id:i, routeStep:0, awake:false, ...p })),
    turn: PLAYER,
    turnNumber: 1,
    commands: map.commands[PLAYER],
    acted: [],
    taken: [],
    slain: [],           // keys of named men who have fallen
    arrived: [],         // which reinforcement waves have already come up
    nextId: 500,
    holdCount: 0,
    over: null,          // 'won' | 'lost'
    reason: '',
    message: ''
  };
}

function loadMap(index) {
  map = MAPS[index];
  mapIndex = index;
  loadWalls(map.walls);
  state = newState();
  history = [];
  selected = null;
  lastMove = null;
  busy = false;
  buildBoard();
  validateMap();
  el('hint').textContent = '';
  showBriefing();
  render();
}

let mapIndex = 0;
const clone = s => JSON.parse(JSON.stringify(s));

/* ============================================================
   QUERIES
   ============================================================ */

const inBounds = (x,y) => x >= 0 && y >= 0 && x < map.width && y < map.height;
const tileAt   = (x,y) => TERRAIN[map.terrain[y][x]];
const pieceAt  = (x,y) => state.pieces.find(p => p.x === x && p.y === y) || null;
const effectFor = (piece, x, y) => tileAt(x, y).effect[PIECES[piece.type].move];
const chebyshev = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y));

/* ============================================================
   MOVEMENT
   ============================================================ */

const ORTHO = [[0,-1],[0,1],[-1,0],[1,0]];
const DIAG  = [[-1,-1],[1,-1],[-1,1],[1,1]];
const ALL8  = ORTHO.concat(DIAG);

function slide(piece, dirs) {
  const moves = [];
  for (const [dx, dy] of dirs) {
    let x = piece.x + dx, y = piece.y + dy;
    while (inBounds(x, y)) {
      if (walled(x - dx, y - dy, x, y)) break;
      const eff = effectFor(piece, x, y);
      if (eff === 'blocked') break;
      const occ = pieceAt(x, y);
      if (occ) {
        if (occ.side !== piece.side) moves.push({ x, y, capture:true });
        break;
      }
      moves.push({ x, y, capture:false });
      if (eff === 'rough') break;
      x += dx; y += dy;
    }
  }
  return moves;
}

function step(piece, dirs, { captures = true } = {}) {
  const moves = [];
  for (const [dx, dy] of dirs) {
    const x = piece.x + dx, y = piece.y + dy;
    if (!inBounds(x, y)) continue;
    if (effectFor(piece, x, y) === 'blocked') continue;
    const occ = pieceAt(x, y);
    if (occ) {
      if (!captures || occ.side === piece.side) continue;
      moves.push({ x, y, capture:true });
    } else {
      moves.push({ x, y, capture:false });
    }
  }
  return moves;
}

/*  Cavaliere — the Xiangqi horse. One orthogonal step (the leg), then one
    diagonal step outward. The leg is what stops it: an enemy piece blocks,
    water blocks, rocks do not.                                           */
function cavaliereMoves(piece) {
  const moves = [];
  for (const [dx, dy] of ORTHO) {
    const lx = piece.x + dx, ly = piece.y + dy;
    if (!inBounds(lx, ly)) continue;
    if (walled(piece.x, piece.y, lx, ly)) continue;
    if (!tileAt(lx, ly).leap) continue;
    const legPiece = pieceAt(lx, ly);
    if (legPiece && legPiece.side !== piece.side) continue;

    const spread = dx === 0 ? [[-1,dy],[1,dy]] : [[dx,-1],[dx,1]];
    for (const [sx, sy] of spread) {
      const x = lx + sx, y = ly + sy;
      if (!inBounds(x, y)) continue;
      if (walled(lx, ly, x, y)) continue;
      if (effectFor(piece, x, y) === 'blocked') continue;
      const occ = pieceAt(x, y);
      if (occ && occ.side === piece.side) continue;
      moves.push({ x, y, capture: !!occ, leg:[dx, dy] });
    }
  }
  return moves;
}

/*  Fante — walks the four square directions, so a rock never traps him and
    he can fall back. But he kills only on the two diagonals ahead of him.
    A footman has a front, and coming at him from behind is the whole
    reason to manoeuvre.                                                  */
const FILE_DIRS = ORTHO;
const ADVANCE = { rosso: -1, azzurro: 1 };   // which way is forward, in y

function fanteMoves(piece) {
  const moves = [];
  for (const [dx, dy] of FILE_DIRS) {
    const x = piece.x + dx, y = piece.y + dy;
    if (!inBounds(x, y)) continue;
    if (walled(piece.x, piece.y, x, y)) continue;
    if (effectFor(piece, x, y) === 'blocked') continue;
    if (pieceAt(x, y)) continue;
    moves.push({ x, y, capture:false });
  }
  const fwd = ADVANCE[piece.side];
  for (const dx of [-1, 1]) {
    const x = piece.x + dx, y = piece.y + fwd;
    if (!inBounds(x, y)) continue;
    if (walled(piece.x, piece.y, x, y)) continue;
    if (effectFor(piece, x, y) === 'blocked') continue;
    const occ = pieceAt(x, y);
    if (occ && occ.side !== piece.side) moves.push({ x, y, capture:true });
  }
  return moves;
}

/*  The Condottiero commands; he does not duel.

    He keeps every square of his reach for moving and for anchoring — he
    still shelters all eight tiles around him, which is the whole of his
    worth — but he may not take a man. Losing him still fails the contract.

    Before this, the solver finished The Bridge on turn two of eighteen and
    took six of ten on the Ambush with this one piece, ignoring every rule
    the maps were built to teach. A sixteen-direction slider that kills for
    free has no answer when nothing on their side is ever sheltered.      */
function legalMoves(piece) {
  const ms = removeBraced(piece, rawMoves(piece));
  return piece.type === 'condottiero' ? ms.filter(m => !m.capture) : ms;
}

/*  WADING

    Water is slow to enter and slow to leave. Entering ends a move, as any
    rough ground does — and a man standing in water may only move one
    square, whatever he is. A condottiero in the river is a footman until
    he is out of it, and a horse can only wade out a step at a time.

    So a river is not a tax on one move. It is two turns of your life, and
    a piece caught mid-crossing is a piece that cannot answer anything.  */
const inMire = p => !!tileAt(p.x, p.y).mire;

function rawMoves(piece) {
  if (inMire(piece)) {
    switch (piece.type) {
      case 'lanciere':    return step(piece, DIAG);
      case 'carro':       return step(piece, ORTHO);
      case 'condottiero': return step(piece, ALL8);
      case 'cavaliere':   return step(piece, ORTHO);   // he wades out, he does not charge
      default: break;                                  // the rest already move a single square
    }
  }
  switch (piece.type) {
    case 'fante':       return fanteMoves(piece);
    case 'cavaliere':   return cavaliereMoves(piece);
    case 'lanciere':    return slide(piece, DIAG);
    case 'carro':       return slide(piece, ORTHO);
    case 'condottiero': return slide(piece, ALL8);
    case 'signore':     return step(piece, ALL8);
    case 'balestriere': return step(piece, ALL8, { captures:false });
    default: return [];
  }
}

/*  Ranged attack — range 2, straight lines, stopped by rocks, forest, the
    board edge and any body in the way including friendly ones.           */
/*  THE CROSSBOW

    At the usual reach of one, that is the eight tiles beside him. Further
    out the far corners fall away, so his arc is never a plain square.

    A bolt down a rank, a file or a true diagonal is a clean shot and will
    kill anyone, defended or not. Any other angle is awkward: good enough
    for a man nobody is covering, and no good at all against one who is.

    Rocks, forest, walls and bodies all stop it. A crossbow strikes alone.  */

const rangeOf = p => p.range || SHOT_RANGE;
const isCleanLine = (dx, dy) => dx === 0 || dy === 0 || Math.abs(dx) === Math.abs(dy);
/*  Reach in steps, where the first diagonal is free and the second costs.
    At reach one that is all eight tiles beside him; at reach two the far
    corners fall away.                                                    */
const paces = (dx, dy) => {
  const a = Math.abs(dx), b = Math.abs(dy);
  return Math.max(a, b) + Math.floor(Math.min(a, b) / 2);
};

/* Walk the bolt from the archer to the tile and see whether it gets there. */
function boltReaches(from, tx, ty) {
  const dx = tx - from.x, dy = ty - from.y;
  const steps = Math.max(Math.abs(dx), Math.abs(dy));
  let px = from.x, py = from.y;
  for (let i = 1; i <= steps; i++) {
    const x = Math.round(from.x + (dx * i) / steps);
    const y = Math.round(from.y + (dy * i) / steps);
    if (!inBounds(x, y)) return false;
    if (walled(px, py, x, y)) return false;
    if (i < steps) {
      if (tileAt(x, y).blocksShot) return false;
      if (pieceAt(x, y)) return false;
    }
    px = x; py = y;
  }
  return true;
}

/* Every tile inside this archer's arc, whether or not anyone is on it. */
function arcOf(piece) {
  const r = rangeOf(piece), out = [];
  for (let dy = -r; dy <= r; dy++) {
    for (let dx = -r; dx <= r; dx++) {
      if (!dx && !dy) continue;
      if (paces(dx, dy) > r) continue;                 // the diamond
      const x = piece.x + dx, y = piece.y + dy;
      if (!inBounds(x, y) || tileAt(x, y).void) continue;
      if (!boltReaches(piece, x, y)) continue;
      out.push({ x, y, clean: isCleanLine(dx, dy) });
    }
  }
  return out;
}

/* Enemies this archer can actually loose at. */
function shots(piece) {
  if (piece.type !== 'balestriere') return [];
  return arcOf(piece).filter(t => {
    const occ = pieceAt(t.x, t.y);
    if (!occ || occ.side === piece.side) return false;
    return true;                          // cover sets the price, not the law
  });
}

function blockedShots() { return []; }


/*  Everything this side could kill right now — bolts, blows, charges, all
    of it, with cover and weight already taken into account. This is what
    the danger marks are drawn from, so what you see is exactly what they
    can do to you.                                                        */
function threatTiles(side) {
  const out = new Map();
  for (const p of state.pieces) {
    if (p.side !== side) continue;
    for (const m of legalMoves(p)) {
      if (!m.capture) continue;
      out.set(m.x + ',' + m.y, PIECES[p.type].label);
    }
    for (const t of shots(p)) out.set(t.x + ',' + t.y, PIECES[p.type].label);
  }
  return out;
}

const canAct = p => !state.over && p.side === state.turn && !state.acted.includes(p.id);

/*  Look one move ahead: if this man goes there, can they kill him on their
    turn? Played out on the real board and put back, so it accounts for the
    discipline, the horse, the bolt and whatever he displaced.            */
function wouldBeExposed(piece, x, y) {
  const original = state.pieces;

  // work entirely on copies — the real men must not be touched, or the
  // piece you have selected ends up standing wherever the test last put it
  const work = original.map(p => ({ ...p }));
  const victim = work.find(p => p.x === x && p.y === y && p.side !== piece.side);
  const board = victim ? work.filter(p => p.id !== victim.id) : work;
  const mover = board.find(p => p.id === piece.id);
  if (!mover) return false;
  mover.x = x; mover.y = y;

  state.pieces = board;
  const foe = piece.side === PLAYER ? FOE : PLAYER;
  let exposed = false;
  for (const e of board) {
    if (e.side !== foe) continue;
    if (legalMoves(e).some(t => t.capture && t.x === x && t.y === y) ||
        shots(e).some(t => t.x === x && t.y === y)) { exposed = true; break; }
  }
  state.pieces = original;
  return exposed;
}

/* ============================================================
   COVER, AT ARM'S LENGTH

   A man protects the neighbouring squares he could kill on. Nothing
   further. That one sentence gives the whole table:

     Fante, Lanciere   the four diagonals touching him
     Carro             the four squares beside him
     Condottiero,
     Signore,
     Balestriere       all eight
     Cavaliere         nothing — his reach is never adjacent

   So a lanciere threatens the length of its diagonal but only shelters
   the four corners it touches. Killing range and protecting range are
   different things, and choosing between them is the position.

   Take a protected man and you die with him. Nobody moves, nothing is
   dragged out of place — you simply spend the man who made the kill.

   Two things break a formation:

     THE HORSE crashes through. He kills a protected man and lives. He
     protects nobody in return, so he is a raider and never an anchor —
     and he can be hobbled, since a body on his leg stops the charge.

     THE BOLT never enters the square, so there is nobody there to die
     with. A crossbowman kills protected men for free, which is why he
     is rare and why he only reaches one step.
   ============================================================ */

function attackVector(attacker, m) {
  if (m.leg) return { dx: m.leg[0], dy: m.leg[1] };
  return { dx: Math.sign(m.x - attacker.x), dy: Math.sign(m.y - attacker.y) };
}

/* ============================================================
   THE CONDOTTIERI DISCIPLINE

   The only shelter in the game, and it is yours alone.

   Where one of your men stands beside a Lanciere or your Condottiero —
   on a square that anchor could strike — the enemy cannot take him. Not
   for a price. Not at all.

   The crossbowman is no anchor. He is the piece that breaks a formation,
   and a man cannot be both the weapon against a line and the thing that
   holds one together.

   Nothing else shelters anything. Their men are simply taken, yours are
   simply taken, and killing costs the killer nothing. One rule, and it
   belongs to the trained company.

   Two things still get through: a cavalry charge, and a crossbow bolt.
   So the whole danger on the board reduces to their horse and their bow,
   and a mission can be finished without losing a man.

   The anchors hold what they touch:
     Lanciere               the four corners beside him
     Condottiero            all eight
   ============================================================ */

const ANCHOR = { lanciere:true, condottiero:true };
const BREAKS_DISCIPLINE = { cavaliere:true, balestriere:true };

/* What an anchor holds: the neighbouring squares it could kill on. */
function attackSquares(piece) {
  if (!ANCHOR[piece.type]) return [];
  return rawMoves(piece).filter(t =>
    Math.max(Math.abs(t.x - piece.x), Math.abs(t.y - piece.y)) === 1);
}

/* Which of your anchors are holding this man up. */
function defendersOf(piece) {
  const original = state.pieces;
  state.pieces = original.filter(p => p.id !== piece.id);
  const out = state.pieces.filter(d =>
    d.side === piece.side && ANCHOR[d.type] &&
    attackSquares(d).some(t => t.x === piece.x && t.y === piece.y));
  state.pieces = original;
  return out;
}

/* One of yours, standing where an anchor of yours holds him. */
function isImmune(piece) {
  return piece.side === PLAYER && defendersOf(piece).length > 0;
}

const isDefended = isImmune;   // the only kind of shelter there is

function canBeTaken(attackerType, victim) {
  if (isImmune(victim) && !BREAKS_DISCIPLINE[attackerType]) return false;
  return true;
}

function removeBraced(attacker, moves) {
  return moves.filter(m => !m.capture || canBeTaken(attacker.type, pieceAt(m.x, m.y)));
}






/* ============================================================
   OBJECTIVES
   ============================================================ */

const inRegion = (tiles, x, y) => tiles.some(t => t[0] === x && t[1] === y);

function objectiveText() {
  const o = map.objective;
  if (o.type === 'clear')  return 'Clear the field of every enemy.';
  if (o.type === 'hold')   return `Hold the crossing for ${o.turns} turns.`;
  if (o.type === 'muster') return `Gather ${o.count} men in the courtyard.`;
  return '';
}

function objectiveProgress() {
  const o = map.objective;
  if (o.type === 'clear') {
    const left = state.pieces.filter(p => p.side === FOE).length;
    return `${left} enemy ${left === 1 ? 'man' : 'men'} left`;
  }
  if (o.type === 'hold') return `Held ${state.holdCount} of ${o.turns} turns`;
  if (o.type === 'muster') {
    const n = state.pieces.filter(p => p.side === PLAYER && inRegion(o.tiles, p.x, p.y)).length;
    return `${n} of ${o.count} in the courtyard`;
  }
  return '';
}

/* Checked at the end of the player's turn. */
function checkObjective() {
  const o = map.objective;

  if (o.type === 'clear') {
    if (!state.pieces.some(p => p.side === FOE)) return true;
  }

  if (o.type === 'hold') {
    const held = o.tiles.every(([x, y]) => {
      const p = pieceAt(x, y);
      return p && p.side === PLAYER;
    });
    state.holdCount = held ? state.holdCount + 1 : 0;
    if (state.holdCount >= o.turns) return true;
  }

  if (o.type === 'muster') {
    const n = state.pieces.filter(p => p.side === PLAYER && inRegion(o.tiles, p.x, p.y)).length;
    if (n >= o.count) return true;
  }

  return false;
}

function checkFailure() {
  if (!state.pieces.some(p => p.side === PLAYER && p.type === 'condottiero')) {
    return 'Your Condottiero is dead. The company scatters.';
  }
  if (state.turnNumber > map.turnLimit) {
    return 'The hour is gone. The contract is forfeit.';
  }
  return null;
}

/* Resolution order: capture -> events -> victory -> failure. Victory wins ties. */
function resolveEndOfPlayerTurn() {
  if (checkObjective()) { finish('won', 'The contract is fulfilled.'); return; }
  const fail = checkFailure();
  if (fail) finish('lost', fail);
}

function finish(result, reason) {
  state.over = result;
  state.reason = reason;
  selected = null;
}

/* ============================================================
   ACTIONS
   ============================================================ */

function remove(victim) {
  state.pieces = state.pieces.filter(p => p.id !== victim.id);
  state.taken.push({ type:victim.type, side:victim.side });
  if (victim.key) state.slain.push(victim.key);   // someone was watching for this
}

function doMove(piece, move) {
  const mover = state.pieces.find(p => p.id === piece.id);
  const from = { x:mover.x, y:mover.y };
  let text = `${SIDE_NAME[mover.side]} ${PIECES[mover.type].label}`;

  const victim = pieceAt(move.x, move.y);
  if (victim) { remove(victim); text += ` takes ${PIECES[victim.type].label}`; }
  else text += ' moves';

  mover.x = move.x; mover.y = move.y;
  if (effectFor(mover, move.x, move.y) === 'rough') text += ' — and is held there';

  lastMove = { from, to:{ x:move.x, y:move.y } };
  state.message = text;
}

function doShot(piece, target) {
  const shooter = state.pieces.find(p => p.id === piece.id);
  const victim = pieceAt(target.x, target.y);
  remove(victim);
  lastMove = { from:{ x:shooter.x, y:shooter.y }, to:target };
  // he never steps onto the square, so there is nobody there to fall with
  state.message = `${SIDE_NAME[shooter.side]} Balestriere shoots ${PIECES[victim.type].label}`;
}


/* True if any piece of the side to move still has something it can do.
   Without this the turn stalls whenever a side has fewer usable pieces
   than it has commands. */
function sideHasAction(side) {
  return state.pieces.some(p =>
    p.side === side &&
    !state.acted.includes(p.id) &&
    (legalMoves(p).length > 0 || shots(p).length > 0));
}

function playerAction(piece, action) {
  history.push({ state:clone(state), lastMove });
  if (action.kind === 'shot') doShot(piece, action); else doMove(piece, action);

  state.acted.push(piece.id);
  state.commands--;

  arrivals();                                  // a death may have called someone up
  const fail = checkFailure();
  if (map.objective.type === 'muster' || map.objective.type === 'clear') {
    if (checkObjective()) { finish('won', 'The contract is fulfilled.'); return; }
  }
  if (fail) { finish('lost', fail); return; }

  if (state.commands <= 0 || !sideHasAction(PLAYER)) endPlayerTurn();
}

/*  Men who come up later. A wave arrives either on a given turn, or the
    moment a named man of theirs falls — kill their captain and his reserve
    is on the road behind him. Each wave comes up once.                   */
function arrivals() {
  (map.reinforcements || []).forEach((r, i) => {
    if (state.arrived.includes(i)) return;
    const due = (r.turn !== undefined && state.turnNumber >= r.turn)
             || (r.whenKilled && state.slain.includes(r.whenKilled));
    if (!due) return;

    const names = [];
    for (const p of r.pieces) {
      if (pieceAt(p.x, p.y)) continue;
      state.pieces.push({ id: state.nextId++, routeStep:0, awake:false, ...p });
      names.push(PIECES[p.type].label);
    }
    state.arrived.push(i);
    if (names.length) {
      state.message = r.text
        || (names.join(' and ') + (r.pieces[0].side === PLAYER
              ? ' rides up at the rear' : ' comes up on their side'));
    }
  });
}

function endPlayerTurn() {
  if (state.over) return;
  resolveEndOfPlayerTurn();
  if (state.over) return;

  state.turn = FOE;
  state.commands = map.commands[FOE];
  state.acted = [];
  selected = null;
  render();
  busy = true;
  setTimeout(enemyStep, 420);
}

/* ============================================================
   THE ENEMY
   Deterministic by construction: every candidate action is scored,
   ties broken by a fixed key. No randomness anywhere. (Story F6)
   ============================================================ */

function nearestPlayer(piece) {
  let best = null, bestD = Infinity;
  for (const p of state.pieces) {
    if (p.side !== FOE) {
      const d = chebyshev(piece, p);
      if (d < bestD || (d === bestD && best && (p.y < best.y || (p.y === best.y && p.x < best.x)))) {
        best = p; bestD = d;
      }
    }
  }
  return best;
}

/*  They only react to what is close to them. Outside his alert distance a
    man simply stands his ground — no marching across an empty field to
    meet you, and no waiting through turns of nothing happening.        */
const ALERT = 3;
const alertOf = p => p.alert || p.trigger || ALERT;

function isAlert(piece) {
  const near = nearestPlayer(piece);
  return !!near && chebyshev(piece, near) <= alertOf(piece);
}

function wake(piece) {
  if (piece.behaviour !== 'hold' || piece.awake) return;
  if (isAlert(piece)) piece.awake = true;
}

/* Patrols walk their route before commands are spent — they're on rails,
   part of the map rather than a decision. */
function movePatrols() {
  for (const p of state.pieces.filter(q => q.side === FOE && q.behaviour === 'patrol')) {
    const route = p.route || [];
    if (!route.length) continue;
    const next = route[(p.routeStep + 1) % route.length];
    const occ = pieceAt(next[0], next[1]);
    if (occ) continue;                       // blocked: wait, don't reroute
    p.routeStep = (p.routeStep + 1) % route.length;
    p.x = next[0]; p.y = next[1];
  }
}

function enemyCandidates() {
  const out = [];
  for (const p of state.pieces) {
    if (p.side !== FOE) continue;
    if (state.acted.includes(p.id)) continue;
    if (p.behaviour === 'patrol') continue;
    wake(p);

    for (const sh of shots(p)) {
      const target = pieceAt(sh.x, sh.y);
      const victim = PIECES[target.type].value;
      out.push({ piece:p, action:{ ...sh, kind:'shot' }, score: 1000 + victim });
    }
    for (const m of legalMoves(p)) {
      if (m.capture) {
        const victim = PIECES[pieceAt(m.x, m.y).type].value;
        const target = pieceAt(m.x, m.y);
        out.push({ piece:p, action:{ ...m, kind:'move' }, score: 1000 + victim });
      } else if (p.behaviour === 'charge' || (p.behaviour === 'hold' && p.awake)) {
        if (!isAlert(p)) continue;             // too far off to have noticed you
        const near = nearestPlayer(p);
        if (!near) continue;
        const after = Math.max(Math.abs(m.x - near.x), Math.abs(m.y - near.y));
        // they advance together — a man alone is a man taken
        let mates = 0;
        for (const [ax, ay] of ALL8) {
          const q = pieceAt(m.x + ax, m.y + ay);
          if (q && q.side === FOE && q.id !== p.id) mates++;
        }
        out.push({ piece:p, action:{ ...m, kind:'move' },
                   score: 100 - after * 2 + Math.min(mates, 2) * 3 });
      }
      // 'guard' and sleeping 'hold' never make a plain move
    }
  }
  // fixed ordering: score, then piece id, then destination
  out.sort((a, b) =>
    b.score - a.score ||
    a.piece.id - b.piece.id ||
    a.action.y - b.action.y ||
    a.action.x - b.action.x);
  return out;
}

function enemyStep() {
  if (state.over) { busy = false; render(); return; }

  if (state.commands === map.commands[FOE]) movePatrols();

  const candidates = enemyCandidates();
  if (!candidates.length || state.commands <= 0) {
    // enemy turn over
    state.turnNumber++;
    state.turn = PLAYER;
    state.commands = map.commands[PLAYER];
    state.acted = [];
    busy = false;
    arrivals();

    const fail = checkFailure();
    if (fail) finish('lost', fail);
    render();
    return;
  }

  const best = candidates[0];
  if (best.action.kind === 'shot') doShot(best.piece, best.action);
  else doMove(best.piece, best.action);

  state.acted.push(best.piece.id);
  state.commands--;
  arrivals();

  const fail = checkFailure();
  if (fail) { finish('lost', fail); busy = false; render(); return; }

  render();
  setTimeout(enemyStep, 420);
}

/* ============================================================
   MAP VALIDATION (story E3)
   ============================================================ */

function validateMap() {
  const issues = [];
  map.terrain.forEach((row, y) => {
    if (row.length !== map.width) issues.push(`Row ${y} is ${row.length} tiles, expected ${map.width}`);
  });
  if (map.terrain.length !== map.height) issues.push(`Map has ${map.terrain.length} rows, expected ${map.height}`);

  for (const p of state.pieces) {
    if (!inBounds(p.x, p.y)) { issues.push(`${p.type} is off the board at ${p.x},${p.y}`); continue; }
    if (effectFor(p, p.x, p.y) === 'blocked') {
      issues.push(`${PIECES[p.type].label} starts on ${tileAt(p.x,p.y).name || 'void'} at ${p.x},${p.y}`);
    }
    if (p.behaviour === 'patrol') {
      for (const [x, y] of (p.route || [])) {
        if (!inBounds(x, y) || effectFor(p, x, y) === 'blocked') {
          issues.push(`Patrol route crosses impassable ground at ${x},${y}`);
        }
      }
    }
  }
  const o = map.objective;
  if (o.tiles) for (const [x, y] of o.tiles) {
    if (!inBounds(x, y)) issues.push(`Objective tile ${x},${y} is off the board`);
  }
  if (map.deployment && map.deployment.region.length < map.deployment.floor) {
    issues.push('Deployment zone is smaller than the force floor');
  }

  if (typeof document !== 'undefined') {
    const box = document.getElementById('issues-block');
    if (box) {
      document.getElementById('issues').innerHTML = issues.join('<br>');
      box.style.display = issues.length ? 'block' : 'none';
    }
  }
  return issues;
}



/* ============================================================
   THE PURE INTERFACE

   Everything above works on module-level `map`, `state` and `WALLS`,
   because that is how the game itself runs. The solver cannot live like
   that — it holds thousands of positions at once.

   So the whole engine is wrapped: every call below takes a state, swaps
   it in, runs the very same code the game runs, and hands back a fresh
   one. Slower than a purpose-built search engine, and worth it: there is
   exactly one implementation of the rules, so the solver can never drift
   away from the game it is measuring.
   ============================================================ */

const clone2 = s => JSON.parse(JSON.stringify(s));

function mount(m, st) { map = m; loadWalls(m.walls); state = st; }

/* A fresh game, ready for the player's first command. */
function initialState(m) {
  map = m; loadWalls(m.walls);
  state = newState();
  arrivals();
  return clone2(state);
}

/* Every command the side to move could spend right now. */
function actions(m, st) {
  mount(m, st);
  const out = [];
  for (const p of state.pieces) {
    if (p.side !== state.turn || state.acted.includes(p.id)) continue;
    for (const mv of legalMoves(p)) out.push({ id:p.id, kind:'move', x:mv.x, y:mv.y, leg:mv.leg });
    for (const sh of shots(p))      out.push({ id:p.id, kind:'shot', x:sh.x, y:sh.y });
  }
  return out;
}

/* Resolve the enemy's whole turn the way the game does, without the clock. */
function runEnemyTurn() {
  let guard = 0;
  movePatrols();
  while (state.commands > 0 && guard++ < 40) {
    const cands = enemyCandidates();
    if (!cands.length) break;
    const b = cands[0];
    if (b.action.kind === 'shot') doShot(b.piece, b.action); else doMove(b.piece, b.action);
    state.acted.push(b.piece.id);
    state.commands--;
    arrivals();
    const fail = checkFailure();
    if (fail) { finish('lost', fail); return; }
  }
  state.turnNumber++;
  state.turn = PLAYER;
  state.commands = map.commands[PLAYER];
  state.acted = [];
  arrivals();
  const fail = checkFailure();
  if (fail) finish('lost', fail);
}

/*  Spend one command. If that empties the turn — or leaves nobody able to
    act — the turn resolves and the enemy takes theirs, so the state handed
    back is always one the player may move in (or a finished game).       */
function apply(m, st, action) {
  mount(m, clone2(st));
  const piece = state.pieces.find(p => p.id === action.id);
  if (!piece) throw new Error('no such piece: ' + action.id);

  if (action.kind === 'shot') doShot(piece, action); else doMove(piece, action);
  state.acted.push(action.id);
  state.commands--;
  arrivals();

  /*  Mirror playerAction exactly: a Clear or Muster is checked after every
      command, but Hold is only ever counted once, at the end of the turn.
      Checking it per command ticks the counter three times a turn and the
      solver reports a one-turn win on a two-turn hold.                   */
  if (!state.over) {
    if (map.objective.type === 'muster' || map.objective.type === 'clear') {
      if (checkObjective()) finish('won', 'The contract is fulfilled.');
    }
    if (!state.over) {
      const fail = checkFailure();
      if (fail) finish('lost', fail);
    }
  }
  if (!state.over && (state.commands <= 0 || !sideHasAction(PLAYER))) {
    if (checkObjective()) finish('won', 'The contract is fulfilled.');
    if (!state.over) {
      const fail = checkFailure();
      if (fail) finish('lost', fail);
    }
    if (!state.over) {
      state.turn = FOE;
      state.commands = map.commands[FOE];
      state.acted = [];
      runEnemyTurn();
    }
  }
  return clone2(state);
}

/* Pass the rest of the turn without spending it. */
function pass(m, st) {
  mount(m, clone2(st));
  if (checkObjective()) { finish('won', 'The contract is fulfilled.'); return clone2(state); }
  const fail = checkFailure();
  if (fail) { finish('lost', fail); return clone2(state); }
  state.turn = FOE;
  state.commands = map.commands[FOE];
  state.acted = [];
  runEnemyTurn();
  return clone2(state);
}

const outcome = st => st.over || 'playing';
const lossCount = (st, side) => st.taken.filter(t => t.side === side).length;

/*  Two positions are the same position if the same men stand in the same
    places with the same orders, the same waves have come up and the same
    objective progress has been made. Which command order got you there
    does not matter — and that is what makes the search tractable.       */
function hash(st) {
  const men = st.pieces
    .map(p => [p.type, p.side, p.x, p.y, p.behaviour || '-', p.awake ? 1 : 0,
               p.routeStep || 0, p.key || '-'].join(':'))
    .sort().join('|');
  return [st.turnNumber, st.turn, st.commands,
          st.acted.slice().sort().join(','), st.holdCount,
          st.arrived.slice().sort().join(','), men].join('#');
}

/* Same, but ignoring how far through a turn we are — for end-of-turn work. */
function turnHash(st) {
  const men = st.pieces
    .map(p => [p.type, p.side, p.x, p.y, p.behaviour || '-', p.awake ? 1 : 0,
               p.routeStep || 0, p.key || '-'].join(':'))
    .sort().join('|');
  return [st.turnNumber, st.holdCount, st.arrived.slice().sort().join(','), men].join('#');
}

/* Read-only helpers the solver and the tests want. */
function inspect(m, st) {
  mount(m, st);
  return {
    immune:    state.pieces.filter(p => isImmune(p)).map(p => p.id),
    danger:    [...threatTiles(FOE).keys()],
    objective: objectiveProgress(),
    wading:    state.pieces.filter(p => inMire(p)).map(p => p.id)
  };
}

const ENGINE = {
  MAPS: (typeof MAPS !== 'undefined' ? MAPS : []),
  TERRAIN, PIECES, PLAYER, FOE, SIDE_NAME,
  rect, wallRect, gateAt,
  initialState, actions, apply, pass, outcome, lossCount,
  hash, turnHash, inspect,
  // for tests that want to poke the raw rules
  _mount: mount,
  _raw: () => ({ legalMoves, shots, arcOf, isImmune, attackSquares, defendersOf, wouldBeExposed,
                 inMire, canBeTaken, checkObjective, checkFailure, enemyCandidates,
                 movePatrols, doMove, doShot, validateMapData: validateMap,
                 get state() { return state; }, get map() { return map; } })
};

if (typeof module !== 'undefined' && module.exports) module.exports = ENGINE;
if (typeof window !== 'undefined') window.ENGINE = ENGINE;
