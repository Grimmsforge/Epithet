-- =============================================================================
-- Epithet — Locale: deDE
-- NOTE: WoW Lua 5.1 does NOT support \xNN hex escapes. Use decimal byte escapes
--       (e.g. \226\128\148 = em dash) or plain ASCII. This file is UTF-8, so
--       German characters are written directly.
-- =============================================================================
local _, ns = ...

-- Register the German table into the locale registry. It is always loaded (no
-- GetLocale guard) so the language picker can offer it on any client; the active
-- locale is chosen by ns.ApplyLocale, and untranslated keys fall back to the
-- English base automatically (see enGB.lua).
ns.Locales = ns.Locales or {}
local L = {}
ns.Locales.deDE = L

-- Shared punctuation glyphs (defined once in LocaleManager.lua).
local DOT, DASH = ns.Glyphs.DOT, ns.Glyphs.DASH

-- Window
L["WINDOW_TITLE"] = "TITEL"
L["CLOSE"] = "Schließen"

-- Header band
L["TITLES_EARNED"] = "TITEL ERHALTEN"
L["TITLES_EARNED_OBTAINABLE"] = "VERFÜGBARE ERHALTEN"
L["TOGGLE_ALL_TITLES"] = "Alle Titel im Zähler anzeigen"
L["TOGGLE_OBTAINABLE_ONLY"] = "Nur verfügbare Titel im Zähler anzeigen"
L["TOGGLE_OBTAINABLE_LABEL"] = "Nur verfügbar"

-- Filter sidebar
L["SEARCH_PLACEHOLDER"] = "Titel oder Quellen suchen..."
L["STATUS"] = "STATUS"
L["STATUS_ALL"] = "Alle"
L["STATUS_EARNED"] = "Erhalten"
L["STATUS_UNEARNED"] = "Nicht erhalten"
L["RARITY_TIER"] = "Seltenheitsstufe"
L["TYPE"] = "Typ"
L["EXPANSION"] = "Erweiterung"
L["ADDITIONAL_FILTERS"] = "Zusätzliche Filter"
L["RESET_ALL_FILTERS"] = "Alle Filter zurücksetzen"
L["FAVOURITES_ONLY"] = "Nur Favoriten"
L["ADD_FAVOURITE"] = "Zu Favoriten hinzufügen"
L["REMOVE_FAVOURITE"] = "Aus Favoriten entfernen"
L["PREFIX"] = "Präfix"
L["SUFFIX"] = "Suffix"

-- Rarity names
L["COMMON"] = "Gewöhnlich"
L["UNCOMMON"] = "Ungewöhnlich"
L["RARE"] = "Selten"
L["EPIC"] = "Episch"
L["LEGENDARY"] = "Legendär"
L["UNRANKED"] = "Unrangiert"

-- List header
L["N_TITLES"] = "%d Titel"
L["SORT_COLLECTED_FIRST"] = "Zuerst gesammelt"
L["SORT_BY_EXPANSION"] = "Nach Erweiterung"
L["SORT_ALPHABETICAL"] = "Alphabetisch"
L["SORT_BY_QUALITY"] = "Nach Qualität"
L["SORT_BY_CATEGORY"] = "Nach Kategorie"

-- Group headers
L["GROUP_COLLECTED"] = "GESAMMELT"
L["GROUP_NOT_COLLECTED"] = "NOCH NICHT GESAMMELT"

-- Detail panel
L["PREVIEW_HOVERING"] = "VORSCHAU " .. DASH .. " BEIM ÜBERFAHREN"
L["PREFIX_TITLE"] = "Präfixtitel"
L["SUFFIX_TITLE"] = "Suffixtitel"
L["HOW_TO_OBTAIN"] = "SO ERHÄLTST DU ES"
L["DETAIL_MORE_ON_SELECT"] = "Wähle diesen Titel aus, um mehr zu lesen"
L["HELD_BY_ESTIMATE"] = "Wird von schätzungsweise %s%% der aktiven Charaktere getragen."
L["EXPANSION_LABEL"] = "Erweiterung"
L["CATEGORY_LABEL"] = "Kategorie"
L["AVAILABILITY_LABEL"] = "Verfügbarkeit"
L["ACCOUNT_WIDE"] = "Accountweit"
L["NO_LONGER_OBTAINABLE"] = "Nicht mehr erhältlich"
L["CURRENT_PATCH"] = "Aktueller Patch " .. DOT .. " 12.0.5"
L["EARNED_DATE"] = "Erhalten am %s"
L["NOT_YET_EARNED"] = "Noch nicht erhalten"

-- Action footer
L["SET_AS_MY_TITLE"] = "Als meinen Titel setzen"
L["SET_NOTE"] = "Wird anderen Spielern unter deinem Namen angezeigt."
L["CURRENT_TITLE"] = "Aktueller Titel"
L["CURRENT_NOTE"] = "Dieser Titel wird über deinem Charakter angezeigt."
L["LOCKED_BUTTON"] = "Noch nicht erhalten"
L["LOCKED_NOTE"] = "Erhalte diesen Titel, um ihn tragen zu können."

-- Empty states
L["NO_MATCH"] = "Kein Titel passt zu diesen Filtern."
L["NO_SELECTION"] = "Wähle einen Titel aus, um Quelle und Seltenheit anzuzeigen."

-- Bottom bar / rarity legend
L["RARITY"] = "SELTENHEIT"
L["SOURCE_LEGEND"] = "QUELLE"

-- Rarity explanation shown in the rarity info modal. Keep the wording in sync
-- with the rarity algorithm (TitlesDBCollector rarity.js).
L["RARITY_NOTE"] = "Die Seltenheit ist ein Wert von 0 bis 100, der schätzt, wie verbreitet ein " ..
    "Titel in der aktiven Spielerschaft ist. 100 = am weitesten verbreitet, <1 = extrem selten. " ..
    "Berechnet aus externen Profilstatistiken (Online-Datenquellen zur Beliebtheit). Die " ..
    "Qualitätsstufe (q) spiegelt Prestige wider: Sie wird durch die Herkunft der Quelle bestimmt " ..
    "(Gladiator=5, Raid-Meta=3 usw.), mit einem Seltenheitsbonus für dauerhaft nicht mehr " ..
    "erhältliche Titel, die nur wenige Spieler besitzen (nicht erhältlich + <2% Besitz = " ..
    "mindestens Episch, <5% = mindestens Selten)."

-- Minimap
L["MINIMAP_TOOLTIP_TITLE"] = "Epithet"
L["MINIMAP_TOOLTIP_LEFT"] = "Linksklick, um den Titelbrowser zu öffnen."
L["MINIMAP_TOOLTIP_RIGHT"] = "Rechtsklick, um diese Schaltfläche auszublenden."
L["MINIMAP_HIDDEN"] = "Minikarten-Schaltfläche ausgeblendet. Tippe /epithet minimap, um sie wieder anzuzeigen."
L["MINIMAP_SHOWN"] = "Minikarten-Schaltfläche angezeigt."

-- What's New
L["WHATS_NEW_HEADING"] = "Was ist neu"
L["WHATS_NEW_CLOSE"] = "Schließen"
L["WHATS_NEW_LINK_PROMPT"] = "Diesen Link kopieren:\nEr ist unten bereits markiert - drücke Strg+C, um ihn zu kopieren."

-- Social layer / title spotting
L["SOCIAL_LAYER"] = "Titelsichtung"
L["SOCIAL_LAYER_DESC"] = "Völlig Fremde zu inspizieren ist inzwischen praktisch eine Kernfähigkeit. Richte sie auch auf ihre Titel: Sieh, welchen Titel ein anderer Spieler trägt, und spring direkt in Epithet, um zu sehen, wie man ihn erhält."
L["SOCIAL_ENABLED"] = "Titelsichtung aktivieren"
L["SOCIAL_STATE_SECTION"] = "Funktionsstatus"
L["SOCIAL_TARGET_UNLOCK"] = "Ziel-Namensplakette entsperren (ziehen zum Verschieben)"
L["SOCIAL_TARGET_RESET"] = "Position der Ziel-Namensplakette zurücksetzen"
L["SOCIAL_TARGET_EDIT_HINT"] = "BEARBEITUNGSMODUS · Mit links ziehen · Mit rechts sperren"
L["SOCIAL_TARGET_EDIT_TOP"] = "BEARBEITUNGSMODUS"
L["SOCIAL_TARGET_EDIT_BOTTOM"] = "Mit links ziehen · Mit rechts sperren"
L["SOCIAL_TARGET_TOOLTIP_LEFT"] = "Linksklick, um diesen Titel in Epithet anzuzeigen."
L["SOCIAL_TARGET_TOOLTIP_RIGHT"] = "Rechtsklick, um diese Namensplakette zu entsperren und zu verschieben."
L["SOCIAL_TARGET_PLACEHOLDER_TITLE"] = "Beispieltitel"
L["SOCIAL_TARGET_PLACEHOLDER_RARITY"] = "SELTEN"
L["SOCIAL_PRESTIGE_FORMAT"] = "%s %s"
L["SOCIAL_LAYOUT_SECTION"] = "Namensplaketten-Layout"
L["SOCIAL_LAYOUT_CLASSIC"] = "Schlank"
L["SOCIAL_LAYOUT_PORTRAIT"] = "Porträtkarte"
L["SOCIAL_LAYOUT_PREVIEW"] = "Layoutvorschau"
L["SOCIAL_LAYOUT_PREVIEW_NOTE"] = "Die Vorschau nutzt Beispieldaten."
L["SOCIAL_LAYOUT_FUNNY_TOGGLE"] = "Lustige Vorschau mit langem Titel anzeigen"
L["SOCIAL_LAYOUT_PORTRAIT_MODE"] = "Porträtmodus des Ziels"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_3D"] = "3D (animiert)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_2D"] = "2D (statisch)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_NOTE"] = "3D verwendet ein animiertes Modell. 2D verwendet eine statische Porträtgrafik."
L["SOCIAL_BEHAVIOUR_SECTION"] = "Sichtbarkeitsregeln"
L["SOCIAL_FADE_SECTION"] = "Ausblenden"
L["SOCIAL_FADE_ENABLE"] = "Ziel-Namensplaketten nach einer Verzögerung ausblenden"
L["SOCIAL_FADE_DURATION"] = "Verzögerung bis zum Ausblenden"
L["SOCIAL_FADE_DURATION_FMT"] = "%.1f Sekunden bis zum Ausblenden"
L["SOCIAL_SHOW_SELF_TARGET"] = "Ziel-Namensplakette auch bei Selbstziel anzeigen"
L["SOCIAL_SELF_TARGET_NOTE"] = "Die eigene Namensplakette bei Selbstziel ist nur visuell. Selbstziel zählt niemals für Erfolge der Titelsichtung."
L["SOCIAL_SPOTTING_NOTIFY"] = "Sichtungsbestätigungen im Chat anzeigen"
L["SOCIAL_ACHIEVEMENT_SECTION"] = "Erfolge"
L["SOCIAL_ACHIEVEMENT_LAYER_DESC"] = "Erfolgs-Popups decken sowohl deine eigene Titelsammlung als auch bei anderen gesichtete Titel ab. Lege hier fest, wie sie dich benachrichtigen - die Titelsichtung selbst wird auf ihrem eigenen Reiter aktiviert."
L["SOCIAL_ACHIEVEMENT_SPOTTING_DISABLED_NOTE"] = "Titelsichtung ist deaktiviert, daher können Sichtungserfolge nicht fortschreiten. Aktiviere sie im Reiter Titelsichtung, damit sie weiter fortschreiten. Erfolge, die auf deiner eigenen Titelsammlung basieren, werden weiterhin erfasst."
L["SOCIAL_ACHIEVEMENT_NOTIFY"] = "Erfolgsbenachrichtigungen"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE"] = "Modus für Erfolgsbenachrichtigungen"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_FULL"] = "Popup + Ton"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_SILENT"] = "Nur Popup (Ton aus)"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_OFF"] = "Aus"
L["SOCIAL_ACHIEVEMENT_ANCHOR_MODE"] = "Verankerung des Erfolgspopups"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT"] = "Bildschirm oben (UIParent)"
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME"] = "An Blizzard-AlertFrame ausrichten"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT_DESC"] = "Verankert am oberen Bildschirmzentrum. Am zuverlässigsten, wenn AlertFrame von UI-Mods verschoben oder ausgeblendet wird."
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME_DESC"] = "Folgt dem Blizzard-Bereich für Erfolgs- und Beutetoasts. Wenn ein anderes Addon AlertFrame verschiebt oder ausblendet, bewegt sich dieses Popup mit."
L["SOCIAL_POSITION_SECTION"] = "Position"

L["SPOTTING_NEW_SPOT_FMT"] = "Gesichtet: %s"
L["SPOTTING_LOG_TOOLTIP"] = "Sichtungsprotokoll (%d gefunden)"
L["SPOTTING_LOG_TOOLTIP_LEFT"] = "Linksklick: Sichtungsprotokoll öffnen."
L["SPOTTING_LOG_TOOLTIP_RIGHT"] = "Rechtsklick: Deine Sichtungsstatistik in /s ausrufen."
L["SPOTTING_LOG_SHOUT_FMT_1"] = "Ich habe völlig normal viele %d Fremde bewundert!"
L["SPOTTING_LOG_SHOUT_FMT_2"] = "Ich habe %d Fremde ohne ihr Wissen und ihre Zustimmung inspiziert!"
L["SPOTTING_LOG_SHOUT_FMT_3"] = "Ich habe still die Titel von %d Fremden beurteilt!"
L["SPOTTING_LOG_SHOUT_FMT_4"] = "%d Fremde wurden beobachtet. Keiner hat es bemerkt. Ausgezeichnet."
L["SPOTTING_LOG_SHOUT_FMT_5"] = "Ich habe %d ahnungslose Abenteurer allein wegen ihrer Titel verfolgt!"
L["SPOTTING_LOG_HEADING"] = "Sichtungsprotokoll"
L["SPOTTING_LOG_COUNT_FMT"] = "%d Titel gesichtet"
L["SPOTTING_LOG_COUNT_PROGRESS_FMT"] = "%d / %d Titel gesichtet"
L["SPOTTING_LOG_COUNT_REMAINING_FMT"] = "%d Titel verbleibend"
L["SPOTTING_LOG_EMPTY"] = "Noch nichts gesichtet. Ziele Spieler in der offenen Welt an, um die Titel zu protokollieren, die sie tragen."
L["SPOTTING_LOG_EMPTY_REMAINING"] = "Im aktuellen Katalog sind keine verbleibenden Titel."
L["SPOTTING_LOG_GATED"] = "Titelsichtung ist ausgeschaltet. Sichtungen werden nicht aufgezeichnet."
L["SPOTTING_LOG_OPEN_SETTINGS"] = "In den Einstellungen aktivieren"
L["SPOTTING_SCOPE_SPOTTED"] = "Gesichtet"
L["SPOTTING_SCOPE_REMAINING"] = "Verbleibend"
L["SPOTTING_VIEW_LIST"] = "Liste"
L["SPOTTING_VIEW_GRID"] = "Raster"
L["SPOTTING_EXPORT_BUTTON"] = "Exportieren"
L["SPOTTING_IMPORT_BUTTON"] = "Importieren"
L["SPOTTING_EXPORT_TITLE"] = "Sichtungsprotokoll exportieren"
L["SPOTTING_IMPORT_TITLE"] = "Sichtungsprotokoll importieren"
L["SPOTTING_TRANSFER_NOTE"] = "Kopiere oder füge die vollständigen Daten unten ein."
L["SPOTTING_TRANSFER_COPY"] = "Alles auswählen"
L["SPOTTING_TRANSFER_IMPORT"] = "Importieren"
L["SPOTTING_TRANSFER_CLOSE"] = "Schließen"
L["SPOTTING_IMPORT_SUCCESS_FMT"] = "%d Sichtungseinträge importiert."
L["SPOTTING_IMPORT_FAILED_FMT"] = "Import fehlgeschlagen: %s"
L["SPOTTING_NOT_SPOTTED"] = "Verbleibend"
L["SPOTTING_NOT_SPOTTED_YET"] = "Noch nicht gesichtet."
L["SPOTTING_TOOLTIP_FIRST_FMT"] = "Erstmals gesichtet auf %s in %s am %s"
L["SPOTTING_TOOLTIP_RACE_FMT"] = "Volk: %s"
L["SPOTTING_TOOLTIP_RACE_UNKNOWN"] = "Unbekannt"
L["SPOTTING_TOOLTIP_COUNT_FMT"] = "%d-mal gesehen"
L["SPOTTING_TOOLTIP_LAST_FMT"] = "Zuletzt gesehen am %s als %s"

L["SPOT_ACHV_MODE"] = "Erfolge"
L["SPOT_ACHV_HEADING"] = "Epithet-Erfolge"
L["SPOT_ACHV_TOOLTIP"] = "Epithet-Erfolge"
L["SPOT_ACHV_TOOLTIP_LEFT"] = "Linksklick: Epithet-Erfolge öffnen."
L["SPOT_ACHV_EMPTY"] = "Keine Epithet-Erfolge verfügbar."
L["SPOT_ACHV_META_TITLE"] = "Notizen zur Erfolgsjagd"
L["SPOT_ACHV_META_DESC"] = "Um jeden Erfolg abzuschließen, musst du deine Sichtungen möglicherweise über Klassen, Fraktionen, Kalenderfenster und wiederholte Sichtungen mit Freunden oder Gildenmitgliedern koordinieren."
L["SPOT_ACHV_COUNT_FMT"] = "%d / %d erhalten"
L["SPOT_ACHV_GROUP_SPOTTING"] = "Sichtung"
L["SPOT_ACHV_GROUP_COLLECTION"] = "Sammlung"
L["SPOT_ACHV_GROUP_CROSSOVERS"] = "Überschneidungen"
L["SPOT_ACHV_SECRET_NAME"] = "???"
L["SPOT_ACHV_SECRET_DESC"] = "Geheimer Erfolg"
L["SPOT_ACHV_PROGRESS_FMT"] = "%d / %d"
L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"] = "%d / %d auf diesem Charakter"
L["SPOT_ACHV_EARNED_FMT"] = "Erhalten am %s"
L["SPOT_ACHV_ALERT_HEADER"] = "Epithet-Erfolg"
L["SPOT_ACHV_CHAT_EARNED_FMT"] = "Erfolg erhalten - %s!"
L["SPOT_ACHV_DETAIL_WITH_FMT"] = "erhalten mit %s"
L["SPOT_ACHV_DETAIL_CLASSES_FMT"] = "über %s Klassen erhalten"
L["SPOT_ACHV_DETAIL_ZONE_FMT"] = "in %s erhalten"
L["SPOT_ACHV_DETAIL_TITLE_FMT"] = "ausgelöst durch %s"
L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"] = "über %s Erweiterungen erhalten"
L["SPOT_ACHV_DETAIL_SECRETS_FMT"] = "über %s Geheimnisse erhalten"
L["SPOT_ACHV_FWENDS_HINT"] = "Zählt Titel, die du auf dieser Person zum allerersten Mal gesichtet hast."
L["SPOT_ACHV_DETAIL_TITLE"] = "Erfolgsdetails"
L["SPOT_ACHV_DETAIL_CLOSE"] = "Schließen"
L["SPOT_ACHV_DETAIL_SECRET_STATUS"] = "Erhalte diesen Erfolg, um die Details zu enthüllen."
L["SPOT_ACHV_ADMIN_TEST_NAME"] = "Admin-Test-Erfolg"
L["SPOT_ACHV_ADMIN_TEST_DESC"] = "Manueller, vom Admin ausgelöster Popup-Test."

L["SPOT_ACHV_NAME_COUNT_1"] = "Erste Sichtung"
L["SPOT_ACHV_DESC_COUNT_1"] = "Sichte 1 unterschiedlichen Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_10"] = "Scharfes Auge"
L["SPOT_ACHV_DESC_COUNT_10"] = "Sichte 10 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_25"] = "Feldnotizen"
L["SPOT_ACHV_DESC_COUNT_25"] = "Sichte 25 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_50"] = "Erfahrener Beobachter"
L["SPOT_ACHV_DESC_COUNT_50"] = "Sichte 50 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_100"] = "Privatsphäre ist ein Mythos"
L["SPOT_ACHV_DESC_COUNT_100"] = "Sichte 100 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_200"] = "Naseweis"
L["SPOT_ACHV_DESC_COUNT_200"] = "Sichte 200 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_350"] = "Zwangsbeobachter"
L["SPOT_ACHV_DESC_COUNT_350"] = "Sichte 350 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_500"] = "Lebendes Register"
L["SPOT_ACHV_DESC_COUNT_500"] = "Sichte 500 unterschiedliche Titel in freier Wildbahn."
L["SPOT_ACHV_NAME_COUNT_700"] = "Der ganze Vogelschwarm"
L["SPOT_ACHV_DESC_COUNT_700"] = "Sichte 700 unterschiedliche Titel in freier Wildbahn."

L["SPOT_ACHV_NAME_ROLL_CALL"] = "Appell"
L["SPOT_ACHV_DESC_ROLL_CALL"] = "Sichte erstmals Titel über alle Klassen hinweg."
L["SPOT_ACHV_NAME_FULL_SPECTRUM"] = "Volles Spektrum"
L["SPOT_ACHV_DESC_FULL_SPECTRUM"] = "Sichte mindestens einen Titel aus jeder Seltenheitsstufe."
L["SPOT_ACHV_NAME_BOTH_ENDS"] = "Beide Enden"
L["SPOT_ACHV_DESC_BOTH_ENDS"] = "Sichte mindestens einen Präfix- und einen Suffixtitel."
L["SPOT_ACHV_NAME_GRAND_TOUR"] = "Große Rundreise"
L["SPOT_ACHV_DESC_GRAND_TOUR"] = "Sichte erstmals Titel in 10 verschiedenen Zonen."
L["SPOT_ACHV_NAME_TITLE_FWENDS"] = "Oooh, Titelfreunde!"
L["SPOT_ACHV_DESC_TITLE_FWENDS"] = "Sichte erstmals 10 verschiedene Titel auf demselben Spieler."
L["SPOT_ACHV_NAME_HAVENT_WE_MET"] = "Kennen wir uns nicht?"
L["SPOT_ACHV_DESC_HAVENT_WE_MET"] = "Sieh denselben Titel mindestens 10-mal."
L["SPOT_ACHV_NAME_LONG_CON"] = "Der lange Plan"
L["SPOT_ACHV_DESC_LONG_CON"] = "Sieh einen Titel mindestens 30 Tage nach seiner ersten Sichtung erneut."
L["SPOT_ACHV_NAME_NIGHT_SHIFT"] = "Nachtschicht"
L["SPOT_ACHV_DESC_NIGHT_SHIFT"] = "Sichte einen Titel erstmals zwischen 03:00 und 04:59 Uhr Ortszeit."
L["SPOT_ACHV_NAME_BUSY_DAY"] = "Geschäftiger Tag"
L["SPOT_ACHV_DESC_BUSY_DAY"] = "Sichte erstmals mindestens 5 Titel am selben lokalen Datum."
L["SPOT_ACHV_NAME_CAPITAL_OFFENCE"] = "Kapitalverbrechen"
L["SPOT_ACHV_DESC_CAPITAL_OFFENCE"] = "Sichte erstmals mindestens 10 Titel in derselben Zone."
L["SPOT_ACHV_NAME_OLD_MONEY"] = "Altes Geld"
L["SPOT_ACHV_DESC_OLD_MONEY"] = "Sichte einen Titel, der nicht mehr erhältlich ist."
L["SPOT_ACHV_NAME_LEGENDARY_SPOT"] = "Albtraum für Komplettisten"
L["SPOT_ACHV_DESC_LEGENDARY_SPOT"] = "Sichte einen Titel legendärer Qualität in freier Wildbahn."
L["SPOT_ACHV_NAME_POTTED_HISTORY"] = "Kurzfassung der Geschichte"
L["SPOT_ACHV_DESC_POTTED_HISTORY"] = "Sichte mindestens einen Titel aus jeder Erweiterung."
L["SPOT_ACHV_NAME_DIPLOMATIC_IMMUNITY"] = "Diplomatische Immunität"
L["SPOT_ACHV_DESC_DIPLOMATIC_IMMUNITY"] = "Sichte mindestens einen Allianz-gebundenen und einen Horde-gebundenen Titel."
L["SPOT_ACHV_NAME_SMALL_WORLD"] = "Kleine Welt"
L["SPOT_ACHV_DESC_SMALL_WORLD"] = "Sieh denselben Titel auf zwei verschiedenen Personen."
L["SPOT_ACHV_NAME_CREATURE_OF_HABIT"] = "Gewohnheitstier"
L["SPOT_ACHV_DESC_CREATURE_OF_HABIT"] = "Sichte erstmals mindestens einen Titel an 7 lokalen Tagen in Folge."
L["SPOT_ACHV_NAME_SEEING_STARS"] = "Sterne sehen"
L["SPOT_ACHV_DESC_SEEING_STARS"] = "Sichte 5 Titel legendärer Qualität."
L["SPOT_ACHV_NAME_MUSEUM_CURATOR"] = "Museumskurator"
L["SPOT_ACHV_DESC_MUSEUM_CURATOR"] = "Sichte 5 Titel aus entferntem Inhalt."
L["SPOT_ACHV_NAME_GNOME_SPOTTER"] = "Taschenvolkszählung"
L["SPOT_ACHV_DESC_GNOME_SPOTTER"] = "Sichte 5 Titel, die erstmals auf Gnomen gesehen wurden."
L["SPOT_ACHV_NAME_AT_LEAST_CHICKEN"] = "Immerhin habe ich Hähnchen"
L["SPOT_ACHV_DESC_AT_LEAST_CHICKEN"] = "Sichte jemanden mit dem Titel Jenkins."
L["SPOT_ACHV_NAME_CERTIFIED"] = "Zertifiziert"
L["SPOT_ACHV_DESC_CERTIFIED"] = "Sichte jemanden mit dem Titel der Wahnsinnige."
L["SPOT_ACHV_NAME_OVERACHIEVER"] = "Überflieger"
L["SPOT_ACHV_DESC_OVERACHIEVER"] = "Erhalte 15 Epithet-Erfolge über Sichtung und Sammlung hinweg."
L["SPOT_ACHV_NAME_GUISING"] = "Verkleidung"
L["SPOT_ACHV_DESC_GUISING"] = "Sichte erstmals irgendeinen Titel am 31. Oktober (Ortszeit)."
L["SPOT_ACHV_NAME_QUITE_A_MOUTHFUL"] = "Ganz schöner Brocken"
L["SPOT_ACHV_DESC_QUITE_A_MOUTHFUL"] = "Sichte einen Titel, dessen Katalogtext 25 Zeichen oder länger ist."
L["SPOT_ACHV_NAME_TERSE"] = "Knapp"
L["SPOT_ACHV_DESC_TERSE"] = "Sichte einen Titel, dessen Katalogtext 5 Zeichen oder kürzer ist."
L["SPOT_ACHV_NAME_LORD_OF_LORDS"] = "Herr der Herren"
L["SPOT_ACHV_DESC_LORD_OF_LORDS"] = "Sichte 5 unterschiedliche Titel, deren englischer Name „Lord“ enthält."
L["SPOT_ACHV_NAME_MASTERCLASS"] = "Meisterklasse"
L["SPOT_ACHV_DESC_MASTERCLASS"] = "Sichte 5 unterschiedliche Titel, deren englischer Name „Master“ enthält."
L["SPOT_ACHV_NAME_SLAY"] = "Slay"
L["SPOT_ACHV_DESC_SLAY"] = "Sichte 5 unterschiedliche Titel, deren englischer Name „Slayer“ enthält."
L["SPOT_ACHV_NAME_GLADIATOR_GROUPIE"] = "Gladiator-Groupie"
L["SPOT_ACHV_DESC_GLADIATOR_GROUPIE"] = "Sichte 5 Titel aus PvP-Quellen."
L["SPOT_ACHV_NAME_RAID_SPECTATOR"] = "Raid-Zuschauer"
L["SPOT_ACHV_DESC_RAID_SPECTATOR"] = "Sichte 5 Titel aus Raid-Quellen."
L["SPOT_ACHV_NAME_BROWN_NOSER"] = "Schleimer"
L["SPOT_ACHV_DESC_BROWN_NOSER"] = "Sichte 5 Titel aus Ruf-Quellen."
L["SPOT_ACHV_NAME_HOW_ITS_MADE"] = "So wird's gemacht"
L["SPOT_ACHV_DESC_HOW_ITS_MADE"] = "Sichte Titel, deren Quelle ein Erfolg, eine Quest und ein Gegenstand ist."
L["SPOT_ACHV_NAME_PEOPLE_WATCHER"] = "Menschenbeobachter"
L["SPOT_ACHV_DESC_PEOPLE_WATCHER"] = "Erfasse insgesamt 500 Sichtungen."
L["SPOT_ACHV_NAME_PROFESSIONAL_LURKER"] = "Professioneller Lauerer"
L["SPOT_ACHV_DESC_PROFESSIONAL_LURKER"] = "Erfasse insgesamt 2.000 Sichtungen."
L["SPOT_ACHV_NAME_DOUBLE_TAKE"] = "Doppelter Blick"
L["SPOT_ACHV_DESC_DOUBLE_TAKE"] = "Sieh denselben Titel innerhalb einer Stunde nach seiner ersten Sichtung zweimal."
L["SPOT_ACHV_NAME_EARLY_BIRD"] = "Der frühe Vogel"
L["SPOT_ACHV_DESC_EARLY_BIRD"] = "Sichte einen Titel erstmals zwischen 05:00 und 08:59 Uhr Ortszeit."
L["SPOT_ACHV_NAME_WEEKEND_WARRIOR"] = "Wochenendkrieger"
L["SPOT_ACHV_DESC_WEEKEND_WARRIOR"] = "Erfasse 10 Erstsichtungen an einem Samstag oder Sonntag."
L["SPOT_ACHV_NAME_FULL_WEEK"] = "Die ganze Woche"
L["SPOT_ACHV_DESC_FULL_WEEK"] = "Erfasse Erstsichtungen an allen 7 Wochentagen."
L["SPOT_ACHV_NAME_YEAR_IN_FIELD"] = "Ein Jahr im Feld"
L["SPOT_ACHV_DESC_YEAR_IN_FIELD"] = "Erfasse Erstsichtungen in allen 12 Kalendermonaten."
L["SPOT_ACHV_NAME_WELCOME_BACK"] = "Willkommen zurück"
L["SPOT_ACHV_DESC_WELCOME_BACK"] = "Lass zwischen zwei aufeinanderfolgenden Erstsichtungen mindestens 90 Tage vergehen."
L["SPOT_ACHV_NAME_FEAST_YOUR_EYES"] = "Schau dir das an"
L["SPOT_ACHV_DESC_FEAST_YOUR_EYES"] = "Sichte einen Titel erstmals am 25. Dezember (Ortszeit)."
L["SPOT_ACHV_NAME_PARTICIPATION_AWARD"] = "Teilnahmepreis"
L["SPOT_ACHV_DESC_PARTICIPATION_AWARD"] = "Sichte einen Titel gewöhnlicher Qualität in freier Wildbahn."
L["SPOT_ACHV_NAME_SNEAKY_BEAKY"] = "Ganz heimlich"
L["SPOT_ACHV_DESC_SNEAKY_BEAKY"] = "Sichte einen Titel erstmals auf einem Schurken."
L["SPOT_ACHV_NAME_DEAD_MAN_WALKING"] = "Toter auf Wanderschaft"
L["SPOT_ACHV_DESC_DEAD_MAN_WALKING"] = "Sichte einen Titel erstmals auf einem Todesritter."
L["SPOT_ACHV_NAME_OLD_SCHOOL"] = "Oldschool"
L["SPOT_ACHV_DESC_OLD_SCHOOL"] = "Sichte einen Titel aus der Classic-Ära."
L["SPOT_ACHV_NAME_POPULAR"] = "Beliebt"
L["SPOT_ACHV_DESC_POPULAR"] = "Sorge dafür, dass 3 verschiedene Personen jeweils für 5 oder mehr Erstsichtungen stehen."
L["SPOT_ACHV_NAME_RESTRAINING_ORDER"] = "Kontaktverbot"
L["SPOT_ACHV_DESC_RESTRAINING_ORDER"] = "Sieh denselben Titel mindestens 25-mal."
L["SPOT_ACHV_NAME_BEYOND_THE_GRAVE"] = "Jenseits des Grabes"
L["SPOT_ACHV_DESC_BEYOND_THE_GRAVE"] = "Erfasse eine Sichtung, während du tot bist oder als Geist herumläufst."
L["SPOT_ACHV_NAME_KNOW_THY_ENEMY"] = "Kenne deinen Feind"
L["SPOT_ACHV_DESC_KNOW_THY_ENEMY"] = "Erfasse eine Sichtung bei einem Spieler der gegnerischen Fraktion."
L["SPOT_ACHV_NAME_SECRET_KEEPER"] = "Hüter der Geheimnisse"
L["SPOT_ACHV_DESC_SECRET_KEEPER"] = "Erhalte alle derzeit definierten geheimen Erfolge."

L["SPOT_ACHV_NAME_OWNED_1"] = "Erster meines Namens"
L["SPOT_ACHV_DESC_OWNED_1"] = "Besitze 1 Titel auf diesem Charakter."
L["SPOT_ACHV_NAME_OWNED_10"] = "Buchstaben hinter meinem Namen"
L["SPOT_ACHV_DESC_OWNED_10"] = "Besitze 10 Titel auf diesem Charakter."
L["SPOT_ACHV_NAME_OWNED_25"] = "Lokale Berühmtheit"
L["SPOT_ACHV_DESC_OWNED_25"] = "Besitze 25 Titel auf diesem Charakter."
L["SPOT_ACHV_NAME_OWNED_50"] = "Adelstitel"
L["SPOT_ACHV_DESC_OWNED_50"] = "Besitze 50 Titel auf diesem Charakter."
L["SPOT_ACHV_NAME_OWNED_100"] = "Größenwahn"
L["SPOT_ACHV_DESC_OWNED_100"] = "Besitze 100 Titel auf diesem Charakter."
L["SPOT_ACHV_NAME_OWNED_SPECTRUM"] = "Für jeden Anlass gekleidet"
L["SPOT_ACHV_DESC_OWNED_SPECTRUM"] = "Besitze mindestens einen Titel aus jeder Seltenheitsstufe."
L["SPOT_ACHV_NAME_OWNED_BOTH_ENDS"] = "Eingerahmt"
L["SPOT_ACHV_DESC_OWNED_BOTH_ENDS"] = "Besitze mindestens einen Präfix- und einen Suffixtitel."
L["SPOT_ACHV_NAME_OWNED_LEGENDARY"] = "Über meinem Stand"
L["SPOT_ACHV_DESC_OWNED_LEGENDARY"] = "Besitze einen Titel legendärer Qualität."
L["SPOT_ACHV_NAME_OWNED_REMOVED"] = "Auslaufmodell"
L["SPOT_ACHV_DESC_OWNED_REMOVED"] = "Besitze einen Titel aus entferntem Inhalt."
L["SPOT_ACHV_NAME_IMPULSE_PURCHASE"] = "Impulskauf"
L["SPOT_ACHV_DESC_IMPULSE_PURCHASE"] = "Komme innerhalb von 7 Tagen nach der ersten Sichtung in den Besitz eines Titels."
L["SPOT_ACHV_NAME_CURRICULUM_VITAE"] = "Curriculum Vitae"
L["SPOT_ACHV_DESC_CURRICULUM_VITAE"] = "Besitze auf diesem Charakter mindestens einen Titel aus jeder Erweiterung."
L["SPOT_ACHV_NAME_DECORATED_VETERAN"] = "Ausgezeichneter Veteran"
L["SPOT_ACHV_DESC_DECORATED_VETERAN"] = "Besitze 5 Titel aus PvP-Quellen auf diesem Charakter."
L["SPOT_ACHV_NAME_NOTHING_NEW"] = "Nichts Neues unter der Sonne"
L["SPOT_ACHV_DESC_NOTHING_NEW"] = "Besitze mindestens 10 Titel und habe jeden davon auch in freier Wildbahn gesichtet."
L["SPOT_ACHV_NAME_MATCHING_SET"] = "Passendes Set"
L["SPOT_ACHV_DESC_MATCHING_SET"] = "Besitze und sichte für jede Seltenheitsstufe mindestens einen Titel dieser Stufe."

L["SPOT_ACHV_NAME_TAKES_ONE"] = "Gleich und gleich erkennt sich"
L["SPOT_ACHV_DESC_TAKES_ONE"] = "Sichte in freier Wildbahn einen Titel, den dieser Charakter bereits besitzt."
L["SPOT_ACHV_NAME_WINDOW_SHOPPER"] = "Schaufensterbummler"
L["SPOT_ACHV_DESC_WINDOW_SHOPPER"] = "Komme in den Besitz eines Titels, den du zuerst bei jemand anderem gesehen hast."
L["SPOT_ACHV_NAME_TWINSIES"] = "Zwillinge"
L["SPOT_ACHV_DESC_TWINSIES"] = "Sichte jemanden, während ihr beide denselben Titel tragt."

-- Source kinds
L["KIND_ACHIEVEMENT"] = "Erfolg"
L["KIND_QUEST"] = "Quest"
L["KIND_REPUTATION"] = "Ruf"
L["KIND_PVP_RANK"] = "PvP-Rang"
L["KIND_FEAT"] = "Großtat"
L["KIND_ITEM"] = "Gegenstand"
L["KIND_PROMOTION"] = "Promotion"

-- Filter facets (new)
L["CATEGORY"] = "Kategorie"
L["KIND"] = "Quellenart"
L["FACTION"] = "Fraktion"
L["FACTION_ALLIANCE"] = "Allianz"
L["FACTION_HORDE"] = "Horde"
L["FACTION_BOTH"] = "Beide Fraktionen"
L["AVAILABILITY"] = "Verfügbarkeit"
L["HIDE_UNOBTAINABLE"] = "Nicht erhältliche ausblenden"
L["HIDE_TIME_SENSITIVE"] = "Zeitlich begrenzte ausblenden"
L["UNKNOWN_SOURCE"] = "Unbekannte Quelle"
L["FEAT_OF_STRENGTH"] = "Großtat (möglicherweise nicht mehr erhältlich)"

-- Source descriptions
L["SOURCE_ACHIEVEMENT_DESC"] = "Gewährt durch den Erfolg %s"
L["SOURCE_QUEST_DESC"] = "Wird während der Quest %s vergeben"
L["SOURCE_ITEM_DESC"] = "Gewährt durch %s"

-- Meta grid
L["LAST_ASSESSED"] = "Zuletzt bewertet"

-- Availability labels
L["AVAILABILITY_SEASONAL"] = "Saisonal"
L["AVAILABILITY_LIMITED"] = "Begrenzt"
L["AVAILABILITY_PROMOTIONAL"] = "Promotional"
L["AVAILABILITY_TEMPORARY"] = "Temporär"
L["AVAILABILITY_REMOVED"] = "Entfernt"
L["AVAILABILITY_PERMANENT"] = "Dauerhaft"

-- Previously-missing keys (had inline English fallbacks in code)
L["SOCIAL_HIDE_IN_COMBAT"] = "Ziel-Namensplakette im Kampf ausblenden"
L["SOCIAL_HIDE_IN_GROUP"] = "Ziel-Namensplakette in Gruppen ausblenden"
L["SPOTTING_META_TITLE"] = "Sichtungsnotizen"
L["SPOTTING_META_DESC"] = "Ziele Spieler in der offenen Welt an, um die Titel zu protokollieren, die sie tragen."
L["SPOT_ACHV_SECRET_EARNED_SUFFIX"] = "(geheim)"
L["SPOT_ACHV_SECRET_EARNED_NOTE"] = "Du hast einen geheimen Erfolg aufgedeckt."

-- Window banner (main frame title bar)
L["BANNER_LEFT"] = "EPITHET"
L["BANNER_RIGHT"] = "DIE TITELSCHAU"

-- Type tags (uppercase pills on title rows)
L["TYPE_TAG_PREFIX"] = "PRÄFIX"
L["TYPE_TAG_SUFFIX"] = "SUFFIX"

-- Rarity fallback
L["RARITY_UNKNOWN"] = "UNBEKANNT"

-- Minimap tooltip collected line
L["MINIMAP_TOOLTIP_COLLECTED"] = "Gesammelt: %d / %d"

-- Slash command feedback
L["SLASH_SCAN_COMPLETE"] = "Titelscan abgeschlossen: %d / %d"

-- Version footer (two rows). %s placeholders filled at runtime.
L["VERSION_LINE1_FMT"] = "Epithet v%s  " .. DOT .. "  Benutzeroberfläche %s"
L["VERSION_LINE2_FMT"] = "TitlesDB v%s  " .. DOT .. "  Aktualisiert %s"
L["VERSION_DATE_UNKNOWN"] = "unbekannt"

-- Source-kind legend (bottom bar hover labels)
L["LEGEND_ACHIEVEMENT"] = "Erfolg"
L["LEGEND_QUEST"] = "Quest"
L["LEGEND_REPUTATION"] = "Ruf"
L["LEGEND_PVP"] = "PvP"
L["LEGEND_FEAT"] = "Großtat"
L["LEGEND_EXPLORATION"] = "Erkundung"
L["LEGEND_RAID"] = "Raid"

-- Layout preview sample data
L["SAMPLE_TITLE"] = "Müllmeister"
L["SAMPLE_RARITY"] = "LEGENDÄR"
L["SAMPLE_FUNNY_TITLE"] = "Bezwinger dummer, unfähiger und enttäuschender Schergen"

-- Fade slider bound labels
L["FADE_SLIDER_LOW"] = "0,5 s"
L["FADE_SLIDER_HIGH"] = "20 s"

-- Month names (used to format achievement earned dates: "dd Month yyyy")
L["MONTH_1"]  = "Januar"
L["MONTH_2"]  = "Februar"
L["MONTH_3"]  = "März"
L["MONTH_4"]  = "April"
L["MONTH_5"]  = "Mai"
L["MONTH_6"]  = "Juni"
L["MONTH_7"]  = "Juli"
L["MONTH_8"]  = "August"
L["MONTH_9"]  = "September"
L["MONTH_10"] = "Oktober"
L["MONTH_11"] = "November"
L["MONTH_12"] = "Dezember"

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
L["CAT_REPUTATION"] = "Ruf"
L["CAT_QUEST"] = "Quest"
L["CAT_PROFESSION"] = "Beruf"
L["CAT_HOLIDAY"] = "Feiertag"
L["CAT_EXPLORATION"] = "Erkundung"
L["CAT_ACHIEVEMENT"] = "Erfolg"
L["CAT_CAMPAIGN"] = "Kampagne"
L["CATEGORY_UNCATEGORIZED"] = "Nicht kategorisiert"

-- Detail panel meta-grid row labels
L["EARNED_LABEL"] = "Erhalten"
L["STATUS_LABEL"] = "Status"

-- "ACTIVE" chip on the currently-equipped title's list row
L["ACTIVE_TITLE"] = "AKTIV"

-- About / info modal ("Grimmsforge" and "World of Warcraft" stay as-is: brands)
L["ABOUT_CRAFTED"] = "Epithet wird von Grimmsforge entwickelt."
L["ABOUT_TAGLINE"] = "Open-Source-Tools und Addons für World of Warcraft."

-- Title-bar settings button
L["SETTINGS_BUTTON_TOOLTIP"] = "Epithet-Einstellungen öffnen"
L["INFO_BUTTON_TOOLTIP"] = "Über Epithet"

-- Language names (shown in the picker, in the active language)
L["LANGUAGE_ENGLISH"] = "Englisch"
L["LANGUAGE_RUSSIAN"] = "Russisch"
L["LANGUAGE_GERMAN"] = "Deutsch"
L["LANGUAGE_FRENCH"] = "Französisch"
L["LANGUAGE_SIMPLIFIED_CHINESE"] = "Vereinfachtes Chinesisch"

-- Options: general section (main Epithet settings page)
L["OPTIONS_GENERAL_SECTION"] = "Allgemein"
L["OPTIONS_GENERAL_DESC"] = "Einstellungen, die für Epithet insgesamt gelten."
L["OPTIONS_STARTUP_SECTION"] = "Start"
L["OPTIONS_WHATSNEW_STARTUP_TOGGLE"] = "„Was ist neu“ nach einem Update anzeigen"
L["OPTIONS_WHATSNEW_STARTUP_NOTE"] = "Wird einmalig beim ersten Einloggen nach einer neuen Version angezeigt. Du kannst es jederzeit mit /epithet whatsnew erneut öffnen."

-- Options: language section
L["OPTIONS_LANGUAGE_SECTION"] = "Sprache"
L["OPTIONS_LANGUAGE_LABEL"] = "Addonsprache"
L["OPTIONS_LANGUAGE_AUTO"] = "Automatisch (Client-Standard)"
L["OPTIONS_LANGUAGE_NOTE"] = "Legt die von Epithet verwendete Sprache unabhängig von deinem Spielclient fest. Beim Ändern wird die Benutzeroberfläche neu geladen."
L["OPTIONS_LANGUAGE_RELOAD_PROMPT"] = "Epithet-Sprache ändern und die Benutzeroberfläche jetzt neu laden?"
L["RELOAD_NOW"] = "Jetzt neu laden"
L["LATER"] = "Später"

-- The locale registry, ns.L proxy, and resolution API live in LocaleManager.lua.
