-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...
local L = ns.L

local Achievements = {}
ns.SpottingAchievements = Achievements

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetNumTitles = GetNumTitles
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsTitleKnown = IsTitleKnown
local GetAchievementInfo = GetAchievementInfo
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local UnitFullName = UnitFullName
local GetLocale = GetLocale
local date = date
local random = math.random
local time = time

local THIRTY_DAYS = 30 * 24 * 60 * 60
local SEVEN_DAYS = 7 * 24 * 60 * 60
local FWENDS_THRESHOLD = 10
local CREATURE_OF_HABIT_STREAK_DAYS = 7
local SEEING_STARS_THRESHOLD = 5
local MUSEUM_CURATOR_THRESHOLD = 5
local GNOME_SPOTTER_THRESHOLD = 5
local OVERACHIEVER_THRESHOLD = 15
local TITLE_KEYWORD_THRESHOLD = 5
local SOURCE_KIND_THRESHOLD = 5
local WEEKEND_WARRIOR_THRESHOLD = 10
local PEOPLE_WATCHER_THRESHOLD = 500
local PROFESSIONAL_LURKER_THRESHOLD = 2000
local DOUBLE_TAKE_WINDOW_SECONDS = 60 * 60
local WELCOME_BACK_GAP_DAYS = 90
local WELCOME_BACK_GAP_SECONDS = WELCOME_BACK_GAP_DAYS * 24 * 60 * 60
local DECORATED_VETERAN_THRESHOLD = 5
local NOTHING_NEW_MIN_OWNED = 10
local POPULAR_PEOPLE_THRESHOLD = 3
local POPULAR_FIRST_SIGHTINGS_THRESHOLD = 5

local staticMetaByID = nil
local expansionTotal = nil
-- Filled by DefineSet from the flavour's set file.
local Registry = {}
local RegistryByID = {}
local ActiveSet = nil
local EarnedStoreFor = nil

local function CountKeys(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do
        n = n + 1
    end
    return n
end

local function BuildExpansionTotal()
    if expansionTotal then
        return expansionTotal
    end

    local seen = {}
    local titles = ns.EpithetData and ns.EpithetData.titles
    for _, data in pairs(titles or {}) do
        local exp = data and data.exp
        if exp and exp ~= "" then
            seen[exp] = true
        end
    end

    expansionTotal = CountKeys(seen)
    if expansionTotal < 1 then
        expansionTotal = 1
    end

    return expansionTotal
end

local function BuildStaticMetaByID()
    if staticMetaByID then
        return staticMetaByID
    end

    staticMetaByID = {}
    local titles = ns.EpithetData and ns.EpithetData.titles
    if not titles then
        return staticMetaByID
    end

    for _, data in pairs(titles) do
        local titleID = data and tonumber(data.titleID)
        if titleID and not staticMetaByID[titleID] then
            staticMetaByID[titleID] = {
                q = data.q,
                type = data.type,
                kind = data.kind,
                cat = data.cat,
                exp = data.exp,
                faction = data.faction,
                obtainable = data.obtainable,
                achievement_id = data.achievement_id,
                obtainability_reason = data.obtainability_reason,
                availability = data.availability,
                availability_event = data.availability_event,
                text = data.text,
            }
        end
    end

    return staticMetaByID
end

local function TitleMeta(titleID)
    local id = tonumber(titleID)
    if not id then
        return nil
    end

    if ns.TitleData and ns.TitleData.Scan then
        ns.TitleData:Scan()
    end

    local runtime = ns.TitleData and ns.TitleData.GetRecord and ns.TitleData:GetRecord(id)
    if runtime then
        return runtime
    end

    local byID = BuildStaticMetaByID()
    return byID[id]
end

local function IsExplicitRemoved(meta)
    if not meta then
        return false
    end

    local obtainable = meta.obtainable
    if obtainable == false then
        return true
    end
    if type(obtainable) == "string" then
        return obtainable:lower() == "no"
    end

    return false
end

local CurrentCharKey
local EnsureRootDB

do
-- The key per-character data was saved under before character IDs: name-realm
-- from UnitFullName. Kept exactly as it was, only to find data to migrate.
-- (On WoW Forever UnitFullName's second value is the surname, so this gave
-- "Manny-Hunters".)
local function LegacyCharKey()
    local name, realm
    if UnitFullName then
        name, realm = UnitFullName("player")
    end
    if not name or name == "" then
        return nil
    end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

-- Folds one character's data saved under `fromKey` into `toKey`, keeping the
-- earliest record of anything both have, then drops `fromKey`.
local function MergeCharacterStores(db, fromKey, toKey)
    -- Earned achievements: id -> { earned = ts, detail }.
    local oldAch = db.achievementsByChar[fromKey]
    if type(oldAch) == "table" then
        local into = db.achievementsByChar[toKey]
        if type(into) ~= "table" then
            db.achievementsByChar[toKey] = oldAch
        else
            for id, rec in pairs(oldAch) do
                local have = into[id]
                local haveTs = type(have) == "table" and tonumber(have.earned) or nil
                local oldTs = type(rec) == "table" and tonumber(rec.earned) or nil
                if not have or (oldTs and (not haveTs or oldTs < haveTs)) then
                    into[id] = rec
                end
            end
        end
        db.achievementsByChar[fromKey] = nil
    end

    -- Owned titles: titleID -> { ts, reliable, source } (or a bare timestamp).
    local oldOwned = db.ownedSeen[fromKey]
    if type(oldOwned) == "table" then
        local into = db.ownedSeen[toKey]
        if type(into) ~= "table" then
            db.ownedSeen[toKey] = oldOwned
        else
            local function Read(raw)
                if type(raw) == "table" then
                    return tonumber(raw.ts), raw.reliable == true
                end
                return tonumber(raw), false
            end
            for titleID, raw in pairs(oldOwned) do
                local have = into[titleID]
                if have == nil then
                    into[titleID] = raw
                else
                    local oldTs, oldReliable = Read(raw)
                    local haveTs, haveReliable = Read(have)
                    -- A reliable date beats a guessed one; otherwise the earlier wins.
                    if (oldReliable and not haveReliable)
                        or (oldReliable == haveReliable and oldTs and (not haveTs or oldTs < haveTs)) then
                        into[titleID] = raw
                    end
                end
            end
        end
        db.ownedSeen[fromKey] = nil
    end

    if db.ownedSeenBaseline[fromKey] then
        db.ownedSeenBaseline[toKey] = true
        db.ownedSeenBaseline[fromKey] = nil
    end
end

-- A readable label for each character ID, refreshed at every login.
local function RecordCharacterLabel(db, guid)
    db.characters = type(db.characters) == "table" and db.characters or {}
    local label = type(db.characters[guid]) == "table" and db.characters[guid] or {}
    -- GetUnitName gives the full "First Last" on WoW Forever, the name on Retail.
    local name = (GetUnitName and GetUnitName("player", false)) or (UnitName and UnitName("player"))
    if type(name) == "string" and name ~= "" then
        label.name = name
    end
    local showRealm = not ns.Flavor or ns.Flavor.showRealm ~= false
    local realm = showRealm and GetNormalizedRealmName and GetNormalizedRealmName() or nil
    label.realm = (type(realm) == "string" and realm ~= "") and realm or nil
    label.lastLogin = time()
    db.characters[guid] = label
end

local migratedFor = nil

-- Per-character data is keyed by the character's ID (UnitGUID), which
-- survives a Retail name change; db.characters[id] holds the readable label.
-- The first call each session moves anything still saved under the old
-- name-realm key across. Nil until the game knows who the player is.
CurrentCharKey = function()
    local guid = UnitGUID and UnitGUID("player")
    if type(guid) ~= "string" or guid == "" then
        return nil
    end
    if migratedFor ~= guid then
        migratedFor = guid
        local db = EnsureRootDB()
        local legacy = LegacyCharKey()
        if legacy and legacy ~= guid then
            MergeCharacterStores(db, legacy, guid)
        end
        RecordCharacterLabel(db, guid)
    end
    return guid
end
end

EnsureRootDB = function()
    if type(_G.EpithetDB) ~= "table" then
        _G.EpithetDB = {}
    end
    local db = _G.EpithetDB
    if type(db.spotted) ~= "table" then
        db.spotted = {}
    end
    if type(db.achievements) ~= "table" then
        db.achievements = {}
    end
    if type(db.achievementsByChar) ~= "table" then
        db.achievementsByChar = {}
    end
    if type(db.ownedSeen) ~= "table" then
        db.ownedSeen = {}
    end
    if type(db.ownedSeenBaseline) ~= "table" then
        db.ownedSeenBaseline = {}
    end
    if type(db.achievementReveal) ~= "table" then
        db.achievementReveal = {}
    end
    if type(db.spottingEvents) ~= "table" then
        db.spottingEvents = {}
    end
    return db
end

-- The key for this character's per-character achievement data (see above).
Achievements.CurrentCharKey = function()
    return CurrentCharKey()
end

-- Shared with Spotting/Capture.lua so both modules guarantee the same set of
-- EpithetDB subtables exist, instead of each keeping its own ad hoc guard.
ns.EnsureSpottingRootDB = EnsureRootDB

local function OwnedForCurrentChar()
    local db = EnsureRootDB()
    local key = CurrentCharKey()
    if not key then
        return nil
    end

    local all = db.ownedSeen
    if type(all[key]) ~= "table" then
        all[key] = {}
    end
    return all[key]
end

local function GetOwnedTimestamp(raw)
    if type(raw) == "number" then
        return tonumber(raw), false
    end

    if type(raw) == "table" then
        local ts = tonumber(raw.ts or raw.time or raw.firstDetected)
        local reliable = (raw.reliable == true)
        return ts, reliable
    end

    return nil, false
end

local function SetOwnedTimestamp(owned, titleID, ts, reliable, source)
    if not owned or not titleID or not ts then
        return
    end

    owned[titleID] = {
        ts = ts,
        reliable = reliable == true,
        source = source,
    }
end

local function GetAchievementCompletionTimestamp(achievementID)
    local id = tonumber(achievementID)
    if not id or not GetAchievementInfo then
        return nil
    end

    local _, _, _, completed, month, day, year = GetAchievementInfo(id)
    if not completed or not month or not day or not year or year <= 0 then
        return nil
    end

    local fullYear = year
    if fullYear < 100 then
        fullYear = 2000 + fullYear
    end

    return time({
        year = fullYear,
        month = month,
        day = day,
        hour = 12,
        min = 0,
        sec = 0,
    })
end

local function ResolveReliableOwnedTimestamp(titleID)
    local meta = TitleMeta(titleID)
    local achievementID = meta and meta.achievement_id
    if achievementID then
        local ts = GetAchievementCompletionTimestamp(achievementID)
        if ts then
            return ts, true, "achievement"
        end
    end

    return nil, false, nil
end

-- Registry defs each check/progress independently via CountSpotted(spotted),
-- and up to 9 count thresholds can be simultaneously unearned, so a single
-- Evaluate() pass could otherwise re-scan the whole `spotted` table 9+ times.
-- Cache the count for the duration of one pass; callers must invalidate it
-- via InvalidateSpottedCountCache() before iterating the registry.
local cachedSpottedCount = nil

local function InvalidateSpottedCountCache()
    cachedSpottedCount = nil
end

local function CountSpotted(spotted)
    if cachedSpottedCount == nil then
        cachedSpottedCount = CountKeys(spotted)
    end
    return cachedSpottedCount
end

local function CheckCount(threshold)
    return function(spotted)
        return CountSpotted(spotted) >= threshold
    end
end

local function CheckRollCallOf(classTotal)
  return function(spotted)
    local seen = {}
    local n = 0

    for _, entry in pairs(spotted) do
        local tag = entry and entry.classTag
        if tag and not seen[tag] then
            seen[tag] = true
            n = n + 1
        end
    end

    if n >= classTotal then
        return true, tostring(classTotal)
    end

    return false
  end
end

local function CheckFullSpectrum(spotted)
    local seen = {}
    local n = 0

    for _, entry in pairs(spotted) do
        local q = entry and entry.quality
        if q and not seen[q] then
            seen[q] = true
            n = n + 1
        end
    end

    return n >= 5
end

local function CheckBothEnds(spotted)
    local hasPrefix, hasSuffix = false, false

    for _, entry in pairs(spotted) do
        if entry and entry.titleType == "prefix" then
            hasPrefix = true
        elseif entry and entry.titleType == "suffix" then
            hasSuffix = true
        end

        if hasPrefix and hasSuffix then
            return true
        end
    end

    return false
end

local function CheckGrandTour(spotted)
    local seen = {}
    local n = 0

    for _, entry in pairs(spotted) do
        local zone = entry and entry.firstZone
        if zone and not seen[zone] then
            seen[zone] = true
            n = n + 1
        end
    end

    return n >= 10
end

local function CheckTitleFwends(spotted)
    local byFriend = {}

    for _, entry in pairs(spotted) do
        local name = entry and entry.firstName
        if name then
            local n = (byFriend[name] or 0) + 1
            byFriend[name] = n
            if n >= FWENDS_THRESHOLD then
                return true, name
            end
        end
    end

    return false
end

local function CheckHaventWeMet(spotted)
    for _, entry in pairs(spotted) do
        if (entry and tonumber(entry.count) or 0) >= 10 then
            return true
        end
    end
    return false
end

local function CheckLongCon(spotted)
    for _, entry in pairs(spotted) do
        if entry and entry.firstSeen and entry.lastSeen and (entry.lastSeen - entry.firstSeen) >= THIRTY_DAYS then
            return true
        end
    end

    return false
end

local function CheckNightShift(spotted)
    for _, entry in pairs(spotted) do
        if entry and entry.firstSeen then
            local hour = tonumber(date("%H", entry.firstSeen))
            if hour and hour >= 3 and hour < 5 then
                return true
            end
        end
    end

    return false
end

local function CheckBusyDay(spotted)
    local byDay = {}

    for _, entry in pairs(spotted) do
        if entry and entry.firstSeen then
            local day = date("%Y-%m-%d", entry.firstSeen)
            local n = (byDay[day] or 0) + 1
            byDay[day] = n
            if n >= 5 then
                return true
            end
        end
    end

    return false
end

local function CheckCapitalOffence(spotted)
    local byZone = {}

    for _, entry in pairs(spotted) do
        local zone = entry and entry.firstZone
        if zone then
            local n = (byZone[zone] or 0) + 1
            byZone[zone] = n
            if n >= 10 then
                return true, zone
            end
        end
    end

    return false
end

local function CheckOldMoney(spotted)
    for titleID, entry in pairs(spotted) do
        local meta = TitleMeta(titleID)
        if IsExplicitRemoved(meta) then
            return true, (entry and entry.titleText) or (meta and meta.text)
        end
    end

    return false
end

local function CheckLegendarySpot(spotted)
    for _, entry in pairs(spotted) do
        if entry and tonumber(entry.quality) == 5 then
            return true
        end
    end

    return false
end

local function ResolveSpottedTitleDetail(titleID, spottedEntry)
    if spottedEntry and spottedEntry.titleText and spottedEntry.titleText ~= "" then
        return spottedEntry.titleText
    end

    local meta = TitleMeta(titleID)
    if meta and meta.text and meta.text ~= "" then
        return meta.text
    end

    return nil
end

local function CheckPottedHistory(spotted)
    local seen = {}
    local n = 0

    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        local exp = meta and meta.exp
        if exp and exp ~= "" and not seen[exp] then
            seen[exp] = true
            n = n + 1
        end
    end

    local target = BuildExpansionTotal()
    if n >= target then
        return true, tostring(target)
    end

    return false
end

local function CheckDiplomaticImmunity(spotted)
    local alliance = false
    local horde = false

    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        local faction = meta and meta.faction
        if faction and faction ~= "" then
            local key = tostring(faction):lower()
            if key == "alliance" then
                alliance = true
            elseif key == "horde" then
                horde = true
            end
        end

        if alliance and horde then
            return true
        end
    end

    return false
end

local function CheckSmallWorld(spotted)
    for titleID, entry in pairs(spotted) do
        if entry and entry.firstName and entry.lastName and entry.firstName ~= entry.lastName then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end

    return false
end

local function CheckCreatureOfHabit(spotted)
    local days = {}
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            if d then
                local midday = time({ year = d.year, month = d.month, day = d.day, hour = 12, min = 0, sec = 0 })
                if midday then
                    days[math.floor(midday / 86400)] = true
                end
            end
        end
    end

    local ordered = {}
    for idx in pairs(days) do
        ordered[#ordered + 1] = idx
    end
    table.sort(ordered)

    local run = 1
    for i = 2, #ordered do
        if ordered[i] == ordered[i - 1] + 1 then
            run = run + 1
            if run >= CREATURE_OF_HABIT_STREAK_DAYS then
                return true
            end
        else
            run = 1
        end
    end

    return false
end

local function CheckSeeingStars(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        if tonumber(entry and entry.quality) == 5 then
            n = n + 1
            if n >= SEEING_STARS_THRESHOLD then
                return true
            end
        end
    end

    return false
end

local function CheckMuseumCurator(spotted)
    local n = 0
    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        if IsExplicitRemoved(meta) then
            n = n + 1
            if n >= MUSEUM_CURATOR_THRESHOLD then
                return true
            end
        end
    end

    return false
end

local function CheckGnomeSpotter(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        local race = entry and entry.raceTag
        if type(race) == "string" and race:lower() == "gnome" then
            n = n + 1
            if n >= GNOME_SPOTTER_THRESHOLD then
                return true
            end
        end
    end

    return false
end

local function CheckSpottedTitleID(titleID)
    return function(spotted)
        return spotted[titleID] ~= nil
    end
end

local function CountOverachieverProgress()
    local db = EnsureRootDB()
    local n = 0

    local hidden = ActiveSet and ActiveSet.hiddenByID or {}
    for id in pairs(db.achievements or {}) do
        if id ~= "overachiever" and not hidden[id] then
            n = n + 1
        end
    end

    local mine = db.achievementsByChar and db.achievementsByChar[CurrentCharKey()]
    for id in pairs(mine or {}) do
        if id ~= "overachiever" and not hidden[id] then
            n = n + 1
        end
    end

    return n
end

local function CheckOverachiever()
    return CountOverachieverProgress() >= OVERACHIEVER_THRESHOLD
end

local function CheckGuising(spotted)
    for _, entry in pairs(spotted) do
        if entry and entry.firstSeen and date("%m-%d", entry.firstSeen) == "10-31" then
            return true
        end
    end

    return false
end

local function EntrySightingCount(entry)
    local count = tonumber(entry and entry.count)
    if not count or count < 1 then
        return 1
    end
    return math.max(1, math.floor(count))
end

local function NormalizedMetaText(meta)
    local text = meta and meta.text
    if type(text) ~= "string" then
        return nil
    end

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    if text == "" then
        return nil
    end

    return text
end

-- A title's ENGLISH catalogue name, i.e. the text the bundled DB is keyed by.
--
-- A live record's `text` comes from GetTitleName(), which Blizzard returns
-- already localised, so it reads differently on every client. The bundled DB is
-- titleID-keyed (titleIDs are identical in every locale) and always English, so
-- matching text-based achievements against this instead makes them resolve the
-- same way in every language rather than only on an English client.
--
-- Falls back to the live localised text for any title the DB snapshot doesn't
-- carry yet: on an English client that is still the English name, so newly-added
-- titles keep counting exactly as they did before.
local function CatalogueText(titleID, meta)
    local byID = ns.EpithetData and ns.EpithetData.titlesByID
    local entry = byID and byID[tonumber(titleID)]
    local text = entry and entry.text
    if type(text) == "string" then
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text ~= "" then
            return text
        end
    end

    return NormalizedMetaText(meta)
end

local function NormalizedMetaToken(meta, key)
    local value = meta and meta[key]
    if type(value) ~= "string" then
        return nil
    end
    value = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then
        return nil
    end
    return value
end

local function MetaMatchesSource(meta, wanted)
    local token = tostring(wanted or ""):lower()
    if token == "" then
        return false
    end

    local kind = NormalizedMetaToken(meta, "kind")
    local cat = NormalizedMetaToken(meta, "cat")

    if kind == token or cat == token then
        return true
    end

    if token == "pvp" then
        return (kind and kind:find("pvp", 1, true) ~= nil)
            or (cat and cat:find("pvp", 1, true) ~= nil)
    end

    if token == "raid" then
        return (kind and kind:find("raid", 1, true) ~= nil)
            or (cat and cat:find("raid", 1, true) ~= nil)
    end

    if token == "reputation" then
        return kind == "reputation" or cat == "reputation"
    end

    return false
end

local function CountDistinctTitlesByTextMatch(spotted, needle)
    local keyword = tostring(needle or ""):lower()
    if keyword == "" then
        return 0
    end

    local n = 0
    for titleID in pairs(spotted) do
        local text = CatalogueText(titleID, TitleMeta(titleID))
        if text and text:lower():find(keyword, 1, true) then
            n = n + 1
        end
    end

    return n
end

local function CountDistinctTitlesBySource(spotted, sourceToken)
    local n = 0
    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        if MetaMatchesSource(meta, sourceToken) then
            n = n + 1
        end
    end
    return n
end

-- Length is measured on the English catalogue text, so the threshold means the
-- same thing on every client (and stays a plain byte count: the catalogue is
-- ASCII, unlike a localised name where one accented character is two bytes).
local function CheckQuiteAMouthful(spotted)
    for titleID, entry in pairs(spotted) do
        local text = CatalogueText(titleID, TitleMeta(titleID))
        if text and #text >= 25 then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end
    return false
end

local function CheckTerse(spotted)
    for titleID, entry in pairs(spotted) do
        local text = CatalogueText(titleID, TitleMeta(titleID))
        if text and #text <= 5 then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end
    return false
end

-- Keyword achievements match a word against a title's English catalogue text
-- (see CatalogueText), never against the client's localised name, so the search
-- word is one language-neutral constant and every client hunts the same set of
-- titles. Only the achievement's displayed name/description is translated, in
-- the locale files.
local KEYWORD_ACHIEVEMENTS = {
    lord_of_lords = "lord",
    masterclass   = "master",
    slay          = "slayer",
}

local function CheckKeyword(id)
    return function(spotted)
        local keyword = KEYWORD_ACHIEVEMENTS[id]
        if not keyword then return false end
        return CountDistinctTitlesByTextMatch(spotted, keyword) >= TITLE_KEYWORD_THRESHOLD
    end
end

local function CheckGladiatorGroupie(spotted)
    return CountDistinctTitlesBySource(spotted, "pvp") >= SOURCE_KIND_THRESHOLD
end

local function CheckRaidSpectator(spotted)
    return CountDistinctTitlesBySource(spotted, "raid") >= SOURCE_KIND_THRESHOLD
end

local function CheckBrownNoser(spotted)
    return CountDistinctTitlesBySource(spotted, "reputation") >= SOURCE_KIND_THRESHOLD
end

local function CheckHowItsMade(spotted)
    local hasAchievement = false
    local hasQuest = false
    local hasItem = false

    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        if meta and meta.achievement_id then
            hasAchievement = true
        end
        if meta and meta.quest_id then
            hasQuest = true
        end
        if meta and meta.source_item and tostring(meta.source_item) ~= "" then
            hasItem = true
        end

        if hasAchievement and hasQuest and hasItem then
            return true
        end
    end

    return false
end

local function TotalSightings(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        n = n + EntrySightingCount(entry)
    end
    return n
end

local function CheckPeopleWatcher(spotted)
    return TotalSightings(spotted) >= PEOPLE_WATCHER_THRESHOLD
end

local function CheckProfessionalLurker(spotted)
    return TotalSightings(spotted) >= PROFESSIONAL_LURKER_THRESHOLD
end

local function CheckDoubleTake(spotted)
    for titleID, entry in pairs(spotted) do
        local count = EntrySightingCount(entry)
        local firstSeen = entry and tonumber(entry.firstSeen)
        local lastSeen = entry and tonumber(entry.lastSeen)
        if count >= 2 and firstSeen and lastSeen and (lastSeen - firstSeen) <= DOUBLE_TAKE_WINDOW_SECONDS then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end

    return false
end

local function CheckEarlyBird(spotted)
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local hour = tonumber(date("%H", firstSeen))
            if hour and hour >= 5 and hour <= 8 then
                return true
            end
        end
    end
    return false
end

local function CheckWeekendWarrior(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            if d and (d.wday == 1 or d.wday == 7) then
                n = n + 1
                if n >= WEEKEND_WARRIOR_THRESHOLD then
                    return true
                end
            end
        end
    end
    return false
end

local function CheckFullWeek(spotted)
    local seen = {}
    local n = 0

    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            local wday = d and d.wday
            if wday and not seen[wday] then
                seen[wday] = true
                n = n + 1
                if n >= 7 then
                    return true
                end
            end
        end
    end

    return false
end

local function CheckYearInField(spotted)
    local seen = {}
    local n = 0

    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            local month = d and d.month
            if month and not seen[month] then
                seen[month] = true
                n = n + 1
                if n >= 12 then
                    return true
                end
            end
        end
    end

    return false
end

local function CheckWelcomeBack(spotted)
    local days = {}

    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            if d then
                local midday = time({ year = d.year, month = d.month, day = d.day, hour = 12, min = 0, sec = 0 })
                if midday then
                    days[math.floor(midday / 86400)] = true
                end
            end
        end
    end

    local ordered = {}
    for idx in pairs(days) do
        ordered[#ordered + 1] = idx
    end
    table.sort(ordered)

    for i = 2, #ordered do
        if (ordered[i] - ordered[i - 1]) * 86400 >= WELCOME_BACK_GAP_SECONDS then
            return true
        end
    end

    return false
end

local function CheckFeastYourEyes(spotted)
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen and date("%m-%d", firstSeen) == "12-25" then
            return true
        end
    end

    return false
end

local function CheckParticipationAward(spotted)
    for _, entry in pairs(spotted) do
        if tonumber(entry and entry.quality) == 1 then
            return true
        end
    end

    return false
end

local function CheckSneakyBeaky(spotted)
    for _, entry in pairs(spotted) do
        if entry and entry.classTag == "ROGUE" then
            return true
        end
    end

    return false
end

local function CheckDeadManWalking(spotted)
    for _, entry in pairs(spotted) do
        if entry and entry.classTag == "DEATHKNIGHT" then
            return true
        end
    end

    return false
end

local function CheckOldSchool(spotted)
    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        local exp = meta and tostring(meta.exp or ""):lower()
        if exp == "classic" then
            return true
        end
    end

    return false
end

local function CheckCurriculumVitae()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local seen = {}
    local n = 0
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        local exp = meta and meta.exp
        if exp and exp ~= "" and not seen[exp] then
            seen[exp] = true
            n = n + 1
        end
    end

    local target = BuildExpansionTotal()
    if n >= target then
        return true, tostring(target)
    end

    return false
end

local function CheckDecoratedVeteran()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local n = 0
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        if MetaMatchesSource(meta, "pvp") then
            n = n + 1
            if n >= DECORATED_VETERAN_THRESHOLD then
                return true
            end
        end
    end

    return false
end

local function CheckNothingNew()
    local db = EnsureRootDB()
    local spotted = db.spotted or {}
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local ownedCount = 0
    for titleID in pairs(owned) do
        ownedCount = ownedCount + 1
        if not spotted[titleID] then
            return false
        end
    end

    return ownedCount >= NOTHING_NEW_MIN_OWNED
end

local function CheckMatchingSet()
    local db = EnsureRootDB()
    local spotted = db.spotted or {}
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local tiers = {}
    for titleID in pairs(owned) do
        if spotted[titleID] then
            local meta = TitleMeta(titleID)
            local q = tonumber(meta and meta.q)
            if q and q >= 1 and q <= 5 then
                tiers[q] = true
            end
        end
    end

    for q = 1, 5 do
        if not tiers[q] then
            return false
        end
    end

    return true
end

local function CheckPopular(spotted)
    local byPerson = {}
    local contributors = 0

    for _, entry in pairs(spotted) do
        local name = entry and entry.firstName
        if name and name ~= "" then
            local n = (byPerson[name] or 0) + 1
            byPerson[name] = n
            if n == POPULAR_FIRST_SIGHTINGS_THRESHOLD then
                contributors = contributors + 1
                if contributors >= POPULAR_PEOPLE_THRESHOLD then
                    return true
                end
            end
        end
    end

    return false
end

local function CheckRestrainingOrder(spotted)
    for titleID, entry in pairs(spotted) do
        if EntrySightingCount(entry) >= 25 then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end
    return false
end

local function CheckBeyondTheGrave()
    local db = EnsureRootDB()
    local hit = db.spottingEvents and db.spottingEvents.beyond_the_grave
    if hit then
        local titleID = tonumber(hit.titleID)
        local meta = titleID and TitleMeta(titleID) or nil
        return true, (meta and meta.text) or nil
    end
    return false
end

local function CheckKnowThyEnemy()
    local db = EnsureRootDB()
    local hit = db.spottingEvents and db.spottingEvents.know_thy_enemy
    if hit then
        local titleID = tonumber(hit.titleID)
        local meta = titleID and TitleMeta(titleID) or nil
        return true, (meta and meta.text) or nil
    end
    return false
end

local function CountEarnedSecrets()
    local earned = 0
    local total = 0

    for _, def in ipairs(Registry or {}) do
        if def.secret == true and not def.timeLimited then
            total = total + 1
            local store = EarnedStoreFor and EarnedStoreFor(def, false) or nil
            if store and store[def.id] then
                earned = earned + 1
            end
        end
    end

    return earned, total
end

local function CheckSecretKeeper()
    local earned, total = CountEarnedSecrets()
    if total > 0 and earned >= total then
        return true, tostring(total)
    end

    return false
end

local function CheckImpulsePurchase()
    local db = EnsureRootDB()
    local spotted = db.spotted
    local owned = OwnedForCurrentChar()
    if not spotted or not owned then
        return false
    end

    for titleID, s in pairs(spotted) do
        local raw = owned[titleID]
        local firstDetected = type(raw) == "table" and tonumber(raw.ts) or tonumber(raw)
        local isBaseline = (type(raw) == "table" and raw.source == "scan_baseline")

        if firstDetected and s and s.firstSeen and not isBaseline
            and firstDetected > s.firstSeen
            and (firstDetected - s.firstSeen) <= SEVEN_DAYS then
            return true, ResolveSpottedTitleDetail(titleID, s)
        end
    end

    return false
end

local function CheckTwinsies()
    local db = EnsureRootDB()
    local hit = db.spottingEvents and db.spottingEvents.twinsies
    if hit then
        local titleID = tonumber(hit.titleID)
        local meta = titleID and TitleMeta(titleID) or nil
        return true, (meta and meta.text) or nil
    end

    return false
end

local function CountOwnedCurrent()
    return CountKeys(OwnedForCurrentChar())
end

local function CheckOwnedCount(threshold)
    return function()
        return CountOwnedCurrent() >= threshold
    end
end

local function CheckOwnedSpectrum()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local seen = {}
    local n = 0

    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        local q = meta and meta.q
        if q and not seen[q] then
            seen[q] = true
            n = n + 1
        end
    end

    return n >= 5
end

local function CheckOwnedBothEnds()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    local hasPrefix, hasSuffix = false, false
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        local kind = meta and meta.type
        if kind == "prefix" then
            hasPrefix = true
        elseif kind == "suffix" then
            hasSuffix = true
        end
        if hasPrefix and hasSuffix then
            return true
        end
    end

    return false
end

local function CheckOwnedLegendary()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        if meta and tonumber(meta.q) == 5 then
            return true
        end
    end

    return false
end

local function CheckOwnedRemoved()
    local owned = OwnedForCurrentChar()
    if not owned then
        return false
    end

    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        if IsExplicitRemoved(meta) then
            return true
        end
    end

    return false
end

local function CheckTakesOne()
    local db = EnsureRootDB()
    local spotted = db.spotted
    local owned = OwnedForCurrentChar()
    if not spotted or not owned then
        return false
    end

    for titleID, entry in pairs(spotted) do
        local firstDetected, reliable = GetOwnedTimestamp(owned[titleID])
        if reliable and firstDetected and entry and entry.firstSeen and firstDetected < entry.firstSeen then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end

    return false
end

local function CheckWindowShopper()
    local db = EnsureRootDB()
    local spotted = db.spotted
    local owned = OwnedForCurrentChar()
    if not spotted or not owned then
        return false
    end

    for titleID, entry in pairs(spotted) do
        local firstDetected, reliable = GetOwnedTimestamp(owned[titleID])
        if reliable and firstDetected and entry and entry.firstSeen and entry.firstSeen < firstDetected then
            return true, ResolveSpottedTitleDetail(titleID, entry)
        end
    end

    return false
end

-- Progress functions are only reached through Achievements.B, so they live in
-- a block (the file is near Lua's 200-local limit) and are handed out via
-- ProgressFns.
local ProgressFns = {}
do
local function ProgressCountSpotted(threshold)
    return function(spotted)
        local n = CountSpotted(spotted)
        return math.min(n, threshold), threshold
    end
end

local function ProgressRollCallOf(classTotal)
  return function(spotted)
    local seen = {}
    local n = 0
    for _, entry in pairs(spotted) do
        local tag = entry and entry.classTag
        if tag and not seen[tag] then
            seen[tag] = true
            n = n + 1
        end
    end
    return math.min(n, classTotal), classTotal
  end
end

local function ProgressFullSpectrum(spotted)
    local seen = {}
    local n = 0
    for _, entry in pairs(spotted) do
        local q = entry and entry.quality
        if q and not seen[q] then
            seen[q] = true
            n = n + 1
        end
    end
    return math.min(n, 5), 5
end

local function ProgressGrandTour(spotted)
    local seen = {}
    local n = 0
    for _, entry in pairs(spotted) do
        local zone = entry and entry.firstZone
        if zone and not seen[zone] then
            seen[zone] = true
            n = n + 1
        end
    end
    return math.min(n, 10), 10
end

local function ProgressPottedHistory(spotted)
    local seen = {}
    local n = 0
    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        local exp = meta and meta.exp
        if exp and exp ~= "" and not seen[exp] then
            seen[exp] = true
            n = n + 1
        end
    end

    local target = BuildExpansionTotal()
    return math.min(n, target), target
end

local function ProgressSeeingStars(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        if tonumber(entry and entry.quality) == 5 then
            n = n + 1
        end
    end
    return math.min(n, SEEING_STARS_THRESHOLD), SEEING_STARS_THRESHOLD
end

local function ProgressMuseumCurator(spotted)
    local n = 0
    for titleID in pairs(spotted) do
        local meta = TitleMeta(titleID)
        if IsExplicitRemoved(meta) then
            n = n + 1
        end
    end
    return math.min(n, MUSEUM_CURATOR_THRESHOLD), MUSEUM_CURATOR_THRESHOLD
end

local function ProgressGnomeSpotter(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        local race = entry and entry.raceTag
        if type(race) == "string" and race:lower() == "gnome" then
            n = n + 1
        end
    end
    return math.min(n, GNOME_SPOTTER_THRESHOLD), GNOME_SPOTTER_THRESHOLD
end

local function ProgressOverachiever()
    local n = CountOverachieverProgress()
    return math.min(n, OVERACHIEVER_THRESHOLD), OVERACHIEVER_THRESHOLD
end

local function ProgressKeyword(id)
    return function(spotted)
        local keyword = KEYWORD_ACHIEVEMENTS[id]
        local n = keyword and CountDistinctTitlesByTextMatch(spotted, keyword) or 0
        return math.min(n, TITLE_KEYWORD_THRESHOLD), TITLE_KEYWORD_THRESHOLD
    end
end

local function ProgressSourceSpotting(sourceToken)
    return function(spotted)
        local n = CountDistinctTitlesBySource(spotted, sourceToken)
        return math.min(n, SOURCE_KIND_THRESHOLD), SOURCE_KIND_THRESHOLD
    end
end

local function ProgressTotalSightings(threshold)
    return function(spotted)
        local n = TotalSightings(spotted)
        return math.min(n, threshold), threshold
    end
end

local function ProgressWeekendWarrior(spotted)
    local n = 0
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            if d and (d.wday == 1 or d.wday == 7) then
                n = n + 1
            end
        end
    end
    return math.min(n, WEEKEND_WARRIOR_THRESHOLD), WEEKEND_WARRIOR_THRESHOLD
end

local function ProgressFullWeek(spotted)
    local seen = {}
    local n = 0
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            local wday = d and d.wday
            if wday and not seen[wday] then
                seen[wday] = true
                n = n + 1
            end
        end
    end
    return math.min(n, 7), 7
end

local function ProgressYearInField(spotted)
    local seen = {}
    local n = 0
    for _, entry in pairs(spotted) do
        local firstSeen = entry and tonumber(entry.firstSeen)
        if firstSeen then
            local d = date("*t", firstSeen)
            local month = d and d.month
            if month and not seen[month] then
                seen[month] = true
                n = n + 1
            end
        end
    end
    return math.min(n, 12), 12
end

local function ProgressCurriculumVitae()
    local owned = OwnedForCurrentChar() or {}
    local seen = {}
    local n = 0
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        local exp = meta and meta.exp
        if exp and exp ~= "" and not seen[exp] then
            seen[exp] = true
            n = n + 1
        end
    end

    local target = BuildExpansionTotal()
    return math.min(n, target), target, true
end

local function ProgressDecoratedVeteran()
    local owned = OwnedForCurrentChar() or {}
    local n = 0
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        if MetaMatchesSource(meta, "pvp") then
            n = n + 1
        end
    end
    return math.min(n, DECORATED_VETERAN_THRESHOLD), DECORATED_VETERAN_THRESHOLD, true
end

local function ProgressPopular(spotted)
    local byPerson = {}
    local contributors = 0

    for _, entry in pairs(spotted) do
        local name = entry and entry.firstName
        if name and name ~= "" then
            local n = (byPerson[name] or 0) + 1
            byPerson[name] = n
            if n == POPULAR_FIRST_SIGHTINGS_THRESHOLD then
                contributors = contributors + 1
            end
        end
    end

    return math.min(contributors, POPULAR_PEOPLE_THRESHOLD), POPULAR_PEOPLE_THRESHOLD
end

local function ProgressSecretKeeper()
    local earned, total = CountEarnedSecrets()
    if total < 1 then
        total = 1
    end
    return math.min(earned, total), total
end

local function ProgressOwnedCount(threshold)
    return function()
        local n = CountOwnedCurrent()
        return math.min(n, threshold), threshold, true
    end
end

local function ProgressOwnedSpectrum()
    local owned = OwnedForCurrentChar() or {}
    local seen = {}
    local n = 0
    for titleID in pairs(owned) do
        local meta = TitleMeta(titleID)
        local q = meta and meta.q
        if q and not seen[q] then
            seen[q] = true
            n = n + 1
        end
    end
    return math.min(n, 5), 5, true
end

ProgressFns.ProgressCountSpotted = ProgressCountSpotted
ProgressFns.ProgressRollCallOf = ProgressRollCallOf
ProgressFns.ProgressFullSpectrum = ProgressFullSpectrum
ProgressFns.ProgressGrandTour = ProgressGrandTour
ProgressFns.ProgressPottedHistory = ProgressPottedHistory
ProgressFns.ProgressSeeingStars = ProgressSeeingStars
ProgressFns.ProgressMuseumCurator = ProgressMuseumCurator
ProgressFns.ProgressGnomeSpotter = ProgressGnomeSpotter
ProgressFns.ProgressOverachiever = ProgressOverachiever
ProgressFns.ProgressKeyword = ProgressKeyword
ProgressFns.ProgressSourceSpotting = ProgressSourceSpotting
ProgressFns.ProgressTotalSightings = ProgressTotalSightings
ProgressFns.ProgressWeekendWarrior = ProgressWeekendWarrior
ProgressFns.ProgressFullWeek = ProgressFullWeek
ProgressFns.ProgressYearInField = ProgressYearInField
ProgressFns.ProgressCurriculumVitae = ProgressCurriculumVitae
ProgressFns.ProgressDecoratedVeteran = ProgressDecoratedVeteran
ProgressFns.ProgressPopular = ProgressPopular
ProgressFns.ProgressSecretKeeper = ProgressSecretKeeper
ProgressFns.ProgressOwnedCount = ProgressOwnedCount
ProgressFns.ProgressOwnedSpectrum = ProgressOwnedSpectrum
end

-- Scoped: the file is near Lua's 200-local limit, so these helpers live in
-- a block and leave only Achievements.BuildersFromData behind.
do
-- ---------------------------------------------------------------------------
-- Builders over the flavour's own title data (first used by WoW Forever's
-- set). They read the catalogue this client loaded, so a set says what to
-- look for and the data decides which titles that is.
-- ---------------------------------------------------------------------------

-- titleID -> { faction, rank } for PvP rank titles. The data states the rank
-- only in prose ("Horde PvP rank 7 of 14"); a rank field would be sturdier.
local pvpRanks = nil
local function PvPRanks()
    if pvpRanks then
        return pvpRanks
    end
    pvpRanks = {}
    for titleID, meta in pairs(BuildStaticMetaByID()) do
        if meta.kind == "PvP Rank" then
            local proseFaction, rank = tostring(meta.obtainability_reason or ""):match("(%a+) PvP rank (%d+) of %d+")
            local faction = meta.faction or proseFaction
            if faction and rank then
                pvpRanks[titleID] = { faction = faction, rank = tonumber(rank) }
            end
        end
    end
    return pvpRanks
end

local function FactionLabel(faction)
    if faction == "Alliance" and _G.FACTION_ALLIANCE then
        return _G.FACTION_ALLIANCE
    elseif faction == "Horde" and _G.FACTION_HORDE then
        return _G.FACTION_HORDE
    end
    return faction
end

-- The faction ladder closest to complete: faction, ranks spotted, ranks in it.
local function BestLadder(spotted)
    local total, have = {}, {}
    for titleID, info in pairs(PvPRanks()) do
        total[info.faction] = (total[info.faction] or 0) + 1
        if spotted[titleID] then
            have[info.faction] = (have[info.faction] or 0) + 1
        end
    end
    local factions = {}
    for faction in pairs(total) do
        factions[#factions + 1] = faction
    end
    table.sort(factions)
    local best, bestHave, bestTotal = nil, -1, 0
    for _, faction in ipairs(factions) do
        local h = have[faction] or 0
        if h > bestHave then
            best, bestHave, bestTotal = faction, h, total[faction]
        end
    end
    return best, math.max(bestHave, 0), bestTotal
end

local function CheckFullLadder(spotted)
    local faction, h, n = BestLadder(spotted)
    if faction and n > 0 and h >= n then
        return true, FactionLabel(faction)
    end
    return false
end

local function ProgressFullLadder(spotted)
    local _, h, n = BestLadder(spotted)
    if n < 1 then
        return nil
    end
    return math.min(h, n), n
end

-- The same rank spotted on both factions; `rank` limits it to one rank.
local function CheckMirrorRank(rank)
    return function(spotted)
        local byRank = {}
        for titleID, info in pairs(PvPRanks()) do
            if spotted[titleID] and (rank == nil or info.rank == rank) then
                local factions = byRank[info.rank] or {}
                factions[info.faction] = true
                byRank[info.rank] = factions
            end
        end
        local ranks = {}
        for r in pairs(byRank) do
            ranks[#ranks + 1] = r
        end
        table.sort(ranks)
        for _, r in ipairs(ranks) do
            if CountKeys(byRank[r]) >= 2 then
                return true, tostring(r)
            end
        end
        return false
    end
end

-- Every title of one kind ("Profession", "Reputation", ...) in the data.
local function KindCounts(spotted, kind)
    local n, have = 0, 0
    for titleID, meta in pairs(BuildStaticMetaByID()) do
        if meta.kind == kind then
            n = n + 1
            if spotted[titleID] then
                have = have + 1
            end
        end
    end
    return have, n
end

local function CheckAllOfKind(kind)
    return function(spotted)
        local have, n = KindCounts(spotted, kind)
        return n > 0 and have >= n
    end
end

local function ProgressAllOfKind(kind)
    return function(spotted)
        local have, n = KindCounts(spotted, kind)
        if n < 1 then
            return nil
        end
        return math.min(have, n), n
    end
end

-- Every listed title, by its data key ("of the gelkis").
local function CheckSpottedKeys(keys)
    return function(spotted)
        local titles = ns.EpithetData and ns.EpithetData.titles
        if not titles or #keys == 0 then
            return false
        end
        for _, key in ipairs(keys) do
            local data = titles[key]
            local titleID = data and tonumber(data.titleID)
            if not titleID or not spotted[titleID] then
                return false
            end
        end
        return true
    end
end

-- Race and class pairs, by the client's file tokens ({ "Orc", "MAGE" }).
-- Undead is "Scourge". Each spotted title carries the first wearer's tags.
local function CountRaceClassPairs(spotted, list)
    local seen = {}
    for _, entry in pairs(spotted) do
        local race, class = entry and entry.raceTag, entry and entry.classTag
        if type(race) == "string" and type(class) == "string" then
            seen[race:lower() .. "|" .. class:lower()] = true
        end
    end
    local have = 0
    for _, pair in ipairs(list) do
        if seen[pair[1]:lower() .. "|" .. pair[2]:lower()] then
            have = have + 1
        end
    end
    return have
end

local function CheckRaceClassPairs(list)
    return function(spotted)
        return CountRaceClassPairs(spotted, list) >= #list
    end
end

local function ProgressRaceClassPairs(list)
    return function(spotted)
        return math.min(CountRaceClassPairs(spotted, list), #list), #list
    end
end

-- `n` titles first spotted on one race in a single day.
local function CheckRaceInOneDay(race, n)
    local wanted = race:lower()
    return function(spotted)
        local byDay = {}
        for _, entry in pairs(spotted) do
            local tag = entry and entry.raceTag
            local firstSeen = entry and tonumber(entry.firstSeen)
            if type(tag) == "string" and tag:lower() == wanted and firstSeen then
                local day = date("%Y-%m-%d", firstSeen)
                byDay[day] = (byDay[day] or 0) + 1
                if byDay[day] >= n then
                    return true
                end
            end
        end
        return false
    end
end

-- A title first spotted between two dates ("YYYY-MM-DD", inclusive, local time).
local function CheckFirstSeenBetween(fromDay, toDay)
    return function(spotted)
        for titleID, entry in pairs(spotted) do
            local firstSeen = entry and tonumber(entry.firstSeen)
            if firstSeen then
                local day = date("%Y-%m-%d", firstSeen)
                if day >= fromDay and day <= toDay then
                    return true, ResolveSpottedTitleDetail(titleID, entry)
                end
            end
        end
        return false
    end
end

-- A WoW Forever player name is "First Last". Retail names are one word
-- (with "-Realm" for other realms), so they never have a surname.
local function Surname(fullName)
    if type(fullName) ~= "string" then
        return nil
    end
    local first, last = fullName:match("^(%S+)%s+(%S+)$")
    return last, first
end

-- The surname shared by the most different spotted players: surname, count.
local function BestSharedSurname(spotted)
    local names, counts, display = {}, {}, {}
    local function Add(who)
        local last = Surname(who)
        if not last then
            return
        end
        local key = last:lower()
        local seen = names[key]
        if not seen then
            seen = {}
            names[key] = seen
            counts[key] = 0
            display[key] = last
        end
        if not seen[who] then
            seen[who] = true
            counts[key] = counts[key] + 1
        end
    end
    for _, entry in pairs(spotted) do
        if entry then
            Add(entry.firstName)
            Add(entry.lastName)
        end
    end
    local keys = {}
    for key in pairs(counts) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    local best, bestN = nil, 0
    for _, key in ipairs(keys) do
        if counts[key] > bestN then
            best, bestN = display[key], counts[key]
        end
    end
    return best, bestN
end

local function CheckSharedSurname(n)
    return function(spotted)
        local surname, count = BestSharedSurname(spotted)
        if surname and count >= n then
            return true, surname
        end
        return false
    end
end

local function ProgressSharedSurname(n)
    return function(spotted)
        local _, count = BestSharedSurname(spotted)
        return math.min(count, n), n
    end
end

-- One title worn by two different players who share a surname.
local function CheckSameTitleSameFamily(spotted)
    for titleID, entry in pairs(spotted) do
        local a, b = entry and entry.firstName, entry and entry.lastName
        if a and b and a ~= b then
            local lastA, lastB = Surname(a), Surname(b)
            if lastA and lastB and lastA:lower() == lastB:lower() then
                return true, ResolveSpottedTitleDetail(titleID, entry)
            end
        end
    end
    return false
end

-- Moments the Logbook records with a sighting (see Spotting/Log.lua).
local function CheckAnySeenFlag(field)
    return function(spotted)
        for titleID, entry in pairs(spotted) do
            if entry and entry[field] == true then
                return true, ResolveSpottedTitleDetail(titleID, entry)
            end
        end
        return false
    end
end

local function CountSeenFlag(spotted, field)
    local n = 0
    for _, entry in pairs(spotted) do
        if entry and entry[field] == true then
            n = n + 1
        end
    end
    return n
end

local function CheckSeenFlagCount(field, n)
    return function(spotted)
        return CountSeenFlag(spotted, field) >= n
    end
end

local function ProgressSeenFlagCount(field, n)
    return function(spotted)
        return math.min(CountSeenFlag(spotted, field), n), n
    end
end

-- A title seen on a player below `belowLevel`.
local function CheckSeenBelowLevel(belowLevel)
    return function(spotted)
        for titleID, entry in pairs(spotted) do
            local level = entry and tonumber(entry.lowestLevel)
            if level and level > 0 and level < belowLevel then
                return true, ResolveSpottedTitleDetail(titleID, entry)
            end
        end
        return false
    end
end

-- A title first spotted on one of these races. A token matches as a prefix,
-- so { "Skyborne" } also covers a "Skyborne..." token for the other faction.
local function CheckFirstSpotRace(tokens)
    return function(spotted)
        for titleID, entry in pairs(spotted) do
            local tag = entry and entry.raceTag
            if type(tag) == "string" then
                local lower = tag:lower()
                for _, token in ipairs(tokens) do
                    if lower:sub(1, #token) == token:lower() then
                        return true, ResolveSpottedTitleDetail(titleID, entry)
                    end
                end
            end
        end
        return false
    end
end

Achievements.BuildersFromData = {
    CheckAnySeenFlag = CheckAnySeenFlag,
    CheckSeenFlagCount = CheckSeenFlagCount,
    ProgressSeenFlagCount = ProgressSeenFlagCount,
    CheckSeenBelowLevel = CheckSeenBelowLevel,
    CheckFirstSpotRace = CheckFirstSpotRace,
    CheckFullLadder = CheckFullLadder,
    ProgressFullLadder = ProgressFullLadder,
    CheckMirrorRank = CheckMirrorRank,
    CheckAllOfKind = CheckAllOfKind,
    ProgressAllOfKind = ProgressAllOfKind,
    CheckSpottedKeys = CheckSpottedKeys,
    CheckRaceClassPairs = CheckRaceClassPairs,
    ProgressRaceClassPairs = ProgressRaceClassPairs,
    CheckRaceInOneDay = CheckRaceInOneDay,
    CheckFirstSeenBetween = CheckFirstSeenBetween,
    CheckSharedSurname = CheckSharedSurname,
    ProgressSharedSurname = ProgressSharedSurname,
    CheckSameTitleSameFamily = CheckSameTitleSameFamily,
}
end

local function GroupLabel(group)
    if group == "collection" then
        return (L and L["SPOT_ACHV_GROUP_COLLECTION"]) or "Collection"
    elseif group == "crossovers" then
        return (L and L["SPOT_ACHV_GROUP_CROSSOVERS"]) or "Crossovers"
    end
    return (L and L["SPOT_ACHV_GROUP_SPOTTING"]) or "Spotting"
end

-- Generic per-achievement locale gate. Nothing sets `locales` today — the
-- text-based achievements that used to be English-only now match the English
-- catalogue text and so work everywhere — but the hook stays for any future
-- achievement that genuinely cannot be earned in some language.
local function LocaleAllows(def)
    if not def or not def.locales then
        return true
    end

    local locale = GetLocale and GetLocale() or "enUS"
    return def.locales[locale] == true
end

-- Check and progress builders shared by every flavour's achievement set
-- (Flavors/<Flavour>/Achievements.lua). A check returns ok[, detail]; a
-- progress returns current, target[, onCharacter].
Achievements.B = {
    CheckBeyondTheGrave = CheckBeyondTheGrave,
    CheckBothEnds = CheckBothEnds,
    CheckBrownNoser = CheckBrownNoser,
    CheckBusyDay = CheckBusyDay,
    CheckCapitalOffence = CheckCapitalOffence,
    CheckCount = CheckCount,
    CheckCreatureOfHabit = CheckCreatureOfHabit,
    CheckCurriculumVitae = CheckCurriculumVitae,
    CheckDeadManWalking = CheckDeadManWalking,
    CheckDecoratedVeteran = CheckDecoratedVeteran,
    CheckDiplomaticImmunity = CheckDiplomaticImmunity,
    CheckDoubleTake = CheckDoubleTake,
    CheckEarlyBird = CheckEarlyBird,
    CheckFeastYourEyes = CheckFeastYourEyes,
    CheckFullSpectrum = CheckFullSpectrum,
    CheckFullWeek = CheckFullWeek,
    CheckGladiatorGroupie = CheckGladiatorGroupie,
    CheckGnomeSpotter = CheckGnomeSpotter,
    CheckGrandTour = CheckGrandTour,
    CheckGuising = CheckGuising,
    CheckHaventWeMet = CheckHaventWeMet,
    CheckHowItsMade = CheckHowItsMade,
    CheckImpulsePurchase = CheckImpulsePurchase,
    CheckKeyword = CheckKeyword,
    CheckKnowThyEnemy = CheckKnowThyEnemy,
    CheckLegendarySpot = CheckLegendarySpot,
    CheckLongCon = CheckLongCon,
    CheckMatchingSet = CheckMatchingSet,
    CheckMuseumCurator = CheckMuseumCurator,
    CheckNightShift = CheckNightShift,
    CheckNothingNew = CheckNothingNew,
    CheckOldMoney = CheckOldMoney,
    CheckOldSchool = CheckOldSchool,
    CheckOverachiever = CheckOverachiever,
    CheckOwnedBothEnds = CheckOwnedBothEnds,
    CheckOwnedCount = CheckOwnedCount,
    CheckOwnedLegendary = CheckOwnedLegendary,
    CheckOwnedRemoved = CheckOwnedRemoved,
    CheckOwnedSpectrum = CheckOwnedSpectrum,
    CheckParticipationAward = CheckParticipationAward,
    CheckPeopleWatcher = CheckPeopleWatcher,
    CheckPopular = CheckPopular,
    CheckPottedHistory = CheckPottedHistory,
    CheckProfessionalLurker = CheckProfessionalLurker,
    CheckQuiteAMouthful = CheckQuiteAMouthful,
    CheckRaidSpectator = CheckRaidSpectator,
    CheckRestrainingOrder = CheckRestrainingOrder,
    CheckRollCallOf = CheckRollCallOf,
    CheckSecretKeeper = CheckSecretKeeper,
    CheckSeeingStars = CheckSeeingStars,
    CheckSmallWorld = CheckSmallWorld,
    CheckSneakyBeaky = CheckSneakyBeaky,
    CheckSpottedTitleID = CheckSpottedTitleID,
    CheckTakesOne = CheckTakesOne,
    CheckTerse = CheckTerse,
    CheckTitleFwends = CheckTitleFwends,
    CheckTwinsies = CheckTwinsies,
    CheckWeekendWarrior = CheckWeekendWarrior,
    CheckWelcomeBack = CheckWelcomeBack,
    CheckWindowShopper = CheckWindowShopper,
    CheckYearInField = CheckYearInField,
}

for name, fn in pairs(ProgressFns) do
    Achievements.B[name] = fn
end
for name, fn in pairs(Achievements.BuildersFromData) do
    Achievements.B[name] = fn
end
Achievements.BuildersFromData = nil

-- ---------------------------------------------------------------------------
-- Achievability audit
-- Each check notes what it needs from the title data, so Achievements:Audit()
-- can say which achievements this client's data makes impossible, or free.
-- Checks that depend on play rather than data (times, people, zones, races)
-- note nothing and are never flagged.
-- ---------------------------------------------------------------------------
local needsByCheck = setmetatable({}, { __mode = "k" })
do
    local B = Achievements.B
    -- Builders that take a parameter: note the need on each check they make.
    local function Note(name, need)
        local make = B[name]
        B[name] = function(...)
            local check = make(...)
            needsByCheck[check] = need(...)
            return check
        end
    end
    Note("CheckCount", function(n) return { spot = n } end)
    Note("CheckOwnedCount", function(n) return { own = n } end)
    Note("CheckKeyword", function(id) return { keyword = KEYWORD_ACHIEVEMENTS[id], count = TITLE_KEYWORD_THRESHOLD } end)
    Note("CheckSpottedTitleID", function(titleID) return { titleID = titleID } end)
    Note("CheckSpottedKeys", function(keys) return { keys = keys } end)
    Note("CheckAllOfKind", function(kind) return { kind = kind } end)
    Note("CheckMirrorRank", function(rank) return { mirror = rank or "any" } end)
    Note("CheckRollCallOf", function(n) return { classes = n } end)

    -- Fixed checks.
    local fixed = {
        CheckFullSpectrum = { tiers = 5 },
        CheckOwnedSpectrum = { tiers = 5 },
        CheckMatchingSet = { tiers = 5 },
        CheckSeeingStars = { tier = 5, count = SEEING_STARS_THRESHOLD },
        CheckLegendarySpot = { tier = 5, count = 1 },
        CheckOwnedLegendary = { tier = 5, count = 1 },
        CheckParticipationAward = { tier = 1, count = 1 },
        CheckOldMoney = { removed = 1 },
        CheckOwnedRemoved = { removed = 1 },
        CheckMuseumCurator = { removed = MUSEUM_CURATOR_THRESHOLD },
        CheckPottedHistory = { allExpansions = true },
        CheckCurriculumVitae = { allExpansions = true },
        CheckOldSchool = { someClassic = true },
        CheckGladiatorGroupie = { source = "pvp", count = SOURCE_KIND_THRESHOLD },
        CheckRaidSpectator = { source = "raid", count = SOURCE_KIND_THRESHOLD },
        CheckBrownNoser = { source = "reputation", count = SOURCE_KIND_THRESHOLD },
        CheckDecoratedVeteran = { source = "pvp", count = DECORATED_VETERAN_THRESHOLD },
        CheckHowItsMade = { linkedSources = true },
        CheckQuiteAMouthful = { textAtLeast = 25 },
        CheckTerse = { textAtMost = 5 },
        CheckBothEnds = { bothEnds = true },
        CheckOwnedBothEnds = { bothEnds = true },
        CheckDiplomaticImmunity = { bothFactions = true },
        CheckFullLadder = { ladder = true },
        CheckSecretKeeper = { secrets = true },
    }
    for name, need in pairs(fixed) do
        if B[name] then
            needsByCheck[B[name]] = need
        end
    end
end

-- What the loaded title data offers, measured once per audit.
local function DataFacts()
    local byID = BuildStaticMetaByID()
    local all = {}
    local f = { total = 0, tiers = {}, tierCount = 0, removed = 0, expansions = {}, expansionCount = 0,
                classic = 0, prefix = 0, suffix = 0, alliance = 0, horde = 0, longest = 0, shortest = math.huge,
                achievementLinked = 0, questLinked = 0, itemLinked = 0 }
    for titleID, meta in pairs(byID) do
        all[titleID] = {}
        f.total = f.total + 1
        local q = tonumber(meta.q)
        if q then
            if not f.tiers[q] then f.tierCount = f.tierCount + 1 end
            f.tiers[q] = (f.tiers[q] or 0) + 1
        end
        if IsExplicitRemoved(meta) then f.removed = f.removed + 1 end
        local exp = meta.exp
        if exp and exp ~= "" then
            if not f.expansions[exp] then f.expansionCount = f.expansionCount + 1 end
            f.expansions[exp] = true
            if tostring(exp):lower() == "classic" then f.classic = f.classic + 1 end
        end
        if meta.type == "prefix" then f.prefix = f.prefix + 1 elseif meta.type == "suffix" then f.suffix = f.suffix + 1 end
        local faction = tostring(meta.faction or ""):lower()
        if faction == "alliance" then f.alliance = f.alliance + 1 elseif faction == "horde" then f.horde = f.horde + 1 end
        local text = CatalogueText(titleID, meta)
        if text then
            f.longest = math.max(f.longest, #text)
            f.shortest = math.min(f.shortest, #text)
        end
        if meta.achievement_id then f.achievementLinked = f.achievementLinked + 1 end
    end
    for _, data in pairs(ns.EpithetData and ns.EpithetData.titles or {}) do
        if data.quest_id then f.questLinked = f.questLinked + 1 end
        if data.source_item and tostring(data.source_item) ~= "" then f.itemLinked = f.itemLinked + 1 end
    end
    -- One character can hold every title except the other faction's.
    f.maxOwned = f.total - math.min(f.alliance, f.horde)
    f.all = all
    return f
end

local function JudgeNeed(need, f)
    if need.spot and need.spot > f.total then
        return ("needs %d titles spotted; the data has %d"):format(need.spot, f.total)
    elseif need.own and need.own > f.maxOwned then
        return ("needs %d titles owned; one character can hold %d"):format(need.own, f.maxOwned)
    elseif need.tiers and f.tierCount < need.tiers then
        return ("needs %d rarity tiers; the data has %d"):format(need.tiers, f.tierCount)
    elseif need.tier and (f.tiers[need.tier] or 0) < need.count then
        return ("needs %d titles of tier %d; the data has %d"):format(need.count, need.tier, f.tiers[need.tier] or 0)
    elseif need.removed and f.removed < need.removed then
        return ("needs %d removed titles; the data has %d"):format(need.removed, f.removed)
    elseif need.allExpansions and f.expansionCount <= 1 then
        return "free: the data has a single expansion, so the first title completes it"
    elseif need.someClassic and f.classic == f.total then
        return "free: every title is Classic"
    elseif need.source then
        local n = CountDistinctTitlesBySource(f.all, need.source)
        if n < need.count then
            return ("needs %d %s titles; the data has %d"):format(need.count, need.source, n)
        end
    elseif need.keyword then
        local n = CountDistinctTitlesByTextMatch(f.all, need.keyword)
        if n < need.count then
            return ("needs %d titles containing \"%s\"; the data has %d"):format(need.count, need.keyword, n)
        end
    elseif need.titleID and not BuildStaticMetaByID()[need.titleID] then
        return ("needs title %d, which is not in the data"):format(need.titleID)
    elseif need.keys then
        local titles = ns.EpithetData and ns.EpithetData.titles or {}
        for _, key in ipairs(need.keys) do
            if not titles[key] then
                return ("needs the title \"%s\", which is not in the data"):format(key)
            end
        end
    elseif need.kind then
        local _, n = Achievements.B.ProgressAllOfKind(need.kind)(f.all)
        if not n or n < 1 then
            return ("needs %s titles; the data has none"):format(need.kind)
        end
    elseif need.ladder and not Achievements.B.CheckFullLadder(f.all) then
        return "needs PvP rank titles with a readable rank; the data has none"
    elseif need.mirror then
        if not Achievements.B.CheckMirrorRank(need.mirror ~= "any" and need.mirror or nil)(f.all) then
            return "needs the same PvP rank on both factions; the data has no such pair"
        end
    elseif need.linkedSources and (f.achievementLinked < 1 or f.questLinked < 1 or f.itemLinked < 1) then
        return "needs titles from an achievement, a quest and an item; the data lacks one"
    elseif need.textAtLeast and f.longest < need.textAtLeast then
        return ("needs a title of %d+ characters; the longest is %d"):format(need.textAtLeast, f.longest)
    elseif need.textAtMost and f.shortest > need.textAtMost then
        return ("needs a title of %d characters or fewer; the shortest is %d"):format(need.textAtMost, f.shortest)
    elseif need.bothEnds and (f.prefix < 1 or f.suffix < 1) then
        return "needs both prefix and suffix titles"
    elseif need.bothFactions and (f.alliance < 1 or f.horde < 1) then
        return "needs titles of both factions"
    elseif need.classes and GetClassInfo then
        local playable = 0
        for classID = 1, 30 do
            local ok, name = pcall(GetClassInfo, classID)
            if ok and name then playable = playable + 1 end
        end
        if playable > 0 and playable ~= need.classes then
            return ("expects %d classes; this client has %d"):format(need.classes, playable)
        end
    end
    return nil
end

-- Achievements this client's data makes impossible (or free), as a list of
-- { id = ..., problem = "..." }. Secret Keeper is flagged when a secret it
-- needs is. Run it after a title data update (the admin command
-- "/epithet admin achvaudit" prints it).
function Achievements:Audit()
    local f = DataFacts()
    local problems, badSecret = {}, false
    for _, def in ipairs(Registry) do
        local need = needsByCheck[def.check]
        local problem = need and not need.secrets and JudgeNeed(need, f) or nil
        if problem then
            problems[#problems + 1] = { id = def.id, problem = problem }
            if def.secret and not def.timeLimited and not problem:find("^free") then
                badSecret = def.id
            end
        end
    end
    for _, def in ipairs(Registry) do
        local need = needsByCheck[def.check]
        if need and need.secrets and badSecret then
            problems[#problems + 1] = { id = def.id, problem = "needs every secret, and " .. badSecret .. " cannot be earned" }
        end
    end
    return problems, f
end

-- Installs the flavour's achievement set. Called once, at load, by the set
-- file. `set` = { id = "retail-1", expected = <count>, list = { def, ... },
-- hidden = { "id", ... } }. A def is { id, check, progress?, group, scope?,
-- secret?, timeLimited?, icon? }. `hidden` names achievements this flavour
-- dropped: anything already earned under them stays saved but is not shown
-- and does not count toward Overachiever.
function Achievements.DefineSet(set)
    if ActiveSet then
        error("Epithet: an achievement set is already defined (" .. tostring(ActiveSet.id) .. ")", 2)
    end
    local list = set and set.list or {}
    for i, def in ipairs(list) do
        if type(def.id) ~= "string" or type(def.check) ~= "function" then
            error("Epithet: achievement set entry " .. i .. " needs an id and a check", 2)
        end
        if RegistryByID[def.id] then
            error("Epithet: duplicate achievement id " .. def.id, 2)
        end
        Registry[#Registry + 1] = def
        RegistryByID[def.id] = def
    end
    local hiddenByID = {}
    for _, id in ipairs(set.hidden or {}) do
        if RegistryByID[id] then
            error("Epithet: achievement " .. id .. " is both listed and hidden", 2)
        end
        hiddenByID[id] = true
    end
    ActiveSet = { id = set.id, expected = set.expected or #Registry, hiddenByID = hiddenByID }
end

function Achievements:GetSetID()
    return ActiveSet and ActiveSet.id or nil
end


local function LocaleName(id)
    return (L and L["SPOT_ACHV_NAME_" .. string.upper(id)]) or id
end

local function LocaleDescription(id)
    return (L and L["SPOT_ACHV_DESC_" .. string.upper(id)]) or ""
end

local function DetailText(id, detail)
    if not detail or detail == "" then
        return nil
    end

    if id == "title_fwends" then
        return (L and L["SPOT_ACHV_DETAIL_WITH_FMT"] and string.format(L["SPOT_ACHV_DETAIL_WITH_FMT"], detail)) or ("earned with " .. detail)
    elseif id == "roll_call" then
        return (L and L["SPOT_ACHV_DETAIL_CLASSES_FMT"] and string.format(L["SPOT_ACHV_DETAIL_CLASSES_FMT"], detail)) or ("earned across " .. detail .. " classes")
    elseif id == "capital_offence" then
        return (L and L["SPOT_ACHV_DETAIL_ZONE_FMT"] and string.format(L["SPOT_ACHV_DETAIL_ZONE_FMT"], detail)) or ("earned in " .. detail)
    elseif id == "keeping_up_with_the_joneses" then
        return (L and L["SPOT_ACHV_DETAIL_FAMILY_FMT"] and string.format(L["SPOT_ACHV_DETAIL_FAMILY_FMT"], detail)) or ("the " .. detail .. " family")
    elseif id == "mirror_image" then
        return (L and L["SPOT_ACHV_DETAIL_RANK_FMT"] and string.format(L["SPOT_ACHV_DETAIL_RANK_FMT"], detail)) or ("rank " .. detail)
    elseif id == "old_money" or id == "takes_one" or id == "window_shopper" or id == "small_world" or id == "impulse_purchase" or id == "twinsies"
        or id == "quite_a_mouthful" or id == "terse" or id == "double_take" or id == "restraining_order"
        or id == "beyond_the_grave" or id == "know_thy_enemy"
        or id == "family_business" or id == "first_wave"
        or id == "position_in_queue" or id == "forever_young" or id == "head_in_the_clouds" then
        return (L and L["SPOT_ACHV_DETAIL_TITLE_FMT"] and string.format(L["SPOT_ACHV_DETAIL_TITLE_FMT"], detail)) or ("triggered by " .. detail)
    elseif id == "potted_history" then
        return (L and L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"] and string.format(L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"], detail)) or ("earned across " .. detail .. " expansions")
    elseif id == "secret_keeper" then
        return (L and L["SPOT_ACHV_DETAIL_SECRETS_FMT"] and string.format(L["SPOT_ACHV_DETAIL_SECRETS_FMT"], detail)) or ("earned across " .. detail .. " secrets")
    end

    return tostring(detail)
end

local function NotificationEnabled()
    local social = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social
    if not social then
        return true
    end
    return social.achievementNotify ~= false
end

local function AlertAnchorMode()
    local social = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social
    local mode = social and social.achievementAlertAnchor or "alertframe"
    if mode ~= "uiparent" and mode ~= "alertframe" then
        mode = "alertframe"
    end
    return mode
end

EarnedStoreFor = function(def, create)
    local db = EnsureRootDB()
    if def.scope == "character" then
        local key = CurrentCharKey()
        if not key then
            return nil
        end
        if create and type(db.achievementsByChar[key]) ~= "table" then
            db.achievementsByChar[key] = {}
        end
        return db.achievementsByChar[key]
    end

    return db.achievements
end

function Achievements:IsRevealed(id)
    local def = RegistryByID[id]
    if not def or not def.secret then
        return true
    end

    local db = EnsureRootDB()
    if db.achievementReveal and db.achievementReveal[id] then
        return true
    end

    if db.achievements and db.achievements[id] then
        return true
    end

    for _, charStore in pairs(db.achievementsByChar or {}) do
        if charStore and charStore[id] then
            return true
        end
    end

    return false
end

function Achievements:MarkRevealed(id)
    local db = EnsureRootDB()
    db.achievementReveal[id] = true
end

function Achievements:ScanOwnedForCurrentChar(reason)
    local owned = OwnedForCurrentChar()
    if not owned then
        return 0
    end

    local db = EnsureRootDB()
    local charKey = CurrentCharKey()
    if not charKey then
        return 0
    end

    if ns.TitleData and ns.TitleData.Scan then
        ns.TitleData:Scan()
    end

    local scanReason = reason or "login"
    local hasBaseline = db.ownedSeenBaseline[charKey] == true
    local reliableByScan = (scanReason == "titles_update" and hasBaseline)

    local now = time()
    local changed = 0
    local records = ns.TitleData and ns.TitleData.records

    if type(records) == "table" and #records > 0 then
        for _, record in ipairs(records) do
            local titleID = record and tonumber(record.titleID)
            if titleID and IsTitleKnown and IsTitleKnown(titleID) then
                local raw = owned[titleID]
                if raw then
                    local ts, reliable = GetOwnedTimestamp(raw)
                    if ts and not reliable then
                        local resolvedTs, resolvedReliable, source = ResolveReliableOwnedTimestamp(titleID)
                        if resolvedTs and resolvedReliable then
                            SetOwnedTimestamp(owned, titleID, resolvedTs, true, source)
                            changed = changed + 1
                        end
                    end
                else
                    local resolvedTs, resolvedReliable, source = ResolveReliableOwnedTimestamp(titleID)
                    if not resolvedTs then
                        resolvedTs = now
                        resolvedReliable = reliableByScan
                        source = reliableByScan and "scan_update" or "scan_baseline"
                    end
                    SetOwnedTimestamp(owned, titleID, resolvedTs, resolvedReliable, source)
                    changed = changed + 1
                end
            end
        end
    else
        local maxID = GetNumTitles and GetNumTitles() or 0
        for titleID = 1, maxID do
            if IsTitleKnown and IsTitleKnown(titleID) then
                local raw = owned[titleID]
                if raw then
                    local ts, reliable = GetOwnedTimestamp(raw)
                    if ts and not reliable then
                        local resolvedTs, resolvedReliable, source = ResolveReliableOwnedTimestamp(titleID)
                        if resolvedTs and resolvedReliable then
                            SetOwnedTimestamp(owned, titleID, resolvedTs, true, source)
                            changed = changed + 1
                        end
                    end
                else
                    local resolvedTs, resolvedReliable, source = ResolveReliableOwnedTimestamp(titleID)
                    if not resolvedTs then
                        resolvedTs = now
                        resolvedReliable = reliableByScan
                        source = reliableByScan and "scan_update" or "scan_baseline"
                    end
                    SetOwnedTimestamp(owned, titleID, resolvedTs, resolvedReliable, source)
                    changed = changed + 1
                end
            end
        end
    end

    db.ownedSeenBaseline[charKey] = true

    return changed
end

function Achievements:BuildChatLine(def, detail)
    local name = LocaleName(def.id)
    local desc = LocaleDescription(def.id)
    local lead = (L and L["SPOT_ACHV_CHAT_EARNED_FMT"] and string.format(L["SPOT_ACHV_CHAT_EARNED_FMT"], name)) or ("Achievement earned - " .. name .. "!")

    local fragments = { lead }
    if desc and desc ~= "" then
        fragments[#fragments + 1] = desc
    end

    local detailText = DetailText(def.id, detail)
    if detailText and detailText ~= "" then
        fragments[#fragments + 1] = detailText
    end

    return table.concat(fragments, " ")
end

function Achievements:QueueAlert(def, detail, earnedAt)
    if not NotificationEnabled() then
        return
    end

    self.pendingAlerts = self.pendingAlerts or {}
    self.pendingAlerts[#self.pendingAlerts + 1] = {
        id = def.id,
        name = LocaleName(def.id),
        description = LocaleDescription(def.id),
        detail = detail,
        earned = earnedAt,
    }

    self:FlushAlertsIfReady()
end

function Achievements:CanPresentAlerts()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end

    if self.deferPresentationUntil and GetTime and GetTime() < self.deferPresentationUntil then
        return false
    end

    return true
end

local ALERT_WIDTH = 320
local ALERT_ICON_SIZE = 40
local ALERT_MIN_HEIGHT = 72
local ALERT_ENTRANCE_SECONDS = 0.22
local ALERT_EXIT_SECONDS = 0.35
local ALERT_HOLD_SECONDS = 4.5
local ALERT_MIN_REMAINING_SECONDS = 0.5
-- Matches the gap Blizzard puts between stacked alerts
-- (AlertFrameQueueMixin:AdjustAnchors -> SetPoint("BOTTOM", relativeAlert, "TOP", 0, 10)).
local ALERT_STACK_GAP = 10

function Achievements:EnsureAlertFrame()
    if self.alertFrame and self.alertFrame.SetPoint then
        return self.alertFrame
    end

    local owner = self
    local T = ns.Theme
    local col = T.col
    local gold = col.gold
    local goldBright = col.goldBright
    local goldDim = col.goldDim
    local panelBg = col.panel2
    local muted = col.muted

    local frame = CreateFrame("Frame", "EpithetSpottingAchievementAlert", UIParent, "BackdropTemplate")
    frame:SetSize(ALERT_WIDTH, 80)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(200)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(panelBg.r, panelBg.g, panelBg.b, 0.96)
    frame:SetBackdropBorderColor(goldDim.r, goldDim.g, goldDim.b, 0.95)
    frame:SetAlpha(0)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function()
        frame:SetBackdropBorderColor(goldBright.r, goldBright.g, goldBright.b, 1)
        owner:PauseAlertTimer(frame)
    end)
    frame:SetScript("OnLeave", function()
        frame:SetBackdropBorderColor(goldDim.r, goldDim.g, goldDim.b, 0.95)
        owner:ResumeAlertTimer(frame)
    end)
    frame:SetScript("OnMouseUp", function()
        owner:DismissAlert(frame, true)
    end)

    -- Small gold corner ornament, echoing the diamond used on the main window chrome.
    if T and T.Diamond then
        local ornament = T.Diamond(frame, 7, gold)
        ornament:SetPoint("TOPRIGHT", -7, -7)
    end

    local iconRing = frame:CreateTexture(nil, "BORDER")
    iconRing:SetPoint("TOPLEFT", 8, -8)
    iconRing:SetSize(ALERT_ICON_SIZE + 8, ALERT_ICON_SIZE + 8)
    iconRing:SetTexture("Interface\\Common\\WhiteIconFrame")
    iconRing:SetVertexColor(gold.r, gold.g, gold.b, 1)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", iconRing, "CENTER", 0, 0)
    icon:SetSize(ALERT_ICON_SIZE, ALERT_ICON_SIZE)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Additive burst that flashes across the icon on entrance, echoing the
    -- shine Blizzard plays on its own achievement/loot toasts.
    local shine = frame:CreateTexture(nil, "OVERLAY")
    shine:SetPoint("CENTER", icon, "CENTER", 0, 0)
    shine:SetSize(ALERT_ICON_SIZE * 2.4, ALERT_ICON_SIZE * 2.4)
    shine:SetTexture("Interface\\Cooldown\\star4")
    shine:SetBlendMode("ADD")
    shine:SetVertexColor(goldBright.r, goldBright.g, goldBright.b, 1)
    shine:SetAlpha(0)

    local header = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", iconRing, "TOPRIGHT", 10, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -1)
    header:SetJustifyH("LEFT")
    header:SetTextColor(gold.r, gold.g, gold.b)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(goldBright.r, goldBright.g, goldBright.b)

    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetWidth(ALERT_WIDTH - (ALERT_ICON_SIZE + 8) - 30)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    desc:SetTextColor(muted.r, muted.g, muted.b)

    local detail = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -3)
    detail:SetWidth(ALERT_WIDTH - (ALERT_ICON_SIZE + 8) - 30)
    detail:SetJustifyH("LEFT")
    detail:SetWordWrap(true)
    detail:SetTextColor(goldDim.r, goldDim.g, goldDim.b)

    frame.icon = icon
    frame.iconRing = iconRing
    frame.shine = shine
    frame.header = header
    frame.title = title
    frame.desc = desc
    frame.detail = detail

    -- Entrance: fade in with a soft pop, growing down from the top edge.
    local animIn = frame:CreateAnimationGroup()
    local inAlpha = animIn:CreateAnimation("Alpha")
    inAlpha:SetFromAlpha(0)
    inAlpha:SetToAlpha(1)
    inAlpha:SetDuration(ALERT_ENTRANCE_SECONDS)
    inAlpha:SetSmoothing("OUT")
    local inScale = animIn:CreateAnimation("Scale")
    inScale:SetOrigin("CENTER", 0, 0)
    inScale:SetScaleFrom(0.88, 0.88)
    inScale:SetScaleTo(1, 1)
    inScale:SetDuration(ALERT_ENTRANCE_SECONDS)
    inScale:SetSmoothing("OUT")
    animIn:SetScript("OnFinished", function()
        frame:SetAlpha(1)
    end)
    frame.animIn = animIn

    -- Exit: simple fade, so it settles away cleanly regardless of anchor mode.
    local animOut = frame:CreateAnimationGroup()
    local outAlpha = animOut:CreateAnimation("Alpha")
    outAlpha:SetFromAlpha(1)
    outAlpha:SetToAlpha(0)
    outAlpha:SetDuration(ALERT_EXIT_SECONDS)
    outAlpha:SetSmoothing("IN")
    animOut:SetScript("OnFinished", function()
        frame:Hide()
        frame:SetAlpha(0)
        owner.alertBusy = false
        owner:FlushAlertsIfReady()
    end)
    frame.animOut = animOut

    local shineGroup = shine:CreateAnimationGroup()
    local shineIn = shineGroup:CreateAnimation("Alpha")
    shineIn:SetFromAlpha(0)
    shineIn:SetToAlpha(0.85)
    shineIn:SetDuration(0.12)
    shineIn:SetOrder(1)
    local shineScale = shineGroup:CreateAnimation("Scale")
    shineScale:SetOrigin("CENTER", 0, 0)
    shineScale:SetScaleFrom(0.5, 0.5)
    shineScale:SetScaleTo(1.15, 1.15)
    shineScale:SetDuration(0.5)
    shineScale:SetOrder(1)
    local shineOut = shineGroup:CreateAnimation("Alpha")
    shineOut:SetFromAlpha(0.85)
    shineOut:SetToAlpha(0)
    shineOut:SetDuration(0.4)
    shineOut:SetOrder(2)
    frame.shineGroup = shineGroup

    -- Blizzard re-anchors its whole stack through AlertContainerMixin:UpdateAnchors,
    -- which runs both when an alert is added (AddAlertFrame) and when a pooled one
    -- is released (OnPooledAlertFrameQueueReset). Re-applying our anchor on the same
    -- beat keeps us above the stack as it grows and collapses, and means we never
    -- keep a point on an alert frame that has since been recycled and cleared.
    if not self.alertAnchorHooked and AlertFrame and AlertFrame.UpdateAnchors and hooksecurefunc then
        self.alertAnchorHooked = true
        hooksecurefunc(AlertFrame, "UpdateAnchors", function()
            local alert = owner.alertFrame
            if alert and alert.IsShown and alert:IsShown() then
                owner:ApplyAlertAnchor(alert)
            end
        end)
    end

    self.alertFrame = frame
    return frame
end

-- Cancels the pending auto-dismiss timer and plays the fade-out; used both by
-- the natural timeout and by clicking the alert to dismiss it early.
function Achievements:BeginAlertExit(frame)
    frame = frame or self.alertFrame
    if not frame or not frame:IsShown() then
        return
    end

    if frame.holdTimer and frame.holdTimer.Cancel then
        frame.holdTimer:Cancel()
    end
    frame.holdTimer = nil

    if frame.animIn and frame.animIn.IsPlaying and frame.animIn:IsPlaying() then
        frame.animIn:Stop()
    end
    frame:SetAlpha(1)

    if frame.animOut then
        if frame.animOut.IsPlaying and frame.animOut:IsPlaying() then
            frame.animOut:Stop()
        end
        frame.animOut:Play()
    else
        frame:Hide()
        self.alertBusy = false
        self:FlushAlertsIfReady()
    end
end

function Achievements:StartAlertHoldTimer(frame, duration)
    frame.holdDuration = duration
    frame.holdStartedAt = GetTime and GetTime() or 0
    if frame.holdTimer and frame.holdTimer.Cancel then
        frame.holdTimer:Cancel()
    end
    frame.holdTimer = nil

    local owner = self
    if C_Timer and C_Timer.NewTimer then
        frame.holdTimer = C_Timer.NewTimer(duration, function()
            frame.holdTimer = nil
            owner:BeginAlertExit(frame)
        end)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(duration, function()
            owner:BeginAlertExit(frame)
        end)
    end
end

-- Hovering pauses the auto-dismiss countdown, same as Blizzard's own alert
-- toasts, so reading a longer description doesn't get cut off mid-read.
function Achievements:PauseAlertTimer(frame)
    frame = frame or self.alertFrame
    if not frame or not frame.holdTimer then
        return
    end

    local elapsed = (GetTime and GetTime() or 0) - (frame.holdStartedAt or 0)
    frame.holdRemaining = math.max((frame.holdDuration or ALERT_HOLD_SECONDS) - elapsed, ALERT_MIN_REMAINING_SECONDS)

    if frame.holdTimer.Cancel then
        frame.holdTimer:Cancel()
    end
    frame.holdTimer = nil
end

function Achievements:ResumeAlertTimer(frame)
    frame = frame or self.alertFrame
    if not frame or not frame:IsShown() or frame.holdTimer then
        return
    end

    self:StartAlertHoldTimer(frame, frame.holdRemaining or ALERT_HOLD_SECONDS)
end

-- Clicking the alert dismisses it immediately and, like Blizzard's own
-- achievement toast, jumps straight to the achievement in the Logbook.
function Achievements:DismissAlert(frame, openLogbook)
    frame = frame or self.alertFrame
    if not frame then
        return
    end

    if openLogbook then
        if ns.MainFrame and ns.MainFrame.Show then
            ns.MainFrame:Show()
        end
        if ns.LogbookUI and ns.LogbookUI.ShowAchievements then
            ns.LogbookUI:ShowAchievements()
        end
    end

    self:BeginAlertExit(frame)
end

-- Highest currently-visible frame in Blizzard's alert stack, or nil when nothing
-- is showing. AlertFrame.alertFrameSubSystems holds two shapes: queue systems
-- own a frame pool of alerts (AlertFrameQueueMixin), while externally- and
-- auto-anchored systems contribute a single anchorFrame. Both can be on screen,
-- so both are measured and the tallest wins.
local function TopmostBlizzardAlert()
    if not AlertFrame or type(AlertFrame.alertFrameSubSystems) ~= "table" then
        return nil
    end

    local best, bestTop = nil, nil

    local function Consider(candidate)
        if not candidate or not candidate.IsShown or not candidate:IsShown() then
            return
        end
        local top = candidate.GetTop and candidate:GetTop()
        if top and (not bestTop or top > bestTop) then
            best, bestTop = candidate, top
        end
    end

    for _, subSystem in ipairs(AlertFrame.alertFrameSubSystems) do
        local pool = subSystem and subSystem.alertFramePool
        if pool and pool.EnumerateActive then
            for alert in pool:EnumerateActive() do
                Consider(alert)
            end
        end

        Consider(subSystem and subSystem.anchorFrame)
    end

    return best
end

function Achievements:ApplyAlertAnchor(frame)
    frame = frame or self.alertFrame
    if not frame or not frame.ClearAllPoints then
        return
    end

    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end

    frame:ClearAllPoints()

    if AlertAnchorMode() == "alertframe" and AlertFrame then
        -- Blizzard's stack only ever grows upward from the AlertFrame stub (a
        -- 10x10 anchor point at BOTTOM of UIParent, y=128 — just above the
        -- action bars). Its first alert sits BOTTOM-on-BOTTOM of that stub and
        -- each subsequent one anchors BOTTOM to the previous alert's TOP, which
        -- is exactly what the two branches below reproduce.
        --
        -- Chaining off the topmost VISIBLE alert rather than the stub is the
        -- point: the stub's own top is y=138, which lands inside a live
        -- achievement toast (300x101, spanning y=128..229) instead of clear of it.
        local relative = TopmostBlizzardAlert()
        if relative then
            frame:SetPoint("BOTTOM", relative, "TOP", 0, ALERT_STACK_GAP)
        else
            frame:SetPoint("BOTTOM", AlertFrame, "BOTTOM", 0, 0)
        end

        -- Keep this frame above common HUD/action-bar layers.
        frame:SetFrameStrata("DIALOG")
        if frame.SetFrameLevel and AlertFrame.GetFrameLevel then
            frame:SetFrameLevel(math.max((AlertFrame:GetFrameLevel() or 0) + 8, 300))
        elseif frame.SetFrameLevel then
            frame:SetFrameLevel(300)
        end
        return
    end

    frame:SetPoint("TOP", UIParent, "TOP", 0, -180)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(300)
end

function Achievements:ShowAlert(payload)
    local frame = self:EnsureAlertFrame()
    self:ApplyAlertAnchor(frame)

    frame.payload = payload

    local iconPath = (ns.SpottingAchievementIcon and ns.SpottingAchievementIcon(payload.id))
        or "Interface\\Icons\\INV_Misc_Spyglass_03"
    frame.icon:SetTexture(iconPath)

    frame.header:SetText((L and L["SPOT_ACHV_ALERT_HEADER"]) or "Epithet Achievement")
    frame.title:SetText(payload.name or "")

    local descText = payload.description or ""
    if descText ~= "" then
        frame.desc:SetText(descText)
        frame.desc:Show()
    else
        frame.desc:SetText("")
        frame.desc:Hide()
    end

    local detailText = DetailText(payload.id, payload.detail)
    if detailText and detailText ~= "" then
        frame.detail:SetText(detailText)
        frame.detail:Show()
    else
        frame.detail:SetText("")
        frame.detail:Hide()
    end

    -- Resize to fit whichever combination of description/detail this alert has,
    -- rather than always paying for the tallest possible layout.
    local contentHeight = 8 + (frame.header:GetStringHeight() or 12) + 3 + (frame.title:GetStringHeight() or 14)
    if frame.desc:IsShown() then
        contentHeight = contentHeight + 4 + (frame.desc:GetStringHeight() or 12)
    end
    if frame.detail:IsShown() then
        contentHeight = contentHeight + 3 + (frame.detail:GetStringHeight() or 11)
    end
    contentHeight = contentHeight + 10

    frame:SetWidth(ALERT_WIDTH)
    frame:SetHeight(math.max(contentHeight, ALERT_MIN_HEIGHT))

    if frame.animOut and frame.animOut.IsPlaying and frame.animOut:IsPlaying() then
        frame.animOut:Stop()
    end
    if frame.animIn and frame.animIn.IsPlaying and frame.animIn:IsPlaying() then
        frame.animIn:Stop()
    end

    frame:SetAlpha(0)
    frame:Show()
    frame.animIn:Play()

    if frame.shineGroup then
        if frame.shineGroup.IsPlaying and frame.shineGroup:IsPlaying() then
            frame.shineGroup:Stop()
        end
        frame.shine:SetAlpha(0)
        frame.shineGroup:Play()
    end

    self:StartAlertHoldTimer(frame, ALERT_HOLD_SECONDS)

    if PlaySound then
        local kit = SOUNDKIT and SOUNDKIT.UI_ACHIEVEMENT_EARNED
        if kit then
            pcall(PlaySound, kit)
        else
            pcall(PlaySound, 12889)
        end
    end

    if ns.Print then
        local def = RegistryByID[payload.id] or { id = payload.id }
        ns.Print(self:BuildChatLine(def, payload.detail))
    end

    self.alertBusy = true
end

function Achievements:FlushAlertsIfReady()
    if not NotificationEnabled() then
        self.pendingAlerts = {}
        self.alertBusy = false
        return
    end

    if self.alertBusy then
        return
    end

    if not self:CanPresentAlerts() then
        return
    end

    local queue = self.pendingAlerts or {}
    if #queue == 0 then
        return
    end

    local payload = table.remove(queue, 1)
    self.pendingAlerts = queue
    self:ShowAlert(payload)
end

function Achievements:TriggerAdminTestAlert()
    local expected = ActiveSet and ActiveSet.expected or 0
    if #Registry ~= expected or expected == 0 then
        return false, string.format(
            "Achievement registry mismatch (%d/%d). Admin test cancelled.",
            #Registry,
            expected
        )
    end

    if InCombatLockdown and InCombatLockdown() then
        return false, "Cannot show admin achievement popup while in combat."
    end

    local def = RegistryByID.overachiever or Registry[1]
    if not def then
        return false, "No achievement definition available for admin popup test."
    end

    local payload = {
        id = def.id,
        name = LocaleName(def.id),
        description = LocaleDescription(def.id),
        detail = nil,
        earned = time(),
    }

    self:ShowAlert(payload)
    return true, "Triggered admin achievement popup test."
end

function Achievements:Evaluate()
    local db = EnsureRootDB()
    local spotted = db.spotted or {}
    local earnedAny = false

    InvalidateSpottedCountCache()

    for _, def in ipairs(Registry) do
        local earnedStore = EarnedStoreFor(def, true)
        if earnedStore and not earnedStore[def.id] and LocaleAllows(def) then
            local ok, detail = def.check(spotted)
            if ok then
                local ts = time()
                earnedStore[def.id] = {
                    earned = ts,
                    detail = detail,
                }
                if def.secret then
                    self:MarkRevealed(def.id)
                end
                self:QueueAlert(def, detail, ts)
                earnedAny = true
            end
        end
    end

    if earnedAny and ns.LogbookUI and ns.LogbookUI.OnLogUpdated then
        ns.LogbookUI:OnLogUpdated()
    end

    return earnedAny
end

function Achievements:OnSpotRecorded()
    self:Evaluate()
end

function Achievements:GetDef(id)
    return RegistryByID[id]
end

function Achievements:GetSummary()
    local total = 0
    local earned = 0

    for _, def in ipairs(Registry) do
        local store = EarnedStoreFor(def, false)
        local hasEarned = store and store[def.id]
        if LocaleAllows(def) or hasEarned then
            total = total + 1
        end
        if hasEarned then
            earned = earned + 1
        end
    end

    return earned, total
end

function Achievements:GetProgressText(def, spotted)
    if not def.progress then
        return nil
    end

    local current, target, onChar = def.progress(spotted)
    if not current or not target or target <= 0 then
        return nil
    end

    if onChar then
        if L and L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"] then
            return string.format(L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"], current, target)
        end
        return string.format("%d / %d on this character", current, target)
    end

    if L and L["SPOT_ACHV_PROGRESS_FMT"] then
        return string.format(L["SPOT_ACHV_PROGRESS_FMT"], current, target)
    end
    return string.format("%d / %d", current, target)
end

function Achievements:GetDisplayEntries()
    local db = EnsureRootDB()
    local spotted = db.spotted or {}
    local entries = {}

    InvalidateSpottedCountCache()
    self.secretOrder = self.secretOrder or {}

    for _, def in ipairs(Registry) do
        local store = EarnedStoreFor(def, false)
        local earnedRecord = store and store[def.id] or nil
        local earned = earnedRecord ~= nil
        if LocaleAllows(def) or earned then
            local revealed = self:IsRevealed(def.id)
            local masked = def.secret and not revealed and not earned

            if masked and not self.secretOrder[def.id] then
                self.secretOrder[def.id] = random()
            end

            local name = masked and ((L and L["SPOT_ACHV_SECRET_NAME"]) or "???") or LocaleName(def.id)
            local description = masked and ((L and L["SPOT_ACHV_SECRET_DESC"]) or "Secret achievement") or LocaleDescription(def.id)
            local detail = earnedRecord and earnedRecord.detail or nil

            entries[#entries + 1] = {
                entryType = "achievement",
                id = def.id,
                secret = def.secret == true,
                secretEarned = (def.secret == true and earned),
                revealed = revealed,
                masked = masked,
                group = def.group or "spotting",
                groupLabel = masked and nil or GroupLabel(def.group or "spotting"),
                scope = def.scope or "account",
                name = name,
                description = description,
                earned = earned,
                earnedAt = earnedRecord and earnedRecord.earned or nil,
                earnedText = (earnedRecord and earnedRecord.earned and date("%d %b %Y", earnedRecord.earned)) or nil,
                detail = detail,
                detailText = DetailText(def.id, detail),
                progressText = (not earned and not masked) and self:GetProgressText(def, spotted) or nil,
                fwendsHint = (def.id == "title_fwends" and not masked),
                secretOrder = self.secretOrder[def.id],
            }
        end
    end

    -- Earned achievements bubble to the top (most recently earned first);
    -- unearned ones keep the general-before-secret grouping below them.
    table.sort(entries, function(a, b)
        if a.earned ~= b.earned then
            return a.earned
        end
        if a.earned then
            local aAt = a.earnedAt or 0
            local bAt = b.earnedAt or 0
            if aAt ~= bAt then
                return aAt > bAt
            end
            return a.id < b.id
        end
        if a.secret ~= b.secret then
            return not a.secret
        end
        if a.masked and b.masked then
            return (a.secretOrder or 0) < (b.secretOrder or 0)
        end
        if a.group ~= b.group then
            local order = { spotting = 1, collection = 2, crossovers = 3 }
            return (order[a.group] or 9) < (order[b.group] or 9)
        end
        return a.id < b.id
    end)

    return entries
end

function Achievements:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    EnsureRootDB()
    self.pendingAlerts = {}
    self.alertBusy = false
    self.deferPresentationUntil = nil

    if not ActiveSet then
        if ns.Print then ns.Print((L and L["SPOT_ACHV_NO_SET"]) or "No achievement set is loaded for this version of the game.") end
    elseif #Registry ~= ActiveSet.expected and ns.Print then
        ns.Print(string.format(
            "Achievement registry count mismatch: %d (expected %d).",
            #Registry,
            ActiveSet.expected
        ))
    end
    if ActiveSet then
        EnsureRootDB().achievementSet = ActiveSet.id
    end

    self.frame = CreateFrame("Frame")

    local function TryRegisterEvent(frame, eventName)
        if not frame or not eventName then
            return false
        end
        local ok = pcall(frame.RegisterEvent, frame, eventName)
        return ok and true or false
    end

    self.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            self:ScanOwnedForCurrentChar("login")
            self:Evaluate()
            if C_Timer and C_Timer.After and GetTime then
                self.deferPresentationUntil = GetTime() + 2.0
                C_Timer.After(2.1, function()
                    self.deferPresentationUntil = nil
                    self:FlushAlertsIfReady()
                end)
            else
                self.deferPresentationUntil = nil
                self:FlushAlertsIfReady()
            end
        elseif event == "KNOWN_TITLES_UPDATE" then
            self:ScanOwnedForCurrentChar("titles_update")
            self:Evaluate()
            self:FlushAlertsIfReady()
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:FlushAlertsIfReady()
        end
    end)

    TryRegisterEvent(self.frame, "PLAYER_ENTERING_WORLD")
    TryRegisterEvent(self.frame, "KNOWN_TITLES_UPDATE")
    TryRegisterEvent(self.frame, "PLAYER_REGEN_ENABLED")
end
