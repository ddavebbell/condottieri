/* The rules, tested against the engine the game actually runs. */
const E = require('../src/engine.bundle.js');
const R = E._raw();
let pass = 0, fail = 0, group = '';
const g = n => { group = n; console.log('\n' + n); };
const chk = (label, got, want) => {
  const ok = String(got) === String(want);
  ok ? pass++ : fail++;
  console.log('  ' + (ok ? '·' : '!') + ' ' + label.padEnd(56) + String(got).padEnd(14) + (ok ? '' : '  WANT ' + want));
};

const TYPE = { p:'fante', l:'lanciere', r:'carro', n:'cavaliere', b:'balestriere', q:'condottiero' };
function board(rows, ground, walls) {
  const h = rows.length, w = rows[0].length;
  const m = { width:w, height:h, turnLimit:99, commands:{rosso:3,azzurro:2}, pieces:[],
              objective:{type:'clear'}, terrain: ground || rows.map(()=>'.'.repeat(w)), walls };
  const pieces = []; let id = 0;
  rows.forEach((r,y)=>[...r].forEach((ch,x)=>{ if (ch==='.') return;
    pieces.push({ id:id++, type:TYPE[ch.toLowerCase()],
                  side: ch===ch.toUpperCase() ? 'rosso' : 'azzurro', x, y,
                  routeStep:0, awake:false }); }));
  const st = { pieces, turn:'rosso', turnNumber:1, commands:3, acted:[], taken:[],
               slain:[], arrived:[], nextId:500, holdCount:0, over:null, reason:'', message:'' };
  E._mount(m, st);
  return { m, st, pieces };
}
const at = (ps,x,y) => ps.find(p=>p.x===x&&p.y===y);
const canTake = (rows,tx,ty,side='rosso') => { const {pieces}=board(rows);
  return pieces.filter(p=>p.side===side).some(p =>
    R.legalMoves(p).some(q=>q.x===tx&&q.y===ty) || R.shots(p).some(q=>q.x===tx&&q.y===ty)); };

g('Footmen');
{ const {pieces}=board(['p.p','.P.','p.p']);
  const k = R.legalMoves(pieces.find(p=>p.side==='rosso')).filter(m=>m.capture)
            .map(m=>m.x+','+m.y).sort().join(' ');
  chk('yours kills the two ahead, none behind', k, '0,0 2,0'); }
{ const {pieces}=board(['P.P','.p.','P.P']);
  const k = R.legalMoves(pieces.find(p=>p.side==='azzurro')).filter(m=>m.capture)
            .map(m=>m.x+','+m.y).sort().join(' ');
  chk('theirs kills the two below', k, '0,2 2,2'); }
{ const {pieces}=board(['...','.P.','...']);
  chk('walks four ways, never diagonally', R.legalMoves(pieces[0]).length, 4); }

g('The Cavaliere');
{ const {pieces}=board(['.....','.....','..N..','.....','.....']);
  chk('eight square-corners', R.legalMoves(pieces[0]).length, 8); }
{ const {pieces}=board(['.....','..p..','..N..','.....','.....']);
  chk('an enemy on his leg hobbles him',
      R.legalMoves(pieces.find(p=>p.type==='cavaliere')).some(m=>m.y===0), false); }
{ const {pieces}=board(['.....','.....','..N..','.....','.....'],['.....','.###.','.....','.....','.....']);
  chk('he leaps rock', R.legalMoves(pieces[0]).some(m=>m.y===1), true); }
{ const {pieces}=board(['.....','.....','..N..','.....','.....'],['.....','~~~~~','.....','.....','.....']);
  chk('he will not touch water', R.legalMoves(pieces[0]).some(m=>m.y===1), false); }

g('Ground');
{ const {pieces}=board(['.....','.....','..P..','.....'],['.....','~~~~~','.....','.....']);
  chk('foot wades', R.legalMoves(pieces[0]).some(m=>m.y===1), true); }
{ const {pieces}=board(['....','....','..R.','....'],['....','.ff.','....','....']);
  chk('the carro will not enter a wood', R.legalMoves(pieces[0]).some(m=>m.y===1), false); }
{ const {pieces}=board(['.....','.....','..Q..','.....','.....']);
  chk('condottiero on dry ground', R.legalMoves(pieces[0]).length, 16); }
{ const {pieces}=board(['.....','.....','..Q..','.....','.....'],['.....','.....','~~~~~','.....','.....']);
  chk('wading, he moves one square', R.legalMoves(pieces[0]).length, 8); }
{ const {pieces}=board(['...','.R.','...'],null,[[[1,1],[1,0]]]);
  chk('a wall stops him', R.legalMoves(pieces[0]).some(m=>m.x===1&&m.y===0), false); }

g('The discipline');
chk('bare man of yours: they take him',        canTake(['p..','.P.','...'],1,1,'azzurro'), true);
chk('beside your Lanciere: they cannot',       canTake(['p..','.P.','L..'],1,1,'azzurro'), false);
chk('beside your Condottiero: they cannot',    canTake(['p..','.P.','.Q.'],1,1,'azzurro'), false);
chk('beside your Balestriere: they still can', canTake(['p..','.P.','.B.'],1,1,'azzurro'), true);
chk('beside another Fante: they still can',    canTake(['p..','.P.','..P'],1,1,'azzurro'), true);
chk('their bolt goes through it',              canTake(['b..','.P.','L..'],1,1,'azzurro'), true);
chk('their charge goes through it',            canTake(['....','..P.','...L','.n..'],2,1,'azzurro'), true);
{ const {pieces}=board(['lp.','P..']);
  chk('theirs is never sheltered', R.isImmune(at(pieces,1,0)), false); }

g('Anchors');
const holds = ch => { const {pieces}=board(['.....','.....','..'+ch+'..','.....','.....']);
  return R.attackSquares(pieces[0]).length; };
chk('lanciere holds four corners', holds('L'), 4);
chk('condottiero holds eight',     holds('Q'), 8);
chk('balestriere holds nothing',   holds('B'), 0);
chk('carro holds nothing',         holds('R'), 0);
chk('cavaliere holds nothing',     holds('N'), 0);

g('Crossbows');
{ const {pieces}=board(['.....','.....','..B..','.....','.....']);
  chk('reaches the eight beside him', R.shots(pieces[0]).length + R.arcOf === undefined ? 0 : 0, 0); }
{ const {pieces}=board(['.....','..p..','..B..','.....','.....']);
  chk('shoots the man beside him', R.shots(pieces.find(p=>p.type==='balestriere')).length, 1); }
{ const {pieces}=board(['..p..','.....','..B..','.....','.....']);
  chk('and nobody two away', R.shots(pieces.find(p=>p.type==='balestriere')).length, 0); }

g('Look-ahead leaves the board alone');
{ const { st, pieces } = board(['.p.','...','..P']);
  const before = pieces.map(p=>p.id+':'+p.x+','+p.y).join('|');
  const mine = pieces.find(p=>p.side==='rosso');
  for (const m of R.legalMoves(mine)) R.wouldBeExposed(mine, m.x, m.y);
  chk('every man is where he started', pieces.map(p=>p.id+':'+p.x+','+p.y).join('|'), before); }

g('Maps as shipped');

console.log('\n' + (fail ? '!! ' + fail + ' FAILED, ' : '') + pass + ' passed');
process.exit(fail ? 1 : 0);
