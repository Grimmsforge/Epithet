'use strict';
// Achievements:Audit() for each set against its own data, and the Retail set
// against Forever's data (which should reproduce the plan's hand audit).
const fs = require('fs'), path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const repo = require('./lib/harness').REPO.replace(/\\/g, '/');
const read = p => fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '');

function audit(setFile, dataFile, classIDs) {
  const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
  const src = `
local ENGINE, SET, DATA, LM, ENGB, CLASSES = ...
date = os.date; time = os.time; strlower = string.lower
GetLocale = function() return "enUS" end
local stub
stub = setmetatable({}, { __index = function() return function() return stub end end, __call = function() return stub end })
CreateFrame = function() return stub end
local have = {}
for id in CLASSES:gmatch("%d+") do have[tonumber(id)] = true end
GetClassInfo = function(id) if have[id] then return "Class" .. id, "C" .. id, id end end
NS = {}
EpithetData = nil
assert(load(DATA, "=data"))("Epithet", NS); NS.EpithetData = EpithetData
assert(load(LM, "=LocaleManager"))("Epithet", NS)
assert(load(ENGB, "=enGB"))("Epithet", NS)
assert(load(ENGINE, "=engine"))("Epithet", NS)
assert(load(SET, "=set"))("Epithet", NS)
local problems, facts = NS.SpottingAchievements:Audit()
local out = { "facts|" .. facts.total .. "|" .. facts.maxOwned .. "|" .. facts.tierCount }
for _, p in ipairs(problems) do out[#out + 1] = p.id .. "|" .. p.problem end
return table.concat(out, "\\n")
`;
  if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring('audit')) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  for (const s of [read(`${repo}/Spotting/Achievements.lua`), read(`${repo}/${setFile}`), read(`${repo}/${dataFile}`),
                   read(`${repo}/Locales/LocaleManager.lua`), read(`${repo}/Locales/enGB.lua`), classIDs.join(',')])
    lua.lua_pushstring(L, to_luastring(s));
  if (lua.lua_pcall(L, 6, 1, 0) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const lines = lua.lua_tojsstring(L, -1).split('\n');
  const [, total, maxOwned, tiers] = lines.shift().split('|');
  return { total: +total, maxOwned: +maxOwned, tiers: +tiers, problems: lines.map(l => { const [id, ...rest] = l.split('|'); return { id, problem: rest.join('|') }; }) };
}

const RETAIL_CLASSES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
const FOREVER_CLASSES = [1, 2, 3, 4, 5, 7, 8, 9, 11];
let failed = 0;
const expect = (cond, msg) => { if (!cond) { failed++; console.log('FAIL: ' + msg); } };
const show = (label, r) => {
  console.log(`\n${label}: ${r.total} titles, one character can own ${r.maxOwned}, ${r.tiers} tiers; ${r.problems.length} flagged`);
  for (const p of r.problems) console.log(`  ${p.id.padEnd(22)} ${p.problem}`);
};

const forever = audit('Flavors/Forever/Achievements.lua', 'data/forever/TitlesDB.enGB.lua', FOREVER_CLASSES);
show('Forever set on Forever data', forever);
expect(forever.problems.length === 0, 'the Forever set has nothing flagged');
expect(forever.total === 40 && forever.maxOwned === 26, 'Forever: 40 titles, 26 per character');

const retail = audit('Flavors/Retail/Achievements.lua', 'data/retail/TitlesDB.enGB.lua', RETAIL_CLASSES);
show('Retail set on Retail data', retail);
expect(retail.problems.length === 0, 'the Retail set has nothing flagged now count_700 asks for 650');

const cross = audit('Flavors/Retail/Achievements.lua', 'data/forever/TitlesDB.enGB.lua', FOREVER_CLASSES);
show('Retail set on Forever data', cross);
const flagged = new Set(cross.problems.map(p => p.id));
const forSet = read(`${repo}/Flavors/Forever/Achievements.lua`);
const hidden = [...forSet.slice(forSet.indexOf('hidden = {')).matchAll(/"([a-z0-9_]+)",/g)].map(m => m[1]);
// The data can't know these two: one depends on an unknown source, the other on Forever's class list (flagged via roll_call instead).
const dataBlind = new Set(['quite_a_mouthful', 'dead_man_walking']);
for (const id of hidden) if (!dataBlind.has(id)) expect(flagged.has(id), `audit flags hidden ${id} on Forever data`);
for (const id of flagged) expect(hidden.includes(id) || id === 'roll_call' || id === 'secret_keeper', `audit flags ${id}, which Forever keeps`);

console.log(failed ? `\n${failed} failure(s)` : '\naudit test: OK');
process.exit(failed ? 1 : 0);
