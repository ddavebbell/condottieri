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

const VERSION = '0.2.0';

/* ============================================================
   SAVING

   One JSON blob under one key. Everything that reads or writes it goes
   through loadProfile() and saveProfile(), so a server can be put
   behind them later without touching the screens. Storage may be
   blocked (private browsing) or the blob may be junk: either way the
   game starts as a fresh player and never throws.

   progress is keyed by map index and also records the map's name, so
   a reordering of MAPS can be migrated. "company" is reserved for the
   persistent company (design/condottieri-company.md).
   ============================================================ */

const SAVE_KEY = 'condottieri.save.v1';

function freshSave() {
  return {
    profile:  { name: '' },
    settings: { tex: 0.5, threat: true, faces: true, sound: true },
    progress: {}
  };
}

let save = freshSave();

function loadProfile() {
  save = freshSave();
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return save;
    const got = JSON.parse(raw);
    if (got && typeof got === 'object') {
      if (got.profile && typeof got.profile.name === 'string') save.profile.name = got.profile.name;
      if (got.settings && typeof got.settings === 'object') Object.assign(save.settings, got.settings);
      if (got.progress && typeof got.progress === 'object') save.progress = got.progress;
      if (got.company) save.company = got.company;
    }
  } catch (e) { /* no storage, or a broken save: fresh player */ }
  return save;
}

function saveProfile() {
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(save)); }
  catch (e) { /* no storage: the session still plays, it just will not keep */ }
}

/* A save worth continuing: the player has a name or has played. */
const hasSave = () => !!save.profile.name || Object.keys(save.progress).length > 0;

const wonCount = () => Object.values(save.progress).filter(p => p.won).length;
const isUnlocked = i => i === 0 || !!(save.progress[i - 1] && save.progress[i - 1].won);

/* Fold a finished mission into progress. Flawless means no man of ours
   was taken, straight from the captured list; nothing is re-derived. */
function recordResult(r) {
  if (!r.won) return;
  const prev = save.progress[r.index] || {};
  save.progress[r.index] = {
    name: r.name,
    won: true,
    flawless: !!prev.flawless || r.lost === 0,
    bestTurns: prev.bestTurns ? Math.min(prev.bestTurns, r.turns) : r.turns
  };
  saveProfile();
}

/* ---------- settings, applied to the board's own controls ----------
   The controls still live on the battle panel until milestone 6; here
   they are set from the save on load and written back when touched. */

function applySettings() {
  const s = save.settings;
  document.documentElement.style.setProperty('--tex', s.tex);
  document.querySelectorAll('.texrow button').forEach(b =>
    b.className = Number(b.dataset.tex) === Number(s.tex) ? 'on' : '');
  el('threat').checked = !!s.threat;
  el('faces').checked = !!s.faces;
}

document.querySelectorAll('.texrow button').forEach(b => b.addEventListener('click', () => {
  save.settings.tex = Number(b.dataset.tex);
  saveProfile();
}));
el('threat').addEventListener('change', () => { save.settings.threat = el('threat').checked; saveProfile(); });
el('faces').addEventListener('change', () => { save.settings.faces = el('faces').checked; saveProfile(); });

/* ============================================================
   ROUTER
   ============================================================ */

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
    el('t-continue').hidden = !hasSave();
  },
  signin() {
    el('s-name').value = save.profile.name;
  },
  campaign() {
    el('c-header').textContent =
      (save.profile.name || 'Captain') + ' · Contracts fulfilled: ' + wonCount() + ' / ' + MAPS.length;
    const box = el('c-stops');
    box.innerHTML = '';
    MAPS.forEach((m, i) => {
      const b = document.createElement('button');
      const p = save.progress[i];
      b.className = 'plaque';
      b.disabled = !isUnlocked(i);
      b.innerHTML = '<span class="n">' + (i + 1) + '</span>' + m.name
        + (p && p.won ? ' <span class="n">' + (p.flawless ? '✦ flawless' : '✓') + '</span>' : '');
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
      ? 'Men lost: ' + r.lost + ' · Turns: ' + r.turns + (r.lost === 0 ? ' · Flawless' : '')
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

/* Progress is saved before the Result screen is shown. */
onMissionEnd = r => { recordResult(r); setPause(false); go('result', r); };
boardActive = () => activeScreen === 'battle' && !pauseOpen;

/* ---------- buttons ---------- */

el('t-continue').onclick = () => go('campaign');
el('t-new').onclick = () => {
  if (hasSave() && !confirm('Start a new campaign? Your progress will be wiped.')) return;
  const settings = save.settings;   // a new campaign keeps the player's settings
  save = freshSave();
  save.settings = settings;
  saveProfile();
  go('signin');
};
el('t-settings').onclick = () => { settingsFrom = 'title'; go('settings'); };

el('s-guest').onclick = () => {
  save.profile.name = el('s-name').value.trim();
  saveProfile();
  go('campaign');
};
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

loadProfile();
applySettings();
el('version').textContent = 'v' + VERSION;
try { window.history.replaceState({ screen: 'title' }, ''); } catch (e) {}
go('title');
