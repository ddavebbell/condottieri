/* Build the game and stage it as the Worker's one static asset.
   prototype/dist.html -> worker/public/index.html. The game is still built
   by prototype/tools/build.js; this only copies the result. */
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const root = path.join(__dirname, '..', '..');
execFileSync(process.execPath, [path.join(root, 'prototype', 'tools', 'build.js')], { stdio: 'inherit' });
const pub = path.join(__dirname, '..', 'public');
fs.mkdirSync(pub, { recursive: true });
fs.copyFileSync(path.join(root, 'prototype', 'dist.html'), path.join(pub, 'index.html'));
console.log('staged  worker/public/index.html');
