# Condottieri

Everything for the project, in one place.

## Play it

- `condottieri-mobile.html` — open in a browser. Also published at
  https://claude.ai/artifact/9cPj1TVikKUJdEamtAjCif
- `prototype/dist.html` — the same game, built from source

## The code

    cd prototype
    node tools/build.js        rebuild dist.html from src/
    node test/rules.test.js    29 rule tests
    node tools/grade.js 0 12 8 grade every map (~80s)
    node tools/trace3.js 0 32 12   solve one map, with a trace
    node tools/uses.js 0 6     which mechanics a winning line actually uses

**Edit `src/`, never `dist.html`.** The page is generated. Hand-editing it means
the game and the solver start disagreeing, which is exactly the bug that once
produced a false two-turn win.

    src/engine.js        the rules + the solver's interface
    src/maps.part.js     the thirteen maps
    src/ui.part.js       rendering and input
    src/shell.*.html     the page around the script

## The design

    design/condottieri-gdd.md              the design doc
    design/condottieri-piece-reference.md  pieces and terrain at a glance
    design/condottieri-company.md          the campaign layer: names, attrition, recruits
    design/condottieri-map-concepts.md     24 map ideas and the layout devices behind them
    design/condottieri-maps.md             the 13 built maps, as the solver grades them
    design/condottieri-solver-plan.md      what the solver is for
    design/condottieri-solver-findings.md  what it found
    design/condottieri-user-stories.md     the backlog

## Where it stands

Five men against eight, thirteen maps, all solvable and all winnable without
losing anybody. 4 easy, 6 medium, 3 hard.

Next: persist the company between missions (see `condottieri-company.md`), and
build maps from the concepts list — the solver says in ten seconds whether a new
one is a real map or just a backdrop.
