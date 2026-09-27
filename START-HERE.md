# Socii

## Play it

- https://socii.daverichardbell.workers.dev — on your phone, with Google sign-in
- `prototype/dist.html` — the same build, opened from disk (guest only)

Deploying: `cd worker && node tools/stage.js && wrangler deploy` (see `worker/README.md`).

One build, generated from `src/`. Two copies of a game is how they drift apart.

## The code

    cd prototype
    node tools/build.js            rebuild dist.html from src/
    node test/rules.test.js        29 rule tests
    node tools/grade.js 0 12 8     grade every map (~80s)
    node tools/trace3.js 0 32 12   solve one map, with a trace
    node tools/uses.js 0 6         which mechanics a winning line really uses

**Edit `src/`, never `dist.html`.** Sounds and the typeface live in
`prototype/assets/` and are embedded by the build; `assets/ATTRIBUTION.md`
lists where each came from and the one credit the game owes.

## Where it stands

Five men against seven or eight, thirteen maps, all solvable and all winnable
without losing anybody. 4 easy, 6 medium, 3 hard.

The full-game shell (title, campaign map, briefing, battle, result, settings,
saving, accounts) is built; notes in `design/SHELL-NOTES.md`.

Next: play them. Then persist the company between missions — see
`design/condottieri-company.md`.
