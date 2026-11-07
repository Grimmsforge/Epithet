-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

-- =============================================================================
-- Epithet — WoW Forever achievement set
-- Loaded on WoW Forever only (Epithet.toc: [AllowLoadGameType camelot]),
-- straight after Spotting/Achievements.lua, which holds the engine and the
-- check builders (ns.SpottingAchievements.B).
--
-- Forever has 40 titles: 28 PvP ranks (14 per faction), 7 profession,
-- 4 reputation and 1 achievement title; no Epic tier; one expansion. Retail
-- achievements that work with that are kept under the same ids (so they share
-- names and translations); the rest are hidden (see `hidden`), and a set made
-- for Forever is added. See docs/ACHIEVEMENTS_FLAVOUR_SPLIT_PLAN.md.
--
-- Order matters: the evaluation pass runs top to bottom, so secret_keeper and
-- overachiever stay last.
-- =============================================================================
local _, ns = ...
local Achievements = ns.SpottingAchievements
local B = Achievements.B

-- Forever facts the shared checks are given here.
local CLASS_TOTAL = 9                -- the nine Classic classes
local TITLE_TOTAL = 40               -- spot every title: needs both ladders
local TOP_RANK = 14                  -- Grand Marshal / High Warlord
local PEOPLE_WATCHER_THRESHOLD = 500
local PROFESSIONAL_LURKER_THRESHOLD = 2000
-- The race and class pairings new in Forever (client race and class tokens).
local NEW_COMBOS = {
    { "Orc", "MAGE" }, { "Troll", "WARLOCK" }, { "Scourge", "PALADIN" },
    { "Human", "HUNTER" }, { "Gnome", "PRIEST" }, { "Dwarf", "SHAMAN" },
}
-- Launch week, local time (Forever launched on 4 November 2026).
local LAUNCH_WEEK_FIRST = "2026-11-04"
local LAUNCH_WEEK_LAST = "2026-11-11"
-- Skyborne's race token (probe, 1.60.1: "High Order Skyborne", race 95). A
-- prefix match, in case the Horde Windshapers' token differs.
local SKYBORNE = { "Skyborne" }
local YOUNG_BELOW_LEVEL = 20
-- Titles spotted with "Campfire Nearby" on you (ns.Flavor.campfireSpellID).
local CAMPFIRE_TITLES = 3

Achievements.DefineSet({
    id = "forever-1",
    expected = 64,
    list = {
        { id = "count_1", check = B.CheckCount(1), progress = B.ProgressCountSpotted(1), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Spyglass_02" },
        { id = "count_10", check = B.CheckCount(10), progress = B.ProgressCountSpotted(10), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Eye_01" },
        { id = "count_25", check = B.CheckCount(25), progress = B.ProgressCountSpotted(25), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { id = "count_40", check = B.CheckCount(TITLE_TOTAL), progress = B.ProgressCountSpotted(TITLE_TOTAL), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Book_11" },
        { id = "roll_call", check = B.CheckRollCallOf(CLASS_TOTAL), progress = B.ProgressRollCallOf(CLASS_TOTAL), group = "spotting", icon = "Interface\\Icons\\Achievement_pvp_p_10" },
        { id = "both_ends", check = B.CheckBothEnds, group = "spotting", icon = "Interface\\Icons\\INV_Scroll_03" },
        { id = "grand_tour", check = B.CheckGrandTour, progress = B.ProgressGrandTour, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Map_01" },
        { id = "title_fwends", check = B.CheckTitleFwends, group = "spotting", secret = true, icon = "Interface\\Icons\\Achievement_WorldEvent_Valentine" },
        { id = "havent_we_met", check = B.CheckHaventWeMet, group = "spotting", icon = "Interface\\Icons\\Ability_priest_focusedwill" },
        { id = "long_con", check = B.CheckLongCon, group = "spotting", secret = true, icon = "Interface\\Icons\\Ability_Hunter_Pet_Turtle" },
        { id = "night_shift", check = B.CheckNightShift, group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Holy_ElunesGrace" },
        { id = "busy_day", check = B.CheckBusyDay, group = "spotting", icon = "Interface\\Icons\\Spell_Holy_BorrowedTime" },
        { id = "capital_offence", check = B.CheckCapitalOffence, group = "spotting", icon = "Interface\\Icons\\Inv_jewelcrafting_gem_02" },
        { id = "legendary_spot", check = B.CheckLegendarySpot, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Gem_Topaz_02" },
        { id = "diplomatic_immunity", check = B.CheckDiplomaticImmunity, group = "spotting", icon = "Interface\\Icons\\Achievement_Reputation_01" },
        { id = "small_world", check = B.CheckSmallWorld, group = "spotting", icon = "Interface\\Icons\\Achievement_Character_Gnome_Male" },
        { id = "creature_of_habit", check = B.CheckCreatureOfHabit, group = "spotting", icon = "Interface\\Icons\\Spell_Nature_Polymorph_Cow" },
        { id = "gnome_spotter", check = B.CheckGnomeSpotter, progress = B.ProgressGnomeSpotter, group = "spotting", icon = "Interface\\Icons\\Ability_mount_mechastrider" },
        { id = "guising", check = B.CheckGuising, group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Misc_Bag_28_Halloween" },
        { id = "terse", check = B.CheckTerse, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Note_05" },
        { id = "gladiator_groupie", check = B.CheckGladiatorGroupie, progress = B.ProgressSourceSpotting("pvp"), group = "spotting", icon = "Interface\\Icons\\Achievement_FeatsOfStrength_Gladiator_01" },
        { id = "people_watcher", check = B.CheckPeopleWatcher, progress = B.ProgressTotalSightings(PEOPLE_WATCHER_THRESHOLD), group = "spotting", icon = "Interface\\Icons\\Achievement_halloween_smiley_01" },
        { id = "professional_lurker", check = B.CheckProfessionalLurker, progress = B.ProgressTotalSightings(PROFESSIONAL_LURKER_THRESHOLD), group = "spotting", icon = "Interface\\Icons\\Ability_Ambush" },
        { id = "double_take", check = B.CheckDoubleTake, group = "spotting", icon = "Interface\\Icons\\Spell_nature_invisibilty" },
        { id = "early_bird", check = B.CheckEarlyBird, group = "spotting", icon = "Interface\\Icons\\INV_Egg_05" },
        { id = "weekend_warrior", check = B.CheckWeekendWarrior, progress = B.ProgressWeekendWarrior, group = "spotting", icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
        { id = "full_week", check = B.CheckFullWeek, progress = B.ProgressFullWeek, group = "spotting", icon = "Interface\\Icons\\INV_Misc_PocketWatch_02" },
        { id = "year_in_field", check = B.CheckYearInField, progress = B.ProgressYearInField, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Book_02" },
        { id = "welcome_back", check = B.CheckWelcomeBack, group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Holy_Resurrection" },
        { id = "feast_your_eyes", check = B.CheckFeastYourEyes, group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Holiday_Christmas_Present_01" },
        { id = "participation_award", check = B.CheckParticipationAward, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Coin_16" },
        { id = "sneaky_beaky", check = B.CheckSneakyBeaky, group = "spotting", icon = "Interface\\Icons\\Ability_Stealth" },
        { id = "popular", check = B.CheckPopular, progress = B.ProgressPopular, group = "spotting", icon = "Interface\\Icons\\Spell_shadow_improvedvampiricembrace" },
        { id = "restraining_order", check = B.CheckRestrainingOrder, group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Misc_Note_03" },
        { id = "beyond_the_grave", check = B.CheckBeyondTheGrave, group = "spotting", secret = true, icon = "Interface\\Icons\\Achievement_halloween_ghost_01" },
        { id = "know_thy_enemy", check = B.CheckKnowThyEnemy, group = "spotting", icon = "Interface\\Icons\\INV_BannerPVP_01" },

        -- Forever only: two-part names.
        { id = "keeping_up_with_the_joneses", check = B.CheckSharedSurname(3), progress = B.ProgressSharedSurname(3), group = "spotting", icon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude" },
        { id = "family_business", check = B.CheckSameTitleSameFamily, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Coin_02" },

        -- Forever only: the PvP rank ladders.
        { id = "chain_of_command", check = B.CheckFullLadder, progress = B.ProgressFullLadder, group = "spotting", icon = "Interface\\PvPRankBadges\\PvPRank10" },
        { id = "mirror_image", check = B.CheckMirrorRank(nil), group = "spotting", icon = "Interface\\Icons\\Ability_Rogue_Disguise" },
        { id = "top_brass", check = B.CheckMirrorRank(TOP_RANK), group = "spotting", icon = "Interface\\PvPRankBadges\\PvPRank14" },

        -- Forever only: titles with a story.
        { id = "centaur_of_attention", check = B.CheckSpottedKeys({ "of the gelkis", "of the magram" }), group = "spotting", icon = "Interface\\Icons\\Ability_Warrior_BattleShout" },
        { id = "trade_secrets", check = B.CheckAllOfKind("Profession"), progress = B.ProgressAllOfKind("Profession"), group = "spotting", icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { id = "who_are_you", check = B.CheckSpottedKeys({ "the harbinger of darkness" }), group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Shadow_Twilight" },

        -- Forever only: its world and its launch.
        { id = "new_combo_who_dis", check = B.CheckRaceClassPairs(NEW_COMBOS), progress = B.ProgressRaceClassPairs(NEW_COMBOS), group = "spotting", icon = "Interface\\Icons\\Spell_Nature_Polymorph" },
        { id = "slaps_roof", check = B.CheckRaceInOneDay("Gnome", 3), group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Gizmo_02" },
        { id = "first_wave", check = B.CheckFirstSeenBetween(LAUNCH_WEEK_FIRST, LAUNCH_WEEK_LAST), group = "spotting", secret = true, timeLimited = true, icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental" },
        { id = "position_in_queue", check = B.CheckAnySeenFlag("seenSoonAfterLogin"), group = "spotting", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
        { id = "forever_young", check = B.CheckSeenBelowLevel(YOUNG_BELOW_LEVEL), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Flower_02" },
        { id = "head_in_the_clouds", check = B.CheckFirstSpotRace(SKYBORNE), group = "spotting", icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
        { id = "campfire_stories", check = B.CheckSeenFlagCount("seenAtCampfire", CAMPFIRE_TITLES), progress = B.ProgressSeenFlagCount("seenAtCampfire", CAMPFIRE_TITLES), group = "spotting", icon = "Interface\\Icons\\Spell_Fire_Fire" },

        { id = "owned_1", check = B.CheckOwnedCount(1), progress = B.ProgressOwnedCount(1), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Crown_01" },
        { id = "owned_10", check = B.CheckOwnedCount(10), progress = B.ProgressOwnedCount(10), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Letter_15" },
        { id = "owned_25", check = B.CheckOwnedCount(25), progress = B.ProgressOwnedCount(25), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Misc_Ribbon_01" },
        { id = "owned_both_ends", check = B.CheckOwnedBothEnds, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "owned_legendary", check = B.CheckOwnedLegendary, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Staff_Medivh" },
        { id = "impulse_purchase", check = B.CheckImpulsePurchase, group = "collection", scope = "character", icon = "Interface\\Icons\\Achievement_guildperk_bartering" },
        { id = "decorated_veteran", check = B.CheckDecoratedVeteran, progress = B.ProgressDecoratedVeteran, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02" },
        { id = "nothing_new", check = B.CheckNothingNew, group = "collection", scope = "character", icon = "Interface\\Icons\\Spell_Holy_SearingLight" },

        { id = "takes_one", check = B.CheckTakesOne, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\Spell_Nature_MirrorImage" },
        { id = "window_shopper", check = B.CheckWindowShopper, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\INV_Misc_Gift_01" },
        { id = "twinsies", check = B.CheckTwinsies, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty" },

        -- Must be last so the same evaluation pass can count newly-earned achievements.
        { id = "secret_keeper", check = B.CheckSecretKeeper, progress = B.ProgressSecretKeeper, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Key_03" },
        { id = "overachiever", check = B.CheckOverachiever, progress = B.ProgressOverachiever, group = "spotting", icon = "Interface\\Icons\\Achievement_Quests_Completed_06" },
    },
    -- Retail achievements Forever leaves out. Any already earned here stay
    -- saved but are not shown and do not count toward Overachiever.
    hidden = {
        "count_50",
        "count_100",
        "count_200",
        "count_350",
        "count_500",
        "count_700",
        "full_spectrum",
        "seeing_stars",
        "old_money",
        "museum_curator",
        "at_least_chicken",
        "certified",
        "lord_of_lords",
        "masterclass",
        "slay",
        "raid_spectator",
        "brown_noser",
        "how_its_made",
        "dead_man_walking",
        "owned_50",
        "owned_100",
        "owned_spectrum",
        "owned_removed",
        "matching_set",
        "potted_history",
        "curriculum_vitae",
        "old_school",
        "quite_a_mouthful",
    },
})
