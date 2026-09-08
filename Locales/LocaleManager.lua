-- =============================================================================
-- Epithet — Locale Manager
-- =============================================================================
-- Shared, locale-agnostic machinery for the localisation system: the locale
-- registry, the ns.L read-only proxy, and the language-resolution API.
--
-- This file loads BEFORE any locale data file (enGB.lua, ruRU.lua, ...). Those
-- files only register their string table into ns.Locales[<code>] and never touch
-- anything here. enGB is the base / default (GetLocale() returns "enUS" for both
-- US and GB clients, so it also serves enUS).
-- =============================================================================
local _, ns = ...

-- Locale registry. Every locale file adds itself as ns.Locales[<code>] = { ... }.
ns.Locales = ns.Locales or {}

-- Shared punctuation glyphs used to build localised strings. These are
-- locale-agnostic — a middle dot is the same byte sequence in every language —
-- so they live here once rather than being redefined in every locale file.
-- (WoW Lua 5.1 has no \xNN hex escapes, hence the decimal byte escapes.)
ns.Glyphs = ns.Glyphs or {
    DOT   = "\194\183",        -- middle dot ·
    DASH  = "\226\128\148",    -- em dash —
    CHECK = "\226\156\147",    -- check mark ✓
}

-- Human-readable language names in each language's own script. Used by the
-- picker as a fallback when a localised LANGUAGE_<X> key isn't defined.
local LOCALE_NAMES = {
    enGB = "English",
    ruRU = "\208\160\209\131\209\129\209\129\208\186\208\184\208\185",    -- Русский
    deDE = "Deutsch",
    frFR = "Fran\195\167ais",                                             -- Français
    esES = "Espa\195\177ol",                                              -- Español
    esMX = "Espa\195\177ol (M\195\169xico)",                              -- Español (México)
    itIT = "Italiano",
    ptBR = "Portugu\195\170s",                                            -- Português
    koKR = "\237\149\156\234\181\173\236\150\180",                        -- 한국어
    zhCN = "\231\174\128\228\189\147\228\184\173\230\150\135",            -- 简体中文
    zhTW = "\231\185\129\233\171\148\228\184\173\230\150\135",            -- 繁體中文
}

-- Maps a locale code to the L key holding its name. Because these resolve
-- through ns.L, the picker shows every language's name in the ACTIVE language
-- (English UI -> "English"/"Russian"; Russian UI -> "Английский"/"Русский").
local LANGUAGE_NAME_KEYS = {
    enGB = "LANGUAGE_ENGLISH",
    ruRU = "LANGUAGE_RUSSIAN",
    deDE = "LANGUAGE_GERMAN",
    frFR = "LANGUAGE_FRENCH",
    zhCN = "LANGUAGE_SIMPLIFIED_CHINESE",
}

-- Display name for a locale code. Prefers the active-language name (via ns.L),
-- then the language's own-script name, then the raw code.
function ns.GetLocaleDisplayName(code)
    local key = LANGUAGE_NAME_KEYS[code]
    if key then
        return ns.L[key]
    end
    return LOCALE_NAMES[code] or code
end

-- Sorted list of the locale codes that are actually registered (i.e. shipped).
function ns.GetAvailableLocales()
    local list = {}
    for code in pairs(ns.Locales) do
        list[#list + 1] = code
    end
    table.sort(list)
    return list
end

-- Resolve a user preference ("auto" | a locale code | nil) to a real, shipped
-- locale code. "auto" (or anything unrecognised) follows the game client.
function ns.ResolveLocaleCode(pref)
    if pref and pref ~= "auto" and ns.Locales[pref] then
        return pref
    end
    local client = (GetLocale and GetLocale()) or "enUS"
    if client == "enGB" or client == "enUS" then
        return "enGB"
    end
    if ns.Locales[client] then
        return client
    end
    return "enGB"
end

-- Make `code` the active overlay. Reads through ns.L pick it up immediately, but
-- text already drawn (SetText) does not re-render, so callers that switch at
-- runtime should ReloadUI() to fully apply.
function ns.ApplyLocale(code)
    if not code or not ns.Locales[code] then
        code = "enGB"
    end
    ns.activeLocale = code
    ns.activeOverlay = (code ~= "enGB") and ns.Locales[code] or nil
end

-- ns.L: read-only proxy. Lookup order is active overlay -> English base -> the
-- key name itself (so a totally-undefined key can never nil-error a SetText or
-- string concat, and shows up plainly in-game / in the audit). The English base
-- (ns.Locales.enGB) is registered by enGB.lua, which loads right after this file;
-- lookups only happen at runtime, well after all locale files have loaded, but
-- the base is nil-guarded here regardless.
ns.L = ns.L or setmetatable({}, {
    __index = function(_, key)
        local overlay = ns.activeOverlay
        if overlay then
            local v = overlay[key]
            if v ~= nil then return v end
        end
        local base = ns.Locales.enGB
        if base then
            local v = base[key]
            if v ~= nil then return v end
        end
        return key
    end,
})
