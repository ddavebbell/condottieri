# Condottieri

## Play it

- https://claude.ai/artifact/9cPj1TVikKUJdEamtAjCif — on your phone
- `prototype/dist.html` — the same build, locally

One build, generated from `src/`. Two copies of a game is how they drift apart.

## The code

    cd prototype
    node tools/build.js            rebuild dist.html from src/
    node test/rules.test.js        29 rule tests
    node tools/grade.js 0 12 8     grade every map (~80s)
    node tools/trace3.js 0 32 12   solve one map, with a trace
    node tools/uses.js 0 6         which mechanics a winning line really uses

**Edit `src/`, never `dist.html`.**

## Where it stands

Five men against seven or eight, thirteen maps, all solvable and all winnable
without losing anybody. 4 easy, 6 medium, 3 hard.

Next: play them. Then persist the company between missions — see
`design/condottieri-company.md`.
