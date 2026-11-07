-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

-- =============================================================================
-- Epithet — Retail achievement set
-- Loaded on Retail and PTR only (Epithet.toc: [AllowLoadGameType standard]),
-- straight after Spotting/Achievements.lua, which holds the engine and the
-- check builders (ns.SpottingAchievements.B). WoW Forever has its own set in
-- Flavors/Forever/Achievements.lua.
--
-- Order matters: the evaluation pass runs top to bottom, so secret_keeper and
-- overachiever stay last. Names and descriptions are SPOT_ACHV_NAME_<ID> /
-- SPOT_ACHV_DESC_<ID> in the locale files.
-- =============================================================================
local _, ns = ...
local Achievements = ns.SpottingAchievements
local B = Achievements.B

-- Retail facts the shared checks are given here rather than hardcoding.
local CLASS_TOTAL = 13
local JENKINS_TITLE_ID = 110
local INSANE_TITLE_ID = 112
-- The top "spot N titles" step; keep it below the number of titles in the data
-- (694 on 2026-11-07). /epithet admin achvaudit flags it if it is not.
local TOP_COUNT = 650
-- Progress targets; the checks themselves use the same numbers in the engine.
local PEOPLE_WATCHER_THRESHOLD = 500
local PROFESSIONAL_LURKER_THRESHOLD = 2000

Achievements.DefineSet({
    id = "retail-1",
    expected = 76,
    list = {
        { id = "count_1", check = B.CheckCount(1), progress = B.ProgressCountSpotted(1), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Spyglass_02" },
        { id = "count_10", check = B.CheckCount(10), progress = B.ProgressCountSpotted(10), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Eye_01" },
        { id = "count_25", check = B.CheckCount(25), progress = B.ProgressCountSpotted(25), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Note_01" },
        { id = "count_50", check = B.CheckCount(50), progress = B.ProgressCountSpotted(50), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
        { id = "count_100", check = B.CheckCount(100), progress = B.ProgressCountSpotted(100), group = "spotting", icon = "Interface\\Icons\\Ability_Rogue_Shadowstep" },
        { id = "count_200", check = B.CheckCount(200), progress = B.ProgressCountSpotted(200), group = "spotting", icon = "Interface\\Icons\\inv_helm_misc_pignosemask_a_01" },
        { id = "count_350", check = B.CheckCount(350), progress = B.ProgressCountSpotted(350), group = "spotting", icon = "Interface\\Icons\\Achievement_Boss_CThun" },
        { id = "count_500", check = B.CheckCount(500), progress = B.ProgressCountSpotted(500), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        -- "count_700" asked for 700, but Retail's data has 694 titles, so it (and
        -- Secret Keeper, which needs every secret) could not be earned. The id
        -- stays, so nothing saved under it moves; the target is now 650.
        { id = "count_700", check = B.CheckCount(TOP_COUNT), progress = B.ProgressCountSpotted(TOP_COUNT), group = "spotting", secret = true, icon = "Interface\\Icons\\Inv_Box_BirdCage_01" },
        { id = "roll_call", check = B.CheckRollCallOf(CLASS_TOTAL), progress = B.ProgressRollCallOf(CLASS_TOTAL), group = "spotting", icon = "Interface\\Icons\\Achievement_pvp_p_10" },
        { id = "full_spectrum", check = B.CheckFullSpectrum, progress = B.ProgressFullSpectrum, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Gem_Variety_01" },
        { id = "both_ends", check = B.CheckBothEnds, group = "spotting", icon = "Interface\\Icons\\INV_Scroll_03" },
        { id = "grand_tour", check = B.CheckGrandTour, progress = B.ProgressGrandTour, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Map_01" },
        { id = "title_fwends", check = B.CheckTitleFwends, group = "spotting", secret = true, icon = "Interface\\Icons\\Achievement_WorldEvent_Valentine" },
        { id = "havent_we_met", check = B.CheckHaventWeMet, group = "spotting", icon = "Interface\\Icons\\Ability_priest_focusedwill" },
        { id = "long_con", check = B.CheckLongCon, group = "spotting", secret = true, icon = "Interface\\Icons\\Ability_Hunter_Pet_Turtle" },
        { id = "night_shift", check = B.CheckNightShift, group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Holy_ElunesGrace" },
        { id = "busy_day", check = B.CheckBusyDay, group = "spotting", icon = "Interface\\Icons\\Spell_Holy_BorrowedTime" },
        { id = "capital_offence", check = B.CheckCapitalOffence, group = "spotting", icon = "Interface\\Icons\\Inv_jewelcrafting_gem_02" },
        { id = "old_money", check = B.CheckOldMoney, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
        { id = "legendary_spot", check = B.CheckLegendarySpot, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Gem_Topaz_02" },
        { id = "potted_history", check = B.CheckPottedHistory, progress = B.ProgressPottedHistory, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Flower_02" },
        { id = "diplomatic_immunity", check = B.CheckDiplomaticImmunity, group = "spotting", icon = "Interface\\Icons\\Achievement_Reputation_01" },
        { id = "small_world", check = B.CheckSmallWorld, group = "spotting", icon = "Interface\\Icons\\Achievement_Character_Gnome_Male" },
        { id = "creature_of_habit", check = B.CheckCreatureOfHabit, group = "spotting", icon = "Interface\\Icons\\Spell_Nature_Polymorph_Cow" },
        { id = "seeing_stars", check = B.CheckSeeingStars, progress = B.ProgressSeeingStars, group = "spotting", icon = "Interface\\Icons\\Achievement_general_classact" },
        { id = "museum_curator", check = B.CheckMuseumCurator, progress = B.ProgressMuseumCurator, group = "spotting", icon = "Interface\\Icons\\Trade_archaeology_tinydinosaurskeleton" },
        { id = "gnome_spotter", check = B.CheckGnomeSpotter, progress = B.ProgressGnomeSpotter, group = "spotting", icon = "Interface\\Icons\\Ability_mount_mechastrider" },
        { id = "at_least_chicken", check = B.CheckSpottedTitleID(JENKINS_TITLE_ID), group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Magic_PolymorphChicken" },
        { id = "certified", check = B.CheckSpottedTitleID(INSANE_TITLE_ID), group = "spotting", secret = true, icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy" },
        { id = "guising", check = B.CheckGuising, group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Misc_Bag_28_Halloween" },

        { id = "quite_a_mouthful", check = B.CheckQuiteAMouthful, group = "spotting", icon = "Interface\\Icons\\Ability_mage_burnout" },
        { id = "terse", check = B.CheckTerse, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Note_05" },
        { id = "lord_of_lords", check = B.CheckKeyword("lord_of_lords"), progress = B.ProgressKeyword("lord_of_lords"), group = "spotting", icon = "Interface\\Icons\\Achievement_Boss_LichKing" },
        { id = "masterclass", check = B.CheckKeyword("masterclass"), progress = B.ProgressKeyword("masterclass"), group = "spotting", icon = "Interface\\Icons\\Achievement_bg_most_damage_killingblow_dieleast" },
        { id = "slay", check = B.CheckKeyword("slay"), progress = B.ProgressKeyword("slay"), group = "spotting", icon = "Interface\\Icons\\INV_Sword_27" },
        { id = "gladiator_groupie", check = B.CheckGladiatorGroupie, progress = B.ProgressSourceSpotting("pvp"), group = "spotting", icon = "Interface\\Icons\\Achievement_FeatsOfStrength_Gladiator_01" },
        { id = "raid_spectator", check = B.CheckRaidSpectator, progress = B.ProgressSourceSpotting("raid"), group = "spotting", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
        { id = "brown_noser", check = B.CheckBrownNoser, progress = B.ProgressSourceSpotting("reputation"), group = "spotting", icon = "Interface\\Icons\\Achievement_Reputation_03" },
        { id = "how_its_made", check = B.CheckHowItsMade, group = "spotting", icon = "Interface\\Icons\\Trade_Engineering" },
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
        { id = "dead_man_walking", check = B.CheckDeadManWalking, group = "spotting", icon = "Interface\\Icons\\Spell_Deathknight_ClassIcon" },
        { id = "old_school", check = B.CheckOldSchool, group = "spotting", icon = "Interface\\Icons\\Achievement_Zone_Barrens_01" },
        { id = "popular", check = B.CheckPopular, progress = B.ProgressPopular, group = "spotting", icon = "Interface\\Icons\\Spell_shadow_improvedvampiricembrace" },
        { id = "restraining_order", check = B.CheckRestrainingOrder, group = "spotting", secret = true, icon = "Interface\\Icons\\INV_Misc_Note_03" },
        { id = "beyond_the_grave", check = B.CheckBeyondTheGrave, group = "spotting", secret = true, icon = "Interface\\Icons\\Achievement_halloween_ghost_01" },
        { id = "know_thy_enemy", check = B.CheckKnowThyEnemy, group = "spotting", icon = "Interface\\Icons\\INV_BannerPVP_01" },

        { id = "owned_1", check = B.CheckOwnedCount(1), progress = B.ProgressOwnedCount(1), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Crown_01" },
        { id = "owned_10", check = B.CheckOwnedCount(10), progress = B.ProgressOwnedCount(10), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Letter_15" },
        { id = "owned_25", check = B.CheckOwnedCount(25), progress = B.ProgressOwnedCount(25), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Misc_Ribbon_01" },
        { id = "owned_50", check = B.CheckOwnedCount(50), progress = B.ProgressOwnedCount(50), group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Shield_04" },
        { id = "owned_100", check = B.CheckOwnedCount(100), progress = B.ProgressOwnedCount(100), group = "collection", scope = "character", icon = "Interface\\Icons\\Spell_Misc_EmotionHappy" },
        { id = "owned_spectrum", check = B.CheckOwnedSpectrum, progress = B.ProgressOwnedSpectrum, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Chest_Cloth_17" },
        { id = "owned_both_ends", check = B.CheckOwnedBothEnds, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Misc_Book_07" },
        { id = "owned_legendary", check = B.CheckOwnedLegendary, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Staff_Medivh" },
        { id = "owned_removed", check = B.CheckOwnedRemoved, group = "collection", scope = "character", icon = "Interface\\Icons\\Trade_Archaeology" },
        { id = "impulse_purchase", check = B.CheckImpulsePurchase, group = "collection", scope = "character", icon = "Interface\\Icons\\Achievement_guildperk_bartering" },
        { id = "curriculum_vitae", check = B.CheckCurriculumVitae, progress = B.ProgressCurriculumVitae, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Scroll_11" },
        { id = "decorated_veteran", check = B.CheckDecoratedVeteran, progress = B.ProgressDecoratedVeteran, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02" },
        { id = "nothing_new", check = B.CheckNothingNew, group = "collection", scope = "character", icon = "Interface\\Icons\\Spell_Holy_SearingLight" },
        { id = "matching_set", check = B.CheckMatchingSet, group = "collection", scope = "character", icon = "Interface\\Icons\\INV_Misc_Gem_Variety_02" },

        { id = "takes_one", check = B.CheckTakesOne, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\Spell_Nature_MirrorImage" },
        { id = "window_shopper", check = B.CheckWindowShopper, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\INV_Misc_Gift_01" },
        { id = "twinsies", check = B.CheckTwinsies, group = "crossovers", scope = "character", secret = true, icon = "Interface\\Icons\\Spell_Magic_LesserInvisibilty" },

        -- Must be last so the same evaluation pass can count newly-earned achievements.
        { id = "secret_keeper", check = B.CheckSecretKeeper, progress = B.ProgressSecretKeeper, group = "spotting", icon = "Interface\\Icons\\INV_Misc_Key_03" },
        { id = "overachiever", check = B.CheckOverachiever, progress = B.ProgressOverachiever, group = "spotting", icon = "Interface\\Icons\\Achievement_Quests_Completed_06" },
    },
})
