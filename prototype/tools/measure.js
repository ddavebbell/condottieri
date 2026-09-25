const { E, enumerateTurn } = require('./lib.js');
const fs = require('fs');
const depth = +(process.argv[2] || 3);
const out = [];
for (const m of E.MAPS) {
  console.log('\n' + m.name);
  let frontier = [E.initialState(m)];
  for (let t = 1; t <= depth; t++) {
    const t0 = Date.now();
    const next = new Map();
    let applies = 0, inner = 0, trunc = false;
    for (const s of frontier) {
      const r = enumerateTurn(m, s, 80000);
      applies += r.applies; inner += r.inner; trunc = trunc || r.truncated;
      for (const e of r.ends) next.set(E.turnHash(e), e);
      if (applies > 400000) { trunc = true; break; }
    }
    const arr = [...next.values()];
    const live = arr.filter(s => !s.over);
    const secs = ((Date.now()-t0)/1000).toFixed(1);
    console.log('  turn %d  %s distinct end positions  (%s live)  %ss  %s applies%s',
      t, String(arr.length).padStart(6), String(live.length).padStart(6), secs,
      applies.toLocaleString(), trunc ? '  [capped]' : '');
    out.push({ map:m.name, turn:t, positions:arr.length, live:live.length, secs:+secs, applies, trunc });
    frontier = live;
    if (!frontier.length || trunc) break;
    if (frontier.length > 1200) { console.log('  (frontier too wide to continue exactly)'); break; }
  }
}
fs.writeFileSync('measure.json', JSON.stringify(out,null,1));
