/* One source of truth. The page and the solver are built from the same rules. */
const fs = require('fs'), path = require('path');
const S = f => fs.readFileSync(path.join(__dirname, '..', f), 'utf8');

const engine = S('src/engine.js');
const sound  = S('src/sound.part.js');    // the cues, on top of the engine's events
const maps   = S('src/maps.part.js');
const ui     = S('src/ui.part.js');
const screens = S('src/screens.part.js');   // the shell around the board, after the board
const tutorial = S('src/tutorial.part.js');  // the guided first contract, on top of both

const bundle = engine.replace('/* MAPS are injected by the build */', maps);
fs.writeFileSync(path.join(__dirname,'..','src/engine.bundle.js'), bundle);

/* Assets are embedded so the page stays one file that opens from disk.
   Fonts: assets/font/Cardo-*.woff2 become @font-face rules in the head.
   Sounds: assets/sfx/*.wav become SFX_DATA, a name -> base64 table. */
const A = f => fs.readFileSync(path.join(__dirname, '..', 'assets', f)).toString('base64');
const faces = [['Regular', 400, 'normal'], ['Italic', 400, 'italic'], ['Bold', 700, 'normal']].map(([file, weight, style]) =>
  `  @font-face { font-family: 'Cardo'; font-weight: ${weight}; font-style: ${style}; font-display: swap;\n` +
  `    src: url('data:font/woff2;base64,${A('font/Cardo-' + file + '.woff2')}') format('woff2'); }`).join('\n');
const shellHead = S('src/shell.head.html');
const head = shellHead.replace(/  \/\* FONTS are injected by the build[^\n]*\n/, () => faces + '\n');
if (head === shellHead) throw new Error('shell.head.html: FONTS marker missing');

const sfxDir = path.join(__dirname, '..', 'assets', 'sfx');
const cues = fs.readdirSync(sfxDir).filter(f => f.endsWith('.wav')).sort()
  .map(f => `  ${JSON.stringify(f.replace(/\.wav$/, ''))}: ${JSON.stringify(A('sfx/' + f))}`);
const soundWithData = sound.replace('/* SFX are injected by the build */', () => 'const SFX_DATA = {\n' + cues.join(',\n') + '\n};');
if (soundWithData === sound) throw new Error('sound.part.js: SFX marker missing');

const page = head + '<script>\n' + bundle + '\n' + soundWithData + '\n' + ui + '\n' + screens + '\n' + tutorial + '\n</scr'+'ipt>' + S('src/shell.tail.html');
fs.writeFileSync(path.join(__dirname,'..','dist.html'), page);

console.log('built  engine.bundle.js  %d KB', (bundle.length/1024).toFixed(0));
console.log('built  dist.html        %d KB  (%d cues, 3 font faces embedded)', (page.length/1024).toFixed(0), cues.length);
