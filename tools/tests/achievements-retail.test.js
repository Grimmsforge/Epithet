// Retail's achievement set: its shape, and a snapshot of how every achievement
// judges 200 generated spotting logs (check result, detail, progress, display).
// The snapshot (golden/retail-achievements.txt) holds one fingerprint per
// achievement, so a change names the achievement it touched. After an
// intended change, review it and refresh the snapshot:
//
//   node tools/tests/achievements-retail.test.js --update
//
// The snapshot was first taken on 2026-11-07 from code shown to match the
// original single-file engine on 46,200 results (count_700 then lowered to 650).
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { newLua, read, PRELUDE, checker } = require('./lib/harness');

const UPDATE = process.argv.includes('--update');
const FIXTURES = 200;
const GOLDEN = path.join(__dirname, 'golden', 'retail-achievements.txt');
const t = checker('achievements (retail)');

const vm = newLua();
vm.run(PRELUDE, 'prelude');
vm.run(`
time = os.time
UnitFullName = function() return "Tester", "Realm" end
CHARKEY = "Player-1-00000001"
UnitGUID = function() return CHARKEY end
EpithetData = nil
`, 'env');
vm.load('data/retail/TitlesDB.enGB.lua');
vm.run('NS.EpithetData = EpithetData', 'data');
for (const f of ['Locales/LocaleManager.lua', 'Locales/enGB.lua', 'Core/Theme.lua', 'Spotting/Achievements.lua',
  'Flavors/Retail/Achievements.lua', 'Spotting/LogbookUI.lua']) vm.load(f);

// Deterministic spotting logs of different sizes and shapes.
const FIXTURE = `
local seed = ...
local s = seed * 7919 + 17
local function rnd(n) s = (s * 1103515245 + 12345) % 2147483648; return (s % n) + 1 end
local ids = {}
for _, t in pairs(NS.EpithetData.titles) do ids[#ids + 1] = t.titleID end
table.sort(ids)
local classes = { "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER" }
local races = { "Human","Orc","Dwarf","NightElf","Scourge","Tauren","Gnome","Troll","BloodElf","Draenei" }
local zones = { "Orgrimmar","Stormwind City","Valdrakken","Dornogal","Elwynn Forest","Durotar","Silvermoon City","Ironforge","Darnassus","Undercity","Thunder Bluff","Dalaran" }
local people = { "Aly-Realm","Bob-Realm","Cat-Realm","Dax-Realm","Eve-Realm","Fin-Realm" }
local spotted = {}
local size = ({ 0, 1, 3, 8, 20, 60, 150, 400, 720 })[rnd(9)]
local base = 1730000000 + rnd(30000000)
for i = 1, size do
  local id = ids[rnd(#ids)]
  local t1 = base + rnd(40000000)
  spotted[id] = {
    firstSeen = t1, lastSeen = t1 + rnd(5000000) - 1, count = rnd(40),
    firstName = people[rnd(#people)], lastName = people[rnd(#people)],
    firstZone = zones[rnd(#zones)], classTag = classes[rnd(#classes)], raceTag = races[rnd(#races)],
    quality = rnd(5), titleType = (rnd(2) == 1) and "prefix" or "suffix",
  }
end
local owned = {}
for i = 1, rnd(120) - 1 do
  local id = ids[rnd(#ids)]
  local reliable = rnd(2) == 1
  owned[id] = { ts = base + rnd(40000000), reliable = reliable, source = reliable and "achievement" or "scan_baseline" }
end
local earned, byChar = {}, {}
local someIds = { "count_1","count_10","roll_call","both_ends","grand_tour","night_shift","old_money","guising","slay","popular","certified","welcome_back","feast_your_eyes","long_con","title_fwends","restraining_order","count_700" }
for i = 1, rnd(14) - 1 do earned[someIds[rnd(#someIds)]] = { earned = base + i } end
local charIds = { "owned_1","owned_10","takes_one","twinsies","matching_set" }
for i = 1, rnd(4) - 1 do byChar[charIds[rnd(#charIds)]] = { earned = base + i } end
local events = {}
if rnd(3) == 1 then events.beyond_the_grave = { titleID = ids[rnd(#ids)] } end
if rnd(3) == 1 then events.know_thy_enemy = { titleID = ids[rnd(#ids)] } end
if rnd(3) == 1 then events.twinsies = { titleID = ids[rnd(#ids)] } end
EpithetDB = {
  spotted = spotted, achievements = earned, achievementsByChar = { [CHARKEY] = byChar },
  ownedSeen = { [CHARKEY] = owned }, ownedSeenBaseline = {}, achievementReveal = {}, spottingEvents = events,
}
`;

// One pass: every achievement's judgement, one line each.
const PROBE = `
local A = NS.SpottingAchievements
math.randomseed(1)
A.secretOrder = {}
local entries = A:GetDisplayEntries()
local byID, ids = {}, {}
for _, e in ipairs(entries) do byID[e.id] = e ids[#ids + 1] = e.id end
table.sort(ids)
local function s(v) if v == nil then return "nil" end return tostring(v) end
local out = {}
for _, id in ipairs(ids) do
  local ok, detail = A:GetDef(id).check(EpithetDB.spotted)
  local e = byID[id]
  out[#out + 1] = table.concat({ id, s(ok), s(detail), s(e.progressText), s(e.name), s(e.description), s(e.masked), s(e.earned),
    s(e.detailText), s(e.group), s(e.scope), s(e.secret), s(NS.SpottingAchievementIcon(id)) }, "|")
end
return table.concat(out, "\\n")
`;

// Shape.
t.check(vm.run('return NS.SpottingAchievements:GetSetID()', 'id') === 'retail-1', 'set id retail-1');
vm.run('EpithetDB = {}', 'empty');
t.check(vm.run('return tostring(#NS.SpottingAchievements:GetDisplayEntries())', 'n') === '76', 'Retail shows 76 achievements');

// count_700 asks for 650 (Retail's data has 694 titles).
const c700 = vm.run(`
  local ids = {} for _, t in pairs(NS.EpithetData.titles) do ids[#ids + 1] = t.titleID end table.sort(ids)
  local function log(n) local s = {} for i = 1, n do s[ids[i]] = { firstSeen = 1 } end return s end
  local A = NS.SpottingAchievements
  EpithetDB = { spotted = log(650), achievements = {}, achievementsByChar = {}, ownedSeen = {}, ownedSeenBaseline = {}, achievementReveal = {}, spottingEvents = {} }
  A:GetDisplayEntries() local at650 = A:GetDef("count_700").check(EpithetDB.spotted)
  EpithetDB.spotted = log(649)
  A:GetDisplayEntries() local at649 = A:GetDef("count_700").check(EpithetDB.spotted)
  return tostring(at650) .. "/" .. tostring(at649)`, 'c700');
t.check(c700 === 'true/false', `count_700 earns at 650 titles, not 649 (${c700})`);

// Snapshot.
const perID = new Map();
for (let f = 1; f <= FIXTURES; f++) {
  vm.run(FIXTURE, 'fixture', f);
  for (const line of vm.run(PROBE, 'probe').split('\n')) {
    const id = line.slice(0, line.indexOf('|'));
    if (!perID.has(id)) perID.set(id, crypto.createHash('sha256'));
    perID.get(id).update(line + '\n');
  }
}
const current = [...perID.entries()].map(([id, h]) => `${id} ${h.digest('hex').slice(0, 16)}`).sort();

if (UPDATE) {
  fs.mkdirSync(path.dirname(GOLDEN), { recursive: true });
  fs.writeFileSync(GOLDEN, `# Retail achievement snapshot: one fingerprint per achievement over ${FIXTURES} generated logs.\n# Refresh with: node tools/tests/achievements-retail.test.js --update\n` + current.join('\n') + '\n');
  console.log(`  snapshot written (${current.length} achievements)`);
} else if (!fs.existsSync(GOLDEN)) {
  t.check(false, 'no snapshot yet: run with --update');
} else {
  const golden = new Map(fs.readFileSync(GOLDEN, 'utf8').split(/\r?\n/).filter(l => l && !l.startsWith('#')).map(l => l.split(' ')));
  const now = new Map(current.map(l => l.split(' ')));
  for (const [id, hash] of golden) t.check(now.get(id) === hash, now.has(id) ? `${id} judges logs differently than the snapshot` : `${id} is missing`);
  for (const id of now.keys()) if (!golden.has(id)) t.check(false, `${id} is new: not in the snapshot`);
}
t.finish();
