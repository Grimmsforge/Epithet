-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local ADDON_NAME, ns = ...
local L = ns.L
local T = ns.Theme

local WhatsNew = {}
ns.WhatsNew = WhatsNew

local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetAddOnMetadata = GetAddOnMetadata
local UIParent = UIParent
local StaticPopupDialogs = StaticPopupDialogs
local StaticPopup_Show = StaticPopup_Show
local gsub = string.gsub
local match = string.match
local tostring = tostring

local function Trim(value)
    local s = tostring(value or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

-- The dialog body is rendered as native WoW widgets (FontString/Texture/Button)
-- instead of HTML markup.

-- Parses optional image size suffixes from markdown image directives.
-- Example: "![alt](path =460x230)"; defaults to 96x96 if no size is present.
local DEFAULT_IMAGE_SIZE = 96

-- The path may also be "tex:<name>", one of Epithet's textures by its
-- Theme.tex name ("![ring](tex:portraitRing =96x96)"), so notes never spell out
-- an Epithet file path and follow any flavour's texture override.
local function ParseImageDirective(raw)
    local path, w, h = match(raw, "^(.-)%s*=%s*(%d+)x(%d+)%s*$")
    if not path then
        path = raw
    end
    local texName = match(path, "^tex:([%w_]+)$")
    if texName then
        path = T and T.tex and T.tex[texName] or nil
    end
    return path, tonumber(w) or DEFAULT_IMAGE_SIZE, tonumber(h) or DEFAULT_IMAGE_SIZE
end

-- Converts markdown-like inline emphasis to WoW color-code runs.
local BOLD_COLOR = "fff6e2a6"
local EMPHASIS_COLOR = "ffe8c873"

local function RenderInlineColor(value)
    local text = tostring(value or "")
    text = gsub(text, "%*%*(.-)%*%*", "|c" .. BOLD_COLOR .. "%1|r")
    text = gsub(text, "%*(.-)%*", "|c" .. EMPHASIS_COLOR .. "%1|r")
    return text
end

-- Parses markdown-like body text into a flat list of typed render blocks.
-- Supports headings, bullets, links, images, and paragraphs; blank lines are skipped.
local function BuildBlocks(body)
    local src = tostring(body or "")
    local blocks = {}

    for line in src:gmatch("[^\r\n]+") do
        if not line:match("^%s*$") then
            local h2 = match(line, "^%s*##%s+(.+)$")
            local h1 = (not h2) and match(line, "^%s*#%s+(.+)$")
            local linkLabel, linkURL
            if not h2 and not h1 then
                linkLabel, linkURL = match(line, "^%s*[%*%-]?%s*%[(.-)%]%((.-)%)%s*$")
            end
            local bullet = (not h2 and not h1 and not linkLabel) and match(line, "^%s*[%*%-]%s+(.+)$")
            local imageDirective = match(line, "^%s*!%[[^%]]*%]%((.+)%)%s*$")

            if imageDirective and imageDirective ~= "" then
                local path, w, h = ParseImageDirective(imageDirective)
                if path then  -- an unknown tex: name is skipped, not drawn as a blank box
                    blocks[#blocks + 1] = { type = "image", path = path, w = w, h = h }
                end
            elseif h2 then
                blocks[#blocks + 1] = { type = "h2", text = RenderInlineColor(h2) }
            elseif h1 then
                blocks[#blocks + 1] = { type = "h1", text = RenderInlineColor(h1) }
            elseif linkLabel then
                blocks[#blocks + 1] = { type = "link", text = RenderInlineColor(linkLabel), url = Trim(linkURL) }
            elseif bullet then
                blocks[#blocks + 1] = { type = "bullet", text = RenderInlineColor(bullet) }
            else
                blocks[#blocks + 1] = { type = "p", text = RenderInlineColor(line) }
            end
        end
    end

    return blocks
end

-- Detects whether text includes UTF-8 Cyrillic code points.
local function ContainsCyrillic(text)
    return text ~= nil and text:find("[\208-\211][\128-\191]") ~= nil
end

-- Applies the bundled Unicode font only when the block text contains Cyrillic.
local function ApplyBlockFont(fontLike, path, size, text)
    if T and T.ApplyUnicodeSansFont and ContainsCyrillic(text) then
        T.ApplyUnicodeSansFont(fontLike, size)
    else
        fontLike:SetFont(path, size, "")
    end
end

-- Layout constants for content width, list indentation, and image spacing.
local BODY_WIDTH = 690
local BULLET_INDENT = 14
local IMAGE_GAP_BEFORE = 14

-- Link colors for default and hover states.
local LINK_COLOR = { 0.45, 0.73, 1.0 }
local LINK_HOVER_COLOR = { 0.68, 0.86, 1.0 }

-- Per-block typography and spacing rules used by RenderBody.
-- gapAfter provides explicit trailing space for heading blocks.
local BLOCK_STYLE = {
    h1 = { font = "Fonts\\FRIZQT__.TTF", size = 18, color = { 0.96, 0.89, 0.65 }, gapBefore = 18, gapAfter = 10 },
    h2 = { font = "Fonts\\FRIZQT__.TTF", size = 14, color = { 0.90, 0.80, 0.52 }, gapBefore = 16, gapAfter = 8 },
    p = { font = "Fonts\\FRIZQT__.TTF", size = 12, color = { 0.86, 0.82, 0.74 }, gapBefore = 10 },
    bullet = { font = "Fonts\\FRIZQT__.TTF", size = 12, color = { 0.86, 0.82, 0.74 }, gapBefore = 10, gapBeforeSameType = 4 },
    link = { font = "Fonts\\FRIZQT__.TTF", size = 12, color = LINK_COLOR, gapBefore = 10, gapBeforeSameType = 4 },
}

-- List-like blocks share indentation and compact same-type vertical spacing.
local function IsListItem(blockType)
    return blockType == "bullet" or blockType == "link"
end

function WhatsNew:AcquireTextWidget(index)
    self.textWidgets = self.textWidgets or {}
    local fs = self.textWidgets[index]
    if not fs then
        fs = self.dialogContent:CreateFontString(nil, "ARTWORK")
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        self.textWidgets[index] = fs
    end
    return fs
end

function WhatsNew:AcquireImageWidget(index)
    self.imageWidgets = self.imageWidgets or {}
    local tex = self.imageWidgets[index]
    if not tex then
        tex = self.dialogContent:CreateTexture(nil, "ARTWORK")
        self.imageWidgets[index] = tex
    end
    return tex
end

-- Links use pooled Button widgets (with a FontString label) so rows are clickable.
function WhatsNew:AcquireLinkWidget(index)
    self.linkWidgets = self.linkWidgets or {}
    local btn = self.linkWidgets[index]
    if not btn then
        btn = CreateFrame("Button", nil, self.dialogContent)
        btn:EnableMouse(true)

        local label = btn:CreateFontString(nil, "ARTWORK")
        label:SetJustifyH("LEFT")
        label:SetJustifyV("TOP")
        label:SetWordWrap(true)
        label:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        label:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        btn.label = label

        btn:SetScript("OnEnter", function(self_)
            self_.label:SetTextColor(LINK_HOVER_COLOR[1], LINK_HOVER_COLOR[2], LINK_HOVER_COLOR[3], 1)
        end)
        btn:SetScript("OnLeave", function(self_)
            self_.label:SetTextColor(LINK_COLOR[1], LINK_COLOR[2], LINK_COLOR[3], 1)
        end)
        btn:SetScript("OnClick", function(self_)
            self:ShowLinkPopup(self_.url)
        end)

        self.linkWidgets[index] = btn
    end
    return btn
end

-- Lays out parsed blocks top-to-bottom, reusing pooled widgets, and returns
-- total rendered height for sizing the scroll child.
function WhatsNew:RenderBody(rawBody)
    self.textWidgets = self.textWidgets or {}
    self.imageWidgets = self.imageWidgets or {}
    self.linkWidgets = self.linkWidgets or {}

    local blocks = BuildBlocks(rawBody)
    local textIndex, imageIndex, linkIndex = 0, 0, 0
    local y = 0
    local prevType = nil

    for _, block in ipairs(blocks) do
        if block.type == "image" then
            y = y + IMAGE_GAP_BEFORE
            imageIndex = imageIndex + 1
            local tex = self:AcquireImageWidget(imageIndex)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", self.dialogContent, "TOPLEFT", 0, -y)
            tex:SetSize(block.w, block.h)
            tex:SetTexture(block.path)
            tex:Show()
            y = y + block.h
        else
            local style = BLOCK_STYLE[block.type]
            local gap = style.gapBefore
            if IsListItem(block.type) and IsListItem(prevType) then
                gap = style.gapBeforeSameType
            end
            y = y + gap

            local indent = IsListItem(block.type) and BULLET_INDENT or 0
            local width = BODY_WIDTH - indent

            if block.type == "link" then
                linkIndex = linkIndex + 1
                local btn = self:AcquireLinkWidget(linkIndex)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", self.dialogContent, "TOPLEFT", indent, -y)
                btn:SetWidth(width)
                ApplyBlockFont(btn.label, style.font, style.size, block.text)
                btn.label:SetTextColor(style.color[1], style.color[2], style.color[3], 1)
                btn.label:SetText("\226\128\162  " .. block.text)
                btn.url = block.url
                btn:SetHeight(math.max(style.size + 4, btn.label:GetStringHeight() or 0))
                btn:Show()

                y = y + btn:GetHeight()
            else
                textIndex = textIndex + 1
                local fs = self:AcquireTextWidget(textIndex)
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", self.dialogContent, "TOPLEFT", indent, -y)
                fs:SetWidth(width)
                ApplyBlockFont(fs, style.font, style.size, block.text)
                fs:SetTextColor(style.color[1], style.color[2], style.color[3], 1)
                fs:SetText(block.type == "bullet" and ("\226\128\162  " .. block.text) or block.text)
                fs:Show()

                y = y + (fs:GetStringHeight() or (style.size + 4))
            end

            if style.gapAfter then
                y = y + style.gapAfter
            end
        end

        prevType = block.type
    end

    for i = textIndex + 1, #self.textWidgets do
        self.textWidgets[i]:Hide()
    end
    for i = imageIndex + 1, #self.imageWidgets do
        self.imageWidgets[i]:Hide()
    end
    for i = linkIndex + 1, #self.linkWidgets do
        self.linkWidgets[i]:Hide()
    end

    return y
end

function WhatsNew:GetCurrentVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0.0.0"
    end
    if GetAddOnMetadata then
        return GetAddOnMetadata(ADDON_NAME, "Version") or "0.0.0"
    end
    return "0.0.0"
end

function WhatsNew:GetContentForVersion(version)
    local container = ns.WhatsNewContent and ns.WhatsNewContent.versions
    if type(container) ~= "table" then
        return nil
    end
    return container[version]
end

-- Whether version a is no newer than b ("1.4.9" <= "1.4.10"), part by part.
local function VersionAtMost(a, b)
    local pa, pb = {}, {}
    for n in tostring(a):gmatch("%d+") do pa[#pa + 1] = tonumber(n) end
    for n in tostring(b):gmatch("%d+") do pb[#pb + 1] = tonumber(n) end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then
            return x < y
        end
    end
    return true
end

-- The newest version with notes for this game, no newer than `atMost` (the
-- current version by default). A release does not need notes of its own:
-- without them the window does not open by itself after the update, and
-- /epithet whatsnew shows the newest notes there are.
function WhatsNew:GetLatestContentVersion(atMost)
    local container = ns.WhatsNewContent and ns.WhatsNewContent.versions
    if type(container) ~= "table" then
        return nil
    end
    atMost = atMost or self:GetCurrentVersion()
    local best = nil
    for version in pairs(container) do
        if VersionAtMost(version, atMost) and (not best or VersionAtMost(best, version)) then
            best = version
        end
    end
    return best
end

-- Resolves localized content fields.
-- Accepts either a direct string or a locale-keyed table and falls back to
-- enUS, enGB, default, then empty string.
function WhatsNew:LocalizeField(value)
    if type(value) == "table" then
        local locale = ns.activeLocale or (GetLocale and GetLocale()) or "enUS"
        return value[locale] or value.enUS or value.enGB or value.default or ""
    end
    return value
end

function WhatsNew:EnsureState()
    _G.EpithetDB = _G.EpithetDB or {}
    local db = _G.EpithetDB
    db.whatsNew = db.whatsNew or {
        byVersion = {},
    }
    db.whatsNew.byVersion = db.whatsNew.byVersion or {}
    return db.whatsNew
end

function WhatsNew:GetStateForVersion(version, create)
    -- create=true initializes missing per-version state on demand.
    local state = self:EnsureState()
    local byVersion = state.byVersion
    local item = byVersion[version]

    if not item and create then
        item = {
            firstRun = true,
            hasNew = true,
        }
        byVersion[version] = item
    end

    return item
end

function WhatsNew:ShouldShow(version)
    local content = self:GetContentForVersion(version)
    if not content then
        return false
    end

    local state = self:GetStateForVersion(version, true)
    if state.hasNew == nil then
        state.hasNew = content.hasNew ~= false
    end

    if state.firstRun == nil then
        state.firstRun = true
    end

    return state.firstRun == true and state.hasNew == true
end

function WhatsNew:DismissCurrentVersion()
    local version = self:GetCurrentVersion()
    local state = self:GetStateForVersion(version, true)
    state.firstRun = false
    state.hasNew = false
end

-- Shows a copy-friendly StaticPopup for a URL clicked from a link block.
-- The popup definition is registered lazily on first use.
function WhatsNew:ShowLinkPopup(url)
    if not url or url == "" then
        return
    end

    if not StaticPopupDialogs["EPITHET_WHATSNEW_LINK"] then
        StaticPopupDialogs["EPITHET_WHATSNEW_LINK"] = {
            text = (L and L["WHATS_NEW_LINK_PROMPT"]) or "Copy this link:\nIt's already selected below - press Ctrl+C to copy it.",
            button1 = OKAY,
            hasEditBox = true,
            editBoxWidth = 350,
            -- Read the URL from popup.data (4th arg to StaticPopup_Show) and
            -- use popup.editBox or legacy "<name>EditBox" as a fallback source.
            OnShow = function(popup)
                local edit = popup.editBox or (popup.GetName and _G[popup:GetName() .. "EditBox"])
                if not edit then return end
                local linkURL = popup.data and popup.data.url
                edit:SetText(linkURL or "")
                edit:HighlightText()
                edit:SetFocus()
            end,
            EditBoxOnEnterPressed = function(popup) popup:GetParent():Hide() end,
            EditBoxOnEscapePressed = function(popup) popup:GetParent():Hide() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    StaticPopup_Show("EPITHET_WHATSNEW_LINK", nil, nil, { url = url })
end

function WhatsNew:EnsureDialog()
    if self.dialog then
        return self.dialog
    end

    local frame = CreateFrame("Frame", "EpithetWhatsNewDialog", UIParent, "BackdropTemplate")
    frame:SetSize(760, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(220)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    frame:SetBackdropColor(T.RGBA(T.col.bg0, 0.98))
    frame:SetBackdropBorderColor(T.RGBA(T.col.line, 0.9))
    frame:Hide()

    -- What's New buttons: the shared bordered button, whose border does not
    -- change on hover here. A centred icon when iconPath is given (gold,
    -- brightening on hover), a text label otherwise.
    local ICON_LOOKS = T.ButtonVariant(T.ButtonLooks.standard, {
        idle  = { text = false, icon = { "gold" } },
        hover = { text = false, icon = { "goldBright" }, border = false },
    })
    local LABEL_LOOKS = T.ButtonVariant(T.ButtonLooks.standard, {
        hover = { border = false },
    })
    local function Skin(button, iconPath)
        if iconPath then
            local icon = button:CreateTexture(nil, "OVERLAY")
            icon:SetSize(18, 18)
            icon:SetPoint("CENTER")
            icon:SetTexture(iconPath)
            button.icon = icon
            T.SkinButton(button, ICON_LOOKS)
        else
            local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("CENTER")
            button.label = label
            T.SkinButton(button, LABEL_LOOKS)
        end
    end

    -- Header logo texture displayed to the left of the title.
    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(28, 28)
    logo:SetPoint("TOPLEFT", 14, -10)
    logo:SetTexture(T.tex.logoSeal)

    local heading = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    heading:SetPoint("RIGHT", frame, "RIGHT", -46, 0)
    heading:SetJustifyH("LEFT")

    -- Header close button using the shared icon-button skin.
    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetSize(26, 26)
    closeButton:SetPoint("TOPRIGHT", -8, -8)
    Skin(closeButton, T.tex.close)

    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -38)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -38)
    divider:SetHeight(1)
    divider:SetColorTexture(T.RGBA(T.col.frameBorder, 0.35))

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 52)

    local body = CreateFrame("Frame", nil, scroll)
    body:SetWidth(BODY_WIDTH)
    body:SetHeight(1)
    body:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)

    scroll:SetScrollChild(body)

    -- Bottom cutoff markers rendered in an overlay above scroll content.
    local scrollCutoffOverlay = CreateFrame("Frame", nil, frame)
    scrollCutoffOverlay:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scrollCutoffOverlay:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
    scrollCutoffOverlay:SetFrameStrata(frame:GetFrameStrata())
    scrollCutoffOverlay:SetFrameLevel((body:GetFrameLevel() or frame:GetFrameLevel() or 1) + 20)

    local scrollCutoffBottom = scrollCutoffOverlay:CreateTexture(nil, "OVERLAY")
    scrollCutoffBottom:SetPoint("BOTTOMLEFT", scrollCutoffOverlay, "BOTTOMLEFT", 0, 0)
    scrollCutoffBottom:SetPoint("BOTTOMRIGHT", scrollCutoffOverlay, "BOTTOMRIGHT", 0, 0)
    scrollCutoffBottom:SetHeight(1)
    scrollCutoffBottom:SetColorTexture(T.RGBA(T.col.scrollFade, 0.95))

    local scrollCutoffBottomSoft = scrollCutoffOverlay:CreateTexture(nil, "OVERLAY")
    scrollCutoffBottomSoft:SetPoint("BOTTOMLEFT", scrollCutoffBottom, "TOPLEFT", 0, 0)
    scrollCutoffBottomSoft:SetPoint("BOTTOMRIGHT", scrollCutoffBottom, "TOPRIGHT", 0, 0)
    scrollCutoffBottomSoft:SetHeight(1)
    scrollCutoffBottomSoft:SetColorTexture(T.RGBA(T.col.scrollFade, 0.35))

    local dismiss = CreateFrame("Button", nil, frame)
    dismiss:SetSize(220, 24)
    dismiss:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 14)

    Skin(dismiss)
    dismiss.label:SetText((L and L["WHATS_NEW_CLOSE"]) or "Close")

    closeButton:SetScript("OnClick", function()
        self:DismissCurrentVersion()
        frame:Hide()
    end)

    dismiss:SetScript("OnClick", function()
        self:DismissCurrentVersion()
        frame:Hide()
    end)

    self.dialog = frame
    self.dialogHeading = heading
    self.dialogContent = body
    self.dialogScroll = scroll

    return frame
end

function WhatsNew:Show(version)
    local content = self:GetContentForVersion(version)
    if not content then
        return
    end

    local frame = self:EnsureDialog()
    if not frame then
        return
    end

    local title = self:LocalizeField(content.title) or ((L and L["WHATS_NEW_HEADING"]) or "What's New")
    self.dialogHeading:SetText(title)

    local totalHeight = self:RenderBody(self:LocalizeField(content.body) or "")
    self.dialogContent:SetHeight(math.max(1, totalHeight + 16))
    self.dialogScroll:SetVerticalScroll(0)

    frame:Show()
end

function WhatsNew:ShowForCurrentVersionIfNeeded()
    -- Defers startup display and prevents multiple popup schedules per session.
    if self.shownThisSession or self.pendingShow then
        return
    end

    local profile = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile
    if profile and profile.showWhatsNewOnStartup == false then
        return
    end

    local version = self:GetCurrentVersion()
    if not self:ShouldShow(version) then
        return
    end

    self.pendingShow = true

    if C_Timer and C_Timer.After then
        C_Timer.After(2.5, function()
            self.pendingShow = false
            if self.shownThisSession then
                return
            end
            self.shownThisSession = true
            self:Show(version)
        end)
    else
        self.pendingShow = false
        self.shownThisSession = true
        self:Show(version)
    end
end

function WhatsNew:Init()
    if self.initialized then
        return
    end
    self.initialized = true
end
