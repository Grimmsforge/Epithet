-- =============================================================================
-- Epithet — Detail Panel (right column)
-- Preview, rarity card (fixed height), source card (fills), action footer.
-- =============================================================================
local _, ns = ...
local L = ns.L
local T = ns.Theme

-- Localize WoW APIs & Lua stdlib
local UnitName  = UnitName
local format    = string.format
local tconcat   = table.concat
local wipe      = wipe
local strlower  = strlower

local Detail = {}
ns.Detail = Detail

local RARITY_GEMS = T and T.RarityGems32

local DOT  = "\194\183"        -- middle dot ·
local STAR = "\226\152\133"    -- star ★

local col  = T and T.col or {}
local GOLD     = col.gold    or { r = 0.91, g = 0.78, b = 0.45 }
local GOLD_DIM = col.goldDim or { r = 0.73, g = 0.57, b = 0.25 }
local MUTED    = col.muted   or { r = 0.61, g = 0.55, b = 0.42 }

local INSET = 16

-- Source-card scroll region. The gutter is the space reserved on the card's right
-- edge for the scrollbar, so text never runs underneath it even when the bar is
-- hidden (keeping the wrap width identical whether or not the content overflows).
local SCROLLBAR_GUTTER = 16
local SCROLLBAR_WIDTH  = 4
local SCROLL_STEP      = 28
local SCROLL_BOTTOM_PAD = 4
local SIGIL_SIZE       = 34
local SIGIL_GAP        = 10
local OBTAIN_INDENT    = 22
-- Space under the source card, sized to hold the overflow hint.
local HINT_GAP         = 16

-- Scratch tables (reused per Refresh to avoid allocation)
local scratchParts = {}

-- Sentinel so the very first Refresh() always runs even when nothing is
-- selected yet (record == nil); a fresh table never equals anything else.
local NEVER_REFRESHED = {}

-- Unobtainability icons (16px for detail panel banner)
local UNOBTAIN_SEALED_16    = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-ui-unobtainable-sealed-16"
local UNOBTAIN_HOURGLASS_16 = "Interface\\AddOns\\Epithet\\icons\\ui\\epithet-ui-unobtainable-hourglass-16"

-- Faction icons (64px for detail panel — sharper at display size)
local FACTION_ALLIANCE_64 = "Interface\\AddOns\\Epithet\\icons\\ui\\alliance-logo-white"
local FACTION_HORDE_64    = "Interface\\AddOns\\Epithet\\icons\\ui\\horde-logo-white"

-- Single-letter / glyph sigil per source kind (fallback if texture missing)
local SIGIL_LETTERS = {
    ["Achievement"]      = "A",
    ["Quest"]            = "Q",
    ["Reputation"]       = "R",
    ["PvP Rank"]         = "P",
    ["Feat of Strength"] = STAR,
    ["Item"]             = "I",
    ["Promotion"]        = "G",
}

-- Category icon textures keyed by source kind
local SIGIL_ICONS = {
    ["Achievement"]      = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-achievement-32",
    ["Quest"]            = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-quest-32",
    ["Reputation"]       = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-reputation-32",
    ["PvP Rank"]         = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-pvp-32",
    ["Feat of Strength"] = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-feat-32",
    ["Raid"]             = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-raid-32",
    ["Dungeon"]          = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-dungeon-32",
    ["Exploration"]      = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-exploration-32",
    ["Holiday"]          = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-holiday-32",
    ["Profession"]       = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-profession-32",
    ["Campaign"]         = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-campaign-32",
    ["Outdoor"]          = "Interface\\AddOns\\Epithet\\icons\\category\\epithet-cat-outdoor-32",
}

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function Detail:Init(panel)
    if self.panel then return end
    self.panel = panel

    -- Preview banner. Themed font: PREVIEW_HOVERING carries an em-dash (U+2014)
    -- separator that some locale game fonts lack.
    local banner = (T and T.Sans and T.Sans(panel, 12, GOLD_DIM))
        or panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    banner:SetPoint("TOPLEFT", INSET, -16)
    banner:SetTextColor(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b)
    self.previewBanner = banner

    -- Title (big)
    local title = panel:CreateFontString(nil, "ARTWORK", "QuestFont_Huge")
    title:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -6)
    title:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    self.titleText = title

    -- Sub-line (type · expansion · rarity). Use the themed font (T.Sans) rather
    -- than a Blizzard game font: the separator is a middle dot (U+00B7), which
    -- some locale game-font builds don't carry, so it renders as a box under a
    -- non-Latin locale. The bundled font used for those locales does carry it.
    local subLine = (T and T.Sans and T.Sans(panel, 12, MUTED))
        or panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    subLine:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subLine:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    subLine:SetJustifyH("LEFT")
    subLine:SetTextColor(MUTED.r, MUTED.g, MUTED.b)
    self.subLine = subLine

    -- Rarity card (fixed height)
    self:InitRarityCard()

    -- Action footer (bottom)
    self:InitActionFooter()

    -- Source card (fills between rarity card and footer)
    self:InitSourceCard()

    -- Empty state
    local empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("TOPLEFT", INSET, -120)
    empty:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    empty:SetJustifyH("CENTER")
    empty:SetText(L["NO_SELECTION"])
    empty:Hide()
    self.emptyState = empty
end

-- ---------------------------------------------------------------------------
-- Rarity card
-- ---------------------------------------------------------------------------
function Detail:InitRarityCard()
    local panel = self.panel
    local card = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
    card:SetPoint("TOPLEFT", self.subLine, "BOTTOMLEFT", 0, -12)
    card:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    card:SetHeight(76)
    self.rarityCard = card

    -- Gem (16x16 rarity gem icon before quality name)
    local gem = card:CreateTexture(nil, "ARTWORK")
    gem:SetSize(16, 16)
    gem:SetPoint("TOPLEFT", 12, -12)
    self.rarityGem = gem

    local label = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", gem, "RIGHT", 11, 0)
    self.qualityLabel = label

    -- Faction icon (24px, shown right of quality label for faction-specific titles)
    local factionIcon = card:CreateTexture(nil, "ARTWORK")
    factionIcon:SetSize(24, 24)
    factionIcon:SetPoint("LEFT", label, "RIGHT", 8, 0)
    factionIcon:Hide()
    self.factionIcon = factionIcon

    -- Tier segments (5 bars)
    self.tierSegments = {}
    local segW, segGap = 56, 6
    for i = 1, 5 do
        local seg = card:CreateTexture(nil, "ARTWORK")
        seg:SetSize(segW, 6)
        seg:SetPoint("TOPLEFT", gem, "BOTTOMLEFT", (i - 1) * (segW + segGap), -10)
        self.tierSegments[i] = seg
    end

    local pct = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pct:SetPoint("TOPLEFT", self.tierSegments[1], "BOTTOMLEFT", 0, -10)
    pct:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    pct:SetJustifyH("LEFT")
    self.rarityPct = pct

    -- Rarity info button (circular ? in top-right)
    self:InitRarityInfoButton(card)
end

-- ---------------------------------------------------------------------------
-- Rarity info popup (? button + modal)
-- ---------------------------------------------------------------------------
function Detail:InitRarityInfoButton(card)
    local btn = CreateFrame("Button", nil, card)
    btn:SetSize(20, 20)
    btn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)

    -- Circular background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.18, 0.15, 0.10, 0.9)
    btn.bg = bg

    -- Round mask (via SetMask on the bg)
    bg:SetTexture("Interface\\COMMON\\common-roundhighlight")
    bg:SetVertexColor(0.18, 0.15, 0.10, 0.9)

    -- Question-mark label
    local qm = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qm:SetPoint("CENTER", 0, 0)
    qm:SetText("?")
    qm:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    btn.label = qm

    btn:SetScript("OnEnter", function(self_)
        self_.bg:SetVertexColor(0.28, 0.23, 0.14, 1.0)
        self_.label:SetTextColor(1, 0.92, 0.6)
    end)
    btn:SetScript("OnLeave", function(self_)
        self_.bg:SetVertexColor(0.18, 0.15, 0.10, 0.9)
        self_.label:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    end)
    btn:SetScript("OnClick", function() self:ToggleRarityModal() end)
    self.rarityInfoBtn = btn

    -- Modal frame (hidden by default)
    local modal = CreateFrame("Frame", nil, card, "BackdropTemplate")
    modal:SetSize(320, 160)
    modal:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, -4)
    modal:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    modal:SetBackdropColor(0.08, 0.06, 0.03, 0.95)
    modal:SetBackdropBorderColor(0.49, 0.37, 0.15, 1.0)
    modal:SetFrameStrata("DIALOG")
    modal:Hide()
    self.rarityModal = modal

    -- Themed font: RARITY_NOTE can contain an em-dash (U+2014) separator that
    -- some locale game fonts lack; the bundled font used for those locales has it.
    local noteText = (T and T.Sans and T.Sans(modal, 11, MUTED))
        or modal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    noteText:SetPoint("TOPLEFT", 10, -10)
    noteText:SetPoint("BOTTOMRIGHT", -10, 10)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetTextColor(MUTED.r, MUTED.g, MUTED.b)
    noteText:SetSpacing(2)
    self.rarityModalText = noteText
end

function Detail:ToggleRarityModal()
    if self.rarityModal:IsShown() then
        self.rarityModal:Hide()
    else
        self.rarityModal:Show()
    end
end

-- ---------------------------------------------------------------------------
-- Source card (fills available space)
-- ---------------------------------------------------------------------------
function Detail:InitSourceCard()
    local panel = self.panel
    local card = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
    card:SetPoint("TOPLEFT", self.rarityCard, "BOTTOMLEFT", 0, -12)
    card:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    -- Gap is fixed rather than grown only when the hint is showing. A dynamic gap
    -- would resize the card as the hint appears, which changes the viewport height
    -- and so can change whether the content overflows at all — hint on, card
    -- shrinks, no longer overflows, hint off, card grows, overflows again.
    card:SetPoint("BOTTOM", self.favButton, "TOP", 0, HINT_GAP)
    self.sourceCard = card

    -- The card itself stays put between the rarity card and the action footer;
    -- only its interior scrolls. Obtainability prose runs to a full paragraph on
    -- some titles (more so once translated), which used to overflow the card and
    -- collide with the meta rows pinned to its bottom edge.
    local scroll = CreateFrame("ScrollFrame", nil, card)
    scroll:SetPoint("TOPLEFT", 12, -12)
    scroll:SetPoint("BOTTOMRIGHT", -SCROLLBAR_GUTTER, 12)
    self.sourceScroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT")
    content:SetSize(1, 1) -- real size applied by SyncSourceScrollSize
    scroll:SetScrollChild(content)
    self.sourceContent = content

    scroll:SetScript("OnSizeChanged", function() self:SyncSourceScrollSize() end)
    -- The card is the frame that actually resizes with the window; the scroll
    -- follows it. Hooking both means the child width is corrected whichever one
    -- the layout pass reports first.
    card:HookScript("OnSizeChanged", function() self:SyncSourceScrollSize() end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self_, delta)
        local range = Detail:GetSourceScrollRange()
        if range <= 0 then return end
        local target = self_:GetVerticalScroll() - (delta * SCROLL_STEP)
        if target < 0 then target = 0 elseif target > range then target = range end
        self_:SetVerticalScroll(target)
        Detail:UpdateSourceScrollBar()
    end)

    self:InitSourceScrollBar(card)

    local heading = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT", 0, 0)
    heading:SetText(L["HOW_TO_OBTAIN"])
    heading:SetTextColor(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b)
    self.sourceHeading = heading

    -- Sigil chip
    local sigilBG = content:CreateTexture(nil, "ARTWORK")
    sigilBG:SetSize(34, 34)
    sigilBG:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10)
    sigilBG:SetColorTexture(0.12, 0.10, 0.06, 0.8)
    self.sigilBG = sigilBG

    local sigil = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sigil:SetPoint("CENTER", sigilBG, "CENTER")
    sigil:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    self.sigil = sigil

    -- Category icon overlay (preferred over letter when available)
    local sigilIcon = content:CreateTexture(nil, "OVERLAY")
    sigilIcon:SetSize(24, 24)
    sigilIcon:SetPoint("CENTER", sigilBG, "CENTER")
    sigilIcon:SetVertexColor(GOLD.r, GOLD.g, GOLD.b)
    sigilIcon:Hide()
    self.sigilIcon = sigilIcon

    -- Wrapping widths are set explicitly by SyncSourceScrollSize rather than by a
    -- RIGHT anchor. An anchor would make the wrap width depend on the scroll
    -- child, which is sized late and re-sized again when the footer below the card
    -- moves — so the text could be laid out against a stale width. An explicit
    -- width is resolved the moment it is set, whatever the layout pass is doing.
    local kindLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    kindLabel:SetPoint("TOPLEFT", sigilBG, "TOPRIGHT", 10, -2)
    kindLabel:SetJustifyH("LEFT")
    self.kindLabel = kindLabel

    local sourceLink = CreateFrame("Button", nil, content)
    sourceLink:SetPoint("TOPLEFT", kindLabel, "BOTTOMLEFT", 0, -2)
    sourceLink:SetHeight(16)
    local linkText = sourceLink:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    linkText:SetPoint("LEFT")
    linkText:SetPoint("RIGHT")
    linkText:SetJustifyH("LEFT")
    linkText:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    sourceLink.text = linkText
    sourceLink:SetScript("OnEnter", function() linkText:SetTextColor(1, 0.92, 0.6) end)
    sourceLink:SetScript("OnLeave", function() linkText:SetTextColor(GOLD.r, GOLD.g, GOLD.b) end)
    sourceLink:SetScript("OnClick", function() self:OnSourceLinkClick() end)
    self.sourceLink = sourceLink

    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", sigilBG, "BOTTOMLEFT", 0, -12)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.78, 0.74, 0.66)
    desc:SetSpacing(2)
    self.descText = desc

    -- Obtainability banner (icon + label, shown only for unobtainable/feat titles)
    local obtainRow = CreateFrame("Frame", nil, content)
    obtainRow:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    obtainRow:SetHeight(20)
    obtainRow:Hide()
    self.obtainRow = obtainRow

    local obtainIcon = obtainRow:CreateTexture(nil, "ARTWORK")
    obtainIcon:SetSize(16, 16)
    obtainIcon:SetPoint("LEFT", 0, 0)
    self.obtainIcon = obtainIcon

    local obtainLabel = obtainRow:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    obtainLabel:SetPoint("LEFT", obtainIcon, "RIGHT", 6, 0)
    obtainLabel:SetPoint("RIGHT", obtainRow, "RIGHT", 0, 0)
    obtainLabel:SetJustifyH("LEFT")
    self.obtainLabel = obtainLabel

    local obtainReason = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    obtainReason:SetPoint("TOPLEFT", obtainRow, "BOTTOMLEFT", 22, -4)
    obtainReason:SetJustifyH("LEFT")
    obtainReason:SetTextColor(0.58, 0.52, 0.42)
    obtainReason:SetSpacing(2)
    obtainReason:Hide()
    self.obtainReason = obtainReason

    -- Themed font (not a Blizzard game font): the availability line can include
    -- a middle-dot (U+00B7) separator that some locale game fonts lack. Per-line
    -- colour is applied via |cff codes in the text, so the base colour here is
    -- just a fallback.
    --
    -- Now flows after the obtainability prose instead of being pinned to the
    -- card's bottom edge: inside a scrolling child a bottom anchor would peg it
    -- to the viewport rather than the end of the content.
    local meta = (T and T.Sans and T.Sans(content, 11, MUTED))
        or content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    meta:SetJustifyH("LEFT")
    self.metaText = meta

    self:SyncSourceScrollSize()
end

-- ---------------------------------------------------------------------------
-- Source-card scrolling
-- ---------------------------------------------------------------------------
-- Slim themed bar rather than UIPanelScrollFrameTemplate, whose Blizzard artwork
-- would sit oddly against the card. Hidden entirely when nothing overflows.
function Detail:InitSourceScrollBar(card)
    local track = card:CreateTexture(nil, "ARTWORK")
    track:SetWidth(SCROLLBAR_WIDTH)
    track:SetPoint("TOPRIGHT", -6, -12)
    track:SetPoint("BOTTOMRIGHT", -6, 12)
    track:SetColorTexture(0.16, 0.13, 0.08, 0.7)
    track:Hide()
    self.sourceScrollTrack = track

    local thumb = card:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(SCROLLBAR_WIDTH)
    thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, 0)
    thumb:SetHeight(20)
    thumb:SetColorTexture(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b, 0.85)
    thumb:Hide()
    self.sourceScrollThumb = thumb

    -- Overflow hint for hover preview. The preview cannot be scrolled (the cursor
    -- is out over the list), so the scrollbar alone would advertise content the
    -- reader has no way to reach. Sits in the gap between the card and the footer,
    -- and is parented to the card so the empty state takes it down too.
    local hint = (T and T.Sans and T.Sans(card, 10, MUTED))
        or card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOP", card, "BOTTOM", 0, -1)
    hint:SetJustifyH("CENTER")
    hint:SetText(L["DETAIL_MORE_ON_SELECT"])
    hint:SetTextColor(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b, 0.9)
    hint:Hide()
    self.moreHint = hint
end

-- Keeps the scroll child exactly as wide as the viewport. This is what makes the
-- prose wrap: a FontString anchored LEFT+RIGHT inside the child derives its width
-- from the child, so a child stuck at its placeholder width leaves every wrapping
-- line effectively unconstrained.
--
-- A frame sized purely by anchors reports GetWidth() == 0 until the first layout
-- pass, which is exactly when InitSourceCard runs. The card fallback covers that
-- first call, and the OnSizeChanged hooks plus the per-refresh call keep it right
-- afterwards.
function Detail:SyncSourceScrollSize()
    local scroll, content = self.sourceScroll, self.sourceContent
    if not (scroll and content) then return end

    local w = scroll:GetWidth()
    if (not w or w <= 0) and self.sourceCard then
        local cardW = self.sourceCard:GetWidth()
        if cardW and cardW > 0 then
            w = cardW - 12 - SCROLLBAR_GUTTER
        end
    end

    if not w or w <= 0 then return end

    if math.abs((content:GetWidth() or 0) - w) > 0.5 then
        content:SetWidth(w)
    end

    -- Explicit wrap widths for everything that can run long. Offsets mirror the
    -- anchors: the kind/link column starts past the 34px sigil chip plus its 10px
    -- gap, and the obtainability prose is indented 22px under its banner row.
    local sideW = math.max(1, w - (SIGIL_SIZE + SIGIL_GAP))
    self.kindLabel:SetWidth(sideW)
    self.sourceLink:SetWidth(sideW)
    self.descText:SetWidth(w)
    self.obtainRow:SetWidth(w)
    self.obtainReason:SetWidth(math.max(1, w - OBTAIN_INDENT))
    self.metaText:SetWidth(w)

    self:UpdateSourceScrollHeight()
end

-- Content height is summed from the laid-out pieces rather than measured, so it
-- is correct in the same frame the text is set (GetTop/GetBottom lag a frame
-- behind a SetText).
function Detail:UpdateSourceScrollHeight()
    local scroll, content = self.sourceScroll, self.sourceContent
    if not (scroll and content) then return end

    local h = self.sourceHeading:GetStringHeight() or 12
    h = h + 10

    -- Sigil chip sits beside the kind/link column; the taller of the two wins.
    local sideColumn = (self.kindLabel:GetStringHeight() or 12) + 2
    if self.sourceLink:IsShown() then
        sideColumn = sideColumn + self.sourceLink:GetHeight()
    end
    h = h + math.max(self.sigilBG:GetHeight() or 34, sideColumn)

    if (self.descText:GetText() or "") ~= "" then
        h = h + 12 + (self.descText:GetStringHeight() or 0)
    end
    if self.obtainRow:IsShown() then
        h = h + 10 + (self.obtainRow:GetHeight() or 20)
    end
    if self.obtainReason:IsShown() then
        h = h + 4 + (self.obtainReason:GetStringHeight() or 0)
    end
    if (self.metaText:GetText() or "") ~= "" then
        h = h + 12 + (self.metaText:GetStringHeight() or 0)
    end
    h = h + SCROLL_BOTTOM_PAD

    -- Never shorter than the viewport, or the scroll range goes negative.
    content:SetHeight(math.max(h, scroll:GetHeight() or 0, 1))

    local range = self:GetSourceScrollRange()
    if (scroll:GetVerticalScroll() or 0) > range then
        scroll:SetVerticalScroll(range)
    end
    self:UpdateSourceScrollBar()
end

-- Scroll range measured from the frames directly rather than read back from
-- ScrollFrame:GetVerticalScrollRange().
--
-- That API is only recalculated on the ScrollFrame's own update, so immediately
-- after UpdateSourceScrollHeight sets a new child height it still reports the
-- PREVIOUS title's range. Selecting a title happened to work anyway, because a
-- later size change or wheel event re-ran this with a settled value — but on
-- hover nothing follows the refresh, so the overflow hint was being decided from
-- a stale number and stayed hidden. Both values here are known exactly at the
-- moment they are needed: the child height is one we set ourselves.
function Detail:GetSourceScrollRange()
    local scroll, content = self.sourceScroll, self.sourceContent
    if not (scroll and content) then return 0, 0 end

    local viewH = scroll:GetHeight() or 0
    local range = (content:GetHeight() or 0) - viewH
    if range < 0 then range = 0 end
    return range, viewH
end

-- Re-sync once the layout has settled.
--
-- The pane's height is not final while Refresh is running: clearing the preview
-- banner collapses it to zero height, which lifts the title, sub-line and rarity
-- card and so makes the source card TALLER, and the footer is rewritten after the
-- source card too. Every one of those changes the viewport height, but they land
-- after RefreshSourceCard has already measured it — which is why selecting a
-- title kept the preview's shorter height and never showed the scrollbar.
--
-- The immediate pass still runs, so there is no visible flicker in the common
-- case; this only corrects the frames where the column moved underneath it.
function Detail:ScheduleSourceScrollSync()
    if self.scrollSyncPending then return end
    if not (C_Timer and C_Timer.After) then return end

    self.scrollSyncPending = true
    C_Timer.After(0, function()
        self.scrollSyncPending = false
        self:SyncSourceScrollSize()
    end)
end

function Detail:UpdateSourceScrollBar()
    local scroll = self.sourceScroll
    local track, thumb = self.sourceScrollTrack, self.sourceScrollThumb
    if not (scroll and track and thumb) then return end

    local range, viewH = self:GetSourceScrollRange()
    local overflows = (range > 1) and (viewH > 0)

    -- The two overflow affordances are mutually exclusive, because only one of
    -- them is actionable at a time. Hovering a row leaves the cursor out over the
    -- list, so the pane cannot be scrolled and a scrollbar would only point at
    -- text the reader cannot reach; the hint tells them how to reach it instead.
    -- Once selected the pane is scrollable, so the bar does the job and the hint
    -- would be telling them to do what they have already done.
    local hovering = (self.lastIsHover == true)

    if self.moreHint then
        self.moreHint:SetShown(overflows and hovering)
    end

    if not overflows or hovering then
        track:Hide()
        thumb:Hide()
        return
    end

    track:Show()
    thumb:Show()

    local contentH = viewH + range
    local thumbH = math.max(20, viewH * (viewH / contentH))
    local travel = viewH - thumbH
    local progress = (scroll:GetVerticalScroll() or 0) / range

    thumb:SetHeight(thumbH)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, -(travel * progress))
end

-- ---------------------------------------------------------------------------
-- Action footer
-- ---------------------------------------------------------------------------
function Detail:InitActionFooter()
    local panel = self.panel

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("BOTTOMLEFT", INSET, 16)
    note:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)
    note:SetJustifyH("CENTER")
    note:SetTextColor(0.42, 0.38, 0.29)
    self.actionNote = note

    -- Custom gold-bordered dark button (Set as Title)
    local button = CreateFrame("Button", nil, panel)
    button:SetHeight(34)
    button:SetPoint("BOTTOMLEFT", note, "TOPLEFT", 0, 9)
    button:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)

    -- Background (dark gradient approximation)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
    button.bg = bg

    -- Border (4 edges, gold-deep)
    local borderTop = button:CreateTexture(nil, "BORDER")
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT")
    borderTop:SetPoint("TOPRIGHT")
    borderTop:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local borderBot = button:CreateTexture(nil, "BORDER")
    borderBot:SetHeight(1)
    borderBot:SetPoint("BOTTOMLEFT")
    borderBot:SetPoint("BOTTOMRIGHT")
    borderBot:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local borderL = button:CreateTexture(nil, "BORDER")
    borderL:SetWidth(1)
    borderL:SetPoint("TOPLEFT")
    borderL:SetPoint("BOTTOMLEFT")
    borderL:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local borderR = button:CreateTexture(nil, "BORDER")
    borderR:SetWidth(1)
    borderR:SetPoint("TOPRIGHT")
    borderR:SetPoint("BOTTOMRIGHT")
    borderR:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    button.borders = { borderTop, borderBot, borderL, borderR }

    -- Text
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 8, 0)
    text:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    button.text = text

    -- Banner mark icon (shown when title is active)
    local tick = button:CreateTexture(nil, "OVERLAY")
    tick:SetSize(34, 34)
    tick:SetPoint("RIGHT", text, "LEFT", -4, 0)
    tick:SetTexture("Interface\\AddOns\\Epithet\\icons\\logo\\epithet-banner-mark-64")
    tick:Hide()
    button.tick = tick

    -- Hover effects
    button:SetScript("OnEnter", function(self_)
        if self_:IsEnabled() then
            self_.bg:SetColorTexture(0.16, 0.12, 0.07, 1.0)
            self_.text:SetTextColor(0.96, 0.89, 0.65)
            for _, b in ipairs(self_.borders) do
                b:SetColorTexture(0.91, 0.78, 0.45, 1.0)
            end
        end
    end)
    button:SetScript("OnLeave", function(self_)
        if self_:IsEnabled() then
            self_.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
            self_.text:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
            for _, b in ipairs(self_.borders) do
                b:SetColorTexture(0.49, 0.37, 0.15, 1.0)
            end
        end
    end)
    button:SetScript("OnClick", function() self:OnActionClick() end)

    -- Custom SetText / Enable / Disable
    function button:SetText(t) self.text:SetText(t) end
    function button:SetEnabled(e)
        if e then self:Enable() else self:Disable() end
    end

    self.actionButton = button

    -- Favourite toggle button (positioned above the action button)
    local favBtn = CreateFrame("Button", nil, panel)
    favBtn:SetHeight(28)
    favBtn:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 8)
    favBtn:SetPoint("RIGHT", panel, "RIGHT", -INSET, 0)

    local favBg = favBtn:CreateTexture(nil, "BACKGROUND")
    favBg:SetAllPoints()
    favBg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
    favBtn.bg = favBg

    -- Border (4 edges)
    local fbTop = favBtn:CreateTexture(nil, "BORDER")
    fbTop:SetHeight(1); fbTop:SetPoint("TOPLEFT"); fbTop:SetPoint("TOPRIGHT")
    fbTop:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local fbBot = favBtn:CreateTexture(nil, "BORDER")
    fbBot:SetHeight(1); fbBot:SetPoint("BOTTOMLEFT"); fbBot:SetPoint("BOTTOMRIGHT")
    fbBot:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local fbL = favBtn:CreateTexture(nil, "BORDER")
    fbL:SetWidth(1); fbL:SetPoint("TOPLEFT"); fbL:SetPoint("BOTTOMLEFT")
    fbL:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local fbR = favBtn:CreateTexture(nil, "BORDER")
    fbR:SetWidth(1); fbR:SetPoint("TOPRIGHT"); fbR:SetPoint("BOTTOMRIGHT")
    fbR:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    favBtn.borders = { fbTop, fbBot, fbL, fbR }

    -- Content container (centers icon + label as a group)
    local content = CreateFrame("Frame", nil, favBtn)
    content:SetPoint("CENTER")
    content:SetHeight(14)
    favBtn.content = content

    -- Star icon
    local favIcon = content:CreateTexture(nil, "OVERLAY")
    favIcon:SetSize(14, 14)
    favIcon:SetPoint("LEFT", 0, 0)
    favIcon:SetTexture("Interface\\AddOns\\Epithet\\icons\\ui\\star")
    favBtn.icon = favIcon

    -- Label
    local favText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    favText:SetPoint("LEFT", favIcon, "RIGHT", 6, 0)
    favBtn.text = favText

    -- Hover
    favBtn:SetScript("OnEnter", function(self_)
        self_.bg:SetColorTexture(0.16, 0.12, 0.07, 1.0)
        for _, b in ipairs(self_.borders) do
            b:SetColorTexture(0.91, 0.78, 0.45, 1.0)
        end
    end)
    favBtn:SetScript("OnLeave", function(self_)
        self_.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
        for _, b in ipairs(self_.borders) do
            b:SetColorTexture(0.49, 0.37, 0.15, 1.0)
        end
    end)
    favBtn:SetScript("OnClick", function() self:OnFavouriteClick() end)

    self.favButton = favBtn
end

-- ---------------------------------------------------------------------------
-- Refresh
-- ---------------------------------------------------------------------------
Detail.lastRecord = NEVER_REFRESHED
Detail.lastIsHover = nil

function Detail:Refresh(force)
    if not self.panel then return end

    local record = ns.MainFrame:GetDetailRecord()
    local isHover = (ns.MainFrame.hoveredRecord ~= nil)

    -- Hovering/unhovering the row that's already selected (or re-hovering
    -- the same row) resolves to the same record and hover state, so the
    -- ~40 widget writes below would be pure churn; skip unless forced (e.g.
    -- OnActionClick, where the record is mutated in place after an action).
    if not force and record == self.lastRecord and isHover == self.lastIsHover then
        return
    end
    local recordChanged = (record ~= self.lastRecord)
    self.lastRecord = record
    self.lastIsHover = isHover

    -- Land at the top of a newly shown title's prose rather than wherever the
    -- previous one happened to be scrolled to.
    if recordChanged and self.sourceScroll then
        self.sourceScroll:SetVerticalScroll(0)
    end

    -- Dismiss rarity info popup on any selection/hover change
    if self.rarityModal and self.rarityModal:IsShown() then
        self.rarityModal:Hide()
    end

    if not record then
        self:ShowEmpty()
        return
    end
    self:HideEmpty()

    self.previewBanner:SetText(isHover and L["PREVIEW_HOVERING"] or "")

    -- Title in context (colour-wrapped per design spec)
    local name = ns.TitleData.playerName or UnitName("player") or "Player"
    if T and T.quality[record.q] then
        local tq = T.quality[record.q]
        local titleHex = record.earned and tq.text.hex or col.locked.hex
        local nameHex  = record.earned and col.muted.hex or col.locked.hex
        local titleStr = T.Wrap(titleHex, record.text)
        local nameStr  = T.Wrap(nameHex, name)
        if record.type == "suffix" then
            self.titleText:SetText(nameStr .. ", " .. titleStr)
        else
            self.titleText:SetText(titleStr .. " " .. nameStr)
        end
    else
        self.titleText:SetText(ns.TitleData:RenderTitleInContext(record, name))
    end

    -- Sub-line
    wipe(scratchParts)
    scratchParts[#scratchParts + 1] = (record.type == "prefix") and L["PREFIX_TITLE"] or L["SUFFIX_TITLE"]
    if record.exp then
        scratchParts[#scratchParts + 1] = ns.EXPANSION_LABELS[record.exp] or record.exp
    end
    if record.q then
        scratchParts[#scratchParts + 1] = ns.QUALITY_NAMES[record.q]
    end
    self.subLine:SetText(tconcat(scratchParts, " " .. DOT .. " "))

    self:RefreshRarityCard(record)
    self:RefreshSourceCard(record)
    self:RefreshActionButton(record)
    self:RefreshFavButton(record)
end

function Detail:RefreshRarityCard(record)
    local q = record.q or 0
    local tq = T and T.quality[q]
    self.qualityLabel:SetText(q > 0 and ns.QUALITY_NAMES[q] or L["UNRANKED"])
    if q > 0 then
        local c = tq and tq.text or ns.QUALITY_COLOURS[q].text
        self.qualityLabel:SetTextColor(c.r, c.g, c.b)
        local p = tq and tq.pip or ns.QUALITY_COLOURS[q].pip
        self.rarityGem:SetTexture(RARITY_GEMS[q] or RARITY_GEMS[1])
        self.rarityGem:SetVertexColor(p.r, p.g, p.b, 1.0)
        self.rarityGem:Show()
    else
        self.qualityLabel:SetTextColor(MUTED.r, MUTED.g, MUTED.b)
        self.rarityGem:Hide()
    end

    for i = 1, 5 do
        local seg = self.tierSegments[i]
        if i <= q then
            local tqi = T and T.quality[i]
            local c = tqi and tqi.pip or ns.QUALITY_COLOURS[q].pip
            seg:SetColorTexture(c.r, c.g, c.b, 1.0)
        else
            seg:SetColorTexture(0.30, 0.27, 0.21, 0.6)
        end
    end

    if record.rarity then
        -- The %s carries the colour wrap, so the localised sentence keeps its own
        -- word order. (This branch used to concatenate a hardcoded English string,
        -- which left HELD_BY_ESTIMATE unreachable and this line untranslated.)
        local pctText = T and T.Wrap(T.col.goldBright.hex, tostring(record.rarity))
            or tostring(record.rarity)
        self.rarityPct:SetText(format(L["HELD_BY_ESTIMATE"], pctText))
    else
        self.rarityPct:SetText("")
    end

    self.rarityModalText:SetText(L["RARITY_NOTE"])

    -- Faction icon
    local faction = record.faction
    if faction == "Alliance" then
        self.factionIcon:SetTexture(FACTION_ALLIANCE_64)
        self.factionIcon:SetVertexColor(0.91, 0.78, 0.45, 1.0)
        self.factionIcon:Show()
    elseif faction == "Horde" then
        self.factionIcon:SetTexture(FACTION_HORDE_64)
        self.factionIcon:SetVertexColor(0.85, 0.20, 0.20, 1.0)
        self.factionIcon:Show()
    else
        self.factionIcon:Hide()
    end
end

function Detail:RefreshSourceCard(record)
    -- Re-sync before writing any text. By the time a record is shown the pane has
    -- been laid out, so this is the call that reliably lands a real width on the
    -- scroll child even if every earlier attempt saw zero.
    self:SyncSourceScrollSize()

    -- Raw DB codes (English) — used ONLY for keying the icon/sigil lookup
    -- tables below. Never display these directly; see kindLabel a few lines
    -- down for the localised text shown to the player.
    local rawKind = record.kind or "Achievement"
    local rawCat  = record.cat or rawKind

    -- Prefer category icon; fall back to letter sigil
    local iconPath = SIGIL_ICONS[rawCat] or SIGIL_ICONS[rawKind]
    if iconPath then
        self.sigilIcon:SetTexture(iconPath)
        self.sigilIcon:Show()
        self.sigil:SetText("")
    else
        self.sigilIcon:Hide()
        self.sigil:SetText(SIGIL_LETTERS[rawKind] or "?")
    end
    self.kindLabel:SetText(ns.KindLabel(rawKind))

    -- Source link text: prefer structured source fields, else the title itself
    local sourceName = record.text or ""
    if record.achievement and record.achievement ~= "" then
        sourceName = record.achievement
    elseif record.quest and record.quest ~= "" then
        sourceName = record.quest
    elseif record.source_item and record.source_item ~= "" then
        sourceName = record.source_item
    end
    self.sourceLink.text:SetText(sourceName)
    if record.achievement_id then
        self.sourceLink:Show()
    else
        self.sourceLink:Hide()
    end

    -- Contextual description based on source kind
    local desc
    if record.achievement and record.achievement ~= "" then
        desc = format(L["SOURCE_ACHIEVEMENT_DESC"], record.achievement)
    elseif record.quest and record.quest ~= "" then
        desc = format(L["SOURCE_QUEST_DESC"], record.quest)
    elseif record.source_item and record.source_item ~= "" then
        desc = format(L["SOURCE_ITEM_DESC"], record.source_item)
    end
    self.descText:SetText(desc or L["UNKNOWN_SOURCE"])

    -- Obtainability banner
    local obt = record.obtainable
    if obt == "no" then
        self.obtainIcon:SetTexture(UNOBTAIN_SEALED_16)
        self.obtainIcon:SetVertexColor(0.85, 0.35, 0.30, 1.0)
        self.obtainLabel:SetText(L["NO_LONGER_OBTAINABLE"])
        self.obtainLabel:SetTextColor(0.85, 0.35, 0.30)
        self.obtainRow:Show()
    elseif obt == "feat" then
        self.obtainIcon:SetTexture(UNOBTAIN_HOURGLASS_16)
        self.obtainIcon:SetVertexColor(0.90, 0.70, 0.25, 1.0)
        self.obtainLabel:SetText(L["FEAT_OF_STRENGTH"])
        self.obtainLabel:SetTextColor(0.90, 0.70, 0.25)
        self.obtainRow:Show()
    else
        self.obtainRow:Hide()
    end

    -- Obtainability reason (shown below the banner when present)
    local reason = record.obtainability_reason
    if reason and reason ~= "" then
        self.obtainReason:SetText(reason)
        self.obtainReason:Show()
    else
        self.obtainReason:SetText("")
        self.obtainReason:Hide()
    end

    -- Meta grid (key-value rows with colour codes from Theme)
    local FAINT = T and ("|cff" .. T.col.faint.hex) or "|cff6b6049"
    local TEXT  = T and ("|cff" .. T.col.text.hex) or "|cffe7dcc4"
    local WARN  = T and ("|cff" .. T.col.warn.hex) or "|cffd98a52"
    local lines = {}

    if record.exp then
        local expLabel = ns.EXPANSION_LABELS[record.exp] or record.exp
        lines[#lines + 1] = FAINT .. L["EXPANSION_LABEL"] .. "|r " .. TEXT .. expLabel .. "|r"
    end
    if record.cat then
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["CATEGORY_LABEL"] .. "|r " .. TEXT .. ns.CategoryLabel(record.cat) .. "|r"
    end
    if record.obtainable == "no" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["AVAILABILITY_LABEL"] .. "|r " .. WARN .. L["NO_LONGER_OBTAINABLE"] .. "|r"
    elseif record.obtainable == "feat" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["AVAILABILITY_LABEL"] .. "|r " .. WARN .. L["FEAT_OF_STRENGTH"] .. "|r"
    elseif record.availability and record.availability ~= "permanent" then
        local avail = L["AVAILABILITY_" .. record.availability:upper()] or record.availability
        if record.availability_event then
            avail = avail .. " " .. DOT .. " " .. record.availability_event
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["AVAILABILITY_LABEL"] .. "|r " .. WARN .. avail .. "|r"
    else
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["AVAILABILITY_LABEL"] .. "|r " .. TEXT .. L["ACCOUNT_WIDE"] .. "|r"
    end
    if record.faction then
        local factionLabel = (record.faction == "Alliance") and L["FACTION_ALLIANCE"]
            or (record.faction == "Horde") and L["FACTION_HORDE"]
            or record.faction
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["FACTION"] .. "|r " .. TEXT .. factionLabel .. "|r"
    end
    if record.earned and record.date then
        local dateHex = T and ("|cff" .. T.quality[5].text.hex) or "|cffffa334"
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["EARNED_LABEL"] .. "|r " .. dateHex .. string.format(L["EARNED_DATE"], record.date) .. "|r"
    elseif not record.earned then
        local lockHex = T and ("|cff" .. T.col.locked.hex) or "|cff5d5443"
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["STATUS_LABEL"] .. "|r " .. lockHex .. L["NOT_YET_EARNED"] .. "|r"
    end
    if record.last_updated then
        lines[#lines + 1] = ""
        lines[#lines + 1] = FAINT .. L["LAST_ASSESSED"] .. "|r " .. TEXT .. record.last_updated .. "|r"
    end

    self.metaText:SetText(table.concat(lines, "\n"))

    -- Re-anchor to whichever block above it is actually visible. A hidden region
    -- keeps its anchors, so chaining off obtainReason unconditionally would leave
    -- a gap on every title that has no obtainability prose.
    local anchor, indent = self.descText, 0
    if self.obtainReason:IsShown() then
        anchor, indent = self.obtainReason, -22 -- cancel obtainReason's own indent
    elseif self.obtainRow:IsShown() then
        anchor = self.obtainRow
    end

    -- TOPLEFT only: the width comes from SyncSourceScrollSize, and a RIGHT anchor
    -- here would override it.
    self.metaText:ClearAllPoints()
    self.metaText:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", indent, -12)

    self:UpdateSourceScrollHeight()
    self:ScheduleSourceScrollSync()
end

function Detail:RefreshActionButton(record)
    local btn = self.actionButton
    local goldCol = T and T.col.gold or GOLD
    local inkCol  = T and T.col.ink or { r = 0.05, g = 0.04, b = 0.02 }
    local deepCol = T and T.col.goldDeep or { r = 0.49, g = 0.37, b = 0.15 }

    if record.isActive then
        btn:SetText(L["CURRENT_TITLE"])
        btn:Disable()
        btn.tick:Show()
        -- Active state: gold fill, dark text
        btn.bg:SetColorTexture(goldCol.r, goldCol.g, goldCol.b, 1.0)
        btn.text:SetTextColor(inkCol.r, inkCol.g, inkCol.b)
        for _, b in ipairs(btn.borders) do
            b:SetColorTexture(goldCol.r, goldCol.g, goldCol.b, 1.0)
        end
        self.actionNote:SetText(L["CURRENT_NOTE"])
    elseif record.earned then
        btn:SetText(L["SET_AS_MY_TITLE"])
        btn:Enable()
        btn.tick:Hide()
        -- Normal enabled state
        btn.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
        btn.text:SetTextColor(goldCol.r, goldCol.g, goldCol.b)
        for _, b in ipairs(btn.borders) do
            b:SetColorTexture(deepCol.r, deepCol.g, deepCol.b, 1.0)
        end
        self.actionNote:SetText(L["SET_NOTE"])
    else
        btn:SetText(L["LOCKED_BUTTON"])
        btn:Disable()
        btn.tick:Hide()
        -- Disabled/locked state
        btn.bg:SetColorTexture(0.07, 0.05, 0.03, 1.0)
        btn.text:SetTextColor(0.36, 0.33, 0.27)
        for _, b in ipairs(btn.borders) do
            b:SetColorTexture(0.20, 0.16, 0.10, 1.0)
        end
        self.actionNote:SetText(L["LOCKED_NOTE"])
    end
    btn.record = record
end

-- ---------------------------------------------------------------------------
-- Actions
-- ---------------------------------------------------------------------------
function Detail:OnActionClick()
    local record = self.actionButton.record
    if not record or not record.earned or record.isActive then return end
    if SetCurrentTitle and record.titleID then
        SetCurrentTitle(record.titleID)
        ns.TitleData:RefreshActiveState()
        ns.MainFrame:FullRefresh()
        ns.TitleList:RefreshSelectionVisuals()
        self:Refresh(true) -- record.isActive changed in place; bypass the no-op guard
    end
end

function Detail:OnSourceLinkClick()
    local record = ns.MainFrame:GetDetailRecord()
    if not record then return end
    local achievementID = tonumber(record.achievement_id)
    if not achievementID then return end
    local achievementIsValid = true
    if C_AchievementInfo and C_AchievementInfo.IsValidAchievement then
        local ok, valid = pcall(C_AchievementInfo.IsValidAchievement, achievementID)
        if ok and valid == false then
            achievementIsValid = false
        end
    end
    if not AchievementFrame then
        if UIParentLoadAddOn then
            UIParentLoadAddOn("Blizzard_AchievementUI")
        elseif C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_AchievementUI")
        end
    end

    local opened = false

    if achievementIsValid and OpenAchievementFrameToAchievement then
        opened = pcall(OpenAchievementFrameToAchievement, achievementID)
    end

    if not opened then
        if AchievementFrame then
            if not AchievementFrame:IsShown() then
                if ShowUIPanel then
                    ShowUIPanel(AchievementFrame)
                else
                    AchievementFrame:Show()
                end
            end
            opened = AchievementFrame:IsShown()
        elseif ToggleAchievementFrame then
            -- Last-resort fallback for clients where explicit show APIs are absent.
            -- Guarding against IsShown avoids the open/close toggle behaviour.
            ToggleAchievementFrame()
            opened = true
        end

        -- Some clients expose explicit selection APIs but not
        -- OpenAchievementFrameToAchievement.
        if opened and achievementIsValid then
            if AchievementFrame_SelectAchievement then
                pcall(AchievementFrame_SelectAchievement, achievementID)
            elseif AchievementFrame and AchievementFrame.SelectAchievement then
                pcall(AchievementFrame.SelectAchievement, AchievementFrame, achievementID)
            end
        end
    end

    -- Blizzard's AchievementFrame is usually "MEDIUM", while EpithetMainFrame is
    -- "HIGH" (see UI/MainFrame.xml). Lift the achievement UI above ours while it
    -- is shown, then restore its original strata on hide.
    if opened and AchievementFrame then
        if not AchievementFrame.epithetOriginalStrata then
            AchievementFrame.epithetOriginalStrata = AchievementFrame:GetFrameStrata() or "MEDIUM"
        end
        AchievementFrame:SetFrameStrata("DIALOG")
        if not AchievementFrame.epithetStrataHooked then
            AchievementFrame.epithetStrataHooked = true
            AchievementFrame:HookScript("OnHide", function(self_)
                self_:SetFrameStrata(self_.epithetOriginalStrata or "MEDIUM")
            end)
        end
    end
end

function Detail:OnFavouriteClick()
    local record = ns.MainFrame:GetDetailRecord()
    if not record or not record.earned then return end
    local favs = ns.Epithet.db.profile.favourites
    local key = strlower(record.text or "")
    if favs[key] then
        favs[key] = nil
    else
        favs[key] = true
    end
    self:RefreshFavButton(record)
    ns.MainFrame:RefreshList()
end

function Detail:RefreshFavButton(record)
    local btn = self.favButton
    if not btn then return end

    if not record or not record.earned then
        btn:Hide()
        return
    end
    btn:Show()

    local favs = ns.Epithet.db and ns.Epithet.db.profile.favourites
    local key = strlower(record.text or "")
    local isFav = favs and favs[key] or false

    if isFav then
        btn.icon:SetVertexColor(0.91, 0.78, 0.45, 1.0)
        btn.text:SetText(L["REMOVE_FAVOURITE"] or "Remove from Favourites")
        btn.text:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
    else
        btn.icon:SetVertexColor(0.40, 0.36, 0.28, 0.6)
        btn.text:SetText(L["ADD_FAVOURITE"] or "Add to Favourites")
        btn.text:SetTextColor(MUTED.r, MUTED.g, MUTED.b)
    end

    -- Resize content container so it stays centred
    local textWidth = btn.text:GetStringWidth() or 80
    btn.content:SetWidth(14 + 6 + textWidth)  -- icon + gap + text
end

-- ---------------------------------------------------------------------------
-- Empty state
-- ---------------------------------------------------------------------------
function Detail:ShowEmpty()
    self.emptyState:Show()
    self.previewBanner:Hide()
    self.titleText:Hide()
    self.subLine:Hide()
    self.rarityCard:Hide()
    self.sourceCard:Hide()
    self.actionButton:Hide()
    self.actionNote:Hide()
    if self.favButton then self.favButton:Hide() end
end

function Detail:HideEmpty()
    self.emptyState:Hide()
    self.previewBanner:Show()
    self.titleText:Show()
    self.subLine:Show()
    self.rarityCard:Show()
    self.sourceCard:Show()
    self.actionButton:Show()
    self.actionNote:Show()
end
