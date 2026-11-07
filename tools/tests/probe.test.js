'use strict';
// Smoke test: load the probe's Textures.lua + Probe.lua with mocked client APIs
// and run every slash command.
const fs = require('fs'), path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const dir = path.join(require('./lib/harness').REPO, 'tools', 'probe', 'EpithetProbe');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const prelude = `
local out = {}
function print(s) out[#out + 1] = tostring(s) end
PRINTED = out
date = os.date
time = os.time
function GetBuildInfo() return "1.60.1", "70790", "Nov 1 2026", 16001 end
local present = {}
function GetFileIDFromPath(p) if p:find("LichKing") then return nil end return 12345 end
function CreateFrame()
  local f = {}
  function f:SetSize() end function f:SetPoint() end
  function f:CreateTexture()
    local t = { cur = nil }
    function t:SetAllPoints() end
    function t:SetTexture(p) self.cur = p; return p ~= nil and not tostring(p):find("LichKing") end
    function t:GetTexture() return self.cur end
    function t:GetTextureFileID() if self.cur and not tostring(self.cur):find("LichKing") then return 1 end return nil end
    return t
  end
  return f
end
UIParent = {}
SlashCmdList = {}
function UnitExists(u) return u == "target" end
function UnitIsPlayer() return true end
function UnitName() return "Bob" end
function UnitFullName() return "Bob", "Realm" end
function UnitPVPName() return "Bob Smith" end
function GetUnitName(u, r) return r and "Bob Smith-Realm" or "Bob Smith" end
function UnitFactionGroup() return "Horde" end
function UnitGUID() return "Player-1-0001" end
function GetPlayerInfoByGUID() return "Warrior", "WARRIOR", "Orc", "Orc", 2, "Bob Smith", "" end
function GetCurrentTitle() return 0 end
TargetFrameName = { GetText = function() return "Bob Smith" end }
function UnitRace() return "Orc", "Orc", 2 end
function UnitClass() return "Mage", "MAGE", 8 end
function UnitLevel() return 17 end
function GetNumClasses() return 2 end
function GetClassInfo(i) return ({ "Warrior", "Paladin" })[i], ({ "WARRIOR", "PALADIN" })[i], i end
function GetZoneText() return "Durotar" end
function GetSubZoneText() return "Razor Hill" end
function IsResting() return true end
C_Map = { GetBestMapForUnit = function() return 1411 end }
C_UnitAuras = { GetAuraDataByIndex = function(_, i) if i == 1 then return { name = "Cozy Fire", spellId = 7353 } end end }
`;
const run = (src, name) => {
  if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring(name)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
    console.error(`LUA ERROR in ${name}: ` + lua.lua_tojsstring(L, -1)); process.exit(1);
  }
};
run(prelude, 'prelude');
run(fs.readFileSync(path.join(dir, 'Textures.lua'), 'utf8'), 'Textures.lua');
run(fs.readFileSync(path.join(dir, 'Probe.lua'), 'utf8'), 'Probe.lua');
run(`
SlashCmdList.EPITHETPROBE("textures")
SlashCmdList.EPITHETPROBE("names")
SlashCmdList.EPITHETPROBE("names focus")
SlashCmdList.EPITHETPROBE("self")
SlashCmdList.EPITHETPROBE("report")
SlashCmdList.EPITHETPROBE("")
local rec = EpithetProbeDB["16001-70790"]
assert(rec and rec.textures and #rec.missingTextures == 1, "expected one missing texture, got " .. tostring(rec and #rec.missingTextures))
assert(rec.missingTextures[1]:find("LichKing"), "the missing one is the LichKing icon")
assert(rec.names[1].UnitPVPName[1] == "Bob Smith" and rec.names[1].UnitName[1] == "Bob", "names recorded")
assert(rec.names[1].UnitRace[2] == "Orc" and rec.names[1].UnitLevel[1] == "17", "race and level recorded")
assert(rec.self and rec.self[1].buffs[1] == "Cozy Fire (spell 7353)", "buff recorded: " .. tostring(rec.self and rec.self[1].buffs[1]))
assert(rec.self[1].GetNumClasses == 2 and rec.self[1].classes[2]:find("PALADIN"), "classes recorded")
local n = 0 for _ in pairs(rec.textures) do n = n + 1 end
assert(n == #EpithetProbeTextures, "every listed texture probed")
assert(#PRINTED > 0, "commands print to chat")
`, 'commands');
console.log('probe smoke test: OK');
