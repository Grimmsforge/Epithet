'use strict';
// Forever achievement set: shape, hidden ids, and each new achievement with a
// log that should earn it and one that should not.
const fs = require('fs'), path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const repo = require('./lib/harness').REPO.replace(/\\/g, '/');
const read = p => fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const run = (src, name, ...args) => {
  if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring(name)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  for (const a of args) lua.lua_pushstring(L, to_luastring(a));
  if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) throw new Error(name + ': ' + lua.lua_tojsstring(L, -1));
  const out = lua.lua_isstring(L, -1) ? lua.lua_tojsstring(L, -1) : null;
  lua.lua_pop(L, 1);
  return out;
};
run(`
date = os.date; strlower = string.lower
MOCK = { now = nil, level = 1, name = "X", zone = "Z" }
time = function(t) if t then return os.time(t) end return MOCK.now or os.time() end
UnitLevel = function() return MOCK.level end
GetUnitName = function() return MOCK.name end
GetZoneText = function() return MOCK.zone end
GetLocale = function() return "enUS" end
UnitFullName = function() return "Manny", "Hunters" end
GetTime = function() return 0 end
InCombatLockdown = function() return false end
FACTION_ALLIANCE = "Alliance"; FACTION_HORDE = "Horde"
local stub
stub = setmetatable({}, { __index = function() return function() return stub end end, __call = function() return stub end })
FRAMES = {}
CreateFrame = function()
  local f = { scripts = {} }
  function f:RegisterEvent() end
  function f:SetScript(k, fn) self.scripts[k] = fn end
  setmetatable(f, { __index = function() return function() return stub end end })
  FRAMES[#FRAMES + 1] = f
  return f
end
UIParent = stub
NS = {}
EpithetData = nil
`, 'prelude');
const load = (file, name) => run(`local src, name = ...; assert(load(src, "=" .. name))("Epithet", NS)`, 'load ' + name, read(file), name);
load(`${repo}/data/forever/TitlesDB.enGB.lua`, 'data');
run(`NS.EpithetData = EpithetData`, 'data2');
load(`${repo}/Locales/LocaleManager.lua`, 'LocaleManager');
load(`${repo}/Locales/enGB.lua`, 'enGB');
load(`${repo}/Core/Theme.lua`, 'Theme');
load(`${repo}/Core/Flavor.lua`, 'Flavor');
load(`${repo}/Flavors/Forever/Flavor.lua`, 'ForeverFlavor');
load(`${repo}/Spotting/Log.lua`, 'Log');
run(`LOG_FRAME = FRAMES[#FRAMES]`, 'logframe');
load(`${repo}/Spotting/Achievements.lua`, 'Achievements');
load(`${repo}/Flavors/Forever/Achievements.lua`, 'ForeverSet');
load(`${repo}/Spotting/LogbookUI.lua`, 'LogbookUI');

const result = run(`
local A = NS.SpottingAchievements
local passes, fails = 0, {}
local function check(cond, msg) if cond then passes = passes + 1 else fails[#fails + 1] = msg end end
local function key(k) return NS.EpithetData.titles[k].titleID end
local function day(y, m, d, h) return time({ year = y, month = m, day = d, hour = h or 12 }) end
local function reset(spotted, extra)
  EpithetDB = { spotted = spotted or {}, achievements = {}, achievementsByChar = {}, ownedSeen = {}, ownedSeenBaseline = {}, achievementReveal = {}, spottingEvents = {} }
  for k, v in pairs(extra or {}) do EpithetDB[k] = v end
end
local function earns(id, spotted)
  reset(spotted)
  A:GetDisplayEntries()  -- resets the per-pass count cache
  return (A:GetDef(id).check(spotted))
end
local function entry(t)
  local e = { firstSeen = t.at or day(2026, 11, 20), lastSeen = t.at or day(2026, 11, 20), count = 1, firstName = t.first or "Aly Stone", lastName = t.last or t.first or "Aly Stone",
    firstZone = "Orgrimmar", classTag = t.class or "WARRIOR", raceTag = t.race or "Orc", quality = 1, titleType = "prefix" }
  return e
end

-- Shape
check(A:GetSetID() == "forever-1", "set id")
reset({})
local entries = A:GetDisplayEntries()
check(#entries == 64, "64 achievements shown (got " .. #entries .. ")")
local _, total = A:GetSummary()
check(total == 64, "summary total 64 (got " .. total .. ")")
for _, id in ipairs({ "count_700", "potted_history", "at_least_chicken", "quite_a_mouthful", "dead_man_walking" }) do
  check(A:GetDef(id) == nil, id .. " is not in the Forever set")
end
for _, id in ipairs({ "count_1", "roll_call", "secret_keeper", "overachiever", "count_40", "who_are_you" }) do
  check(A:GetDef(id) ~= nil, id .. " is in the Forever set")
end
check(NS.SpottingAchievementIcon("count_40"):find("INV_Misc_Book_11") ~= nil, "tile icon comes from the set")

-- Hidden ids already earned: not shown, not counted, not toward Overachiever.
local hiddenEarned = {}
for _, id in ipairs({ "count_50","count_100","count_200","count_350","count_500","count_700","full_spectrum","seeing_stars","old_money","museum_curator","at_least_chicken","certified","lord_of_lords","masterclass","slay","raid_spectator" }) do
  hiddenEarned[id] = { earned = 1 }
end
reset({}, { achievements = hiddenEarned })
local shown = A:GetDisplayEntries()
local leaked = false
for _, e in ipairs(shown) do if hiddenEarned[e.id] then leaked = true end end
check(not leaked and #shown == 64, "earned hidden achievements are not shown")
local earned = A:GetSummary()
check(earned == 0, "earned hidden achievements are not counted (got " .. earned .. ")")
check(not A:GetDef("overachiever").check(EpithetDB.spotted), "16 hidden achievements do not earn Overachiever")
local kept = {}
for i, id in ipairs({ "count_1","count_10","both_ends","grand_tour","busy_day","terse","early_bird","double_take","popular","guising","night_shift","long_con","sneaky_beaky","participation_award","legendary_spot" }) do kept[id] = { earned = i } end
reset({}, { achievements = kept })
check(A:GetDef("overachiever").check(EpithetDB.spotted), "15 kept achievements earn Overachiever")

-- Secret Keeper counts Forever's secrets, minus the time-limited one.
local secrets, timeLimitedSecret = 0, false
for _, e in ipairs(entries) do
  local def = A:GetDef(e.id)
  if def.secret and not def.timeLimited then secrets = secrets + 1 end
  if def.secret and def.timeLimited then timeLimitedSecret = true end
end
local _, target = A:GetDef("secret_keeper").progress(EpithetDB.spotted)
check(timeLimitedSecret and target == secrets, "Secret Keeper ignores the time-limited secret (" .. tostring(target) .. " / " .. secrets .. ")")

-- count_40 and roll_call
local all = {}
for _, t in pairs(NS.EpithetData.titles) do all[t.titleID] = entry({}) end
local n = 0 for _ in pairs(all) do n = n + 1 end
check(n == 40, "Forever has 40 titles")
check(earns("count_40", all), "spotting all 40 earns count_40")
local most = {} local k = 0 for id, e in pairs(all) do k = k + 1 if k < 40 then most[id] = e end end
check(not earns("count_40", most), "39 titles does not earn count_40")
local classes = { "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID" }
local rc = {} local i = 0
for id in pairs(all) do i = i + 1 if i <= 9 then rc[id] = entry({ class = classes[i] }) end end
check(earns("roll_call", rc), "nine classes earn Roll Call")

-- Names
check(earns("keeping_up_with_the_joneses", {
  [key("private")] = entry({ first = "Aly Hunters" }), [key("corporal")] = entry({ first = "Bob Hunters" }), [key("scout")] = entry({ first = "Cat Hunters", last = "Dan Smith" }) }),
  "three Hunters earn Joneses")
check(not earns("keeping_up_with_the_joneses", {
  [key("private")] = entry({ first = "Aly Hunters" }), [key("corporal")] = entry({ first = "Aly Hunters" }), [key("scout")] = entry({ first = "Cat Smith" }) }),
  "the same Hunters twice is not three")
check(not earns("keeping_up_with_the_joneses", {
  [key("private")] = entry({ first = "Aly-Realm" }), [key("corporal")] = entry({ first = "Bob-Realm" }), [key("scout")] = entry({ first = "Cat-Realm" }) }),
  "Retail-style names have no surname")
reset({ [key("private")] = entry({ first = "Aly Hunters" }), [key("corporal")] = entry({ first = "Bob Hunters" }), [key("scout")] = entry({ first = "Cat Hunters" }) })
local okJ, detailJ = A:GetDef("keeping_up_with_the_joneses").check(EpithetDB.spotted)
check(okJ and detailJ == "Hunters", "Joneses detail is the surname (" .. tostring(detailJ) .. ")")
check(earns("family_business", { [key("private")] = entry({ first = "Aly Hunters", last = "Bob Hunters" }) }), "same title, two Hunters")
check(not earns("family_business", { [key("private")] = entry({ first = "Aly Hunters", last = "Aly Hunters" }) }), "same player twice is not a family")
check(not earns("family_business", { [key("private")] = entry({ first = "Aly Hunters", last = "Bob Smith" }) }), "different surnames")

-- Ladders
local alliance, horde = {}, {}
for _, t in pairs(NS.EpithetData.titles) do
  if t.kind == "PvP Rank" and t.faction == "Alliance" then alliance[t.titleID] = entry({}) end
  if t.kind == "PvP Rank" and t.faction == "Horde" then horde[t.titleID] = entry({}) end
end
local na, nh = 0, 0 for _ in pairs(alliance) do na = na + 1 end for _ in pairs(horde) do nh = nh + 1 end
check(na == 14 and nh == 14, "14 ranks per faction (" .. na .. "/" .. nh .. ")")
check(earns("chain_of_command", alliance), "full Alliance ladder")
check(earns("chain_of_command", horde), "full Horde ladder")
local partial = {} local c = 0 for id, e in pairs(alliance) do c = c + 1 if c < 14 then partial[id] = e end end
for id, e in pairs(horde) do partial[id] = e break end
check(not earns("chain_of_command", partial), "13 Alliance ranks plus one Horde is not a ladder")
reset(partial)
local cur, tgt = A:GetDef("chain_of_command").progress(partial)
check(cur == 13 and tgt == 14, "ladder progress 13 / 14 (" .. tostring(cur) .. "/" .. tostring(tgt) .. ")")
check(earns("mirror_image", { [key("sergeant")] = entry({}), [key("sergeant#23")] = entry({}) }), "both Sergeants")
check(earns("mirror_image", { [key("private")] = entry({}), [key("scout")] = entry({}) }), "Private and Scout are both rank 1")
check(not earns("mirror_image", { [key("private")] = entry({}), [key("grunt")] = entry({}) }), "rank 1 and rank 2 are not a mirror")
check(earns("top_brass", { [key("grand marshal")] = entry({}), [key("high warlord")] = entry({}) }), "Grand Marshal and High Warlord")
check(not earns("top_brass", { [key("private")] = entry({}), [key("scout")] = entry({}) }), "rank 1 pair is not Top Brass")
check(not earns("top_brass", { [key("grand marshal")] = entry({}) }), "one rank 14 is not Top Brass")

-- Titles with a story
check(earns("centaur_of_attention", { [key("of the gelkis")] = entry({}), [key("of the magram")] = entry({}) }), "both centaur clans")
check(not earns("centaur_of_attention", { [key("of the gelkis")] = entry({}) }), "one clan")
local prof = {}
for _, t in pairs(NS.EpithetData.titles) do if t.kind == "Profession" then prof[t.titleID] = entry({}) end end
check(earns("trade_secrets", prof), "all profession titles")
local fewer = {} local p = 0 for id, e in pairs(prof) do p = p + 1 if p < 7 then fewer[id] = e end end
check(not earns("trade_secrets", fewer), "six of seven professions")
check(earns("who_are_you", { [key("the harbinger of darkness")] = entry({}) }), "Harbinger")
check(not earns("who_are_you", { [key("private")] = entry({}) }), "not the Harbinger")

-- World and launch
local combos = { { "Orc","MAGE" }, { "Troll","WARLOCK" }, { "Scourge","PALADIN" }, { "Human","HUNTER" }, { "Gnome","PRIEST" }, { "Dwarf","SHAMAN" } }
local ids = {} for id in pairs(all) do ids[#ids + 1] = id end table.sort(ids)
local combo = {}
for j, pr in ipairs(combos) do combo[ids[j]] = entry({ race = pr[1], class = pr[2] }) end
check(earns("new_combo_who_dis", combo), "all six new pairings")
combo[ids[3]] = entry({ race = "Human", class = "PALADIN" })
check(not earns("new_combo_who_dis", combo), "Human Paladin is not new")
local gn = {}
for j = 1, 3 do gn[ids[j]] = entry({ race = "Gnome", at = day(2026, 11, 20, 9 + j) }) end
check(earns("slaps_roof", gn), "three Gnomes in a day")
gn[ids[3]] = entry({ race = "Gnome", at = day(2026, 11, 21) })
check(not earns("slaps_roof", gn), "Gnomes over two days")
check(earns("first_wave", { [ids[1]] = entry({ at = day(2026, 11, 4, 23) }) }), "launch day counts")
check(earns("first_wave", { [ids[1]] = entry({ at = day(2026, 11, 11, 1) }) }), "11 November counts")
check(not earns("first_wave", { [ids[1]] = entry({ at = day(2026, 11, 12, 0) }) }), "12 November does not")

-- The last four: moments recorded with a sighting.
check(earns("position_in_queue", { [ids[1]] = (function() local e = entry({}) e.seenSoonAfterLogin = true return e end)() }), "seen soon after login")
check(not earns("position_in_queue", { [ids[1]] = entry({}) }), "not soon after login")
check(earns("forever_young", { [ids[1]] = (function() local e = entry({}) e.lowestLevel = 17 return e end)() }), "level 17")
check(not earns("forever_young", { [ids[1]] = (function() local e = entry({}) e.lowestLevel = 20 return e end)() }), "level 20 is not below 20")
check(earns("head_in_the_clouds", { [ids[1]] = entry({ race = "Skyborne" }) }), "Skyborne")
check(earns("head_in_the_clouds", { [ids[1]] = entry({ race = "SkyborneHorde" }) }), "a Skyborne-prefixed token")
check(not earns("head_in_the_clouds", { [ids[1]] = entry({ race = "BloodElf" }) }), "not Skyborne")
local camp = {}
for j = 1, 3 do camp[ids[j]] = entry({}) camp[ids[j]].seenAtCampfire = j <= 2 end
check(not earns("campfire_stories", camp), "two titles at a campfire")
camp[ids[3]].seenAtCampfire = true
check(earns("campfire_stories", camp), "three titles at a campfire")

-- The Logbook records those moments.
local Log = NS.SpottingLog
local aura = false
MOCK.level, MOCK.name, MOCK.zone = 15, "Darnath Bloodoath", "Goldshire"
C_UnitAuras = { GetPlayerAuraBySpellID = function(id) if aura and id == 1283391 then return { spellId = id } end end }
MOCK.now = 2000000000
reset({})
LOG_FRAME.scripts.OnEvent(LOG_FRAME, "PLAYER_ENTERING_WORLD", true, false)
MOCK.now = MOCK.now + 30
Log:Record(ids[1], "target", { raceTag = "Skyborne", classTag = "WARRIOR" })
local e1 = EpithetDB.spotted[ids[1]]
check(e1 and e1.lowestLevel == 15 and e1.seenSoonAfterLogin == true and not e1.seenAtCampfire, "first sighting: level and soon after login")
MOCK.now = MOCK.now + 600
MOCK.level, aura = 12, true
Log:Record(ids[1], "target", {})
check(e1.lowestLevel == 12 and e1.seenAtCampfire == true, "later sighting: lower level, at a campfire")
MOCK.level, aura = 40, false
Log:Record(ids[2], "target", {})
local e2 = EpithetDB.spotted[ids[2]]
check(e2.lowestLevel == 40 and not e2.seenSoonAfterLogin and not e2.seenAtCampfire, "ten minutes in, no campfire")
LOG_FRAME.scripts.OnEvent(LOG_FRAME, "PLAYER_ENTERING_WORLD", false, true)  -- a /reload keeps the login time
MOCK.now = MOCK.now + 1
Log:Record(ids[3], "target", {})
check(not EpithetDB.spotted[ids[3]].seenSoonAfterLogin, "a /reload does not restart the login clock")
Log:Init()
local n1 = EpithetDB.spotted[ids[1]]
check(n1.lowestLevel == 12 and n1.seenSoonAfterLogin == true and n1.seenAtCampfire == true, "moments survive the load-time normalise")
MOCK.now = nil

-- Every Forever achievement has a name and description.
local missing = {}
for _, e in ipairs(entries) do
  if not NS.L["SPOT_ACHV_NAME_" .. e.id:upper()] or not NS.L["SPOT_ACHV_DESC_" .. e.id:upper()] then missing[#missing + 1] = e.id end
end
check(#missing == 0, "locale text for every achievement (missing: " .. table.concat(missing, ", ") .. ")")

return passes .. "|" .. table.concat(fails, "\\n")
`, 'tests');
const [passes, fails] = result.split('|');
if (fails) { console.log('FAIL:\n' + fails); }
console.log(`forever achievements: ${passes} passed, ${fails ? fails.split('\n').length : 0} failed`);
process.exit(fails ? 1 : 0);
