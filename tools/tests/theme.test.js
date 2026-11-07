// The theme system and the WoW Forever override (lua/theme.lua).
'use strict';
const fs = require('fs');
const path = require('path');
const { newLua, LUA_CHECK, checker } = require('./lib/harness');

const t = checker('theme');
const vm = newLua();
vm.exposeFiles(['Core/Theme.lua', 'Flavors/Forever/Theme.lua']);
vm.run(LUA_CHECK, 'check');
vm.run(fs.readFileSync(path.join(__dirname, 'lua', 'theme.lua'), 'utf8'), 'lua/theme.lua');
t.merge(vm.run('return LUA_RESULT()', 'result'));

// Every Epithet texture the theme names, on each flavour, is a file in the repo.
const { exists } = require('./lib/harness');
for (const [label, files] of [['shared', ['Core/Theme.lua']], ['forever', ['Core/Theme.lua', 'Flavors/Forever/Theme.lua']]]) {
  const v = newLua();
  v.run('NS = {}', 'ns');
  for (const f of files) v.load(f);
  const paths = v.run('local o = {} for _, p in pairs(NS.Theme.tex) do o[#o + 1] = p end return table.concat(o, "\\n")', 'tex').split('\n');
  for (const p of paths) {
    const m = p.match(/^Interface\\AddOns\\Epithet\\(.+)$/i);
    if (!m) continue;
    const rel = m[1].replace(/\\/g, '/');
    t.check(['.tga', '.blp'].some(ext => exists(rel + ext)), `${label}: texture ${rel} exists`);
  }
}
t.finish();
