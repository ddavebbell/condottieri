/* ============================================================
   THE SHELL

   Everything around the board: title, sign in, campaign, briefing,
   result, settings, and the router that moves between them.

   One <section class="screen"> per screen lives in shell.head.html and
   exactly one of them carries .on at a time. ui.part.js knows nothing
   about this file; it offers startMission(), onMissionEnd() and
   boardActive() and this file plugs into them.

   Back button. The page keeps exactly one history entry above the one
   it was opened on. Every navigation replaces that entry; when the
   browser pops it, popstate pushes it straight back and then walks
   BACK_TO within the game. So Back never leaves the page, and from
   the battle it opens the pause menu instead.
   ============================================================ */

const VERSION = '0.1.0';

/* Where Back goes. null means stay (title) or special: battle toggles
   the pause menu, settings returns to wherever it was opened from. */
const BACK_TO = {
  title: null, signin: 'title', campaign: 'title', briefing: 'campaign',
  battle: null, result: 'campaign', settings: null
};

let activeScreen = null;
let settingsFrom = 'title';   // the screen Settings returns to
let briefingIndex = 0;        // the mission Briefing is showing
let lastResult = null;        // what Result is showing
let pauseOpen = false;

/* Milestone 2 moves this into the save. */
const profile = { name: '' };

/* ---------- router ---------- */

function show(name, data) {
  if (activeScreen) el('scr-' + activeScreen).classList.remove('on');
  activeScreen = name;
  if (ENTER[name]) ENTER[name](data);
  el('scr-' + name).classList.add('on');
  window.scrollTo(0, 0);
}

let armed = false;   // is our one history entry in place yet
function mark(name) {
  try {
    if (armed) window.history.replaceState({ screen: name }, '');
    else { window.history.pushState({ screen: name }, ''); armed = true; }
  } catch (e) { /* no history API: no Back button, nothing else lost. (window. is
                  needed: the engine has a top-level `history` of its own, the undo stack.) */ }
}

function go(name, data) {
  show(name, data);
  mark(name);
}

function back() {
  if (!el('rules').classList.contains('hidden')) { el('rules').classList.add('hidden'); return; }
  if (activeScreen === 'battle') { setPause(!pauseOpen); return; }
  if (activeScreen === 'settings') { go(settingsFrom); return; }
  const to = BACK_TO[activeScreen];
  if (to) go(to);
}

window.addEventListener('popstate', () => {
  armed = false;      // the browser just took our entry; put it back
  mark(activeScreen);
  back();
});

/* ---------- what each screen does when it comes up ---------- */

const ENTER = {
  title() {
    el('t-continue').hidden = true;   // milestone 2: shown when a save exists
  },
  signin() {
    el('s-name').value = profile.name;
  },
  campaign() {
    el('c-header').textContent =
      (profile.name || 'Captain') + ' · Contracts fulfilled: 0 / ' + MAPS.length;
    const box = el('c-stops');
    box.innerHTML = '';
    MAPS.forEach((m, i) => {
      const b = document.createElement('button');
      b.className = 'plaque';
      b.innerHTML = '<span class="n">' + (i + 1) + '</span>' + m.name;
      b.onclick = () => go('briefing', i);
      box.appendChild(b);
    });
  },
  briefing(i) {
    if (i !== undefined) briefingIndex = i;
    const m = MAPS[briefingIndex];
    el('b-name').textContent = m.name;
    el('b-brief').textContent = m.problem || m.brief;
    el('b-teaches').textContent = 'This contract teaches: ' + m.teaches;
  },
  battle() {
    setPause(false);
  },
  result(r) {
    lastResult = r;
    el('r-title').textContent = r.won ? 'Contract fulfilled' : 'Contract failed';
    el('r-reason').textContent = r.reason;
    el('r-detail').textContent = r.won
      ? 'Men lost: ' + r.lost + ' · Turns: ' + r.turns
      : '';
    el('r-next').hidden = !(r.won && r.index < MAPS.length - 1);
    el('r-retry').hidden = r.won;
  },
  settings() {}
};

/* ---------- into and out of the board ---------- */

function startBattle(index) {
  briefingIndex = index;
  go('battle');
  startMission(index);
}

function setPause(on) {
  pauseOpen = on;
  el('pause').classList.toggle('hidden', !on);
}

onMissionEnd = r => { setPause(false); go('result', r); };
boardActive = () => activeScreen === 'battle' && !pauseOpen;

/* ---------- buttons ---------- */

el('t-continue').onclick = () => go('campaign');
el('t-new').onclick = () => go('signin');            // milestone 2: confirm before wiping a save
el('t-settings').onclick = () => { settingsFrom = 'title'; go('settings'); };

el('s-guest').onclick = () => { profile.name = el('s-name').value.trim(); go('campaign'); };
el('s-back').onclick = () => go('title');

el('c-back').onclick = () => go('title');

el('b-accept').onclick = () => startBattle(briefingIndex);
el('b-back').onclick = () => go('campaign');

el('p-resume').onclick = () => setPause(false);
el('p-restart').onclick = () => { setPause(false); startMission(mapIndex); };
el('p-rules').onclick = () => openRules();
el('p-settings').onclick = () => { settingsFrom = 'battle'; go('settings'); };
el('p-abandon').onclick = () => {
  if (confirm('Abandon this contract and return to the campaign map?')) {
    setPause(false);
    go('campaign');
  }
};

el('r-next').onclick = () => go('briefing', lastResult.index + 1);
el('r-retry').onclick = () => startBattle(lastResult.index);
el('r-campaign').onclick = () => go('campaign');

el('st-back').onclick = () => go(settingsFrom);

/* ---------- boot ---------- */

el('version').textContent = 'v' + VERSION;
try { window.history.replaceState({ screen: 'title' }, ''); } catch (e) {}
go('title');
