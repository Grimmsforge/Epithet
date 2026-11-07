// Title data, filters and title reading on both flavours (lua/titles.lua).
'use strict';
const fs = require('fs');
const path = require('path');
const { newLua, exists, LUA_CHECK, checker } = require('./lib/harness');

const t = checker('titles');
const DATA = ['data/retail/TitlesDB.enGB.lua', 'data/forever/TitlesDB.enGB.lua'];
for (const d of DATA) {
  if (!exists(d)) {
    console.log(`titles: skipped, ${d} is missing (generate it with TitlesDBCollector)`);
    process.exit(1);
  }
}
const vm = newLua();
vm.exposeFiles([...DATA, 'Locales/LocaleManager.lua', 'Locales/enGB.lua', 'Core/Theme.lua',
  'Core/TitleData.lua', 'Core/Filters.lua', 'Spotting/TitleIndex.lua']);
vm.run(LUA_CHECK, 'check');
vm.run(fs.readFileSync(path.join(__dirname, 'lua', 'titles.lua'), 'utf8'), 'lua/titles.lua');
t.merge(vm.run('return LUA_RESULT()', 'result'));
t.finish();
