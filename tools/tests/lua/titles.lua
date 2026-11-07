-- Title data, the sidebar filters and title reading (TitleData, Filters,
-- TitleIndex) on both flavours. Run by titles.test.js, which provides FILES
-- (repo files by path) and check().

local function run(src, name, ns)
    local chunk, err = load(src, "=" .. name)
    if not chunk then error(name .. ": " .. err) end
    chunk("Epithet", ns)
end

local RETAIL = FILES["data/retail/TitlesDB.enGB.lua"]
local FOREVER = FILES["data/forever/TitlesDB.enGB.lua"]

-- The live client catalogue (titleID -> GetTitleName string) built from a DB.
-- `translate` simulates a non-English client: it maps the English text to the
-- client's text, so the English text keys can never match.
local function catalogueFrom(dataSrc, translate)
    EpithetData = nil
    run(dataSrc, "data", {})
    local live, maxID = {}, 0
    for _, e in pairs(EpithetData.titles) do
        local text = translate and translate(e.text) or e.text
        live[e.titleID] = (e.type == "prefix") and (text .. " %s") or ("%s " .. text)
        if e.titleID > maxID then maxID = e.titleID end
    end
    EpithetData = nil
    return live, maxID
end

local function newEnv(dataSrc, live, maxID, unit)
    EpithetData = nil
    strlower = string.lower; strupper = string.upper; format = string.format
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    GetLocale = function() return "enUS" end
    GetTitleName = function(id) return live[id] end
    GetNumTitles = function() return maxID end
    IsTitleKnown = function() return false end
    GetCurrentTitle = function() return unit and unit.title or 0 end
    UnitName = function() return unit and unit.name end
    GetNormalizedRealmName = function() return "Realm" end
    UnitFactionGroup = function() return unit and unit.faction end
    UnitIsPlayer = function() return true end
    UnitPVPName = function() return unit and unit.pvp end
    GetAchievementInfo = nil
    local ns = {}
    run(dataSrc, "data", ns)
    run(FILES["Locales/LocaleManager.lua"], "LocaleManager", ns)
    run(FILES["Locales/enGB.lua"], "enGB", ns)
    run(FILES["Core/Theme.lua"], "Theme", ns)  -- TOC order: Theme before TitleData
    run(FILES["Core/TitleData.lua"], "TitleData", ns)
    run(FILES["Core/Filters.lua"], "Filters", ns)
    run(FILES["Spotting/TitleIndex.lua"], "TitleIndex", ns)
    ns.TitleData:Scan(true)
    return ns
end

local function join(list) return table.concat(list, ",") end
local function cap(s) return (s:gsub("^%l", string.upper)) end
local function capAll(live) for id, raw in pairs(live) do live[id] = cap(raw) end return live end

-- ======================================================================
-- Forever: the data, buckets and faction variants
-- ======================================================================
do
    local live, maxID = catalogueFrom(FOREVER)
    live[36] = "[DNT] Test %s"
    if maxID < 41 then maxID = 41 end

    local ns = newEnv(FOREVER, live, maxID, nil)
    local td = ns.TitleData
    check(#td.records == 40, "Forever: 40 titles listed (got " .. #td.records .. ")")
    check(td.recordsByID[36] == nil, "Forever: no [DNT] Test row")

    local sergeants = {}
    for _, r in ipairs(td.records) do
        if r.text == "sergeant" then sergeants[#sergeants + 1] = r end
    end
    check(#sergeants == 2, "Forever: two Sergeant rows (got " .. #sergeants .. ")")
    local f = {}
    for _, r in ipairs(sergeants) do f[r.faction or "nil"] = r.titleID end
    check(f.Alliance == 10 and f.Horde == 23, "Forever: Sergeant 10 Alliance / 23 Horde")

    local profCount = 0
    for _, r in ipairs(td.records) do
        if r.kind == "Profession" then profCount = profCount + 1 end
    end
    check(profCount == 7, "Forever: 7 Profession records (got " .. profCount .. ")")
    check(ns.KindLabel("Profession") == "Profession", "Forever: Profession kind label")
    check(ns.KindLabel("PvP Rank") == "PvP Rank", "PvP Rank label")
    check(td.totalCount == 40, "Forever: totalCount 40 (got " .. td.totalCount .. ")")

    local b = ns.Filters:GetBuckets()
    check(join(b.exp) == "classic", "Forever: exp bucket is classic only")
    check(join(b.kind) == "Achievement,Reputation,PvP Rank,Profession", "Forever: kind buckets (" .. join(b.kind) .. ")")
    check(join(b.cat) == "Achievement,Profession,PvP,Reputation", "Forever: cat buckets (" .. join(b.cat) .. ")")
    local counts = ns.Filters:ComputeCounts(td.records)
    check(counts.exp.classic == 40, "Forever: exp classic count 40")
    check(counts.kind["PvP Rank"] == 28 and counts.kind.Profession == 7, "Forever: kind counts")
    check(counts.faction.Alliance == 14 and counts.faction.Horde == 14 and counts.faction.Both == 12, "Forever: faction counts")

    -- Variant pick from text alone
    local base = EpithetData.titles["sergeant"]
    check(ns.PickFactionVariant(base, "Horde").titleID == 23, "PickFactionVariant Horde -> 23")
    check(ns.PickFactionVariant(base, "Alliance").titleID == 10, "PickFactionVariant Alliance -> 10")
    check(ns.PickFactionVariant(base, nil).titleID == 10, "PickFactionVariant nil -> base")
    local other = EpithetData.titles["corporal"]
    check(ns.PickFactionVariant(other, "Horde") == other, "PickFactionVariant no-op for unsplit title")

    -- Spotting: TitleIndex resolves by unit faction
    for _, case in ipairs({ { "Horde", 23 }, { "Alliance", 10 } }) do
        local env = newEnv(FOREVER, live, maxID, { name = "Bob", pvp = "sergeant Bob", faction = case[1] })
        check(env.TitleIndex:Resolve("target") == case[2], "TitleIndex " .. case[1] .. " Sergeant -> " .. case[2])
    end
    local env = newEnv(FOREVER, live, maxID, { name = "Bob", pvp = "sergeant Bob", faction = nil })
    local rid = env.TitleIndex:Resolve("target")
    check(rid == 10 or rid == 23, "TitleIndex unknown faction still resolves a Sergeant")
    local env2 = newEnv(FOREVER, live, maxID, { name = "Bob", pvp = "corporal Bob", faction = "Horde" })
    check(env2.TitleIndex:Resolve("target") == 9, "TitleIndex unsplit title unaffected by faction")

    -- Non-English client: the text keys never match, IDs must carry it.
    local liveDE, maxDE = catalogueFrom(FOREVER, function(t) return "de-" .. t:reverse() end)
    liveDE[36] = "[DNT] Test %s"
    local nsDE = newEnv(FOREVER, liveDE, math.max(maxDE, 41))
    local n = 0
    for _, r in ipairs(nsDE.TitleData.records) do
        if r.titleID == 10 or r.titleID == 23 then n = n + 1 end
    end
    check(#nsDE.TitleData.records == 40, "Forever non-English: 40 titles (got " .. #nsDE.TitleData.records .. ")")
    check(n == 2, "Forever non-English: two Sergeant rows")
end

-- ======================================================================
-- Retail: the data and buckets
-- ======================================================================
for _, scenario in ipairs({ "english", "non-english" }) do
    local translate = (scenario == "non-english") and function(t) return "de-" .. t:reverse() end or nil
    local live, maxID = catalogueFrom(RETAIL, translate)
    -- Retail alias IDs the collector does not ship: Sergeant is 3/17/156/170,
    -- Grunt is 16/169; plus the [PH] placeholders.
    local sergeant = live[3]
    live[17], live[156], live[170] = sergeant, sergeant, sergeant
    live[169] = live[16]
    for id = 660, 663 do live[id] = "[PH] %s" end
    if maxID < 663 then maxID = 663 end

    local ns = newEnv(RETAIL, live, maxID, nil)
    local td = ns.TitleData
    check(#td.records > 600, "Retail " .. scenario .. ": the catalogue is listed (" .. #td.records .. " records)")
    local placeholder, sergeants = false, 0
    for _, r in ipairs(td.records) do
        if tostring(r.text):find("%[PH%]") then placeholder = true end
        if r._titleIDs and r._titleIDs[3] then
            sergeants = sergeants + 1
            check(r._titleIDs[17] and r._titleIDs[156] and r._titleIDs[170], "Retail " .. scenario .. ": Sergeant aliases share one record")
        end
    end
    check(not placeholder, "Retail " .. scenario .. ": no [PH] placeholder rows")
    check(sergeants == 1, "Retail " .. scenario .. ": one record carries Sergeant 3")

    local b = ns.Filters:GetBuckets()
    check(join(b.exp) == join(ns.EXPANSION_ORDER), "Retail exp buckets = EXPANSION_ORDER")
    check(join(b.cat) == "Achievement,Campaign,Exploration,Holiday,Profession,PvP,Quest,Raid,Reputation", "Retail cat buckets (" .. join(b.cat) .. ")")
    check(join(b.kind) == "Achievement,Feat of Strength,Quest,Reputation", "Retail kind buckets (" .. join(b.kind) .. ")")
    check(join(b.faction) == "Alliance,Horde,Both", "Retail faction buckets")
end

-- ======================================================================
-- Retail: reading a title off a displayed name, for every title
-- ======================================================================
for _, scenario in ipairs({ "english", "non-english" }) do
    local translate = (scenario == "non-english") and function(t) return "de-" .. t:reverse() end or nil
    local live, maxID = catalogueFrom(RETAIL, translate)
    local unit = { name = "Ann", pvp = "Ann" }
    local ns = newEnv(RETAIL, live, maxID, unit)
    local readWrong, resolveWrong, n = 0, 0, 0
    for id, raw in pairs(live) do
        n = n + 1
        local wantType = raw:find("^%%s") and "suffix" or "prefix"
        local wantText = (raw:gsub("%%s", "")):gsub("^%s+", ""):gsub("%s+$", "")
        for _, base in ipairs({ "Ann", "Ann-Realm" }) do
            local display = raw:gsub("%%s", base)
            local affix, text = ns.TitleIndex:ReadTitle({ display }, "Ann")
            if affix ~= wantType or tostring(text):lower() ~= wantText:lower() then
                readWrong = readWrong + 1
                if readWrong <= 3 then print(("  read '%s' -> %s/%s"):format(display, tostring(affix), tostring(text))) end
            end
        end
        -- Spotting resolves to a title showing this text in this position.
        unit.pvp = raw:gsub("%%s", "Ann")
        local got = ns.TitleIndex:Resolve("target")
        local rec = got and live[got]
        if not rec or rec:lower() ~= raw:lower() then
            resolveWrong = resolveWrong + 1
            if resolveWrong <= 3 then print(("  resolve '%s' -> %s"):format(unit.pvp, tostring(got))) end
        end
    end
    check(readWrong == 0, ("Retail %s: every title read off a name (%d titles, %d wrong)"):format(scenario, n, readWrong))
    check(resolveWrong == 0, ("Retail %s: spotting resolves every title (%d wrong)"):format(scenario, resolveWrong))
    check(ns.TitleIndex:ReadTitle({ "Ann" }, "Ann") == nil, "Retail " .. scenario .. ": a plain name shows no title")
end

-- ======================================================================
-- The player's own name in the header (TitleData.playerName)
-- ======================================================================
do
    -- Forever: first + last name, title removed.
    local live, maxID = catalogueFrom(FOREVER)
    capAll(live); maxID = math.max(maxID, 41)
    for _, c in ipairs({
        { "Bob", "Bob Smith", 0, "Bob Smith" },
        { "Bob", "Sergeant Bob Smith", 10, "Bob Smith" },
        { "Bob", "Bob Smith of the Magram", 1, "Bob Smith" },
        { "Bob", "Bob Smith", 10, "Bob" },          -- display still lags the new title: first name only
        { "Bob", nil, 0, "Bob" },                   -- display not loaded yet
        { "Bob Smith", "Sergeant Bob Smith", 10, "Bob Smith" },
    }) do
        local env = newEnv(FOREVER, live, maxID, { name = c[1], pvp = c[2], title = c[3] })
        local got = env.TitleData.playerName
        check(got == c[4], ("player name from '%s' (title %d) -> '%s' (got '%s')"):format(tostring(c[2]), c[3], c[4], tostring(got)))
    end
    -- A good read survives a later read that can't be trusted.
    local unit = { name = "Bob", pvp = "Bob Smith", title = 0 }
    local env = newEnv(FOREVER, live, maxID, unit)
    unit.title = 10                                 -- title changed, display not yet updated
    env.TitleData:RefreshActiveState()
    check(env.TitleData.playerName == "Bob Smith", "last good name kept while the display lags")
    unit.pvp = "Sergeant Bob Smith"
    env.TitleData:RefreshActiveState()
    check(env.TitleData.playerName == "Bob Smith", "name after the display catches up")

    -- Retail: always exactly UnitName, for every title in the catalogue.
    local rlive, rmax = catalogueFrom(RETAIL)
    capAll(rlive)
    local runit = { name = "Bob", pvp = "Bob", title = 0 }
    local renv = newEnv(RETAIL, rlive, rmax, runit)
    check(renv.TitleData.playerName == "Bob", "Retail: no title -> UnitName")
    local wrong, n = 0, 0
    for id, raw in pairs(rlive) do
        n = n + 1
        runit.title = id
        runit.pvp = raw:gsub("%%s", "Bob", 1)
        renv.TitleData.playerName = nil
        renv.TitleData:RefreshActiveState()
        if renv.TitleData.playerName ~= "Bob" then wrong = wrong + 1 end
    end
    check(wrong == 0, ("Retail: player name is UnitName for all %d titles (%d differ)"):format(n, wrong))
    runit.title, runit.pvp = 36, "Bob, Champion of the Naaru"
    renv.TitleData.playerName = nil
    renv.TitleData:RefreshActiveState()
    check(renv.TitleData.playerName == "Bob", "Retail: comma suffix stripped (got " .. tostring(renv.TitleData.playerName) .. ")")
end

-- ======================================================================
-- Names with a surname (WoW Forever): no title read off a surname
-- ======================================================================
do
    local live, maxID = catalogueFrom(FOREVER)
    capAll(live)
    local ns = newEnv(FOREVER, live, math.max(maxID, 41))
    local TI = ns.TitleIndex

    local function read(display, base) return TI:ReadTitle({ display }, base) end
    local a, t, id = read("Bob Smith", "Bob")
    check(t == nil, "surname alone is not a title (got " .. tostring(t) .. ")")
    a, t = read("Bob Smith", "Bob Smith")
    check(t == nil, "full name alone is not a title")
    a, t, id = read("Sergeant Bob Smith", "Bob")
    check(a == "prefix" and t == "Sergeant" and (id == 10 or id == 23), "prefix title before first+last name")
    a, t = read("Sergeant Bob Smith", "Bob Smith")
    check(a == "prefix" and t == "Sergeant", "prefix title, full base")
    a, t, id = read("Bob Smith of the Magram", "Bob")
    check(a == "suffix" and t == "of the Magram" and id == 1, "suffix title after first+last name (" .. tostring(t) .. ")")
    a, t = read("Bob Sergeant", "Bob")
    check(t == nil, "surname that is a prefix title word, at the end, is not a title (got " .. tostring(t) .. ")")
    a, t = read("Bob Smith", "Al")
    check(t == nil, "name not in display: nothing")
    a, t = read("Bob", "Bob")
    check(t == nil, "plain name: nothing")

    for _, c in ipairs({
        { "Bob", "Bob Smith", "Horde", nil },
        { "Bob", "Sergeant Bob Smith", "Horde", 23 },
        { "Bob", "Sergeant Bob Smith", "Alliance", 10 },
        { "Bob", "Bob Smith of the Magram", "Alliance", 1 },
        { "Bob", "Bob Sergeant", "Horde", nil },
        { "Bob Smith", "Sergeant Bob Smith", "Horde", 23 },
    }) do
        local env = newEnv(FOREVER, live, math.max(maxID, 41), { name = c[1], pvp = c[2], faction = c[3] })
        local got = env.TitleIndex:Resolve("target")
        check(got == c[4], ("Resolve '%s' (UnitName '%s', %s) -> %s (got %s)"):format(c[2], c[1], c[3], tostring(c[4]), tostring(got)))
    end
end
