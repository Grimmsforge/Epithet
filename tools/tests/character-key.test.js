'use strict';
// Per-character key migration: name-realm -> character ID, with a label.
const fs = require('fs'), path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const repo = require('./lib/harness').REPO.replace(/\\/g, '/');
const read = p => fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '');

function runCase(flavour, body) {
  const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
  const src = `
local FLAVOR, FOREVER_FLAVOR, ENGINE, SET, DATA, LM, ENGB, FLAVOUR, BODY = ...
date = os.date; time = os.time; strlower = string.lower
GetLocale = function() return "enUS" end
GetTime = function() return 0 end
InCombatLockdown = function() return false end
local stub
stub = setmetatable({}, { __index = function() return function() return stub end end, __call = function() return stub end })
CreateFrame = function() return stub end
if FLAVOUR == "forever" then
  UnitFullName = function() return "Manny", "Hunters" end
  GetUnitName = function() return "Manny Hunters" end
  GetNormalizedRealmName = function() return "CAMWOWEU4Realm1PvE" end
  UnitGUID = function() return "Player-6841-0115217A" end
else
  UnitFullName = function() return "Bob", "Draenor" end
  GetUnitName = function() return "Bob" end
  GetNormalizedRealmName = function() return "Draenor" end
  UnitGUID = function() return "Player-1403-0A1B2C3D" end
end
NS = {}
EpithetData = nil
assert(load(DATA, "=data"))("Epithet", NS); NS.EpithetData = EpithetData
assert(load(LM, "=LocaleManager"))("Epithet", NS)
assert(load(ENGB, "=enGB"))("Epithet", NS)
assert(load(FLAVOR, "=Core/Flavor.lua"))("Epithet", NS)
if FLAVOUR == "forever" then assert(load(FOREVER_FLAVOR, "=Flavors/Forever/Flavor.lua"))("Epithet", NS) end
assert(load(ENGINE, "=Spotting/Achievements.lua"))("Epithet", NS)
assert(load(SET, "=set"))("Epithet", NS)
PASS, FAILS = 0, {}
function check(c, m) if c then PASS = PASS + 1 else FAILS[#FAILS + 1] = m end end
assert(load(BODY, "=body"))()
return PASS .. "|" .. table.concat(FAILS, "\\n")
`;
  if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring('case')) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const setFile = flavour === 'forever' ? 'Flavors/Forever/Achievements.lua' : 'Flavors/Retail/Achievements.lua';
  const dataFile = flavour === 'forever' ? 'data/forever/TitlesDB.enGB.lua' : 'data/retail/TitlesDB.enGB.lua';
  for (const s of [read(`${repo}/Core/Flavor.lua`), read(`${repo}/Flavors/Forever/Flavor.lua`), read(`${repo}/Spotting/Achievements.lua`),
                   read(`${repo}/${setFile}`), read(`${repo}/${dataFile}`), read(`${repo}/Locales/LocaleManager.lua`), read(`${repo}/Locales/enGB.lua`), flavour, body])
    lua.lua_pushstring(L, to_luastring(s));
  if (lua.lua_pcall(L, 9, 1, 0) !== lua.LUA_OK) throw new Error(flavour + ': ' + lua.lua_tojsstring(L, -1));
  const [p, f] = lua.lua_tojsstring(L, -1).split('|');
  return { pass: +p, fails: f ? f.split('\n') : [] };
}

const retail = runCase('retail', `
local A = NS.SpottingAchievements
EpithetDB = {
  achievementsByChar = {
    ["Bob-Draenor"] = { owned_1 = { earned = 100 }, owned_10 = { earned = 500 } },
    ["Player-1403-0A1B2C3D"] = { owned_10 = { earned = 300 }, nothing_new = { earned = 900 } },
    ["Alice-Draenor"] = { owned_1 = { earned = 50 } },
  },
  ownedSeen = {
    ["Bob-Draenor"] = { [1] = { ts = 10, reliable = false }, [2] = { ts = 99, reliable = true }, [3] = 7 },
    ["Player-1403-0A1B2C3D"] = { [1] = { ts = 20, reliable = true }, [2] = { ts = 50, reliable = true } },
  },
  ownedSeenBaseline = { ["Bob-Draenor"] = true },
}
local key = A.CurrentCharKey()
check(key == "Player-1403-0A1B2C3D", "key is the character ID")
local ach = EpithetDB.achievementsByChar[key]
check(EpithetDB.achievementsByChar["Bob-Draenor"] == nil, "old achievement key removed")
check(ach.owned_1 and ach.owned_1.earned == 100, "achievement only under the old key moves across")
check(ach.owned_10.earned == 300, "the earlier of two earned dates wins (300 < 500)")
check(ach.nothing_new.earned == 900, "achievement only under the new key stays")
check(EpithetDB.achievementsByChar["Alice-Draenor"].owned_1.earned == 50, "another character's data is untouched")
local owned = EpithetDB.ownedSeen[key]
check(EpithetDB.ownedSeen["Bob-Draenor"] == nil, "old owned key removed")
check(owned[1].ts == 20 and owned[1].reliable, "a reliable date beats an earlier guessed one")
check(owned[2].ts == 50, "between two reliable dates the earlier wins")
check(owned[3] == 7, "an owned title only under the old key moves across")
check(EpithetDB.ownedSeenBaseline[key] == true and EpithetDB.ownedSeenBaseline["Bob-Draenor"] == nil, "baseline moves")
local label = EpithetDB.characters[key]
check(label and label.name == "Bob" and label.realm == "Draenor" and label.lastLogin, "Retail label: name and realm")
-- A second call does nothing more; data saved later under the old key (another
-- addon version, say) is not pulled in mid-session.
EpithetDB.achievementsByChar["Bob-Draenor"] = { slay = { earned = 1 } }
A.CurrentCharKey()
check(EpithetDB.achievementsByChar["Bob-Draenor"] ~= nil, "migration runs once per session")
`);

const forever = runCase('forever', `
local A = NS.SpottingAchievements
EpithetDB = {
  achievementsByChar = { ["Manny-Hunters"] = { owned_1 = { earned = 100 } } },
  ownedSeen = { ["Manny-Hunters"] = { [8] = { ts = 10, reliable = true } } },
  ownedSeenBaseline = { ["Manny-Hunters"] = true },
}
local key = A.CurrentCharKey()
check(key == "Player-6841-0115217A", "Forever key is the character ID")
check(EpithetDB.achievementsByChar[key].owned_1.earned == 100 and EpithetDB.achievementsByChar["Manny-Hunters"] == nil, "Forever achievements move across")
check(EpithetDB.ownedSeen[key][8].ts == 10, "Forever owned titles move across")
local label = EpithetDB.characters[key]
check(label.name == "Manny Hunters" and label.realm == nil, "Forever label: full name, no internal realm")
-- Fresh install: nothing to migrate.
EpithetDB = {}
`);

let failed = 0;
for (const [name, r] of [['retail', retail], ['forever', forever]]) {
  for (const f of r.fails) { console.log(`FAIL (${name}): ${f}`); failed++; }
  console.log(`${name}: ${r.pass} passed, ${r.fails.length} failed`);
}
process.exit(failed ? 1 : 0);
