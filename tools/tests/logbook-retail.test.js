'use strict';
// The Logbook's new sighting fields on Retail: recorded where they make sense,
// no campfire lookup at all, and a secret level in combat is skipped safely.
const fs = require('fs'), path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const repo = require('./lib/harness').REPO.replace(/\\/g, '/');
const read = p => fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '');
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
const src = `
local FLAVOR, LOG = ...
date = os.date
MOCK = { now = 1900000000, level = 70 }
time = function(t) if t then return os.time(t) end return MOCK.now end
local SECRET = setmetatable({}, { __lt = function() error("attempt to compare a secret value") end,
                                 __le = function() error("attempt to compare a secret value") end })
issecretvalue = function(v) return v == SECRET end
UnitLevel = function() if MOCK.secret then return SECRET end return MOCK.level end
GetUnitName = function() return "Bob-Draenor" end
GetZoneText = function() return "Dornogal" end
local auraLookups = 0
C_UnitAuras = { GetPlayerAuraBySpellID = function() auraLookups = auraLookups + 1 return nil end }
local frames = {}
CreateFrame = function() local f = { s = {} } function f:RegisterEvent() end function f:SetScript(k, fn) self.s[k] = fn end frames[#frames + 1] = f return f end
local ns = {}
assert(load(FLAVOR, "=Core/Flavor.lua"))("Epithet", ns)
assert(load(LOG, "=Spotting/Log.lua"))("Epithet", ns)
EpithetDB = { spotted = {} }
frames[1].s.OnEvent(frames[1], "PLAYER_ENTERING_WORLD", true, false)
MOCK.now = MOCK.now + 45
ns.SpottingLog:Record(101, "target", {})
local e = EpithetDB.spotted[101]
assert(e.lowestLevel == 70, "level recorded on Retail")
assert(e.seenSoonAfterLogin == true, "soon-after-login recorded on Retail")
assert(e.seenAtCampfire == nil, "no campfire on Retail")
assert(auraLookups == 0, "Retail never looks up an aura (" .. auraLookups .. ")")
MOCK.secret = true
local ok, err = pcall(ns.SpottingLog.Record, ns.SpottingLog, 102, "target", {})
assert(ok, "a secret level in combat does not break recording: " .. tostring(err))
assert(EpithetDB.spotted[102] and EpithetDB.spotted[102].lowestLevel == nil, "secret level is simply not recorded")
return "ok"
`;
if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring('t')) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
lua.lua_pushstring(L, to_luastring(read(`${repo}/Core/Flavor.lua`)));
lua.lua_pushstring(L, to_luastring(read(`${repo}/Spotting/Log.lua`)));
if (lua.lua_pcall(L, 2, 1, 0) !== lua.LUA_OK) { console.log('FAIL: ' + lua.lua_tojsstring(L, -1)); process.exit(1); }
console.log('retail log test: OK');
