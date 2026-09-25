const { E, enumerateTurnBeam, foesOutstanding } = require('./lib.js');
const m = E.MAPS[+(process.argv[2]||0)];
const width = +(process.argv[3]||32), intra = +(process.argv[4]||12);
const cache = new WeakMap();
function score(mm, s) {
  if (cache.has(s)) return cache.get(s);
  let v;
  if (s.over === 'won') v = 1e7 - s.turnNumber;
  else if (s.over === 'lost') v = -1e7;
  else {
    const mine = s.pieces.filter(p=>p.side===E.PLAYER), theirs = s.pieces.filter(p=>p.side===E.FOE);
    v = -foesOutstanding(m, s) * 3000 + mine.length * 300;
    let d=0; for (const p of mine){ let b=99;
      for (const q of theirs) b=Math.min(b,Math.max(Math.abs(p.x-q.x),Math.abs(p.y-q.y))); d+=Math.min(b,10);} 
    v -= d*22;
    if (m.objective.type==='hold') v += (s.holdCount||0)*6000;
    if (m.objective.type==='muster') v += mine.filter(p=>
      m.objective.tiles.some(t=>t[0]===p.x&&t[1]===p.y)).length*3000;
  }
  cache.set(s,v); return v;
}
let frontier = [E.initialState(m)]; frontier[0]._line = [];
console.log(m.name + '  objective ' + m.objective.type + ', limit ' + m.turnLimit);
for (let turn = 1; turn <= m.turnLimit; turn++) {
  const next = new Map();
  for (const s of frontier) for (const e of enumerateTurnBeam(m, s, intra, score).ends) next.set(E.turnHash(e), e);
  const arr = [...next.values()], won = arr.filter(s=>s.over==='won');
  if (won.length) { won.sort((a,b)=>a.turnNumber-b.turnNumber||a.taken.filter(t=>t.side===E.PLAYER).length-b.taken.filter(t=>t.side===E.PLAYER).length);
    const w = won[0];
    console.log('  WON turn ' + w.turnNumber + ', lost ' + w.taken.filter(t=>t.side===E.PLAYER).length + ' of yours');
    console.log('  ' + w._line.join('\n  '));
    require('fs').writeFileSync('win-' + (+(process.argv[2]||0)) + '.json', JSON.stringify({turns:w.turnNumber, lost:w.taken.filter(t=>t.side===E.PLAYER).length, line:w._line},null,1));
    process.exit(0); }
  const live = arr.filter(s=>!s.over);
  if (!live.length) { console.log('  t'+turn+': every line has ended'); break; }
  console.log('  t%s  %s live | still to kill min %s | your dead min %s | hold %s | in-goal %s',
    String(turn).padStart(2), String(live.length).padStart(5),
    Math.min(...live.map(s=>foesOutstanding(m,s))),
    Math.min(...live.map(s=>s.taken.filter(t=>t.side===E.PLAYER).length)),
    Math.max(...live.map(s=>s.holdCount||0)),
    m.objective.tiles ? Math.max(...live.map(s=>s.pieces.filter(p=>p.side===E.PLAYER&&m.objective.tiles.some(t=>t[0]===p.x&&t[1]===p.y)).length)) : '-');
  frontier = live.sort((a,b)=>score(m,b)-score(m,a)).slice(0,width);
}
