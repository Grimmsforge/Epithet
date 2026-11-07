-- =============================================================================
-- Epithet — Filter & Sort Engine
-- Provides filtering predicates, sort modes, and sidebar count computation.
-- =============================================================================
local _, ns = ...

-- Localize Lua stdlib
local next, pairs, ipairs = next, pairs, ipairs
local wipe     = wipe
local sort     = table.sort
local strlower = strlower
local strfind  = strfind

local Filters = {}
ns.Filters = Filters

-- ---------------------------------------------------------------------------
-- Check if filters are at default (nothing active)
-- ---------------------------------------------------------------------------
function Filters:IsDefault(filters)
    if filters.search ~= "" then return false end
    if filters.status ~= "all" then return false end
    if next(filters.rarity) then return false end
    if next(filters.type) then return false end
    if next(filters.exp) then return false end
    if filters.cat and next(filters.cat) then return false end
    if filters.kind and next(filters.kind) then return false end
    if filters.faction and next(filters.faction) then return false end
    if filters.hideUnobtainable then return false end
    if filters.hideTimeSensitive then return false end
    if filters.favouritesOnly then return false end
    return true
end

-- ---------------------------------------------------------------------------
-- Reset filters to defaults
-- ---------------------------------------------------------------------------
function Filters:Reset(filters)
    filters.search = ""
    filters.status = "all"
    wipe(filters.rarity)
    wipe(filters.type)
    wipe(filters.exp)
    if filters.cat then wipe(filters.cat) else filters.cat = {} end
    if filters.kind then wipe(filters.kind) else filters.kind = {} end
    if filters.faction then wipe(filters.faction) else filters.faction = {} end
    filters.hideUnobtainable = false
    filters.hideTimeSensitive = false
    filters.favouritesOnly = false
end

-- ---------------------------------------------------------------------------
-- Test a single record against filters (AND across facets, OR within)
-- ---------------------------------------------------------------------------
function Filters:Matches(record, filters)
    -- Favourites only
    if filters.favouritesOnly then
        local favs = ns.Epithet.db and ns.Epithet.db.profile.favourites
        if not favs or not favs[strlower(record.text or "")] then return false end
    end

    -- Status
    if filters.status == "earned" and not record.earned then return false end
    if filters.status == "unearned" and record.earned then return false end

    -- Hide unobtainable
    if filters.hideUnobtainable and record.obtainable == "no" then return false end

    -- Hide time-sensitive / feat of strength
    if filters.hideTimeSensitive and record.obtainable == "feat" then return false end

    -- Rarity (OR within)
    if next(filters.rarity) then
        local q = record.q or 0
        if not filters.rarity[q] then return false end
    end

    -- Type (OR within)
    if next(filters.type) then
        if not filters.type[record.type] then return false end
    end

    -- Expansion (OR within)
    if next(filters.exp) then
        if not filters.exp[record.exp or ""] then return false end
    end

    -- Category (OR within)
    if filters.cat and next(filters.cat) then
        if not filters.cat[record.cat or ""] then return false end
    end

    -- Kind (OR within)
    if filters.kind and next(filters.kind) then
        if not filters.kind[record.kind or ""] then return false end
    end

    -- Faction (OR within; "Both" means show Alliance + Horde specific titles)
    if filters.faction and next(filters.faction) then
        local f = record.faction
        if filters.faction["Both"] then
            -- "Both" selected: show faction-specific titles (Alliance + Horde)
            if not f then
                -- Neutral title — only show if not exclusively "Both"
                if not filters.faction["Alliance"] and not filters.faction["Horde"] then
                    return false
                end
            end
        else
            -- Only specific factions selected
            if f then
                if not filters.faction[f] then return false end
            else
                -- Neutral title, no matching faction filter
                return false
            end
        end
    end

    -- Search (case-insensitive substring using pre-computed key from Scan)
    if filters.search and filters.search ~= "" then
        local needle = strlower(filters.search)
        local haystack = record._searchKey
        if not haystack then
            haystack = strlower(
                (record.text or "") .. " " ..
                (record.achievement or "") .. " " ..
                (record.quest or "") .. " " ..
                (record.source_item or "") .. " " ..
                (record.cat or "")
            )
        end
        if not strfind(haystack, needle, 1, true) then
            return false
        end
    end

    return true
end

-- Scratch table reused by Apply() to avoid per-call allocation
local filteredScratch = {}

-- ---------------------------------------------------------------------------
-- Apply filters to a list of records, return filtered array
-- NOTE: The returned table is reused across calls. Callers must consume it
-- before the next Apply() invocation (BuildDisplayList does this).
-- ---------------------------------------------------------------------------
function Filters:Apply(records, filters)
    wipe(filteredScratch)
    for _, record in ipairs(records) do
        if self:Matches(record, filters) then
            filteredScratch[#filteredScratch + 1] = record
        end
    end
    return filteredScratch
end

-- ---------------------------------------------------------------------------
-- Sort modes
-- ---------------------------------------------------------------------------
local function ExpOrder(exp)
    return ns.EXPANSION_INDEX[exp or ""] or 99
end

local function SortCollectedFirst(a, b)
    -- Earned before locked
    if a.earned ~= b.earned then
        return a.earned
    end
    -- Within earned: favourites first
    if a.earned and b.earned then
        local favs = ns.Epithet.db and ns.Epithet.db.profile.favourites
        if favs then
            local fa = favs[strlower(a.text or "")] or false
            local fb = favs[strlower(b.text or "")] or false
            if fa ~= fb then return fa end
        end
    end
    -- Within group: expansion order
    local ea, eb = ExpOrder(a.exp), ExpOrder(b.exp)
    if ea ~= eb then return ea < eb end
    -- Then rarity descending
    local qa, qb = a.q or 0, b.q or 0
    if qa ~= qb then return qa > qb end
    -- Then alphabetical
    return (a.text or "") < (b.text or "")
end

local function SortByExpansion(a, b)
    local ea, eb = ExpOrder(a.exp), ExpOrder(b.exp)
    if ea ~= eb then return ea < eb end
    local qa, qb = a.q or 0, b.q or 0
    if qa ~= qb then return qa > qb end
    return (a.text or "") < (b.text or "")
end

local function SortAlphabetical(a, b)
    return (a.text or "") < (b.text or "")
end

local function SortByQuality(a, b)
    local qa, qb = a.q or 0, b.q or 0
    if qa ~= qb then return qa > qb end
    return (a.text or "") < (b.text or "")
end

local function SortByCategory(a, b)
    local ca, cb = a.cat or "", b.cat or ""
    if ca ~= cb then return ca < cb end
    return (a.text or "") < (b.text or "")
end

function Filters:Sort(records, mode)
    -- Sort in place and return the same table reference for caller chaining.
    if mode == "expansion" then
        sort(records, SortByExpansion)
    elseif mode == "alphabetical" then
        sort(records, SortAlphabetical)
    elseif mode == "quality" then
        sort(records, SortByQuality)
    elseif mode == "category" then
        sort(records, SortByCategory)
    else
        sort(records, SortCollectedFirst)
    end
    return records
end

-- ---------------------------------------------------------------------------
-- Sidebar buckets present in the loaded data
-- ---------------------------------------------------------------------------
-- Each flavour ships its own title set (Retail spans every expansion; WoW
-- Forever is all "classic" with PvP Rank and Profession kinds Retail lacks), so
-- the sidebar lists only the buckets the loaded data actually uses, instead of
-- a fixed list that would be mostly empty, or missing kinds, on one of them.
-- `order` fixes the display order of known codes; any other code present is
-- appended alphabetically so new collector codes still get a row. With no data
-- loaded at all, the full `order` is returned so the sidebar keeps its shape.
local function PresentBuckets(field, order)
    local present = {}
    local any = false
    local titles = ns.EpithetData and ns.EpithetData.titles
    for _, entry in pairs(titles or {}) do
        local v = entry[field]
        if v ~= nil and v ~= "" then
            present[v] = true
            any = true
        end
    end

    local out = {}
    if not any then
        for i, key in ipairs(order) do out[i] = key end
        return out
    end

    local known = {}
    for _, key in ipairs(order) do
        known[key] = true
        if present[key] then out[#out + 1] = key end
    end
    local extras = {}
    for key in pairs(present) do
        if not known[key] then extras[#extras + 1] = key end
    end
    sort(extras)
    for _, key in ipairs(extras) do out[#out + 1] = key end
    return out
end

local CATEGORY_ORDER = {
    "Achievement", "Campaign", "Exploration", "Holiday",
    "Profession", "PvP", "Quest", "Raid", "Reputation",
}
local KIND_ORDER = {
    "Achievement", "Feat of Strength", "Quest", "Reputation",
    "PvP Rank", "Profession", "Item", "Promotion",
}

-- Returns { exp = {...}, cat = {...}, kind = {...}, faction = {...} }: the
-- ordered bucket codes the sidebar should offer for the loaded data. Faction
-- buckets are "Alliance", "Horde" and "Both" (titles with no faction).
function Filters:GetBuckets()
    local factions = {}
    local titles = ns.EpithetData and ns.EpithetData.titles
    local hasAlliance, hasHorde, hasNeutral = false, false, false
    for _, entry in pairs(titles or {}) do
        if entry.faction == "Alliance" then
            hasAlliance = true
        elseif entry.faction == "Horde" then
            hasHorde = true
        else
            hasNeutral = true
        end
    end
    local noData = not (hasAlliance or hasHorde or hasNeutral)
    if hasAlliance or noData then factions[#factions + 1] = "Alliance" end
    if hasHorde or noData then factions[#factions + 1] = "Horde" end
    if hasNeutral or noData then factions[#factions + 1] = "Both" end

    return {
        exp     = PresentBuckets("exp", ns.EXPANSION_ORDER),
        cat     = PresentBuckets("cat", CATEGORY_ORDER),
        kind    = PresentBuckets("kind", KIND_ORDER),
        faction = factions,
    }
end

-- ---------------------------------------------------------------------------
-- Compute sidebar counts (against FULL dataset, not filtered)
-- Returns: { rarity={[1]=n,...}, type={prefix=n,...}, exp={classic=n,...},
--            earned=n, unearned=n, total=n }
-- ---------------------------------------------------------------------------
function Filters:ComputeCounts(records)
    local counts = {
        rarity   = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 },
        type     = { prefix = 0, suffix = 0 },
        exp      = {},
        cat      = {},
        kind     = {},
        -- Neutral/faction-agnostic titles live in "Both" (record.faction == nil).
        faction  = { Alliance = 0, Horde = 0, Both = 0 },
        earned   = 0,
        unearned = 0,
        total    = 0,
    }

    -- Initialise expansion counts
    for _, key in ipairs(ns.EXPANSION_ORDER) do
        counts.exp[key] = 0
    end

    for _, record in ipairs(records) do
        counts.total = counts.total + 1
        if record.earned then
            counts.earned = counts.earned + 1
        else
            counts.unearned = counts.unearned + 1
        end

        local q = record.q or 0
        if q >= 1 and q <= 5 then
            counts.rarity[q] = counts.rarity[q] + 1
        end

        if record.type == "prefix" then
            counts.type.prefix = counts.type.prefix + 1
        elseif record.type == "suffix" then
            counts.type.suffix = counts.type.suffix + 1
        end

        -- Counted for any expansion code, not just the known order, so a code
        -- the sidebar shows because the loaded data carries it is never left at 0.
        local exp = record.exp or ""
        if exp ~= "" then
            counts.exp[exp] = (counts.exp[exp] or 0) + 1
        end

        -- Category
        local cat = record.cat or ""
        counts.cat[cat] = (counts.cat[cat] or 0) + 1

        -- Kind
        local kind = record.kind or ""
        counts.kind[kind] = (counts.kind[kind] or 0) + 1

        -- Faction
        local f = record.faction
        if f == "Alliance" then
            counts.faction.Alliance = counts.faction.Alliance + 1
        elseif f == "Horde" then
            counts.faction.Horde = counts.faction.Horde + 1
        else
            counts.faction.Both = counts.faction.Both + 1
        end
    end

    return counts
end

-- ---------------------------------------------------------------------------
-- Build display list with group headers (for "Collected first" mode)
-- Returns array of {isHeader=bool, label=string, count=number} or record refs
-- ---------------------------------------------------------------------------
function Filters:BuildDisplayList(records, sortMode)
    local sorted = self:Sort(records, sortMode)

    if sortMode == "expansion" or sortMode == "alphabetical" or sortMode == "quality" then
        -- No group headers in flat modes
        return sorted
    end

    if sortMode == "category" then
        -- Insert group headers per category
        local display = {}
        local currentCat = nil
        local catCounts = {}
        for _, record in ipairs(sorted) do
            local c = record.cat or ""
            catCounts[c] = (catCounts[c] or 0) + 1
        end
        for _, record in ipairs(sorted) do
            local c = record.cat or ""
            if c ~= currentCat then
                currentCat = c
                local label = (c ~= "") and ns.CategoryLabel(c) or (ns.L and ns.L["CATEGORY_UNCATEGORIZED"]) or "Uncategorized"
                -- Uppercase locale-safely: plain :upper() only folds ASCII and
                -- would leave a Cyrillic (or other non-Latin) label lower-case.
                display[#display + 1] = {
                    isHeader = true,
                    label = (ns.Strupper and ns.Strupper(label)) or label:upper(),
                    count = catCounts[c] or 0,
                }
            end
            display[#display + 1] = record
        end
        return display
    end

    -- "Collected first" mode: insert group headers
    local display = {}
    local earnedCount = 0
    local lockedCount = 0
    local inLockedSection = false

    for _, record in ipairs(sorted) do
        if record.earned then
            earnedCount = earnedCount + 1
        else
            lockedCount = lockedCount + 1
        end
    end

    local insertedEarnedHeader = false
    local insertedLockedHeader = false

    for _, record in ipairs(sorted) do
        if record.earned and not insertedEarnedHeader then
            display[#display + 1] = {
                isHeader = true,
                label = ns.L and ns.L["GROUP_COLLECTED"] or "COLLECTED",
                count = earnedCount,
            }
            insertedEarnedHeader = true
        elseif not record.earned and not insertedLockedHeader then
            display[#display + 1] = {
                isHeader = true,
                label = ns.L and ns.L["GROUP_NOT_COLLECTED"] or "NOT YET COLLECTED",
                count = lockedCount,
            }
            insertedLockedHeader = true
        end
        display[#display + 1] = record
    end

    return display
end
