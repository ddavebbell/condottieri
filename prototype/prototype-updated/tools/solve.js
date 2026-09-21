/*  The beam solver. Finds a win and the line that gets there.
    A result proves the map is winnable; silence proves nothing.   */
const { E, enumerateTurnBeam, makeScore } = require('./lib.js');

function solve(m, opts = {}) {
  const width = opts.width || 24, intra = opts.intra || 10;
  const noLoss = !!opts.noLoss;
  const score = makeScore(m);
  const t0 = Date.now();

  let frontier = [E.initialState(m)];
  frontier[0]._line = [];
  let applies = 0, best = null;

  for (let turn = 1; turn <= m.turnLimit + 1; turn++) {
    const next = new Map();
    for (const s of frontier) {
      const r = enumerateTurnBeam(m, s, intra, score);
      applies += r.applies;
      for (const e of r.ends) {
        if (noLoss && e.taken.some(t => t.side === E.PLAYER)) continue;
        const k = E.turnHash(e);
        if (!next.has(k)) next.set(k, e);
      }
    }
    const arr = [...next.values()];
    const won = arr.filter(s => s.over === 'won');
    if (won.length) {
      won.sort((a,b) => a.turnNumber - b.turnNumber || a._line.length - b._line.length);
      best = won[0];
      break;
    }
    frontier = arr.filter(s => !s.over).sort((a,b) => score(m,b) - score(m,a)).slice(0, width);
    if (!frontier.length) break;
  }

  return {
    map: m.name, noLoss,
    winnable: !!best,
    turns: best ? best.turnNumber : null,
    lost: best ? best.taken.filter(t => t.side === E.PLAYER).length : null,
    line: best ? best._line : null,
    final: best || null,
    applies, secs: +((Date.now()-t0)/1000).toFixed(1)
  };
}

module.exports = { solve };

if (require.main === module) {
  const idx = +(process.argv[2] || 0);
  const m = E.MAPS[idx];
  const noLoss = process.argv[3] === 'noloss';
  const r = solve(m, { noLoss, width: +(process.argv[4]||24), intra: +(process.argv[5]||10) });
  console.log(JSON.stringify({ ...r, final: undefined }, null, 1));
}
