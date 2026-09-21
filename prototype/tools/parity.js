const { E } = require('./lib.js');
const m = E.MAPS[1];
let s = E.initialState(m);
function step(x,y){
  const c = s.pieces.find(p=>p.side===E.PLAYER&&p.type==='condottiero');
  const a = E.actions(m,s).find(q=>q.id===c.id&&q.x===x&&q.y===y);
  if(!a) return console.log('  cannot reach '+x+','+y+' from '+c.x+','+c.y);
  s = E.apply(m,s,a);
  console.log('  -> %d,%d   turn %d  hold %d  %s', x,y,s.turnNumber,s.holdCount,s.over||'');
}
console.log('Walking the captain onto the planks and sitting there:');
step(4,5); s = E.pass(m,s);
step(4,4); s = E.pass(m,s);
console.log('  (end of the turn he first stood on it: hold %d)', s.holdCount);
s = E.pass(m,s);
console.log('  after one more turn: hold %d, outcome %s', s.holdCount, s.over || 'playing');
console.log('\nA two-turn hold should resolve on the second count, not the first.');
