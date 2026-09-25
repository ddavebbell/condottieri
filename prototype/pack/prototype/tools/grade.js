/*  DIFFICULTY, MEASURED

    The cheapest honest signal is how hard the search has to try. A beam of
    4 is a greedy player taking the obvious move; a beam of 64 is someone
    planning several pieces ahead. So: find the narrowest beam that wins.

      W*      narrowest beam that finds a win   -> how much planning it needs
      turns   how long the win takes            -> against the turn limit
      slack   limit - turns                     -> room for error
      loss%   share of explored lines that end in defeat -> how punishing
      no-loss whether a line exists losing nobody -> the perfect run

    Grades fall out of W* and slack, and are deliberately blunt.          */
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
      const theirs = s.pieces.filter(p => p.side === E.FOE);
      v = -foesOutstanding(m, s) * 3000 + mine.length * 300;
      let d = 0;
      const goal = m.objective.tiles;
      if (goal && goal.length) {
        for (const p of mine) {
          let b = 99;
          for (const t of goal) b = Math.min(b, Math.max(Math.abs(p.x-t[0]), Math.abs(p.y-t[1])));
          d += Math.min(b, 12);
        }
      } else {
        for (const p of mine) { let b = 99;
          for (const q of theirs) b = Math.min(b, Math.max(Math.abs(p.x-q.x), Math.abs(p.y-q.y)));
          d += Math.min(b, 10); }
      }
      v -= d * 22;
      if (m.objective.type === 'hold')   v += (s.holdCount||0) * 6000;
      if (m.objective.type === 'muster') v += mine.filter(p =>
          goal.some(t => t[0]===p.x && t[1]===p.y)).length * 3000;
    }
    cache.set(s, v); return v;
  };
}

function attempt(m, width, intra, noLoss) {
  const score = scorer(m);
  let frontier = [E.initialState(m)];
  frontier[0]._line = [];
  let lost = 0, seen = 0;
  for (let turn = 1; turn <= m.turnLimit; turn++) {
    const next = new Map();
    for (const s of frontier) for (const e of enumerateTurnBeam(m, s, intra, score).ends)
      next.set(E.turnHash(e), e);
    const arr = [...next.values()];
    seen += arr.length;
    lost += arr.filter(s => s.over === 'lost').length;
    const won = arr.filter(s => s.over === 'won' &&
      (!noLoss || !s.taken.some(t => t.side === E.PLAYER)));
    if (won.length) {
      won.sort((a,b) => a.turnNumber - b.turnNumber);
      return { won: true, turns: won[0].turnNumber, line: won[0]._line,
               lostPieces: won[0].taken.filter(t=>t.side===E.PLAYER).length,
               lossRate: seen ? lost/seen : 0 };
    }
    frontier = arr.filter(s => !s.over && (!noLoss || !s.taken.some(t=>t.side===E.PLAYER)))
                  .sort((a,b) => score(m,b) - score(m,a)).slice(0, width);
    if (!frontier.length) break;
  }
  return { won: false, lossRate: seen ? lost/seen : 0 };
}

const LADDER = [3, 6, 12, 24, 48];

function grade(m, opts = {}) {
  const intra = opts.intra || 10;
  const t0 = Date.now();
  let first = null, lossRate = 0;
  for (const w of LADDER) {
    const r = attempt(m, w, intra, false);
    lossRate = Math.max(lossRate, r.lossRate);
    if (r.won) { first = { width: w, ...r }; break; }
  }
  let noLoss = null;
  if (first) {
    const r = attempt(m, Math.max(first.width * 2, 48), intra, true);
    noLoss = r.won ? { turns: r.turns, line: r.line } : null;
  }
  const slack = first ? m.turnLimit - first.turns : null;

  /*  Difficulty is three things, and beam width alone is not enough.

        planning  how wide the search had to be before it found a win
        pressure  how little room the turn limit leaves for a wrong move
        risk      how much of the tree ends in defeat

      Most of the first draft of these maps graded easy on W*=3 while
      having eight or ten spare turns. Room for error is the real dial.  */
  let band, difficulty = null;
  if (!first) band = 'UNSOLVED';
  else {
    const planning = Math.log2(first.width);
    const pressure = Math.max(0, 6 - slack) * 0.8;
    const risk     = lossRate * 5;
    difficulty = +(planning + pressure + risk).toFixed(2);
    band = difficulty < 3 ? 'easy' : difficulty < 5 ? 'medium'
         : difficulty < 7 ? 'hard' : 'brutal';
  }

  return {
    name: m.name, objective: m.objective.type, limit: m.turnLimit,
    solved: !!first,
    W: first ? first.width : null,
    turns: first ? first.turns : null,
    slack, band, difficulty,
    lostInBestLine: first ? first.lostPieces : null,
    noLoss: !!noLoss, noLossTurns: noLoss ? noLoss.turns : null,
    lossRate: +(lossRate*100).toFixed(1),
    secs: +((Date.now()-t0)/1000).toFixed(1),
    line: first ? first.line : null
  };
}

module.exports = { grade };

if (require.main === module) {
  const fs = require('fs');
  const from = +(process.argv[2] || 0), to = +(process.argv[3] || from);
  const out = [];
  for (let i = from; i <= to && i < E.MAPS.length; i++) {
    const g = grade(E.MAPS[i], { intra: +(process.argv[4] || 10) });
    out.push(g);
    console.log('%s  %s d=%s  W*=%s turns=%s slack=%s  loss%%=%s  no-loss=%s  %ss',
      String(i).padStart(2), (g.band + '        ').slice(0,8),
      String(g.difficulty).padStart(5),
      String(g.W).padStart(3), String(g.turns).padStart(3), String(g.slack).padStart(3),
      String(g.lossRate).padStart(5), g.noLoss ? 'yes' : 'no ', g.secs);
    console.log('     ' + g.name + '  (' + g.objective + ', limit ' + g.limit + ')');
  }
  const path = 'grades.json';
  const prev = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path)) : {};
  for (const g of out) prev[g.name] = g;
  fs.writeFileSync(path, JSON.stringify(prev, null, 1));
}
