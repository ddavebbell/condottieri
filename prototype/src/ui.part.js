/* ---------- art ----------
   Pieces with a drawing show it on a coloured base; the rest keep their glyph
   until their art arrives. Marble picks one of nine slabs, fixed per square. */
const ART = new Set(['fante', 'cavaliere', 'lanciere', 'balestriere', 'condottiero', 'carro']);
function pieceClass(type, side) {
  return 'piece p-' + side + (ART.has(type) ? ' art k-' + type : '');
}
function slab(x, y) {
  let h = Math.imul(x, 374761393) + Math.imul(y, 668265263);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  const n = ((h ^ (h >>> 16)) >>> 0) % 9 + 1;
  return n === 1 ? '' : ' v' + n;
}

/* ============================================================
   RENDER
   ============================================================ */

const boardEl = document.getElementById('board');
const tiles = [];

/*  Size the tiles so the whole board is on screen at once — no scrolling,
    no pinching. Leaves room for the panel underneath on a phone.        */
function fitBoard() {
  if (!map) return;
  const narrow = window.innerWidth <= 760;
  const availW = Math.min(window.innerWidth - (narrow ? 18 : 40), 560);
  const availH = window.innerHeight - (narrow ? 290 : 90);
  const t = Math.max(26, Math.min(48, Math.floor(Math.min(availW / map.width, availH / map.height))));
  document.documentElement.style.setProperty('--tile', t + 'px');
  boardEl.style.gridTemplateColumns = `repeat(${map.width}, ${t}px)`;
}
window.addEventListener('resize', fitBoard);
window.addEventListener('orientationchange', () => setTimeout(fitBoard, 120));

function buildBoard() {
  boardEl.innerHTML = '';
  tiles.length = 0;
  fitBoard();
  for (let y = 0; y < map.height; y++) {
    for (let x = 0; x < map.width; x++) {
      const el = document.createElement('div');
      el.className = 'tile';
      el.addEventListener('click', () => onTileClick(x, y));
      boardEl.appendChild(el);
      tiles.push(el);
    }
  }
}
const tileEl = (x, y) => tiles[y * map.width + x];

const el = id => document.getElementById(id);

function render() {
  const moves = selected ? legalMoves(selected) : [];
  const shotList = selected ? shots(selected) : [];
  const threats = el('threat').checked ? threatTiles(FOE) : new Map();
  const faces = el('faces').checked;
  const goal = map.objective.tiles || [];
  const routes = new Set();
  for (const p of state.pieces) {
    if (p.side === FOE && p.behaviour === 'patrol') {
      for (const [x, y] of (p.route || [])) routes.add(x + ',' + y);
    }
  }

  for (let y = 0; y < map.height; y++) {
    for (let x = 0; x < map.width; x++) {
      const t = tileEl(x, y);
      const terrain = tileAt(x, y);
      let cls = 'tile ' + terrain.css;
      if (terrain.css === 't-open' && (x + y) % 2 === 1) cls += ' alt';
      if (terrain.css === 't-marble') cls += slab(x, y);

      const piece = pieceAt(x, y);
      const move = moves.find(m => m.x === x && m.y === y);
      const shot = shotList.find(s => s.x === x && s.y === y);

      if (inRegion(goal, x, y)) cls += ' goal';
      if (routes.has(x + ',' + y)) cls += ' route';
      if (piece && piece.side === PLAYER && threats.has(x + ',' + y)) cls += ' threat';
      if (selected && selected.x === x && selected.y === y) cls += ' selected';
      if (move) {
        const risky = wouldBeExposed(selected, x, y);
        cls += (move.capture ? ' capture' : ' move') + (risky ? ' exposed' : '');
      }
      if (shot) cls += ' shot';
      if (lastMove && lastMove.from.x === x && lastMove.from.y === y) cls += ' origin';
      if (!busy && !state.over && (move || shot || (piece && canAct(piece)))) cls += ' selectable';

      t.className = cls;
      const untouchable = piece && faces && isImmune(piece);
      let inner = terrain.void ? '' : '<span class="ground"></span>';
      if (untouchable) inner += '<span class="glow discipline"></span><span class="ring"></span>';
      if (piece && inMire(piece)) inner += '<span class="wading"></span>';
      if (piece) {
        const dim = (canAct(piece) || piece.side === FOE) ? '' : ' spent';
        inner += `<span class="${pieceClass(piece.type, piece.side)}${dim}${untouchable ? ' guarded' : ''}">${PIECES[piece.type].glyph}</span>`;
      }
      for (const [dx, dy, k] of [[0,-1,'n'],[0,1,'s'],[-1,0,'w'],[1,0,'e']]) {
        if (walled(x, y, x + dx, y + dy)) inner += `<span class="wall w-${k}"></span>`;
      }

      t.innerHTML = inner;
      t.title = piece
        ? `${PIECES[piece.type].label} (${SIDE_NAME[piece.side]})${piece.side === FOE ? ' — ' + (piece.behaviour === 'hold' ? (piece.awake ? 'charging' : 'waiting') : piece.behaviour) : ''}`
        : terrain.name;
    }
  }

  el('obj-what').textContent = objectiveText();
  el('obj-prog').textContent = objectiveProgress();

  if (state.over) {
    el('side').textContent = state.over === 'won' ? 'Contract fulfilled' : 'Contract failed';
    el('side').className = 'side';
    el('pips').textContent = '';
  } else {
    el('side').textContent = state.turn === PLAYER ? 'Your move' : 'They are moving';
    el('side').className = 'side ' + state.turn;
    el('pips').innerHTML = '●'.repeat(Math.max(0, state.commands))
      + `<span class="used">${'●'.repeat(Math.max(0, map.commands[state.turn] - state.commands))}</span>`;
  }
  el('count').textContent = `Turn ${Math.min(state.turnNumber, map.turnLimit)} of ${map.turnLimit}`;
  el('log').textContent = state.message;

  el('taken').innerHTML = state.taken.length
    ? state.taken.map(p => `<span class="${pieceClass(p.type, p.side)} small" style="font-size:20px">${PIECES[p.type].glyph}</span>`).join(' ')
    : '<span class="none">Nothing yet</span>';

  el('undo').disabled = busy || !!state.over || history.length === 0;
  el('endturn').disabled = busy || !!state.over || state.turn !== PLAYER;

  [...el('missions').children].forEach((b, i) => b.className = i === mapIndex ? 'on' : '');

  if (state.over) showResult();
}

/* ============================================================
   OVERLAYS
   ============================================================ */

function showBriefing() {
  el('ov-title').textContent = map.name;
  el('ov-title').className = '';
  el('ov-text').textContent = map.problem || map.brief;
  el('ov-teaches').textContent = map.teaches;
  el('ov-obj').textContent = objectiveText();
  el('ov-btn').textContent = 'Begin';
  el('ov-btn').onclick = () => el('overlay').classList.add('hidden');
  el('overlay').classList.remove('hidden');
}

/* The line the map was built around. For design work, not for the player. */
function showSolution() {
  el('hint').textContent = el('hint').textContent ? '' : (map.solution || '');
}

function showResult() {
  el('ov-title').textContent = state.over === 'won' ? 'Contract fulfilled' : 'Contract failed';
  el('ov-title').className = state.over === 'won' ? 'won' : 'lost';
  el('ov-text').textContent = state.reason;
  el('ov-teaches').textContent = '';
  el('ov-obj').textContent = '';
  el('ov-btn').textContent = state.over === 'won' && mapIndex < MAPS.length - 1 ? 'Next engagement' : 'Retry';
  el('ov-btn').onclick = () => {
    if (state.over === 'won' && mapIndex < MAPS.length - 1) loadMap(mapIndex + 1);
    else loadMap(mapIndex);
  };
  el('overlay').classList.remove('hidden');
}

/* ============================================================
   INPUT
   ============================================================ */

function onTileClick(x, y) {
  if (busy || state.over || state.turn !== PLAYER) return;

  if (selected) {
    const shot = shots(selected).find(s => s.x === x && s.y === y);
    if (shot) { playerAction(selected, { ...shot, kind:'shot' }); selected = null; render(); return; }
    const move = legalMoves(selected).find(m => m.x === x && m.y === y);
    if (move) { playerAction(selected, { ...move, kind:'move' }); selected = null; render(); return; }
  }

  const piece = pieceAt(x, y);

  selected = (piece && canAct(piece)) ? piece : null;
  render();
}

el('endturn').addEventListener('click', () => { if (!busy) { endPlayerTurn(); render(); } });

el('undo').addEventListener('click', () => {
  if (busy || !history.length) return;
  const prev = history.pop();
  state = prev.state;
  lastMove = prev.lastMove;
  selected = null;
  render();
});

el('restart').addEventListener('click', () => loadMap(mapIndex));
el('hintbtn').addEventListener('click', showSolution);
document.querySelectorAll('.texrow button').forEach(b => b.addEventListener('click', () => {
  document.documentElement.style.setProperty('--tex', b.dataset.tex);
  document.querySelectorAll('.texrow button').forEach(o => o.className = '');
  b.className = 'on';
}));
el('threat').addEventListener('change', render);
el('faces').addEventListener('change', render);

document.addEventListener('keydown', e => {
  if (busy) return;
  if (e.key === 'u') el('undo').click();
  if (e.key === 'r') el('restart').click();
  if (e.key === 'e') el('endturn').click();
  if (e.key === 'Escape') { selected = null; render(); }
});

/* ============================================================
   THE RULES CARD

   Every diagram below is played out on a real board by the real engine:
   the glows, the covered squares, the legal moves and the verdicts are
   all computed, not drawn. If a rule changes, the chart changes with it
   and it cannot quietly start lying.
   ============================================================ */

const MINI  = { p:'♟', l:'♝', r:'♜', n:'♞', b:'✦', q:'♛' };
const MTYPE = { p:'fante', l:'lanciere', r:'carro', n:'cavaliere', b:'balestriere', q:'condottiero' };

/* Set up a scratch board, ask the engine something, put everything back. */
function withMini(c, fn) {
  const saveMap = map, saveState = state, saveWalls = WALLS;
  const rows = c.rows, h = rows.length, w = rows[0].length;
  map = {
    width: w, height: h, turnLimit: 9,
    commands: { rosso:3, azzurro:2 }, objective: { type:'clear' },
    terrain: c.ground || rows.map(() => '.'.repeat(w))
  };
  WALLS = new Set((c.walls || []).map(q => wallKey(q[0][0], q[0][1], q[1][0], q[1][1])));
  state = { pieces: [], turn: PLAYER, turnNumber: 1, commands: 3,
            acted: [], taken: [], holdCount: 0, over: null, message: '' };
  let id = 0;
  rows.forEach((row, y) => [...row].forEach((ch, x) => {
    if (ch === '.') return;
    state.pieces.push({ id: id++, type: MTYPE[ch.toLowerCase()],
                        side: ch === ch.toUpperCase() ? PLAYER : FOE, x, y });
  }));
  const out = fn(state.pieces);
  map = saveMap; state = saveState; WALLS = saveWalls;
  return out;
}

function drawCase(c) {
  const w = c.rows[0].length;

  const data = withMini(c, pieces => {
    const glow = pieces.filter(p => isDefended(p)).map(p => p.x + ',' + p.y);
    let dots = [], verdict = null;
    const from = c.from && pieces.find(p => p.x === c.from[0] && p.y === c.from[1]);

    if (c.show === 'cover' && from) dots = attackSquares(from).map(t => t.x + ',' + t.y);
    if (c.show === 'moves' && from) dots = legalMoves(from).map(t => t.x + ',' + t.y);
    if (c.show === 'alert' && from) {
      for (let y = 0; y < c.rows.length; y++) for (let x = 0; x < w; x++)
        if (Math.max(Math.abs(x - from.x), Math.abs(y - from.y)) <= 3 && !(x === from.x && y === from.y))
          dots.push(x + ',' + y);
    }
    if (c.mark) {
      const [tx, ty] = c.mark;
      const target = pieceAt(tx, ty);
      const killer = pieces.find(p => p.side === PLAYER &&
        (legalMoves(p).some(m => m.x === tx && m.y === ty) ||
         shots(p).some(t => t.x === tx && t.y === ty)));
      if (!killer) verdict = 'none';
      else verdict = 'free';
    }
    return { glow, dots, verdict, ground: map.terrain, walls: new Set(WALLS) };
  });

  let html = '<div class="case"><div class="mini" style="grid-template-columns:repeat(' + w + ',34px)">';
  c.rows.forEach((row, y) => {
    [...row].forEach((ch, x) => {
      const g = (c.ground ? c.ground[y][x] : '.');
      const t = TERRAIN[g] || TERRAIN['.'];
      let cls = 'cell ' + t.css + ((x + y) % 2 && t.css === 't-open' ? ' alt' : '') + (t.css === 't-marble' ? slab(x, y) : '');
      if (c.mark && c.mark[0] === x && c.mark[1] === y)
        cls += data.verdict === 'free' ? ' hit' : ' deny';
      html += `<div class="${cls}">`;
      for (const [dx, dy, k] of [[0,-1,'n'],[0,1,'s'],[-1,0,'w'],[1,0,'e']])
        if (data.walls.has(wallKey(x, y, x + dx, y + dy))) html += `<span class="mwall mw-${k}"></span>`;
      if (data.glow.includes(x + ',' + y)) html += '<span class="g"></span>';
      if (data.dots.includes(x + ',' + y)) html += '<span class="cov"></span>';
      const pc = MINI[ch.toLowerCase()];
      if (pc) html += `<span class="pc p-${ch === ch.toUpperCase() ? 'rosso' : 'azzurro'}${ART.has(MTYPE[ch.toLowerCase()]) ? ' art k-' + MTYPE[ch.toLowerCase()] : ''}">${pc}</span>`;
      html += '</div>';
    });
  });
  html += '</div>';
  if (c.mark) {
    const v = data.verdict;
    const free = v === 'free';
    const label = free ? 'The kill is available' : 'They cannot touch him';
    html += `<div class="verdict ${free ? 'yes' : 'no'}">${label}</div>`;
  }
  html += `<p>${c.text}</p></div>`;
  return html;
}

const CASES = [
  { h: 'The discipline', id: 'discipline',
    note: 'The only shelter in the game. Where one of your men stands beside a Lanciere, a Balestriere or your Condottiero, the enemy cannot take him at all. A gold ring marks it. Nothing else on the board shelters anything, and killing never costs you the killer.' },
  { rows: ['p..','.P.','...'], mark:[1,1],
    text:'Your footman on his own. Their footman takes him from the corner and walks away.' },
  { rows: ['p..','.P.','L..'], mark:[1,1],
    text:'Now your lanciere stands on his corner. That attack is not available to them at all. This is the shape the whole company is built around.' },
  { rows: ['p..','.P.','..P'], mark:[1,1],
    text:'A second footman is not an anchor. Only the Lanciere and your Condottiero hold anything, so your man is still open.' },
  { rows: ['p..','.P.','.B.'], mark:[1,1],
    text:'Nor is your own crossbowman. He is the answer to <i>their</i> formations, not the foundation of yours.' },
  { rows: ['.p.','l.P'], mark:[1,0],
    text:'And it is yours alone. Their lanciere holds nothing up — take their footman and your man walks away as usual.' },

  { h: 'What the anchors hold', id: 'covers',
    note: 'An anchor holds the neighbouring squares it could strike, and nothing further. Dotted tiles are what it holds — a lanciere threatens the length of his diagonal but only holds the four corners he touches.' },
  { rows: ['.....','.....','..L..','.....','.....'], show:'cover', from:[2,2],
    text:'<b>Lanciere.</b> Four corners. A man standing square beside him gets nothing.' },
  { rows: ['.....','.....','..Q..','.....','.....'], show:'cover', from:[2,2],
    text:'<b>Condottiero.</b> All eight, and he takes no man. He commands and he anchors — that is his whole worth, and losing him still ends the contract.' },
  { rows: ['.....','.....','..B..','.....','.....'], show:'cover', from:[2,2],
    text:'<b>Balestriere.</b> Nothing. He is the piece that goes through a formation, so he cannot be the thing holding one up.' },

  { h: 'Forming up', id: 'formations',
    note: 'Anchors are few and each holds a handful of squares, so you cannot shelter everybody at once. Choosing who is covered while you advance is the game.' },
  { rows: ['P.P','.L.','P.P'],
    text:'<b>Four on the corners.</b> A lanciere at full stretch: all four untouchable, and the lanciere himself is not.' },
  { rows: ['PPP','.L.'],
    text:'<b>A rank in front of him.</b> Only the two on the corners glow. The man square in front of the lanciere is open — the commonest mistake on the board.' },
  { rows: ['PPP','PQP','PPP'],
    text:'<b>Around the captain.</b> He holds all eight, so the whole cluster is untouchable. Slow, and it walks your captain into reach of their horse.' },
  { rows: ['P..','.N.'],
    text:'<b>The horse can be sheltered too.</b> He anchors nobody himself, but land him on a corner your lanciere holds and the raider survives the raid.' },

  { h: 'What gets through', id: 'breaking',
    note: 'Two things ignore the discipline entirely. Watch these and nothing else on the board can hurt you.' },
  { rows: ['b..','.P.','L..'], mark:[1,1],
    text:'<b>The bolt.</b> He never steps onto the square, so no discipline puts a man in his way.' },
  { rows: ['....','..P.','...L','.n..'], mark:[2,1],
    text:'<b>The charge.</b> A horse crashes past an anchor as if it were not there.' },
  { rows: ['....','..P.','.L..','.n..'], mark:[2,1],
    text:'<b>Hobbling him.</b> His charge starts with one step sideways. Put a body on that step and the horse cannot move at all — here your own lanciere blocks his leg.' },

  { h: 'Ground', id: 'ground',
    note: 'Dotted tiles are where this man may go. Terrain reads differently depending on who is walking on it.' },
  { rows: ['....','....','..R.','....'], ground:['....','.ff.','....','....'], show:'moves', from:[2,2],
    text:'<b>Carro.</b> He cannot enter a wood at all. Wheels and trees do not agree.' },
  { rows: ['....','....','..L.','....'], ground:['....','.ff.','....','....'], show:'moves', from:[2,2],
    text:'<b>Lanciere in a wood.</b> He may enter, but entering ends his move — he stops on the first tree.' },
  { rows: ['.....','.....','..P..','.....'], ground:['.....','~~~~~','.....','.....'], show:'moves', from:[2,2],
    text:'<b>Foot wades.</b> A footman may cross the river, and stops in it. Everything else must find a bridge.' },
  { rows: ['.....','.....','..N..','.....'], ground:['.....','~~~~~','.....','.....'], show:'moves', from:[2,2],
    text:'<b>The horse will not.</b> Water stops him dead, both to stand in and to leap across.' },
  { rows: ['.....','.....','..N..','.....'], ground:['.....','.###.','.....','.....'], show:'moves', from:[2,2],
    text:'<b>But he leaps rock.</b> The only piece that ignores a boulder in his way.' },
  { rows: ['.....','.....','..Q..','.....','.....'], ground:['.....','.....','~~~~~','.....','.....'], show:'moves', from:[2,2],
    text:'<b>Wading.</b> Your captain in the river may move a single square, in any direction, until he is out. A river costs two turns, not one.' },
  { rows: ['.....','.....','..Q..','.....','.....'], show:'moves', from:[2,2],
    text:'<b>The same captain on dry ground.</b> The difference is the whole reason a crossing is dangerous.' },
  { rows: ['...','.R.','...'], walls:[[[1,1],[1,0]]], show:'moves', from:[1,1],
    text:'<b>A wall.</b> It sits on the border rather than eating a tile, and nothing crosses it — man, horse or bolt.' },

  { h: 'Their orders', id: 'orders' },
  { rows: ['.......','.......','.......','...n...','.......','.......','.......'], show:'alert', from:[3,3],
    text:'<b>Charge.</b> He notices you within three tiles and comes on. Outside that ring he stands where he is.' },
  { rows: ['.....','..p..','.....'], show:'cover', from:[2,1],
    text:'<b>Guard.</b> He never leaves his tile. He will kill what walks into the squares he covers, and nothing else.' },
  { rows: ['.....','.....','.....'],
    text:'<b>Patrol.</b> He walks a fixed loop, drawn on the board as blue dots. You can always see where he will be next turn.' }
];

function buildRules() {
  let html = '', open = false;
  for (const c of CASES) {
    if (c.h) {
      if (open) html += '</div>';
      html += `<h3 id="rx-${c.id}">${c.h}</h3>`;
      if (c.note) html += `<p class="note">${c.note}</p>`;
      html += '<div class="cases">';
      open = true;
    } else html += drawCase(c);
  }
  if (open) html += '</div>';
  el('rules-body').innerHTML = html;
}

function openRules(anchor) {
  buildRules();
  el('rules').classList.remove('hidden');
  const target = anchor && document.getElementById('rx-' + anchor);
  el('rules').scrollTop = 0;
  if (target) target.scrollIntoView({ block: 'start' });
}

el('rulesbtn').addEventListener('click', () => openRules());
el('rules-close').addEventListener('click', () => el('rules').classList.add('hidden'));
document.querySelectorAll('[data-rules]').forEach(a =>
  a.addEventListener('click', () => openRules(a.getAttribute('data-rules'))));

MAPS.forEach((m, i) => {
  const b = document.createElement('button');
  b.textContent = i + 1;
  b.title = m.name;
  b.onclick = () => loadMap(i);
  el('missions').appendChild(b);
});

loadMap(0);
