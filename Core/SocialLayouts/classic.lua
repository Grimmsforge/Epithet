-- =============================================================================
-- Epithet — Social Layout: Classic
-- =============================================================================
local _, ns = ...

local Layouts = ns.Layouts
local T = ns.Theme
local floor = math.floor

local PORTRAIT_MODE_2D = "2d"
local PORTRAIT_MODE_3D = "3d"
local DEFAULT_EDIT_HINT_TOP_OFFSET_Y = 3

-- The portrait is a fixed square sized from the plate's BASE height, not its
-- current one. A wrapped title makes the plate taller, and deriving the portrait
-- from the live height would grow it in step — pushing the text column narrower,
-- which needs more lines, which grows the plate again.
local function PortraitBox(m)
    local topInset = m.portraitTopInset or m.portraitInsetY or 3
    local bottomInset = m.portraitBottomInset or m.portraitInsetY or 3
    local size = math.max(m.portraitMinWidth or 20, (m.frameHeight or 58) - (topInset + bottomInset))
    return size, topInset, bottomInset
end

-- Width the plate spends on everything that is not the title/rarity column.
local function ChromeWidth(m)
    return (m.leftColWidth or 44) + ((m.centerGapX or 9) * 2) + PortraitBox(m) + (m.widthTailPad or 8)
end

local function ResolvePortraitMode(frame, m)
    local mode = (frame and frame.portraitModeOverride)
        or (m and m.portraitMode)
        or (ns.GetPortraitMode and ns.GetPortraitMode())
        or PORTRAIT_MODE_3D

    if type(mode) == "string" then
        mode = mode:lower()
    end
    if mode ~= PORTRAIT_MODE_2D then
        mode = PORTRAIT_MODE_3D
    end
    return mode
end

if not Layouts or not Layouts.RegisterLayout then
    return
end

Layouts:RegisterLayout("classic", {
    label = "Slimline",
    labelKey = "SOCIAL_LAYOUT_CLASSIC",
    metrics = {
        layoutStyle = "classic",
        frameHeight = 58,
        minWidth = 248,
        maxWidth = 448,
        edgeInsetY = 3,
        leftInsetX = 4,
        leftColWidth = 44,
        gemSize = 40,
        centerGapX = 9,
        centerTopOffset = -6,
        centerBottomOffset = 6,
        portraitRightInset = 1,
        portraitTopInset = 4,
        portraitBottomInset = 3,
        portraitMinWidth = 20,
        crownBaseScale = 0.65,
        crownMinSize = 24,
        widthTailPad = 8,
        titleRowHeight = 20,         -- single-line title row; grows per extra line
        rarityRowHeight = 18,
        titleFontSize = 11,          -- reasserted every pass; portrait card uses 16
        rarityFontSize = 10,
        titleMaxLines = 2,           -- wrap past maxWidth rather than truncating
        titleLineSpacing = 1,
    },

    ApplyLayout = function(self, frame, m)
        if frame.editHintTop then
            frame.editHintTop:ClearAllPoints()
            frame.editHintTop:SetPoint("BOTTOM", frame, "TOP", 0, DEFAULT_EDIT_HINT_TOP_OFFSET_Y)
        end

        if frame.portraitMask then
            if frame.portrait and frame.portrait.RemoveMaskTexture and frame.portraitTextureMasked then
                frame.portrait:RemoveMaskTexture(frame.portraitMask)
                frame.portraitTextureMasked = false
            end
            if frame.portraitBG and frame.portraitBG.RemoveMaskTexture and frame.portraitBGMasked then
                frame.portraitBG:RemoveMaskTexture(frame.portraitMask)
                frame.portraitBGMasked = false
            end
        end

        local mode = ResolvePortraitMode(frame, m)
        frame.portraitMode = mode
        if mode == PORTRAIT_MODE_3D then
            -- Creation, the keep-on-hide flag, the load callback and the camera
            -- all live on the registry so both layouts share one implementation.
            self:EnsurePortraitModel(frame)
        end

        if frame.portraitRingFrame then
            frame.portraitRingFrame:Hide()
        end

        if frame.scrollBackdrop then
            frame.scrollBackdrop:Hide()
        end

        -- Classic mode reuses the shared frame and explicitly hides portrait-card
        -- ornament layers. The swallowtails are bannerTailLeft/Right — the old
        -- bannerTab* names this list used to carry are never created, so nothing
        -- was hiding the tails when switching back from the portrait card.
        if frame.bannerFill then frame.bannerFill:Hide() end
        if frame.bannerTailLeft then frame.bannerTailLeft:Hide() end
        if frame.bannerTailRight then frame.bannerTailRight:Hide() end
        if frame.bannerTopLine then frame.bannerTopLine:Hide() end
        if frame.bannerBottomLine then frame.bannerBottomLine:Hide() end
        if frame.bannerLeftLine then frame.bannerLeftLine:Hide() end
        if frame.bannerRightLine then frame.bannerRightLine:Hide() end
        if frame.bannerTailTrimLeft then frame.bannerTailTrimLeft:Hide() end
        if frame.bannerTailTrimRight then frame.bannerTailTrimRight:Hide() end

        if mode == PORTRAIT_MODE_3D then
            if frame.portrait then frame.portrait:Hide() end
            if frame.portraitModel then frame.portraitModel:Show() end
        else
            if frame.portraitModel then frame.portraitModel:Hide() end
            if frame.portrait then frame.portrait:Show() end
        end

        if frame.SetBackdropColor then
            if ns.Theme and ns.Theme.col then
                frame:SetBackdropColor(ns.Theme.col.bg0.r, ns.Theme.col.bg0.g, ns.Theme.col.bg0.b, 0.86)
                frame:SetBackdropBorderColor(ns.Theme.col.goldDeep.r, ns.Theme.col.goldDeep.g, ns.Theme.col.goldDeep.b, 0.9)
            else
                frame:SetBackdropColor(T.RGBA(T.col.plateBg, 0.86))
                frame:SetBackdropBorderColor(T.RGBA(T.col.plateBorder, 0.9))
            end
        end

        if frame.portraitBG then
            frame.portraitBG:SetColorTexture(T.RGBA(T.col.platePortraitBg))
        end

        local portraitW = PortraitBox(m)
        frame:SetHeight(frame.dynamicFrameHeight or m.frameHeight)

        if frame.leftCol then
            frame.leftCol:ClearAllPoints()
            frame.leftCol:SetPoint("TOPLEFT", frame, "TOPLEFT", m.leftInsetX, -m.edgeInsetY)
            frame.leftCol:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", m.leftInsetX, m.edgeInsetY)
            frame.leftCol:SetWidth(m.leftColWidth)
        end
        if frame.gem then
            frame.gem:SetSize(m.gemSize, m.gemSize)
        end

        self:LayoutTargetPortrait(frame)

        -- Anchored to the frame rather than to leftCol/portraitShell: the portrait
        -- is now a centred fixed square, so its edges no longer track the plate's
        -- top and bottom once a wrapped title has made the plate taller.
        if frame.centerCol then
            -- centerTopOffset is stored as a downward (negative) nudge from the
            -- left column's top, so it subtracts here where the inset is positive.
            local topInsetY = m.edgeInsetY - m.centerTopOffset
            local bottomInsetY = m.edgeInsetY + m.centerBottomOffset
            frame.centerCol:ClearAllPoints()
            frame.centerCol:SetPoint("TOPLEFT", frame, "TOPLEFT",
                m.leftInsetX + m.leftColWidth + m.centerGapX, -topInsetY)
            frame.centerCol:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
                -(m.portraitRightInset + portraitW + m.centerGapX), bottomInsetY)
        end

        local titleLines = frame.dynamicTitleLines or 1
        local titleRowHeight = frame.dynamicTitleHeight or m.titleRowHeight or 20

        if frame.titleRow and frame.centerCol then
            frame.titleRow:ClearAllPoints()
            frame.titleRow:SetPoint("TOPLEFT", frame.centerCol, "TOPLEFT", 0, 0)
            frame.titleRow:SetPoint("TOPRIGHT", frame.centerCol, "TOPRIGHT", 0, 0)
            frame.titleRow:SetHeight(titleRowHeight)
        end

        if frame.rarityRow and frame.centerCol then
            frame.rarityRow:ClearAllPoints()
            frame.rarityRow:SetPoint("BOTTOMLEFT", frame.centerCol, "BOTTOMLEFT", 0, 0)
            frame.rarityRow:SetPoint("BOTTOMRIGHT", frame.centerCol, "BOTTOMRIGHT", 0, 0)
            frame.rarityRow:SetHeight(m.rarityRowHeight or 18)
        end

        if frame.titleText then
            self:SetFontSize(frame.titleText, m.titleFontSize)

            -- Wrapping is only switched on for a title that has already been
            -- measured as too long for the widest the plate is allowed to get,
            -- so short titles still let the plate hug their text.
            local wraps = titleLines > 1
            frame.titleText:SetWordWrap(wraps)
            if frame.titleText.SetMaxLines then
                frame.titleText:SetMaxLines(wraps and (m.titleMaxLines or 2) or 1)
            end
            if frame.titleText.SetSpacing then
                frame.titleText:SetSpacing(m.titleLineSpacing or 0)
            end
            frame.titleText:SetJustifyH("LEFT")
            frame.titleText:SetJustifyV("MIDDLE")
            frame.titleText:SetShadowOffset(0, 0)
        end

        if frame.rarityText then
            self:SetFontSize(frame.rarityText, m.rarityFontSize)
            frame.rarityText:SetWordWrap(false)
            frame.rarityText:SetJustifyH("LEFT")
            frame.rarityText:SetJustifyV("MIDDLE")
            frame.rarityText:SetShadowOffset(0, 0)
        end

        if frame.crownFrame then
            frame.crownFrame:Show()
        end

        if frame.portraitTopRule and frame.portraitBottomRule then
            frame.portraitTopRule:Hide()
            frame.portraitBottomRule:Hide()
        end
    end,

    LayoutPortrait = function(self, frame, m)
        if not frame or not frame.portraitShell then return end

        if frame.portraitRingFrame then
            frame.portraitRingFrame:Hide()
        end

        local mode = frame.portraitMode or ResolvePortraitMode(frame, m)

        -- Fixed square pinned to the right edge and centred vertically, so a plate
        -- that grew to fit a wrapped title keeps the same portrait it had at one line.
        local portraitW = PortraitBox(m)

        frame.portraitShell:ClearAllPoints()
        frame.portraitShell:SetPoint("RIGHT", frame, "RIGHT", -m.portraitRightInset, 0)
        frame.portraitShell:SetSize(portraitW, portraitW)

        if mode == PORTRAIT_MODE_3D and frame.portraitModel then
            if frame.portrait then frame.portrait:Hide() end
            frame.portraitModel:Show()
            frame.portraitModel:ClearAllPoints()
            frame.portraitModel:SetPoint("TOPLEFT", frame.portraitShell, "TOPLEFT", 0, 0)
            frame.portraitModel:SetPoint("BOTTOMRIGHT", frame.portraitShell, "BOTTOMRIGHT", 0, 0)
            self:ApplyPortraitLayering(frame)
            self:SeatPortraitModel(frame)
            self:RefreshPortraitCamera(frame)
        elseif frame.portrait then
            if frame.portraitModel then
                frame.portraitModel:Hide()
                self:ReleasePortraitModel(frame)
            end
            frame.portrait:ClearAllPoints()
            frame.portrait:SetPoint("TOPLEFT", frame.portraitShell, "TOPLEFT", 0, -1)
            frame.portrait:SetPoint("BOTTOMRIGHT", frame.portraitShell, "BOTTOMRIGHT", -1, 0)
            frame.portrait:Show()
        end

        if frame.crownFrame then
            local crownSize = math.max(m.crownMinSize, floor((portraitW * m.crownBaseScale * self:GetCrownSizeMultiplier()) + 0.5))
            frame.crownFrame:SetSize(crownSize, crownSize)
            frame.crownFrame:ClearAllPoints()
            frame.crownFrame:SetPoint("BOTTOM", frame.portraitShell, "TOP", 0, self:GetCrownYOffset())
        end

        if frame.portraitTopRule and frame.portraitBottomRule then
            frame.portraitTopRule:Hide()
            frame.portraitBottomRule:Hide()
        end

        if mode ~= PORTRAIT_MODE_3D and frame.portrait and frame.portraitUnit then
            self:ApplyPortraitTexture(frame.portrait, frame.portraitUnit, "classic", frame.portraitShell)
        end
    end,

    -- Grow sideways first, then downwards. The plate widens with the title until
    -- it hits maxWidth; only a title that still does not fit there wraps onto a
    -- second line, and the plate gets taller by exactly that line.
    SizePill = function(self, frame, m)
        if not frame or not frame.titleText or not frame.rarityText then return end

        -- Measure at this layout's own size, not one the portrait card left behind.
        self:SetFontSize(frame.titleText, m.titleFontSize)
        self:SetFontSize(frame.rarityText, m.rarityFontSize)

        local chrome = ChromeWidth(m)
        local maxTextWidth = math.max(40, (m.maxWidth or 448) - chrome)
        local maxLines = math.max(1, m.titleMaxLines or 2)
        local spacing = m.titleLineSpacing or 0

        local titleWidth, lineHeight, lines = self:MeasureText(
            frame, frame.titleText, frame.titleText:GetText(), maxTextWidth, maxLines)
        local rarityWidth = frame.rarityText:GetStringWidth() or 0

        local textColWidth
        if lines > 1 then
            -- Already at the widest the plate goes; the extra lines use all of it.
            textColWidth = maxTextWidth
        else
            textColWidth = math.max(titleWidth, rarityWidth)
        end

        local extraHeight = 0
        if lines > 1 then
            extraHeight = self:TextBlockHeight(lines, lineHeight, spacing)
                - self:TextBlockHeight(1, lineHeight, spacing)
        end

        frame.dynamicTitleLines = lines
        frame.dynamicTitleHeight = (m.titleRowHeight or 20) + extraHeight
        frame.dynamicFrameHeight = (m.frameHeight or 58) + extraHeight

        -- Width = left column + centre text column + portrait column + tail padding.
        local width = math.max(m.minWidth, math.min(m.maxWidth, floor(chrome + textColWidth)))
        frame:SetWidth(width)

        -- Re-run the layout so the rows and centre column pick up the measured
        -- title height rather than the single-line base metrics.
        self:ApplyLayoutToFrame(frame, { layout = frame.layoutKey or "classic" })
    end,
})
