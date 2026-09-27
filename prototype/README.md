# Condottieri — engine, tests and solver

Built overnight against the plan in `condottieri-solver-plan.md`.

## Layout

    src/rules.part.js   the rules, cut out of the page
    src/maps.part.js    the three maps, on their own
    src/ui.part.js      the board: rendering and input
    src/screens.part.js the shell around it: title, campaign, briefing, result, settings, router
    src/tutorial.part.js the guided first contract: scrim, spotlight, cards
    src/sound.part.js   the cues: Web Audio, hung on the engine's onGameEvent()
    src/shell.*.html    the page around them
    assets/sfx/         the 22 WAV cues, embedded by the build (assets/ATTRIBUTION.md)
    assets/font/        Cardo regular, italic, bold (WOFF2, OFL)
    src/engine.js       rules + a pure state-passing interface   <- the important one
    tools/build.js      stitches engine + maps + sound + ui -> dist.html and engine.bundle.js,
                        embedding the fonts and the cues as base64
    tools/lib.js        search machinery and the heuristic
    tools/measure.js    step 1: how big is the state space
    tools/solve.js      the beam solver
    tools/trace3.js     solve with a turn-by-turn trace
    tools/parity.js     checks the solver plays the same game the player does
    test/rules.test.js  29 rule tests, run against the engine directly

## Running it

    node tools/build.js          # rebuild dist.html and the bundle
    node test/rules.test.js      # 29 tests
    node tools/measure.js 2      # state space per turn
    node tools/trace3.js 0 32 12 # solve map 0, beam 32 parents, 12 partials per command

`dist.html` is the playable game, built from the same engine the solver uses.
There is one implementation of the rules and there must never be two.
