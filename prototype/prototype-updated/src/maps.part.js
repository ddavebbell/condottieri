const MAPS = [
{
  name: 'Ambush in the Countryside',
  brief: 'The company is drawn up on the road. They are already in the hills on either side.',
  problem: 'You start in good order and they do not — but they hold both flanks in small knots, and their horse is loose at the head of the pass.',
  solution: 'Keep the rank together as it advances so the Condottiero holds the men beside him. Break one knot at a time; do not let the horse catch a man out on his own. Two more footmen come up the road on turn four — and cutting down their captain will bring his reserve over the ridge.',
  teaches: 'You begin in order. Staying in order while you move is the work.',
  width: 9, height: 9,
  commands: { rosso:3, azzurro:2 },
  turnLimit: 16,
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
    { turn: 7, text: 'More of them come down the pass',
      pieces: [ { type:'fante', side:'azzurro', x:4, y:0, behaviour:'charge', alert:4 } ] },
    { whenKilled: 'capo', text: 'Their captain is down — his reserve comes over the ridge',
      pieces: [ { type:'fante', side:'azzurro', x:3, y:0, behaviour:'charge', alert:5 },
                { type:'fante', side:'azzurro', x:5, y:0, behaviour:'charge', alert:5 } ] }
  ],
  pieces: [
    { type:'fante',       side:'rosso', x:1, y:7 },
    { type:'cavaliere',   side:'rosso', x:2, y:7 },
    { type:'fante',       side:'rosso', x:3, y:7 },
    { type:'condottiero', side:'rosso', x:4, y:7 },
    { type:'fante',       side:'rosso', x:5, y:7 },
    { type:'lanciere',    side:'rosso', x:6, y:7 },
    { type:'balestriere', side:'rosso', x:7, y:7 },

    { type:'balestriere', side:'azzurro', x:2, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:3, y:2, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:6, y:2, behaviour:'charge', alert:4, key:'capo' },
    { type:'fante',       side:'azzurro', x:6, y:3, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:4, y:4, behaviour:'charge', alert:3 },
    { type:'fante',       side:'azzurro', x:1, y:3, behaviour:'charge', alert:3 },
    { type:'cavaliere',   side:'azzurro', x:4, y:1, behaviour:'charge', alert:4 }
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
  turnLimit: 18,
  objective: { type:'hold', tiles:[[4,4]], turns:2 },
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
    { type:'fante',       side:'rosso', x:1, y:6 },
    { type:'cavaliere',   side:'rosso', x:2, y:6 },
    { type:'fante',       side:'rosso', x:3, y:6 },
    { type:'condottiero', side:'rosso', x:4, y:6 },
    { type:'fante',       side:'rosso', x:5, y:6 },
    { type:'lanciere',    side:'rosso', x:6, y:6 },
    { type:'balestriere', side:'rosso', x:7, y:6 },

    { type:'balestriere', side:'azzurro', x:4, y:3, behaviour:'guard', key:'bridgeguard' },
    { type:'fante',       side:'azzurro', x:3, y:3, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:1, y:2, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:2, y:2, behaviour:'charge', alert:4 },
    { type:'fante',       side:'azzurro', x:7, y:2, behaviour:'charge', alert:3 },
    { type:'fante',       side:'azzurro', x:6, y:3, behaviour:'guard' },
    { type:'cavaliere',   side:'azzurro', x:6, y:1, behaviour:'charge', alert:4 }
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
  turnLimit: 16,
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
  walls: gateAt(wallRect(2,1,6,3), 4,3, 4,4),
  reinforcements: [
    { turn: 4, pieces: [ { type:'fante', side:'rosso', x:3, y:8 },
                         { type:'fante', side:'rosso', x:5, y:8 } ] },
    { whenKilled: 'gateguard', text: 'The gate is unwatched — the household turns out',
      pieces: [ { type:'fante', side:'azzurro', x:2, y:1, behaviour:'guard' },
                { type:'fante', side:'azzurro', x:6, y:1, behaviour:'guard' } ] },
    { turn: 8, text: 'Riders reach the lawn',
      pieces: [ { type:'cavaliere', side:'azzurro', x:8, y:6, behaviour:'charge', alert:5 } ] }
  ],
  pieces: [
    { type:'fante',       side:'rosso', x:1, y:7 },
    { type:'cavaliere',   side:'rosso', x:2, y:7 },
    { type:'fante',       side:'rosso', x:3, y:7 },
    { type:'condottiero', side:'rosso', x:4, y:7 },
    { type:'fante',       side:'rosso', x:5, y:7 },
    { type:'lanciere',    side:'rosso', x:6, y:7 },
    { type:'balestriere', side:'rosso', x:7, y:7 },

    { type:'balestriere', side:'azzurro', x:4, y:2, behaviour:'guard', key:'gateguard' },
    { type:'fante',       side:'azzurro', x:3, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:5, y:2, behaviour:'guard' },
    { type:'fante',       side:'azzurro', x:3, y:5, behaviour:'charge', alert:3 },
    { type:'lanciere',    side:'azzurro', x:4, y:5, behaviour:'charge', alert:4 },
    { type:'fante',       side:'azzurro', x:5, y:5, behaviour:'charge', alert:3 },
    { type:'cavaliere',   side:'azzurro', x:1, y:3, behaviour:'charge', alert:4 }
  ]
}
];