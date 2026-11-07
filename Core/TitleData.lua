-- =============================================================================
-- Epithet — Title Data Layer
-- Enumerates live titles, merges with bundled DB, provides unified records.
-- =============================================================================
local _, ns = ...

-- Bridge global EpithetData into the addon namespace. It is set by exactly one
-- flavour's base: data/retail/TitlesDB.enGB.lua on Retail and PTR, or
-- data/forever/TitlesDB.enGB.lua on WoW Forever (the TOC gates them by game
-- type). The shape is identical, so nothing below needs to know which loaded.
ns.EpithetData = EpithetData

-- ---------------------------------------------------------------------------
-- titleID index for the bundled DB
-- ---------------------------------------------------------------------------
-- The bundled DB (EpithetData.titles) is keyed by lowercase ENGLISH title text,
-- because that's what the source-of-truth JSON is keyed by upstream. But the
-- live merge below (Scan) reads a title's *name* via GetTitleName(), which
-- Blizzard already returns correctly localised for whatever language the
-- player's game client is running — so on any non-English client, matching by
-- lowercased name text never finds the English key, and every title silently
-- loses its rarity/expansion/category/achievement metadata (not mistranslated
-- — entirely absent), regardless of Epithet's own locale/language override.
--
-- Every bundled entry also carries `titleID`, Blizzard's numeric title ID,
-- which is identical across every client locale (only the display string
-- differs). Indexing by that instead makes the merge locale-independent.
-- Built once at load from the existing text-keyed table (the DB is static, so
-- it never needs rebuilding) — no change needed upstream in TitlesDBCollector.
local function BuildTitlesByID()
    local byID = {}
    if ns.EpithetData and ns.EpithetData.titles then
        for _, entry in pairs(ns.EpithetData.titles) do
            if entry.titleID then
                byID[entry.titleID] = entry
            end
        end
    end
    return byID
end
if ns.EpithetData then
    ns.EpithetData.titlesByID = BuildTitlesByID()
end

-- ---------------------------------------------------------------------------
-- Faction variants of one title text
-- ---------------------------------------------------------------------------
-- The client can give one title text several IDs that differ only by faction:
-- WoW Forever's "Sergeant" is 10 (Alliance) and 23 (Horde). The collector ships
-- each such ID as its own entry, the first under its text and the rest under
-- "<text>#<titleID>", with `text` always holding the real title text. Those
-- entries are what this index is built from, so it only ever reflects what the
-- loaded data declares; a dataset that ships one entry per text yields nothing.
--
-- factionVariants["<lower text>|<type>"] = { Alliance = entry, Horde = entry, [""] = entry }
-- exists only for a text+affix whose entries carry more than one distinct
-- faction ("" stands for neutral). Same-faction duplicates are not split: they
-- are indistinguishable to the player, which is what deduplication is for.
local function VariantGroupKey(text, titleType)
    return strlower(text or "") .. "|" .. (titleType or "")
end

local function BuildFactionVariants()
    local groups = {}
    if ns.EpithetData and ns.EpithetData.titles then
        for _, entry in pairs(ns.EpithetData.titles) do
            if entry.text and entry.titleID then
                local key = VariantGroupKey(entry.text, entry.type)
                local group = groups[key]
                if not group then
                    group = {}
                    groups[key] = group
                end
                group[#group + 1] = entry
            end
        end
    end

    local split = {}
    for key, group in pairs(groups) do
        if #group > 1 then
            local byFaction, factionCount = {}, 0
            for _, entry in ipairs(group) do
                local faction = entry.faction or ""
                local current = byFaction[faction]
                if not current then
                    factionCount = factionCount + 1
                end
                -- Lowest titleID wins within a faction, so the pick never depends
                -- on pairs() order.
                if not current or entry.titleID < current.titleID then
                    byFaction[faction] = entry
                end
            end
            if factionCount > 1 then
                split[key] = byFaction
            end
        end
    end
    return split
end
local factionVariants = BuildFactionVariants()

-- The faction variants `entry` belongs to, or nil when its text+affix has none.
local function GetFactionVariants(entry)
    if not entry or not entry.text then return nil end
    return factionVariants[VariantGroupKey(entry.text, entry.type)]
end

-- Given a DB entry resolved from title text alone (which cannot tell the
-- Alliance and Horde variants apart), return the variant matching `faction`
-- ("Alliance" / "Horde"). Returns `entry` unchanged when it has no faction
-- variants or `faction` is unknown, so it is a no-op on any dataset without them.
function ns.PickFactionVariant(entry, faction)
    local variants = GetFactionVariants(entry)
    if not variants or not faction then return entry end
    return variants[faction] or entry
end

-- UnitFactionGroup for a unit, or nil when unavailable. Under combat taint unit
-- APIs can return secret values, which must never be compared or branched on.
local issecretvalue = _G.issecretvalue
function ns.SafeUnitFaction(unit)
    if not unit or not UnitFactionGroup then return nil end
    local ok, faction = pcall(UnitFactionGroup, unit)
    if not ok or faction == nil then return nil end
    if issecretvalue and issecretvalue(faction) then return nil end
    if type(faction) ~= "string" then return nil end
    return faction
end

-- ---------------------------------------------------------------------------
-- Localised title-database overlays
-- ---------------------------------------------------------------------------
-- The enGB base above ships the full dataset. Localised databases
-- (data/<flavour>/TitlesDB.<code>.lua) are SPARSE overlays keyed by titleID — the stable,
-- locale-independent join key — that carry only translated free-prose fields
-- (obtainability_reason, achievement/quest/source_item). Each registers itself:
--
--     ns.TitlesDBLocales = ns.TitlesDBLocales or {}
--     ns.TitlesDBLocales.ruRU = { version = "...", byID = { [660] = { ... } } }
--
-- The active display language (ns.activeLocale, chosen in LocaleManager) selects
-- which overlay applies; Scan() below prefers an overlay field, falling back to
-- the enGB base. A language switch triggers a ReloadUI, so Scan re-runs fresh and
-- no live-refresh path is needed. Title NAMES are never taken from here — they
-- always come from GetTitleName() so they match the game client / nameplates.
ns.TitlesDBLocales = ns.TitlesDBLocales or {}

-- Returns the byID overlay table for the active locale, or nil when the enGB
-- base already applies (enGB / auto / no overlay shipped for this language).
function ns.ResolveTitlesDBOverlay()
    local code = ns.activeLocale
    if not code or code == "enGB" then return nil end
    local pack = ns.TitlesDBLocales[code]
    return pack and pack.byID or nil
end

-- Localize WoW APIs (called 700+ times in Scan loop)
local GetTitleName   = GetTitleName
local IsTitleKnown   = IsTitleKnown
local GetCurrentTitle = GetCurrentTitle
local GetNumTitles   = GetNumTitles
local UnitName       = UnitName
local UnitPVPName    = UnitPVPName
local GetNormalizedRealmName = GetNormalizedRealmName
local GetAchievementInfo     = GetAchievementInfo

-- Localize Lua stdlib
local pairs, ipairs  = pairs, ipairs
local format         = string.format
local strlower       = strlower

local TitleData = {}
ns.TitleData = TitleData
TitleData.dirty = true  -- ensure first Scan() always runs

-- The player's name as the game shows it, without the title. On WoW Forever a
-- character has a first and a last name and UnitName returns only the first;
-- the displayed name (UnitPVPName) carries both, so the title is read off it
-- with the same rule the nameplates use (TitleIndex:ReadTitle). On Retail the
-- result is exactly UnitName. Returns nil when the displayed name can't be
-- trusted yet (not loaded, or still showing the previous title), so callers
-- keep their last good read.
local function ReadPlayerName(currentTitleID)
    local first = UnitName and UnitName("player")
    if type(first) ~= "string" or first == "" then return nil end
    local shown = UnitPVPName and UnitPVPName("player")
    if issecretvalue and issecretvalue(shown) then return nil end
    if type(shown) ~= "string" or not shown:find(first, 1, true) then return nil end
    if currentTitleID and currentTitleID > 0 then
        local index = ns.TitleIndex
        if not (index and index.ReadTitle) then return nil end
        local affix, text = index:ReadTitle({ shown }, first)
        if not text or text == "" then return nil end
        if affix == "prefix" and shown:sub(1, #text) == text then
            shown = shown:sub(#text + 1)
        elseif affix == "suffix" and shown:sub(-#text) == text then
            shown = shown:sub(1, #shown - #text):gsub("[,%s]+$", "")
        else
            return nil
        end
    end
    shown = shown:gsub("^%s+", ""):gsub("%s+$", "")
    if not shown:find(first, 1, true) then return nil end
    return shown
end

-- ---------------------------------------------------------------------------
-- Rarity / quality colours (pip hex = true item colour; text = on-dark variant)
-- ---------------------------------------------------------------------------
-- The same tables as ns.Theme.quality, so there is one quality palette and a
-- flavour's theme overrides reach both names.
ns.QUALITY_COLOURS = ns.Theme.quality

-- Rarity tier names (indexed 1..5). Resolved through ns.L at ACCESS time so they
-- follow the active locale, with the usual English fallback. Kept as a table (not
-- a plain array) via a metatable so every existing `ns.QUALITY_NAMES[q]` call site
-- keeps working unchanged.
local QUALITY_NAME_KEYS = { "COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY" }
ns.QUALITY_NAMES = setmetatable({}, {
    __index = function(_, q)
        local key = QUALITY_NAME_KEYS[q]
        return key and ns.L[key] or nil
    end,
})

ns.EXPANSION_ORDER = {
    "classic", "tbc", "wrath", "cata", "mop", "wod",
    "legion", "bfa", "sl", "df", "tww", "mid",
}

-- Resolve `key` through ns.L; if it comes back unresolved (ns.L's own fallback
-- echoes the key name itself when no locale defines it), use `raw` instead.
-- This keeps display text forward-compatible with a TitlesDB shipping a brand
-- new expansion/category/kind code before Epithet has a translation for it —
-- rather than literally showing "EXPANSION_FOO" on screen.
local function LocalizedOrRaw(key, raw)
    if not key then return raw end
    local v = ns.L[key]
    if v == key then return raw end
    return v
end
ns.LocalizedOrRaw = LocalizedOrRaw

-- Expansion display names. Resolution order: ns.L["EXPANSION_<CODE>"]
-- (translated, active locale) -> the raw code as a last resort. The DB no longer
-- ships English labels (EpithetData.expansionLabels was removed): Epithet's own
-- locale table is authoritative for display text. A metatable-backed table (not a
-- plain array) so every existing `ns.EXPANSION_LABELS[key]` call site keeps
-- working, but re-resolves through the active locale on every access instead of
-- being snapshotted once at load (which is what lets a runtime language switch
-- take effect).
ns.EXPANSION_LABELS = setmetatable({}, {
    __index = function(_, code)
        if not code or code == "" then return nil end
        return LocalizedOrRaw("EXPANSION_" .. code:upper(), code)
    end,
})

-- Category display names. Category codes ("PvP", "Raid", ...) upper() cleanly
-- into their L key suffix (CAT_PVP, CAT_RAID, ...), so no explicit map is
-- needed; falls back to the raw code for anything not yet recognised.
function ns.CategoryLabel(code)
    if not code or code == "" then return code end
    return LocalizedOrRaw("CAT_" .. code:upper(), code)
end

-- Source-kind display names. Unlike category, kind codes ("Feat of Strength",
-- "PvP Rank") contain spaces and don't upper() into a clean identifier, so this
-- maps them explicitly onto the existing KIND_* locale keys.
local KIND_LABEL_KEYS = {
    Achievement = "KIND_ACHIEVEMENT",
    Quest = "KIND_QUEST",
    Reputation = "KIND_REPUTATION",
    ["Feat of Strength"] = "KIND_FEAT",
    ["PvP Rank"] = "KIND_PVP_RANK",
    Item = "KIND_ITEM",
    Promotion = "KIND_PROMOTION",
    Profession = "KIND_PROFESSION",
}
function ns.KindLabel(code)
    if not code or code == "" then return code end
    return LocalizedOrRaw(KIND_LABEL_KEYS[code], code)
end

-- Build expansion index for sort ordering
ns.EXPANSION_INDEX = {}
for i, key in ipairs(ns.EXPANSION_ORDER) do
    ns.EXPANSION_INDEX[key] = i
end

-- ---------------------------------------------------------------------------
-- Blizzard ships unnamed placeholder titles as the literal text "[PH]" (Retail
-- IDs 660-663 at time of writing) and dev-only ones marked "[DNT]" ("do not
-- translate"; WoW Forever ID 36 is "[DNT] Test"). They are not real titles and
-- are excluded from the bundled database, so exclude them from the scan too —
-- otherwise they show up as metadata-less rows in the list and inflate both the
-- title count and the obtainable-progress denominator. Mirrors the collector's
-- rule, ^\s*(?:\[ph\]\s*$|\[dnt\]) case-insensitive: "[PH]" must be the whole
-- text (anything looser risks swallowing a genuine title), while "[DNT]" only
-- has to lead it.
-- ---------------------------------------------------------------------------
local function IsPlaceholderTitle(text)
    if not text then return false end
    local lower = strlower(text)
    return lower:match("^%s*%[ph%]%s*$") ~= nil
        or lower:match("^%s*%[dnt%]") ~= nil
end

-- ---------------------------------------------------------------------------
-- Classify a raw title string into text + type (prefix/suffix)
-- ---------------------------------------------------------------------------
local function ClassifyTitle(raw)
    if not raw then return nil, nil end

    -- Modern (12.0.x) GetTitleName returns a "%s" name placeholder, e.g.
    --   "Private %s"        -> prefix
    --   "%s the Explorer"   -> suffix
    --   "%s, Lord Admiral"  -> suffix
    -- Detect by where the placeholder sits and strip it + padding/punctuation.
    if raw:find("%%s") then
        local before = raw:match("^(.-)%%s")
        local after  = raw:match("%%s(.*)$")
        before = before or ""
        after  = after or ""
        if before:match("%S") then
            -- text precedes the name -> prefix ("Private %s")
            return "prefix", (before:gsub("%s+$", ""))
        else
            -- name precedes the text -> suffix ("%s the Explorer" / "%s, Jenkins")
            return "suffix", (after:gsub("^[%s,]+", ""))
        end
    end

    -- Legacy/whitespace form fallback.
    if raw:match("^%s") or raw:match("^,") then
        -- Leading space or comma → suffix
        return "suffix", (raw:gsub("^[%s,]+", ""))
    else
        -- Trailing space → prefix
        return "prefix", (raw:gsub("%s+$", ""))
    end
end

-- ---------------------------------------------------------------------------
-- Get earned date from achievement info (if available)
-- ---------------------------------------------------------------------------
local function GetEarnedDate(sourceID)
    if not sourceID or not GetAchievementInfo then return nil end
    local _, _, _, completed, month, day, year = GetAchievementInfo(sourceID)
    if completed and day and month and year and year > 0 then
        -- Format as "dd Month yyyy". Month name comes from the active locale
        -- (genitive case in ruRU) so dates read naturally in every language.
        local monthName = (ns.L and month and ns.L["MONTH_" .. month]) or "?"
        return format("%d %s %d", day, monthName, 2000 + year)
    end
    return nil
end

-- Build a stable dedupe key for live titles that are API-duplicates of the same
-- underlying title (for example the legacy PvP rank aliases, where Grunt is
-- exposed as both 16 and 169).
--
-- ONLY locale-independent, live-derived fields belong here. Both come from this
-- client's own GetTitleName, so the duplicate IDs always agree on them whatever
-- language the client runs in.
--
-- Bundled-DB fields (cat/kind/exp/q/faction/achievement_id/...) must NOT be used,
-- however well they would discriminate. The DB stores one entry per title under
-- the lowest duplicate ID, so an alias ID misses the titleID index and falls back
-- to the English-text-keyed lookup, which resolves on an English client only. On
-- any other locale the alias record carries all-nil metadata, its key stops
-- matching the canonical one, and the duplicate row reappears — the exact failure
-- the comment above that lookup warns about.
--
-- Text plus affix is enough to be safe: where one text spans two IDs of differing
-- affix ("the Forbidden" is 495 suffix / 533 prefix) the type still separates
-- them, and two titles sharing both text and affix are indistinguishable to the
-- player anyway, which is precisely what collapsing them is for.
--
-- The one exception is a title the DB itself ships as separate faction variants
-- (see factionVariants above; WoW Forever's Alliance "Sergeant" 10 and Horde
-- "Sergeant" 23). Those are different titles to the player, so the variant's
-- faction joins the key and each keeps its own row. This does not reopen the
-- failure described above: every variant is its own DB entry, so each of its
-- IDs resolves through the titleID index on any client locale. It relies on the
-- collector shipping every ID of a split title; an ID it left out would resolve
-- by English text only and could land in the wrong row on other locales.
-- `static` is the DB entry this record resolved to (nil when it has none).
local function BuildRecordDedupeKey(record, static)
    local key = strlower(record.text or "") .. "|" .. (record.type or "")
    if GetFactionVariants(static) then
        key = key .. "|" .. (static.faction or "")
    end
    return key
end

-- ---------------------------------------------------------------------------
-- Full scan: enumerate all titles, merge with bundled DB
-- Gated by a dirty flag to avoid redundant work on repeated Show() calls.
-- ---------------------------------------------------------------------------
function TitleData:Scan(force)
    if not force and not self.dirty and self.records then return self.records end

    local records = {}
    local recordsByID = {}
    -- One lowercased title text can map to multiple records (e.g., prefix/suffix variants).
    local recordsByLowerText = {}
    local recordsByDedupeKey = {}
    local earnedCount = 0
    local totalCount = 0
    local earnedObtainableCount = 0
    local totalObtainableCount = 0
    local currentTitleID = GetCurrentTitle and GetCurrentTitle() or 0

    local maxID = GetNumTitles and GetNumTitles() or 0

    -- Active-locale prose overlay (nil on enGB / when no overlay ships). Resolved
    -- once here rather than per-title.
    local overlayByID = ns.ResolveTitlesDBOverlay and ns.ResolveTitlesDBOverlay() or nil

    for titleID = 1, maxID do
        local raw = GetTitleName and GetTitleName(titleID) or nil
        if raw then
            local titleType, text = ClassifyTitle(raw)
            if text and text ~= "" and not IsPlaceholderTitle(text) then
                local earned = IsTitleKnown and IsTitleKnown(titleID) or false
                local isActive = (titleID == currentTitleID)

                -- Lookup in bundled DB. Prefer titleID (locale-independent —
                -- works regardless of the game client's language); fall back
                -- to matching the normalised name text (English-keyed, so only
                -- resolves on an English client) for any DB snapshot that
                -- predates the titleID index.
                local key = strlower(text)
                local staticByID = (ns.EpithetData and ns.EpithetData.titlesByID and ns.EpithetData.titlesByID[titleID]) or nil
                local staticByText = (ns.EpithetData and ns.EpithetData.titles and ns.EpithetData.titles[key]) or nil

                -- Some client builds expose alias/shifted live IDs for certain
                -- titles. When an ID-hit resolves to a different title text than
                -- the live title we just read, prefer the text-key match so type,
                -- source, and obtainability metadata stay attached to the right
                -- title.
                local static = staticByID or staticByText
                local staticFromText = false
                if staticByID and staticByText and staticByID.text and strlower(staticByID.text) ~= key then
                    static = staticByText
                    staticFromText = true
                elseif not staticByID and staticByText then
                    static = staticByText
                    staticFromText = true
                end

                -- Treat TitlesDB as authoritative for affix when a static row is
                -- available. Live classification remains the fallback only when
                -- this title has no catalog metadata.
                local resolvedType = (static and static.type) or titleType

                -- Sparse localised prose for this title (nil for most), each
                -- field falling back to the enGB base when the overlay omits it.
                local overlayID = titleID
                if staticFromText and static and static.titleID then
                    overlayID = static.titleID
                end
                local over = overlayByID and overlayByID[overlayID] or nil

                local record = {
                    titleID   = titleID,
                    text      = text,
                    raw       = raw, -- unclassified GetTitleName() string, reused by TitleIndex to avoid a second API pass
                    -- Prefer catalog type when available so suffix/prefix rendering
                    -- is stable across client formatting differences in raw title
                    -- strings. Live classification remains the fallback for titles
                    -- with no static DB row.
                    type      = resolvedType or (static and static.type),
                    earned    = earned,
                    isActive  = isActive,
                    -- Bundled fields (may be nil)
                    q         = static and static.q or nil,
                    exp       = static and static.exp or nil,
                    cat       = static and static.cat or nil,
                    kind      = static and static.kind or nil,
                    -- Free-prose fields: prefer the active-locale overlay, else
                    -- the enGB base. (Language-neutral fields never overlay.)
                    achievement    = (over and over.achievement) or (static and static.achievement) or nil,
                    achievement_id = static and static.achievement_id or nil,
                    quest          = (over and over.quest) or (static and static.quest) or nil,
                    quest_id       = static and static.quest_id or nil,
                    source_item    = (over and over.source_item) or (static and static.source_item) or nil,
                    rarity    = static and static.rarity or nil,
                    obtainable = static and static.obtainable or nil,
                    obtainability_reason = (over and over.obtainability_reason) or (static and static.obtainability_reason) or nil,
                    faction   = static and static.faction or nil,
                    availability       = static and static.availability or nil,
                    availability_event = static and static.availability_event or nil,
                    last_updated       = static and static.last_updated or nil,
                    date      = nil, -- populated below
                    _titleIDs = { [titleID] = true },
                }

                -- Pre-compute lower-case search key for fast filtering
                record._searchKey = strlower(
                    (text or "") .. " " ..
                    (record.achievement or "") .. " " ..
                    (record.quest or "") .. " " ..
                    (record.source_item or "") .. " " ..
                    (record.cat or "")
                )

                -- Try to get earned date from achievement
                if earned and record.achievement_id then
                    record.date = GetEarnedDate(record.achievement_id)
                end

                local dedupeKey = BuildRecordDedupeKey(record, static)
                local deduped = recordsByDedupeKey[dedupeKey]

                if deduped then
                    -- Keep every live titleID addressable while collapsing the
                    -- duplicate row in the visible list.
                    deduped._titleIDs[titleID] = true
                    if isActive then
                        deduped.isActive = true
                    end
                    if earned then
                        -- Promoting the canonical row from unearned to earned has
                        -- to move the counters with it. They were decided when that
                        -- row was created and are never revisited otherwise, so a
                        -- title the client reports known only under its alias ID
                        -- would display as earned while the header count omitted
                        -- it. Guarded on the flag so a title known under several
                        -- IDs is still only counted once.
                        if not deduped.earned then
                            deduped.earned = true
                            earnedCount = earnedCount + 1

                            local obt = deduped.obtainable
                            if obt ~= "no" and obt ~= "feat" then
                                earnedObtainableCount = earnedObtainableCount + 1
                            end
                        end

                        if deduped.date == nil then
                            deduped.date = record.date
                        end
                    end
                    recordsByID[titleID] = deduped
                else
                    recordsByDedupeKey[dedupeKey] = record
                    totalCount = totalCount + 1

                    if earned then
                        earnedCount = earnedCount + 1
                    end

                    -- Track obtainable-only pool (deduped records only)
                    local obt = record.obtainable
                    if obt ~= "no" and obt ~= "feat" then
                        totalObtainableCount = totalObtainableCount + 1
                        if earned then
                            earnedObtainableCount = earnedObtainableCount + 1
                        end
                    end

                    records[#records + 1] = record
                    recordsByID[titleID] = record

                    local lowerText = strlower(text)
                    local sameText = recordsByLowerText[lowerText]
                    if not sameText then
                        sameText = {}
                        recordsByLowerText[lowerText] = sameText
                    end
                    sameText[#sameText + 1] = record
                end
            end
        end
    end

    self.records = records
    self.recordsByID = recordsByID
    self.recordsByLowerText = recordsByLowerText
    self.earnedCount = earnedCount
    self.totalCount = totalCount
    self.earnedObtainableCount = earnedObtainableCount
    self.totalObtainableCount = totalObtainableCount
    self.currentTitleID = currentTitleID
    self.playerRealm = GetNormalizedRealmName and GetNormalizedRealmName() or "Unknown"
    self.dirty = false
    -- After the records are in place: reading the title off the displayed name
    -- uses TitleIndex, which is built from them.
    self.playerName = ReadPlayerName(currentTitleID) or self.playerName
        or (UnitName and UnitName("player")) or "Player"

    return records
end

-- ---------------------------------------------------------------------------
-- Refresh active title state without full rescan
-- ---------------------------------------------------------------------------
function TitleData:RefreshActiveState()
    local currentTitleID = GetCurrentTitle and GetCurrentTitle() or 0
    self.currentTitleID = currentTitleID
    self.playerName = ReadPlayerName(currentTitleID) or self.playerName
    if self.records then
        for _, record in ipairs(self.records) do
            if record._titleIDs then
                record.isActive = record._titleIDs[currentTitleID] == true
            else
                record.isActive = (record.titleID == currentTitleID)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Get record by titleID (O(1) via index built during Scan)
-- ---------------------------------------------------------------------------
function TitleData:GetRecord(titleID)
    if not self.recordsByID then return nil end
    return self.recordsByID[titleID]
end

-- ---------------------------------------------------------------------------
-- Render title in context: "the Insane Aelynne" or "Aelynne, Lord Admiral"
-- ---------------------------------------------------------------------------
function TitleData:RenderTitleInContext(record, name)
    -- Any non-prefix type intentionally falls back to suffix rendering for safe output.
    name = name or self.playerName or "Player"
    if record.type == "prefix" then
        return record.text .. " " .. name
    else
        return name .. ", " .. record.text
    end
end

-- ---------------------------------------------------------------------------
-- Open the linked achievement (mirrors design/Core/TitleData.lua ns.OpenSource)
-- ---------------------------------------------------------------------------
function TitleData:OpenSource(record)
    if not (record and record.achievement_id) then return end
    if not AchievementFrame then
        if UIParentLoadAddOn then UIParentLoadAddOn("Blizzard_AchievementUI") end
    end
    if OpenAchievementFrameToAchievement then
        OpenAchievementFrameToAchievement(record.achievement_id)
    elseif AchievementFrame_SelectAchievement then
        ShowUIPanel(AchievementFrame)
        AchievementFrame_SelectAchievement(record.achievement_id)
    end
end
