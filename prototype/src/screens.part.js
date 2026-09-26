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

const VERSION = '0.4.0';

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
  pushSave();
}

/* ---------- the server ----------
   Served by the Worker (worker/), a signed-in player's save also lives
   on the server and every saveProfile() is pushed there. Opened as a
   file there is no server, and none of this does anything. */

const ONLINE = /^https?:$/.test(location.protocol);
let account = null;   // { name } while signed in with Google

/* Fold the server's copy into this device's: progress is the union,
   a name or a setting from the server wins over a blank one here. */
function mergeRemote(remote) {
  if (!remote || typeof remote !== 'object') return;
  if (remote.profile && typeof remote.profile.name === 'string' && remote.profile.name) save.profile.name = remote.profile.name;
  if (remote.settings && typeof remote.settings === 'object') Object.assign(save.settings, remote.settings);
  if (remote.progress && typeof remote.progress === 'object') {
    for (const k of Object.keys(remote.progress)) {
      const a = save.progress[k], b = remote.progress[k];
      if (!b || typeof b !== 'object') continue;
      if (!a) { save.progress[k] = b; continue; }
      save.progress[k] = {
        name: b.name || a.name,
        won: !!(a.won || b.won),
        flawless: !!(a.flawless || b.flawless),
        bestTurns: (a.bestTurns && b.bestTurns) ? Math.min(a.bestTurns, b.bestTurns) : (a.bestTurns || b.bestTurns)
      };
    }
  }
  if (remote.company) save.company = remote.company;
}

async function fetchAccount() {
  if (!ONLINE) return;
  try {
    const r = await fetch('/api/me', { credentials: 'same-origin' });
    if (!r.ok) return;
    const me = await r.json();
    if (!me.signedIn) return;
    account = { name: me.name || '' };
    mergeRemote(me.save);
    if (!save.profile.name) save.profile.name = account.name;
    applySettings();
    saveProfile();
    /* Straight from Google's redirect: land on the campaign. Otherwise
       just refresh the screen we are on, so Continue can appear. */
    if (location.hash === '#signedin') {
      window.history.replaceState(window.history.state, '', location.pathname);
      go('campaign');
    } else if (activeScreen === 'title' || activeScreen === 'signin' || activeScreen === 'campaign') {
      ENTER[activeScreen]();
    }
  } catch (e) { /* offline, or no server: play as a guest */ }
}

let pushTimer = null;
function pushSave() {
  if (!ONLINE || !account) return;
  clearTimeout(pushTimer);
  pushTimer = setTimeout(() => {
    fetch('/api/save', {
      method: 'PUT', credentials: 'same-origin', keepalive: true,
      headers: { 'content-type': 'application/json' }, body: JSON.stringify(save)
    }).catch(() => {});
  }, 300);
}

/* Signing out also clears this device's copy, so the next player on a
   shared phone does not inherit the campaign. Settings stay. */
async function signOut() {
  try { await fetch('/auth/logout', { method: 'POST', credentials: 'same-origin' }); } catch (e) {}
  account = null;
  const settings = save.settings;
  save = freshSave();
  save.settings = settings;
  saveProfile();
}

/* A save worth continuing: the player has a name or has played. */
const hasSave = () => !!save.profile.name || Object.keys(save.progress).length > 0;

const wonCount = () => Object.values(save.progress).filter(p => p.won).length;

/* Missions open one at a time. debugUnlock (five taps on the campaign
   title) opens them all for this session only; it is never saved. */
let debugUnlock = false;
const isUnlocked = i => debugUnlock || i === 0 || !!(save.progress[i - 1] && save.progress[i - 1].won);

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
    el('s-google').hidden = !ONLINE || !!account;
    el('s-status').textContent = account ? 'Signed in with Google as ' + account.name + '.'
      : ONLINE ? 'Sign in to keep your campaign across phones.'
      : 'Signing in needs the online version of the game.';
  },
  campaign() {
    el('c-header').textContent =
      (save.profile.name || 'Captain') + ' · Contracts fulfilled: ' + wonCount() + ' / ' + MAPS.length;
    drawCampaign();
  },
  briefing(i) {
    if (i !== undefined) briefingIndex = i;
    const m = MAPS[briefingIndex];
    el('b-name').textContent = m.name;
    el('b-brief').textContent = m.brief;
    el('b-problem').textContent = m.problem || '';
    el('b-obj').textContent = objectiveFor(briefingIndex);
    el('b-teaches').textContent = m.teaches;
    drawPreview(briefingIndex);
  },
  battle() {
    setPause(false);
  },
  result(r) {
    lastResult = r;
    const flawless = r.won && r.lost === 0;
    el('r-title').textContent = r.won ? 'Contract fulfilled' : 'Contract failed';
    el('r-title').className = r.won ? 'won' : 'lost';
    el('r-reason').textContent = r.reason;
    const box = el('r-seal');
    box.innerHTML = '';
    const s = svg('svg', { viewBox: '-32 -32 64 64' });
    s.appendChild(sealNode(r.won ? (flawless ? 'flawless' : 'won') : 'lost', r.index + 1));
    box.appendChild(s);
    el('r-stats').innerHTML = r.won
      ? '<div><b>' + r.lost + '</b>men lost</div><div><b>' + r.turns + ' / ' + MAPS[r.index].turnLimit + '</b>turns used</div>'
      : '';
    el('r-flawless').textContent = flawless ? 'Not a man lost. The laurel is yours.' : '';
    el('r-next').hidden = !(r.won && r.index < MAPS.length - 1);
    el('r-retry').hidden = r.won;
  },
  settings() {
    el('st-signout').hidden = !account;
  }
};

/* ============================================================
   THE CAMPAIGN MAP

   The parchment, coast, rivers and compass are static SVG in
   shell.head.html. Here: the thirteen stops, the dotted road through
   them, and a wax seal on each. Coordinates are in the map's 360x480
   viewBox and follow the towns of the Po valley, west to east.
   ============================================================ */

const STOPS = [
  [58, 262], [96, 290], [138, 262], [150, 206], [196, 168], [232, 190], [212, 240],
  [252, 262], [264, 208], [292, 176], [302, 222], [314, 266], [338, 208]
];

const SVG_NS = 'http://www.w3.org/2000/svg';
function svg(tag, attrs, text) {
  const e = document.createElementNS(SVG_NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (text !== undefined) e.textContent = text;
  return e;
}

/* The objective line for a map that is not loaded. objectiveText() reads
   the engine's current map, so lend it this one for a moment. */
function objectiveFor(i) {
  const was = map;
  map = MAPS[i];
  try { return objectiveText(); } finally { map = was; }
}

/* A small copy of the board before the battle: terrain, walls, the
   objective region and the starting pieces, all straight from the map. */
function drawPreview(i) {
  const m = MAPS[i];
  const cell = Math.min(30, Math.floor(320 / m.width));
  const goal = m.objective.tiles || [];
  const walls = new Set((m.walls || []).map(w => wallKey(w[0][0], w[0][1], w[1][0], w[1][1])));
  const at = (x, y) => m.pieces.find(p => p.x === x && p.y === y);
  let html = '<div class="mini" style="grid-template-columns:repeat(' + m.width + ',' + cell + 'px);--cell:' + cell + 'px">';
  for (let y = 0; y < m.height; y++) for (let x = 0; x < m.width; x++) {
    const t = TERRAIN[m.terrain[y][x]] || TERRAIN['.'];
    let cls = 'cell ' + t.css;
    if (t.css === 't-open' && (x + y) % 2 === 1) cls += ' alt';
    if (t.css === 't-marble') cls += slab(x, y);
    if (inRegion(goal, x, y)) cls += ' goal';
    html += '<div class="' + cls + '">' + (t.void ? '' : '<span class="ground"></span>');
    for (const [dx, dy, k] of [[0,-1,'n'],[0,1,'s'],[-1,0,'w'],[1,0,'e']])
      if (walls.has(wallKey(x, y, x + dx, y + dy))) html += '<span class="wall w-' + k + '"></span>';
    const p = at(x, y);
    if (p) html += '<span class="pc p-' + p.side + '">' + glyphOf(p.type) + '</span>';
    html += '</div>';
  }
  html += '</div><p class="cap">' + m.turnLimit + ' turns · ' + m.commands.rosso + ' commands a turn</p>';
  el('b-preview').innerHTML = html;
}

/* A wax seal: locked | open | won | flawless | lost. Shared by the map
   and the result screen. Radius about 15 units around (0,0). */
function sealNode(state, label) {
  const g = svg('g', { class: 'seal ' + state });
  g.appendChild(svg('ellipse', { class: 'sh', cx: 1.5, cy: 2.5, rx: 14, ry: 13 }));
  const body = svg('g', { class: 'pulse' });
  body.appendChild(svg('path', { class: 'wax',
    d: 'M0 -14 c8 0 14 6 14 13 c0 8 -6 14 -14 15 c-8 -1 -14 -6 -15 -14 c0 -8 7 -14 15 -14z' }));
  body.appendChild(svg('circle', { class: 'stamp', r: 8.5 }));
  body.appendChild(svg('text', { y: 3.6 }, label));
  if (state === 'lost') body.appendChild(svg('path', { class: 'crack', d: 'M-9 -11 l4 5 l-3 4 l5 5 l-2 6 l4 3' }));
  g.appendChild(body);
  if (state === 'flawless') {
    g.appendChild(svg('path', { class: 'laurel', d: 'M-17 6 c-5 -9 -2 -18 5 -23' }));
    g.appendChild(svg('path', { class: 'laurel', d: 'M17 6 c5 -9 2 -18 -5 -23' }));
  }
  return g;
}

/* locked | open | won | flawless */
function stopState(i) {
  const p = save.progress[i];
  if (p && p.won) return p.flawless ? 'flawless' : 'won';
  return isUnlocked(i) ? 'open' : 'locked';
}

function drawCampaign() {
  const n = Math.min(STOPS.length, MAPS.length);
  el('c-route').innerHTML = '';
  el('c-route').appendChild(svg('path', {
    class: 'route',
    d: STOPS.slice(0, n).map(([x, y], i) => (i ? 'L' : 'M') + x + ' ' + y).join(' ')
  }));

  const seals = el('c-seals');
  seals.innerHTML = '';
  let next = null;
  for (let i = 0; i < n; i++) {
    const [x, y] = STOPS[i], state = stopState(i);
    if (next === null && state === 'open') next = i;
    const g = sealNode(state, i + 1);
    g.setAttribute('transform', 'translate(' + x + ' ' + y + ')');
    g.insertBefore(svg('title', {}, (i + 1) + '. ' + MAPS[i].name), g.firstChild);
    const hit = svg('circle', { class: 'hit', r: 22 });   // a thumb-sized target
    hit.addEventListener('click', () => pickStop(i));
    g.appendChild(hit);
    seals.appendChild(g);
  }
  el('c-next').textContent = next === null
    ? (wonCount() >= n ? 'Every contract fulfilled.' : '')
    : 'Next: ' + MAPS[next].name;
}

function pickStop(i) {
  if (!isUnlocked(i)) return;
  go('briefing', i);
}

/* Five taps on the title open every contract, for testing. */
let titleTaps = 0;
el('c-title').addEventListener('click', () => {
  if (debugUnlock) return;
  if (++titleTaps < 5) return;
  debugUnlock = true;
  el('c-header').textContent = 'Every contract unlocked (debug)';
  drawCampaign();
});

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
el('s-google').onclick = () => {
  save.profile.name = el('s-name').value.trim();   // keep what they typed
  saveProfile();
  location.href = '/auth/google';
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

el('st-signout').onclick = async () => { await signOut(); go('title'); };
el('st-back').onclick = () => go(settingsFrom);

/* ---------- boot ---------- */

loadProfile();
applySettings();
el('version').textContent = 'v' + VERSION;
try { window.history.replaceState({ screen: 'title' }, ''); } catch (e) {}
go('title');
fetchAccount();
