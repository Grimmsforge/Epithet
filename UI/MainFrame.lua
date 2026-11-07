-- =============================================================================
-- Epithet — Main Frame Controller
-- Window lifecycle, header band, bottom bar, position persistence.
-- =============================================================================
local _, ns = ...
local L = ns.L
local T = ns.Theme

-- Localize WoW APIs & Lua stdlib
local UnitName = UnitName
local GetNormalizedRealmName = GetNormalizedRealmName
local SetPortraitTexture     = SetPortraitTexture
local CreateFrame = CreateFrame
local format  = string.format
local floor   = math.floor
local tinsert = tinsert
local strlower = strlower

local function NormalizeTitleText(value)
    if not value then return "" end
    return strlower((tostring(value):gsub("^%s+", ""):gsub("%s+$", "")))
end

local function CanonicalTitleText(value)
    local text = NormalizeTitleText(value)
    text = text:gsub("[^%w%s]", "")
    text = text:gsub("%s+", " ")
    return text
end

-- Below this, a canonical title (e.g. "om" from "Om'") is short enough that it
-- can appear as a substring of unrelated text purely by chance (e.g. inside
-- "broom"), so loose substring-containment matching is skipped for it. Exact
-- and canonical-equality matches above are unaffected.
local FUZZY_SUBSTRING_MIN_LEN = 4

local MainFrame = {}
ns.MainFrame = MainFrame

local RARITY_GEMS = T and T.RarityGems32

local HEADER_SPOTTED_COL_WIDTH = 130
local HEADER_SPOTTED_COL_GAP = 10

local frame = nil  -- reference to EpithetMainFrame

-- ---------------------------------------------------------------------------
-- Initialise (called once, sets up the frame the first time it's needed)
-- ---------------------------------------------------------------------------

-- Backdrop definition for the custom dark frame
local EPITHET_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = nil,
    tile     = false,
    tileEdge = false,
    tileSize = 0,
    edgeSize = 0,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- ---------------------------------------------------------------------------
-- Window skin
-- ---------------------------------------------------------------------------
-- Every colour of the XML-defined window (UI/MainFrame.xml carries layout
-- only). { "path.from.EpithetMainFrame", kind, token, alpha } — see
-- Theme.ApplySkin. "fill" is a solid colour texture; "tint" colours a texture
-- file (the title-bar buttons use WHITE8X8 tinted).
local MAIN_FRAME_SKIN = {
    { "BorderTop",    "fill", "goldDeep", 0.85 },
    { "BorderBottom", "fill", "goldDeep", 0.85 },
    { "BorderLeft",   "fill", "goldDeep", 0.85 },
    { "BorderRight",  "fill", "goldDeep", 0.85 },
    { "InnerTop",     "fill", "line", 0.18 },
    { "InnerBottom",  "fill", "line", 0.18 },
    { "InnerLeft",    "fill", "line", 0.18 },
    { "InnerRight",   "fill", "line", 0.18 },

    { "TitleBar.BG",    "fill", "surface", 0.92 },
    { "TitleBar.Title", "text", "gold" },
    { "TitleBar.Sep",   "fill", "line", 0.30 },
    { "TitleBar.CloseButton.Icon", "tint", "closeBtnIcon", 0.8 },

    { "Header.PortraitRing", "fill", "goldDeep", 0.8 },
    { "Header.PlayerName",   "text", "goldBright" },
    { "Header.PlayerRealm",  "text", "muted" },
    { "Header.EarnedLabel",  "text", "goldDim" },
    { "Header.EarnedCount",  "text", "goldBright" },
    { "Header.ProgressBar",              "bar",  "gold" },
    { "Header.ProgressBar.BG",           "fill", "progressTrack", 0.95 },
    { "Header.ProgressBar.Border",       "fill", "progressBorder", 0.45 },
    { "Header.ProgressBar.BorderBottom", "fill", "progressBorder", 0.45 },

    { "BottomBar.RarityLabel", "text", "gold" },
}

-- The window's own textures (UI/MainFrame.xml names Blizzard files only).
-- { "path.from.EpithetMainFrame", Theme.tex name }.
local MAIN_FRAME_TEXTURES = {
    { "TitleBar.Logo",             "logoSeal" },
    { "TitleBar.CloseButton.Icon", "close" },
}

-- Title-bar buttons: { token, alpha } per part and state. The close button
-- keeps its own warm border; its icon starts at closeBtnIcon (MAIN_FRAME_SKIN)
-- and returns to closeBtnIconIdle after a hover, as it always has.
local TITLE_BUTTON_LOOKS = {
    standard = {
        idle  = { bg = { "titleBtnBg", 0.95 }, border = { "titleBtnBorder", 0.82 },
                  icon = { "titleBtnIcon", 0.95 }, label = { "titleBtnLabel", 0.95 } },
        hover = { bg = { "titleBtnBgHover", 0.98 }, border = { "titleBtnBorderHover", 1.0 },
                  icon = { "titleBtnIconHover", 1.0 }, label = { "titleBtnLabelHover", 1.0 } },
    },
    close = {
        idle  = { bg = { "titleBtnBg", 0.95 }, border = { "closeBtnBorder", 0.95 },
                  icon = { "closeBtnIconIdle", 0.92 } },
        hover = { bg = { "closeBtnBgHover", 0.98 }, border = { "closeBtnBorderHover", 1.0 },
                  icon = { "closeBtnIconHover", 1.0 } },
    },
}
local TITLE_BUTTON_BORDERS = { "BorderTop", "BorderBottom", "BorderLeft", "BorderRight" }

local function PaintTitleButton(btn, look, skipIcon)
    T.Paint(btn.BG, "tint", T.col[look.bg[1]], look.bg[2])
    for _, key in ipairs(TITLE_BUTTON_BORDERS) do
        T.Paint(btn[key], "tint", T.col[look.border[1]], look.border[2])
    end
    if btn.Icon and look.icon and not skipIcon then
        T.Paint(btn.Icon, "tint", T.col[look.icon[1]], look.icon[2])
    end
    if btn.Label and look.label then
        T.Paint(btn.Label, "text", T.col[look.label[1]], look.label[2])
    end
end

local function SkinTitleButton(btn, looks, keepInitialIcon)
    if not btn then return end
    PaintTitleButton(btn, looks.idle, keepInitialIcon)
    btn:HookScript("OnEnter", function(self_) PaintTitleButton(self_, looks.hover) end)
    btn:HookScript("OnLeave", function(self_) PaintTitleButton(self_, looks.idle) end)
end

-- Skins for the XML row templates, applied once per pooled frame by TitleList.
MainFrame.TITLE_ROW_SKIN = {
    { "Highlight",       "fill", "gold", 0.06 },
    { "Selected",        "fill", "gold", 0.06 },
    { "SelBorderTop",    "fill", "goldDeep", 0.7 },
    { "SelBorderBottom", "fill", "goldDeep", 0.7 },
    { "SelBorderLeft",   "fill", "goldDeep", 0.7 },
    { "SelBorderRight",  "fill", "goldDeep", 0.7 },
    { "ActiveBar",       "fill", "gold", 1.0 },
    { "TypeTag",         "text", "muted" },
    { "ActiveChip",      "text", "ink" },
    { "SourceText",      "text", "muted" },
}
MainFrame.GROUP_HEADER_SKIN = {
    { "Label", "text", "goldDeep" },
    { "Count", "text", "muted" },
    { "Line",  "fill", "line", 0.22 },
}

function MainFrame:Init()
    if frame then return end
    frame = EpithetMainFrame
    if not frame then return end

    -- Epithet's own textures (Theme.tex), then colours: exactly what the XML
    -- used to set, so everything below layers on top as before.
    for _, entry in ipairs(MAIN_FRAME_TEXTURES) do
        local region = frame
        for key in entry[1]:gmatch("[^%.]+") do region = region and region[key] end
        if region then region:SetTexture(T.tex[entry[2]]) end
    end
    T.ApplySkin(frame, MAIN_FRAME_SKIN)
    if frame.TitleBar then
        SkinTitleButton(frame.TitleBar.SettingsButton, TITLE_BUTTON_LOOKS.standard)
        SkinTitleButton(frame.TitleBar.InfoButton, TITLE_BUTTON_LOOKS.standard)
        SkinTitleButton(frame.TitleBar.CloseButton, TITLE_BUTTON_LOOKS.close, true)
    end

    -- Apply custom dark background via BackdropTemplate
    if frame.SetBackdrop then
        frame:SetBackdrop(EPITHET_BACKDROP)
    end
    frame:SetBackdropColor(T.RGBA(T.col.bg0, 0.97))

    -- Set custom title bar text
    if frame.TitleBar and frame.TitleBar.Title then
        frame.TitleBar.Title:SetText(T.Wrap(T.col.brandGold, L["BANNER_LEFT"]) .. " " .. T.Wrap(T.col.brandSubtitle, L["BANNER_RIGHT"]))
    end

    -- The flavour's badge beside the seal (Theme.TitleBadge), when it has one.
    local badge = T.TitleBadge
    if badge and frame.TitleBar and frame.TitleBar.Logo and not frame.TitleBar.Badge then
        local tex = frame.TitleBar:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(badge.texture)
        tex:SetSize(badge.width, badge.height)
        tex:SetPoint("LEFT", frame.TitleBar.Logo, "RIGHT", badge.x or 6, badge.y or 0)
        frame.TitleBar.Badge = tex
    end

    -- Wire info button click
    if frame.TitleBar and frame.TitleBar.InfoButton then
        local infoBtn = frame.TitleBar.InfoButton
        infoBtn:SetScript("OnClick", function() MainFrame:ShowAbout() end)
        infoBtn:HookScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["INFO_BUTTON_TOOLTIP"])
            GameTooltip:Show()
        end)
        infoBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Wire settings button: opens the Blizzard options UI on Epithet's panel
    if frame.TitleBar and frame.TitleBar.SettingsButton then
        local settingsBtn = frame.TitleBar.SettingsButton
        settingsBtn:SetScript("OnClick", function()
            if ns.Settings and ns.Settings.OpenMainSettings then
                ns.Settings:OpenMainSettings()
            end
        end)
        settingsBtn:HookScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(L["SETTINGS_BUTTON_TOOLTIP"])
            GameTooltip:Show()
        end)
        settingsBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Add to special frames for ESC-close
    tinsert(UISpecialFrames, "EpithetMainFrame")

    -- Expose SavePosition on the frame widget for XML script access
    frame.SavePosition = function() MainFrame:SavePosition() end

    -- Restore position
    self:RestorePosition()

    -- Set up header
    self:InitHeader()

    -- Set up bottom bar
    self:InitBottomBar()

    -- Reskin inset panels to match custom dark chrome
    self:SkinInsetPanel(frame.Sidebar)
    self:SkinInsetPanel(frame.ListContainer)
    self:SkinInsetPanel(frame.Detail)

    -- Set up sub-panels
    ns.Sidebar:Init(frame.Sidebar)
    ns.TitleList:Init(frame.ListContainer)
    ns.Detail:Init(frame.Detail)

    if ns.LogbookUI and ns.LogbookUI.Init then
        ns.LogbookUI:Init(frame)
    end

    -- If the main frame is closed (ESC, titlebar close, toggle, etc.), force the
    -- spotting log panel closed so reopening starts on the normal layout.
    frame:HookScript("OnHide", function()
        if ns.LogbookUI and ns.LogbookUI.Hide then
            ns.LogbookUI:Hide()
        end
    end)

    -- Locales the client font can't render (Russian on a Western client) need the
    -- bundled face on EVERY FontString, not just the ones built via Theme.Sans /
    -- Theme.Serif. Sweep the whole tree once the sub-panels exist, then again on
    -- each show so anything built lazily afterwards is caught too. No-op on
    -- locales the client fonts already cover.
    if T and T.ApplyLocaleFontToTree then
        T.ApplyLocaleFontToTree(frame)
        frame:HookScript("OnShow", function(self_)
            T.ApplyLocaleFontToTree(self_)
        end)
    end
end

-- ---------------------------------------------------------------------------
-- Toggle / Show / Hide
-- ---------------------------------------------------------------------------
function MainFrame:Toggle()
    self:Init()
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        self:Show()
    end
end

function MainFrame:Show()
    self:Init()
    if not frame then return end

    -- Clear stale hover state from previous sessions so detail reflects selection.
    self.hoveredRecord = nil

    -- Scan fresh data
    ns.TitleData:Scan()

    -- Show the frame first so refresh guards pass
    frame:Show()

    -- Update displays
    self:RefreshHeader()
    ns.Sidebar:Refresh()
    self:RefreshList()

    -- Select the equipped title or first row
    self:SelectDefault()

    if ns.LogbookUI and ns.LogbookUI.RefreshButton then
        ns.LogbookUI:RefreshButton()
    end
end

function MainFrame:IsShown()
    return frame and frame:IsShown()
end

-- ---------------------------------------------------------------------------
-- Full refresh (called on data change while window is open)
-- ---------------------------------------------------------------------------
function MainFrame:FullRefresh()
    if not frame or not frame:IsShown() then return end
    self:RefreshHeader()
    ns.Sidebar:Refresh()
    self:RefreshList()
end

-- ---------------------------------------------------------------------------
-- Refresh just the list (called on filter/sort change)
-- ---------------------------------------------------------------------------
function MainFrame:RefreshList()
    if not frame or not frame:IsShown() then return end
    ns.TitleList:Refresh()
end

-- ---------------------------------------------------------------------------
-- Header band
-- ---------------------------------------------------------------------------
function MainFrame:InitHeader()
    local header = frame.Header
    if not header then return end

    -- Portrait ring, from the theme (Theme.HeaderPortraitRing): the compass
    -- ring, drawn over the portrait's edge.
    local ring = header.PortraitRing
    if ring then
        local spec = T.HeaderPortraitRing
        ring:SetTexture(T.tex[spec.tex])
        ring:SetSize(spec.size, spec.size)
        if spec.tint then
            ring:SetVertexColor(T.RGBA(T.col[spec.tint], spec.tintAlpha))
        else
            ring:SetVertexColor(1, 1, 1, 1)
        end
        ring:SetDrawLayer(spec.overPortrait and "ARTWORK" or "BACKGROUND", spec.overPortrait and 2 or 0)
    end

    -- Portrait: set to player model portrait
    if header.Portrait then
        SetPortraitTexture(header.Portrait, "player")
    end

    header.PlayerName:SetText("")
    header.PlayerRealm:SetText("")
    header.EarnedLabel:SetText(L["TITLES_EARNED"])
    header.EarnedCount:SetText("")
    header.ProgressBar:SetMinMaxValues(0, 100)
    header.ProgressBar:SetValue(0)

    -- Obtainable-only toggle (icon to the right of earned label)
    local TOGGLE_OFF = T.tex.toggleOff
    local TOGGLE_ON  = T.tex.toggleOn

    local rightReserve = HEADER_SPOTTED_COL_WIDTH + HEADER_SPOTTED_COL_GAP

    -- Shift earned label left to make room for toggle + spotted button column.
    header.EarnedLabel:ClearAllPoints()
    header.EarnedLabel:SetPoint("TOPRIGHT", header, "TOPRIGHT", -(30 + rightReserve), -8)

    -- Ensure count row shares the same right edge as the shifted earned region.
    header.EarnedCount:ClearAllPoints()
    header.EarnedCount:SetPoint("TOPRIGHT", header, "TOPRIGHT", -(8 + rightReserve), -22)

    -- Progress bar keeps its left edge but gives the spotted-button column space.
    if header.ProgressBar and header.PlayerRealm then
        header.ProgressBar:ClearAllPoints()
        header.ProgressBar:SetPoint("TOPLEFT", header.PlayerRealm, "BOTTOMLEFT", 0, -8)
        header.ProgressBar:SetPoint("RIGHT", header, "RIGHT", -(8 + rightReserve), 0)
    end

    local toggle = CreateFrame("Button", nil, header)
    toggle:SetSize(18, 18)
    toggle:SetPoint("LEFT", header.EarnedLabel, "RIGHT", 4, 0)

    local icon = toggle:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(TOGGLE_OFF)
    icon:SetVertexColor(T.RGBA(T.col.goldDim))
    toggle.icon = icon
    toggle.TOGGLE_ON = TOGGLE_ON
    toggle.TOGGLE_OFF = TOGGLE_OFF

    toggle:SetScript("OnClick", function()
        local db = ns.Epithet.db.profile
        db.obtainableOnly = not db.obtainableOnly
        MainFrame:RefreshHeader()
    end)
    toggle:SetScript("OnEnter", function(self_)
        GameTooltip:SetOwner(self_, "ANCHOR_BOTTOMLEFT")
        local mode = ns.Epithet.db.profile.obtainableOnly
        GameTooltip:SetText(mode and L["TOGGLE_ALL_TITLES"] or L["TOGGLE_OBTAINABLE_ONLY"], 1, 1, 1)
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    header.ObtainToggle = toggle
end

function MainFrame:RefreshHeader()
    local header = frame.Header
    if not header then return end

    local name = ns.TitleData.playerName or UnitName("player") or "Player"
    local realm = ns.TitleData.playerRealm or GetNormalizedRealmName() or ""

    -- Build display name with current title applied
    local currentTitleID = ns.TitleData.currentTitleID or 0
    if currentTitleID > 0 and ns.TitleData.records then
        local activeRecord = ns.TitleData:GetRecord(currentTitleID)
        if activeRecord and activeRecord.text then
            if activeRecord.type == "suffix" then
                name = name .. ", " .. activeRecord.text
            else
                name = activeRecord.text .. " " .. name
            end
        end
    end

    local obtOnly = ns.Epithet.db.profile.obtainableOnly
    local earned, total
    if obtOnly then
        earned = ns.TitleData.earnedObtainableCount or 0
        total  = ns.TitleData.totalObtainableCount or 0
    else
        earned = ns.TitleData.earnedCount or 0
        total  = ns.TitleData.totalCount or 0
    end
    local pct = total > 0 and floor((earned / total) * 100) or 0

    -- Refresh portrait in case of character change
    if header.Portrait then
        SetPortraitTexture(header.Portrait, "player")
    end

    header.PlayerName:SetText(name)
    -- A blank line rather than a hidden one: the progress bar hangs off it, so
    -- the header keeps the same layout on every flavour.
    local showRealm = not ns.Flavor or ns.Flavor.showRealm ~= false
    header.PlayerRealm:SetText(showRealm and realm or " ")

    -- Update label to reflect mode
    header.EarnedLabel:SetText(obtOnly and L["TITLES_EARNED_OBTAINABLE"] or L["TITLES_EARNED"])

    if T then
        local col = T.col
        header.PlayerName:SetTextColor(col.goldBright.r, col.goldBright.g, col.goldBright.b)
        header.PlayerRealm:SetTextColor(col.muted.r, col.muted.g, col.muted.b)
        header.EarnedCount:SetText(
            T.Wrap(col.goldBright.hex, earned) .. "  / " .. total .. "   " .. T.Wrap(col.goldDim.hex, pct .. "%")
        )
    else
        header.EarnedCount:SetText(format("|cff%s%d|r / %d    |cff%s%d%%|r", T.col.gold.hex, earned, total, T.col.goldDim.hex, pct))
    end

    header.ProgressBar:SetMinMaxValues(0, total)
    header.ProgressBar:SetValue(earned)

    -- Update toggle icon
    if header.ObtainToggle then
        if obtOnly then
            header.ObtainToggle.icon:SetTexture(header.ObtainToggle.TOGGLE_ON)
        else
            header.ObtainToggle.icon:SetTexture(header.ObtainToggle.TOGGLE_OFF)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Bottom bar (rarity legend + version)
-- ---------------------------------------------------------------------------
function MainFrame:InitBottomBar()
    local bar = frame.BottomBar
    if not bar then return end

    -- Bottom-bar layout: left legend can wrap to two rows, right metadata stays
    -- vertically centred with a separator to preserve visual hierarchy.
    if not bar.RightMetaBlock then
        bar.RightMetaBlock = CreateFrame("Frame", nil, bar)
        bar.RightMetaBlock:SetSize(300, 30)
        bar.RightMetaBlock:SetPoint("RIGHT", bar, "RIGHT", -12, 0)
    end

    if not bar.MetaSeparator then
        bar.MetaSeparator = bar:CreateTexture(nil, "ARTWORK")
    end
    bar.MetaSeparator:SetColorTexture(T.RGBA(T.col.line, 0.30))
    bar.MetaSeparator:SetWidth(1)
    bar.MetaSeparator:SetPoint("TOP", bar.RightMetaBlock, "TOPLEFT", -12, 0)
    bar.MetaSeparator:SetPoint("BOTTOM", bar.RightMetaBlock, "BOTTOMLEFT", -12, 0)

    if not bar.LeftLegendBlock then
        bar.LeftLegendBlock = CreateFrame("Frame", nil, bar)
        bar.LeftLegendBlock:SetHeight(38)
    end
    bar.LeftLegendBlock:ClearAllPoints()
    bar.LeftLegendBlock:SetPoint("LEFT", bar, "LEFT", 12, 0)
    bar.LeftLegendBlock:SetPoint("RIGHT", bar.MetaSeparator, "LEFT", -12, 0)
    bar.LeftLegendBlock:SetPoint("CENTER", bar, "CENTER", 0, 0)

    bar.RarityLabel:SetText(L["RARITY"])
    bar.RarityLabel:ClearAllPoints()
    bar.RarityLabel:SetPoint("LEFT", bar.LeftLegendBlock, "LEFT", 0, 0)
    if T then
        bar.RarityLabel:SetTextColor(T.col.gold.r, T.col.gold.g, T.col.gold.b)
    end

    -- Create rarity legend pips + labels (round dots, labels on OVERLAY so a
    -- pip never draws over a label; vertically centred to the bar).
    local prevAnchor = bar.RarityLabel
    local qualityData = T and T.quality or nil

    for i = 1, 5 do
        local q = qualityData and qualityData[i]
        local pipCol = q and q.pip or ns.QUALITY_COLOURS[i].pip
        local txtCol = q and q.text or ns.QUALITY_COLOURS[i].text
        local name   = ns.QUALITY_NAMES[i]   -- localised (theme label is colour-only now)

        -- Gem (rarity icon, tinted)
        local pip = bar:CreateTexture(nil, "ARTWORK")
        pip:SetTexture(RARITY_GEMS[i])
        pip:SetVertexColor(pipCol.r, pipCol.g, pipCol.b, 1.0)
        pip:SetSize(9, 9)
        pip:ClearAllPoints()
        pip:SetPoint("LEFT", prevAnchor, "RIGHT", i == 1 and 12 or 11, 0)

        -- Label
        local label = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        label:SetText(name)
        label:SetTextColor(txtCol.r, txtCol.g, txtCol.b)
        label:ClearAllPoints()
        label:SetPoint("LEFT", pip, "RIGHT", 7, 0)

        prevAnchor = label
    end

    -- Version info (two rows)
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local addonVersion = (getMeta and getMeta("Epithet", "Version")) or "1.0.0"
    local dbVersion = ns.EpithetData and ns.EpithetData.version or "?"
    local rawDate = ns.EpithetData and ns.EpithetData.date or nil
    local dbDate
    if rawDate and rawDate:match("^%d%d%d%d%-%d%d%-%d%d$") then
        local y, m, d = rawDate:match("^(%d+)-(%d+)-(%d+)$")
        dbDate = format("%s/%s/%s", d, m, y)
    else
        dbDate = rawDate or L["VERSION_DATE_UNKNOWN"]
    end
    local gameInterface = select(4, GetBuildInfo()) or "?"
    -- Format as X.X.X from the integer (e.g. 120001 -> 12.0.1)
    if type(gameInterface) == "number" then
        local major = floor(gameInterface / 10000)
        local minor = floor((gameInterface % 10000) / 100)
        local patch = gameInterface % 100
        gameInterface = format("%d.%d.%d", major, minor, patch)
    end

    -- These lines carry a middle-dot (U+00B7) separator via VERSION_LINE*_FMT.
    -- The XML FontStrings inherit a Blizzard game font, whose locale build may
    -- lack that glyph (renders as a box). On locales that need the bundled font,
    -- swap in the bundled font object (no-op / nil on Latin locales, so English
    -- keeps its Blizzard font unchanged).
    local versionFont = T and T.LocaleFontObject and T.LocaleFontObject(10)
    if versionFont then
        bar.Version:SetFontObject(versionFont)
        bar.Version2:SetFontObject(versionFont)
    end

    -- Row 1: Epithet version (left) | Interface version (right)
    bar.Version:SetText(string.format(L["VERSION_LINE1_FMT"], addonVersion, gameInterface))
    -- Row 2: TitlesDB version (left) | TitlesDB date (right)
    bar.Version2:SetText(string.format(L["VERSION_LINE2_FMT"], dbVersion, dbDate))
    if T then
        bar.Version:SetTextColor(T.col.faint.r, T.col.faint.g, T.col.faint.b)
        bar.Version2:SetTextColor(T.col.faint.r, T.col.faint.g, T.col.faint.b)
    end

    bar.Version:ClearAllPoints()
    bar.Version:SetPoint("TOPRIGHT", bar.RightMetaBlock, "RIGHT", 0, -1)
    bar.Version2:ClearAllPoints()
    bar.Version2:SetPoint("BOTTOMRIGHT", bar.RightMetaBlock, "RIGHT", 0, 1)

    -- Source kind icon legend (right of rarity pips)
    local SOURCE_LEGEND = {
        { icon = T.tex.catAchievementSmall, label = L["LEGEND_ACHIEVEMENT"] },
        { icon = T.tex.catQuestSmall, label = L["LEGEND_QUEST"] },
        { icon = T.tex.catReputationSmall, label = L["LEGEND_REPUTATION"] },
        { icon = T.tex.catPvpSmall, label = L["LEGEND_PVP"] },
        { icon = T.tex.catFeatSmall, label = L["LEGEND_FEAT"] },
        { icon = T.tex.catExplorationSmall, label = L["LEGEND_EXPLORATION"] },
        { icon = T.tex.catRaidSmall, label = L["LEGEND_RAID"] },
    }

    local sourceLabel = bar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sourceLabel:SetText(L["SOURCE_LEGEND"] or "SOURCE")
    sourceLabel:ClearAllPoints()
    sourceLabel:SetPoint("LEFT", bar.LeftLegendBlock, "LEFT", 0, 0)
    if T then
        sourceLabel:SetTextColor(T.col.gold.r, T.col.gold.g, T.col.gold.b)
    end

    local srcPrev = sourceLabel
    local goldCol = T.col.gold
    local parchCol = T.col.panel

    -- Shared hover popup (circular-ish with gold border, parchment bg, large icon)
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(48, 48)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    popup:SetBackdropColor(parchCol.r, parchCol.g, parchCol.b, 0.95)
    popup:SetBackdropBorderColor(goldCol.r, goldCol.g, goldCol.b, 1.0)
    popup:Hide()

    -- Circular mask overlay (rounded corners via texture)
    local popupIcon = popup:CreateTexture(nil, "ARTWORK")
    popupIcon:SetSize(32, 32)
    popupIcon:SetPoint("CENTER")
    popup.icon = popupIcon

    -- Label pill above the popup (background + border frame)
    local pill = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    pill:SetFrameStrata("TOOLTIP")
    pill:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    pill:SetBackdropColor(parchCol.r, parchCol.g, parchCol.b, 0.95)
    pill:SetBackdropBorderColor(goldCol.r, goldCol.g, goldCol.b, 0.7)
    pill:SetPoint("BOTTOM", popup, "TOP", 0, 6)

    local popupLabel = pill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popupLabel:SetPoint("CENTER", pill, "CENTER", 0, 0)
    popupLabel:SetTextColor(goldCol.r, goldCol.g, goldCol.b)
    popup.label = popupLabel
    popup.pill = pill

    self.sourceIconPopup = popup

    for i, def in ipairs(SOURCE_LEGEND) do
        -- Wrap icon + label in an invisible button for mouse events
        local btn = CreateFrame("Button", nil, bar.LeftLegendBlock)
        btn:SetHeight(12)
        btn:SetPoint("LEFT", srcPrev, "RIGHT", i == 1 and 12 or 10, 0)

        local ico = btn:CreateTexture(nil, "ARTWORK")
        ico:SetSize(12, 12)
        ico:SetPoint("LEFT", 0, 0)
        ico:SetTexture(def.icon)
        ico:SetVertexColor(goldCol.r, goldCol.g, goldCol.b, 1.0)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lbl:SetText(def.label)
        if T then
            lbl:SetTextColor(T.col.muted.r, T.col.muted.g, T.col.muted.b)
        end
        lbl:SetPoint("LEFT", ico, "RIGHT", 4, 0)

        -- Size button to cover both icon and label
        btn:SetScript("OnShow", function(self_)
            local w = 12 + 4 + (lbl:GetStringWidth() or 30)
            self_:SetWidth(w)
        end)
        local initWidth = 12 + 4 + (lbl:GetStringWidth() or 30)
        btn:SetWidth(initWidth)

        -- The 32px version for the popup
        local icon32 = def.icon:gsub("%-16$", "-32")

        btn:SetScript("OnEnter", function(self_)
            popupIcon:SetTexture(icon32)
            popupIcon:SetVertexColor(goldCol.r, goldCol.g, goldCol.b, 1.0)
            popupLabel:SetText(def.label)
            -- Size the pill to fit the label text + padding
            local textWidth = popupLabel:GetStringWidth() or 40
            pill:SetSize(textWidth + 16, 18)
            popup:ClearAllPoints()
            popup:SetPoint("BOTTOM", self_, "TOP", 0, 24)
            popup:Show()
        end)
        btn:SetScript("OnLeave", function()
            popup:Hide()
        end)

        srcPrev = btn
    end

    local function LegendWidthFromAnchor(firstRegion, lastRegion)
        if not firstRegion or not lastRegion then return 0 end
        local left = firstRegion:GetLeft()
        local right = lastRegion:GetRight()
        if not left or not right then return 0 end
        return right - left
    end

    local function LayoutBottomBarLegend()
        local available = bar.LeftLegendBlock:GetWidth() or 0
        local rarityWidth = LegendWidthFromAnchor(bar.RarityLabel, prevAnchor)
        local sourceWidth = LegendWidthFromAnchor(sourceLabel, srcPrev)
        local gap = 24
        local fitsOneLine = (available > 0) and ((rarityWidth + gap + sourceWidth) <= available)

        if fitsOneLine then
            bar.RarityLabel:ClearAllPoints()
            bar.RarityLabel:SetPoint("LEFT", bar.LeftLegendBlock, "LEFT", 0, 0)
            sourceLabel:ClearAllPoints()
            sourceLabel:SetPoint("LEFT", prevAnchor, "RIGHT", gap, 0)
        else
            bar.RarityLabel:ClearAllPoints()
            bar.RarityLabel:SetPoint("LEFT", bar.LeftLegendBlock, "LEFT", 0, 8)
            sourceLabel:ClearAllPoints()
            sourceLabel:SetPoint("LEFT", bar.LeftLegendBlock, "LEFT", 0, -8)
        end

        local rightWidth = math.max(
            bar.Version:GetStringWidth() or 0,
            bar.Version2:GetStringWidth() or 0,
            200
        )
        bar.RightMetaBlock:SetWidth(rightWidth)
    end

    LayoutBottomBarLegend()
    if not bar._epithetBottomBarSizeHooked then
        bar:HookScript("OnSizeChanged", LayoutBottomBarLegend)
        bar._epithetBottomBarSizeHooked = true
    end
end

-- ---------------------------------------------------------------------------
-- Reskin an InsetFrameTemplate3 panel to custom dark parchment look
-- ---------------------------------------------------------------------------
function MainFrame:SkinInsetPanel(panel)
    if not panel then return end
    -- Suppress the default inset border/bg textures if present
    if panel.NineSlice then panel.NineSlice:Hide() end
    if panel.Bg then panel.Bg:Hide() end

    -- Custom background
    if not panel.EpithetBG then
        local bg = panel:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints()
        bg:SetColorTexture(T.RGBA(T.col.ink, 0.85))
        panel.EpithetBG = bg
    end

    -- Subtle hairline border (1px, faint gold)
    if not panel.EpithetBorder then
        local c = T.col.line
        local t = panel:CreateTexture(nil, "BORDER")
        t:SetPoint("TOPLEFT", -1, 1); t:SetPoint("TOPRIGHT", 1, 1); t:SetHeight(1)
        t:SetColorTexture(c.r, c.g, c.b, c.a or 0.22)
        local b = panel:CreateTexture(nil, "BORDER")
        b:SetPoint("BOTTOMLEFT", -1, -1); b:SetPoint("BOTTOMRIGHT", 1, -1); b:SetHeight(1)
        b:SetColorTexture(c.r, c.g, c.b, c.a or 0.22)
        local l = panel:CreateTexture(nil, "BORDER")
        l:SetPoint("TOPLEFT", -1, 0); l:SetPoint("BOTTOMLEFT", -1, 0); l:SetWidth(1)
        l:SetColorTexture(c.r, c.g, c.b, c.a or 0.22)
        local r = panel:CreateTexture(nil, "BORDER")
        r:SetPoint("TOPRIGHT", 1, 0); r:SetPoint("BOTTOMRIGHT", 1, 0); r:SetWidth(1)
        r:SetColorTexture(c.r, c.g, c.b, c.a or 0.22)
        panel.EpithetBorder = { t, b, l, r }
    end
end

-- ---------------------------------------------------------------------------
-- Position persistence
-- ---------------------------------------------------------------------------
function MainFrame:SavePosition()
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.Epithet.db.profile.framePoint = { point, relPoint, x, y }
end

function MainFrame:RestorePosition()
    if not frame then return end
    local saved = ns.Epithet.db.profile.framePoint
    if saved then
        frame:ClearAllPoints()
        frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    end

    local scale = ns.Epithet.db.profile.scale or 1.0
    frame:SetScale(scale)
end

-- ---------------------------------------------------------------------------
-- Default selection (equipped title or first row)
-- ---------------------------------------------------------------------------
function MainFrame:SelectDefault()
    local currentID = ns.TitleData.currentTitleID
    if currentID and currentID > 0 then
        local record = ns.TitleData:GetRecord(currentID)
        if record then
            ns.TitleList:SetSelection(record)
            return
        end
    end
    -- Fall back to first row
    ns.TitleList:SelectFirst()
end

function MainFrame:OpenAndSelectTitle(titleText, titleType, titleID)
    self:Show()

    -- Explicit external selection should always override hover-preview mode.
    self.hoveredRecord = nil

    if titleID and ns.TitleData and ns.TitleData.GetRecord then
        local byID = ns.TitleData:GetRecord(titleID)
        if byID then
            self:EnsureRecordVisibleInList(byID)
            ns.TitleList:SetSelection(byID)
            return
        end
    end

    if not titleText or titleText == "" then
        return
    end

    local target = NormalizeTitleText(titleText)
    local targetCanonical = CanonicalTitleText(titleText)
    local bestMatch = nil
    local bestScore = -1

    for _, record in ipairs(ns.TitleData.records or {}) do
        local textNorm = NormalizeTitleText(record.text)
        local textCanonical = CanonicalTitleText(record.text)
        local score = 0

        if textNorm == target then
            score = score + 4
        elseif targetCanonical ~= "" and textCanonical == targetCanonical then
            score = score + 3
        elseif targetCanonical ~= "" and
            #targetCanonical >= FUZZY_SUBSTRING_MIN_LEN and #textCanonical >= FUZZY_SUBSTRING_MIN_LEN and (
            textCanonical:find(targetCanonical, 1, true) or
            targetCanonical:find(textCanonical, 1, true)
        ) then
            score = score + 1
        end

        if score > 0 and titleType and record.type == titleType then
            score = score + 5
        end

        if score > bestScore then
            bestScore = score
            bestMatch = record
        end
    end

    if bestMatch then
        self:EnsureRecordVisibleInList(bestMatch)
        ns.TitleList:SetSelection(bestMatch)
    end
end

function MainFrame:EnsureRecordVisibleInList(record)
    if not record then return end
    if not ns.Epithet or not ns.Epithet.db or not ns.Epithet.db.profile then return end

    local filters = ns.Epithet.db.profile.filters
    if not filters then return end

    -- External title-open should always drive the sidebar search state.
    if ns.Filters and ns.Filters.Reset then
        ns.Filters:Reset(filters)
    end

    local searchText = record.text or ""
    filters.search = searchText

    if ns.Sidebar then
        if ns.Sidebar.searchBox then
            if ns.Sidebar.searchBox:GetText() ~= searchText then
                ns.Sidebar.searchBox:SetText(searchText)
            end
        end
        if ns.Sidebar.Refresh then
            ns.Sidebar:Refresh()
        end
    end

    self:RefreshList()
end

-- ---------------------------------------------------------------------------
-- Selection / hover state (shared between list and detail)
-- ---------------------------------------------------------------------------
MainFrame.selectedRecord = nil
MainFrame.hoveredRecord = nil

function MainFrame:SetSelection(record)
    self.selectedRecord = record
    self.hoveredRecord = nil
    ns.Detail:Refresh()
end

function MainFrame:SetHover(record)
    self.hoveredRecord = record
    ns.Detail:Refresh()
end

function MainFrame:ClearHover()
    self.hoveredRecord = nil
    ns.Detail:Refresh()
end

function MainFrame:GetDetailRecord()
    return self.hoveredRecord or self.selectedRecord
end

-- ---------------------------------------------------------------------------
-- About / Info modal
-- ---------------------------------------------------------------------------
function MainFrame:ShowAbout()
    if self.aboutFrame then
        self.aboutFrame:Show()
        return
    end

    local goldCol = T.col.gold
    local parchCol = T.col.panel
    local faintCol = T.col.faint

    -- Overlay backdrop (dims the main frame)
    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetAllPoints(frame)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    overlay:SetBackdropColor(T.RGBA(T.col.black, 0.6))
    overlay:EnableMouse(true)
    overlay:SetScript("OnMouseDown", function() MainFrame:HideAbout() end)

    -- Modal card
    local modal = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    modal:SetSize(340, 280)
    modal:SetPoint("CENTER", frame, "CENTER", 0, 0)
    modal:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    modal:SetBackdropColor(parchCol.r, parchCol.g, parchCol.b, 0.97)
    modal:SetBackdropBorderColor(goldCol.r, goldCol.g, goldCol.b, 0.85)
    modal:EnableMouse(true)

    -- Grimmsforge logo
    local logo = modal:CreateTexture(nil, "ARTWORK")
    logo:SetSize(64, 64)
    logo:SetPoint("TOP", modal, "TOP", 0, -24)
    logo:SetTexture(T.tex.logoGrimmsforge)

    -- Title
    local title = modal:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", logo, "BOTTOM", 0, -12)
    title:SetText(T.Wrap(T.col.brandGold, "Grimmsforge"))

    -- Description
    local desc = modal:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetPoint("LEFT", modal, "LEFT", 24, 0)
    desc:SetPoint("RIGHT", modal, "RIGHT", -24, 0)
    desc:SetJustifyH("CENTER")
    desc:SetSpacing(3)
    desc:SetTextColor(T.RGBA(T.col.bodyText))
    desc:SetText(
        L["ABOUT_CRAFTED"] .. "\n\n" ..
        L["ABOUT_TAGLINE"] .. "\n\n" ..
        T.Wrap(T.col.brandGold, "github.com/Grimmsforge")
    )

    -- Close button
    local closeBtn = CreateFrame("Button", nil, modal)
    closeBtn:SetSize(80, 28)
    closeBtn:SetPoint("BOTTOM", modal, "BOTTOM", 0, 18)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER")
    closeText:SetText(L["CLOSE"])
    closeBtn.text = closeText

    -- Shared bordered button with a softer, constant edge; its label turns
    -- textHover (not btnTextHover) on hover, as it always has.
    T.SkinButton(closeBtn, T.ButtonVariant(T.ButtonLooks.standard, {
        idle  = { border = { "btnBorderSoft" } },
        hover = { border = false, text = { "textHover" } },
    }))
    closeBtn:SetScript("OnClick", function() MainFrame:HideAbout() end)

    self.aboutFrame = overlay
end

function MainFrame:HideAbout()
    if self.aboutFrame then
        self.aboutFrame:Hide()
    end
end
