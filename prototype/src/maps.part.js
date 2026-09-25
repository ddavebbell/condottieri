/* The company, drawn up: the same seven men in the same order, every map. */
function company(y) {
  return [
    { type:'fante',       side:'rosso', x:2, y },
    { type:'cavaliere',   side:'rosso', x:3, y },
    { type:'condottiero', side:'rosso', x:4, y },
    { type:'lanciere',    side:'rosso', x:5, y },
    { type:'fante',       side:'rosso', x:6, y }
  ];
}
const foe = (type, x, y, behaviour, extra) =>
  Object.assign({ type, side:'azzurro', x, y, behaviour: behaviour || 'guard' }, extra || {});

const MAPS = [
{
  name: 'Ambush in the Countryside',
  brief: 'The company is drawn up on the road. They are already in the hills on either side.',
  problem: 'You start in good order and they do not — but they hold both flanks in small knots, and their horse is loose at the head of the pass.',
  solution: 'Keep the rank together as it advances so the Condottiero holds the men beside him. Break one knot at a time; do not let the horse catch a man out on his own. Two more footmen come up the road on turn four — and cutting down their captain will bring his reserve over the ridge.',
  teaches: 'You begin in order. Staying in order while you move is the work.',
  width: 9, height: 9,
  commands: { rosso:3, azzurro:2 },
  turnLimit: 19,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',
    ' ....... ',
    '.........',
    '..f...f..',
    '...#.#...',
    '..f...f..',
    '.........',
    ' ....... ',
    '  .....  '
  ],
  reinforcements: [
    { turn: 4, pieces: [ { type:'fante', side:'rosso', x:3, y:8 },
                         { type:'fante', side:'rosso', x:5, y:8 } ] },
    { whenKilled: 'capo', text: 'Their captain is down — his reserve comes over the ridge',
      pieces: [ { type:'fante', side:'azzurro', x:4, y:0, behaviour:'charge', alert:5 } ] }
  ],
  pieces: [
    { type:'fante',       side:'rosso', x:2, y:7 },
    { type:'cavaliere',   side:'rosso', x:3, y:7 },
    { type:'condottiero', side:'rosso', x:4, y:7 },
    { type:'lanciere',    side:'rosso', x:5, y:7 },
    { type:'fante',       side:'rosso', x:6, y:7 },

    { type:'balestriere', side:'azzurro', x:2, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:3, y:2, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:6, y:2, behaviour:'charge', alert:4, key:'capo' },
    { type:'fante',       side:'azzurro', x:4, y:4, behaviour:'charge', alert:3 },
    { type:'cavaliere',   side:'azzurro', x:4, y:1, behaviour:'charge', alert:3 },
    foe('fante', 5, 1, 'charge', {alert:3}),
    foe('fante', 4, 2, 'charge', {alert:4})
  ]
},
{
  name: 'The Bridge',
  brief: 'Drawn up short of the river. The crossing has to be held.',
  problem: 'A crossbowman covers the planks with a footman at his shoulder, and there is a knot on each bank flank.',
  solution: 'Advance the rank to the water in good order. Wade on a flank where their bolts do not reach and put the crossbowman down — but know that a rider is sent for the moment he falls. Have the bridge held and the Lanciere on the corner before that.',
  teaches: 'Water costs two turns. A man mid-river can answer nothing.',
  width: 9, height: 9,
  commands: { rosso:3, azzurro:2 },
  turnLimit: 21,
  objective: { type:'hold', tiles:[[4,4]], turns: 3 },
  deployment: { region: rect(1,6,7,6), floor: 4 },
  terrain: [
    '  .....  ',
    ' ....... ',
    '.........',
    '..f...f..',
    '~~~~=~~~~',
    '..f...f..',
    '.........',
    ' ....... ',
    '  .....  '
  ],
  reinforcements: [
    { turn: 4, pieces: [ { type:'fante', side:'rosso', x:3, y:8 },
                         { type:'fante', side:'rosso', x:5, y:8 } ] },
    { whenKilled: 'bridgeguard', text: 'The crossbowman is down — a rider is sent for',
      pieces: [ { type:'cavaliere', side:'azzurro', x:4, y:0, behaviour:'charge', alert:5 } ] },
    { turn: 8, text: 'Another party reaches the far bank',
      pieces: [ { type:'fante', side:'azzurro', x:2, y:0, behaviour:'charge', alert:4 },
                { type:'fante', side:'azzurro', x:6, y:0, behaviour:'charge', alert:4 } ] }
  ],
  pieces: [
    { type:'fante',       side:'rosso', x:2, y:6 },
    { type:'cavaliere',   side:'rosso', x:3, y:6 },
    { type:'condottiero', side:'rosso', x:4, y:6 },
    { type:'lanciere',    side:'rosso', x:5, y:6 },
    { type:'fante',       side:'rosso', x:6, y:6 },

    { type:'balestriere', side:'azzurro', x:4, y:2, behaviour:'guard', key:'bridgeguard' },
    { type:'fante',       side:'azzurro', x:3, y:3, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:1, y:2, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:2, y:2, behaviour:'charge', alert:4 },
    { type:'fante',       side:'azzurro', x:7, y:2, behaviour:'charge', alert:3 },
    { type:'fante',       side:'azzurro', x:6, y:3, behaviour:'guard' },
    { type:'cavaliere',   side:'azzurro', x:6, y:1, behaviour:'charge', alert:4 },
    foe('fante', 5, 0, 'charge', {alert:3})
  ]
},
{
  name: 'The Villa Gate',
  brief: 'Formed up on the lawn. Three men inside the courtyard and the house is yours.',
  problem: 'One gate, with a knot of three behind it and a crossbowman in the middle of them. A second party is out on the lawn and their horse is loose on your flank.',
  solution: 'Deal with the lawn party without breaking the rank, then bring a column to the gate. The first man through blocks the bolt for the second. Killing their crossbowman turns the household out, so time it.',
  teaches: 'A column pushes a gate. A crowd does not.',
  width: 9, height: 9,
  commands: { rosso:3, azzurro:2 },
  turnLimit: 20,
  objective: { type:'muster', tiles: rect(2,1,6,3), count: 3 },
  deployment: { region: rect(1,7,7,7), floor: 5 },
  terrain: [
    '.........',
    '..mmmmm..',
    '..mmmmm..',
    '..mmmmm..',
    '.........',
    '..f...f..',
    '.........',
    ' ....... ',
    '  .....  '
  ],
  walls: gateAt(gateAt(wallRect(2,1,6,3), 4,3, 4,4), 3,3, 3,4),
  reinforcements: [
    { turn: 4, pieces: [ { type:'fante', side:'rosso', x:3, y:8 },
                         { type:'fante', side:'rosso', x:5, y:8 } ] },
    { whenKilled: 'gateguard', text: 'The gate is unwatched — the household turns out',
      pieces: [ { type:'fante', side:'azzurro', x:1, y:5, behaviour:'charge', alert:5 },
                { type:'fante', side:'azzurro', x:7, y:5, behaviour:'charge', alert:5 } ] },
    { turn: 8, text: 'Riders reach the lawn',
      pieces: [ { type:'cavaliere', side:'azzurro', x:8, y:6, behaviour:'charge', alert:5 } ] }
  ],
  pieces: [
    { type:'fante',       side:'rosso', x:2, y:7 },
    { type:'cavaliere',   side:'rosso', x:3, y:7 },
    { type:'condottiero', side:'rosso', x:4, y:7 },
    { type:'lanciere',    side:'rosso', x:5, y:7 },
    { type:'fante',       side:'rosso', x:6, y:7 },

    { type:'balestriere', side:'azzurro', x:4, y:2, behaviour:'guard', key:'gateguard' },
    { type:'fante',       side:'azzurro', x:3, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:5, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:3, y:5, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:4, y:5, behaviour:'charge', alert:4 },
    { type:'fante',       side:'azzurro', x:5, y:5, behaviour:'charge', alert:3 },
    { type:'cavaliere',   side:'azzurro', x:1, y:3, behaviour:'charge', alert:4 },
    foe('fante', 4, 0, 'charge', {alert:3})
  ]
}
,
{
  name: 'Skirmish on the Road',
  brief: 'Four of them, loose on open ground. A first contract.',
  problem: 'Nothing clever. Four men in the open, no cover, no crossbow.',
  solution: 'Walk up in order and take them. Keep your flanks on an anchor and nothing of theirs can answer.',
  teaches: 'Men beside an anchor cannot be touched by their infantry.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 16,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',' ....... ','.........','.........','.........',
    '.........','.........',' ....... ','  .....  '
  ],
  reinforcements: [],
  pieces: [ ...company(7),
    foe('fante', 3, 2, 'charge', {alert:4}), foe('fante', 5, 2, 'charge', {alert:4}),
    foe('fante', 2, 4, 'charge', {alert:3}), foe('fante', 6, 4, 'charge', {alert:3}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 5, 0, 'charge', {alert:4}),
    foe('fante', 4, 1, 'charge', {alert:5}),
    foe('lanciere', 5, 1, 'charge', {alert:3})
  ]
},
{
  name: 'The Treeline',
  brief: 'They are holding the wood across the valley.',
  problem: 'A belt of trees they can sit in and you cannot slide through. Their crossbowman is behind it.',
  solution: 'Trees stop a slider dead, so bring footmen — they lose nothing entering. Come at the crossbowman from a corner.',
  teaches: 'Rough ground ends a slider\u2019s move. Foot pays no such price.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 19,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '.........','.........','..fffff..','..fffff..','.........',
    '.........','.........',' ....... ','  .....  '
  ],
  reinforcements: [],
  pieces: [ ...company(7),
    foe('balestriere', 4, 1), foe('fante', 3, 2, 'charge', {alert:3}),
    foe('fante', 5, 3, 'charge', {alert:3}), foe('lanciere', 6, 1, 'charge', {alert:4}),
    foe('fante', 2, 4, 'charge', {alert:4}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 5, 0, 'charge', {alert:4}),
    foe('fante', 5, 1, 'charge', {alert:5})
  ]
},
{
  name: 'The Ford',
  brief: 'Across the water and hold the far bank.',
  problem: 'A river with two shallow crossings. Your horse cannot swim and anyone caught in the water moves a single square.',
  solution: 'Send foot across on both fords at once so neither crossing can be held against you. The horse takes the bridge or waits.',
  teaches: 'Water costs two turns. A man mid-river can answer nothing.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 18,
  objective: { type:'muster', tiles: rect(3,1,5,2), count: 3 },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '.........','.........','.........','.........','~~:~~~:~~',
    '.........','.........',' ....... ','  .....  '
  ],
  reinforcements: [],
  pieces: [ ...company(7),
    foe('fante', 2, 3, 'charge', {alert:3}), foe('fante', 6, 3, 'charge', {alert:3}),
    foe('lanciere', 4, 2, 'charge', {alert:4}), foe('balestriere', 4, 0),
    foe('fante', 1, 1, 'charge', {alert:4}),
    foe('fante', 5, 0, 'charge', {alert:3}),
    foe('fante', 4, 3, 'charge', {alert:4}),
    foe('fante', 5, 3, 'charge', {alert:5})
  ]
},
{
  name: 'The Watchtower',
  brief: 'Two crossbows on the rocks, and a narrow way past them.',
  problem: 'Boulders split the field into three lanes, and a crossbow sits at the mouth of two of them. They kill whatever stands beside them, anchored or not.',
  solution: 'A crossbow only reaches one step. Come down the lane he does not cover, or send the horse — he leaps the rock and arrives from a corner.',
  teaches: 'Bolts go through the discipline. Only the horse leaps rock.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 19,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '.........','..#...#..','..#...#..','.........','..#...#..',
    '.........','.........',' ....... ','  .....  '
  ],
  reinforcements: [],
  pieces: [ ...company(7),
    foe('balestriere', 4, 1), foe('fante', 5, 2, 'charge', {alert:3}),
    foe('fante', 4, 3, 'charge', {alert:3}), foe('fante', 1, 2, 'charge', {alert:4}),
    foe('lanciere', 7, 1, 'charge', {alert:4}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 5, 0, 'charge', {alert:4}),
    foe('fante', 5, 1, 'charge', {alert:5})
  ]
},
{
  name: 'Hold the Crossroads',
  brief: 'Sit on the crossroads for four turns while the column passes.',
  problem: 'One tile, four turns, and they come at it from three sides. Standing there alone is death.',
  solution: 'Put a man on the crossroads and the Condottiero beside him — an anchored man cannot be taken by their foot. Then only their horse matters.',
  teaches: 'The discipline is what lets you stand still.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 21,
  objective: { type:'hold', tiles:[[4,4]], turns: 4 },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',' ..#.#.. ','.........','...###...','.........',
    '...###...','.........',' ....... ','  .....  '
  ],
  reinforcements: [
    { turn: 5, text: 'More of them reach the crossroads',
      pieces: [ foe('fante', 4, 0, 'charge', {alert:5}) ] }
  ],
  pieces: [ ...company(7),
    foe('fante', 1, 4, 'charge', {alert:4}), foe('fante', 7, 4, 'charge', {alert:4}),
    foe('lanciere', 4, 2, 'charge', {alert:4}), foe('cavaliere', 1, 1, 'charge', {alert:5}),
    foe('fante', 7, 1, 'charge', {alert:4}),
    foe('fante', 5, 0, 'charge', {alert:3}),
    foe('fante', 4, 1, 'charge', {alert:4}),
    foe('fante', 5, 2, 'charge', {alert:5})
  ]
},
{
  name: 'The Courtyard',
  brief: 'Three men inside the walls and the house is yours.',
  problem: 'A walled yard with a gate two tiles wide, and men holding it. The wall costs no ground but nothing crosses it.',
  solution: 'Come to the gate as a column, not a crowd. The first man in blocks the bolt for the second.',
  teaches: 'A wall sits on the border, not on the tile. A column pushes a gate.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 19,
  objective: { type:'muster', tiles: rect(2,1,6,3), count: 3 },
  deployment: { region: rect(1,7,7,7), floor: 5 },
  terrain: [
    '.........','..mmmmm..','..mmmmm..','..mmmmm..','.........',
    '..f...f..','.........',' ....... ','  .....  '
  ],
  walls: gateAt(gateAt(wallRect(2,1,6,3), 4,3, 4,4), 3,3, 3,4),
  reinforcements: [
    { whenKilled: 'gateguard', text: 'The household turns out onto the lawn',
      pieces: [ foe('fante', 1, 4, 'charge', {alert:5}), foe('fante', 7, 4, 'charge', {alert:5}) ] }
  ],
  pieces: [ ...company(7),
    foe('balestriere', 4, 2, 'guard', {key:'gateguard'}),
    foe('fante', 3, 2), foe('fante', 5, 2),
    foe('lanciere', 4, 5, 'charge', {alert:4}),
    foe('cavaliere', 1, 5, 'charge', {alert:5}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 5, 0, 'charge', {alert:4}),
    foe('fante', 3, 0, 'charge', {alert:5})
  ]
},
{
  name: 'Horse Country',
  brief: 'Open ground, and three of their riders.',
  problem: 'Nothing to hide behind and three horses, and a charge goes through the discipline as if it were not there.',
  solution: 'A horse begins his charge with one step sideways. Put a body on that step and he cannot move at all. Close the ground and shut them down.',
  teaches: 'Hobbling: a man on the leg stops a charge.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 19,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',' ....... ','.........','.........','.........',
    '.........','.........',' ....... ','  .....  '
  ],
  reinforcements: [],
  pieces: [ ...company(7),
    foe('cavaliere', 2, 1, 'charge', {alert:5}), foe('cavaliere', 6, 1, 'charge', {alert:5}),
    foe('cavaliere', 4, 3, 'charge', {alert:5}), foe('fante', 4, 0, 'charge', {alert:4}),
    foe('fante', 5, 0, 'charge', {alert:3}),
    foe('fante', 4, 1, 'charge', {alert:4}),
    foe('fante', 5, 1, 'charge', {alert:5}),
    foe('lanciere', 4, 2, 'charge', {alert:3})
  ]
},
{
  name: 'Two Knots',
  brief: 'Two parties, and a captain worth killing last.',
  problem: 'Their captain has a reserve behind him — cut him down early and two more come over the ridge while you are still busy.',
  solution: 'Clear the far knot first, then take the captain when there is nobody left to punish you for it.',
  teaches: 'Order of killing. A trigger is a clock you start yourself.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 17,
  objective: { type:'clear' },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',' ....... ','..f...f..','.........','...#.#...',
    '..f...f..','.........',' ....... ','  .....  '
  ],
  reinforcements: [
    { whenKilled: 'capo', text: 'Their captain is down — his reserve comes over the ridge',
      pieces: [ foe('fante', 3, 0, 'charge', {alert:5}), foe('fante', 5, 0, 'charge', {alert:5}) ] }
  ],
  pieces: [ ...company(7),
    foe('lanciere', 2, 1, 'charge', {alert:4}, ), foe('fante', 1, 2, 'charge', {alert:4}),
    foe('fante', 6, 1, 'charge', {alert:4}), foe('balestriere', 7, 2),
    foe('fante', 4, 3, 'charge', {alert:3}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 4, 1, 'charge', {alert:4}),
    foe('fante', 5, 1, 'charge', {alert:5})
  ]
},
{
  name: 'The Long Hold',
  brief: 'Hold the bridge five turns. They will keep coming.',
  problem: 'Five turns on one tile with waves arriving on turn four and turn eight, and a crossbow already sighted on the planks.',
  solution: 'Kill the crossbow first, then rotate anchored men onto the bridge. Only their horse can shift an anchored man.',
  teaches: 'A long hold is a rotation, not a stand.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 21,
  objective: { type:'hold', tiles:[[4,4]], turns: 4 },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '  .....  ',' ....... ','.........','..f...f..','~~~~=~~~~',
    '..f...f..','.........',' ....... ','  .....  '
  ],
  reinforcements: [
    { turn: 4, text: 'A party reaches the far bank',
      pieces: [ foe('fante', 3, 0, 'charge', {alert:5}) ] },
    { turn: 9, text: 'Riders reach the far bank',
      pieces: [ foe('cavaliere', 5, 0, 'charge', {alert:4}) ] }
  ],
  pieces: [ ...company(7),
    foe('balestriere', 4, 2), foe('fante', 3, 3), foe('fante', 5, 3),
    foe('lanciere', 2, 1, 'charge', {alert:4}), foe('fante', 6, 1, 'charge', {alert:4}),
    foe('fante', 4, 0, 'charge', {alert:3}),
    foe('fante', 4, 1, 'charge', {alert:4}),
    foe('fante', 5, 1, 'charge', {alert:5})
  ]
},
{
  name: 'The Gauntlet',
  brief: 'A walled lane, and the yard at the end of it.',
  problem: 'One lane, walls on both sides, a crossbow at the mouth and men behind him. Nothing can flank because there is nowhere to flank to.',
  solution: 'A column, and patience. The lead man eats the bolt so the next two get through; the Condottiero on the threshold holds whoever follows.',
  teaches: 'Bodies stop bolts.',
  width: 9, height: 9, commands: { rosso:3, azzurro:2 }, turnLimit: 21,
  objective: { type:'muster', tiles: rect(3,0,5,1), count: 2 },
  deployment: { region: rect(1,7,7,7), floor: 4 },
  terrain: [
    '...mmm...','...mmm...','.........','.........','.........',
    '.........','.........',' ....... ','  .....  '
  ],
  walls: wallRect(3,0,5,3).filter(w =>
    !(w[0][1] === 3 && w[1][1] === 4) &&            // the gate, two tiles wide
    !(w[0][0] === 2 && w[1][0] === 3 && w[0][1] === 1)),  // and a side door
  reinforcements: [],
  pieces: [ ...company(7),
    foe('balestriere', 4, 1, 'guard', {key:'lanewatch'}),
    foe('fante', 4, 2),
    foe('lanciere', 4, 5, 'charge', {alert:4}),
    foe('fante', 1, 4, 'charge', {alert:4}),
    foe('fante', 5, 2, 'charge', {alert:3}),
    foe('fante', 4, 3, 'charge', {alert:4}),
    foe('fante', 5, 3, 'charge', {alert:5}),
    foe('lanciere', 6, 0, 'charge', {alert:3})
  ]
}

];