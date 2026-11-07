-- =============================================================================
-- Epithet Probe — dev-only diagnostics for WoW Forever support. Never shipped
-- (tools/ is outside the package). Run the same commands on Retail and on WoW
-- Forever: Retail is the control, so a texture that "fails" there means the
-- detection is wrong, not the client.
--
--   /eprobe textures      try every Blizzard texture Epithet names (Textures.lua)
--   /eprobe names [unit]  record every name API for a unit (default: target;
--                         "player" for yourself)
--   /eprobe self          your buffs (run it at a campsite), the class list, your GUID
--   /eprobe report        print what has been recorded on this client
--   /eprobe clear         forget this client's results
--
-- Results are saved per client in EpithetProbeDB, written to
-- WTF\Account\<account>\SavedVariables\EpithetProbe.lua on /reload or logout.
-- =============================================================================

EpithetProbeDB = EpithetProbeDB or {}

local issecretvalue = _G.issecretvalue

local function Out(msg)
    print("|cffe8c873Epithet probe:|r " .. tostring(msg))
end

-- A value as text; secret values (combat taint) and errors never break the probe.
local function Show(value)
    if value == nil then return "nil" end
    if issecretvalue and issecretvalue(value) then return "<secret>" end
    local ok, text = pcall(tostring, value)
    return ok and text or "<unprintable>"
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return { "<no such API>" } end
    local results = { pcall(fn, ...) }
    if not results[1] then return { "<error: " .. Show(results[2]) .. ">" } end
    local out = {}
    for i = 2, #results do out[#out + 1] = Show(results[i]) end
    if #out == 0 then out[1] = "nil" end
    return out
end

local function ClientRecord()
    local version, build, date, interface = GetBuildInfo()
    local key = Show(interface) .. "-" .. Show(build)
    local rec = EpithetProbeDB[key]
    if not rec then
        rec = { version = Show(version), build = Show(build), date = Show(date), interface = Show(interface) }
        EpithetProbeDB[key] = rec
    end
    return rec, key
end

-- ---------------------------------------------------------------------------
-- Textures
-- ---------------------------------------------------------------------------
-- No single API says "this file exists", so every signal is recorded and a
-- texture counts as loaded when any of them says so. The Retail run checks
-- that this verdict is right before the Forever run is trusted.
local probeFrame = CreateFrame("Frame", nil, UIParent)
probeFrame:SetSize(1, 1)
probeFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 10, -10)  -- off screen
local probeTex = probeFrame:CreateTexture(nil, "ARTWORK")
probeTex:SetAllPoints()

local function ProbeTexture(path)
    local result = {}
    if type(GetFileIDFromPath) == "function" then
        local ok, id = pcall(GetFileIDFromPath, path)
        result.fileIDFromPath = ok and id or nil
    end
    probeTex:SetTexture(nil)
    local ok, ret = pcall(probeTex.SetTexture, probeTex, path)
    result.setTextureReturned = ok and Show(ret) or "<error>"
    if probeTex.GetTextureFileID then
        local okID, id = pcall(probeTex.GetTextureFileID, probeTex)
        result.fileIDAfterSet = okID and id or nil
    end
    local okGet, got = pcall(probeTex.GetTexture, probeTex)
    result.getTexture = okGet and Show(got) or "<error>"
    result.loaded = (type(result.fileIDFromPath) == "number" and result.fileIDFromPath > 0)
        or (type(result.fileIDAfterSet) == "number" and result.fileIDAfterSet > 0)
        or (ok and ret == true)
        or false
    return result
end

local function ProbeTextures()
    local list = EpithetProbeTextures or {}
    local rec = ClientRecord()
    rec.textures = {}
    rec.missingTextures = {}
    for _, entry in ipairs(list) do
        local r = ProbeTexture(entry.path)
        r.used = entry.used
        rec.textures[entry.path] = r
        if not r.loaded then
            rec.missingTextures[#rec.missingTextures + 1] = entry.path .. "  (" .. entry.used .. ")"
        end
    end
    probeTex:SetTexture(nil)
    table.sort(rec.missingTextures)
    Out(("%d textures tried, %d did not load."):format(#list, #rec.missingTextures))
    for i = 1, math.min(#rec.missingTextures, 15) do Out("  missing: " .. rec.missingTextures[i]) end
    if #rec.missingTextures > 15 then Out("  ... the rest are in SavedVariables after /reload") end
end

-- ---------------------------------------------------------------------------
-- Names
-- ---------------------------------------------------------------------------
-- How each client shows a unit's name and title. On WoW Forever names have a
-- first and a last name; this records which API carries which part, so the
-- title reader (Epithet's TitleIndex:ReadTitle) can be checked against it.
local function ProbeNames(unit)
    unit = (unit and unit ~= "") and unit or "target"
    if not UnitExists(unit) then
        Out("no unit '" .. unit .. "'. Target a player first.")
        return
    end
    local r = {
        unit = unit,
        at = date("%Y-%m-%d %H:%M:%S"),
        UnitIsPlayer = Call(UnitIsPlayer, unit),
        UnitName = Call(UnitName, unit),
        UnitFullName = Call(UnitFullName, unit),
        UnitNameUnmodified = Call(_G.UnitNameUnmodified, unit),
        UnitPVPName = Call(UnitPVPName, unit),
        GetUnitName_noRealm = Call(GetUnitName, unit, false),
        GetUnitName_withRealm = Call(GetUnitName, unit, true),
        UnitFactionGroup = Call(UnitFactionGroup, unit),
        -- Race and class file tokens ("Scourge", "MAGE") are what the
        -- achievements match on; Skyborne's token is not known yet.
        UnitRace = Call(_G.UnitRace, unit),
        UnitClass = Call(_G.UnitClass, unit),
        UnitLevel = Call(_G.UnitLevel, unit),
        -- Client-wide, but cheap: which realm API gives a name players know
        -- (Forever's normalised realm is an internal ID).
        GetRealmName = Call(_G.GetRealmName),
        GetNormalizedRealmName = Call(_G.GetNormalizedRealmName),
    }
    if unit == "target" and TargetFrameName and TargetFrameName.GetText then
        r.TargetFrameName = Call(TargetFrameName.GetText, TargetFrameName)
    end
    local guid = UnitGUID(unit)
    r.UnitGUID = Show(guid)
    if guid and GetPlayerInfoByGUID then
        local info = Call(GetPlayerInfoByGUID, guid)
        r.GetPlayerInfoByGUID_name = info[6]
        r.GetPlayerInfoByGUID_realm = info[7]
    end
    if unit ~= "player" then
        r.myTitle = Call(GetCurrentTitle)
    end

    local rec = ClientRecord()
    rec.names = rec.names or {}
    table.insert(rec.names, 1, r)
    while #rec.names > 40 do table.remove(rec.names) end

    for _, k in ipairs({ "UnitName", "UnitFullName", "UnitNameUnmodified", "UnitPVPName", "GetUnitName_noRealm",
                         "GetUnitName_withRealm", "TargetFrameName", "GetRealmName", "GetNormalizedRealmName",
                         "UnitRace", "UnitClass", "UnitLevel" }) do
        if r[k] then Out(("%-22s %s"):format(k, table.concat(r[k], " | "))) end
    end
    Out("GetPlayerInfoByGUID    " .. Show(r.GetPlayerInfoByGUID_name) .. " | " .. Show(r.GetPlayerInfoByGUID_realm))
end

-- ---------------------------------------------------------------------------
-- Self: your buffs (the campfire's spell), the class list and your GUID
-- ---------------------------------------------------------------------------
-- Run it while resting at a campsite, so the campfire buff is among the buffs.
local function ReadBuffs()
    local buffs = {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not aura then break end
            buffs[#buffs + 1] = Show(aura.name) .. " (spell " .. Show(aura.spellId) .. ")"
        end
    elseif UnitBuff then
        for i = 1, 40 do
            local results = { pcall(UnitBuff, "player", i) }
            if not results[1] or not results[2] then break end
            -- name is the 1st value, spellId the 10th
            buffs[#buffs + 1] = Show(results[2]) .. " (spell " .. Show(results[11]) .. ")"
        end
    end
    return buffs
end

local function ReadClasses()
    local classes = {}
    local n = (GetNumClasses and select(2, pcall(GetNumClasses))) or 0
    if type(n) ~= "number" then n = 0 end
    -- Class IDs are sparse on Forever (no 6, Death Knight; Druid is 11), so
    -- walk the whole ID range rather than 1..GetNumClasses().
    for i = 1, 20 do
        local info = Call(GetClassInfo, i)
        if info[1] ~= "nil" and info[1] ~= "<no such API>" then
            classes[#classes + 1] = table.concat(info, " | ")
        end
    end
    return classes, n
end

local function ProbeSelf()
    local rec = ClientRecord()
    local classes, n = ReadClasses()
    local r = {
        at = date("%Y-%m-%d %H:%M:%S"),
        zone = Call(_G.GetZoneText),
        subZone = Call(_G.GetSubZoneText),
        mapID = (C_Map and C_Map.GetBestMapForUnit) and Call(C_Map.GetBestMapForUnit, "player") or { "<no C_Map>" },
        resting = Call(_G.IsResting),
        UnitGUID = Show(UnitGUID("player")),
        UnitRace = Call(_G.UnitRace, "player"),
        UnitClass = Call(_G.UnitClass, "player"),
        UnitLevel = Call(_G.UnitLevel, "player"),
        GetNumClasses = n,
        classes = classes,
        buffs = ReadBuffs(),
    }
    rec.self = rec.self or {}
    table.insert(rec.self, 1, r)
    while #rec.self > 20 do table.remove(rec.self) end

    Out("GUID " .. r.UnitGUID .. "   zone " .. table.concat(r.zone, "") .. " / " .. table.concat(r.subZone, "") .. "   resting " .. table.concat(r.resting, ""))
    Out(("classes (%d): "):format(n))
    for _, c in ipairs(classes) do Out("  " .. c) end
    Out(("buffs (%d):"):format(#r.buffs))
    for _, b in ipairs(r.buffs) do Out("  " .. b) end
end

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------
local function Report()
    local rec, key = ClientRecord()
    Out("client " .. key .. " (" .. rec.version .. ")")
    if rec.missingTextures then
        Out(("textures: %d missing"):format(#rec.missingTextures))
    else
        Out("textures: not probed yet (/eprobe textures)")
    end
    Out(("names: %d unit(s) recorded"):format(rec.names and #rec.names or 0))
end

SLASH_EPITHETPROBE1 = "/eprobe"
SlashCmdList.EPITHETPROBE = function(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    if cmd == "textures" then
        ProbeTextures()
    elseif cmd == "names" then
        ProbeNames(arg)
    elseif cmd == "self" then
        ProbeSelf()
    elseif cmd == "report" then
        Report()
    elseif cmd == "clear" then
        local _, key = ClientRecord()
        EpithetProbeDB[key] = nil
        Out("cleared " .. key)
    else
        Out("/eprobe textures | names [unit] | self | report | clear")
    end
end
