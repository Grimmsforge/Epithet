-- =============================================================================
-- Epithet — Theme
-- Palette, quality colours and skinning helpers, centralising all visual tokens
-- so the addon matches the design spec. Lifted from design/Core/Theme.lua.
-- =============================================================================
local _, ns = ...

local Theme = {}
ns.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- hex "e8c873" -> {r,g,b,a,hex} in 0..1
local function C(hex, a)
    return {
        r = tonumber(hex:sub(1, 2), 16) / 255,
        g = tonumber(hex:sub(3, 4), 16) / 255,
        b = tonumber(hex:sub(5, 6), 16) / 255,
        a = a or 1,
        hex = hex,
    }
end

-- ---- surfaces (warm dark "parchment & gold") --------------------------
Theme.col = {
    ink       = C("0c0a06"),
    bg0       = C("120e09"),
    bg1       = C("1a140c"),
    panel     = C("1c1610"),
    panel2    = C("15100a"),
    inset     = C("0d0a06"),
    parch     = C("251d11"),
    gold      = C("e8c873"),
    goldBright= C("f6e2a6"),
    goldDim   = C("b9923f"),
    goldDeep  = C("7c5e26"),
    bronze    = C("8a6c34"),
    line      = C("b8985c", 0.22),
    lineSoft  = C("b8985c", 0.12),
    text      = C("e7dcc4"),
    muted     = C("9c8c6c"),
    faint     = C("6b6049"),
    locked    = C("5d5443"),
    warn      = C("d98a52"),
}

-- ---- rarity = WoW item quality (true pip colour + on-dark text) -------
Theme.quality = {
    [1] = { label = "Common",    pip = C("ffffff"), text = C("f1ede2") },
    [2] = { label = "Uncommon",  pip = C("1eff00"), text = C("5fe24a") },
    [3] = { label = "Rare",      pip = C("0070dd"), text = C("4ea3ff") },
    [4] = { label = "Epic",      pip = C("a335ee"), text = C("c98bff") },
    [5] = { label = "Legendary", pip = C("ff8000"), text = C("ffa334") },
}

-- ---- rarity gem icon paths, shared so UI/MainFrame.lua, UI/Detail.lua and
-- UI/TitleList.lua stay in sync if a new quality tier is ever added --------
-- Indexed by quality tier 1..5 (Common -> Legendary); callers can index by q directly.
Theme.RarityGems32 = {
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-1-common-32",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-2-uncommon-32",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-3-rare-32",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-4-epic-32",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-5-legendary-32",
}

Theme.RarityGems64 = {
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-1-common-64",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-2-uncommon-64",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-3-rare-64",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-4-epic-64",
    "Interface\\AddOns\\Epithet\\icons\\rarity\\epithet-rarity-5-legendary-64",
}

-- |cffRRGGBB....|r colour wrap for FontString rich text
function Theme.Wrap(hex, s)
    return "|cff" .. hex .. tostring(s) .. "|r"
end

-- ---- fonts: native TTFs that approximate the Cinzel/Marcellus pairing --
-- MORPHEUS = WoW's serif (quest titles) -> title-in-context & names
-- FRIZQT__ = WoW's body face -> labels, caps headings, body
--
-- The client's MORPHEUS/FRIZQT only cover its own region's script, so under the
-- language override a locale using a different script (e.g. Russian on a Western
-- client) renders as boxes. For such locales we use a bundled Unicode TTF; drop
-- the files into Epithet\Fonts\ (see Fonts\README.md). If a bundled file is
-- missing, SetFont fails and we fall back to the client font (uncovered glyphs
-- still show as boxes, but nothing errors).
local CLIENT_SERIF  = "Fonts\\MORPHEUS.TTF"
local CLIENT_SANS   = "Fonts\\FRIZQT__.TTF"
local BUNDLED_SERIF = "Interface\\AddOns\\Epithet\\Fonts\\Epithet-Serif.ttf"
local BUNDLED_SANS  = "Interface\\AddOns\\Epithet\\Fonts\\Epithet-Sans.ttf"

-- Active locales whose script isn't in the Western client fonts.
local BUNDLED_FONT_LOCALES = { ruRU = true }

local function NeedsBundledFont()
    local code = ns.activeLocale
    return code ~= nil and BUNDLED_FONT_LOCALES[code] == true
end

local function DefaultGameFontPath(fallback)
    if ns.activeLocale == "zhCN" and GameFontNormal and GameFontNormal.GetFont then
        local path = GameFontNormal:GetFont()
        if path then return path end
    end
    return fallback
end

function Theme.SerifFontPath()
    return NeedsBundledFont() and BUNDLED_SERIF or DefaultGameFontPath(CLIENT_SERIF)
end

function Theme.SansFontPath()
    return NeedsBundledFont() and BUNDLED_SANS or DefaultGameFontPath(CLIENT_SANS)
end

-- Set `preferred` on a font instance; if it fails, fall back to the client font
-- so text still draws. SetFont RAISES a Lua error for a missing/invalid asset
-- (it does not return false), so the attempt must be wrapped in pcall. Once a
-- path has failed we remember it and skip straight to the client font, so a
-- missing bundled font errors at most once per session instead of per widget.
local fontLoadFailed = {}
local function SafeFontSize(size)
    size = tonumber(size)
    if not size or size <= 0 or size ~= size then return 12 end
    return size
end

local function ApplyFont(fontLike, preferred, client, size, flags)
    size = SafeFontSize(size)
    flags = flags or ""
    if preferred ~= client and not fontLoadFailed[preferred] then
        if pcall(fontLike.SetFont, fontLike, preferred, size, flags) then
            return
        end
        fontLoadFailed[preferred] = true
    end
    fontLike:SetFont(client, size, flags)
end

-- Unconditionally applies the bundled Unicode Sans font (PT Sans: Latin +
-- Cyrillic), regardless of the active display locale. Theme.Sans/SansFontPath
-- gate on NeedsBundledFont() because most text is purely in the active
-- locale's own script, but some content (e.g. the WhatsNew popup's
-- multilingual headings) deliberately mixes scripts on a single line, so a
-- reader on an English or French client can still land on Cyrillic text that
-- the client font can't render. Falls back to the client font exactly like
-- ApplyFont does if the bundled file is ever missing.
function Theme.ApplyUnicodeSansFont(fontLike, size, flags)
    if not fontLike then return end
    ApplyFont(fontLike, BUNDLED_SANS, CLIENT_SANS, size or 12, flags)
end

function Theme.Serif(parent, size, col)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    ApplyFont(fs, Theme.SerifFontPath(), CLIENT_SERIF, size or 16)
    if col then fs:SetTextColor(col.r, col.g, col.b, col.a or 1) end
    return fs
end

function Theme.Sans(parent, size, col)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    ApplyFont(fs, Theme.SansFontPath(), CLIENT_SANS, size or 12)
    if col then fs:SetTextColor(col.r, col.g, col.b, col.a or 1) end
    return fs
end

-- Shared font OBJECT for Blizzard template widgets (dropdowns) that take a
-- fontObject instead of a raw SetFont. Returns nil when the client fonts already
-- cover the active locale, so those widgets keep their default look unchanged.
-- Returned objects are cached per size and shared, so treat them as immutable.
local localeFontObjects = {}
function Theme.LocaleFontObject(size)
    if not NeedsBundledFont() then return nil end
    size = size or 12
    local obj = localeFontObjects[size]
    if not obj then
        obj = CreateFont("EpithetLocaleFont" .. size)
        ApplyFont(obj, BUNDLED_SANS, CLIENT_SANS, size)
        obj:SetTextColor(0.96, 0.92, 0.82)
        localeFontObjects[size] = obj
    end
    return obj
end

-- Re-point an EXISTING FontString (from an XML template or a Blizzard game font
-- like GameFontDisableSmall) at the bundled Unicode face when the active locale
-- needs it — for text that isn't created via Theme.Sans/Serif. A no-op on
-- locales the client fonts already cover, so those widgets keep their template
-- look. Preserves the widget's current size and outline flags.
function Theme.ApplyLocaleFont(fontLike)
    if not fontLike or not NeedsBundledFont() then return end
    local _, size, flags = fontLike:GetFont()
    ApplyFont(fontLike, BUNDLED_SANS, CLIENT_SANS, size or 12, flags)
end

-- Public form of the gate, so callers can skip bookkeeping (e.g. "already done"
-- flags) that would otherwise latch on a run where this was a no-op.
function Theme.NeedsLocaleFont() return NeedsBundledFont() end

-- Re-points EVERY FontString under `frame` at the bundled face.
--
-- Per-widget opt-in does not scale: Blizzard templates and XML-defined
-- FontStrings never route through Theme.Sans/Serif, so each one that nobody
-- remembered to call Theme.ApplyLocaleFont on renders as boxes — which is
-- exactly what the list header, row source lines, type pills, detail meta rows
-- and most of the options panel were doing. Walking a panel once after it is
-- built catches all of them, including widgets a template added for us.
--
-- The client serif maps to the bundled serif and everything else to the bundled
-- sans, so the theme's type pairing survives the sweep. FontStrings already on a
-- bundled face are left untouched, which keeps Theme.Serif headings serif.
local MAX_FONT_TREE_DEPTH = 12
function Theme.ApplyLocaleFontToTree(frame, depth)
    if not frame or not NeedsBundledFont() then return end

    depth = (depth or 0) + 1
    if depth > MAX_FONT_TREE_DEPTH then return end

    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for i = 1, #regions do
            local region = regions[i]
            if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.GetFont then
                local current, size, flags = region:GetFont()
                if current ~= BUNDLED_SANS and current ~= BUNDLED_SERIF then
                    local isSerif = type(current) == "string"
                        and current:upper():find("MORPHEUS", 1, true) ~= nil
                    ApplyFont(region,
                        isSerif and BUNDLED_SERIF or BUNDLED_SANS,
                        isSerif and CLIENT_SERIF or CLIENT_SANS,
                        size or 12, flags)
                end
            end
        end
    end

    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for i = 1, #children do
            Theme.ApplyLocaleFontToTree(children[i], depth)
        end
    end
end

-- caps "display" label (caller uppercases text before setting)
function Theme.Disp(parent, size, col)
    local fs = Theme.Sans(parent, size or 11, col or Theme.col.gold)
    fs:SetSpacing(2)
    return fs
end

-- ---- solid colour texture (pips, accents, fills) ----------------------
function Theme.Tex(parent, col, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetColorTexture(col.r, col.g, col.b, col.a or 1)
    return t
end

-- ---- a flat tinted panel with a 1px hairline border -------------------
function Theme.Panel(parent, bg, border, borderA)
    local fr = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    fr:SetBackdrop({
        bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    bg = bg or Theme.col.panel
    fr:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 1)
    border = border or Theme.col.line
    fr:SetBackdropBorderColor(border.r, border.g, border.b, borderA or border.a or 1)
    return fr
end

-- small gold diamond (rotated square) — the window corner ornament
function Theme.Diamond(parent, size, col)
    local t = Theme.Tex(parent, col or Theme.col.gold, "OVERLAY")
    t:SetSize(size or 10, size or 10)
    t:SetRotation(math.rad(45))
    return t
end
