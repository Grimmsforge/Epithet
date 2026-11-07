-- =============================================================================
-- Epithet — Theme
-- The one place Epithet's colours live, plus the skinning and font helpers.
--
-- HOW COLOUR WORKS
--   * Every colour is a named TOKEN in Theme.col (or Theme.quality for rarity
--     tiers). A token is a table { r, g, b, a, hex } with channels in 0..1.
--   * Code never writes raw numbers. It reads a token:
--         fs:SetTextColor(T.RGBA(T.col.gold))           -- token's own alpha
--         tex:SetColorTexture(T.RGBA(T.col.goldDeep, 0.85)) -- alpha for this use
--         T.Paint(region, "text", T.col.muted)           -- same, by kind
--         T.Wrap(T.col.gold, "Epithet")                   -- |cff...|r rich text
--     Alpha is usually a property of the use, not the colour, so call sites
--     pass it; the token's alpha is the default.
--   * scripts/validate/validate-theme.ps1 fails on raw colour numbers outside
--     this file and on references to undefined tokens.
--
-- TOKEN NAMING
--   * The base palette (ink ... goldGlow) holds the actual shades. Changing
--     one recolours everything built from it.
--   * Role tokens are named for the one component that uses them (btnBg,
--     plateBorder, logbookTileBg, ...), so a flavour can restyle one component
--     without touching the rest.
--   * A role written Ref("gold") FOLLOWS a palette token: same colour, and the
--     same alpha unless Ref("gold", 0.5) gives its own. Overriding the palette
--     token restyles every role that follows it; overriding the role itself
--     detaches it. A Ref must point at a token that is not itself a Ref.
--   * A role with its own value (RGB / C) is a shade no palette token matches
--     yet. Pointing it at one is how near-duplicates are merged: a deliberate,
--     visible edit to this file (see "Merging" below), never a side effect.
--
-- MERGING (stage 1, 2026-11-07)
--   Roles that held exactly a palette value now Ref it (no visible change).
--   Roles within two 8-bit steps of a palette shade now Ref that shade (a
--   change no eye can see); each such merge is marked "merged, Nstep" with the
--   step count. Larger merges are left as candidates for an in-game review.
--
-- PER-FLAVOUR TWEAKS
--   Each flavour can ship a Flavors/<Flavour>/Theme.lua, gated in the TOC by
--   game type and loaded straight after this file, which calls Theme.Apply():
--
--       ns.Theme.Apply({
--           col     = { gold = "d9a441", btnBg = { 0.12, 0.09, 0.05 } },
--           quality = { [5] = { text = "ffb04a" } },
--       })
--
--   Apply rewrites the existing token tables IN PLACE, so any code holding a
--   token (local GOLD = T.col.gold) sees the new value. It must still run
--   before frames are built, because frames copy colours when they are painted;
--   that is why the override file loads before every other UI file, and why
--   Apply warns once the addon has initialised (Theme.Seal).
--
-- Values were lifted from the original hard-coded colours with no visual
-- change: a raw colour reuses a palette token only when every channel rounds to
-- within one 8-bit step of it; otherwise it got its own token with its exact
-- value.
-- =============================================================================
local _, ns = ...

local Theme = {}
ns.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"

local floor, format = math.floor, string.format

local function ToHex(v)
    return floor(v * 255 + 0.5)
end

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

-- exact 0..1 channels -> {r,g,b,a,hex}; hex is the nearest 8-bit value, for
-- |cff rich text.
local function RGB(r, g, b, a)
    return {
        r = r, g = g, b = b, a = a or 1,
        hex = format("%02x%02x%02x", ToHex(r), ToHex(g), ToHex(b)),
    }
end

-- A role that follows another token (see TOKEN NAMING). Resolved below, once
-- Theme.col exists, and again after every Theme.Apply.
local REF = {}
local function Ref(source, a)
    return { [REF] = true, source = source, a = a }
end

Theme.col = {
    -- ---- base palette (warm dark "parchment & gold") ---------------------
    ink       = C("0c0a06"),
    bg0       = C("120e09"),
    bg1       = C("1a140c"),
    panel     = C("1c1610"),
    panel2    = C("15100a"),
    inset     = Ref("ink"),              -- merged, 1 step (was 0d0a06)
    parch     = C("251d11"),
    raised    = RGB(0.16, 0.12, 0.07),   -- hovered / raised dark surface
    surfaceDeep = RGB(0.06, 0.05, 0.03), -- darkest floating surface (pill, Logbook modal)
    chip      = RGB(0.12, 0.10, 0.06),   -- small inset chips (sidebar segment, detail sigil)
    gold      = C("e8c873"),
    goldBright= C("f6e2a6"),
    goldPale  = RGB(0.95, 0.82, 0.48),   -- selected edge, scroll fade
    goldGlow  = RGB(1.0, 0.92, 0.70),    -- selected / hovered light text
    goldDim   = C("b9923f"),
    goldDeep  = C("7c5e26"),
    bronze    = C("8a6c34"),
    line      = C("b8985c", 0.22),
    lineSoft  = Ref("line", 0.12),
    text      = C("e7dcc4"),
    muted     = C("9c8c6c"),
    faint     = C("6b6049"),
    locked    = C("5d5443"),
    warn      = C("d98a52"),
    black     = RGB(0, 0, 0),            -- scrims and shades (alpha set per use)
    white     = RGB(1, 1, 1),            -- washes and full-bright text

    -- ---- brand -------------------------------------------------------------
    brandGold     = C("e8c767"),         -- window banner, About title and link
    brandSubtitle = C("b0a284"),         -- window banner, right half

    -- ---- shared surfaces ---------------------------------------------------
    surface       = Ref("bg0"),              -- merged, 2 steps (was 0.08, 0.06, 0.03)
    frameBorder   = RGB(0.55, 0.45, 0.26),   -- modal/panel borders and dividers
    bodyText      = RGB(0.78, 0.74, 0.66),   -- long-form description text
    noteText      = RGB(0.58, 0.52, 0.42),   -- detail obtainability reason
    textHover     = RGB(1.0, 0.92, 0.6),     -- link / close-text hover
    dropdownText  = RGB(0.96, 0.92, 0.82),   -- locale font object for dropdowns

    -- ---- gold-bordered buttons (Theme.SkinButton) --------------------------
    btnBg            = Ref("bg1"),           -- merged, 2 steps (was 0.11, 0.08, 0.04)
    btnBgHover       = Ref("raised"),
    btnBgSelected    = RGB(0.20, 0.15, 0.08),
    btnBorder        = Ref("goldDeep"),
    btnBorderHover   = Ref("gold"),
    btnBorderSelected= Ref("goldPale"),
    btnBorderSoft    = Ref("gold", 0.5),     -- About "Close": a softer resting edge
    btnText          = Ref("gold"),
    btnTextHover     = Ref("goldBright"),
    btnTextSelected  = Ref("goldGlow"),
    btnActiveBg      = Ref("gold"),          -- "Current title": gold fill
    btnActiveBorder  = Ref("gold"),
    btnActiveText    = Ref("ink"),
    btnDisabledBg    = Ref("bg0"),           -- merged, 1 step (was 0.07, 0.05, 0.03)
    btnDisabledBorder= RGB(0.20, 0.16, 0.10),
    btnDisabledText  = Ref("locked"),        -- merged, 2 steps (was 0.36, 0.33, 0.27)
    iconDisabled     = RGB(0.40, 0.36, 0.28),
    toggleOnText     = RGB(1, 0.92, 0.72),   -- Settings "enabled" label

    -- ---- main window chrome (UI/MainFrame.xml) ----------------------------
    titleBtnBg          = Ref("raised"),
    titleBtnBgHover     = RGB(0.21, 0.16, 0.10),
    titleBtnBorder      = Ref("line", 1),
    titleBtnBorderHover = Ref("gold"),
    titleBtnIcon        = RGB(0.95, 0.85, 0.55),
    titleBtnIconHover   = RGB(1.0, 0.95, 0.75),
    titleBtnLabel       = RGB(0.92, 0.85, 0.67),
    titleBtnLabelHover  = RGB(0.96, 0.91, 0.78),
    closeBtnBorder      = Ref("warn"),
    closeBtnBorderHover = RGB(0.97, 0.70, 0.45),
    closeBtnBgHover     = RGB(0.22, 0.14, 0.09),
    closeBtnIcon        = Ref("white"),          -- before first hover
    closeBtnIconIdle    = RGB(0.95, 0.80, 0.66), -- after hover ends (differs from closeBtnIcon today)
    closeBtnIconHover   = RGB(0.99, 0.89, 0.74),
    progressTrack       = Ref("parch"),          -- merged, 2 steps (was 0.14, 0.11, 0.06)
    progressBorder      = Ref("frameBorder"),    -- merged, 2 steps (was 0.55, 0.45, 0.25)
    segmentBg           = Ref("chip"),           -- sidebar status segment (idle)

    -- ---- title list rows ---------------------------------------------------
    rowTitleActive  = Ref("white"),
    rowTitleLocked  = RGB(0.50, 0.46, 0.36),

    -- ---- title status ------------------------------------------------------
    alliance      = Ref("gold"),
    horde         = RGB(0.85, 0.20, 0.20),
    unobtainable  = RGB(0.85, 0.35, 0.30),
    timeSensitive = RGB(0.90, 0.70, 0.25),

    -- ---- detail panel ------------------------------------------------------
    infoBtnBg      = RGB(0.18, 0.15, 0.10),
    infoBtnBgHover = RGB(0.28, 0.23, 0.14),
    sigilBg        = Ref("chip"),
    detailTrack    = Ref("raised"),          -- merged, 2 steps (was 0.16, 0.13, 0.08)
    tierEmpty      = RGB(0.30, 0.27, 0.21),

    -- ---- social layer (target plate, pill, Settings preview) --------------
    plateBg            = Ref("bg0"),         -- merged, 2 steps (was 0.08, 0.06, 0.04)
    plateBorder        = RGB(0.72, 0.58, 0.26),
    platePortraitBg    = RGB(0.05, 0.05, 0.05),
    plateRule          = RGB(0.70, 0.58, 0.31),
    plateRarityText    = RGB(0.75, 0.75, 0.75), -- rarity line without the theme font
    plateEditBg        = RGB(0.14, 0.10, 0.06),
    plateEditHighlight = RGB(1, 0.9, 0.4),
    pillBg             = Ref("surfaceDeep"),
    pillBorder         = RGB(0.95, 0.84, 0.52),
    portraitTextShadow = RGB(0.08, 0.05, 0.01),
    portraitBgSoft     = RGB(0.09, 0.08, 0.08),
    previewFrameBorder = RGB(0.55, 0.46, 0.30),
    previewAccent      = Ref("timeSensitive"),

    -- ---- What's New --------------------------------------------------------
    scrollFade = Ref("goldPale"),

    -- ---- Logbook (Spotting/LogbookUI.lua) ---------------------------------
    logbookCloseText       = RGB(0.95, 0.90, 0.75),
    logbookCloseHover      = Ref("goldGlow"),
    logbookModalBg         = Ref("surfaceDeep"),
    logbookInsetBg         = RGB(0.08, 0.07, 0.05),
    logbookInsetBorder     = RGB(0.40, 0.34, 0.22),
    logbookInfoBg          = Ref("panel2"),  -- merged, 2 steps (was 0.09, 0.07, 0.04)
    logbookToolIcon        = RGB(0.86, 0.74, 0.40),
    logbookToolIconHover   = RGB(1.0, 0.9, 0.55),
    logbookStateOn         = RGB(0.90, 0.74, 0.30),
    logbookStateOff        = RGB(0.56, 0.52, 0.45),
    logbookIconMasked      = RGB(0.66, 0.62, 0.55),
    logbookIconLocked      = RGB(0.72, 0.72, 0.72),
    logbookTileBg          = Ref("panel"),   -- merged, 1 step (was 0.11, 0.09, 0.06)
    logbookTileBorderHover = RGB(0.83, 0.70, 0.36),
    logbookTileBorderEarned= RGB(0.67, 0.57, 0.30),
    logbookTileStateLocked = RGB(0.88, 0.84, 0.75),
    logbookStatePlateBg    = RGB(0.02, 0.02, 0.02),
    logbookStatePlateBorder= RGB(0.72, 0.58, 0.28),
    logbookStatePlateEarned= RGB(0.95, 0.80, 0.36),
    logbookStatePlateLocked= RGB(0.86, 0.74, 0.42),
    logbookSecretBorder    = RGB(0.94, 0.80, 0.40),
    logbookSecretText      = RGB(0.96, 0.88, 0.56),
    logbookRowMeta         = RGB(0.72, 0.66, 0.56),
    logbookRowTitle        = RGB(0.84, 0.80, 0.71),
    logbookRowTitleEarned  = RGB(0.96, 0.88, 0.62),
    logbookRowTitleMasked  = RGB(0.70, 0.66, 0.58),
}

-- Turn each Ref placeholder into a token table of its own (so code may hold
-- it like any other) and remember what it follows.
local refs = {}
for name, value in pairs(Theme.col) do
    if value[REF] then
        refs[name] = { source = value.source, a = value.a }
        Theme.col[name] = { r = 0, g = 0, b = 0, a = 1, hex = "000000" }
    end
end
for name, ref in pairs(refs) do
    if not Theme.col[ref.source] then
        error("Epithet Theme: col." .. name .. " follows unknown token '" .. tostring(ref.source) .. "'")
    elseif refs[ref.source] then
        error("Epithet Theme: col." .. name .. " follows col." .. ref.source .. ", which is itself a Ref")
    end
end

-- Copy every following role's colour from its source, in place.
local function ResolveRefs()
    for name, ref in pairs(refs) do
        local source, token = Theme.col[ref.source], Theme.col[name]
        token.r, token.g, token.b, token.hex = source.r, source.g, source.b, source.hex
        token.a = ref.a or source.a
    end
end
ResolveRefs()

-- The token a role follows, or nil when it has a value of its own.
function Theme.RefSource(name)
    return refs[name] and refs[name].source or nil
end

-- ---- rarity = WoW item quality (true pip colour + on-dark text) -------
-- Also exposed as ns.QUALITY_COLOURS (Core/TitleData.lua), so there is one
-- quality palette.
Theme.quality = {
    [1] = { label = "Common",    pip = C("ffffff"), text = C("f1ede2") },
    [2] = { label = "Uncommon",  pip = C("1eff00"), text = C("5fe24a") },
    [3] = { label = "Rare",      pip = C("0070dd"), text = C("4ea3ff") },
    [4] = { label = "Epic",      pip = C("a335ee"), text = C("c98bff") },
    [5] = { label = "Legendary", pip = C("ff8000"), text = C("ffa334") },
}

-- ---------------------------------------------------------------------------
-- Reading tokens
-- ---------------------------------------------------------------------------

-- r, g, b, a of a token, for any Set*Color call. `a` overrides the token's own
-- alpha for this use. Errors on a missing token so a typo shows at its call
-- site instead of silently painting white.
function Theme.RGBA(token, a)
    if type(token) ~= "table" or token.r == nil then
        error("Epithet Theme: missing colour token", 2)
    end
    return token.r, token.g, token.b, a or token.a or 1
end

-- Paint a region by kind: "text" (FontString:SetTextColor), "fill"
-- (Texture:SetColorTexture, a solid colour texture), "tint"
-- (Texture:SetVertexColor, tinting a texture file), "bar"
-- (StatusBar:SetStatusBarColor), "shadow" (FontString:SetShadowColor),
-- "backdrop" / "border" (BackdropTemplate colour / border colour).
local PAINTERS = {
    text     = "SetTextColor",
    fill     = "SetColorTexture",
    tint     = "SetVertexColor",
    bar      = "SetStatusBarColor",
    shadow   = "SetShadowColor",
    backdrop = "SetBackdropColor",
    border   = "SetBackdropBorderColor",
}
function Theme.Paint(region, kind, token, a)
    if not region then return end
    local method = PAINTERS[kind]
    if not method then
        error("Epithet Theme: unknown paint kind '" .. tostring(kind) .. "'", 2)
    end
    region[method](region, Theme.RGBA(token, a))
end

-- Apply a declarative skin to a frame tree. `spec` is a list of
-- { "Path.To.Region", kind, tokenName, alpha? }, where the path walks
-- parentKeys from `root` ("" is root itself). Used for XML-defined frames,
-- whose colours used to be literal <Color> tags that no override could reach.
function Theme.ApplySkin(root, spec)
    if not root then return end
    for _, entry in ipairs(spec) do
        local path, kind, name, a = entry[1], entry[2], entry[3], entry[4]
        local region = root
        for key in path:gmatch("[^%.]+") do
            region = region and region[key]
        end
        local token = Theme.col[name]
        if not token then
            error("Epithet Theme: skin references unknown token '" .. tostring(name) .. "'", 2)
        end
        if region then
            Theme.Paint(region, kind, token, a)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Component: the ring around the player's portrait in the main window header
-- ---------------------------------------------------------------------------
-- UI/MainFrame.lua builds it from this spec; a flavour can change it in
-- Flavors/<Flavour>/Theme.lua:
--   tex          the Theme.tex name of the ring texture
--   size         ring size in pixels. The compass ring's hole is about 0.66 of
--                its size, so 68 frames the 46 px portrait.
--   tint         colour token to tint it with, or nil for the texture's own colours
--   tintAlpha    alpha for the tint
--   overPortrait false: a backing disc behind the portrait. true: a frame with a
--                hole, drawn over the portrait's edge
-- The compass ring on every flavour: gold here, verdigris on WoW Forever (its
-- Theme.lua overrides tex.headerPortraitRing).
Theme.HeaderPortraitRing = {
    tex = "headerPortraitRing",
    size = 68,
    tint = nil,
    tintAlpha = 1,
    overPortrait = true,
}

-- An optional badge beside the seal in the main window's title bar, set by a
-- flavour in Flavors/<Flavour>/Theme.lua (WoW Forever's "FOREVER"):
--   { texture = path, width = px, height = px, x = gap after the seal, y = offset }
-- Nil: no badge.
Theme.TitleBadge = nil

-- ---------------------------------------------------------------------------
-- Component: bordered button
-- ---------------------------------------------------------------------------
-- Epithet's dark button with a one-pixel border (Settings, What's New, the
-- Detail panel, About, the Logbook). Theme.SkinButton(button, looks) adds the
-- background (button.bg) and four border edges (button.borders) and paints
-- the button from `looks`:
--
--   looks = { idle = LOOK, hover = LOOK, <state> = LOOK, ... }
--   LOOK  = { bg = { "token", alpha? }, border = { ... }, text = { ... }, icon = { ... } }
--
-- A look paints only the parts it names, so a site that colours its own label
-- or icon (the favourite toggle) leaves that part out. The text part is
-- button.text (or button.label), the icon part is button.icon: create them
-- before calling SkinButton. Tokens are looked up by name at paint time, so
-- flavour overrides always apply.
--
-- button:SetLook(state) changes the resting look ("idle", "selected",
-- "active", "disabled", ...). Hover applies only while the resting look is
-- "idle": a selected tab or a disabled / current-title button does not react.
-- Leaving repaints the resting look.
--
-- Theme.ButtonLooks.standard is the shared set. Theme.ButtonVariant(base,
-- changes) derives a site's variant: `changes` is { state = LOOK }, merged part
-- by part, and a part set to false is dropped.
Theme.ButtonLooks = {
    standard = {
        idle     = { bg = { "btnBg" },         border = { "btnBorder" },         text = { "btnText" } },
        hover    = { bg = { "btnBgHover" },    border = { "btnBorderHover" },    text = { "btnTextHover" } },
        selected = { bg = { "btnBgSelected" }, border = { "btnBorderSelected" }, text = { "btnTextSelected" } },
        active   = { bg = { "btnActiveBg" },   border = { "btnActiveBorder" },   text = { "btnActiveText" } },
        disabled = { bg = { "btnDisabledBg" }, border = { "btnDisabledBorder" }, text = { "btnDisabledText" } },
    },
}

function Theme.ButtonVariant(base, changes)
    local out = {}
    for state, look in pairs(base) do
        out[state] = {}
        for part, value in pairs(look) do out[state][part] = value end
    end
    for state, look in pairs(changes or {}) do
        out[state] = out[state] or {}
        for part, value in pairs(look) do
            if value == false then out[state][part] = nil else out[state][part] = value end
        end
    end
    return out
end

local BUTTON_EDGES = {
    { "TOPLEFT", "TOPRIGHT", "SetHeight" },      -- top
    { "BOTTOMLEFT", "BOTTOMRIGHT", "SetHeight" }, -- bottom
    { "TOPLEFT", "BOTTOMLEFT", "SetWidth" },     -- left
    { "TOPRIGHT", "BOTTOMRIGHT", "SetWidth" },   -- right
}
local LOOK_PARTS = { bg = true, border = true, text = true, icon = true }

local function PaintPart(region, kind, part)
    if region and part then
        Theme.Paint(region, kind, Theme.col[part[1]], part[2])
    end
end

local function PaintLook(button, look)
    if not look then return end
    PaintPart(button.bg, "fill", look.bg)
    if look.border then
        for _, edge in ipairs(button.borders) do PaintPart(edge, "fill", look.border) end
    end
    PaintPart(button.text or button.label, "text", look.text)
    PaintPart(button.icon, "tint", look.icon)
end

local function SetLook(button, state)
    button.epithetLook = state
    PaintLook(button, button.epithetLooks[state])
end

function Theme.SkinButton(button, looks)
    for state, look in pairs(looks) do
        for part, value in pairs(look) do
            if not LOOK_PARTS[part] then
                error("Epithet Theme: button look '" .. tostring(state) .. "' has unknown part '" .. tostring(part) .. "'", 2)
            elseif not Theme.col[value[1]] then
                error("Epithet Theme: button look '" .. tostring(state) .. "." .. part .. "' references unknown token '" .. tostring(value[1]) .. "'", 2)
            end
        end
    end

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    button.bg = bg

    local borders = {}
    for i, edge in ipairs(BUTTON_EDGES) do
        local tex = button:CreateTexture(nil, "BORDER")
        tex[edge[3]](tex, 1)
        tex:SetPoint(edge[1])
        tex:SetPoint(edge[2])
        borders[i] = tex
    end
    button.borders = borders

    button.epithetLooks = looks
    button.SetLook = SetLook
    SetLook(button, "idle")

    button:HookScript("OnEnter", function(self_)
        if self_.epithetLook == "idle" then PaintLook(self_, self_.epithetLooks.hover) end
    end)
    button:HookScript("OnLeave", function(self_)
        if self_.epithetLook == "idle" then PaintLook(self_, self_.epithetLooks.idle) end
    end)
    return button
end

-- ---------------------------------------------------------------------------
-- Per-flavour overrides
-- ---------------------------------------------------------------------------

-- Accepts "rrggbb", { "rrggbb", a }, { r, g, b [, a] } or { r =, g =, b = [, a =] }.
local function ParseColour(value)
    local t = type(value)
    if t == "string" and value:match("^%x%x%x%x%x%x$") then
        return C(value)
    elseif t == "table" then
        if type(value[1]) == "string" then
            local c = value[1]:match("^%x%x%x%x%x%x$") and C(value[1], value[2])
            return c or nil
        elseif type(value[1]) == "number" then
            return RGB(value[1], value[2], value[3], value[4])
        elseif type(value.r) == "number" then
            return RGB(value.r, value.g, value.b, value.a)
        end
    end
    return nil
end

local function Assign(token, value, label)
    local parsed = ParseColour(value)
    if not parsed then
        print("|cffd98a52Epithet theme:|r invalid colour for " .. label)
        return false
    end
    token.r, token.g, token.b, token.a, token.hex = parsed.r, parsed.g, parsed.b, parsed.a, parsed.hex
    return true
end

local sealed = false

-- Override tokens: { col = { name = colour, ... }, quality = { [tier] = { pip =, text = } },
-- tex = { name = "Interface\\...path", ... } } (textures: see Theme.tex).
-- Tokens are updated in place; unknown names and invalid values are reported
-- and skipped, never created. Overriding a palette token restyles the roles
-- that follow it (Ref); overriding a following role detaches it, so it keeps
-- its new colour whatever its old source later becomes.
function Theme.Apply(overrides)
    if type(overrides) ~= "table" then return end
    if sealed then
        print("|cffd98a52Epithet theme:|r overrides applied after the UI was built; frames already painted keep their colours.")
    end
    for name, value in pairs(overrides.col or {}) do
        local token = Theme.col[name]
        if token then
            if Assign(token, value, "col." .. tostring(name)) then
                refs[name] = nil
            end
        else
            print("|cffd98a52Epithet theme:|r unknown colour token col." .. tostring(name))
        end
    end
    for tier, parts in pairs(overrides.quality or {}) do
        local q = Theme.quality[tier]
        if q and type(parts) == "table" then
            for part, value in pairs(parts) do
                if q[part] and part ~= "label" then
                    Assign(q[part], value, "quality[" .. tostring(tier) .. "]." .. tostring(part))
                else
                    print("|cffd98a52Epithet theme:|r unknown quality token quality[" .. tostring(tier) .. "]." .. tostring(part))
                end
            end
        else
            print("|cffd98a52Epithet theme:|r unknown quality tier " .. tostring(tier))
        end
    end
    if overrides.tex then
        Theme.ApplyTextures(overrides.tex)
    end
    ResolveRefs()
end

-- Called once the addon has initialised; later Apply calls warn.
function Theme.Seal()
    sealed = true
end

-- ---------------------------------------------------------------------------
-- Textures: Theme.tex
-- ---------------------------------------------------------------------------
-- Every texture file Epithet ships (icons/, logo/) has one named entry here,
-- and code uses the name, never the path. That keeps duplicates out (the
-- category icons used to be listed in Detail.lua and MainFrame.lua, the status
-- icons in TitleList.lua and Detail.lua) and lets a flavour swap one:
--
--     ns.Theme.Apply({ tex = { catPvp = "Interface\\AddOns\\Epithet\\icons\\..." } })
--
-- A texture path is a string, so unlike a colour it cannot be updated in
-- place: code that copies one into a local (local LOCK = T.tex.lock) keeps the
-- value it read. Flavour overrides therefore rely on the same load order as
-- colour overrides: Flavors/<Flavour>/Theme.lua runs straight after this file,
-- before any file that reads Theme.tex.
--
-- Fonts are not here (see the font helpers below). Blizzard textures (WHITE8X8,
-- Interface\Icons\...) are not themed either: they are part of the client, and
-- whether a client has them is a question for the probe (tools/probe), not for
-- the theme. The TOC's ## IconTexture cannot read Lua and names its file itself.
local ICONS = "Interface\\AddOns\\Epithet\\icons\\"
Theme.tex = {
    -- ---- brand (the same on every flavour) --------------------------------
    logoSeal        = ICONS .. "logo\\epithet-wax-seal-red-mark-32",    -- title bar, What's New
    -- Minimap button: the seal alone, full size, no baked-in disc or ring;
    -- LibDBIcon and button bags (EllesmereUI) draw the frame around it.
    logoSealMinimap = ICONS .. "logo\\epithet-wax-seal-red-minimap-64",
    logoCrown       = ICONS .. "logo\\epithet-crown-mark-32",           -- title card on a target
    badgeForever    = ICONS .. "logo\\epithet-badge-forever",           -- WoW Forever title bar (Theme.TitleBadge)
    logoBannerMark  = ICONS .. "logo\\epithet-banner-mark-64",          -- "current title" tick
    logoGrimmsforge = "Interface\\AddOns\\Epithet\\logo\\grimmsforge-logo", -- About

    -- ---- interface glyphs --------------------------------------------------
    close         = ICONS .. "ui\\epithet-ui-close-16",
    reset         = ICONS .. "ui\\epithet-ui-reset-16",
    sort          = ICONS .. "ui\\epithet-ui-sort-16",
    check         = ICONS .. "ui\\epithet-ui-check-32",
    lock          = ICONS .. "ui\\epithet-ui-lock-32",
    star          = ICONS .. "ui\\star",
    toggleOn      = ICONS .. "ui\\epithet-ui-toggle-on-32",
    toggleOff     = ICONS .. "ui\\epithet-ui-toggle-off-32",
    unobtainable  = ICONS .. "ui\\epithet-ui-unobtainable-sealed-16",
    timeSensitive = ICONS .. "ui\\epithet-ui-unobtainable-hourglass-16",
    alliance      = ICONS .. "ui\\alliance-logo-white",
    horde         = ICONS .. "ui\\horde-logo-white",

    -- ---- the compass ring around your portrait in the main window header ----
    -- (Theme.HeaderPortraitRing); WoW Forever swaps in its verdigris version.
    headerPortraitRing = ICONS .. "ui\\epithet-portrait-ring-compass",

    -- ---- social layer art --------------------------------------------------
    portraitRing   = ICONS .. "ui\\epithet-portrait-ring",
    bannerTail     = ICONS .. "ui\\epithet-banner-tail",
    bannerTailTrim = ICONS .. "ui\\epithet-banner-tail-trim",

    -- ---- source categories (32px; "Small" = 16px, for the bottom legend) --
    catAchievement      = ICONS .. "category\\epithet-cat-achievement-32",
    catAchievementSmall = ICONS .. "category\\epithet-cat-achievement-16",
    catCampaign         = ICONS .. "category\\epithet-cat-campaign-32",
    catDungeon          = ICONS .. "category\\epithet-cat-dungeon-32",
    catExploration      = ICONS .. "category\\epithet-cat-exploration-32",
    catExplorationSmall = ICONS .. "category\\epithet-cat-exploration-16",
    catFeat             = ICONS .. "category\\epithet-cat-feat-32",
    catFeatSmall        = ICONS .. "category\\epithet-cat-feat-16",
    catHoliday          = ICONS .. "category\\epithet-cat-holiday-32",
    catOutdoor          = ICONS .. "category\\epithet-cat-outdoor-32",
    catProfession       = ICONS .. "category\\epithet-cat-profession-32",
    catPvp              = ICONS .. "category\\epithet-cat-pvp-32",
    catPvpSmall         = ICONS .. "category\\epithet-cat-pvp-16",
    catQuest            = ICONS .. "category\\epithet-cat-quest-32",
    catQuestSmall       = ICONS .. "category\\epithet-cat-quest-16",
    catRaid             = ICONS .. "category\\epithet-cat-raid-32",
    catRaidSmall        = ICONS .. "category\\epithet-cat-raid-16",
    catReputation       = ICONS .. "category\\epithet-cat-reputation-32",
    catReputationSmall  = ICONS .. "category\\epithet-cat-reputation-16",

    -- ---- rarity gems, by quality tier (also as Theme.RarityGems32 / 64) ----
    rarity1 = ICONS .. "rarity\\epithet-rarity-1-common-32",
    rarity2 = ICONS .. "rarity\\epithet-rarity-2-uncommon-32",
    rarity3 = ICONS .. "rarity\\epithet-rarity-3-rare-32",
    rarity4 = ICONS .. "rarity\\epithet-rarity-4-epic-32",
    rarity5 = ICONS .. "rarity\\epithet-rarity-5-legendary-32",
    rarity1Large = ICONS .. "rarity\\epithet-rarity-1-common-64",
    rarity2Large = ICONS .. "rarity\\epithet-rarity-2-uncommon-64",
    rarity3Large = ICONS .. "rarity\\epithet-rarity-3-rare-64",
    rarity4Large = ICONS .. "rarity\\epithet-rarity-4-epic-64",
    rarity5Large = ICONS .. "rarity\\epithet-rarity-5-legendary-64",
}

-- Rarity gem paths indexed by quality tier 1..5 (Common -> Legendary), so
-- callers can index by q directly. Rebuilt in place after every Theme.Apply,
-- so code holding these tables sees texture overrides.
Theme.RarityGems32 = {}
Theme.RarityGems64 = {}
local function RebuildRarityGems()
    for q = 1, 5 do
        Theme.RarityGems32[q] = Theme.tex["rarity" .. q]
        Theme.RarityGems64[q] = Theme.tex["rarity" .. q .. "Large"]
    end
end
RebuildRarityGems()

-- An inline |T...|t texture escape for rich text (FontString:SetText).
function Theme.InlineTex(name, size)
    local path = Theme.tex[name]
    if not path then
        error("Epithet Theme: unknown texture '" .. tostring(name) .. "'", 2)
    end
    size = size or 12
    return "|T" .. path .. ":" .. size .. ":" .. size .. "|t"
end

-- Texture overrides for Theme.Apply: { name = "Interface\\...path" }.
function Theme.ApplyTextures(overrides)
    for name, path in pairs(overrides or {}) do
        if Theme.tex[name] == nil then
            print("|cffd98a52Epithet theme:|r unknown texture tex." .. tostring(name))
        elseif type(path) ~= "string" or path == "" then
            print("|cffd98a52Epithet theme:|r invalid path for tex." .. tostring(name))
        else
            Theme.tex[name] = path
        end
    end
    RebuildRarityGems()
end

-- |cffRRGGBB....|r colour wrap for FontString rich text. Takes a token or a
-- bare "rrggbb" hex string.
function Theme.Wrap(colour, s)
    local hex = type(colour) == "table" and colour.hex or colour
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
        obj:SetTextColor(Theme.RGBA(Theme.col.dropdownText))
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
