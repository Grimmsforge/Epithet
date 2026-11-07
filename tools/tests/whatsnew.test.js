'use strict';
// Per-flavour What's New. For each game type, loads the WhatsNew files the TOC
// gates to it, plus Core/WhatsNew.lua, and checks:
//   - a release does not need notes of its own: with none for the current
//     version the window does not open by itself, and /epithet whatsnew falls
//     back to the newest notes there are;
//   - notes for the current version, when there are some, have a title and
//     body in every locale Epithet ships;
//   - Forever never loads Retail's older notes.
const fs = require('fs');
const { newLua, read, REPO, PRELUDE, checker } = require('./lib/harness');

const t = checker('whatsnew');
const toc = read('Epithet.toc');
const version = (toc.match(/^## Version:\s*(\S+)/m) || [])[1];
const LOCALES = fs.readdirSync(`${REPO}/Locales`).filter(f => /^[a-z]{2}[A-Z]{2}\.lua$/.test(f)).map(f => f.slice(0, 4))
  .map(code => (code === 'enGB' ? 'enUS' : code));   // What's New text uses enUS for English
t.check(!!version, 'the TOC has a ## Version');

function filesFor(gameType) {
  return [...toc.matchAll(/^(WhatsNew\\[^\s]+\.lua)(?:\s+\[AllowLoadGameType ([a-z|]+)\])?\s*$/gm)]
    .filter(m => !m[2] || m[2].split('|').includes(gameType)).map(m => m[1].replace(/\\/g, '/'));
}

function load(gameType) {
  const vm = newLua();
  vm.run(PRELUDE, 'prelude');
  vm.run('C_AddOns = { GetAddOnMetadata = function() return CURRENT_VERSION end }', 'meta');
  for (const f of filesFor(gameType)) vm.load(f);
  for (const f of ['Locales/LocaleManager.lua', 'Locales/enGB.lua', 'Core/Theme.lua', 'Core/WhatsNew.lua']) vm.load(f);
  return vm;
}

const LATEST = 'return tostring(NS.WhatsNew:GetLatestContentVersion())';
const SHOULD = 'EpithetDB = {} return tostring(NS.WhatsNew:ShouldShow(CURRENT_VERSION))';

for (const game of ['standard', 'camelot']) {
  const vm = load(game);
  const versions = vm.run('local v = {} for k in pairs(NS.WhatsNewContent.versions) do v[#v + 1] = k end table.sort(v) return table.concat(v, ",")', 'v');

  // The current version: its notes, if it has them, in every locale.
  vm.run(`CURRENT_VERSION = ${JSON.stringify(version)}`, 'cv');
  const missing = vm.run(`
    local e = NS.WhatsNewContent.versions[CURRENT_VERSION]
    if not e then return "no notes" end
    local missing = {}
    for code in (...):gmatch("[^,]+") do
      local title = type(e.title) == "table" and e.title[code] or (code == "enUS" and e.title)
      local body = type(e.body) == "table" and e.body[code] or (code == "enUS" and e.body)
      if type(title) ~= "string" or title == "" or type(body) ~= "string" or body == "" then missing[#missing + 1] = code end
    end
    return table.concat(missing, ",")`, 'locales', LOCALES.join(','));
  if (missing === 'no notes') console.log(`  ${game}: no notes for ${version} (fine); /epithet whatsnew shows ${vm.run(LATEST, 'l')}`);
  else {
    console.log(`  ${game}: notes for ${version}; opens by itself: ${vm.run(SHOULD, 's')}`);
    t.check(!missing, `${game}: ${version} notes in every locale (missing: ${missing})`);
  }
  if (game === 'camelot') t.check(!versions.split(',').some(v => v.startsWith('1.3.')), `camelot never loads Retail's 1.3 notes (${versions})`);

  // A release with no notes of its own: no popup, and the newest notes are shown on request.
  vm.run('CURRENT_VERSION = "99.0.0"', 'future');
  t.check(vm.run(SHOULD, 's') === 'false', `${game}: a version without notes does not open the window`);
  const newest = versions.split(',').sort((a, b) => a.localeCompare(b, undefined, { numeric: true })).pop();
  t.check(vm.run(LATEST, 'l') === newest, `${game}: /epithet whatsnew falls back to the newest notes (${newest})`);
  // Never newer than the running version, and "1.4.10" sorts after "1.4.9".
  t.check(vm.run('return tostring(NS.WhatsNew:GetLatestContentVersion("1.3.1"))', 'l') === (game === 'standard' ? '1.3.1' : 'nil'),
    `${game}: never shows notes newer than the running version`);
  vm.run('NS.WhatsNewContent.versions["1.4.9"] = { title = "a", body = "a" } NS.WhatsNewContent.versions["1.4.10"] = { title = "b", body = "b" }', 'add');
  t.check(vm.run(LATEST, 'l') === '1.4.10', `${game}: versions compare by number (1.4.10 after 1.4.9)`);
}
t.finish();
