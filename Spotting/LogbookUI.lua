-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...
local L = ns.L
local T = ns.Theme
local GetSpellTexture = GetSpellTexture

local LogbookUI = {}
ns.LogbookUI = LogbookUI

local CHECK_ICON = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-ui-check-32"
local LOCK_ICON = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-ui-lock-32"
local BINOCULARS_ICON = "Interface\\Icons\\INV_Misc_Spyglass_03"
local ACHIEVEMENTS_LOG_ICON = "Interface\\Icons\\achievement_guildperk_mrpopularity_rank2"
local CLASS_ICON = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local RACE_ICON = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-RACES"
local ACHIEVEMENT_ICON = "Interface\\Icons\\Achievement_General"
local BODYTYPE_ICON_1 = "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-BodyType-1"
local BODYTYPE_ICON_2 = "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-BodyType-2"
local BODYTYPE_ICON_1_LEGACY = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-GENDER-BODYTYPE1"
local BODYTYPE_ICON_2_LEGACY = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-GENDER-BODYTYPE2"
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local ROW_HEIGHT = 36
local TILE_SIZE = 104
local TILE_GAP = 10
local ACHV_TILE_MIN = 74
local ACHV_TILE_GAP = 10

local STANDARD_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local ACHIEVEMENT_FALLBACK_ICONS = {
    count_1 = "Interface\\Icons\\INV_Misc_Spyglass_02",
    count_10 = "Interface\\Icons\\INV_Misc_Eye_01",
    count_25 = "Interface\\Icons\\INV_Misc_Note_01",
    count_50 = "Interface\\Icons\\INV_Misc_Spyglass_03",
    count_100 = "Interface\\Icons\\Ability_Rogue_Shadowstep",
    count_200 = "Interface\\Icons\\inv_helm_misc_pignosemask_a_01",
    count_350 = "Interface\\Icons\\Achievement_Boss_CThun",
    count_500 = "Interface\\Icons\\INV_Misc_Book_09",
    count_700 = "Interface\\Icons\\Inv_Box_BirdCage_01",
    roll_call = "Interface\\Icons\\Achievement_pvp_p_10",
    full_spectrum = "Interface\\Icons\\INV_Misc_Gem_Variety_01",
    both_ends = "Interface\\Icons\\INV_Scroll_03",
    grand_tour = "Interface\\Icons\\INV_Misc_Map_01",
    title_fwends = "Interface\\Icons\\Achievement_WorldEvent_Valentine",
    havent_we_met = "Interface\\Icons\\Ability_priest_focusedwill",
    long_con = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
    night_shift = "Interface\\Icons\\Spell_Holy_ElunesGrace",
    busy_day = "Interface\\Icons\\Spell_Holy_BorrowedTime",
    capital_offence = "Interface\\Icons\\Inv_jewelcrafting_gem_02",
    old_money = "Interface\\Icons\\INV_Misc_Coin_02",
    legendary_spot = "Interface\\Icons\\INV_Misc_Gem_Topaz_02",
    potted_history = "Interface\\Icons\\INV_Misc_Flower_02",
    diplomatic_immunity = "Interface\\Icons\\Achievement_Reputation_01",
    small_world = "Interface\\Icons\\Achievement_Character_Gnome_Male",
    creature_of_habit = "Interface\\Icons\\Spell_Nature_Polymorph_Cow",
    seeing_stars = "Interface\\Icons\\Achievement_general_classact",
    museum_curator = "Interface\\Icons\\Trade_archaeology_tinydinosaurskeleton",
    gnome_spotter = "Interface\\Icons\\Ability_mount_mechastrider",
    at_least_chicken = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
    certified = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    overachiever = "Interface\\Icons\\Achievement_Quests_Completed_06",
    guising = "Interface\\Icons\\INV_Misc_Bag_28_Halloween",
    quite_a_mouthful = "Interface\\Icons\\Ability_mage_burnout",
    terse = "Interface\\Icons\\INV_Misc_Note_05",
    lord_of_lords = "Interface\\Icons\\Achievement_Boss_LichKing",
    masterclass = "Interface\\Icons\\Achievement_bg_most_damage_killingblow_dieleast",
    slay = "Interface\\Icons\\INV_Sword_27",
    gladiator_groupie = "Interface\\Icons\\Achievement_FeatsOfStrength_Gladiator_01",
    raid_spectator = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    brown_noser = "Interface\\Icons\\Achievement_Reputation_03",
    how_its_made = "Interface\\Icons\\Trade_Engineering",
    people_watcher = "Interface\\Icons\\Achievement_halloween_smiley_01",
    professional_lurker = "Interface\\Icons\\Ability_Ambush",
    double_take = "Interface\\Icons\\Spell_nature_invisibilty",
    early_bird = "Interface\\Icons\\INV_Egg_05",
    weekend_warrior = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
    full_week = "Interface\\Icons\\INV_Misc_PocketWatch_02",
    year_in_field = "Interface\\Icons\\INV_Misc_Book_02",
    welcome_back = "Interface\\Icons\\Spell_Holy_Resurrection",
    feast_your_eyes = "Interface\\Icons\\INV_Holiday_Christmas_Present_01",
    participation_award = "Interface\\Icons\\INV_Misc_Coin_16",
    sneaky_beaky = "Interface\\Icons\\Ability_Stealth",
    dead_man_walking = "Interface\\Icons\\Spell_Deathknight_ClassIcon",
    old_school = "Interface\\Icons\\Achievement_Zone_Barrens_01",
    popular = "Interface\\Icons\\Spell_shadow_improvedvampiricembrace",
    restraining_order = "Interface\\Icons\\INV_Misc_Note_03",
    beyond_the_grave = "Interface\\Icons\\Achievement_halloween_ghost_01",
    know_thy_enemy = "Interface\\Icons\\INV_BannerPVP_01",
    secret_keeper = "Interface\\Icons\\INV_Misc_Key_03",
    owned_1 = "Interface\\Icons\\INV_Crown_01",
    owned_10 = "Interface\\Icons\\INV_Letter_15",
    owned_25 = "Interface\\Icons\\INV_Misc_Ribbon_01",
    owned_50 = "Interface\\Icons\\INV_Shield_04",
    owned_100 = "Interface\\Icons\\Spell_Misc_EmotionHappy",
    owned_spectrum = "Interface\\Icons\\INV_Chest_Cloth_17",
    owned_both_ends = "Interface\\Icons\\INV_Misc_Book_07",
    owned_legendary = "Interface\\Icons\\INV_Staff_Medivh",
    owned_removed = "Interface\\Icons\\Trade_Archaeology",
    impulse_purchase = "Interface\\Icons\\Achievement_guildperk_bartering",
    curriculum_vitae = "Interface\\Icons\\INV_Scroll_11",
    decorated_veteran = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
    nothing_new = "Interface\\Icons\\Spell_Holy_SearingLight",
    matching_set = "Interface\\Icons\\INV_Misc_Gem_Variety_02",
    takes_one = "Interface\\Icons\\Spell_Nature_MirrorImage",
    window_shopper = "Interface\\Icons\\INV_Misc_Gift_01",
    twinsies = "Interface\\Icons\\Spell_Magic_LesserInvisibilty",
}

local function GetAchievementTileIcon(achievementID)
    return ACHIEVEMENT_FALLBACK_ICONS[achievementID] or ACHIEVEMENT_ICON
end

-- Shared with Spotting/Achievements.lua so the earned-achievement popup shows
-- the same per-achievement icon as the Logbook tile instead of a placeholder.
ns.SpottingAchievementIcon = GetAchievementTileIcon

local SHOUT_FORMAT_KEYS = {
    "SPOTTING_LOG_SHOUT_FMT_1",
    "SPOTTING_LOG_SHOUT_FMT_2",
    "SPOTTING_LOG_SHOUT_FMT_3",
    "SPOTTING_LOG_SHOUT_FMT_4",
    "SPOTTING_LOG_SHOUT_FMT_5",
}

local SHOUT_FORMAT_FALLBACKS = {
    "I've admired %d strangers a completely normal amount!",
    "I have inspected %d strangers against their knowledge and consent!",
    "I've been quietly judging the titles of %d strangers!",
    "%d strangers have been observed. None of them noticed. Excellent.",
    "I've stalked %d unsuspecting adventurers for their titles alone!",
}

local function SecretEarnedSuffixText()
    return (L and L["SPOT_ACHV_SECRET_EARNED_SUFFIX"]) or "(Secret)"
end

local function SecretEarnedTooltipText()
    return (L and L["SPOT_ACHV_SECRET_EARNED_NOTE"]) or "Originally a secret achievement."
end

local staticByID = nil

local function CountTableKeys(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do
        n = n + 1
    end
    return n
end

local function GetSocialProfile()
    return ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social or nil
end

local function GetShoutFormatByIndex(index)
    local i = tonumber(index) or 1
    if i < 1 or i > #SHOUT_FORMAT_KEYS then
        i = 1
    end

    local key = SHOUT_FORMAT_KEYS[i]
    local localized = key and L and L[key]
    return localized or SHOUT_FORMAT_FALLBACKS[i], i
end

local function BuildStaticIndex()
    if staticByID then
        return staticByID
    end

    staticByID = {}
    local titles = ns.EpithetData and ns.EpithetData.titles
    if not titles then
        return staticByID
    end

    for key, data in pairs(titles) do
        local id = data and tonumber(data.titleID)
        if id and not staticByID[id] then
            staticByID[id] = {
                titleID = id,
                text = data.text or key,
                type = data.type,
                q = data.q,
                kind = data.kind,
                cat = data.cat,
                exp = data.exp,
            }
        end
    end

    return staticByID
end

local function GetCatalogueCount()
    -- Scan() is dirty-flag gated; callers scan once up front (see Refresh()).
    local runtimeTotal = ns.TitleData and ns.TitleData.totalCount
    if tonumber(runtimeTotal) and runtimeTotal > 0 then
        return runtimeTotal
    end

    local byID = BuildStaticIndex()
    local count = CountTableKeys(byID)
    if count > 0 then
        return count
    end

    return (ns.TitleData and ns.TitleData.totalCount) or 0
end

local function GetDisplayRecord(titleID, entry)
    if ns.TitleData and ns.TitleData.GetRecord then
        local runtime = ns.TitleData:GetRecord(titleID)
        if runtime then
            return runtime
        end
    end

    local byID = BuildStaticIndex()
    local staticRecord = byID[tonumber(titleID)]
    if staticRecord then
        return staticRecord
    end

    if entry and entry.titleText and entry.titleText ~= "" then
        return {
            titleID = tonumber(titleID),
            text = entry.titleText,
            type = entry.titleType,
            q = entry.quality,
            kind = entry.kind,
            cat = entry.cat,
        }
    end

    if entry then
        return {
            titleID = tonumber(titleID),
            text = "Title #" .. tostring(titleID),
            type = entry.titleType,
            q = entry.quality,
            kind = entry.kind,
            cat = entry.cat,
        }
    end

    return nil
end

local function BuildDateString(epoch)
    if not epoch then
        return "?"
    end
    -- date("%b") month abbreviations are always English regardless of the active
    -- locale, so decompose the epoch and resolve the month through ns.L (the same
    -- MONTH_<n> keys the main title list uses), matching its "day Month year" form.
    local t = date("*t", epoch)
    local monthName = (t and L and L["MONTH_" .. t.month]) or "?"
    return string.format("%d %s %d", t.day, monthName, t.year)
end

local function GetRarityColour(quality)
    local q = tonumber(quality) or 1
    local colours = ns.QUALITY_COLOURS and ns.QUALITY_COLOURS[q]
    if colours and colours.text then
        return colours.text.r, colours.text.g, colours.text.b
    end
    return 0.9, 0.82, 0.62
end

local function GetClassCoords(classTag)
    local coords = _G.CLASS_ICON_TCOORDS
    if not coords or not classTag then
        return nil
    end
    return coords[classTag]
end

local function NormalizeRaceTagForLookup(raceTag)
    if raceTag == nil then
        return nil
    end

    local text = tostring(raceTag)
    if text == "" then
        return nil
    end

    local squashed = text:gsub("[%s%-%']", "")
    return squashed:lower(), squashed
end

local function NormalizeSexForLookup(sex)
    local n = tonumber(sex)
    if n == 2 or n == 3 then
        return n
    end
    return nil
end

local function ExtractAtlasCoords(value, sex)
    if type(value) ~= "table" then
        return nil
    end

    local normalizedSex = NormalizeSexForLookup(sex)
    if normalizedSex == 2 then
        if type(value.male) == "table" then
            local directMale = ExtractAtlasCoords(value.male, sex)
            if directMale then
                return directMale
            end
        end
        if type(value["Male"]) == "table" then
            local directMale = ExtractAtlasCoords(value["Male"], sex)
            if directMale then
                return directMale
            end
        end
    elseif normalizedSex == 3 then
        if type(value.female) == "table" then
            local directFemale = ExtractAtlasCoords(value.female, sex)
            if directFemale then
                return directFemale
            end
        end
        if type(value["Female"]) == "table" then
            local directFemale = ExtractAtlasCoords(value["Female"], sex)
            if directFemale then
                return directFemale
            end
        end
    end

    if type(value[1]) == "number" and type(value[2]) == "number" and type(value[3]) == "number" and type(value[4]) == "number" then
        return value
    end

    local byCommonKeys = {
        value.male,
        value.female,
        value.normal,
        value.default,
        value[1],
        value["Male"],
        value["Female"],
    }

    for _, candidate in ipairs(byCommonKeys) do
        local coords = ExtractAtlasCoords(candidate, sex)
        if coords then
            return coords
        end
    end

    for _, candidate in pairs(value) do
        local coords = ExtractAtlasCoords(candidate, sex)
        if coords then
            return coords
        end
    end

    return nil
end

local RACE_COORD_ALIASES = {
    scourge = "Scourge",
    undead = "Scourge",
    goblin = "Goblin",
    dracthyr = "Dracthyr",
    dracthyrvisage = "Dracthyr",
    dracthyrhumanoid = "Dracthyr",
    earthen = "Earthen",
}

local RACE_COORD_KEY_ALIASES = {
    kultiran = "KULTIRANHUMAN",
    kultiranhuman = "KULTIRANHUMAN",
    highmountaintauren = "HIGHMOUNTAIN",
    highmountain = "HIGHMOUNTAIN",
    lightforgeddraenei = "LIGHTFORGED",
    lightforged = "LIGHTFORGED",
    magharorc = "MAGHAR",
    maghar = "MAGHAR",
    darkirondwarf = "DARKIRONDWARF",
    zandalaritroll = "ZANDALARITROLL",
    voidelf = "VOIDELF",
    earthendwarf = "EARTHEN",
    earthen = "EARTHEN",
    dracthyrvisage = "DRACTHYR",
    dracthyrhumanoid = "DRACTHYR",
}

local function NormalizeRaceKeyVariant(lower)
    if type(lower) ~= "string" or lower == "" then
        return nil
    end

    local base = lower
    base = base:gsub("(alliance|horde|neutral)$", "")
    base = base:gsub("(male|female)$", "")
    if base == "" then
        return nil
    end
    return base
end

local function GetRaceCoords(raceTag, sex)
    local coords = _G.RACE_ICON_TCOORDS
    if not coords or not raceTag then
        return nil
    end

    local direct = ExtractAtlasCoords(coords[raceTag], sex)
    if direct then
        return direct
    end

    local lower, squashed = NormalizeRaceTagForLookup(raceTag)
    if not lower then
        return nil
    end

    local normalizedSex = NormalizeSexForLookup(sex)
    local sexKey = normalizedSex == 3 and "FEMALE" or "MALE"
    local baseUpper = (RACE_COORD_KEY_ALIASES[lower] or lower):upper()
    local variant = NormalizeRaceKeyVariant(lower)
    local variantUpper = variant and (RACE_COORD_KEY_ALIASES[variant] or variant):upper() or nil

    local keyedCandidates = {
        baseUpper .. "_" .. sexKey,
        baseUpper,
    }

    if variantUpper and variantUpper ~= baseUpper then
        keyedCandidates[#keyedCandidates + 1] = variantUpper .. "_" .. sexKey
        keyedCandidates[#keyedCandidates + 1] = variantUpper
    end

    for _, key in ipairs(keyedCandidates) do
        local resolved = ExtractAtlasCoords(coords[key], sex)
        if resolved then
            return resolved
        end
    end

    for key, value in pairs(coords) do
        if type(key) == "string" then
            local keyLower, keySquashed = NormalizeRaceTagForLookup(key)
            if keyLower == lower or keySquashed == squashed then
                local resolved = ExtractAtlasCoords(value, sex)
                if resolved then
                    return resolved
                end
            end
        end
    end

    local aliased = RACE_COORD_ALIASES[lower]
    if aliased then
        local resolved = ExtractAtlasCoords(coords[aliased], sex)
        if resolved then
            return resolved
        end
    end

    variant = NormalizeRaceKeyVariant(lower)
    if variant and variant ~= lower then
        local variantAlias = RACE_COORD_ALIASES[variant]
        if variantAlias then
            local resolved = ExtractAtlasCoords(coords[variantAlias], sex)
            if resolved then
                return resolved
            end
        end
    end

    if lower == "forsaken" then
        local resolved = ExtractAtlasCoords(coords.Forsaken, sex)
        if resolved then
            return resolved
        end
    end

    if lower == "magharorc" then
        local resolved = ExtractAtlasCoords(coords["Mag'harOrc"], sex) or ExtractAtlasCoords(coords.MagharOrc, sex)
        if resolved then
            return resolved
        end
    end

    if lower == "pandaren" then
        local pandaren = ExtractAtlasCoords(coords.Pandaren, sex)
        if pandaren then
            return pandaren
        end
        local neutral = ExtractAtlasCoords(coords.PandarenNeutral, sex)
        if neutral then
            return neutral
        end
        local alliance = ExtractAtlasCoords(coords.PandarenAlliance, sex)
        if alliance then
            return alliance
        end
        local horde = ExtractAtlasCoords(coords.PandarenHorde, sex)
        if horde then
            return horde
        end
    end

    return nil
end

local RACE_LABEL_OVERRIDES = {
    Scourge = "Undead",
    HighmountainTauren = "Highmountain Tauren",
    LightforgedDraenei = "Lightforged Draenei",
    DarkIronDwarf = "Dark Iron Dwarf",
    MagharOrc = "Mag'har Orc",
    ZandalariTroll = "Zandalari Troll",
    KulTiran = "Kul Tiran",
    VoidElf = "Void Elf",
    Nightborne = "Nightborne",
    Mechagnome = "Mechagnome",
    Dracthyr = "Dracthyr",
    Earthen = "Earthen",
}

local function FormatRaceLabel(raceTag)
    if type(raceTag) ~= "string" or raceTag == "" then
        return nil
    end

    if RACE_LABEL_OVERRIDES[raceTag] then
        return RACE_LABEL_OVERRIDES[raceTag]
    end

    local label = raceTag:gsub("(%l)(%u)", "%1 %2")
    return label
end

local RACE_ICON_FALLBACKS
local RACE_ICON_FALLBACKS_FEMALE
local RACE_ICON_ALIAS_TO_BASE
local RACE_ICON_SPECIES_BASE_FALLBACK
local ResolveRaceFallbackIcon
local RACE_GLUE_ICON_TOKENS
local TryApplyGlueRaceIcon
local ResolveRaceSpellIcon
local ApplyRaceTexture
local RACE_ICON_MISS_REPORTED = {}
local RACE_ICON_DEBUG_LINES = {}
local RACE_ICON_DEBUG_LIMIT = 500

local function IsRaceIconDebugEnabled()
    local admin = ns.AdminCommands
    if admin and type(admin.IsRaceIconDebugEnabled) == "function" then
        return admin:IsRaceIconDebugEnabled()
    end
    return false
end

ns.ResetRaceIconDebugCache = function()
    RACE_ICON_MISS_REPORTED = {}
end

ns.ClearRaceIconDebugLog = function()
    RACE_ICON_DEBUG_LINES = {}
end

ns.GetRaceIconDebugPayload = function()
    if #RACE_ICON_DEBUG_LINES == 0 then
        return "(No unresolved race icon entries captured yet.)"
    end
    return table.concat(RACE_ICON_DEBUG_LINES, "\n")
end

local function AppendRaceIconDebugLine(line)
    if not line or line == "" then
        return
    end
    RACE_ICON_DEBUG_LINES[#RACE_ICON_DEBUG_LINES + 1] = line
    if #RACE_ICON_DEBUG_LINES > RACE_ICON_DEBUG_LIMIT then
        table.remove(RACE_ICON_DEBUG_LINES, 1)
    end
end

local raceDebugProbeTexture = nil

local function GetRaceDebugProbeTexture()
    if raceDebugProbeTexture then
        return raceDebugProbeTexture
    end

    local parent = UIParent
    if not parent or not CreateFrame then
        return nil
    end

    local holder = CreateFrame("Frame", nil, parent)
    holder:Hide()
    raceDebugProbeTexture = holder:CreateTexture(nil, "ARTWORK")
    return raceDebugProbeTexture
end

local function CanResolveRaceIcon(raceTag, sex)
    local normalizedSex = NormalizeSexForLookup(sex)
    local probe = GetRaceDebugProbeTexture()

    local function ProbeLoadsTexture(path)
        if not probe or not path or path == "" then
            return false
        end
        if not probe.SetTexture then
            return false
        end
        return probe:SetTexture(path) == true
    end

    if raceTag and raceTag ~= "" then
        local coords = normalizedSex and GetRaceCoords(raceTag, normalizedSex) or nil
        if coords then
            return true
        end

        if probe and TryApplyGlueRaceIcon(probe, raceTag, normalizedSex) then
            return true
        end

        local icon = ResolveRaceFallbackIcon(raceTag, normalizedSex)
        if ProbeLoadsTexture(icon) then
            return true
        end

        local spellIcon = ResolveRaceSpellIcon(raceTag)
        if ProbeLoadsTexture(spellIcon) then
            return true
        end
    else
        -- Missing race tags still render via unknown placeholders and should
        -- not be reported as unresolved icon mapping failures.
        return true
    end

    return false
end

ns.RunRaceIconDebugCheck = function()
    if type(ns.ClearRaceIconDebugLog) == "function" then
        ns.ClearRaceIconDebugLog()
    end
    if type(ns.ResetRaceIconDebugCache) == "function" then
        ns.ResetRaceIconDebugCache()
    end

    local log = ns.SpottingLog
    if not log or type(log.Iterate) ~= "function" then
        return true, "Race icon check unavailable: spotting log is not ready."
    end

    local checked = 0
    local probe = GetRaceDebugProbeTexture()
    if not probe then
        return false, "Race icon check unavailable: unable to create probe texture."
    end

    local admin = ns.AdminCommands
    local previousDebugState = nil
    if admin and type(admin.IsRaceIconDebugEnabled) == "function" then
        previousDebugState = admin:IsRaceIconDebugEnabled()
    end
    if admin and type(admin.SetRaceIconDebugEnabled) == "function" then
        admin:SetRaceIconDebugEnabled(true)
    end

    for titleID, entry in log:Iterate() do
        checked = checked + 1
        local raceTag = entry and entry.raceTag or nil
        local sex = entry and entry.sex or nil

        -- Reuse the exact same resolution path as row/tile rendering so this
        -- check reflects live unresolved results one-to-one.
        ApplyRaceTexture(probe, nil, raceTag, sex)
    end

    if admin and type(admin.SetRaceIconDebugEnabled) == "function" then
        admin:SetRaceIconDebugEnabled(previousDebugState == true)
    end

    local payload = (ns.GetRaceIconDebugPayload and ns.GetRaceIconDebugPayload()) or ""
    local unresolved = 0
    if payload ~= "" then
        unresolved = select(2, payload:gsub("\n", "")) + 1
    end

    local summary = "Checked " .. tostring(checked) .. " spotted entries. Unresolved race icons: " .. tostring(unresolved) .. "."
    if unresolved == 0 then
        return true, summary .. "\nAll spotted race icon mappings resolved."
    end

    if payload ~= "" then
        return true, payload
    end

    return true, summary
end

local function BuildRaceInlineIconTag(raceTag, sex)
    local coords = GetRaceCoords(raceTag, sex)
    if coords then
        local left = math.floor((coords[1] or 0) * 256)
        local right = math.floor((coords[2] or 1) * 256)
        local top = math.floor((coords[3] or 0) * 256)
        local bottom = math.floor((coords[4] or 1) * 256)

        return string.format("|T%s:16:16:0:0:256:256:%d:%d:%d:%d|t ", RACE_ICON, left, right, top, bottom)
    end

    local icon = ResolveRaceFallbackIcon and ResolveRaceFallbackIcon(raceTag, sex) or nil

    if icon and icon ~= "" then
        return string.format("|T%s:16:16:0:0|t ", icon)
    end

    return ""
end

local RACE_ICON_TOKENS = {
    human = "Human",
    orc = "Orc",
    dwarf = "Dwarf",
    nightelf = "NightElf",
    undead = "Undead",
    tauren = "Tauren",
    gnome = "Gnome",
    troll = "Troll",
    goblin = "Goblin",
    bloodelf = "BloodElf",
    draenei = "Draenei",
    worgen = "Worgen",
    pandaren = "Pandaren",
    voidelf = "VoidElf",
    lightforgeddraenei = "LightforgedDraenei",
    highmountaintauren = "HighmountainTauren",
    nightborne = "Nightborne",
    magharorc = "MagharOrc",
    darkirondwarf = "DarkIronDwarf",
    zandalaritroll = "ZandalariTroll",
    kultiran = "KulTiran",
    mechagnome = "Mechagnome",
    vulpera = "Vulpera",
    dracthyr = "Dracthyr",
    earthen = "Earthen",
}

RACE_ICON_FALLBACKS = {}
for raceKey, token in pairs(RACE_ICON_TOKENS) do
    RACE_ICON_FALLBACKS[raceKey] = "Interface\\Icons\\Achievement_Character_" .. token .. "_Male"
end

RACE_ICON_ALIAS_TO_BASE = {
    scourge = "undead",
    forsaken = "undead",
    maghar = "magharorc",
    magharorc = "magharorc",
    zandalari = "zandalaritroll",
    kultiranhuman = "kultiran",
    kultiran = "kultiran",
    darkiron = "darkirondwarf",
    darkirondwarf = "darkirondwarf",
    lightforged = "lightforgeddraenei",
    lightforgeddraenei = "lightforgeddraenei",
    highmountain = "highmountaintauren",
    highmountaintauren = "highmountaintauren",
    voidelf = "voidelf",
    rendorei = "voidelf",
    dracthyr = "dracthyr",
    dracthyrvisage = "dracthyr",
    dracthyrhumanoid = "dracthyr",
    earthen = "earthen",
    haranir = "nightelf",
    harronir = "nightelf",
}

-- Every fallback icon follows Achievement_Character_<Race>_Male, so the
-- female set is derived rather than hand-duplicated.
RACE_ICON_FALLBACKS_FEMALE = {}
for raceKey, malePath in pairs(RACE_ICON_FALLBACKS) do
    RACE_ICON_FALLBACKS_FEMALE[raceKey] = (malePath:gsub("_Male$", "_Female"))
end

RACE_ICON_SPECIES_BASE_FALLBACK = {
    magharorc = "orc",
    darkirondwarf = "dwarf",
    highmountaintauren = "tauren",
    zandalaritroll = "troll",
    lightforgeddraenei = "draenei",
    voidelf = "bloodelf",
    nightborne = "nightelf",
    mechagnome = "gnome",
    kultiran = "human",
    earthen = "dwarf",
}

local RACE_SPELL_ICON_IDS = {
    human = 59752,
    dwarf = 20594,
    nightelf = 58984,
    gnome = 20589,
    draenei = 59545,
    worgen = 68992,
    orc = 20572,
    scourge = 7744,
    undead = 7744,
    tauren = 20549,
    troll = 26297,
    bloodelf = 50613,
    goblin = 69070,
    pandaren = 107079,
    dracthyr = 357214,
    voidelf = 256948,
    lightforgeddraenei = 255647,
    darkirondwarf = 265221,
    kultiran = 287712,
    mechagnome = 312924,
    nightborne = 260364,
    highmountaintauren = 255654,
    magharorc = 274738,
    zandalaritroll = 291944,
    vulpera = 312411,
    earthen = 436344,
    earthendwarf = 436344,
}

ResolveRaceSpellIcon = function(raceTag)
    local normalized = NormalizeRaceTagForLookup(raceTag)
    local variant = NormalizeRaceKeyVariant(normalized)

    local canonical = nil
    if normalized then
        canonical = RACE_ICON_ALIAS_TO_BASE[normalized]
    end
    if not canonical and variant then
        canonical = RACE_ICON_ALIAS_TO_BASE[variant]
    end

    local keys = { normalized, variant, canonical }
    for _, key in ipairs(keys) do
        local spellID = key and RACE_SPELL_ICON_IDS[key] or nil
        if spellID and GetSpellTexture then
            local icon = GetSpellTexture(spellID)
            if icon then
                return icon
            end
        end
    end

    return nil
end

RACE_GLUE_ICON_TOKENS = {
    human = { "human" },
    orc = { "orc" },
    dwarf = { "dwarf" },
    nightelf = { "nightelf" },
    undead = { "undead" },
    tauren = { "tauren" },
    gnome = { "gnome" },
    troll = { "troll" },
    goblin = { "goblin" },
    bloodelf = { "bloodelf" },
    draenei = { "draenei" },
    worgen = { "worgen" },
    pandaren = { "pandaren", "panda" },
    voidelf = { "voidelf" },
    lightforgeddraenei = { "lightforged" },
    highmountaintauren = { "highmountain" },
    nightborne = { "nightborne" },
    magharorc = { "maghar" },
    darkirondwarf = { "darkirondwarf" },
    zandalaritroll = { "zandalaritroll" },
    kultiran = { "kultiranhuman", "kultiran" },
    mechagnome = { "mechagnome" },
    vulpera = { "vulpera" },
    dracthyr = { "dracthyr", "dracthyr-visage" },
    earthen = { "earthen" },
    haranir = { "haranir" },
    harronir = { "haranir" },
}

TryApplyGlueRaceIcon = function(texture, raceTag, sex)
    if not texture then
        return false
    end

    local normalizedSex = NormalizeSexForLookup(sex)
    local sexSuffix = (normalizedSex == 3) and "female" or "male"
    local normalized = NormalizeRaceTagForLookup(raceTag)
    local variant = NormalizeRaceKeyVariant(normalized)

    local canonical = nil
    if normalized then
        canonical = RACE_ICON_ALIAS_TO_BASE[normalized]
    end
    if not canonical and variant then
        canonical = RACE_ICON_ALIAS_TO_BASE[variant]
    end

    local keys = { normalized, variant, canonical }
    local tried = {}

    for _, key in ipairs(keys) do
        if key and not tried[key] then
            tried[key] = true
            local tokens = RACE_GLUE_ICON_TOKENS[key]
            if tokens then
                for _, token in ipairs(tokens) do
                    local tokenTitle = token:gsub("^%l", string.upper)
                    local sexTitle = sexSuffix:gsub("^%l", string.upper)

                    if texture.SetAtlas then
                        local atlasCandidates = {
                            "ui-charactercreate-races_" .. token .. "-" .. sexSuffix,
                            "ui-charactercreate-races-" .. token .. "-" .. sexSuffix,
                            "charactercreate-races_" .. token .. "-" .. sexSuffix,
                            "charactercreate-races-" .. token .. "-" .. sexSuffix,
                            "ui-charactercreate-races_" .. tokenTitle .. "-" .. sexTitle,
                            "ui-charactercreate-races-" .. tokenTitle .. "-" .. sexTitle,
                            "charactercreate-races_" .. tokenTitle .. "-" .. sexTitle,
                            "charactercreate-races-" .. tokenTitle .. "-" .. sexTitle,
                        }

                        for _, atlasName in ipairs(atlasCandidates) do
                            if texture:SetAtlas(atlasName, true) then
                                return true
                            end
                        end
                    end

                    local candidates = {
                        "Interface\\Icons\\UI-CharacterCreate-Races_" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\CharacterCreate-Races_" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\UI-CharacterCreate-Races-" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\CharacterCreate-Races-" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\Ui-CharacterCreate-Races_" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\Ui-CharacterCreate-Races-" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\Charactercreate-races_" .. token .. "-" .. sexSuffix,
                        "Interface\\Icons\\Charactercreate-races-" .. token .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Races_" .. token .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Races-" .. token .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-Races_" .. token .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-Races-" .. token .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Races_" .. tokenTitle .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Races-" .. tokenTitle .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-Races_" .. tokenTitle .. "-" .. sexSuffix,
                        "Interface\\GLUES\\CHARACTERCREATE\\CharacterCreate-Races-" .. tokenTitle .. "-" .. sexSuffix,
                    }

                    for _, path in ipairs(candidates) do
                        if texture:GetTexture() ~= path then
                            texture:SetTexture(nil)
                            texture:SetTexture(path)
                        end
                        if texture:GetTexture() then
                            texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

ResolveRaceFallbackIcon = function(raceTag, sex)
    local normalizedSex = NormalizeSexForLookup(sex)
    local normalized = NormalizeRaceTagForLookup(raceTag)
    local variant = NormalizeRaceKeyVariant(normalized)
    local icon = nil

    if normalizedSex == 3 then
        icon = normalized and RACE_ICON_FALLBACKS_FEMALE[normalized] or nil
    end
    if not icon then
        icon = normalized and RACE_ICON_FALLBACKS[normalized] or nil
    end

    if not icon and variant and variant ~= normalized then
        icon = (normalizedSex == 3) and RACE_ICON_FALLBACKS_FEMALE[variant] or RACE_ICON_FALLBACKS[variant]
        if not icon and normalizedSex == 3 then
            icon = RACE_ICON_FALLBACKS[variant]
        end
    end

    local canonical = nil
    if not canonical and normalized then
        canonical = RACE_ICON_ALIAS_TO_BASE[normalized]
    end
    if not canonical and variant then
        canonical = RACE_ICON_ALIAS_TO_BASE[variant]
    end

    if canonical and not icon then
        icon = (normalizedSex == 3) and RACE_ICON_FALLBACKS_FEMALE[canonical] or RACE_ICON_FALLBACKS[canonical]
        if not icon and normalizedSex == 3 then
            icon = RACE_ICON_FALLBACKS[canonical]
        end
    end

    local species = nil
    if normalized then
        species = RACE_ICON_SPECIES_BASE_FALLBACK[normalized]
    end
    if not species and canonical then
        species = RACE_ICON_SPECIES_BASE_FALLBACK[canonical]
    end
    if not species and variant then
        species = RACE_ICON_SPECIES_BASE_FALLBACK[variant]
    end
    if species and not icon then
        icon = (normalizedSex == 3) and RACE_ICON_FALLBACKS_FEMALE[species] or RACE_ICON_FALLBACKS[species]
        if not icon and normalizedSex == 3 then
            icon = RACE_ICON_FALLBACKS[species]
        end
    end

    return icon
end

local function TrySetTexture(texture, path)
    if not texture or not path or path == "" then
        return false
    end

    if texture:GetTexture() == path then
        -- Already showing this exact texture (common on pooled rows/tiles
        -- across refreshes) — skip the SetTexture(nil)+SetTexture() reset.
        return true
    end

    texture:SetTexture(nil)
    texture:SetTexture(path)
    return texture:GetTexture() ~= nil
end

local function SetUnknownTexture(texture, blendTexture, sex)
    local normalizedSex = NormalizeSexForLookup(sex)

    if normalizedSex == 2 then
        if not TrySetTexture(texture, BODYTYPE_ICON_1) then
            if not TrySetTexture(texture, BODYTYPE_ICON_1_LEGACY) then
                TrySetTexture(texture, UNKNOWN_ICON)
            end
        end
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if blendTexture then blendTexture:Hide() end
        return true
    end

    if normalizedSex == 3 then
        if not TrySetTexture(texture, BODYTYPE_ICON_2) then
            if not TrySetTexture(texture, BODYTYPE_ICON_2_LEGACY) then
                TrySetTexture(texture, UNKNOWN_ICON)
            end
        end
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if blendTexture then blendTexture:Hide() end
        return true
    end

    local leftOK = TrySetTexture(texture, BODYTYPE_ICON_1) or TrySetTexture(texture, BODYTYPE_ICON_1_LEGACY)
    if not leftOK then
        TrySetTexture(texture, UNKNOWN_ICON)
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if blendTexture then blendTexture:Hide() end
        return true
    end

    texture:SetTexCoord(0.07, 0.50, 0.07, 0.93)
    if blendTexture then
        local rightOK = TrySetTexture(blendTexture, BODYTYPE_ICON_2) or TrySetTexture(blendTexture, BODYTYPE_ICON_2_LEGACY)
        if rightOK then
            blendTexture:SetTexCoord(0.50, 0.93, 0.07, 0.93)
            blendTexture:Show()
        else
            blendTexture:Hide()
        end
    end

    return true
end

ApplyRaceTexture = function(texture, blendTexture, raceTag, sex)
    if not texture then
        return false
    end

    if blendTexture then
        blendTexture:Hide()
    end

    local normalizedSex = NormalizeSexForLookup(sex)

    if not raceTag or raceTag == "" then
        return SetUnknownTexture(texture, blendTexture, sex)
    end

    local coords = normalizedSex and GetRaceCoords(raceTag, normalizedSex) or nil
    if coords then
        TrySetTexture(texture, RACE_ICON)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        return true
    end

    if TryApplyGlueRaceIcon(texture, raceTag, normalizedSex) then
        return true
    end

    local icon = ResolveRaceFallbackIcon(raceTag, normalizedSex)
    if icon then
        if TrySetTexture(texture, icon) then
            texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            return true
        end
    end

    local spellIcon = ResolveRaceSpellIcon(raceTag)
    if spellIcon and TrySetTexture(texture, spellIcon) then
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        return true
    end

    if IsRaceIconDebugEnabled() then
        local missKey = tostring(raceTag or "") .. "|" .. tostring(normalizedSex or sex or "")
        if not RACE_ICON_MISS_REPORTED[missKey] then
            RACE_ICON_MISS_REPORTED[missKey] = true
            AppendRaceIconDebugLine("Race icon unresolved for raceTag='" .. tostring(raceTag or "") .. "', sex='" .. tostring(sex or "") .. "'.")
        end
    end

    return SetUnknownTexture(texture, blendTexture, sex)
end

local function OpenSpottingSettings()
    if ns.Settings and ns.Settings.OpenSpottingSettings then
        ns.Settings:OpenSpottingSettings()
        return
    end

    local settings = _G.Settings
    if settings and settings.OpenToCategory and ns.Settings and ns.Settings.category then
        local category = ns.Settings.category
        local categoryID = (type(category) == "table" and category.GetID and category:GetID()) or category.ID or category
        settings.OpenToCategory(categoryID)
        return
    end

    if _G.InterfaceOptionsFrame_OpenToCategory and ns.Settings and ns.Settings.panel then
        _G.InterfaceOptionsFrame_OpenToCategory(ns.Settings.panel)
        _G.InterfaceOptionsFrame_OpenToCategory(ns.Settings.panel)
    end
end

local function SkinEpithetButton(button)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
    button.bg = bg

    local top = button:CreateTexture(nil, "BORDER")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetColorTexture(0.49, 0.37, 0.15, 1.0)

    local bottom = button:CreateTexture(nil, "BORDER")
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetColorTexture(0.49, 0.37, 0.15, 1.0)

    local left = button:CreateTexture(nil, "BORDER")
    left:SetWidth(1)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetColorTexture(0.49, 0.37, 0.15, 1.0)

    local right = button:CreateTexture(nil, "BORDER")
    right:SetWidth(1)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetColorTexture(0.49, 0.37, 0.15, 1.0)

    button.borders = { top, bottom, left, right }

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetTextColor(0.91, 0.78, 0.45)
    button.label = label

    button:SetScript("OnEnter", function(self_)
        if self_.selected then return end
        self_.bg:SetColorTexture(0.16, 0.12, 0.07, 1.0)
        self_.label:SetTextColor(0.96, 0.89, 0.65)
        for _, border in ipairs(self_.borders) do
            border:SetColorTexture(0.91, 0.78, 0.45, 1.0)
        end
    end)

    button:SetScript("OnLeave", function(self_)
        if self_.selected then return end
        self_.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
        self_.label:SetTextColor(0.91, 0.78, 0.45)
        for _, border in ipairs(self_.borders) do
            border:SetColorTexture(0.49, 0.37, 0.15, 1.0)
        end
    end)
end

local function SetButtonSelected(button, selected)
    if not button then return end
    button.selected = selected and true or false
    if button.selected then
        button.bg:SetColorTexture(0.20, 0.15, 0.08, 1.0)
        button.label:SetTextColor(1.0, 0.92, 0.70)
        for _, border in ipairs(button.borders) do
            border:SetColorTexture(0.95, 0.82, 0.48, 1.0)
        end
    else
        button.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
        button.label:SetTextColor(0.91, 0.78, 0.45)
        for _, border in ipairs(button.borders) do
            border:SetColorTexture(0.49, 0.37, 0.15, 1.0)
        end
    end
end

local function CreateChromePanel(mainFrame)
    local panel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -40)
    panel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel((mainFrame:GetFrameLevel() or 1) + 200)
    panel:EnableMouse(true)
    panel:SetBackdrop(STANDARD_BACKDROP)

    if T and T.col then
        panel:SetBackdropColor(T.col.bg0.r, T.col.bg0.g, T.col.bg0.b, 1.0)
        panel:SetBackdropBorderColor(T.col.line.r, T.col.line.g, T.col.line.b, 0.8)
    else
        panel:SetBackdropColor(0.08, 0.06, 0.03, 1.0)
        panel:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.8)
    end
    panel:Hide()

    return panel
end

local function CreateCloseButton(panel, onClick)
    local close = CreateFrame("Button", nil, panel)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -10, -10)
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetScale(2)
    closeText:SetTextColor(0.95, 0.90, 0.75)
    close:SetScript("OnClick", onClick)
    return close
end

-- Shared by the list/grid scroll areas in the log panel and the achievements
-- grid: mouse-wheel scrolling clamped to the content's actual height.
local function AttachWheelScroll(scrollFrame, contentFrame, step)
    scrollFrame:SetScript("OnMouseWheel", function(self_, delta)
        local current = self_:GetVerticalScroll() or 0
        local maxScroll = math.max(0, (contentFrame:GetHeight() or 0) - (self_:GetHeight() or 0))
        if delta > 0 then
            self_:SetVerticalScroll(math.max(0, current - step))
        else
            self_:SetVerticalScroll(math.min(maxScroll, current + step))
        end
    end)
end

-- Keeps a scroll child's width in sync with its (resizable) container.
local function AttachContentWidthSync(sizingFrame, contentFrame, onResized)
    sizingFrame:SetScript("OnSizeChanged", function(self_)
        local width = math.max(1, (self_:GetWidth() or 0) - 8)
        contentFrame:SetWidth(width)
        if onResized then
            onResized()
        end
    end)
end

-- Info/meta banners size themselves to fit their (localized, variable-length)
-- title + body text, never shrinking below minHeight.
local function ApplyMeasuredBannerHeight(wrap, titleFS, textFS, minHeight)
    local measured = math.ceil((titleFS:GetStringHeight() or 0) + 8 + (textFS:GetStringHeight() or 0) + 16)
    wrap:SetHeight(math.max(minHeight, measured))
end

local function FormatAchievementEarnedText(earnedText)
    return (L and L["SPOT_ACHV_EARNED_FMT"] and string.format(L["SPOT_ACHV_EARNED_FMT"], earnedText)) or ("Earned " .. earnedText)
end

-- Shared between the list row and grid tile widgets (both expose the same
-- .state/.portrait/.race/.raceBlend fields) so the spotted/unspotted icon
-- state isn't hand-duplicated per view.
local function ApplySpottedStateIcons(widget, data)
    if data.isSpotted then
        TrySetTexture(widget.state, CHECK_ICON)
        widget.state:SetVertexColor(0.90, 0.74, 0.30, 1.0)

        local classCoords = GetClassCoords(data.log and data.log.classTag)
        if classCoords then
            widget.portrait:SetTexCoord(classCoords[1], classCoords[2], classCoords[3], classCoords[4])
            widget.portrait:Show()
        else
            widget.portrait:Hide()
        end

        if ApplyRaceTexture(widget.race, widget.raceBlend, data.log and data.log.raceTag, data.log and data.log.sex) then
            widget.race:Show()
        else
            widget.race:Hide()
            if widget.raceBlend then widget.raceBlend:Hide() end
        end
    else
        TrySetTexture(widget.state, LOCK_ICON)
        widget.state:SetVertexColor(0.56, 0.52, 0.45, 1.0)
        widget.portrait:Hide()
        widget.race:Hide()
        if widget.raceBlend then widget.raceBlend:Hide() end
    end
end

function LogbookUI:LoadPrefs()
    local social = GetSocialProfile()
    local view = social and social.spotLogView or "grid"
    local scope = social and social.spotLogScope or "spotted"
    local achvFilter = social and social.spotAchvFilter or "all"

    if view ~= "list" and view ~= "grid" then
        view = "grid"
    end
    if scope ~= "spotted" and scope ~= "remaining" then
        scope = "spotted"
    end
    if achvFilter ~= "all" and achvFilter ~= "unearned" then
        achvFilter = "all"
    end
    self.viewMode = view
    self.scopeMode = scope
    self.achievementFilterMode = achvFilter
end

function LogbookUI:SavePrefs()
    local social = GetSocialProfile()
    if not social then return end
    social.spotLogView = self.viewMode or "list"
    social.spotLogScope = self.scopeMode or "spotted"
    social.spotAchvFilter = self.achievementFilterMode or "all"
end

function LogbookUI:Init(mainFrame)
    if self.initialized then return end
    self.initialized = true
    self.mainFrame = mainFrame

    self:LoadPrefs()
    self.shoutCycleIndex = 1
    self:CreateButton(mainFrame)
    self:CreatePanel(mainFrame)
    self:CreateAchievementsPanel(mainFrame)
    self:RefreshButton()
end

function LogbookUI:CreateButton(mainFrame)
    local header = mainFrame and mainFrame.Header
    if not header then return end

    local achButton = CreateFrame("Button", nil, header)
    achButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -8, -8)
    achButton:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -8, 8)
    achButton:RegisterForClicks("LeftButtonUp")
    SkinEpithetButton(achButton)
    achButton.label:SetText("")

    local spotButton = CreateFrame("Button", nil, header)
    spotButton:SetPoint("TOPRIGHT", achButton, "TOPLEFT", -6, 0)
    spotButton:SetPoint("BOTTOMRIGHT", achButton, "BOTTOMLEFT", -6, 0)
    spotButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    SkinEpithetButton(spotButton)
    spotButton.label:SetText("")

    local function SyncHeaderButtonsSize()
        local h = spotButton:GetHeight() or 0
        if h <= 0 and header.GetHeight then
            h = math.max(0, (header:GetHeight() or 0) - 16)
        end
        if h > 0 then
            spotButton:SetWidth(h)
            achButton:SetWidth(h)
        end
    end

    header:HookScript("OnSizeChanged", SyncHeaderButtonsSize)
    spotButton:HookScript("OnShow", SyncHeaderButtonsSize)
    achButton:HookScript("OnShow", SyncHeaderButtonsSize)

    local spotIcon = spotButton:CreateTexture(nil, "ARTWORK")
    spotIcon:SetPoint("TOPLEFT", spotButton, "TOPLEFT", 4, -4)
    spotIcon:SetPoint("BOTTOMRIGHT", spotButton, "BOTTOMRIGHT", -4, 4)
    spotIcon:SetTexture(BINOCULARS_ICON)
    spotIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    spotIcon:SetVertexColor(0.86, 0.74, 0.40, 0.95)
    spotButton.icon = spotIcon

    local achIcon = achButton:CreateTexture(nil, "ARTWORK")
    achIcon:SetPoint("TOPLEFT", achButton, "TOPLEFT", 4, -4)
    achIcon:SetPoint("BOTTOMRIGHT", achButton, "BOTTOMRIGHT", -4, 4)
    achIcon:SetTexture(ACHIEVEMENTS_LOG_ICON)
    achIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    achIcon:SetVertexColor(0.86, 0.74, 0.40, 0.95)
    achButton.icon = achIcon

    spotButton:SetScript("OnClick", function(_, mouseButton)
        local count = ns.SpottingLog and ns.SpottingLog.Count and ns.SpottingLog:Count() or 0
        if mouseButton == "RightButton" then
            local fmt, idx = GetShoutFormatByIndex(self.shoutCycleIndex)
            if _G and _G.SendChatMessage then
                _G.SendChatMessage(string.format(fmt, count), "SAY")
            end
            self.shoutCycleIndex = (idx % #SHOUT_FORMAT_KEYS) + 1
            return
        end

        self:Toggle()
    end)
    spotButton:SetScript("OnEnter", function(self_)
        spotIcon:SetVertexColor(1.0, 0.9, 0.55, 1.0)
        GameTooltip:SetOwner(self_, "ANCHOR_BOTTOMRIGHT")
        local count = ns.SpottingLog and ns.SpottingLog.Count and ns.SpottingLog:Count() or 0
        GameTooltip:SetText((L and L["SPOTTING_LOG_TOOLTIP"] and string.format(L["SPOTTING_LOG_TOOLTIP"], count)) or ("Spotting Log (" .. count .. " found)"), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L and L["SPOTTING_LOG_TOOLTIP_LEFT"]) or "Left-click: Open title spotting log.", 0.85, 0.82, 0.72, true)
        GameTooltip:AddLine((L and L["SPOTTING_LOG_TOOLTIP_RIGHT"]) or "Right-click: Shout your spotting stats in /s.", 0.85, 0.82, 0.72, true)
        GameTooltip:Show()
    end)
    spotButton:SetScript("OnLeave", function()
        spotIcon:SetVertexColor(0.86, 0.74, 0.40, 0.95)
        GameTooltip:Hide()
    end)

    achButton:SetScript("OnClick", function()
        self:ShowAchievements()
    end)
    achButton:SetScript("OnEnter", function(self_)
        achIcon:SetVertexColor(1.0, 0.9, 0.55, 1.0)
        GameTooltip:SetOwner(self_, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText((L and L["SPOT_ACHV_TOOLTIP"]) or "Open Epithet achievements.", 1, 1, 1)
        GameTooltip:AddLine((L and L["SPOT_ACHV_TOOLTIP_LEFT"]) or "Left-click: Open achievements.", 0.85, 0.82, 0.72, true)
        GameTooltip:Show()
    end)
    achButton:SetScript("OnLeave", function()
        achIcon:SetVertexColor(0.86, 0.74, 0.40, 0.95)
        GameTooltip:Hide()
    end)

    -- Ensure square sizing is correct immediately on creation.
    SyncHeaderButtonsSize()

    self.button = spotButton
    self.achievementButton = achButton
end

function LogbookUI:CreateModeButton(parent, text, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(82, 22)
    SkinEpithetButton(button)
    button.label:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

function LogbookUI:EnsureTransferModal()
    if self.transferModal then
        return self.transferModal
    end

    local panel = self.panel
    if not panel then return nil end

    local modal = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    modal:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -92)
    modal:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -24, 24)
    -- Keep modal at least on the same strata as the parent panel so it cannot
    -- render behind it when opened from the toolbar buttons.
    modal:SetFrameStrata(panel:GetFrameStrata() or "FULLSCREEN_DIALOG")
    modal:SetFrameLevel((panel:GetFrameLevel() or 1) + 50)
    modal:EnableMouse(true)
    modal:SetBackdrop(STANDARD_BACKDROP)
    modal:SetBackdropColor(0.06, 0.05, 0.03, 0.98)
    modal:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.95)
    modal:Hide()

    local heading = modal:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("TOPLEFT", 12, -10)
    heading:SetPoint("TOPRIGHT", -12, -10)
    heading:SetJustifyH("LEFT")
    modal.heading = heading

    local note = modal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -6)
    note:SetPoint("TOPRIGHT", -12, -6)
    note:SetJustifyH("LEFT")
    note:SetText((L and L["SPOTTING_TRANSFER_NOTE"]) or "Copy/paste the payload below.")
    modal.note = note

    local editorWrap = CreateFrame("Frame", nil, modal, "BackdropTemplate")
    editorWrap:SetPoint("TOPLEFT", modal, "TOPLEFT", 12, -48)
    editorWrap:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -32, 48)
    editorWrap:SetBackdrop(STANDARD_BACKDROP)
    editorWrap:SetBackdropColor(0.08, 0.07, 0.05, 1.0)
    editorWrap:SetBackdropBorderColor(0.40, 0.34, 0.22, 0.95)

    local scroll = CreateFrame("ScrollFrame", nil, editorWrap, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", editorWrap, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", editorWrap, "BOTTOMRIGHT", -26, 4)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetWidth(520)
    edit:SetHeight(180)
    edit:SetScript("OnEscapePressed", function() modal:Hide() end)
    scroll:SetScrollChild(edit)

    local function ResizeTransferEditor()
        local wrapW = editorWrap:GetWidth() or 0
        local wrapH = editorWrap:GetHeight() or 0
        local minW = math.max(520, wrapW - 40)
        local minH = math.max(140, wrapH - 10)
        if (edit:GetWidth() or 0) < minW then
            edit:SetWidth(minW)
        end
        edit:SetHeight(minH)
    end

    editorWrap:SetScript("OnMouseDown", function()
        edit:SetFocus()
    end)
    editorWrap:SetScript("OnSizeChanged", ResizeTransferEditor)
    ResizeTransferEditor()

    local primary = CreateFrame("Button", nil, modal)
    primary:SetSize(120, 24)
    primary:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -12, 12)
    SkinEpithetButton(primary)
    modal.primaryButton = primary

    local secondary = CreateFrame("Button", nil, modal)
    secondary:SetSize(120, 24)
    secondary:SetPoint("RIGHT", primary, "LEFT", -8, 0)
    SkinEpithetButton(secondary)
    secondary.label:SetText((L and L["SPOTTING_TRANSFER_CLOSE"]) or "Close")
    secondary:SetScript("OnClick", function() modal:Hide() end)

    modal.scroll = scroll
    modal.edit = edit
    self.transferModal = modal
    return modal
end

function LogbookUI:OpenExportModal()
    local modal = self:EnsureTransferModal()
    if not modal then return end

    local payload = (ns.SpottingLog and ns.SpottingLog.Export and ns.SpottingLog:Export()) or ""
    modal.heading:SetText((L and L["SPOTTING_EXPORT_TITLE"]) or "Export Spotting Log")
    modal.primaryButton.label:SetText((L and L["SPOTTING_TRANSFER_COPY"]) or "Select All")
    modal.primaryButton:SetScript("OnClick", function()
        modal.edit:HighlightText(0, -1)
        modal.edit:SetFocus()
    end)

    modal.edit:SetText(payload)
    modal:Show()
    -- Apply focus only after the modal is visible so keybinds (e.g. "C") do
    -- not win over copy shortcuts when exporting.
    modal.edit:SetFocus()
    modal.edit:HighlightText(0, -1)
end

function LogbookUI:OpenImportModal()
    local modal = self:EnsureTransferModal()
    if not modal then return end

    modal.heading:SetText((L and L["SPOTTING_IMPORT_TITLE"]) or "Import Spotting Log")
    modal.primaryButton.label:SetText((L and L["SPOTTING_TRANSFER_IMPORT"]) or "Import")
    modal.primaryButton:SetScript("OnClick", function()
        local text = modal.edit:GetText() or ""
        local ok, changed, err = false, 0, "Import unavailable"
        if ns.SpottingLog and ns.SpottingLog.Import then
            ok, changed, err = ns.SpottingLog:Import(text)
        end
        if ok then
            if ns.Print then
                ns.Print((L and L["SPOTTING_IMPORT_SUCCESS_FMT"] and string.format(L["SPOTTING_IMPORT_SUCCESS_FMT"], changed or 0)) or ("Imported " .. tostring(changed or 0) .. " spotting entries."))
            end
            if ns.SpottingAchievements and ns.SpottingAchievements.Evaluate then
                ns.SpottingAchievements:Evaluate()
            end
            modal:Hide()
            self:Refresh()
            self:RefreshButton()
        else
            if ns.Print then
                ns.Print((L and L["SPOTTING_IMPORT_FAILED_FMT"] and string.format(L["SPOTTING_IMPORT_FAILED_FMT"], err or "Unknown error")) or ("Import failed: " .. tostring(err or "Unknown error")))
            end
        end
    end)

    modal.edit:SetText("")
    modal.edit:SetFocus()
    modal:Show()
end

function LogbookUI:OpenRaceIconDebugModal()
    local payload = (ns.GetRaceIconDebugPayload and ns.GetRaceIconDebugPayload()) or "(No unresolved race icon entries captured yet.)"
    if ns and type(ns.OpenDebugTextModal) == "function" then
        return ns.OpenDebugTextModal("Race Icon Debug Log", payload, "Copy the unresolved race icon entries below.")
    end
    return false, "Global debug modal is unavailable."
end

function LogbookUI:OpenDebugTextModal(title, payload, note)
    if not self.panel then
        return false, "Spotting UI is not initialized yet."
    end

    if not self.panel:IsShown() then
        self:Show()
    end

    local modal = self:EnsureTransferModal()
    if not modal then
        return false, "Unable to open debug modal."
    end

    if modal.note then
        modal.note:SetText(note or "Copy/paste the payload below.")
    end

    modal.heading:SetText(title or "Debug Output")
    modal.primaryButton.label:SetText("Select All")
    modal.primaryButton:SetScript("OnClick", function()
        modal.edit:HighlightText(0, -1)
        modal.edit:SetFocus()
    end)

    modal.edit:SetText(payload or "")
    modal:Show()
    modal.edit:SetFocus()
    modal.edit:HighlightText(0, -1)

    return true
end

function LogbookUI:CreatePanel(mainFrame)
    local panel = CreateChromePanel(mainFrame)

    local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 14, -12)
    heading:SetText(L and L["SPOTTING_LOG_HEADING"] or "Spotting Log")
    self.heading = heading

    local countText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    countText:SetPoint("TOPRIGHT", -36, -16)
    countText:SetJustifyH("RIGHT")
    self.countText = countText

    CreateCloseButton(panel, function() self:Hide() end)

    local controlsRow = CreateFrame("Frame", nil, panel)
    controlsRow:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -38)
    controlsRow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -38)
    controlsRow:SetHeight(24)

    local spottedBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_SCOPE_SPOTTED"]) or "Spotted", function()
        self.scopeMode = "spotted"
        self:SavePrefs()
        self:Refresh()
    end)
    spottedBtn:SetPoint("LEFT", controlsRow, "LEFT", 0, 0)

    local remainingBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_SCOPE_REMAINING"]) or "Remaining", function()
        self.scopeMode = "remaining"
        self:SavePrefs()
        self:Refresh()
    end)
    remainingBtn:SetPoint("LEFT", spottedBtn, "RIGHT", 6, 0)

    local viewSep = panel:CreateTexture(nil, "BORDER")
    viewSep:SetWidth(1)
    viewSep:SetHeight(18)
    viewSep:SetPoint("LEFT", remainingBtn, "RIGHT", 9, 0)
    viewSep:SetColorTexture(0.55, 0.45, 0.26, 0.7)

    local listBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_VIEW_LIST"]) or "List", function()
        self.viewMode = "list"
        self:SavePrefs()
        self:Refresh()
    end)
    listBtn:SetPoint("LEFT", viewSep, "RIGHT", 9, 0)

    local gridBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_VIEW_GRID"]) or "Grid", function()
        self.viewMode = "grid"
        self:SavePrefs()
        self:Refresh()
    end)
    gridBtn:SetPoint("LEFT", listBtn, "RIGHT", 6, 0)

    local importBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_IMPORT_BUTTON"]) or "Import", function()
        self:OpenImportModal()
    end)
    importBtn:SetPoint("RIGHT", controlsRow, "RIGHT", 0, 0)

    local exportBtn = self:CreateModeButton(controlsRow, (L and L["SPOTTING_EXPORT_BUTTON"]) or "Export", function()
        self:OpenExportModal()
    end)
    exportBtn:SetPoint("RIGHT", importBtn, "LEFT", -6, 0)

    local infoWrap = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    infoWrap:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -70)
    infoWrap:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -70)
    infoWrap:SetHeight(62)
    infoWrap:SetBackdrop(STANDARD_BACKDROP)
    infoWrap:SetBackdropColor(0.09, 0.07, 0.04, 0.95)
    infoWrap:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.65)

    local infoTitle = infoWrap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    infoTitle:SetPoint("TOPLEFT", infoWrap, "TOPLEFT", 10, -8)
    infoTitle:SetPoint("TOPRIGHT", infoWrap, "TOPRIGHT", -10, -8)
    infoTitle:SetJustifyH("LEFT")
    infoTitle:SetText((L and L["SPOTTING_META_TITLE"]) or "Spotting Meta-Game (Completely Normal Behavior)")

    local infoText = infoWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    infoText:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 0, -8)
    infoText:SetPoint("TOPRIGHT", infoWrap, "TOPRIGHT", -10, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetJustifyV("TOP")
    infoText:SetText((L and L["SPOTTING_META_DESC"]) or "Totally normal activity: click players, target strangers, and quietly evaluate their title choices for science. First-spot unique titles to fill your log, then chase meta achievements across rarity, classes, zones, and repeat sightings. Completionists may experience a powerful urge to inspect absolutely everyone in sight. This is expected.")

    ApplyMeasuredBannerHeight(infoWrap, infoTitle, infoText, 62)

    local divider = panel:CreateTexture(nil, "BORDER")
    divider:SetPoint("TOPLEFT", infoWrap, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("TOPRIGHT", infoWrap, "BOTTOMRIGHT", 0, -8)
    divider:SetHeight(1)
    divider:SetColorTexture(0.55, 0.45, 0.26, 0.35)

    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -6)
    contentArea:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 12)

    local listWrap = CreateFrame("Frame", nil, contentArea)
    listWrap:SetAllPoints(contentArea)

    local listScroll = CreateFrame("ScrollFrame", nil, listWrap, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", listWrap, "TOPLEFT", 0, 0)
    listScroll:SetPoint("BOTTOMRIGHT", listWrap, "BOTTOMRIGHT", 0, 0)
    listScroll:EnableMouseWheel(true)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetPoint("TOPLEFT", listScroll, "TOPLEFT", 0, 0)
    listContent:SetPoint("TOPRIGHT", listScroll, "TOPRIGHT", 0, 0)
    listContent:SetWidth(math.max(1, (listWrap:GetWidth() or 0) - 8))
    listContent:SetHeight(1)
    listScroll:SetScrollChild(listContent)

    AttachContentWidthSync(listWrap, listContent)
    AttachWheelScroll(listScroll, listContent, 32)

    local gridWrap = CreateFrame("Frame", nil, contentArea)
    gridWrap:SetAllPoints(contentArea)

    local gridScroll = CreateFrame("ScrollFrame", nil, gridWrap, "UIPanelScrollFrameTemplate")
    gridScroll:SetPoint("TOPLEFT", gridWrap, "TOPLEFT", 0, 0)
    gridScroll:SetPoint("BOTTOMRIGHT", gridWrap, "BOTTOMRIGHT", 0, 0)
    gridScroll:EnableMouseWheel(true)

    local gridContent = CreateFrame("Frame", nil, gridScroll)
    gridContent:SetPoint("TOPLEFT", gridScroll, "TOPLEFT", 0, 0)
    gridContent:SetWidth(math.max(1, (gridWrap:GetWidth() or 0) - 8))
    gridContent:SetHeight(1)
    gridScroll:SetScrollChild(gridContent)

    AttachContentWidthSync(gridWrap, gridContent)
    AttachWheelScroll(gridScroll, gridContent, 48)

    local empty = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    empty:SetPoint("CENTER", panel, "CENTER", 0, -12)
    empty:SetPoint("LEFT", panel, "LEFT", 60, 0)
    empty:SetPoint("RIGHT", panel, "RIGHT", -60, 0)
    empty:SetJustifyH("CENTER")
    empty:SetText(L and L["SPOTTING_LOG_EMPTY"] or "Nothing spotted yet. Target players in the wild to log the titles they are wearing.")
    empty:Hide()

    local gated = CreateFrame("Frame", nil, panel)
    gated:SetAllPoints(panel)
    gated:Hide()

    local gatedText = gated:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    gatedText:SetPoint("CENTER", gated, "CENTER", 0, 8)
    gatedText:SetPoint("LEFT", gated, "LEFT", 70, 0)
    gatedText:SetPoint("RIGHT", gated, "RIGHT", -70, 0)
    gatedText:SetJustifyH("CENTER")
    gatedText:SetText(L and L["SPOTTING_LOG_GATED"] or "Title spotting is off. Sightings are not being recorded.")
    local gatedWarnCol = (T and T.col and T.col.warn) or { r = 0.851, g = 0.541, b = 0.322 }
    gatedText:SetTextColor(gatedWarnCol.r, gatedWarnCol.g, gatedWarnCol.b)

    local settingsButton = CreateFrame("Button", nil, gated)
    settingsButton:SetSize(170, 24)
    settingsButton:SetPoint("TOP", gatedText, "BOTTOM", 0, -12)
    SkinEpithetButton(settingsButton)
    settingsButton.label:SetText(L and L["SPOTTING_LOG_OPEN_SETTINGS"] or "Enable in Settings")
    settingsButton:SetScript("OnClick", function()
        OpenSpottingSettings()
    end)

    panel:SetScript("OnShow", function()
        self:Refresh()
    end)

    panel:SetScript("OnHide", function()
        if self.transferModal and self.transferModal.Hide then
            self.transferModal:Hide()
        end
    end)

    -- No OnUpdate poll for the enabled/disabled state: the only place that
    -- toggles it (Core/Settings.lua's "Enable title spotting" checkbox)
    -- already calls LogbookUI:HandleSpottingStateChanged() synchronously.

    self.panel = panel
    self.scopeSpottedBtn = spottedBtn
    self.scopeRemainingBtn = remainingBtn
    self.viewListBtn = listBtn
    self.viewGridBtn = gridBtn
    self.metaGameInfo = infoWrap
    self.listWrap = listWrap
    self.listScroll = listScroll
    self.listContent = listContent
    self.gridWrap = gridWrap
    self.gridScroll = gridScroll
    self.gridContent = gridContent
    self.emptyState = empty
    self.gatedState = gated
    self.rows = {}
    self.tiles = {}
    self.entries = {}
end

function LogbookUI:Toggle()
    if not self.panel then return end
    if self.panel:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function LogbookUI:Show()
    if not self.panel then return end
    if self.achievementPanel and self.achievementPanel:IsShown() then
        self:CloseAchievementDetail()
        self.achievementPanel:Hide()
    end
    self.panel:Raise()
    self.panel:Show()
    self:Refresh()
end

function LogbookUI:ShowAchievements()
    if not self.achievementPanel then return end
    if self.panel and self.panel:IsShown() then
        self.panel:Hide()
    end
    self.achievementPanel:Raise()
    self.achievementPanel:Show()
    self:RefreshAchievements()
end

function LogbookUI:Hide()
    self:CloseAchievementDetail()
    if self.panel then
        self.panel:Hide()
    end
    if self.achievementPanel then
        self.achievementPanel:Hide()
    end
end

function LogbookUI:CreateAchievementsPanel(mainFrame)
    local panel = CreateChromePanel(mainFrame)

    local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 14, -12)
    heading:SetText((L and L["SPOT_ACHV_HEADING"]) or "Epithet Achievements")

    local countText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    countText:SetPoint("TOPRIGHT", -36, -16)
    countText:SetJustifyH("RIGHT")

    CreateCloseButton(panel, function() self:Hide() end)

    local controlsRow = CreateFrame("Frame", nil, panel)
    controlsRow:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -42)
    controlsRow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -42)
    controlsRow:SetHeight(24)

    local allBtn = self:CreateModeButton(controlsRow, (L and L["STATUS_ALL"]) or "All", function()
        self.achievementFilterMode = "all"
        self:SavePrefs()
        self:RefreshAchievements()
    end)
    allBtn:SetSize(72, 22)
    allBtn:SetPoint("LEFT", controlsRow, "LEFT", 0, 0)

    local unearnedBtn = self:CreateModeButton(controlsRow, (L and L["STATUS_UNEARNED"]) or "Unearned", function()
        self.achievementFilterMode = "unearned"
        self:SavePrefs()
        self:RefreshAchievements()
    end)
    unearnedBtn:SetSize(88, 22)
    unearnedBtn:SetPoint("LEFT", allBtn, "RIGHT", 6, 0)

    local divider = panel:CreateTexture(nil, "BORDER")
    divider:SetPoint("TOPLEFT", controlsRow, "BOTTOMLEFT", -2, -8)
    divider:SetPoint("TOPRIGHT", controlsRow, "BOTTOMRIGHT", 2, -8)
    divider:SetHeight(1)
    divider:SetColorTexture(0.55, 0.45, 0.26, 0.35)

    local metaWrap = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    metaWrap:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8)
    metaWrap:SetPoint("TOPRIGHT", divider, "BOTTOMRIGHT", 0, -8)
    metaWrap:SetHeight(58)
    metaWrap:SetBackdrop(STANDARD_BACKDROP)
    metaWrap:SetBackdropColor(0.09, 0.07, 0.04, 0.95)
    metaWrap:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.65)

    local metaTitle = metaWrap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    metaTitle:SetPoint("TOPLEFT", metaWrap, "TOPLEFT", 10, -8)
    metaTitle:SetPoint("TOPRIGHT", metaWrap, "TOPRIGHT", -10, -8)
    metaTitle:SetJustifyH("LEFT")
    metaTitle:SetText((L and L["SPOT_ACHV_META_TITLE"]) or "Achievement Hunting Notes")

    local metaText = metaWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    metaText:SetPoint("TOPLEFT", metaTitle, "BOTTOMLEFT", 0, -8)
    metaText:SetPoint("TOPRIGHT", metaWrap, "TOPRIGHT", -10, 0)
    metaText:SetJustifyH("LEFT")
    metaText:SetJustifyV("TOP")
    metaText:SetText((L and L["SPOT_ACHV_META_DESC"]) or "To complete every achievement, you may need to coordinate your spotting across classes, factions, calendar windows, and repeated sightings with friends or guildmates.")

    ApplyMeasuredBannerHeight(metaWrap, metaTitle, metaText, 58)

    local contentDivider = panel:CreateTexture(nil, "BORDER")
    contentDivider:SetPoint("TOPLEFT", metaWrap, "BOTTOMLEFT", 0, -8)
    contentDivider:SetPoint("TOPRIGHT", metaWrap, "BOTTOMRIGHT", 0, -8)
    contentDivider:SetHeight(1)
    contentDivider:SetColorTexture(0.55, 0.45, 0.26, 0.35)

    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", contentDivider, "BOTTOMLEFT", 0, -6)
    contentArea:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 12)

    local gridScroll = CreateFrame("ScrollFrame", nil, contentArea, "UIPanelScrollFrameTemplate")
    gridScroll:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    gridScroll:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    gridScroll:EnableMouseWheel(true)

    local gridContent = CreateFrame("Frame", nil, gridScroll)
    gridContent:SetPoint("TOPLEFT", gridScroll, "TOPLEFT", 0, 0)
    gridContent:SetWidth(math.max(1, (contentArea:GetWidth() or 0) - 8))
    gridContent:SetHeight(1)
    gridScroll:SetScrollChild(gridContent)

    AttachContentWidthSync(contentArea, gridContent, function()
        if panel:IsShown() then
            self:RefreshAchievements()
        end
    end)
    AttachWheelScroll(gridScroll, gridContent, 32)

    local empty = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    empty:SetPoint("CENTER", panel, "CENTER", 0, -12)
    empty:SetPoint("LEFT", panel, "LEFT", 60, 0)
    empty:SetPoint("RIGHT", panel, "RIGHT", -60, 0)
    empty:SetJustifyH("CENTER")
    empty:SetText((L and L["SPOT_ACHV_EMPTY"]) or "No achievements available.")
    empty:Hide()

    panel:SetScript("OnShow", function()
        self:RefreshAchievements()
    end)

    panel:SetScript("OnHide", function()
        local overlay = self.achievementDetailOverlay
        if not overlay then
            return
        end
        if overlay.animIn and overlay.animIn.IsPlaying and overlay.animIn:IsPlaying() then
            overlay.animIn:Stop()
        end
        if overlay.shineGroup and overlay.shineGroup.IsPlaying and overlay.shineGroup:IsPlaying() then
            overlay.shineGroup:Stop()
        end
        if overlay.iconPulse and overlay.iconPulse.IsPlaying and overlay.iconPulse:IsPlaying() then
            overlay.iconPulse:Stop()
        end
        overlay:EnableMouse(false)
        overlay:Hide()
    end)

    self:EnsureAchievementDetailOverlay()

    self.achievementPanel = panel
    self.achievementHeading = heading
    self.achievementMetaWrap = metaWrap
    self.achievementMetaTitle = metaTitle
    self.achievementMetaText = metaText
    self.achievementControlsRow = controlsRow
    self.achievementFilterAllBtn = allBtn
    self.achievementFilterUnearnedBtn = unearnedBtn
    self.achievementCountText = countText
    self.achievementGridScroll = gridScroll
    self.achievementGridContent = gridContent
    self.achievementEmptyState = empty
    self.achievementTiles = {}
    self.achievementEntries = {}
end

function LogbookUI:RefreshAchievementFilterButtons()
    if not self.achievementFilterAllBtn or not self.achievementFilterUnearnedBtn then
        return
    end

    local mode = self.achievementFilterMode or "all"
    SetButtonSelected(self.achievementFilterAllBtn, mode == "all")
    SetButtonSelected(self.achievementFilterUnearnedBtn, mode == "unearned")
end

function LogbookUI:EnsureAchievementDetailOverlay()
    if self.achievementDetailOverlay then
        return self.achievementDetailOverlay
    end
    if not self.achievementPanel then
        return nil
    end

    local overlay = CreateFrame("Frame", nil, self.achievementPanel, "BackdropTemplate")
    overlay:SetPoint("TOPLEFT", self.achievementPanel, "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", self.achievementPanel, "BOTTOMRIGHT", 0, 0)
    overlay:SetFrameStrata(self.achievementPanel:GetFrameStrata() or "FULLSCREEN_DIALOG")
    overlay:SetFrameLevel((self.achievementPanel:GetFrameLevel() or 1) + 60)
    -- Focus-lock layer: consume clicks outside the card so only explicit close
    -- actions dismiss the modal.
    overlay:EnableMouse(true)
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    overlay:SetBackdropColor(0, 0, 0, 0.72)
    overlay:SetAlpha(0)
    overlay:Hide()

    local card = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    card:SetPoint("CENTER")
    -- Height is a placeholder only - ResizeAchievementDetailCard sets the
    -- real height from content every time the card is opened.
    card:SetSize(480, 260)
    -- Keep the modal card interactive while swallowing clicks.
    card:EnableMouse(true)
    if card.SetPropagateMouseClicks then
        card:SetPropagateMouseClicks(false)
    end
    card:SetBackdrop(STANDARD_BACKDROP)
    card:SetBackdropColor(0.08, 0.07, 0.05, 0.98)
    card:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.95)

    local goldCol = (T and T.col and T.col.gold) or { r = 0.91, g = 0.78, b = 0.45 }
    local goldBrightCol = (T and T.col and T.col.goldBright) or { r = 0.96, g = 0.89, b = 0.65 }

    -- Left room at the front of the heading for the diamond ornament below,
    -- which anchors to (and vertically centers against) the heading itself.
    local heading = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("TOPLEFT", 30, -12)
    heading:SetPoint("TOPRIGHT", -42, -12)
    heading:SetJustifyH("LEFT")
    heading:SetText((L and L["SPOT_ACHV_DETAIL_TITLE"]) or "Achievement Details")

    -- Small gold corner ornament, matching the achievement-earned popup and
    -- the main window's own chrome. Anchored to the heading's LEFT/RIGHT
    -- points (which are always vertically centred on the frame) 
    if T and T.Diamond then
        local ornament = T.Diamond(card, 8, goldCol)
        ornament:SetPoint("RIGHT", heading, "LEFT", -10, 0)
    end

    local bodyWrap = CreateFrame("Frame", nil, card, "BackdropTemplate")
    bodyWrap:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -36)
    bodyWrap:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, 44)
    bodyWrap:SetBackdrop(STANDARD_BACKDROP)
    bodyWrap:SetBackdropColor(0.08, 0.07, 0.05, 1.0)
    bodyWrap:SetBackdropBorderColor(0.40, 0.34, 0.22, 0.95)
    -- Contain the shine burst to the body area so its scale animation can
    -- never bleed past the card into the rest of the screen.
    if bodyWrap.SetClipsChildren then
        bodyWrap:SetClipsChildren(true)
    end

    local icon = bodyWrap:CreateTexture(nil, "ARTWORK")
    icon:SetSize(64, 64)
    icon:SetPoint("TOPLEFT", bodyWrap, "TOPLEFT", 10, -10)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Echoes the icon ring + shine on the achievement-earned popup, so
    -- opening a tile's detail feels like the same "achievement" moment.
    local iconRing = bodyWrap:CreateTexture(nil, "BORDER")
    iconRing:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconRing:SetSize(76, 76)
    iconRing:SetTexture("Interface\\Common\\WhiteIconFrame")
    iconRing:SetVertexColor(goldCol.r, goldCol.g, goldCol.b, 1)

    local shine = bodyWrap:CreateTexture(nil, "OVERLAY")
    shine:SetPoint("CENTER", icon, "CENTER", 0, 0)
    shine:SetSize(64 * 1.7, 64 * 1.7)
    shine:SetTexture("Interface\\Cooldown\\star4")
    shine:SetBlendMode("ADD")
    shine:SetVertexColor(goldBrightCol.r, goldBrightCol.g, goldBrightCol.b, 1)
    shine:SetAlpha(0)

    local name = bodyWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    name:SetPoint("TOPRIGHT", -10, -10)
    name:SetJustifyH("LEFT")
    name:SetJustifyV("TOP")

    local desc = bodyWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("TOPRIGHT", bodyWrap, "TOPRIGHT", -10, 0)
    desc:SetJustifyH("LEFT")
    desc:SetJustifyV("TOP")

    local status = bodyWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    status:SetPoint("TOPRIGHT", bodyWrap, "TOPRIGHT", -10, 0)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")

    local detail = bodyWrap:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -8)
    detail:SetPoint("TOPRIGHT", bodyWrap, "TOPRIGHT", -10, 0)
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")

    -- Sized well past the old 20px box (a common accessibility minimum for
    -- click targets is ~24-28px) and given its own plate + hover feedback so
    -- it reads clearly as a button rather than a stray glyph.
    local closeX = CreateFrame("Button", nil, card)
    closeX:SetSize(28, 28)
    closeX:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -6)
    local closeXText = closeX:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeXText:SetPoint("CENTER")
    closeXText:SetText("x")
    closeXText:SetScale(2)
    closeXText:SetTextColor(0.91, 0.78, 0.45)
    closeX:SetScript("OnEnter", function()
        closeXText:SetTextColor(1.0, 0.92, 0.70)
    end)
    closeX:SetScript("OnLeave", function()
        closeXText:SetTextColor(0.91, 0.78, 0.45)
    end)
    closeX:SetScript("OnClick", function() self:CloseAchievementDetail() end)

    local close = CreateFrame("Button", nil, card)
    close:SetSize(120, 24)
    close:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, 12)
    SkinEpithetButton(close)
    close.label:SetText((L and L["SPOT_ACHV_DETAIL_CLOSE"]) or "Close")
    close:SetScript("OnClick", function() self:CloseAchievementDetail() end)

    overlay:SetScript("OnMouseDown", function() end)
    overlay:SetScript("OnMouseUp", function() end)
    card:SetScript("OnMouseDown", function() end)
    card:SetScript("OnMouseUp", function() end)

    -- Entrance fade: the dimmed backdrop and card (which inherits its
    -- parent's alpha) fade in together.
    local animIn = overlay:CreateAnimationGroup()
    -- Without this, the overlay's alpha reverts to its pre-animation value
    -- (0, set above) the instant the group finishes, so it fades in and then
    -- immediately vanishes again.
    animIn:SetToFinalAlpha(true)
    local fadeIn = animIn:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.12)
    fadeIn:SetSmoothing("OUT")

    -- Kept deliberately subtle and contained near the icon (see
    -- bodyWrap:SetClipsChildren above) rather than a big screen-filling burst.
    local shineGroup = shine:CreateAnimationGroup()
    shineGroup:SetToFinalAlpha(true)
    local shineIn = shineGroup:CreateAnimation("Alpha")
    shineIn:SetFromAlpha(0)
    shineIn:SetToAlpha(0.72)
    shineIn:SetDuration(0.08)
    shineIn:SetOrder(1)
    shineIn:SetSmoothing("OUT")
    -- "IN" (slow start, fast finish) rather than "OUT": with the 0.08s alpha
    -- ramp above, "OUT" grows most of the way while still nearly invisible,
    -- so by the time you can see it, it already looks fully grown. Starting
    -- slow keeps it visibly small while it fades in, then it grows into
    -- place after that, which actually reads as "starts small, gets bigger".
    local shineScale = shineGroup:CreateAnimation("Scale")
    shineScale:SetOrigin("CENTER", 0, 0)
    shineScale:SetScaleFrom(0.6, 0.6)
    shineScale:SetScaleTo(1.05, 1.05)
    shineScale:SetDuration(0.22)
    shineScale:SetOrder(1)
    shineScale:SetSmoothing("IN")
    -- Deliberately longer than the grow/fade-in above: it finishes growing
    -- quickly, then keeps turning at full size for a slower, steadier spin
    -- before the twinkle kicks in.
    local shineSpin = shineGroup:CreateAnimation("Rotation")
    shineSpin:SetOrigin("CENTER", 0, 0)
    shineSpin:SetDegrees(360)
    shineSpin:SetDuration(0.55)
    shineSpin:SetOrder(1)

    -- Twinkle: two quick brightness pulses once it's fully grown.
    local twinkleDim1 = shineGroup:CreateAnimation("Alpha")
    twinkleDim1:SetFromAlpha(0.72)
    twinkleDim1:SetToAlpha(0.30)
    twinkleDim1:SetDuration(0.06)
    twinkleDim1:SetOrder(2)
    local twinkleBright1 = shineGroup:CreateAnimation("Alpha")
    twinkleBright1:SetFromAlpha(0.30)
    twinkleBright1:SetToAlpha(0.85)
    twinkleBright1:SetDuration(0.06)
    twinkleBright1:SetOrder(3)
    local twinkleDim2 = shineGroup:CreateAnimation("Alpha")
    twinkleDim2:SetFromAlpha(0.85)
    twinkleDim2:SetToAlpha(0.45)
    twinkleDim2:SetDuration(0.06)
    twinkleDim2:SetOrder(4)
    local twinkleBright2 = shineGroup:CreateAnimation("Alpha")
    twinkleBright2:SetFromAlpha(0.45)
    twinkleBright2:SetToAlpha(0.72)
    twinkleBright2:SetDuration(0.06)
    twinkleBright2:SetOrder(5)

    -- Dissipate: fade out while drifting gently upward. Kept to a small
    -- offset since bodyWrap clips its children close to the icon (see
    -- above) - a bigger drift would visibly get cut off at the clip edge.
    local shineOut = shineGroup:CreateAnimation("Alpha")
    shineOut:SetFromAlpha(0.72)
    shineOut:SetToAlpha(0)
    shineOut:SetDuration(0.26)
    shineOut:SetOrder(6)
    shineOut:SetSmoothing("IN")
    local shineDrift = shineGroup:CreateAnimation("Translation")
    shineDrift:SetOffset(0, 10)
    shineDrift:SetDuration(0.26)
    shineDrift:SetOrder(6)
    shineDrift:SetSmoothing("OUT")

    -- Icon pulse: plays alongside the shine burst above - grows past full
    -- size, shrinks back past normal, then settles, like a little heartbeat.
    local iconPulse = icon:CreateAnimationGroup()
    local iconGrow = iconPulse:CreateAnimation("Scale")
    iconGrow:SetOrigin("CENTER", 0, 0)
    iconGrow:SetScaleFrom(1, 1)
    iconGrow:SetScaleTo(1.15, 1.15)
    iconGrow:SetDuration(0.16)
    iconGrow:SetOrder(1)
    iconGrow:SetSmoothing("OUT")
    local iconShrink = iconPulse:CreateAnimation("Scale")
    iconShrink:SetOrigin("CENTER", 0, 0)
    iconShrink:SetScaleFrom(1.15, 1.15)
    iconShrink:SetScaleTo(0.94, 0.94)
    iconShrink:SetDuration(0.14)
    iconShrink:SetOrder(2)
    iconShrink:SetSmoothing("IN")
    local iconSettle = iconPulse:CreateAnimation("Scale")
    iconSettle:SetOrigin("CENTER", 0, 0)
    iconSettle:SetScaleFrom(0.94, 0.94)
    iconSettle:SetScaleTo(1, 1)
    iconSettle:SetDuration(0.12)
    iconSettle:SetOrder(3)
    iconSettle:SetSmoothing("OUT")

    overlay.card = card
    overlay.icon = icon
    overlay.shine = shine
    overlay.heading = heading
    overlay.name = name
    overlay.desc = desc
    overlay.status = status
    overlay.detail = detail
    overlay.animIn = animIn
    overlay.shineGroup = shineGroup
    overlay.iconPulse = iconPulse

    self.achievementDetailOverlay = overlay
    return overlay
end

function LogbookUI:OpenAchievementDetail(data)
    if not data then return end
    local overlay = self:EnsureAchievementDetailOverlay()
    if not overlay then return end

    -- Only a genuinely earned (and unmasked) achievement gets the full-colour
    -- icon and the celebration animations below - matches how the grid tiles
    -- already distinguish earned/unearned.
    local earned = data.earned and not data.masked

    local iconPath
    if data.masked then
        iconPath = "Interface\\Icons\\inv_misc_questionmark"
    else
        iconPath = GetAchievementTileIcon(data.id)
    end
    TrySetTexture(overlay.icon, iconPath)
    overlay.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if data.masked then
        overlay.icon:SetVertexColor(0.66, 0.62, 0.55, 1.0)
    elseif earned then
        overlay.icon:SetVertexColor(1, 1, 1, 1)
    else
        overlay.icon:SetVertexColor(0.72, 0.72, 0.72, 0.95)
    end
    if overlay.icon.SetDesaturated then
        overlay.icon:SetDesaturated(not earned)
    end

    local name = data.name or ""
    local desc = data.description or ""
    local status = ""
    local detail = ""

    if data.masked then
        name = (L and L["SPOT_ACHV_SECRET_NAME"]) or "???"
        desc = (L and L["SPOT_ACHV_SECRET_DESC"]) or "Secret achievement"
        status = (L and L["SPOT_ACHV_DETAIL_SECRET_STATUS"]) or "Earn this achievement to reveal details."
        detail = ""
    else
        if data.earned and data.earnedText then
            status = FormatAchievementEarnedText(data.earnedText)
            if data.secret and data.secretEarned then
                status = status .. " " .. SecretEarnedSuffixText()
            end
        elseif data.progressText and data.progressText ~= "" then
            status = data.progressText
        else
            status = data.groupLabel or ""
        end

        if data.detailText and data.detailText ~= "" then
            detail = data.detailText
        elseif data.fwendsHint then
            detail = (L and L["SPOT_ACHV_FWENDS_HINT"]) or "Counts titles you spotted for the very first time on them."
        else
            detail = ""
        end

        if data.secret and data.secretEarned then
            if detail ~= "" then
                detail = detail .. "\n\n" .. SecretEarnedTooltipText()
            else
                detail = SecretEarnedTooltipText()
            end
        end
    end

    overlay.name:SetText(name)
    overlay.desc:SetText(desc)
    overlay.status:SetText(status)
    overlay.detail:SetText(detail)

    self:ResizeAchievementDetailCard(overlay)
    self:ShowAchievementDetailOverlay(overlay, earned)
end

-- Shrinks/grows the card to fit whatever text this achievement actually
-- has, instead of always reserving space for the longest possible entry.
function LogbookUI:ResizeAchievementDetailCard(overlay)
    local card = overlay.card
    if not card then return end

    local textHeight = (overlay.name:GetStringHeight() or 0)
        + 8 + (overlay.desc:GetStringHeight() or 0)
        + 10 + (overlay.status:GetStringHeight() or 0)
        + 8 + (overlay.detail:GetStringHeight() or 0)

    -- The icon + ring column is a fixed size and doesn't shrink with the
    -- text, so it sets the floor for how short the body can get.
    local iconColumnHeight = 10 + 76

    local bodyHeight = math.max(iconColumnHeight, textHeight) + 20
    local cardHeight = bodyHeight + 36 + 44
    cardHeight = math.max(220, math.min(460, cardHeight))
    card:SetHeight(cardHeight)
end

function LogbookUI:ShowAchievementDetailOverlay(overlay, celebrate)
    if not overlay then
        return
    end

    overlay:Show()

    if overlay.animIn then
        overlay.animIn:Stop()
        overlay.animIn:Play()
    else
        overlay:SetAlpha(1)
    end

    if celebrate then
        if overlay.shineGroup then
            overlay.shineGroup:Stop()
            overlay.shineGroup:Play()
        end
        if overlay.iconPulse then
            overlay.iconPulse:Stop()
            overlay.iconPulse:Play()
        end
    else
        -- Not earned: no shine burst, no icon pulse - just the plain,
        -- greyed-out icon. Force both back to their neutral resting state in
        -- case either was left mid-animation from a previous, earned entry.
        if overlay.shineGroup then
            overlay.shineGroup:Stop()
        end
        if overlay.shine then
            overlay.shine:SetAlpha(0)
        end
        if overlay.iconPulse then
            -- Playing then immediately stopping snaps the icon back to its
            -- neutral 100% scale (the first animation's "from" value) without
            -- it ever visibly running, since no frame renders in between.
            overlay.iconPulse:Play()
            overlay.iconPulse:Stop()
        end
    end
end

function LogbookUI:CloseAchievementDetail()
    local overlay = self.achievementDetailOverlay
    if not overlay or not overlay:IsShown() then
        return
    end

    if overlay.animIn and overlay.animIn.IsPlaying and overlay.animIn:IsPlaying() then
        overlay.animIn:Stop()
    end
    if overlay.shineGroup and overlay.shineGroup.IsPlaying and overlay.shineGroup:IsPlaying() then
        overlay.shineGroup:Stop()
    end
    if overlay.iconPulse and overlay.iconPulse.IsPlaying and overlay.iconPulse:IsPlaying() then
        overlay.iconPulse:Stop()
    end
    overlay:EnableMouse(false)
    overlay:Hide()
end

function LogbookUI:AcquireAchievementTile(index)
    local tile = self.achievementTiles[index]
    if tile then return tile end

    tile = CreateFrame("Button", nil, self.achievementGridContent, "BackdropTemplate")
    tile:SetBackdrop(STANDARD_BACKDROP)
    tile:SetBackdropColor(0.11, 0.09, 0.06, 0.92)
    tile:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.55)

    local state = tile:CreateTexture(nil, "ARTWORK")
    state:SetSize(14, 14)
    state:SetPoint("CENTER")
    tile.state = state

    local statePlate = CreateFrame("Frame", nil, tile, "BackdropTemplate")
    statePlate:SetSize(22, 22)
    statePlate:SetPoint("TOPLEFT", tile, "TOPLEFT", 4, -4)
    statePlate:SetBackdrop(STANDARD_BACKDROP)
    statePlate:SetBackdropColor(0.02, 0.02, 0.02, 0.85)
    statePlate:SetBackdropBorderColor(0.72, 0.58, 0.28, 0.95)
    state:SetParent(statePlate)
    state:SetPoint("CENTER", statePlate, "CENTER", 0, 0)
    tile.statePlate = statePlate

    local icon = tile:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", tile, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    tile.icon = icon

    local secretBadge = CreateFrame("Frame", nil, tile, "BackdropTemplate")
    secretBadge:SetSize(22, 14)
    secretBadge:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -4, -4)
    secretBadge:SetBackdrop(STANDARD_BACKDROP)
    secretBadge:SetBackdropColor(0.10, 0.08, 0.05, 0.92)
    secretBadge:SetBackdropBorderColor(0.94, 0.80, 0.40, 0.95)
    secretBadge:Hide()

    local secretBadgeText = secretBadge:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    secretBadgeText:SetPoint("CENTER")
    secretBadgeText:SetText("?")
    secretBadgeText:SetTextColor(0.96, 0.88, 0.56)

    tile.secretBadge = secretBadge

    tile:SetScript("OnEnter", function(self_)
        self_:SetBackdropBorderColor(0.83, 0.70, 0.36, 0.9)
        if self_.data then
            self:ConfigureEntryTooltip(self_, self_.data)
        end
    end)

    tile:SetScript("OnClick", function(self_)
        if self_.data then
            self:OpenAchievementDetail(self_.data)
        end
    end)

    tile:SetScript("OnLeave", function(self_)
        self_:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.55)
        GameTooltip:Hide()
    end)

    self.achievementTiles[index] = tile
    return tile
end

-- Shared square-tile grid math for both the achievement grid and the title
-- grid: given the available width and tile count, how many columns fit and
-- how big is each tile; then where does tile #index sit in that grid.
local function ComputeGridLayout(width, count, minTileSize, gap)
    width = math.max(1, width or 1)
    local colsByWidth = math.max(1, math.floor((width + gap) / (minTileSize + gap)))
    local cols = math.max(1, math.min(colsByWidth, math.max(1, count)))
    local tileSize = (width - ((cols - 1) * gap)) / cols
    local rows = math.max(1, math.ceil(count / cols))
    local totalHeight = math.max(1, (rows * tileSize) + ((rows - 1) * gap))
    return cols, tileSize, totalHeight
end

local function PositionGridTile(tile, index, cols, tileSize, gap, container)
    tile:SetSize(tileSize, tileSize)
    local col = (index - 1) % cols
    local row = math.floor((index - 1) / cols)
    local x = col * (tileSize + gap)
    local y = row * (tileSize + gap)
    tile:ClearAllPoints()
    tile:SetPoint("TOPLEFT", container, "TOPLEFT", x, -y)
end

function LogbookUI:RefreshAchievementTiles(entries)
    local cols, tileSize, totalHeight = ComputeGridLayout(
        self.achievementGridContent:GetWidth(), #entries, ACHV_TILE_MIN, ACHV_TILE_GAP)
    self.achievementGridContent:SetHeight(totalHeight)

    for i, data in ipairs(entries) do
        local tile = self:AcquireAchievementTile(i)
        PositionGridTile(tile, i, cols, tileSize, ACHV_TILE_GAP, self.achievementGridContent)
        tile:Show()
        tile.data = data

        if data.earned then
            TrySetTexture(tile.state, CHECK_ICON)
            tile.state:SetVertexColor(0.90, 0.74, 0.30, 1.0)
            tile.statePlate:SetBackdropBorderColor(0.95, 0.80, 0.36, 1.0)
            tile:SetBackdropBorderColor(0.67, 0.57, 0.30, 0.85)
            if tile.icon.SetDesaturated then
                tile.icon:SetDesaturated(false)
            end
        else
            TrySetTexture(tile.state, LOCK_ICON)
            tile.state:SetVertexColor(0.88, 0.84, 0.75, 1.0)
            tile.statePlate:SetBackdropBorderColor(0.86, 0.74, 0.42, 1.0)
            tile:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.55)
            if tile.icon.SetDesaturated then
                tile.icon:SetDesaturated(true)
            end
        end

        if tile.secretBadge then
            if data.secret and data.secretEarned then
                tile.secretBadge:Show()
            else
                tile.secretBadge:Hide()
            end
        end

        if data.masked then
            TrySetTexture(tile.state, LOCK_ICON)
            tile.state:SetVertexColor(0.88, 0.84, 0.75, 1.0)
            TrySetTexture(tile.icon, "Interface\\Icons\\inv_misc_questionmark")
            tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            tile.icon:SetVertexColor(0.66, 0.62, 0.55, 1.0)
            if tile.icon.SetDesaturated then
                tile.icon:SetDesaturated(true)
            end
            tile.icon:ClearAllPoints()
            tile.icon:SetPoint("TOPLEFT", tile, "TOPLEFT", 2, -2)
            tile.icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -2, 2)
        else
            TrySetTexture(tile.icon, GetAchievementTileIcon(data.id))
            tile.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            if data.earned then
                tile.icon:SetVertexColor(1, 1, 1, 1)
            else
                tile.icon:SetVertexColor(0.72, 0.72, 0.72, 0.95)
            end
            tile.icon:ClearAllPoints()
            tile.icon:SetPoint("TOPLEFT", tile, "TOPLEFT", 2, -2)
            tile.icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -2, 2)
        end
    end

    for i = #entries + 1, #self.achievementTiles do
        self.achievementTiles[i]:Hide()
        self.achievementTiles[i].data = nil
    end
end

function LogbookUI:RefreshAchievements()
    if not self.achievementPanel then return end

    self:RefreshAchievementFilterButtons()

    if self.achievementHeading then
        self.achievementHeading:SetText((L and L["SPOT_ACHV_HEADING"]) or "Epithet Achievements")
    end
    if self.achievementMetaTitle then
        self.achievementMetaTitle:SetText((L and L["SPOT_ACHV_META_TITLE"]) or "Achievement Hunting Notes")
    end
    if self.achievementMetaText then
        self.achievementMetaText:SetText((L and L["SPOT_ACHV_META_DESC"]) or "To complete every achievement, you may need to coordinate your spotting across classes, factions, calendar windows, and repeated sightings with friends or guildmates.")
    end
    if self.achievementMetaWrap and self.achievementMetaTitle and self.achievementMetaText then
        local measuredMetaHeight = math.ceil((self.achievementMetaTitle:GetStringHeight() or 0) + 8 + (self.achievementMetaText:GetStringHeight() or 0) + 16)
        self.achievementMetaWrap:SetHeight(math.max(58, measuredMetaHeight))
    end

    local allEntries = (ns.SpottingAchievements and ns.SpottingAchievements.GetDisplayEntries and ns.SpottingAchievements:GetDisplayEntries()) or {}
    local mode = self.achievementFilterMode or "all"
    local entries
    if mode == "unearned" then
        entries = {}
        for _, entry in ipairs(allEntries) do
            if not entry.earned then
                entries[#entries + 1] = entry
            end
        end
    else
        entries = allEntries
    end
    local earned, total = 0, #entries
    if ns.SpottingAchievements and ns.SpottingAchievements.GetSummary then
        earned, total = ns.SpottingAchievements:GetSummary()
    end

    if self.achievementCountText then
        self.achievementCountText:SetText((L and L["SPOT_ACHV_COUNT_FMT"] and string.format(L["SPOT_ACHV_COUNT_FMT"], earned or 0, total or 0)) or ((earned or 0) .. " / " .. (total or 0) .. " earned"))
    end

    self.achievementEntries = entries
    if #entries == 0 then
        self.achievementEmptyState:Show()
        self:RefreshAchievementTiles({})
    else
        self.achievementEmptyState:Hide()
        self:RefreshAchievementTiles(entries)
    end
end

function LogbookUI:BuildEntries(scopeMode)
    local entries = {}

    -- Scan() is dirty-flag gated; callers scan once up front (see Refresh()).

    if scopeMode == "remaining" then
        local records = (ns.TitleData and ns.TitleData.records) or {}
        for _, record in ipairs(records) do
            local spotted = ns.SpottingLog and ns.SpottingLog.Has and ns.SpottingLog:Has(record.titleID)
            if not spotted then
                entries[#entries + 1] = {
                    titleID = record.titleID,
                    record = record,
                    log = nil,
                    isSpotted = false,
                }
            end
        end

        table.sort(entries, function(a, b)
            return (a.record.text or "") < (b.record.text or "")
        end)

        return entries
    end

    if not (ns.SpottingLog and ns.SpottingLog.Iterate) then
        return entries
    end

    for titleID, entry in ns.SpottingLog:Iterate() do
        local record = GetDisplayRecord(titleID, entry)
        if record and entry then
            entries[#entries + 1] = {
                titleID = titleID,
                record = record,
                log = entry,
                isSpotted = true,
            }
        end
    end

    table.sort(entries, function(a, b)
        local aSeen = tonumber(a.log and a.log.firstSeen) or 0
        local bSeen = tonumber(b.log and b.log.firstSeen) or 0
        if aSeen == bSeen then
            return (a.record.text or "") < (b.record.text or "")
        end
        return aSeen > bSeen
    end)

    return entries
end

function LogbookUI:ConfigureEntryTooltip(owner, data)
    if data.entryType == "achievement" then
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:AddLine(data.name or "", 1, 1, 1)
        if data.masked then
            GameTooltip:AddLine((L and L["SPOT_ACHV_SECRET_DESC"]) or "Secret achievement", 0.85, 0.82, 0.72, true)
            GameTooltip:Show()
            return
        end

        if data.description and data.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(data.description, 0.85, 0.82, 0.72, true)
        end

        if data.progressText and data.progressText ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(data.progressText, 0.78, 0.85, 0.72, true)
        end

        if data.earned and data.earnedText then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(FormatAchievementEarnedText(data.earnedText), 0.88, 0.86, 0.74, true)
        end

        if data.secret and data.secretEarned then
            GameTooltip:AddLine(SecretEarnedTooltipText(), 0.96, 0.88, 0.56, true)
        end

        if data.detailText and data.detailText ~= "" then
            GameTooltip:AddLine(data.detailText, 0.80, 0.85, 0.92, true)
        end

        if data.fwendsHint then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine((L and L["SPOT_ACHV_FWENDS_HINT"]) or "Counts titles you spotted for the very first time on them.", 0.85, 0.82, 0.72, true)
        end

        GameTooltip:Show()
        return
    end

    local record = data.record
    local log = data.log

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(record.text or "", 1, 1, 1)

    if data.isSpotted and log then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L and L["SPOTTING_TOOLTIP_FIRST_FMT"] and string.format(L["SPOTTING_TOOLTIP_FIRST_FMT"], log.firstName or "?", log.firstZone or "?", BuildDateString(log.firstSeen))) or "", 0.85, 0.82, 0.72, true)
        local raceLabel = FormatRaceLabel(log.raceTag) or ((L and L["SPOTTING_TOOLTIP_RACE_UNKNOWN"]) or "Unknown")
        local raceIcon = BuildRaceInlineIconTag(log.raceTag, log.sex)
        local raceText = (L and L["SPOTTING_TOOLTIP_RACE_FMT"] and string.format(L["SPOTTING_TOOLTIP_RACE_FMT"], raceLabel)) or ("Race: " .. raceLabel)
        GameTooltip:AddLine(raceIcon .. raceText, 0.85, 0.82, 0.72, true)
        GameTooltip:AddLine((L and L["SPOTTING_TOOLTIP_COUNT_FMT"] and string.format(L["SPOTTING_TOOLTIP_COUNT_FMT"], tonumber(log.count) or 1)) or "", 0.85, 0.82, 0.72, true)
        GameTooltip:AddLine((L and L["SPOTTING_TOOLTIP_LAST_FMT"] and string.format(L["SPOTTING_TOOLTIP_LAST_FMT"], BuildDateString(log.lastSeen), log.lastName or "?")) or "", 0.85, 0.82, 0.72, true)
    else
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L and L["SPOTTING_NOT_SPOTTED_YET"]) or "Not spotted yet.", 0.85, 0.82, 0.72, true)
    end

    GameTooltip:Show()
end

function LogbookUI:AcquireRow(index)
    local row = self.rows[index]
    if row then return row end

    row = CreateFrame("Button", nil, self.listContent)
    row:SetHeight(ROW_HEIGHT)
    -- Slot position depends only on index, never on the data bound to it, so
    -- it only needs to be set once here rather than re-anchored every Refresh.
    row:SetPoint("TOPLEFT", self.listContent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
    row:SetPoint("RIGHT", self.listContent, "RIGHT", 0, 0)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.02)
    row.bg = bg

    local state = row:CreateTexture(nil, "ARTWORK")
    state:SetSize(16, 16)
    state:SetPoint("LEFT", 6, 0)
    row.state = state

    local portrait = row:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(26, 26)
    portrait:SetPoint("LEFT", state, "RIGHT", 6, 0)
    portrait:SetTexture(CLASS_ICON)
    portrait:Hide()
    row.portrait = portrait

    local race = row:CreateTexture(nil, "ARTWORK")
    race:SetSize(26, 26)
    race:SetPoint("LEFT", portrait, "RIGHT", 4, 0)
    race:SetTexture(RACE_ICON)
    race:Hide()
    row.race = race

    local raceBlend = row:CreateTexture(nil, "OVERLAY")
    raceBlend:SetAllPoints(race)
    raceBlend:Hide()
    row.raceBlend = raceBlend

    local title = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("LEFT", race, "RIGHT", 6, 0)
    title:SetPoint("RIGHT", row, "RIGHT", -230, 0)
    title:SetJustifyH("LEFT")
    row.title = title

    local meta = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    meta:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    meta:SetJustifyH("RIGHT")
    meta:SetTextColor(0.72, 0.66, 0.56)
    row.meta = meta

    row:SetScript("OnEnter", function(self_)
        self_.bg:SetColorTexture(1, 1, 1, 0.05)
        if self_.data then
            self:ConfigureEntryTooltip(self_, self_.data)
        end
    end)

    row:SetScript("OnLeave", function(self_)
        self_.bg:SetColorTexture(1, 1, 1, 0.02)
        GameTooltip:Hide()
    end)

    self.rows[index] = row
    return row
end

function LogbookUI:RefreshRows(entries)
    local totalHeight = math.max(1, #entries * ROW_HEIGHT)
    self.listContent:SetHeight(totalHeight)

    for i, data in ipairs(entries) do
        local row = self:AcquireRow(i)
        row:Show()
        row.data = data

        if data.entryType == "achievement" then
            if data.earned then
                TrySetTexture(row.state, CHECK_ICON)
                row.state:SetVertexColor(0.90, 0.74, 0.30, 1.0)
            else
                TrySetTexture(row.state, LOCK_ICON)
                row.state:SetVertexColor(0.56, 0.52, 0.45, 1.0)
            end

            if data.masked then
                TrySetTexture(row.state, LOCK_ICON)
                row.state:SetVertexColor(0.56, 0.52, 0.45, 1.0)
                row.portrait:Hide()
                row.race:Hide()
                if row.raceBlend then row.raceBlend:Hide() end
                row.title:SetText((L and L["SPOT_ACHV_SECRET_NAME"]) or "???")
                row.title:SetTextColor(0.70, 0.66, 0.58)
                row.meta:SetText("")
            else
                TrySetTexture(row.portrait, ACHIEVEMENT_ICON)
                row.portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                row.portrait:Show()
                row.race:Hide()
                if row.raceBlend then row.raceBlend:Hide() end
                row.title:SetText(data.name or "")
                if data.earned then
                    row.title:SetTextColor(0.96, 0.88, 0.62)
                else
                    row.title:SetTextColor(0.84, 0.80, 0.71)
                end

                local right = data.groupLabel or ""
                if data.earned and data.earnedText then
                    right = FormatAchievementEarnedText(data.earnedText)
                elseif data.progressText and data.progressText ~= "" then
                    right = data.progressText
                end
                row.meta:SetText(right)
            end

        else
            local r, g, b = GetRarityColour(data.record.q)
            row.title:SetText(data.record.text or "")
            row.title:SetTextColor(r, g, b)

            ApplySpottedStateIcons(row, data)

            local source = (data.record.kind and ns.KindLabel(data.record.kind))
                or (data.record.cat and ns.CategoryLabel(data.record.cat)) or ""
            if data.isSpotted then
                local seen = BuildDateString(data.log and data.log.firstSeen)
                local playerName = data.log and (data.log.lastName or data.log.firstName) or nil
                local tail = playerName and (seen .. " - " .. playerName) or seen
                row.meta:SetText((source ~= "" and (source .. " - " .. tail)) or tail)
            else
                row.meta:SetText((source ~= "" and source) or ((L and L["SPOTTING_NOT_SPOTTED_YET"]) or "Not spotted yet"))
            end
        end
    end

    for i = #entries + 1, #self.rows do
        self.rows[i]:Hide()
        self.rows[i].data = nil
    end
end

function LogbookUI:AcquireTile(index)
    local tile = self.tiles[index]
    if tile then return tile end

    tile = CreateFrame("Button", nil, self.gridContent, "BackdropTemplate")
    tile:SetBackdrop(STANDARD_BACKDROP)
    tile:SetBackdropColor(0.11, 0.09, 0.06, 0.92)
    tile:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.55)

    local state = tile:CreateTexture(nil, "ARTWORK")
    state:SetSize(16, 16)
    state:SetPoint("TOPLEFT", 6, -6)
    tile.state = state

    local race = tile:CreateTexture(nil, "ARTWORK")
    race:SetSize(26, 26)
    race:SetPoint("TOPRIGHT", -6, -6)
    race:SetTexture(RACE_ICON)
    race:Hide()
    tile.race = race

    local raceBlend = tile:CreateTexture(nil, "OVERLAY")
    raceBlend:SetAllPoints(race)
    raceBlend:Hide()
    tile.raceBlend = raceBlend

    local portrait = tile:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(26, 26)
    portrait:SetPoint("TOPRIGHT", race, "TOPLEFT", -2, 0)
    portrait:SetTexture(CLASS_ICON)
    portrait:Hide()
    tile.portrait = portrait

    local title = tile:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", tile, "TOPLEFT", 8, -40)
    title:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -8, -40)
    title:SetPoint("BOTTOM", tile, "BOTTOM", 0, 26)
    title:SetJustifyH("CENTER")
    title:SetJustifyV("MIDDLE")
    title:SetWordWrap(true)
    tile.title = title

    local meta = tile:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    meta:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 6, 6)
    meta:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -6, 6)
    meta:SetJustifyH("CENTER")
    meta:SetWordWrap(false)
    tile.meta = meta

    tile:SetScript("OnEnter", function(self_)
        self_:SetBackdropBorderColor(0.83, 0.70, 0.36, 0.9)
        if self_.data then
            self:ConfigureEntryTooltip(self_, self_.data)
        end
    end)

    tile:SetScript("OnLeave", function(self_)
        self_:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.55)
        GameTooltip:Hide()
    end)

    self.tiles[index] = tile
    return tile
end

function LogbookUI:RefreshTiles(entries)
    local cols, tileSize, totalHeight = ComputeGridLayout(
        self.gridContent:GetWidth(), #entries, TILE_SIZE, TILE_GAP)
    self.gridContent:SetHeight(totalHeight)

    for i, data in ipairs(entries) do
        local tile = self:AcquireTile(i)
        PositionGridTile(tile, i, cols, tileSize, TILE_GAP, self.gridContent)
        tile:Show()
        tile.data = data

        local r, g, b = GetRarityColour(data.record.q)
        tile.title:SetText(data.record.text or "")
        tile.title:SetTextColor(r, g, b)

        ApplySpottedStateIcons(tile, data)

        if data.isSpotted then
            tile.meta:SetText(BuildDateString(data.log and data.log.firstSeen))
        else
            tile.meta:SetText((L and L["SPOTTING_NOT_SPOTTED"]) or "Remaining")
        end
    end

    for i = #entries + 1, #self.tiles do
        self.tiles[i]:Hide()
        self.tiles[i].data = nil
    end
end

function LogbookUI:RefreshButton()
    if not self.button then return end
    local count = ns.SpottingLog and ns.SpottingLog.Count and ns.SpottingLog:Count() or 0
    self.button.count = count
end

function LogbookUI:RefreshModeButtons()
    if not self.scopeSpottedBtn or not self.scopeRemainingBtn then return end

    SetButtonSelected(self.scopeSpottedBtn, self.scopeMode == "spotted")
    SetButtonSelected(self.scopeRemainingBtn, self.scopeMode == "remaining")
    SetButtonSelected(self.viewListBtn, self.viewMode == "list")
    SetButtonSelected(self.viewGridBtn, self.viewMode == "grid")
end

function LogbookUI:Refresh()
    if not self.panel then return end

    self:RefreshButton()
    self:RefreshModeButtons()
    if self.heading then
        self.heading:SetText((L and L["SPOTTING_LOG_HEADING"]) or "Spotting Log")
    end

    local enabled = ns.IsTitleSpottingEnabled and ns.IsTitleSpottingEnabled() or false

    if ns.TitleData and ns.TitleData.Scan then
        ns.TitleData:Scan()
    end

    local spottedCount = ns.SpottingLog and ns.SpottingLog.Count and ns.SpottingLog:Count() or 0
    local totalCatalogue = GetCatalogueCount()
    if self.countText then
        if self.scopeMode == "remaining" then
            local remaining = math.max(0, totalCatalogue - spottedCount)
            self.countText:SetText((L and L["SPOTTING_LOG_COUNT_REMAINING_FMT"] and string.format(L["SPOTTING_LOG_COUNT_REMAINING_FMT"], remaining)) or (remaining .. " titles remaining"))
        else
            self.countText:SetText((L and L["SPOTTING_LOG_COUNT_PROGRESS_FMT"] and string.format(L["SPOTTING_LOG_COUNT_PROGRESS_FMT"], spottedCount, totalCatalogue)) or (spottedCount .. " / " .. totalCatalogue .. " titles spotted"))
        end
    end

    if not enabled then
        self.gatedState:Show()
        if self.metaGameInfo then
            self.metaGameInfo:Hide()
        end
        self.listWrap:Hide()
        self.gridWrap:Hide()
        self.emptyState:Hide()
        return
    end

    self.gatedState:Hide()
    if self.metaGameInfo then
        if self.scopeMode == "spotted" then
            self.metaGameInfo:Show()
        else
            self.metaGameInfo:Hide()
        end
    end
    self.entries = self:BuildEntries(self.scopeMode)

    if #self.entries == 0 then
        self.listWrap:Hide()
        self.gridWrap:Hide()
        self.emptyState:Show()
        if self.scopeMode == "remaining" then
            self.emptyState:SetText((L and L["SPOTTING_LOG_EMPTY_REMAINING"]) or "No remaining titles in the current catalogue.")
        else
            self.emptyState:SetText((L and L["SPOTTING_LOG_EMPTY"]) or "Nothing spotted yet. Target players in the wild to log the titles they are wearing.")
        end
        return
    end

    self.emptyState:Hide()

    if self.viewMode == "grid" then
        self.listWrap:Hide()
        self.gridWrap:Show()
        self:RefreshTiles(self.entries)
    else
        self.gridWrap:Hide()
        self.listWrap:Show()
        self:RefreshRows(self.entries)
    end
end

function LogbookUI:OnLogUpdated()
    if self.panel and self.panel:IsShown() then
        self:Refresh()
    elseif self.achievementPanel and self.achievementPanel:IsShown() then
        self:RefreshAchievements()
    else
        self:RefreshButton()
    end
end

function LogbookUI:HandleSpottingStateChanged()
    if self.panel and self.panel:IsShown() then
        self:Refresh()
    end
end
