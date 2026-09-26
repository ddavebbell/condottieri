/* ============================================================
   THE TUTORIAL

   The first contract, played with a guide. A scrim darkens the battle
   screen except for one spotlit thing (a group of tiles, the command
   pips, a button) and a card explains it. Every card has a Next button
   and the board is held still until the guide is done; where a step
   needs something on the board to point at, it sets that up itself.

   Lives entirely on top of ui.part.js and screens.part.js: it wraps
   startMission() to begin, render() to notice the board changing, and
   boardActive() to hold the board still on the Next steps. It runs
   only on mission 0 and only until it has been finished or skipped
   (save.tutorialDone). Settings can bring it back.
   ============================================================ */

const TUTORIAL_MAP = 0;

/* Each step: what to spotlight (a function returning one element or a
   list of them), what to say, and the button's label. `enter` and
   `leave` set up and clear anything the step needs on the board.
   `skip` drops a step that has nothing to show. */
const TUTORIAL = [
  {
    target: () => ownTiles(),
    title: 'Your company',
    text: 'Five men. Two footmen, a horseman, your Condottiero in the middle and a Lanciere beside him. Lose the Condottiero and the contract is lost.',
    button: 'Next'
  },
  {
    target: () => foeTiles(),
    title: 'Theirs',
    text: 'Eight men on the road. This contract is simple: clear the field. Progress sits in the top bar.',
    button: 'Next'
  },
  {
    target: () => el('pips'),
    title: 'Three commands',
    text: 'You give three commands a turn, one dot each. Every move or shot spends one.',
    button: 'Next'
  },
  {
    enter: () => { selected = pieceAt(6, 7); render(); },
    leave: () => { selected = null; render(); },
    target: () => [tileEl(6, 7), ...document.querySelectorAll('#board .tile.move, #board .tile.capture')],
    title: 'How a man moves',
    text: 'Tap a man and the pale dots show where he can step. A green ring would be a kill. A red mark means they could kill him there. Footmen step one square and strike diagonally forward.',
    button: 'Next'
  },
  {
    target: () => [...document.querySelectorAll('#board .tile .ring')].map(r => r.parentElement),
    skip: () => !document.querySelector('#board .tile .ring'),
    title: 'The discipline',
    text: 'The gold rings. A man beside your Condottiero, or on a corner of your Lanciere, cannot be taken by their footmen at all. Everything in this game is built on that.',
    button: 'Next'
  },
  {
    target: () => document.querySelector('#board .tile.threat'),
    skip: () => !document.querySelector('#board .tile.threat'),
    title: 'The red corner',
    text: 'This man of yours can be killed on their next turn. Move him, or bring an anchor to him.',
    button: 'Next'
  },
  {
    target: () => el('endturn'),
    title: 'End turn',
    text: 'When your commands are spent, or you are done, tap End turn. They move, and the board is yours again.',
    button: 'Next'
  },
  {
    target: () => [el('undo'), el('hintbtn')],
    title: 'Undo and Hint',
    text: 'Undo takes back your last move. Hint shows the line this contract was built around. The full rules, with worked examples, are under the menu.',
    button: 'Next'
  },
  {
    target: () => null,
    title: 'Clear the road',
    text: 'Keep your men on the corners of the Lanciere and beside the Condottiero, and nothing of theirs can answer. Good luck, Captain.',
    button: 'Begin'
  }
];

function ownTiles() { return state.pieces.filter(p => p.side === PLAYER).map(p => tileEl(p.x, p.y)); }
function foeTiles() { return state.pieces.filter(p => p.side === FOE).map(p => tileEl(p.x, p.y)); }

let tutStep = -1;          // -1: not running
let tutMap = -1;

function tutorialRunning() { return tutStep >= 0 && tutStep < TUTORIAL.length; }

function tutorialStart(index) {
  tutMap = index;
  if (index !== TUTORIAL_MAP || save.tutorialDone) { tutorialEnd(false); return; }
  tutStep = 0;
  tutorialShow();
}

function tutorialEnd(done) {
  if (tutorialRunning() && TUTORIAL[tutStep].leave) TUTORIAL[tutStep].leave();
  tutStep = -1;
  el('tut').classList.add('hidden');
  if (done && !save.tutorialDone) { save.tutorialDone = true; saveProfile(); }
}

function tutorialNext() {
  if (TUTORIAL[tutStep].leave) TUTORIAL[tutStep].leave();
  tutStep++;
  while (tutorialRunning() && TUTORIAL[tutStep].skip && TUTORIAL[tutStep].skip()) tutStep++;
  if (!tutorialRunning()) { tutorialEnd(true); return; }
  if (TUTORIAL[tutStep].enter) TUTORIAL[tutStep].enter();
  tutorialShow();
}

/* Place the spotlight over the step's target and the card near it. */
function tutorialShow() {
  if (!tutorialRunning()) return;
  const step = TUTORIAL[tutStep];
  const box = el('tut');
  box.classList.toggle('hidden', activeScreen !== 'battle');
  el('tut-title').textContent = step.title;
  el('tut-text').textContent = step.text;
  el('tut-next').textContent = step.button;
  el('tut-count').textContent = (tutStep + 1) + ' / ' + TUTORIAL.length;

  let targets = step.target();
  if (targets && !Array.isArray(targets)) targets = [targets];
  targets = (targets || []).filter(Boolean);
  const spot = el('tut-spot');
  const card = el('tut-card');
  const vw = window.innerWidth, vh = window.innerHeight;
  if (targets.length) {
    let l = Infinity, t = Infinity, r = -Infinity, b = -Infinity;
    for (const e of targets) {
      const q = e.getBoundingClientRect();
      l = Math.min(l, q.left); t = Math.min(t, q.top); r = Math.max(r, q.right); b = Math.max(b, q.bottom);
    }
    const pad = 6;
    spot.style.left = (l - pad) + 'px'; spot.style.top = (t - pad) + 'px';
    spot.style.width = (r - l + 2 * pad) + 'px'; spot.style.height = (b - t + 2 * pad) + 'px';
    spot.style.opacity = 1;
    /* the card goes under the target if there is room, else above it */
    const below = vh - b - pad;
    card.style.top = below > 220 ? (b + pad + 12) + 'px' : '';
    card.style.bottom = below > 220 ? '' : (vh - t + pad + 12) + 'px';
  } else {
    spot.style.left = (vw / 2) + 'px'; spot.style.top = (vh / 2) + 'px';
    spot.style.width = '0px'; spot.style.height = '0px';
    spot.style.opacity = 1;
    card.style.top = ''; card.style.bottom = '18%';
  }
}

/* After every draw, re-place the spotlight: the board may have resized. */
function tutorialTick() {
  if (!tutorialRunning()) return;
  if (state.over || activeScreen !== 'battle') { el('tut').classList.add('hidden'); return; }
  tutorialShow();
}

/* ---------- hooks into the board and the shell ---------- */

const baseStartMission = startMission;
startMission = function (index) {
  baseStartMission(index);
  tutorialStart(index);
};

const baseRender = render;
render = function () {
  baseRender();
  tutorialTick();
};

/* The board holds still while the guide is up. */
const baseBoardActive = boardActive;
boardActive = () => baseBoardActive() && !tutorialRunning();

window.addEventListener('resize', () => tutorialRunning() && tutorialShow());

el('tut-next').onclick = tutorialNext;
el('tut-skip').onclick = () => tutorialEnd(true);
el('st-tutorial').onclick = () => {
  save.tutorialDone = false;
  saveProfile();
  el('st-account').textContent = 'The tutorial will run on the first contract.';
};
