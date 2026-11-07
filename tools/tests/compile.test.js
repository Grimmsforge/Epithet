// Every addon Lua file compiles, and none is close to Lua's 200-local limit.
// The limit is the same in WoW's Lua 5.1: a file over it fails to load at all.
'use strict';
const { lua, lauxlib, to_luastring } = require('fengari');
const { read, addonLuaFiles, checker } = require('./lib/harness');

const MIN_HEADROOM = 10;
const t = checker('compile');

const compiles = src => {
  const L = lauxlib.luaL_newstate();
  const ok = lauxlib.luaL_loadbuffer(L, to_luastring(src), null, to_luastring('x')) === lua.LUA_OK;
  return ok ? null : lua.lua_tojsstring(L, -1);
};

// How many more file-level locals fit, by appending dummies until it fails.
const headroom = src => {
  let lo = 0, hi = 200;
  while (lo < hi) {
    const mid = Math.ceil((lo + hi) / 2);
    const extra = '\n' + Array.from({ length: mid }, (_, i) => `local zz${i}`).join('\n');
    if (compiles(src + extra) === null) lo = mid; else hi = mid - 1;
  }
  return lo;
};

for (const rel of addonLuaFiles()) {
  const src = read(rel);
  const err = compiles(src);
  t.check(err === null, `${rel} compiles: ${err}`);
  if (err === null) {
    const room = headroom(src);
    t.check(room >= MIN_HEADROOM, `${rel} has room for ${room} more file-level locals (keep >= ${MIN_HEADROOM}; move helpers into a do ... end block)`);
  }
}
t.finish();
