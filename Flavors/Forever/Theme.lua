-- =============================================================================
-- Epithet — WoW Forever theme: "Verdigris"
-- Loaded only on WoW Forever (Epithet.toc: [AllowLoadGameType camelot]),
-- straight after Core/Theme.lua and before any file that builds frames.
--
-- Taken from the Forever logo: a bronze compass ring on a teal sea map, with
-- ivory lettering. Each colour family has one job:
--   * deep-sea surfaces  — every panel, a dark blue-teal instead of brown
--   * bronze             — the frame: borders, resting buttons, idle icons
--   * gold and ivory     — yours: earned count, progress, selection, current title
--   * verdigris teal     — the world: dividers and the Logbook (spotting)
-- Rarity colours, fonts, the Epithet logo and Blizzard's own textures are
-- unchanged. Unnamed tokens keep the shared value; Ref roles follow their
-- source. To change one colour, edit it here; see Core/Theme.lua for every
-- token and how they are named.
-- =============================================================================
local _, ns = ...

ns.Theme.Apply({
    col = {
        -- Deep-sea surfaces, darkest to lightest.
        ink         = "050d10",
        surfaceDeep = "050e12",
        bg0         = "08141a",
        panel2      = "0a171d",
        bg1         = "0c1b22",
        chip        = "0d2128",
        panel       = "0e1f26",
        parch       = "10262e",
        raised      = "143039",

        -- Gold and ivory: earned, selected, progress.
        gold        = "e6c47e",
        goldBright  = "f7ead0",
        goldPale    = "efd9a9",
        goldGlow    = "fff4e0",

        -- Bronze: the frame.
        goldDim     = "a8865f",
        goldDeep    = "6b4f3a",
        bronze      = "876c53",
        frameBorder = "8a6d50",

        -- Verdigris: dividers.
        line        = { "7fb3ba", 0.22 },

        -- Text: cool ivory to slate.
        text         = "e4e6df",
        bodyText     = "c4ccc8",
        muted        = "8fa3a5",
        noteText     = "8a9c9c",
        faint        = "5f7477",
        locked       = "4f6165",
        textHover    = "fff1d0",
        dropdownText = "f1efe8",
        brandSubtitle = "9fb1b0",

        -- Factions: most Forever titles are faction PvP ranks, so Alliance
        -- gets its own blue instead of sharing the frame's gold.
        alliance    = "5b9be6",
        horde       = "e4544a",   -- a touch brighter: readable on the darker sea

        -- Standalone shades re-tinted to the sea (same lightness as Retail).
        btnBgSelected      = "17343d",
        btnDisabledBorder  = "1c2e33",
        iconDisabled       = "4f6467",
        toggleOnText       = "fff1d6",
        titleBtnBgHover    = "1a3a44",
        titleBtnIcon       = "f0d9a0",
        titleBtnIconHover  = "fff1d0",
        titleBtnLabel      = "dfe3da",
        titleBtnLabelHover = "f3f2ea",
        rowTitleLocked     = "6a7c7f",
        infoBtnBg          = "12292f",
        infoBtnBgHover     = "1b3c45",
        tierEmpty          = "2c4146",

        -- The title card shown on other players.
        plateBorder        = "b08d62",
        platePortraitBg    = "040a0c",
        plateRule          = "9b7d58",
        plateEditBg        = "10262e",
        pillBorder         = "efd9a9",
        portraitTextShadow = "02080a",
        portraitBgSoft     = "0b1619",
        previewFrameBorder = "7f6a52",

        -- Logbook: spotting titles in the world, so verdigris leads here.
        logbookCloseText        = "e9ece4",
        logbookInsetBg          = "07141a",
        logbookInsetBorder      = "2f5a62",
        -- The header's Logbook and Achievements buttons draw full-colour game
        -- icons, so these stay neutral: a tint would colour the whole icon.
        logbookToolIcon         = "e8e8e8",
        logbookToolIconHover    = "ffffff",
        logbookStateOn          = "4fb6c2",
        logbookStateOff         = "6d8285",
        logbookIconMasked       = "8da0a1",
        logbookTileBorderHover  = "6fc0c8",
        logbookTileBorderEarned = "b08d62",
        logbookTileStateLocked  = "dfe3da",
        logbookStatePlateBg     = "03090b",
        logbookStatePlateBorder = "a8865f",
        logbookStatePlateEarned = "f0cf86",
        logbookStatePlateLocked = "cdb68c",
        logbookSecretBorder     = "7fd0d8",
        logbookSecretText       = "b5eaee",
        logbookRowMeta          = "93a7a8",
        logbookRowTitle         = "d3d9d3",
        logbookRowTitleEarned   = "f3dfaf",
        logbookRowTitleMasked   = "8fa1a1",
    },
    quality = {
    },
    tex = {
        -- The portrait frame on the title card, drawn as the logo's compass
        -- ring. Same geometry as the shared ring, so the layout is unchanged.
        portraitRing = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-portrait-ring-forever",
        -- The compass ring around your portrait in the main window header:
        -- the same verdigris ring (Retail's is gold).
        headerPortraitRing = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-portrait-ring-forever",
    },
})

-- "FOREVER" over an infinity flourish, beside the seal in the main window's
-- title bar: Epithet's own serif in ivory and bronze (256x64, shown at 128x32).
ns.Theme.TitleBadge = {
    texture = ns.Theme.tex.badgeForever,
    width = 128,
    height = 32,
    x = 6,
    y = 0,
}
