/* ============================================================
   SOUND

   Twenty short cues, embedded in the page by the build (see
   tools/build.js and assets/sfx/). Nothing here knows about the rules:
   the engine announces what happened through onGameEvent(), the board
   and the shell call SFX.play() for taps and screens, and this file
   turns both into noise. Sources and licences: assets/ATTRIBUTION.md.

   Browsers will not make a sound until the player has touched the page,
   so the audio context is created on the first tap and the cues are
   decoded then. A cue asked for before its buffer is ready simply waits
   for it — the first tap's click is not lost.
   ============================================================ */

/* SFX are injected by the build */

const SFX = (() => {
  /* how loud each cue plays, relative to the master */
  const LEVEL = {
    move: .55, move_2: .55, move_3: .55, move_rough: .6, move_water: .6,
    select: .7, deselect: .7, deny: .9, anchor: 1,
    kill: 1, kill_them: 1, bolt: .9, charge: .8,
    arrive: .8, arrive_them: .8, objective: .6, recruit: .9,
    ui: .6, turn: .9, victory: 1, victory_clean: 1, defeat: 1
  };
  /* a plain step is one of three takes, never the same twice running */
  const STEPS = ['move', 'move_2', 'move_3'];
  let lastStep = -1;

  let ctx = null, master = null;
  const buffers = {};          // name -> Promise<AudioBuffer>
  const lastAt = {};           // name -> when it last started, to squash doubles
  const data = typeof SFX_DATA !== 'undefined' ? SFX_DATA : {};

  const bytes = b64 => {
    const s = atob(b64), out = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
    return out.buffer;
  };

  /* First touch: open the context and decode everything. Safe to call
     more than once; only the first does any work. */
  function unlock() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume().catch(() => {}); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    try { ctx = new AC(); } catch (e) { return; }
    master = ctx.createGain();
    master.gain.value = 0.9;
    master.connect(ctx.destination);
    if (ctx.state === 'suspended') ctx.resume().catch(() => {});
    for (const name in data) {
      buffers[name] = new Promise((ok, no) => {
        try { ctx.decodeAudioData(bytes(data[name]), ok, no); } catch (e) { no(e); }
      }).catch(() => null);
    }
  }
  for (const ev of ['pointerdown', 'touchend', 'keydown']) {
    document.addEventListener(ev, unlock, { capture: true, passive: true });
  }
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden && ctx && ctx.state === 'suspended') ctx.resume().catch(() => {});
  });

  /* The shell points `enabled` at the player's setting. `loaded()` is for
     checking from the console: how many cues decoded after the first tap. */
  const api = {
    enabled: () => true,
    unlock,
    loaded: () => Promise.all(Object.values(buffers)).then(bs => bs.filter(Boolean).length)
  };

  /*  play('kill')                      now
      play('arrive', { delay: 350 })    a little after
      play('move', { rate: 1.03 })      a touch quicker                  */
  api.play = function (name, opt) {
    if (!api.enabled() || !ctx) return;
    const o = opt || {};
    if (name === 'move') {
      let i; do { i = Math.floor(Math.random() * STEPS.length); } while (i === lastStep);
      lastStep = i; name = STEPS[i];
      if (o.rate === undefined) o.rate = 0.96 + Math.random() * 0.08;
    }
    const p = buffers[name];
    if (!p) return;
    const now = performance.now() + (o.delay || 0);
    if (lastAt[name] !== undefined && Math.abs(now - lastAt[name]) < 40) return;
    lastAt[name] = now;
    p.then(buf => {
      if (!buf || !api.enabled()) return;
      const src = ctx.createBufferSource();
      src.buffer = buf;
      if (o.rate) src.playbackRate.value = o.rate;
      const g = ctx.createGain();
      g.gain.value = (LEVEL[name] === undefined ? 1 : LEVEL[name]) * (o.gain === undefined ? 1 : o.gain);
      src.connect(g); g.connect(master);
      src.start(ctx.currentTime + (o.delay || 0) / 1000);
    });
  };

  return api;
})();

/* ---------- what the engine announces ---------- */

onGameEvent = (kind, d) => {
  switch (kind) {
    case 'move': {
      const ours = d.piece.side === PLAYER;
      const step = d.mire ? 'move_water' : d.effect === 'rough' ? 'move_rough' : 'move';
      if (d.victim && d.piece.type === 'cavaliere') SFX.play('charge');
      else SFX.play(step, { gain: ours ? 1 : .8 });
      if (d.victim) {
        SFX.play(d.victim.side === PLAYER ? 'kill_them' : 'kill',
                 { delay: d.piece.type === 'cavaliere' ? 300 : 90 });
      }
      break;
    }
    case 'shot':
      SFX.play('bolt');
      SFX.play(d.victim.side === PLAYER ? 'kill_them' : 'kill', { delay: 140 });
      break;
    case 'arrive':
      SFX.play(d.side === PLAYER ? 'arrive' : 'arrive_them', { delay: 350 });
      break;
    case 'turn':
      if (d.side === FOE) SFX.play('turn', { delay: 200 });
      break;
  }
};

/* Every button in the shell clicks the same way; the board's own two
   have their own voices, and a recruit is taken with coins. */
document.addEventListener('click', e => {
  const b = e.target.closest && e.target.closest('button');
  if (!b || b.disabled) return;
  if (b.id === 'endturn' || b.id === 'undo') return;
  if (/^r-pick-/.test(b.id)) { SFX.play('recruit'); return; }
  SFX.play('ui');
});
