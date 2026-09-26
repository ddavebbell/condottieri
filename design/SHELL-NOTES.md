# Shell notes

What was built for `FULL-GAME-SHELL.md`, and where things live. Written
2026-09-25 at the end of milestone 7.

## The screen router

`prototype/src/screens.part.js` owns everything around the board. Each screen
is a `<section class="screen" id="scr-NAME">` in `shell.head.html`; exactly one
carries `.on`, which is a 200ms fade (none under `prefers-reduced-motion`).
`go(name, data)` turns a screen on, runs its `ENTER[name](data)` setup, and
marks history. The page keeps exactly one history entry above the one it was
opened on: the first `go` pushes it, every later `go` replaces it, and when
the browser pops it, `popstate` pushes it straight back and calls `back()`.
`back()` closes the rules card if open, toggles the pause menu on the battle,
returns Settings and Sign in to wherever they were opened from, and otherwise
follows `BACK_TO`. Back on the title stays put. The Back button can therefore
never leave the page. One trap: the engine declares a top-level `history` (the
undo stack), so shell code must say `window.history`.

`ui.part.js` knows nothing about screens. It offers three hooks the shell
plugs into: `startMission(index)`, `onMissionEnd(result)` (fired once per
mission, from the first `render()` after the engine sets `state.over`), and
`boardActive()` (taps and keys are ignored unless the battle is up and the
pause menu is closed). The engine's `loadMap()` still calls `showBriefing()`,
which now only re-arms the end hook.

## Saving

All of it is in the SAVING section at the top of `screens.part.js`.
`loadProfile()` and `saveProfile()` are the only two places that touch
`localStorage`, under the key `condottieri.save.v1`. Both are wrapped in
try/catch; a blocked or corrupt save boots a fresh player. `saveProfile()` also
calls `pushSave()`, which does nothing unless the page is served over http(s)
and the player is signed in.

The format:

    { "profile":  { "name": "Dave" },
      "settings": { "tex": 0.5, "threat": true, "faces": true, "sound": true },
      "progress": { "0": { "name": "Skirmish on the Road", "won": true,
                           "flawless": true, "bestTurns": 7 } } }

`progress` is keyed by map index and records the map's name so a reorder can
be migrated. `flawless` comes from the captured list (`missionResult()` in
`ui.part.js`), never re-derived. A `company` field is reserved and carried
through untouched. The debug unlock (five taps on the campaign title) is a
session variable and is never saved.

## The server

`worker/` is a Cloudflare Worker (see its README). It serves `dist.html` as a
static asset and keeps one row per Google account in D1 with the same save
JSON. On boot the page calls `/api/me`; if signed in it merges the server copy
into the device copy with `mergeRemote()` (progress is the union, flawless and
best turns only improve, a server name or setting wins over a blank one) and
pushes the result back. Sign out clears the device copy but keeps settings.
Opened from a file, `ONLINE` is false and none of this runs. The Google
client id is in `worker/wrangler.jsonc`; the secret is a Worker secret.

## Adding a screen

1. Add `<section class="screen shell" id="scr-NAME">` to `shell.head.html`
   with a `.grow` spacer and a `.stack` of `.plaque` buttons at the bottom.
2. Add `NAME` to `BACK_TO` in `screens.part.js`, and an `ENTER.NAME(data)`
   if it needs setting up when shown.
3. Wire its buttons at the bottom of `screens.part.js` with `go()`.
4. Build with `node tools/build.js`; the section is bundled automatically.

## Testing

`node test/rules.test.js` for the rules (29). The shell was checked by
driving `dist.html` in headless Chrome over the DevTools protocol (no
Playwright on the machine); those scripts lived in a scratch folder and are
not in the repo. Each milestone's walk is easy to redo by hand: title, guest
sign-in, tap a seal, accept, play, pause, settings, win, next contract.

## Rough edges and things I was unsure about

- Confirmations (new campaign, abandon, reset) use `window.confirm`. Fine on a
  phone, but not styled.
- The result screen shows the seal of the map's number, not a mission-specific
  emblem.
- `enemyStep` timers keep running for a few hundred milliseconds after
  Abandon; harmless, since the next `startMission` resets everything, but a
  cancel hook in the engine would be cleaner. Not done: the engine is
  off-limits.
- The carved piece figures are still embedded (~31 KB) but switched off; the
  `ART` set in `ui.part.js` turns them back on per type.
- The campaign map's town positions are approximate and the route was laid
  out to avoid crossing itself, not for geography.
- Google's consent screen may still be in Testing mode, which limits sign-in
  to listed test users until it is published.
