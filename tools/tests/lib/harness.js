// Shared helpers for Epithet's tests: a Lua VM (fengari, Lua 5.3) with the
// addon's files available, plus a tiny pass/fail counter.
//
// WoW runs Lua 5.1. The code Epithet uses behaves the same in both for what
// these tests cover; the one limit that matters (200 locals per function) is
// identical, and compile.test.js checks it.
'use strict';
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const REPO = path.resolve(__dirname, '..', '..', '..');

// A repo file as text, without the UTF-8 BOM the WoW client skips.
function read(rel) {
  return fs.readFileSync(path.join(REPO, rel), 'utf8').replace(/^﻿/, '');
}

function exists(rel) {
  return fs.existsSync(path.join(REPO, rel));
}

// Every addon Lua file, repo-relative with forward slashes.
function addonLuaFiles() {
  const out = [];
  const walk = dir => {
    for (const e of fs.readdirSync(path.join(REPO, dir), { withFileTypes: true })) {
      const rel = `${dir}/${e.name}`;
      if (e.isDirectory()) walk(rel);
      else if (e.name.endsWith('.lua')) out.push(rel);
    }
  };
  for (const dir of ['Core', 'UI', 'Spotting', 'Flavors', 'WhatsNew', 'Locales']) if (exists(dir)) walk(dir);
  return out.sort();
}

// A fresh Lua state. run(src, name, ...args) runs a chunk with string/number
// arguments and returns its first result as a string (or null).
function newLua() {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const run = (src, name, ...args) => {
    if (lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring(name)) !== lua.LUA_OK) {
      throw new Error(`${name}: ${lua.lua_tojsstring(L, -1)}`);
    }
    for (const a of args) {
      if (typeof a === 'number') lua.lua_pushnumber(L, a);
      else lua.lua_pushstring(L, to_luastring(String(a)));
    }
    if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) {
      throw new Error(`${name}: ${lua.lua_tojsstring(L, -1)}`);
    }
    const out = lua.lua_isnil(L, -1) ? null : lua.lua_tojsstring(L, -1);
    lua.lua_pop(L, 1);
    return out;
  };
  // Runs a repo file as the addon would: chunk("Epithet", NS).
  const load = rel => run(`local src, name = ...; assert(load(src, "=" .. name))("Epithet", NS)`, `load ${rel}`, read(rel), rel);
  // Exposes repo files to Lua as FILES["Core/Theme.lua"].
  const exposeFiles = rels => {
    run('FILES = FILES or {}', 'files');
    for (const rel of rels) run('local k, v = ...; FILES[k] = v', 'file', rel, read(rel));
  };
  return { L, run, load, exposeFiles };
}

// The usual WoW-side globals a module needs to load in a test.
const PRELUDE = `
date = os.date
strlower, strupper, format = string.lower, string.upper, string.format
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
GetLocale = function() return "enUS" end
GetTime = function() return 0 end
InCombatLockdown = function() return false end
local stub
stub = setmetatable({}, { __index = function() return function() return stub end end, __call = function() return stub end })
STUB = stub
CreateFrame = CreateFrame or function() return stub end
UIParent = stub
NS = {}
`;

// Pass/fail counter. finish() prints the summary and exits non-zero on failure.
function checker(name) {
  let passes = 0;
  const fails = [];
  return {
    check(cond, msg) {
      if (cond) passes++;
      else { fails.push(msg); console.log(`  FAIL: ${msg}`); }
    },
    // Adds results reported from Lua as "passes|fail1\nfail2".
    merge(result) {
      const i = result.indexOf('|');
      passes += Number(result.slice(0, i));
      const rest = result.slice(i + 1);
      if (rest) for (const f of rest.split('\n')) { fails.push(f); console.log(`  FAIL: ${f}`); }
    },
    finish() {
      console.log(`${name}: ${passes} passed, ${fails.length} failed`);
      process.exit(fails.length ? 1 : 0);
    },
  };
}

// Lua-side check helper; collect with LUA_RESULT at the end of a chunk.
const LUA_CHECK = `
PASS, FAILS = 0, {}
function check(cond, msg) if cond then PASS = PASS + 1 else FAILS[#FAILS + 1] = tostring(msg) end end
function LUA_RESULT() return PASS .. "|" .. table.concat(FAILS, "\\n") end
`;

module.exports = { REPO, read, exists, addonLuaFiles, newLua, PRELUDE, LUA_CHECK, checker };
