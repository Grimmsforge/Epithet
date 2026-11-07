-- =============================================================================
-- Epithet — Title List (centre column)
-- Virtualised ScrollBox list of title rows + group headers.
-- =============================================================================
local _, ns = ...
local L = ns.L
local T = ns.Theme

-- Localize WoW APIs & Lua stdlib
local pairs, ipairs = pairs, ipairs
local tconcat  = table.concat
local strlower = strlower
local format   = string.format
local UnitName = UnitName
local wipe     = wipe

-- Scratch table reused per-row to avoid allocating in InitTitleRow (called
-- once per visible row on every scroll/refresh).
local metaScratch = {}

local TitleList = {}
ns.TitleList = TitleList

local CHECK_ICON = T.tex.check
local LOCK_ICON  = T.tex.lock

-- Unobtainability overlay icons (16px, shown as badge on the row)
local UNOBTAIN_SEALED    = T.tex.unobtainable
local UNOBTAIN_HOURGLASS = T.tex.timeSensitive

-- Faction overlay icons (32px, downscaled to 20px for clean rendering on rarity gem)
local FACTION_ALLIANCE = T.tex.alliance
local FACTION_HORDE    = T.tex.horde

local RARITY_GEMS = T and T.RarityGems64

-- Inline star texture escape (prepended to title text for favourites)
local FAV_STAR = T.InlineTex("star", 12) .. " "

local ROW_HEIGHT    = 64
local HEADER_HEIGHT = 28

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function TitleList:Init(container)
    if self.container then return end
    self.container = container
    self.scrollBox = container.ScrollBox
    self.scrollBar = container.ScrollBar
    self.header    = container.ListHeader

    self:InitHeader()
    self:InitScrollBox()
end

-- ---------------------------------------------------------------------------
-- List header (count + sort button)
-- ---------------------------------------------------------------------------
function TitleList:InitHeader()
    local header = self.header
    if not header then return end

    header.SortButton:SetScript("OnClick", function()
        self:ToggleSort()
    end)

    -- Add sort icon to button
    if not header.SortButton.icon then
        local icon = header.SortButton:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(T.tex.sort)
        icon:SetSize(12, 12)
        icon:SetPoint("LEFT", header.SortButton, "LEFT", 4, 0)
        icon:SetVertexColor(T.RGBA(T.col.goldDim))
        header.SortButton.icon = icon
    end

    -- Route the localized header text through the bundled font under a language
    -- override whose script the client fonts lack (e.g. Russian on a Western
    -- client), so the count and sort label don't render as boxes.
    if T and T.ApplyLocaleFont then
        T.ApplyLocaleFont(header.Count)
        T.ApplyLocaleFont(header.SortButton:GetFontString())
    end

    self:UpdateHeaderText(0)
end

function TitleList:UpdateHeaderText(count)
    local header = self.header
    if not header then return end

    header.Count:SetText(string.format(L["N_TITLES"], count or 0))

    local sortMode = ns.Epithet.db.profile.sort
    local label
    if sortMode == "expansion" then
        label = L["SORT_BY_EXPANSION"]
    elseif sortMode == "alphabetical" then
        label = L["SORT_ALPHABETICAL"]
    elseif sortMode == "quality" then
        label = L["SORT_BY_QUALITY"]
    elseif sortMode == "category" then
        label = L["SORT_BY_CATEGORY"]
    else
        label = L["SORT_COLLECTED_FIRST"]
    end
    header.SortButton:SetText(label)
end

local SORT_CYCLE = { "collectedFirst", "expansion", "alphabetical", "quality", "category" }

function TitleList:ToggleSort()
    local db = ns.Epithet.db.profile
    local current = db.sort or "collectedFirst"
    local nextIdx = 1
    for i, mode in ipairs(SORT_CYCLE) do
        if mode == current then
            nextIdx = (i % #SORT_CYCLE) + 1
            break
        end
    end
    db.sort = SORT_CYCLE[nextIdx]
    self:Refresh()
end

-- ---------------------------------------------------------------------------
-- ScrollBox setup
-- ---------------------------------------------------------------------------
function TitleList:InitScrollBox()
    local view = CreateScrollBoxListLinearView()

    view:SetElementExtentCalculator(function(_, elementData)
        if elementData.isHeader then
            return HEADER_HEIGHT
        end
        return ROW_HEIGHT
    end)

    view:SetElementFactory(function(factory, elementData)
        -- Template colours live in the theme (MainFrame.*_SKIN), painted once
        -- per pooled frame before its first bind, as the XML used to.
        if elementData.isHeader then
            factory("EpithetGroupHeaderTemplate", function(frame, data)
                if not frame.epithetSkinned then
                    T.ApplySkin(frame, ns.MainFrame.GROUP_HEADER_SKIN)
                    frame.epithetSkinned = true
                end
                TitleList:InitGroupHeader(frame, data)
            end)
        else
            factory("EpithetTitleRowTemplate", function(frame, data)
                if not frame.epithetSkinned then
                    T.ApplySkin(frame, ns.MainFrame.TITLE_ROW_SKIN)
                    frame.epithetSkinned = true
                end
                TitleList:InitTitleRow(frame, data)
            end)
        end
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, view)
    self.scrollView = view
end

-- ---------------------------------------------------------------------------
-- Refresh (apply filters, rebuild data provider)
-- ---------------------------------------------------------------------------
function TitleList:Refresh()
    if not self.scrollBox then return end

    local db = ns.Epithet.db.profile
    local records = ns.TitleData.records or {}
    local filtered = ns.Filters:Apply(records, db.filters)
    local display = ns.Filters:BuildDisplayList(filtered, db.sort)
    self.displayList = display

    self:UpdateHeaderText(#filtered)

    local dataProvider = CreateDataProvider(display)
    self.scrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

-- Stable row-script handlers: read row.record (kept current by InitTitleRow
-- on every acquire) instead of closing over `record`, so InitTitleRow can
-- bind them once per row instead of allocating 3 new closures per refresh.
local function RowOnEnter(row)
    ns.MainFrame:SetHover(row.record)
end

local function RowOnLeave(_row)
    ns.MainFrame:ClearHover()
end

local function RowOnClick(row)
    TitleList:SetSelection(row.record)
end

-- Shared by InitTitleRow and RefreshSelectionVisuals so the selection
-- highlight (fill + 4 border edges) only has one place to keep in sync.
local function ApplySelectionVisual(frame, isSelected)
    if isSelected then
        frame.Selected:Show()
        frame.SelBorderTop:Show()
        frame.SelBorderBottom:Show()
        frame.SelBorderLeft:Show()
        frame.SelBorderRight:Show()
    else
        frame.Selected:Hide()
        frame.SelBorderTop:Hide()
        frame.SelBorderBottom:Hide()
        frame.SelBorderLeft:Hide()
        frame.SelBorderRight:Hide()
    end
end

-- ---------------------------------------------------------------------------
-- Title row initialiser (called each time a row is acquired/recycled)
-- ---------------------------------------------------------------------------
function TitleList:InitTitleRow(row, record)
    row.record = record

    -- Under a language override in a non-client script (e.g. Russian on a Western
    -- client), the template's client font lacks the glyphs and text renders as
    -- boxes. Re-point the row's text at the bundled Unicode face once per frame
    -- (locale is fixed for the session; changing it reloads the UI). No-op on
    -- locales the client fonts already cover.
    if not row.localeFontDone and T and T.NeedsLocaleFont and T.NeedsLocaleFont() then
        T.ApplyLocaleFont(row.TitleText)
        T.ApplyLocaleFont(row.SourceText)
        T.ApplyLocaleFont(row.TypeTag)
        T.ApplyLocaleFont(row.ActiveChip)
        row.localeFontDone = true
    end

    -- Create chip background textures on first use
    if not row.ActiveChipBG then
        -- The chip text is a fixed label; the XML template ships an English
        -- placeholder, so localise it once here.
        row.ActiveChip:SetText(L["ACTIVE_TITLE"])
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetColorTexture(T.RGBA(T.col.gold))
        bg:SetPoint("TOPLEFT", row.ActiveChip, "TOPLEFT", -7, 3)
        bg:SetPoint("BOTTOMRIGHT", row.ActiveChip, "BOTTOMRIGHT", 7, -3)
        bg:Hide()
        row.ActiveChipBG = bg
    end
    if not row.TypeTagBG then
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetColorTexture(T.RGBA(T.col.black, 0.2))
        bg:SetPoint("TOPLEFT", row.TypeTag, "TOPLEFT", -6, 2)
        bg:SetPoint("BOTTOMRIGHT", row.TypeTag, "BOTTOMRIGHT", 4, -2)
        row.TypeTagBG = bg
    end
    if not row.TypeTagBorder then
        local border = row:CreateTexture(nil, "BACKGROUND")
        border:SetColorTexture(T.RGBA(T.col.line))
        border:SetPoint("TOPLEFT", row.TypeTag, "TOPLEFT", -7, 3)
        border:SetPoint("BOTTOMRIGHT", row.TypeTag, "BOTTOMRIGHT", 5, -3)
        row.TypeTagBorder = border
    end

    local quality = record.q and ns.QUALITY_COLOURS[record.q]
    local tq = T and T.quality and T.quality[record.q]
    local playerName = ns.TitleData.playerName or UnitName("player") or "Player"

    -- Rarity gem (full row height, tinted by rarity colour)
    local gemTex = RARITY_GEMS[record.q or 1] or RARITY_GEMS[1]
    row.Pip:SetTexture(gemTex)
    local pipColour = (tq and tq.pip) or (quality and quality.pip) or T.col.locked
    if record.earned then
        row.Pip:SetVertexColor(pipColour.r, pipColour.g, pipColour.b, 1.0)
    else
        local lc = T and T.col.locked or pipColour
        row.Pip:SetVertexColor(lc.r, lc.g, lc.b, 0.9)
    end
    row.Pip:Show()

    -- Faction badge (20px icon overlaid bottom-right of rarity gem, tinted faction colour)
    if not row.FactionBadge then
        local badge = row:CreateTexture(nil, "OVERLAY")
        badge:SetSize(20, 20)
        badge:SetPoint("BOTTOMRIGHT", row.Pip, "BOTTOMRIGHT", 4, -4)
        row.FactionBadge = badge
    end
    local faction = record.faction
    if faction == "Alliance" then
        row.FactionBadge:SetTexture(FACTION_ALLIANCE)
        row.FactionBadge:SetVertexColor(T.RGBA(T.col.alliance))
        row.FactionBadge:Show()
    elseif faction == "Horde" then
        row.FactionBadge:SetTexture(FACTION_HORDE)
        row.FactionBadge:SetVertexColor(T.RGBA(T.col.horde))
        row.FactionBadge:Show()
    else
        row.FactionBadge:Hide()
    end

    -- Row 1: Title with player name in context
    local favs = ns.Epithet.db and ns.Epithet.db.profile.favourites
    local isFav = favs and favs[strlower(record.text or "")] or false
    local starPrefix = isFav and FAV_STAR or ""

    if T and tq then
        local col = T.col
        local titleHex = record.earned and tq.text.hex or col.locked.hex
        local nameHex  = record.earned and col.muted.hex or col.locked.hex
        local title    = T.Wrap(titleHex, record.text)
        local name     = T.Wrap(nameHex, playerName)
        if record.type == "suffix" then
            row.TitleText:SetText(starPrefix .. name .. ", " .. title)
        else
            row.TitleText:SetText(starPrefix .. title .. " " .. name)
        end
        row.TitleText:SetTextColor(T.RGBA(T.col.rowTitleActive))
    else
        local contextText = ns.TitleData:RenderTitleInContext(record, playerName)
        row.TitleText:SetText(starPrefix .. contextText)
        if record.earned then
            local c = quality and quality.text or T.quality[1].text
            row.TitleText:SetTextColor(c.r, c.g, c.b)
        else
            row.TitleText:SetTextColor(T.RGBA(T.col.rowTitleLocked))
        end
    end

    -- Row 2: "Kind: Source" (e.g. "Achievement: Glory of the Raider")
    local kindStr = (record.kind and ns.KindLabel(record.kind))
        or (record.cat and ns.CategoryLabel(record.cat)) or ""
    local srcStr  = record.achievement or record.quest or record.source_item or ""
    if kindStr ~= "" and srcStr ~= "" then
        row.SourceText:SetText(kindStr .. ": " .. srcStr)
    elseif srcStr ~= "" then
        row.SourceText:SetText(srcStr)
    elseif kindStr ~= "" then
        row.SourceText:SetText(kindStr)
    else
        row.SourceText:SetText(L["UNKNOWN_SOURCE"] or "Unknown source")
    end

    -- Row 3: Expansion · Category (small muted label)
    if not row.MetaText then
        local meta = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        meta:SetPoint("TOPLEFT", row.SourceText, "BOTTOMLEFT", 0, -2)
        meta:SetPoint("RIGHT", row.TypeTag, "LEFT", -8, 0)
        meta:SetJustifyH("LEFT")
        if T and T.ApplyLocaleFont then T.ApplyLocaleFont(meta) end
        row.MetaText = meta
    end
    local metaParts = metaScratch
    wipe(metaParts)
    if record.exp then
        metaParts[#metaParts + 1] = ns.EXPANSION_LABELS[record.exp] or record.exp
    end
    if record.cat then
        metaParts[#metaParts + 1] = ns.CategoryLabel(record.cat)
    end
    if #metaParts > 0 then
        row.MetaText:SetText(tconcat(metaParts, " \194\183 "))
        row.MetaText:Show()
    else
        row.MetaText:SetText("")
        row.MetaText:Hide()
    end

    -- Right column 3: State mark (lock/tick, 32x32 from 64px asset)
    if record.earned then
        row.StateMark:SetTexture(CHECK_ICON)
        if T then
            row.StateMark:SetVertexColor(T.col.gold.r, T.col.gold.g, T.col.gold.b)
        else
            row.StateMark:SetVertexColor(T.RGBA(T.col.gold))
        end
    else
        row.StateMark:SetTexture(LOCK_ICON)
        if T then
            row.StateMark:SetVertexColor(T.col.locked.r, T.col.locked.g, T.col.locked.b)
        else
            row.StateMark:SetVertexColor(T.RGBA(T.col.locked))
        end
    end

    -- Obtainability badge (small 14px icon overlaid bottom-right of state mark)
    if not row.ObtainBadge then
        local badge = row:CreateTexture(nil, "OVERLAY")
        badge:SetSize(14, 14)
        badge:SetPoint("BOTTOMRIGHT", row.StateMark, "BOTTOMRIGHT", 4, -4)
        row.ObtainBadge = badge
    end
    local obt = record.obtainable
    if obt == "no" then
        row.ObtainBadge:SetTexture(UNOBTAIN_SEALED)
        row.ObtainBadge:SetVertexColor(T.RGBA(T.col.unobtainable))
        row.ObtainBadge:Show()
    elseif obt == "feat" then
        row.ObtainBadge:SetTexture(UNOBTAIN_HOURGLASS)
        row.ObtainBadge:SetVertexColor(T.RGBA(T.col.timeSensitive))
        row.ObtainBadge:Show()
    else
        row.ObtainBadge:Hide()
    end

    -- Right column 2: Type tag pill (PREFIX / SUFFIX)
    if record.type == "prefix" then
        row.TypeTag:SetText(L["TYPE_TAG_PREFIX"])
        row.TypeTag:SetTextColor(T.RGBA(T.col.muted))
        row.TypeTagBG:Show()
        row.TypeTagBorder:Show()
    elseif record.type == "suffix" then
        row.TypeTag:SetText(L["TYPE_TAG_SUFFIX"])
        row.TypeTag:SetTextColor(T.RGBA(T.col.muted))
        row.TypeTagBG:Show()
        row.TypeTagBorder:Show()
    else
        row.TypeTag:SetText("")
        row.TypeTagBG:Hide()
        row.TypeTagBorder:Hide()
    end

    -- Right column 1: Active title pill
    if record.isActive then
        row.ActiveChip:Show()
        row.ActiveChipBG:Show()
        row.ActiveBar:Show()
    else
        row.ActiveChip:Hide()
        row.ActiveChipBG:Hide()
        row.ActiveBar:Hide()
    end

    -- Selection highlight (fill + border)
    ApplySelectionVisual(row, record == self.selectedRecord)
    row.Highlight:Hide()

    -- Handlers (bound once; they read row.record, which is kept current above)
    if not row.OnRowEnter then
        row.OnRowEnter = RowOnEnter
        row.OnRowLeave = RowOnLeave
        row.OnRowClick = RowOnClick
    end
end

-- ---------------------------------------------------------------------------
-- Group header initialiser
-- ---------------------------------------------------------------------------
function TitleList:InitGroupHeader(header, data)
    -- Gate the latch on NeedsLocaleFont, not just on the call existing: if this
    -- ran once while the active locale was still unresolved, ApplyLocaleFont is a
    -- no-op and the flag would pin the header to the client font for good.
    if not header.localeFontDone and T and T.NeedsLocaleFont and T.NeedsLocaleFont() then
        T.ApplyLocaleFont(header.Label)
        header.localeFontDone = true
    end
    header.Label:SetText(string.format("%s \194\183 %d", data.label or "", data.count or 0))
    header.Count:SetText("")
end

-- ---------------------------------------------------------------------------
-- Selection
-- ---------------------------------------------------------------------------
function TitleList:SetSelection(record)
    if not record then return end
    self.selectedRecord = record
    ns.MainFrame:SetSelection(record)
    self:RefreshSelectionVisuals()
    self:EnsureSelectionVisible(record)

    -- Some ScrollBox layouts settle on the next frame; run a follow-up pass.
    if C_Timer and C_Timer.After then
        local selected = record
        C_Timer.After(0, function()
            if TitleList.selectedRecord == selected then
                TitleList:RefreshSelectionVisuals()
                TitleList:EnsureSelectionVisible(selected)
            end
        end)
    end
end

function TitleList:EnsureSelectionVisible(record)
    if not record or not self.scrollBox or not self.scrollBar or not self.displayList then return end
    if not self.scrollBar.GetMinMaxValues or not self.scrollBar.SetValue then return end

    local topOffset = 0
    local elemHeight = ROW_HEIGHT
    local found = false

    for _, elementData in ipairs(self.displayList) do
        local h = elementData.isHeader and HEADER_HEIGHT or ROW_HEIGHT
        if elementData == record then
            elemHeight = h
            found = true
            break
        end
        topOffset = topOffset + h
    end

    if not found then return end

    local minValue, maxValue = self.scrollBar:GetMinMaxValues()
    if not minValue or not maxValue or maxValue <= minValue then return end

    local current = self.scrollBar.GetValue and self.scrollBar:GetValue() or minValue
    local viewHeight = self.scrollBox.GetHeight and self.scrollBox:GetHeight() or 0
    if viewHeight <= 0 then return end

    local viewTop = current
    local viewBottom = current + viewHeight
    local elemBottom = topOffset + elemHeight

    local targetValue = current
    if topOffset < viewTop then
        targetValue = topOffset
    elseif elemBottom > viewBottom then
        targetValue = elemBottom - viewHeight
    else
        return
    end

    if targetValue < minValue then
        targetValue = minValue
    elseif targetValue > maxValue then
        targetValue = maxValue
    end

    self.scrollBar:SetValue(targetValue)
end

function TitleList:RefreshSelectionVisuals()
    if not self.scrollBox then return end
    self.scrollBox:ForEachFrame(function(frame)
        if frame.record then
            ApplySelectionVisual(frame, frame.record == self.selectedRecord)
        end
    end)
end

function TitleList:SelectFirst()
    local dp = self.scrollBox and self.scrollBox:GetDataProvider()
    if not dp then return end
    for _, elementData in dp:Enumerate() do
        if not elementData.isHeader then
            self:SetSelection(elementData)
            return
        end
    end
end
