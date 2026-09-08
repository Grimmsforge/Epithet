-- =============================================================================
-- Epithet — Locale: frFR
-- NOTE: WoW Lua 5.1 does NOT support \xNN hex escapes. Use decimal byte escapes
--       (e.g. \226\128\148 = em dash) or plain ASCII. This file is UTF-8, so
--       accented Latin characters are written directly (as ruRU.lua does).
-- =============================================================================
local _, ns = ...

-- Register the French table into the locale registry. It is always loaded (no
-- GetLocale guard) so the language picker can offer it on any client; the active
-- locale is chosen by ns.ApplyLocale, and untranslated keys fall back to the
-- English base automatically (see enGB.lua).
ns.Locales = ns.Locales or {}
local L = {}
ns.Locales.frFR = L

-- Shared punctuation glyphs (defined once in LocaleManager.lua).
local DOT, DASH = ns.Glyphs.DOT, ns.Glyphs.DASH

-- Window
L["WINDOW_TITLE"] = "TITRES"
L["CLOSE"] = "Fermer"

-- Header band
L["TITLES_EARNED"] = "TITRES OBTENUS"
L["TITLES_EARNED_OBTAINABLE"] = "DISPONIBLES OBTENUS"
L["TOGGLE_ALL_TITLES"] = "Compter tous les titres"
L["TOGGLE_OBTAINABLE_ONLY"] = "Ne compter que les titres disponibles"
L["TOGGLE_OBTAINABLE_LABEL"] = "Disponibles uniquement"

-- Filter sidebar
L["SEARCH_PLACEHOLDER"] = "Rechercher un titre ou une source..."
L["STATUS"] = "STATUT"
L["STATUS_ALL"] = "Tous"
L["STATUS_EARNED"] = "Obtenus"
L["STATUS_UNEARNED"] = "Non obtenus"
L["RARITY_TIER"] = "Palier de rareté"
L["TYPE"] = "Type"
L["EXPANSION"] = "Extension"
L["ADDITIONAL_FILTERS"] = "Filtres supplémentaires"
L["RESET_ALL_FILTERS"] = "Réinitialiser tous les filtres"
L["FAVOURITES_ONLY"] = "Favoris uniquement"
L["ADD_FAVOURITE"] = "Ajouter aux favoris"
L["REMOVE_FAVOURITE"] = "Retirer des favoris"
L["PREFIX"] = "Préfixe"
L["SUFFIX"] = "Suffixe"

-- Rarity names
L["COMMON"] = "Commun"
L["UNCOMMON"] = "Peu commun"
L["RARE"] = "Rare"
L["EPIC"] = "Épique"
L["LEGENDARY"] = "Légendaire"
L["UNRANKED"] = "Non classé"

-- List header
L["N_TITLES"] = "%d titres"
L["SORT_COLLECTED_FIRST"] = "Obtenus en premier"
L["SORT_BY_EXPANSION"] = "Par extension"
L["SORT_ALPHABETICAL"] = "Alphabétique"
L["SORT_BY_QUALITY"] = "Par qualité"
L["SORT_BY_CATEGORY"] = "Par catégorie"

-- Group headers
L["GROUP_COLLECTED"] = "OBTENUS"
L["GROUP_NOT_COLLECTED"] = "PAS ENCORE OBTENUS"

-- Detail panel
L["PREVIEW_HOVERING"] = "APERÇU " .. DASH .. " SURVOL"
L["PREFIX_TITLE"] = "Titre en préfixe"
L["SUFFIX_TITLE"] = "Titre en suffixe"
L["HOW_TO_OBTAIN"] = "COMMENT L'OBTENIR"
L["DETAIL_MORE_ON_SELECT"] = "Sélectionnez ce titre pour en lire plus"
L["HELD_BY_ESTIMATE"] = "Porté par environ %s%% des personnages actifs."
L["EXPANSION_LABEL"] = "Extension"
L["CATEGORY_LABEL"] = "Catégorie"
L["AVAILABILITY_LABEL"] = "Disponibilité"
L["ACCOUNT_WIDE"] = "Lié au compte"
L["NO_LONGER_OBTAINABLE"] = "Plus disponible"
L["CURRENT_PATCH"] = "Correctif actuel " .. DOT .. " 12.0.5"
L["EARNED_DATE"] = "Obtenu le %s"
L["NOT_YET_EARNED"] = "Pas encore obtenu"

-- Action footer
L["SET_AS_MY_TITLE"] = "Définir comme mon titre"
L["SET_NOTE"] = "Affiché sous votre nom pour les autres joueurs."
L["CURRENT_TITLE"] = "Titre actuel"
L["CURRENT_NOTE"] = "Ce titre est affiché au-dessus de votre personnage."
L["LOCKED_BUTTON"] = "Pas encore obtenu"
L["LOCKED_NOTE"] = "Obtenez ce titre pour pouvoir le porter."

-- Empty states
L["NO_MATCH"] = "Aucun titre ne correspond à ces filtres."
L["NO_SELECTION"] = "Sélectionnez un titre pour voir sa source et sa rareté."

-- Bottom bar / rarity legend
L["RARITY"] = "RARETÉ"
L["SOURCE_LEGEND"] = "SOURCE"

-- Rarity explanation shown in the rarity info modal. Keep the wording in sync
-- with the rarity algorithm (TitlesDBCollector rarity.js).
L["RARITY_NOTE"] = "La rareté est un pourcentage de 0 à 100 estimant à quel point un titre est " ..
    "répandu parmi les joueurs actifs. 100 = le plus répandu, <1 = extrêmement rare. Calculée à " ..
    "partir de statistiques de profils externes (sources de données de popularité en ligne). Le " ..
    "palier de qualité (q) reflète le prestige : il découle de l'origine de la source " ..
    "(Gladiateur=5, méta de raid=3, etc.), avec un bonus de rareté appliqué aux titres " ..
    "définitivement indisponibles détenus par peu de joueurs (indisponible + moins de 2% de " ..
    "détenteurs = Épique minimum, moins de 5% = Rare minimum)."

-- Minimap
L["MINIMAP_TOOLTIP_TITLE"] = "Epithet"
L["MINIMAP_TOOLTIP_LEFT"] = "Clic gauche : ouvrir le navigateur de titres."
L["MINIMAP_TOOLTIP_RIGHT"] = "Clic droit : masquer ce bouton."
L["MINIMAP_HIDDEN"] = "Bouton de minicarte masqué. Tapez /epithet minimap pour le réafficher."
L["MINIMAP_SHOWN"] = "Bouton de minicarte affiché."

-- What's New
L["WHATS_NEW_HEADING"] = "Nouveautés"
L["WHATS_NEW_CLOSE"] = "Fermer"
L["WHATS_NEW_LINK_PROMPT"] = "Copiez ce lien :\nIl est déjà sélectionné ci-dessous - appuyez sur Ctrl+C pour le copier."

-- Social layer / title spotting
L["SOCIAL_LAYER"] = "Repérage de titres"
L["SOCIAL_LAYER_DESC"] = "Inspecter de parfaits inconnus est devenu une compétence de base. Faites-en autant avec leurs titres : repérez celui qu'un autre joueur a choisi de porter et découvrez aussitôt comment l'obtenir dans Epithet."
L["SOCIAL_ENABLED"] = "Activer le repérage de titres"
L["SOCIAL_STATE_SECTION"] = "État de la fonctionnalité"
L["SOCIAL_TARGET_UNLOCK"] = "Déverrouiller la barre d'infos de la cible (glisser pour déplacer)"
L["SOCIAL_TARGET_RESET"] = "Réinitialiser la position de la barre d'infos"
L["SOCIAL_TARGET_EDIT_HINT"] = "MODE ÉDITION · Clic gauche maintenu pour déplacer · Clic droit pour verrouiller"
L["SOCIAL_TARGET_EDIT_TOP"] = "MODE ÉDITION"
L["SOCIAL_TARGET_EDIT_BOTTOM"] = "Clic gauche maintenu pour déplacer · Clic droit pour verrouiller"
L["SOCIAL_TARGET_TOOLTIP_LEFT"] = "Clic gauche : afficher ce titre dans Epithet."
L["SOCIAL_TARGET_TOOLTIP_RIGHT"] = "Clic droit : déverrouiller et déplacer cette barre d'infos."
L["SOCIAL_TARGET_PLACEHOLDER_TITLE"] = "Titre d'exemple"
L["SOCIAL_TARGET_PLACEHOLDER_RARITY"] = "RARE"
L["SOCIAL_PRESTIGE_FORMAT"] = "%s %s"
L["SOCIAL_LAYOUT_SECTION"] = "Disposition de la barre d'infos"
L["SOCIAL_LAYOUT_CLASSIC"] = "Épurée"
L["SOCIAL_LAYOUT_PORTRAIT"] = "Carte portrait"
L["SOCIAL_LAYOUT_PREVIEW"] = "Aperçu de la disposition"
L["SOCIAL_LAYOUT_PREVIEW_NOTE"] = "L'aperçu utilise des données d'exemple."
L["SOCIAL_LAYOUT_FUNNY_TOGGLE"] = "Afficher l'aperçu avec un titre à rallonge"
L["SOCIAL_LAYOUT_PORTRAIT_MODE"] = "Mode de portrait de la cible"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_3D"] = "3D (animé)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_2D"] = "2D (fixe)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_NOTE"] = "La 3D utilise un modèle animé. La 2D utilise une image de portrait fixe."
L["SOCIAL_BEHAVIOUR_SECTION"] = "Règles d'affichage"
L["SOCIAL_FADE_SECTION"] = "Fondu"
L["SOCIAL_FADE_ENABLE"] = "Faire disparaître la barre d'infos après un délai"
L["SOCIAL_FADE_DURATION"] = "Délai avant le fondu"
L["SOCIAL_FADE_DURATION_FMT"] = "%.1f secondes avant le fondu"
L["SOCIAL_SHOW_SELF_TARGET"] = "Afficher la barre d'infos quand vous vous ciblez vous-même"
L["SOCIAL_SELF_TARGET_NOTE"] = "L'affichage de votre propre barre d'infos en auto-ciblage est purement visuel. Vous cibler vous-même ne compte jamais pour les hauts faits de repérage de titres."
L["SOCIAL_SPOTTING_NOTIFY"] = "Afficher les confirmations de repérage dans la fenêtre de discussion"
L["SOCIAL_ACHIEVEMENT_SECTION"] = "Hauts faits"
L["SOCIAL_ACHIEVEMENT_LAYER_DESC"] = "Les fenêtres de hauts faits couvrent aussi bien votre propre collection de titres que les titres repérés chez d'autres joueurs. Configurez ici la façon dont elles vous notifient : le repérage de titres se règle dans son propre onglet."
L["SOCIAL_ACHIEVEMENT_SPOTTING_DISABLED_NOTE"] = "Le repérage de titres est désactivé, les hauts faits de repérage ne peuvent donc pas progresser. Activez-le depuis l'onglet Repérage de titres pour qu'ils progressent à nouveau. Les hauts faits basés sur votre propre collection de titres restent suivis."
L["SOCIAL_ACHIEVEMENT_NOTIFY"] = "Notifications de hauts faits"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE"] = "Mode de notification des hauts faits"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_FULL"] = "Fenêtre + son"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_SILENT"] = "Fenêtre seule (son coupé)"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_OFF"] = "Désactivé"
L["SOCIAL_ACHIEVEMENT_ANCHOR_MODE"] = "Ancrage de la fenêtre de haut fait"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT"] = "Haut de l'écran (UIParent)"
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME"] = "Suivre l'AlertFrame de Blizzard"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT_DESC"] = "S'ancre en haut au centre de l'écran. C'est l'option la plus fiable si l'AlertFrame est déplacée ou masquée par un autre addon."
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME_DESC"] = "Suit la zone des annonces de hauts faits et de butin de Blizzard. Si un autre addon déplace ou masque l'AlertFrame, cette fenêtre le suit."
L["SOCIAL_POSITION_SECTION"] = "Position"

L["SPOTTING_NEW_SPOT_FMT"] = "Repéré : %s"
L["SPOTTING_LOG_TOOLTIP"] = "Journal de repérage (%d trouvés)"
L["SPOTTING_LOG_TOOLTIP_LEFT"] = "Clic gauche : ouvrir le journal de repérage."
L["SPOTTING_LOG_TOOLTIP_RIGHT"] = "Clic droit : crier vos statistiques de repérage dans /s."
L["SPOTTING_LOG_SHOUT_FMT_1"] = "J'ai admiré %d inconnus, dans des proportions tout à fait normales !"
L["SPOTTING_LOG_SHOUT_FMT_2"] = "J'ai inspecté %d inconnus à leur insu et sans leur consentement !"
L["SPOTTING_LOG_SHOUT_FMT_3"] = "Je juge en silence les titres de %d inconnus !"
L["SPOTTING_LOG_SHOUT_FMT_4"] = "%d inconnus ont été observés. Aucun ne s'en est aperçu. Excellent."
L["SPOTTING_LOG_SHOUT_FMT_5"] = "J'ai traqué %d aventuriers sans méfiance, rien que pour leurs titres !"
L["SPOTTING_LOG_HEADING"] = "Journal de repérage"
L["SPOTTING_LOG_COUNT_FMT"] = "%d titres repérés"
L["SPOTTING_LOG_COUNT_PROGRESS_FMT"] = "%d / %d titres repérés"
L["SPOTTING_LOG_COUNT_REMAINING_FMT"] = "%d titres restants"
L["SPOTTING_LOG_EMPTY"] = "Rien de repéré pour l'instant. Ciblez des joueurs dans le monde pour enregistrer les titres qu'ils portent."
L["SPOTTING_LOG_EMPTY_REMAINING"] = "Aucun titre restant dans le catalogue actuel."
L["SPOTTING_LOG_GATED"] = "Le repérage de titres est désactivé. Les observations ne sont pas enregistrées."
L["SPOTTING_LOG_OPEN_SETTINGS"] = "Activer dans les options"
L["SPOTTING_SCOPE_SPOTTED"] = "Repérés"
L["SPOTTING_SCOPE_REMAINING"] = "Restants"
L["SPOTTING_VIEW_LIST"] = "Liste"
L["SPOTTING_VIEW_GRID"] = "Grille"
L["SPOTTING_EXPORT_BUTTON"] = "Exporter"
L["SPOTTING_IMPORT_BUTTON"] = "Importer"
L["SPOTTING_EXPORT_TITLE"] = "Exporter le journal de repérage"
L["SPOTTING_IMPORT_TITLE"] = "Importer le journal de repérage"
L["SPOTTING_TRANSFER_NOTE"] = "Copiez ou collez l'intégralité des données ci-dessous."
L["SPOTTING_TRANSFER_COPY"] = "Tout sélectionner"
L["SPOTTING_TRANSFER_IMPORT"] = "Importer"
L["SPOTTING_TRANSFER_CLOSE"] = "Fermer"
L["SPOTTING_IMPORT_SUCCESS_FMT"] = "%d entrées de repérage importées."
L["SPOTTING_IMPORT_FAILED_FMT"] = "Échec de l'importation : %s"
L["SPOTTING_NOT_SPOTTED"] = "Restant"
L["SPOTTING_NOT_SPOTTED_YET"] = "Pas encore repéré."
L["SPOTTING_TOOLTIP_FIRST_FMT"] = "Repéré pour la première fois sur %s à %s le %s"
L["SPOTTING_TOOLTIP_RACE_FMT"] = "Race : %s"
L["SPOTTING_TOOLTIP_RACE_UNKNOWN"] = "Inconnue"
L["SPOTTING_TOOLTIP_COUNT_FMT"] = "Vu %d fois"
L["SPOTTING_TOOLTIP_LAST_FMT"] = "Vu pour la dernière fois le %s sur %s"

L["SPOT_ACHV_MODE"] = "Hauts faits"
L["SPOT_ACHV_HEADING"] = "Hauts faits Epithet"
L["SPOT_ACHV_TOOLTIP"] = "Hauts faits Epithet"
L["SPOT_ACHV_TOOLTIP_LEFT"] = "Clic gauche : ouvrir les hauts faits Epithet."
L["SPOT_ACHV_EMPTY"] = "Aucun haut fait Epithet disponible."
L["SPOT_ACHV_META_TITLE"] = "Notes de chasse aux hauts faits"
L["SPOT_ACHV_META_DESC"] = "Pour tout accomplir, il vous faudra peut-être coordonner vos repérages entre les classes, les factions, les périodes du calendrier et les observations répétées, avec des amis ou des membres de votre guilde."
L["SPOT_ACHV_COUNT_FMT"] = "%d / %d obtenus"
L["SPOT_ACHV_GROUP_SPOTTING"] = "Repérage"
L["SPOT_ACHV_GROUP_COLLECTION"] = "Collection"
L["SPOT_ACHV_GROUP_CROSSOVERS"] = "Croisements"
L["SPOT_ACHV_SECRET_NAME"] = "???"
L["SPOT_ACHV_SECRET_DESC"] = "Haut fait secret"
L["SPOT_ACHV_PROGRESS_FMT"] = "%d / %d"
L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"] = "%d / %d sur ce personnage"
L["SPOT_ACHV_EARNED_FMT"] = "Obtenu le %s"
L["SPOT_ACHV_ALERT_HEADER"] = "Haut fait Epithet"
L["SPOT_ACHV_CHAT_EARNED_FMT"] = "Haut fait obtenu - %s !"
L["SPOT_ACHV_DETAIL_WITH_FMT"] = "obtenu avec %s"
L["SPOT_ACHV_DETAIL_CLASSES_FMT"] = "obtenu sur %s classes"
L["SPOT_ACHV_DETAIL_ZONE_FMT"] = "obtenu à %s"
L["SPOT_ACHV_DETAIL_TITLE_FMT"] = "déclenché par %s"
L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"] = "obtenu sur %s extensions"
L["SPOT_ACHV_DETAIL_SECRETS_FMT"] = "obtenu sur %s secrets"
L["SPOT_ACHV_FWENDS_HINT"] = "Compte les titres que vous avez repérés pour la toute première fois sur cette personne."
L["SPOT_ACHV_DETAIL_TITLE"] = "Détails du haut fait"
L["SPOT_ACHV_DETAIL_CLOSE"] = "Fermer"
L["SPOT_ACHV_DETAIL_SECRET_STATUS"] = "Obtenez ce haut fait pour en révéler les détails."
L["SPOT_ACHV_ADMIN_TEST_NAME"] = "Haut fait de test admin"
L["SPOT_ACHV_ADMIN_TEST_DESC"] = "Test manuel de la fenêtre, déclenché par l'admin."

L["SPOT_ACHV_NAME_COUNT_1"] = "Première observation"
L["SPOT_ACHV_DESC_COUNT_1"] = "Repérez 1 titre distinct dans le monde."
L["SPOT_ACHV_NAME_COUNT_10"] = "Œil aiguisé"
L["SPOT_ACHV_DESC_COUNT_10"] = "Repérez 10 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_25"] = "Carnet de terrain"
L["SPOT_ACHV_DESC_COUNT_25"] = "Repérez 25 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_50"] = "Observateur aguerri"
L["SPOT_ACHV_DESC_COUNT_50"] = "Repérez 50 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_100"] = "L'espace vital est un mythe"
L["SPOT_ACHV_DESC_COUNT_100"] = "Repérez 100 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_200"] = "Fouineur invétéré"
L["SPOT_ACHV_DESC_COUNT_200"] = "Repérez 200 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_350"] = "Curieux compulsif"
L["SPOT_ACHV_DESC_COUNT_350"] = "Repérez 350 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_500"] = "Répertoire vivant"
L["SPOT_ACHV_DESC_COUNT_500"] = "Repérez 500 titres distincts dans le monde."
L["SPOT_ACHV_NAME_COUNT_700"] = "Toute la volière"
L["SPOT_ACHV_DESC_COUNT_700"] = "Repérez 700 titres distincts dans le monde."

L["SPOT_ACHV_NAME_ROLL_CALL"] = "Appel nominal"
L["SPOT_ACHV_DESC_ROLL_CALL"] = "Repérez des titres vus pour la première fois sur toutes les classes."
L["SPOT_ACHV_NAME_FULL_SPECTRUM"] = "Spectre complet"
L["SPOT_ACHV_DESC_FULL_SPECTRUM"] = "Repérez au moins un titre de chaque palier de rareté."
L["SPOT_ACHV_NAME_BOTH_ENDS"] = "Des deux côtés"
L["SPOT_ACHV_DESC_BOTH_ENDS"] = "Repérez au moins un titre en préfixe et un titre en suffixe."
L["SPOT_ACHV_NAME_GRAND_TOUR"] = "Grand tour"
L["SPOT_ACHV_DESC_GRAND_TOUR"] = "Repérez pour la première fois des titres dans 10 zones différentes."
L["SPOT_ACHV_NAME_TITLE_FWENDS"] = "Oooh, des copains à titres !"
L["SPOT_ACHV_DESC_TITLE_FWENDS"] = "Repérez pour la première fois 10 titres différents sur le même joueur."
L["SPOT_ACHV_NAME_HAVENT_WE_MET"] = "On se connaît, non ?"
L["SPOT_ACHV_DESC_HAVENT_WE_MET"] = "Voyez le même titre au moins 10 fois."
L["SPOT_ACHV_NAME_LONG_CON"] = "L'arnaque au long cours"
L["SPOT_ACHV_DESC_LONG_CON"] = "Revoyez un titre au moins 30 jours après l'avoir repéré pour la première fois."
L["SPOT_ACHV_NAME_NIGHT_SHIFT"] = "Équipe de nuit"
L["SPOT_ACHV_DESC_NIGHT_SHIFT"] = "Repérez un titre pour la première fois entre 03h00 et 04h59, heure locale."
L["SPOT_ACHV_NAME_BUSY_DAY"] = "Journée chargée"
L["SPOT_ACHV_DESC_BUSY_DAY"] = "Repérez pour la première fois au moins 5 titres au cours de la même journée locale."
L["SPOT_ACHV_NAME_CAPITAL_OFFENCE"] = "Crime capital"
L["SPOT_ACHV_DESC_CAPITAL_OFFENCE"] = "Repérez pour la première fois au moins 10 titres dans la même zone."
L["SPOT_ACHV_NAME_OLD_MONEY"] = "Vieille fortune"
L["SPOT_ACHV_DESC_OLD_MONEY"] = "Repérez un titre qui n'est plus disponible."
L["SPOT_ACHV_NAME_LEGENDARY_SPOT"] = "Cauchemar de complétiste"
L["SPOT_ACHV_DESC_LEGENDARY_SPOT"] = "Repérez un titre de qualité légendaire dans le monde."
L["SPOT_ACHV_NAME_POTTED_HISTORY"] = "Un condensé d'histoire"
L["SPOT_ACHV_DESC_POTTED_HISTORY"] = "Repérez au moins un titre de chaque extension."
L["SPOT_ACHV_NAME_DIPLOMATIC_IMMUNITY"] = "Immunité diplomatique"
L["SPOT_ACHV_DESC_DIPLOMATIC_IMMUNITY"] = "Repérez au moins un titre réservé à l'Alliance et un titre réservé à la Horde."
L["SPOT_ACHV_NAME_SMALL_WORLD"] = "Le monde est petit"
L["SPOT_ACHV_DESC_SMALL_WORLD"] = "Voyez le même titre sur deux personnes différentes."
L["SPOT_ACHV_NAME_CREATURE_OF_HABIT"] = "Force de l'habitude"
L["SPOT_ACHV_DESC_CREATURE_OF_HABIT"] = "Repérez pour la première fois au moins un titre 7 jours locaux consécutifs."
L["SPOT_ACHV_NAME_SEEING_STARS"] = "Voir des étoiles"
L["SPOT_ACHV_DESC_SEEING_STARS"] = "Repérez 5 titres de qualité légendaire."
L["SPOT_ACHV_NAME_MUSEUM_CURATOR"] = "Conservateur de musée"
L["SPOT_ACHV_DESC_MUSEUM_CURATOR"] = "Repérez 5 titres issus de contenu supprimé."
L["SPOT_ACHV_NAME_GNOME_SPOTTER"] = "Recensement de poche"
L["SPOT_ACHV_DESC_GNOME_SPOTTER"] = "Repérez 5 titres vus pour la première fois sur des gnomes."
L["SPOT_ACHV_NAME_AT_LEAST_CHICKEN"] = "Au moins, j'ai du poulet"
L["SPOT_ACHV_DESC_AT_LEAST_CHICKEN"] = "Repérez quelqu'un portant le titre Jenkins."
L["SPOT_ACHV_NAME_CERTIFIED"] = "Certifié"
L["SPOT_ACHV_DESC_CERTIFIED"] = "Repérez quelqu'un portant le titre le Dément."
L["SPOT_ACHV_NAME_OVERACHIEVER"] = "Zélé"
L["SPOT_ACHV_DESC_OVERACHIEVER"] = "Obtenez 15 hauts faits Epithet, en repérage comme en collection."
L["SPOT_ACHV_NAME_GUISING"] = "Déguisement"
L["SPOT_ACHV_DESC_GUISING"] = "Repérez un titre, quel qu'il soit, pour la première fois le 31 octobre, heure locale."
L["SPOT_ACHV_NAME_QUITE_A_MOUTHFUL"] = "Un peu long à dire"
L["SPOT_ACHV_DESC_QUITE_A_MOUTHFUL"] = "Repérez un titre dont le texte du catalogue fait 25 caractères ou plus."
L["SPOT_ACHV_NAME_TERSE"] = "Laconique"
L["SPOT_ACHV_DESC_TERSE"] = "Repérez un titre dont le texte du catalogue fait 5 caractères ou moins."
L["SPOT_ACHV_NAME_LORD_OF_LORDS"] = "Seigneur des seigneurs"
L["SPOT_ACHV_DESC_LORD_OF_LORDS"] = "Repérez 5 titres distincts dont le nom anglais contient « Lord »."
L["SPOT_ACHV_NAME_MASTERCLASS"] = "Cours de maître"
L["SPOT_ACHV_DESC_MASTERCLASS"] = "Repérez 5 titres distincts dont le nom anglais contient « Master »."
L["SPOT_ACHV_NAME_SLAY"] = "Massacre"
L["SPOT_ACHV_DESC_SLAY"] = "Repérez 5 titres distincts dont le nom anglais contient « Slayer »."
L["SPOT_ACHV_NAME_GLADIATOR_GROUPIE"] = "Groupie de gladiateur"
L["SPOT_ACHV_DESC_GLADIATOR_GROUPIE"] = "Repérez 5 titres issus de sources JcJ."
L["SPOT_ACHV_NAME_RAID_SPECTATOR"] = "Spectateur de raid"
L["SPOT_ACHV_DESC_RAID_SPECTATOR"] = "Repérez 5 titres issus de sources de raid."
L["SPOT_ACHV_NAME_BROWN_NOSER"] = "Lèche-bottes"
L["SPOT_ACHV_DESC_BROWN_NOSER"] = "Repérez 5 titres issus de sources de réputation."
L["SPOT_ACHV_NAME_HOW_ITS_MADE"] = "Fabriqué sous vos yeux"
L["SPOT_ACHV_DESC_HOW_ITS_MADE"] = "Repérez des titres provenant d'un haut fait, d'une quête et d'un objet."
L["SPOT_ACHV_NAME_PEOPLE_WATCHER"] = "Observateur de foule"
L["SPOT_ACHV_DESC_PEOPLE_WATCHER"] = "Enregistrez 500 observations au total."
L["SPOT_ACHV_NAME_PROFESSIONAL_LURKER"] = "Rôdeur professionnel"
L["SPOT_ACHV_DESC_PROFESSIONAL_LURKER"] = "Enregistrez 2 000 observations au total."
L["SPOT_ACHV_NAME_DOUBLE_TAKE"] = "Double prise"
L["SPOT_ACHV_DESC_DOUBLE_TAKE"] = "Revoyez le même titre dans l'heure qui suit son premier repérage."
L["SPOT_ACHV_NAME_EARLY_BIRD"] = "L'avenir appartient..."
L["SPOT_ACHV_DESC_EARLY_BIRD"] = "Repérez un titre pour la première fois entre 05h00 et 08h59, heure locale."
L["SPOT_ACHV_NAME_WEEKEND_WARRIOR"] = "Guerrier du week-end"
L["SPOT_ACHV_DESC_WEEKEND_WARRIOR"] = "Enregistrez 10 premières observations un samedi ou un dimanche."
L["SPOT_ACHV_NAME_FULL_WEEK"] = "La semaine complète"
L["SPOT_ACHV_DESC_FULL_WEEK"] = "Enregistrez des premières observations les 7 jours de la semaine."
L["SPOT_ACHV_NAME_YEAR_IN_FIELD"] = "Une année sur le terrain"
L["SPOT_ACHV_DESC_YEAR_IN_FIELD"] = "Enregistrez des premières observations sur les 12 mois de l'année."
L["SPOT_ACHV_NAME_WELCOME_BACK"] = "Bon retour parmi nous"
L["SPOT_ACHV_DESC_WELCOME_BACK"] = "Laissez passer au moins 90 jours entre deux premières observations consécutives."
L["SPOT_ACHV_NAME_FEAST_YOUR_EYES"] = "Régalez vos yeux"
L["SPOT_ACHV_DESC_FEAST_YOUR_EYES"] = "Repérez un titre pour la première fois le 25 décembre, heure locale."
L["SPOT_ACHV_NAME_PARTICIPATION_AWARD"] = "Prix de participation"
L["SPOT_ACHV_DESC_PARTICIPATION_AWARD"] = "Repérez un titre de qualité commune dans le monde."
L["SPOT_ACHV_NAME_SNEAKY_BEAKY"] = "En toute discrétion"
L["SPOT_ACHV_DESC_SNEAKY_BEAKY"] = "Repérez un titre pour la première fois sur un voleur."
L["SPOT_ACHV_NAME_DEAD_MAN_WALKING"] = "Mort en sursis"
L["SPOT_ACHV_DESC_DEAD_MAN_WALKING"] = "Repérez un titre pour la première fois sur un chevalier de la mort."
L["SPOT_ACHV_NAME_OLD_SCHOOL"] = "À l'ancienne"
L["SPOT_ACHV_DESC_OLD_SCHOOL"] = "Repérez un titre de l'époque Classic."
L["SPOT_ACHV_NAME_POPULAR"] = "Populaire"
L["SPOT_ACHV_DESC_POPULAR"] = "Faites en sorte que 3 personnes différentes soient à l'origine d'au moins 5 premières observations chacune."
L["SPOT_ACHV_NAME_RESTRAINING_ORDER"] = "Ordonnance restrictive"
L["SPOT_ACHV_DESC_RESTRAINING_ORDER"] = "Voyez le même titre au moins 25 fois."
L["SPOT_ACHV_NAME_BEYOND_THE_GRAVE"] = "Par-delà la tombe"
L["SPOT_ACHV_DESC_BEYOND_THE_GRAVE"] = "Enregistrez une observation en étant mort ou sous forme de fantôme."
L["SPOT_ACHV_NAME_KNOW_THY_ENEMY"] = "Connais ton ennemi"
L["SPOT_ACHV_DESC_KNOW_THY_ENEMY"] = "Enregistrez une observation sur un joueur de la faction adverse."
L["SPOT_ACHV_NAME_SECRET_KEEPER"] = "Gardien des secrets"
L["SPOT_ACHV_DESC_SECRET_KEEPER"] = "Obtenez tous les hauts faits secrets actuellement définis."

L["SPOT_ACHV_NAME_OWNED_1"] = "Premier du nom"
L["SPOT_ACHV_DESC_OWNED_1"] = "Possédez 1 titre sur ce personnage."
L["SPOT_ACHV_NAME_OWNED_10"] = "Des lettres après mon nom"
L["SPOT_ACHV_DESC_OWNED_10"] = "Possédez 10 titres sur ce personnage."
L["SPOT_ACHV_NAME_OWNED_25"] = "Célébrité locale"
L["SPOT_ACHV_DESC_OWNED_25"] = "Possédez 25 titres sur ce personnage."
L["SPOT_ACHV_NAME_OWNED_50"] = "Pairie"
L["SPOT_ACHV_DESC_OWNED_50"] = "Possédez 50 titres sur ce personnage."
L["SPOT_ACHV_NAME_OWNED_100"] = "Folie des grandeurs"
L["SPOT_ACHV_DESC_OWNED_100"] = "Possédez 100 titres sur ce personnage."
L["SPOT_ACHV_NAME_OWNED_SPECTRUM"] = "Habillé pour toutes les occasions"
L["SPOT_ACHV_DESC_OWNED_SPECTRUM"] = "Possédez au moins un titre de chaque palier de rareté."
L["SPOT_ACHV_NAME_OWNED_BOTH_ENDS"] = "Entre parenthèses"
L["SPOT_ACHV_DESC_OWNED_BOTH_ENDS"] = "Possédez au moins un titre en préfixe et un titre en suffixe."
L["SPOT_ACHV_NAME_OWNED_LEGENDARY"] = "Au-dessus de ma condition"
L["SPOT_ACHV_DESC_OWNED_LEGENDARY"] = "Possédez un titre de qualité légendaire."
L["SPOT_ACHV_NAME_OWNED_REMOVED"] = "Stock épuisé"
L["SPOT_ACHV_DESC_OWNED_REMOVED"] = "Possédez un titre issu de contenu supprimé."
L["SPOT_ACHV_NAME_IMPULSE_PURCHASE"] = "Achat impulsif"
L["SPOT_ACHV_DESC_IMPULSE_PURCHASE"] = "Obtenez un titre dans les 7 jours suivant son premier repérage."
L["SPOT_ACHV_NAME_CURRICULUM_VITAE"] = "Curriculum vitæ"
L["SPOT_ACHV_DESC_CURRICULUM_VITAE"] = "Possédez au moins un titre de chaque extension sur ce personnage."
L["SPOT_ACHV_NAME_DECORATED_VETERAN"] = "Vétéran décoré"
L["SPOT_ACHV_DESC_DECORATED_VETERAN"] = "Possédez 5 titres de source JcJ sur ce personnage."
L["SPOT_ACHV_NAME_NOTHING_NEW"] = "Rien de nouveau sous le soleil"
L["SPOT_ACHV_DESC_NOTHING_NEW"] = "Avec au moins 10 titres possédés, ayez également repéré chacun d'eux dans le monde."
L["SPOT_ACHV_NAME_MATCHING_SET"] = "Ensemble assorti"
L["SPOT_ACHV_DESC_MATCHING_SET"] = "Pour chaque palier de rareté, possédez et repérez au moins un titre de ce palier."

L["SPOT_ACHV_NAME_TAKES_ONE"] = "Il faut en être un pour en reconnaître un"
L["SPOT_ACHV_DESC_TAKES_ONE"] = "Repérez dans le monde un titre que ce personnage possédait déjà."
L["SPOT_ACHV_NAME_WINDOW_SHOPPER"] = "Lèche-vitrines"
L["SPOT_ACHV_DESC_WINDOW_SHOPPER"] = "Obtenez un titre que vous aviez d'abord repéré sur quelqu'un d'autre."
L["SPOT_ACHV_NAME_TWINSIES"] = "Jumeaux"
L["SPOT_ACHV_DESC_TWINSIES"] = "Repérez quelqu'un alors que vous portez tous les deux le même titre."

-- Source kinds
L["KIND_ACHIEVEMENT"] = "Haut fait"
L["KIND_QUEST"] = "Quête"
L["KIND_REPUTATION"] = "Réputation"
L["KIND_PVP_RANK"] = "Rang JcJ"
L["KIND_FEAT"] = "Exploit"
L["KIND_ITEM"] = "Objet"
L["KIND_PROMOTION"] = "Promotion"

-- Filter facets (new)
L["CATEGORY"] = "Catégorie"
L["KIND"] = "Type de source"
L["FACTION"] = "Faction"
L["FACTION_ALLIANCE"] = "Alliance"
L["FACTION_HORDE"] = "Horde"
L["FACTION_BOTH"] = "Les deux factions"
L["AVAILABILITY"] = "Disponibilité"
L["HIDE_UNOBTAINABLE"] = "Masquer les indisponibles"
L["HIDE_TIME_SENSITIVE"] = "Masquer les titres à durée limitée"
L["UNKNOWN_SOURCE"] = "Source inconnue"
L["FEAT_OF_STRENGTH"] = "Exploit (peut être indisponible)"

-- Source descriptions
L["SOURCE_ACHIEVEMENT_DESC"] = "Octroyé par le haut fait %s"
L["SOURCE_QUEST_DESC"] = "Octroyé lors de la quête %s"
L["SOURCE_ITEM_DESC"] = "Octroyé par %s"

-- Meta grid
L["LAST_ASSESSED"] = "Dernière évaluation"

-- Availability labels
L["AVAILABILITY_SEASONAL"] = "Saisonnier"
L["AVAILABILITY_LIMITED"] = "Limité"
L["AVAILABILITY_PROMOTIONAL"] = "Promotionnel"
L["AVAILABILITY_TEMPORARY"] = "Temporaire"
L["AVAILABILITY_REMOVED"] = "Supprimé"
L["AVAILABILITY_PERMANENT"] = "Permanent"

-- Previously-missing keys (had inline English fallbacks in code)
L["SOCIAL_HIDE_IN_COMBAT"] = "Masquer la barre d'infos de la cible en combat"
L["SOCIAL_HIDE_IN_GROUP"] = "Masquer la barre d'infos de la cible en groupe"
L["SPOTTING_META_TITLE"] = "Notes de repérage"
L["SPOTTING_META_DESC"] = "Ciblez des joueurs en zone ouverte pour enregistrer les titres qu'ils portent."
L["SPOT_ACHV_SECRET_EARNED_SUFFIX"] = "(secret)"
L["SPOT_ACHV_SECRET_EARNED_NOTE"] = "Vous avez découvert un haut fait secret."

-- Window banner (main frame title bar)
L["BANNER_LEFT"] = "EPITHET"
L["BANNER_RIGHT"] = "LA VITRINE DES TITRES"

-- Type tags (uppercase pills on title rows)
L["TYPE_TAG_PREFIX"] = "PRÉFIXE"
L["TYPE_TAG_SUFFIX"] = "SUFFIXE"

-- Rarity fallback
L["RARITY_UNKNOWN"] = "INCONNUE"

-- Minimap tooltip collected line
L["MINIMAP_TOOLTIP_COLLECTED"] = "Obtenus : %d / %d"

-- Slash command feedback
L["SLASH_SCAN_COMPLETE"] = "Analyse des titres terminée : %d / %d"

-- Version footer (two rows). %s placeholders filled at runtime.
L["VERSION_LINE1_FMT"] = "Epithet v%s  " .. DOT .. "  Interface %s"
L["VERSION_LINE2_FMT"] = "TitlesDB v%s  " .. DOT .. "  Mise à jour : %s"
L["VERSION_DATE_UNKNOWN"] = "inconnue"

-- Source-kind legend (bottom bar hover labels)
L["LEGEND_ACHIEVEMENT"] = "Haut fait"
L["LEGEND_QUEST"] = "Quête"
L["LEGEND_REPUTATION"] = "Réputation"
L["LEGEND_PVP"] = "JcJ"
L["LEGEND_FEAT"] = "Exploit"
L["LEGEND_EXPLORATION"] = "Exploration"
L["LEGEND_RAID"] = "Raid"

-- Layout preview sample data
L["SAMPLE_TITLE"] = "Maître des sbires"
L["SAMPLE_RARITY"] = "LÉGENDAIRE"
L["SAMPLE_FUNNY_TITLE"] = "Pourfendeur de sbires stupides, incompétents et décevants"

-- Fade slider bound labels
L["FADE_SLIDER_LOW"] = "0.5 s"
L["FADE_SLIDER_HIGH"] = "20 s"

-- Month names (used to format achievement earned dates: "dd Month yyyy").
-- French writes month names in lower case, e.g. "5 mars 2026".
L["MONTH_1"]  = "janvier"
L["MONTH_2"]  = "février"
L["MONTH_3"]  = "mars"
L["MONTH_4"]  = "avril"
L["MONTH_5"]  = "mai"
L["MONTH_6"]  = "juin"
L["MONTH_7"]  = "juillet"
L["MONTH_8"]  = "août"
L["MONTH_9"]  = "septembre"
L["MONTH_10"] = "octobre"
L["MONTH_11"] = "novembre"
L["MONTH_12"] = "décembre"

-- Expansion names (filter sidebar, detail panel, list rows). Keyed to match
-- the DB's stable expansion codes uppercased, e.g. "tbc" -> EXPANSION_TBC.
-- Blizzard ships the expansion titles untranslated on the French client, so
-- these deliberately stay in English to match the game.
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
L["CAT_PVP"] = "JcJ"
L["CAT_RAID"] = "Raid"
L["CAT_REPUTATION"] = "Réputation"
L["CAT_QUEST"] = "Quête"
L["CAT_PROFESSION"] = "Métier"
L["CAT_HOLIDAY"] = "Événement"
L["CAT_EXPLORATION"] = "Exploration"
L["CAT_ACHIEVEMENT"] = "Haut fait"
L["CAT_CAMPAIGN"] = "Campagne"
L["CATEGORY_UNCATEGORIZED"] = "Sans catégorie"

-- Detail panel meta-grid row labels
L["EARNED_LABEL"] = "Obtenu"
L["STATUS_LABEL"] = "Statut"

-- "ACTIVE" chip on the currently-equipped title's list row
L["ACTIVE_TITLE"] = "ACTIF"

-- About / info modal ("Grimmsforge" and "World of Warcraft" stay as-is: brands)
L["ABOUT_CRAFTED"] = "Epithet est conçu par Grimmsforge."
L["ABOUT_TAGLINE"] = "Outils et add-ons open source pour World of Warcraft."

-- Title-bar settings button
L["SETTINGS_BUTTON_TOOLTIP"] = "Ouvrir les options d'Epithet"
L["INFO_BUTTON_TOOLTIP"] = "À propos d'Epithet"

-- Language names (shown in the picker, in the active language)
L["LANGUAGE_ENGLISH"] = "Anglais"
L["LANGUAGE_RUSSIAN"] = "Russe"
L["LANGUAGE_GERMAN"] = "Allemand"
L["LANGUAGE_FRENCH"] = "Français"
L["LANGUAGE_SIMPLIFIED_CHINESE"] = "Chinois simplifié"

-- Options: general section (main Epithet settings page)
L["OPTIONS_GENERAL_SECTION"] = "Général"
L["OPTIONS_GENERAL_DESC"] = "Paramètres qui s'appliquent à l'ensemble d'Epithet."
L["OPTIONS_STARTUP_SECTION"] = "Démarrage"
L["OPTIONS_WHATSNEW_STARTUP_TOGGLE"] = "Afficher les nouveautés après une mise à jour"
L["OPTIONS_WHATSNEW_STARTUP_NOTE"] = "Affiché une seule fois, lors de votre première connexion sur une nouvelle version. Vous pouvez toujours le rouvrir avec /epithet whatsnew."

-- Options: language section
L["OPTIONS_LANGUAGE_SECTION"] = "Langue"
L["OPTIONS_LANGUAGE_LABEL"] = "Langue de l'add-on"
L["OPTIONS_LANGUAGE_AUTO"] = "Automatique (langue du client)"
L["OPTIONS_LANGUAGE_NOTE"] = "Définit la langue utilisée par Epithet, indépendamment de celle de votre client de jeu. L'interface se recharge lorsque vous la changez."
L["OPTIONS_LANGUAGE_RELOAD_PROMPT"] = "Changer la langue d'Epithet et recharger l'interface maintenant ?"
L["RELOAD_NOW"] = "Recharger"
L["LATER"] = "Plus tard"

-- The locale registry, ns.L proxy, and resolution API live in LocaleManager.lua.
