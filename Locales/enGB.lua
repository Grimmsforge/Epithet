-- =============================================================================
-- Epithet — Locale: enGB (default)
-- NOTE: WoW Lua 5.1 does NOT support \xNN hex escapes. Use decimal byte escapes
--       (e.g. \226\128\148 = em dash) or plain ASCII.
-- =============================================================================
local _, ns = ...

-- enGB is the base / default locale: the full English string set that every
-- other locale overlays onto (untranslated keys fall back here). GetLocale()
-- returns "enUS" for both US and GB clients, so this file also serves enUS.
--
-- The localisation machinery — the registry, the ns.L proxy, and the resolution
-- API — lives in LocaleManager.lua, which loads first. This file just registers
-- its strings into ns.Locales.
ns.Locales = ns.Locales or {}

local L = {}
ns.Locales.enGB = L

-- Shared punctuation glyphs (defined once in LocaleManager.lua).
local DOT, DASH = ns.Glyphs.DOT, ns.Glyphs.DASH

-- Window
L["WINDOW_TITLE"] = "TITLES"
L["CLOSE"] = "Close"

-- Header band
L["TITLES_EARNED"] = "TITLES EARNED"
L["TITLES_EARNED_OBTAINABLE"] = "OBTAINABLE EARNED"
L["TOGGLE_ALL_TITLES"] = "Show all titles in count"
L["TOGGLE_OBTAINABLE_ONLY"] = "Show only obtainable titles in count"
L["TOGGLE_OBTAINABLE_LABEL"] = "Obtainable only"

-- Filter sidebar
L["SEARCH_PLACEHOLDER"] = "Search titles or sources..."
L["STATUS"] = "STATUS"
L["STATUS_ALL"] = "All"
L["STATUS_EARNED"] = "Earned"
L["STATUS_UNEARNED"] = "Unearned"
L["RARITY_TIER"] = "Rarity Tier"
L["TYPE"] = "Type"
L["EXPANSION"] = "Expansion"
L["ADDITIONAL_FILTERS"] = "Additional Filters"
L["RESET_ALL_FILTERS"] = "Reset all filters"
L["FAVOURITES_ONLY"] = "Favourites only"
L["ADD_FAVOURITE"] = "Add to Favourites"
L["REMOVE_FAVOURITE"] = "Remove from Favourites"
L["PREFIX"] = "Prefix"
L["SUFFIX"] = "Suffix"

-- Rarity names
L["COMMON"] = "Common"
L["UNCOMMON"] = "Uncommon"
L["RARE"] = "Rare"
L["EPIC"] = "Epic"
L["LEGENDARY"] = "Legendary"
L["UNRANKED"] = "Unranked"

-- List header
L["N_TITLES"] = "%d titles"
L["SORT_COLLECTED_FIRST"] = "Collected first"
L["SORT_BY_EXPANSION"] = "By expansion"
L["SORT_ALPHABETICAL"] = "Alphabetical"
L["SORT_BY_QUALITY"] = "By quality"
L["SORT_BY_CATEGORY"] = "By category"

-- Group headers
L["GROUP_COLLECTED"] = "COLLECTED"
L["GROUP_NOT_COLLECTED"] = "NOT YET COLLECTED"

-- Detail panel
L["PREVIEW_HOVERING"] = "PREVIEW " .. DASH .. " HOVERING"
L["PREFIX_TITLE"] = "Prefix title"
L["SUFFIX_TITLE"] = "Suffix title"
L["HOW_TO_OBTAIN"] = "HOW TO OBTAIN"
-- Shown under the source card during hover preview when its content is taller
-- than the card, since the preview cannot be scrolled.
L["DETAIL_MORE_ON_SELECT"] = "Select this title to read more"
L["HELD_BY_ESTIMATE"] = "Held by an estimated %s%% of active characters."
L["EXPANSION_LABEL"] = "Expansion"
L["CATEGORY_LABEL"] = "Category"
L["AVAILABILITY_LABEL"] = "Availability"
L["ACCOUNT_WIDE"] = "Account-wide"
L["NO_LONGER_OBTAINABLE"] = "No longer obtainable"
L["CURRENT_PATCH"] = "Current patch " .. DOT .. " 12.0.5"
L["EARNED_DATE"] = "Earned %s"
L["NOT_YET_EARNED"] = "Not yet earned"

-- Action footer
L["SET_AS_MY_TITLE"] = "Set as My Title"
L["SET_NOTE"] = "Shown beneath your name to other players."
L["CURRENT_TITLE"] = "Current Title"
L["CURRENT_NOTE"] = "This title is displayed above your character."
L["LOCKED_BUTTON"] = "Not Yet Earned"
L["LOCKED_NOTE"] = "Earn this title to set it as your own."

-- Empty states
L["NO_MATCH"] = "No titles match these filters."
L["NO_SELECTION"] = "Select a title to view its source and rarity."

-- Bottom bar / rarity legend
L["RARITY"] = "RARITY"
L["SOURCE_LEGEND"] = "SOURCE"

-- Rarity explanation shown in the rarity info modal. Keep the wording in sync
-- with the rarity algorithm (TitlesDBCollector rarity.js).
L["RARITY_NOTE"] = "Rarity is a 0-100 percentage estimating how common a title is among the " ..
    "active player base. 100 = most widely held, <1 = extremely rare. Calculated from external " ..
    "profile statistics (online popularity data sources). Quality tier (q) reflects prestige: " ..
    "determined by source origin (Gladiator=5, Raid meta=3, etc.) with a scarcity bump applied to " ..
    "permanently unobtainable titles held by few players (unobtainable + <2% ownership = Epic " ..
    "minimum, <5% = Rare minimum)."

-- Minimap
L["MINIMAP_TOOLTIP_TITLE"] = "Epithet"
L["MINIMAP_TOOLTIP_LEFT"] = "Left-click to open the title browser."
L["MINIMAP_TOOLTIP_RIGHT"] = "Right-click to hide this button."
L["MINIMAP_HIDDEN"] = "Minimap button hidden. Type /epithet minimap to show it again."
L["MINIMAP_SHOWN"] = "Minimap button shown."

-- What's New
L["WHATS_NEW_HEADING"] = "What's New"
L["WHATS_NEW_CLOSE"] = "Close"
L["WHATS_NEW_LINK_PROMPT"] = "Copy this link:\nIt's already selected below - press Ctrl+C to copy it."

-- Social layer / title spotting
L["SOCIAL_LAYER"] = "Title Spotting"
L["SOCIAL_LAYER_DESC"] = "Inspecting total strangers is practically a core ability by now. Point it at their titles too: spot what another players have chosen to wear and jump straight in to how it's earned in Epithet."
L["SOCIAL_ENABLED"] = "Enable title spotting"
L["SOCIAL_STATE_SECTION"] = "Feature State"
L["SOCIAL_TARGET_UNLOCK"] = "Unlock target nameplate (drag to move)"
L["SOCIAL_TARGET_RESET"] = "Reset target nameplate position"
L["SOCIAL_TARGET_EDIT_HINT"] = "EDIT MODE · Left-drag to move · Right-click to lock"
L["SOCIAL_TARGET_EDIT_TOP"] = "EDIT MODE"
L["SOCIAL_TARGET_EDIT_BOTTOM"] = "Left-drag to move · Right-click to lock"
L["SOCIAL_TARGET_TOOLTIP_LEFT"] = "Left-click to view this title in Epithet."
L["SOCIAL_TARGET_TOOLTIP_RIGHT"] = "Right-click to unlock and move this nameplate."
L["SOCIAL_TARGET_PLACEHOLDER_TITLE"] = "Example Title"
L["SOCIAL_TARGET_PLACEHOLDER_RARITY"] = "RARE"
L["SOCIAL_PRESTIGE_FORMAT"] = "%s %s"
L["SOCIAL_LAYOUT_SECTION"] = "Nameplate Layout"
L["SOCIAL_LAYOUT_CLASSIC"] = "Slimline"
L["SOCIAL_LAYOUT_PORTRAIT"] = "Portrait Card"
L["SOCIAL_LAYOUT_PREVIEW"] = "Layout Preview"
L["SOCIAL_LAYOUT_PREVIEW_NOTE"] = "Preview uses sample data."
L["SOCIAL_LAYOUT_FUNNY_TOGGLE"] = "Show funny long-title preview"
L["SOCIAL_LAYOUT_PORTRAIT_MODE"] = "Target portrait mode"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_3D"] = "3D (animated)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_2D"] = "2D (static)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_NOTE"] = "3D uses an animated model. 2D uses a static portrait texture."
L["SOCIAL_BEHAVIOUR_SECTION"] = "Visibility Rules"
L["SOCIAL_FADE_SECTION"] = "Fade"
L["SOCIAL_FADE_ENABLE"] = "Fade target nameplates after a delay"
L["SOCIAL_FADE_DURATION"] = "Fade delay"
L["SOCIAL_FADE_DURATION_FMT"] = "%.1f seconds before fade"
L["SOCIAL_SHOW_SELF_TARGET"] = "Show target nameplate when targeting yourself"
L["SOCIAL_SELF_TARGET_NOTE"] = "Showing your own target nameplate is visual only. Targeting yourself never counts toward title spotting achievements."
L["SOCIAL_SPOTTING_NOTIFY"] = "Show spotting confirmations in chat"
L["SOCIAL_ACHIEVEMENT_SECTION"] = "Achievements"
L["SOCIAL_ACHIEVEMENT_LAYER_DESC"] = "Achievement pop-ups cover your own title collection as well as titles you've spotted on others. Configure how they notify you here - title spotting itself is switched on from its own tab."
L["SOCIAL_ACHIEVEMENT_SPOTTING_DISABLED_NOTE"] = "Title spotting is off, so spotting achievements can't progress. Turn it on from the Title Spotting tab to keep them updating. Achievements based on your own title collection are still tracked."
L["SOCIAL_ACHIEVEMENT_NOTIFY"] = "Achievement notifications"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE"] = "Achievement notification mode"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_FULL"] = "Popup + sound"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_SILENT"] = "Popup only (mute sound)"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_OFF"] = "Off"
L["SOCIAL_ACHIEVEMENT_ANCHOR_MODE"] = "Achievement popup anchor"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT"] = "Screen top (UIParent)"
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME"] = "Match Blizzard AlertFrame"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT_DESC"] = "Anchors to the top-center of the screen. Most reliable if AlertFrame is moved or hidden by UI mods."
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME_DESC"] = "Follows Blizzard achievement/loot toast area. If another addon moves or hides AlertFrame, this popup moves with it."
L["SOCIAL_POSITION_SECTION"] = "Position"

L["SPOTTING_NEW_SPOT_FMT"] = "Spotted: %s"
L["SPOTTING_LOG_TOOLTIP"] = "Spotting Log (%d found)"
L["SPOTTING_LOG_TOOLTIP_LEFT"] = "Left-click: Open title spotting log."
L["SPOTTING_LOG_TOOLTIP_RIGHT"] = "Right-click: Shout your spotting stats in /s."
L["SPOTTING_LOG_SHOUT_FMT_1"] = "I've admired %d strangers a completely normal amount!"
L["SPOTTING_LOG_SHOUT_FMT_2"] = "I have inspected %d strangers against their knowledge and consent!"
L["SPOTTING_LOG_SHOUT_FMT_3"] = "I've been quietly judging the titles of %d strangers!"
L["SPOTTING_LOG_SHOUT_FMT_4"] = "%d strangers have been observed. None of them noticed. Excellent."
L["SPOTTING_LOG_SHOUT_FMT_5"] = "I've stalked %d unsuspecting adventurers for their titles alone!"
L["SPOTTING_LOG_HEADING"] = "Spotting Log"
L["SPOTTING_LOG_COUNT_FMT"] = "%d titles spotted"
L["SPOTTING_LOG_COUNT_PROGRESS_FMT"] = "%d / %d titles spotted"
L["SPOTTING_LOG_COUNT_REMAINING_FMT"] = "%d titles remaining"
L["SPOTTING_LOG_EMPTY"] = "Nothing spotted yet. Target players in the wild to log the titles they are wearing."
L["SPOTTING_LOG_EMPTY_REMAINING"] = "No remaining titles in the current catalogue."
L["SPOTTING_LOG_GATED"] = "Title spotting is off. Sightings are not being recorded."
L["SPOTTING_LOG_OPEN_SETTINGS"] = "Enable in Settings"
L["SPOTTING_SCOPE_SPOTTED"] = "Spotted"
L["SPOTTING_SCOPE_REMAINING"] = "Remaining"
L["SPOTTING_VIEW_LIST"] = "List"
L["SPOTTING_VIEW_GRID"] = "Grid"
L["SPOTTING_EXPORT_BUTTON"] = "Export"
L["SPOTTING_IMPORT_BUTTON"] = "Import"
L["SPOTTING_EXPORT_TITLE"] = "Export Spotting Log"
L["SPOTTING_IMPORT_TITLE"] = "Import Spotting Log"
L["SPOTTING_TRANSFER_NOTE"] = "Copy or paste the full payload below."
L["SPOTTING_TRANSFER_COPY"] = "Select All"
L["SPOTTING_TRANSFER_IMPORT"] = "Import"
L["SPOTTING_TRANSFER_CLOSE"] = "Close"
L["SPOTTING_IMPORT_SUCCESS_FMT"] = "Imported %d spotting entries."
L["SPOTTING_IMPORT_FAILED_FMT"] = "Import failed: %s"
L["SPOTTING_NOT_SPOTTED"] = "Remaining"
L["SPOTTING_NOT_SPOTTED_YET"] = "Not spotted yet."
L["SPOTTING_TOOLTIP_FIRST_FMT"] = "First spotted on %s in %s on %s"
L["SPOTTING_TOOLTIP_RACE_FMT"] = "Race: %s"
L["SPOTTING_TOOLTIP_RACE_UNKNOWN"] = "Unknown"
L["SPOTTING_TOOLTIP_COUNT_FMT"] = "Seen %d times"
L["SPOTTING_TOOLTIP_LAST_FMT"] = "Last seen on %s as %s"

L["SPOT_ACHV_MODE"] = "Achievements"
L["SPOT_ACHV_HEADING"] = "Epithet Achievements"
L["SPOT_ACHV_TOOLTIP"] = "Epithet Achievements"
L["SPOT_ACHV_TOOLTIP_LEFT"] = "Left-click: Open Epithet achievements."
L["SPOT_ACHV_EMPTY"] = "No Epithet achievements available."
L["SPOT_ACHV_META_TITLE"] = "Achievement Hunting Notes"
L["SPOT_ACHV_META_DESC"] = "To complete every achievement, you may need to coordinate your spotting across classes, factions, calendar windows, and repeated sightings with friends or guildmates."
L["SPOT_ACHV_COUNT_FMT"] = "%d / %d earned"
L["SPOT_ACHV_GROUP_SPOTTING"] = "Spotting"
L["SPOT_ACHV_GROUP_COLLECTION"] = "Collection"
L["SPOT_ACHV_GROUP_CROSSOVERS"] = "Crossovers"
L["SPOT_ACHV_SECRET_NAME"] = "???"
L["SPOT_ACHV_SECRET_DESC"] = "Secret achievement"
L["SPOT_ACHV_PROGRESS_FMT"] = "%d / %d"
L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"] = "%d / %d on this character"
L["SPOT_ACHV_EARNED_FMT"] = "Earned %s"
L["SPOT_ACHV_ALERT_HEADER"] = "Epithet Achievement"
L["SPOT_ACHV_CHAT_EARNED_FMT"] = "Achievement earned - %s!"
L["SPOT_ACHV_DETAIL_WITH_FMT"] = "earned with %s"
L["SPOT_ACHV_DETAIL_CLASSES_FMT"] = "earned across %s classes"
L["SPOT_ACHV_DETAIL_ZONE_FMT"] = "earned in %s"
L["SPOT_ACHV_DETAIL_TITLE_FMT"] = "triggered by %s"
L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"] = "earned across %s expansions"
L["SPOT_ACHV_DETAIL_SECRETS_FMT"] = "earned across %s secrets"
L["SPOT_ACHV_FWENDS_HINT"] = "Counts titles you spotted for the very first time on them."
L["SPOT_ACHV_DETAIL_TITLE"] = "Achievement Details"
L["SPOT_ACHV_DETAIL_CLOSE"] = "Close"
L["SPOT_ACHV_DETAIL_SECRET_STATUS"] = "Earn this achievement to reveal details."
L["SPOT_ACHV_ADMIN_TEST_NAME"] = "Admin Test Achievement"
L["SPOT_ACHV_ADMIN_TEST_DESC"] = "Manual admin-triggered popup test."

L["SPOT_ACHV_NAME_COUNT_1"] = "First Sighting"
L["SPOT_ACHV_DESC_COUNT_1"] = "Spot 1 distinct title in the wild."
L["SPOT_ACHV_NAME_COUNT_10"] = "Keen Eye"
L["SPOT_ACHV_DESC_COUNT_10"] = "Spot 10 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_25"] = "Field Notes"
L["SPOT_ACHV_DESC_COUNT_25"] = "Spot 25 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_50"] = "Seasoned Spotter"
L["SPOT_ACHV_DESC_COUNT_50"] = "Spot 50 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_100"] = "Personal Space Is a Myth"
L["SPOT_ACHV_DESC_COUNT_100"] = "Spot 100 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_200"] = "Nosy Parker"
L["SPOT_ACHV_DESC_COUNT_200"] = "Spot 200 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_350"] = "Compulsive Watcher"
L["SPOT_ACHV_DESC_COUNT_350"] = "Spot 350 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_500"] = "Living Rolodex"
L["SPOT_ACHV_DESC_COUNT_500"] = "Spot 500 distinct titles in the wild."
L["SPOT_ACHV_NAME_COUNT_700"] = "The Whole Aviary"
L["SPOT_ACHV_DESC_COUNT_700"] = "Spot 700 distinct titles in the wild."

L["SPOT_ACHV_NAME_ROLL_CALL"] = "Roll Call"
L["SPOT_ACHV_DESC_ROLL_CALL"] = "Spot titles first seen across all classes."
L["SPOT_ACHV_NAME_FULL_SPECTRUM"] = "Full Spectrum"
L["SPOT_ACHV_DESC_FULL_SPECTRUM"] = "Spot at least one title from each rarity tier."
L["SPOT_ACHV_NAME_BOTH_ENDS"] = "Both Ends"
L["SPOT_ACHV_DESC_BOTH_ENDS"] = "Spot at least one prefix and one suffix title."
L["SPOT_ACHV_NAME_GRAND_TOUR"] = "Grand Tour"
L["SPOT_ACHV_DESC_GRAND_TOUR"] = "First-spot titles across 10 distinct zones."
L["SPOT_ACHV_NAME_TITLE_FWENDS"] = "Ooooh, Title Fwends!"
L["SPOT_ACHV_DESC_TITLE_FWENDS"] = "First-spot 10 different titles on the same player."
L["SPOT_ACHV_NAME_HAVENT_WE_MET"] = "Haven't We Met?"
L["SPOT_ACHV_DESC_HAVENT_WE_MET"] = "See the same title at least 10 times."
L["SPOT_ACHV_NAME_LONG_CON"] = "The Long Con"
L["SPOT_ACHV_DESC_LONG_CON"] = "See a title again at least 30 days after first spotting it."
L["SPOT_ACHV_NAME_NIGHT_SHIFT"] = "Night Shift"
L["SPOT_ACHV_DESC_NIGHT_SHIFT"] = "First-spot a title between 03:00 and 04:59 local time."
L["SPOT_ACHV_NAME_BUSY_DAY"] = "Busy Day"
L["SPOT_ACHV_DESC_BUSY_DAY"] = "First-spot at least 5 titles on the same local date."
L["SPOT_ACHV_NAME_CAPITAL_OFFENCE"] = "Capital Offence"
L["SPOT_ACHV_DESC_CAPITAL_OFFENCE"] = "First-spot at least 10 titles in the same zone."
L["SPOT_ACHV_NAME_OLD_MONEY"] = "Old Money"
L["SPOT_ACHV_DESC_OLD_MONEY"] = "Spot a title that is no longer obtainable."
L["SPOT_ACHV_NAME_LEGENDARY_SPOT"] = "Completionist's Nightmare"
L["SPOT_ACHV_DESC_LEGENDARY_SPOT"] = "Spot a Legendary-quality title in the wild."
L["SPOT_ACHV_NAME_POTTED_HISTORY"] = "A Potted History"
L["SPOT_ACHV_DESC_POTTED_HISTORY"] = "Spot at least one title from every expansion."
L["SPOT_ACHV_NAME_DIPLOMATIC_IMMUNITY"] = "Diplomatic Immunity"
L["SPOT_ACHV_DESC_DIPLOMATIC_IMMUNITY"] = "Spot at least one Alliance-locked and one Horde-locked title."
L["SPOT_ACHV_NAME_SMALL_WORLD"] = "Small World"
L["SPOT_ACHV_DESC_SMALL_WORLD"] = "See the same title on two different people."
L["SPOT_ACHV_NAME_CREATURE_OF_HABIT"] = "Creature of Habit"
L["SPOT_ACHV_DESC_CREATURE_OF_HABIT"] = "First-spot at least one title on 7 consecutive local days."
L["SPOT_ACHV_NAME_SEEING_STARS"] = "Seeing Stars"
L["SPOT_ACHV_DESC_SEEING_STARS"] = "Spot 5 Legendary-quality titles."
L["SPOT_ACHV_NAME_MUSEUM_CURATOR"] = "Museum Curator"
L["SPOT_ACHV_DESC_MUSEUM_CURATOR"] = "Spot 5 titles from removed content."
L["SPOT_ACHV_NAME_GNOME_SPOTTER"] = "Pocket Census"
L["SPOT_ACHV_DESC_GNOME_SPOTTER"] = "Spot 5 titles first seen on gnomes."
L["SPOT_ACHV_NAME_AT_LEAST_CHICKEN"] = "At Least I Have Chicken"
L["SPOT_ACHV_DESC_AT_LEAST_CHICKEN"] = "Spot someone wearing Jenkins."
L["SPOT_ACHV_NAME_CERTIFIED"] = "Certified"
L["SPOT_ACHV_DESC_CERTIFIED"] = "Spot someone wearing the Insane."
L["SPOT_ACHV_NAME_OVERACHIEVER"] = "Overachiever"
L["SPOT_ACHV_DESC_OVERACHIEVER"] = "Earn 15 Epithet achievements across spotting and collection."
L["SPOT_ACHV_NAME_GUISING"] = "Guising"
L["SPOT_ACHV_DESC_GUISING"] = "First-spot any title on 31 October (local time)."
L["SPOT_ACHV_NAME_QUITE_A_MOUTHFUL"] = "A Bit of a Mouthful"
L["SPOT_ACHV_DESC_QUITE_A_MOUTHFUL"] = "Spot a title whose catalogue text is 25 characters or longer."
L["SPOT_ACHV_NAME_TERSE"] = "Terse"
L["SPOT_ACHV_DESC_TERSE"] = "Spot a title whose catalogue text is 5 characters or fewer."
L["SPOT_ACHV_NAME_LORD_OF_LORDS"] = "Lord of Lords"
L["SPOT_ACHV_DESC_LORD_OF_LORDS"] = "Spot 5 distinct titles containing 'Lord'."
L["SPOT_ACHV_NAME_MASTERCLASS"] = "Masterclass"
L["SPOT_ACHV_DESC_MASTERCLASS"] = "Spot 5 distinct titles containing 'Master'."
L["SPOT_ACHV_NAME_SLAY"] = "Slay"
L["SPOT_ACHV_DESC_SLAY"] = "Spot 5 distinct titles containing 'Slayer'."
L["SPOT_ACHV_NAME_GLADIATOR_GROUPIE"] = "Gladiator Groupie"
L["SPOT_ACHV_DESC_GLADIATOR_GROUPIE"] = "Spot 5 titles from PvP sources."
L["SPOT_ACHV_NAME_RAID_SPECTATOR"] = "Raid Spectator"
L["SPOT_ACHV_DESC_RAID_SPECTATOR"] = "Spot 5 titles from raid sources."
L["SPOT_ACHV_NAME_BROWN_NOSER"] = "Brown-Noser"
L["SPOT_ACHV_DESC_BROWN_NOSER"] = "Spot 5 titles from reputation sources."
L["SPOT_ACHV_NAME_HOW_ITS_MADE"] = "How It's Made"
L["SPOT_ACHV_DESC_HOW_ITS_MADE"] = "Spot titles sourced from an achievement, a quest, and an item."
L["SPOT_ACHV_NAME_PEOPLE_WATCHER"] = "People Watcher"
L["SPOT_ACHV_DESC_PEOPLE_WATCHER"] = "Record 500 total sightings."
L["SPOT_ACHV_NAME_PROFESSIONAL_LURKER"] = "Professional Lurker"
L["SPOT_ACHV_DESC_PROFESSIONAL_LURKER"] = "Record 2,000 total sightings."
L["SPOT_ACHV_NAME_DOUBLE_TAKE"] = "Double Take"
L["SPOT_ACHV_DESC_DOUBLE_TAKE"] = "See the same title twice within one hour of first spotting it."
L["SPOT_ACHV_NAME_EARLY_BIRD"] = "The Early Bird"
L["SPOT_ACHV_DESC_EARLY_BIRD"] = "First-spot a title between 05:00 and 08:59 local time."
L["SPOT_ACHV_NAME_WEEKEND_WARRIOR"] = "Weekend Warrior"
L["SPOT_ACHV_DESC_WEEKEND_WARRIOR"] = "Record 10 first sightings on Saturday or Sunday."
L["SPOT_ACHV_NAME_FULL_WEEK"] = "The Full Week"
L["SPOT_ACHV_DESC_FULL_WEEK"] = "Record first sightings on all 7 days of the week."
L["SPOT_ACHV_NAME_YEAR_IN_FIELD"] = "A Year in the Field"
L["SPOT_ACHV_DESC_YEAR_IN_FIELD"] = "Record first sightings in all 12 calendar months."
L["SPOT_ACHV_NAME_WELCOME_BACK"] = "Welcome Back"
L["SPOT_ACHV_DESC_WELCOME_BACK"] = "Have at least a 90-day gap between consecutive first sightings."
L["SPOT_ACHV_NAME_FEAST_YOUR_EYES"] = "Feast Your Eyes"
L["SPOT_ACHV_DESC_FEAST_YOUR_EYES"] = "First-spot a title on 25 December (local time)."
L["SPOT_ACHV_NAME_PARTICIPATION_AWARD"] = "Participation Award"
L["SPOT_ACHV_DESC_PARTICIPATION_AWARD"] = "Spot a Common-quality title in the wild."
L["SPOT_ACHV_NAME_SNEAKY_BEAKY"] = "Sneaky Beaky Like"
L["SPOT_ACHV_DESC_SNEAKY_BEAKY"] = "First-spot a title on a Rogue."
L["SPOT_ACHV_NAME_DEAD_MAN_WALKING"] = "Dead Man Walking"
L["SPOT_ACHV_DESC_DEAD_MAN_WALKING"] = "First-spot a title on a Death Knight."
L["SPOT_ACHV_NAME_OLD_SCHOOL"] = "Old School"
L["SPOT_ACHV_DESC_OLD_SCHOOL"] = "Spot a Classic-era title."
L["SPOT_ACHV_NAME_POPULAR"] = "Popular"
L["SPOT_ACHV_DESC_POPULAR"] = "Have 3 different people each account for 5 or more first sightings."
L["SPOT_ACHV_NAME_RESTRAINING_ORDER"] = "Restraining Order"
L["SPOT_ACHV_DESC_RESTRAINING_ORDER"] = "See the same title at least 25 times."
L["SPOT_ACHV_NAME_BEYOND_THE_GRAVE"] = "Beyond the Grave"
L["SPOT_ACHV_DESC_BEYOND_THE_GRAVE"] = "Record a sighting while dead or as a ghost."
L["SPOT_ACHV_NAME_KNOW_THY_ENEMY"] = "Know Thy Enemy"
L["SPOT_ACHV_DESC_KNOW_THY_ENEMY"] = "Record a sighting on an opposite-faction player."
L["SPOT_ACHV_NAME_SECRET_KEEPER"] = "Secret Keeper"
L["SPOT_ACHV_DESC_SECRET_KEEPER"] = "Earn every currently-defined secret achievement."

L["SPOT_ACHV_NAME_OWNED_1"] = "First of My Name"
L["SPOT_ACHV_DESC_OWNED_1"] = "Own 1 title on this character."
L["SPOT_ACHV_NAME_OWNED_10"] = "Letters After My Name"
L["SPOT_ACHV_DESC_OWNED_10"] = "Own 10 titles on this character."
L["SPOT_ACHV_NAME_OWNED_25"] = "Local Celebrity"
L["SPOT_ACHV_DESC_OWNED_25"] = "Own 25 titles on this character."
L["SPOT_ACHV_NAME_OWNED_50"] = "Peerage"
L["SPOT_ACHV_DESC_OWNED_50"] = "Own 50 titles on this character."
L["SPOT_ACHV_NAME_OWNED_100"] = "Delusions of Grandeur"
L["SPOT_ACHV_DESC_OWNED_100"] = "Own 100 titles on this character."
L["SPOT_ACHV_NAME_OWNED_SPECTRUM"] = "Dressed for Every Occasion"
L["SPOT_ACHV_DESC_OWNED_SPECTRUM"] = "Own at least one title from each rarity tier."
L["SPOT_ACHV_NAME_OWNED_BOTH_ENDS"] = "Bookended"
L["SPOT_ACHV_DESC_OWNED_BOTH_ENDS"] = "Own at least one prefix and one suffix title."
L["SPOT_ACHV_NAME_OWNED_LEGENDARY"] = "Above My Station"
L["SPOT_ACHV_DESC_OWNED_LEGENDARY"] = "Own a Legendary-quality title."
L["SPOT_ACHV_NAME_OWNED_REMOVED"] = "Discontinued Stock"
L["SPOT_ACHV_DESC_OWNED_REMOVED"] = "Own a title from removed content."
L["SPOT_ACHV_NAME_IMPULSE_PURCHASE"] = "Impulse Purchase"
L["SPOT_ACHV_DESC_IMPULSE_PURCHASE"] = "Come to own a title within 7 days of first spotting it."
L["SPOT_ACHV_NAME_CURRICULUM_VITAE"] = "Curriculum Vitae"
L["SPOT_ACHV_DESC_CURRICULUM_VITAE"] = "Own at least one title from every expansion on this character."
L["SPOT_ACHV_NAME_DECORATED_VETERAN"] = "Decorated Veteran"
L["SPOT_ACHV_DESC_DECORATED_VETERAN"] = "Own 5 PvP-source titles on this character."
L["SPOT_ACHV_NAME_NOTHING_NEW"] = "Nothing New Under the Sun"
L["SPOT_ACHV_DESC_NOTHING_NEW"] = "With at least 10 owned titles, have all of them also spotted in the wild."
L["SPOT_ACHV_NAME_MATCHING_SET"] = "Matching Set"
L["SPOT_ACHV_DESC_MATCHING_SET"] = "For each rarity tier, own and spot at least one title in that tier."

L["SPOT_ACHV_NAME_TAKES_ONE"] = "Takes One to Know One"
L["SPOT_ACHV_DESC_TAKES_ONE"] = "Spot in the wild a title this character already owned."
L["SPOT_ACHV_NAME_WINDOW_SHOPPER"] = "Window Shopper"
L["SPOT_ACHV_DESC_WINDOW_SHOPPER"] = "Come to own a title you first spotted on someone else."
L["SPOT_ACHV_NAME_TWINSIES"] = "Twinsies"
L["SPOT_ACHV_DESC_TWINSIES"] = "Spot someone while you are both displaying the same title."

-- Source kinds
L["KIND_ACHIEVEMENT"] = "Achievement"
L["KIND_QUEST"] = "Quest"
L["KIND_REPUTATION"] = "Reputation"
L["KIND_PVP_RANK"] = "PvP Rank"
L["KIND_FEAT"] = "Feat of Strength"
L["KIND_ITEM"] = "Item"
L["KIND_PROMOTION"] = "Promotion"

-- Filter facets (new)
L["CATEGORY"] = "Category"
L["KIND"] = "Source Kind"
L["FACTION"] = "Faction"
L["FACTION_ALLIANCE"] = "Alliance"
L["FACTION_HORDE"] = "Horde"
L["FACTION_BOTH"] = "Both Factions"
L["AVAILABILITY"] = "Availability"
L["HIDE_UNOBTAINABLE"] = "Hide unobtainable"
L["HIDE_TIME_SENSITIVE"] = "Hide time-sensitive"
L["UNKNOWN_SOURCE"] = "Unknown source"
L["FEAT_OF_STRENGTH"] = "Feat of Strength (may be unobtainable)"

-- Source descriptions
L["SOURCE_ACHIEVEMENT_DESC"] = "Awarded by the achievement %s"
L["SOURCE_QUEST_DESC"] = "Awarded during the quest %s"
L["SOURCE_ITEM_DESC"] = "Granted by %s"

-- Meta grid
L["LAST_ASSESSED"] = "Last assessed"

-- Availability labels
L["AVAILABILITY_SEASONAL"] = "Seasonal"
L["AVAILABILITY_LIMITED"] = "Limited"
L["AVAILABILITY_PROMOTIONAL"] = "Promotional"
L["AVAILABILITY_TEMPORARY"] = "Temporary"
L["AVAILABILITY_REMOVED"] = "Removed"
L["AVAILABILITY_PERMANENT"] = "Permanent"

-- Previously-missing keys (had inline English fallbacks in code)
L["SOCIAL_HIDE_IN_COMBAT"] = "Hide target nameplate during combat"
L["SOCIAL_HIDE_IN_GROUP"] = "Hide target nameplate when grouped"
L["SPOTTING_META_TITLE"] = "Spotting Notes"
L["SPOTTING_META_DESC"] = "Target players in the open world to record the titles they are wearing."
L["SPOT_ACHV_SECRET_EARNED_SUFFIX"] = "(secret)"
L["SPOT_ACHV_SECRET_EARNED_NOTE"] = "You uncovered a secret achievement."

-- Window banner (main frame title bar)
L["BANNER_LEFT"] = "EPITHET"
L["BANNER_RIGHT"] = "THE TITLE SHOWCASE"

-- Type tags (uppercase pills on title rows)
L["TYPE_TAG_PREFIX"] = "PREFIX"
L["TYPE_TAG_SUFFIX"] = "SUFFIX"

-- Rarity fallback
L["RARITY_UNKNOWN"] = "UNKNOWN"

-- Minimap tooltip collected line
L["MINIMAP_TOOLTIP_COLLECTED"] = "Collected: %d / %d"

-- Slash command feedback
L["SLASH_SCAN_COMPLETE"] = "Title scan complete: %d / %d"

-- Version footer (two rows). %s placeholders filled at runtime.
L["VERSION_LINE1_FMT"] = "Epithet v%s  " .. DOT .. "  Interface %s"
L["VERSION_LINE2_FMT"] = "TitlesDB v%s  " .. DOT .. "  Updated %s"
L["VERSION_DATE_UNKNOWN"] = "unknown"

-- Source-kind legend (bottom bar hover labels)
L["LEGEND_ACHIEVEMENT"] = "Achievement"
L["LEGEND_QUEST"] = "Quest"
L["LEGEND_REPUTATION"] = "Reputation"
L["LEGEND_PVP"] = "PvP"
L["LEGEND_FEAT"] = "Feat"
L["LEGEND_EXPLORATION"] = "Exploration"
L["LEGEND_RAID"] = "Raid"

-- Layout preview sample data
L["SAMPLE_TITLE"] = "Trash Master"
L["SAMPLE_RARITY"] = "LEGENDARY"
L["SAMPLE_FUNNY_TITLE"] = "Slayer of Stupid, Incompetent and Disappointing Minions"

-- Fade slider bound labels
L["FADE_SLIDER_LOW"] = "0.5s"
L["FADE_SLIDER_HIGH"] = "20s"

-- Month names (used to format achievement earned dates: "dd Month yyyy")
L["MONTH_1"]  = "January"
L["MONTH_2"]  = "February"
L["MONTH_3"]  = "March"
L["MONTH_4"]  = "April"
L["MONTH_5"]  = "May"
L["MONTH_6"]  = "June"
L["MONTH_7"]  = "July"
L["MONTH_8"]  = "August"
L["MONTH_9"]  = "September"
L["MONTH_10"] = "October"
L["MONTH_11"] = "November"
L["MONTH_12"] = "December"

-- Expansion names (filter sidebar, detail panel, list rows). Keyed to match
-- the DB's stable expansion codes uppercased, e.g. "tbc" -> EXPANSION_TBC.
L["EXPANSION_CLASSIC"] = "Classic"
L["EXPANSION_TBC"] = "The Burning Crusade"
L["EXPANSION_WRATH"] = "Wrath of the Lich King"
L["EXPANSION_CATA"] = "Cataclysm"
L["EXPANSION_MOP"] = "Mists of Pandaria"
L["EXPANSION_WOD"] = "Warlords of Draenor"
L["EXPANSION_LEGION"] = "Legion"
L["EXPANSION_BFA"] = "Battle for Azeroth"
L["EXPANSION_SL"] = "Shadowlands"
L["EXPANSION_DF"] = "Dragonflight"
L["EXPANSION_TWW"] = "The War Within"
L["EXPANSION_MID"] = "Midnight"

-- Category names (filter sidebar, detail panel, list rows, group headers).
-- Keyed to match the DB's stable category codes uppercased, e.g. "PvP" -> CAT_PVP.
L["CAT_PVP"] = "PvP"
L["CAT_RAID"] = "Raid"
L["CAT_REPUTATION"] = "Reputation"
L["CAT_QUEST"] = "Quest"
L["CAT_PROFESSION"] = "Profession"
L["CAT_HOLIDAY"] = "Holiday"
L["CAT_EXPLORATION"] = "Exploration"
L["CAT_ACHIEVEMENT"] = "Achievement"
L["CAT_CAMPAIGN"] = "Campaign"
L["CATEGORY_UNCATEGORIZED"] = "Uncategorized"

-- Detail panel meta-grid row labels
L["EARNED_LABEL"] = "Earned"
L["STATUS_LABEL"] = "Status"

-- "ACTIVE" chip on the currently-equipped title's list row
L["ACTIVE_TITLE"] = "ACTIVE"

-- About / info modal ("Grimmsforge" and "World of Warcraft" stay as-is: brands)
L["ABOUT_CRAFTED"] = "Epithet is crafted by Grimmsforge."
L["ABOUT_TAGLINE"] = "Open-source tools and addons for World of Warcraft."

-- Title-bar settings button
L["SETTINGS_BUTTON_TOOLTIP"] = "Open Epithet settings"
L["INFO_BUTTON_TOOLTIP"] = "About Epithet"

-- Language names (shown in the picker, in the active language)
L["LANGUAGE_ENGLISH"] = "English"
L["LANGUAGE_RUSSIAN"] = "Russian"
L["LANGUAGE_GERMAN"] = "German"
L["LANGUAGE_FRENCH"] = "French"
L["LANGUAGE_SIMPLIFIED_CHINESE"] = "Simplified Chinese"

-- Options: general section (main Epithet settings page)
L["OPTIONS_GENERAL_SECTION"] = "General"
L["OPTIONS_GENERAL_DESC"] = "Settings that apply across Epithet as a whole."
L["OPTIONS_STARTUP_SECTION"] = "Startup"
L["OPTIONS_WHATSNEW_STARTUP_TOGGLE"] = "Show What's New after an update"
L["OPTIONS_WHATSNEW_STARTUP_NOTE"] = "Shown once the first time you log in on a new version. You can always reopen it with /epithet whatsnew."

-- Options: language section
L["OPTIONS_LANGUAGE_SECTION"] = "Language"
L["OPTIONS_LANGUAGE_LABEL"] = "Add-on language"
L["OPTIONS_LANGUAGE_AUTO"] = "Automatic (client default)"
L["OPTIONS_LANGUAGE_NOTE"] = "Sets the language Epithet uses, independent of your game client. The interface reloads when you change it."
L["OPTIONS_LANGUAGE_RELOAD_PROMPT"] = "Change Epithet's language and reload the interface now?"
L["RELOAD_NOW"] = "Reload Now"
L["LATER"] = "Later"

-- The locale registry, ns.L proxy, and resolution API live in LocaleManager.lua.
