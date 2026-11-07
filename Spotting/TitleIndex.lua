-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...

local TitleIndex = {}
ns.TitleIndex = TitleIndex

local GetNumTitles = GetNumTitles
local GetTitleName = GetTitleName
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local UnitPVPName = UnitPVPName
local pairs, ipairs, next = pairs, ipairs, next

local index = nil
local built = false

-- fragment -> { Alliance = titleID, Horde = titleID }, kept only for fragments
-- shared by records of both factions (neutral records never count). A title text the data
-- splits by faction (WoW Forever's Alliance "Sergeant" 10 and Horde "Sergeant"
-- 23) renders identically on a nameplate, so the fragment alone cannot tell the
-- two apart; the unit's own faction can. Empty on any dataset without such
-- variants, which leaves Resolve() exactly as it was.
local factionIndex = nil

local function Trim(value)
    if not value then return "" end
    value = tostring(value)
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function Normalize(value)
    value = Trim(value)
    value = value:gsub("^[%s,]+", "")
    value = value:gsub("[%s,]+$", "")
    value = value:gsub("%s+", " ")
    return value:lower()
end

-- The normalised title text of a GetTitleName() string, and where it sits
-- relative to the name: "prefix" ("Private %s") or "suffix" ("%s the Explorer").
local function ExtractFragment(raw)
    if not raw or raw == "" then
        return nil
    end

    local before = raw:match("^(.-)%%s") or ""
    local after = raw:match("%%s(.*)$") or ""

    if before:match("%S") then
        return Normalize(before), "prefix"
    end

    if after:match("%S") then
        return Normalize(after), "suffix"
    end

    return nil
end

-- Every catalogue fragment with its affix and titleID, longest first, for
-- FindInDisplay (a longer title wins over one it contains).
local fragmentList = nil
-- "fragment|affix" -> titleID: whether the catalogue has that text in that
-- position ("sergeant|prefix" yes, "sergeant|suffix" no).
local affixIndex = nil

local function StripLeading(full, base)
    if not full or not base then return "" end
    if full:sub(1, #base) == base then
        return full:sub(#base + 1)
    end

    local _, e = full:find(base, 1, true)
    if e then
        return full:sub(e + 1)
    end

    return ""
end

local function StripTrailing(full, base)
    if not full or not base then return "" end
    if full:sub(-#base) == base then
        return full:sub(1, #full - #base)
    end

    local s = full:find(base, 1, true)
    if s then
        return full:sub(1, s - 1)
    end

    return ""
end

local function EscapePattern(text)
    return (text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

-- Reused across calls to avoid allocating a fresh table on every Resolve()
-- (this runs from the UNIT_NAME_UPDATE / PLAYER_TARGET_CHANGED hot path).
local candidateScratch = {}
-- The affix each candidate was read as: text after the name is a suffix,
-- text before it a prefix. Parallel to candidateScratch.
local candidateAffix = {}

local function PushCandidate(candidates, value, affix)
    local normalized = Normalize(value)
    if normalized ~= "" then
        candidates[#candidates + 1] = normalized
        candidateAffix[#candidates] = affix
    end
end

local function BuildCandidates(full, base)
    local candidates = candidateScratch
    for i = #candidates, 1, -1 do
        candidates[i] = nil
        candidateAffix[i] = nil
    end

    if full and full:find(",", 1, true) then
        local commaSuffix = full:match("^[^,]+,%s*(.+)$")
        if commaSuffix then
            PushCandidate(candidates, commaSuffix, "suffix")
        end
    end

    if base and base ~= "" then
        local basePlain = base:match("^([^%-]+)") or base
        local baseEsc = EscapePattern(base)
        local basePlainEsc = EscapePattern(basePlain)

        PushCandidate(candidates, StripLeading(full, base), "suffix")
        PushCandidate(candidates, StripTrailing(full, base), "prefix")

        if basePlain ~= base then
            PushCandidate(candidates, StripLeading(full, basePlain), "suffix")
            PushCandidate(candidates, StripTrailing(full, basePlain), "prefix")
        end

        local prefixed = full:gsub("%s*" .. baseEsc .. "$", "", 1)
        if prefixed ~= full then
            PushCandidate(candidates, prefixed, "prefix")
        end

        local prefixedPlain = full:gsub("%s*" .. basePlainEsc .. "$", "", 1)
        if prefixedPlain ~= full then
            PushCandidate(candidates, prefixedPlain, "prefix")
        end
    end

    return candidates
end

function TitleIndex:Reset()
    index = nil
    factionIndex = nil
    fragmentList = nil
    affixIndex = nil
    built = false
end

function TitleIndex:Build()
    if built and index then
        return index
    end

    if ns.TitleData and ns.TitleData.Scan then
        ns.TitleData:Scan()
    end

    index = {}
    factionIndex = {}
    fragmentList = {}
    affixIndex = {}
    -- One text can be both a prefix and a suffix title ("the Forbidden" is
    -- 495 suffix / 533 prefix), and each is matched where it sits.
    local function List(fragment, affix, titleID)
        local key = fragment .. "|" .. affix
        if not affixIndex[key] then
            affixIndex[key] = titleID
            fragmentList[#fragmentList + 1] = { fragment = fragment, affix = affix, titleID = titleID }
        end
    end

    local recordsByID = ns.TitleData and ns.TitleData.recordsByID
    if recordsByID then
        local byFaction = {}
        -- Index the RECORD's own id, never the key being iterated. Scan collapses
        -- API-duplicate titles (Grunt is both 16 and 169) onto one record that
        -- every alias id maps to, so the iterated key is whichever duplicate
        -- pairs() happens to reach first — an order that can differ between
        -- sessions. Since the spotting log is keyed by title id, drifting between
        -- 16 and 169 would log one title as two and inflate the spotted count.
        -- record.titleID is always the canonical row, so resolution is stable.
        for _, record in pairs(recordsByID) do
            if record and record.titleID then
                -- TitleData:Scan() already fetched and classified this string;
                -- reuse it instead of a second GetTitleName() + parse pass.
                local raw = record.raw or (GetTitleName and GetTitleName(record.titleID))
                local fragment, affix = ExtractFragment(raw)
                if fragment and fragment ~= "" and not index[fragment] then
                    index[fragment] = record.titleID
                end
                if fragment and fragment ~= "" then
                    List(fragment, affix, record.titleID)
                end
                local faction = record.faction
                if fragment and fragment ~= "" and faction then
                    local factions = byFaction[fragment]
                    if not factions then
                        factions = { count = 0, ids = {} }
                        byFaction[fragment] = factions
                    end
                    local current = factions.ids[faction]
                    if not current then
                        factions.count = factions.count + 1
                    end
                    -- Lowest titleID per faction, so the pick is stable across sessions.
                    if not current or record.titleID < current then
                        factions.ids[faction] = record.titleID
                    end
                end
            end
        end
        for fragment, factions in pairs(byFaction) do
            if factions.count > 1 then
                factionIndex[fragment] = factions.ids
            end
        end
    else
        local maxID = GetNumTitles and GetNumTitles() or 0
        for titleID = 1, maxID do
            local raw = GetTitleName and GetTitleName(titleID) or nil
            local fragment, affix = ExtractFragment(raw)
            if fragment and fragment ~= "" and not index[fragment] then
                index[fragment] = titleID
            end
            if fragment and fragment ~= "" then
                List(fragment, affix, titleID)
            end
        end
    end

    -- Longest first, then lowest titleID, so the search is deterministic.
    table.sort(fragmentList, function(a, b)
        if #a.fragment ~= #b.fragment then return #a.fragment > #b.fragment end
        return a.titleID < b.titleID
    end)

    built = true
    return index
end

-- ---------------------------------------------------------------------------
-- Reading a title off a displayed name
-- ---------------------------------------------------------------------------
-- A displayed name is the unit's name with its title around it ("Private Bob",
-- "Bob the Explorer"). The simple reading strips the bare name and keeps the
-- rest. That breaks when the bare name is only part of the displayed one: WoW
-- Forever names have a first and a last name, so with UnitName "Bob" and a
-- displayed "Bob Smith" the surname " Smith" looked like a suffix title.
--
-- So a reading only counts when the text is a real title, one in this client's
-- own catalogue (GetTitleName, any locale) or in the bundled DB. When the
-- simple reading finds none, FindInDisplay looks for a catalogue title at the
-- start (prefix titles) or end (suffix titles) of the displayed name, with the
-- bare name inside what is left, which finds "Sergeant Bob Smith" and
-- "Bob Smith of the Magram". A surname that is also a title word only matches
-- where that title would sit (a prefix title is never read off the end).

local strlowerUtf = string.lower

-- The DB's text key for a title (lower case, cut at the first "-", as
-- SocialLayer has always keyed it).
local function DBKey(text)
    local base = text:match("^([^%-]+)") or text
    return strlowerUtf(base)
end

-- Whether `text`, shown as `affix` ("prefix" / "suffix"), is a real title:
-- this client's catalogue has that text in that position, or the bundled DB
-- has it with that type. Returns the catalogue titleID when there is one.
function TitleIndex:IsKnownTitleText(text, affix)
    if not text or text == "" then return false end
    self:EnsureBuilt()
    local id = affixIndex and affixIndex[Normalize(text) .. "|" .. tostring(affix)]
    if id then return true, id end
    local titles = ns.EpithetData and ns.EpithetData.titles
    local entry = titles and titles[DBKey(text)]
    if entry and (entry.type == nil or entry.type == affix) then return true, nil end
    return false
end

-- Finds a catalogue title anchored at the start (prefix) or end (suffix) of
-- `full` with `base` inside the rest. Returns titleID, affix, the title as
-- shown (original casing), and the normalised fragment; nil when none.
function TitleIndex:FindInDisplay(full, base)
    if not full or full == "" or not base or base == "" then return nil end
    self:EnsureBuilt()
    if not fragmentList then return nil end
    local lower = strlowerUtf(full)
    local baseLower = strlowerUtf(base)
    local n = #lower
    for _, entry in ipairs(fragmentList) do
        local f = entry.fragment
        local len = #f
        if len < n then
            if entry.affix == "prefix" then
                -- "<title> <name...>"
                if lower:find(f, 1, true) == 1 and lower:byte(len + 1) == 32
                    and lower:find(baseLower, len + 2, true) then
                    return entry.titleID, "prefix", Trim(full:sub(1, len)), f
                end
            else
                -- "<name...> <title>" or "<name...>, <title>"
                local s = n - len + 1
                if lower:find(f, s, true) == s then
                    local c = lower:byte(s - 1)
                    if (c == 32 or c == 44) then
                        local headEnd = lower:find(baseLower, 1, true)
                        if headEnd and headEnd + #baseLower - 1 < s then
                            return entry.titleID, "suffix", full:sub(s), f
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- The title shown in a displayed name, as (affix, text, titleID). `candidates`
-- are displayed-name strings to try in order (UnitPVPName, the target frame's
-- text); `base` is the unit's bare name (no realm). titleID is set when the
-- catalogue identified the title; nil results mean no title is shown.
local function ParseDisplay(candidate, base, escapedBase)
    if not candidate then return nil, nil end

    if candidate:find("^" .. escapedBase) then
        local suffix = candidate:sub(#base + 1)
        -- Handle cross-realm display names that include "-Realm" right
        -- after the character name before any title text.
        suffix = suffix:gsub("^%-[^,%s]+", "")
        if suffix:match("^,%s+") then
            return "suffix", (suffix:gsub("^,%s+", ""))
        end
        if suffix:match("^%s+") then
            return "suffix", (suffix:gsub("^%s+", ""))
        end
    end

    local prefix = candidate:match("^(.-)%s+" .. escapedBase .. "%-?[^%s]*$")
    if prefix and prefix:match("%S") then
        return "prefix", (prefix:gsub("%s+$", ""))
    end

    return nil, nil
end

function TitleIndex:ReadTitle(candidates, base)
    if not base or base == "" then return nil end
    local escapedBase = base:gsub("(%W)", "%%%1")
    for _, candidate in ipairs(candidates) do
        local affix, text = ParseDisplay(candidate, base, escapedBase)
        if text and text ~= "" then
            local known, id = self:IsKnownTitleText(text, affix)
            if known then return affix, text, id end
        end
    end
    for _, candidate in ipairs(candidates) do
        local id, affix, text = self:FindInDisplay(candidate, base)
        if id then return affix, text, id end
    end
    return nil
end

function TitleIndex:EnsureBuilt()
    if not built or not index then
        self:Build()
    end
    return index
end

function TitleIndex:Resolve(unit)
    if not unit or not UnitIsPlayer or not UnitIsPlayer(unit) then
        return nil
    end

    local base = UnitName and UnitName(unit)
    local full = UnitPVPName and UnitPVPName(unit) or nil
    if unit == "target" and TargetFrameName and TargetFrameName.GetText then
        full = full or TargetFrameName:GetText()
    end

    if not full or full == "" or not base or base == "" then
        return nil
    end

    local idx = self:EnsureBuilt()
    if not idx then
        return nil
    end

    if not next(idx) then
        self:Reset()
        idx = self:Build() or {}
    end

    -- A candidate counts only where the catalogue has it: text left after the
    -- name must be a suffix title, text before it a prefix title. Without this
    -- a WoW Forever player called "Bob Sergeant" would be spotted as a Sergeant.
    local candidates = BuildCandidates(full, base)
    for i, candidate in ipairs(candidates) do
        local titleID = affixIndex and affixIndex[candidate .. "|" .. candidateAffix[i]]
        if titleID then
            return self:PickFactionID(candidate, titleID, unit)
        end
    end

    -- The bare name may be only part of the displayed one (WoW Forever's first
    -- and last names): look for a catalogue title at either end instead.
    local titleID, _, _, fragment = self:FindInDisplay(full, base)
    if titleID then
        return self:PickFactionID(fragment, titleID, unit)
    end

    return nil
end

-- A fragment the data splits by faction resolves by the unit's faction.
function TitleIndex:PickFactionID(fragment, titleID, unit)
    local split = factionIndex and factionIndex[fragment]
    if split then
        local faction = ns.SafeUnitFaction and ns.SafeUnitFaction(unit) or nil
        if faction and split[faction] then
            return split[faction]
        end
    end
    return titleID
end
