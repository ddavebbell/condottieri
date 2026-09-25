/*  Step 5, in miniature: replay a winning line and see which of the game's
    mechanics it actually touches. A map can claim to teach anything; this
    says what the win really needed.                                      */
const { E, enumerateTurnBeam, foesOutstanding } = require('./lib.js');

function scorer(m) {
  const cache = new WeakMap();
  return (mm, s) => {
    if (cache.has(s)) return cache.get(s);
    let v;
    if (s.over === 'won') v = 1e7 - s.turnNumber;
    else if (s.over === 'lost') v = -1e7;
    else {
      const mine = s.pieces.filter(p => p.side === E.PLAYER);
      v = -foesOutstanding(m, s) * 3000 + mine.length * 300;
      let d = 0; const goal = m.objective.tiles;
      if (goal && goal.length) for (const p of mine) { let b=99;
        for (const t of goal) b = Math.min(b, Math.max(Math.abs(p.x-t[0]), Math.abs(p.y-t[1]))); d += Math.min(b,12); }
      else { const th = s.pieces.filter(p=>p.side===E.FOE);
        for (const p of mine) { let b=99;
          for (const q of th) b = Math.min(b, Math.max(Math.abs(p.x-q.x), Math.abs(p.y-q.y))); d += Math.min(b,10); } }
      v -= d*22;
      if (m.objective.type==='hold') v += (s.holdCount||0)*6000;
      if (m.objective.type==='muster') v += mine.filter(p=>goal.some(t=>t[0]===p.x&&t[1]===p.y)).length*3000;
    }
    cache.set(s,v); return v;
  };
}

function winWithStates(m, width, intra) {
  const score = scorer(m);
  let frontier = [E.initialState(m)];
  frontier[0]._line = []; frontier[0]._snap = [];
  for (let turn = 1; turn <= m.turnLimit; turn++) {
    const next = new Map();
    for (const s of frontier) for (const e of enumerateTurnBeam(m, s, intra, score).ends) {
      // a few numbers per turn, never the positions themselves
      const ins = E.inspect(m, e);
      e._snap = (s._snap || []).concat([[ins.immune.length, ins.danger.length, ins.wading.length]]);
      next.set(E.turnHash(e), e);
    }
    const arr = [...next.values()];
    const won = arr.filter(s => s.over === 'won');
    if (won.length) { won.sort((a,b)=>a.turnNumber-b.turnNumber); return won[0]; }
    frontier = arr.filter(s=>!s.over).sort((a,b)=>score(m,b)-score(m,a)).slice(0,width);
    if (!frontier.length) return null;
  }
  return null;
}

function audit(m) {
  const w = winWithStates(m, 24, 10);
  if (!w) return { name: m.name, won: false };
  const snap = w._snap || [];
  let turnsAnchored = 0, everInDanger = 0, waded = 0, shot = 0, charged = 0;
  for (const [imm, dang, wad] of snap) {
    if (imm) turnsAnchored++;
    if (dang) everInDanger++;
    if (wad) waded++;
  }
  for (const step of (w._line || [])) {
    if (/shoots/.test(step)) shot++;
    if (/Cavaliere .*takes/.test(step)) charged++;
  }
  return {
    name: m.name, won: true, turns: w.turnNumber,
    anchoredTurns: turnsAnchored, dangerTurns: everInDanger,
    wadedTurns: waded, shots: shot, charges: charged, states: snap.length,
    lost: w.taken.filter(t=>t.side===E.PLAYER).length,
    killers: [...new Set((w._line||[]).filter(l=>/takes|shoots/.test(l))
              .map(l => l.split(' ')[1]))].join(', ')
  };
}

if (require.main === module) {
  const from=+(process.argv[2]||0), to=+(process.argv[3]||from);
  console.log('map                          turns  anchored  in-danger  waded  bolts  charges  who did the killing');
  for (let i=from;i<=to && i<E.MAPS.length;i++) {
    const a = audit(E.MAPS[i]);
    if (!a.won) { console.log(E.MAPS[i].name.padEnd(28) + '  unsolved'); continue; }
    console.log('%s %s %s %s %s %s %s  %s',
      a.name.padEnd(28), String(a.turns).padStart(5),
      (a.anchoredTurns+'/'+a.states).padStart(9),
      (a.dangerTurns+'/'+a.states).padStart(10),
      String(a.wadedTurns).padStart(6), String(a.shots).padStart(6),
      String(a.charges).padStart(8), a.killers);
  }
}
