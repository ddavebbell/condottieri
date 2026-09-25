/* One source of truth. The page and the solver are built from the same rules. */
const fs = require('fs'), path = require('path');
const S = f => fs.readFileSync(path.join(__dirname, '..', f), 'utf8');

const engine = S('src/engine.js');
const maps   = S('src/maps.part.js');
const ui     = S('src/ui.part.js');

const bundle = engine.replace('/* MAPS are injected by the build */', maps);
fs.writeFileSync(path.join(__dirname,'..','src/engine.bundle.js'), bundle);

const page = S('src/shell.head.html') + '<script>\n' + bundle + '\n' + ui + '\n</scr'+'ipt>' + S('src/shell.tail.html');
fs.writeFileSync(path.join(__dirname,'..','dist.html'), page);

console.log('built  engine.bundle.js  %d KB', (bundle.length/1024).toFixed(0));
console.log('built  dist.html        %d KB', (page.length/1024).toFixed(0));
