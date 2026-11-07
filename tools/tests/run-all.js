// Runs every Epithet test (tools/tests/*.test.js), each in its own process, and
// exits non-zero if any fails. Covers both flavours: Retail and WoW Forever.
//
//   cd tools/tests && npm install      (once: fetches fengari, a Lua VM)
//   npm test                           (or: node tools/tests/run-all.js)
//   node tools/tests/run-all.js achievements   (only tests whose name matches)
//
// scripts/build/build.ps1 runs this before packaging.
'use strict';
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const filter = process.argv[2];
const files = fs.readdirSync(__dirname).filter(f => f.endsWith('.test.js') && (!filter || f.includes(filter))).sort();
if (!files.length) {
  console.error(`No tests match "${filter}".`);
  process.exit(1);
}

const started = Date.now();
const failed = [];
for (const file of files) {
  const r = spawnSync(process.execPath, [path.join(__dirname, file)], { stdio: 'inherit' });
  if (r.status !== 0) failed.push(file);
}
const secs = ((Date.now() - started) / 1000).toFixed(1);
console.log('');
if (failed.length) {
  console.log(`FAILED: ${failed.length} of ${files.length} test file(s): ${failed.join(', ')} (${secs}s)`);
  process.exit(1);
}
console.log(`OK: all ${files.length} test files passed (${secs}s).`);
