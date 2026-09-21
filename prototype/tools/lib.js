/* Shared search machinery. */
const E = require('../src/engine.bundle.js');

/*  Every distinct position reachable by spending one turn's commands.
    The turn is over when the turn counter moves — not when it stops being
    your move, because after they reply it is your move again.           */
function enumerateTurn(m, st, cap = 60000) {
  const start = st.turnNumber;
  const seen = new Set(), ends = new Map();
  const stack = [st];
  let applies = 0, truncated = false;
  while (stack.length) {
    const cur = stack.pop();
    const k = E.hash(cur);
    if (seen.has(k)) continue;
    seen.add(k);
    if (cur.over || cur.turnNumber > start) { ends.set(E.turnHash(cur), cur); continue; }
    const acts = E.actions(m, cur);
    if (!acts.length) { const p = E.pass(m, cur); ends.set(E.turnHash(p), p); continue; }
    for (const a of acts) {
      if (applies++ > cap) { truncated = true; break; }
      stack.push(E.apply(m, cur, a));
    }
    if (truncated) break;
  }
  return { ends: [...ends.values()], applies, inner: seen.size, truncated };
}

/*  The same, but narrowed: at each command keep only the most promising
    partial positions. Cheap enough to run to the turn limit.            */
function enumerateTurnBeam(m, st, width, score) {
  const start = st.turnNumber;
  let level = [st];
  const ends = new Map();
  let applies = 0;
  for (let step = 0; step < 6 && level.length; step++) {
    const next = new Map();
    for (const cur of level) {
      if (cur.over || cur.turnNumber > start) { ends.set(E.turnHash(cur), cur); continue; }
      const acts = E.actions(m, cur);
      const p = E.pass(m, cur);
      p._line = (cur._line || []).concat(['t' + cur.turnNumber + ' hold']);
      ends.set(E.turnHash(p), p);                 // holding back is always allowed
      for (const a of acts) {
        applies++;
        const nx = E.apply(m, cur, a);
        nx._line = (cur._line || []).concat([describe(m, cur, a)]);
        if (nx.over || nx.turnNumber > start) ends.set(E.turnHash(nx), nx);
        else next.set(E.hash(nx), nx);
      }
    }
    level = [...next.values()].sort((a,b) => score(m,b) - score(m,a)).slice(0, width);
  }
  return { ends: [...ends.values()], applies };
}

/* A move, written the way a person would read it back. */
function describe(m, st, a) {
  const p = st.pieces.find(q => q.id === a.id);
  const t = st.pieces.find(q => q.x === a.x && q.y === a.y && q.id !== a.id);
  const verb = a.kind === 'shot' ? 'shoots' : (t ? 'takes' : 'to');
  return 't' + st.turnNumber + ' ' + E.PIECES[p.type].label + ' ' + p.x + ',' + p.y
       + ' ' + verb + ' ' + (t ? E.PIECES[t.type].label + ' at ' : '') + a.x + ',' + a.y;
}

/*  How good does this position look? Used only to steer the beam.
    Cached on the position: sorting asks for it O(n log n) times and the
    inspection behind it is not cheap.                                   */
function makeScore(m) {
  const raw = rawScore(m);
  return (mm, s) => (s._score !== undefined ? s._score : (s._score = raw(mm, s)));
}

/*  How many of theirs you must still put down — counting the waves that
    have not come up yet. Without this, killing a man who summons two more
    looks like a step backwards and the search refuses to take it, which
    is how a perfectly winnable map stalls one kill short.               */
function foesOutstanding(m, s) {
  let n = s.pieces.filter(p => p.side === E.FOE).length;
  (m.reinforcements || []).forEach((r, i) => {
    if (s.arrived.includes(i)) return;
    if (r.pieces[0].side !== E.FOE) return;
    n += r.pieces.length;                    // they are coming either way
  });
  return n;
}

function rawScore(m) {
  const goal = m.objective.tiles || [];
  const centre = goal.length
    ? { x: goal.reduce((a,t)=>a+t[0],0)/goal.length, y: goal.reduce((a,t)=>a+t[1],0)/goal.length }
    : null;
  return (mm, s) => {
    if (s.over === 'won') return 1e6 - s.turnNumber * 100;
    if (s.over === 'lost') return -1e6;
    const mine = s.pieces.filter(p => p.side === E.PLAYER);
    const theirs = s.pieces.filter(p => p.side === E.FOE);
    let v = 0;
    v -= foesOutstanding(m, s) * 170;               // counting the waves still to come
    v += mine.length * 60;                          // so is keeping your own
    v -= s.taken.filter(t => t.side === E.PLAYER).length * 220;
    const ins = E.inspect(mm, s);
    v += ins.immune.length * 14;                    // stay anchored
    v -= ins.danger.length * 22;                    // stay out of reach
    if (m.objective.type === 'hold')   v += s.holdCount * 400;
    if (m.objective.type === 'muster') {
      const n = mine.filter(p => goal.some(t=>t[0]===p.x&&t[1]===p.y)).length;
      v += n * 260;
    }
    if (centre) {                                   // drift toward the objective
      let d = 0;
      for (const p of mine) d += Math.max(Math.abs(p.x-centre.x), Math.abs(p.y-centre.y));
      v -= d * 2.2;
    } else {
      let d = 0;                                    // or toward the nearest enemy
      for (const p of mine) {
        let best = 99;
        for (const q of theirs) best = Math.min(best, Math.max(Math.abs(p.x-q.x), Math.abs(p.y-q.y)));
        d += Math.min(best, 12);
      }
      v -= d * 2.2;
    }
    return v;
  };
}

module.exports = { E, enumerateTurn, enumerateTurnBeam, makeScore, describe, foesOutstanding };
